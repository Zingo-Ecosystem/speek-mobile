import '../config/app_config.dart';

int _i(dynamic v, [int f = 0]) => v is num ? v.toInt() : f;
double _d(dynamic v, [double f = 0]) => v is num ? v.toDouble() : f;
String _s(dynamic v, [String f = '']) => v == null ? f : '$v';

/// Resolves a possibly-relative media path to an absolute URL.
String _media(dynamic v) => AppConfig.media(_s(v));

/// Mirrors `GamificationDto`.
class GamificationData {
  final int totalXp, level, xpIntoLevel, xpForLevel;
  final double levelProgress;
  final int totalCalls, streakDays, countriesSpoken, unlockedBadgeCount;
  final int totalTalkSeconds;
  final int xpBalance, bestStreakDays;
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
    this.xpBalance = 0,
    this.bestStreakDays = 0,
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
        xpBalance: _i(j['xpBalance']),
        bestStreakDays: _i(j['bestStreakDays']),
        badges: (j['badges'] as List?)
                ?.map((e) => BadgeProgress.fromJson((e as Map).cast()))
                .toList() ??
            const [],
      );
}

/// Mirrors `StoreProductDto`.
class StoreProduct {
  final String id, emoji, name, description, category;
  final int priceXp, grantsPremiumDays;
  final bool featured, owned, affordable;

  StoreProduct({
    required this.id,
    required this.emoji,
    required this.name,
    required this.description,
    required this.category,
    required this.priceXp,
    required this.grantsPremiumDays,
    required this.featured,
    required this.owned,
    required this.affordable,
  });

  bool get isConsumable => category == 'Premium' || category == 'Boost';

  factory StoreProduct.fromJson(Map<String, dynamic> j) => StoreProduct(
        id: _s(j['id']),
        emoji: _s(j['emoji']),
        name: _s(j['name']),
        description: _s(j['description']),
        category: _s(j['category']),
        priceXp: _i(j['priceXp']),
        grantsPremiumDays: _i(j['grantsPremiumDays']),
        featured: j['featured'] == true,
        owned: j['owned'] == true,
        affordable: j['affordable'] == true,
      );
}

/// Mirrors `MarketplaceDto`.
class MarketplaceData {
  final int xpBalance, totalXp;
  final List<StoreProduct> products;
  MarketplaceData(
      {required this.xpBalance, required this.totalXp, required this.products});

  factory MarketplaceData.fromJson(Map<String, dynamic> j) => MarketplaceData(
        xpBalance: _i(j['xpBalance']),
        totalXp: _i(j['totalXp']),
        products: ((j['products'] as List?) ?? const [])
            .whereType<Map>()
            .map((e) => StoreProduct.fromJson(e.cast()))
            .toList(),
      );
}

/// Mirrors `BuyResultDto`.
class BuyResult {
  final bool success, owned;
  final String message;
  final int xpBalance;
  BuyResult(
      {required this.success,
      required this.owned,
      required this.message,
      required this.xpBalance});

  factory BuyResult.fromJson(Map<String, dynamic> j) => BuyResult(
        success: j['success'] == true,
        owned: j['owned'] == true,
        message: _s(j['message']),
        xpBalance: _i(j['xpBalance']),
      );
}

/// Mirrors `ChallengeDayDto`.
class ChallengeDay {
  final int day, xpReward;
  final bool completed, unlocked, isToday;
  ChallengeDay(
      {required this.day,
      required this.xpReward,
      required this.completed,
      required this.unlocked,
      required this.isToday});

  factory ChallengeDay.fromJson(Map<String, dynamic> j) => ChallengeDay(
        day: _i(j['day']),
        xpReward: _i(j['xpReward']),
        completed: j['completed'] == true,
        unlocked: j['unlocked'] == true,
        isToday: j['isToday'] == true,
      );
}

/// Mirrors `ChallengeJourneyDto`.
class ChallengeJourney {
  final int streakDays, bestStreakDays, completedDays, xpBalance;
  final bool canClaimToday;
  final List<ChallengeDay> days;
  ChallengeJourney({
    required this.streakDays,
    required this.bestStreakDays,
    required this.completedDays,
    required this.xpBalance,
    required this.canClaimToday,
    required this.days,
  });

