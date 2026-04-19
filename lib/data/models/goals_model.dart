import 'package:hive/hive.dart';
import '../../domain/entities/user_goals.dart';

class GoalsModel extends HiveObject {
  late int dailySteps;
  late double sleepHours;

  GoalsModel();

  factory GoalsModel.fromEntity(UserGoals goals) => GoalsModel()
    ..dailySteps = goals.dailySteps
    ..sleepHours = goals.sleepHours;

  UserGoals toEntity() => UserGoals(
        dailySteps: dailySteps,
        sleepHours: sleepHours,
      );
}

class GoalsAdapter extends TypeAdapter<GoalsModel> {
  @override
  final int typeId = 4;

  @override
  GoalsModel read(BinaryReader reader) => GoalsModel()
    ..dailySteps = reader.readInt()
    ..sleepHours = reader.readDouble();

  @override
  void write(BinaryWriter writer, GoalsModel obj) {
    writer.writeInt(obj.dailySteps);
    writer.writeDouble(obj.sleepHours);
  }
}
