import '../entities/health_data.dart';

abstract class HealthRepository {
  /// Синхронизировать данные из Health Connect и сохранить локально
  Future<void> syncFromHealthConnect({int days = 7});

  /// Получить данные сна из локального хранилища
  Future<List<SleepData>> getSleepData({int days = 30});

  /// Получить данные активности из локального хранилища
  Future<List<ActivityData>> getActivityData({int days = 30});

  /// Сохранить агрегированную сводку (вычисленную после sync)
  Future<void> saveDailySummary(DailyHealthSummary summary);

  /// Получить сводки за последние [days] дней
  Future<List<DailyHealthSummary>> getDailySummaries({int days = 30});

  /// Очистить все сохранённые сводки (вызывается перед пересчётом)
  Future<void> clearDailySummaries();
}
