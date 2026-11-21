import 'dart:collection';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import '../engine/adguard_engine.dart';
import '../models/browser_tab.dart';
import '../services/download_service.dart';
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

class _BrowserScreenState extends State<BrowserScreen> {
  final BrowserController _controller = BrowserController();
  final TextEditingController _homeSearchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _controller.init();
  }

  @override
  void dispose() {
    _homeSearchController.dispose();
    _controller.dispose();
    super.dispose();
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

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _controller,
      builder: (context, _) {
        final tabs = _controller.tabs;
        final currentIndex = _controller.currentTabIndex;
        final currentTab = _controller.currentTab;

        if (tabs.isEmpty || currentTab == null) {
          // Fallback - should never happen because controller seeds initial tab
          return const Scaffold(
            backgroundColor: Colors.black,
            body: SizedBox.shrink(),
          );
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
            backgroundColor: Colors.black,
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
                    child: IndexedStack(
                      index: currentIndex,
                      children: tabs.map((tab) => _buildTabView(tab)).toList(),
                    ),
                  ),

                  // Bottom Navigation Bar
                  BrowserBottomBar(
                    tab: currentTab,
                    tabCount: tabs.length,
                    onBack: () => currentTab.webViewController?.goBack(),
                    onForward: () => currentTab.webViewController?.goForward(),
                    onHome: () => _controller.navigate(_controller.homepage),
                    onTabs: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => TabsScreen(controller: _controller),
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

  Widget _buildTabView(BrowserTab tab) {
    final isEmptyOrHome = tab.url.isEmpty || tab.url == 'about:blank';

    if (isEmptyOrHome) {
      return _buildHomeView(tab);
    }

    final domain = UrlHelper.extractDomain(tab.url);

    return InAppWebView(
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
          _controller.updateTabProgress(tab, 0.1);
          _controller.updateTabUrl(tab, urlStr);
        }
      },
      onProgressChanged: (webController, progress) {
        _controller.updateTabProgress(tab, progress / 100.0);
      },
      onLoadStop: (webController, uri) async {
        _controller.updateTabProgress(tab, 1.0);
        if (uri != null) {
          final title = await webController.getTitle() ?? '';
          _controller.updateTabTitle(tab, title);
          _controller.updateTabUrl(tab, uri.toString());
        }
      },
      onTitleChanged: (webController, title) {
        if (title != null) {
          _controller.updateTabTitle(tab, title);
        }
      },
      shouldInterceptRequest: (webController, request) async {
        final response = AdGuardEngine.instance.interceptRequest(request, pageUrl: tab.url);
        if (response != null) {
          _controller.incrementTabBlockedCount(tab);
          return response;
        }
        return null;
      },
      shouldOverrideUrlLoading: (webController, navigationAction) async {
        return await BrowserNavigation.handleNavigationAction(webController, navigationAction);
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

        await DownloadService.instance.startDownload(url, suggestedFilename: filename);
      },
    );
  }

  Widget _buildHomeView(BrowserTab tab) {
    return Container(
      color: Colors.black,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Monochrome Brand Logo Badge
              Container(
                width: 76,
                height: 76,
                decoration: BoxDecoration(
                  color: BrowserConstants.surface,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2.0),
                ),
                child: Icon(
                  tab.isIncognito ? Icons.visibility_off : Icons.shield_outlined,
                  size: 38,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 18),

              Text(
                tab.isIncognito ? 'PRIVATE BROWSING' : BrowserConstants.appFullName,
                style: const TextStyle(
                  color: Colors.white,
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
                style: const TextStyle(
                  color: BrowserConstants.textSecondary,
                  fontSize: 12,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 28),

              // Minimalist Monochrome Search Bar
              Container(
                decoration: BoxDecoration(
                  color: BrowserConstants.surface,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: BrowserConstants.borderLight, width: 1.2),
                ),
                child: TextField(
                  controller: _homeSearchController,
                  style: const TextStyle(color: Colors.white, fontSize: 15),
                  textInputAction: TextInputAction.go,
                  decoration: InputDecoration(
                    hintText: 'Search or enter website address',
                    hintStyle: const TextStyle(color: BrowserConstants.textSecondary),
                    prefixIcon: const Icon(Icons.search, color: Colors.white, size: 20),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.arrow_forward, color: Colors.white, size: 20),
                      onPressed: () {
                        final text = _homeSearchController.text.trim();
                        if (text.isNotEmpty) {
                          _homeSearchController.clear();
                          _controller.navigate(text);
                        }
                      },
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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

              // Monochrome Speed Dial Shortcuts
              Wrap(
                spacing: 16,
                runSpacing: 16,
                alignment: WrapAlignment.center,
                children: [
                  _buildSpeedDial('Google', 'https://www.google.com', Icons.search),
                  _buildSpeedDial('YouTube', 'https://www.youtube.com', Icons.play_arrow),
                  _buildSpeedDial('Wikipedia', 'https://www.wikipedia.org', Icons.menu_book),
                  _buildSpeedDial('Reddit', 'https://www.reddit.com', Icons.forum),
                  _buildSpeedDial('GitHub', 'https://www.github.com', Icons.code),
                  _buildSpeedDial('News', 'https://news.google.com', Icons.newspaper),
                ],
              ),

              const SizedBox(height: 28),

              // Privacy Status Monochrome Pill
              ListenableBuilder(
                listenable: AdGuardEngine.instance,
                builder: (context, _) {
                  final totalBlocked = AdGuardEngine.instance.statistics.totalBlocked;
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: BrowserConstants.surface,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: BrowserConstants.border),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.security, color: Colors.white, size: 16),
                        const SizedBox(width: 8),
                        Text(
                          '$totalBlocked Threats & Ads Blocked Locally',
                          style: const TextStyle(
                            color: Colors.white,
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

  Widget _buildSpeedDial(String name, String url, IconData icon) {
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
                color: BrowserConstants.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: BrowserConstants.borderLight, width: 1.2),
              ),
              child: Icon(icon, color: Colors.white, size: 22),
            ),
            const SizedBox(height: 6),
            Text(
              name,
              style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
