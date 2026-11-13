import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Text style dari Figma (DiVi/...), font Plus Jakarta Sans.
class AppText {
  AppText._();

  static TextStyle _s(double size, FontWeight weight, double height) =>
      GoogleFonts.plusJakartaSans(fontSize: size, fontWeight: weight, height: height);

  static TextStyle get displayXl => _s(48, FontWeight.w700, 1.2);
  static TextStyle get displayLg => _s(36, FontWeight.w700, 1.2);
  static TextStyle get h1 => _s(22, FontWeight.w700, 1.3);
  static TextStyle get h2 => _s(18, FontWeight.w700, 1.35);
  static TextStyle get h3 => _s(16, FontWeight.w600, 1.4);
  static TextStyle get title => _s(14, FontWeight.w600, 1.45);
  static TextStyle get body => _s(14, FontWeight.w400, 1.5);
  static TextStyle get bodySm => _s(12, FontWeight.w400, 1.5);
  static TextStyle get label => _s(12, FontWeight.w500, 1.4);
  static TextStyle get labelSm => _s(11, FontWeight.w600, 1.35);
  static TextStyle get caption => _s(11, FontWeight.w400, 1.4);
  static TextStyle get button => _s(14, FontWeight.w600, 1.4);
}

extension TextStyleColor on TextStyle {
  /// Singkatan `copyWith(color: ...)`.
  TextStyle c(Color color) => copyWith(color: color);
}
