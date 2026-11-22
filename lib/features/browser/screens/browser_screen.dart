import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

import '../engine/adguard_engine.dart';
import '../models/browser_tab.dart';
import '../services/app_update_service.dart';
import '../services/download_service.dart';
import '../services/pip_service.dart';
import '../services/theme_service.dart';
import '../utils/browser_constants.dart';
import '../utils/url_helper.dart';
import '../webview/browser_configuration.dart';
import '../webview/browser_controller.dart';
import '../webview/browser_navigation.dart';
import '../widgets/browser_bottom_bar.dart';
import '../widgets/browser_menu.dart';
import '../widgets/browser_toolbar.dart';
import '../widgets/loading_indicator.dart';
import 'tabs_screen.dart';

class BrowserScreen extends StatefulWidget {
  const BrowserScreen({super.key});

  @override
  State<BrowserScreen> createState() => _BrowserScreenState();
}

class _BrowserScreenState extends State<BrowserScreen>
    with WidgetsBindingObserver {
  final BrowserController _controller = BrowserController();
  final TextEditingController _homeSearchController = TextEditingController();

  bool _isInPiP = false;
  bool _mediaPlaying = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _controller.init();

    // Listen to PiP state changes from native
    PiPService.instance.onPiPChanged = (inPiP) {
      if (mounted) setState(() => _isInPiP = inPiP);
    };

    // Auto-check for updates on startup
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkUpdateOnStartup();
    });
  }

  void _checkUpdateOnStartup() {
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        AppUpdateService.instance.checkAndPromptUpdate(
          context,
          notifyIfLatest: false,
        );
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _homeSearchController.dispose();
    _controller.dispose();
    PiPService.instance.onPiPChanged = null;
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    // When app is paused/minimized but NOT entering PiP, keep audio playing
    // The WebView handles this natively on Android — no extra action needed.
    // We just track lifecycle to update UI state.
    if (state == AppLifecycleState.resumed) {
      if (mounted) setState(() => _isInPiP = false);
    }
  }

  Future<bool> _handlePopScope() async {
    final cur = _controller.currentTab;
    if (cur != null && cur.webViewController != null) {
      final canGoBack = await cur.webViewController!.canGoBack();
      if (canGoBack) {
        await cur.webViewController!.goBack();
        return false;
      }
    }
    return true;
  }

  /// Track if media is currently playing (set by JS bridge)
  void _setMediaPlaying(bool playing) {
    _mediaPlaying = playing;
    PiPService.instance.setMediaPlaying(playing);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeService.instance.isDark;
    final bgColor = isDark ? Colors.black : BrowserConstants.lightBackground;

    return ListenableBuilder(
      listenable: Listenable.merge([_controller, ThemeService.instance]),
      builder: (context, _) {
        final tabs = _controller.tabs;
        final currentIndex = _controller.currentTabIndex;
        final currentTab = _controller.currentTab;

        if (tabs.isEmpty || currentTab == null) {
          return Scaffold(
            backgroundColor: bgColor,
            body: const SizedBox.shrink(),
          );
        }

        // PiP mode — show minimal overlay UI
        if (_isInPiP) {
          return _buildPiPOverlay(currentTab, isDark);
        }

        return PopScope(
          canPop: false,
          onPopInvokedWithResult: (didPop, result) async {
            if (didPop) return;
            final shouldPop = await _handlePopScope();
            if (shouldPop && context.mounted) {
              Navigator.of(context).pop();
            }
          },
          child: Scaffold(
            backgroundColor: bgColor,

            body: SafeArea(
              child: Column(
                children: [
                  // Top Toolbar with Address Bar & Shield
                  BrowserToolbar(
                    tab: currentTab,
                    onNavigate: (query) => _controller.navigate(query),
                    onReload: () => currentTab.webViewController?.reload(),
                    onStop: () => currentTab.webViewController?.stopLoading(),
                  ),

                  // Loading Progress Line
                  LoadingIndicator(
                    progress: currentTab.progress,
                    isLoading: currentTab.isLoading,
                  ),

                  // Active WebViews Stack
                  Expanded(
                    child: Stack(
                      children: [
                        IndexedStack(
                          index: currentIndex,
                          children: tabs
                              .map((tab) => _buildTabView(tab))
                              .toList(),
                        ),

                        // PiP Floating Button when media is detected
                        if (_mediaPlaying && PiPService.instance.isPiPSupported)
                          Positioned(
                            bottom: 12,
                            right: 12,
                            child: _buildPiPFab(isDark),
                          ),
                      ],
                    ),
                  ),

                  // Bottom Navigation Bar
                  BrowserBottomBar(
                    tab: currentTab,
                    tabCount: tabs.length,
                    onBack: () => currentTab.webViewController?.goBack(),
                    onForward: () =>
                        currentTab.webViewController?.goForward(),
                    onHome: () =>
                        _controller.navigate(_controller.homepage),
                    onTabs: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              TabsScreen(controller: _controller),
                        ),
                      );
                    },
                    onMenu: () {
                      BrowserMenu.show(context, currentTab, _controller);
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildPiPFab(bool isDark) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () async {
          await PiPService.instance.enterPiP();
        },
        borderRadius: BorderRadius.circular(28),
        child: Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            color: isDark ? Colors.white : Colors.black,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Icon(
            Icons.picture_in_picture_alt,
            color: isDark ? Colors.black : Colors.white,
            size: 24,
          ),
        ),
      ),
    );
  }

  /// Minimal PiP overlay shown while in picture-in-picture mode
  Widget _buildPiPOverlay(BrowserTab tab, bool isDark) {
    final bgColor = isDark ? Colors.black : BrowserConstants.lightBackground;
    final textColor = isDark ? Colors.white : Colors.black;
    return Scaffold(
      backgroundColor: bgColor,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.play_circle_filled,
                size: 48, color: textColor.withValues(alpha: 0.7)),
            const SizedBox(height: 8),
            Text(
              tab.title.isEmpty ? 'Playing' : tab.title,
              style: TextStyle(
                color: textColor,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
              maxLines: 2,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabView(BrowserTab tab) {
    final isEmptyOrHome = tab.url.isEmpty || tab.url == 'about:blank';

    if (isEmptyOrHome) {
      return _buildHomeView(tab);
    }

    final domain = UrlHelper.extractDomain(tab.url);

    return Stack(
      children: [
        InAppWebView(
          key: ValueKey(tab.id),
          initialUrlRequest: URLRequest(url: WebUri(tab.url)),
          initialSettings: BrowserConfiguration.buildSettings(tab),
          initialUserScripts: UnmodifiableListView(
            AdGuardEngine.instance.getUserScripts(currentDomain: domain),
          ),
          onWebViewCreated: (webController) {
            tab.webViewController = webController;
          },
          onLoadStart: (webController, uri) {
            if (uri != null) {
              final urlStr = uri.toString();
              tab.url = urlStr;
              if (urlStr.contains('spotify.com') && !tab.isDesktopMode) {
                webController.setSettings(
                  settings: BrowserConfiguration.buildSettings(tab),
                );
              }
              _controller.clearTabError(tab);
              _controller.updateTabProgress(tab, 0.1);
              _controller.updateTabUrl(tab, urlStr);
            }
          },
          onProgressChanged: (webController, progress) {
            _controller.updateTabProgress(tab, progress / 100.0);
            if (progress >= 50) {
              AdGuardEngine.instance.injectCosmeticCleanup(
                webController,
                domain: UrlHelper.extractDomain(tab.url),
              );
            }
          },
          onLoadStop: (webController, uri) async {
            _controller.updateTabProgress(tab, 1.0);
            if (uri != null) {
              final title = await webController.getTitle() ?? '';
              _controller.updateTabTitle(tab, title);
              _controller.updateTabUrl(tab, uri.toString());
            }
            await AdGuardEngine.instance.injectCosmeticCleanup(
              webController,
              domain: UrlHelper.extractDomain(uri?.toString() ?? tab.url),
            );
            // Inject JS to detect media playing state for PiP FAB
            await _injectMediaDetectionScript(webController);

            Future.delayed(const Duration(milliseconds: 800), () {
              if (mounted) {
                AdGuardEngine.instance.injectCosmeticCleanup(
                  webController,
                  domain: UrlHelper.extractDomain(tab.url),
                );
              }
            });
          },
          onReceivedError: (webController, request, error) {
            if (request.isForMainFrame == true) {
              _controller.setTabError(tab, error.description);
            }
          },
          onTitleChanged: (webController, title) {
            if (title != null) {
              _controller.updateTabTitle(tab, title);
            }
          },
          shouldInterceptRequest: (webController, request) async {
            final response = AdGuardEngine.instance.interceptRequest(
              request,
              pageUrl: tab.url,
            );
            if (response != null) {
              _controller.incrementTabBlockedCount(tab);
              return response;
            }
            return null;
          },
          shouldOverrideUrlLoading: (webController, navigationAction) async {
            return await BrowserNavigation.handleNavigationAction(
              webController,
              navigationAction,
            );
          },
          onCreateWindow: (webController, createWindowAction) async {
            final url = createWindowAction.request.url?.toString();
            if (url != null && url.isNotEmpty) {
              _controller.navigate(url);
              return true;
            }
            return false;
          },
          onDownloadStartRequest: (webController, downloadRequest) async {
            final url = downloadRequest.url.toString();
            final filename = downloadRequest.suggestedFilename;

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Starting download: ${filename ?? url}'),
                backgroundColor: BrowserConstants.surface,
              ),
            );

            await DownloadService.instance.startDownload(
              url,
              suggestedFilename: filename,
            );
          },
        ),
        if (tab.errorMessage != null) _buildErrorView(tab),
      ],
    );
  }

  /// Inject JavaScript that tells Flutter when media starts/stops playing.
  /// Uses window.postMessage to communicate back via console.message listener.
  Future<void> _injectMediaDetectionScript(
      InAppWebViewController webController) async {
    // Add a JS handler so the page can notify Flutter about media state
    try {
      webController.addJavaScriptHandler(
        handlerName: 'mediaStateChanged',
        callback: (args) {
          final playing = args.isNotEmpty ? args[0] as bool? ?? false : false;
          if (mounted) {
            setState(() {
              _setMediaPlaying(playing);
            });
          }
        },
      );
    } catch (_) {}

    try {
      await webController.evaluateJavascript(source: '''
        (function() {
          function checkMedia() {
            var els = document.querySelectorAll('video, audio');
            for (var i = 0; i < els.length; i++) {
              if (!els[i].paused && !els[i].ended && els[i].readyState > 2) {
                return true;
              }
            }
            return false;
          }

          function notify(playing) {
            try {
              window.flutter_inappwebview.callHandler('mediaStateChanged', playing);
            } catch(e) {}
          }

          document.addEventListener('play', function(e) {
            var t = e.target.tagName;
            if (t === 'VIDEO' || t === 'AUDIO') notify(true);
          }, true);

          document.addEventListener('pause', function(e) {
            var t = e.target.tagName;
            if (t === 'VIDEO' || t === 'AUDIO') notify(checkMedia());
          }, true);

          document.addEventListener('ended', function(e) {
            notify(checkMedia());
          }, true);
        })();
      ''');
    } catch (_) {}
  }

  Widget _buildErrorView(BrowserTab tab) {
    final isDark = ThemeService.instance.isDark;
    final bgColor = isDark ? Colors.black : BrowserConstants.lightBackground;
    final surfaceColor = isDark ? BrowserConstants.surface : BrowserConstants.lightSurface;
    final borderColor = isDark ? Colors.white24 : Colors.black12;
    final textColor = isDark ? Colors.white : Colors.black;
    final textSecondary = isDark ? Colors.white38 : Colors.black38;
    final textMuted = isDark ? Colors.white70 : Colors.black54;
    final textSubtle = isDark ? Colors.white54 : Colors.black45;

    final isDnsOrOffline =
        (tab.errorMessage ?? '').contains('ERR_NAME_NOT_RESOLVED') ||
        (tab.errorMessage ?? '').contains('ERR_INTERNET_DISCONNECTED') ||
        (tab.errorMessage ?? '').contains('ERR_CONNECTION');

    return Container(
      color: bgColor,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: surfaceColor,
                  shape: BoxShape.circle,
                  border: Border.all(color: borderColor, width: 2.0),
                ),
                child: Icon(
                  Icons.wifi_off_rounded,
                  size: 36,
                  color: textMuted,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Unable to Connect',
                style: TextStyle(
                  color: textColor,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                tab.url,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(color: textSecondary, fontSize: 13),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E1E1E) : const Color(0xFFEEEEEE),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: isDark ? Colors.white12 : Colors.black12),
                ),
                child: Text(
                  tab.errorMessage ?? 'Network request failed',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: textMuted,
                    fontSize: 12,
                    fontFamily: 'monospace',
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                isDnsOrOffline
                    ? 'Check your device internet or emulator DNS settings.'
                    : 'The server may be down or unreachable.',
                textAlign: TextAlign.center,
                style: TextStyle(color: textSubtle, fontSize: 13),
              ),
              const SizedBox(height: 28),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  OutlinedButton.icon(
                    onPressed: () {
                      _controller.clearTabError(tab);
                      _controller.navigate(_controller.homepage);
                    },
                    icon: Icon(
                      Icons.home_outlined,
                      size: 18,
                      color: textMuted,
                    ),
                    label: Text(
                      'Home',
                      style: TextStyle(color: textMuted),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: borderColor),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton.icon(
                    onPressed: () {
                      _controller.clearTabError(tab);
                      tab.webViewController?.reload();
                    },
                    icon: Icon(
                      Icons.refresh_rounded,
                      size: 18,
                      color: isDark ? Colors.black : Colors.white,
                    ),
                    label: Text(
                      'Try Again',
                      style: TextStyle(
                        color: isDark ? Colors.black : Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isDark ? Colors.white : Colors.black,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHomeView(BrowserTab tab) {
    final isDark = ThemeService.instance.isDark;
    final bgColor = isDark ? Colors.black : BrowserConstants.lightBackground;
    final surfaceColor = isDark ? BrowserConstants.surface : BrowserConstants.lightSurface;
    final borderColor = isDark ? Colors.white : Colors.black;
    final borderLightColor = isDark ? BrowserConstants.borderLight : BrowserConstants.lightBorderLight;
    final textColor = isDark ? Colors.white : Colors.black;
    final textSecColor = isDark ? BrowserConstants.textSecondary : BrowserConstants.lightTextSecondary;
    final hintStyle = TextStyle(color: textSecColor);

    return Container(
      color: bgColor,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Brand Logo Badge
              Container(
                width: 76,
                height: 76,
                decoration: BoxDecoration(
                  color: surfaceColor,
                  shape: BoxShape.circle,
                  border: Border.all(color: borderColor, width: 2.0),
                ),
                child: Icon(
                  tab.isIncognito
                      ? Icons.visibility_off
                      : Icons.shield_outlined,
                  size: 38,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 18),

              Text(
                tab.isIncognito
                    ? 'PRIVATE BROWSING'
                    : BrowserConstants.appFullName,
                style: TextStyle(
                  color: textColor,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                tab.isIncognito
                    ? 'No history, cookies or local traces saved'
                    : 'AdGuard Ad-Blocking • Built-in Privacy • Zero Trackers',
                style: TextStyle(
                  color: textSecColor,
                  fontSize: 12,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 28),

              // Search Bar
              Container(
                decoration: BoxDecoration(
                  color: surfaceColor,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: borderLightColor,
                    width: 1.2,
                  ),
                ),
                child: TextField(
                  controller: _homeSearchController,
                  style: TextStyle(color: textColor, fontSize: 15),
                  textInputAction: TextInputAction.go,
                  decoration: InputDecoration(
                    hintText: 'Search or enter website address',
                    hintStyle: hintStyle,
                    prefixIcon: Icon(
                      Icons.search,
                      color: textColor,
                      size: 20,
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(
                        Icons.arrow_forward,
                        color: textColor,
                        size: 20,
                      ),
                      onPressed: () {
                        final text = _homeSearchController.text.trim();
                        if (text.isNotEmpty) {
                          _homeSearchController.clear();
                          _controller.navigate(text);
                        }
                      },
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                  ),
                  onSubmitted: (text) {
                    final trimmed = text.trim();
                    if (trimmed.isNotEmpty) {
                      _homeSearchController.clear();
                      _controller.navigate(trimmed);
                    }
                  },
                ),
              ),

              const SizedBox(height: 32),

              // Speed Dial Shortcuts
              Wrap(
                spacing: 16,
                runSpacing: 16,
                alignment: WrapAlignment.center,
                children: [
                  _buildSpeedDial('Google', 'https://www.google.com',
                      Icons.search, isDark),
                  _buildSpeedDial('YouTube', 'https://www.youtube.com',
                      Icons.play_arrow, isDark),
                  _buildSpeedDial('Wikipedia', 'https://www.wikipedia.org',
                      Icons.menu_book, isDark),
                  _buildSpeedDial(
                      'Reddit', 'https://www.reddit.com', Icons.forum, isDark),
                  _buildSpeedDial(
                      'GitHub', 'https://www.github.com', Icons.code, isDark),
                  _buildSpeedDial('News', 'https://news.google.com',
                      Icons.newspaper, isDark),
                ],
              ),

              const SizedBox(height: 28),

              // Privacy Status Pill
              ListenableBuilder(
                listenable: AdGuardEngine.instance,
                builder: (context, _) {
                  final totalBlocked =
                      AdGuardEngine.instance.statistics.totalBlocked;
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: surfaceColor,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: isDark ? BrowserConstants.border : BrowserConstants.lightBorder),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.security,
                          color: textColor,
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '$totalBlocked Threats & Ads Blocked Locally',
                          style: TextStyle(
                            color: textColor,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSpeedDial(
      String name, String url, IconData icon, bool isDark) {
    final surfaceColor = isDark ? BrowserConstants.surface : BrowserConstants.lightSurface;
    final borderColor = isDark ? BrowserConstants.borderLight : BrowserConstants.lightBorderLight;
    final textColor = isDark ? Colors.white : Colors.black;

    return InkWell(
      onTap: () => _controller.navigate(url),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 72,
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: surfaceColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: borderColor,
                  width: 1.2,
                ),
              ),
              child: Icon(icon, color: textColor, size: 22),
            ),
            const SizedBox(height: 6),
            Text(
              name,
              style: TextStyle(
                color: textColor,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
