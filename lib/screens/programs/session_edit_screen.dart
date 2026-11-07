import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/exercise.dart';
import '../../models/session.dart';
import '../../providers/app_state.dart';

class SessionEditScreen extends StatefulWidget {
  const SessionEditScreen({super.key, required this.sessionId});

  final int sessionId;

  @override
  State<SessionEditScreen> createState() => _SessionEditScreenState();
}

class _SessionEditScreenState extends State<SessionEditScreen> {
  WorkoutSession? _session;
  List<SessionExercise> _items = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final state = context.read<AppState>();
    final session = await state.programs.getSessionById(widget.sessionId);
    final items = await state.programs.getSessionExercises(widget.sessionId);
    if (!mounted) return;
    setState(() {
      _session = session;
      _items = items;
      _loading = false;
    });
  }

  Future<void> _addExercise() async {
    final state = context.read<AppState>();
    final exercises = state.exerciseList;
    Exercise? selected = exercises.isEmpty ? null : exercises.first;
    final setsCtrl = TextEditingController(text: '3');
    final repsCtrl = TextEditingController(text: '10');
    final weightCtrl = TextEditingController();

    final ok = await showDialog<bool>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Ajouter un exercice'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<Exercise>(
                      initialValue: selected,
                      items: exercises
                          .map(
                            (e) => DropdownMenuItem(
                              value: e,
                              child: Text('${e.name} (${e.muscleGroup})'),
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
                      controller: setsCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Séries'),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: repsCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Reps'),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: weightCtrl,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Poids cible (kg)',
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Annuler'),
                ),
                FilledButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('Ajouter'),
                ),
              ],
            );
          },
        );
      },
    );

    if (ok != true || selected == null || !mounted) return;

    await state.addExerciseToSession(
      SessionExercise(
        sessionId: widget.sessionId,
        exerciseId: selected!.id!,
        targetSets: int.tryParse(setsCtrl.text) ?? 3,
        targetReps: int.tryParse(repsCtrl.text) ?? 10,
        targetWeight: double.tryParse(weightCtrl.text.replaceAll(',', '.')),
      ),
    );
    await _load();
  }

  Future<void> _removeItem(SessionExercise item) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Retirer cet exercice ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Retirer'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    await context.read<AppState>().removeExerciseFromSession(item.id!);
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_session?.name ?? 'Séance'),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addExercise,
        child: const Icon(Icons.add),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _items.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('Aucun exercice. Ajoute-en pour cette séance.'),
                      const SizedBox(height: 16),
                      FilledButton(
                        onPressed: _addExercise,
                        child: const Text('Ajouter un exercice'),
                      ),
                    ],
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 88),
                  itemCount: _items.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final item = _items[index];
                    final weight = item.targetWeight;
                    return Card(
                      child: ListTile(
                        title: Text(
                          item.exerciseName ?? 'Exercice',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        subtitle: Text(
                          [
                            '${item.targetSets} × ${item.targetReps}',
                            if (weight != null)
                              '${weight.toStringAsFixed(weight % 1 == 0 ? 0 : 1)} kg',
                            if (item.muscleGroup != null) item.muscleGroup!,
                          ].join(' · '),
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline),
                          onPressed: () => _removeItem(item),
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
