/// Profil pasien yang bisa dipilih di "Ganti Akun" / "Pilih Pasien".
/// Setiap user punya satu profil "Pemilik Akun" dan bisa menambah profil lain,
/// termasuk akun dari API eksternal (dummyjson) lewat halaman Ganti Akun.
class Profile {
  const Profile({
    this.id,
    required this.ownerId,
    required this.name,
    required this.relation,
    required this.gender,
    this.age,
    this.colorIndex = 0,
    this.remoteId,
    this.email,
  });

  static const owner = 'Pemilik Akun';

  final int? id;
  final int ownerId;
  final String name;
  final String relation; // Pemilik Akun, Anak, Saudara, Dokter, Lainnya
  final String gender;
  final int? age;
  final int colorIndex;
  final int? remoteId; // id dummyjson bila berasal dari API
  final String? email;

  bool get isOwner => relation == owner;

  String get initials {
    final parts = name.trim().split(RegExp(r'\s+')).where((e) => e.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first.substring(0, parts.first.length >= 2 ? 2 : 1).toUpperCase();
    return (parts[0][0] + parts[1][0]).toUpperCase();
  }

  String get subtitle => [relation, gender, if (age != null) '$age tahun'].join(' · ');

  Map<String, Object?> toMap() => {
        'id': id,
        'owner_id': ownerId,
        'name': name,
        'relation': relation,
        'gender': gender,
        'age': age,
        'color_index': colorIndex,
        'remote_id': remoteId,
        'email': email,
      };

  factory Profile.fromMap(Map<String, Object?> m) => Profile(
        id: m['id'] as int?,
        ownerId: m['owner_id'] as int,
        name: m['name'] as String,
        relation: m['relation'] as String,
        gender: (m['gender'] as String?) ?? '-',
        age: m['age'] as int?,
        colorIndex: (m['color_index'] as int?) ?? 0,
        remoteId: m['remote_id'] as int?,
        email: m['email'] as String?,
      );

  Profile copyWith({String? name, String? gender, int? age}) => Profile(
        id: id,
        ownerId: ownerId,
        name: name ?? this.name,
        relation: relation,
        gender: gender ?? this.gender,
        age: age ?? this.age,
        colorIndex: colorIndex,
        remoteId: remoteId,
        email: email,
      );
}
