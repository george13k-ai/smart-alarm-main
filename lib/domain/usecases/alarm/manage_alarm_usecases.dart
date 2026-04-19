import '../../entities/alarm.dart';
import '../../repositories/alarm_repository.dart';
import '../../../core/services/notification_service.dart';

class GetAlarmsUseCase {
  final AlarmRepository _repo;
  GetAlarmsUseCase(this._repo);

  Future<List<Alarm>> call() => _repo.getAll();
}

class SaveAlarmUseCase {
  final AlarmRepository _repo;
  SaveAlarmUseCase(this._repo);

  Future<void> call(Alarm alarm) async {
    await _repo.save(alarm);
    try {
      if (alarm.isEnabled) {
        await NotificationService.instance.scheduleAlarm(alarm);
      } else {
        await NotificationService.instance.cancelAlarmById(alarm.id);
      }
    } catch (_) {
      // Не ломаем сохранение локальных данных из-за ошибок планировщика.
    }
  }
}

class DeleteAlarmUseCase {
  final AlarmRepository _repo;
  DeleteAlarmUseCase(this._repo);

  Future<void> call(Alarm alarm) async {
    try {
      await NotificationService.instance.cancelAlarmById(alarm.id);
    } catch (_) {
      // Даже если отмена нотификаций не удалась, запись из БД удаляем.
    }
    await _repo.delete(alarm.id);
  }
}

class ToggleAlarmUseCase {
  final AlarmRepository _repo;
  ToggleAlarmUseCase(this._repo);

  Future<Alarm> call(Alarm alarm) async {
    final updated = alarm.copyWith(isEnabled: !alarm.isEnabled);
    await _repo.save(updated);
    try {
      if (updated.isEnabled) {
        await NotificationService.instance.scheduleAlarm(updated);
      } else {
        await NotificationService.instance.cancelAlarmById(updated.id);
      }
    } catch (_) {
      // Состояние переключателя должно применяться сразу, даже при ошибке Android-планировщика.
    }
    return updated;
  }
}
