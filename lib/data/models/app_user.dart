import '../../core/utils/date_fmt.dart';

/// Akun yang terdaftar di aplikasi (tabel `users`).
class AppUser {
  const AppUser({
    this.id,
    required this.email,
    required this.passwordHash,
    required this.salt,
    required this.name,
    required this.gender,
    this.birthDate,
    this.height,
    this.weight,
    this.productionCode,
    required this.createdAt,
  });

  final int? id;
  final String email;
  final String passwordHash;
  final String salt;
  final String name;
  final String gender; // 'Laki-laki' | 'Perempuan'
  final DateTime? birthDate;
  final double? height;
  final double? weight;
  final String? productionCode;
  final DateTime createdAt;

  int? get age => birthDate == null ? null : DateFmt.ageFrom(birthDate!);

  Map<String, Object?> toMap() => {
        'id': id,
        'email': email,
        'password_hash': passwordHash,
        'salt': salt,
        'name': name,
        'gender': gender,
        'birth_date': birthDate?.toIso8601String(),
        'height': height,
        'weight': weight,
        'production_code': productionCode,
        'created_at': createdAt.toIso8601String(),
      };

  factory AppUser.fromMap(Map<String, Object?> m) => AppUser(
        id: m['id'] as int?,
        email: m['email'] as String,
        passwordHash: m['password_hash'] as String,
        salt: m['salt'] as String,
        name: m['name'] as String,
        gender: (m['gender'] as String?) ?? 'Perempuan',
        birthDate: m['birth_date'] == null ? null : DateTime.parse(m['birth_date'] as String),
        height: (m['height'] as num?)?.toDouble(),
        weight: (m['weight'] as num?)?.toDouble(),
        productionCode: m['production_code'] as String?,
        createdAt: DateTime.parse(m['created_at'] as String),
      );

  AppUser copyWith({
    String? name,
    String? gender,
    DateTime? birthDate,
    double? height,
    double? weight,
    String? productionCode,
  }) =>
      AppUser(
        id: id,
        email: email,
        passwordHash: passwordHash,
        salt: salt,
        name: name ?? this.name,
        gender: gender ?? this.gender,
        birthDate: birthDate ?? this.birthDate,
        height: height ?? this.height,
        weight: weight ?? this.weight,
        productionCode: productionCode ?? this.productionCode,
        createdAt: createdAt,
      );
}
