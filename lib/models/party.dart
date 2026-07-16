
class Party {
  final int? id;
  final String name;
  final String? photoPath;
  final DateTime createdAt;

  Party({
    this.id,
    required this.name,
    this.photoPath,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'photo_path': photoPath,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory Party.fromMap(Map<String, dynamic> map) {
    return Party(
      id: map['id'] as int?,
      name: map['name'] as String,
      photoPath: map['photo_path'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }
}