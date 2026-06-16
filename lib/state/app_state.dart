import 'dart:async';

import 'package:flutter/widgets.dart';

import '../core/api_exception.dart';
import '../core/session.dart';
import '../data/dto.dart';
import '../data/repositories.dart';
import '../models/models.dart';
import '../realtime/realtime_service.dart';
import '../services/auth_service.dart';

/// A gamification badge with a concrete unlock rule (mirrors the server catalog
/// but lets the profile render progress locally between refreshes).
class BadgeDef {
  final String id;
  final String emoji;
  final String label;
  final String category; // Speaking | Streak | Global | Level
  final String howTo;
  final int color;
  final int target;
  final int Function(AppState s) progress;

  const BadgeDef({
    required this.id,
    required this.emoji,
    required this.label,
    required this.category,
    required this.howTo,
    required this.color,
    required this.target,
    required this.progress,
  });

  bool unlocked(AppState s) => progress(s) >= target;
  double ratio(AppState s) => (progress(s) / target).clamp(0, 1).toDouble();
}

/// Global app state — now backed by the Speek API. Screens keep using the same
/// fields/getters; this class hydrates them from the backend on login and
/// pushes mutations back to the server.
class AppState extends ChangeNotifier {
  AppState._();
  static final AppState instance = AppState._();

  // ---- Auth / current user ----
  bool isRegistered = false;
  bool isOnboarded = false;
  SpeekUser? currentUser;

  String get myUserId => Session.instance.userId ?? '';

  // ---- Profile (editable) ----
  String name = 'Speeker';
  int age = 24;
  String gender = 'Female';
  String country = '🇫🇷 France'; // "<flag> <name>" for the UI pickers
  String countryCode = '';
  String city = '';
  String level = 'B1'; // CEFR
  bool isLearner = true;
  String bio = '';
  List<String> interests = const [];

  /// Photos uploaded during the onboarding wizard (first = main avatar).
  final List<String> onboardingPhotoUrls = [];

  String get flag => country.split(' ').first;
  String get photoUrl =>
      currentUser?.photoUrl.isNotEmpty == true ? currentUser!.photoUrl : '';

  // ---- Gamification ----
  int totalXp = 0;
  int totalCalls = 0;
  int streakDays = 0;
  Duration totalTalk = Duration.zero;
  int _serverCountriesSpoken = 0;
  final Set<String> countriesSpoken = {};
  List<BadgeProgress> serverBadges = const [];
  DateTime _lastCallDay = DateTime.fromMillisecondsSinceEpoch(0);

  int get countriesSpokenCount =>
      countriesSpoken.length > _serverCountriesSpoken
          ? countriesSpoken.length
          : _serverCountriesSpoken;

  static const _xpPerLevel = 220;
  int get gLevel => (totalXp ~/ _xpPerLevel) + 1;
  int get xpIntoLevel => totalXp % _xpPerLevel;
  int get xpForLevel => _xpPerLevel;
  double get levelProgress => xpIntoLevel / _xpPerLevel;

  // ---- Premium / subscription ----
  DateTime? premiumUntil;
  bool fromTrial = false;
  bool isSubscribed = false;

  bool get isPremium =>
      isSubscribed ||
      (premiumUntil != null && premiumUntil!.isAfter(DateTime.now()));
  int get premiumDaysLeft => premiumUntil == null
      ? 0
      : premiumUntil!.difference(DateTime.now()).inDays.clamp(0, 9999);

  // ---- Referral ----
  String referralCode = '—';
  int invitedFriends = 0;
  int referralPremiumDays = 0;
  static const referralRewardDays = 10;

  // ---- Notification settings ----
  final Map<String, bool> notifications = {
    'messages': true,
    'requests': true,
    'calls': true,
    'missed': true,
    'likes': true,
    'streak': true,
    'badges': true,
    'promos': false,
  };

  // =========================================================================
  // Lifecycle
  // =========================================================================

