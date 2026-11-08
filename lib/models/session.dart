class ExerciseSet {
  final int? id;
  final int setNumber;
  final int reps;
  final double weight;

  const ExerciseSet({
    this.id,
    required this.setNumber,
    required this.reps,
    this.weight = 0,
  });

  ExerciseSet copyWith({
    int? id,
    int? setNumber,
    int? reps,
    double? weight,
  }) {
    return ExerciseSet(
      id: id ?? this.id,
      setNumber: setNumber ?? this.setNumber,
      reps: reps ?? this.reps,
      weight: weight ?? this.weight,
    );
  }

  Map<String, Object?> toMap(int exerciseId) {
    return {
      'id': id,
      'exercise_id': exerciseId,
      'set_number': setNumber,
      'reps': reps,
      'weight': weight,
    };
  }

  factory ExerciseSet.fromMap(Map<String, Object?> map) {
    return ExerciseSet(
      id: map['id'] as int?,
      setNumber: map['set_number'] as int,
      reps: map['reps'] as int,
      weight: (map['weight'] as num?)?.toDouble() ?? 0,
    );
  }
}

class SessionExercise {
  final int? id;
  final String name;
  final int orderIndex;
  final List<ExerciseSet> sets;

  const SessionExercise({
    this.id,
    required this.name,
    this.orderIndex = 0,
    this.sets = const [],
  });

  SessionExercise copyWith({
    int? id,
    String? name,
    int? orderIndex,
    List<ExerciseSet>? sets,
  }) {
    return SessionExercise(
      id: id ?? this.id,
      name: name ?? this.name,
      orderIndex: orderIndex ?? this.orderIndex,
      sets: sets ?? this.sets,
    );
  }

  factory SessionExercise.fromMap(Map<String, Object?> map) {
    return SessionExercise(
      id: map['id'] as int?,
      name: map['name'] as String,
      orderIndex: map['order_index'] as int? ?? 0,
    );
  }
}

class WorkoutSession {
  final int? id;
  final DateTime performedAt;
  final String notes;
  final String? photoPath;
  final List<SessionExercise> exercises;

  const WorkoutSession({
    this.id,
    required this.performedAt,
    this.notes = '',
    this.photoPath,
    this.exercises = const [],
  });

  int get exerciseCount => exercises.length;

  int get totalSets =>
      exercises.fold(0, (sum, exercise) => sum + exercise.sets.length);

  WorkoutSession copyWith({
    int? id,
    DateTime? performedAt,
    String? notes,
    String? photoPath,
    bool clearPhoto = false,
    List<SessionExercise>? exercises,
  }) {
    return WorkoutSession(
      id: id ?? this.id,
      performedAt: performedAt ?? this.performedAt,
      notes: notes ?? this.notes,
      photoPath: clearPhoto ? null : (photoPath ?? this.photoPath),
      exercises: exercises ?? this.exercises,
    );
  }

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'performed_at': performedAt.toIso8601String(),
      'notes': notes,
      'photo_path': photoPath,
    };
  }

  factory WorkoutSession.fromMap(Map<String, Object?> map) {
    return WorkoutSession(
      id: map['id'] as int?,
      performedAt: DateTime.parse(map['performed_at'] as String),
      notes: (map['notes'] as String?) ?? '',
      photoPath: map['photo_path'] as String?,
    );
  }
}
