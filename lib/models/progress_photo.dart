class ProgressPhoto {
  final int? id;
  final int userId;
  final String imagePath;
  final String? category; // front, side, back
  final String? notes;
  final double? weight;
  final DateTime takenAt;
  final DateTime createdAt;

  ProgressPhoto({
    this.id,
    required this.userId,
    required this.imagePath,
    this.category,
    this.notes,
    this.weight,
    DateTime? takenAt,
    DateTime? createdAt,
  })  : takenAt = takenAt ?? DateTime.now(),
        createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'image_path': imagePath,
      'category': category,
      'notes': notes,
      'weight': weight,
      'taken_at': takenAt.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory ProgressPhoto.fromMap(Map<String, dynamic> map) {
    return ProgressPhoto(
      id: map['id'] as int?,
      userId: map['user_id'] as int,
      imagePath: map['image_path'] as String,
      category: map['category'] as String?,
      notes: map['notes'] as String?,
      weight: map['weight'] != null ? (map['weight'] as num).toDouble() : null,
      takenAt: DateTime.parse(map['taken_at'] as String),
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  ProgressPhoto copyWith({
    int? id,
    int? userId,
    String? imagePath,
    String? category,
    String? notes,
    double? weight,
    DateTime? takenAt,
    DateTime? createdAt,
  }) {
    return ProgressPhoto(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      imagePath: imagePath ?? this.imagePath,
      category: category ?? this.category,
      notes: notes ?? this.notes,
      weight: weight ?? this.weight,
      takenAt: takenAt ?? this.takenAt,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
