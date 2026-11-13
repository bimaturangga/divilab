import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_palette.dart';
import 'app_text.dart';

class AppTheme {
  AppTheme._();

  static ThemeData light() => _build(AppPalette.light, Brightness.light);
  static ThemeData dark() => _build(AppPalette.dark, Brightness.dark);

  static ThemeData _build(AppPalette p, Brightness b) {
    final scheme = ColorScheme.fromSeed(seedColor: p.primary, brightness: b).copyWith(
      primary: p.primary,
      onPrimary: p.textOnPrimary,
      surface: p.bgCanvas,
      onSurface: p.textPrimary,
      error: p.danger,
      outline: p.borderDefault,
    );
    final base = ThemeData(useMaterial3: true, brightness: b, colorScheme: scheme);

    OutlineInputBorder border(Color c, [double w = 1]) => OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: c, width: w),
        );

    return base.copyWith(
      scaffoldBackgroundColor: p.bgCanvas,
      extensions: [p],
      textTheme: GoogleFonts.plusJakartaSansTextTheme(base.textTheme).apply(
        bodyColor: p.textPrimary,
        displayColor: p.textPrimary,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: p.bgCanvas,
        foregroundColor: p.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: AppText.h2.c(p.textPrimary),
        systemOverlayStyle: b == Brightness.light ? SystemUiOverlayStyle.dark : SystemUiOverlayStyle.light,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: p.bgSurface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        hintStyle: AppText.body.c(p.textTertiary),
        enabledBorder: border(p.borderDefault),
        border: border(p.borderDefault),
        focusedBorder: border(p.primary, 1.5),
        errorBorder: border(p.danger),
        focusedErrorBorder: border(p.danger, 1.5),
        disabledBorder: border(p.borderDefault),
        errorStyle: AppText.caption.c(p.danger),
        suffixIconColor: p.textTertiary,
        prefixIconColor: p.textTertiary,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.all(Colors.white),
        trackColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? p.primary : p.borderStrong,
        ),
        trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
      ),
      dividerTheme: DividerThemeData(color: p.borderDefault, thickness: 1, space: 1),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: p.bgCanvas,
        modalBackgroundColor: p.bgCanvas,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: p.textPrimary,
        contentTextStyle: AppText.body.c(p.bgCanvas),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(color: p.primary),
    );
  }
}
