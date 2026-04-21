class AppConstants {
  AppConstants._();

  // Hive box names
  static const String alarmsBox = 'alarms_box';
  static const String healthDataBox = 'health_data_box';
  static const String goalsBox = 'goals_box';
  static const String achievementsBox = 'achievements_box';
  static const String achievementMetricsBox = 'achievement_metrics_box';
  static const String recoveryBox = 'recovery_box';

  // Notification channel
  static const String alarmChannelId = 'smart_alarm_channel';
  static const String alarmChannelName = 'Smart Alarm';
  static const String alarmChannelDesc =
      'Канал для уведомлений умного будильника';

  // Platform channel (Health Connect)
  static const String healthChannelName = 'com.example.app1/health';

  // Shake game
  static const double shakeThreshold = 15.0;
  static const int shakeCountRequired = 10;

  // Math game
  static const int mathProblemsRequired = 3;

  // Recovery algorithm
  static const int targetSleepMinutes = 480; // 8 часов
  static const int targetSteps = 10000;

  // Color game
  static const int colorTapsRequired = 5;

  // Snooze
  static const int snoozeMinutes = 1;
  static const int ringDurationSeconds = 60;
  static const int mathGameTimeLimitSeconds = 60;
  static const int shakeGameTimeLimitSeconds = 45;
  static const int colorGameTimeLimitSeconds = 60;
  static const int gameRetryDelaySeconds = 30;

  // Alarm request code base (уникальный id для каждого будильника)
  static const int alarmRequestCodeBase = 1000;

  // Days of week labels
  static const List<String> weekdayLabels = [
    'Пн',
    'Вт',
    'Ср',
    'Чт',
    'Пт',
    'Сб',
    'Вс'
  ];

  // Available alarm sounds: (fileName, displayName)
  static const List<(String, String)> alarmSounds = [
    ('alarm_sound.wav', 'Стандартный'),
    ('alarm_gentle.wav', 'Мягкий'),
    ('alarm_digital.wav', 'Цифровой'),
    ('alarm_birds.wav', 'Природа'),
  ];
}

enum DismissType {
  math,
  shake,
  color;

  String get label {
    switch (this) {
      case DismissType.math:
        return 'Математика';
      case DismissType.shake:
        return 'Встряхивание';
      case DismissType.color:
        return 'Цвета';
    }
  }
}
