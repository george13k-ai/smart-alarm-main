import '../constants/app_constants.dart';

class RecoveryResult {
  final int recoveryIndex; // 0–100
  final int sleepScore;    // 0–50
  final int activityScore; // 0–30
  final int heartRateScore; // 0–20
  final String explanation;

  const RecoveryResult({
    required this.recoveryIndex,
    required this.sleepScore,
    required this.activityScore,
    required this.heartRateScore,
    required this.explanation,
  });
}

RecoveryResult calculateRecovery({
  required int sleepMinutes,
  required int steps,
  double? heartRate,
}) {
  // Sleep score (0–50): optimum 480 min (8h)
  final sleepRatio = (sleepMinutes / AppConstants.targetSleepMinutes).clamp(0.0, 1.2);
  final sleepScore = (sleepRatio * 50).round().clamp(0, 50);

  // Activity score (0–30)
  final activityRatio = (steps / AppConstants.targetSteps).clamp(0.0, 1.0);
  final activityScore = (activityRatio * 30).round().clamp(0, 30);

  // Heart rate score (0–20)
  int heartRateScore;
  if (heartRate == null) {
    heartRateScore = 10;
  } else if (heartRate < 55) {
    heartRateScore = 20;
  } else if (heartRate < 65) {
    heartRateScore = 16;
  } else if (heartRate < 75) {
    heartRateScore = 12;
  } else if (heartRate < 85) {
    heartRateScore = 7;
  } else {
    heartRateScore = 3;
  }

  final recoveryIndex = (sleepScore + activityScore + heartRateScore).clamp(0, 100);

  String explanation;
  if (recoveryIndex >= 80) {
    explanation = 'Отличное восстановление — вы в хорошей форме.';
  } else if (recoveryIndex >= 65) {
    explanation = 'Хорошее восстановление. Продолжайте в том же духе.';
  } else if (recoveryIndex >= 45) {
    explanation = 'Нормальное восстановление. Старайтесь больше двигаться и спать 8 часов.';
  } else if (recoveryIndex >= 25) {
    explanation = 'Слабое восстановление. Уделите внимание сну и активности.';
  } else {
    explanation = 'Плохое восстановление. Постарайтесь хорошо выспаться сегодня.';
  }

  return RecoveryResult(
    recoveryIndex: recoveryIndex,
    sleepScore: sleepScore,
    activityScore: activityScore,
    heartRateScore: heartRateScore,
    explanation: explanation,
  );
}
