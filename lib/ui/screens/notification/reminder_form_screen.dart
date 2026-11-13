import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/health.dart';
import '../../../core/theme/app_palette.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/utils/date_fmt.dart';
import '../../../data/models/reminder.dart';
import '../../../state/health_store.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_sheet.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/common.dart';
import 'reminder_templates_screen.dart';

/// Atur Pengingat (dari template, kustom, atau edit pengingat yang ada).
class ReminderFormScreen extends StatefulWidget {
  const ReminderFormScreen({super.key, this.template, this.existing});
  final ReminderTemplate? template;
  final Reminder? existing;

  @override
  State<ReminderFormScreen> createState() => _ReminderFormScreenState();
}

class _ReminderFormScreenState extends State<ReminderFormScreen> {
  final _title = TextEditingController();
  late Set<MeasurementType> _types;
  late Set<int> _days;
  late TimeOfDay _time;
  String? _error;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    final t = widget.template;
    _title.text = e?.title ?? t?.title ?? '';
    _types = {...(e?.types ?? t?.types ?? [MeasurementType.glucose])};
    _days = {...(e?.days ?? [1, 3, 5])};
    _time = e == null ? const TimeOfDay(hour: 7, minute: 0) : TimeOfDay(hour: e.hour, minute: e.minute);
  }

  @override
  void dispose() {
    _title.dispose();
    super.dispose();
  }

  bool get _valid => _types.isNotEmpty && _days.isNotEmpty;

  Future<void> _pickTime() async {
    final t = await showTimePicker(context: context, initialTime: _time, helpText: 'Pilih jam pengingat');
    if (t != null) setState(() => _time = t);
  }

  Future<void> _save() async {
    final store = context.read<HealthStore>();
    final title = _title.text.trim().isEmpty ? _types.map((e) => e.label).join(', ') : _title.text.trim();
    if (!_valid) {
      setState(() => _error = 'Pilih minimal satu jenis pengukuran dan satu hari');
      return;
    }
    await store.saveReminder(Reminder(
      id: widget.existing?.id,
      ownerId: store.ownerId!,
      title: title,
      types: _types.toList(),
      days: _days.toList()..sort(),
      hour: _time.hour,
      minute: _time.minute,
      enabled: widget.existing?.enabled ?? true,
    ));
    if (!mounted) return;
    showSnack(context, 'Pengingat disimpan');
    // Dari daftar template/kustom: tutup form & daftar template sekaligus.
    final nav = Navigator.of(context)..pop();
    if (widget.existing == null && nav.canPop()) nav.pop();
  }

  Future<void> _delete() async {
    final store = context.read<HealthStore>();
    await store.deleteReminder(widget.existing!);
    if (!mounted) return;
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final template = widget.template;
    final body = Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (template != null) ...[
            Text(template.title, style: AppText.h2.c(p.textPrimary)),
            const SizedBox(height: 6),
            Text(template.description, style: AppText.bodySm.c(p.textSecondary)),
          ] else
            AppTextField(label: 'Nama pengingat', hint: 'Contoh: Cek gula darah pagi', controller: _title),
          const SizedBox(height: 20),
          Text('Pengukuran', style: AppText.label.c(p.textPrimary)),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final t in MeasurementType.values)
                ChoicePill(
                  label: t.label,
                  selected: _types.contains(t),
                  showCheck: true,
                  onTap: () => setState(() => _types.contains(t) ? _types.remove(t) : _types.add(t)),
                ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(child: Text('Hari', style: AppText.label.c(p.textPrimary))),
              GestureDetector(
                onTap: () => setState(() => _days.length == 7 ? _days.clear() : _days.addAll([1, 2, 3, 4, 5, 6, 7])),
                child: Text(_days.length == 7 ? 'Hapus semua' : 'Setiap hari', style: AppText.label.c(p.primary)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              for (var d = 1; d <= 7; d++)
                Tooltip(
                  message: DateFmt.days[d - 1],
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: () => setState(() => _days.contains(d) ? _days.remove(d) : _days.add(d)),
                    child: Container(
                      width: 38,
                      height: 38,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(color: _days.contains(d) ? p.primary : p.bgMuted, shape: BoxShape.circle),
                      child: Text(
                        DateFmt.dayInitials[d - 1],
                        style: AppText.title.c(_days.contains(d) ? p.textOnPrimary : p.textSecondary),
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 20),
          Text('Jam', style: AppText.label.c(p.textPrimary)),
          const SizedBox(height: 10),
          Material(
            color: p.bgSubtle,
            borderRadius: BorderRadius.circular(14),
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: _pickTime,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    Icon(Icons.schedule_rounded, color: p.primary),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        '${_time.hour.toString().padLeft(2, '0')}:${_time.minute.toString().padLeft(2, '0')}',
                        style: AppText.h1.c(p.textPrimary),
                      ),
                    ),
                    Icon(Icons.chevron_right_rounded, color: p.textSecondary),
                  ],
                ),
              ),
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            NoteBox(text: _error!, tone: NoteTone.danger, icon: Icons.error_outline_rounded),
          ],
        ],
      ),
    );

    return Scaffold(
      appBar: template == null
          ? AppTopBar(
              title: widget.existing == null ? 'Pengingat Baru' : 'Ubah Pengingat',
              actions: [
                if (widget.existing != null)
                  CircleIconButton(icon: Icons.delete_outline_rounded, color: p.danger, onTap: _delete, tooltip: 'Hapus'),
              ],
            )
          : null,
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: template == null
                  ? body
                  : Stack(
                      children: [
                        Image.asset('assets/images/reminder_header.png', height: 220, width: double.infinity, fit: BoxFit.cover),
                        Positioned(
                          top: MediaQuery.of(context).padding.top + 8,
                          left: 12,
                          child: CircleIconButton(
                            icon: Icons.arrow_back_ios_new_rounded,
                            size: 40,
                            background: Colors.white.withAlpha(230),
                            color: const Color(0xFF16191F),
                            onTap: () => Navigator.pop(context),
                          ),
                        ),
                        Container(
                          margin: const EdgeInsets.only(top: 196),
                          decoration: BoxDecoration(
                            color: p.bgCanvas,
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                          ),
                          child: body,
                        ),
                      ],
                    ),
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
              child: AppButton(label: 'Simpan Pengingat', onPressed: _valid ? _save : null),
            ),
          ),
        ],
      ),
    );
  }
}
