import '../models/models.dart';
import '../theme/app_colors.dart';

/// Static demo content. Swap for backend data later.
class Mock {
  Mock._();

  static const james = SpeekUser(
    id: 'james',
    name: 'James',
    age: 27,
    flag: '🇺🇸',
    country: 'USA',
    city: 'New York',
    role: SpeakerRole.native,
    photoUrl:
        'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?auto=format&fit=crop&w=500&q=80',
    photos: [
      'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?auto=format&fit=crop&w=700&q=80',
      'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?auto=format&fit=crop&w=700&q=80',
    ],
    bio:
        'Here to help people speak naturally & make friends around the world 🌍 Coffee addict.',
    interests: ['✈️ Travel', '🎵 Music', '📷 Photography', '☕ Coffee'],
    levelXp: 12,
    online: true,
    distanceKm: 2.4,
    lat: 40.71,
    lng: -74.00,
  );

  static const sofia = SpeekUser(
    id: 'sofia',
    name: 'Sofia',
    age: 24,
    flag: '🇪🇸',
    country: 'Spain',
    city: 'Madrid',
    role: SpeakerRole.learner,
    level: 'B2',
    photoUrl:
        'https://images.unsplash.com/photo-1534528741775-53994a69daeb?auto=format&fit=crop&w=500&q=80',
    bio: 'Learning English to travel the world. Love music and good coffee ☕',
    interests: ['🎵 Music', '✈️ Travel', '🎬 Movies'],
    levelXp: 7,
    online: true,
    distanceKm: 1.1,
    lat: 40.42,
    lng: -3.70,
  );

  static const yuki = SpeekUser(
    id: 'yuki',
    name: 'Yuki',
    age: 23,
    flag: '🇰🇷',
    country: 'Korea',
    city: 'Seoul',
    role: SpeakerRole.learner,
    level: 'B1',
    photoUrl:
        'https://images.unsplash.com/photo-1524504388940-b1c1722653e1?auto=format&fit=crop&w=500&q=80',
    bio: 'K-pop, coding and conversations. Let\'s practice together!',
    interests: ['🎮 Gaming', '🎵 Music', '💻 Tech'],
    levelXp: 5,
    online: true,
    distanceKm: 3.0,
    lat: 37.57,
    lng: 126.98,
  );

  static const noah = SpeekUser(
    id: 'noah',
    name: 'Noah',
    age: 29,
    flag: '🇬🇧',
    country: 'UK',
    city: 'London',
    role: SpeakerRole.native,
    photoUrl:
        'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?auto=format&fit=crop&w=500&q=80',
    bio: 'British native, happy to help with pronunciation 🇬🇧',
    interests: ['⚽ Sports', '📚 Books', '✈️ Travel'],
    levelXp: 9,
    online: false,
    distanceKm: 5.2,
    lat: 51.51,
    lng: -0.13,
  );

  static const emma = SpeekUser(
    id: 'emma',
    name: 'Emma',
    age: 26,
    flag: '🇨🇦',
    country: 'Canada',
    city: 'Toronto',
    role: SpeakerRole.native,
    photoUrl:
        'https://images.unsplash.com/photo-1544005313-94ddf0286df2?auto=format&fit=crop&w=500&q=80',
    bio: 'Yoga teacher who loves languages 🧘',
    interests: ['🧘 Yoga', '🌱 Nature', '🎨 Art'],
    levelXp: 8,
    online: true,
    distanceKm: 0.8,
    lat: 43.65,
    lng: -79.38,
  );

  /// The signed-in user.
  static const me = SpeekUser(
    id: 'me',
    name: 'Chloe',
    age: 24,
    flag: '🇫🇷',
    country: 'France',
    city: 'Paris',
    role: SpeakerRole.learner,
    level: 'B1',
    photoUrl:
        'https://images.unsplash.com/photo-1494790108377-be9c29b29330?auto=format&fit=crop&w=700&q=80',
    bio: 'Learning English to travel & make friends worldwide 🌍',
    interests: ['🎵 Music', '✈️ Travel', '🎮 Gaming', '🍳 Cooking'],
    levelXp: 9,
    online: true,
  );

  static const nearbyUsers = [james, sofia, yuki, noah, emma];

