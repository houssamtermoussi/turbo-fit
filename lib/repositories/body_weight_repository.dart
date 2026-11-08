import 'package:sqflite/sqflite.dart';

import '../models/body_weight.dart';

class BodyWeightRepository {
  BodyWeightRepository(this._db);

  final Database _db;

  Future<List<BodyWeightLog>> getLogs() async {
    final rows = await _db.query(
      'body_weight_logs',
      orderBy: 'weighed_at ASC, id ASC',
    );
    return rows.map(BodyWeightLog.fromMap).toList();
  }

  Future<int> saveLog(BodyWeightLog log) async {
    if (log.id == null) {
      return _db.insert('body_weight_logs', log.toMap()..remove('id'));
    }
    await _db.update(
      'body_weight_logs',
      log.toMap()..remove('id'),
      where: 'id = ?',
      whereArgs: [log.id],
    );
    return log.id!;
  }

  Future<void> deleteLog(int id) async {
    await _db.delete('body_weight_logs', where: 'id = ?', whereArgs: [id]);
  }

  Future<WeightGoal?> getActiveGoal() async {
    final rows = await _db.query(
      'weight_goals',
      orderBy: 'created_at DESC, id DESC',
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return WeightGoal.fromMap(rows.first);
  }

  Future<int> saveGoal(WeightGoal goal) async {
    // Un seul objectif actif : on remplace l'existant.
    await _db.delete('weight_goals');
    return _db.insert('weight_goals', goal.toMap()..remove('id'));
  }

  Future<void> clearGoal() async {
    await _db.delete('weight_goals');
  }
}
