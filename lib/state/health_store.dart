import 'package:flutter/foundation.dart';

import '../core/health.dart';
import '../data/models/app_message.dart';
import '../data/models/measurement.dart';
import '../data/models/reminder.dart';
import '../data/repositories/health_repository.dart';

/// Data kesehatan untuk user & profil aktif, di-cache agar UI bisa
/// membaca secara sinkron. Diperbarui otomatis saat profil berganti
/// (lihat ChangeNotifierProxyProvider di main.dart).
class HealthStore extends ChangeNotifier {
  HealthStore({HealthRepository? repo}) : _repo = repo ?? HealthRepository();
  final HealthRepository _repo;

  int? _ownerId;
  int? _profileId;

  bool loading = false;
  List<Measurement> measurements = const []; // profil aktif, terbaru dulu
  Map<MeasurementType, int> strips = const {};
  List<AppMessage> messages = const [];
  List<Reminder> reminders = const [];

  int get unreadCount => messages.where((m) => !m.read).length;
  int? get profileId => _profileId;

  /// Dipanggil dari ProxyProvider; tidak boleh notify secara sinkron.
  void bind(int? ownerId, int? profileId) {
    if (ownerId == _ownerId && profileId == _profileId) return;
    _ownerId = ownerId;
    _profileId = profileId;
    if (ownerId == null || profileId == null) {
      measurements = const [];
      strips = const {};
      messages = const [];
      reminders = const [];
      Future.microtask(notifyListeners);
      return;
    }
    Future.microtask(refresh);
  }

  Future<void> refresh() async {
    final owner = _ownerId;
    final profile = _profileId;
    if (owner == null || profile == null) return;
    loading = true;
    notifyListeners();
    final results = await Future.wait<Object>([
      _repo.measurementsOf(profile),
      _repo.strips(owner),
      _repo.messages(owner),
      _repo.reminders(owner),
    ]);
    // Abaikan hasil jika profil sudah berganti saat menunggu.
    if (owner != _ownerId || profile != _profileId) return;
    measurements = results[0] as List<Measurement>;
    strips = results[1] as Map<MeasurementType, int>;
    messages = results[2] as List<AppMessage>;
    reminders = results[3] as List<Reminder>;
    loading = false;
    notifyListeners();
  }

  Measurement? latest(MeasurementType t) {
    for (final m in measurements) {
      if (m.type == t) return m;
    }
    return null;
  }

  List<Measurement> filter({MeasurementType? type, DateTime? from, DateTime? to, GlucoseKind? kind}) {
    return measurements.where((m) {
      if (type != null && m.type != type) return false;
      if (kind != null && (m.glucoseKind ?? GlucoseKind.gen) != kind) return false;
      if (from != null && m.measuredAt.isBefore(from)) return false;
      if (to != null && m.measuredAt.isAfter(to)) return false;
      return true;
    }).toList();
  }

  /// Simpan hasil pengukuran. Otomatis mengurangi strip & membuat pesan
  /// bila hasil di luar rentang normal atau strip hampir habis.
  Future<Measurement> save(Measurement m, {required String profileName, bool consumeStrip = false}) async {
    final owner = _ownerId!;
    final saved = await _repo.insertMeasurement(m);
    if (consumeStrip && m.type.usesStrip) {
      final left = (strips[m.type] ?? 0) - 1;
      await _repo.setStrip(owner, m.type, left);
      if (left <= 2) {
        await _repo.addMessage(AppMessage(
          ownerId: owner,
          title: left <= 0 ? 'Strip ${m.type.label} Habis' : 'Strip ${m.type.label} Hampir Habis',
          body: left <= 0
              ? 'Strip ${m.type.label.toLowerCase()} sudah habis. Segera beli strip baru untuk melanjutkan pengukuran.'
              : 'Sisa strip ${m.type.label.toLowerCase()} tinggal $left. Segera beli strip baru.',
          createdAt: DateTime.now(),
        ));
      }
    }
    if (saved.status != HealthStatus.normal) {
      await _repo.addMessage(AppMessage(
        ownerId: owner,
        title: 'Pengukuran ${m.type.label} – $profileName',
        body: '${m.type.label} $profileName ${saved.displayValue} ${m.type.unit} '
            '(terdeteksi ${saved.status.label.toLowerCase()}). Nilai ini berada di luar rentang normal.',
        createdAt: DateTime.now(),
      ));
    }
    await refresh();
    return saved;
  }

  Future<void> delete(Measurement m) async {
    await _repo.deleteMeasurement(m.id!);
    await refresh();
  }

  Future<void> setStrip(MeasurementType t, int qty) async {
    await _repo.setStrip(_ownerId!, t, qty);
    await refresh();
  }

  Future<void> saveReminder(Reminder r) async {
    await _repo.saveReminder(r);
    await refresh();
  }

  Future<void> toggleReminder(Reminder r, bool enabled) => saveReminder(r.copyWith(enabled: enabled));

  Future<void> deleteReminder(Reminder r) async {
    await _repo.deleteReminder(r.id!);
    await refresh();
  }

  Future<void> markMessagesRead() async {
    if (unreadCount == 0) return;
    await _repo.markAllRead(_ownerId!);
    await refresh();
  }

  int? get ownerId => _ownerId;
}
