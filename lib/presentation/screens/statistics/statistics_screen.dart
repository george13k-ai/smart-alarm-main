import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../domain/entities/health_data.dart';
import '../../providers/achievement_provider.dart';
import '../../providers/health_provider.dart';

class StatisticsScreen extends ConsumerStatefulWidget {
  const StatisticsScreen({super.key});

  @override
  ConsumerState<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends ConsumerState<StatisticsScreen>
    with SingleTickerProviderStateMixin {
  int _days = 7;
  late TabController _tabs;
  bool _syncInProgress = false;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  Future<void> _syncData() async {
    if (_syncInProgress) return;
    setState(() => _syncInProgress = true);

    try {
      await ref.read(todayRecoveryProvider.notifier).sync();
      await ref.read(achievementProvider.notifier).refreshProgress();

      ref.invalidate(summariesProvider(_days));
      final summaries = await ref.read(summariesProvider(_days).future);

      if (!mounted) return;

      if (summaries.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Данные пока не поступили. Проверьте доступы Health Connect.',
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Синхронизация завершена: ${summaries.length} дн.'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка синхронизации: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _syncInProgress = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final summariesAsync = ref.watch(summariesProvider(_days));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Статистика'),
        bottom: TabBar(
          controller: _tabs,
          tabs: const [
            Tab(text: 'Сон'),
            Tab(text: 'Активность'),
            Tab(text: 'Восстановление'),
          ],
        ),
        actions: [
          IconButton(
            icon: _syncInProgress
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.sync),
            tooltip: 'Синхронизировать данные',
            onPressed: _syncInProgress ? null : _syncData,
          ),
          SegmentedButton<int>(
            segments: const [
              ButtonSegment(value: 7, label: Text('7д')),
              ButtonSegment(value: 30, label: Text('30д')),
            ],
            selected: {_days},
            onSelectionChanged: (s) => setState(() => _days = s.first),
            style: const ButtonStyle(
              visualDensity: VisualDensity.compact,
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: summariesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Ошибка: $e')),
        data: (summaries) => TabBarView(
          controller: _tabs,
          children: [
            _SleepChart(summaries: summaries),
            _ActivityChart(summaries: summaries),
            _RecoveryChart(summaries: summaries),
          ],
        ),
      ),
    );
  }
}

// ---- Графики ----

class _SleepChart extends StatelessWidget {
  final List<DailyHealthSummary> summaries;
  const _SleepChart({required this.summaries});

  @override
  Widget build(BuildContext context) {
    if (summaries.isEmpty) return const _EmptyChart();

    final bars = summaries.asMap().entries.map((e) {
      final hours = e.value.sleepMinutes / 60.0;
      return BarChartGroupData(
        x: e.key,
        barRods: [
          BarChartRodData(
            toY: hours,
            color: hours >= 7 ? Colors.blue : Colors.orange,
            width: 14,
            borderRadius: BorderRadius.circular(4),
          ),
        ],
      );
    }).toList();

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _MetricRow(
            label: 'Среднее',
            value:
                '${_avg(summaries.map((s) => s.sleepMinutes / 60.0).toList()).toStringAsFixed(1)} ч',
          ),
          const SizedBox(height: 12),
          Expanded(
            child: BarChart(
              BarChartData(
                barGroups: bars,
                barTouchData: BarTouchData(
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipItem: (group, _, rod, __) => BarTooltipItem(
                      '${rod.toY.toStringAsFixed(2)} ч',
                      const TextStyle(color: Colors.white),
                    ),
                  ),
                ),
                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (v, _) => _dateLabel(summaries, v),
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 32,
                      getTitlesWidget: (v, _) => Text('${v.toInt()}ч',
                          style: const TextStyle(fontSize: 10)),
                    ),
                  ),
                  topTitles: const AxisTitles(sideTitles: SideTitles()),
                  rightTitles: const AxisTitles(sideTitles: SideTitles()),
                ),
                gridData: const FlGridData(show: true),
                borderData: FlBorderData(show: false),
                maxY: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActivityChart extends StatelessWidget {
  final List<DailyHealthSummary> summaries;
  const _ActivityChart({required this.summaries});

  @override
  Widget build(BuildContext context) {
    if (summaries.isEmpty) return const _EmptyChart();

    final spots = summaries.asMap().entries.map((e) {
      return FlSpot(e.key.toDouble(), e.value.steps.toDouble());
    }).toList();

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _MetricRow(
            label: 'Среднее',
            value:
                '${_avg(summaries.map((s) => s.steps.toDouble()).toList()).toStringAsFixed(0)} шагов',
          ),
          const SizedBox(height: 12),
          Expanded(
            child: LineChart(
              LineChartData(
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    color: Colors.green,
                    barWidth: 3,
                    dotData: const FlDotData(show: true),
                    belowBarData: BarAreaData(
                      show: true,
                      color: Colors.green.withOpacity(0.15),
                    ),
                  ),
                  // Линия цели (10 000)
                  LineChartBarData(
                    spots: List.generate(
                      summaries.length,
                      (i) => FlSpot(i.toDouble(), 10000),
                    ),
                    isCurved: false,
                    color: Colors.red.withOpacity(0.5),
                    barWidth: 1,
                    dashArray: [6, 4],
                    dotData: const FlDotData(show: false),
                  ),
                ],
                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (v, _) => _dateLabel(summaries, v),
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 48,
                      getTitlesWidget: (v, _) => Text(
                        '${(v / 1000).toStringAsFixed(0)}к',
                        style: const TextStyle(fontSize: 10),
                      ),
                    ),
                  ),
                  topTitles: const AxisTitles(sideTitles: SideTitles()),
                  rightTitles: const AxisTitles(sideTitles: SideTitles()),
                ),
                gridData: const FlGridData(show: true),
                borderData: FlBorderData(show: false),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RecoveryChart extends StatelessWidget {
  final List<DailyHealthSummary> summaries;
  const _RecoveryChart({required this.summaries});

  @override
  Widget build(BuildContext context) {
    if (summaries.isEmpty) return const _EmptyChart();

    final spots = summaries.asMap().entries.map((e) {
      return FlSpot(e.key.toDouble(), e.value.recoveryIndex.toDouble());
    }).toList();

    final avgIndex =
        _avg(summaries.map((s) => s.recoveryIndex.toDouble()).toList());

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _MetricRow(
                  label: 'Средний индекс', value: avgIndex.toStringAsFixed(0)),
              const SizedBox(width: 24),
              _MetricRow(
                label: 'Макс',
                value: summaries
                    .map((s) => s.recoveryIndex)
                    .reduce((a, b) => a > b ? a : b)
                    .toString(),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: LineChart(
              LineChartData(
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    gradient: const LinearGradient(
                      colors: [Colors.red, Colors.orange, Colors.green],
                    ),
                    barWidth: 3,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, _, __, ___) => FlDotCirclePainter(
                        radius: 4,
                        color: _recoveryColor(spot.y.toInt()),
                        strokeWidth: 0,
                      ),
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        colors: [
                          Colors.green.withOpacity(0.1),
                          Colors.red.withOpacity(0.1),
                        ],
                      ),
                    ),
                  ),
                ],
                minY: 0,
                maxY: 100,
                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (v, _) => _dateLabel(summaries, v),
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 32,
                      getTitlesWidget: (v, _) => Text('${v.toInt()}',
                          style: const TextStyle(fontSize: 10)),
                    ),
                  ),
                  topTitles: const AxisTitles(sideTitles: SideTitles()),
                  rightTitles: const AxisTitles(sideTitles: SideTitles()),
                ),
                gridData: const FlGridData(show: true),
                borderData: FlBorderData(show: false),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _recoveryColor(int index) {
    if (index >= 75) return Colors.green;
    if (index >= 50) return Colors.orange;
    return Colors.red;
  }
}

