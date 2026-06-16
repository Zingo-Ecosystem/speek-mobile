/// Central runtime configuration for the Speek app.
///
/// Everything environment-specific lives here so the rest of the codebase never
/// hard-codes a URL or a key. Values can be overridden at build time with
/// `--dart-define`, e.g.
///
///   flutter build apk --dart-define=GOOGLE_SERVER_CLIENT_ID=xxxx.apps.googleusercontent.com
///
class AppConfig {
  AppConfig._();

  /// Base URL of the deployed Speek API (no trailing slash).
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://new.munosabatai.uz',
  );

  /// REST root.
  static String get apiRoot => '$apiBaseUrl/api';

  /// SignalR realtime hub.
  static String get realtimeHubUrl => '$apiBaseUrl/hubs/realtime';

  /// OAuth 2.0 **Web** client ID from Google Cloud, used as `serverClientId`
  /// so `google_sign_in` returns an `idToken` the backend can verify.
  ///
  /// Drop yours in here (or pass `--dart-define=GOOGLE_SERVER_CLIENT_ID=...`).
  /// Until it is set, Google sign-in is disabled gracefully and the UI tells
  /// the user instead of crashing.
  static const String googleServerClientId = String.fromEnvironment(
    'GOOGLE_SERVER_CLIENT_ID',
    defaultValue:
        '40470320500-ap0qctevqt33q6mgfmpa9uin4kii5cnr.apps.googleusercontent.com',
  );

  static bool get hasGoogleAuth => googleServerClientId.isNotEmpty;

  /// Network timeout for REST calls.
  static const Duration httpTimeout = Duration(seconds: 20);

  /// How often to push a presence heartbeat to the map while online.
  static const Duration heartbeatInterval = Duration(seconds: 30);
}
