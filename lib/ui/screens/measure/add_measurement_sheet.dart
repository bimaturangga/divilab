import 'package:flutter/material.dart';

import '../../../core/theme/app_palette.dart';
import '../../../core/theme/app_text.dart';
import '../../widgets/app_sheet.dart';
import 'manual_measurement_screen.dart';
import 'select_device_screen.dart';

/// Sheet "Tambah pengukuran" dari tombol + di bottom navigation.
Future<void> showAddMeasurementSheet(BuildContext context) {
  return showAppSheet<void>(
    context,
    builder: (ctx) {
      final p = ctx.palette;
      Widget option(IconData icon, String title, String subtitle, Widget page) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Material(
              color: p.bgSubtle,
              borderRadius: BorderRadius.circular(14),
              child: InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: () {
                  final nav = Navigator.of(ctx);
                  nav.pop();
                  nav.push(MaterialPageRoute<void>(builder: (_) => page));
                },
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(color: p.primary50, borderRadius: BorderRadius.circular(12)),
                        child: Icon(icon, color: p.primary, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(title, style: AppText.title.c(p.textPrimary)),
                            const SizedBox(height: 2),
                            Text(subtitle, style: AppText.caption.c(p.textSecondary)),
                          ],
                        ),
                      ),
                      Icon(Icons.chevron_right_rounded, color: p.textSecondary),
                    ],
                  ),
                ),
              ),
            ),
          );
      return SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SheetHeader(title: 'Tambah pengukuran'),
              const SizedBox(height: 4),
              option(Icons.edit_note_rounded, 'Pengukuran Manual', 'Masukkan hasil pengukuran sendiri',
                  const ManualMeasurementScreen()),
              option(Icons.bluetooth_rounded, 'Menggunakan Perangkat', 'Ukur otomatis dengan DiViLab via Bluetooth',
                  const SelectDeviceScreen()),
            ],
          ),
        ),
      );
    },
  );
}
