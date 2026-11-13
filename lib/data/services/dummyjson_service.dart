import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../../core/config.dart';
import '../models/remote_user.dart';

class ApiException implements Exception {
  const ApiException(this.message, {this.detail});
  final String message;
  final String? detail;
  @override
  String toString() => detail == null ? message : '$message ($detail)';
}

/// Mengambil daftar akun dari API eksternal https://dummyjson.com/users
/// (dipakai di halaman Ganti Akun).
class DummyJsonService {
  DummyJsonService({http.Client? client}) : _client = client ?? http.Client();
  final http.Client _client;

  static const pageSize = 20;

  Future<RemoteUserPage> fetchUsers({int skip = 0, int limit = pageSize, String query = ''}) async {
    final q = query.trim();
    final uri = Uri.parse('${AppConfig.dummyJsonBaseUrl}${q.isEmpty ? '/users' : '/users/search'}').replace(
      queryParameters: {
        'limit': '$limit',
        'skip': '$skip',
        if (q.isNotEmpty) 'q': q,
      },
    );
    final json = await _get(uri);
    final users = (json['users'] as List<dynamic>)
        .cast<Map<String, dynamic>>()
        .map(RemoteUser.fromJson)
        .toList();
    return RemoteUserPage(
      users: users,
      total: (json['total'] as num?)?.toInt() ?? users.length,
      skip: (json['skip'] as num?)?.toInt() ?? skip,
    );
  }

  Future<RemoteUser> fetchUser(int id) async {
    final json = await _get(Uri.parse('${AppConfig.dummyJsonBaseUrl}/users/$id'));
    return RemoteUser.fromJson(json);
  }

  Future<Map<String, dynamic>> _get(Uri uri) async {
    try {
      final res = await _client
          .get(uri, headers: const {'Accept': 'application/json'})
          .timeout(const Duration(seconds: 15));
      if (res.statusCode != 200) {
        throw ApiException('Server mengembalikan kode ${res.statusCode}');
      }
      return jsonDecode(res.body) as Map<String, dynamic>;
    } on SocketException catch (e) {
      throw ApiException('Tidak ada koneksi internet', detail: 'SocketException: ${e.message}');
    } on TimeoutException {
      throw const ApiException('Koneksi ke server terlalu lama');
    } on http.ClientException catch (e) {
      throw ApiException('Gagal terhubung ke server', detail: e.message);
    } on FormatException {
      throw const ApiException('Format data dari server tidak valid');
    }
  }
}
