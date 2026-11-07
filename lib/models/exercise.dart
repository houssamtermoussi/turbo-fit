class Exercise {
  final int? id;
  final String name;
  final String muscleGroup;

  const Exercise({
    this.id,
    required this.name,
    required this.muscleGroup,
  });

  Exercise copyWith({
    int? id,
    String? name,
    String? muscleGroup,
  }) {
    return Exercise(
      id: id ?? this.id,
      name: name ?? this.name,
      muscleGroup: muscleGroup ?? this.muscleGroup,
    );
  }

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'name': name,
      'muscle_group': muscleGroup,
    };
  }

  factory Exercise.fromMap(Map<String, Object?> map) {
    return Exercise(
      id: map['id'] as int?,
      name: map['name'] as String,
      muscleGroup: map['muscle_group'] as String,
    );
  }
}
