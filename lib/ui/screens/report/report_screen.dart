import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../core/forecast.dart';
import '../../../core/health.dart';
import '../../../core/theme/app_palette.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/utils/date_fmt.dart';
import '../../../data/models/measurement.dart';
import '../../../state/app_state.dart';
import '../../../state/health_store.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_sheet.dart';
import '../../widgets/brand.dart';
import '../../widgets/common.dart';
import '../../widgets/line_chart.dart';
import '../home/switch_account_sheet.dart';
import 'history_screen.dart';

class ReportScreen extends StatefulWidget {
  const ReportScreen({super.key});

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  int _tab = 0;
  MeasurementType _forecastType = MeasurementType.glucose;

  void _download(HealthStore store, String name) {
    final b = StringBuffer('pasien,jenis,tipe,nilai,nilai2,denyut,status,sumber,waktu\n');
    for (final m in store.measurements) {
      b.writeln([
        name,
        m.type.label,
        m.glucoseKind?.code ?? '',
        m.value,
        m.value2 ?? '',
        m.pulse ?? '',
        m.status.label,
        m.source,
        m.measuredAt.toIso8601String(),
      ].join(','));
    }
    Clipboard.setData(ClipboardData(text: b.toString()));
    showSnack(context, 'Laporan ${store.measurements.length} pengukuran disalin sebagai CSV');
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final app = context.watch<AppState>();
    final store = context.watch<HealthStore>();
    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: store.refresh,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
            children: [
              Row(
                children: [
                  Expanded(child: Text('Laporan', style: AppText.h1.c(p.textPrimary))),
                  Material(
                    color: p.bgMuted,
                    shape: const StadiumBorder(),
                    child: InkWell(
                      customBorder: const StadiumBorder(),
                      onTap: () => _download(store, app.activeProfile?.name ?? ''),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.download_rounded, size: 16, color: p.textPrimary),
                            const SizedBox(width: 6),
                            Text('Download', style: AppText.label.c(p.textPrimary)),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  CircleIconButton(
                    icon: Icons.cloud_sync_outlined,
                    tooltip: 'Sinkronkan',
                    onTap: () async {
                      await store.refresh();
                      if (context.mounted) showSnack(context, 'Data sudah diperbarui');
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SegmentedTabs(labels: const ['Pengukuran', 'Prediksi'], index: _tab, onChanged: (i) => setState(() => _tab = i)),
              const SizedBox(height: 14),
              InkWell(
                onTap: () => showSwitchAccountSheet(context, title: 'Pilih Pasien'),
                child: Row(
                  children: [
                    Text(app.activeProfile?.name ?? '-', style: AppText.h3.c(p.textPrimary)),
                    Icon(Icons.keyboard_arrow_down_rounded, color: p.textPrimary),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              if (_tab == 0) ..._measurementCards(store) else _forecast(store),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _measurementCards(HealthStore store) {
    final p = context.palette;
    return [
      for (final t in MeasurementType.values)
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Material(
            color: p.bgSubtle,
            clipBehavior: Clip.antiAlias,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: p.borderDefault)),
            child: InkWell(
              onTap: () => push(context, HistoryScreen(type: t)),
              child: IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 16, 12, 16),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container(width: 10, height: 10, decoration: BoxDecoration(color: t.color(p), shape: BoxShape.circle)),
                                      const SizedBox(width: 8),
                                      Text(t.label, style: AppText.h3.c(p.textPrimary)),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      StatusBadge(status: store.latest(t)?.status),
                                      const SizedBox(width: 10),
                                      if (store.latest(t) != null)
                                        Flexible(
                                          child: Text(
                                            '${DateFmt.time(store.latest(t)!.measuredAt)} · ${DateFmt.dateShort(store.latest(t)!.measuredAt)}',
                                            style: AppText.caption.c(p.textSecondary),
                                          ),
                                        ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            MetricIcon(type: t, size: 56),
                          ],
                        ),
                      ),
                    ),
                    Container(width: 6, color: t.color(p)),
                  ],
                ),
              ),
            ),
          ),
        ),
    ];
  }

