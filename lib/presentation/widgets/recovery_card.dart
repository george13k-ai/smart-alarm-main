import 'package:flutter/material.dart';
import '../../core/utils/recovery_algorithm.dart';

class RecoveryCard extends StatelessWidget {
  final RecoveryResult result;
  final int? alarmHour;
  final int? alarmMinute;

  const RecoveryCard({
    super.key,
    required this.result,
    this.alarmHour,
    this.alarmMinute,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = _indexColor(result.recoveryIndex);

    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text(
                  'Восстановление',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                _RecoveryCircle(index: result.recoveryIndex, color: color),
              ],
            ),
            const SizedBox(height: 12),
            _ScoreRow(label: 'Сон', value: result.sleepScore, max: 50),
            const SizedBox(height: 4),
            _ScoreRow(label: 'Активность', value: result.activityScore, max: 30),
            const SizedBox(height: 4),
            _ScoreRow(label: 'Пульс', value: result.heartRateScore, max: 20),
            const Divider(height: 20),
            Text(result.explanation, style: theme.textTheme.bodyMedium),
            if (alarmHour != null) ...[
              const SizedBox(height: 12),
              _SleepCycleRow(
                alarmHour: alarmHour!,
                alarmMinute: alarmMinute!,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Color _indexColor(int index) {
    if (index >= 75) return Colors.green;
    if (index >= 50) return Colors.orange;
    return Colors.red;
  }
}

class _RecoveryCircle extends StatelessWidget {
  final int index;
  final Color color;
  const _RecoveryCircle({required this.index, required this.color});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 56,
      height: 56,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CircularProgressIndicator(
            value: index / 100,
            strokeWidth: 5,
            valueColor: AlwaysStoppedAnimation(color),
            backgroundColor: color.withOpacity(0.2),
          ),
          Text(
            '$index',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: color,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }
}

class _ScoreRow extends StatelessWidget {
  final String label;
  final int value;
  final int max;
  const _ScoreRow({required this.label, required this.value, required this.max});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 80,
          child: Text(label, style: const TextStyle(fontSize: 12)),
        ),
        Expanded(
          child: LinearProgressIndicator(
            value: value / max,
            minHeight: 6,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 8),
        Text('$value/$max', style: const TextStyle(fontSize: 11)),
      ],
    );
  }
}

/// Shows recommended bedtimes calculated from alarm time using 90-min sleep cycles.
/// Two options: 5 cycles (7h 30m sleep + 15m to fall asleep) and 4 cycles (6h + 15m).
class _SleepCycleRow extends StatelessWidget {
  final int alarmHour;
  final int alarmMinute;

  const _SleepCycleRow({
    required this.alarmHour,
    required this.alarmMinute,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final alarmTotal = alarmHour * 60 + alarmMinute;

    // Cycles to show: 5 (7h30m) and 4 (6h); add 15 min to fall asleep
    final options = [6, 5, 4].map((cycles) {
      final sleepMin = cycles * 90 + 15;
      final bedTotal = (alarmTotal - sleepMin + 24 * 60) % (24 * 60);
      final h = bedTotal ~/ 60;
      final m = bedTotal % 60;
      return (
        time: '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}',
        cycles: cycles,
        hoursStr: '${cycles * 90 ~/ 60}ч ${cycles * 90 % 60 > 0 ? '${cycles * 90 % 60}м' : ''}',
      );
    }).toList();

    final accent = theme.colorScheme.primary;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.bedtime_outlined, size: 15, color: accent),
            const SizedBox(width: 6),
            Text(
              'Ложитесь спать (цикл сна = 90 мин):',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: accent,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ...options.map(
          (o) => Padding(
            padding: const EdgeInsets.only(bottom: 3, left: 4),
            child: Row(
              children: [
                Text(
                  o.time,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: accent,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '— ${o.hoursStr} сна (${o.cycles} цикла)',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '+15 мин на засыпание уже учтены',
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurface.withOpacity(0.4),
          ),
        ),
      ],
    );
  }
}
