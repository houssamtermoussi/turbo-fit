import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/exercise.dart';
import '../../providers/app_state.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/goal_progress_card.dart';

class GoalsScreen extends StatelessWidget {
  const GoalsScreen({super.key});

  Future<void> _createGoal(BuildContext context) async {
    final state = context.read<AppState>();
    final exercises = state.exerciseList;
    if (exercises.isEmpty) return;

    Exercise? selected = exercises.first;
    final targetCtrl = TextEditingController();

    final ok = await showDialog<bool>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Nouvel objectif'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<Exercise>(
                    initialValue: selected,
                    items: exercises
                        .map(
                          (e) => DropdownMenuItem(
                            value: e,
                            child: Text(e.name),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      setDialogState(() => selected = value);
                    },
                    decoration: const InputDecoration(labelText: 'Exercice'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: targetCtrl,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: 'Poids cible (kg)',
                      hintText: 'ex. 100',
                    ),
                    autofocus: true,
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Annuler'),
                ),
                FilledButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('Créer'),
                ),
              ],
            );
          },
        );
      },
    );

    if (ok != true || selected == null || !context.mounted) return;
    final target =
        double.tryParse(targetCtrl.text.replaceAll(',', '.')) ?? 0;
    if (target <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Entre un poids cible valide.')),
      );
      return;
    }

    await state.createGoal(
      exerciseId: selected!.id!,
      targetWeight: target,
    );
  }

  Future<void> _deleteGoal(BuildContext context, int id) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer cet objectif ?'),
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
    if (ok != true || !context.mounted) return;
    await context.read<AppState>().deleteGoal(id);
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();

    return Scaffold(
      appBar: AppBar(title: const Text('Objectifs')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _createGoal(context),
        child: const Icon(Icons.add),
      ),
      body: state.goalList.isEmpty
          ? EmptyState(
              icon: Icons.flag_outlined,
              title: 'Aucun objectif',
              subtitle:
                  'Fixe une charge cible (ex. Bench 100 kg) pour suivre où tu en es.',
              actionLabel: 'Créer un objectif',
              onAction: () => _createGoal(context),
            )
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 88),
              itemCount: state.goalList.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final goal = state.goalList[index];
                return Dismissible(
                  key: ValueKey(goal.id),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 20),
                    decoration: BoxDecoration(
                      color: Colors.red.shade700,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(Icons.delete, color: Colors.white),
                  ),
                  confirmDismiss: (_) async {
                    await _deleteGoal(context, goal.id!);
                    return false;
                  },
                  child: GoalProgressCard(goal: goal),
                );
              },
            ),
    );
  }
}
