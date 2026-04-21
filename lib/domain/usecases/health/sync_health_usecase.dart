import '../../entities/health_data.dart';
import '../../repositories/health_repository.dart';
import '../../../core/utils/recovery_algorithm.dart';

class SyncHealthDataUseCase {
  final HealthRepository _repo;
  SyncHealthDataUseCase(this._repo);

  Future<void> call({int days = 30}) async {
    await _repo.syncFromHealthConnect(days: days);
    await _recalculateSummaries(days: days);
  }

  Future<void> _recalculateSummaries({required int days}) async {
    await _repo.clearDailySummaries();
    final sleepList = await _repo.getSleepData(days: days);
    final activityList = await _repo.getActivityData(days: days);

    final Map<String, int> sleepMinutesByDate = {};
    for (final s in sleepList) {
      final key = _dateKey(s.date);
      sleepMinutesByDate[key] =
          (sleepMinutesByDate[key] ?? 0) + s.durationMinutes;
    }

    final Map<String, int> stepsByDate = {};
    final Map<String, List<double>> hrSamplesByDate = {};
    for (final a in activityList) {
      final key = _dateKey(a.date);
      stepsByDate[key] = (stepsByDate[key] ?? 0) + a.steps;
      if (a.heartRate != null) {
        hrSamplesByDate.putIfAbsent(key, () => <double>[]).add(a.heartRate!);
      }
    }

    final allKeys = {...sleepMinutesByDate.keys, ...stepsByDate.keys}.toList()
      ..sort();

    for (final key in allKeys) {
      final sleepMinutes = sleepMinutesByDate[key] ?? 0;
      final steps = stepsByDate[key] ?? 0;
      final hrList = hrSamplesByDate[key];
      final heartRate = (hrList != null && hrList.isNotEmpty)
          ? hrList.reduce((a, b) => a + b) / hrList.length
          : null;

      final result = calculateRecovery(
        sleepMinutes: sleepMinutes,
        steps: steps,
        heartRate: heartRate,
      );

      final parts = key.split('-');
      final date = DateTime(
        int.parse(parts[0]),
        int.parse(parts[1]),
        int.parse(parts[2]),
      );

      await _repo.saveDailySummary(
        DailyHealthSummary(
          date: date,
          sleepMinutes: sleepMinutes,
          steps: steps,
          heartRate: heartRate,
          recoveryIndex: result.recoveryIndex,
          wakeTimeOffset: 0,
        ),
      );
    }
  }

  String _dateKey(DateTime dt) =>
      '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
}
