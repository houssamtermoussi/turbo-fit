import 'package:sqflite/sqflite.dart';

import '../models/workout_log.dart';

class WorkoutRepository {
  WorkoutRepository(this._db);

  final Database _db;

  Future<int> saveWorkout({
    required int sessionId,
    required DateTime performedAt,
    String notes = '',
    required List<SetLog> sets,
  }) async {
    return _db.transaction((txn) async {
      final workoutId = await txn.insert('workout_logs', {
        'session_id': sessionId,
        'performed_at': performedAt.toIso8601String(),
        'notes': notes,
      });

      for (final set in sets) {
        await txn.insert('set_logs', {
          'workout_log_id': workoutId,
          'exercise_id': set.exerciseId,
          'set_number': set.setNumber,
          'reps': set.reps,
          'weight': set.weight,
        });
      }

      // Refresh goals' current_best for involved exercises
      final exerciseIds = sets.map((s) => s.exerciseId).toSet();
      for (final exerciseId in exerciseIds) {
        final maxRow = await txn.rawQuery('''
          SELECT MAX(weight) AS best
          FROM set_logs
          WHERE exercise_id = ?
        ''', [exerciseId]);
        final best = (maxRow.first['best'] as num?)?.toDouble() ?? 0;
        await txn.update(
          'goals',
          {'current_best': best},
          where: 'exercise_id = ?',
          whereArgs: [exerciseId],
        );
      }

      return workoutId;
    });
  }

  Future<WorkoutLog?> getLastWorkout() async {
    final rows = await _db.rawQuery('''
      SELECT wl.*, s.name AS session_name
      FROM workout_logs wl
      JOIN sessions s ON s.id = wl.session_id
      ORDER BY wl.performed_at DESC
      LIMIT 1
    ''');
    if (rows.isEmpty) return null;
    return WorkoutLog.fromMap(rows.first);
  }

  Future<List<WorkoutLog>> getRecent({int limit = 20}) async {
    final rows = await _db.rawQuery('''
      SELECT wl.*, s.name AS session_name
      FROM workout_logs wl
      JOIN sessions s ON s.id = wl.session_id
      ORDER BY wl.performed_at DESC
      LIMIT ?
    ''', [limit]);
    return rows.map(WorkoutLog.fromMap).toList();
  }

  Future<int?> getLastCompletedSessionId(int programId) async {
    final rows = await _db.rawQuery('''
      SELECT wl.session_id
      FROM workout_logs wl
      JOIN sessions s ON s.id = wl.session_id
      WHERE s.program_id = ?
      ORDER BY wl.performed_at DESC
      LIMIT 1
    ''', [programId]);
    if (rows.isEmpty) return null;
    return rows.first['session_id'] as int?;
  }

  Future<List<ProgressPoint>> getProgressForExercise(int exerciseId) async {
    final rows = await _db.rawQuery('''
      SELECT
        date(wl.performed_at) AS day,
        MAX(sl.weight) AS max_weight,
        SUM(sl.weight * sl.reps) AS volume
      FROM set_logs sl
      JOIN workout_logs wl ON wl.id = sl.workout_log_id
      WHERE sl.exercise_id = ?
      GROUP BY day
      ORDER BY day ASC
    ''', [exerciseId]);

    return rows.map((row) {
      return ProgressPoint(
        date: DateTime.parse(row['day'] as String),
        maxWeight: (row['max_weight'] as num).toDouble(),
        volume: (row['volume'] as num).toDouble(),
      );
    }).toList();
  }

  Future<double> getBestWeight(int exerciseId) async {
    final rows = await _db.rawQuery('''
      SELECT MAX(weight) AS best FROM set_logs WHERE exercise_id = ?
    ''', [exerciseId]);
    return (rows.first['best'] as num?)?.toDouble() ?? 0;
  }
}
