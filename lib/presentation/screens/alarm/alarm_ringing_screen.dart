import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/services/notification_service.dart';
import '../../../domain/entities/alarm.dart';
import '../../providers/achievement_provider.dart';
import '../games/color_game_screen.dart';
import '../games/math_game_screen.dart';
import '../games/shake_game_screen.dart';

class AlarmRingingScreen extends ConsumerStatefulWidget {
  final Alarm alarm;

  const AlarmRingingScreen({super.key, required this.alarm});

  @override
  ConsumerState<AlarmRingingScreen> createState() => _AlarmRingingScreenState();
}

class _AlarmRingingScreenState extends ConsumerState<AlarmRingingScreen>
    with WidgetsBindingObserver {
  Timer? _ringTimer;
  bool _dismissed = false;
  bool _gameInProgress = false;
  bool _retryScheduled = false;
  late DateTime _ringTime;

  @override
  void initState() {
    super.initState();
    _ringTime = DateTime.now();
    WidgetsBinding.instance.addObserver(this);

    WakelockPlus.enable();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

    _startRingTimer();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _ringTimer?.cancel();
    WakelockPlus.disable();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && !_dismissed) {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    }
  }

  void _startRingTimer() {
    _ringTimer?.cancel();
    _ringTimer = Timer(
      const Duration(seconds: AppConstants.ringDurationSeconds),
      _onRingWindowExpired,
    );
  }

  Future<void> _stopCurrentAlarm({bool rescheduleRecurring = true}) async {
    _ringTimer?.cancel();
    await NotificationService.instance.stopAlarmAudio(widget.alarm.id);
    if (rescheduleRecurring &&
        widget.alarm.weekdays.isNotEmpty &&
        widget.alarm.isEnabled) {
      await NotificationService.instance.scheduleAlarm(widget.alarm);
    }
  }

  Future<void> _scheduleRetryAndClose(Duration delay) async {
    if (_retryScheduled) return;
    _retryScheduled = true;
    _dismissed = true;
    NotificationService.instance.onAlarmScreenClosed();
    await _stopCurrentAlarm();
    await NotificationService.instance.showSnoozeNotification(
      widget.alarm,
      delay: delay,
    );
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  void _onRingWindowExpired() {
    if (_dismissed || _gameInProgress) return;
    _scheduleRetryAndClose(
      const Duration(minutes: AppConstants.snoozeMinutes),
    );
  }

  Future<void> _openGame() async {
    if (_dismissed || _gameInProgress) return;
    _gameInProgress = true;

    await _stopCurrentAlarm(rescheduleRecurring: false);

    final timeLimitSeconds = _gameTimeLimitFor(widget.alarm.dismissType);
    var gameResolved = false;

    final timeoutTimer = Timer(
      Duration(seconds: timeLimitSeconds),
      () {
        if (!mounted || _dismissed || !_gameInProgress || gameResolved) return;
        gameResolved = true;
        Navigator.of(context).pop(); // pop game screen without result
      },
    );

    Widget game;
    switch (widget.alarm.dismissType) {
      case DismissType.math:
        game = MathGameScreen(onSuccess: () {
          if (gameResolved) return;
          gameResolved = true;
          // Экран закроется сам своим Navigator.of(context)
        });
      case DismissType.shake:
        game = ShakeGameScreen(onSuccess: () {
          if (gameResolved) return;
          gameResolved = true;
        });
      case DismissType.color:
        game = ColorGameScreen(onSuccess: () {
          if (gameResolved) return;
          gameResolved = true;
        });
    }

    final solved = mounted
        ? (await Navigator.push<bool>(
                context, MaterialPageRoute(builder: (_) => game)) ??
            false)
        : false;

    timeoutTimer.cancel();
    _gameInProgress = false;

    if (!mounted) return;

    if (solved && !_dismissed) {
      await _dismiss();
    } else if (!solved && !_dismissed) {
      await _scheduleRetryAndClose(
        const Duration(seconds: AppConstants.gameRetryDelaySeconds),
      );
    }
  }

  Future<void> _recordAchievementProgress() async {
    final notifier = ref.read(achievementProvider.notifier);
    await notifier.incrementAlarmDismissed();
    if (widget.alarm.dismissType == DismissType.math) {
      await notifier.incrementMathSolved(AppConstants.mathProblemsRequired);
    }
  }

  Future<void> _dismiss() async {
    if (_dismissed) return;
    _dismissed = true;
    NotificationService.instance.onAlarmScreenClosed();
    try {
      await _recordAchievementProgress();
    } catch (_) {}
    try {
      await _stopCurrentAlarm();
    } catch (_) {}
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: Colors.black,
        body: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),
              _PulsingAlarmIcon(),
              const SizedBox(height: 24),
              StreamBuilder<DateTime>(
                stream: Stream.periodic(
                  const Duration(seconds: 1),
                  (_) => DateTime.now(),
                ),
                initialData: DateTime.now(),
                builder: (_, snap) {
                  final now = snap.data!;
                  final h = now.hour.toString().padLeft(2, '0');
                  final m = now.minute.toString().padLeft(2, '0');
                  return Text(
                    '$h:$m',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 80,
                      fontWeight: FontWeight.w100,
                    ),
                  );
                },
              ),
              const SizedBox(height: 8),
              Text(
                widget.alarm.name,
                style: const TextStyle(color: Colors.white60, fontSize: 22),
              ),
              const Spacer(),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(double.infinity, 56),
                    backgroundColor: Colors.redAccent,
                  ),
                  icon: _gameIcon(widget.alarm.dismissType),
                  label: Text(
                    'Выключить: ${widget.alarm.dismissType.label}',
                    style: const TextStyle(fontSize: 18),
                  ),
                  onPressed: _openGame,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Game time: ${_formatSeconds(_gameTimeLimitFor(widget.alarm.dismissType))}',
                style: const TextStyle(color: Colors.white54, fontSize: 13),
              ),
              const SizedBox(height: 16),
              _AutoRepeatCountdown(ringTime: _ringTime),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _gameIcon(DismissType type) {
    switch (type) {
      case DismissType.math:
        return const Icon(Icons.calculate);
      case DismissType.shake:
        return const Icon(Icons.vibration);
      case DismissType.color:
        return const Icon(Icons.palette);
    }
  }

  int _gameTimeLimitFor(DismissType type) {
    switch (type) {
      case DismissType.math:
        return AppConstants.mathGameTimeLimitSeconds;
      case DismissType.shake:
        return AppConstants.shakeGameTimeLimitSeconds;
      case DismissType.color:
        return AppConstants.colorGameTimeLimitSeconds;
    }
  }

  String _formatSeconds(int totalSeconds) {
    final m = totalSeconds ~/ 60;
    final s = totalSeconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }
}

