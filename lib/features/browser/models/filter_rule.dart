enum FilterCategory {
  ads,
  trackers,
  youtube,
  popups,
  cosmetic,
  custom,
}

enum FilterRuleType {
  networkBlock,
  networkAllow,
  cosmeticHide,
  scriptlet,
}

class FilterRule {
  final String id;
  final String rawPattern;
  final FilterRuleType ruleType;
  final FilterCategory category;
  final String? targetDomain;
  final bool isRegex;
  final bool isThirdPartyOnly;
  final bool enabled;

  const FilterRule({
    required this.id,
    required this.rawPattern,
    required this.ruleType,
    required this.category,
    this.targetDomain,
    this.isRegex = false,
    this.isThirdPartyOnly = false,
    this.enabled = true,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'rawPattern': rawPattern,
      'ruleType': ruleType.index,
      'category': category.index,
      'targetDomain': targetDomain,
      'isRegex': isRegex ? 1 : 0,
      'isThirdPartyOnly': isThirdPartyOnly ? 1 : 0,
      'enabled': enabled ? 1 : 0,
    };
  }

  factory FilterRule.fromMap(Map<String, dynamic> map) {
    return FilterRule(
      id: map['id'] as String,
      rawPattern: map['rawPattern'] as String,
      ruleType: FilterRuleType.values[map['ruleType'] as int],
      category: FilterCategory.values[map['category'] as int],
      targetDomain: map['targetDomain'] as String?,
      isRegex: (map['isRegex'] as int?) == 1,
      isThirdPartyOnly: (map['isThirdPartyOnly'] as int?) == 1,
      enabled: (map['enabled'] as int?) == 1,
    );
  }

  FilterRule copyWith({
    String? id,
    String? rawPattern,
    FilterRuleType? ruleType,
    FilterCategory? category,
    String? targetDomain,
    bool? isRegex,
    bool? isThirdPartyOnly,
    bool? enabled,
  }) {
    return FilterRule(
      id: id ?? this.id,
      rawPattern: rawPattern ?? this.rawPattern,
      ruleType: ruleType ?? this.ruleType,
      category: category ?? this.category,
      targetDomain: targetDomain ?? this.targetDomain,
      isRegex: isRegex ?? this.isRegex,
      isThirdPartyOnly: isThirdPartyOnly ?? this.isThirdPartyOnly,
      enabled: enabled ?? this.enabled,
    );
  }
}
