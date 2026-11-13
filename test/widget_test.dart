// Catatan: file ini sengaja ada agar `flutter create .` tidak membuat
// widget_test.dart bawaan (yang merujuk ke MyApp).
import 'package:divilab/core/utils/date_fmt.dart';
import 'package:divilab/data/models/profile.dart';
import 'package:divilab/data/models/reminder.dart';
import 'package:divilab/core/health.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('format tanggal Indonesia', () {
    final d = DateTime(2026, 9, 14, 15, 46);
    expect(DateFmt.dateShort(d), '14 Sep 2026');
    expect(DateFmt.dateTime(d), '14 Sep 2026, 15:46');
    expect(DateFmt.range(DateTime(2026, 9, 8), d), '8 – 14 Sep 2026');
  });

  test('inisial profil', () {
    const p = Profile(ownerId: 1, name: 'Jane Dane', relation: Profile.owner, gender: 'Perempuan');
    expect(p.initials, 'JD');
    expect(p.isOwner, isTrue);
  });

  test('label jadwal pengingat', () {
    const r = Reminder(ownerId: 1, title: 'Gula Darah', types: [MeasurementType.glucose], days: [5, 1, 3], hour: 7, minute: 0);
    expect(r.scheduleLabel, 'Sen, Rab, Jum · 07:00');
    final all = Reminder.fromMap(const Reminder(
      ownerId: 1,
      title: 'Tensi',
      types: [MeasurementType.bloodPressure],
      days: [1, 2, 3, 4, 5, 6, 7],
      hour: 6,
      minute: 30,
    ).toMap());
    expect(all.scheduleLabel, 'Setiap hari · 06:30');
  });
}
