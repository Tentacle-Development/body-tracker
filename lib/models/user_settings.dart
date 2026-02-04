class UserSettings {
  final int? id;
  final int userId;
  final int reminderIntervalDays;
  final String preferredUnitSystem;
  final DateTime createdAt;
  final DateTime updatedAt;

  UserSettings({
    this.id,
    required this.userId,
    this.reminderIntervalDays = 30,
    this.preferredUnitSystem = 'metric',
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'reminder_interval_days': reminderIntervalDays,
      'preferred_unit_system': preferredUnitSystem,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory UserSettings.fromMap(Map<String, dynamic> map) {
    return UserSettings(
      id: map['id'] as int?,
      userId: map['user_id'] as int,
      reminderIntervalDays: map['reminder_interval_days'] as int? ?? 30,
      preferredUnitSystem: map['preferred_unit_system'] as String? ?? 'metric',
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  UserSettings copyWith({
    int? id,
    int? userId,
    int? reminderIntervalDays,
    String? preferredUnitSystem,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserSettings(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      reminderIntervalDays: reminderIntervalDays ?? this.reminderIntervalDays,
      preferredUnitSystem: preferredUnitSystem ?? this.preferredUnitSystem,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
