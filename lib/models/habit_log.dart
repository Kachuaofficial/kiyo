class HabitLog {
  final String id;
  final String habitId;
  final String userId;
  final String date; // Format: YYYY-MM-DD
  final bool completed;
  final DateTime? completedAt;
  final String note; // Reflection, exercises done, pages read, details

  HabitLog({
    required this.id,
    required this.habitId,
    required this.userId,
    required this.date,
    this.completed = true,
    this.completedAt,
    this.note = '',
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'habitId': habitId,
      'userId': userId,
      'date': date,
      'completed': completed,
      'completedAt': completedAt?.toIso8601String(),
      'note': note,
    };
  }

  factory HabitLog.fromJson(Map<String, dynamic> json) {
    return HabitLog(
      id: json['id'] ?? json['\$id'] ?? '',
      habitId: json['habitId'] ?? '',
      userId: json['userId'] ?? '',
      date: json['date'] ?? '',
      completed: json['completed'] == true,
      completedAt: json['completedAt'] != null
          ? DateTime.tryParse(json['completedAt'])
          : null,
      note: json['note'] ?? '',
    );
  }

  HabitLog copyWith({
    String? id,
    String? habitId,
    String? userId,
    String? date,
    bool? completed,
    DateTime? completedAt,
    String? note,
  }) {
    return HabitLog(
      id: id ?? this.id,
      habitId: habitId ?? this.habitId,
      userId: userId ?? this.userId,
      date: date ?? this.date,
      completed: completed ?? this.completed,
      completedAt: completedAt ?? this.completedAt,
      note: note ?? this.note,
    );
  }

  static String dateKey(DateTime dt) {
    final year = dt.year.toString().padLeft(4, '0');
    final month = dt.month.toString().padLeft(2, '0');
    final day = dt.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }
}
