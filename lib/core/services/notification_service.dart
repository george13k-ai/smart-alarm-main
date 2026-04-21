import 'package:alarm/alarm.dart' as pkg;
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../domain/entities/alarm.dart';
import '../constants/app_constants.dart';

class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  GlobalKey<NavigatorState>? navigatorKey;
  Future<Alarm?> Function(String id)? findAlarmById;

  static const List<int> _allSlots = [0, 1, 2, 3, 4, 5, 6, 7, 99];

  bool _alarmScreenShowing = false;

  void onAlarmScreenClosed() {
    _alarmScreenShowing = false;
  }

  Future<void> initialize() async {
    await pkg.Alarm.init();
    await _requestPermissions();

    pkg.Alarm.ringing.listen((alarmSet) {
      final ringing = alarmSet.alarms;
      if (ringing.isNotEmpty) {
        final payload = ringing.first.payload;
        if (payload != null) _navigateToAlarm(payload);
      }
    });
  }

  // Kept for API compatibility — alarm package handles launch-from-notification
  Future<String?> checkLaunchFromNotification() async => null;

  Future<void> scheduleAlarm(Alarm alarm) async {
    if (!alarm.isEnabled) return;
    await cancelAlarmById(alarm.id);

    final now = DateTime.now();

    if (alarm.weekdays.isEmpty) {
      var date =
          DateTime(now.year, now.month, now.day, alarm.hour, alarm.minute);
      if (!date.isAfter(now)) date = date.add(const Duration(days: 1));
      await _setAlarm(alarm, date, 0);
    } else {
      for (final weekday in alarm.weekdays) {
        final date = _nextWeekdayTime(
          weekday: weekday,
          hour: alarm.hour,
          minute: alarm.minute,
          from: now,
        );
        await _setAlarm(alarm, date, weekday);
      }
    }
  }

  Future<void> cancelAlarm(Alarm alarm) => cancelAlarmById(alarm.id);

  Future<void> cancelAlarmById(String alarmId) async {
    for (final slot in _allSlots) {
      try {
        await pkg.Alarm.stop(_pkgId(alarmId, slot));
      } catch (_) {}
    }
  }

  Future<void> stopAlarmAudio(String alarmId) => cancelAlarmById(alarmId);

  Future<void> showSnoozeNotification(Alarm alarm, {Duration? delay}) async {
    final snoozedTime = DateTime.now().add(
      delay ?? const Duration(minutes: AppConstants.snoozeMinutes),
    );
    await _setAlarm(alarm, snoozedTime, 99);
  }

  Future<void> cancelAll() => pkg.Alarm.stopAll();

  // ── Private ───────────────────────────────────────────────────────────────

  Future<void> _setAlarm(Alarm alarm, DateTime dateTime, int slot) async {
    await pkg.Alarm.set(
      alarmSettings: pkg.AlarmSettings(
        id: _pkgId(alarm.id, slot),
        dateTime: dateTime,
        assetAudioPath: 'assets/sounds/${_resolveSound(alarm.soundFile)}',
        loopAudio: true,
        vibrate: true,
        androidFullScreenIntent: true,
        warningNotificationOnKill: false,
        volumeSettings: pkg.VolumeSettings.fixed(volume: 0.65),
        notificationSettings: pkg.NotificationSettings(
          title: '⏰ ${alarm.name}',
          body: 'Нажмите, чтобы выключить будильник',
          stopButton: 'Остановить',
        ),
        payload: alarm.id,
      ),
    );
  }

  void _navigateToAlarm(String alarmId) async {
    if (_alarmScreenShowing) return;

    final nav = navigatorKey?.currentState;
    if (nav == null) {
      // Navigator not ready yet (cold start) — retry after first frame
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _navigateToAlarm(alarmId),
      );
      return;
    }

    _alarmScreenShowing = true;

    final getAlarm = findAlarmById;
    if (getAlarm == null) { _alarmScreenShowing = false; return; }

    final alarm = await getAlarm(alarmId);
    if (alarm == null) { _alarmScreenShowing = false; return; }

    nav.pushNamedAndRemoveUntil(
      '/alarm_ringing',
      (route) => route.isFirst,
      arguments: alarm,
    );
  }

  Future<void> _requestPermissions() async {
    try {
      await Permission.notification.request();
    } catch (_) {}
    try {
      await Permission.scheduleExactAlarm.request();
    } catch (_) {}
    try {
      if (!(await Permission.ignoreBatteryOptimizations.isGranted)) {
        await Permission.ignoreBatteryOptimizations.request();
      }
    } catch (_) {}
  }

  // alarm package: id must not be 0 or -1
  int _pkgId(String alarmId, int slot) =>
      (alarmId.hashCode.abs() % 99999 + 1) * 100 + slot;

  String _resolveSound(String soundFile) {
    final known = AppConstants.alarmSounds.any((s) => s.$1 == soundFile);
    return known ? soundFile : 'alarm_sound.wav';
  }

  DateTime _nextWeekdayTime({
    required int weekday,
    required int hour,
    required int minute,
    required DateTime from,
  }) {
    var date = DateTime(from.year, from.month, from.day, hour, minute);
    while (date.weekday != weekday || !date.isAfter(from)) {
      date = date.add(const Duration(days: 1));
    }
    return date;
  }
}
