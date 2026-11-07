class Goal {
  final int? id;
  final int exerciseId;
  final double targetWeight;
  final double currentBest;
  final DateTime createdAt;
  final String? exerciseName;

  const Goal({
    this.id,
    required this.exerciseId,
    required this.targetWeight,
    this.currentBest = 0,
    required this.createdAt,
    this.exerciseName,
  });

  double get progress {
    if (targetWeight <= 0) return 0;
    return (currentBest / targetWeight).clamp(0.0, 1.0);
  }

  int get progressPercent => (progress * 100).round();

  Goal copyWith({
    int? id,
    int? exerciseId,
    double? targetWeight,
    double? currentBest,
    DateTime? createdAt,
    String? exerciseName,
  }) {
    return Goal(
      id: id ?? this.id,
      exerciseId: exerciseId ?? this.exerciseId,
      targetWeight: targetWeight ?? this.targetWeight,
      currentBest: currentBest ?? this.currentBest,
      createdAt: createdAt ?? this.createdAt,
      exerciseName: exerciseName ?? this.exerciseName,
    );
  }

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'exercise_id': exerciseId,
      'target_weight': targetWeight,
      'current_best': currentBest,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory Goal.fromMap(Map<String, Object?> map) {
    return Goal(
      id: map['id'] as int?,
      exerciseId: map['exercise_id'] as int,
      targetWeight: (map['target_weight'] as num).toDouble(),
      currentBest: (map['current_best'] as num?)?.toDouble() ?? 0,
      createdAt: DateTime.parse(map['created_at'] as String),
      exerciseName: map['exercise_name'] as String?,
    );
  }
}
