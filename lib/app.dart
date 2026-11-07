import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/theme.dart';
import 'providers/app_state.dart';
import 'screens/shell.dart';

class TurboFitApp extends StatelessWidget {
  const TurboFitApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Turbo Fit',
      debugShowCheckedModeBanner: false,
      theme: TurboFitTheme.dark(),
      home: Consumer<AppState>(
        builder: (context, state, _) {
          if (state.loading) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }
          return const AppShell();
        },
      ),
    );
  }
}
