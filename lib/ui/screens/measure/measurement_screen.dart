import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/health.dart';
import '../../../core/theme/app_palette.dart';
import '../../../core/theme/app_text.dart';
import '../../../data/models/catalog.dart';
import '../../../data/models/measurement.dart';
import '../../../data/services/device_simulator.dart';
import '../../../state/app_state.dart';
import '../../../state/health_store.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_sheet.dart';
import '../../widgets/brand.dart';
import '../../widgets/common.dart';
import '../home/measurement_detail_screen.dart';
import '../home/switch_account_sheet.dart';
import '../product/product_detail_screen.dart';
import 'device_guide_sheet.dart';
import 'manual_measurement_screen.dart';

enum _Phase { idle, measuring, done }

/// Layar Pengukuran (perangkat terhubung).
class MeasurementScreen extends StatefulWidget {
  const MeasurementScreen({super.key, required this.device});
  final DeviceInfo device;

  @override
  State<MeasurementScreen> createState() => _MeasurementScreenState();
}

class _MeasurementScreenState extends State<MeasurementScreen> {
  late int _tab = widget.device.supportsBloodPressure ? 1 : 0; // 0 = tensi, 1 = darah
  MeasurementType _stripType = MeasurementType.glucose;
  GlucoseKind _kind = GlucoseKind.gen;
  _Phase _phase = _Phase.idle;
  DeviceReading? _live;
  StreamSubscription<DeviceReading>? _sub;
  final Map<MeasurementType, Measurement> _results = {};

  bool get _bpTab => widget.device.supportsBloodPressure && _tab == 0;
  MeasurementType get _currentType => _bpTab ? MeasurementType.bloodPressure : _stripType;

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  void _switchTab(int i) {
    if (_phase == _Phase.measuring) return;
    setState(() {
      _tab = i;
      _phase = _Phase.idle;
      _live = null;
    });
  }

  Future<void> _start() async {
    final store = context.read<HealthStore>();
    final type = _currentType;
    if (type.usesStrip && (store.strips[type] ?? 0) <= 0) {
      _showNoStrip(type);
      return;
    }
    setState(() {
      _phase = _Phase.measuring;
      _live = null;
    });
    _sub?.cancel();
    _sub = context.read<DeviceSimulator>().measure(type).listen((r) async {
      if (!mounted) return;
      setState(() => _live = r);
      if (r.done) await _finish(type, r);
    });
  }

  Future<void> _finish(MeasurementType type, DeviceReading r) async {
    final app = context.read<AppState>();
    final store = context.read<HealthStore>();
    final profile = app.activeProfile!;
    final saved = await store.save(
      Measurement(
        profileId: profile.id!,
        type: type,
        glucoseKind: type == MeasurementType.glucose ? _kind : null,
        value: r.value,
        value2: r.value2,
        pulse: r.pulse,
        deviceName: widget.device.name,
        measuredAt: DateTime.now(),
      ),
      profileName: profile.name,
      consumeStrip: true,
    );
    if (!mounted) return;
    setState(() {
      _results[type] = saved;
      _phase = _Phase.done;
    });
    if (type.usesStrip) {
      await showAppDialog<void>(context, dismissible: false, builder: (_) => const _StripRemovedDialog());
      if (!mounted) return;
      await showAppDialog<void>(context, builder: (_) => const _DeviceReadyDialog());
    }
  }