// ---- Helpers ----

class _EmptyChart extends StatelessWidget {
  const _EmptyChart();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.bar_chart, size: 64, color: Colors.grey),
          SizedBox(height: 12),
          Text(
            'Нет данных.\nНажмите кнопку синхронизации вверху экрана.',
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _MetricRow extends StatelessWidget {
  final String label;
  final String value;
  const _MetricRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return RichText(
      text: TextSpan(
        style: DefaultTextStyle.of(context).style,
        children: [
          TextSpan(
            text: '$label: ',
            style: const TextStyle(color: Colors.grey, fontSize: 13),
          ),
          TextSpan(
            text: value,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
        ],
      ),
    );
  }
}

Widget _dateLabel(List<DailyHealthSummary> summaries, double value) {
  final index = value.round();
  if ((value - index).abs() > 0.001) return const SizedBox.shrink();
  if (index < 0 || index >= summaries.length) return const SizedBox.shrink();

  final step = (summaries.length / 6).ceil().clamp(1, 99);
  final isLast = index == summaries.length - 1;
  if (!isLast && index % step != 0) return const SizedBox.shrink();

  final d = summaries[index].date;
  return Padding(
    padding: const EdgeInsets.only(top: 4),
    child: Text(
      DateFormat('dd.MM').format(d),
      style: const TextStyle(fontSize: 9),
    ),
  );
}

double _avg(List<double> values) {
  if (values.isEmpty) return 0;
  return values.reduce((a, b) => a + b) / values.length;
}