  // Extra people scattered across the globe so the world map feels alive.
  static const _extra = [
    SpeekUser(
        id: 'liam', name: 'Liam', age: 25, flag: '🇦🇺', country: 'Australia',
        city: 'Sydney', role: SpeakerRole.native, levelXp: 6,
        photoUrl: 'https://images.unsplash.com/photo-1506794778202-cad84cf45f1d?auto=format&fit=crop&w=500&q=80',
        bio: 'Surfer & language nerd 🏄', interests: ['🏔 Hiking', '🎵 Music'],
        lat: -33.87, lng: 151.21),
    SpeekUser(
        id: 'ana', name: 'Ana', age: 22, flag: '🇧🇷', country: 'Brazil',
        city: 'São Paulo', role: SpeakerRole.learner, level: 'A2', levelXp: 4,
        photoUrl: 'https://images.unsplash.com/photo-1502823403499-6ccfcf4fb453?auto=format&fit=crop&w=500&q=80',
        bio: 'Quero aprender inglês! 🇧🇷', interests: ['💃 Dance', '🎬 Movies'],
        lat: -23.55, lng: -46.63),
    SpeekUser(
        id: 'raj', name: 'Raj', age: 28, flag: '🇮🇳', country: 'India',
        city: 'Mumbai', role: SpeakerRole.learner, level: 'B2', levelXp: 10,
        photoUrl: 'https://images.unsplash.com/photo-1488161628813-04466f872be2?auto=format&fit=crop&w=500&q=80',
        bio: 'Software dev who loves cricket 🏏', interests: ['💻 Tech', '⚽ Sports'],
        lat: 19.08, lng: 72.88),
    SpeekUser(
        id: 'mei', name: 'Mei', age: 24, flag: '🇯🇵', country: 'Japan',
        city: 'Tokyo', role: SpeakerRole.learner, level: 'B1', levelXp: 7,
        photoUrl: 'https://images.unsplash.com/photo-1531123897727-8f129e1688ce?auto=format&fit=crop&w=500&q=80',
        bio: 'はじめまして! Practicing English daily', interests: ['🎨 Art', '📚 Books'],
        lat: 35.68, lng: 139.69),
    SpeekUser(
        id: 'leo', name: 'Leo', age: 30, flag: '🇩🇪', country: 'Germany',
        city: 'Berlin', role: SpeakerRole.native, levelXp: 11,
        photoUrl: 'https://images.unsplash.com/photo-1492562080023-ab3db95bfbce?auto=format&fit=crop&w=500&q=80',
        bio: 'Techno & deep talks 🎧', interests: ['🎵 Music', '💻 Tech'],
        lat: 52.52, lng: 13.40),
    SpeekUser(
        id: 'aisha', name: 'Aisha', age: 26, flag: '🇿🇦', country: 'South Africa',
        city: 'Cape Town', role: SpeakerRole.native, levelXp: 8,
        photoUrl: 'https://images.unsplash.com/photo-1531746020798-e6953c6e8e04?auto=format&fit=crop&w=500&q=80',
        bio: 'Nature lover & teacher 🌿', interests: ['🌱 Nature', '🧘 Yoga'],
        lat: -33.92, lng: 18.42),
    SpeekUser(
        id: 'diego', name: 'Diego', age: 27, flag: '🇲🇽', country: 'Mexico',
        city: 'Mexico City', role: SpeakerRole.learner, level: 'B1', levelXp: 6,
        photoUrl: 'https://images.unsplash.com/photo-1463453091185-61582044d556?auto=format&fit=crop&w=500&q=80',
        bio: 'Foodie aprendiendo inglés 🌮', interests: ['🍳 Cooking', '🎮 Gaming'],
        lat: 19.43, lng: -99.13),
    SpeekUser(
        id: 'olga', name: 'Olga', age: 23, flag: '🇷🇺', country: 'Russia',
        city: 'Moscow', role: SpeakerRole.learner, level: 'A2', levelXp: 3,
        photoUrl: 'https://images.unsplash.com/photo-1487412720507-e7ab37603c6f?auto=format&fit=crop&w=500&q=80',
        bio: 'Want to speak English fluently 💬', interests: ['📷 Photography', '🎬 Movies'],
        lat: 55.75, lng: 37.62),
    SpeekUser(
        id: 'sara', name: 'Sara', age: 25, flag: '🇦🇪', country: 'UAE',
        city: 'Dubai', role: SpeakerRole.native, levelXp: 9,
        photoUrl: 'https://images.unsplash.com/photo-1544717305-2782549b5136?auto=format&fit=crop&w=500&q=80',
        bio: 'Bilingual & always traveling ✈️', interests: ['✈️ Travel', '☕ Coffee'],
        lat: 25.20, lng: 55.27),

    // More people online around the world so the live map feels busy.
    SpeekUser(id: 'oliver', name: 'Oliver', age: 24, flag: '🇬🇧', country: 'UK',
        city: 'Manchester', role: SpeakerRole.native, levelXp: 7, inCall: true,
        photoUrl: 'https://images.unsplash.com/photo-1539571696357-5a69c17a67c6?auto=format&fit=crop&w=500&q=80',
        bio: 'Football & films ⚽', interests: ['⚽ Sports'], lat: 53.48, lng: -2.24),
    SpeekUser(id: 'camille', name: 'Camille', age: 23, flag: '🇫🇷', country: 'France',
        city: 'Lyon', role: SpeakerRole.learner, level: 'B1', levelXp: 5,
        photoUrl: 'https://images.unsplash.com/photo-1517841905240-472988babdf9?auto=format&fit=crop&w=500&q=80',
        bio: 'Pâtisserie & English 🥐', interests: ['🍳 Cooking'], lat: 45.76, lng: 4.84),
    SpeekUser(id: 'marco', name: 'Marco', age: 28, flag: '🇮🇹', country: 'Italy',
        city: 'Milan', role: SpeakerRole.learner, level: 'B2', levelXp: 9, inCall: true,
        photoUrl: 'https://images.unsplash.com/photo-1463453091185-61582044d556?auto=format&fit=crop&w=500&q=80',
        bio: 'Design & espresso ☕', interests: ['🎨 Art'], lat: 45.46, lng: 9.19),
    SpeekUser(id: 'elena', name: 'Elena', age: 25, flag: '🇪🇸', country: 'Spain',
        city: 'Barcelona', role: SpeakerRole.learner, level: 'B1', levelXp: 6,
        photoUrl: 'https://images.unsplash.com/photo-1502823403499-6ccfcf4fb453?auto=format&fit=crop&w=500&q=80',
        bio: 'Beach & books 📚', interests: ['📚 Books'], lat: 41.39, lng: 2.17),
    SpeekUser(id: 'jonas', name: 'Jonas', age: 26, flag: '🇸🇪', country: 'Sweden',
        city: 'Stockholm', role: SpeakerRole.native, levelXp: 8,
        photoUrl: 'https://images.unsplash.com/photo-1492562080023-ab3db95bfbce?auto=format&fit=crop&w=500&q=80',
        bio: 'Hej! Happy to chat 🇸🇪', interests: ['🎵 Music'], lat: 59.33, lng: 18.07),
    SpeekUser(id: 'fatima', name: 'Fatima', age: 24, flag: '🇪🇬', country: 'Egypt',
        city: 'Cairo', role: SpeakerRole.learner, level: 'A2', levelXp: 4,
        photoUrl: 'https://images.unsplash.com/photo-1531746020798-e6953c6e8e04?auto=format&fit=crop&w=500&q=80',
        bio: 'Learning English for work ✨', interests: ['✈️ Travel'], lat: 30.04, lng: 31.24),
    SpeekUser(id: 'tunde', name: 'Tunde', age: 27, flag: '🇳🇬', country: 'Nigeria',
        city: 'Lagos', role: SpeakerRole.native, levelXp: 7, inCall: true,
        photoUrl: 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?auto=format&fit=crop&w=500&q=80',
        bio: 'Afrobeats & good vibes 🎶', interests: ['🎵 Music'], lat: 6.52, lng: 3.38),
    SpeekUser(id: 'sophia', name: 'Sophia', age: 22, flag: '🇺🇸', country: 'USA',
        city: 'Los Angeles', role: SpeakerRole.native, levelXp: 6,
        photoUrl: 'https://images.unsplash.com/photo-1438761681033-6461ffad8d80?auto=format&fit=crop&w=500&q=80',
        bio: 'Sunshine & surf 🌊', interests: ['🏄 Surf'], lat: 34.05, lng: -118.24),
    SpeekUser(id: 'lucas2', name: 'Lucas', age: 25, flag: '🇨🇦', country: 'Canada',
        city: 'Vancouver', role: SpeakerRole.native, levelXp: 8,
        photoUrl: 'https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?auto=format&fit=crop&w=500&q=80',
        bio: 'Mountains & maple 🍁', interests: ['🏔 Hiking'], lat: 49.28, lng: -123.12),
    SpeekUser(id: 'valentina', name: 'Valentina', age: 23, flag: '🇦🇷', country: 'Argentina',
        city: 'Buenos Aires', role: SpeakerRole.learner, level: 'B1', levelXp: 5, inCall: true,
        photoUrl: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?auto=format&fit=crop&w=500&q=80',
        bio: 'Tango & travel 💃', interests: ['💃 Dance'], lat: -34.60, lng: -58.38),
    SpeekUser(id: 'chen', name: 'Chen', age: 26, flag: '🇨🇳', country: 'China',
        city: 'Shanghai', role: SpeakerRole.learner, level: 'B2', levelXp: 10,
        photoUrl: 'https://images.unsplash.com/photo-1488161628813-04466f872be2?auto=format&fit=crop&w=500&q=80',
        bio: 'Coding & coffee ☕', interests: ['💻 Tech'], lat: 31.23, lng: 121.47),
    SpeekUser(id: 'minji', name: 'Min-ji', age: 22, flag: '🇰🇷', country: 'Korea',
        city: 'Busan', role: SpeakerRole.learner, level: 'B1', levelXp: 6,
        photoUrl: 'https://images.unsplash.com/photo-1524504388940-b1c1722653e1?auto=format&fit=crop&w=500&q=80',
        bio: 'K-drama & English 🎬', interests: ['🎬 Movies'], lat: 35.18, lng: 129.08),
    SpeekUser(id: 'arjun', name: 'Arjun', age: 27, flag: '🇮🇳', country: 'India',
        city: 'Delhi', role: SpeakerRole.learner, level: 'B2', levelXp: 9,
        photoUrl: 'https://images.unsplash.com/photo-1506794778202-cad84cf45f1d?auto=format&fit=crop&w=500&q=80',
        bio: 'Cricket & conversation 🏏', interests: ['⚽ Sports'], lat: 28.61, lng: 77.21),
    SpeekUser(id: 'amelia', name: 'Amelia', age: 24, flag: '🇦🇺', country: 'Australia',
        city: 'Melbourne', role: SpeakerRole.native, levelXp: 7,
        photoUrl: 'https://images.unsplash.com/photo-1544005313-94ddf0286df2?auto=format&fit=crop&w=500&q=80',
        bio: 'Coffee capital local ☕', interests: ['☕ Coffee'], lat: -37.81, lng: 144.96),
    SpeekUser(id: 'isabella', name: 'Isabella', age: 23, flag: '🇧🇷', country: 'Brazil',
        city: 'Rio de Janeiro', role: SpeakerRole.learner, level: 'A2', levelXp: 4,
        photoUrl: 'https://images.unsplash.com/photo-1494790108377-be9c29b29330?auto=format&fit=crop&w=500&q=80',
        bio: 'Praia e inglês 🏖', interests: ['🏖 Beach'], lat: -22.91, lng: -43.17),
  ];

