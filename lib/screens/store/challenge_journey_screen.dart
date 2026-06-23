import 'package:flutter/material.dart';

import '../../data/dto.dart';
import '../../data/repositories.dart';
import '../../models/journey_world.dart';
import '../../state/app_state.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text.dart';
import '../../theme/app_theme.dart';
import '../../widgets/journey/journey_celebrations.dart';
import '../../widgets/journey/mission_center.dart';
import '../../widgets/journey/node_detail_sheet.dart';
import '../../widgets/journey/world_banner.dart';
import '../../widgets/journey/world_path.dart';
import '../../widgets/snack.dart';
import '../shell.dart';

/// The redesigned Journey — a 6-world speaking adventure (Speaking Forest →
/// Global Stage). Progression is driven by the live `/challenges` data and
/// projected into worlds, nodes and missions by [JourneyWorldBuilder]. This
/// widget is a thin orchestrator: load → build → render → celebrate.
class ChallengeJourneyScreen extends StatefulWidget {
  const ChallengeJourneyScreen({super.key});

  @override
  State<ChallengeJourneyScreen> createState() => _ChallengeJourneyScreenState();
}

class _ChallengeJourneyScreenState extends State<ChallengeJourneyScreen>
    with SingleTickerProviderStateMixin {
  ChallengeJourney? _j;
  bool _loading = true;
  bool _claiming = false;
  final Set<String> _claimedMissions = {};

  late final AnimationController _pulse = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 1400))
    ..repeat(reverse: true);

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final j = await Repos.marketplace.journey();
      if (mounted) setState(() => _j = j);
    } catch (_) {
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // ---- Actions ----
  Future<void> _claimDaily() async {
    if (_claiming) return;
    setState(() => _claiming = true);
    final granted = await AppState.instance.claimDailyReward();
    if (!mounted) return;
    setState(() => _claiming = false);
    if (granted > 0) {
      await showRewardCelebration(
        context,
        emoji: '🔥',
        title: 'Streak extended!',
        subtitle: 'Come back tomorrow to keep it alive.',
        xp: granted,
      );
      _load();
    } else {
      showSnack(context, 'Already claimed today — come back tomorrow!');
    }
  }

  Future<void> _claimMission(Mission m) async {
    // The streak mission is the real backend-backed one.
    if (m.id == 'daily_streak' || m.id == 'daily_speak') {
      await _claimDaily();
      return;
    }
    setState(() => _claimedMissions.add(m.id));
    await showRewardCelebration(
      context,
      emoji: m.emoji,
      title: 'Mission complete!',
      subtitle: m.title,
      xp: m.xpReward,
    );
  }

  void _routeMission(Mission m) {
    if (m.routeTab != null) ShellNav.goTo(m.routeTab!);
  }

  void _openNode(WorldNode node, WorldTheme theme) {
    final label = node.isCompleted
        ? 'Review'
        : node.isActive
            ? 'Start speaking'
            : 'Preview';
    NodeDetailSheet.show(
      context,
      node: node,
      theme: theme,
      primaryLabel: label,
      onPrimary: () {
        if (node.isActive) {
          ShellNav.goTo(ShellNav.map); // speaking-first: go find a partner
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.of(context).padding.top;

    if (_loading) {
      return const Scaffold(
        backgroundColor: AppColors.bgApp,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final j = _j;
    final econ = JourneyEconomy.from(j, AppState.instance);
    final worlds = j != null ? JourneyWorldBuilder.build(j) : <JourneyWorld>[];
    final missions = JourneyWorldBuilder.missions(j, AppState.instance)
        .map((m) => _claimedMissions.contains(m.id)
            ? Mission(
                id: m.id,
                period: m.period,
                emoji: m.emoji,
                title: m.title,
                subtitle: m.subtitle,
                current: m.target,
                target: m.target,
                xpReward: m.xpReward,
                coinReward: m.coinReward,
                claimed: true,
              )
            : m)
        .toList();

    final activeWorld = worlds.firstWhere(
      (w) => w.status == WorldStatus.active,
      orElse: () => worlds.isNotEmpty ? worlds.first : _emptyWorld(),
    );

    return Scaffold(
      backgroundColor: AppColors.bgApp,
      body: RefreshIndicator(
        onRefresh: _load,
        color: AppColors.warning,
        child: ListView(
          padding: EdgeInsets.only(top: topPad, bottom: 140),
          children: [
            _EconomyHeader(econ: econ, pulse: _pulse),
            const SizedBox(height: 18),
            _todayCard(activeWorld, econ),
            const SizedBox(height: 24),
            MissionCenter(
              missions: missions,
              onClaim: _claimMission,
              onRoute: _routeMission,
            ),
            const SizedBox(height: 8),
            _worldMapTitle(econ),
            for (final world in worlds) ...[
              WorldBanner(world: world),
              if (!world.isLocked)
                WorldPath(
                  world: world,
                  pulse: _pulse,
                  onTapNode: (n) => _openNode(n, world.theme),
                ),
            ],
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  JourneyWorld _emptyWorld() => JourneyWorld(
        theme: kWorldThemes.first,
        nodes: const [],
        status: WorldStatus.active,
        completedInWorld: 0,
        unlockRequirements: const [],
      );

  // ---- Today's focus card ----
  Widget _todayCard(JourneyWorld world, JourneyEconomy econ) {
    final node = world.activeNode;
    final canClaim = _j?.canClaimToday ?? false;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: Insets.x5),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              world.theme.color.withValues(alpha: 0.24),
              AppColors.warning.withValues(alpha: 0.12),
            ],
          ),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: world.theme.color.withValues(alpha: 0.45)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              const Text('🎯', style: TextStyle(fontSize: 20)),
              const SizedBox(width: 8),
              Text("Today's quest", style: AppText.h3),
              const Spacer(),
              Text(world.theme.name,
                  style: AppText.caption.copyWith(
                      color: world.theme.color, fontWeight: FontWeight.w700)),
            ]),
            const SizedBox(height: 14),
            if (node != null)
              _questRow(
                emoji: '🗣️',
                title: node.title,
                subtitle: node.objective,
                actionLabel: 'Speak',
                onAction: () => _openNode(node, world.theme),
              ),
            const SizedBox(height: 10),
            _questRow(
              emoji: '🎁',
              title: 'Daily reward',
              subtitle: canClaim
                  ? 'Claim today to extend your ${econ.streak}-day streak.'
                  : 'Collected! Come back tomorrow for more.',
              actionLabel: canClaim ? 'Claim' : 'Done',
              done: !canClaim,
              busy: _claiming,
              onAction: canClaim ? _claimDaily : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _questRow({
    required String emoji,
    required String title,
    required String subtitle,
    required String actionLabel,
    bool done = false,
    bool busy = false,
    VoidCallback? onAction,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.sFill(0.05),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
            color: done
                ? AppColors.success.withValues(alpha: 0.4)
                : AppColors.borderSubtle),
      ),
      child: Row(children: [
        Container(
          width: 40,
          height: 40,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: done
                ? AppColors.success.withValues(alpha: 0.16)
                : AppColors.brand500.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(12),
          ),
          child: done
              ? Icon(Icons.check_rounded, color: AppColors.success)
              : Text(emoji, style: const TextStyle(fontSize: 18)),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: AppText.label, maxLines: 1, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 2),
              Text(subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.caption.copyWith(
                      fontSize: 11, color: AppColors.sText3)),
            ],
          ),
        ),
        const SizedBox(width: 8),
        if (busy)
          const SizedBox(
              width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
        else if (onAction != null)
          GestureDetector(
            onTap: onAction,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                  gradient: AppColors.grad,
                  borderRadius: BorderRadius.circular(10)),
              child: Text(actionLabel,
                  style: AppText.caption.copyWith(
                      color: Colors.white, fontWeight: FontWeight.w700)),
            ),
          )
        else
          Text(actionLabel,
              style: AppText.caption.copyWith(
                  color: AppColors.success, fontWeight: FontWeight.w700)),
      ]),
    );
  }

  Widget _worldMapTitle(JourneyEconomy econ) => Padding(
        padding: const EdgeInsets.fromLTRB(Insets.x5, 6, Insets.x5, 0),
        child: Row(children: [
          Text('World Map', style: AppText.h3),
          const SizedBox(width: 8),
          Text('· 6 worlds to legend',
              style: AppText.caption.copyWith(color: AppColors.sText3)),
        ]),
      );
}

