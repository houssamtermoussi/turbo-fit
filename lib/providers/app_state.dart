import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';

import '../models/exercise.dart';
import '../models/goal.dart';
import '../models/program.dart';
import '../models/session.dart';
import '../models/workout_log.dart';
import '../repositories/exercise_repository.dart';
import '../repositories/goal_repository.dart';
import '../repositories/program_repository.dart';
import '../repositories/workout_repository.dart';

class AppState extends ChangeNotifier {
  AppState(this._db);

  final Database _db;

  late final ExerciseRepository exercises = ExerciseRepository(_db);
  late final ProgramRepository programs = ProgramRepository(_db);
  late final WorkoutRepository workouts = WorkoutRepository(_db);
  late final GoalRepository goals = GoalRepository(_db);

  bool loading = true;
  List<Program> programList = [];
  List<Exercise> exerciseList = [];
  List<Goal> goalList = [];
  Program? activeProgram;
  List<WorkoutSession> activeSessions = [];
  WorkoutSession? nextSession;
  WorkoutLog? lastWorkout;

  Future<void> init() async {
    loading = true;
    notifyListeners();
    await refreshAll();
    loading = false;
    notifyListeners();
  }

  Future<void> refreshAll() async {
    programList = await programs.getAll();
    exerciseList = await exercises.getAll();
    goalList = await goals.getAll();
    activeProgram = await programs.getActive();
    lastWorkout = await workouts.getLastWorkout();

    if (activeProgram?.id != null) {
      activeSessions = await programs.getSessions(activeProgram!.id!);
      nextSession = await _computeNextSession(activeProgram!.id!, activeSessions);
    } else {
      activeSessions = [];
      nextSession = null;
    }
    notifyListeners();
  }

  Future<WorkoutSession?> _computeNextSession(
    int programId,
    List<WorkoutSession> sessions,
  ) async {
    if (sessions.isEmpty) return null;
    final lastId = await workouts.getLastCompletedSessionId(programId);
    if (lastId == null) return sessions.first;

    final index = sessions.indexWhere((s) => s.id == lastId);
    if (index < 0 || index >= sessions.length - 1) {
      return sessions.first;
    }
    return sessions[index + 1];
  }

  Future<void> createProgram(String name, {String notes = ''}) async {
    final id = await programs.insert(Program(name: name, notes: notes));
    if (programList.isEmpty) {
      await programs.setActive(id);
    }
    await refreshAll();
  }

  Future<void> updateProgram(Program program) async {
    await programs.update(program);
    await refreshAll();
  }

  Future<void> deleteProgram(int id) async {
    await programs.delete(id);
    await refreshAll();
  }

  Future<void> setActiveProgram(int id) async {
    await programs.setActive(id);
    await refreshAll();
  }

  Future<int> createSession(int programId, String name) async {
    final existing = await programs.getSessions(programId);
    final id = await programs.insertSession(
      WorkoutSession(
        programId: programId,
        name: name,
        orderIndex: existing.length,
      ),
    );
    await refreshAll();
    return id;
  }

  Future<void> deleteSession(int id) async {
    await programs.deleteSession(id);
    await refreshAll();
  }

  Future<void> addExerciseToSession(SessionExercise item) async {
    await programs.insertSessionExercise(item);
    await refreshAll();
  }

  Future<void> updateSessionExercise(SessionExercise item) async {
    await programs.updateSessionExercise(item);
    await refreshAll();
  }

  Future<void> removeExerciseFromSession(int id) async {
    await programs.deleteSessionExercise(id);
    await refreshAll();
  }

  Future<void> saveWorkout({
    required int sessionId,
    required List<SetLog> sets,
    String notes = '',
  }) async {
    await workouts.saveWorkout(
      sessionId: sessionId,
      performedAt: DateTime.now(),
      notes: notes,
      sets: sets,
    );
    await refreshAll();
  }

  Future<void> createGoal({
    required int exerciseId,
    required double targetWeight,
  }) async {
    await goals.insert(
      Goal(
        exerciseId: exerciseId,
        targetWeight: targetWeight,
        createdAt: DateTime.now(),
      ),
    );
    await refreshAll();
  }

  Future<void> deleteGoal(int id) async {
    await goals.delete(id);
    await refreshAll();
  }
}
