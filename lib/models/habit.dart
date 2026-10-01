class Habit {
  final String id;
  final String userId;
  final String title;
  final String description;
  final String category;
  final String icon;
  final bool isDefault;
  final DateTime createdAt;
  final int streak;

  Habit({
    required this.id,
    required this.userId,
    required this.title,
    this.description = '',
    this.category = 'Discipline',
    this.icon = '❄️',
    this.isDefault = false,
    DateTime? createdAt,
    this.streak = 0,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'title': title,
      'description': description,
      'category': category,
      'icon': icon,
      'isDefault': isDefault,
      'createdAt': createdAt.toIso8601String(),
      'streak': streak,
    };
  }

  factory Habit.fromJson(Map<String, dynamic> json) {
    return Habit(
      id: json['id'] ?? json['\$id'] ?? '',
      userId: json['userId'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      category: json['category'] ?? 'Discipline',
      icon: json['icon'] ?? '❄️',
      isDefault: json['isDefault'] == true,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt']) ?? DateTime.now()
          : DateTime.now(),
      streak: json['streak'] is int ? json['streak'] : int.tryParse('${json['streak']}') ?? 0,
    );
  }

  Habit copyWith({
    String? id,
    String? userId,
    String? title,
    String? description,
    String? category,
    String? icon,
    bool? isDefault,
    DateTime? createdAt,
    int? streak,
  }) {
    return Habit(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      icon: icon ?? this.icon,
      isDefault: isDefault ?? this.isDefault,
      createdAt: createdAt ?? this.createdAt,
      streak: streak ?? this.streak,
    );
  }
}
