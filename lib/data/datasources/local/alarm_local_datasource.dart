import 'package:hive/hive.dart';
import '../../models/alarm_model.dart';
import '../../../domain/entities/alarm.dart';
import '../../../core/constants/app_constants.dart';

class AlarmLocalDatasource {
  Box<AlarmModel> get _box => Hive.box<AlarmModel>(AppConstants.alarmsBox);

  Future<List<Alarm>> getAll() async {
    return _box.values.map((m) => m.toEntity()).toList();
  }

  Future<void> save(Alarm alarm) async {
    final model = AlarmModel.fromEntity(alarm);
    await _box.put(alarm.id, model);
  }

  Future<void> delete(String id) async {
    await _box.delete(id);
  }

  Future<Alarm?> getById(String id) async {
    final model = _box.get(id);
    return model?.toEntity();
  }
}
