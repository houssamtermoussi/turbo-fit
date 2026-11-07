import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/app_state.dart';
import '../../widgets/empty_state.dart';
import 'program_detail_screen.dart';

class ProgramsScreen extends StatelessWidget {
  const ProgramsScreen({super.key});

  Future<void> _createProgram(BuildContext context) async {
    final controller = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Nouveau programme'),
          content: TextField(
            controller: controller,
            autofocus: true,
            decoration: const InputDecoration(
              hintText: 'ex. Push / Pull / Legs',
            ),
            textCapitalization: TextCapitalization.sentences,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Annuler'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, controller.text.trim()),
              child: const Text('Créer'),
            ),
          ],
        );
      },
    );

    if (name == null || name.isEmpty || !context.mounted) return;
    await context.read<AppState>().createProgram(name);
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();

    return Scaffold(
      appBar: AppBar(title: const Text('Programmes')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _createProgram(context),
        child: const Icon(Icons.add),
      ),
      body: state.programList.isEmpty
          ? EmptyState(
              icon: Icons.playlist_add,
              title: 'Aucun programme',
              subtitle: 'Crée un programme pour organiser tes séances.',
              actionLabel: 'Créer un programme',
              onAction: () => _createProgram(context),
            )
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 88),
              itemCount: state.programList.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final program = state.programList[index];
                return Card(
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    title: Text(
                      program.name,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: program.isActive
                        ? Text(
                            'Programme actif',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          )
                        : (program.notes.isEmpty
                            ? null
                            : Text(program.notes)),
                    trailing: program.isActive
                        ? Icon(
                            Icons.check_circle,
                            color: Theme.of(context).colorScheme.primary,
                          )
                        : const Icon(Icons.chevron_right),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => ProgramDetailScreen(
                            programId: program.id!,
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
    );
  }
}
