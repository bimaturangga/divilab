/// User dari API eksternal https://dummyjson.com/users
class RemoteUser {
  const RemoteUser({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.username,
    required this.email,
    required this.phone,
    required this.gender,
    required this.age,
    required this.birthDate,
    required this.bloodGroup,
    required this.height,
    required this.weight,
    required this.image,
    required this.city,
    required this.address,
    required this.companyTitle,
    required this.companyName,
  });

  final int id;
  final String firstName;
  final String lastName;
  final String username;
  final String email;
  final String phone;
  final String gender; // male | female
  final int age;
  final String birthDate;
  final String bloodGroup;
  final double height;
  final double weight;
  final String image;
  final String city;
  final String address;
  final String companyTitle;
  final String companyName;

  String get fullName => '$firstName $lastName'.trim();
  String get genderLabel => gender == 'male' ? 'Laki-laki' : 'Perempuan';
  String get initials =>
      ((firstName.isNotEmpty ? firstName[0] : '') + (lastName.isNotEmpty ? lastName[0] : '')).toUpperCase();

  double? get bmi {
    if (height <= 0) return null;
    final m = height / 100;
    return weight / (m * m);
  }

  factory RemoteUser.fromJson(Map<String, dynamic> j) {
    final addr = (j['address'] as Map<String, dynamic>?) ?? const {};
    final comp = (j['company'] as Map<String, dynamic>?) ?? const {};
    return RemoteUser(
      id: (j['id'] as num).toInt(),
      firstName: (j['firstName'] ?? '') as String,
      lastName: (j['lastName'] ?? '') as String,
      username: (j['username'] ?? '') as String,
      email: (j['email'] ?? '') as String,
      phone: (j['phone'] ?? '') as String,
      gender: (j['gender'] ?? '') as String,
      age: ((j['age'] ?? 0) as num).toInt(),
      birthDate: (j['birthDate'] ?? '') as String,
      bloodGroup: (j['bloodGroup'] ?? '-') as String,
      height: ((j['height'] ?? 0) as num).toDouble(),
      weight: ((j['weight'] ?? 0) as num).toDouble(),
      image: (j['image'] ?? '') as String,
      city: (addr['city'] ?? '') as String,
      address: [addr['address'], addr['city'], addr['state']].whereType<String>().where((e) => e.isNotEmpty).join(', '),
      companyTitle: (comp['title'] ?? '') as String,
      companyName: (comp['name'] ?? '') as String,
    );
  }
}

class RemoteUserPage {
  const RemoteUserPage({required this.users, required this.total, required this.skip});
  final List<RemoteUser> users;
  final int total;
  final int skip;
}
