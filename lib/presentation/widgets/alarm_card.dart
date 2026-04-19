import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/alarm.dart';
import '../../core/constants/app_constants.dart';
import '../providers/alarm_provider.dart';

class AlarmCard extends ConsumerWidget {
  final Alarm alarm;
  final VoidCallback onTap;

  const AlarmCard({super.key, required this.alarm, required this.onTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      elevation: alarm.isEnabled ? 3 : 0,
      color: alarm.isEnabled
          ? theme.colorScheme.primaryContainer
          : theme.colorScheme.surfaceVariant,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              // Время
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    alarm.timeLabel,
                    style: theme.textTheme.displaySmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: alarm.isEnabled
                          ? theme.colorScheme.onPrimaryContainer
                          : theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  Text(
                    alarm.name,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: alarm.isEnabled
                          ? theme.colorScheme.onPrimaryContainer
                          : theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    alarm.weekdaysLabel,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: (alarm.isEnabled
                              ? theme.colorScheme.onPrimaryContainer
                              : theme.colorScheme.onSurfaceVariant)
                          .withOpacity(0.7),
                    ),
                  ),
                ],
              ),
              const Spacer(),
              // Иконка режима
              Column(
                children: [
                  _dismissIcon(alarm.dismissType),
                  const SizedBox(height: 8),
                  // Toggle
                  Switch(
                    value: alarm.isEnabled,
                    onChanged: (_) =>
                        ref.read(alarmProvider.notifier).toggle(alarm),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _dismissIcon(DismissType type) {
    IconData icon;
    switch (type) {
      case DismissType.math:
        icon = Icons.calculate_outlined;
        break;
      case DismissType.shake:
        icon = Icons.vibration;
        break;
      case DismissType.qr:
        icon = Icons.qr_code_scanner;
        break;
    }
    return Icon(icon, size: 20);
  }
}
