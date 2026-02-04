class Goal {
  final int? id;
  final int userId;
  final String type; // weight, waist, etc.
  final double startValue;
  final double targetValue;
  final DateTime startDate;
  final DateTime targetDate;
  final bool isCompleted;
  final DateTime createdAt;

  Goal({
    this.id,
    required this.userId,
    required this.type,
    required this.startValue,
    required this.targetValue,
    required this.startDate,
    required this.targetDate,
    this.isCompleted = false,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'type': type,
      'start_value': startValue,
      'target_value': targetValue,
      'start_date': startDate.toIso8601String(),
      'target_date': targetDate.toIso8601String(),
      'is_completed': isCompleted ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory Goal.fromMap(Map<String, dynamic> map) {
    return Goal(
      id: map['id'] as int?,
      userId: map['user_id'] as int,
      type: map['type'] as String,
      startValue: (map['start_value'] as num).toDouble(),
      targetValue: (map['target_value'] as num).toDouble(),
      startDate: DateTime.parse(map['start_date'] as String),
      targetDate: DateTime.parse(map['target_date'] as String),
      isCompleted: (map['is_completed'] as int) == 1,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  Goal copyWith({
    int? id,
    int? userId,
    String? type,
    double? startValue,
    double? targetValue,
    DateTime? startDate,
    DateTime? targetDate,
    bool? isCompleted,
    DateTime? createdAt,
  }) {
    return Goal(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      type: type ?? this.type,
      startValue: startValue ?? this.startValue,
      targetValue: targetValue ?? this.targetValue,
      startDate: startDate ?? this.startDate,
      targetDate: targetDate ?? this.targetDate,
      isCompleted: isCompleted ?? this.isCompleted,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
