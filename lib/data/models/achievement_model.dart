import 'package:hive/hive.dart';
import '../../domain/entities/achievement.dart';

class AchievementModel extends HiveObject {
  late String id;
  late bool isUnlocked;
  int? unlockedAtMs;
  late int progress;

  AchievementModel();

  factory AchievementModel.fromEntity(Achievement a) => AchievementModel()
    ..id = a.id
    ..isUnlocked = a.isUnlocked
    ..unlockedAtMs = a.unlockedAt?.millisecondsSinceEpoch
    ..progress = a.progress;

  Achievement toEntity(Achievement template) => template.copyWith(
        isUnlocked: isUnlocked,
        unlockedAt: unlockedAtMs != null
            ? DateTime.fromMillisecondsSinceEpoch(unlockedAtMs!)
            : null,
        progress: progress,
      );
}

class AchievementAdapter extends TypeAdapter<AchievementModel> {
  @override
  final int typeId = 5;

  @override
  AchievementModel read(BinaryReader reader) {
    final model = AchievementModel()
      ..id = reader.readString()
      ..isUnlocked = reader.readBool();
    final hasDate = reader.readBool();
    model.unlockedAtMs = hasDate ? reader.readInt() : null;
    // progress добавлено позже — читаем с дефолтом для совместимости
    try {
      model.progress = reader.readInt();
    } catch (_) {
      model.progress = 0;
    }
    return model;
  }

  @override
  void write(BinaryWriter writer, AchievementModel obj) {
    writer.writeString(obj.id);
    writer.writeBool(obj.isUnlocked);
    writer.writeBool(obj.unlockedAtMs != null);
    if (obj.unlockedAtMs != null) writer.writeInt(obj.unlockedAtMs!);
    writer.writeInt(obj.progress);
  }
}
