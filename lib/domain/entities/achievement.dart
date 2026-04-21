class Achievement {
  final String id;
  final String title;
  final String description;
  final String icon;
  final bool isUnlocked;
  final DateTime? unlockedAt;
  /// Текущий прогресс (шаги, минуты сна, дни стрика и т.д.)
  final int progress;
  /// Целевое значение для достижения
  final int target;

  const Achievement({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.isUnlocked,
    this.unlockedAt,
    this.progress = 0,
    this.target = 1,
  });

  double get progressFraction =>
      isUnlocked ? 1.0 : (progress / target).clamp(0.0, 1.0);

  Achievement copyWith({
    bool? isUnlocked,
    DateTime? unlockedAt,
    int? progress,
    int? target,
  }) {
    return Achievement(
      id: id,
      title: title,
      description: description,
      icon: icon,
      isUnlocked: isUnlocked ?? this.isUnlocked,
      unlockedAt: unlockedAt ?? this.unlockedAt,
      progress: progress ?? this.progress,
      target: target ?? this.target,
    );
  }

  /// Предопределённые достижения
  static List<Achievement> get defaults => [
        const Achievement(
          id: 'streak_7',
          title: '7 дней подряд',
          description: 'Вставай вовремя 7 дней подряд',
          icon: '🔥',
          isUnlocked: false,
          target: 7,
        ),
        const Achievement(
          id: 'streak_30',
          title: 'Месяц дисциплины',
          description: '30 дней подряд без игнора',
          icon: '🏆',
          isUnlocked: false,
          target: 30,
        ),
        const Achievement(
          id: 'steps_10k',
          title: '10 000 шагов',
          description: 'Пройди 10 000 шагов за день',
          icon: '👟',
          isUnlocked: false,
          target: 10000,
        ),
        const Achievement(
          id: 'sleep_8h',
          title: 'Идеальный сон',
          description: 'Поспи ровно 8 часов',
          icon: '😴',
          isUnlocked: false,
          target: 480,
        ),
        const Achievement(
          id: 'math_master',
          title: 'Математик',
          description: 'Реши 50 задач в режиме "Математика"',
          icon: '🧮',
          isUnlocked: false,
          target: 50,
        ),
      ];
}
