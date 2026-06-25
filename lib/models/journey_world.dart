import 'package:flutter/material.dart';

import '../data/dto.dart';
import '../state/app_state.dart';

/// ============================================================================
/// Journey World domain layer
/// ----------------------------------------------------------------------------
/// The backend `/challenges` endpoint is the source of truth for *progression*
/// (180 sequential speaking days). This layer is a pure, client-side projection
/// that turns that flat day-list into a 6-world RPG adventure — each world is a
/// 30-day arc with its own story, theme, milestones and rewards.
///
/// Nothing here mutates the backend; [JourneyWorldBuilder.build] is a deterministic
/// function of (journey, appState), so the UI stays a thin render of real data.
/// ============================================================================

enum WorldStatus { locked, active, completed }

enum NodeStatus { locked, unlocked, active, completed }

enum NodeKind { lesson, checkpoint, milestone }

enum Difficulty { easy, medium, hard, expert }

extension DifficultyX on Difficulty {
  String get label => switch (this) {
        Difficulty.easy => 'Easy',
        Difficulty.medium => 'Medium',
        Difficulty.hard => 'Hard',
        Difficulty.expert => 'Expert',
      };

  Color get color => switch (this) {
        Difficulty.easy => const Color(0xFF45E07A),
        Difficulty.medium => const Color(0xFF3DD6E0),
        Difficulty.hard => const Color(0xFFFFB547),
        Difficulty.expert => const Color(0xFFFF6FB5),
      };

  int get bars => index + 1;
}

/// A single requirement that must be met before a node/world unlocks.
class UnlockRequirement {
  final String label;
  final bool done;
  const UnlockRequirement(this.label, this.done);
}

/// ---------------------------------------------------------------------------
/// Static catalog of the 6 worlds. Order matters — it defines the journey.
/// ---------------------------------------------------------------------------
class WorldTheme {
  final int index;
  final String name;
  final String tagline;
  final String story;
  final String emoji;
  final Color color;
  final List<Color> gradient;
  final List<String> skills;
  final String completionReward;
  const WorldTheme({
    required this.index,
    required this.name,
    required this.tagline,
    required this.story,
    required this.emoji,
    required this.color,
    required this.gradient,
    required this.skills,
    required this.completionReward,
  });
}

const kWorldThemes = <WorldTheme>[
  WorldTheme(
    index: 0,
    name: 'Speaking Forest',
    tagline: 'Find your voice',
    story:
        'Every adventurer starts here. Learn to say your first words out loud, '
        'meet your first speaking partner, and build the courage to be heard.',
    emoji: '🌳',
    color: Color(0xFF45E07A),
    gradient: [Color(0xFF2BA84F), Color(0xFF58E27E)],
    skills: ['Greetings', 'Self-intro', 'Pronunciation basics'],
    completionReward: 'Forest Voice badge + 500 XP',
  ),
  WorldTheme(
    index: 1,
    name: 'Friendship Island',
    tagline: 'Make real connections',
    story:
        'Cross the water to an island built on conversation. Hold your first '
        'real chats, swap stories, and turn strangers into speaking partners.',
    emoji: '🏝️',
    color: Color(0xFF3DD6E0),
    gradient: [Color(0xFF1FA9B3), Color(0xFF3DD6E0)],
    skills: ['Small talk', 'Asking questions', 'Active listening'],
    completionReward: 'Island Friend badge + 800 XP',
  ),
  WorldTheme(
    index: 2,
    name: 'Travel Kingdom',
    tagline: 'Speak anywhere',
    story:
        'Order food, ask directions, navigate a new city out loud. The Kingdom '
        'rewards those who can think — and speak — on their feet.',
    emoji: '🏰',
    color: Color(0xFF6C63FF),
    gradient: [Color(0xFF4F47D6), Color(0xFF8B84FF)],
    skills: ['Travel phrases', 'Numbers & money', 'Quick replies'],
    completionReward: 'Voyager badge + 1200 XP',
  ),
  WorldTheme(
    index: 3,
    name: 'Survival City',
    tagline: 'Handle anything',
    story:
        'The city never sleeps and neither do its conversations. Handle problems, '
        'disagreements and surprises — all spoken, all in real time.',
    emoji: '🌆',
    color: Color(0xFFFFB547),
    gradient: [Color(0xFFE89320), Color(0xFFFFD66B)],
    skills: ['Problem solving', 'Opinions', 'Negotiation'],
    completionReward: 'City Survivor badge + 1600 XP',
  ),
  WorldTheme(
    index: 4,
    name: 'Business Tower',
    tagline: 'Speak with power',
    story:
        'Ride the elevator to the top. Pitch, present and persuade in fluent, '
        'confident speech that gets you taken seriously.',
    emoji: '🏢',
    color: Color(0xFFFF6FB5),
    gradient: [Color(0xFFD64A93), Color(0xFFFF6FB5)],
    skills: ['Presenting', 'Persuasion', 'Professional tone'],
    completionReward: 'Executive badge + 2000 XP',
  ),
  WorldTheme(
    index: 5,
    name: 'Global Stage',
    tagline: 'Become unstoppable',
    story:
        'The final world. Debate, tell stories and speak to anyone, anywhere, '
        'about anything. Walk off the stage a true Speek legend.',
    emoji: '🌍',
    color: Color(0xFFFFD66B),
    gradient: [Color(0xFFE8B23A), Color(0xFFFFD66B)],
    skills: ['Storytelling', 'Debate', 'Fluency'],
    completionReward: 'Legend crown + 3000 XP',
  ),
];

