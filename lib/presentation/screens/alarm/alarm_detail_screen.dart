import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_constants.dart';
import '../../../domain/entities/alarm.dart';
import '../../providers/alarm_provider.dart';

class AlarmDetailScreen extends ConsumerStatefulWidget {
  final Alarm alarm;
  const AlarmDetailScreen({super.key, required this.alarm});

  @override
  ConsumerState<AlarmDetailScreen> createState() => _AlarmDetailScreenState();
}

class _AlarmDetailScreenState extends ConsumerState<AlarmDetailScreen> {
  late int _hour;
  late int _minute;
  late String _name;
  late List<int> _weekdays;
  late DismissType _dismissType;
  late String _soundFile;

  final _nameController = TextEditingController();
  final AudioPlayer _previewPlayer = AudioPlayer();

  Timer? _previewStopTimer;
  bool _isPlaying = false;
  bool _isPreviewingAll = false;
  String? _previewingFile;
  bool _previewAudioConfigured = false;

  @override
  void initState() {
    super.initState();
    final a = widget.alarm;
    _hour = a.hour;
    _minute = a.minute;
    _name = a.name;
    _weekdays = List.from(a.weekdays);
    _dismissType = a.dismissType;
    _soundFile = a.soundFile;
    _nameController.text = _name;

    _configurePreviewAudio();

    _previewPlayer.onPlayerComplete.listen((_) {
      _previewStopTimer?.cancel();
      _previewStopTimer = null;
      if (mounted) {
        setState(() {
          _isPlaying = false;
          _previewingFile = null;
        });
      }
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _previewStopTimer?.cancel();
    _previewPlayer.dispose();
    super.dispose();
  }

  Future<void> _configurePreviewAudio() async {
    if (_previewAudioConfigured) return;
    try {
      await _previewPlayer.setPlayerMode(PlayerMode.mediaPlayer);
      await _previewPlayer.setVolume(0.6);
      await _previewPlayer.setAudioContext(
        AudioContext(
          android: const AudioContextAndroid(
            usageType: AndroidUsageType.alarm,
            contentType: AndroidContentType.sonification,
            audioFocus: AndroidAudioFocus.gainTransientMayDuck,
            stayAwake: true,
          ),
          iOS: AudioContextIOS(
            category: AVAudioSessionCategory.playback,
          ),
        ),
      );
      _previewAudioConfigured = true;
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Настройка будильника'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: _delete,
            tooltip: 'Удалить',
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: InkWell(
              onTap: _pickTime,
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Center(
                  child: Text(
                    '${_hour.toString().padLeft(2, '0')}:${_minute.toString().padLeft(2, '0')}',
                    style: theme.textTheme.displayMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'Название',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.label_outline),
            ),
            onChanged: (v) => _name = v,
          ),
          const SizedBox(height: 16),
          const Text('Дни недели',
              style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(
            'Если не выбрать ни одного дня — будильник сработает один раз',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
            ),
          ),
          const SizedBox(height: 8),
          _WeekdaySelector(
            selected: _weekdays,
            onChanged: (days) => setState(() => _weekdays = days),
          ),
          const SizedBox(height: 16),
          const Text('Мелодия будильника',
              style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Card(
            child: Column(
              children: AppConstants.alarmSounds.map(((String, String) sound) {
                return RadioListTile<String>(
                  value: sound.$1,
                  groupValue: _soundFile,
                  title: Text(sound.$2),
                  secondary: IconButton(
                    icon: Icon(
                      _isPlaying && _previewingFile == sound.$1
                          ? Icons.stop_circle_outlined
                          : Icons.play_circle_outline,
                      color: theme.colorScheme.primary,
                    ),
                    tooltip: _isPlaying && _previewingFile == sound.$1
                        ? 'Стоп'
                        : 'Прослушать',
                    onPressed: () => _togglePreview(sound.$1),
                  ),
                  onChanged: (v) {
                    if (v == null) return;
                    setState(() => _soundFile = v);
                    _startPreview(v);
                  },
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: _previewAllSounds,
              icon: Icon(
                _isPreviewingAll ? Icons.stop : Icons.queue_music,
              ),
              label: Text(
                _isPreviewingAll
                    ? 'Остановить прослушивание'
                    : 'Прослушать все мелодии',
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text('Способ отключения',
              style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          ...DismissType.values.map((type) => RadioListTile<DismissType>(
                title: Text(type.label),
                secondary: _dismissIcon(type),
                value: type,
                groupValue: _dismissType,
                onChanged: (v) => setState(() => _dismissType = v!),
              )),
          const SizedBox(height: 32),
          FilledButton.icon(
            icon: const Icon(Icons.save),
            label: const Text('Сохранить'),
            onPressed: _save,
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Future<void> _togglePreview(String fileName) async {
    _isPreviewingAll = false;
    if (_isPlaying && _previewingFile == fileName) {
      await _stopPreview();
      return;
    }
    await _startPreview(fileName);
  }

  Future<void> _previewAllSounds() async {
    if (_isPreviewingAll) {
      _isPreviewingAll = false;
      await _stopPreview();
      if (mounted) setState(() {});
      return;
    }

    final originalSelected = _soundFile;
    setState(() => _isPreviewingAll = true);

    try {
      for (final sound in AppConstants.alarmSounds) {
        if (!_isPreviewingAll || !mounted) break;

        await _startPreview(
          sound.$1,
          previewDuration: const Duration(seconds: 3),
          updateSelected: false,
        );
        await Future.delayed(const Duration(milliseconds: 3300));
      }
    } finally {
      await _stopPreview();
      if (mounted) {
        setState(() {
          _isPreviewingAll = false;
          _soundFile = originalSelected;
        });
      }
    }
  }

  Future<void> _startPreview(
    String fileName, {
    Duration previewDuration = const Duration(seconds: 8),
    bool updateSelected = true,
  }) async {
    await _configurePreviewAudio();
    await _stopPreview();
    if (!mounted) return;

    setState(() {
      if (updateSelected) {
        _soundFile = fileName;
      }
      _isPlaying = true;
      _previewingFile = fileName;
    });

    try {
      await _previewPlayer.play(AssetSource('sounds/$fileName'));
      _previewStopTimer = Timer(previewDuration, () {
        if (_previewingFile == fileName) {
          _stopPreview();
        }
      });
    } catch (_) {
      try {
        await _previewPlayer.play(AssetSource('sounds/alarm_sound.wav'));
        _previewStopTimer = Timer(previewDuration, _stopPreview);
      } catch (_) {
        if (mounted) {
          setState(() {
            _isPlaying = false;
            _previewingFile = null;
          });
        }
      }
    }
  }

  Future<void> _stopPreview() async {
    _previewStopTimer?.cancel();
    _previewStopTimer = null;
    await _previewPlayer.stop();
    if (mounted) {
      setState(() {
        _isPlaying = false;
        _previewingFile = null;
      });
    }
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: _hour, minute: _minute),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() {
        _hour = picked.hour;
        _minute = picked.minute;
      });
    }
  }

  Future<void> _save() async {
    await _stopPreview();

    final normalizedWeekdays =
        _weekdays.where((d) => d >= 1 && d <= 7).toSet().toList()..sort();

    final alarm = widget.alarm.copyWith(
      name: _name.trim().isEmpty ? 'Будильник' : _name.trim(),
      hour: _hour,
      minute: _minute,
      weekdays: normalizedWeekdays,
      dismissType: _dismissType,
      soundFile: _soundFile,
      isEnabled: widget.alarm.isEnabled,
    );

    await ref.read(alarmProvider.notifier).save(alarm);
    if (mounted) Navigator.pop(context);
  }

  Future<void> _delete() async {
    await _stopPreview();
    if (!mounted) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Удалить будильник?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Отмена'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Удалить'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ref.read(alarmProvider.notifier).delete(widget.alarm);
      if (mounted) Navigator.pop(context);
    }
  }

  Widget _dismissIcon(DismissType type) {
    switch (type) {
      case DismissType.math:
        return const Icon(Icons.calculate_outlined);
      case DismissType.shake:
        return const Icon(Icons.vibration);
      case DismissType.color:
        return const Icon(Icons.palette_outlined);
    }
  }
}

class _WeekdaySelector extends StatefulWidget {
  final List<int> selected;
  final ValueChanged<List<int>> onChanged;

  const _WeekdaySelector({required this.selected, required this.onChanged});

  @override
  State<_WeekdaySelector> createState() => _WeekdaySelectorState();
}

class _WeekdaySelectorState extends State<_WeekdaySelector> {
  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      children: List.generate(7, (i) {
        final day = i + 1;
        final isSelected = widget.selected.contains(day);

        return FilterChip(
          label: Text(AppConstants.weekdayLabels[i]),
          selected: isSelected,
          onSelected: (_) {
            final updated = [...widget.selected];
            if (isSelected) {
              updated.remove(day);
            } else {
              updated.add(day);
              updated.sort();
            }
            widget.onChanged(updated);
          },
        );
      }),
    );
  }
}

