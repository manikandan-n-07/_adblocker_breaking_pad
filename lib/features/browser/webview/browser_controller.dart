import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/browser_tab.dart';
import '../services/history_service.dart';
import '../utils/browser_constants.dart';
import '../utils/url_helper.dart';

class BrowserController extends ChangeNotifier {
  static const String _prefSavedSession = 'pref_saved_browser_session';

  final List<BrowserTab> _tabs = [];
  int _currentTabIndex = 0;
  String _homepage = BrowserConstants.defaultHomepage;
  String _searchEngine = 'Google';

  BrowserController() {
    // Synchronously seed initial tab so BrowserScreen renders INSTANTLY on frame 1
    _tabs.add(BrowserTab(
      id: 'tab_init_${DateTime.now().millisecondsSinceEpoch}',
      url: '',
      title: 'New Tab',
    ));
  }

  List<BrowserTab> get tabs => List.unmodifiable(_tabs);
  int get currentTabIndex => _currentTabIndex;
  BrowserTab? get currentTab => (_tabs.isNotEmpty && _currentTabIndex >= 0 && _currentTabIndex < _tabs.length)
      ? _tabs[_currentTabIndex]
      : null;
  String get homepage => _homepage;
  String get searchEngine => _searchEngine;

  int get regularTabsCount => _tabs.where((t) => !t.isIncognito).length;
  int get privateTabsCount => _tabs.where((t) => t.isIncognito).length;

  Future<void> init() async {
    await _loadPreferences();
    notifyListeners();
  }

  Future<void> _loadPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _homepage = prefs.getString('pref_browser_homepage') ?? BrowserConstants.defaultHomepage;
      _searchEngine = prefs.getString('pref_browser_search_engine') ?? 'Google';

