class DashboardShortcutModel {
  final String id;
  String title;
  String url;
  String? favicon;
  int position;

  DashboardShortcutModel({
    required this.id,
    required this.title,
    required this.url,
    this.favicon,
    this.position = 0,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'url': url,
      'favicon': favicon,
      'position': position,
    };
  }

  factory DashboardShortcutModel.fromMap(Map<dynamic, dynamic> map) {
    return DashboardShortcutModel(
      id: map['id'] as String,
      title: map['title'] as String? ?? 'Shortcut',
      url: map['url'] as String? ?? 'https://google.com',
      favicon: map['favicon'] as String?,
      position: map['position'] as int? ?? 0,
    );
  }
}
