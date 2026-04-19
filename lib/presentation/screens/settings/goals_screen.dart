import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../domain/entities/user_goals.dart';
import '../../../domain/entities/achievement.dart';
import '../../providers/goals_provider.dart';
import '../../providers/achievement_provider.dart';

class GoalsScreen extends ConsumerStatefulWidget {
  const GoalsScreen({super.key});

  @override
  ConsumerState<GoalsScreen> createState() => _GoalsScreenState();
}

class _GoalsScreenState extends ConsumerState<GoalsScreen> {
  late int _steps;
  late double _sleepHours;

  @override
  void initState() {
    super.initState();
    final goals = ref.read(goalsProvider);
    _steps = goals.dailySteps;
    _sleepHours = goals.sleepHours;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bottomInset =
        MediaQuery.of(context).padding.bottom + kBottomNavigationBarHeight + 24;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(title: const Text('Цели и достижения')),
      body: ListView(
        padding: EdgeInsets.fromLTRB(16, 16, 16, bottomInset),
        children: [
          // ── Шаги ──
          _GoalCard(
            icon: Icons.directions_walk,
            iconColor: theme.colorScheme.primary,
            label: 'Шагов в день',
            value: _steps.toString(),
            child: Slider(
              value: _steps.toDouble(),
              min: 1000,
              max: 20000,
              divisions: 19,
              label: _steps.toString(),
              onChanged: (v) => setState(() => _steps = v.round()),
            ),
            bottomLabels: const ['1 000', '10 000', '20 000'],
          ),
          const SizedBox(height: 12),

          // ── Сон ──
          _GoalCard(
            icon: Icons.bedtime_outlined,
            iconColor: theme.colorScheme.tertiary,
            label: 'Часов сна',
            value: '${_sleepHours.toStringAsFixed(1)} ч',
            child: Slider(
              value: _sleepHours,
              min: 4,
              max: 12,
              divisions: 16,
              label: '${_sleepHours.toStringAsFixed(1)} ч',
              onChanged: (v) => setState(() => _sleepHours = v),
            ),
            bottomLabels: const ['4 ч', '8 ч', '12 ч'],
          ),
          const SizedBox(height: 20),

          FilledButton.icon(
            icon: const Icon(Icons.save),
            label: const Text('Сохранить цели'),
            onPressed: _save,
          ),

          const SizedBox(height: 32),

          Text(
            'Достижения',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Выполняйте условия, чтобы разблокировать награды',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.5),
            ),
          ),
          const SizedBox(height: 12),

          const _AchievementsList(),
        ],
      ),
    );
  }

  Future<void> _save() async {
    await ref.read(goalsProvider.notifier).save(
          UserGoals(dailySteps: _steps, sleepHours: _sleepHours),
        );
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Цели сохранены')),
      );
    }
  }
}

class _AchievementsList extends ConsumerWidget {
  const _AchievementsList();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final achievements = ref.watch(achievementProvider);
    return Column(
      children: achievements.map((a) => _AchievementTile(achievement: a)).toList(),
    );
  }
}

class _GoalCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;
  final Widget child;
  final List<String> bottomLabels;

  const _GoalCard({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
    required this.child,
    required this.bottomLabels,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: iconColor),
                const SizedBox(width: 8),
                Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
                const Spacer(),
                Text(
                  value,
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            child,
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: bottomLabels
                  .map((l) => Text(l, style: const TextStyle(fontSize: 11)))
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }
}

class _AchievementTile extends StatelessWidget {
  final Achievement achievement;
  const _AchievementTile({required this.achievement});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final unlocked = achievement.isUnlocked;
    final fraction = achievement.progressFraction;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Иконка
            Text(
              achievement.icon,
              style: TextStyle(
                fontSize: 32,
                color: unlocked ? null : null,
              ),
            ),
            const SizedBox(width: 14),
            // Текст + прогресс
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          achievement.title,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: unlocked
                                ? theme.colorScheme.onSurface
                                : theme.colorScheme.onSurface.withOpacity(0.6),
                          ),
                        ),
                      ),
                      if (unlocked)
                        Icon(Icons.check_circle,
                            color: theme.colorScheme.primary, size: 20)
                      else
                        Icon(Icons.lock_outline,
                            color: theme.colorScheme.onSurface.withOpacity(0.3),
                            size: 20),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    achievement.description,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.5),
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Прогресс-бар
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: fraction,
                      minHeight: 6,
                      backgroundColor:
                          theme.colorScheme.onSurface.withOpacity(0.1),
                      valueColor: AlwaysStoppedAnimation<Color>(
                        unlocked
                            ? theme.colorScheme.primary
                            : theme.colorScheme.primary.withOpacity(0.6),
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  // Подпись прогресса
                  Text(
                    unlocked
                        ? 'Выполнено!'
                        : _progressLabel(achievement),
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: unlocked
                          ? theme.colorScheme.primary
                          : theme.colorScheme.onSurface.withOpacity(0.45),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _progressLabel(Achievement a) {
    switch (a.id) {
      case 'streak_7':
      case 'streak_30':
        return '${a.progress} из ${a.target} дней';
      case 'steps_10k':
        return '${a.progress} из ${a.target} шагов';
      case 'sleep_8h':
        final pMin = a.progress;
        final tMin = a.target;
        return '${(pMin / 60).toStringAsFixed(1)} из ${(tMin / 60).toStringAsFixed(0)} ч';
      case 'recovery_90':
        return '${a.progress} из ${a.target} (индекс)';
      case 'math_master':
        return '${a.progress} из ${a.target} задач';
      default:
        return '${(a.progressFraction * 100).toInt()}%';
    }
  }
}
