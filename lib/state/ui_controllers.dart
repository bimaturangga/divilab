import 'package:flutter/foundation.dart';

import '../data/models/catalog.dart';

/// Tab aktif pada bottom navigation (agar layar lain bisa pindah tab).
class ShellController extends ChangeNotifier {
  int index = 0;

  void go(int i) {
    if (i == index) return;
    index = i;
    notifyListeners();
  }
}

/// Status koneksi perangkat (simulasi Bluetooth) & daftar perangkat user.
class DeviceController extends ChangeNotifier {
  final List<DeviceInfo> devices = [DeviceInfo.optima, DeviceInfo.core];
  DeviceInfo? connected;

  bool isConnected(DeviceInfo d) => connected?.code == d.code;

  void connect(DeviceInfo d) {
    connected = d;
    notifyListeners();
  }

  void disconnect() {
    connected = null;
    notifyListeners();
  }

  void addDevice(String code) {
    final c = code.trim().toUpperCase();
    final isCore = c.startsWith('DVIGC');
    devices.add(DeviceInfo(
      name: isCore ? 'DiViLab Core' : 'DiViLab Optima',
      code: c,
      asset: isCore ? DeviceInfo.core.asset : DeviceInfo.optima.asset,
      supportsBloodPressure: !isCore,
    ));
    notifyListeners();
  }
}
