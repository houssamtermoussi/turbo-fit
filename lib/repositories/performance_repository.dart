import 'package:sqflite/sqflite.dart';

import '../models/performance.dart';

class PerformanceRepository {
  PerformanceRepository(this._db);

  final Database _db;

  Future<List<ExercisePerformanceSummary>> getSummaries() async {
    final rows = await _db.rawQuery('''
      SELECT
        e.name AS name,
        s.performed_at AS performed_at,
        MAX(ss.weight) AS max_weight,
        SUM(ss.reps) AS total_reps,
        SUM(ss.weight * ss.reps) AS volume
      FROM session_sets ss
      INNER JOIN session_exercises e ON e.id = ss.exercise_id
      INNER JOIN sessions s ON s.id = e.session_id
      WHERE ss.weight > 0
      GROUP BY e.name, s.id, s.performed_at
      ORDER BY e.name COLLATE NOCASE ASC, s.performed_at ASC
    ''');

    final byName = <String, List<ExercisePerformancePoint>>{};
    for (final row in rows) {
      final name = (row['name'] as String).trim();
      if (name.isEmpty) continue;
      final point = ExercisePerformancePoint(
        date: DateTime.parse(row['performed_at'] as String),
        maxWeight: (row['max_weight'] as num?)?.toDouble() ?? 0,
        totalReps: (row['total_reps'] as num?)?.toInt() ?? 0,
        volume: (row['volume'] as num?)?.toDouble() ?? 0,
      );
      byName.putIfAbsent(name, () => []).add(point);
    }

    final summaries = byName.entries
        .map(
          (entry) => ExercisePerformanceSummary(
            name: entry.key,
            points: entry.value,
          ),
        )
        .toList();

    summaries.sort((a, b) {
      final aDate = a.latest?.date ?? DateTime.fromMillisecondsSinceEpoch(0);
      final bDate = b.latest?.date ?? DateTime.fromMillisecondsSinceEpoch(0);
      return bDate.compareTo(aDate);
    });
    return summaries;
  }
}
