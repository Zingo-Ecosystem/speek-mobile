import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Holds the authenticated session: the JWT access token, refresh token and the
/// signed-in user id. Persists the tokens in secure storage so the user stays
/// logged in across launches.
class Session {
  Session._();
  static final Session instance = Session._();

  static const _kAccess = 'speek_access_token';
  static const _kRefresh = 'speek_refresh_token';
  static const _kUserId = 'speek_user_id';

  final _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  String? _accessToken;
  String? _userId;

  String? get accessToken => _accessToken;
  String? get userId => _userId;
  bool get isAuthenticated => _accessToken != null && _accessToken!.isNotEmpty;

  /// Loads any persisted session into memory. Call once on startup.
  Future<void> load() async {
    try {
      _accessToken = await _storage.read(key: _kAccess);
      _userId = await _storage.read(key: _kUserId);
    } catch (_) {
      _accessToken = null;
      _userId = null;
    }
  }

  Future<void> save({
    required String accessToken,
    required String refreshToken,
    required String userId,
  }) async {
    _accessToken = accessToken;
    _userId = userId;
    try {
      await _storage.write(key: _kAccess, value: accessToken);
      await _storage.write(key: _kRefresh, value: refreshToken);
      await _storage.write(key: _kUserId, value: userId);
    } catch (_) {
      // In-memory session still works even if disk write fails.
    }
  }

  Future<void> clear() async {
    _accessToken = null;
    _userId = null;
    try {
      await _storage.delete(key: _kAccess);
      await _storage.delete(key: _kRefresh);
      await _storage.delete(key: _kUserId);
    } catch (_) {}
  }
}
