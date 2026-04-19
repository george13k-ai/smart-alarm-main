import 'package:hive/hive.dart';
import '../../domain/entities/health_data.dart';

/// Модель для хранения данных сна
class SleepDataModel extends HiveObject {
  late String id;
  late int dateMs;
  late int durationMinutes;
  late String source;

  SleepDataModel();

  factory SleepDataModel.fromEntity(SleepData data, String id) =>
      SleepDataModel()
        ..id = id
        ..dateMs = data.date.millisecondsSinceEpoch
        ..durationMinutes = data.durationMinutes
        ..source = data.source;

  SleepData toEntity() => SleepData(
        date: DateTime.fromMillisecondsSinceEpoch(dateMs),
        durationMinutes: durationMinutes,
        source: source,
      );
}

class SleepDataAdapter extends TypeAdapter<SleepDataModel> {
  @override
  final int typeId = 1;

  @override
  SleepDataModel read(BinaryReader reader) => SleepDataModel()
    ..id = reader.readString()
    ..dateMs = reader.readInt()
    ..durationMinutes = reader.readInt()
    ..source = reader.readString();

  @override
  void write(BinaryWriter writer, SleepDataModel obj) {
    writer.writeString(obj.id);
    writer.writeInt(obj.dateMs);
    writer.writeInt(obj.durationMinutes);
    writer.writeString(obj.source);
  }
}

/// Модель для хранения данных активности
class ActivityDataModel extends HiveObject {
  late String id;
  late int dateMs;
  late int steps;
  double? heartRate;

  ActivityDataModel();

  factory ActivityDataModel.fromEntity(ActivityData data, String id) =>
      ActivityDataModel()
        ..id = id
        ..dateMs = data.date.millisecondsSinceEpoch
        ..steps = data.steps
        ..heartRate = data.heartRate;

  ActivityData toEntity() => ActivityData(
        date: DateTime.fromMillisecondsSinceEpoch(dateMs),
        steps: steps,
        heartRate: heartRate,
      );
}

class ActivityDataAdapter extends TypeAdapter<ActivityDataModel> {
  @override
  final int typeId = 2;

  @override
  ActivityDataModel read(BinaryReader reader) {
    final model = ActivityDataModel()
      ..id = reader.readString()
      ..dateMs = reader.readInt()
      ..steps = reader.readInt();
    final hasHr = reader.readBool();
    model.heartRate = hasHr ? reader.readDouble() : null;
    return model;
  }

  @override
  void write(BinaryWriter writer, ActivityDataModel obj) {
    writer.writeString(obj.id);
    writer.writeInt(obj.dateMs);
    writer.writeInt(obj.steps);
    writer.writeBool(obj.heartRate != null);
    if (obj.heartRate != null) writer.writeDouble(obj.heartRate!);
  }
}

/// Агрегированная дневная сводка
class DailySummaryModel extends HiveObject {
  late String dateKey; // 'yyyy-MM-dd' — используется как ключ в box
  late int dateMs;
  late int sleepMinutes;
  late int steps;
  double? heartRate;
  late int recoveryIndex;
  late int wakeTimeOffset;

  DailySummaryModel();

  factory DailySummaryModel.fromEntity(DailyHealthSummary summary) {
    final key =
        '${summary.date.year}-${summary.date.month.toString().padLeft(2, '0')}-${summary.date.day.toString().padLeft(2, '0')}';
    return DailySummaryModel()
      ..dateKey = key
      ..dateMs = summary.date.millisecondsSinceEpoch
      ..sleepMinutes = summary.sleepMinutes
      ..steps = summary.steps
      ..heartRate = summary.heartRate
      ..recoveryIndex = summary.recoveryIndex
      ..wakeTimeOffset = summary.wakeTimeOffset;
  }

  DailyHealthSummary toEntity() => DailyHealthSummary(
        date: DateTime.fromMillisecondsSinceEpoch(dateMs),
        sleepMinutes: sleepMinutes,
        steps: steps,
        heartRate: heartRate,
        recoveryIndex: recoveryIndex,
        wakeTimeOffset: wakeTimeOffset,
      );
}

class DailySummaryAdapter extends TypeAdapter<DailySummaryModel> {
  @override
  final int typeId = 3;

  @override
  DailySummaryModel read(BinaryReader reader) {
    final model = DailySummaryModel()
      ..dateKey = reader.readString()
      ..dateMs = reader.readInt()
      ..sleepMinutes = reader.readInt()
      ..steps = reader.readInt();
    final hasHr = reader.readBool();
    model.heartRate = hasHr ? reader.readDouble() : null;
    model
      ..recoveryIndex = reader.readInt()
      ..wakeTimeOffset = reader.readInt();
    return model;
  }

  @override
  void write(BinaryWriter writer, DailySummaryModel obj) {
    writer.writeString(obj.dateKey);
    writer.writeInt(obj.dateMs);
    writer.writeInt(obj.sleepMinutes);
    writer.writeInt(obj.steps);
    writer.writeBool(obj.heartRate != null);
    if (obj.heartRate != null) writer.writeDouble(obj.heartRate!);
    writer.writeInt(obj.recoveryIndex);
    writer.writeInt(obj.wakeTimeOffset);
  }
}