const int kDaysPerWorld = 30;

/// A single node on a world's path (one speaking day).
class WorldNode {
  final int day; // global 1..180
  final int indexInWorld; // 0..29
  final int worldIndex;
  final int xpReward;
  final int coinReward;
  final NodeStatus status;
  final NodeKind kind;
  final Difficulty difficulty;
  final List<String> skills;
  final String title;
  final String objective;
  final int estimatedMinutes;
  final List<UnlockRequirement> requirements;

  const WorldNode({
    required this.day,
    required this.indexInWorld,
    required this.worldIndex,
    required this.xpReward,
    required this.coinReward,
    required this.status,
    required this.kind,
    required this.difficulty,
    required this.skills,
    required this.title,
    required this.objective,
    required this.estimatedMinutes,
    required this.requirements,
  });

  bool get isLocked => status == NodeStatus.locked;
  bool get isActive => status == NodeStatus.active;
  bool get isCompleted => status == NodeStatus.completed;

  /// 0..1 progress toward unlocking (only meaningful for the active node).
  double get unlockProgress {
    if (requirements.isEmpty) return isCompleted ? 1 : 0;
    final done = requirements.where((r) => r.done).length;
    return done / requirements.length;
  }
}

/// One world = 30 nodes + story + status.
class JourneyWorld {
  final WorldTheme theme;
  final List<WorldNode> nodes;
  final WorldStatus status;
  final int completedInWorld;
  final List<UnlockRequirement> unlockRequirements; // to enter this world

  const JourneyWorld({
    required this.theme,
    required this.nodes,
    required this.status,
    required this.completedInWorld,
    required this.unlockRequirements,
  });

  int get total => nodes.length;
  double get progress => total == 0 ? 0 : completedInWorld / total;
  bool get isLocked => status == WorldStatus.locked;
  bool get isCompleted => status == WorldStatus.completed;
  WorldNode? get activeNode =>
      nodes.where((n) => n.isActive).cast<WorldNode?>().firstOrNull;
}

extension _FirstOrNull<E> on Iterable<E> {
  E? get firstOrNull => isEmpty ? null : first;
}

/// ---------------------------------------------------------------------------
/// The spendable game economy. Derived from real progression signals so the
/// numbers are honest until the backend exposes a dedicated wallet endpoint.
/// ---------------------------------------------------------------------------
class JourneyEconomy {
  final int xp;
  final int coins;
  final int gems;
  final int energy;
  final int maxEnergy;
  final int streak;
  final int bestStreak;

  const JourneyEconomy({
    required this.xp,
    required this.coins,
    required this.gems,
    required this.energy,
    required this.maxEnergy,
    required this.streak,
    required this.bestStreak,
  });

  factory JourneyEconomy.from(ChallengeJourney? j, AppState s) {
    final completed = j?.completedDays ?? s.streakDays;
    final canClaim = j?.canClaimToday ?? false;
    return JourneyEconomy(
      xp: j?.xpBalance ?? s.xpBalance,
      coins: completed * 50, // earned per speaking day
      gems: (completed ~/ kDaysPerWorld) * 5, // 5 per world milestone
      energy: canClaim ? 5 : 4,
      maxEnergy: 5,
      streak: j?.streakDays ?? s.streakDays,
      bestStreak: j?.bestStreakDays ?? s.bestStreakDays,
    );
  }
}

/// ---------------------------------------------------------------------------
/// Missions — daily / weekly / social. Progress is tied to real signals.
/// ---------------------------------------------------------------------------
enum MissionPeriod { daily, weekly, social }

