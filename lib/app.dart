import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import 'core/theme.dart';
import 'providers/app_state.dart';
import 'screens/sessions/sessions_screen.dart';

class TurboFitApp extends StatelessWidget {
  const TurboFitApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'turbo',
      debugShowCheckedModeBanner: false,
      theme: TurboFitTheme.dark(),
      locale: const Locale('fr'),
      supportedLocales: const [Locale('fr'), Locale('en')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: Consumer<AppState>(
        builder: (context, state, _) {
          if (state.loading) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }
          return const SessionsScreen();
        },
      ),
    );
  }
}
