/// Konfigurasi aplikasi. Nilai sensitif dibaca dari `--dart-define`,
/// tidak ditulis langsung di kode.
///
/// Contoh:
/// flutter run --dart-define=GEMINI_API_KEY=xxxx
class AppConfig {
  AppConfig._();

  /// API eksternal untuk halaman Ganti Akun.
  static const dummyJsonBaseUrl = 'https://dummyjson.com';

  /// API key Gemini (opsional). Jika kosong, asisten memakai mode offline.
  static const geminiApiKey = String.fromEnvironment('GEMINI_API_KEY');

  /// Model Gemini yang dipakai (bisa diganti tanpa ubah kode).
  static const geminiModel = String.fromEnvironment('GEMINI_MODEL', defaultValue: 'gemini-2.5-flash');

  static bool get hasAssistantKey => geminiApiKey.isNotEmpty;

  static const appVersion = '1.0.0';

  /// Akun demo yang otomatis dibuat saat database pertama kali dibuat.
  static const demoEmail = 'demo@divilab.id';
  static const demoPassword = 'Divilab@2026';
}
