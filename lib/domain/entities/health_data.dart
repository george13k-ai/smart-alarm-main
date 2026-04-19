class SleepData {
  final DateTime date;
  final int durationMinutes;
  final String source; // 'health_connect' | 'manual'

  const SleepData({
    required this.date,
    required this.durationMinutes,
    required this.source,
  });

  double get durationHours => durationMinutes / 60.0;
}

class ActivityData {
  final DateTime date;
  final int steps;
  final double? heartRate;

  const ActivityData({
    required this.date,
    required this.steps,
    this.heartRate,
  });
}

/// Агрегированные данные за один день для статистики
class DailyHealthSummary {
  final DateTime date;
  final int sleepMinutes;
  final int steps;
  final double? heartRate;
  final int recoveryIndex;
  final int wakeTimeOffset;

  const DailyHealthSummary({
    required this.date,
    required this.sleepMinutes,
    required this.steps,
    this.heartRate,
    required this.recoveryIndex,
    required this.wakeTimeOffset,
  });
}
