import 'package:flutter/foundation.dart';

import '../core/api_client.dart';
import '../core/api_exception.dart';
import '../models/models.dart';
import 'api_enums.dart';
import 'dto.dart';

List<Map<String, dynamic>> _list(dynamic v) {
  // Plain array
  if (v is List) {
    return v.map((e) => (e as Map).cast<String, dynamic>()).toList();
  }
  // Paginated envelope: { items: [...] } or similar
  if (v is Map) {
    final inner = v['items'] ?? v['data'] ?? v['conversations'] ??
        v['messages'] ?? v['results'];
    if (inner is List) {
      return inner.map((e) => (e as Map).cast<String, dynamic>()).toList();
    }
  }
  return const [];
}

// ---------------------------------------------------------------------------
// Profile
// ---------------------------------------------------------------------------
class ProfileRepository {
  final _api = ApiClient.instance;

  Future<SpeekUser> me() async {
    final j = await _api.get('/Profile/me');
    return SpeekUser.fromJson((j as Map).cast());
  }

  Future<SpeekUser> byId(String id) async {
    final j = await _api.get('/Profile/$id');
    return SpeekUser.fromJson((j as Map).cast());
  }

  Future<SpeekUser> update({
    required String name,
    required int age,
    required String gender,
    required String countryCode,
    required String countryName,
    required String flag,
    required String city,
    required SpeakerRole role,
    required String englishLevel,
    required String bio,
  }) async {
    final j = await _api.put('/Profile/me', body: {
      'name': name,
      'age': age,
      'gender': gender,
      'countryCode': countryCode,
      'countryName': countryName,
      'flag': flag,
      'city': city,
      'role': ApiEnums.roleToInt(role),
      'englishLevel': ApiEnums.cefrToInt(englishLevel),
      'bio': bio,
    });
    return SpeekUser.fromJson((j as Map).cast());
  }

  Future<SpeekUser> completeOnboarding(Map<String, dynamic> body) async {
    final j = await _api.post('/Profile/onboarding', body: body);
    return SpeekUser.fromJson((j as Map).cast());
  }

  /// Uploads an image file and returns its hosted URL.
  Future<String> uploadImage(String filePath) async {
    final j = await _api.uploadFile('/Upload', filePath);
    if (j is! Map) throw ApiException(0, 'Unexpected upload response.');
    return (j['url'] ?? '').toString();
  }

  /// Cross-platform image upload from raw bytes (use on web).
  Future<String> uploadImageBytes(List<int> bytes, String filename) async {
    final j = await _api.uploadBytes('/Upload', bytes, filename);
    if (j is! Map) throw ApiException(0, 'Unexpected upload response.');
    return (j['url'] ?? '').toString();
  }

  /// Sets the uploaded URL as the user's primary avatar.
  Future<SpeekUser> setPhoto(String url) async {
    final j = await _api.post('/Profile/photo', body: {'url': url});
    return SpeekUser.fromJson((j as Map).cast());
  }

  /// Replaces the whole photo gallery (first url becomes the avatar).
  Future<SpeekUser> setPhotos(List<String> urls) async {
    final j = await _api.put('/Profile/photos', body: {'urls': urls});
    return SpeekUser.fromJson((j as Map).cast());
  }

  /// Sets who may call the user: 'Everyone' | 'Friends only' | 'No one'.
  Future<void> setCallPolicy(String policy) =>
      _api.put('/Profile/call-policy', body: {'policy': _callPolicyToInt(policy)});

  static int _callPolicyToInt(String p) => switch (p) {
        'Friends only' => 1,
        'No one' => 2,
        _ => 0, // Everyone
      };

  static String callPolicyFromInt(int v) => switch (v) {
        1 => 'Friends only',
        2 => 'No one',
        _ => 'Everyone',
      };
}

// ---------------------------------------------------------------------------
// Map / presence
// ---------------------------------------------------------------------------
class MapRepository {
  final _api = ApiClient.instance;

  Future<void> heartbeat(double lat, double lng) =>
      _api.post('/Map/heartbeat', body: {'lat': lat, 'lng': lng});

  Future<void> offline() => _api.post('/Map/offline');

  Future<List<SpeekUser>> nearby({
    required double lat,
    required double lng,
    double radiusKm = 50,
    int limit = 100,
    int? role,
    int? maxCefrLevel,
    String? countryCode,
    int? goals,
  }) async {
    final j = await _api.get('/Map/nearby', query: {
      'lat': lat,
      'lng': lng,
      'radiusKm': radiusKm,
      'limit': limit,
      'role': ?role,
      'maxCefrLevel': ?maxCefrLevel,
      if (countryCode != null && countryCode.isNotEmpty) 'countryCode': countryCode,
      if (goals != null && goals != 0) 'goals': goals,
    });
    return _list(j).map(SpeekUser.fromJson).toList();
  }

  Future<void> boost() => _api.post('/Map/boost');

  Future<List<ClusterData>> clusters() async {
    final j = await _api.get('/Map/clusters');
    return _list(j).map(ClusterData.fromJson).toList();
  }
}

