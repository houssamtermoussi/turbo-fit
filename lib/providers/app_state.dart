import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

import '../models/session.dart';
import '../repositories/session_repository.dart';

class AppState extends ChangeNotifier {
  AppState(this._db);

  final Database _db;
  late final SessionRepository sessions = SessionRepository(_db);

  bool loading = true;
  List<WorkoutSession> sessionList = [];

  Future<void> init() async {
    loading = true;
    notifyListeners();
    await refreshAll();
    loading = false;
    notifyListeners();
  }

  Future<void> refreshAll() async {
    sessionList = await sessions.getAll();
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
