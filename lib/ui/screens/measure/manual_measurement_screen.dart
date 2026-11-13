import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../core/health.dart';
import '../../../core/theme/app_palette.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/utils/date_fmt.dart';
import '../../../core/utils/validators.dart';
import '../../../data/models/measurement.dart';
import '../../../state/app_state.dart';
import '../../../state/health_store.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/common.dart';
import '../home/switch_account_sheet.dart';
import 'measurement_saved_screen.dart';

/// Pengukuran Manual — input hasil sendiri, disimpan ke SQLite.
class ManualMeasurementScreen extends StatefulWidget {
  const ManualMeasurementScreen({super.key});

  @override
  State<ManualMeasurementScreen> createState() => _ManualMeasurementScreenState();
}

class _ManualMeasurementScreenState extends State<ManualMeasurementScreen> {
  MeasurementType _type = MeasurementType.glucose;
  GlucoseKind _kind = GlucoseKind.gen;
  final _value = TextEditingController();
  final _dia = TextEditingController();
  final _pulse = TextEditingController();
  final _note = TextEditingController();
  final _dateText = TextEditingController();
  final _timeText = TextEditingController();
  DateTime _at = DateTime.now();
  final Map<String, String?> _errors = {};
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _syncDateText();
  }

  void _syncDateText() {
    _dateText.text = DateFmt.dateShort(_at);
    _timeText.text = DateFmt.time(_at);
  }

  @override
  void dispose() {
    for (final c in [_value, _dia, _pulse, _note, _dateText, _timeText]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _pickDate() async {
    final d = await showDatePicker(
      context: context,
      initialDate: _at,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
    );
    if (d == null) return;
    setState(() {
      _at = DateTime(d.year, d.month, d.day, _at.hour, _at.minute);
      _syncDateText();
    });
  }

  Future<void> _pickTime() async {
    final t = await showTimePicker(context: context, initialTime: TimeOfDay.fromDateTime(_at));
    if (t == null) return;
    setState(() {
      _at = DateTime(_at.year, _at.month, _at.day, t.hour, t.minute);
      _syncDateText();
    });
  }

  (double, double) get _limits => switch (_type) {
        MeasurementType.glucose => (10.0, 600.0),
        MeasurementType.cholesterol => (50.0, 500.0),
        MeasurementType.uricAcid => (1.0, 20.0),
        MeasurementType.bloodPressure => (50.0, 250.0),
      };

  double _parse(String s) => double.parse(s.trim().replaceAll(',', '.'));

  Future<void> _save() async {
    FocusScope.of(context).unfocus();
    final (min, max) = _limits;
    _errors
      ..clear()
      ..['value'] = Validators.number(_value.text, _type == MeasurementType.bloodPressure ? 'Sistolik' : 'Hasil', min: min, max: max);
    if (_type == MeasurementType.bloodPressure) {
      _errors['dia'] = Validators.number(_dia.text, 'Diastolik', min: 30, max: 160);
      _errors['pulse'] = _pulse.text.trim().isEmpty ? null : Validators.number(_pulse.text, 'Denyut', min: 30, max: 220);
    }
    if (_at.isAfter(DateTime.now().add(const Duration(minutes: 1)))) _errors['date'] = 'Waktu tidak boleh di masa depan';
    setState(() {});
    if (_errors.values.any((e) => e != null)) return;

    setState(() => _saving = true);
    final app = context.read<AppState>();
    final store = context.read<HealthStore>();
    final profile = app.activeProfile!;
    final saved = await store.save(
      Measurement(
        profileId: profile.id!,
        type: _type,
        glucoseKind: _type == MeasurementType.glucose ? _kind : null,
        value: _parse(_value.text),
        value2: _type == MeasurementType.bloodPressure ? _parse(_dia.text) : null,
        pulse: _type == MeasurementType.bloodPressure && _pulse.text.trim().isNotEmpty ? _parse(_pulse.text).round() : null,
        source: 'manual',
        note: _note.text.trim().isEmpty ? null : _note.text.trim(),
        measuredAt: _at,
      ),
      profileName: profile.name,
    );
    if (!mounted) return;
    Navigator.of(context).pushReplacement(MaterialPageRoute<void>(builder: (_) => MeasurementSavedScreen(measurement: saved)));
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final profile = context.watch<AppState>().activeProfile;
    final digits = [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))];
    final bp = _type == MeasurementType.bloodPressure;
    return Scaffold(
      appBar: const AppTopBar(title: 'Pengukuran Manual'),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              children: [
                Text('Pasien', style: AppText.label.c(p.textPrimary)),
                const SizedBox(height: 8),
                Material(
                  color: p.bgSurface,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: p.borderDefault),
                  ),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () => showSwitchAccountSheet(context, title: 'Pilih Pasien'),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      child: Row(
                        children: [
                          Expanded(child: Text(profile?.name ?? '-', style: AppText.body.c(p.textPrimary))),
                          Icon(Icons.keyboard_arrow_down_rounded, color: p.textTertiary),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Text('Jenis pengukuran', style: AppText.label.c(p.textPrimary)),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final t in MeasurementType.values)
                      ChoicePill(
                        label: t.label,
                        selected: _type == t,
                        onTap: () => setState(() {
                          _type = t;
                          _errors.clear();
                        }),
                      ),
                  ],
                ),
                if (_type == MeasurementType.glucose) ...[
                  const SizedBox(height: 18),
                  Text('Tipe gula darah', style: AppText.label.c(p.textPrimary)),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final k in GlucoseKind.values)
                        ChoicePill(label: k.label, selected: _kind == k, onTap: () => setState(() => _kind = k)),
                    ],
                  ),
                ],
                const SizedBox(height: 18),
                if (bp)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: AppTextField(
                          label: 'Sistolik',
                          hint: '120',
                          controller: _value,
                          keyboardType: TextInputType.number,
                          inputFormatters: digits,
                          errorText: _errors['value'],
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: AppTextField(
                          label: 'Diastolik',
                          hint: '80',
                          controller: _dia,
                          keyboardType: TextInputType.number,
                          inputFormatters: digits,
                          errorText: _errors['dia'],
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: AppTextField(
                          label: 'Denyut',
                          hint: '75',
                          controller: _pulse,
                          keyboardType: TextInputType.number,
                          inputFormatters: digits,
                          errorText: _errors['pulse'],
                        ),
                      ),
                    ],
                  )
                else
                  AppTextField(
                    label: 'Hasil (${_type.unit})',
                    hint: _type == MeasurementType.uricAcid ? '5,2' : '110',
                    controller: _value,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: digits,
                    suffixText: _type.unit,
                    errorText: _errors['value'],
                  ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(
                      child: AppTextField(
                        label: 'Tanggal',
                        controller: _dateText,
                        readOnly: true,
                        onTap: _pickDate,
                        suffixIcon: Icons.calendar_today_outlined,
                        errorText: _errors['date'],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: AppTextField(
                        label: 'Jam',
                        controller: _timeText,
                        readOnly: true,
                        onTap: _pickTime,
                        suffixIcon: Icons.schedule_rounded,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                AppTextField(label: 'Catatan (opsional)', hint: 'Contoh: setelah olahraga pagi', controller: _note, maxLines: 2),
              ],
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
              child: AppButton(label: 'Simpan Hasil', loading: _saving, onPressed: _save),
            ),
          ),
        ],
      ),
    );
  }
}
