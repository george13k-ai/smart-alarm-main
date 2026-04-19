import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../domain/entities/alarm.dart';
import '../../core/constants/app_constants.dart';
import '../../domain/usecases/alarm/manage_alarm_usecases.dart';
import '../../data/datasources/local/alarm_local_datasource.dart';
import '../../data/repositories/alarm_repository_impl.dart';

// ---- DI ----

final _alarmDatasource = AlarmLocalDatasource();
final _alarmRepo = AlarmRepositoryImpl(_alarmDatasource);

final _getAlarms = GetAlarmsUseCase(_alarmRepo);
final _saveAlarm = SaveAlarmUseCase(_alarmRepo);
final _deleteAlarm = DeleteAlarmUseCase(_alarmRepo);
final _toggleAlarm = ToggleAlarmUseCase(_alarmRepo);

// ---- Provider ----

class AlarmNotifier extends StateNotifier<AsyncValue<List<Alarm>>> {
  AlarmNotifier() : super(const AsyncValue.loading()) {
    loadAlarms();
  }

  Future<void> loadAlarms({bool keepPrevious = false}) async {
    if (!keepPrevious) {
      state = const AsyncValue.loading();
    }
    try {
      final alarms = await _getAlarms();
      // Сортируем по времени (час, минута)
      alarms.sort((a, b) {
        final aMin = a.hour * 60 + a.minute;
        final bMin = b.hour * 60 + b.minute;
        return aMin.compareTo(bMin);
      });
      state = AsyncValue.data(alarms);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> save(Alarm alarm) async {
    try {
      await _saveAlarm(alarm);
    } finally {
      await loadAlarms(keepPrevious: true);
    }
  }

  Future<void> delete(Alarm alarm) async {
    try {
      await _deleteAlarm(alarm);
    } finally {
      await loadAlarms(keepPrevious: true);
    }
  }

  Future<void> toggle(Alarm alarm) async {
    try {
      await _toggleAlarm(alarm);
    } finally {
      await loadAlarms(keepPrevious: true);
    }
  }

  Alarm buildNew() {
    const uuid = Uuid();
    return Alarm(
      id: uuid.v4(),
      name: 'Будильник',
      hour: 7,
      minute: 0,
      weekdays: [1, 2, 3, 4, 5], // пн–пт
      isEnabled: true,
      dismissType: DismissType.math,
    );
  }
}

final alarmProvider =
    StateNotifierProvider<AlarmNotifier, AsyncValue<List<Alarm>>>(
  (ref) => AlarmNotifier(),
);
