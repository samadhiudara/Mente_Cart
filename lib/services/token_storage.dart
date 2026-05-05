import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class TokenStorage {
  static const _tokenKey = 'auth_token';
  final FlutterSecureStorage _storage;

  TokenStorage(this._storage);

  Future<void> saveToken(String token) =>
      _storage.write(key: _tokenKey, value: token);

  Future<String?> getToken() => _storage.read(key: _tokenKey);

  Future<void> clearToken() => _storage.delete(key: _tokenKey);
}
