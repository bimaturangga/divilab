/// Validasi form (dipakai di layar registrasi & login).
class Validators {
  Validators._();

  static final _email = RegExp(r'^[\w.+-]+@[\w-]+(\.[\w-]+)+$');

  static String? email(String? v) {
    final s = (v ?? '').trim();
    if (s.isEmpty) return 'Email wajib diisi';
    if (!_email.hasMatch(s)) return 'Format email tidak valid';
    return null;
  }

  static String? required(String? v, String field) {
    if ((v ?? '').trim().isEmpty) return '$field wajib diisi';
    return null;
  }

  /// Aturan password sesuai desain:
  /// 1 huruf besar, 1 huruf kecil, 1 simbol, minimal 10 karakter.
  static PasswordRules passwordRules(String v) => PasswordRules(
        hasUpper: RegExp('[A-Z]').hasMatch(v),
        hasLower: RegExp('[a-z]').hasMatch(v),
        hasSymbol: RegExp(r'[^A-Za-z0-9]').hasMatch(v),
        hasMinLength: v.length >= 10,
      );

  static String? password(String? v) {
    final s = v ?? '';
    if (s.isEmpty) return 'Password wajib diisi';
    if (!passwordRules(s).allMet) return 'Password belum memenuhi semua syarat';
    return null;
  }

  static String? confirmPassword(String? v, String password) {
    if ((v ?? '').isEmpty) return 'Konfirmasi password wajib diisi';
    if (v != password) return 'Konfirmasi password tidak cocok dengan password';
    return null;
  }

  static String? number(String? v, String field, {double min = 0, double max = 1000}) {
    final s = (v ?? '').trim().replaceAll(',', '.');
    if (s.isEmpty) return '$field wajib diisi';
    final n = double.tryParse(s);
    if (n == null) return '$field harus berupa angka';
    if (n < min || n > max) return '$field harus antara ${min.toStringAsFixed(0)}–${max.toStringAsFixed(0)}';
    return null;
  }
}

class PasswordRules {
  const PasswordRules({
    required this.hasUpper,
    required this.hasLower,
    required this.hasSymbol,
    required this.hasMinLength,
  });

  final bool hasUpper;
  final bool hasLower;
  final bool hasSymbol;
  final bool hasMinLength;

  bool get allMet => hasUpper && hasLower && hasSymbol && hasMinLength;
  List<bool> get asList => [hasUpper, hasLower, hasSymbol, hasMinLength];
}
