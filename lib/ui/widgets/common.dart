import 'package:flutter/material.dart';

import '../../core/health.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_text.dart';
import '../../core/utils/validators.dart';

/// Badge status (Normal/Tinggi/Rendah) — komponen "Badge".
class StatusBadge extends StatelessWidget {
  const StatusBadge({super.key, this.status});

  /// null = "Belum ada data".
  final HealthStatus? status;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final s = status;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: s == null ? p.bgMuted : s.background(p),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(
        s == null ? 'Belum ada data' : s.label,
        style: AppText.labelSm.c(s == null ? p.textTertiary : s.color(p)),
      ),
    );
  }
}

/// Ikon 3D jenis pengukuran dalam lingkaran.
class MetricIcon extends StatelessWidget {
  const MetricIcon({super.key, required this.type, this.size = 32});
  final MeasurementType type;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(color: Color(0xFFF8F9FB), shape: BoxShape.circle),
      clipBehavior: Clip.antiAlias,
      child: Image.asset(type.asset, fit: BoxFit.cover),
    );
  }
}

/// Avatar inisial.
class InitialsAvatar extends StatelessWidget {
  const InitialsAvatar({super.key, required this.initials, required this.color, this.size = 40, this.textColor});
  final String initials;
  final Color color;
  final double size;
  final Color? textColor;

  @override
  Widget build(BuildContext context) {
    final style = size >= 56 ? AppText.h1 : (size >= 36 ? AppText.title : AppText.labelSm);
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      child: Text(initials, style: style.c(textColor ?? Colors.white)),
    );
  }
}

/// Segmented tab (komponen "Segmented Tab").
class SegmentedTabs extends StatelessWidget {
  const SegmentedTabs({super.key, required this.labels, required this.index, required this.onChanged, this.icons});
  final List<String> labels;
  final int index;
  final ValueChanged<int> onChanged;
  final List<IconData?>? icons;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Container(
      height: 44,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(color: p.bgMuted, borderRadius: BorderRadius.circular(12)),
      child: Row(
        children: [
          for (var i = 0; i < labels.length; i++)
            Expanded(
              child: GestureDetector(
                onTap: () => onChanged(i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: i == index ? p.primary : Colors.transparent,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (icons != null && icons![i] != null) ...[
                        Icon(icons![i], size: 15, color: i == index ? p.textOnPrimary : p.textSecondary),
                        const SizedBox(width: 6),
                      ],
                      Text(labels[i], style: AppText.label.c(i == index ? p.textOnPrimary : p.textSecondary)),
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

/// App bar standar: tombol kembali + judul + aksi.
class AppTopBar extends StatelessWidget implements PreferredSizeWidget {
  const AppTopBar({super.key, this.title = '', this.actions = const [], this.showBack = true, this.onBack});
  final String title;
  final List<Widget> actions;
  final bool showBack;
  final VoidCallback? onBack;

  @override
  Size get preferredSize => const Size.fromHeight(56);

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return AppBar(
      automaticallyImplyLeading: false,
      titleSpacing: showBack ? 0 : 16,
      leading: showBack
          ? IconButton(
              onPressed: onBack ?? () => Navigator.of(context).maybePop(),
              icon: Icon(Icons.arrow_back_ios_new_rounded, size: 20, color: p.textPrimary),
              tooltip: 'Kembali',
            )
          : null,
      title: Text(title, style: AppText.h2.c(p.textPrimary)),
      actions: [...actions, const SizedBox(width: 12)],
    );
  }
}

class SectionHeader extends StatelessWidget {
  const SectionHeader({super.key, required this.title, this.action, this.onAction, this.trailing});
  final String title;
  final String? action;
  final VoidCallback? onAction;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Row(
      children: [
        Expanded(child: Text(title, style: AppText.h3.c(p.textPrimary))),
        if (trailing != null) trailing!,
        if (action != null)
          GestureDetector(onTap: onAction, child: Text(action!, style: AppText.label.c(p.primary))),
      ],
    );
  }
}

/// Pill pilihan (chip) — dipakai untuk filter & pilihan jenis.
class ChoicePill extends StatelessWidget {
  const ChoicePill({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.showCheck = false,
    this.outlined = false,
  });
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final bool showCheck;
  final bool outlined;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Material(
      color: selected ? p.primary : (outlined ? Colors.transparent : p.bgMuted),
      shape: StadiumBorder(side: outlined && !selected ? BorderSide(color: p.borderStrong) : BorderSide.none),
      child: InkWell(
        customBorder: const StadiumBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (showCheck && selected) ...[
                Icon(Icons.check_rounded, size: 14, color: p.textOnPrimary),
                const SizedBox(width: 6),
              ],
              Text(label, style: AppText.label.c(selected ? p.textOnPrimary : p.textSecondary)),
            ],
          ),
        ),
      ),
    );
  }
}

/// Kotak info berwarna (tips, peringatan, catatan).
class NoteBox extends StatelessWidget {
  const NoteBox({super.key, required this.text, this.icon = Icons.info_outline_rounded, this.tone = NoteTone.info});
  final String text;
  final IconData icon;
  final NoteTone tone;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final (bg, fg) = switch (tone) {
      NoteTone.info => (p.primary50, p.primary),
      NoteTone.warning => (p.warning50, p.warning),
      NoteTone.success => (p.success50, p.success),
      NoteTone.danger => (p.danger50, p.danger),
      NoteTone.neutral => (p.bgSubtle, p.textTertiary),
    };
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(14)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: fg),
          const SizedBox(width: 10),
          Expanded(child: Text(text, style: AppText.bodySm.c(p.textSecondary))),
        ],
      ),
    );
  }
}

