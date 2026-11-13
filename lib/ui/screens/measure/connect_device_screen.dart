import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_palette.dart';
import '../../../core/theme/app_text.dart';
import '../../../data/models/catalog.dart';
import '../../../data/services/device_simulator.dart';
import '../../../state/ui_controllers.dart';
import '../../widgets/app_button.dart';
import '../../widgets/common.dart';
import 'measurement_screen.dart';

/// "Hubungkan Perangkat Sekarang".
class ConnectDeviceScreen extends StatelessWidget {
  const ConnectDeviceScreen({super.key, required this.device});
  final DeviceInfo device;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final other = context.watch<DeviceController>().connected;
    return Scaffold(
      appBar: const AppTopBar(),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              children: [
                Text('Hubungkan Perangkat Sekarang', style: AppText.h1.c(p.textPrimary)),
                const SizedBox(height: 8),
                Text(
                  'Pastikan Bluetooth Anda aktif sebelum menghubungkan ke perangkat ${device.name} berikut.',
                  style: AppText.body.c(p.textSecondary),
                ),
                const SizedBox(height: 32),
                Center(
                  child: Container(
                    width: 240,
                    height: 220,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24)),
                    child: Image.asset(device.asset, fit: BoxFit.contain),
                  ),
                ),
                const SizedBox(height: 14),
                Center(child: Text(device.name, style: AppText.h3.c(p.textPrimary))),
                Center(child: Text('Kode: ${device.code}', style: AppText.caption.c(p.textTertiary))),
                const SizedBox(height: 32),
                if (other != null && other.code != device.code)
                  NoteBox(
                    tone: NoteTone.warning,
                    icon: Icons.warning_amber_rounded,
                    text: 'Menghubungkan ke perangkat ini akan memutuskan koneksi ${other.name} yang sedang aktif.',
                  )
                else
                  const NoteBox(
                    tone: NoteTone.warning,
                    icon: Icons.warning_amber_rounded,
                    text: 'Menghubungkan ke perangkat lain akan memutuskan koneksi perangkat yang sedang aktif.',
                  ),
              ],
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
              child: AppButton(
                label: 'Hubungkan Bluetooth',
                icon: Icons.bluetooth_rounded,
                onPressed: () => Navigator.of(context).pushReplacement(
                  MaterialPageRoute<void>(builder: (_) => ConnectingScreen(device: device)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// "Menghubungkan…" — simulasi pencarian & pairing Bluetooth.
class ConnectingScreen extends StatefulWidget {
  const ConnectingScreen({super.key, required this.device});
  final DeviceInfo device;

  @override
  State<ConnectingScreen> createState() => _ConnectingScreenState();
}

class _ConnectingScreenState extends State<ConnectingScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _pulse =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1600))..repeat();
  StreamSubscription<int>? _sub;
  int _step = 0;

  @override
  void initState() {
    super.initState();
    _sub = context.read<DeviceSimulator>().connect().listen((s) {
      if (!mounted) return;
      setState(() => _step = s);
      if (s == 3) {
        context.read<DeviceController>().connect(widget.device);
        Navigator.of(context).pushReplacement(
          MaterialPageRoute<void>(builder: (_) => MeasurementScreen(device: widget.device)),
        );
      }
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    const labels = ['Bluetooth aktif', 'Mencari perangkat', 'Memasangkan perangkat'];
    return Scaffold(
      appBar: const AppTopBar(),
      body: Column(
        children: [
          Text('Menghubungkan…', style: AppText.h1.c(p.textPrimary)),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              'Dekatkan ponsel ke ${widget.device.name} dan biarkan perangkat tetap menyala.',
              style: AppText.body.c(p.textSecondary),
              textAlign: TextAlign.center,
            ),
          ),
          Expanded(
            child: Center(
              child: AnimatedBuilder(
                animation: _pulse,
                builder: (_, child) => Stack(
                  alignment: Alignment.center,
                  children: [
                    for (var k = 0; k < 3; k++)
                      _ring(160 + 140 * ((_pulse.value + k / 3) % 1), 1 - ((_pulse.value + k / 3) % 1), p.primary),
                    child!,
                  ],
                ),
                child: Container(
                  width: 120,
                  height: 120,
                  padding: const EdgeInsets.all(14),
                  decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                  child: Image.asset(widget.device.asset, fit: BoxFit.contain),
                ),
              ),
            ),
          ),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: p.bgSubtle, borderRadius: BorderRadius.circular(16)),
            child: Column(
              children: [
                for (var i = 0; i < 3; i++)
                  Padding(
                    padding: EdgeInsets.only(bottom: i < 2 ? 12 : 0),
                    child: Row(
                      children: [
                        Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            color: i < _step ? p.success : (i == _step ? p.primary50 : p.bgMuted),
                            shape: BoxShape.circle,
                          ),
                          child: i < _step
                              ? const Icon(Icons.check_rounded, size: 14, color: Colors.white)
                              : (i == _step
                                  ? Padding(
                                      padding: const EdgeInsets.all(5),
                                      child: CircularProgressIndicator(strokeWidth: 2, color: p.primary),
                                    )
                                  : null),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          labels[i],
                          style: (i <= _step ? AppText.title : AppText.body).c(i <= _step ? p.textPrimary : p.textTertiary),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
              child: AppButton(
                label: 'Batalkan',
                variant: AppButtonVariant.secondary,
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _ring(double size, double opacity, Color color) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color.withAlpha((opacity * 40).round()),
          border: Border.all(color: color.withAlpha((opacity * 90).round())),
        ),
      );
}
