class Bookmark {
  final int? id;
  final String title;
  final String url;
  final String folder;
  final DateTime createdAt;
  final String? favicon;

  const Bookmark({
    this.id,
    required this.title,
    required this.url,
    this.folder = 'Favorites',
    required this.createdAt,
    this.favicon,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'title': title,
      'url': url,
      'folder': folder,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'favicon': favicon,
    };
  }

  factory Bookmark.fromMap(Map<String, dynamic> map) {
    return Bookmark(
      id: map['id'] as int?,
      title: map['title'] as String? ?? 'Untitled',
      url: map['url'] as String,
      folder: map['folder'] as String? ?? 'Favorites',
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt'] as int),
      favicon: map['favicon'] as String?,
    );
  }

  Bookmark copyWith({
    int? id,
    String? title,
    String? url,
    String? folder,
    DateTime? createdAt,
    String? favicon,
  }) {
    return Bookmark(
      id: id ?? this.id,
      title: title ?? this.title,
      url: url ?? this.url,
      folder: folder ?? this.folder,
      createdAt: createdAt ?? this.createdAt,
      favicon: favicon ?? this.favicon,
    );
  }
}
