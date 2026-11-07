import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../models/exercise.dart';
import '../../models/workout_log.dart';
import '../../providers/app_state.dart';
import '../../widgets/empty_state.dart';

class ProgressScreen extends StatefulWidget {
  const ProgressScreen({super.key});

  @override
  State<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen> {
  Exercise? _selected;
  List<ProgressPoint> _points = [];
  bool _loadingChart = false;

  Future<void> _loadChart(Exercise exercise) async {
    setState(() {
      _selected = exercise;
      _loadingChart = true;
    });
    final points = await context
        .read<AppState>()
        .workouts
        .getProgressForExercise(exercise.id!);
    if (!mounted) return;
    setState(() {
      _points = points;
      _loadingChart = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final theme = Theme.of(context);
    final exercises = state.exerciseList;

    return Scaffold(
      appBar: AppBar(title: const Text('Progression')),
      body: exercises.isEmpty
          ? const EmptyState(
              icon: Icons.show_chart,
              title: 'Pas encore de données',
              subtitle: 'Les exercices apparaîtront ici.',
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
              children: [
                Text(
                  'Choisis un exercice',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<Exercise>(
                  initialValue: _selected,
                  items: exercises
                      .map(
                        (e) => DropdownMenuItem(
                          value: e,
                          child: Text(e.name),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value != null) _loadChart(value);
                  },
                  decoration: const InputDecoration(
                    labelText: 'Exercice',
                  ),
                ),
                const SizedBox(height: 24),
                if (_selected == null)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Text(
                        'Sélectionne un exercice pour voir ton évolution.',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurface
                              .withValues(alpha: 0.7),
                        ),
                      ),
                    ),
                  )
                else if (_loadingChart)
                  const Padding(
                    padding: EdgeInsets.all(40),
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (_points.isEmpty)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Text(
                        'Aucune perf enregistrée pour ${_selected!.name}. '
                        'Fais une séance pour commencer le suivi.',
                      ),
                    ),
                  )
                else ...[
                  Text(
                    'Charge max (kg)',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 240,
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(12, 20, 20, 12),
                        child: LineChart(
                          LineChartData(
                            minY: 0,
                            gridData: FlGridData(
                              show: true,
                              drawVerticalLine: false,
                              getDrawingHorizontalLine: (value) => FlLine(
                                color: theme.colorScheme.onSurface
                                    .withValues(alpha: 0.08),
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
                                  reservedSize: 36,
                                  getTitlesWidget: (value, meta) => Text(
                                    value.toInt().toString(),
                                    style: theme.textTheme.labelSmall,
                                  ),
                                ),
                              ),
                              bottomTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  reservedSize: 28,
                                  interval: (_points.length / 3)
                                      .clamp(1, double.infinity)
                                      .toDouble(),
                                  getTitlesWidget: (value, meta) {
                                    final i = value.toInt();
                                    if (i < 0 || i >= _points.length) {
                                      return const SizedBox.shrink();
                                    }
                                    return Text(
                                      DateFormat.Md('fr')
                                          .format(_points[i].date),
                                      style: theme.textTheme.labelSmall,
                                    );
                                  },
                                ),
                              ),
                            ),
                            lineBarsData: [
                              LineChartBarData(
                                spots: [
                                  for (var i = 0; i < _points.length; i++)
                                    FlSpot(i.toDouble(), _points[i].maxWeight),
                                ],
                                isCurved: true,
                                color: theme.colorScheme.primary,
                                barWidth: 3,
                                dotData: const FlDotData(show: true),
                                belowBarData: BarAreaData(
                                  show: true,
                                  color: theme.colorScheme.primary
                                      .withValues(alpha: 0.15),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Histororique',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ..._points.reversed.map((point) {
                    return Card(
                      child: ListTile(
                        title: Text(
                          DateFormat.yMMMd('fr').format(point.date),
                        ),
                        subtitle: Text(
                          'Volume : ${point.volume.toStringAsFixed(0)} kg',
                        ),
                        trailing: Text(
                          '${point.maxWeight.toStringAsFixed(point.maxWeight % 1 == 0 ? 0 : 1)} kg',
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    );
                  }),
                ],
              ],
            ),
    );
  }
}
