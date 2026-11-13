import 'package:sqflite/sqflite.dart';

import '../../core/utils/password_hasher.dart';
import '../db/app_database.dart';
import '../db/demo_seeder.dart';
import '../models/app_user.dart';

class AuthException implements Exception {
  const AuthException(this.message);
  final String message;
  @override
  String toString() => message;
}

/// Data registrasi yang dikumpulkan dari 3 langkah (akun, OTP, data personal).
class RegistrationDraft {
  RegistrationDraft({required this.email, required this.password});
  final String email;
  final String password;
}

class AuthRepository {
  AuthRepository([AppDatabase? db]) : _db = db ?? AppDatabase.instance;
  final AppDatabase _db;

  Future<bool> emailExists(String email) async {
    final db = await _db.database;
    final rows = await db.query('users', columns: ['id'], where: 'email = ?', whereArgs: [email.trim().toLowerCase()]);
    return rows.isNotEmpty;
  }

  Future<AppUser> login(String email, String password) async {
    final db = await _db.database;
    final rows = await db.query('users', where: 'email = ?', whereArgs: [email.trim().toLowerCase()], limit: 1);
    if (rows.isEmpty) throw const AuthException('Email belum terdaftar');
    final user = AppUser.fromMap(rows.first);
    if (!PasswordHasher.verify(password, user.salt, user.passwordHash)) {
      throw const AuthException('Email atau password salah');
    }
    return user;
  }

  /// Membuat user baru + profil "Pemilik Akun" + data default dalam satu transaksi.
  Future<AppUser> register({
    required RegistrationDraft draft,
    required String name,
    required String gender,
    required DateTime birthDate,
    required double height,
    required double weight,
    String? productionCode,
  }) async {
    final db = await _db.database;
    final email = draft.email.trim().toLowerCase();
    if (await emailExists(email)) throw const AuthException('Email sudah terdaftar');
    final salt = PasswordHasher.newSalt();
    final user = AppUser(
      email: email,
      passwordHash: PasswordHasher.hash(draft.password, salt),
      salt: salt,
      name: name.trim(),
      gender: gender,
      birthDate: birthDate,
      height: height,
      weight: weight,
      productionCode: (productionCode ?? '').trim().isEmpty ? null : productionCode!.trim(),
      createdAt: DateTime.now(),
    );
    final id = await db.transaction<int>((txn) async {
      final map = user.toMap()..remove('id');
      final userId = await txn.insert('users', map, conflictAlgorithm: ConflictAlgorithm.abort);
      await txn.insert('profiles', {
        'owner_id': userId,
        'name': user.name,
        'relation': 'Pemilik Akun',
        'gender': gender,
        'age': user.age,
        'color_index': 5,
      });
      await DemoSeeder.insertDefaults(txn, userId);
      return userId;
    });
    return (await findById(id))!;
  }

  Future<AppUser?> findById(int id) async {
    final db = await _db.database;
    final rows = await db.query('users', where: 'id = ?', whereArgs: [id], limit: 1);
    return rows.isEmpty ? null : AppUser.fromMap(rows.first);
  }

  Future<AppUser> updateProfile(AppUser user) async {
    final db = await _db.database;
    await db.update('users', user.toMap()..remove('id'), where: 'id = ?', whereArgs: [user.id]);
    await db.update(
      'profiles',
      {'name': user.name, 'gender': user.gender, 'age': user.age},
      where: 'owner_id = ? AND relation = ?',
      whereArgs: [user.id, 'Pemilik Akun'],
    );
    return (await findById(user.id!))!;
  }
}
