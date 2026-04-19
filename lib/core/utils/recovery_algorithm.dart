import '../constants/app_constants.dart';

/// Результат алгоритма умного пробуждения
class RecoveryResult {
  final int recoveryIndex;    // 0–100
  final int sleepScore;       // 0–50
  final int activityScore;    // 0–30
  final int heartRateScore;   // 0–20
  /// Смещение относительно заданного времени будильника в минутах.
  /// Отрицательное = проснись раньше, положительное = позже.
  final int wakeTimeOffset;
  final String explanation;

  const RecoveryResult({
    required this.recoveryIndex,
    required this.sleepScore,
    required this.activityScore,
    required this.heartRateScore,
    required this.wakeTimeOffset,
    required this.explanation,
  });
}

/// Простой детерминированный алгоритм без ML.
/// Входные данные: сон, шаги, пульс покоя.
RecoveryResult calculateRecovery({
  required int sleepMinutes,
  required int steps,
  double? heartRate,
}) {
  // --- Sleep score (0–50) ---
  // Оптимум: 480 мин (8 часов).
  // Меньше 4 часов (240 мин) → 0 баллов.
  // Больше 10 часов (600 мин) → полный балл, но с пометкой.
  final sleepRatio = (sleepMinutes / AppConstants.targetSleepMinutes).clamp(0.0, 1.2);
  final sleepScore = (sleepRatio * 50).round().clamp(0, 50);

  // --- Activity score (0–30) ---
  final activityRatio = (steps / AppConstants.targetSteps).clamp(0.0, 1.0);
  final activityScore = (activityRatio * 30).round().clamp(0, 30);

  // --- Heart rate score (0–20) ---
  int heartRateScore;
  if (heartRate == null) {
    heartRateScore = 10; // нет данных — нейтрально
  } else if (heartRate < 55) {
    heartRateScore = 20; // отличный пульс спортсмена
  } else if (heartRate < 65) {
    heartRateScore = 16;
  } else if (heartRate < 75) {
    heartRateScore = 12;
  } else if (heartRate < 85) {
    heartRateScore = 7;
  } else {
    heartRateScore = 3; // высокий ЧСС покоя
  }

  final recoveryIndex = (sleepScore + activityScore + heartRateScore).clamp(0, 100);

  // --- Wake time offset ---
  int wakeOffset;
  String explanation;
  if (recoveryIndex >= 80) {
    wakeOffset = -30;
    explanation = 'Отличное восстановление! Рекомендую встать на 30 минут раньше.';
  } else if (recoveryIndex >= 65) {
    wakeOffset = -15;
    explanation = 'Хорошее восстановление. Можно встать на 15 минут раньше.';
  } else if (recoveryIndex >= 45) {
    wakeOffset = 0;
    explanation = 'Нормальное восстановление. Вставай по расписанию.';
  } else if (recoveryIndex >= 25) {
    wakeOffset = 15;
    explanation = 'Слабое восстановление. Лучше поспать ещё 15 минут.';
  } else {
    wakeOffset = 30;
    explanation = 'Плохое восстановление. Рекомендую поспать ещё 30 минут.';
  }

  return RecoveryResult(
    recoveryIndex: recoveryIndex,
    sleepScore: sleepScore,
    activityScore: activityScore,
    heartRateScore: heartRateScore,
    wakeTimeOffset: wakeOffset,
    explanation: explanation,
  );
}
