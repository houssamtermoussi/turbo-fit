import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/session.dart';
import '../../providers/app_state.dart';
import '../session_player/session_player_screen.dart';
import 'session_edit_screen.dart';

class ProgramDetailScreen extends StatefulWidget {
  const ProgramDetailScreen({super.key, required this.programId});

  final int programId;

  @override
  State<ProgramDetailScreen> createState() => _ProgramDetailScreenState();
}

class _ProgramDetailScreenState extends State<ProgramDetailScreen> {
  List<WorkoutSession> _sessions = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final state = context.read<AppState>();
    final sessions = await state.programs.getSessions(widget.programId);
    if (!mounted) return;
    setState(() {
      _sessions = sessions;
      _loading = false;
    });
  }

  Future<void> _addSession() async {
    final controller = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Nouvelle séance'),
          content: TextField(
            controller: controller,
            autofocus: true,
            decoration: const InputDecoration(hintText: 'ex. Push A'),
            textCapitalization: TextCapitalization.sentences,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Annuler'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, controller.text.trim()),
              child: const Text('Ajouter'),
            ),
          ],
        );
      },
    );
    if (name == null || name.isEmpty || !mounted) return;
    final id = await context.read<AppState>().createSession(
          widget.programId,
          name,
        );
    await _load();
    if (!mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => SessionEditScreen(sessionId: id),
      ),
    );
    await _load();
  }

  Future<void> _confirmDeleteProgram() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer ce programme ?'),
        content: const Text(
          'Les séances associées seront aussi supprimées. Cette action est irréversible.',
        ),
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
    if (ok != true || !mounted) return;
    await context.read<AppState>().deleteProgram(widget.programId);
    if (!mounted) return;
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final matches =
        state.programList.where((p) => p.id == widget.programId).toList();
    final current = matches.isEmpty ? null : matches.first;

    if (current == null) {
      return const Scaffold(body: Center(child: Text('Programme introuvable')));
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(current.name),
        actions: [
          if (!current.isActive)
            TextButton(
              onPressed: () => state.setActiveProgram(current.id!),
              child: const Text('Activer'),
            ),
          PopupMenuButton<String>(
            onSelected: (value) async {
              if (value == 'delete') await _confirmDeleteProgram();
            },
            itemBuilder: (context) => const [
              PopupMenuItem(
                value: 'delete',
                child: Text('Supprimer'),
              ),
            ],
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addSession,
        child: const Icon(Icons.add),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _sessions.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('Aucune séance dans ce programme.'),
                        const SizedBox(height: 16),
                        FilledButton(
                          onPressed: _addSession,
                          child: const Text('Ajouter une séance'),
                        ),
                      ],
                    ),
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 88),
                  itemCount: _sessions.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final session = _sessions[index];
                    return Card(
                      child: ListTile(
                        title: Text(
                          session.name,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        subtitle: Text('Séance ${index + 1}'),
                        trailing: PopupMenuButton<String>(
                          onSelected: (value) async {
                            if (value == 'edit') {
                              await Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => SessionEditScreen(
                                    sessionId: session.id!,
                                  ),
                                ),
                              );
                              await _load();
                            } else if (value == 'start') {
                              await Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => SessionPlayerScreen(
                                    sessionId: session.id!,
                                  ),
                                ),
                              );
                            } else if (value == 'delete') {
                              final ok = await showDialog<bool>(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: const Text('Supprimer la séance ?'),
                                  actions: [
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.pop(context, false),
                                      child: const Text('Annuler'),
                                    ),
                                    FilledButton(
                                      onPressed: () =>
                                          Navigator.pop(context, true),
                                      child: const Text('Supprimer'),
                                    ),
                                  ],
                                ),
                              );
                              if (ok == true && context.mounted) {
                                await context
                                    .read<AppState>()
                                    .deleteSession(session.id!);
                                if (mounted) await _load();
                              }
                            }
                          },
                          itemBuilder: (context) => const [
                            PopupMenuItem(
                              value: 'start',
                              child: Text('Démarrer'),
                            ),
                            PopupMenuItem(
                              value: 'edit',
                              child: Text('Modifier exercices'),
                            ),
                            PopupMenuItem(
                              value: 'delete',
                              child: Text('Supprimer'),
                            ),
                          ],
                        ),
                        onTap: () async {
                          await Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => SessionEditScreen(
                                sessionId: session.id!,
                              ),
                            ),
                          );
                          await _load();
                        },
                      ),
                    );
                  },
                ),
    );
  }
}
