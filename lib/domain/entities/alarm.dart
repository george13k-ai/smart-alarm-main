import '../../core/constants/app_constants.dart';

class Alarm {
  static const Object _qrCodeNoChange = Object();

  final String id;
  final String name;
  final int hour;
  final int minute;
  /// Дни недели: 1=Пн, 2=Вт, ..., 7=Вс (соответствует DateTime.weekday)
  final List<int> weekdays;
  final bool isEnabled;
  final DismissType dismissType;
  /// Сохранённый QR-код для режима QR
  final String? qrCode;
  /// Имя файла звука из assets/sounds/ (например 'alarm_sound.mp3')
  final String soundFile;

  const Alarm({
    required this.id,
    required this.name,
    required this.hour,
    required this.minute,
    required this.weekdays,
    required this.isEnabled,
    required this.dismissType,
    this.qrCode,
    this.soundFile = 'alarm_sound.wav',
  });

  String get timeLabel {
    final h = hour.toString().padLeft(2, '0');
    final m = minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  String get weekdaysLabel {
    if (weekdays.length == 7) return 'Каждый день';
    if (weekdays.isEmpty) return 'Один раз';
    final labels = const ['', 'Пн', 'Вт', 'Ср', 'Чт', 'Пт', 'Сб', 'Вс'];
    final sorted = [...weekdays]..sort();
    return sorted.map((d) => labels[d]).join(', ');
  }

  Alarm copyWith({
    String? id,
    String? name,
    int? hour,
    int? minute,
    List<int>? weekdays,
    bool? isEnabled,
    DismissType? dismissType,
    Object? qrCode = _qrCodeNoChange,
    String? soundFile,
  }) {
    return Alarm(
      id: id ?? this.id,
      name: name ?? this.name,
      hour: hour ?? this.hour,
      minute: minute ?? this.minute,
      weekdays: weekdays ?? this.weekdays,
      isEnabled: isEnabled ?? this.isEnabled,
      dismissType: dismissType ?? this.dismissType,
      qrCode: identical(qrCode, _qrCodeNoChange) ? this.qrCode : qrCode as String?,
      soundFile: soundFile ?? this.soundFile,
    );
  }
}
