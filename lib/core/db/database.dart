import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class AppDatabase {
  AppDatabase._();
  static final AppDatabase instance = AppDatabase._();

  Database? _db;

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _open();
    return _db!;
  }

  Future<Database> _open() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'turbo_fit.db');

    return openDatabase(
      path,
      version: 1,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE exercises (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        muscle_group TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE programs (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        notes TEXT NOT NULL DEFAULT '',
        is_active INTEGER NOT NULL DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE sessions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        program_id INTEGER NOT NULL,
        name TEXT NOT NULL,
        order_index INTEGER NOT NULL DEFAULT 0,
        FOREIGN KEY (program_id) REFERENCES programs (id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE session_exercises (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        session_id INTEGER NOT NULL,
        exercise_id INTEGER NOT NULL,
        target_sets INTEGER NOT NULL DEFAULT 3,
        target_reps INTEGER NOT NULL DEFAULT 10,
        target_weight REAL,
        FOREIGN KEY (session_id) REFERENCES sessions (id) ON DELETE CASCADE,
        FOREIGN KEY (exercise_id) REFERENCES exercises (id)
      )
    ''');

    await db.execute('''
      CREATE TABLE workout_logs (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        session_id INTEGER NOT NULL,
        performed_at TEXT NOT NULL,
        notes TEXT NOT NULL DEFAULT '',
        FOREIGN KEY (session_id) REFERENCES sessions (id)
      )
    ''');

    await db.execute('''
      CREATE TABLE set_logs (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        workout_log_id INTEGER NOT NULL,
        exercise_id INTEGER NOT NULL,
        set_number INTEGER NOT NULL,
        reps INTEGER NOT NULL,
        weight REAL NOT NULL,
        FOREIGN KEY (workout_log_id) REFERENCES workout_logs (id) ON DELETE CASCADE,
        FOREIGN KEY (exercise_id) REFERENCES exercises (id)
      )
    ''');

    await db.execute('''
      CREATE TABLE goals (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        exercise_id INTEGER NOT NULL,
        target_weight REAL NOT NULL,
        current_best REAL NOT NULL DEFAULT 0,
        created_at TEXT NOT NULL,
        FOREIGN KEY (exercise_id) REFERENCES exercises (id)
      )
    ''');

    await _seedExercises(db);
  }

  Future<void> _seedExercises(Database db) async {
    const seeds = [
      ('Développé couché', 'Pectoraux'),
      ('Squat', 'Jambes'),
      ('Soulevé de terre', 'Dos'),
      ('Développé militaire', 'Épaules'),
      ('Rowing barre', 'Dos'),
      ('Tractions', 'Dos'),
      ('Dips', 'Pectoraux'),
      ('Curl biceps', 'Bras'),
      ('Extension triceps', 'Bras'),
      ('Fentes', 'Jambes'),
      ('Leg press', 'Jambes'),
      ('Élévations latérales', 'Épaules'),
      ('Hip thrust', 'Jambes'),
      ('Pompes', 'Pectoraux'),
      ('Planche', 'Core'),
    ];

    final batch = db.batch();
    for (final (name, group) in seeds) {
      batch.insert('exercises', {'name': name, 'muscle_group': group});
    }
    await batch.commit(noResult: true);
  }
}
