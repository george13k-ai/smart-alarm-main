import '../entities/alarm.dart';

abstract class AlarmRepository {
  Future<List<Alarm>> getAll();
  Future<void> save(Alarm alarm);
  Future<void> delete(String id);
  Future<Alarm?> getById(String id);
}
