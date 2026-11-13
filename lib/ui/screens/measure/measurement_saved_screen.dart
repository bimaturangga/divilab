import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_palette.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/utils/date_fmt.dart';
import '../../../data/models/measurement.dart';
import '../../../state/app_state.dart';
import '../../../state/ui_controllers.dart';
import '../../widgets/app_button.dart';
import '../../widgets/common.dart';

class MeasurementSavedScreen extends StatelessWidget {
  const MeasurementSavedScreen({super.key, required this.measurement});
  final Measurement measurement;

  void _goTab(BuildContext context, int tab) {
    context.read<ShellController>().go(tab);
    Navigator.of(context).popUntil((r) => r.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final m = measurement;
    final profile = context.watch<AppState>().activeProfile;
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            children: [
              const Spacer(),
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(color: p.success50, shape: BoxShape.circle),
                alignment: Alignment.center,
                child: Container(
                  width: 76,
                  height: 76,
                  decoration: BoxDecoration(color: p.success, shape: BoxShape.circle),
                  child: const Icon(Icons.check_rounded, color: Colors.white, size: 42),
                ),
              ),
              const SizedBox(height: 20),
              Text('Hasil berhasil disimpan', style: AppText.h1.c(p.textPrimary)),
              const SizedBox(height: 6),
              Text(
                'Data pengukuran sudah masuk ke laporan dan bisa dipantau oleh keluarga Anda.',
                style: AppText.body.c(p.textSecondary),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: p.bgSubtle, borderRadius: BorderRadius.circular(20)),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(child: Text(m.title, style: AppText.title.c(p.textPrimary))),
                        StatusBadge(status: m.status),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(m.displayValue, style: AppText.displayLg.c(p.textPrimary)),
                        const SizedBox(width: 6),
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Text(m.type.unit, style: AppText.body.c(p.textSecondary)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    for (final kv in [
                      ('Pasien', profile?.name ?? '-'),
                      ('Waktu', DateFmt.dateTime(m.measuredAt)),
                      ('Sumber', m.source == 'manual' ? 'Input manual' : (m.deviceName ?? 'Perangkat')),
                    ])
                      Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Row(
                          children: [
                            Expanded(child: Text(kv.$1, style: AppText.bodySm.c(p.textSecondary))),
                            Text(kv.$2, style: AppText.label.c(p.textPrimary)),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              const Spacer(),
              AppButton(label: 'Lihat Laporan', onPressed: () => _goTab(context, 1)),
              const SizedBox(height: 12),
              AppButton(label: 'Kembali ke Beranda', variant: AppButtonVariant.secondary, onPressed: () => _goTab(context, 0)),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
