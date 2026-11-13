import '../../core/health.dart';

/// Hasil pengukuran (tabel `measurements`).
class Measurement {
  const Measurement({
    this.id,
    required this.profileId,
    required this.type,
    this.glucoseKind,
    required this.value,
    this.value2,
    this.pulse,
    this.source = 'device',
    this.deviceName,
    this.note,
    required this.measuredAt,
  });

  final int? id;
  final int profileId;
  final MeasurementType type;
  final GlucoseKind? glucoseKind;
  final double value; // nilai utama / sistolik
  final double? value2; // diastolik
  final int? pulse; // denyut nadi
  final String source; // device | manual
  final String? deviceName;
  final String? note;
  final DateTime measuredAt;

  HealthStatus get status => HealthRanges.classify(type, value, value2: value2, kind: glucoseKind);

  String get displayValue =>
      type == MeasurementType.bloodPressure ? '${fmtNum(value)}/${fmtNum(value2 ?? 0)}' : fmtNum(value);

  String get title =>
      type == MeasurementType.glucose ? '${type.label} ${(glucoseKind ?? GlucoseKind.gen).code}' : type.label;

  double get gaugePosition => HealthRanges.primaryRange(type, glucoseKind).gaugePosition(value);

  Map<String, Object?> toMap() => {
        'id': id,
        'profile_id': profileId,
        'type': type.key,
        'subtype': glucoseKind?.code,
        'value': value,
        'value2': value2,
        'pulse': pulse,
        'source': source,
        'device_name': deviceName,
        'note': note,
        'measured_at': measuredAt.toIso8601String(),
      };

  factory Measurement.fromMap(Map<String, Object?> m) => Measurement(
        id: m['id'] as int?,
        profileId: m['profile_id'] as int,
        type: MeasurementType.fromKey(m['type'] as String),
        glucoseKind: GlucoseKind.fromCode(m['subtype'] as String?),
        value: (m['value'] as num).toDouble(),
        value2: (m['value2'] as num?)?.toDouble(),
        pulse: m['pulse'] as int?,
        source: (m['source'] as String?) ?? 'device',
        deviceName: m['device_name'] as String?,
        note: m['note'] as String?,
        measuredAt: DateTime.parse(m['measured_at'] as String),
      );
}
