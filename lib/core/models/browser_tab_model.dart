class BrowserTabModel {
  final String id;
  String title;
  String url;
  String? favicon;
  final bool isPrivate;
  String? groupId;
  DateTime lastAccessedAt;

  BrowserTabModel({
    required this.id,
    this.title = 'New Tab',
    this.url = 'about:blank',
    this.favicon,
    this.isPrivate = false,
    this.groupId,
    DateTime? lastAccessedAt,
  }) : lastAccessedAt = lastAccessedAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'url': url,
      'favicon': favicon,
      'isPrivate': isPrivate,
      'groupId': groupId,
      'lastAccessedAt': lastAccessedAt.toIso8601String(),
    };
  }

  factory BrowserTabModel.fromMap(Map<dynamic, dynamic> map) {
    return BrowserTabModel(
      id: map['id'] as String? ?? DateTime.now().millisecondsSinceEpoch.toString(),
      title: map['title'] as String? ?? 'New Tab',
      url: map['url'] as String? ?? 'about:blank',
      favicon: map['favicon'] as String?,
      isPrivate: map['isPrivate'] as bool? ?? false,
      groupId: map['groupId'] as String?,
      lastAccessedAt: map['lastAccessedAt'] != null
          ? DateTime.tryParse(map['lastAccessedAt'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}
