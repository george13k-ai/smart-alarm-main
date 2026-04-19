import '../../../core/services/health_connect_service.dart';
import '../../../domain/entities/health_data.dart';

/// Remote datasource — проксирует запросы к Health Connect через platform channel.
class HealthConnectDatasource {
  final HealthConnectService _service = HealthConnectService.instance;

  Future<bool> isAvailable() => _service.isAvailable();
  Future<bool> requestPermissions() => _service.requestPermissions();

  Future<List<SleepData>> fetchSleep({int days = 7}) =>
      _service.getSleepData(days: days);

  Future<List<ActivityData>> fetchActivity({int days = 7}) =>
      _service.getActivityData(days: days);
}
