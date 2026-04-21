import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';

import '../../core/constants/app_constants.dart';
import '../../data/datasources/local/health_local_datasource.dart';
import '../../data/datasources/remote/health_connect_datasource.dart';
import '../../data/models/achievement_model.dart';
import '../../data/repositories/health_repository_impl.dart';
import '../../domain/entities/achievement.dart';
import '../../domain/entities/health_data.dart';

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
  static const _dismissedDaysKey = 'dismissed_days';
  static const _currentStreakKey = 'current_streak';

  final _healthRepo =
      HealthRepositoryImpl(HealthLocalDatasource(), HealthConnectDatasource());

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
    final total =
        (_metricsBox.get(_dismissedTotalKey, defaultValue: 0) as int?) ?? 0;
    await _metricsBox.put(_dismissedTotalKey, total + by);

    final dismissedDays = _loadDismissedDays();
    dismissedDays.add(_dateKey(DateTime.now()));
    final orderedDays = dismissedDays.toList()..sort();
    await _metricsBox.put(_dismissedDaysKey, orderedDays);

    final currentStreak = _calculateCurrentStreak(dismissedDays);
    await _metricsBox.put(_currentStreakKey, currentStreak);

    await refreshProgress();
  }

  Future<void> refreshProgress() async {
    final summaries = await _healthRepo.getDailySummaries(days: 30);
    final mathSolved =
        (_metricsBox.get(_mathSolvedKey, defaultValue: 0) as int?) ?? 0;

    final dismissedDays = _loadDismissedDays();
    final currentStreak = _calculateCurrentStreak(dismissedDays);
    await _metricsBox.put(_currentStreakKey, currentStreak);

    await checkConditions(
      summaries: summaries,
      mathSolved: mathSolved,
      currentStreak: currentStreak,
    );
  }

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
            final todayKey = _dateKey(DateTime.now());
            final todaySummary = summaries
                .where((s) => _dateKey(s.date) == todayKey)
                .firstOrNull;
            final todaySteps = todaySummary?.steps ?? 0;
            await _updateProgress('steps_10k', todaySteps);
            final maxSteps =
                summaries.map((s) => s.steps).reduce((a, b) => a > b ? a : b);
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
        case 'math_master':
          await _updateProgress('math_master', mathSolved);
          if (mathSolved >= 50) await unlock('math_master');
          break;
      }
    }
  }

  Set<String> _loadDismissedDays() {
    final raw = _metricsBox.get(_dismissedDaysKey, defaultValue: <dynamic>[]);
    if (raw is! List) return <String>{};
    return raw.map((e) => e.toString()).where(_isValidDateKey).toSet();
  }

  int _calculateCurrentStreak(Set<String> dayKeys) {
    if (dayKeys.isEmpty) return 0;

    final dates = dayKeys
        .map(_parseDateKey)
        .whereType<DateTime>()
        .map((d) => DateTime(d.year, d.month, d.day))
        .toList();

    if (dates.isEmpty) return 0;

    dates.sort((a, b) => b.compareTo(a));

    var streak = 1;
    var cursor = dates.first;

    for (var i = 1; i < dates.length; i++) {
      final expectedPrev = cursor.subtract(const Duration(days: 1));
      final candidate = dates[i];

      if (_sameDay(candidate, expectedPrev)) {
        streak++;
        cursor = candidate;
      } else if (_sameDay(candidate, cursor)) {
        continue;
      } else {
        break;
      }
    }

    return streak;
  }

  bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  String _dateKey(DateTime dt) =>
      '${dt.year.toString().padLeft(4, '0')}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';

  DateTime? _parseDateKey(String key) {
    final parts = key.split('-');
    if (parts.length != 3) return null;
    final y = int.tryParse(parts[0]);
    final m = int.tryParse(parts[1]);
    final d = int.tryParse(parts[2]);
    if (y == null || m == null || d == null) return null;
    if (m < 1 || m > 12 || d < 1 || d > 31) return null;
    return DateTime(y, m, d);
  }

  bool _isValidDateKey(String key) => _parseDateKey(key) != null;
}

final achievementProvider =
    StateNotifierProvider<AchievementNotifier, List<Achievement>>(
  (ref) => AchievementNotifier(),
);
