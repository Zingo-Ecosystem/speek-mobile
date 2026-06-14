import 'package:flutter/material.dart';

import '../../models/models.dart';
import '../../state/app_state.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common.dart';
import '../call/incoming_call_screen.dart';
import '../chat/conversation_screen.dart';
import 'register_gate_sheet.dart';

/// Bottom sheet shown when tapping a user pin on the map.
Future<void> showUserPreview(BuildContext context, SpeekUser user) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withValues(alpha: 0.5),
    builder: (_) => _UserPreviewSheet(user: user),
  );
}

class _UserPreviewSheet extends StatelessWidget {
  final SpeekUser user;
  const _UserPreviewSheet({required this.user});

  void _call(BuildContext context) {
    Navigator.of(context).pop();
    if (!AppState.instance.isRegistered) {
      showRegisterGate(context, user);
    } else {
      Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => IncomingCallScreen(user: user)));
    }
  }

  void _message(BuildContext context) {
    Navigator.of(context).pop();
    if (!AppState.instance.isRegistered) {
      showRegisterGate(context, user);
    } else {
      Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => ConversationScreen(user: user)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final subtitle = user.role == SpeakerRole.native
        ? 'Native speaker · ${user.city} · ${user.distanceKm} km away'
        : 'Learner · ${user.city} · ${user.level}';
    return Container(
      constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.82),
      decoration: const BoxDecoration(
        color: AppColors.n800,
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
        border: Border(
            top: BorderSide(color: Color(0x4D6C63FF))),
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(0, 12, 0, Insets.x6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 42,
                    height: 5,
                    decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(3)),
                  ),
                ),
                const SizedBox(height: 14),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: Insets.x5),
                  child: Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: Image.network(user.photoUrl,
                            height: 220,
                            width: double.infinity,
                            fit: BoxFit.cover),
                      ),
                      if (user.online)
                        Positioned(
                          top: 12,
                          left: 12,
                          child: Pill('● Online now',
                              bg: AppColors.success.withValues(alpha: 0.85),
                              fg: const Color(0xFF042204),
                              border: Colors.transparent),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: Insets.x5),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('${user.name}, ${user.age}  ${user.flag}',
                                    style: AppText.displayMd
                                        .copyWith(fontSize: 24)),
                                const SizedBox(height: 2),
                                Text(subtitle, style: AppText.smMuted),
                              ],
                            ),
                          ),
                          Column(
                            children: [
                              Text('🏆 ${user.levelXp}',
                                  style: AppText.h3.copyWith(
                                      color: AppColors.brand300, fontSize: 18)),
                              Text('level', style: AppText.smMuted),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text('“${user.bio}”', style: AppText.body),
                      const SizedBox(height: 14),
                      Wrap(
                        spacing: 7,
                        runSpacing: 7,
                        children: [
                          for (final i in user.interests) Chip2(i),
                        ],
                      ),
                      const SizedBox(height: 18),
                      Row(
                        children: [
                          Expanded(
                              child: GhostButton('💬 Message',
                                  onTap: () => _message(context))),
                          const SizedBox(width: 10),
                          Expanded(
                              child: PrimaryButton('📞 Call now',
                                  onTap: () => _call(context))),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
