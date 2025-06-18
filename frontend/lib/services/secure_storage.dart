// frontend/lib/services/secure_storage.dart
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorage {
  final _storage = const FlutterSecureStorage();

  static const String _keyJwtToken = 'jwt_token';

  Future<void> saveJwtToken(String token) async {
    await _storage.write(key: _keyJwtToken, value: token);
  }

  Future<String?> getJwtToken() async {
    return await _storage.read(key: _keyJwtToken);
  }

  Future<void> deleteJwtToken() async {
    await _storage.delete(key: _keyJwtToken);
  }
}