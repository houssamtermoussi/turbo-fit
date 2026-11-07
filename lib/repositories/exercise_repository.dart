import 'package:sqflite/sqflite.dart';

import '../models/exercise.dart';

class ExerciseRepository {
  ExerciseRepository(this._db);

  final Database _db;

  Future<List<Exercise>> getAll() async {
    final rows = await _db.query('exercises', orderBy: 'name ASC');
    return rows.map(Exercise.fromMap).toList();
  }

  Future<Exercise?> getById(int id) async {
    final rows = await _db.query(
      'exercises',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return Exercise.fromMap(rows.first);
  }

  Future<int> insert(Exercise exercise) async {
    return _db.insert('exercises', exercise.toMap()..remove('id'));
  }
}