  /// Called at startup. Returns true if a valid session was restored.
  Future<bool> bootstrap() async {
    await Session.instance.load();
    if (!Session.instance.isAuthenticated) return false;
    try {
      await hydrate();
      isRegistered = true;
      RealtimeService.instance.connect();
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Stores the result of a social login and hydrates everything.
  Future<void> applyAuth(AuthResult res) async {
    currentUser = res.user;
    isRegistered = true;
    isOnboarded = res.user.isOnboarded;
    _applyUser(res.user);
    RealtimeService.instance.connect();
    await hydrate();
  }

  /// Pulls profile, gamification, subscription, referral and notification
  /// preferences from the API in parallel.
  Future<void> hydrate() async {
    final results = await Future.wait([
      Repos.profile.me().then<Object?>((v) => v).catchError((_) => null),
      Repos.gamification.get().then<Object?>((v) => v).catchError((_) => null),
      Repos.subscription.get().then<Object?>((v) => v).catchError((_) => null),
      Repos.subscription.referral().then<Object?>((v) => v).catchError((_) => null),
      Repos.notifications.preferences().then<Object?>((v) => v).catchError((_) => null),
    ]);

    if (results[0] is SpeekUser) {
      currentUser = results[0] as SpeekUser;
      isOnboarded = currentUser!.isOnboarded;
      _applyUser(currentUser!);
    }
    if (results[1] is GamificationData) _applyGamification(results[1] as GamificationData);
    if (results[2] is SubscriptionData) _applySubscription(results[2] as SubscriptionData);
    if (results[3] is ReferralData) _applyReferral(results[3] as ReferralData);
    if (results[4] is Map<String, bool>) {
      final prefs = results[4] as Map<String, bool>;
      if (prefs.isNotEmpty) {
        prefs.forEach((k, v) => notifications[k] = v);
      }
    }
    notifyListeners();
  }

  Future<void> logout() async {
    await RealtimeService.instance.disconnect();
    try {
      await Repos.map.offline();
    } catch (_) {}
    await AuthService.instance.signOut();
    isRegistered = false;
    isOnboarded = false;
    currentUser = null;
    notifyListeners();
  }

  // =========================================================================
  // Appliers
  // =========================================================================

  void _applyUser(SpeekUser u) {
    name = u.name;
    age = u.age;
    city = u.city;
    bio = u.bio;
    level = u.level.isNotEmpty ? u.level : level;
    isLearner = u.role == SpeakerRole.learner;
    interests = u.interests;
    countryCode = '';
    if (u.flag.isNotEmpty || u.country.isNotEmpty) {
      country = '${u.flag} ${u.country}'.trim();
    }
  }

  void _applyGamification(GamificationData g) {
    totalXp = g.totalXp;
    totalCalls = g.totalCalls;
    streakDays = g.streakDays;
    totalTalk = Duration(seconds: g.totalTalkSeconds);
    _serverCountriesSpoken = g.countriesSpoken;
    serverBadges = g.badges;
  }

  void _applySubscription(SubscriptionData s) {
    isSubscribed = s.isSubscribed;
    fromTrial = s.fromTrial;
    premiumUntil = s.premiumUntil;
  }

  void _applyReferral(ReferralData r) {
    referralCode = r.code;
    invitedFriends = r.invitedFriends;
    referralPremiumDays = r.rewardDaysGranted;
  }

  // =========================================================================
  // Badges
  // =========================================================================
  static final badges = <BadgeDef>[
    BadgeDef(id: 'first_call', emoji: '🎙', label: 'First call', category: 'Speaking', color: 0xFF45E07A, target: 1, howTo: 'Make your first call', progress: (s) => s.totalCalls),
    BadgeDef(id: 'talker', emoji: '💬', label: 'Talker', category: 'Speaking', color: 0xFF6C63FF, target: 10, howTo: 'Complete 10 calls', progress: (s) => s.totalCalls),
    BadgeDef(id: 'fifty', emoji: '🗣', label: '50 calls', category: 'Speaking', color: 0xFFFF6FB5, target: 50, howTo: 'Complete 50 calls', progress: (s) => s.totalCalls),
    BadgeDef(id: 'hundred', emoji: '🏆', label: '100 calls', category: 'Speaking', color: 0xFFFFD66B, target: 100, howTo: 'Complete 100 calls', progress: (s) => s.totalCalls),
    BadgeDef(id: 'streak7', emoji: '🔥', label: 'On fire', category: 'Streak', color: 0xFFFFB547, target: 7, howTo: 'Keep a 7-day streak', progress: (s) => s.streakDays),
    BadgeDef(id: 'streak30', emoji: '⚡', label: 'Unstoppable', category: 'Streak', color: 0xFFE89320, target: 30, howTo: 'Keep a 30-day streak', progress: (s) => s.streakDays),
    BadgeDef(id: 'countries5', emoji: '🌍', label: 'Globetrotter', category: 'Global', color: 0xFF3DD6E0, target: 5, howTo: 'Talk to people from 5 countries', progress: (s) => s.countriesSpokenCount),
    BadgeDef(id: 'countries10', emoji: '✈️', label: 'Worldwide', category: 'Global', color: 0xFFFFD66B, target: 10, howTo: 'Talk to people from 10 countries', progress: (s) => s.countriesSpokenCount),
    BadgeDef(id: 'level5', emoji: '⭐', label: 'Rising star', category: 'Level', color: 0xFF3DD6E0, target: 5, howTo: 'Reach level 5', progress: (s) => s.gLevel),
    BadgeDef(id: 'level10', emoji: '👑', label: 'Pro speaker', category: 'Level', color: 0xFFFFD66B, target: 10, howTo: 'Reach level 10', progress: (s) => s.gLevel),
  ];

  int get unlockedBadgeCount => badges.where((b) => b.unlocked(this)).length;

  // =========================================================================
  // Mutations
  // =========================================================================

  void register() {
    isRegistered = true;
    notifyListeners();
  }

  /// Optimistic local update after a call ends, then refresh from the server
  /// (the backend awards XP authoritatively on `Calls/{id}/end`).
  int recordCall({required String country, required int minutes}) {
    final xp = (minutes * 15).clamp(40, 400);
    totalXp += xp;
    totalCalls += 1;
    totalTalk += Duration(minutes: minutes);
    countriesSpoken.add(country.split(' ').last);

    final today = DateTime.now();
    final last = _lastCallDay;
    final dayGap = DateTime(today.year, today.month, today.day)
        .difference(DateTime(last.year, last.month, last.day))
        .inDays;
    if (dayGap == 1) {
      streakDays += 1;
    } else if (dayGap > 1) {
      streakDays = 1;
    }
    _lastCallDay = today;
    notifyListeners();

    // Reconcile with the server in the background.
    Repos.gamification.get().then((g) {
      _applyGamification(g);
      notifyListeners();
    }).catchError((_) {});

    return xp;
  }

  /// Persists profile edits to the backend.
  Future<void> saveProfile({
    required String name,
    required int age,
    required String gender,
    required String country,
    required String city,
    required String level,
    required bool isLearner,
    required String bio,
  }) async {
    this.name = name;
    this.age = age;
    this.gender = gender;
    this.country = country;
    this.city = city;
    this.level = level;
    this.isLearner = isLearner;
    this.bio = bio;
    notifyListeners();

    final parts = country.trim().split(' ');
    final f = parts.isNotEmpty ? parts.first : '';
    final cName = parts.length > 1 ? parts.sublist(1).join(' ') : country;
    try {
      final updated = await Repos.profile.update(
        name: name,
        age: age,
        gender: gender,
        countryCode: countryCode,
        countryName: cName,
        flag: f,
        city: city,
        role: isLearner ? SpeakerRole.learner : SpeakerRole.native,
        englishLevel: level,
        bio: bio,
      );
      currentUser = updated;
      notifyListeners();
    } catch (_) {
      // Local edit stays; surfaced by the caller if needed.
    }
  }

  /// Uploads a photo during onboarding (no profile set yet). Returns the hosted
  /// URL on success, or throws — the caller surfaces the error.
  Future<String> uploadOnboardingPhoto(String filePath) =>
      Repos.profile.uploadImage(filePath);

  /// Uploads a picked image and sets it as the avatar.
  /// Returns null on success, or a human-readable error message.
  Future<String?> updatePhoto(String filePath) async {
    try {
      final url = await Repos.profile.uploadImage(filePath);
      if (url.isEmpty) return 'Upload returned no URL.';
      currentUser = await Repos.profile.setPhoto(url);
      notifyListeners();
      return null;
    } on ApiException catch (e) {
      return e.message;
    } catch (e) {
      return 'Upload failed: $e';
    }
  }

  // ---- Subscription ----
  Future<void> refreshSubscription() async {
    try {
      _applySubscription(await Repos.subscription.get());
      notifyListeners();
    } catch (_) {}
  }

  /// Validates a store purchase with the backend. [store]: SubscriptionSource
  /// (AppStore=2, PlayStore=3). Falls back to a local grant if the call fails.
  Future<void> validatePurchase({
    required int store,
    required String productId,
    required String receiptData,
  }) async {
    try {
      final sub = await Repos.subscription.validatePurchase(
        store: store,
        productId: productId,
        receiptData: receiptData,
      );
      _applySubscription(sub);
    } catch (_) {
      isSubscribed = true; // optimistic local fallback
    }
    notifyListeners();
  }

  void subscribe() {
    isSubscribed = true;
    notifyListeners();
  }

  Future<void> cancelSubscription() async {
    isSubscribed = false;
    notifyListeners();
    try {
      await Repos.subscription.cancel();
      await refreshSubscription();
    } catch (_) {}
  }

  void startTrial() {
    fromTrial = true;
    final base = (premiumUntil != null && premiumUntil!.isAfter(DateTime.now()))
        ? premiumUntil!
        : DateTime.now();
    premiumUntil = base.add(const Duration(days: 14));
    notifyListeners();
  }

  // ---- Referral ----
  Future<void> refreshReferral() async {
    try {
      _applyReferral(await Repos.subscription.referral());
      notifyListeners();
    } catch (_) {}
  }

  /// Local demo helper retained for the "simulate a friend" button.
  void redeemInvite() {
    invitedFriends += 1;
    referralPremiumDays += referralRewardDays;
    final base = (premiumUntil != null && premiumUntil!.isAfter(DateTime.now()))
        ? premiumUntil!
        : DateTime.now();
    premiumUntil = base.add(const Duration(days: referralRewardDays));
    notifyListeners();
  }

  // ---- Notifications ----
  void toggleNotification(String key, bool value) {
    notifications[key] = value;
    notifyListeners();
    Repos.notifications.setPreference(key, value).catchError((_) {});
  }
}
