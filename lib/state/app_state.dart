import 'package:flutter/material.dart';

import '../data/models/app_user.dart';
import '../data/models/profile.dart';
import '../data/models/remote_user.dart';
import '../data/repositories/auth_repository.dart';
import '../data/repositories/profile_repository.dart';
import '../data/services/session_store.dart';

/// State global: sesi login, profil aktif, tema, dan preferensi.
class AppState extends ChangeNotifier {
  AppState({AuthRepository? auth, ProfileRepository? profiles, SessionStore? session})
      : _auth = auth ?? AuthRepository(),
        _profiles = profiles ?? ProfileRepository(),
        _session = session ?? SessionStore();

  final AuthRepository _auth;
  final ProfileRepository _profiles;
  final SessionStore _session;

  AuthRepository get auth => _auth;

  bool ready = false;
  bool onboardingDone = false;
  ThemeMode themeMode = ThemeMode.light;
  bool pushEnabled = true;

  AppUser? user;
  List<Profile> profiles = const [];
  Profile? activeProfile;

  bool get isLoggedIn => user != null;

  Future<void> init() async {
    await _session.load();
    onboardingDone = _session.onboardingDone;
    themeMode = _session.themeMode == 'dark' ? ThemeMode.dark : ThemeMode.light;
    pushEnabled = _session.pushEnabled;
    final uid = _session.userId;
    if (uid != null) {
      user = await _auth.findById(uid);
      if (user == null) {
        await _session.clearSession();
      } else {
        await _loadProfiles(preferredId: _session.profileId);
      }
    }
    ready = true;
    notifyListeners();
  }

  Future<void> completeOnboarding() async {
    onboardingDone = true;
    await _session.setOnboardingDone();
    notifyListeners();
  }

  Future<void> login(String email, String password) async {
    final u = await _auth.login(email, password);
    await _startSession(u);
  }

  /// Dipanggil setelah registrasi selesai.
  Future<void> startSession(AppUser u) => _startSession(u);

  Future<void> _startSession(AppUser u) async {
    user = u;
    await _session.setUserId(u.id!);
    await _loadProfiles();
    notifyListeners();
  }

  Future<void> logout() async {
    user = null;
    profiles = const [];
    activeProfile = null;
    await _session.clearSession();
    notifyListeners();
  }

  Future<void> _loadProfiles({int? preferredId}) async {
    final u = user;
    if (u == null) return;
    profiles = await _profiles.profilesOf(u.id!);
    if (profiles.isEmpty) {
      activeProfile = null;
      return;
    }
    activeProfile = profiles.firstWhere((p) => p.id == preferredId, orElse: () => profiles.first);
    await _session.setProfileId(activeProfile!.id!);
  }

  Future<void> switchProfile(Profile p) async {
    activeProfile = p;
    await _session.setProfileId(p.id!);
    notifyListeners();
  }

  /// "Gunakan Akun Ini" di halaman Ganti Akun (data dari API dummyjson):
  /// akun disimpan sebagai profil di SQLite lalu dijadikan profil aktif.
  Future<Profile> useRemoteAccount(RemoteUser remote) async {
    final p = await _profiles.upsertRemote(user!.id!, remote);
    await _loadProfiles(preferredId: p.id);
    notifyListeners();
    return p;
  }

  Future<void> updateUser(AppUser updated) async {
    user = await _auth.updateProfile(updated);
    await _loadProfiles(preferredId: activeProfile?.id);
    notifyListeners();
  }

  Future<void> setDarkMode(bool dark) async {
    themeMode = dark ? ThemeMode.dark : ThemeMode.light;
    await _session.setThemeMode(dark ? 'dark' : 'light');
    notifyListeners();
  }

  Future<void> setPushEnabled(bool v) async {
    pushEnabled = v;
    await _session.setPushEnabled(v);
    notifyListeners();
  }
}