enum NoteTone { info, warning, success, danger, neutral }

/// Placeholder loading (skeleton).
class SkeletonBox extends StatelessWidget {
  const SkeletonBox({super.key, this.width, required this.height, this.radius = 6, this.circle = false});
  final double? width;
  final double height;
  final double radius;
  final bool circle;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: context.palette.bgMuted,
        shape: circle ? BoxShape.circle : BoxShape.rectangle,
        borderRadius: circle ? null : BorderRadius.circular(radius),
      ),
    );
  }
}

/// Gauge 3 segmen Rendah | Normal | Tinggi dengan penanda posisi.
class RangeGauge extends StatelessWidget {
  const RangeGauge({super.key, required this.position, this.rangeLabel, this.compact = false});
  final double position; // 0..1
  final String? rangeLabel;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return LayoutBuilder(
      builder: (context, c) {
        final w = c.maxWidth;
        final x = position.clamp(0.0, 1.0).toDouble() * w;
        double fit(double v, double lo, double hi) => hi < lo ? lo : v.clamp(lo, hi).toDouble();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (rangeLabel != null && !compact)
              SizedBox(
                height: 30,
                width: w,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Positioned(
                      left: fit(x - 50, 0, w - 100),
                      width: 100,
                      top: 0,
                      child: Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                          decoration: BoxDecoration(
                            color: p.bgSurface,
                            borderRadius: BorderRadius.circular(99),
                            border: Border.all(color: p.borderStrong),
                          ),
                          child: Text(rangeLabel!, style: AppText.labelSm.c(p.textPrimary), maxLines: 1),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            SizedBox(
              height: 8,
              width: w,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned(
                    left: fit(x - 5, 0, w - 10),
                    top: 0,
                    child: CustomPaint(size: const Size(10, 7), painter: _TrianglePainter(p.textPrimary)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 2),
            Row(
              children: [
                Expanded(flex: 3, child: _bar(p.gaugeLow)),
                const SizedBox(width: 3),
                Expanded(flex: 4, child: _bar(p.gaugeNormal)),
                const SizedBox(width: 3),
                Expanded(flex: 3, child: _bar(p.gaugeHigh)),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                for (final l in const ['Rendah', 'Normal', 'Tinggi'])
                  Text(l, style: AppText.caption.c(compact ? p.textTertiary : p.textSecondary)),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _bar(Color c) =>
      Container(height: compact ? 5 : 6, decoration: BoxDecoration(color: c, borderRadius: BorderRadius.circular(3)));
}

class _TrianglePainter extends CustomPainter {
  _TrianglePainter(this.color);
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width / 2, size.height)
      ..close();
    canvas.drawPath(path, Paint()..color = color);
  }

  @override
  bool shouldRepaint(covariant _TrianglePainter old) => old.color != color;
}

/// Chip aturan password (1 huruf besar, 1 huruf kecil, 1 simbol, min. 10).
class PasswordRuleChips extends StatelessWidget {
  const PasswordRuleChips({super.key, required this.rules});
  final PasswordRules rules;

  static const _labels = ['1 huruf besar', '1 huruf kecil', '1 simbol', 'Min. 10 karakter'];

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final met = rules.asList;
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        for (var i = 0; i < 4; i++)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: met[i] ? p.success50 : p.bgMuted,
              borderRadius: BorderRadius.circular(99),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(met[i] ? Icons.check_rounded : Icons.circle_outlined, size: 12, color: met[i] ? p.success : p.textTertiary),
                const SizedBox(width: 4),
                Text(_labels[i], style: AppText.caption.c(met[i] ? p.success : p.textTertiary)),
              ],
            ),
          ),
      ],
    );
  }
}

/// Toggle kecil sesuai desain.
class AppSwitch extends StatelessWidget {
  const AppSwitch({super.key, required this.value, required this.onChanged});
  final bool value;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    return Transform.scale(scale: 0.85, child: Switch(value: value, onChanged: onChanged));
  }
}

/// Garis pemisah bawah untuk baris list.
BoxDecoration bottomDivider(BuildContext context) =>
    BoxDecoration(border: Border(bottom: BorderSide(color: context.palette.borderDefault)));
