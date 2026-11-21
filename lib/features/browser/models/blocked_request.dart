import 'filter_rule.dart';

class BlockedRequest {
  final String id;
  final String url;
  final String domain;
  final FilterCategory category;
  final DateTime timestamp;
  final String ruleMatched;

  const BlockedRequest({
    required this.id,
    required this.url,
    required this.domain,
    required this.category,
    required this.timestamp,
    required this.ruleMatched,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'url': url,
      'domain': domain,
      'category': category.name,
      'timestamp': timestamp.toIso8601String(),
      'ruleMatched': ruleMatched,
    };
  }

  factory BlockedRequest.fromMap(Map<String, dynamic> map) {
    return BlockedRequest(
      id: map['id'] as String,
      url: map['url'] as String,
      domain: map['domain'] as String,
      category: FilterCategory.values.firstWhere(
        (e) => e.name == map['category'],
        orElse: () => FilterCategory.ads,
      ),
      timestamp: DateTime.parse(map['timestamp'] as String),
      ruleMatched: map['ruleMatched'] as String,
    );
  }
}
