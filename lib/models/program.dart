class Program {
  final int? id;
  final String name;
  final String notes;
  final bool isActive;

  const Program({
    this.id,
    required this.name,
    this.notes = '',
    this.isActive = false,
  });

  Program copyWith({
    int? id,
    String? name,
    String? notes,
    bool? isActive,
  }) {
    return Program(
      id: id ?? this.id,
      name: name ?? this.name,
      notes: notes ?? this.notes,
      isActive: isActive ?? this.isActive,
    );
  }

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'name': name,
      'notes': notes,
      'is_active': isActive ? 1 : 0,
    };
  }

  factory Program.fromMap(Map<String, Object?> map) {
    return Program(
      id: map['id'] as int?,
      name: map['name'] as String,
      notes: (map['notes'] as String?) ?? '',
      isActive: (map['is_active'] as int? ?? 0) == 1,
    );
  }
}
