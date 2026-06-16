int _i(dynamic v, [int f = 0]) => v is num ? v.toInt() : f;
double _d(dynamic v, [double f = 0]) => v is num ? v.toDouble() : f;
String _s(dynamic v, [String f = '']) => v == null ? f : '$v';

/// Mirrors `GamificationDto`.
class GamificationData {
  final int totalXp, level, xpIntoLevel, xpForLevel;
  final double levelProgress;
  final int totalCalls, streakDays, countriesSpoken, unlockedBadgeCount;
  final int totalTalkSeconds;
  final List<BadgeProgress> badges;

  GamificationData({
    required this.totalXp,
    required this.level,
    required this.xpIntoLevel,
    required this.xpForLevel,
    required this.levelProgress,
    required this.totalCalls,
    required this.streakDays,
    required this.countriesSpoken,
    required this.unlockedBadgeCount,
    required this.totalTalkSeconds,
    required this.badges,
  });

  factory GamificationData.fromJson(Map<String, dynamic> j) => GamificationData(
        totalXp: _i(j['totalXp']),
        level: _i(j['level'], 1),
        xpIntoLevel: _i(j['xpIntoLevel']),
        xpForLevel: _i(j['xpForLevel'], 220),
        levelProgress: _d(j['levelProgress']),
        totalCalls: _i(j['totalCalls']),
        streakDays: _i(j['streakDays']),
        countriesSpoken: _i(j['countriesSpoken']),
        unlockedBadgeCount: _i(j['unlockedBadgeCount']),
        totalTalkSeconds: _i(j['totalTalkSeconds']),
        badges: (j['badges'] as List?)
                ?.map((e) => BadgeProgress.fromJson((e as Map).cast()))
                .toList() ??
            const [],
      );
}

/// Mirrors `BadgeDto`.
class BadgeProgress {
  final String id, emoji, label, category, howTo;
  final int target, progress;
  final double ratio;
  final bool unlocked;

  BadgeProgress({
    required this.id,
    required this.emoji,
    required this.label,
    required this.category,
    required this.howTo,
    required this.target,
    required this.progress,
    required this.ratio,
    required this.unlocked,
  });

  factory BadgeProgress.fromJson(Map<String, dynamic> j) => BadgeProgress(
        id: _s(j['id']),
        emoji: _s(j['emoji']),
        label: _s(j['label']),
        category: _s(j['category']),
        howTo: _s(j['howTo']),
        target: _i(j['target'], 1),
        progress: _i(j['progress']),
        ratio: _d(j['ratio']),
        unlocked: j['unlocked'] == true,
      );
}

/// Mirrors `SubscriptionDto`.
class SubscriptionData {
  final int status, plan, source;
  final bool isPremium;
  final DateTime? premiumUntil;
  final int premiumDaysLeft;

  SubscriptionData({
    required this.status,
    required this.plan,
    required this.source,
    required this.isPremium,
    required this.premiumUntil,
    required this.premiumDaysLeft,
  });

  // SubscriptionSource.Trial == 1
  bool get fromTrial => source == 1;
  // SubscriptionStatus.Active == 2
  bool get isSubscribed => status == 2;

  factory SubscriptionData.fromJson(Map<String, dynamic> j) => SubscriptionData(
        status: _i(j['status']),
        plan: _i(j['plan']),
        source: _i(j['source']),
        isPremium: j['isPremium'] == true,
        premiumUntil: DateTime.tryParse('${j['premiumUntilUtc']}')?.toLocal(),
        premiumDaysLeft: _i(j['premiumDaysLeft']),
      );
}

/// Mirrors `ReferralDto`.
class ReferralData {
  final String code;
  final int invitedFriends, rewardDaysGranted, rewardDaysPerInvite;

  ReferralData({
    required this.code,
    required this.invitedFriends,
    required this.rewardDaysGranted,
    required this.rewardDaysPerInvite,
  });

  factory ReferralData.fromJson(Map<String, dynamic> j) => ReferralData(
        code: _s(j['code']),
        invitedFriends: _i(j['invitedFriends']),
        rewardDaysGranted: _i(j['rewardDaysGranted']),
        rewardDaysPerInvite: _i(j['rewardDaysPerInvite'], 10),
      );
}

/// Mirrors `NotificationDto`.
class AppNotification {
  final String id, type, title, body;
  final String? deepLink;
  final bool isRead;
  final DateTime? createdAt;

  AppNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    required this.deepLink,
    required this.isRead,
    required this.createdAt,
  });

  factory AppNotification.fromJson(Map<String, dynamic> j) => AppNotification(
        id: _s(j['id']),
        type: _s(j['type']),
        title: _s(j['title']),
        body: _s(j['body']),
        deepLink: j['deepLink']?.toString(),
        isRead: j['isRead'] == true,
        createdAt: DateTime.tryParse('${j['createdAtUtc']}')?.toLocal(),
      );
}

/// Mirrors `CallDto` — includes the LiveKit media handshake.
class CallData {
  final String id, callerId, calleeId;
  final int type, status;
  final String mediaRoomName, mediaServerUrl, mediaToken;
  final int durationSeconds;

  CallData({
    required this.id,
    required this.callerId,
    required this.calleeId,
    required this.type,
    required this.status,
    required this.mediaRoomName,
    required this.mediaServerUrl,
    required this.mediaToken,
    required this.durationSeconds,
  });

  bool get isVideo => type == 1; // CallType.Video

  factory CallData.fromJson(Map<String, dynamic> j) => CallData(
        id: _s(j['id']),
        callerId: _s(j['callerId']),
        calleeId: _s(j['calleeId']),
        type: _i(j['type']),
        status: _i(j['status']),
        mediaRoomName: _s(j['mediaRoomName']),
        mediaServerUrl: _s(j['mediaServerUrl']),
        mediaToken: _s(j['mediaToken']),
        durationSeconds: _i(j['durationSeconds']),
      );
}

/// Mirrors `CountryClusterDto`.
class ClusterData {
  final String countryCode, flag, name;
  final int count;
  ClusterData({
    required this.countryCode,
    required this.flag,
    required this.name,
    required this.count,
  });
  factory ClusterData.fromJson(Map<String, dynamic> j) => ClusterData(
        countryCode: _s(j['countryCode']),
        flag: _s(j['flag']),
        name: _s(j['name']),
        count: _i(j['count']),
      );
}
