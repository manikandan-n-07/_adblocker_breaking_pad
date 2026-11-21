class BrowserHistoryEntry {
  final int? id;
  final String title;
  final String url;
  final DateTime visitedAt;
  final String? favicon;

  const BrowserHistoryEntry({
    this.id,
    required this.title,
    required this.url,
    required this.visitedAt,
    this.favicon,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'title': title,
      'url': url,
      'visitedAt': visitedAt.millisecondsSinceEpoch,
      'favicon': favicon,
    };
  }

  factory BrowserHistoryEntry.fromMap(Map<String, dynamic> map) {
    return BrowserHistoryEntry(
      id: map['id'] as int?,
      title: map['title'] as String? ?? 'Untitled',
      url: map['url'] as String,
      visitedAt: DateTime.fromMillisecondsSinceEpoch(map['visitedAt'] as int),
      favicon: map['favicon'] as String?,
    );
  }
}
