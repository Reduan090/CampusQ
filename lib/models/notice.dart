class Notice {
  final String id;
  final String title;
  final String content;
  final DateTime createdAt;
  final String createdBy;
  final bool isActive;

  Notice({
    required this.id,
    required this.title,
    required this.content,
    required this.createdAt,
    required this.createdBy,
    this.isActive = true,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'createdAt': createdAt.toIso8601String(),
      'createdBy': createdBy,
      'isActive': isActive,
    };
  }

  factory Notice.fromMap(Map<String, dynamic> map) {
    return Notice(
      id: map['id'] as String,
      title: map['title'] as String,
      content: map['content'] as String,
      createdAt: DateTime.parse(map['createdAt'] as String),
      createdBy: map['createdBy'] as String,
      isActive: map['isActive'] as bool? ?? true,
    );
  }

  Notice copyWith({
    String? id,
    String? title,
    String? content,
    DateTime? createdAt,
    String? createdBy,
    bool? isActive,
  }) {
    return Notice(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      createdAt: createdAt ?? this.createdAt,
      createdBy: createdBy ?? this.createdBy,
      isActive: isActive ?? this.isActive,
    );
  }
}
