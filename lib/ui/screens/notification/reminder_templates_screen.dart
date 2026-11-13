import 'package:flutter/material.dart';

import '../../../core/health.dart';
import '../../../core/theme/app_palette.dart';
import '../../../core/theme/app_text.dart';
import '../../widgets/brand.dart';
import '../../widgets/common.dart';
import 'reminder_form_screen.dart';

class ReminderTemplate {
  const ReminderTemplate({required this.title, required this.description, required this.image, required this.types});
  final String title;
  final String description;
  final String image;
  final List<MeasurementType> types;

  static const strip = ReminderTemplate(
    title: 'Gula darah, kolesterol, asam urat',
    description: 'Sudah waktunya melakukan pengukuran rutin untuk menjaga kualitas hidup yang lebih baik.',
    image: 'assets/images/reminder_strip.png',
    types: [MeasurementType.glucose, MeasurementType.cholesterol],
  );
  static const tensi = ReminderTemplate(
    title: 'Tekanan Darah',
    description: 'Pantau tekanan darah secara rutin untuk menjaga kesehatan jantung dan pembuluh darah.',
    image: 'assets/images/reminder_tensi.png',
    types: [MeasurementType.bloodPressure],
  );
}

class ReminderTemplatesScreen extends StatelessWidget {
  const ReminderTemplatesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Scaffold(
      appBar: const AppTopBar(title: 'Tambah Pengingat'),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          for (final t in const [ReminderTemplate.strip, ReminderTemplate.tensi]) ...[
            _TemplateCard(template: t),
            const SizedBox(height: 14),
          ],
          Material(
            color: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: p.borderDefault),
            ),
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () => push(context, const ReminderFormScreen()),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(color: p.primary50, shape: BoxShape.circle),
                      child: Icon(Icons.add_rounded, color: p.primary, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Buat pengingat kustom', style: AppText.title.c(p.textPrimary)),
                          Text('Atur jenis, hari, dan jam sendiri', style: AppText.caption.c(p.textSecondary)),
                        ],
                      ),
                    ),
                    Icon(Icons.chevron_right_rounded, color: p.textSecondary),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TemplateCard extends StatelessWidget {
  const _TemplateCard({required this.template});
  final ReminderTemplate template;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    void open() => push(context, ReminderFormScreen(template: template));
    return Material(
      color: p.bgSubtle,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: open,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                AspectRatio(aspectRatio: 328 / 148, child: Image.asset(template.image, fit: BoxFit.cover, width: double.infinity)),
                Positioned(
                  right: 12,
                  bottom: 12,
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(12, 6, 8, 6),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(99)),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('Atur Sekarang', style: AppText.labelSm.c(const Color(0xFF16191F))),
                        const Icon(Icons.chevron_right_rounded, size: 16, color: Color(0xFF16191F)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(template.title, style: AppText.title.c(p.textPrimary)),
                  const SizedBox(height: 4),
                  Text(template.description, style: AppText.caption.c(p.textSecondary)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
