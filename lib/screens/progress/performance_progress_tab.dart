import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../models/performance.dart';
import '../../providers/app_state.dart';
import '../../widgets/empty_state.dart';

class PerformanceProgressTab extends StatelessWidget {
  const PerformanceProgressTab({super.key});

  String _formatKg(double value) {
    return value == value.roundToDouble()
        ? '${value.toInt()} kg'
        : '${value.toStringAsFixed(1)} kg';
  }

  String _deltaLabel(double? delta) {
    if (delta == null) return 'Première mesure';
    if (delta == 0) return 'Stable';
    final formatted = delta == delta.roundToDouble()
        ? '${delta.toInt()}'
        : delta.toStringAsFixed(1);
    return delta > 0 ? '+$formatted kg' : '$formatted kg';
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final theme = Theme.of(context);
    final summaries = state.performanceSummaries;

    if (summaries.isEmpty) {
      return const EmptyState(
        icon: Icons.trending_up,
        title: 'Aucune performance',
        subtitle:
            'Enregistre des séances avec des charges pour voir ta progression par exercice.',
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
      itemCount: summaries.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final summary = summaries[index];
        final latest = summary.latest;
        final delta = summary.weightDelta;
        final deltaColor = delta == null
            ? theme.colorScheme.onSurface.withValues(alpha: 0.6)
            : delta > 0
                ? const Color(0xFF3DDC97)
                : delta < 0
                    ? theme.colorScheme.error
                    : theme.colorScheme.onSurface.withValues(alpha: 0.6);

        return Card(
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () => _openDetail(context, summary),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          summary.name,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          latest == null
                              ? 'Pas encore de charge'
                              : 'Max : ${_formatKg(latest.maxWeight)} · ${summary.points.length} séance${summary.points.length > 1 ? 's' : ''}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface.withValues(
                              alpha: 0.7,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        _deltaLabel(delta),
                        style: theme.textTheme.titleSmall?.copyWith(
                          color: deltaColor,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Icon(
                        Icons.chevron_right,
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.4,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _openDetail(BuildContext context, ExercisePerformanceSummary summary) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => _ExercisePerformanceDetail(summary: summary),
      ),
    );
  }
}

class _ExercisePerformanceDetail extends StatelessWidget {
  const _ExercisePerformanceDetail({required this.summary});

  final ExercisePerformanceSummary summary;

  String _formatKg(double value) {
    return value == value.roundToDouble()
        ? '${value.toInt()} kg'
        : '${value.toStringAsFixed(1)} kg';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final points = summary.points;
    final dateFormat = DateFormat('d MMM', 'fr_FR');
    final fullDate = DateFormat('EEEE d MMMM yyyy', 'fr_FR');

    return Scaffold(
      appBar: AppBar(title: Text(summary.name)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          if (points.length >= 2)
            Card(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 16, 16, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(left: 4, bottom: 12),
                      child: Text(
                        'Charge max par séance',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    SizedBox(
                      height: 220,
                      child: LineChart(
                        LineChartData(
                          minY: _minY(points),
                          maxY: _maxY(points),
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
                                    (points.length / 3).clamp(1, 10).toDouble(),
                                getTitlesWidget: (value, meta) {
                                  final index = value.round();
                                  if (index < 0 || index >= points.length) {
                                    return const SizedBox.shrink();
                                  }
                                  return Padding(
                                    padding: const EdgeInsets.only(top: 6),
                                    child: Text(
                                      dateFormat.format(points[index].date),
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
                                for (var i = 0; i < points.length; i++)
                                  FlSpot(i.toDouble(), points[i].maxWeight),
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
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 16),
          Text(
            'Histororique',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          ...points.reversed.map((point) {
            return Card(
              child: ListTile(
                title: Text(
                  _formatKg(point.maxWeight),
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                subtitle: Text(fullDate.format(point.date)),
                trailing: Text(
                  '${point.totalReps} reps',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  double _minY(List<ExercisePerformancePoint> points) {
    final min = points.map((e) => e.maxWeight).reduce((a, b) => a < b ? a : b);
    return (min - 5).clamp(0, double.infinity);
  }

  double _maxY(List<ExercisePerformancePoint> points) {
    return points.map((e) => e.maxWeight).reduce((a, b) => a > b ? a : b) + 5;
  }
}
