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
                const Text('Восстановление', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const Spacer(),
                _RecoveryCircle(index: result.recoveryIndex, color: color),
              ],
            ),
            const SizedBox(height: 12),
            // Scores breakdown
            _ScoreRow(label: 'Сон', value: result.sleepScore, max: 50),
            const SizedBox(height: 4),
            _ScoreRow(label: 'Активность', value: result.activityScore, max: 30),
            const SizedBox(height: 4),
            _ScoreRow(label: 'Пульс', value: result.heartRateScore, max: 20),
            const Divider(height: 20),
            Text(
              result.explanation,
              style: theme.textTheme.bodyMedium,
            ),
            if (alarmHour != null) ...[
              const SizedBox(height: 8),
              _OptimalWakeRow(
                baseHour: alarmHour!,
                baseMinute: alarmMinute!,
                offsetMinutes: result.wakeTimeOffset,
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
            style: TextStyle(fontWeight: FontWeight.bold, color: color, fontSize: 16),
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
        SizedBox(width: 80, child: Text(label, style: const TextStyle(fontSize: 12))),
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

class _OptimalWakeRow extends StatelessWidget {
  final int baseHour;
  final int baseMinute;
  final int offsetMinutes;
  const _OptimalWakeRow({
    required this.baseHour,
    required this.baseMinute,
    required this.offsetMinutes,
  });

  @override
  Widget build(BuildContext context) {
    final totalMinutes = baseHour * 60 + baseMinute + offsetMinutes;
    final h = (totalMinutes ~/ 60) % 24;
    final m = totalMinutes % 60;
    final timeStr =
        '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}';
    final sign = offsetMinutes > 0 ? '+' : '';

    final accent = Theme.of(context).colorScheme.primary;
    return Row(
      children: [
        Icon(Icons.alarm, size: 16, color: accent),
        const SizedBox(width: 4),
        Text(
          'Оптимальный подъём: $timeStr ($sign${offsetMinutes} мин)',
          style: TextStyle(
            color: accent,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
