import 'package:flutter/foundation.dart';

import '../core/api_client.dart';
import '../core/api_exception.dart';
import '../models/models.dart';
import 'api_enums.dart';
import 'dto.dart';

List<Map<String, dynamic>> _list(dynamic v) =>
    (v as List?)?.map((e) => (e as Map).cast<String, dynamic>()).toList() ??
    const [];

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

  /// Sets the uploaded URL as the user's primary avatar.
  Future<SpeekUser> setPhoto(String url) async {
    final j = await _api.post('/Profile/photo', body: {'url': url});
    return SpeekUser.fromJson((j as Map).cast());
  }
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
  }) async {
    final j = await _api.get('/Map/nearby', query: {
      'lat': lat,
      'lng': lng,
      'radiusKm': radiusKm,
      'limit': limit,
    });
    return _list(j).map(SpeekUser.fromJson).toList();
  }

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

  Future<List<Chat>> conversations() async {
    final j = await _api.get('/Chat/conversations');
    return _list(j).map(Chat.fromJson).toList();
  }

  Future<List<Message>> messages(String conversationId,
      {int take = 30, DateTime? before}) async {
    final j = await _api.get('/Chat/conversations/$conversationId/messages',
        query: {'take': take, if (before != null) 'before': before.toUtc().toIso8601String()});
    return _list(j).map(Message.fromJson).toList();
  }

  Future<Message> send({
    required String peerId,
    required MessageKind kind,
    required String text,
    String? mediaUrl,
    int durationSeconds = 0,
  }) async {
    final j = await _api.post('/Chat/messages', body: {
      'peerId': peerId,
      'kind': ApiEnums.messageKindToInt(kind),
      'text': text,
      'mediaUrl': mediaUrl,
      'durationSeconds': durationSeconds,
    });
    return Message.fromJson((j as Map).cast());
  }

  Future<void> markRead(String conversationId) =>
      _api.post('/Chat/conversations/$conversationId/read');

  Future<void> accept(String conversationId) =>
      _api.post('/Chat/conversations/$conversationId/accept');

  Future<void> decline(String conversationId) =>
      _api.post('/Chat/conversations/$conversationId/decline');
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
}