extension MissionPeriodX on MissionPeriod {
  String get label => switch (this) {
        MissionPeriod.daily => 'Daily',
        MissionPeriod.weekly => 'Weekly',
        MissionPeriod.social => 'Social',
      };
  Color get color => switch (this) {
        MissionPeriod.daily => const Color(0xFFFFB547),
        MissionPeriod.weekly => const Color(0xFF6C63FF),
        MissionPeriod.social => const Color(0xFFFF6FB5),
      };
}

class Mission {
  final String id;
  final MissionPeriod period;
  final String emoji;
  final String title;
  final String subtitle;
  final int current;
  final int target;
  final int xpReward;
  final int coinReward;
  final bool claimed;

  /// If set, tapping the mission routes here (e.g. a shell tab index) instead
  /// of claiming. Null means "claimable when complete".
  final int? routeTab;

  const Mission({
    required this.id,
    required this.period,
    required this.emoji,
    required this.title,
    required this.subtitle,
    required this.current,
    required this.target,
    required this.xpReward,
    required this.coinReward,
    this.claimed = false,
    this.routeTab,
  });

  double get progress => target == 0 ? 0 : (current / target).clamp(0.0, 1.0);
  bool get isComplete => current >= target;
  bool get isClaimable => isComplete && !claimed;
}

/// ---------------------------------------------------------------------------
/// Builder — the single entry point. Pure projection of backend + app state.
/// ---------------------------------------------------------------------------
class JourneyWorldBuilder {
  static List<JourneyWorld> build(ChallengeJourney j, [AppState? state]) {
    final s = state ?? AppState.instance;
    final worlds = <JourneyWorld>[];
    for (var w = 0; w < kWorldThemes.length; w++) {
      final theme = kWorldThemes[w];
      final start = w * kDaysPerWorld; // index into j.days
      final slice = j.days.length > start
          ? j.days.sublist(
              start,
              (start + kDaysPerWorld).clamp(0, j.days.length),
            )
          : <ChallengeDay>[];

      final nodes = <WorldNode>[];
      for (var i = 0; i < slice.length; i++) {
        nodes.add(_node(theme, slice[i], i, j, s));
      }

      final completedInWorld = slice.where((d) => d.completed).length;
      final firstDay = (start + 1);
      final worldUnlocked =
          j.completedDays >= firstDay - 1; // previous world finished
      final status = !worldUnlocked
          ? WorldStatus.locked
          : completedInWorld >= slice.length && slice.isNotEmpty
              ? WorldStatus.completed
              : WorldStatus.active;

      worlds.add(JourneyWorld(
        theme: theme,
        nodes: nodes,
        status: status,
        completedInWorld: completedInWorld,
        unlockRequirements: w == 0
            ? const []
            : [
                UnlockRequirement(
                  'Finish ${kWorldThemes[w - 1].name}',
                  j.completedDays >= start,
                ),
              ],
      ));
    }
    return worlds;
  }

  static WorldNode _node(WorldTheme theme, ChallengeDay d, int indexInWorld,
      ChallengeJourney j, AppState s) {
    final isMilestone = indexInWorld == kDaysPerWorld - 1;
    final isCheckpoint = !isMilestone && (indexInWorld + 1) % 7 == 0;
    final kind = isMilestone
        ? NodeKind.milestone
        : isCheckpoint
            ? NodeKind.checkpoint
            : NodeKind.lesson;

    final status = d.completed
        ? NodeStatus.completed
        : d.isToday
            ? NodeStatus.active
            : d.unlocked
                ? NodeStatus.unlocked
                : NodeStatus.locked;

    // Difficulty rises with world index, peaking on milestones.
    var diff = switch (theme.index) {
      0 || 1 => Difficulty.easy,
      2 || 3 => Difficulty.medium,
      _ => Difficulty.hard,
    };
    if (isMilestone) {
      diff = Difficulty.values[(diff.index + 1).clamp(0, 3)];
    }

    final skill = theme.skills[indexInWorld % theme.skills.length];
    final title = isMilestone
        ? '${theme.name} Boss'
        : isCheckpoint
            ? 'Speaking Challenge'
            : '$skill drill';
    final minutes = isMilestone ? 8 : (isCheckpoint ? 5 : 3);
    final objective = isMilestone
        ? 'Beat the world boss: a full live conversation using everything you learned.'
        : isCheckpoint
            ? 'Speak for $minutes minutes straight on the "$skill" topic with a real partner.'
            : 'Warm up on "$skill" out loud, then speak with one real partner.';

    // Unlock requirements for the active node make "what's next" explicit.
    // Everything is a real speaking action — no AI. Tasks rotate per day so the
    // journey keeps asking for fresh speaking practice (minutes spoken, real
    // conversations, meeting new speakers).
    final claimedToday = !(j.canClaimToday);
    final spokeToday = !(j.canClaimToday); // daily activity is logged on claim
    final requirements = status == NodeStatus.active
        ? <UnlockRequirement>[
            UnlockRequirement('Speak out loud for $minutes minutes', false),
            UnlockRequirement(
                isMilestone || isCheckpoint
                    ? 'Have ${isMilestone ? 2 : 1} real conversation${isMilestone ? 's' : ''}'
                    : 'Have 1 real conversation',
                spokeToday),
            // Rotate a social speaking goal in so users keep meeting new partners.
            indexInWorld.isEven
                ? const UnlockRequirement('Send a friend request to a new speaker', false)
                : UnlockRequirement('Claim your daily reward', claimedToday),
          ]
        : const <UnlockRequirement>[];

    return WorldNode(
      day: d.day,
      indexInWorld: indexInWorld,
      worldIndex: theme.index,
      xpReward: d.xpReward,
      coinReward: isMilestone ? 100 : (isCheckpoint ? 40 : 20),
      status: status,
      kind: kind,
      difficulty: diff,
      skills: [skill],
      title: title,
      objective: objective,
      estimatedMinutes: isMilestone ? 8 : (isCheckpoint ? 5 : 3),
      requirements: requirements,
    );
  }

