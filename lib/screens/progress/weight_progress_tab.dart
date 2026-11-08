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

  Future<void> _addWeight(BuildContext context) async {
    final state = context.read<AppState>();
    final weightCtrl = TextEditingController(
      text: state.weightLogs.isEmpty
          ? ''
          : (state.weightLogs.last.weight ==
                    state.weightLogs.last.weight.roundToDouble()
                ? '${state.weightLogs.last.weight.toInt()}'
                : state.weightLogs.last.weight.toStringAsFixed(1)),
    );
    var date = DateTime.now();

    final saved = await showDialog<bool>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setLocal) {
            return AlertDialog(
              title: const Text('Ajouter un poids'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: weightCtrl,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'Poids (kg)',
                      hintText: 'ex. 78.5',
                    ),
                    autofocus: true,
                  ),
                  const SizedBox(height: 12),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Date'),
                    subtitle: Text(
                      DateFormat('d MMMM yyyy', 'fr_FR').format(date),
                    ),
                    trailing: const Icon(Icons.calendar_today_outlined),
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: date,
                        firstDate: DateTime(2020),
                        lastDate: DateTime.now().add(const Duration(days: 1)),
                        locale: const Locale('fr', 'FR'),
                      );
                      if (picked != null) {
                        setLocal(() => date = picked);
                      }
                    },
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
                  child: const Text('Enregistrer'),
                ),
              ],
            );
          },
        );
      },
    );

    if (saved != true || !context.mounted) {
      weightCtrl.dispose();
      return;
    }

    final weight = double.tryParse(weightCtrl.text.trim().replaceAll(',', '.'));
    weightCtrl.dispose();
    if (weight == null || weight <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Entre un poids valide.')),
      );
      return;
    }

    await state.saveWeightLog(
      BodyWeightLog(
        weighedAt: DateTime(date.year, date.month, date.day),
        weight: weight,
      ),
    );
  }

  Future<void> _editGoal(BuildContext context) async {
    final state = context.read<AppState>();
    final current = state.weightLogs.isEmpty
        ? null
        : state.weightLogs.last.weight;
    final startCtrl = TextEditingController(
      text: state.weightGoal != null
          ? _plain(state.weightGoal!.startWeight)
          : (current == null ? '' : _plain(current)),
    );
    final targetCtrl = TextEditingController(
      text: state.weightGoal == null
          ? ''
          : _plain(state.weightGoal!.targetWeight),
    );

    final saved = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(
            state.weightGoal == null
                ? 'Définir un objectif'
                : 'Modifier l’objectif',
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: startCtrl,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  labelText: 'Poids de départ (kg)',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: targetCtrl,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  labelText: 'Poids cible (kg)',
                ),
                autofocus: true,
              ),
            ],
          ),
          actions: [
            if (state.weightGoal != null)
              TextButton(
                onPressed: () async {
                  await state.clearWeightGoal();
                  if (context.mounted) Navigator.pop(context, false);
                },
                child: const Text('Supprimer'),
              ),
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Annuler'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Enregistrer'),
            ),
          ],
        );
      },
    );

    if (saved != true || !context.mounted) {
      startCtrl.dispose();
      targetCtrl.dispose();
      return;
    }

    final start = double.tryParse(startCtrl.text.trim().replaceAll(',', '.'));
    final target = double.tryParse(targetCtrl.text.trim().replaceAll(',', '.'));
    startCtrl.dispose();
    targetCtrl.dispose();

    if (start == null || start <= 0 || target == null || target <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Entre des poids valides.')),
      );
      return;
    }

    await state.saveWeightGoal(
      WeightGoal(
        startWeight: start,
        targetWeight: target,
        createdAt: DateTime.now(),
      ),
    );
  }

  String _plain(double value) {
    return value == value.roundToDouble()
        ? '${value.toInt()}'
        : value.toStringAsFixed(1);
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
                label: Text(goal == null ? 'Objectif' : 'Modifier'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (goal != null) ...[
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Objectif de poids',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _StatChip(
                        label: 'Départ',
                        value: _formatKg(goal.startWeight),
                      ),
                      const SizedBox(width: 8),
                      _StatChip(
                        label: 'Actuel',
                        value: current == null ? '—' : _formatKg(current),
                      ),
                      const SizedBox(width: 8),
                      _StatChip(
                        label: 'Cible',
                        value: _formatKg(goal.targetWeight),
                      ),
                    ],
                  ),
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
                    '${(progress * 100).round()}% vers l’objectif',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
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
                              interval: (logs.length / 3).clamp(1, 10).toDouble(),
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
                                      labelResolver: (_) => 'cible',
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
              return await showDialog<bool>(
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
            },
            onDismissed: (_) {
              if (log.id != null) {
                state.deleteWeightLog(log.id!);
              }
            },
            child: Card(
              child: ListTile(
                title: Text(
                  _formatKg(log.weight),
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                subtitle: Text(
                  DateFormat('EEEE d MMMM yyyy', 'fr_FR').format(log.weighedAt),
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

class _StatChip extends StatelessWidget {
  const _StatChip({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: theme.scaffoldBackgroundColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
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
    );
  }
}
