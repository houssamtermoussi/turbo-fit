import 'package:sqflite/sqflite.dart';

import '../models/goal.dart';

class GoalRepository {
  GoalRepository(this._db);

  final Database _db;

  Future<List<Goal>> getAll() async {
    final rows = await _db.rawQuery('''
      SELECT g.*, e.name AS exercise_name
      FROM goals g
      JOIN exercises e ON e.id = g.exercise_id
      ORDER BY g.created_at DESC
    ''');
    return rows.map(Goal.fromMap).toList();
  }

  Future<int> insert(Goal goal) async {
    // Seed current_best from existing logs
    final bestRows = await _db.rawQuery('''
      SELECT MAX(weight) AS best FROM set_logs WHERE exercise_id = ?
    ''', [goal.exerciseId]);
    final best = (bestRows.first['best'] as num?)?.toDouble() ?? 0;

    return _db.insert('goals', {
      ...goal.toMap()..remove('id'),
      'current_best': best,
    });
  }

  Future<void> update(Goal goal) async {
    await _db.update(
      'goals',
      goal.toMap(),
      where: 'id = ?',
      whereArgs: [goal.id],
    );
  }

  Future<void> delete(int id) async {
    await _db.delete('goals', where: 'id = ?', whereArgs: [id]);
  }
}
