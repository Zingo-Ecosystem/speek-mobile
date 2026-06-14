# Speek · Mobile (Flutter)

Dark-premium speaking + social-map app. Built to match `ui-ux design/speek-screens.html`.

## Run
```bash
cd mobile
flutter pub get
flutter run
```

## Navigation (MVP)
Bottom navbar: **Chats · Map · Profile**

Flow: Splash → Onboarding (3 slides) → Sign up → Create account (4 steps) → Trial started → App shell.

## Structure
```
lib/
  theme/        design tokens — colors, typography, spacing (from tokens.json)
  models/       SpeekUser, Chat, Message, Badge, CountryCluster
  data/         mock_data.dart — demo content (replace with backend)
  state/        app_state.dart — auth / trial flags (replace with real store)
  widgets/      reusable UI — buttons, chips, avatar, badges, brand mark
  screens/
    onboarding/ splash, onboarding, signup, create account, trial
    map/        3-scope map (world counts -> city clusters -> user pins), preview & register gate
    call/       incoming, voice, video, call-ended (XP + rating)
    chat/       chat list (online row + requests), conversation (voice notes, in-chat call)
    profile/    profile (streak/XP/badges), badge gallery
    subscription/ paywall (plans), manage subscription
```

## Notes for backend integration
- `Mock` in `data/mock_data.dart` is the single source of demo data — swap each list for API calls.
- `AppState` holds `isRegistered` / `isPremiumTrial`; wire these to real auth + RevenueCat/StoreKit.
- Map is a stylized hand-drawn `CustomPainter`. For production swap in Mapbox/Google Maps with a dark
  style and avatar markers (positions already modeled as `mapX`/`mapY` fractions).
- Avatars use Unsplash placeholder URLs via `cached_network_image`.
