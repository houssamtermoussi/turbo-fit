import 'package:flutter/material.dart';

import '../models/goal.dart';

class GoalProgressCard extends StatelessWidget {
  const GoalProgressCard({super.key, required this.goal});

  final Goal goal;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    goal.exerciseName ?? 'Exercice',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Text(
                  '${goal.progressPercent}%',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '${goal.currentBest.toStringAsFixed(1)} / ${goal.targetWeight.toStringAsFixed(1)} kg',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: goal.progress,
                minHeight: 10,
                backgroundColor: theme.colorScheme.onSurface.withValues(alpha: 0.1),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
