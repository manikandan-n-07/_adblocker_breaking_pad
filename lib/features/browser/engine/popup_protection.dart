import 'filter_rule_manager.dart';
import 'request_statistics.dart';
import '../models/filter_rule.dart';
import '../utils/url_helper.dart';

class PopupProtection {
  final FilterRuleManager ruleManager;
  final RequestStatistics statistics;

  // Track rapid popups to detect popup floods
  final List<DateTime> _recentOpenTimes = [];

  PopupProtection({
    required this.ruleManager,
    required this.statistics,
  });

  /// Evaluates whether an external window / popup request should be allowed or blocked.
  bool shouldBlockPopup(String? targetUrl, {String? sourceUrl}) {
    if (!ruleManager.isPopupBlockingEnabled) return false;

    // Check allowlist
    if (sourceUrl != null) {
      final sourceDomain = UrlHelper.extractDomain(sourceUrl);
      if (ruleManager.isDomainAllowlisted(sourceDomain)) {
        return false;
      }
    }

    if (targetUrl == null || targetUrl.isEmpty || targetUrl == 'about:blank') {
      return false;
    }

    final now = DateTime.now();
    _recentOpenTimes.removeWhere((dt) => now.difference(dt).inSeconds > 3);
    _recentOpenTimes.add(now);

    // If more than 3 window opens occur in 3 seconds, block as rapid popup flood
    if (_recentOpenTimes.length > 3) {
      statistics.recordBlockedRequest(
        url: targetUrl,
        domain: UrlHelper.extractDomain(targetUrl),
        category: FilterCategory.popups,
        ruleMatched: 'popup_rate_limit',
      );
      return true;
    }

    final targetDomain = UrlHelper.extractDomain(targetUrl);
    final lowerUrl = targetUrl.toLowerCase();

    if (lowerUrl.contains('popup') ||
        lowerUrl.contains('popunder') ||
        lowerUrl.contains('adclick') ||
        lowerUrl.contains('onclickads')) {
      statistics.recordBlockedRequest(
        url: targetUrl,
        domain: targetDomain,
        category: FilterCategory.popups,
        ruleMatched: 'popup_url_pattern',
      );
      return true;
    }

    return false;
  }
}
