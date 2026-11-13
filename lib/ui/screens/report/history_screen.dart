import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

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
import '../home/measurement_detail_screen.dart';
import 'period_picker_sheet.dart';
import 'report_screen.dart';

/// Riwayat per jenis pengukuran (list / grafik), filter periode & tipe.
class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key, required this.type});
  final MeasurementType type;

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  int _mode = 0; // 0 = 7 hari, 1 = pilih periode
  DateTimeRange? _custom;
  GlucoseKind? _kind;
  bool _chart = false;

  DateTimeRange get _range {
    if (_mode == 1 && _custom != null) return _custom!;
    final now = DateTime.now();
    return DateTimeRange(start: DateFmt.startOfDay(now.subtract(const Duration(days: 6))), end: DateFmt.endOfDay(now));
  }

  Future<void> _pickPeriod() async {
    final r = await showPeriodPicker(context, initial: _custom);
    if (r != null) {
      setState(() {
        _custom = r;
        _mode = 1;
      });
    }
  }

  Future<void> _confirmDelete(Measurement m) async {
    final store = context.read<HealthStore>();
    final ok = await showAppDialog<bool>(
      context,
      builder: (ctx) {
        final p = ctx.palette;
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(color: p.danger50, shape: BoxShape.circle),
                child: Icon(Icons.delete_outline_rounded, color: p.danger, size: 26),
              ),
              const SizedBox(height: 12),
              Text('Hapus data pengukuran?', style: AppText.h2.c(p.textPrimary)),
              const SizedBox(height: 8),
              Text(
                'Data ${m.type.label} ${m.displayValue} ${m.type.unit} pada ${DateFmt.dateTime(m.measuredAt)} '
                'akan dihapus permanen dari laporan.',
                style: AppText.body.c(p.textSecondary),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: AppButton(label: 'Batal', variant: AppButtonVariant.secondary, onPressed: () => Navigator.pop(ctx, false)),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: AppButton(label: 'Hapus', variant: AppButtonVariant.danger, onPressed: () => Navigator.pop(ctx, true)),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
    if (ok == true) {
      await store.delete(m);
      if (mounted) showSnack(context, 'Data pengukuran dihapus');
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final store = context.watch<HealthStore>();
    final profile = context.watch<AppState>().activeProfile;
    final range = _range;
    final items = store.filter(type: widget.type, from: range.start, to: range.end, kind: _kind);
    return Scaffold(
      appBar: AppTopBar(title: widget.type.label),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
        children: [
          SegmentedTabs(
            labels: const ['7 Hari', 'Pilih Periode'],
            icons: const [null, Icons.calendar_month_outlined],
            index: _mode,
            onChanged: (i) => i == 1 ? _pickPeriod() : setState(() => _mode = 0),
          ),
          const SizedBox(height: 14),
          Text(profile?.name ?? '-', style: AppText.h3.c(p.textPrimary)),
          if (widget.type == MeasurementType.glucose) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: [
                ChoicePill(label: 'Semua', selected: _kind == null, outlined: true, onTap: () => setState(() => _kind = null)),
                for (final k in GlucoseKind.values)
                  ChoicePill(label: k.code, selected: _kind == k, outlined: true, onTap: () => setState(() => _kind = k)),
              ],
            ),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: Text(DateFmt.range(range.start, range.end), style: AppText.label.c(p.textSecondary))),
              Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(color: p.bgMuted, borderRadius: BorderRadius.circular(10)),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (final (icon, isChart) in const [(Icons.show_chart_rounded, true), (Icons.format_list_bulleted_rounded, false)])
                      GestureDetector(
                        onTap: () => setState(() => _chart = isChart),
                        child: Container(
                          width: 34,
                          height: 28,
                          decoration: BoxDecoration(
                            color: _chart == isChart ? p.primary : Colors.transparent,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(icon, size: 16, color: _chart == isChart ? p.textOnPrimary : p.textSecondary),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (items.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 48),
              child: Column(
                children: [
                  Icon(Icons.event_busy_rounded, size: 48, color: p.textTertiary),
                  const SizedBox(height: 10),
                  Text('Belum ada data pada periode ini', style: AppText.title.c(p.textPrimary)),
                  const SizedBox(height: 4),
                  Text('Coba pilih periode lain atau lakukan pengukuran.', style: AppText.bodySm.c(p.textSecondary)),
                ],
              ),
            )
          else if (_chart)
            ..._chartView(items)
          else
            ..._listView(items),
        ],
      ),
    );
  }

  List<Widget> _listView(List<Measurement> items) {
    final p = context.palette;
    final widgets = <Widget>[];
    String? lastDay;
    for (final m in items) {
      final day = DateFmt.dayHeader(m.measuredAt);
      if (day != lastDay) {
        lastDay = day;
        widgets.add(Padding(
          padding: const EdgeInsets.only(bottom: 10, top: 4),
          child: Text(day, style: AppText.title.c(p.textPrimary)),
        ));
      }
      widgets.add(Padding(padding: const EdgeInsets.only(bottom: 12), child: _entry(m)));
    }
    return widgets;
  }

  Widget _entry(Measurement m) {
    final p = context.palette;
    return Material(
      color: p.bgSubtle,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: p.borderDefault)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => push(context, MeasurementDetailScreen(measurement: m)),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(width: 10, height: 10, decoration: BoxDecoration(color: m.type.color(p), shape: BoxShape.circle)),
                  const SizedBox(width: 8),
                  Expanded(child: Text(m.title, style: AppText.title.c(p.textPrimary))),
                  Text(DateFmt.time(m.measuredAt), style: AppText.caption.c(p.textSecondary)),
                  const SizedBox(width: 4),
                  Icon(Icons.schedule_rounded, size: 12, color: p.textSecondary),
                  const SizedBox(width: 8),
                  InkWell(
                    borderRadius: BorderRadius.circular(99),
                    onTap: () => _confirmDelete(m),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(borderRadius: BorderRadius.circular(99), border: Border.all(color: p.danger)),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('Hapus', style: AppText.labelSm.c(p.danger)),
                          const SizedBox(width: 2),
                          Icon(Icons.delete_outline_rounded, size: 12, color: p.danger),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(m.displayValue, style: AppText.h1.c(p.textPrimary)),
                  const SizedBox(width: 6),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 3),
                    child: Text(
                      m.pulse == null ? m.type.unit : '${m.type.unit}   ${m.pulse} bpm',
                      style: AppText.bodySm.c(p.textSecondary),
                    ),
                  ),
                  const Spacer(),
                  StatusBadge(status: m.status),
                ],
              ),
              const SizedBox(height: 8),
              RangeGauge(position: m.gaugePosition, compact: true),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _chartView(List<Measurement> items) {
    final p = context.palette;
    final chrono = items.reversed.toList();
    final shown = chrono.length > 14 ? chrono.sublist(chrono.length - 14) : chrono;
    final bp = widget.type == MeasurementType.bloodPressure;
    final range = HealthRanges.primaryRange(widget.type, _kind ?? GlucoseKind.gen);
    final maxV = [...shown.map((m) => m.value), range.max].reduce((a, b) => a > b ? a : b);
    final step = widget.type == MeasurementType.uricAcid ? 2.0 : 25.0;
    final yMax = ((maxV * 1.2) / step).ceil() * step;
    final s = statsOf(shown);
    return [
      SimpleLineChart(
        xLabels: [for (final m in shown) '${m.measuredAt.day}/${m.measuredAt.month}'],
        yMin: 0,
        yMax: yMax.toDouble(),
        bandMin: range.min,
        bandMax: range.max,
        height: 240,
        series: [
          ChartSeries(values: shown.map((m) => m.value).toList(), color: widget.type.color(p)),
          if (bp) ChartSeries(values: shown.map((m) => m.value2).toList(), color: p.info),
        ],
      ),
      if (bp) ...[
        const SizedBox(height: 6),
        Text('Ungu: sistolik · Biru: diastolik', style: AppText.caption.c(p.textTertiary)),
      ],
      const SizedBox(height: 16),
      Row(
        children: [
          for (final (label, v) in [('Rata-rata', s.avg), ('Terendah', s.min), ('Tertinggi', s.max)]) ...[
            if (label != 'Rata-rata') const SizedBox(width: 10),
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), border: Border.all(color: p.borderDefault)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label, style: AppText.caption.c(p.textSecondary)),
                    Text('${fmtNum(v)} ${widget.type.unit}', style: AppText.title.c(p.textPrimary), maxLines: 1),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
      const SizedBox(height: 12),
      Text('${shown.length} pengukuran ditampilkan', style: AppText.caption.c(p.textTertiary)),
    ];
  }
}
