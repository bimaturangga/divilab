import 'package:flutter/material.dart';

/// Token warna dari Figma (koleksi "DiVi Tokens", mode Light/Dark).
/// Diakses lewat `context.palette`.
@immutable
class AppPalette extends ThemeExtension<AppPalette> {
  const AppPalette({
    required this.bgCanvas,
    required this.bgSubtle,
    required this.bgSurface,
    required this.bgMuted,
    required this.bgHeader,
    required this.borderDefault,
    required this.borderStrong,
    required this.textPrimary,
    required this.textSecondary,
    required this.textTertiary,
    required this.textOnPrimary,
    required this.primary,
    required this.primary600,
    required this.primary100,
    required this.primary50,
    required this.success,
    required this.success50,
    required this.warning,
    required this.warning50,
    required this.danger,
    required this.danger50,
    required this.purple,
    required this.purple50,
    required this.info,
    required this.info50,
    required this.gaugeLow,
    required this.gaugeNormal,
    required this.gaugeHigh,
    required this.scrim,
  });

  final Color bgCanvas;
  final Color bgSubtle;
  final Color bgSurface;
  final Color bgMuted;
  final Color bgHeader;
  final Color borderDefault;
  final Color borderStrong;
  final Color textPrimary;
  final Color textSecondary;
  final Color textTertiary;
  final Color textOnPrimary;
  final Color primary;
  final Color primary600;
  final Color primary100;
  final Color primary50;
  final Color success;
  final Color success50;
  final Color warning;
  final Color warning50;
  final Color danger;
  final Color danger50;
  final Color purple;
  final Color purple50;
  final Color info;
  final Color info50;
  final Color gaugeLow;
  final Color gaugeNormal;
  final Color gaugeHigh;
  final Color scrim;

  static const light = AppPalette(
    bgCanvas: Color(0xFFFFFFFF),
    bgSubtle: Color(0xFFF5F7FA),
    bgSurface: Color(0xFFFFFFFF),
    bgMuted: Color(0xFFEEF1F5),
    bgHeader: Color(0xFF009CEE),
    borderDefault: Color(0xFFE4E7EC),
    borderStrong: Color(0xFFD0D5DD),
    textPrimary: Color(0xFF16191F),
    textSecondary: Color(0xFF5D6675),
    textTertiary: Color(0xFF98A2B3),
    textOnPrimary: Color(0xFFFFFFFF),
    primary: Color(0xFF009CEE),
    primary600: Color(0xFF0086D1),
    primary100: Color(0xFFD6EFFD),
    primary50: Color(0xFFEEF8FF),
    success: Color(0xFF1F9D45),
    success50: Color(0xFFE7F7EC),
    warning: Color(0xFFF58A07),
    warning50: Color(0xFFFFF3E3),
    danger: Color(0xFFF04438),
    danger50: Color(0xFFFEEDEC),
    purple: Color(0xFF6941C6),
    purple50: Color(0xFFF2EDFC),
    info: Color(0xFF2E90FA),
    info50: Color(0xFFE6F4FF),
    gaugeLow: Color(0xFFBFE3FA),
    gaugeNormal: Color(0xFFC6EFD2),
    gaugeHigh: Color(0xFFFDD8C6),
    scrim: Color(0x800B111C),
  );

  static const dark = AppPalette(
    bgCanvas: Color(0xFF0B111C),
    bgSubtle: Color(0xFF121A27),
    bgSurface: Color(0xFF172032),
    bgMuted: Color(0xFF1F2A3D),
    bgHeader: Color(0xFF0D3354),
    borderDefault: Color(0xFF263148),
    borderStrong: Color(0xFF37435C),
    textPrimary: Color(0xFFF3F5F8),
    textSecondary: Color(0xFFA9B2C1),
    textTertiary: Color(0xFF6E7A8F),
    textOnPrimary: Color(0xFFFFFFFF),
    primary: Color(0xFF22ADF6),
    primary600: Color(0xFF55C0F8),
    primary100: Color(0xFF14395A),
    primary50: Color(0xFF0F2236),
    success: Color(0xFF3DCB63),
    success50: Color(0xFF11301C),
    warning: Color(0xFFFFA43A),
    warning50: Color(0xFF3A2810),
    danger: Color(0xFFF97066),
    danger50: Color(0xFF3A1816),
    purple: Color(0xFF9B7BF0),
    purple50: Color(0xFF241A40),
    info: Color(0xFF53B1FD),
    info50: Color(0xFF12304A),
    gaugeLow: Color(0xFF1D4F75),
    gaugeNormal: Color(0xFF1D5A34),
    gaugeHigh: Color(0xFF6A3322),
    scrim: Color(0xA6000000),
  );

  /// Warna avatar profil (dipilih berdasarkan indeks).
  List<Color> get avatarColors => [primary, purple, warning, danger, success, info];

  @override
  AppPalette copyWith() => this;

  @override
  AppPalette lerp(ThemeExtension<AppPalette>? other, double t) {
    if (other is! AppPalette) return this;
    Color l(Color a, Color b) => Color.lerp(a, b, t)!;
    return AppPalette(
      bgCanvas: l(bgCanvas, other.bgCanvas),
      bgSubtle: l(bgSubtle, other.bgSubtle),
      bgSurface: l(bgSurface, other.bgSurface),
      bgMuted: l(bgMuted, other.bgMuted),
      bgHeader: l(bgHeader, other.bgHeader),
      borderDefault: l(borderDefault, other.borderDefault),
      borderStrong: l(borderStrong, other.borderStrong),
      textPrimary: l(textPrimary, other.textPrimary),
      textSecondary: l(textSecondary, other.textSecondary),
      textTertiary: l(textTertiary, other.textTertiary),
      textOnPrimary: l(textOnPrimary, other.textOnPrimary),
      primary: l(primary, other.primary),
      primary600: l(primary600, other.primary600),
      primary100: l(primary100, other.primary100),
      primary50: l(primary50, other.primary50),
      success: l(success, other.success),
      success50: l(success50, other.success50),
      warning: l(warning, other.warning),
      warning50: l(warning50, other.warning50),
      danger: l(danger, other.danger),
      danger50: l(danger50, other.danger50),
      purple: l(purple, other.purple),
      purple50: l(purple50, other.purple50),
      info: l(info, other.info),
      info50: l(info50, other.info50),
      gaugeLow: l(gaugeLow, other.gaugeLow),
      gaugeNormal: l(gaugeNormal, other.gaugeNormal),
      gaugeHigh: l(gaugeHigh, other.gaugeHigh),
      scrim: l(scrim, other.scrim),
    );
  }
}

extension PaletteContext on BuildContext {
  AppPalette get palette => Theme.of(this).extension<AppPalette>()!;
  TextTheme get text => Theme.of(this).textTheme;
}