      // Restore session tabs if available
      final savedTabsJson = prefs.getStringList(_prefSavedSession);
      if (savedTabsJson != null && savedTabsJson.isNotEmpty) {
        _tabs.clear();
        for (final item in savedTabsJson) {
          try {
            final map = jsonDecode(item) as Map<String, dynamic>;
            final url = map['url'] as String? ?? _homepage;
            final title = map['title'] as String? ?? 'New Tab';
            final isDesktop = map['isDesktop'] as bool? ?? false;
            _tabs.add(BrowserTab(
              id: 'tab_${DateTime.now().microsecondsSinceEpoch}_${_tabs.length}',
              url: url,
              title: title,
              isDesktopMode: isDesktop,
            ));
          } catch (_) {}
        }
        if (_tabs.isEmpty) {
          _tabs.add(BrowserTab(
            id: 'tab_${DateTime.now().microsecondsSinceEpoch}',
            url: _homepage,
            title: 'New Tab',
          ));
        }
        _currentTabIndex = 0;
      }
    } catch (e) {
      debugPrint('BrowserController load preferences error: $e');
    }
  }

  Future<void> setHomepage(String url) async {
    _homepage = url;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('pref_browser_homepage', url);
    notifyListeners();
  }

  Future<void> setSearchEngine(String engine) async {
    _searchEngine = engine;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('pref_browser_search_engine', engine);
    notifyListeners();
  }

  /// Adds a new tab and switches to it
  BrowserTab addNewTab({
    String? url,
    bool isIncognito = false,
  }) {
    final newTab = BrowserTab(
      id: 'tab_${DateTime.now().microsecondsSinceEpoch}',
      url: url ?? (isIncognito ? 'about:blank' : _homepage),
      title: isIncognito ? 'Private Tab' : 'New Tab',
      isIncognito: isIncognito,
    );

    _tabs.add(newTab);
    _currentTabIndex = _tabs.length - 1;
    _saveSession();
    notifyListeners();
    return newTab;
  }

  /// Switches active tab
  void switchTab(int index) {
    if (index >= 0 && index < _tabs.length) {
      _currentTabIndex = index;
      notifyListeners();
    }
  }

  /// Closes a tab
  void closeTab(int index) {
    if (index < 0 || index >= _tabs.length) return;

    final closedTab = _tabs[index];
    closedTab.webViewController = null;
    _tabs.removeAt(index);

    if (_tabs.isEmpty) {
      addNewTab(url: _homepage);
    } else {
      if (_currentTabIndex >= _tabs.length) {
        _currentTabIndex = _tabs.length - 1;
      }
    }

    _saveSession();
    notifyListeners();
  }

  /// Closes all regular or private tabs
  void closeAllTabs({bool incognitoOnly = false}) {
    if (incognitoOnly) {
      _tabs.removeWhere((t) {
        if (t.isIncognito) {
          t.webViewController = null;
          return true;
        }
        return false;
      });
      if (_tabs.isEmpty) {
        addNewTab(url: _homepage);
      } else {
        _currentTabIndex = 0;
      }
    } else {
      for (final t in _tabs) {
        t.webViewController = null;
      }
      _tabs.clear();
      addNewTab(url: _homepage);
    }
    _saveSession();
    notifyListeners();
  }

  /// Duplicates current tab
  void duplicateCurrentTab() {
    final cur = currentTab;
    if (cur != null) {
      addNewTab(url: cur.url, isIncognito: cur.isIncognito);
    }
  }

  /// Navigate active tab
  void navigate(String queryOrUrl) {
    final cur = currentTab;
    if (cur == null) return;

    final trimmed = queryOrUrl.trim();
    if (trimmed.isEmpty || trimmed == 'about:blank') {
      cur.url = '';
      cur.webViewController = null;
      _saveSession();
      notifyListeners();
      return;
    }

    final template = BrowserConstants.searchEngines[_searchEngine] ??
        BrowserConstants.searchEngines['Google']!;
    final destination = UrlHelper.sanitizeOrSearchUrl(trimmed, searchEngineTemplate: template);

    cur.url = destination;
    if (cur.webViewController != null) {
      cur.webViewController!.loadUrl(
        urlRequest: URLRequest(url: WebUri(destination)),
      );
    }
    notifyListeners();
  }

  /// Toggle desktop mode for active tab
  void toggleDesktopMode() {
    final cur = currentTab;
    if (cur == null) return;

    cur.isDesktopMode = !cur.isDesktopMode;
    final ua = cur.isDesktopMode
        ? BrowserConstants.desktopUserAgent
        : BrowserConstants.mobileUserAgent;

    cur.webViewController?.setSettings(
      settings: InAppWebViewSettings(
        userAgent: ua,
        useWideViewPort: cur.isDesktopMode,
        loadWithOverviewMode: cur.isDesktopMode,
      ),
    );
    cur.webViewController?.reload();
    _saveSession();
    notifyListeners();
  }

  /// Update tab state from WebView callbacks
  void updateTabUrl(BrowserTab tab, String newUrl) {
    tab.url = newUrl;
    tab.canGoBack = false;
    tab.canGoForward = false;
    tab.webViewController?.canGoBack().then((can) {
      tab.canGoBack = can;
      notifyListeners();
    });
    tab.webViewController?.canGoForward().then((can) {
      tab.canGoForward = can;
      notifyListeners();
    });
    notifyListeners();
  }

  void updateTabTitle(BrowserTab tab, String title) {
    if (title.isNotEmpty) {
      tab.title = title;
      if (!tab.isIncognito && tab.url.isNotEmpty && tab.url != 'about:blank') {
        HistoryService.instance.addEntry(
          title: title,
          url: tab.url,
          favicon: tab.favicon,
          isIncognito: false,
        );
      }
      _saveSession();
      notifyListeners();
    }
  }

  void updateTabProgress(BrowserTab tab, double progress) {
    tab.progress = progress;
    tab.isLoading = progress < 1.0;
    notifyListeners();
  }

  void incrementTabBlockedCount(BrowserTab tab) {
    tab.blockedCount++;
    notifyListeners();
  }

  Future<void> _saveSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = _tabs
          .where((t) => !t.isIncognito && t.url.isNotEmpty && t.url != 'about:blank')
          .map((t) => jsonEncode({
                'url': t.url,
                'title': t.title,
                'isDesktop': t.isDesktopMode,
              }))
          .toList();
      await prefs.setStringList(_prefSavedSession, list);
    } catch (_) {}
  }
}