  /// Everyone shown on the world map.
  static const mapUsers = [...nearbyUsers, ..._extra];

  static const countryClusters = [
    CountryCluster('🇺🇸', 'USA', 1200, 0.24, 0.27),
    CountryCluster('🇬🇧', 'UK', 840, 0.60, 0.25),
    CountryCluster('🇧🇷', 'Brazil', 510, 0.32, 0.62),
    CountryCluster('🇮🇳', 'India', 390, 0.72, 0.60),
    CountryCluster('🇪🇸', 'Spain', 220, 0.50, 0.46),
  ];

  static final chats = <Chat>[
    Chat(
      user: james,
      preview: 'You: That sounds great! 😄',
      timeLabel: '2m',
      unread: 2,
      messages: const [
        Message(text: 'Hey Chloe! Saw you\'re learning English 😊'),
        Message(text: 'Hi James! I\'m from Paris 🇫🇷', outgoing: true),
        Message(
            text: '', kind: MessageKind.voice, voiceDuration: '0:14'),
        Message(text: 'Sounds perfect 😄 Let\'s talk!', outgoing: true),
        Message(
            text: 'Missed voice call',
            kind: MessageKind.callLog),
        Message(text: 'That sounds great! 😄', outgoing: true),
      ],
    ),
    Chat(
      user: sofia,
      preview: 'Voice message · 0:14',
      timeLabel: '14m',
      previewIsVoice: true,
      messages: const [
        Message(text: 'Hola! Ready to practice? 🇪🇸'),
        Message(text: 'Yes! Let\'s do it', outgoing: true),
      ],
    ),
    Chat(
      user: yuki,
      preview: 'Nice talking to you!',
      timeLabel: '1h',
      messages: const [
        Message(text: 'Nice talking to you!'),
      ],
    ),
  ];

