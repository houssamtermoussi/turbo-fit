import 'package:sqflite/sqflite.dart';

import '../models/program.dart';
import '../models/session.dart';

class ProgramRepository {
  ProgramRepository(this._db);

  final Database _db;

  Future<List<Program>> getAll() async {
    final rows = await _db.query('programs', orderBy: 'name ASC');
    return rows.map(Program.fromMap).toList();
  }

  Future<Program?> getActive() async {
    final rows = await _db.query(
      'programs',
      where: 'is_active = 1',
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return Program.fromMap(rows.first);
  }

  Future<Program?> getById(int id) async {
    final rows = await _db.query(
      'programs',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return Program.fromMap(rows.first);
  }

  Future<int> insert(Program program) async {
    return _db.insert('programs', program.toMap()..remove('id'));
  }

  Future<void> update(Program program) async {
    await _db.update(
      'programs',
      program.toMap(),
      where: 'id = ?',
      whereArgs: [program.id],
    );
  }

  Future<void> delete(int id) async {
    await _db.delete('programs', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> setActive(int id) async {
    await _db.transaction((txn) async {
      await txn.update('programs', {'is_active': 0});
      await txn.update(
        'programs',
        {'is_active': 1},
        where: 'id = ?',
        whereArgs: [id],
      );
    });
  }

  Future<List<WorkoutSession>> getSessions(int programId) async {
    final rows = await _db.query(
      'sessions',
      where: 'program_id = ?',
      whereArgs: [programId],
      orderBy: 'order_index ASC, id ASC',
    );
    return rows.map(WorkoutSession.fromMap).toList();
  }

  Future<WorkoutSession?> getSessionById(int id) async {
    final rows = await _db.query(
      'sessions',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return WorkoutSession.fromMap(rows.first);
  }

  Future<int> insertSession(WorkoutSession session) async {
    return _db.insert('sessions', session.toMap()..remove('id'));
  }

  Future<void> updateSession(WorkoutSession session) async {
    await _db.update(
      'sessions',
      session.toMap(),
      where: 'id = ?',
      whereArgs: [session.id],
    );
  }

  Future<void> deleteSession(int id) async {
    await _db.delete('sessions', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<SessionExercise>> getSessionExercises(int sessionId) async {
    final rows = await _db.rawQuery('''
      SELECT se.*, e.name AS exercise_name, e.muscle_group
      FROM session_exercises se
      JOIN exercises e ON e.id = se.exercise_id
      WHERE se.session_id = ?
      ORDER BY se.id ASC
    ''', [sessionId]);
    return rows.map(SessionExercise.fromMap).toList();
  }

  Future<int> insertSessionExercise(SessionExercise item) async {
    return _db.insert('session_exercises', item.toMap()..remove('id'));
  }

  Future<void> updateSessionExercise(SessionExercise item) async {
    await _db.update(
      'session_exercises',
      item.toMap(),
      where: 'id = ?',
      whereArgs: [item.id],
    );
  }

  Future<void> deleteSessionExercise(int id) async {
    await _db.delete('session_exercises', where: 'id = ?', whereArgs: [id]);
  }
}