// ---------------------------------------------------------------------------
// Chat
// ---------------------------------------------------------------------------
class ChatRepository {
  final _api = ApiClient.instance;

  Future<List<Chat>> conversations({int take = 20, DateTime? cursor}) async {
    final j = await _api.get('/Chat/conversations', query: {
      'take': take,
      if (cursor != null) 'cursor': cursor.toUtc().toIso8601String(),
    });
    return _list(j).map(Chat.fromJson).toList();
  }

  Future<List<Message>> messages(
    String conversationId, {
    int take = 30,
    DateTime? before,
    DateTime? after,
  }) async {
    final j = await _api.get(
      '/Chat/conversations/$conversationId/messages',
      query: {
        'take': take,
        if (before != null) 'before': before.toUtc().toIso8601String(),
        if (after != null) 'after': after.toUtc().toIso8601String(),
      },
    );
    return _list(j).map(Message.fromJson).toList();
  }

  Future<Message> send({
    required String peerId,
    required MessageKind kind,
    String text = '',
    String? mediaUrl,
    String? documentName,
    int durationSeconds = 0,
  }) async {
    final j = await _api.post('/Chat/messages', body: {
      'peerId': peerId,
      'kind': ApiEnums.messageKindToInt(kind),
      'text': text,
      'mediaUrl': mediaUrl,
      'documentName': documentName,
      'durationSeconds': durationSeconds,
    });
    return Message.fromJson((j as Map).cast());
  }

  Future<String> uploadMedia(String filePath) async {
    final j = await _api.uploadFile('/Upload', filePath);
    if (j is! Map) throw ApiException(0, 'Unexpected upload response.');
    return (j['url'] ?? '').toString();
  }

  Future<void> editMessage(String id, String text) =>
      _api.put('/Chat/messages/$id', body: {'text': text});

  Future<void> deleteMessage(String id) => _api.delete('/Chat/messages/$id');

  Future<List<String>> checkDeleted(List<String> ids) async {
    final j = await _api.post('/Chat/messages/check-deleted', body: {'ids': ids});
    return (_list(j)).map((e) => '${e['id']}').toList();
  }

  /// Searches the conversations list for an existing conversation with [peerId].
  /// Returns the conversation ID, or empty string if none found.
  Future<String> findConversationByPeer(String peerId) async {
    try {
      final chats = await conversations(take: 50);
      for (final c in chats) {
        if (c.user.id == peerId) return c.id;
      }
    } catch (_) {}
    return '';
  }

  Future<void> markRead(String conversationId) =>
      _api.post('/Chat/conversations/$conversationId/read');

  Future<void> accept(String conversationId) =>
      _api.post('/Chat/conversations/$conversationId/accept');

  Future<void> decline(String conversationId) =>
      _api.post('/Chat/conversations/$conversationId/decline');

  /// Invites an online user (from the map) to practice. [mode] is the suggested
  /// medium: null = chat, 0 = voice, 1 = video. Returns the conversation ID.
  Future<String> invite(String peerId, {int? mode, String? note}) async {
    final j = await _api.post('/Chat/invite', body: {
      'peerId': peerId,
      if (mode != null) 'mode': mode,
      if (note != null && note.isNotEmpty) 'note': note,
    });
    if (j is Map && j['conversationId'] != null) {
      return j['conversationId'].toString();
    }
    return '';
  }
}

// ---------------------------------------------------------------------------
// Calls
// ---------------------------------------------------------------------------
class CallRepository {
  final _api = ApiClient.instance;

  Future<CallData> start({required String calleeId, required bool video}) async {
    final j = await _api.post('/Calls', body: {
      'calleeId': calleeId,
      'type': video ? 1 : 0,
    });
    debugPrint('[CallRepository.start] response: $j');
    return CallData.fromJson((j as Map).cast());
  }

  Future<CallData> accept(String id) async {
    final j = await _api.post('/Calls/$id/accept');
    debugPrint('[CallRepository.accept] response: $j');
    return CallData.fromJson((j as Map).cast());
  }
  Future<void> decline(String id) => _api.post('/Calls/$id/decline');
  Future<void> cancel(String id) => _api.post('/Calls/$id/cancel');
  Future<void> end(String id) => _api.post('/Calls/$id/end');
  Future<void> rate(String id, int stars) =>
      _api.post('/Calls/$id/rate', body: {'stars': stars});
}

// ---------------------------------------------------------------------------
// Gamification
// ---------------------------------------------------------------------------
class GamificationRepository {
  final _api = ApiClient.instance;

  Future<GamificationData> get() async {
    final j = await _api.get('/Gamification');
    return GamificationData.fromJson((j as Map).cast());
  }
}

// ---------------------------------------------------------------------------
// Subscription / referral
// ---------------------------------------------------------------------------
class SubscriptionRepository {
  final _api = ApiClient.instance;

  Future<SubscriptionData> get() async {
    final j = await _api.get('/Subscription');
    return SubscriptionData.fromJson((j as Map).cast());
  }

