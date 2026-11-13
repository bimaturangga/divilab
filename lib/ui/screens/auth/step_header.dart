import 'package:flutter/material.dart';

import '../../../core/theme/app_palette.dart';
import '../../../core/theme/app_text.dart';

/// Header langkah registrasi: progress bar + tombol kembali + judul.
class StepHeader extends StatelessWidget {
  const StepHeader({super.key, required this.step, required this.title, required this.subtitle, this.total = 3});

  final int step;
  final int total;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: (step - 1) / total, end: step / total),
              duration: const Duration(milliseconds: 400),
              builder: (_, v, __) =>
                  LinearProgressIndicator(value: v, minHeight: 4, backgroundColor: p.bgMuted, color: p.primary),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(left: 4, top: 4),
          child: IconButton(
            onPressed: () => Navigator.of(context).maybePop(),
            icon: Icon(Icons.arrow_back_ios_new_rounded, size: 20, color: p.textPrimary),
            tooltip: 'Kembali',
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: AppText.h1.c(p.textPrimary)),
              const SizedBox(height: 4),
              Text('Langkah $step dari $total · $subtitle', style: AppText.body.c(p.textSecondary)),
            ],
          ),
        ),
      ],
    );
  }
}