/// The header: total XP, current streak and best streak — XP is the only
/// currency in the system.
class _EconomyHeader extends StatelessWidget {
  final JourneyEconomy econ;
  final Animation<double> pulse;
  const _EconomyHeader({required this.econ, required this.pulse});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(Insets.x5, 16, Insets.x5, 20),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF3A1E5E), Color(0xFF1A1430)],
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
      ),
      child: Column(
        children: [
          Row(children: [
            Text('Your Journey', style: AppText.h2),
            const Spacer(),
            AnimatedBuilder(
              animation: pulse,
              builder: (_, __) => Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                decoration: BoxDecoration(
                  color: AppColors.warning.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: AppColors.warning
                          .withValues(alpha: 0.4 + 0.3 * pulse.value)),
                ),
                child: Row(children: [
                  const Text('🔥', style: TextStyle(fontSize: 15)),
                  const SizedBox(width: 6),
                  Text('${econ.streak} day streak',
                      style: AppText.caption.copyWith(
                          color: AppColors.warning,
                          fontWeight: FontWeight.w800)),
                ]),
              ),
            ),
          ]),
          const SizedBox(height: 20),
          Row(children: [
            Expanded(child: _stat('⚡', '${econ.xp}', 'Total XP')),
            Container(
                width: 1,
                height: 34,
                color: Colors.white.withValues(alpha: 0.12)),
            Expanded(child: _stat('🏆', '${econ.bestStreak}', 'Best streak')),
          ]),
        ],
      ),
    );
  }

  Widget _stat(String emoji, String value, String label) => Column(
        children: [
          Row(mainAxisSize: MainAxisSize.min, children: [
            Text(emoji, style: const TextStyle(fontSize: 22)),
            const SizedBox(width: 8),
            Text(value,
                style: AppText.displayMd
                    .copyWith(fontSize: 26, color: Colors.white, height: 1)),
          ]),
          const SizedBox(height: 4),
          Text(label,
              style: AppText.caption
                  .copyWith(fontSize: 11, color: Colors.white54)),
        ],
      );
}
