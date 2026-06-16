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
      bottomNavigationBar: _TabBar(
        index: _index,
        onChanged: (i) => setState(() => _index = i),
      ),
    );
  }
}

class _TabBar extends StatelessWidget {
  final int index;
  final ValueChanged<int> onChanged;
  const _TabBar({required this.index, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).padding.bottom;
    return SizedBox(
      height: 84 + bottomInset,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.bottomCenter,
        children: [
          // The bar itself
          ClipRect(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
              child: Container(
                height: 70 + bottomInset,
                decoration: BoxDecoration(
                  color: const Color(0xFF0C0C12).withValues(alpha: 0.94),
                  border: Border(
                      top: BorderSide(
                          color: Colors.white.withValues(alpha: 0.07))),
                ),
                padding: EdgeInsets.only(bottom: bottomInset),
                child: Row(
                  children: [
                    Expanded(
                      child: _SideTab(
                        icon: Icons.chat_bubble_outline_rounded,
                        activeIcon: Icons.chat_bubble_rounded,
                        label: 'Chats',
                        active: index == 0,
                        onTap: () => onChanged(0),
                      ),
                    ),
                    const Expanded(child: SizedBox()), // space for center button
                    Expanded(
                      child: _SideTab(
                        icon: Icons.person_outline_rounded,
                        activeIcon: Icons.person_rounded,
                        label: 'Profile',
                        active: index == 2,
                        onTap: () => onChanged(2),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Center "Map" killer button
          Positioned(
            bottom: 18 + bottomInset,
            child: _MapButton(
              active: index == 1,
              onTap: () => onChanged(1),
            ),
          ),
        ],
      ),
    );
  }
}

class _SideTab extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool active;
  final VoidCallback onTap;
  const _SideTab({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = active ? AppColors.brand400 : AppColors.n300;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(active ? activeIcon : icon, color: color, size: 25),
          const SizedBox(height: 4),
          Text(label,
              style: AppText.caption.copyWith(
                  color: color, fontSize: 11, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

/// The elevated center Map button — the app's primary action.
class _MapButton extends StatelessWidget {
  final bool active;
  final VoidCallback onTap;
  const _MapButton({required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 68,
            height: 68,
            decoration: BoxDecoration(
              gradient: AppColors.grad,
              shape: BoxShape.circle,
              border: Border.all(
                  color: active
                      ? Colors.white.withValues(alpha: 0.85)
                      : Colors.white.withValues(alpha: 0.12),
                  width: 3),
              boxShadow: [
                BoxShadow(
                    color: AppColors.brand500.withValues(alpha: 0.55),
                    blurRadius: 22,
                    offset: const Offset(0, 10)),
              ],
            ),
            child: const Icon(Icons.public_rounded, color: Colors.white, size: 32),
          ),
          const SizedBox(height: 4),
          Text('Map',
              style: AppText.caption.copyWith(
                  color: active ? AppColors.brand300 : AppColors.n200,
                  fontSize: 11,
                  fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}