  static const requests = [
    Chat(
      user: noah,
      preview: '“Hey! Want to practice English?”',
      timeLabel: '3h',
      isRequest: true,
    ),
  ];

  static const onlineFriends = [james, sofia, yuki, noah];

  static final myBadges = [
    Badge('🔥', 'Streak', AppColors.warning.toARGB32()),
    Badge('🌍', 'Globetrotter', AppColors.brand500.toARGB32()),
    Badge('🎙', 'Chatterbox', AppColors.success.toARGB32()),
    const Badge('🔒', 'Polyglot', 0xFF444444, locked: true),
  ];

  static final badgeGallerySpeaking = [
    Badge('🎙', 'First call', AppColors.success.toARGB32()),
    Badge('💬', 'Talker', AppColors.brand500.toARGB32()),
    Badge('🗣', '50 calls', AppColors.like.toARGB32()),
    const Badge('🔒', '100 calls', 0xFF444444, locked: true),
  ];

  static final badgeGalleryGlobal = [
    Badge('🌍', '5 countries', AppColors.cyan.toARGB32()),
    Badge('✈️', '10 flags', AppColors.gold.toARGB32()),
    const Badge('🔒', '20 flags', 0xFF444444, locked: true),
    const Badge('🔒', 'Polyglot', 0xFF444444, locked: true),
  ];
}
