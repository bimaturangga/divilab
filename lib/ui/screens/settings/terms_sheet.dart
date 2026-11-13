import 'package:flutter/material.dart';

import '../../../core/theme/app_palette.dart';
import '../../../core/theme/app_text.dart';
import '../../widgets/app_sheet.dart';

Future<void> showTermsSheet(BuildContext context) {
  const sections = [
    ('Penggunaan Aplikasi',
        'DiViLab membantu mencatat dan memantau hasil pengukuran kesehatan. Aplikasi ini bukan alat diagnosis dan tidak menggantikan konsultasi dengan tenaga medis.'),
    ('Data Pribadi',
        'Data akun dan hasil pengukuran disimpan secara lokal di perangkat Anda (SQLite). Password disimpan dalam bentuk hash, bukan teks asli.'),
    ('Asisten AI',
        'Jawaban asisten dibuat otomatis berdasarkan data Anda dan dapat keliru. Selalu konfirmasikan keputusan kesehatan dengan dokter.'),
    ('Data Pihak Ketiga',
        'Daftar akun pada fitur Ganti Akun diambil dari layanan publik dummyjson.com untuk keperluan demonstrasi.'),
  ];
  return showAppSheet<void>(
    context,
    builder: (ctx) {
      final p = ctx.palette;
      return SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SheetHeader(title: 'Syarat & Ketentuan'),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                children: [
                  for (final s in sections) ...[
                    Text(s.$1, style: AppText.title.c(p.textPrimary)),
                    const SizedBox(height: 4),
                    Text(s.$2, style: AppText.bodySm.c(p.textSecondary)),
                    const SizedBox(height: 14),
                  ],
                ],
              ),
            ),
          ],
        ),
      );
    },
  );
}
