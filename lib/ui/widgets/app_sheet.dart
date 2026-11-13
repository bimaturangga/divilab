import 'package:flutter/material.dart';

import '../../core/theme/app_palette.dart';
import '../../core/theme/app_text.dart';

/// Bottom sheet standar dengan handle di atas.
Future<T?> showAppSheet<T>(BuildContext context, {required WidgetBuilder builder, bool scrollControlled = true}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: scrollControlled,
    useSafeArea: true,
    barrierColor: context.palette.scrim,
    builder: (ctx) => Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 10),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(color: ctx.palette.borderStrong, borderRadius: BorderRadius.circular(2)),
          ),
          Flexible(child: builder(ctx)),
        ],
      ),
    ),
  );
}

/// Judul sheet + tombol tutup.
class SheetHeader extends StatelessWidget {
  const SheetHeader({super.key, required this.title, this.center = false});
  final String title;
  final bool center;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 4, 4),
      child: Row(
        children: [
          if (center) const SizedBox(width: 44),
          Expanded(
            child: Text(
              title,
              style: AppText.h3.c(p.textPrimary),
              textAlign: center ? TextAlign.center : TextAlign.start,
            ),
          ),
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: Icon(Icons.close_rounded, color: p.textPrimary),
            tooltip: 'Tutup',
          ),
        ],
      ),
    );
  }
}

/// Dialog standar (radius 24, latar canvas).
Future<T?> showAppDialog<T>(BuildContext context, {required WidgetBuilder builder, bool dismissible = true}) {
  return showDialog<T>(
    context: context,
    barrierDismissible: dismissible,
    barrierColor: context.palette.scrim,
    builder: (ctx) => Dialog(
      backgroundColor: ctx.palette.bgCanvas,
      surfaceTintColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: builder(ctx),
    ),
  );
}

void showSnack(BuildContext context, String message) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message)));
}
