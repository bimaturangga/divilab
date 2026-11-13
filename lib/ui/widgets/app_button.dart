import 'package:flutter/material.dart';

import '../../core/theme/app_palette.dart';
import '../../core/theme/app_text.dart';

enum AppButtonVariant { primary, secondary, outline, danger, success }

/// Tombol sesuai komponen "Button" di Figma (tinggi 48, radius penuh).
class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.label,
    this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.icon,
    this.loading = false,
    this.expand = true,
    this.height = 48,
  });

  final String label;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final IconData? icon;
  final bool loading;
  final bool expand;
  final double height;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final disabled = onPressed == null || loading;
    Color bg;
    Color fg;
    BorderSide side = BorderSide.none;
    switch (variant) {
      case AppButtonVariant.primary:
        bg = p.primary;
        fg = p.textOnPrimary;
      case AppButtonVariant.secondary:
        bg = p.bgMuted;
        fg = p.textPrimary;
      case AppButtonVariant.outline:
        bg = Colors.transparent;
        fg = p.primary;
        side = BorderSide(color: p.primary, width: 1.2);
      case AppButtonVariant.danger:
        bg = p.danger;
        fg = p.textOnPrimary;
      case AppButtonVariant.success:
        bg = p.success;
        fg = p.textOnPrimary;
    }
    if (disabled && !loading) {
      bg = variant == AppButtonVariant.outline ? Colors.transparent : p.bgMuted;
      fg = p.textTertiary;
      if (variant == AppButtonVariant.outline) side = BorderSide(color: p.borderStrong);
    }
    final shape = StadiumBorder(side: side);
    return SizedBox(
      height: height,
      width: expand ? double.infinity : null,
      child: Material(
        color: bg,
        shape: shape,
        child: InkWell(
          customBorder: shape,
          onTap: disabled ? null : onPressed,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (loading)
                  SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2.2, color: fg))
                else ...[
                  if (icon != null) ...[Icon(icon, size: 18, color: fg), const SizedBox(width: 8)],
                  Flexible(
                    child: Text(label, style: AppText.button.c(fg), overflow: TextOverflow.ellipsis),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Tombol ikon bulat kecil (mis. di top bar).
class CircleIconButton extends StatelessWidget {
  const CircleIconButton({
    super.key,
    required this.icon,
    this.onTap,
    this.size = 36,
    this.background,
    this.color,
    this.badge = false,
    this.tooltip,
  });

  final IconData icon;
  final VoidCallback? onTap;
  final double size;
  final Color? background;
  final Color? color;
  final bool badge;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final btn = Material(
      color: background ?? p.bgMuted,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: size,
          height: size,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Icon(icon, size: size * 0.52, color: color ?? p.textPrimary),
              if (badge)
                Positioned(
                  top: size * 0.2,
                  right: size * 0.2,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(color: p.danger, shape: BoxShape.circle),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
    return tooltip == null ? btn : Tooltip(message: tooltip!, child: btn);
  }
}