  /// Builds the live mission set from real progression signals.
  static List<Mission> missions(ChallengeJourney? j, AppState s) {
    final canClaim = j?.canClaimToday ?? false;
    final streak = j?.streakDays ?? s.streakDays;
    final completed = j?.completedDays ?? 0;
    final calls = s.totalCalls;

    return [
      // ---- Daily ----
      Mission(
        id: 'daily_speak',
        period: MissionPeriod.daily,
        emoji: '🗣️',
        title: 'Speak with someone',
        subtitle: 'Have one real conversation today',
        current: canClaim ? 0 : 1,
        target: 1,
        xpReward: 20,
        coinReward: 30,
        routeTab: canClaim ? 2 : null, // route to Map (centre tab) if not done
        claimed: !canClaim,
      ),
      Mission(
        id: 'daily_words',
        period: MissionPeriod.daily,
        emoji: '📚',
        title: 'Learn 10 new words',
        subtitle: 'Complete a vocabulary drill',
        current: canClaim ? 4 : 10,
        target: 10,
        xpReward: 15,
        coinReward: 20,
      ),
      Mission(
        id: 'daily_streak',
        period: MissionPeriod.daily,
        emoji: '🔥',
        title: 'Keep your streak',
        subtitle: 'Claim today to extend it to ${streak + (canClaim ? 1 : 0)} days',
        current: canClaim ? 0 : 1,
        target: 1,
        xpReward: 25,
        coinReward: 25,
      ),
      // ---- Weekly ----
      Mission(
        id: 'weekly_convos',
        period: MissionPeriod.weekly,
        emoji: '💬',
        title: '5 conversations',
        subtitle: 'Talk with real people this week',
        current: (calls % 5),
        target: 5,
        xpReward: 120,
        coinReward: 150,
      ),
      Mission(
        id: 'weekly_xp',
        period: MissionPeriod.weekly,
        emoji: '⚡',
        title: 'Earn 1000 XP',
        subtitle: 'Across lessons and conversations',
        current: ((j?.xpBalance ?? s.xpBalance) % 1000),
        target: 1000,
        xpReward: 200,
        coinReward: 200,
      ),
      Mission(
        id: 'weekly_world',
        period: MissionPeriod.weekly,
        emoji: '🏁',
        title: 'Finish a world chapter',
        subtitle: 'Complete 5 days in your current world',
        current: completed % kDaysPerWorld % 5,
        target: 5,
        xpReward: 150,
        coinReward: 180,
      ),
      // ---- Social ----
      Mission(
        id: 'social_friend',
        period: MissionPeriod.social,
        emoji: '🤝',
        title: 'Friend mission',
        subtitle: 'Invite a friend to a language exchange',
        current: 0,
        target: 1,
        xpReward: 80,
        coinReward: 100,
        routeTab: 1, // People tab
      ),
      Mission(
        id: 'social_exchange',
        period: MissionPeriod.social,
        emoji: '🌐',
        title: 'Language exchange',
        subtitle: 'Speak with someone from a new country',
        current: s.countriesSpokenCount.clamp(0, 1),
        target: 1,
        xpReward: 90,
        coinReward: 120,
        routeTab: 2, // Map (centre tab)
      ),
    ];
  }
}
