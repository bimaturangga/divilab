import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_palette.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/utils/date_fmt.dart';
import '../../../core/utils/validators.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../state/app_state.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_sheet.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/brand.dart';
import '../../widgets/common.dart';
import 'step_header.dart';
import 'sync_screen.dart';

/// Registrasi langkah 3 (data personal). Juga dipakai untuk "Ubah Profil"
/// bila [draft] null.
class PersonalDataScreen extends StatefulWidget {
  const PersonalDataScreen({super.key, this.draft});
  final RegistrationDraft? draft;

  bool get editing => draft == null;

  @override
  State<PersonalDataScreen> createState() => _PersonalDataScreenState();
}

class _PersonalDataScreenState extends State<PersonalDataScreen> {
  final _name = TextEditingController();
  final _height = TextEditingController();
  final _weight = TextEditingController();
  final _code = TextEditingController();
  final _birthText = TextEditingController();
  String _gender = 'Perempuan';
  DateTime? _birth;
  final Map<String, String?> _errors = {};
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    if (widget.editing) {
      final u = context.read<AppState>().user!;
      _name.text = u.name;
      _gender = u.gender;
      _birth = u.birthDate;
      if (_birth != null) _birthText.text = DateFmt.dateLong(_birth!);
      _height.text = u.height == null ? '' : u.height!.toStringAsFixed(0);
      _weight.text = u.weight == null ? '' : u.weight!.toStringAsFixed(0);
      _code.text = u.productionCode ?? '';
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _height.dispose();
    _weight.dispose();
    _code.dispose();
    _birthText.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _birth ?? DateTime(now.year - 30),
      firstDate: DateTime(1920),
      lastDate: now,
      helpText: 'Pilih tanggal lahir',
    );
    if (picked != null) {
      setState(() {
        _birth = picked;
        _birthText.text = DateFmt.dateLong(picked);
      });
    }
  }

  /// Simulasi scan barcode kode produksi di kemasan perangkat.
  Future<void> _scanCode() async {
    final result = await showAppDialog<String>(
      context,
      builder: (ctx) {
        final p = ctx.palette;
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 180,
                height: 120,
                decoration: BoxDecoration(
                  color: p.bgSubtle,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: p.primary, width: 2),
                ),
                child: Icon(Icons.qr_code_scanner_rounded, size: 56, color: p.primary),
              ),
              const SizedBox(height: 16),
              Text('Pindai Kode Produksi', style: AppText.h3.c(p.textPrimary)),
              const SizedBox(height: 6),
              Text(
                'Arahkan kamera ke barcode pada kemasan DiViLab. (Simulasi untuk technical test)',
                style: AppText.bodySm.c(p.textSecondary),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              AppButton(
                label: 'Simulasikan Scan',
                onPressed: () {
                  final n = Random().nextInt(899999) + 100000;
                  Navigator.pop(ctx, 'DVIBGCU25$n');
                },
              ),
            ],
          ),
        );
      },
    );
    if (result != null) setState(() => _code.text = result);
  }

  bool _validate() {
    _errors
      ..clear()
      ..['name'] = Validators.required(_name.text, 'Nama lengkap')
      ..['birth'] = _birth == null ? 'Tanggal lahir wajib diisi' : null
      ..['height'] = Validators.number(_height.text, 'Tinggi', min: 50, max: 250)
      ..['weight'] = Validators.number(_weight.text, 'Berat', min: 10, max: 300);
    setState(() {});
    return _errors.values.every((e) => e == null);
  }

  Future<void> _save() async {
    FocusScope.of(context).unfocus();
    if (!_validate()) return;
    setState(() => _saving = true);
    final app = context.read<AppState>();
    final height = double.parse(_height.text.replaceAll(',', '.'));
    final weight = double.parse(_weight.text.replaceAll(',', '.'));
    try {
      if (widget.editing) {
        await app.updateUser(app.user!.copyWith(
          name: _name.text.trim(),
          gender: _gender,
          birthDate: _birth,
          height: height,
          weight: weight,
          productionCode: _code.text.trim(),
        ));
        if (!mounted) return;
        showSnack(context, 'Profil berhasil diperbarui');
        Navigator.pop(context);
      } else {
        final user = await app.auth.register(
          draft: widget.draft!,
          name: _name.text,
          gender: _gender,
          birthDate: _birth!,
          height: height,
          weight: weight,
          productionCode: _code.text,
        );
        await app.startSession(user);
        if (!mounted) return;
        goRoot(context, const SyncScreen());
      }
    } on AuthException catch (e) {
      if (mounted) showSnack(context, e.message);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final digits = [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))];
    final form = Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppTextField(label: 'Nama Lengkap', hint: 'Masukkan nama lengkap', controller: _name, errorText: _errors['name']),
          const SizedBox(height: 14),
          Text('Jenis Kelamin', style: AppText.label.c(p.textPrimary)),
          const SizedBox(height: 8),
          Row(
            children: [
              for (final g in const ['Laki-laki', 'Perempuan']) ...[
                if (g == 'Perempuan') const SizedBox(width: 12),
                Expanded(child: _genderOption(g)),
              ],
            ],
          ),
          const SizedBox(height: 14),
          AppTextField(
            label: 'Tanggal Lahir',
            hint: 'Pilih tanggal lahir',
            controller: _birthText,
            readOnly: true,
            onTap: _pickDate,
            suffixIcon: Icons.calendar_today_outlined,
            errorText: _errors['birth'],
          ),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: AppTextField(
                  label: 'Tinggi (cm)',
                  hint: '165',
                  controller: _height,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: digits,
                  errorText: _errors['height'],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: AppTextField(
                  label: 'Berat (kg)',
                  hint: '58',
                  controller: _weight,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: digits,
                  errorText: _errors['weight'],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          AppTextField(
            label: 'Kode Produksi (opsional)',
            hint: 'Scan atau ketik kode perangkat',
            controller: _code,
            suffixIcon: Icons.photo_camera_outlined,
            onSuffixTap: _scanCode,
          ),
        ],
      ),
    );
    return Scaffold(
      appBar: widget.editing ? const AppTopBar(title: 'Ubah Profil') : null,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (!widget.editing)
                      const StepHeader(step: 3, title: 'Data Personal', subtitle: 'Untuk hasil analisis yang akurat'),
                    form,
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
              child: AppButton(
                label: widget.editing ? 'Simpan Perubahan' : 'Simpan & Lanjut',
                loading: _saving,
                onPressed: _save,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _genderOption(String g) {
    final p = context.palette;
    final on = _gender == g;
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () => setState(() => _gender = g),
      child: Container(
        height: 48,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: on ? p.primary50 : p.bgSurface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: on ? p.primary : p.borderDefault, width: on ? 1.5 : 1),
        ),
        child: Row(
          children: [
            Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: on ? p.primary : p.borderStrong, width: on ? 5 : 1.5),
              ),
            ),
            const SizedBox(width: 10),
            Text(g, style: AppText.body.c(p.textPrimary)),
          ],
        ),
      ),
    );
  }
}
