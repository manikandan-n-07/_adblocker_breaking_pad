import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:browser/features/browser/engine/adguard_filter_rules.dart';
import 'package:browser/features/browser/engine/filter_list_parser.dart';
import 'package:browser/features/browser/engine/filter_rule_manager.dart';
import 'package:browser/features/browser/engine/network_filter.dart';
import 'package:browser/features/browser/engine/request_statistics.dart';
import 'package:browser/features/browser/engine/cosmetic_filter.dart';
import 'package:browser/features/browser/engine/adguard_scriptlets.dart';
import 'package:browser/features/browser/engine/popup_protection.dart';
import 'package:browser/features/browser/models/filter_rule.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AdGuard Rule Parser Tests', () {
    test('Parses network block domain rule ||example.com^', () {
      final rule = FilterListParser.parseRule('||example.com^');
      expect(rule, isNotNull);
      expect(rule!.ruleType, equals(FilterRuleType.networkBlock));
      expect(rule.targetDomain, equals('example.com'));
    });

    test('Parses exception allowlist rule @@||example.com^', () {
      final rule = FilterListParser.parseRule('@@||goodsite.com^');
      expect(rule, isNotNull);
      expect(rule!.ruleType, equals(FilterRuleType.networkAllow));
      expect(rule.targetDomain, equals('goodsite.com'));
    });

    test('Parses cosmetic filter ##.ad-banner', () {
      final rule = FilterListParser.parseRule('##.ad-banner');
      expect(rule, isNotNull);
      expect(rule!.ruleType, equals(FilterRuleType.cosmeticHide));
      expect(rule.rawPattern, equals('.ad-banner'));
      expect(rule.targetDomain, isNull);
    });

    test('Parses site-specific cosmetic filter example.com##.sponsor-card', () {
      final rule = FilterListParser.parseRule('example.com##.sponsor-card');
      expect(rule, isNotNull);
      expect(rule!.ruleType, equals(FilterRuleType.cosmeticHide));
      expect(rule.rawPattern, equals('.sponsor-card'));
      expect(rule.targetDomain, equals('example.com'));
    });

    test('Ignores comments and empty lines', () {
      expect(FilterListParser.parseRule('! This is a comment'), isNull);
      expect(FilterListParser.parseRule('[Adblock Plus 2.0]'), isNull);
      expect(FilterListParser.parseRule('   '), isNull);
    });
  });

  group('AdGuard Network Filter Engine Tests', () {
    late FilterRuleManager ruleManager;
    late RequestStatistics statistics;
    late NetworkFilter networkFilter;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      ruleManager = FilterRuleManager();
      statistics = RequestStatistics();
      networkFilter = NetworkFilter(ruleManager: ruleManager, statistics: statistics);

      // Seed test rules into ruleManager in-memory
      ruleManager.adDomains.addAll(AdGuardFilterRules.defaultAdDomains);
      ruleManager.trackerDomains.addAll(AdGuardFilterRules.defaultTrackerDomains);
      for (final p in AdGuardFilterRules.defaultYouTubeAdPatterns) {
        ruleManager.youtubeUrlRegexes.add(AdGuardFilterRules.wildcardToRegex(p));
      }
    });

    test('Blocks known ad networks (doubleclick, googlesyndication, etc.)', () {
      final res1 = networkFilter.shouldBlockUrl('https://ad.doubleclick.net/pagead/ads?test=1');
      expect(res1.isBlocked, isTrue);
      expect(res1.category, equals(FilterCategory.ads));

      final res2 = networkFilter.shouldBlockUrl('https://pagead2.googlesyndication.com/pagead/show_ads.js');
      expect(res2.isBlocked, isTrue);

      final res3 = networkFilter.shouldBlockUrl('https://cdn.taboola.com/libtrc/unip/loader.js');
      expect(res3.isBlocked, isTrue);

      final res4 = networkFilter.shouldBlockUrl('https://ade.clmbtech.com/c/v/123');
      expect(res4.isBlocked, isTrue);

      final res5 = networkFilter.shouldBlockUrl('https://static.colombiaonline.com/js/colombia.js');
      expect(res5.isBlocked, isTrue);
    });

    test('Blocks known trackers (google-analytics, hotjar, etc.)', () {
      final res = networkFilter.shouldBlockUrl('https://www.google-analytics.com/analytics.js');
      expect(res.isBlocked, isTrue);
      expect(res.category, equals(FilterCategory.trackers));

      final res2 = networkFilter.shouldBlockUrl('https://static.hotjar.com/c/hotjar-123.js');
      expect(res2.isBlocked, isTrue);
      expect(res2.category, equals(FilterCategory.trackers));
    });

    test('Mitigates known YouTube ad endpoints', () {
      final res1 = networkFilter.shouldBlockUrl(
        'https://www.youtube.com/pagead/parallel?test=1',
        pageUrl: 'https://www.youtube.com/watch?v=123',
      );
      expect(res1.isBlocked, isTrue);
      expect(res1.category, equals(FilterCategory.youtube));

      final res2 = networkFilter.shouldBlockUrl(
        'https://www.youtube.com/api/stats/ads?ns=yt',
        pageUrl: 'https://www.youtube.com/watch?v=123',
      );
      expect(res2.isBlocked, isTrue);
      expect(res2.category, equals(FilterCategory.youtube));
    });

    test('Does NOT block legitimate non-ad websites and search engines', () {
      expect(networkFilter.shouldBlockUrl('https://www.google.com').isBlocked, isFalse);
      expect(networkFilter.shouldBlockUrl('https://www.google.com/search?q=flutter').isBlocked, isFalse);
      expect(networkFilter.shouldBlockUrl('https://duckduckgo.com/?q=flutter').isBlocked, isFalse);
      expect(networkFilter.shouldBlockUrl('https://www.bing.com/search?q=flutter').isBlocked, isFalse);
      expect(networkFilter.shouldBlockUrl('https://search.brave.com/search?q=flutter').isBlocked, isFalse);
      expect(networkFilter.shouldBlockUrl('https://www.ecosia.org/search?q=flutter').isBlocked, isFalse);
      expect(networkFilter.shouldBlockUrl('https://en.wikipedia.org/wiki/Flutter').isBlocked, isFalse);
      expect(networkFilter.shouldBlockUrl('https://github.com/flutter/flutter').isBlocked, isFalse);
    });

    test('Allows allowlisted domains even if matching ad domain', () async {
      await ruleManager.toggleDomainAllowlist('doubleclick.net');
      expect(ruleManager.isDomainAllowlisted('doubleclick.net'), isTrue);

      final res = networkFilter.shouldBlockUrl('https://ad.doubleclick.net/test');
      expect(res.isBlocked, isFalse);
    });

    test('Correctly increments actual statistics when requests blocked', () {
      final initialTotal = statistics.totalBlocked;
      final initialAds = statistics.adsBlocked;

      networkFilter.shouldBlockUrl('https://ad.doubleclick.net/test');

      expect(statistics.totalBlocked, equals(initialTotal + 1));
      expect(statistics.adsBlocked, equals(initialAds + 1));
      expect(statistics.recentBlocked.isNotEmpty, isTrue);
      expect(statistics.recentBlocked.first.domain, contains('doubleclick.net'));
    });
  });

  group('Cosmetic Filter & Scriptlets Tests', () {
    test('Builds valid CSS stylesheet', () {
      final manager = FilterRuleManager();
      manager.cosmeticSelectors.addAll(['.ad-banner', '.adsbygoogle', 'ytd-ad-slot-renderer']);
      final cosmetic = CosmeticFilter(ruleManager: manager);

      final css = cosmetic.buildCssRules();
      expect(css.contains('.ad-banner'), isTrue);
      expect(css.contains('display: none !important'), isTrue);
      expect(css.contains('background-image: none !important'), isTrue);

      final cleanupJs = cosmetic.buildCleanupSnippetJs();
      expect(cleanupJs.contains('display'), isTrue);
      expect(cleanupJs.contains('advertisement'), isTrue);
    });

    test('Builds Document Start Scriptlet with anti-adblock and youtube mitigations', () {
      final script = AdGuardScriptlets.getDocumentStartScript(
        enableYouTubeMitigation: true,
        enablePopupProtection: true,
      );

      expect(script.contains('window.canRunAds = true'), isTrue);
      expect(script.contains('window.adsbygoogle'), isTrue);
      expect(script.contains('cleanYouTubeData'), isTrue);
      expect(script.contains('ytp-ad-skip-button'), isTrue);
    });
  });

  group('Popup Protection Tests', () {
    test('Blocks known popup spam URLs', () {
      final manager = FilterRuleManager();
      final stats = RequestStatistics();
      final popupGuard = PopupProtection(ruleManager: manager, statistics: stats);

      expect(popupGuard.shouldBlockPopup('https://onclickads.net/popup?id=1'), isTrue);
      expect(popupGuard.shouldBlockPopup('https://legitimate-site.org'), isFalse);
    });
  });
}
