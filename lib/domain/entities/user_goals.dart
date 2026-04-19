class UserGoals {
  final int dailySteps;
  final double sleepHours;

  const UserGoals({
    required this.dailySteps,
    required this.sleepHours,
  });

  static const defaultGoals = UserGoals(
    dailySteps: 10000,
    sleepHours: 8.0,
  );

  UserGoals copyWith({int? dailySteps, double? sleepHours}) {
    return UserGoals(
      dailySteps: dailySteps ?? this.dailySteps,
      sleepHours: sleepHours ?? this.sleepHours,
    );
  }
}
