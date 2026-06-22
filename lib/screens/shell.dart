import 'dart:ui';

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_text.dart';
import 'chat/chat_list_screen.dart';
import 'map/map_screen.dart';
import 'profile/profile_screen.dart';

class ShellScreen extends StatefulWidget {
  final int initialIndex;
  const ShellScreen({super.key, this.initialIndex = 1});

  @override
  State<ShellScreen> createState() => _ShellScreenState();
}

class _ShellScreenState extends State<ShellScreen> {
  late int _index = widget.initialIndex;

  late final _pages = const [
    ChatListScreen(),
    MapScreen(),
    ProfileScreen(),
  ];

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
      icon: Icons.travel_explore_rounded,
      activeIcon: Icons.public_rounded,
      label: 'Map',
      tint: AppColors.brand400,
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
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 0, 20, 14 + bottomInset),
      child: ClipRRect(
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
                            child: _NavCell(
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
