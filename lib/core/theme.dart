import 'package:flutter/material.dart';

class TurboFitTheme {
  static const Color electric = Color(0xFF00E5A8);
  static const Color charcoal = Color(0xFF0F1419);
  static const Color slate = Color(0xFF1A2332);
  static const Color mist = Color(0xFFE8EEF5);
  static const Color amber = Color(0xFFFFB020);

  static ThemeData dark() {
    final base = ColorScheme.fromSeed(
      seedColor: electric,
      brightness: Brightness.dark,
      surface: slate,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: base.copyWith(
        primary: electric,
        onPrimary: charcoal,
        secondary: amber,
        surface: slate,
        onSurface: mist,
      ),
      scaffoldBackgroundColor: charcoal,
      appBarTheme: const AppBarTheme(
        backgroundColor: charcoal,
        foregroundColor: mist,
        elevation: 0,
        centerTitle: false,
      ),
      cardTheme: CardThemeData(
        color: slate,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: electric,
        foregroundColor: charcoal,
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: slate,
        selectedItemColor: electric,
        unselectedItemColor: Color(0xFF7A8899),
        type: BottomNavigationBarType.fixed,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: slate,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: electric,
      ),
    );
  }
}
