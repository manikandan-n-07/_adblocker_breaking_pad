import '../models/filter_rule.dart';

/// Parses AdGuard and uBlock style filter rule lines.
/// Examples:
///   ||example.com^           -> Network Block domain
///   @@||example.com^         -> Network Allow domain
///   ||example.com/ads/*      -> Network Pattern Block
///   ##.ad-banner             -> Cosmetic Hide (Global)
///   example.com##.ad-banner  -> Cosmetic Hide (Site Specific)
///   ! Comment line           -> Ignored
class FilterListParser {
  /// Parses multiple lines of filter rules into structured FilterRule objects.
  static List<FilterRule> parseRuleList(
    String content, {
    FilterCategory defaultCategory = FilterCategory.ads,
  }) {
    final rules = <FilterRule>[];
    final lines = content.split('\n');

    for (int i = 0; i < lines.length; i++) {
      final line = lines[i].trim();
      if (line.isEmpty || line.startsWith('!') || line.startsWith('[')) {
        continue; // Comment or header
      }

      final parsed = parseRule(line, defaultCategory: defaultCategory, id: 'rule_$i');
      if (parsed != null) {
        rules.add(parsed);
      }
    }

    return rules;
  }

  /// Parses a single rule line.
  static FilterRule? parseRule(
    String line, {
    FilterCategory defaultCategory = FilterCategory.ads,
    String? id,
  }) {
    final trimmed = line.trim();
    if (trimmed.isEmpty || trimmed.startsWith('!') || trimmed.startsWith('[')) {
      return null;
    }

    final ruleId = id ?? 'rule_${DateTime.now().microsecondsSinceEpoch}';

    // 1. Cosmetic Filter: contains '##' or '#?#' or '#@#'
    if (trimmed.contains('##')) {
      final parts = trimmed.split('##');
      final domain = parts[0].trim();
      final selector = parts[1].trim();

      return FilterRule(
        id: ruleId,
        rawPattern: selector,
        ruleType: FilterRuleType.cosmeticHide,
        category: FilterCategory.cosmetic,
        targetDomain: domain.isEmpty ? null : domain,
      );
    }

    // 2. Exception / Allowlist Rule: starts with '@@'
    if (trimmed.startsWith('@@')) {
      var pattern = trimmed.substring(2);
      var isThirdParty = false;

      if (pattern.contains(r'$')) {
        final parts = pattern.split(r'$');
        pattern = parts[0];
        if (parts[1].contains('third-party')) {
          isThirdParty = true;
        }
      }

      // Domain anchor '||'
      String? domain;
      if (pattern.startsWith('||')) {
        domain = pattern.substring(2).replaceAll('^', '');
      }

      return FilterRule(
        id: ruleId,
        rawPattern: pattern,
        ruleType: FilterRuleType.networkAllow,
        category: defaultCategory,
        targetDomain: domain,
        isThirdPartyOnly: isThirdParty,
      );
    }

    // 3. Network Block Rule
    var pattern = trimmed;
    var isThirdParty = false;
    FilterCategory category = defaultCategory;

    if (pattern.contains(r'$')) {
      final parts = pattern.split(r'$');
      pattern = parts[0];
      final options = parts[1].split(',');
      for (final opt in options) {
        if (opt.trim() == 'third-party') {
          isThirdParty = true;
        } else if (opt.trim() == 'script') {
          category = FilterCategory.ads;
        } else if (opt.trim() == 'image') {
          category = FilterCategory.ads;
        }
      }
    }

    String? targetDomain;
    if (pattern.startsWith('||')) {
      targetDomain = pattern.substring(2).replaceAll('^', '');
    }

    final isRegex = pattern.startsWith('/') && pattern.endsWith('/');

    return FilterRule(
      id: ruleId,
      rawPattern: pattern,
      ruleType: FilterRuleType.networkBlock,
      category: category,
      targetDomain: targetDomain,
      isRegex: isRegex,
      isThirdPartyOnly: isThirdParty,
    );
  }
}
