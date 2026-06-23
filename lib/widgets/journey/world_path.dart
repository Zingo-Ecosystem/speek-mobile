import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../models/journey_world.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text.dart';

/// A connected, 3D, winding path of nodes for a single world — Duolingo-style,
/// but theme-tinted per world and tappable for a rich detail sheet.
class WorldPath extends StatelessWidget {
  final JourneyWorld world;
  final Animation<double> pulse;
  final ValueChanged<WorldNode> onTapNode;
  const WorldPath({
    super.key,
    required this.world,
    required this.pulse,
    required this.onTapNode,
  });

  static const _rowH = 110.0;

  @override
  Widget build(BuildContext context) {
    final nodes = world.nodes;
    return LayoutBuilder(
      builder: (context, c) {
        final w = c.maxWidth;
        final centerX = w / 2;
        final amp = (w / 2 - 60).clamp(40.0, 120.0);
        double xAt(int i) => centerX + amp * math.sin(i * 0.7);
        double yAt(int i) => i * _rowH + _rowH / 2;

        final children = <Widget>[];
        for (var i = 0; i < nodes.length; i++) {
          final node = nodes[i];
          final size = switch (node.kind) {
            NodeKind.milestone => 84.0,
            NodeKind.checkpoint => 70.0,
            NodeKind.lesson => 62.0,
          };
          children.add(Positioned(
            left: xAt(i) - size / 2,
            top: yAt(i) - size / 2,
            child: _WorldNodeView(
              node: node,
              theme: world.theme,
              size: size,
              pulse: pulse,
              onTap: () => onTapNode(node),
            ),
          ));
        }

        return SizedBox(
          width: w,
          height: nodes.length * _rowH,
          child: Stack(
            children: [
              Positioned.fill(
                child: CustomPaint(
                  painter: _ConnectorPainter(
                    count: nodes.length,
                    reached: nodes.map((n) => n.isCompleted).toList(),
                    color: world.theme.color,
                    xAt: xAt,
                    yAt: yAt,
                  ),
                ),
              ),
              ...children,
            ],
          ),
        );
      },
    );
  }
}

class _ConnectorPainter extends CustomPainter {
  final int count;
  final List<bool> reached;
  final Color color;
  final double Function(int) xAt, yAt;
  _ConnectorPainter({
    required this.count,
    required this.reached,
    required this.color,
    required this.xAt,
    required this.yAt,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (var i = 0; i < count - 1; i++) {
      final p0 = Offset(xAt(i), yAt(i));
      final p1 = Offset(xAt(i + 1), yAt(i + 1));
      final lit = reached[i] && reached[i + 1];
      final paint = Paint()
        ..strokeWidth = lit ? 7 : 5
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke
        ..color = lit
            ? color.withValues(alpha: 0.9)
            : Colors.white.withValues(alpha: 0.08);
      final path = Path()..moveTo(p0.dx, p0.dy);
      final midY = (p0.dy + p1.dy) / 2;
      path.cubicTo(p0.dx, midY, p1.dx, midY, p1.dx, p1.dy);
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _ConnectorPainter old) =>
      old.reached != reached || old.count != count || old.color != color;
}

/// A single tactile 3D node with status styling + a floating "START" bubble.
class _WorldNodeView extends StatelessWidget {
  final WorldNode node;
  final WorldTheme theme;
  final double size;
  final Animation<double> pulse;
  final VoidCallback onTap;
  const _WorldNodeView({
    required this.node,
    required this.theme,
    required this.size,
    required this.pulse,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    late Color top, rim;
    Widget center;

    if (node.isCompleted) {
      top = const Color(0xFF58E27E);
      rim = const Color(0xFF2BA84F);
      center = Icon(Icons.check_rounded, color: Colors.white, size: size * 0.42);
    } else if (node.isActive) {
      top = const Color(0xFFFFD66B);
      rim = const Color(0xFFD79A1E);
      center = Icon(Icons.bolt_rounded, color: Colors.white, size: size * 0.46);
    } else if (node.isLocked) {
      top = AppColors.n500;
      rim = AppColors.n700;
      center = Icon(Icons.lock_rounded,
          color: Colors.white.withValues(alpha: 0.45), size: size * 0.34);
    } else {
      // unlocked, not yet today
      top = theme.color;
      rim = Color.lerp(theme.color, Colors.black, 0.35)!;
      center = node.kind == NodeKind.milestone
          ? Text('🎁', style: TextStyle(fontSize: size * 0.42))
          : Text('${node.day}',
              style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: size * 0.32));
    }

    if (node.kind == NodeKind.milestone && !node.isCompleted) {
      center = Text(node.isActive ? '👑' : '🎁', style: TextStyle(fontSize: size * 0.44));
    }

    Widget core = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: top,
        border: Border.all(color: rim, width: 1),
        boxShadow: [
          BoxShadow(color: rim, offset: const Offset(0, 5), blurRadius: 0),
          if (node.isActive)
            BoxShadow(color: AppColors.gold.withValues(alpha: 0.55), blurRadius: 24),
          if (node.isCompleted)
            BoxShadow(
                color: const Color(0xFF45E07A).withValues(alpha: 0.4), blurRadius: 16),
        ],
      ),
      child: Center(child: center),
    );

    if (node.isActive) {
      core = AnimatedBuilder(
        animation: pulse,
        builder: (_, child) =>
            Transform.scale(scale: 1 + 0.05 * pulse.value, child: child),
        child: core,
      );
    }

    final labelColor = node.isCompleted
        ? const Color(0xFF58E27E)
        : node.isActive
            ? AppColors.gold
            : AppColors.sText3;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (node.isActive)
            _StartBubble(xp: node.xpReward)
          else
            const SizedBox(height: 2),
          const SizedBox(height: 4),
          core,
          const SizedBox(height: 8),
          Text(
            node.kind == NodeKind.milestone ? 'Day ${node.day} · Boss' : 'Day ${node.day}',
            style: AppText.caption.copyWith(
              fontSize: 10.5,
              color: labelColor,
              fontWeight: node.isActive || node.kind == NodeKind.milestone
                  ? FontWeight.w800
                  : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _StartBubble extends StatelessWidget {
  final int xp;
  const _StartBubble({required this.xp});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        gradient: AppColors.gradGold,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
              color: AppColors.gold.withValues(alpha: 0.4),
              blurRadius: 14,
              offset: const Offset(0, 4)),
        ],
      ),
      child: Text('START · +$xp XP',
          style: AppText.caption.copyWith(
              fontSize: 11,
              color: const Color(0xFF3A2600),
              fontWeight: FontWeight.w900,
              letterSpacing: 0.4)),
    );
  }
}
