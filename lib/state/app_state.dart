import 'package:flutter/widgets.dart';

import '../data/mock_data.dart';

/// A gamification badge with a concrete unlock rule.
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

/// Global app state — auth, gamification, premium, referral, notifications.
/// In-memory only; wire to a backend/local store later.
class AppState extends ChangeNotifier {
  AppState._();
  static final AppState instance = AppState._();

  // ---- Auth ----
  bool isRegistered = false;

  // ---- Profile (editable) ----
  String name = Mock.me.name;
  int age = Mock.me.age;
  String gender = 'Female';
  String country = '🇫🇷 France';
  String city = Mock.me.city;
  String level = Mock.me.level; // CEFR
  bool isLearner = true;
  String bio = Mock.me.bio;
  List<String> interests = List.of(Mock.me.interests);

  // ---- Gamification (seeded with demo history) ----
  int totalXp = 1840;
  int totalCalls = 142;
  int streakDays = 23;
  Duration totalTalk = const Duration(hours: 41);
  final Set<String> countriesSpoken = {'USA', 'Spain', 'Korea', 'UK', 'Canada'};
  DateTime _lastCallDay = DateTime.now();

  static const _xpPerLevel = 220;
  int get gLevel => (totalXp ~/ _xpPerLevel) + 1;
  int get xpIntoLevel => totalXp % _xpPerLevel;
  int get xpForLevel => _xpPerLevel;
  double get levelProgress => xpIntoLevel / _xpPerLevel;

  /// Called when a call ends — drives the whole reward loop.
  /// Returns the XP earned so the UI can celebrate it.
  int recordCall({required String country, required int minutes}) {
    final xp = (minutes * 15).clamp(40, 400);
    totalXp += xp;
    totalCalls += 1;
    totalTalk += Duration(minutes: minutes);
    countriesSpoken.add(country.split(' ').last);

    // Streak: extend if the last call was on a previous day; reset if a day
    // was skipped.
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
    return xp;
  }

  // ---- Badges ----
  static final badges = <BadgeDef>[
    BadgeDef(id: 'first_call', emoji: '🎙', label: 'First call', category: 'Speaking', color: 0xFF45E07A, target: 1, howTo: 'Make your first call', progress: (s) => s.totalCalls),
    BadgeDef(id: 'talker', emoji: '💬', label: 'Talker', category: 'Speaking', color: 0xFF6C63FF, target: 10, howTo: 'Complete 10 calls', progress: (s) => s.totalCalls),
    BadgeDef(id: 'fifty', emoji: '🗣', label: '50 calls', category: 'Speaking', color: 0xFFFF6FB5, target: 50, howTo: 'Complete 50 calls', progress: (s) => s.totalCalls),
    BadgeDef(id: 'hundred', emoji: '🏆', label: '100 calls', category: 'Speaking', color: 0xFFFFD66B, target: 100, howTo: 'Complete 100 calls', progress: (s) => s.totalCalls),
    BadgeDef(id: 'streak7', emoji: '🔥', label: 'On fire', category: 'Streak', color: 0xFFFFB547, target: 7, howTo: 'Keep a 7-day streak', progress: (s) => s.streakDays),
    BadgeDef(id: 'streak30', emoji: '⚡', label: 'Unstoppable', category: 'Streak', color: 0xFFE89320, target: 30, howTo: 'Keep a 30-day streak', progress: (s) => s.streakDays),
    BadgeDef(id: 'countries5', emoji: '🌍', label: 'Globetrotter', category: 'Global', color: 0xFF3DD6E0, target: 5, howTo: 'Talk to people from 5 countries', progress: (s) => s.countriesSpoken.length),
    BadgeDef(id: 'countries10', emoji: '✈️', label: 'Worldwide', category: 'Global', color: 0xFFFFD66B, target: 10, howTo: 'Talk to people from 10 countries', progress: (s) => s.countriesSpoken.length),
    BadgeDef(id: 'level5', emoji: '⭐', label: 'Rising star', category: 'Level', color: 0xFF3DD6E0, target: 5, howTo: 'Reach level 5', progress: (s) => s.gLevel),
    BadgeDef(id: 'level10', emoji: '👑', label: 'Pro speaker', category: 'Level', color: 0xFFFFD66B, target: 10, howTo: 'Reach level 10', progress: (s) => s.gLevel),
  ];

  int get unlockedBadgeCount => badges.where((b) => b.unlocked(this)).length;

  // ---- Premium / subscription ----
  DateTime? premiumUntil;
  bool fromTrial = false;
  bool isSubscribed = false; // paid plan

  bool get isPremium =>
      isSubscribed ||
      (premiumUntil != null && premiumUntil!.isAfter(DateTime.now()));
  int get premiumDaysLeft => premiumUntil == null
      ? 0
      : premiumUntil!.difference(DateTime.now()).inDays.clamp(0, 9999);

  void startTrial() {
    fromTrial = true;
    _extendPremium(14);
  }

  void subscribe() {
    isSubscribed = true;
    notifyListeners();
  }

  void cancelSubscription() {
    isSubscribed = false;
    notifyListeners();
  }

  void _extendPremium(int days) {
    final base = (premiumUntil != null && premiumUntil!.isAfter(DateTime.now()))
        ? premiumUntil!
        : DateTime.now();
    premiumUntil = base.add(Duration(days: days));
    notifyListeners();
  }

  // ---- Referral ----
  final String referralCode = 'CHLOE7K2';
  int invitedFriends = 0;
  int referralPremiumDays = 0;
  static const referralRewardDays = 10;

  /// Each accepted invite grants 10 days of premium.
  void redeemInvite() {
    invitedFriends += 1;
    referralPremiumDays += referralRewardDays;
    _extendPremium(referralRewardDays);
  }

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

  void toggleNotification(String key, bool value) {
    notifications[key] = value;
    notifyListeners();
  }

  // ---- Mutations ----
  void register() {
    isRegistered = true;
    notifyListeners();
  }

  void saveProfile({
    required String name,
    required int age,
    required String gender,
    required String country,
    required String city,
    required String level,
    required bool isLearner,
    required String bio,
  }) {
    this.name = name;
    this.age = age;
    this.gender = gender;
    this.country = country;
    this.city = city;
    this.level = level;
    this.isLearner = isLearner;
    this.bio = bio;
    notifyListeners();
  }
}
