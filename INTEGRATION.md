# Speek mobile ↔ backend integration

The app is wired to the live API at **https://new.munosabatai.uz**. All screens
read/write real data; mock data only remains as a visual fallback when offline.

## Architecture (added)

```
lib/
  config/app_config.dart        # base URL + Google client ID (env-overridable)
  core/
    api_client.dart             # http client, bearer auth, error envelope parsing
    session.dart                # JWT persisted in flutter_secure_storage
    api_exception.dart
  data/
    api_enums.dart              # int<->enum mapping (mirrors Speek.Domain.Enums)
    dto.dart                    # Gamification/Subscription/Referral/Notification/Call DTOs
    repositories.dart           # one repository per controller (Repos.*)
  realtime/realtime_service.dart# SignalR /hubs/realtime (message/call/notification/typing)
  services/
    auth_service.dart           # Google/Apple sign-in -> /Auth/social-login
    call_service.dart           # LiveKit connect/teardown + call lifecycle
  state/app_state.dart          # API-backed; hydrate() pulls everything on login
```

Every endpoint from Swagger is covered: Auth, Profile (me/update/onboarding/by-id),
Map (heartbeat/offline/nearby/clusters), Chat (conversations/messages/send/read),
Calls (start/accept/decline/cancel/end), Gamification, Subscription
(get/validate-purchase/cancel), referral, Notifications (prefs/devices/list/read).

## What YOU need to configure (keys)

### 1. Google Sign-In (required for login)
The backend verifies a Google **ID token**. To get one on Android you need an
OAuth client in Google Cloud:

1. Create an **OAuth client ID → Web application** → copy its client ID.
2. Create an **OAuth client ID → Android**: package `com.speek.speek`, plus the
   SHA-1 of your signing key (`keytool -list -v -keystore <keystore>` or, for the
   bundled debug key, `~/.android/debug.keystore`, password `android`).
3. Put the **Web** client ID into the app, either:
   - edit `lib/config/app_config.dart` → `googleServerClientId`, or
   - build with `--dart-define=GOOGLE_SERVER_CLIENT_ID=xxxx.apps.googleusercontent.com`

Until this is set, the Google button shows a friendly "not configured" message
instead of crashing. (Backend `Auth:Google:ClientIds` is empty, so it accepts any
validly-signed Google token — no extra backend change needed for Google.)

### 2. Apple Sign-In (optional, iOS)
Configure Sign in with Apple capability + set `Auth:Apple:ClientIds` on the backend.

### 3. LiveKit (voice/video media)
Calls connect automatically using the `MediaServerUrl`/`MediaToken` the backend
returns from `POST /Calls`. Make sure the backend `LiveKit:Url` points at a
reachable LiveKit host. If it's unreachable the call screen still works as
signaling-only (no crash).

### 4. In-app purchases (premium)
Set product IDs `speek_premium_monthly` / `speek_premium_yearly` in Play Console.
Purchases are validated server-side via `POST /Subscription/validate-purchase`.

## Build

```
flutter build apk --release \
  --dart-define=GOOGLE_SERVER_CLIENT_ID=<your-web-client-id>
```

APK output: `build/app/outputs/flutter-apk/app-release.apk`
