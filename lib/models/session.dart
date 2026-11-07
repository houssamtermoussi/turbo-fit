class WorkoutSession {
  final int? id;
  final int programId;
  final String name;
  final int orderIndex;

  const WorkoutSession({
    this.id,
    required this.programId,
    required this.name,
    this.orderIndex = 0,
  });

  WorkoutSession copyWith({
    int? id,
    int? programId,
    String? name,
    int? orderIndex,
  }) {
    return WorkoutSession(
      id: id ?? this.id,
      programId: programId ?? this.programId,
      name: name ?? this.name,
      orderIndex: orderIndex ?? this.orderIndex,
    );
  }

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'program_id': programId,
      'name': name,
      'order_index': orderIndex,
    };
  }

  factory WorkoutSession.fromMap(Map<String, Object?> map) {
    return WorkoutSession(
      id: map['id'] as int?,
      programId: map['program_id'] as int,
      name: map['name'] as String,
      orderIndex: map['order_index'] as int? ?? 0,
    );
  }
}

class SessionExercise {
  final int? id;
  final int sessionId;
  final int exerciseId;
  final int targetSets;
  final int targetReps;
  final double? targetWeight;
  final String? exerciseName;
  final String? muscleGroup;

  const SessionExercise({
    this.id,
    required this.sessionId,
    required this.exerciseId,
    this.targetSets = 3,
    this.targetReps = 10,
    this.targetWeight,
    this.exerciseName,
    this.muscleGroup,
  });

  SessionExercise copyWith({
    int? id,
    int? sessionId,
    int? exerciseId,
    int? targetSets,
    int? targetReps,
    double? targetWeight,
    String? exerciseName,
    String? muscleGroup,
  }) {
    return SessionExercise(
      id: id ?? this.id,
      sessionId: sessionId ?? this.sessionId,
      exerciseId: exerciseId ?? this.exerciseId,
      targetSets: targetSets ?? this.targetSets,
      targetReps: targetReps ?? this.targetReps,
      targetWeight: targetWeight ?? this.targetWeight,
      exerciseName: exerciseName ?? this.exerciseName,
      muscleGroup: muscleGroup ?? this.muscleGroup,
    );
  }

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'session_id': sessionId,
      'exercise_id': exerciseId,
      'target_sets': targetSets,
      'target_reps': targetReps,
      'target_weight': targetWeight,
    };
  }

  factory SessionExercise.fromMap(Map<String, Object?> map) {
    return SessionExercise(
      id: map['id'] as int?,
      sessionId: map['session_id'] as int,
      exerciseId: map['exercise_id'] as int,
      targetSets: map['target_sets'] as int? ?? 3,
      targetReps: map['target_reps'] as int? ?? 10,
      targetWeight: (map['target_weight'] as num?)?.toDouble(),
      exerciseName: map['exercise_name'] as String?,
      muscleGroup: map['muscle_group'] as String?,
    );
  }
}
