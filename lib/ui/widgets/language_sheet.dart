import 'package:flutter/material.dart';

import '../../core/theme/app_palette.dart';
import '../../core/theme/app_text.dart';
import 'app_sheet.dart';
import 'brand.dart';

/// Chip "Bahasa" di onboarding/login.
class LanguageChip extends StatelessWidget {
  const LanguageChip({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Material(
      color: p.bgMuted,
      shape: const StadiumBorder(),
      child: InkWell(
        customBorder: const StadiumBorder(),
        onTap: () => showLanguageSheet(context),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const IndonesiaFlag(),
              const SizedBox(width: 8),
              Text('Bahasa', style: AppText.label.c(p.textPrimary)),
              const SizedBox(width: 2),
              Icon(Icons.keyboard_arrow_down_rounded, size: 18, color: p.textSecondary),
            ],
          ),
        ),
      ),
    );
  }
}

Future<void> showLanguageSheet(BuildContext context) {
  return showAppSheet<void>(
    context,
    builder: (ctx) {
      final p = ctx.palette;
      return SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(0, 0, 0, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SheetHeader(title: 'Pilih Bahasa'),
              ListTile(
                leading: const IndonesiaFlag(size: 24),
                title: Text('Bahasa Indonesia', style: AppText.title.c(p.textPrimary)),
                trailing: Icon(Icons.check_circle_rounded, color: p.primary),
                onTap: () => Navigator.pop(ctx),
              ),
              ListTile(
                enabled: false,
                leading: Icon(Icons.language_rounded, color: p.textTertiary),
                title: Text('English', style: AppText.title.c(p.textTertiary)),
                subtitle: Text('Segera hadir', style: AppText.caption.c(p.textTertiary)),
              ),
            ],
          ),
        ),
      );
    },
  );
}
