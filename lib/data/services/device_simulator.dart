import 'dart:async';
import 'dart:math';

import '../../core/health.dart';

/// Satu pembacaan dari perangkat.
class DeviceReading {
  const DeviceReading({required this.value, this.value2, this.pulse, this.countdown, this.done = false});

  final double value; // nilai live / hasil akhir
  final double? value2;
  final int? pulse;
  final int? countdown; // detik tersisa (untuk strip)
  final bool done;
}

/// Simulasi perangkat DiViLab via Bluetooth.
///
/// Technical test ini tidak memakai perangkat fisik, jadi koneksi dan
/// hasil pengukuran disimulasikan. Antarmukanya dibuat seperti stream
/// Bluetooth sehingga mudah diganti dengan implementasi BLE sungguhan
/// (mis. package flutter_blue_plus) tanpa mengubah UI.
class DeviceSimulator {
  DeviceSimulator({Random? random}) : _rnd = random ?? Random();
  final Random _rnd;

  /// Simulasi proses mencari & memasangkan perangkat.
  Stream<int> connect() async* {
    yield 0; // Bluetooth aktif
    await Future<void>.delayed(const Duration(milliseconds: 900));
    yield 1; // mencari perangkat
    await Future<void>.delayed(const Duration(milliseconds: 1600));
    yield 2; // memasangkan
    await Future<void>.delayed(const Duration(milliseconds: 1000));
    yield 3; // terhubung
  }

  Stream<DeviceReading> measure(MeasurementType type) async* {
    if (type == MeasurementType.bloodPressure) {
      // Manset mengembang: tekanan naik bertahap, lalu hasil akhir.
      for (var p = 20; p <= 160; p += 10) {
        yield DeviceReading(value: p.toDouble());
        await Future<void>.delayed(const Duration(milliseconds: 220));
      }
      yield DeviceReading(
        value: (105 + _rnd.nextInt(30)).toDouble(),
        value2: (65 + _rnd.nextInt(23)).toDouble(),
        pulse: 65 + _rnd.nextInt(25),
        done: true,
      );
      return;
    }
    // Strip: hitung mundur 5 detik, lalu hasil.
    for (var s = 5; s >= 1; s--) {
      yield DeviceReading(value: 0, countdown: s);
      await Future<void>.delayed(const Duration(seconds: 1));
    }
    final value = switch (type) {
      MeasurementType.glucose => (85 + _rnd.nextInt(65)).toDouble(),
      MeasurementType.cholesterol => (150 + _rnd.nextInt(80)).toDouble(),
      MeasurementType.uricAcid => double.parse((3.5 + _rnd.nextDouble() * 4.5).toStringAsFixed(1)),
      MeasurementType.bloodPressure => 0.0,
    };
    yield DeviceReading(value: value, done: true);
  }
}
