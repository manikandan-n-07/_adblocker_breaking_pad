import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'adguard_scriptlets.dart';
import 'cosmetic_filter.dart';
import 'filter_rule_manager.dart';
import 'network_filter.dart';
import 'popup_protection.dart';
import 'request_statistics.dart';

class AdGuardEngine extends ChangeNotifier {
  static final AdGuardEngine instance = AdGuardEngine._internal();

  AdGuardEngine._internal() {
    ruleManager = FilterRuleManager();
    statistics = RequestStatistics();
    networkFilter = NetworkFilter(ruleManager: ruleManager, statistics: statistics);
    cosmeticFilter = CosmeticFilter(ruleManager: ruleManager);
    popupProtection = PopupProtection(ruleManager: ruleManager, statistics: statistics);

    ruleManager.addListener(_onStateChange);
    statistics.addListener(_onStateChange);
  }

  late final FilterRuleManager ruleManager;
  late final RequestStatistics statistics;
  late final NetworkFilter networkFilter;
  late final CosmeticFilter cosmeticFilter;
  late final PopupProtection popupProtection;

  bool _initialized = false;
  bool get isInitialized => _initialized;

  void _onStateChange() {
    notifyListeners();
  }

  Future<void> init() async {
    if (_initialized) return;
    try {
      await statistics.init();
      await ruleManager.init();
    } catch (e) {
      debugPrint('AdGuardEngine init non-fatal error: $e');
    }
    _initialized = true;
    notifyListeners();
  }

  /// Builds UserScripts for document start injection (Cosmetic CSS + Scriptlets)
  List<UserScript> getUserScripts({String? currentDomain}) {
    final scripts = <UserScript>[];

    // Scriptlets (Anti-adblock evasion, YouTube ad mitigation, popup wrapper)
    final scriptletJs = AdGuardScriptlets.getDocumentStartScript(
      enableYouTubeMitigation: ruleManager.isYouTubeBlockingEnabled,
      enablePopupProtection: ruleManager.isPopupBlockingEnabled,
    );

    scripts.add(
      UserScript(
        source: scriptletJs,
        injectionTime: UserScriptInjectionTime.AT_DOCUMENT_START,
        forMainFrameOnly: false,
      ),
    );

    // Cosmetic filtering: inject CSS stylesheet dynamically
    final css = cosmeticFilter.buildCssRules(domain: currentDomain);
    if (css.isNotEmpty) {
      final encodedCss = jsonEncode(css);
      final cssInjectionJs = '''
        (function() {
          function addAdBlockStyle() {
            if (document.getElementById('__breaking_pad_adblock_css')) return;
            const style = document.createElement('style');
            style.id = '__breaking_pad_adblock_css';
            style.type = 'text/css';
            style.textContent = $encodedCss;
            const target = document.head || document.documentElement;
            if (target) {
              target.appendChild(style);
            }
          }
          addAdBlockStyle();
          if (document.readyState === 'loading') {
            document.addEventListener('DOMContentLoaded', addAdBlockStyle);
          }
        })();
      ''';

      scripts.add(
        UserScript(
          source: cssInjectionJs,
          injectionTime: UserScriptInjectionTime.AT_DOCUMENT_START,
          forMainFrameOnly: false,
        ),
      );
    }

    // Dynamic MutationObserver for dynamically added ads
    final mutationJs = cosmeticFilter.buildMutationObserverJs(domain: currentDomain);
    if (mutationJs.isNotEmpty) {
      scripts.add(
        UserScript(
          source: mutationJs,
          injectionTime: UserScriptInjectionTime.AT_DOCUMENT_END,
          forMainFrameOnly: false,
        ),
      );
    }

    return scripts;
  }

  /// Injects active cosmetic cleanup dynamically into the running WebView page.
  /// Used during onLoadStart, onProgressChanged, and onLoadStop to guarantee zero ad flash.
  Future<void> injectCosmeticCleanup(InAppWebViewController controller, {String? domain}) async {
    if (!ruleManager.isCosmeticFilteringEnabled) return;
    if (domain != null && ruleManager.isDomainAllowlisted(domain)) return;

    try {
      final css = cosmeticFilter.buildCssRules(domain: domain);
      if (css.isNotEmpty) {
        await controller.injectCSSCode(source: css);
      }
      final cleanupJs = cosmeticFilter.buildCleanupSnippetJs(domain: domain);
      if (cleanupJs.isNotEmpty) {
        await controller.evaluateJavascript(source: cleanupJs);
      }
    } catch (_) {}
  }

  /// Intercepts network requests in Android WebView (shouldInterceptRequest callback).
  /// If the URL is determined to be an ad or tracker, returns an empty 200 HTTP response.
  WebResourceResponse? interceptRequest(WebResourceRequest request, {String? pageUrl}) {
    // Never intercept main frame document loads with an empty response
    if (request.isForMainFrame == true) {
      return null;
    }

    final url = request.url.toString();
    final result = networkFilter.shouldBlockUrl(url, pageUrl: pageUrl);

    if (result.isBlocked) {
      // Empty 200 OK response with 0 data — avoids WebView hanging/timeout bugs with 204
      return WebResourceResponse(
        contentType: 'text/plain',
        contentEncoding: 'utf-8',
        statusCode: 200,
        reasonPhrase: 'OK',
        headers: {'Access-Control-Allow-Origin': '*'},
        data: Uint8List(0),
      );
    }
    return null;
  }

  @override
  void dispose() {
    ruleManager.removeListener(_onStateChange);
    statistics.removeListener(_onStateChange);
    super.dispose();
  }
}
