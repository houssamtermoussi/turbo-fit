class ExercisePerformancePoint {
  final DateTime date;
  final double maxWeight;
  final int totalReps;
  final double volume;

  const ExercisePerformancePoint({
    required this.date,
    required this.maxWeight,
    required this.totalReps,
    required this.volume,
  });
}

class ExercisePerformanceSummary {
  final String name;
  final List<ExercisePerformancePoint> points;

  const ExercisePerformanceSummary({
    required this.name,
    required this.points,
  });

  ExercisePerformancePoint? get latest =>
      points.isEmpty ? null : points.last;

  ExercisePerformancePoint? get previous =>
      points.length < 2 ? null : points[points.length - 2];

  double? get weightDelta {
    final a = previous;
    final b = latest;
    if (a == null || b == null) return null;
    return b.maxWeight - a.maxWeight;
  }
}
