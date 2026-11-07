import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/session.dart';
import '../../models/workout_log.dart';
import '../../providers/app_state.dart';

class _DraftSet {
  _DraftSet({
    required this.exerciseId,
    required this.setNumber,
    required this.reps,
    required this.weight,
  });

  final int exerciseId;
  final int setNumber;
  int reps;
  double weight;
  bool done = false;
}

class SessionPlayerScreen extends StatefulWidget {
  const SessionPlayerScreen({super.key, required this.sessionId});

  final int sessionId;

  @override
  State<SessionPlayerScreen> createState() => _SessionPlayerScreenState();
}

class _SessionPlayerScreenState extends State<SessionPlayerScreen> {
  WorkoutSession? _session;
  List<SessionExercise> _exercises = [];
  final Map<int, List<_DraftSet>> _drafts = {};
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final state = context.read<AppState>();
    final session = await state.programs.getSessionById(widget.sessionId);
    final exercises =
        await state.programs.getSessionExercises(widget.sessionId);

    final drafts = <int, List<_DraftSet>>{};
    for (final ex in exercises) {
      drafts[ex.exerciseId] = List.generate(ex.targetSets, (i) {
        return _DraftSet(
          exerciseId: ex.exerciseId,
          setNumber: i + 1,
          reps: ex.targetReps,
          weight: ex.targetWeight ?? 0,
        );
      });
    }

    if (!mounted) return;
    setState(() {
      _session = session;
      _exercises = exercises;
      _drafts
        ..clear()
        ..addAll(drafts);
      _loading = false;
    });
  }

  Future<void> _editSet(_DraftSet draft) async {
    final repsCtrl = TextEditingController(text: '${draft.reps}');
    final weightCtrl = TextEditingController(
      text: draft.weight % 1 == 0
          ? draft.weight.toStringAsFixed(0)
          : draft.weight.toStringAsFixed(1),
    );

    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Série ${draft.setNumber}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: weightCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'Poids (kg)'),
              autofocus: true,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: repsCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Reps'),
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
            child: const Text('OK'),
          ),
        ],
      ),
    );

    if (ok != true || !mounted) return;
    setState(() {
      draft.reps = int.tryParse(repsCtrl.text) ?? draft.reps;
      draft.weight =
          double.tryParse(weightCtrl.text.replaceAll(',', '.')) ?? draft.weight;
      draft.done = true;
    });
  }

  Future<void> _finish() async {
    final completed = _drafts.values
        .expand((list) => list)
        .where((s) => s.done)
        .toList();

    if (completed.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Coche au moins une série avant de terminer.'),
        ),
      );
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Terminer la séance ?'),
        content: Text('${completed.length} série(s) seront enregistrées.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Continuer'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Enregistrer'),
          ),
        ],
      ),
    );
    if (confirm != true || !mounted) return;

    setState(() => _saving = true);
    final sets = completed
        .map(
          (s) => SetLog(
            workoutLogId: 0,
            exerciseId: s.exerciseId,
            setNumber: s.setNumber,
            reps: s.reps,
            weight: s.weight,
          ),
        )
        .toList();

    await context.read<AppState>().saveWorkout(
          sessionId: widget.sessionId,
          sets: sets,
        );

    if (!mounted) return;
    setState(() => _saving = false);

    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Séance terminée'),
        content: const Text('Bravo — ta séance est enregistrée.'),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
    if (!mounted) return;
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(_session?.name ?? 'Séance'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _exercises.isEmpty
              ? const Center(
                  child: Text('Cette séance n’a pas encore d’exercices.'),
                )
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                  itemCount: _exercises.length,
                  itemBuilder: (context, index) {
                    final ex = _exercises[index];
                    final sets = _drafts[ex.exerciseId] ?? [];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              ex.exerciseName ?? 'Exercice',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            if (ex.muscleGroup != null) ...[
                              const SizedBox(height: 4),
                              Text(
                                ex.muscleGroup!,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurface
                                      .withValues(alpha: 0.6),
                                ),
                              ),
                            ],
                            const SizedBox(height: 12),
                            ...sets.map((draft) {
                              return CheckboxListTile(
                                contentPadding: EdgeInsets.zero,
                                value: draft.done,
                                onChanged: (value) async {
                                  if (value == true && !draft.done) {
                                    await _editSet(draft);
                                  } else {
                                    setState(() => draft.done = value ?? false);
                                  }
                                },
                                title: Text('Série ${draft.setNumber}'),
                                subtitle: Text(
                                  '${draft.weight.toStringAsFixed(draft.weight % 1 == 0 ? 0 : 1)} kg × ${draft.reps}',
                                ),
                                secondary: IconButton(
                                  icon: const Icon(Icons.edit_outlined),
                                  onPressed: () => _editSet(draft),
                                ),
                              );
                            }),
                          ],
                        ),
                      ),
                    );
                  },
                ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: FilledButton.icon(
            onPressed: _saving || _loading ? null : _finish,
            icon: _saving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.check),
            label: Text(_saving ? 'Enregistrement…' : 'Terminer la séance'),
          ),
        ),
      ),
    );
  }
}
