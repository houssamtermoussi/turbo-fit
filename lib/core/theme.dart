import 'package:flutter/material.dart';

class TurboFitTheme {
  static const Color crimson = Color(0xFFE10600);
  static const Color charcoal = Color(0xFF0A0A0A);
  static const Color slate = Color(0xFF161616);
  static const Color mist = Color(0xFFF2F2F2);
  static const Color ember = Color(0xFFFF4D4D);

  static ThemeData dark() {
    final base = ColorScheme.fromSeed(
      seedColor: crimson,
      brightness: Brightness.dark,
      surface: slate,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: base.copyWith(
        primary: crimson,
        onPrimary: mist,
        secondary: ember,
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
        backgroundColor: crimson,
        foregroundColor: mist,
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
        color: crimson,
      ),
    );
  }
}