  void _showNoStrip(MeasurementType t) {
    showAppDialog<void>(
      context,
      builder: (ctx) {
        final p = ctx.palette;
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.inventory_2_outlined, size: 48, color: p.warning),
              const SizedBox(height: 12),
              Text('Strip ${t.label} habis', style: AppText.h2.c(p.textPrimary)),
              const SizedBox(height: 6),
              Text(
                'Beli strip baru atau ubah kuantitas bila Anda masih memiliki stok.',
                style: AppText.body.c(p.textSecondary),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              AppButton(
                label: 'Beli Strip',
                onPressed: () {
                  Navigator.pop(ctx);
                  push(context, ProductDetailScreen(product: Product.all.first));
                },
              ),
              const SizedBox(height: 10),
              AppButton(
                label: 'Ubah Kuantitas',
                variant: AppButtonVariant.secondary,
                onPressed: () {
                  Navigator.pop(ctx);
                  _editStrips();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _editStrips() {
    final store = context.read<HealthStore>();
    final values = {for (final t in MeasurementType.stripTypes) t: store.strips[t] ?? 0};
    showAppSheet<void>(
      context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) {
          final p = ctx.palette;
          return SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SheetHeader(title: 'Edit Kuantitas Strip'),
                  for (final t in MeasurementType.stripTypes)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Row(
                        children: [
                          MetricIcon(type: t, size: 32),
                          const SizedBox(width: 12),
                          Expanded(child: Text(t.label, style: AppText.title.c(p.textPrimary))),
                          CircleIconButton(
                            icon: Icons.remove_rounded,
                            onTap: () => setSheet(() => values[t] = (values[t]! - 1).clamp(0, 999).toInt()),
                          ),
                          SizedBox(
                            width: 44,
                            child: Text('${values[t]}', style: AppText.h3.c(p.textPrimary), textAlign: TextAlign.center),
                          ),
                          CircleIconButton(
                            icon: Icons.add_rounded,
                            onTap: () => setSheet(() => values[t] = values[t]! + 1),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 16),
                  AppButton(
                    label: 'Simpan',
                    onPressed: () async {
                      for (final e in values.entries) {
                        await store.setStrip(e.key, e.value);
                      }
                      if (ctx.mounted) Navigator.pop(ctx);
                    },
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final app = context.watch<AppState>();
    final store = context.watch<HealthStore>();
    final measuring = _phase == _Phase.measuring;
    return Scaffold(
      appBar: AppTopBar(
        title: 'Pengukuran',
        actions: [
          Material(
            color: p.bgMuted,
            shape: const StadiumBorder(),
            child: InkWell(
              customBorder: const StadiumBorder(),
              onTap: () => push(context, const ManualMeasurementScreen()),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.add_rounded, size: 16, color: p.textPrimary),
                    const SizedBox(width: 4),
                    Text('Manual', style: AppText.label.c(p.textPrimary)),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          CircleIconButton(icon: Icons.menu_book_outlined, tooltip: 'Panduan', onTap: () => showDeviceGuide(context)),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
              children: [
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: measuring ? null : () => showSwitchAccountSheet(context, title: 'Pilih Pasien'),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text('Pasien', style: AppText.title.c(p.textPrimary)),
                                Icon(Icons.keyboard_arrow_down_rounded, size: 18, color: p.textPrimary),
                              ],
                            ),
                            Text(app.activeProfile?.name ?? '-', style: AppText.bodySm.c(p.textSecondary)),
                          ],
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(color: p.success, borderRadius: BorderRadius.circular(99)),
                      child: Text('Terhubung', style: AppText.label.c(Colors.white)),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (widget.device.supportsBloodPressure)
                  SegmentedTabs(labels: const ['Tekanan Darah', 'Pengukuran Darah'], index: _tab, onChanged: _switchTab),
                if (!_bpTab) ...[
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final t in MeasurementType.stripTypes)
                        ChoicePill(
                          label: t.label,
                          selected: _stripType == t,
                          outlined: true,
                          onTap: measuring
                              ? () {}
                              : () => setState(() {
                                    _stripType = t;
                                    _phase = _Phase.idle;
                                    _live = null;
                                  }),
                        ),
                    ],
                  ),
                  if (_stripType == MeasurementType.glucose) ...[
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: [
                        for (final k in GlucoseKind.values)
                          ChoicePill(
                            label: k.code,
                            selected: _kind == k,
                            onTap: measuring ? () {} : () => setState(() => _kind = k),
                          ),
                      ],
                    ),
                  ],
                ],
                const SizedBox(height: 12),
                _liveCard(context),
                const SizedBox(height: 20),
                Text('Hasil Akhir Pengukuran', style: AppText.h3.c(p.textPrimary)),
                const SizedBox(height: 10),
                if (_bpTab) _bpResults(context) else _stripResults(context),
                const SizedBox(height: 20),
                if (_bpTab)
                  const NoteBox(
                    text: 'Tips: duduk tenang 5 menit sebelum mengukur, posisikan manset sejajar jantung, '
                        'dan jangan berbicara selama pengukuran.',
                  )
                else ...[
                  SectionHeader(
                    title: 'Sisa Strip Anda',
                    trailing: TextButton.icon(
                      onPressed: _editStrips,
                      icon: Icon(Icons.edit_outlined, size: 14, color: p.textPrimary),
                      label: Text('Edit kuantitas', style: AppText.labelSm.c(p.textPrimary)),
                      style: TextButton.styleFrom(backgroundColor: p.bgMuted, shape: const StadiumBorder()),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      for (final t in MeasurementType.stripTypes) ...[
                        if (t != MeasurementType.glucose) const SizedBox(width: 10),
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(color: p.bgSubtle, borderRadius: BorderRadius.circular(14)),
                            child: Row(
                              children: [
                                Icon(Icons.science_outlined, size: 18, color: t.color(p)),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '${store.strips[t] ?? 0}',
                                        style: AppText.h3.c((store.strips[t] ?? 0) <= 2 ? p.danger : p.textPrimary),
                                      ),
                                      Text(t.label, style: AppText.caption.c(p.textSecondary), maxLines: 1),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ],
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
              child: _bpTab
                  ? AppButton(
                      label: _phase == _Phase.done ? 'Ukur Ulang' : 'Mulai Ukur',
                      loading: measuring,
                      onPressed: _start,
                    )
                  : AppButton(
                      label: 'Beli Strip',
                      icon: Icons.shopping_cart_outlined,
                      onPressed: () => push(context, ProductDetailScreen(product: Product.all.first)),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _liveCard(BuildContext context) {
    final p = context.palette;
    final type = _currentType;
    final r = _live;
    String status;
    String big;
    Color bigColor = type == MeasurementType.bloodPressure ? p.purple : p.primary;
    String? sub;
    switch (_phase) {
      case _Phase.idle:
        status = type.usesStrip ? 'Pasang strip lalu tekan Mulai' : 'Pasang manset lalu tekan Mulai';
        big = '–';
        bigColor = p.textTertiary;
      case _Phase.measuring:
        if (type == MeasurementType.bloodPressure) {
          status = 'Manset sedang mengembang…';
          big = fmtNum(r?.value ?? 0);
          sub = 'mmHg';
        } else {
          status = 'Pengukuran sedang berjalan';
          big = r?.countdown == null ? '…' : '${r!.countdown}';
          sub = 'detik';
        }
      case _Phase.done:
        final m = _results[type]!;
        status = 'Pengukuran selesai · ${m.status.label}';
        big = m.displayValue;
        sub = m.pulse == null ? type.unit : '${type.unit} · ${m.pulse} bpm';
    }
    final active = _phase == _Phase.measuring;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: p.bgSubtle, borderRadius: BorderRadius.circular(20)),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (final a in const [255, 160, 80])
                Container(
                  margin: const EdgeInsets.only(right: 3),
                  width: 5,
                  height: 5,
                  decoration: BoxDecoration(
                    color: (active ? bigColor : p.textTertiary).withAlpha(a),
                    shape: BoxShape.circle,
                  ),
                ),
              const SizedBox(width: 4),
              Flexible(child: Text(status, style: AppText.label.c(active ? bigColor : p.textTertiary))),
            ],
          ),
          const SizedBox(height: 8),
          Text(type.label, style: AppText.body.c(p.textSecondary)),
          Text(big, style: AppText.displayXl.c(bigColor)),
          if (sub != null) Text(sub, style: AppText.bodySm.c(p.textSecondary)),
          if (type.usesStrip) ...[
            const SizedBox(height: 12),
            AppButton(
              label: _phase == _Phase.done ? 'Ukur Lagi' : 'Mulai Ukur',
              height: 40,
              loading: active,
              onPressed: _start,
            ),
          ],
        ],
      ),
    );
  }

  Widget _resultCard(BuildContext context, String label, Color dot, String value, String unit, Measurement? m) {
    final p = context.palette;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: p.bgSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: m != null ? p.primary : p.borderDefault),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(width: 8, height: 8, decoration: BoxDecoration(color: dot, shape: BoxShape.circle)),
              const SizedBox(width: 4),
              Flexible(child: Text(label, style: AppText.caption.c(p.textSecondary), maxLines: 1, overflow: TextOverflow.ellipsis)),
            ],
          ),
          const SizedBox(height: 6),
          FittedBox(child: Text(value, style: AppText.h1.c(m == null ? p.textTertiary : p.textPrimary))),
          Text(unit, style: AppText.caption.c(p.textTertiary)),
          const SizedBox(height: 6),
          if (m != null) StatusBadge(status: m.status) else const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _stripResults(BuildContext context) {
    final p = context.palette;
    return Row(
      children: [
        for (final t in MeasurementType.stripTypes) ...[
          if (t != MeasurementType.glucose) const SizedBox(width: 10),
          Expanded(
            child: GestureDetector(
              onTap: _results[t] == null ? null : () => push(context, MeasurementDetailScreen(measurement: _results[t]!)),
              child: _resultCard(context, t.label, t.color(p), _results[t]?.displayValue ?? '--', t.unit, _results[t]),
            ),
          ),
        ],
      ],
    );
  }

  Widget _bpResults(BuildContext context) {
    final p = context.palette;
    final m = _results[MeasurementType.bloodPressure];
    return GestureDetector(
      onTap: m == null ? null : () => push(context, MeasurementDetailScreen(measurement: m)),
      child: Row(
        children: [
          Expanded(child: _resultCard(context, 'Sistolik', p.purple, m == null ? '--' : fmtNum(m.value), 'mmHg', m)),
          const SizedBox(width: 10),
          Expanded(child: _resultCard(context, 'Diastolik', p.purple, m == null ? '--' : fmtNum(m.value2 ?? 0), 'mmHg', m)),
          const SizedBox(width: 10),
          Expanded(child: _resultCard(context, 'Denyut', p.danger, m?.pulse?.toString() ?? '--', 'bpm', m)),
        ],
      ),
    );
  }
}

/// Dialog "Strip sudah dicabut" dengan hitung mundur 7 detik.
class _StripRemovedDialog extends StatefulWidget {
  const _StripRemovedDialog();

  @override
  State<_StripRemovedDialog> createState() => _StripRemovedDialogState();
}

class _StripRemovedDialogState extends State<_StripRemovedDialog> {
  static const _total = 7;
  int _left = _total;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_left <= 1) {
        t.cancel();
        if (mounted) Navigator.pop(context);
      } else {
        setState(() => _left--);
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text.rich(
            TextSpan(
              style: AppText.h2.c(p.textPrimary),
              children: [
                const TextSpan(text: 'Strip sudah '),
                TextSpan(text: 'dicabut', style: AppText.h2.c(p.warning)),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text('Alat sedang bersiap untuk pengukuran berikutnya.', style: AppText.body.c(p.textSecondary), textAlign: TextAlign.center),
          const SizedBox(height: 20),
          SizedBox(
            width: 168,
            height: 168,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox.expand(
                  child: CircularProgressIndicator(
                    value: _left / _total,
                    strokeWidth: 10,
                    backgroundColor: p.bgMuted,
                    color: p.primary,
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('$_left', style: AppText.displayXl.c(p.textPrimary)),
                    Text('Detik', style: AppText.label.c(p.textSecondary)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          const NoteBox(text: 'Mohon tunggu hingga hitungan selesai sebelum memasang strip baru.'),
        ],
      ),
    );
  }
}

/// Dialog "Alat siap dipakai" — menutup otomatis.
class _DeviceReadyDialog extends StatefulWidget {
  const _DeviceReadyDialog();

  @override
  State<_DeviceReadyDialog> createState() => _DeviceReadyDialogState();
}

class _DeviceReadyDialogState extends State<_DeviceReadyDialog> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer(const Duration(seconds: 2), () {
      if (mounted) Navigator.pop(context);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Alat siap dipakai', style: AppText.h2.c(p.textPrimary)),
          const SizedBox(height: 8),
          Text('Silakan pasang strip berikutnya.', style: AppText.body.c(p.textSecondary)),
          const SizedBox(height: 20),
          Container(
            width: 168,
            height: 168,
            decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: p.success50, width: 10)),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(color: p.success, shape: BoxShape.circle),
                  child: const Icon(Icons.check_rounded, color: Colors.white, size: 40),
                ),
                const SizedBox(height: 6),
                Text('Selesai', style: AppText.label.c(p.success)),
              ],
            ),
          ),
          const SizedBox(height: 20),
          const NoteBox(tone: NoteTone.success, icon: Icons.check_circle_outline_rounded, text: 'Layar ini akan menutup otomatis.'),
        ],
      ),
    );
  }
}
