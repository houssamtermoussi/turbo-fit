import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

import '../models/body_weight.dart';
import '../models/performance.dart';
import '../models/session.dart';
import '../repositories/body_weight_repository.dart';
import '../repositories/performance_repository.dart';
import '../repositories/session_repository.dart';

class AppState extends ChangeNotifier {
  AppState(this._db);

  final Database _db;
  late final SessionRepository sessions = SessionRepository(_db);
  late final BodyWeightRepository bodyWeight = BodyWeightRepository(_db);
  late final PerformanceRepository performance = PerformanceRepository(_db);

  bool loading = true;
  List<WorkoutSession> sessionList = [];
  List<BodyWeightLog> weightLogs = [];
  WeightGoal? weightGoal;
  List<ExercisePerformanceSummary> performanceSummaries = [];

  Future<void> init() async {
    loading = true;
    notifyListeners();
    await refreshAll();
    loading = false;
    notifyListeners();
  }

  Future<void> refreshAll() async {
    sessionList = await sessions.getAll();
    weightLogs = await bodyWeight.getLogs();
    weightGoal = await bodyWeight.getActiveGoal();
    performanceSummaries = await performance.getSummaries();
    notifyListeners();
  }

  Future<WorkoutSession?> getSession(int id) {
    return sessions.getById(id);
  }

  Future<int> saveSession(WorkoutSession session) async {
    final id = await sessions.save(session);
    await refreshAll();
    return id;
  }

  Future<void> deleteSession(WorkoutSession session) async {
    if (session.id == null) return;
    await sessions.delete(session.id!);
    if (session.photoPath != null) {
      final file = File(session.photoPath!);
      if (await file.exists()) {
        await file.delete();
      }
    }
    await refreshAll();
  }

  Future<void> saveWeightLog(BodyWeightLog log) async {
    await bodyWeight.saveLog(log);
    await refreshAll();
  }

  Future<void> deleteWeightLog(int id) async {
    await bodyWeight.deleteLog(id);
    await refreshAll();
  }

  Future<void> saveWeightGoal(WeightGoal goal) async {
    await bodyWeight.saveGoal(goal);
    await refreshAll();
  }

  Future<void> clearWeightGoal() async {
    await bodyWeight.clearGoal();
    await refreshAll();
  }

  Future<String> persistPhoto(String sourcePath) async {
    final docs = await getApplicationDocumentsDirectory();
    final photosDir = Directory(p.join(docs.path, 'session_photos'));
    if (!await photosDir.exists()) {
      await photosDir.create(recursive: true);
    }
    final filename =
        'session_${DateTime.now().millisecondsSinceEpoch}${p.extension(sourcePath)}';
    final dest = p.join(photosDir.path, filename);
    await File(sourcePath).copy(dest);
    return dest;
  }
}
