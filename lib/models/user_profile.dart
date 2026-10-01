class UserProfile {
  final String userId;
  final String name;
  final int age;
  final String email;
  final DateTime joinedArcDate;
  final DateTime arcStartDate;
  final DateTime arcEndDate;
  final int targetDays;
  final int currentStreak;

  UserProfile({
    required this.userId,
    required this.name,
    required this.age,
    required this.email,
    DateTime? joinedArcDate,
    DateTime? arcStartDate,
    DateTime? arcEndDate,
    int? targetDays,
    this.currentStreak = 0,
  })  : joinedArcDate = joinedArcDate ?? DateTime.now(),
        arcStartDate = arcStartDate ?? DateTime(DateTime.now().year, 10, 1),
        arcEndDate = arcEndDate ?? DateTime(DateTime.now().year + 1, 1, 1),
        targetDays = targetDays ?? 90;

  int get totalArcDays {
    final diff = arcEndDate.difference(arcStartDate).inDays;
    return diff <= 0 ? targetDays : diff;
  }

  int get currentArcDay {
    final now = DateTime.now();
    if (now.isBefore(arcStartDate)) return 1;
    final diff = now.difference(arcStartDate).inDays + 1;
    return diff > totalArcDays ? totalArcDays : diff;
  }

  int get daysRemaining {
    final now = DateTime.now();
    final diff = arcEndDate.difference(now).inDays;
    return diff < 0 ? 0 : diff;
  }

  double get arcProgressRatio {
    if (totalArcDays == 0) return 0.0;
    return (currentArcDay / totalArcDays).clamp(0.0, 1.0);
  }

  int get daysIntoArc => currentArcDay;

  String get rankTitle {
    if (currentStreak >= 60) return 'Winter Legend ❄️👑';
    if (currentStreak >= 30) return 'Glacier Beast 🧊⚡';
    if (currentStreak >= 14) return 'Iron Discipline 🛡️';
    if (currentStreak >= 7) return 'Frost Warrior ⚔️';
    if (currentStreak >= 3) return 'Cold Blood ❄️';
    return 'Arc Initiate 🐺';
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'name': name,
      'age': age,
      'email': email,
      'joinedArcDate': joinedArcDate.toIso8601String(),
      'arcStartDate': arcStartDate.toIso8601String(),
      'arcEndDate': arcEndDate.toIso8601String(),
      'targetDays': totalArcDays,
      'currentStreak': currentStreak,
    };
  }

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    DateTime parseDate(dynamic val, DateTime fallback) {
      if (val == null) return fallback;
      return DateTime.tryParse(val.toString()) ?? fallback;
    }

    final start = parseDate(json['arcStartDate'], DateTime(DateTime.now().year, 10, 1));
    final end = parseDate(json['arcEndDate'], DateTime(DateTime.now().year + 1, 1, 1));

    return UserProfile(
      userId: json['userId'] ?? '',
      name: json['name'] ?? 'Warrior',
      age: json['age'] is int ? json['age'] : int.tryParse('${json['age']}') ?? 20,
      email: json['email'] ?? '',
      joinedArcDate: parseDate(json['joinedArcDate'], DateTime.now()),
      arcStartDate: start,
      arcEndDate: end,
      targetDays: json['targetDays'] ?? 90,
      currentStreak: json['currentStreak'] ?? 0,
    );
  }

  UserProfile copyWith({
    String? userId,
    String? name,
    int? age,
    String? email,
    DateTime? joinedArcDate,
    DateTime? arcStartDate,
    DateTime? arcEndDate,
    int? targetDays,
    int? currentStreak,
  }) {
    return UserProfile(
      userId: userId ?? this.userId,
      name: name ?? this.name,
      age: age ?? this.age,
      email: email ?? this.email,
      joinedArcDate: joinedArcDate ?? this.joinedArcDate,
      arcStartDate: arcStartDate ?? this.arcStartDate,
      arcEndDate: arcEndDate ?? this.arcEndDate,
      targetDays: targetDays ?? this.targetDays,
      currentStreak: currentStreak ?? this.currentStreak,
    );
  }
}