  Widget _forecast(HealthStore store) {
    final p = context.palette;
    final type = _forecastType;
    final list = store.filter(type: type).reversed.toList(); // lama -> baru
    final values = list.map((m) => m.value).toList();
    final fc = Forecast.compute(values);
    final range = HealthRanges.primaryRange(type, GlucoseKind.gen);
    final recent = list.length > 7 ? list.sublist(list.length - 7) : list;

    final selector = Row(
      children: [
        Expanded(
          child: Material(
            color: p.bgSubtle,
            borderRadius: BorderRadius.circular(12),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: _pickForecastType,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        type == MeasurementType.bloodPressure ? 'Tekanan Darah (Sistolik)' : type.label,
                        style: AppText.body.c(p.textPrimary),
                      ),
                    ),
                    Icon(Icons.keyboard_arrow_down_rounded, color: p.textSecondary),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );

    if (fc == null) {
      return Column(
        children: [
          selector,
          const SizedBox(height: 16),
          Stack(
            alignment: Alignment.center,
            children: [
              SimpleLineChart(
                xLabels: const ['1', '2', '3', '4', '5', '6', '7'],
                series: const [],
                yMin: 0,
                yMax: type == MeasurementType.uricAcid ? 15 : 300,
                height: 260,
              ),
              Container(
                width: 260,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: p.bgSurface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: p.borderDefault),
                  boxShadow: const [BoxShadow(color: Color(0x14000000), blurRadius: 16, offset: Offset(0, 6))],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.insights_rounded, color: p.primary),
                    const SizedBox(height: 6),
                    Text('Data Belum Memadai', style: AppText.title.c(p.textPrimary)),
                    const SizedBox(height: 4),
                    Text(
                      'Prediksi tersedia setelah minimal ${Forecast.minSamples} kali pengukuran ${type.label.toLowerCase()}.',
                      style: AppText.caption.c(p.textSecondary),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: p.bgSubtle, borderRadius: BorderRadius.circular(16)),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(child: Text('Pengukuran terkumpul', style: AppText.bodySm.c(p.textSecondary))),
                    Text('${values.length} / ${Forecast.minSamples}', style: AppText.title.c(p.primary)),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    for (var i = 0; i < Forecast.minSamples; i++) ...[
                      if (i > 0) const SizedBox(width: 4),
                      Expanded(
                        child: Container(
                          height: 6,
                          decoration: BoxDecoration(
                            color: i < values.length ? p.primary : p.borderDefault,
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      );
    }

    final actual = recent.map((m) => m.value).toList();
    final all = [...actual, ...fc.predicted, range.min, range.max];
    final step = type == MeasurementType.uricAcid ? 1.0 : 10.0;
    final lo = all.reduce(math.min);
    final hi = all.reduce(math.max);
    final pad = (hi - lo) * 0.15 + step;
    final yMin = math.max(0.0, ((lo - pad) / step).floor() * step);
    final yMax = ((hi + pad) / step).ceil() * step;
    final lastDate = recent.last.measuredAt;
    final labels = [
      for (final m in recent) '${m.measuredAt.day}',
      for (var i = 1; i <= fc.predicted.length; i++) '${lastDate.add(Duration(days: i)).day}',
    ];
    final up = fc.changePercent >= 0;
    final predictedLast = fc.predicted.last;
    final predictedStatus = range.classify(predictedLast);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        selector,
        const SizedBox(height: 16),
        SimpleLineChart(
          xLabels: labels,
          yMin: yMin,
          yMax: yMax.toDouble(),
          bandMin: range.min,
          bandMax: range.max,
          series: [
            ChartSeries(values: actual, color: p.primary),
            ChartSeries(values: [actual.last, ...fc.predicted], color: p.purple, dashed: true, offset: actual.length - 1),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 16,
          children: [
            _legend(p.primary, 'Aktual'),
            _legend(p.purple, 'Prediksi AI'),
            _legend(p.success50, 'Rentang normal'),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: p.purple50, borderRadius: BorderRadius.circular(16)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.smart_toy_outlined, size: 20, color: p.purple),
                  const SizedBox(width: 8),
                  Text('Insight AI', style: AppText.title.c(p.purple)),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Rata-rata ${type.label.toLowerCase()} Anda ${fmtNum(fc.average)} ${type.unit} dan cenderung '
                '${up ? 'naik' : 'turun'} ±${fmtNum(fc.changePercent.abs())}% dalam ${fc.predicted.length} hari ke depan. '
                '${predictedStatus == HealthStatus.normal ? 'Perkiraan masih dalam rentang normal, pertahankan pola hidup sehat Anda.' : 'Perkiraan berada di luar rentang normal, pertimbangkan konsultasi dengan dokter.'}',
                style: AppText.bodySm.c(p.textSecondary),
              ),
              const SizedBox(height: 6),
              Text('Prediksi berdasarkan tren data Anda, bukan diagnosis medis.', style: AppText.caption.c(p.textTertiary)),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            _stat('Rata-rata', fc.average, type),
            const SizedBox(width: 10),
            _stat('Tertinggi', fc.max, type),
            const SizedBox(width: 10),
            _stat('Prediksi', predictedLast, type),
          ],
        ),
      ],
    );
  }

  Widget _legend(Color c, String label) {
    final p = context.palette;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 14, height: 4, decoration: BoxDecoration(color: c, borderRadius: BorderRadius.circular(2))),
        const SizedBox(width: 6),
        Text(label, style: AppText.caption.c(p.textSecondary)),
      ],
    );
  }

  Widget _stat(String label, double v, MeasurementType t) {
    final p = context.palette;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(color: p.bgSubtle, borderRadius: BorderRadius.circular(12)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: AppText.caption.c(p.textSecondary)),
            const SizedBox(height: 2),
            Text('${fmtNum(v)} ${t.unit}', style: AppText.title.c(p.textPrimary), maxLines: 1, overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
    );
  }

  void _pickForecastType() {
    showAppSheet<void>(
      context,
      builder: (ctx) {
        final p = ctx.palette;
        return SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SheetHeader(title: 'Pilih Jenis Prediksi'),
                for (final t in MeasurementType.values)
                  ListTile(
                    leading: MetricIcon(type: t),
                    title: Text(t.label, style: AppText.title.c(p.textPrimary)),
                    trailing: t == _forecastType ? Icon(Icons.check_circle_rounded, color: p.primary) : null,
                    onTap: () {
                      setState(() => _forecastType = t);
                      Navigator.pop(ctx);
                    },
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Dipakai history_screen untuk statistik ringkas.
({double avg, double min, double max}) statsOf(List<Measurement> list) {
  final v = list.map((e) => e.value).toList();
  if (v.isEmpty) return (avg: 0.0, min: 0.0, max: 0.0);
  return (avg: v.reduce((a, b) => a + b) / v.length, min: v.reduce(math.min), max: v.reduce(math.max));
}