  factory ChallengeJourney.fromJson(Map<String, dynamic> j) => ChallengeJourney(
        streakDays: _i(j['streakDays']),
        bestStreakDays: _i(j['bestStreakDays']),
        completedDays: _i(j['completedDays']),
        xpBalance: _i(j['xpBalance']),
        canClaimToday: j['canClaimToday'] == true,
        days: ((j['days'] as List?) ?? const [])
            .whereType<Map>()
            .map((e) => ChallengeDay.fromJson(e.cast()))
            .toList(),
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
  final List<InvitedFriend> invited;

  ReferralData({
    required this.code,
    required this.invitedFriends,
    required this.rewardDaysGranted,
    required this.rewardDaysPerInvite,
    this.invited = const [],
  });

  factory ReferralData.fromJson(Map<String, dynamic> j) => ReferralData(
        code: _s(j['code']),
        invitedFriends: _i(j['invitedFriends']),
        rewardDaysGranted: _i(j['rewardDaysGranted']),
        rewardDaysPerInvite: _i(j['rewardDaysPerInvite'], 10),
        invited: ((j['invited'] as List?) ?? const [])
            .whereType<Map>()
            .map((e) => InvitedFriend.fromJson(e.cast()))
            .toList(),
      );
}

/// Mirrors `InvitedFriendDto` — one friend the user successfully brought in.
class InvitedFriend {
  final String userId, name;
  final String? photoUrl;
  final String flag;
  final int rewardDays;
  final bool isOnboarded;
  final DateTime joinedAt;

  InvitedFriend({
    required this.userId,
    required this.name,
    required this.photoUrl,
    required this.flag,
    required this.rewardDays,
    required this.isOnboarded,
    required this.joinedAt,
  });

  factory InvitedFriend.fromJson(Map<String, dynamic> j) => InvitedFriend(
        userId: _s(j['userId']),
        name: _s(j['name']),
        photoUrl: (j['photoUrl'] as String?)?.isEmpty ?? true
            ? null
            : _media(j['photoUrl']),
        flag: _s(j['flag']),
        rewardDays: _i(j['rewardDays'], 10),
        isOnboarded: j['isOnboarded'] == true,
        joinedAt: DateTime.tryParse('${j['joinedAtUtc']}')?.toLocal() ??
            DateTime.now(),
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

/// Mirrors `FriendshipDto`.
class FriendData {
  final String userId;
  final String name;
  final String photoUrl;
  final String flag;
  final String country;
  // 0 = Pending, 1 = Accepted
  final int status;
  final bool isSentByMe;

  FriendData({
    required this.userId,
    required this.name,
    required this.photoUrl,
    required this.flag,
    required this.country,
    required this.status,
    required this.isSentByMe,
  });

  bool get isPending => status == 0;
  bool get isAccepted => status == 1;

  factory FriendData.fromJson(Map<String, dynamic> j) {
    // Backend `FriendDto` nests the profile under `user`; tolerate a flat shape too.
    final u = (j['user'] as Map?)?.cast<String, dynamic>() ?? j;
    final pending = j['isPending'] == true;
    return FriendData(
      userId: _s(u['id'] ?? j['userId']),
      name: _s(u['name'], 'Speeker'),
      photoUrl: _media(u['photoUrl']),
      flag: _s(u['flag']),
      country: _s(u['countryName'] ?? u['country']),
      status: j.containsKey('isPending') ? (pending ? 0 : 1) : _i(j['status']),
      isSentByMe: (j['iSentRequest'] ?? j['isSentByMe']) == true,
    );
  }
}

/// Mirrors `BlockedUserDto`.
class BlockedUser {
  final String userId, name, photoUrl, flag, country;
  final DateTime? at;

  BlockedUser({
    required this.userId,
    required this.name,
    required this.photoUrl,
    required this.flag,
    required this.country,
    required this.at,
  });

  factory BlockedUser.fromJson(Map<String, dynamic> j) {
    final u = (j['user'] as Map?)?.cast<String, dynamic>() ?? j;
    return BlockedUser(
      userId: _s(u['id'] ?? j['userId']),
      name: _s(u['name'], 'Speeker'),
      photoUrl: _media(u['photoUrl']),
      flag: _s(u['flag']),
      country: _s(u['countryName'] ?? u['country']),
      at: DateTime.tryParse('${j['blockedAtUtc']}')?.toLocal(),
    );
  }
}

/// Mirrors `SocialUserDto` (liked/viewed me entries).
class SocialUserData {
  final String userId;
  final String name;
  final String photoUrl;
  final String flag;
  final String country;
  final DateTime? at;

  SocialUserData({
    required this.userId,
    required this.name,
    required this.photoUrl,
    required this.flag,
    required this.country,
    required this.at,
  });

  factory SocialUserData.fromJson(Map<String, dynamic> j) {
    final u = (j['user'] as Map?)?.cast<String, dynamic>() ?? j;
    return SocialUserData(
      userId: _s(u['id'] ?? j['userId']),
      name: _s(u['name'], 'Speeker'),
      photoUrl: _media(u['photoUrl']),
      flag: _s(u['flag']),
      country: _s(u['countryName'] ?? u['country']),
      at: DateTime.tryParse('${j['likedAtUtc'] ?? j['viewedAtUtc']}')?.toLocal(),
    );
  }
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
