import '../models/filter_rule.dart';
import '../utils/url_helper.dart';
import 'adguard_filter_rules.dart';
import 'filter_rule_manager.dart';
import 'request_statistics.dart';

class FilterResult {
  final bool isBlocked;
  final FilterCategory category;
  final String ruleMatched;

  const FilterResult({
    required this.isBlocked,
    this.category = FilterCategory.ads,
    this.ruleMatched = '',
  });

  static const FilterResult allowed = FilterResult(isBlocked: false);
}

class NetworkFilter {
  final FilterRuleManager ruleManager;
  final RequestStatistics statistics;

  NetworkFilter({
    required this.ruleManager,
    required this.statistics,
  });

  /// Evaluates whether a requested network [url] should be blocked.
  /// [pageUrl] is the URL of the containing web page (for allowlisting & third-party checks).
  FilterResult shouldBlockUrl(String url, {String? pageUrl}) {
    if (url.isEmpty || url.startsWith('data:') || url.startsWith('blob:') || url.startsWith('file:')) {
      return FilterResult.allowed;
    }

    final requestDomain = UrlHelper.extractDomain(url);
    final pageDomain = pageUrl != null ? UrlHelper.extractDomain(pageUrl) : '';

    // Check allowlist: if current website or request domain is allowlisted, allow immediately
    if (pageDomain.isNotEmpty && ruleManager.isDomainAllowlisted(pageDomain)) {
      return FilterResult.allowed;
    }
    if (requestDomain.isNotEmpty && ruleManager.isDomainAllowlisted(requestDomain)) {
      return FilterResult.allowed;
    }

    // Layer 1.1: YouTube specific endpoint filtering
    if (ruleManager.isYouTubeBlockingEnabled &&
        (pageDomain.contains('youtube.com') || requestDomain.contains('youtube.com') || requestDomain.contains('googlevideo.com'))) {
      for (final pattern in ruleManager.youtubeUrlRegexes) {
        if (pattern.hasMatch(url)) {
          final result = FilterResult(
            isBlocked: true,
            category: FilterCategory.youtube,
            ruleMatched: pattern.pattern,
          );
          statistics.recordBlockedRequest(
            url: url,
            domain: requestDomain,
            category: FilterCategory.youtube,
            ruleMatched: pattern.pattern,
          );
          return result;
        }
      }
    }

    // Layer 1.2: General Ads Network domain matching
    if (ruleManager.isAdBlockingEnabled && requestDomain.isNotEmpty) {
      if (AdGuardFilterRules.matchesDomain(requestDomain, ruleManager.adDomains)) {
        final result = FilterResult(
          isBlocked: true,
          category: FilterCategory.ads,
          ruleMatched: '||$requestDomain^',
        );
        statistics.recordBlockedRequest(
          url: url,
          domain: requestDomain,
          category: FilterCategory.ads,
          ruleMatched: '||$requestDomain^',
        );
        return result;
      }

      // Check ad URL regexes
      for (final regex in ruleManager.adUrlRegexes) {
        if (regex.hasMatch(url)) {
          final result = FilterResult(
            isBlocked: true,
            category: FilterCategory.ads,
            ruleMatched: regex.pattern,
          );
          statistics.recordBlockedRequest(
            url: url,
            domain: requestDomain,
            category: FilterCategory.ads,
            ruleMatched: regex.pattern,
          );
          return result;
        }
      }
    }

    // Layer 1.3: Trackers & Analytics
    if (ruleManager.isTrackerBlockingEnabled && requestDomain.isNotEmpty) {
      if (AdGuardFilterRules.matchesDomain(requestDomain, ruleManager.trackerDomains)) {
        final result = FilterResult(
          isBlocked: true,
          category: FilterCategory.trackers,
          ruleMatched: '||$requestDomain^',
        );
        statistics.recordBlockedRequest(
          url: url,
          domain: requestDomain,
          category: FilterCategory.trackers,
          ruleMatched: '||$requestDomain^',
        );
        return result;
      }

      // Check tracker URL regexes
      for (final regex in ruleManager.trackerUrlRegexes) {
        if (regex.hasMatch(url)) {
          final result = FilterResult(
            isBlocked: true,
            category: FilterCategory.trackers,
            ruleMatched: regex.pattern,
          );
          statistics.recordBlockedRequest(
            url: url,
            domain: requestDomain,
            category: FilterCategory.trackers,
            ruleMatched: regex.pattern,
          );
          return result;
        }
      }
    }

    // Layer 1.4: Popups and popunders
    if (ruleManager.isPopupBlockingEnabled && requestDomain.isNotEmpty) {
      if (AdGuardFilterRules.matchesDomain(requestDomain, ruleManager.popupDomains)) {
        final result = FilterResult(
          isBlocked: true,
          category: FilterCategory.popups,
          ruleMatched: '||$requestDomain^',
        );
        statistics.recordBlockedRequest(
          url: url,
          domain: requestDomain,
          category: FilterCategory.popups,
          ruleMatched: '||$requestDomain^',
        );
        return result;
      }
    }

    return FilterResult.allowed;
  }
}
