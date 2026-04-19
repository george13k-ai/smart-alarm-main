import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import '../../domain/entities/achievement.dart';
import '../../domain/entities/health_data.dart';
import '../../data/models/achievement_model.dart';
import '../../data/datasources/local/health_local_datasource.dart';
import '../../data/datasources/remote/health_connect_datasource.dart';
import '../../data/repositories/health_repository_impl.dart';
import '../../core/constants/app_constants.dart';

class AchievementNotifier extends StateNotifier<List<Achievement>> {
  AchievementNotifier() : super(Achievement.defaults) {
    _load();
    refreshProgress();
  }

  Box<AchievementModel> get _box =>
      Hive.box<AchievementModel>(AppConstants.achievementsBox);
  Box<dynamic> get _metricsBox => Hive.box(AppConstants.achievementMetricsBox);

  static const _mathSolvedKey = 'math_solved_total';
  static const _dismissedTotalKey = 'dismissed_total';
  static const _currentStreakKey = 'current_streak';

  final _healthRepo = HealthRepositoryImpl(
    HealthLocalDatasource(),
    HealthConnectDatasource(),
  );

  void _load() {
    final templates = Achievement.defaults;
    state = templates.map((t) {
      final saved = _box.get(t.id);
      return saved != null ? saved.toEntity(t) : t;
    }).toList();
  }

  Future<void> _save(Achievement a) async {
    await _box.put(a.id, AchievementModel.fromEntity(a));
  }

  Future<void> unlock(String id) async {
    final updated = state.map((a) {
      if (a.id == id && !a.isUnlocked) {
        final unlocked = a.copyWith(
          isUnlocked: true,
          unlockedAt: DateTime.now(),
          progress: a.target,
        );
        _save(unlocked);
        return unlocked;
      }
      return a;
    }).toList();
    state = updated;
  }

  Future<void> _updateProgress(String id, int progress) async {
    final updated = state.map((a) {
      if (a.id == id && !a.isUnlocked) {
        final next = a.copyWith(progress: progress);
        _save(next);
        return next;
      }
      return a;
    }).toList();
    state = updated;
  }

  Future<void> incrementMathSolved([int by = 1]) async {
    final current =
        (_metricsBox.get(_mathSolvedKey, defaultValue: 0) as int?) ?? 0;
    await _metricsBox.put(_mathSolvedKey, current + by);
    await refreshProgress();
  }

  Future<void> incrementAlarmDismissed([int by = 1]) async {
    final current =
        (_metricsBox.get(_dismissedTotalKey, defaultValue: 0) as int?) ?? 0;
    await _metricsBox.put(_dismissedTotalKey, current + by);
    await refreshProgress();
  }

  Future<void> refreshProgress() async {
    final summaries = await _healthRepo.getDailySummaries(days: 30);
    final mathSolved =
        (_metricsBox.get(_mathSolvedKey, defaultValue: 0) as int?) ?? 0;
    final currentStreak =
        (_metricsBox.get(_currentStreakKey, defaultValue: 0) as int?) ?? 0;
    await checkConditions(
      summaries: summaries,
      mathSolved: mathSolved,
      currentStreak: currentStreak,
    );
  }

  /// Проверить все условия и разблокировать / обновить прогресс
  Future<void> checkConditions({
    required List<DailyHealthSummary> summaries,
    required int mathSolved,
    int currentStreak = 0,
  }) async {
    for (final a in state) {
      switch (a.id) {
        case 'streak_7':
          await _updateProgress('streak_7', currentStreak);
          if (currentStreak >= 7) await unlock('streak_7');
          break;
        case 'streak_30':
          await _updateProgress('streak_30', currentStreak);
          if (currentStreak >= 30) await unlock('streak_30');
          break;
        case 'steps_10k':
          if (summaries.isNotEmpty) {
            final maxSteps =
                summaries.map((s) => s.steps).reduce((a, b) => a > b ? a : b);
            await _updateProgress('steps_10k', maxSteps);
            if (maxSteps >= 10000) await unlock('steps_10k');
          }
          break;
        case 'sleep_8h':
          if (summaries.isNotEmpty) {
            final maxSleep = summaries
                .map((s) => s.sleepMinutes)
                .reduce((a, b) => a > b ? a : b);
            await _updateProgress('sleep_8h', maxSleep);
            if (maxSleep >= 480) await unlock('sleep_8h');
          }
          break;
        case 'recovery_90':
          if (summaries.isNotEmpty) {
            final maxRecovery = summaries
                .map((s) => s.recoveryIndex)
                .reduce((a, b) => a > b ? a : b);
            await _updateProgress('recovery_90', maxRecovery);
            if (maxRecovery >= 90) await unlock('recovery_90');
          }
          break;
        case 'math_master':
          await _updateProgress('math_master', mathSolved);
          if (mathSolved >= 50) await unlock('math_master');
          break;
      }
    }
  }
}

final achievementProvider =
    StateNotifierProvider<AchievementNotifier, List<Achievement>>(
  (ref) => AchievementNotifier(),
);
