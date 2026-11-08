import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../providers/app_state.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/goal_progress_card.dart';
import '../session_player/session_player_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final theme = Theme.of(context);

    if (state.loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.asset(
                'assets/icon/app_icon.png',
                width: 32,
                height: 32,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(width: 10),
            Text(
              'turbo',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
                color: theme.colorScheme.primary,
              ),
            ),
          ],
        ),
      ),
      body: RefreshIndicator(
        onRefresh: state.refreshAll,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          children: [
            if (state.activeProgram == null)
              EmptyState(
                icon: Icons.fitness_center,
                title: 'Crée ton premier programme',
                subtitle:
                    'Va dans l’onglet Programmes pour organiser tes séances.',
              )
            else ...[
              Text(
                'Programme actif',
                style: theme.textTheme.labelLarge?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                state.activeProgram!.name,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              if (state.nextSession == null)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      'Ajoute des séances à ce programme pour commencer.',
                      style: theme.textTheme.bodyLarge,
                    ),
                  ),
                )
              else
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Prochaine séance',
                          style: theme.textTheme.labelLarge?.copyWith(
                            color: theme.colorScheme.primary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          state.nextSession!.name,
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton.icon(
                            onPressed: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => SessionPlayerScreen(
                                    sessionId: state.nextSession!.id!,
                                  ),
                                ),
                              );
                            },
                            icon: const Icon(Icons.play_arrow_rounded),
                            label: const Text('Démarrer la séance'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              if (state.lastWorkout != null) ...[
                const SizedBox(height: 16),
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.check_circle_outline),
                    title: Text(
                      'Dernière séance : ${state.lastWorkout!.sessionName ?? ''}',
                    ),
                    subtitle: Text(
                      DateFormat.yMMMd('fr').add_Hm().format(
                            state.lastWorkout!.performedAt,
                          ),
                    ),
                  ),
                ),
              ],
            ],
            const SizedBox(height: 28),
            Text(
              'Où j’en suis',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            if (state.goalList.isEmpty)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'Pas encore d’objectifs. Crée-en un dans l’onglet Objectifs.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
                ),
              )
            else
              ...state.goalList.take(3).map(
                    (goal) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: GoalProgressCard(goal: goal),
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}
