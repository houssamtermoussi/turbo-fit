import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../models/body_weight.dart';
import '../../providers/app_state.dart';
import '../../widgets/empty_state.dart';

class WeightProgressTab extends StatelessWidget {
  const WeightProgressTab({super.key});

  String _formatKg(double value) {
    return value == value.roundToDouble()
        ? '${value.toInt()} kg'
        : '${value.toStringAsFixed(1)} kg';
  }

  String _plain(double value) {
    return value == value.roundToDouble()
        ? '${value.toInt()}'
        : value.toStringAsFixed(1);
  }

  Future<void> _addWeight(BuildContext context) async {
    final state = context.read<AppState>();
    final initial = state.weightLogs.isEmpty
        ? ''
        : _plain(state.weightLogs.last.weight);

    final result = await showDialog<_WeightDraft>(
      context: context,
      builder: (context) => _WeightLogDialog(initialWeight: initial),
    );

    if (result == null || !context.mounted) return;
    await _saveWeightDraft(state, result);
  }

  Future<void> _editCurrentWeight(BuildContext context) async {
    final state = context.read<AppState>();
    final last = state.weightLogs.isEmpty ? null : state.weightLogs.last;

    final result = await showDialog<_WeightDraft>(
      context: context,
      builder: (context) => _WeightLogDialog(
        initialWeight: last == null ? '' : _plain(last.weight),
        title: 'Modifier le poids actuel',
        initialDate: last?.weighedAt,
      ),
    );

    if (result == null || !context.mounted) return;

    final date = result.date!;
    final weighedAt = DateTime(date.year, date.month, date.day);
    final sameDay = last != null &&
        last.weighedAt.year == weighedAt.year &&
        last.weighedAt.month == weighedAt.month &&
        last.weighedAt.day == weighedAt.day;

    await _saveWeightDraft(
      state,
      result,
      id: sameDay ? last.id : null,
    );
  }

  Future<void> _editWeightLog(
    BuildContext context,
    BodyWeightLog log,
  ) async {
    final state = context.read<AppState>();
    final result = await showDialog<_WeightDraft>(
      context: context,
      builder: (context) => _WeightLogDialog(
        initialWeight: _plain(log.weight),
        title: 'Modifier la mesure',
        initialDate: log.weighedAt,
        canDelete: log.id != null,
      ),
    );

    if (result == null || !context.mounted) return;

    if (result.delete) {
      if (log.id != null) {
        await state.deleteWeightLog(log.id!);
      }
      return;
    }

    await _saveWeightDraft(state, result, id: log.id);
  }

  Future<bool> _confirmDeleteWeight(
    BuildContext context,
    BodyWeightLog log,
  ) async {
    final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Supprimer ?'),
            content: Text(
              'Supprimer la mesure du ${DateFormat('d MMMM yyyy', 'fr_FR').format(log.weighedAt)} ?',
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
        ) ??
        false;

    if (!confirmed || log.id == null || !context.mounted) return false;
    await context.read<AppState>().deleteWeightLog(log.id!);
    return true;
  }

  Future<void> _saveWeightDraft(
    AppState state,
    _WeightDraft result, {
    int? id,
  }) async {
    final date = result.date!;
    await state.saveWeightLog(
      BodyWeightLog(
        id: id,
        weighedAt: DateTime(date.year, date.month, date.day),
        weight: result.weight,
      ),
    );
  }

  Future<void> _editGoal(BuildContext context) async {
    final state = context.read<AppState>();
    final current = state.weightLogs.isEmpty
        ? null
        : state.weightLogs.last.weight;

    final result = await showDialog<_GoalDraft>(
      context: context,
      builder: (context) => _GoalDialog(
        initialTarget: state.weightGoal == null
            ? ''
            : _plain(state.weightGoal!.targetWeight),
        canDelete: state.weightGoal != null,
      ),
    );

    if (!context.mounted || result == null) return;

    if (result.delete) {
      await state.clearWeightGoal();
      return;
    }

    final target = result.target;
    if (target == null || target <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Entre un but valide.')),
      );
      return;
    }

    final start = current ?? state.weightGoal?.startWeight ?? target;

