import 'dart:io';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../models/session.dart';
import '../../providers/app_state.dart';
import '../../widgets/penguin_feeling.dart';
import 'session_form_screen.dart';

class SessionDetailScreen extends StatelessWidget {
  const SessionDetailScreen({super.key, required this.sessionId});

  final int sessionId;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    WorkoutSession? session;
    for (final item in state.sessionList) {
      if (item.id == sessionId) {
        session = item;
        break;
      }
    }

    if (session == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Séance')),
        body: const Center(child: Text('Séance introuvable')),
      );
    }

    final current = session;
    final theme = Theme.of(context);
    final dateFormat = DateFormat('EEEE d MMMM yyyy', 'fr_FR');
    final hasPhoto =
        current.photoPath != null && File(current.photoPath!).existsSync();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Séance'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => SessionFormScreen(session: current),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: () => _confirmDelete(context, state, current),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  dateFormat.format(current.performedAt),
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              PenguinFeelingBadge(
                value: current.feeling,
                size: 36,
                fontSize: 24,
              ),
            ],
          ),
          if (current.notes.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              current.notes,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.75),
              ),
            ),
          ],
          if (hasPhoto) ...[
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.file(
                File(current.photoPath!),
                fit: BoxFit.cover,
              ),
            ),
          ],
          const SizedBox(height: 24),
          Text(
            'Exercices',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          ...current.exercises.map((exercise) {
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      exercise.name,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ...exercise.sets.map((set) {
                      final weightLabel = set.weight == set.weight.roundToDouble()
                          ? set.weight.toInt().toString()
                          : set.weight.toString();
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 72,
                              child: Text(
                                'Série ${set.setNumber}',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: theme.colorScheme.onSurface
                                      .withValues(alpha: 0.55),
                                ),
                              ),
                            ),
                            Text(
                              '${set.reps} reps',
                              style: theme.textTheme.bodyLarge,
                            ),
                            const SizedBox(width: 16),
                            Text(
                              '$weightLabel kg',
                              style: theme.textTheme.bodyLarge?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    AppState state,
    WorkoutSession session,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer la séance ?'),
        content: const Text('Cette action est définitive.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      await state.deleteSession(session);
      if (context.mounted) Navigator.of(context).pop();
    }
  }
}