  Future<SubscriptionData> validatePurchase({
    required int store,
    required String productId,
    required String receiptData,
  }) async {
    final j = await _api.post('/Subscription/validate-purchase', body: {
      'store': store,
      'productId': productId,
      'receiptData': receiptData,
    });
    return SubscriptionData.fromJson((j as Map).cast());
  }

  Future<void> cancel() => _api.post('/Subscription/cancel');

  Future<ReferralData> referral() async {
    final j = await _api.get('/referral');
    return ReferralData.fromJson((j as Map).cast());
  }
}

// ---------------------------------------------------------------------------
// Notifications
// ---------------------------------------------------------------------------
class NotificationRepository {
  final _api = ApiClient.instance;

  Future<Map<String, bool>> preferences() async {
    final j = await _api.get('/Notifications/preferences');
    final toggles = (j is Map ? j['toggles'] : null) as Map?;
    return (toggles ?? {}).map((k, v) => MapEntry('$k', v == true));
  }

  Future<void> setPreference(String key, bool value) =>
      _api.put('/Notifications/preferences', body: {'key': key, 'value': value});

  Future<void> registerDevice(String token, {int platform = 1}) =>
      _api.post('/Notifications/devices',
          body: {'token': token, 'platform': platform});

  Future<List<AppNotification>> list({int take = 30}) async {
    final j = await _api.get('/Notifications', query: {'take': take});
    return _list(j).map(AppNotification.fromJson).toList();
  }

  Future<void> markRead(String id) => _api.post('/Notifications/$id/read');
}

// ---------------------------------------------------------------------------
// Friends
// ---------------------------------------------------------------------------
class FriendRepository {
  final _api = ApiClient.instance;

  Future<List<FriendData>> list() async {
    final j = await _api.get('/friends');
    return _list(j).map(FriendData.fromJson).toList();
  }

  /// Sends a friend request OR accepts one (idempotent).
  Future<void> addOrAccept(String targetId) =>
      _api.post('/friends/$targetId');

  /// Removes a friendship or declines a pending request.
  Future<void> remove(String targetId) =>
      _api.delete('/friends/$targetId');

  /// Blocks a user: drops friendship, blocks chat, hides both from each other.
  Future<void> block(String targetId) =>
      _api.post('/friends/$targetId/block');

  /// Lifts a previously placed block.
  Future<void> unblock(String targetId) =>
      _api.delete('/friends/$targetId/block');

  /// Users the current user has blocked.
  Future<List<BlockedUser>> blocked() async {
    final j = await _api.get('/friends/blocked');
    return _list(j).map(BlockedUser.fromJson).toList();
  }
}

// ---------------------------------------------------------------------------
// Social (likes & views)
// ---------------------------------------------------------------------------
class SocialRepository {
  final _api = ApiClient.instance;

  Future<void> like(String profileId) =>
      _api.post('/profiles/$profileId/like');

  Future<void> unlike(String profileId) =>
      _api.delete('/profiles/$profileId/like');

  Future<void> recordView(String profileId) =>
      _api.post('/profiles/$profileId/view');

  /// Premium required — who liked me.
  Future<List<SocialUserData>> whoLikedMe() async {
    final j = await _api.get('/social/likes');
    return _list(j).map(SocialUserData.fromJson).toList();
  }

  /// Premium required — who viewed my profile.
  Future<List<SocialUserData>> whoViewedMe() async {
    final j = await _api.get('/social/views');
    return _list(j).map(SocialUserData.fromJson).toList();
  }
}

// ---------------------------------------------------------------------------
// Marketplace / XP economy + challenges
// ---------------------------------------------------------------------------
class MarketplaceRepository {
  final _api = ApiClient.instance;

  Future<MarketplaceData> list() async {
    final j = await _api.get('/marketplace');
    return MarketplaceData.fromJson((j as Map).cast());
  }

  Future<List<String>> inventory() async {
    final j = await _api.get('/marketplace/inventory');
    return _list(j).map((e) => '$e').toList();
  }

  Future<BuyResult> buy(String productId) async {
    final j = await _api.post('/marketplace/$productId/buy');
    return BuyResult.fromJson((j as Map).cast());
  }

  Future<ChallengeJourney> journey() async {
    final j = await _api.get('/challenges');
    return ChallengeJourney.fromJson((j as Map).cast());
  }

  /// Claims the daily streak reward. Returns granted XP and new balance.
  Future<Map<String, dynamic>> claimDaily() async {
    final j = await _api.post('/challenges/claim');
    return (j as Map).cast();
  }
}

/// Single access point for all repositories.
class Repos {
  Repos._();
  static final profile = ProfileRepository();
  static final map = MapRepository();
  static final chat = ChatRepository();
  static final calls = CallRepository();
  static final gamification = GamificationRepository();
  static final subscription = SubscriptionRepository();
  static final notifications = NotificationRepository();
  static final friends = FriendRepository();
  static final social = SocialRepository();
  static final marketplace = MarketplaceRepository();
}
