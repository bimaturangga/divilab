import 'package:flutter/material.dart';

import '../../../core/theme/app_palette.dart';
import '../../../core/theme/app_text.dart';
import '../../widgets/app_sheet.dart';

/// Panduan singkat penggunaan perangkat (ikon buku di top bar).
Future<void> showDeviceGuide(BuildContext context) {
  const steps = [
    ('Nyalakan perangkat', 'Tekan tombol START/STOP hingga layar menyala.'),
    ('Aktifkan Bluetooth', 'Pastikan Bluetooth ponsel aktif dan dekatkan ke perangkat.'),
    ('Pasang strip', 'Masukkan strip sesuai jenis pengukuran sampai berbunyi.'),
    ('Teteskan darah', 'Gunakan lancet, lalu teteskan darah ke ujung strip.'),
    ('Tunggu hasil', 'Hasil otomatis tersimpan ke aplikasi dalam ±5 detik.'),
  ];
  return showAppSheet<void>(
    context,
    builder: (ctx) {
      final p = ctx.palette;
      return SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(0, 0, 0, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SheetHeader(title: 'Panduan Pengukuran'),
              for (var i = 0; i < steps.length; i++)
                ListTile(
                  leading: CircleAvatar(
                    radius: 14,
                    backgroundColor: p.primary50,
                    child: Text('${i + 1}', style: AppText.labelSm.c(p.primary)),
                  ),
                  title: Text(steps[i].$1, style: AppText.title.c(p.textPrimary)),
                  subtitle: Text(steps[i].$2, style: AppText.bodySm.c(p.textSecondary)),
                ),
            ],
          ),
        ),
      );
    },
  );
}
