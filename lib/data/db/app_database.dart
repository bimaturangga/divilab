import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import 'demo_seeder.dart';

/// Database SQLite lokal aplikasi (sqflite).
///
/// Tabel:
/// - users        : akun terdaftar (password di-hash + salt)
/// - profiles     : profil pasien (pemilik akun, keluarga, akun dari API)
/// - measurements : hasil pengukuran (perangkat / manual)
/// - reminders    : pengingat pengukuran
/// - messages     : pesan notifikasi
/// - strip_stock  : sisa strip per jenis
class AppDatabase {
  AppDatabase._();
  static final AppDatabase instance = AppDatabase._();

  static const _fileName = 'divilab.db';
  static const _version = 1;

  Database? _db;

  Future<Database> get database async => _db ??= await _open();

  Future<Database> _open() async {
    final dir = await getDatabasesPath();
    return openDatabase(
      p.join(dir, _fileName),
      version: _version,
      onConfigure: (db) => db.execute('PRAGMA foreign_keys = ON'),
      onCreate: (db, version) async {
        await _createSchema(db);
        await DemoSeeder.seed(db);
      },
    );
  }

  static Future<void> _createSchema(Database db) async {
    final batch = db.batch();
    batch.execute('''
      CREATE TABLE users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        email TEXT NOT NULL UNIQUE,
        password_hash TEXT NOT NULL,
        salt TEXT NOT NULL,
        name TEXT NOT NULL,
        gender TEXT,
        birth_date TEXT,
        height REAL,
        weight REAL,
        production_code TEXT,
        created_at TEXT NOT NULL
      )''');
    batch.execute('''
      CREATE TABLE profiles (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        owner_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
        name TEXT NOT NULL,
        relation TEXT NOT NULL,
        gender TEXT,
        age INTEGER,
        color_index INTEGER NOT NULL DEFAULT 0,
        remote_id INTEGER,
        email TEXT
      )''');
    batch.execute('''
      CREATE TABLE measurements (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        profile_id INTEGER NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
        type TEXT NOT NULL,
        subtype TEXT,
        value REAL NOT NULL,
        value2 REAL,
        pulse INTEGER,
        source TEXT NOT NULL DEFAULT 'device',
        device_name TEXT,
        note TEXT,
        measured_at TEXT NOT NULL
      )''');
    batch.execute('CREATE INDEX idx_measurements_profile ON measurements(profile_id, measured_at)');
    batch.execute('''
      CREATE TABLE reminders (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        owner_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
        title TEXT NOT NULL,
        types TEXT NOT NULL,
        days TEXT NOT NULL,
        hour INTEGER NOT NULL,
        minute INTEGER NOT NULL,
        enabled INTEGER NOT NULL DEFAULT 1
      )''');
    batch.execute('''
      CREATE TABLE messages (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        owner_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
        title TEXT NOT NULL,
        body TEXT NOT NULL,
        created_at TEXT NOT NULL,
        read INTEGER NOT NULL DEFAULT 0
      )''');
    batch.execute('''
      CREATE TABLE strip_stock (
        owner_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
        type TEXT NOT NULL,
        qty INTEGER NOT NULL,
        PRIMARY KEY (owner_id, type)
      )''');
    await batch.commit(noResult: true);
  }
}
