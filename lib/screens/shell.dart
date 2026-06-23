import 'dart:ui';

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_text.dart';
import 'chat/chat_list_screen.dart';
import 'map/map_screen.dart';
import 'profile/profile_screen.dart';
import 'social/people_screen.dart';
import 'store/challenge_journey_screen.dart';

/// Lets any screen request a navbar tab switch (e.g. a "Find someone" CTA on
/// the Journey tab jumping to the Map). Tab indexes: 0 Chats, 1 Map, 2 People,
/// 3 Journey, 4 Me.
class ShellNav {
  ShellNav._();
  static void Function(int index)? _switch;
  static void goTo(int index) => _switch?.call(index);
  // Map is the centre, hero tab — the app's killer feature.
  static const int chats = 0, people = 1, map = 2, journey = 3, me = 4;
}

class ShellScreen extends StatefulWidget {
  final int initialIndex;
  const ShellScreen({super.key, this.initialIndex = ShellNav.map});

  @override
  State<ShellScreen> createState() => _ShellScreenState();
}

class _ShellScreenState extends State<ShellScreen> {
  late int _index = widget.initialIndex;

  late final _pages = const [
    ChatListScreen(),
    PeopleScreen(),
    MapScreen(),
    ChallengeJourneyScreen(),
    ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    ShellNav._switch = (i) {
      if (mounted) setState(() => _index = i);
    };
  }

  @override
  void dispose() {
    ShellNav._switch = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: IndexedStack(index: _index, children: _pages),
      bottomNavigationBar: LiquidNavBar(
        index: _index,
        onChanged: (i) => setState(() => _index = i),
      ),
    );
  }
}

/// A modern floating "liquid" navigation bar: a glassy pill that floats above
/// the content, with a gradient blob that fluidly glides under the active tab
/// and each icon morphing into its filled, glowing variant when selected.
class LiquidNavBar extends StatelessWidget {
  final int index;
  final ValueChanged<int> onChanged;
  const LiquidNavBar({super.key, required this.index, required this.onChanged});

  static const _items = <_NavItem>[
    _NavItem(
      icon: Icons.forum_outlined,
      activeIcon: Icons.forum_rounded,
      label: 'Chats',
      tint: AppColors.cyan,
    ),
    _NavItem(
      icon: Icons.people_outline_rounded,
      activeIcon: Icons.people_rounded,
      label: 'People',
      tint: AppColors.like,
    ),
    // Centre hero tab — rendered as a raised gradient button, not a flat cell.
    _NavItem(
      icon: Icons.public_rounded,
      activeIcon: Icons.public_rounded,
      label: 'Map',
      tint: AppColors.brand400,
    ),
    _NavItem(
      icon: Icons.local_fire_department_outlined,
      activeIcon: Icons.local_fire_department_rounded,
      label: 'Journey',
      tint: AppColors.warning,
    ),
    _NavItem(
      icon: Icons.auto_awesome_outlined,
      activeIcon: Icons.auto_awesome_rounded,
      label: 'Me',
      tint: AppColors.gold,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).padding.bottom;
    const center = ShellNav.map;
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 0, 20, 14 + bottomInset),
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.topCenter,
        children: [
          ClipRRect(
        borderRadius: BorderRadius.circular(30),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
          child: Container(
            height: 70,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(30),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  const Color(0xFF16161F).withValues(alpha: 0.92),
                  const Color(0xFF0C0C12).withValues(alpha: 0.96),
                ],
              ),
              border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.45),
                  blurRadius: 28,
                  offset: const Offset(0, 12),
                ),
                BoxShadow(
                  color: _items[index].tint.withValues(alpha: 0.18),
                  blurRadius: 34,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: LayoutBuilder(
              builder: (context, c) {
                final slot = c.maxWidth / _items.length;
                return Stack(
                  children: [
                    // The gliding liquid blob behind the active tab.
                    AnimatedAlign(
                      duration: const Duration(milliseconds: 420),
                      curve: Curves.easeOutCubic,
                      alignment: Alignment(
                          _items.length == 1
                              ? 0
                              : (index / (_items.length - 1)) * 2 - 1,
                          0),
                      child: Container(
                        width: slot - 26,
                        height: 50,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(22),
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              _items[index].tint.withValues(alpha: 0.30),
                              _items[index].tint.withValues(alpha: 0.10),
                            ],
                          ),
                          border: Border.all(
                              color: _items[index]
                                  .tint
                                  .withValues(alpha: 0.45),
                              width: 1),
                        ),
                      ),
                    ),
                    Row(
                      children: [
                        for (int i = 0; i < _items.length; i++)
                          Expanded(
                            child: i == center
                                ? const SizedBox.shrink()
                                : _NavCell(
                                    item: _items[i],
                                    active: index == i,
                                    onTap: () => onChanged(i),
                                  ),
                          ),
                      ],
                    ),
                  ],
                );
              },
            ),
          ),
        ),
          ),
          // The raised, creative hero button for the Map — our killer feature.
          _HeroNavButton(
            item: _items[center],
            active: index == center,
            onTap: () => onChanged(center),
          ),
        ],
      ),
    );
  }
}

