import '../../domain/entities/alarm.dart';
import '../../domain/repositories/alarm_repository.dart';
import '../datasources/local/alarm_local_datasource.dart';

class AlarmRepositoryImpl implements AlarmRepository {
  final AlarmLocalDatasource _local;
  AlarmRepositoryImpl(this._local);

  @override
  Future<List<Alarm>> getAll() => _local.getAll();

  @override
  Future<void> save(Alarm alarm) => _local.save(alarm);

  @override
  Future<void> delete(String id) => _local.delete(id);

  @override
  Future<Alarm?> getById(String id) => _local.getById(id);
}
