import 'dart:math';
import '../../../domain/entities/health_data.dart';

/// Генерирует реалистичные синтетические данные о здоровье для демо-режима.
/// Используется когда Health Connect недоступен или не выдал разрешения.
class DemoHealthDatasource {
  static final _rnd = Random(DateTime.now().millisecondsSinceEpoch);

  /// Генерирует данные сна за [days] дней
  static List<SleepData> generateSleep({int days = 7}) {
    final result = <SleepData>[];
    final now = DateTime.now();
    for (int i = days - 1; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      // Базовая продолжительность сна 6-9 часов
      final baseMinutes = 360 + _rnd.nextInt(180);
      result.add(SleepData(
        date: DateTime(date.year, date.month, date.day),
        durationMinutes: baseMinutes,
        source: 'demo',
      ));
    }
    return result;
  }

  /// Генерирует данные активности за [days] дней
  static List<ActivityData> generateActivity({int days = 7}) {
    final result = <ActivityData>[];
    final now = DateTime.now();
    for (int i = days - 1; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      final steps = 6000 + _rnd.nextInt(8000); // 6 000–14 000 шагов
      final hr = 58.0 + _rnd.nextDouble() * 20; // 58–78 уд/мин
      result.add(ActivityData(
        date: DateTime(date.year, date.month, date.day),
        steps: steps,
        heartRate: hr,
      ));
    }
    return result;
  }
}
