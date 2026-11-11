class TabGroupModel {
  final String id;
  String name;
  int colorValue;
  final DateTime createdAt;

  TabGroupModel({
    required this.id,
    required this.name,
    this.colorValue = 0xFF2196F3,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'colorValue': colorValue,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory TabGroupModel.fromMap(Map<dynamic, dynamic> map) {
    return TabGroupModel(
      id: map['id'] as String,
      name: map['name'] as String? ?? 'Group',
      colorValue: map['colorValue'] as int? ?? 0xFF2196F3,
      createdAt: map['createdAt'] != null
          ? DateTime.tryParse(map['createdAt'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}
