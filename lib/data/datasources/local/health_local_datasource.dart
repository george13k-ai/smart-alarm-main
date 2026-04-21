import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';
import '../../models/health_data_model.dart';
import '../../../domain/entities/health_data.dart';
import '../../../core/constants/app_constants.dart';

class HealthLocalDatasource {
  static const _uuid = Uuid();

  Box<SleepDataModel> get _sleepBox =>
      Hive.box<SleepDataModel>(AppConstants.healthDataBox + '_sleep');

  Box<ActivityDataModel> get _activityBox =>
      Hive.box<ActivityDataModel>(AppConstants.healthDataBox + '_activity');

  Box<DailySummaryModel> get _summaryBox =>
      Hive.box<DailySummaryModel>(AppConstants.recoveryBox);

  // ---- Sleep ----

  Future<void> saveSleepData(List<SleepData> data) async {
    for (final item in data) {
      final id = _uuid.v4();
      await _sleepBox.put(id, SleepDataModel.fromEntity(item, id));
    }
  }

  Future<List<SleepData>> getSleepData({int days = 30}) async {
    final today = DateTime.now();
    final cutoff = DateTime(today.year, today.month, today.day)
        .subtract(Duration(days: days - 1));
    return _sleepBox.values
        .map((m) => m.toEntity())
        .where((d) => !d.date.isBefore(cutoff))
        .toList()
      ..sort((a, b) => a.date.compareTo(b.date));
  }

  Future<void> clearSleepData() async => _sleepBox.clear();

  // ---- Activity ----

  Future<void> saveActivityData(List<ActivityData> data) async {
    for (final item in data) {
      final id = _uuid.v4();
      await _activityBox.put(id, ActivityDataModel.fromEntity(item, id));
    }
  }

  Future<List<ActivityData>> getActivityData({int days = 30}) async {
    final today = DateTime.now();
    final cutoff = DateTime(today.year, today.month, today.day)
        .subtract(Duration(days: days - 1));
    return _activityBox.values
        .map((m) => m.toEntity())
        .where((d) => !d.date.isBefore(cutoff))
        .toList()
      ..sort((a, b) => a.date.compareTo(b.date));
  }

  Future<void> clearActivityData() async => _activityBox.clear();

  // ---- Summary ----

  Future<void> saveSummary(DailyHealthSummary summary) async {
    final model = DailySummaryModel.fromEntity(summary);
    await _summaryBox.put(model.dateKey, model);
  }

  Future<List<DailyHealthSummary>> getSummaries({int days = 30}) async {
    final today = DateTime.now();
    final cutoff = DateTime(today.year, today.month, today.day)
        .subtract(Duration(days: days - 1));

    final all = _summaryBox.values
        .map((m) => m.toEntity())
        .where((s) => !s.date.isBefore(cutoff));

    // Дедуплицируем по дате — старые записи с UUID-ключами могут соседствовать
    // с новыми dateKey-записями для тех же дней
    final byDate = <String, DailyHealthSummary>{};
    for (final s in all) {
      final k =
          '${s.date.year}-${s.date.month.toString().padLeft(2, '0')}-${s.date.day.toString().padLeft(2, '0')}';
      byDate[k] = s;
    }
    return byDate.values.toList()
      ..sort((a, b) => a.date.compareTo(b.date));
  }

  Future<void> clearSummaries() async => _summaryBox.clear();
}
