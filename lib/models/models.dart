import 'package:flutter/foundation.dart';

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
  });

  String get roleLabel => role == SpeakerRole.native ? 'Native' : 'Learner';
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
}

@immutable
class Chat {
  final SpeekUser user;
  final String preview;
  final String timeLabel;
  final int unread;
  final bool isRequest;
  final bool previewIsVoice;
  final List<Message> messages;

  const Chat({
    required this.user,
    required this.preview,
    required this.timeLabel,
    this.unread = 0,
    this.isRequest = false,
    this.previewIsVoice = false,
    this.messages = const [],
  });
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
