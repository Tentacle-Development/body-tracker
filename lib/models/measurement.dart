class Measurement {
  final int? id;
  final int userId;
  final String type;
  final double value;
  final String unit;
  final DateTime measuredAt;
  final DateTime createdAt;

  Measurement({
    this.id,
    required this.userId,
    required this.type,
    required this.value,
    required this.unit,
    DateTime? measuredAt,
    DateTime? createdAt,
  })  : measuredAt = measuredAt ?? DateTime.now(),
        createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'type': type,
      'value': value,
      'unit': unit,
      'measured_at': measuredAt.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory Measurement.fromMap(Map<String, dynamic> map) {
    return Measurement(
      id: map['id'] as int?,
      userId: map['user_id'] as int,
      type: map['type'] as String,
      value: (map['value'] as num).toDouble(),
      unit: map['unit'] as String,
      measuredAt: DateTime.parse(map['measured_at'] as String),
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  Measurement copyWith({
    int? id,
    int? userId,
    String? type,
    double? value,
    String? unit,
    DateTime? measuredAt,
    DateTime? createdAt,
  }) {
    return Measurement(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      type: type ?? this.type,
      value: value ?? this.value,
      unit: unit ?? this.unit,
      measuredAt: measuredAt ?? this.measuredAt,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
