import '../../domain/entities/health_data.dart';
import '../../domain/repositories/health_repository.dart';
import '../datasources/local/health_local_datasource.dart';
import '../datasources/remote/health_connect_datasource.dart';

class HealthRepositoryImpl implements HealthRepository {
  final HealthLocalDatasource _local;
  final HealthConnectDatasource _remote;

  HealthRepositoryImpl(this._local, this._remote);

  @override
  Future<void> syncFromHealthConnect({int days = 7}) async {
    try {
      final available = await _remote.isAvailable();
      if (!available) return;

      // Ask for permissions, but still try to read each data type separately.
      try {
        await _remote.requestPermissions();
      } catch (_) {}

      List<SleepData> sleep = const [];
      List<ActivityData> activity = const [];

      try {
        sleep = await _remote.fetchSleep(days: days);
      } catch (_) {}

      try {
        activity = await _remote.fetchActivity(days: days);
      } catch (_) {}

      if (sleep.isNotEmpty) {
        await _local.clearSleepData();
        await _local.saveSleepData(sleep);
      }

      if (activity.isNotEmpty) {
        await _local.clearActivityData();
        await _local.saveActivityData(activity);
      }
    } catch (_) {
      // Keep previously cached data if Health Connect fails.
    }
  }

  @override
  Future<List<SleepData>> getSleepData({int days = 30}) =>
      _local.getSleepData(days: days);

  @override
  Future<List<ActivityData>> getActivityData({int days = 30}) =>
      _local.getActivityData(days: days);

  @override
  Future<void> saveDailySummary(DailyHealthSummary summary) =>
      _local.saveSummary(summary);

  @override
  Future<List<DailyHealthSummary>> getDailySummaries({int days = 30}) =>
      _local.getSummaries(days: days);
}
