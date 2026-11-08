import 'package:sqflite/sqflite.dart';

import '../models/session.dart';

class SessionRepository {
  SessionRepository(this._db);

  final Database _db;

  Future<List<WorkoutSession>> getAll() async {
    final rows = await _db.query(
      'sessions',
      orderBy: 'performed_at DESC, id DESC',
    );

    final sessions = <WorkoutSession>[];
    for (final row in rows) {
      final session = WorkoutSession.fromMap(row);
      final exercises = await _getExercises(session.id!);
      sessions.add(session.copyWith(exercises: exercises));
    }
    return sessions;
  }

  Future<WorkoutSession?> getById(int id) async {
    final rows = await _db.query(
      'sessions',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    final session = WorkoutSession.fromMap(rows.first);
    final exercises = await _getExercises(id);
    return session.copyWith(exercises: exercises);
  }

  Future<List<SessionExercise>> _getExercises(int sessionId) async {
    final rows = await _db.query(
      'session_exercises',
      where: 'session_id = ?',
      whereArgs: [sessionId],
      orderBy: 'order_index ASC, id ASC',
    );

    final exercises = <SessionExercise>[];
    for (final row in rows) {
      final exercise = SessionExercise.fromMap(row);
      final sets = await _db.query(
        'session_sets',
        where: 'exercise_id = ?',
        whereArgs: [exercise.id],
        orderBy: 'set_number ASC, id ASC',
      );
      exercises.add(
        exercise.copyWith(sets: sets.map(ExerciseSet.fromMap).toList()),
      );
    }
    return exercises;
  }

  Future<int> save(WorkoutSession session) async {
    return _db.transaction((txn) async {
      late final int sessionId;

      if (session.id == null) {
        sessionId = await txn.insert('sessions', session.toMap()..remove('id'));
      } else {
        sessionId = session.id!;
        await txn.update(
          'sessions',
          session.toMap()..remove('id'),
          where: 'id = ?',
          whereArgs: [sessionId],
        );
        final exerciseRows = await txn.query(
          'session_exercises',
          columns: ['id'],
          where: 'session_id = ?',
          whereArgs: [sessionId],
        );
        for (final row in exerciseRows) {
          await txn.delete(
            'session_sets',
            where: 'exercise_id = ?',
            whereArgs: [row['id']],
          );
        }
        await txn.delete(
          'session_exercises',
          where: 'session_id = ?',
          whereArgs: [sessionId],
        );
      }

      for (var i = 0; i < session.exercises.length; i++) {
        final exercise = session.exercises[i];
        final exerciseId = await txn.insert('session_exercises', {
          'session_id': sessionId,
          'name': exercise.name.trim(),
          'order_index': i,
        });

        for (var s = 0; s < exercise.sets.length; s++) {
          final set = exercise.sets[s];
          await txn.insert('session_sets', {
            'exercise_id': exerciseId,
            'set_number': s + 1,
            'reps': set.reps,
            'weight': set.weight,
          });
        }
      }

      return sessionId;
    });
  }

  Future<void> delete(int id) async {
    await _db.delete('sessions', where: 'id = ?', whereArgs: [id]);
  }
}
