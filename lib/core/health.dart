import 'package:flutter/material.dart';

import 'theme/app_palette.dart';

/// Jenis pengukuran yang didukung perangkat DiViLab.
enum MeasurementType {
  glucose('glucose', 'Gula Darah', 'mg/dL', 'assets/images/metric_gula_darah.png'),
  cholesterol('cholesterol', 'Kolesterol', 'mg/dL', 'assets/images/metric_kolesterol.png'),
  uricAcid('uric_acid', 'Asam Urat', 'mg/dL', 'assets/images/metric_asam_urat.png'),
  bloodPressure('blood_pressure', 'Tekanan Darah', 'mmHg', 'assets/images/metric_tekanan_darah.png');

  const MeasurementType(this.key, this.label, this.unit, this.asset);

  final String key;
  final String label;
  final String unit;
  final String asset;

  /// Jenis yang memakai strip (tekanan darah memakai manset).
  bool get usesStrip => this != MeasurementType.bloodPressure;

  static MeasurementType fromKey(String key) =>
      MeasurementType.values.firstWhere((e) => e.key == key, orElse: () => MeasurementType.glucose);

  static const stripTypes = [MeasurementType.glucose, MeasurementType.cholesterol, MeasurementType.uricAcid];

  Color color(AppPalette p) => switch (this) {
        MeasurementType.glucose => p.primary,
        MeasurementType.cholesterol => p.warning,
        MeasurementType.uricAcid => p.success,
        MeasurementType.bloodPressure => p.purple,
      };
}

/// Tipe pengukuran gula darah.
enum GlucoseKind {
  gen('GEN', 'GEN (Sewaktu)'),
  ac('AC', 'AC (Puasa)'),
  pc('PC', 'PC (Setelah makan)');

  const GlucoseKind(this.code, this.label);
  final String code;
  final String label;

  static GlucoseKind? fromCode(String? code) {
    if (code == null) return null;
    for (final k in GlucoseKind.values) {
      if (k.code == code) return k;
    }
    return null;
  }
}

enum HealthStatus {
  low('Rendah'),
  normal('Normal'),
  high('Tinggi');

  const HealthStatus(this.label);
  final String label;

  Color color(AppPalette p) => switch (this) {
        HealthStatus.low => p.info,
        HealthStatus.normal => p.success,
        HealthStatus.high => p.danger,
      };

  Color background(AppPalette p) => switch (this) {
        HealthStatus.low => p.info50,
        HealthStatus.normal => p.success50,
        HealthStatus.high => p.danger50,
      };
}

/// Rentang normal: nilai < [min] = rendah, nilai > [max] = tinggi.
class ReferenceRange {
  const ReferenceRange(this.min, this.max);

  final double min;
  final double max;

  HealthStatus classify(double v) {
    if (v < min) return HealthStatus.low;
    if (v > max) return HealthStatus.high;
    return HealthStatus.normal;
  }

  /// Posisi 0..1 pada gauge 3 segmen (rendah 30% | normal 40% | tinggi 30%).
  double gaugePosition(double v) {
    if (v < min) return (0.3 * (v / min)).clamp(0.02, 0.29).toDouble();
    if (v <= max) return 0.3 + 0.4 * ((v - min) / (max - min));
    return (0.7 + 0.3 * ((v - max) / (max * 0.5))).clamp(0.71, 0.98).toDouble();
  }

  String get label => '${fmtNum(min)} – ${fmtNum(max)}';
}

/// Baris tabel "Nilai Rujukan".
class ReferenceTable {
  const ReferenceTable(this.title, this.low, this.normal, this.high);
  final String title;
  final String low;
  final String normal;
  final String high;
}

class HealthRanges {
  HealthRanges._();

  static ReferenceRange glucose(GlucoseKind kind) => switch (kind) {
        GlucoseKind.gen => const ReferenceRange(70, 139),
        GlucoseKind.ac => const ReferenceRange(70, 100),
        GlucoseKind.pc => const ReferenceRange(80, 139),
      };

  static const cholesterol = ReferenceRange(100, 200);
  static const uricAcid = ReferenceRange(3, 7);
  static const systolic = ReferenceRange(90, 139);
  static const diastolic = ReferenceRange(60, 89);
  static const pulse = ReferenceRange(60, 100);

  static ReferenceRange primaryRange(MeasurementType t, GlucoseKind? kind) => switch (t) {
        MeasurementType.glucose => glucose(kind ?? GlucoseKind.gen),
        MeasurementType.cholesterol => cholesterol,
        MeasurementType.uricAcid => uricAcid,
        MeasurementType.bloodPressure => systolic,
      };

  /// Status gabungan untuk tekanan darah: tinggi jika salah satu tinggi.
  static HealthStatus classify(MeasurementType t, double value, {double? value2, GlucoseKind? kind}) {
    if (t == MeasurementType.bloodPressure) {
      final s = systolic.classify(value);
      final d = diastolic.classify(value2 ?? 70);
      if (s == HealthStatus.high || d == HealthStatus.high) return HealthStatus.high;
      if (s == HealthStatus.low || d == HealthStatus.low) return HealthStatus.low;
      return HealthStatus.normal;
    }
    return primaryRange(t, kind).classify(value);
  }

  static String rangeLabel(MeasurementType t, GlucoseKind? kind) {
    if (t == MeasurementType.bloodPressure) return '90–139 / 60–89';
    return primaryRange(t, kind).label;
  }

  static List<ReferenceTable> references(MeasurementType t) => switch (t) {
        MeasurementType.glucose => const [
            ReferenceTable('A. Gula Darah GEN (Sewaktu)', '< 70', '70 – 139', '≥ 140'),
            ReferenceTable('B. Gula Darah AC (Puasa)', '< 70', '70 – 100', '> 100'),
            ReferenceTable('C. Gula Darah PC (2 jam setelah makan)', '< 80', '80 – 139', '≥ 140'),
          ],
        MeasurementType.cholesterol => const [
            ReferenceTable('A. Kolesterol Total', '< 100', '100 – 200', '> 200'),
          ],
        MeasurementType.uricAcid => const [
            ReferenceTable('A. Asam Urat', '< 3', '3 – 7', '> 7'),
          ],
        MeasurementType.bloodPressure => const [
            ReferenceTable('A. Tekanan Darah', '< 90 / 60', '90 – 139 / 60 – 89', '≥ 140 / 90'),
            ReferenceTable('B. Denyut Nadi', '< 60 bpm', '60 – 100 bpm', '> 100 bpm'),
          ],
      };
}

/// Format angka gaya Indonesia: 14.6 -> "14,6", 100.0 -> "100".
String fmtNum(num v, {int decimals = 1}) {
  if (v == v.roundToDouble()) return v.toInt().toString();
  return v.toStringAsFixed(decimals).replaceAll('.', ',');
}
