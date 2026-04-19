import 'package:hive/hive.dart';
import '../../domain/entities/alarm.dart';
import '../../core/constants/app_constants.dart';

/// Ручные адаптеры — build_runner не требуется.
class AlarmModel extends HiveObject {
  late String id;
  late String name;
  late int hour;
  late int minute;
  late List<int> weekdays;
  late bool isEnabled;
  late int dismissTypeIndex;
  String? qrCode;
  late String soundFile;

  AlarmModel();

  factory AlarmModel.fromEntity(Alarm alarm) => AlarmModel()
    ..id = alarm.id
    ..name = alarm.name
    ..hour = alarm.hour
    ..minute = alarm.minute
    ..weekdays = List<int>.from(alarm.weekdays)
    ..isEnabled = alarm.isEnabled
    ..dismissTypeIndex = alarm.dismissType.index
    ..qrCode = alarm.qrCode
    ..soundFile = alarm.soundFile;

  Alarm toEntity() => Alarm(
        id: id,
        name: name,
        hour: hour,
        minute: minute,
        weekdays: List<int>.from(weekdays),
        isEnabled: isEnabled,
        dismissType: DismissType.values[dismissTypeIndex],
        qrCode: qrCode,
        soundFile: soundFile,
      );
}

class AlarmModelAdapter extends TypeAdapter<AlarmModel> {
  @override
  final int typeId = 0;

  @override
  AlarmModel read(BinaryReader reader) {
    final model = AlarmModel();
    model.id = reader.readString();
    model.name = reader.readString();
    model.hour = reader.readInt();
    model.minute = reader.readInt();
    model.weekdays = reader.readList().cast<int>();
    model.isEnabled = reader.readBool();
    model.dismissTypeIndex = reader.readInt();
    final hasQr = reader.readBool();
    model.qrCode = hasQr ? reader.readString() : null;
    // soundFile добавлено позже — читаем с дефолтом для совместимости
    try {
      model.soundFile = reader.readString();
    } catch (_) {
      model.soundFile = 'alarm_sound.wav';
    }
    return model;
  }

  @override
  void write(BinaryWriter writer, AlarmModel obj) {
    writer.writeString(obj.id);
    writer.writeString(obj.name);
    writer.writeInt(obj.hour);
    writer.writeInt(obj.minute);
    writer.writeList(obj.weekdays);
    writer.writeBool(obj.isEnabled);
    writer.writeInt(obj.dismissTypeIndex);
    writer.writeBool(obj.qrCode != null);
    if (obj.qrCode != null) writer.writeString(obj.qrCode!);
    writer.writeString(obj.soundFile);
  }
}