    await state.saveWeightGoal(
      WeightGoal(
        startWeight: state.weightGoal?.startWeight ?? start,
        targetWeight: target,
        createdAt: state.weightGoal?.createdAt ?? DateTime.now(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final theme = Theme.of(context);
    final logs = state.weightLogs;
    final goal = state.weightGoal;
    final current = logs.isEmpty ? null : logs.last.weight;
    final dateFormat = DateFormat('d MMM', 'fr_FR');

    if (logs.isEmpty && goal == null) {
      return EmptyState(
        icon: Icons.monitor_weight_outlined,
        title: 'Suivi du poids',
        subtitle:
            'Ajoute ton poids et définis un objectif pour suivre ta progression.',
        actionLabel: 'Ajouter un poids',
        onAction: () => _addWeight(context),
      );
    }

    final progress = goal?.progressRatio(current) ?? 0;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
      children: [
        Row(
          children: [
            Expanded(
              child: FilledButton.tonalIcon(
                onPressed: () => _addWeight(context),
                icon: const Icon(Icons.add),
                label: const Text('Poids'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _editGoal(context),
                icon: const Icon(Icons.flag_outlined),
                label: Text(goal == null ? 'But' : 'Modifier'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _StatChip(
                      label: 'Actuel',
                      value: current == null ? '—' : _formatKg(current),
                      onTap: () => _editCurrentWeight(context),
                    ),
                    const SizedBox(width: 10),
                    _StatChip(
                      label: 'But',
                      value: goal == null
                          ? '—'
                          : _formatKg(goal.targetWeight),
                      onTap: () => _editGoal(context),
                    ),
                  ],
                ),
                if (goal != null && current != null) ...[
                  const SizedBox(height: 14),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 10,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${(progress * 100).round()}% vers le but',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        if (logs.length >= 2) ...[
          Card(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 16, 16, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(left: 4, bottom: 12),
                    child: Text(
                      'Courbe de poids',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  SizedBox(
                    height: 200,
                    child: LineChart(
                      LineChartData(
                        minY: _chartMin(logs, goal),
                        maxY: _chartMax(logs, goal),
                        gridData: FlGridData(
                          show: true,
                          drawVerticalLine: false,
                          getDrawingHorizontalLine: (value) => FlLine(
                            color: theme.colorScheme.onSurface.withValues(
                              alpha: 0.08,
                            ),
                            strokeWidth: 1,
                          ),
                        ),
                        borderData: FlBorderData(show: false),
                        titlesData: FlTitlesData(
                          topTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          rightTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 40,
                              getTitlesWidget: (value, meta) {
                                return Text(
                                  value.toStringAsFixed(0),
                                  style: theme.textTheme.labelSmall,
                                );
                              },
                            ),
                          ),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              interval:
                                  (logs.length / 3).clamp(1, 10).toDouble(),
                              getTitlesWidget: (value, meta) {
                                final index = value.round();
                                if (index < 0 || index >= logs.length) {
                                  return const SizedBox.shrink();
                                }
                                return Padding(
                                  padding: const EdgeInsets.only(top: 6),
                                  child: Text(
                                    dateFormat.format(logs[index].weighedAt),
                                    style: theme.textTheme.labelSmall,
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                        lineBarsData: [
                          LineChartBarData(
                            spots: [
                              for (var i = 0; i < logs.length; i++)
                                FlSpot(i.toDouble(), logs[i].weight),
                            ],
                            isCurved: true,
                            color: theme.colorScheme.primary,
                            barWidth: 3,
                            dotData: const FlDotData(show: true),
                            belowBarData: BarAreaData(
                              show: true,
                              color: theme.colorScheme.primary.withValues(
                                alpha: 0.15,
                              ),
                            ),
                          ),
                        ],
                        extraLinesData: goal == null
                            ? null
                            : ExtraLinesData(
                                horizontalLines: [
                                  HorizontalLine(
                                    y: goal.targetWeight,
                                    color: theme.colorScheme.secondary
                                        .withValues(alpha: 0.7),
                                    strokeWidth: 1.5,
                                    dashArray: [6, 4],
                                    label: HorizontalLineLabel(
                                      show: true,
                                      alignment: Alignment.topRight,
                                      style: theme.textTheme.labelSmall
                                          ?.copyWith(
                                            color: theme.colorScheme.secondary,
                                          ),
                                      labelResolver: (_) => 'but',
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
        Text(
          'Histororique',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        ...logs.reversed.map((log) {
          return Dismissible(
            key: ValueKey('weight_${log.id}'),
            direction: DismissDirection.endToStart,
            background: Container(
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.only(right: 20),
              color: theme.colorScheme.error,
              child: const Icon(Icons.delete_outline, color: Colors.white),
            ),
            confirmDismiss: (_) async {
              await _confirmDeleteWeight(context, log);
              // Parent rebuild removes the item; returning true would
              // conflict with the already-refreshed list.
              return false;
            },
            child: Card(
              child: ListTile(
                onTap: () => _editWeightLog(context, log),
                title: Text(
                  _formatKg(log.weight),
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                subtitle: Text(
                  DateFormat('EEEE d MMMM yyyy', 'fr_FR').format(log.weighedAt),
                ),
                trailing: IconButton(
                  tooltip: 'Supprimer',
                  icon: Icon(
                    Icons.delete_outline,
                    color: theme.colorScheme.error,
                  ),
                  onPressed: () => _confirmDeleteWeight(context, log),
                ),
              ),
            ),
          );
        }),
      ],
    );
  }

  double _chartMin(List<BodyWeightLog> logs, WeightGoal? goal) {
    final values = logs.map((e) => e.weight).toList();
    if (goal != null) {
      values.add(goal.targetWeight);
      values.add(goal.startWeight);
    }
    final min = values.reduce((a, b) => a < b ? a : b);
    return (min - 2).clamp(0, double.infinity);
  }

  double _chartMax(List<BodyWeightLog> logs, WeightGoal? goal) {
    final values = logs.map((e) => e.weight).toList();
    if (goal != null) {
      values.add(goal.targetWeight);
      values.add(goal.startWeight);
    }
    return values.reduce((a, b) => a > b ? a : b) + 2;
  }
}

class _WeightDraft {
  const _WeightDraft({
    required this.weight,
    required this.date,
  }) : delete = false;

  const _WeightDraft.delete()
      : weight = 0,
        date = null,
        delete = true;

  final double weight;
  final DateTime? date;
  final bool delete;
}

class _GoalDraft {
  const _GoalDraft({this.target, this.delete = false});

  final double? target;
  final bool delete;
}

class _WeightLogDialog extends StatefulWidget {
  const _WeightLogDialog({
    required this.initialWeight,
    this.title = 'Ajouter un poids',
    this.initialDate,
    this.canDelete = false,
  });

  final String initialWeight;
  final String title;
  final DateTime? initialDate;
  final bool canDelete;

  @override
  State<_WeightLogDialog> createState() => _WeightLogDialogState();
}

class _WeightLogDialogState extends State<_WeightLogDialog> {
  late final TextEditingController _weightCtrl;
  late DateTime _date;

  @override
  void initState() {
    super.initState();
    _weightCtrl = TextEditingController(text: widget.initialWeight);
    _date = widget.initialDate ?? DateTime.now();
  }

  @override
  void dispose() {
    _weightCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    final weight =
        double.tryParse(_weightCtrl.text.trim().replaceAll(',', '.'));
    if (weight == null || weight <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Entre un poids valide.')),
      );
      return;
    }
    Navigator.pop(context, _WeightDraft(weight: weight, date: _date));
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _weightCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'Poids (kg)',
              hintText: 'ex. 78.5',
            ),
            autofocus: true,
            onSubmitted: (_) => _submit(),
          ),
          const SizedBox(height: 12),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Date'),
            subtitle: Text(DateFormat('d MMMM yyyy', 'fr_FR').format(_date)),
            trailing: const Icon(Icons.calendar_today_outlined),
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: _date,
                firstDate: DateTime(2020),
                lastDate: DateTime.now().add(const Duration(days: 1)),
                locale: const Locale('fr', 'FR'),
              );
              if (picked != null) {
                setState(() => _date = picked);
              }
            },
          ),
        ],
      ),
      actions: [
        if (widget.canDelete)
          TextButton(
            onPressed: () =>
                Navigator.pop(context, const _WeightDraft.delete()),
            child: const Text('Supprimer'),
          ),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Annuler'),
        ),
        FilledButton(
          onPressed: _submit,
          child: const Text('Enregistrer'),
        ),
      ],
    );
  }
}

class _GoalDialog extends StatefulWidget {
  const _GoalDialog({
    required this.initialTarget,
    required this.canDelete,
  });

  final String initialTarget;
  final bool canDelete;

  @override
  State<_GoalDialog> createState() => _GoalDialogState();
}

class _GoalDialogState extends State<_GoalDialog> {
  late final TextEditingController _targetCtrl;

  @override
  void initState() {
    super.initState();
    _targetCtrl = TextEditingController(text: widget.initialTarget);
  }

  @override
  void dispose() {
    _targetCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    final target =
        double.tryParse(_targetCtrl.text.trim().replaceAll(',', '.'));
    Navigator.pop(context, _GoalDraft(target: target));
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.canDelete ? 'Modifier le but' : 'Définir le but'),
      content: TextField(
        controller: _targetCtrl,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        decoration: const InputDecoration(
          labelText: 'But (kg)',
          hintText: 'ex. 75',
        ),
        autofocus: true,
        onSubmitted: (_) => _submit(),
      ),
      actions: [
        if (widget.canDelete)
          TextButton(
            onPressed: () => Navigator.pop(context, const _GoalDraft(delete: true)),
            child: const Text('Supprimer'),
          ),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Annuler'),
        ),
        FilledButton(
          onPressed: _submit,
          child: const Text('Enregistrer'),
        ),
      ],
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({
    required this.label,
    required this.value,
    this.onTap,
  });

  final String label;
  final String value;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Expanded(
      child: Material(
        color: theme.scaffoldBackgroundColor,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        label,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onSurface
                              .withValues(alpha: 0.6),
                        ),
                      ),
                    ),
                    Icon(
                      Icons.edit_outlined,
                      size: 14,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
