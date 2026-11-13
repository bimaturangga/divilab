import '../../core/health.dart';
import '../../core/utils/date_fmt.dart';

/// Pengingat pengukuran (tabel `reminders`).
class Reminder {
  const Reminder({
    this.id,
    required this.ownerId,
    required this.title,
    required this.types,
    required this.days,
    required this.hour,
    required this.minute,
    this.enabled = true,
  });

  final int? id;
  final int ownerId;
  final String title;
  final List<MeasurementType> types;
  final List<int> days; // 1 = Senin ... 7 = Minggu
  final int hour;
  final int minute;
  final bool enabled;

  String get timeLabel => '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';

  String get scheduleLabel {
    final sorted = [...days]..sort();
    final dayText = sorted.length == 7 ? 'Setiap hari' : sorted.map((d) => DateFmt.daysShort[d - 1]).join(', ');
    return '$dayText · $timeLabel';
  }

  Map<String, Object?> toMap() => {
        'id': id,
        'owner_id': ownerId,
        'title': title,
        'types': types.map((e) => e.key).join(','),
        'days': days.join(','),
        'hour': hour,
        'minute': minute,
        'enabled': enabled ? 1 : 0,
      };

  factory Reminder.fromMap(Map<String, Object?> m) => Reminder(
        id: m['id'] as int?,
        ownerId: m['owner_id'] as int,
        title: m['title'] as String,
        types: (m['types'] as String).split(',').where((e) => e.isNotEmpty).map(MeasurementType.fromKey).toList(),
        days: (m['days'] as String).split(',').where((e) => e.isNotEmpty).map(int.parse).toList(),
        hour: m['hour'] as int,
        minute: m['minute'] as int,
        enabled: (m['enabled'] as int) == 1,
      );

  Reminder copyWith({bool? enabled}) => Reminder(
        id: id,
        ownerId: ownerId,
        title: title,
        types: types,
        days: days,
        hour: hour,
        minute: minute,
        enabled: enabled ?? this.enabled,
      );
}
