import '../../repositories/health_repository.dart';
import '../../entities/health_data.dart';
import '../../../core/utils/recovery_algorithm.dart';

class SyncHealthDataUseCase {
  final HealthRepository _repo;
  SyncHealthDataUseCase(this._repo);

  Future<void> call() async {
    await _repo.syncFromHealthConnect(days: 7);
    await _recalculateSummaries();
  }

  Future<void> _recalculateSummaries() async {
    final sleepList = await _repo.getSleepData(days: 7);
    final activityList = await _repo.getActivityData(days: 7);

    // Группируем по дате (только дата без времени)
    final Map<String, SleepData> sleepByDate = {};
    for (final s in sleepList) {
      final key = _dateKey(s.date);
      // Берём последнюю запись за день
      sleepByDate[key] = s;
    }

    final Map<String, ActivityData> activityByDate = {};
    for (final a in activityList) {
      final key = _dateKey(a.date);
      activityByDate[key] = a;
    }

    final allKeys = {...sleepByDate.keys, ...activityByDate.keys};
    for (final key in allKeys) {
      final sleep = sleepByDate[key];
      final activity = activityByDate[key];
      final result = calculateRecovery(
        sleepMinutes: sleep?.durationMinutes ?? 0,
        steps: activity?.steps ?? 0,
        heartRate: activity?.heartRate,
      );
      final parts = key.split('-');
      final date = DateTime(
        int.parse(parts[0]),
        int.parse(parts[1]),
        int.parse(parts[2]),
      );
      await _repo.saveDailySummary(DailyHealthSummary(
        date: date,
        sleepMinutes: sleep?.durationMinutes ?? 0,
        steps: activity?.steps ?? 0,
        heartRate: activity?.heartRate,
        recoveryIndex: result.recoveryIndex,
        wakeTimeOffset: result.wakeTimeOffset,
      ));
    }
  }

  String _dateKey(DateTime dt) =>
      '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
}
