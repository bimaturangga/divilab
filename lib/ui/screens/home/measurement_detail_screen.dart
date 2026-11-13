import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../core/health.dart';
import '../../../core/theme/app_palette.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/utils/date_fmt.dart';
import '../../../data/models/measurement.dart';
import '../../../state/app_state.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_sheet.dart';
import '../../widgets/common.dart';

/// Detail Pemeriksaan Terakhir + Nilai Rujukan.
class MeasurementDetailScreen extends StatelessWidget {
  const MeasurementDetailScreen({super.key, required this.measurement});
  final Measurement measurement;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final m = measurement;
    final profile = context.watch<AppState>().activeProfile;
    return Scaffold(
      appBar: AppTopBar(
        title: 'Detail Pemeriksaan',
        actions: [
          CircleIconButton(
            icon: Icons.share_outlined,
            tooltip: 'Salin ringkasan',
            onTap: () {
              Clipboard.setData(ClipboardData(
                text: '${m.title}: ${m.displayValue} ${m.type.unit} (${m.status.label}) – '
                    '${DateFmt.dateTime(m.measuredAt)} · ${profile?.name ?? ''}',
              ));
              showSnack(context, 'Ringkasan hasil disalin');
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: p.bgSurface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: p.borderDefault),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (profile != null) ...[
                  Row(
                    children: [
                      InitialsAvatar(initials: profile.initials, color: p.avatarColors[profile.colorIndex % 6], size: 36),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(profile.name, style: AppText.title.c(p.textPrimary)),
                            Text(profile.subtitle, style: AppText.caption.c(p.textSecondary)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const Padding(padding: EdgeInsets.symmetric(vertical: 14), child: Divider()),
                ],
                Row(
                  children: [
                    MetricIcon(type: m.type, size: 36),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(m.type.label, style: AppText.title.c(p.textPrimary)),
                          Text(
                            m.type == MeasurementType.glucose
                                ? (m.glucoseKind ?? GlucoseKind.gen).label
                                : (m.type == MeasurementType.bloodPressure ? 'Sistolik / Diastolik' : 'Total'),
                            style: AppText.caption.c(p.textTertiary),
                          ),
                        ],
                      ),
                    ),
                    StatusBadge(status: m.status),
                  ],
                ),
                const SizedBox(height: 14),
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
                if (m.pulse != null)
                  Text('Denyut nadi ${m.pulse} bpm', style: AppText.bodySm.c(p.textSecondary)),
                const SizedBox(height: 14),
                RangeGauge(position: m.gaugePosition, rangeLabel: HealthRanges.rangeLabel(m.type, m.glucoseKind)),
                const Padding(padding: EdgeInsets.symmetric(vertical: 14), child: Divider()),
                _kv(context, 'Tanggal pengukuran', DateFmt.dateTime(m.measuredAt)),
                const SizedBox(height: 8),
                _kv(context, 'Sumber', m.source == 'manual' ? 'Input manual' : (m.deviceName ?? 'Perangkat DiViLab')),
                if ((m.note ?? '').isNotEmpty) ...[
                  const SizedBox(height: 8),
                  _kv(context, 'Catatan', m.note!),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(color: p.bgSubtle, borderRadius: BorderRadius.circular(10)),
            child: Text('Nilai Rujukan', style: AppText.title.c(p.textPrimary)),
          ),
          const SizedBox(height: 12),
          for (final r in HealthRanges.references(m.type))
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(r.title, style: AppText.label.c(p.textPrimary)),
                  const SizedBox(height: 6),
                  _refRow(context, HealthStatus.low, r.low),
                  _refRow(context, HealthStatus.normal, r.normal),
                  _refRow(context, HealthStatus.high, r.high),
                ],
              ),
            ),
          const SizedBox(height: 8),
          if (m.status != HealthStatus.normal)
            const NoteBox(
              tone: NoteTone.warning,
              icon: Icons.warning_amber_rounded,
              text: 'Hasil berada di luar rentang normal. Ukur ulang dan konsultasikan dengan dokter bila tetap sama.',
            ),
          const SizedBox(height: 16),
          AppButton(label: 'Kembali', variant: AppButtonVariant.secondary, onPressed: () => Navigator.pop(context)),
        ],
      ),
    );
  }

  Widget _kv(BuildContext context, String k, String v) {
    final p = context.palette;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: Text(k, style: AppText.bodySm.c(p.textSecondary))),
        Flexible(child: Text(v, style: AppText.label.c(p.textPrimary), textAlign: TextAlign.right)),
      ],
    );
  }

  Widget _refRow(BuildContext context, HealthStatus s, String v) {
    final p = context.palette;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Container(width: 8, height: 8, decoration: BoxDecoration(color: s.color(p), shape: BoxShape.circle)),
          const SizedBox(width: 8),
          SizedBox(width: 70, child: Text(s.label, style: AppText.bodySm.c(p.textSecondary))),
          Text(v, style: AppText.bodySm.c(p.textPrimary)),
        ],
      ),
    );
  }
}
