class BookmarkModel {
  final String id;
  String title;
  String url;
  String? favicon;
  String folder;
  final DateTime createdAt;

  BookmarkModel({
    required this.id,
    required this.title,
    required this.url,
    this.favicon,
    this.folder = 'Default',
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'url': url,
      'favicon': favicon,
      'folder': folder,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory BookmarkModel.fromMap(Map<dynamic, dynamic> map) {
    return BookmarkModel(
      id: map['id'] as String,
      title: map['title'] as String? ?? 'Untitled',
      url: map['url'] as String? ?? '',
      favicon: map['favicon'] as String?,
      folder: map['folder'] as String? ?? 'Default',
      createdAt: map['createdAt'] != null
          ? DateTime.tryParse(map['createdAt'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}
