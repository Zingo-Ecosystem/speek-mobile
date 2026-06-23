import 'package:flutter/material.dart';

import '../../models/journey_world.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text.dart';
import '../../theme/app_theme.dart';

/// A horizontally-categorised Mission Center: Daily / Weekly / Social tabs with
/// animated progress cards and claim buttons.
class MissionCenter extends StatefulWidget {
  final List<Mission> missions;
  final void Function(Mission) onClaim;
  final void Function(Mission) onRoute;
  const MissionCenter({
    super.key,
    required this.missions,
    required this.onClaim,
    required this.onRoute,
  });

  @override
  State<MissionCenter> createState() => _MissionCenterState();
}

class _MissionCenterState extends State<MissionCenter> {
  MissionPeriod _period = MissionPeriod.daily;

  @override
  Widget build(BuildContext context) {
    final list =
        widget.missions.where((m) => m.period == _period).toList();
    final claimable = widget.missions.where((m) => m.isClaimable).length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: Insets.x5),
          child: Row(children: [
            const Text('🎖️', style: TextStyle(fontSize: 20)),
            const SizedBox(width: 8),
            Text('Mission Center', style: AppText.h3),
            const Spacer(),
            if (claimable > 0)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text('$claimable to claim',
                    style: AppText.caption.copyWith(
                        color: AppColors.success, fontWeight: FontWeight.w800)),
              ),
          ]),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 36,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: Insets.x5),
            children: [
              for (final p in MissionPeriod.values) _tab(p),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: Insets.x5),
          child: Column(
            children: [
              for (final m in list) ...[
                _MissionCard(
                  mission: m,
                  onClaim: () => widget.onClaim(m),
                  onRoute: () => widget.onRoute(m),
                ),
                const SizedBox(height: 10),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _tab(MissionPeriod p) {
    final active = p == _period;
    final count = widget.missions.where((m) => m.period == p && m.isClaimable).length;
    return GestureDetector(
      onTap: () => setState(() => _period = p),
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
        decoration: BoxDecoration(
          gradient: active ? LinearGradient(colors: [p.color, p.color.withValues(alpha: 0.7)]) : null,
          color: active ? null : AppColors.sFill(0.05),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: active ? Colors.transparent : AppColors.borderSubtle),
        ),
        child: Row(children: [
          Text(p.label,
              style: AppText.caption.copyWith(
                  color: active ? Colors.white : AppColors.sText3,
                  fontWeight: FontWeight.w800)),
          if (count > 0) ...[
            const SizedBox(width: 6),
            Container(
              width: 18,
              height: 18,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: active ? Colors.white : AppColors.success,
                shape: BoxShape.circle,
              ),
              child: Text('$count',
                  style: AppText.caption.copyWith(
                      color: active ? p.color : Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w900)),
            ),
          ],
        ]),
      ),
    );
  }
}

class _MissionCard extends StatelessWidget {
  final Mission mission;
  final VoidCallback onClaim;
  final VoidCallback onRoute;
  const _MissionCard({
    required this.mission,
    required this.onClaim,
    required this.onRoute,
  });

  @override
  Widget build(BuildContext context) {
    final m = mission;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.sFill(0.05),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
            color: m.isClaimable
                ? AppColors.success.withValues(alpha: 0.5)
                : AppColors.borderSubtle),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: m.period.color.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(14),
            ),
            child: m.claimed
                ? Icon(Icons.check_rounded, color: AppColors.success)
                : Text(m.emoji, style: const TextStyle(fontSize: 22)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Expanded(child: Text(m.title, style: AppText.label)),
                  Text('+${m.xpReward} XP',
                      style: AppText.caption.copyWith(
                          color: AppColors.gold, fontWeight: FontWeight.w800, fontSize: 11)),
                ]),
                const SizedBox(height: 2),
                Text(m.subtitle,
                    style: AppText.caption.copyWith(
                        color: AppColors.sText3, fontSize: 11)),
                const SizedBox(height: 8),
                Row(children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: TweenAnimationBuilder<double>(
                        duration: const Duration(milliseconds: 600),
                        curve: Curves.easeOutCubic,
                        tween: Tween(begin: 0, end: m.progress),
                        builder: (_, v, __) => Stack(children: [
                          Container(height: 7, color: AppColors.sFill(0.12)),
                          FractionallySizedBox(
                            widthFactor: v,
                            child: Container(
                              height: 7,
                              decoration: BoxDecoration(
                                color: m.period.color,
                                borderRadius: BorderRadius.circular(6),
                              ),
                            ),
                          ),
                        ]),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text('${m.current}/${m.target}',
                      style: AppText.caption.copyWith(
                          color: AppColors.sText3, fontSize: 10.5)),
                ]),
              ],
            ),
          ),
          const SizedBox(width: 10),
          _action(),
        ],
      ),
    );
  }

  Widget _action() {
    if (m.claimed) {
      return Text('Done',
          style: AppText.caption.copyWith(
              color: AppColors.success, fontWeight: FontWeight.w800));
    }
    if (m.isClaimable) {
      return GestureDetector(
        onTap: onClaim,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          decoration: BoxDecoration(
            gradient: AppColors.gradGold,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                  color: AppColors.gold.withValues(alpha: 0.4),
                  blurRadius: 12,
                  offset: const Offset(0, 4)),
            ],
          ),
          child: Text('Claim',
              style: AppText.caption.copyWith(
                  color: const Color(0xFF3A2600), fontWeight: FontWeight.w900)),
        ),
      );
    }
    if (m.routeTab != null) {
      return GestureDetector(
        onTap: onRoute,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
          decoration: BoxDecoration(
            gradient: AppColors.grad,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 18),
        ),
      );
    }
    return Icon(Icons.lock_outline_rounded, color: AppColors.sText3, size: 18);
  }

  Mission get m => mission;
}
