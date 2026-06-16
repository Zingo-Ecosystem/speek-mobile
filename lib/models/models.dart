import 'package:flutter/foundation.dart';

import '../data/api_enums.dart';

/// Whether a person is a native speaker or a learner.
enum SpeakerRole { native, learner }

@immutable
class SpeekUser {
  final String id;
  final String name;
  final int age;
  final String flag;
  final String country;
  final String city;
  final SpeakerRole role;
  final String level; // CEFR e.g. B2 (for learners)
  final String photoUrl;
  final List<String> photos;
  final String bio;
  final List<String> interests;
  final int levelXp; // gamification level
  final bool online;
  final double distanceKm;
  // Real-world position for the map.
  final double lat;
  final double lng;
  final bool isOnboarded;
  final bool inCall;
  final DateTime? callStartedAt;

  const SpeekUser({
    required this.id,
    required this.name,
    required this.age,
    required this.flag,
    required this.country,
    required this.city,
    required this.role,
    this.level = '',
    required this.photoUrl,
    this.photos = const [],
    this.bio = '',
    this.interests = const [],
    this.levelXp = 1,
    this.online = true,
    this.distanceKm = 0,
    this.lat = 0,
    this.lng = 0,
    this.isOnboarded = true,
    this.inCall = false,
    this.callStartedAt,
  });

  String get roleLabel => role == SpeakerRole.native ? 'Native' : 'Learner';

  /// Maps a backend `UserDto` (see Speek.Application.Contracts) to a [SpeekUser].
  factory SpeekUser.fromJson(Map<String, dynamic> j) {
    String s(String key, [String fallback = '']) =>
        (j[key] ?? fallback).toString();
    double d(String key) => (j[key] is num) ? (j[key] as num).toDouble() : 0;
    int i(String key, [int fallback = 0]) =>
        (j[key] is num) ? (j[key] as num).toInt() : fallback;

    final photos = (j['photos'] as List?)?.map((e) => '$e').toList() ?? const [];
    final interests =
        (j['interests'] as List?)?.map((e) => '$e').toList() ?? const [];
    final photo = s('photoUrl').isNotEmpty
        ? s('photoUrl')
        : (photos.isNotEmpty ? photos.first : '');

    return SpeekUser(
      id: s('id'),
      name: s('name', 'Speeker'),
      age: i('age'),
      flag: s('flag'),
      country: s('countryName').isNotEmpty ? s('countryName') : s('countryCode'),
      city: s('city'),
      role: ApiEnums.role(j['role']),
      level: ApiEnums.cefr(j['englishLevel']),
      photoUrl: photo,
      photos: photos,
      bio: s('bio'),
      interests: interests,
      levelXp: i('level', 1),
      online: j['online'] == true,
      distanceKm: d('distanceKm'),
      lat: d('lat'),
      lng: d('lng'),
      isOnboarded: j['isOnboarded'] == true,
      inCall: j['inCall'] == true,
      callStartedAt: DateTime.tryParse('${j['callStartedAtUtc']}')?.toLocal(),
    );
  }
}

enum MessageKind { text, voice, callLog }

@immutable
class Message {
  final String text;
  final bool outgoing;
  final MessageKind kind;
  final String voiceDuration; // for voice notes
  final DateTime? time;

  const Message({
    required this.text,
    this.outgoing = false,
    this.kind = MessageKind.text,
    this.voiceDuration = '',
    this.time,
  });

  /// Maps a backend `MessageDto` to a [Message].
  factory Message.fromJson(Map<String, dynamic> j) {
    final secs = (j['durationSeconds'] is num)
        ? (j['durationSeconds'] as num).toInt()
        : 0;
    final dur = secs > 0
        ? '${secs ~/ 60}:${(secs % 60).toString().padLeft(2, '0')}'
        : '';
    return Message(
      text: (j['text'] ?? '').toString(),
      outgoing: j['outgoing'] == true,
      kind: ApiEnums.messageKind(j['kind']),
      voiceDuration: dur,
      time: DateTime.tryParse('${j['createdAtUtc']}')?.toLocal(),
    );
  }
}

@immutable
class Chat {
  final String id; // conversation id (empty for mock/no-conversation)
  final SpeekUser user;
  final String preview;
  final String timeLabel;
  final int unread;
  final bool isRequest;
  final bool previewIsVoice;
  final List<Message> messages;

  const Chat({
    this.id = '',
    required this.user,
    required this.preview,
    required this.timeLabel,
    this.unread = 0,
    this.isRequest = false,
    this.previewIsVoice = false,
    this.messages = const [],
  });

  /// Maps a backend `ConversationDto` to a [Chat].
  factory Chat.fromJson(Map<String, dynamic> j) {
    final last = DateTime.tryParse('${j['lastMessageAtUtc']}')?.toLocal();
    return Chat(
      id: (j['id'] ?? '').toString(),
      user: SpeekUser.fromJson((j['peer'] as Map).cast<String, dynamic>()),
      preview: (j['preview'] ?? '').toString(),
      timeLabel: _relativeTime(last),
      unread: (j['unread'] is num) ? (j['unread'] as num).toInt() : 0,
      isRequest: j['isRequest'] == true,
      previewIsVoice: j['previewIsVoice'] == true,
    );
  }

  static String _relativeTime(DateTime? t) {
    if (t == null) return '';
    final diff = DateTime.now().difference(t);
    if (diff.inMinutes < 1) return 'now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    if (diff.inHours < 24) return '${diff.inHours}h';
    return '${diff.inDays}d';
  }
}

@immutable
class CountryCluster {
  final String flag;
  final String name;
  final int count;
  final double x;
  final double y;
  const CountryCluster(this.flag, this.name, this.count, this.x, this.y);
}

@immutable
class Badge {
  final String emoji;
  final String label;
  final int color; // ARGB
  final bool locked;
  const Badge(this.emoji, this.label, this.color, {this.locked = false});
}
