import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

abstract interface class SessionStore {
  Future<void> save(Map<String, dynamic> session);

  Future<Map<String, dynamic>?> read();

  Future<void> clear();
}

class SecureSessionStore implements SessionStore {
  SecureSessionStore({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  static const _key = 'truereport.session';

  final FlutterSecureStorage _storage;

  @override
  Future<void> save(Map<String, dynamic> session) {
    return _storage.write(key: _key, value: jsonEncode(session));
  }

  @override
  Future<Map<String, dynamic>?> read() async {
    final value = await _storage.read(key: _key);
    if (value == null || value.isEmpty) {
      return null;
    }
    return jsonDecode(value) as Map<String, dynamic>;
  }

  @override
  Future<void> clear() => _storage.delete(key: _key);
}
