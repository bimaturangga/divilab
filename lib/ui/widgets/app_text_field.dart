import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/app_palette.dart';
import '../../core/theme/app_text.dart';

/// Input sesuai komponen "Input" di Figma: label di atas, field 48px,
/// ikon di kanan, dan teks bantuan/error di bawah.
class AppTextField extends StatefulWidget {
  const AppTextField({
    super.key,
    required this.label,
    this.hint,
    this.controller,
    this.password = false,
    this.keyboardType,
    this.textInputAction,
    this.suffixIcon,
    this.onSuffixTap,
    this.readOnly = false,
    this.onTap,
    this.onChanged,
    this.onSubmitted,
    this.errorText,
    this.helper,
    this.inputFormatters,
    this.autofillHints,
    this.maxLines = 1,
    this.suffixText,
    this.enabled = true,
  });

  final String label;
  final String? hint;
  final TextEditingController? controller;
  final bool password;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final IconData? suffixIcon;
  final VoidCallback? onSuffixTap;
  final bool readOnly;
  final VoidCallback? onTap;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final String? errorText;
  final Widget? helper;
  final List<TextInputFormatter>? inputFormatters;
  final Iterable<String>? autofillHints;
  final int maxLines;
  final String? suffixText;
  final bool enabled;

  @override
  State<AppTextField> createState() => _AppTextFieldState();
}

class _AppTextFieldState extends State<AppTextField> {
  late bool _hidden = widget.password;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final hasError = widget.errorText != null;
    Widget? suffix;
    if (widget.password) {
      suffix = IconButton(
        onPressed: () => setState(() => _hidden = !_hidden),
        icon: Icon(_hidden ? Icons.visibility_off_outlined : Icons.visibility_outlined, size: 20),
        tooltip: _hidden ? 'Tampilkan password' : 'Sembunyikan password',
      );
    } else if (widget.suffixIcon != null) {
      suffix = IconButton(onPressed: widget.onSuffixTap ?? widget.onTap, icon: Icon(widget.suffixIcon, size: 20));
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(widget.label, style: AppText.label.c(hasError ? p.danger : p.textPrimary)),
        const SizedBox(height: 8),
        TextField(
          controller: widget.controller,
          obscureText: _hidden,
          keyboardType: widget.keyboardType,
          textInputAction: widget.textInputAction,
          readOnly: widget.readOnly,
          onTap: widget.onTap,
          onChanged: widget.onChanged,
          onSubmitted: widget.onSubmitted,
          inputFormatters: widget.inputFormatters,
          autofillHints: widget.autofillHints,
          maxLines: widget.password ? 1 : widget.maxLines,
          enabled: widget.enabled,
          style: AppText.body.c(p.textPrimary),
          cursorColor: p.primary,
          decoration: InputDecoration(
            hintText: widget.hint,
            suffixIcon: suffix,
            suffixText: widget.suffixText,
            suffixStyle: AppText.bodySm.c(p.textSecondary),
            fillColor: widget.enabled ? p.bgSurface : p.bgMuted,
            enabledBorder: hasError
                ? OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: p.danger))
                : null,
            focusedBorder: hasError
                ? OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: p.danger, width: 1.5),
                  )
                : null,
          ),
        ),
        if (hasError) ...[
          const SizedBox(height: 6),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.error_outline_rounded, size: 14, color: p.danger),
              const SizedBox(width: 6),
              Expanded(child: Text(widget.errorText!, style: AppText.caption.c(p.danger))),
            ],
          ),
        ],
        if (widget.helper != null) ...[const SizedBox(height: 8), widget.helper!],
      ],
    );
  }
}
