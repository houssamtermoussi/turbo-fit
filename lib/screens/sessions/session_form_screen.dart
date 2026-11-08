import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../models/session.dart';
import '../../providers/app_state.dart';
import '../../widgets/penguin_feeling.dart';

class SessionFormScreen extends StatefulWidget {
  const SessionFormScreen({super.key, this.session});

  final WorkoutSession? session;

  @override
  State<SessionFormScreen> createState() => _SessionFormScreenState();
}

class _SessionFormScreenState extends State<SessionFormScreen> {
  late DateTime _date;
  late final TextEditingController _notesController;
  final List<_ExerciseDraft> _exercises = [];
  String? _photoPath;
  late int _feeling;
  bool _saving = false;

  bool get _isEditing => widget.session != null;

  @override
  void initState() {
    super.initState();
    final session = widget.session;
    _date = session?.performedAt ?? DateTime.now();
    _notesController = TextEditingController(text: session?.notes ?? '');
    _photoPath = session?.photoPath;
    _feeling = session?.feeling ?? 3;

    if (session != null && session.exercises.isNotEmpty) {
      for (final exercise in session.exercises) {
        _exercises.add(
          _ExerciseDraft(
            name: TextEditingController(text: exercise.name),
            sets: exercise.sets
                .map(
                  (set) => _SetDraft(
                    reps: TextEditingController(text: '${set.reps}'),
                    weight: TextEditingController(
                      text: set.weight == 0
                          ? ''
                          : (set.weight == set.weight.roundToDouble()
                              ? '${set.weight.toInt()}'
                              : '${set.weight}'),
                    ),
                  ),
                )
                .toList(),
          ),
        );
      }
    } else {
      _exercises.add(_ExerciseDraft.empty());
    }
  }

  @override
  void dispose() {
    _notesController.dispose();
    for (final exercise in _exercises) {
      exercise.dispose();
    }
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 1)),
      locale: const Locale('fr', 'FR'),
    );
    if (picked != null) {
      setState(() {
        _date = DateTime(picked.year, picked.month, picked.day);
      });
    }
  }

  Future<void> _choosePhoto() async {
    final action = await showModalBottomSheet<_PhotoAction>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Galerie'),
              onTap: () => Navigator.pop(context, _PhotoAction.gallery),
            ),
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('Appareil photo'),
              onTap: () => Navigator.pop(context, _PhotoAction.camera),
            ),
            if (_photoPath != null)
              ListTile(
                leading: const Icon(Icons.delete_outline),
                title: const Text('Retirer la photo'),
                onTap: () => Navigator.pop(context, _PhotoAction.remove),
              ),
          ],
        ),
      ),
    );

    if (!mounted || action == null) return;

    if (action == _PhotoAction.remove) {
      setState(() => _photoPath = null);
      return;
    }

    final picker = ImagePicker();
    final file = await picker.pickImage(
      source: action == _PhotoAction.camera
          ? ImageSource.camera
          : ImageSource.gallery,
      imageQuality: 85,
      maxWidth: 1600,
    );
    if (file != null && mounted) {
      setState(() => _photoPath = file.path);
    }
  }

  void _addExercise() {
    setState(() => _exercises.add(_ExerciseDraft.empty()));
  }

  void _removeExercise(int index) {
    if (_exercises.length <= 1) return;
    setState(() {
      _exercises.removeAt(index).dispose();
    });
  }

  Future<void> _save() async {
    final exercises = <SessionExercise>[];

    for (final draft in _exercises) {
      final name = draft.name.text.trim();
      if (name.isEmpty) continue;

      final sets = <ExerciseSet>[];
      for (var i = 0; i < draft.sets.length; i++) {
        final setDraft = draft.sets[i];
        final reps = int.tryParse(setDraft.reps.text.trim()) ?? 0;
        final weight =
            double.tryParse(setDraft.weight.text.trim().replaceAll(',', '.')) ??
                0;
        if (reps <= 0 && weight <= 0) continue;
        sets.add(
          ExerciseSet(
            setNumber: i + 1,
            reps: reps <= 0 ? 0 : reps,
            weight: weight,
          ),
        );
      }

      if (sets.isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ajoute au moins une série pour "$name"')),
        );
        return;
      }

      exercises.add(SessionExercise(name: name, sets: sets));
    }

    if (exercises.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ajoute au moins un exercice')),
      );
      return;
    }

    setState(() => _saving = true);
    final state = context.read<AppState>();

    try {
      var photoPath = _photoPath;
      final previousPhoto = widget.session?.photoPath;

      if (photoPath != null && photoPath != previousPhoto) {
        photoPath = await state.persistPhoto(photoPath);
      }

      final session = WorkoutSession(
        id: widget.session?.id,
        performedAt: _date,
        notes: _notesController.text.trim(),
        photoPath: photoPath,
        feeling: _feeling,
        exercises: exercises,
      );

      await state.saveSession(session);

      if (previousPhoto != null &&
          previousPhoto != photoPath &&
          File(previousPhoto).existsSync()) {
        await File(previousPhoto).delete();
      }

      if (mounted) Navigator.of(context).pop();
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateLabel = DateFormat('EEEE d MMMM yyyy', 'fr_FR').format(_date);
    final hasPhoto = _photoPath != null && File(_photoPath!).existsSync();

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Modifier la séance' : 'Nouvelle séance'),
        actions: [
          TextButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Enregistrer'),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.calendar_today_outlined),
            title: const Text('Date'),
            subtitle: Text(dateLabel),
            trailing: const Icon(Icons.chevron_right),
            onTap: _pickDate,
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _notesController,
            decoration: const InputDecoration(
              labelText: 'Notes (optionnel)',
              hintText: 'Focus du jour…',
            ),
            maxLines: 2,
            textCapitalization: TextCapitalization.sentences,
          ),
          const SizedBox(height: 20),
          PenguinFeelingPicker(
            value: _feeling,
            onChanged: (value) => setState(() => _feeling = value),
          ),
          const SizedBox(height: 20),
          Text(
            'Photo',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          if (hasPhoto)
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: Image.file(File(_photoPath!), fit: BoxFit.cover),
              ),
            )
          else
            OutlinedButton.icon(
              onPressed: _choosePhoto,
              icon: const Icon(Icons.add_a_photo_outlined),
              label: const Text('Ajouter une photo'),
            ),
          if (hasPhoto) ...[
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: _choosePhoto,
              icon: const Icon(Icons.photo_outlined),
              label: const Text('Changer / retirer'),
            ),
          ],
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Exercices',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              TextButton.icon(
                onPressed: _addExercise,
                icon: const Icon(Icons.add),
                label: const Text('Ajouter'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...List.generate(_exercises.length, (index) {
            return _ExerciseCard(
              key: ValueKey(_exercises[index]),
              index: index,
              draft: _exercises[index],
              canRemove: _exercises.length > 1,
              onRemove: () => _removeExercise(index),
              onChanged: () => setState(() {}),
            );
          }),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: _saving ? null : _save,
            child: Text(_isEditing ? 'Mettre à jour' : 'Enregistrer la séance'),
          ),
        ],
      ),
    );
  }
}

