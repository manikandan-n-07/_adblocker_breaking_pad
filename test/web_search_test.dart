import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:browser/features/browser/utils/url_helper.dart';
import 'package:browser/features/browser/utils/browser_constants.dart';
import 'package:browser/features/browser/webview/browser_controller.dart';
import 'package:browser/features/browser/engine/adguard_engine.dart';
import 'package:browser/features/browser/engine/filter_rule_manager.dart';
import 'package:browser/features/browser/engine/network_filter.dart';
import 'package:browser/features/browser/engine/request_statistics.dart';
import 'package:browser/features/browser/engine/adguard_filter_rules.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Web Search Integration Tests', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('UrlHelper generates correct query URL for all configured search engines', () {
      const query = 'breaking bad cast';

      for (final entry in BrowserConstants.searchEngines.entries) {
        final engineName = entry.key;
        final template = entry.value;

        final result = UrlHelper.sanitizeOrSearchUrl(query, searchEngineTemplate: template);
        expect(result, isNot(equals('about:blank')), reason: 'Engine $engineName failed');
        expect(result.contains('breaking%20bad%20cast'), isTrue, reason: 'Engine $engineName missing query');
      }
    });

    test('BrowserController navigates plain queries to active search engine', () async {
      final controller = BrowserController();
      await controller.init();

      // Default is Google
      controller.navigate('flutter inappwebview');
      expect(controller.currentTab?.url, equals('https://www.google.com/search?q=flutter%20inappwebview'));

      // Switch to DuckDuckGo
      await controller.setSearchEngine('DuckDuckGo');
      controller.navigate('privacy browser');
      expect(controller.currentTab?.url, equals('https://duckduckgo.com/?q=privacy%20browser'));

      // Switch to Bing
      await controller.setSearchEngine('Bing');
      controller.navigate('microsoft');
      expect(controller.currentTab?.url, equals('https://www.bing.com/search?q=microsoft'));

      // Switch to Brave
      await controller.setSearchEngine('Brave');
      controller.navigate('brave search');
      expect(controller.currentTab?.url, equals('https://search.brave.com/search?q=brave%20search'));

      // Switch to Ecosia
      await controller.setSearchEngine('Ecosia');
      controller.navigate('trees');
      expect(controller.currentTab?.url, equals('https://www.ecosia.org/search?q=trees'));
    });

    test('BrowserController handles empty or blank navigation to return home', () async {
      final controller = BrowserController();
      await controller.init();

      controller.navigate('test search');
      expect(controller.currentTab?.url.isNotEmpty, isTrue);

      controller.navigate('');
      expect(controller.currentTab?.url, equals(''));
      expect(controller.currentTab?.webViewController, isNull);
    });

    test('NetworkFilter allows all search engine domains and query URLs', () {
      final ruleManager = FilterRuleManager();
      final stats = RequestStatistics();
      final filter = NetworkFilter(ruleManager: ruleManager, statistics: stats);

      ruleManager.adDomains.addAll(AdGuardFilterRules.defaultAdDomains);
      ruleManager.trackerDomains.addAll(AdGuardFilterRules.defaultTrackerDomains);

      final searchUrls = [
        'https://www.google.com/search?q=test',
        'https://google.com/search?q=hello+world',
        'https://duckduckgo.com/?q=test',
        'https://www.bing.com/search?q=test',
        'https://bing.com/search?q=test',
        'https://search.brave.com/search?q=test',
        'https://www.ecosia.org/search?q=test',
        'https://www.google.com/complete/search?client=chrome&q=test',
      ];

      for (final url in searchUrls) {
        final result = filter.shouldBlockUrl(url);
        expect(result.isBlocked, isFalse, reason: 'URL unexpectedly blocked: $url');
      }
    });

    test('AdGuardEngine interceptRequest never blocks main frame document requests', () {
      final engine = AdGuardEngine.instance;

      final mainFrameReq = WebResourceRequest(
        url: WebUri('https://www.google.com/search?q=test'),
        isForMainFrame: true,
      );

      final response = engine.interceptRequest(mainFrameReq);
      expect(response, isNull, reason: 'Main frame document must never be intercepted with empty body');
    });
  });
}
