import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:turbo_fit/core/theme.dart';

void main() {
  test('Turbo Fit theme builds', () {
    final theme = TurboFitTheme.dark();
    expect(theme.brightness, equals(Brightness.dark));
    expect(theme.colorScheme.primary, equals(TurboFitTheme.crimson));
  });
}
