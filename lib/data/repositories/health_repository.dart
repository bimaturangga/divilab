import 'package:sqflite/sqflite.dart';

import '../../core/health.dart';
import '../db/app_database.dart';
import '../models/app_message.dart';
import '../models/measurement.dart';
import '../models/reminder.dart';

/// Akses data kesehatan: pengukuran, sisa strip, pesan, dan pengingat.
class HealthRepository {
  HealthRepository([AppDatabase? db]) : _db = db ?? AppDatabase.instance;
  final AppDatabase _db;

  // ---------------- Measurements ----------------

  Future<List<Measurement>> measurementsOf(int profileId, {DateTime? from, DateTime? to}) async {
    final db = await _db.database;
    final where = StringBuffer('profile_id = ?');
    final args = <Object?>[profileId];
    if (from != null) {
      where.write(' AND measured_at >= ?');
      args.add(from.toIso8601String());
    }
    if (to != null) {
      where.write(' AND measured_at <= ?');
      args.add(to.toIso8601String());
    }
    final rows = await db.query('measurements', where: where.toString(), whereArgs: args, orderBy: 'measured_at DESC');
    return rows.map(Measurement.fromMap).toList();
  }

  Future<Measurement> insertMeasurement(Measurement m) async {
    final db = await _db.database;
    final id = await db.insert('measurements', m.toMap()..remove('id'));
    final rows = await db.query('measurements', where: 'id = ?', whereArgs: [id]);
    return Measurement.fromMap(rows.first);
  }

  Future<void> deleteMeasurement(int id) async {
    final db = await _db.database;
    await db.delete('measurements', where: 'id = ?', whereArgs: [id]);
  }

  // ---------------- Strip stock ----------------

  Future<Map<MeasurementType, int>> strips(int ownerId) async {
    final db = await _db.database;
    final rows = await db.query('strip_stock', where: 'owner_id = ?', whereArgs: [ownerId]);
    final map = {for (final t in MeasurementType.stripTypes) t: 0};
    for (final r in rows) {
      map[MeasurementType.fromKey(r['type'] as String)] = r['qty'] as int;
    }
    return map;
  }

  Future<void> setStrip(int ownerId, MeasurementType type, int qty) async {
    final db = await _db.database;
    await db.insert(
      'strip_stock',
      {'owner_id': ownerId, 'type': type.key, 'qty': qty < 0 ? 0 : qty},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // ---------------- Messages ----------------

  Future<List<AppMessage>> messages(int ownerId) async {
    final db = await _db.database;
    final rows = await db.query('messages', where: 'owner_id = ?', whereArgs: [ownerId], orderBy: 'created_at DESC');
    return rows.map(AppMessage.fromMap).toList();
  }

  Future<void> addMessage(AppMessage m) async {
    final db = await _db.database;
    await db.insert('messages', m.toMap()..remove('id'));
  }

  Future<void> markAllRead(int ownerId) async {
    final db = await _db.database;
    await db.update('messages', {'read': 1}, where: 'owner_id = ?', whereArgs: [ownerId]);
  }

  // ---------------- Reminders ----------------

  Future<List<Reminder>> reminders(int ownerId) async {
    final db = await _db.database;
    final rows = await db.query('reminders', where: 'owner_id = ?', whereArgs: [ownerId], orderBy: 'hour, minute');
    return rows.map(Reminder.fromMap).toList();
  }

  Future<void> saveReminder(Reminder r) async {
    final db = await _db.database;
    if (r.id == null) {
      await db.insert('reminders', r.toMap()..remove('id'));
    } else {
      await db.update('reminders', r.toMap()..remove('id'), where: 'id = ?', whereArgs: [r.id]);
    }
  }

  Future<void> deleteReminder(int id) async {
    final db = await _db.database;
    await db.delete('reminders', where: 'id = ?', whereArgs: [id]);
  }
}