class _PulsingAlarmIcon extends StatefulWidget {
  @override
  State<_PulsingAlarmIcon> createState() => _PulsingAlarmIconState();
}

class _PulsingAlarmIconState extends State<_PulsingAlarmIcon>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..repeat(reverse: true);
    _scale = Tween(begin: 0.9, end: 1.1).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scale,
      child: const Icon(Icons.alarm, size: 100, color: Colors.redAccent),
    );
  }
}

class _AutoRepeatCountdown extends StatefulWidget {
  final DateTime ringTime;
  const _AutoRepeatCountdown({required this.ringTime});

  @override
  State<_AutoRepeatCountdown> createState() => _AutoRepeatCountdownState();
}

class _AutoRepeatCountdownState extends State<_AutoRepeatCountdown> {
  late Timer _timer;
  int _secondsLeft = AppConstants.ringDurationSeconds;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      final elapsed = DateTime.now().difference(widget.ringTime).inSeconds;
      final left = AppConstants.ringDurationSeconds - elapsed;
      if (mounted) setState(() => _secondsLeft = left.clamp(0, 9999));
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final m = _secondsLeft ~/ 60;
    final s = _secondsLeft % 60;
    return Text(
      'Автоповтор через ${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}',
      style: const TextStyle(color: Colors.white38, fontSize: 14),
    );
  }
}