enum _PhotoAction { gallery, camera, remove }

class _ExerciseDraft {
  _ExerciseDraft({required this.name, required this.sets});

  factory _ExerciseDraft.empty() {
    return _ExerciseDraft(
      name: TextEditingController(),
      sets: [_SetDraft.empty()],
    );
  }

  final TextEditingController name;
  final List<_SetDraft> sets;

  void dispose() {
    name.dispose();
    for (final set in sets) {
      set.dispose();
    }
  }
}

class _SetDraft {
  _SetDraft({required this.reps, required this.weight});

  factory _SetDraft.empty() {
    return _SetDraft(
      reps: TextEditingController(),
      weight: TextEditingController(),
    );
  }

  final TextEditingController reps;
  final TextEditingController weight;

  void dispose() {
    reps.dispose();
    weight.dispose();
  }
}

class _ExerciseCard extends StatelessWidget {
  const _ExerciseCard({
    super.key,
    required this.index,
    required this.draft,
    required this.canRemove,
    required this.onRemove,
    required this.onChanged,
  });

  final int index;
  final _ExerciseDraft draft;
  final bool canRemove;
  final VoidCallback onRemove;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Exercice ${index + 1}',
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
                    ),
                  ),
                ),
                if (canRemove)
                  IconButton(
                    onPressed: onRemove,
                    icon: const Icon(Icons.close),
                    tooltip: 'Retirer',
                  ),
              ],
            ),
            TextField(
              controller: draft.name,
              decoration: const InputDecoration(
                labelText: 'Nom',
                hintText: 'Ex. Développé couché',
              ),
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: 12),
            ...List.generate(draft.sets.length, (setIndex) {
              final set = draft.sets[setIndex];
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    SizedBox(
                      width: 64,
                      child: Text(
                        'Série ${setIndex + 1}',
                        style: theme.textTheme.bodyMedium,
                      ),
                    ),
                    Expanded(
                      child: TextField(
                        controller: set.reps,
                        decoration: const InputDecoration(
                          labelText: 'Reps',
                          isDense: true,
                        ),
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: set.weight,
                        decoration: const InputDecoration(
                          labelText: 'Poids (kg)',
                          isDense: true,
                        ),
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                      ),
                    ),
                    if (draft.sets.length > 1)
                      IconButton(
                        onPressed: () {
                          draft.sets.removeAt(setIndex).dispose();
                          onChanged();
                        },
                        icon: const Icon(Icons.remove_circle_outline),
                      )
                    else
                      const SizedBox(width: 48),
                  ],
                ),
              );
            }),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: () {
                  draft.sets.add(_SetDraft.empty());
                  onChanged();
                },
                icon: const Icon(Icons.add),
                label: const Text('Série'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
