import 'package:flutter/material.dart';

import '../core/theme.dart';

/// Visage de pingouin Turbo Fit + numéro de ressenti (1–5).
class PenguinFeelingBadge extends StatelessWidget {
  const PenguinFeelingBadge({
    super.key,
    required this.value,
    this.size = 28,
    this.fontSize = 18,
  });

  final int value;
  final double size;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    final level = value.clamp(1, 5);

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Image.asset(
          'assets/icon/penguin_feeling_face.png',
          width: size,
          height: size,
          fit: BoxFit.contain,
          filterQuality: FilterQuality.high,
          gaplessPlayback: true,
        ),
        const SizedBox(width: 4),
        Text(
          '$level',
          style: TextStyle(
            color: Colors.white,
            fontSize: fontSize,
            fontWeight: FontWeight.w800,
            height: 1,
          ),
        ),
      ],
    );
  }
}

/// Sélecteur 1–5 : chaque option = visage de pingouin et numéro.
class PenguinFeelingPicker extends StatelessWidget {
  const PenguinFeelingPicker({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final int value;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final selected = value.clamp(1, 5);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Ressenti',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: List.generate(5, (index) {
            final level = index + 1;
            final isSelected = level == selected;

            return Expanded(
              child: Padding(
                padding: EdgeInsets.only(right: level < 5 ? 8 : 0),
                child: Material(
                  color: isSelected
                      ? TurboFitTheme.crimson.withValues(alpha: 0.18)
                      : theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(12),
                  child: InkWell(
                    onTap: () => onChanged(level),
                    borderRadius: BorderRadius.circular(12),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 160),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected
                              ? TurboFitTheme.crimson
                              : theme.colorScheme.onSurface
                                  .withValues(alpha: 0.12),
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                      child: Center(
                        child: PenguinFeelingBadge(
                          value: level,
                          size: 28,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
      ],
    );
  }
}
