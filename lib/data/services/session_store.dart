import 'package:shared_preferences/shared_preferences.dart';

/// Menyimpan sesi & preferensi ringan (bukan data kesehatan).
class SessionStore {
  static const _kOnboarding = 'onboarding_done';
  static const _kUserId = 'user_id';
  static const _kProfileId = 'profile_id';
  static const _kTheme = 'theme_mode';
  static const _kPush = 'push_enabled';

  SharedPreferences? _prefs;

  Future<void> load() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  SharedPreferences get _p {
    final p = _prefs;
    if (p == null) throw StateError('SessionStore.load() belum dipanggil');
    return p;
  }

  bool get onboardingDone => _p.getBool(_kOnboarding) ?? false;
  Future<void> setOnboardingDone() => _p.setBool(_kOnboarding, true);

  int? get userId => _p.getInt(_kUserId);
  Future<void> setUserId(int id) => _p.setInt(_kUserId, id);

  int? get profileId => _p.getInt(_kProfileId);
  Future<void> setProfileId(int id) => _p.setInt(_kProfileId, id);

  String get themeMode => _p.getString(_kTheme) ?? 'light';
  Future<void> setThemeMode(String v) => _p.setString(_kTheme, v);

  bool get pushEnabled => _p.getBool(_kPush) ?? true;
  Future<void> setPushEnabled(bool v) => _p.setBool(_kPush, v);

  Future<void> clearSession() async {
    await _p.remove(_kUserId);
    await _p.remove(_kProfileId);
  }
}
