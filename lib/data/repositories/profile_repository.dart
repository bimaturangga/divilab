import '../db/app_database.dart';
import '../models/profile.dart';
import '../models/remote_user.dart';

class ProfileRepository {
  ProfileRepository([AppDatabase? db]) : _db = db ?? AppDatabase.instance;
  final AppDatabase _db;

  /// Pemilik akun selalu di urutan pertama.
  Future<List<Profile>> profilesOf(int ownerId) async {
    final db = await _db.database;
    final rows = await db.query(
      'profiles',
      where: 'owner_id = ?',
      whereArgs: [ownerId],
      orderBy: "CASE relation WHEN 'Pemilik Akun' THEN 0 ELSE 1 END, id",
    );
    return rows.map(Profile.fromMap).toList();
  }

  Future<Profile?> findById(int id) async {
    final db = await _db.database;
    final rows = await db.query('profiles', where: 'id = ?', whereArgs: [id], limit: 1);
    return rows.isEmpty ? null : Profile.fromMap(rows.first);
  }

  /// Menambahkan akun dari API dummyjson sebagai profil (atau memakai yang sudah ada).
  Future<Profile> upsertRemote(int ownerId, RemoteUser user) async {
    final db = await _db.database;
    final existing = await db.query(
      'profiles',
      where: 'owner_id = ? AND remote_id = ?',
      whereArgs: [ownerId, user.id],
      limit: 1,
    );
    if (existing.isNotEmpty) return Profile.fromMap(existing.first);
    final profile = Profile(
      ownerId: ownerId,
      name: user.fullName,
      relation: 'Lainnya',
      gender: user.genderLabel,
      age: user.age,
      colorIndex: user.id % 6,
      remoteId: user.id,
      email: user.email,
    );
    final id = await db.insert('profiles', profile.toMap()..remove('id'));
    return (await findById(id))!;
  }
}
