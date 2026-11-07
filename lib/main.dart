import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'app.dart';
import 'core/db/database.dart';
import 'providers/app_state.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final db = await AppDatabase.instance.database;
  final appState = AppState(db);
  await appState.init();

  runApp(
    ChangeNotifierProvider.value(
      value: appState,
      child: const TurboFitApp(),
    ),
  );
}
