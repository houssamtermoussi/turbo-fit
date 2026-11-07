class WorkoutLog {
  final int? id;
  final int sessionId;
  final DateTime performedAt;
  final String notes;
  final String? sessionName;

  const WorkoutLog({
    this.id,
    required this.sessionId,
    required this.performedAt,
    this.notes = '',
    this.sessionName,
  });

  WorkoutLog copyWith({
    int? id,
    int? sessionId,
    DateTime? performedAt,
    String? notes,
    String? sessionName,
  }) {
    return WorkoutLog(
      id: id ?? this.id,
      sessionId: sessionId ?? this.sessionId,
      performedAt: performedAt ?? this.performedAt,
      notes: notes ?? this.notes,
      sessionName: sessionName ?? this.sessionName,
    );
  }

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'session_id': sessionId,
      'performed_at': performedAt.toIso8601String(),
      'notes': notes,
    };
  }

  factory WorkoutLog.fromMap(Map<String, Object?> map) {
    return WorkoutLog(
      id: map['id'] as int?,
      sessionId: map['session_id'] as int,
      performedAt: DateTime.parse(map['performed_at'] as String),
      notes: (map['notes'] as String?) ?? '',
      sessionName: map['session_name'] as String?,
    );
  }
}

class SetLog {
  final int? id;
  final int workoutLogId;
  final int exerciseId;
  final int setNumber;
  final int reps;
  final double weight;

  const SetLog({
    this.id,
    required this.workoutLogId,
    required this.exerciseId,
    required this.setNumber,
    required this.reps,
    required this.weight,
  });

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'workout_log_id': workoutLogId,
      'exercise_id': exerciseId,
      'set_number': setNumber,
      'reps': reps,
      'weight': weight,
    };
  }

  factory SetLog.fromMap(Map<String, Object?> map) {
    return SetLog(
      id: map['id'] as int?,
      workoutLogId: map['workout_log_id'] as int,
      exerciseId: map['exercise_id'] as int,
      setNumber: map['set_number'] as int,
      reps: map['reps'] as int,
      weight: (map['weight'] as num).toDouble(),
    );
  }
}

class ProgressPoint {
  final DateTime date;
  final double maxWeight;
  final double volume;

  const ProgressPoint({
    required this.date,
    required this.maxWeight,
    required this.volume,
  });
}
