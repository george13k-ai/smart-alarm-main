import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'core/services/notification_service.dart';
import 'core/constants/app_constants.dart';
import 'data/models/alarm_model.dart';
import 'data/models/health_data_model.dart';
import 'data/models/goals_model.dart';
import 'data/models/achievement_model.dart';
import 'data/datasources/local/alarm_local_datasource.dart';
import 'domain/entities/alarm.dart';
import 'presentation/screens/home/home_screen.dart';
import 'presentation/screens/alarm/alarm_ringing_screen.dart';

/// Глобальный ключ навигатора — позволяет navigating из notification callback
final navigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ---- Hive ----
  await Hive.initFlutter();
  _registerAdapters();
  await _openBoxes();

  // ---- Notifications ----
  final notifService = NotificationService.instance;
  notifService.navigatorKey = navigatorKey;

  final alarmDatasource = AlarmLocalDatasource();
  notifService.findAlarmById = alarmDatasource.getById;

  await notifService.initialize();

  // Проверяем: запущены ли из уведомления-будильника
  final pendingAlarmId = await notifService.checkLaunchFromNotification();

  runApp(
    ProviderScope(
      child: SmartAlarmApp(pendingAlarmId: pendingAlarmId),
    ),
  );
}

void _registerAdapters() {
  Hive.registerAdapter(AlarmModelAdapter());
  Hive.registerAdapter(SleepDataAdapter());
  Hive.registerAdapter(ActivityDataAdapter());
  Hive.registerAdapter(DailySummaryAdapter());
  Hive.registerAdapter(GoalsAdapter());
  Hive.registerAdapter(AchievementAdapter());
}

Future<void> _openBoxes() async {
  await Hive.openBox<AlarmModel>(AppConstants.alarmsBox);
  await Hive.openBox<SleepDataModel>('${AppConstants.healthDataBox}_sleep');
  await Hive.openBox<ActivityDataModel>(
      '${AppConstants.healthDataBox}_activity');
  await Hive.openBox<DailySummaryModel>(AppConstants.recoveryBox);
  await Hive.openBox<GoalsModel>(AppConstants.goalsBox);
  await Hive.openBox<AchievementModel>(AppConstants.achievementsBox);
  await Hive.openBox(AppConstants.achievementMetricsBox);
}

class SmartAlarmApp extends StatefulWidget {
  final String? pendingAlarmId;
  const SmartAlarmApp({super.key, this.pendingAlarmId});

  @override
  State<SmartAlarmApp> createState() => _SmartAlarmAppState();
}

class _SmartAlarmAppState extends State<SmartAlarmApp> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Умный будильник',
      debugShowCheckedModeBanner: false,
      navigatorKey: navigatorKey,
      theme: _buildTheme(Brightness.light),
      darkTheme: _buildTheme(Brightness.dark),
      themeMode: ThemeMode.dark,
      onGenerateRoute: (settings) {
        if (settings.name == '/alarm_ringing') {
          final alarm = settings.arguments as Alarm;
          return MaterialPageRoute(
            builder: (_) => AlarmRingingScreen(alarm: alarm),
            fullscreenDialog: true,
          );
        }
        return null;
      },
      home: const HomeScreen(),
    );
  }

  ThemeData _buildTheme(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    // Акцентный цвет — насыщенный зелёно-голубой (teal)
    const seedColor = Color(0xFF00BFA5); // teal accent

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: ColorScheme.fromSeed(
        seedColor: seedColor,
        brightness: brightness,
      ),
      scaffoldBackgroundColor: isDark ? const Color(0xFF0D0D0D) : null,
      cardTheme: CardThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: isDark ? 0 : 2,
        color: isDark ? const Color(0xFF1A1A1A) : null,
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: isDark ? const Color(0xFF111111) : null,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: isDark ? const Color(0xFF0D0D0D) : null,
        elevation: 0,
      ),
    );
  }
}
