import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';

/// Password tidak pernah disimpan apa adanya di SQLite.
/// Disimpan sebagai SHA-256(salt + password) dengan salt acak per user.
class PasswordHasher {
  PasswordHasher._();

  static String newSalt([int length = 16]) {
    final r = Random.secure();
    final bytes = List<int>.generate(length, (_) => r.nextInt(256));
    return base64UrlEncode(bytes);
  }

  static String hash(String password, String salt) {
    final bytes = utf8.encode('$salt::$password');
    return sha256.convert(bytes).toString();
  }

  static bool verify(String password, String salt, String expectedHash) => hash(password, salt) == expectedHash;
}
