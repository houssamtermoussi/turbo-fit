class BodyWeightLog {
  final int? id;
  final DateTime weighedAt;
  final double weight;

  const BodyWeightLog({
    this.id,
    required this.weighedAt,
    required this.weight,
  });

  BodyWeightLog copyWith({
    int? id,
    DateTime? weighedAt,
    double? weight,
  }) {
    return BodyWeightLog(
      id: id ?? this.id,
      weighedAt: weighedAt ?? this.weighedAt,
      weight: weight ?? this.weight,
    );
  }

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'weighed_at': weighedAt.toIso8601String(),
      'weight': weight,
    };
  }

  factory BodyWeightLog.fromMap(Map<String, Object?> map) {
    return BodyWeightLog(
      id: map['id'] as int?,
      weighedAt: DateTime.parse(map['weighed_at'] as String),
      weight: (map['weight'] as num).toDouble(),
    );
  }
}

class WeightGoal {
  final int? id;
  final double startWeight;
  final double targetWeight;
  final DateTime createdAt;

  const WeightGoal({
    this.id,
    required this.startWeight,
    required this.targetWeight,
    required this.createdAt,
  });

  bool get isLoss => targetWeight < startWeight;

  double progressRatio(double? currentWeight) {
    if (currentWeight == null) return 0;
    final total = (startWeight - targetWeight).abs();
    if (total == 0) return currentWeight == targetWeight ? 1 : 0;
    final done = isLoss
        ? (startWeight - currentWeight).clamp(0, total)
        : (currentWeight - startWeight).clamp(0, total);
    return (done / total).clamp(0, 1);
  }

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'start_weight': startWeight,
      'target_weight': targetWeight,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory WeightGoal.fromMap(Map<String, Object?> map) {
    return WeightGoal(
      id: map['id'] as int?,
      startWeight: (map['start_weight'] as num).toDouble(),
      targetWeight: (map['target_weight'] as num).toDouble(),
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }
}
