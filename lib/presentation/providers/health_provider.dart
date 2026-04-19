import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/health_data.dart';
import '../../domain/usecases/health/sync_health_usecase.dart';
import '../../data/datasources/local/health_local_datasource.dart';
import '../../data/datasources/remote/health_connect_datasource.dart';
import '../../data/repositories/health_repository_impl.dart';
import '../../core/utils/recovery_algorithm.dart';

// ---- DI ----

final _healthLocal = HealthLocalDatasource();
final _healthRemote = HealthConnectDatasource();
final _healthRepo = HealthRepositoryImpl(_healthLocal, _healthRemote);
final _syncUseCase = SyncHealthDataUseCase(_healthRepo);

// ---- Today Recovery Provider ----

/// Провайдер индекса восстановления на сегодня
class TodayRecoveryNotifier extends StateNotifier<RecoveryResult?> {
  TodayRecoveryNotifier() : super(null) {
    _ensureDataAndCompute();
  }

  Future<void> _ensureDataAndCompute() async {
    // При старте автоматически подгружаем (демо если Health Connect недоступен)
    final existing = await _healthRepo.getDailySummaries(days: 7);
    if (existing.isEmpty) {
      await _syncUseCase();
    }
    await _compute();
  }

  Future<void> _compute() async {
    final today = DateTime.now();
    final summaries = await _healthRepo.getDailySummaries(days: 1);
    final todayKey =
        '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

    final todaySummary = summaries.where((s) {
      final k =
          '${s.date.year}-${s.date.month.toString().padLeft(2, '0')}-${s.date.day.toString().padLeft(2, '0')}';
      return k == todayKey;
    }).firstOrNull;

    if (todaySummary != null) {
      state = calculateRecovery(
        sleepMinutes: todaySummary.sleepMinutes,
        steps: todaySummary.steps,
        heartRate: todaySummary.heartRate,
      );
    }
  }

  Future<void> sync() async {
    await _syncUseCase();
    await _compute();
  }
}

final todayRecoveryProvider =
    StateNotifierProvider<TodayRecoveryNotifier, RecoveryResult?>(
  (ref) => TodayRecoveryNotifier(),
);

// ---- Summaries Provider ----

final summariesProvider =
    FutureProvider.family<List<DailyHealthSummary>, int>((ref, days) {
  return _healthRepo.getDailySummaries(days: days);
});
