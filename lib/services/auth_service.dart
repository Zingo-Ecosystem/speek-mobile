import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

import '../config/app_config.dart';
import '../core/api_client.dart';
import '../core/api_exception.dart';
import '../core/session.dart';
import '../models/models.dart';

/// Result of a successful social login.
class AuthResult {
  final SpeekUser user;
  final bool isNewUser;
  AuthResult(this.user, this.isNewUser);
}

/// Drives Google / Apple sign-in and exchanges the identity token for a Speek
/// JWT via `POST /api/Auth/social-login`.
class AuthService {
  AuthService._();
  static final AuthService instance = AuthService._();

  final _api = ApiClient.instance;

  bool get googleEnabled => AppConfig.hasGoogleAuth;

  /// Google → backend. Throws [ApiException] with a friendly message on failure.
  Future<AuthResult> signInWithGoogle({String? referralCode}) async {
    if (!AppConfig.hasGoogleAuth) {
      throw ApiException(0,
          'Google sign-in is not configured yet. Add your Google Web client ID to AppConfig.googleServerClientId.',
          code: 'config');
    }

    final google = GoogleSignIn(
      serverClientId: AppConfig.googleServerClientId,
      scopes: const ['email', 'profile'],
    );

    try {
      await google.signOut();
    } catch (_) {}

    final account = await google.signIn();
    if (account == null) {
      throw ApiException(0, 'Sign-in cancelled.', code: 'cancelled');
    }
    final auth = await account.authentication;
    final idToken = auth.idToken;
    if (idToken == null || idToken.isEmpty) {
      throw ApiException(0, 'Could not get a Google identity token.', code: 'no_token');
    }
    return _exchange(provider: 0, idToken: idToken, referralCode: referralCode);
  }

  /// Apple → backend.
  Future<AuthResult> signInWithApple({String? referralCode}) async {
    final cred = await SignInWithApple.getAppleIDCredential(
      scopes: const [
        AppleIDAuthorizationScopes.email,
        AppleIDAuthorizationScopes.fullName,
      ],
    );
    final idToken = cred.identityToken;
    if (idToken == null || idToken.isEmpty) {
      throw ApiException(0, 'Could not get an Apple identity token.', code: 'no_token');
    }
    return _exchange(provider: 1, idToken: idToken, referralCode: referralCode);
  }

  Future<AuthResult> _exchange({
    required int provider,
    required String idToken,
    String? referralCode,
  }) async {
    final j = await _api.post('/Auth/social-login', body: {
      'provider': provider,
      'idToken': idToken,
      'referralCode': referralCode,
    });
    final map = (j as Map).cast<String, dynamic>();
    final user = SpeekUser.fromJson((map['user'] as Map).cast());
    await Session.instance.save(
      accessToken: '${map['accessToken']}',
      refreshToken: '${map['refreshToken'] ?? ''}',
      userId: user.id,
    );
    return AuthResult(user, map['isNewUser'] == true);
  }

  Future<void> signOut() async {
    try {
      await GoogleSignIn().signOut();
    } catch (_) {}
    await Session.instance.clear();
  }
}