/// The centre Map button — a raised, glowing gradient orb that floats above the
/// nav bar to signal it's the app's primary, hero destination.
class _HeroNavButton extends StatefulWidget {
  final _NavItem item;
  final bool active;
  final VoidCallback onTap;
  const _HeroNavButton(
      {required this.item, required this.active, required this.onTap});

  @override
  State<_HeroNavButton> createState() => _HeroNavButtonState();
}

class _HeroNavButtonState extends State<_HeroNavButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _glow = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 2200))
    ..repeat(reverse: true);

  @override
  void dispose() {
    _glow.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tint = widget.item.tint;
    final active = widget.active;
    return Positioned(
      top: -22,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onTap,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedBuilder(
              animation: _glow,
              builder: (context, _) {
                final t = _glow.value;
                return SizedBox(
                  width: 76,
                  height: 60,
                  child: Stack(
                    alignment: Alignment.center,
                    clipBehavior: Clip.none,
                    children: [
                      // Liquid energy ring — expands & fades, stronger when active.
                      Container(
                        width: 58 + (active ? 10 * t : 4 * t),
                        height: 58 + (active ? 10 * t : 4 * t),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: tint.withValues(
                                alpha: (active ? 0.40 : 0.16) * (1 - t)),
                            width: 2,
                          ),
                        ),
                      ),
                      // The hero orb.
                      AnimatedScale(
                        duration: const Duration(milliseconds: 320),
                        curve: Curves.easeOutBack,
                        scale: active ? 1.06 : 1.0,
                        child: Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Color.lerp(tint, Colors.white, 0.28)!,
                                AppColors.brand500,
                                AppColors.brand700,
                              ],
                              stops: const [0.0, 0.55, 1.0],
                            ),
                            border: Border.all(
                                color: Colors.white.withValues(alpha: 0.22),
                                width: 1.5),
                            boxShadow: [
                              // Coloured liquid glow that breathes when active.
                              BoxShadow(
                                color: tint.withValues(
                                    alpha: active ? 0.42 + 0.22 * t : 0.22),
                                blurRadius: active ? 20 + 10 * t : 14,
                                spreadRadius: active ? 1 + t : 0,
                              ),
                              // Grounding drop shadow so it reads as raised.
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.45),
                                blurRadius: 14,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              // Soft glossy highlight on the upper half.
                              Align(
                                alignment: Alignment.topCenter,
                                child: Container(
                                  margin: const EdgeInsets.only(top: 6),
                                  width: 34,
                                  height: 18,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(20),
                                    gradient: LinearGradient(
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                      colors: [
                                        Colors.white.withValues(alpha: 0.45),
                                        Colors.white.withValues(alpha: 0.0),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              const Icon(Icons.public_rounded,
                                  color: Colors.white, size: 28),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 5),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 250),
              style: AppText.caption.copyWith(
                color: active ? tint : AppColors.n300,
                fontSize: active ? 11.5 : 11,
                fontWeight: active ? FontWeight.w800 : FontWeight.w600,
                letterSpacing: active ? 0.2 : 0,
              ),
              child: Text(widget.item.label),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final Color tint;
  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.tint,
  });
}

class _NavCell extends StatelessWidget {
  final _NavItem item;
  final bool active;
  final VoidCallback onTap;
  const _NavCell(
      {required this.item, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final color = active ? item.tint : AppColors.n300;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedScale(
            duration: const Duration(milliseconds: 320),
            curve: Curves.easeOutBack,
            scale: active ? 1.16 : 1.0,
            child: Icon(active ? item.activeIcon : item.icon,
                color: color, size: 24),
          ),
          const SizedBox(height: 4),
          AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 250),
            style: AppText.caption.copyWith(
              color: color,
              fontSize: active ? 11.5 : 11,
              fontWeight: active ? FontWeight.w800 : FontWeight.w600,
              letterSpacing: active ? 0.2 : 0,
            ),
            child: Text(item.label),
          ),
        ],
      ),
    );
  }
}
