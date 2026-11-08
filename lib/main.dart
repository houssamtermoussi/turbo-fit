import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';

import 'app.dart';
import 'core/db/database.dart';
import 'providers/app_state.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('fr_FR');

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
