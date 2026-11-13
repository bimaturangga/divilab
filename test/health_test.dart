import 'package:divilab/core/forecast.dart';
import 'package:divilab/core/health.dart';
import 'package:divilab/core/utils/password_hasher.dart';
import 'package:divilab/core/utils/validators.dart';
import 'package:divilab/data/models/measurement.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Klasifikasi rentang kesehatan', () {
    test('gula darah GEN', () {
      expect(HealthRanges.classify(MeasurementType.glucose, 65, kind: GlucoseKind.gen), HealthStatus.low);
      expect(HealthRanges.classify(MeasurementType.glucose, 110, kind: GlucoseKind.gen), HealthStatus.normal);
      expect(HealthRanges.classify(MeasurementType.glucose, 140, kind: GlucoseKind.gen), HealthStatus.high);
    });

    test('gula darah puasa (AC) lebih ketat', () {
      expect(HealthRanges.classify(MeasurementType.glucose, 110, kind: GlucoseKind.ac), HealthStatus.high);
    });

    test('kolesterol & asam urat', () {
      expect(HealthRanges.classify(MeasurementType.cholesterol, 205), HealthStatus.high);
      expect(HealthRanges.classify(MeasurementType.uricAcid, 5.2), HealthStatus.normal);
      expect(HealthRanges.classify(MeasurementType.uricAcid, 14.6), HealthStatus.high);
    });

    test('tekanan darah memakai sistolik & diastolik', () {
      expect(HealthRanges.classify(MeasurementType.bloodPressure, 120, value2: 80), HealthStatus.normal);
      expect(HealthRanges.classify(MeasurementType.bloodPressure, 120, value2: 95), HealthStatus.high);
      expect(HealthRanges.classify(MeasurementType.bloodPressure, 85, value2: 55), HealthStatus.low);
    });

    test('posisi gauge berada di segmen yang benar', () {
      const r = ReferenceRange(70, 139);
      expect(r.gaugePosition(50), lessThan(0.3));
      expect(r.gaugePosition(100), inInclusiveRange(0.3, 0.7));
      expect(r.gaugePosition(200), greaterThan(0.7));
    });
  });

  group('Model Measurement', () {
    test('toMap/fromMap bolak-balik', () {
      final m = Measurement(
        id: 3,
        profileId: 1,
        type: MeasurementType.bloodPressure,
        value: 123,
        value2: 80,
        pulse: 78,
        measuredAt: DateTime(2026, 11, 13, 9, 30),
      );
      final back = Measurement.fromMap(m.toMap());
      expect(back.type, MeasurementType.bloodPressure);
      expect(back.displayValue, '123/80');
      expect(back.pulse, 78);
      expect(back.status, HealthStatus.normal);
    });

    test('format angka gaya Indonesia', () {
      expect(fmtNum(100.0), '100');
      expect(fmtNum(14.6), '14,6');
    });
  });

  group('Validasi form', () {
    test('email', () {
      expect(Validators.email('jane@mail.com'), isNull);
      expect(Validators.email('jane@'), isNotNull);
    });

    test('aturan password sesuai desain', () {
      expect(Validators.passwordRules('Divilab123').allMet, isFalse); // tanpa simbol
      expect(Validators.passwordRules('Divilab@2026').allMet, isTrue);
      expect(Validators.confirmPassword('a', 'b'), 'Konfirmasi password tidak cocok dengan password');
    });
  });

  group('Keamanan password', () {
    test('hash memakai salt & bisa diverifikasi', () {
      final salt = PasswordHasher.newSalt();
      final hash = PasswordHasher.hash('Divilab@2026', salt);
      expect(hash, isNot('Divilab@2026'));
      expect(PasswordHasher.verify('Divilab@2026', salt, hash), isTrue);
      expect(PasswordHasher.verify('salah', salt, hash), isFalse);
    });
  });

  group('Prediksi', () {
    test('butuh minimal 7 data', () {
      expect(Forecast.compute([100, 110, 120]), isNull);
    });

    test('tren naik menghasilkan prediksi lebih tinggi', () {
      final f = Forecast.compute([100, 102, 104, 106, 108, 110, 112])!;
      expect(f.predicted.first, closeTo(114, 0.001));
      expect(f.changePercent, greaterThan(0));
    });
  });
}
