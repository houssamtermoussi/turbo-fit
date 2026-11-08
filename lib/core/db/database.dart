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
      version: 4,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
      onCreate: _onCreate,
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await _dropAll(db);
          await _onCreate(db, newVersion);
          return;
        }
        if (oldVersion < 3) {
          await db.execute(
            'ALTER TABLE sessions ADD COLUMN feeling INTEGER NOT NULL DEFAULT 3',
          );
        }
        if (oldVersion < 4) {
          await _createProgressTables(db);
        }
      },
    );
  }

  Future<void> _dropAll(Database db) async {
    await db.execute('DROP TABLE IF EXISTS session_sets');
    await db.execute('DROP TABLE IF EXISTS set_logs');
    await db.execute('DROP TABLE IF EXISTS workout_logs');
    await db.execute('DROP TABLE IF EXISTS goals');
    await db.execute('DROP TABLE IF EXISTS body_weight_logs');
    await db.execute('DROP TABLE IF EXISTS weight_goals');
    await db.execute('DROP TABLE IF EXISTS session_exercises');
    await db.execute('DROP TABLE IF EXISTS sessions');
    await db.execute('DROP TABLE IF EXISTS programs');
    await db.execute('DROP TABLE IF EXISTS exercises');
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE sessions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        performed_at TEXT NOT NULL,
        notes TEXT NOT NULL DEFAULT '',
        photo_path TEXT,
        feeling INTEGER NOT NULL DEFAULT 3
      )
    ''');

    await db.execute('''
      CREATE TABLE session_exercises (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        session_id INTEGER NOT NULL,
        name TEXT NOT NULL,
        order_index INTEGER NOT NULL DEFAULT 0,
        FOREIGN KEY (session_id) REFERENCES sessions (id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE session_sets (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        exercise_id INTEGER NOT NULL,
        set_number INTEGER NOT NULL,
        reps INTEGER NOT NULL,
        weight REAL NOT NULL DEFAULT 0,
        FOREIGN KEY (exercise_id) REFERENCES session_exercises (id) ON DELETE CASCADE
      )
    ''');

    await _createProgressTables(db);
  }

  Future<void> _createProgressTables(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS body_weight_logs (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        weighed_at TEXT NOT NULL,
        weight REAL NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS weight_goals (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        start_weight REAL NOT NULL,
        target_weight REAL NOT NULL,
        created_at TEXT NOT NULL
      )
    ''');
  }
}
