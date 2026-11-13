import 'dart:math';

import 'package:sqflite/sqflite.dart';

import '../../core/config.dart';
import '../../core/health.dart';
import '../../core/utils/password_hasher.dart';
import '../models/measurement.dart';

/// Mengisi data awal saat database pertama kali dibuat:
/// akun demo + keluarga + riwayat pengukuran 10 hari terakhir,
/// supaya semua layar (laporan, grafik, prediksi) langsung terisi.
class DemoSeeder {
  DemoSeeder._();

  /// Data default untuk setiap user baru (strip & pengingat).
  static Future<void> insertDefaults(DatabaseExecutor db, int userId) async {
    for (final e in {'glucose': 10, 'cholesterol': 5, 'uric_acid': 6}.entries) {
      await db.insert('strip_stock', {'owner_id': userId, 'type': e.key, 'qty': e.value});
    }
    await db.insert('reminders', {
      'owner_id': userId,
      'title': 'Gula Darah',
      'types': 'glucose',
      'days': '1,3,5',
      'hour': 7,
      'minute': 0,
      'enabled': 1,
    });
    await db.insert('reminders', {
      'owner_id': userId,
      'title': 'Tekanan Darah',
      'types': 'blood_pressure',
      'days': '1,2,3,4,5,6,7',
      'hour': 6,
      'minute': 30,
      'enabled': 1,
    });
  }

  static Future<void> seed(Database db) async {
    final salt = PasswordHasher.newSalt();
    final now = DateTime.now();
    final userId = await db.insert('users', {
      'email': AppConfig.demoEmail,
      'password_hash': PasswordHasher.hash(AppConfig.demoPassword, salt),
      'salt': salt,
      'name': 'Jane Dane',
      'gender': 'Perempuan',
      'birth_date': DateTime(1990, 3, 12).toIso8601String(),
      'height': 165.0,
      'weight': 58.0,
      'production_code': 'DVIBGCU25121800X3',
      'created_at': now.toIso8601String(),
    });
    await insertDefaults(db, userId);
    await db.update('strip_stock', {'qty': 2}, where: 'owner_id = ? AND type = ?', whereArgs: [userId, 'cholesterol']);

    final ownerProfile = await db.insert('profiles', {
      'owner_id': userId,
      'name': 'Jane Dane',
      'relation': 'Pemilik Akun',
      'gender': 'Perempuan',
      'age': 36,
      'color_index': 5,
    });
    final family = [
      ['Johannes', 'Lainnya', 'Laki-laki', 58, 0],
      ['Yahya', 'Anak', 'Laki-laki', 12, 1],
      ['Putri', 'Saudara', 'Perempuan', 30, 2],
      ['Nuhaa', 'Lainnya', 'Perempuan', 9, 3],
      ['Dr. Lucia', 'Dokter', 'Perempuan', null, 4],
    ];
    final ids = <String, int>{};
    for (final f in family) {
      ids[f[0] as String] = await db.insert('profiles', {
        'owner_id': userId,
        'name': f[0],
        'relation': f[1],
        'gender': f[2],
        'age': f[3],
        'color_index': f[4],
      });
    }

    // Riwayat 10 hari untuk pemilik akun.
    final rnd = Random(42);
    final glucose = [96, 112, 104, 140, 121, 98, 100, 108, 115, 110];
    final batch = db.batch();
    void add(Measurement m) => batch.insert('measurements', m.toMap()..remove('id'));
    for (var i = 0; i < 10; i++) {
      final day = DateTime(now.year, now.month, now.day).subtract(Duration(days: 9 - i));
      add(Measurement(
        profileId: ownerProfile,
        type: MeasurementType.glucose,
        glucoseKind: GlucoseKind.gen,
        value: glucose[i].toDouble(),
        deviceName: 'DiViLab Optima',
        measuredAt: day.add(Duration(hours: 7, minutes: rnd.nextInt(50))),
      ));
      add(Measurement(
        profileId: ownerProfile,
        type: MeasurementType.bloodPressure,
        value: (110 + rnd.nextInt(18)).toDouble(),
        value2: (68 + rnd.nextInt(16)).toDouble(),
        pulse: 70 + rnd.nextInt(16),
        deviceName: 'DiViLab Optima',
        measuredAt: day.add(Duration(hours: 8, minutes: rnd.nextInt(50))),
      ));
      if (i % 3 == 0) {
        add(Measurement(
          profileId: ownerProfile,
          type: MeasurementType.cholesterol,
          value: (180 + rnd.nextInt(25)).toDouble(),
          deviceName: 'DiViLab Optima',
          measuredAt: day.add(const Duration(hours: 15, minutes: 35)),
        ));
        add(Measurement(
          profileId: ownerProfile,
          type: MeasurementType.uricAcid,
          value: double.parse((4.5 + rnd.nextDouble() * 2).toStringAsFixed(1)),
          deviceName: 'DiViLab Optima',
          measuredAt: day.add(const Duration(hours: 15, minutes: 36)),
        ));
      }
    }
    // Contoh hasil di luar normal untuk profil Yahya.
    final yesterday = now.subtract(const Duration(days: 1));
    add(Measurement(profileId: ids['Yahya']!, type: MeasurementType.uricAcid, value: 14.6, measuredAt: yesterday));
    add(Measurement(profileId: ids['Yahya']!, type: MeasurementType.cholesterol, value: 205, measuredAt: yesterday));
    await batch.commit(noResult: true);

    final msgs = [
      ['Pengukuran Asam Urat – Yahya', 'Asam urat Yahya 14,6 mg/dL (terdeteksi tinggi). Nilai ini berada di luar rentang normal, disarankan untuk konsultasi.'],
      ['Pengukuran Kolesterol – Yahya', 'Kolesterol Yahya 205 mg/dL (terdeteksi tinggi). Nilai ini berada di luar rentang normal.'],
      ['Strip Kolesterol Hampir Habis', 'Sisa strip kolesterol tinggal 2. Segera beli strip baru untuk melanjutkan pengukuran.'],
    ];
    for (final m in msgs) {
      await db.insert('messages', {'owner_id': userId, 'title': m[0], 'body': m[1], 'created_at': yesterday.toIso8601String(), 'read': 0});
    }
  }
}
