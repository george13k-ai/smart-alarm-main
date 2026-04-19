import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/alarm_provider.dart';
import '../../providers/health_provider.dart';
import '../../widgets/alarm_card.dart';
import '../../widgets/recovery_card.dart';
import '../alarm/alarm_detail_screen.dart';
import '../settings/goals_screen.dart';
import '../statistics/statistics_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _currentTab = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: switch (_currentTab) {
        0 => const _AlarmsTab(),
        1 => const StatisticsScreen(),
        _ => const GoalsScreen(),
      },
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentTab,
        onDestinationSelected: (i) => setState(() => _currentTab = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.alarm), label: 'Будильники'),
          NavigationDestination(
              icon: Icon(Icons.bar_chart), label: 'Статистика'),
          NavigationDestination(icon: Icon(Icons.flag_outlined), label: 'Цели'),
        ],
      ),
    );
  }
}

class _AlarmsTab extends ConsumerWidget {
  const _AlarmsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final alarmsAsync = ref.watch(alarmProvider);
    final recovery = ref.watch(todayRecoveryProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Умный будильник'),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openDetail(context, ref, null),
        child: const Icon(Icons.add),
      ),
      body: CustomScrollView(
        slivers: [
          if (recovery != null)
            SliverToBoxAdapter(
              child: RecoveryCard(
                result: recovery,
                alarmHour: alarmsAsync.valueOrNull
                    ?.where((a) => a.isEnabled)
                    .firstOrNull
                    ?.hour,
                alarmMinute: alarmsAsync.valueOrNull
                    ?.where((a) => a.isEnabled)
                    .firstOrNull
                    ?.minute,
              ),
            ),
          alarmsAsync.when(
            loading: () => const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (e, _) => SliverFillRemaining(
              child: Center(child: Text('Ошибка: $e')),
            ),
            data: (alarms) {
              if (alarms.isEmpty) {
                return const SliverFillRemaining(
                  child: _EmptyAlarmsPlaceholder(),
                );
              }
              return SliverList(
                delegate: SliverChildBuilderDelegate(
                  (ctx, i) {
                    final alarm = alarms[i];
                    return Dismissible(
                      key: ValueKey('alarm_${alarm.id}'),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.red.shade400,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 20),
                        child: const Icon(
                          Icons.delete_outline,
                          color: Colors.white,
                        ),
                      ),
                      confirmDismiss: (_) async {
                        return await showDialog<bool>(
                              context: ctx,
                              builder: (_) => AlertDialog(
                                title: const Text('Удалить будильник?'),
                                content: Text(
                                  'Будильник "${alarm.name}" будет удален.',
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(ctx, false),
                                    child: const Text('Отмена'),
                                  ),
                                  FilledButton(
                                    onPressed: () => Navigator.pop(ctx, true),
                                    child: const Text('Удалить'),
                                  ),
                                ],
                              ),
                            ) ??
                            false;
                      },
                      onDismissed: (_) {
                        ref.read(alarmProvider.notifier).delete(alarm);
                        ScaffoldMessenger.of(ctx).showSnackBar(
                          SnackBar(
                            content: Text('Будильник "${alarm.name}" удален'),
                          ),
                        );
                      },
                      child: AlarmCard(
                        alarm: alarm,
                        onTap: () => _openDetail(ctx, ref, alarm),
                      ),
                    );
                  },
                  childCount: alarms.length,
                ),
              );
            },
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 80)),
        ],
      ),
    );
  }

  void _openDetail(BuildContext context, WidgetRef ref, dynamic alarm) {
    final notifier = ref.read(alarmProvider.notifier);
    final target = alarm ?? notifier.buildNew();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AlarmDetailScreen(alarm: target),
      ),
    );
  }
}

class _EmptyAlarmsPlaceholder extends StatelessWidget {
  const _EmptyAlarmsPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.alarm_off, size: 72, color: Colors.grey.shade400),
        const SizedBox(height: 16),
        Text(
          'Нет будильников',
          style: Theme.of(context)
              .textTheme
              .titleMedium
              ?.copyWith(color: Colors.grey),
        ),
        const SizedBox(height: 8),
        const Text(
          'Нажмите + чтобы добавить',
          style: TextStyle(color: Colors.grey),
        ),
      ],
    );
  }
}
