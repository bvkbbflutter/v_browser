class HistoryModel {
  final String id;
  final String title;
  final String url;
  final String? favicon;
  final DateTime visitedAt;

  HistoryModel({
    required this.id,
    required this.title,
    required this.url,
    this.favicon,
    DateTime? visitedAt,
  }) : visitedAt = visitedAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'url': url,
      'favicon': favicon,
      'visitedAt': visitedAt.toIso8601String(),
    };
  }

  factory HistoryModel.fromMap(Map<dynamic, dynamic> map) {
    return HistoryModel(
      id: map['id'] as String,
      title: map['title'] as String? ?? 'Untitled',
      url: map['url'] as String? ?? '',
      favicon: map['favicon'] as String?,
      visitedAt: map['visitedAt'] != null
          ? DateTime.tryParse(map['visitedAt'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}
