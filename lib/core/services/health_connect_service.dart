import 'package:flutter/services.dart';
import '../../domain/entities/health_data.dart';
import '../constants/app_constants.dart';

/// Обёртка над MethodChannel для работы с Health Connect.
/// Kotlin-сторона реализована в MainActivity.kt / HealthConnectPlugin.kt
class HealthConnectService {
  HealthConnectService._();
  static final HealthConnectService instance = HealthConnectService._();

  static const _channel = MethodChannel(AppConstants.healthChannelName);

  /// Проверить, доступен ли Health Connect на устройстве
  Future<bool> isAvailable() async {
    try {
      final result = await _channel.invokeMethod<bool>('isAvailable');
      return result ?? false;
    } on PlatformException {
      return false;
    }
  }

  /// Запросить разрешения на чтение данных здоровья
  Future<bool> requestPermissions() async {
    try {
      final result = await _channel.invokeMethod<bool>('requestPermissions');
      return result ?? false;
    } on PlatformException catch (e) {
      throw Exception('Health Connect permission error: ${e.message}');
    }
  }

  /// Получить данные сна за последние [days] дней
  Future<List<SleepData>> getSleepData({int days = 7}) async {
    try {
      final raw = await _channel.invokeMethod<List<dynamic>>(
        'getSleepData',
        {'days': days},
      );
      if (raw == null) return [];
      return raw.map((e) {
        final map = Map<String, dynamic>.from(e as Map);
        return SleepData(
          date: DateTime.fromMillisecondsSinceEpoch(map['dateMs'] as int),
          durationMinutes: map['durationMinutes'] as int,
          source: map['source'] as String? ?? 'health_connect',
        );
      }).toList();
    } on PlatformException catch (e) {
      throw Exception('getSleepData error: ${e.message}');
    }
  }

  /// Получить данные активности за последние [days] дней
  Future<List<ActivityData>> getActivityData({int days = 7}) async {
    try {
      final raw = await _channel.invokeMethod<List<dynamic>>(
        'getActivityData',
        {'days': days},
      );
      if (raw == null) return [];
      return raw.map((e) {
        final map = Map<String, dynamic>.from(e as Map);
        return ActivityData(
          date: DateTime.fromMillisecondsSinceEpoch(map['dateMs'] as int),
          steps: map['steps'] as int? ?? 0,
          heartRate: (map['heartRate'] as num?)?.toDouble(),
        );
      }).toList();
    } on PlatformException catch (e) {
      throw Exception('getActivityData error: ${e.message}');
    }
  }
}
