import 'dart:async';
import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';

import '../../data/repositories.dart';
import '../../models/models.dart';
import '../../state/app_state.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common.dart';
import '../../widgets/snack.dart';
import '../call/incoming_call_screen.dart';
import '../chat/conversation_screen.dart';
import '../subscription/paywall_screen.dart';
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

/// Live "🗣 Talking · mm:ss" badge that ticks every second.
class _TalkingBadge extends StatefulWidget {
  final DateTime? since;
  const _TalkingBadge({this.since});
  @override
  State<_TalkingBadge> createState() => _TalkingBadgeState();
}

class _TalkingBadgeState extends State<_TalkingBadge> {
  Timer? _t;
  @override
  void initState() {
    super.initState();
    _t = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _t?.cancel();
    super.dispose();
  }

  String get _label {
    final since = widget.since;
    if (since == null) return 'In a call';
    final d = DateTime.now().difference(since);
    final s = d.inSeconds < 0 ? 0 : d.inSeconds;
    final h = s ~/ 3600, m = (s % 3600) ~/ 60, sec = s % 60;
    final clock = h > 0
        ? '$h:${m.toString().padLeft(2, '0')}:${sec.toString().padLeft(2, '0')}'
        : '${m.toString().padLeft(2, '0')}:${sec.toString().padLeft(2, '0')}';
    return 'Talking · $clock';
  }

  @override
  Widget build(BuildContext context) {
    return Pill('🗣 $_label',
        bg: AppColors.success.withValues(alpha: 0.15),
        fg: AppColors.success,
        border: AppColors.success.withValues(alpha: 0.4));
  }
}

Widget _previewFallback(SpeekUser user) => SizedBox(
      height: 220,
      width: double.infinity,
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF241F4D), Color(0xFF0F0E1A)],
          ),
        ),
        alignment: Alignment.center,
        child: Avatar('', size: 110, name: user.name),
      ),
    );

class _UserPreviewSheet extends StatefulWidget {
  final SpeekUser user;
  const _UserPreviewSheet({required this.user});

  @override
  State<_UserPreviewSheet> createState() => _UserPreviewSheetState();
}

class _UserPreviewSheetState extends State<_UserPreviewSheet> {
  bool _liked = false;
  bool _friendSent = false;
  bool _likeLoading = false;
  bool _friendLoading = false;
  bool _inviteSent = false;
  bool _inviteLoading = false;

  @override
  void initState() {
    super.initState();
    // Auto-record profile view (fire-and-forget, no UI feedback needed).
    if (AppState.instance.isRegistered) {
      Repos.social.recordView(widget.user.id).catchError((_) {});
    }
  }

  /// Free users can browse the map but every action requires Premium. Returns
  /// false (and opens the paywall) when the user isn't allowed to proceed.
  bool _gate(BuildContext context) {
    if (!AppState.instance.isRegistered) {
      showRegisterGate(context, widget.user);
      return false;
    }
    if (!AppState.instance.isPremium) {
      Navigator.of(context).pop();
      Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const PaywallScreen()));
      return false;
    }
    return true;
  }

  void _call(BuildContext context) {
    final nav = Navigator.of(context);
    if (!_gate(context)) return;
    nav.pop();
    nav.push(MaterialPageRoute(
        builder: (_) => IncomingCallScreen(user: widget.user)));
  }

  void _message(BuildContext context) {
    if (!_gate(context)) return;
    Navigator.of(context).pop();
    Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => ConversationScreen(user: widget.user)));
  }

  /// Sends a "practice with me" invite. It lands in the peer's chat as a request;
  /// once they accept, both can chat and start voice/video calls.
  Future<void> _invite(BuildContext context) async {
    if (!_gate(context)) return;
    if (_inviteLoading || _inviteSent) return;
    setState(() => _inviteLoading = true);
    try {
      await Repos.chat.invite(widget.user.id);
      if (mounted) {
        setState(() {
          _inviteSent = true;
          _inviteLoading = false;
        });
        showSnack(context, 'Invite sent to ${widget.user.name} 👋');
      }
    } catch (_) {
      if (mounted) {
        setState(() => _inviteLoading = false);
        showSnack(context, 'Could not send invite.', type: SnackType.error);
      }
    }
  }

  Future<void> _toggleLike() async {
    if (!AppState.instance.isRegistered) return;
    if (_likeLoading) return;
    setState(() => _likeLoading = true);
    try {
      if (_liked) {
        await Repos.social.unlike(widget.user.id);
      } else {
        await Repos.social.like(widget.user.id);
      }
      if (mounted) setState(() => _liked = !_liked);
    } catch (_) {
      if (mounted) {
        showSnack(context, 'Could not update like.', type: SnackType.error);
      }
    } finally {
      if (mounted) setState(() => _likeLoading = false);
    }
  }

  Future<void> _addFriend() async {
    if (!AppState.instance.isRegistered) return;
    if (_friendLoading || _friendSent) return;
    setState(() => _friendLoading = true);
    try {
      await Repos.friends.addOrAccept(widget.user.id);
      if (mounted) {
        setState(() {
          _friendSent = true;
          _friendLoading = false;
        });
        showSnack(context, 'Friend request sent to ${widget.user.name}!');
      }
    } catch (_) {
      if (mounted) {
        setState(() => _friendLoading = false);
        showSnack(context, 'Could not send friend request.', type: SnackType.error);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = widget.user;
    final subtitle = user.role == SpeakerRole.native
        ? 'Native speaker · ${user.city} · ${AppState.instance.formatDistance(user.distanceKm)} away'
        : 'Learner · ${user.city} · ${user.level}';
    final premium = AppState.instance.isPremium;
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
                        child: Stack(
                          children: [
                            user.photoUrl.isNotEmpty
                                ? Image.network(user.photoUrl,
                                    height: 220,
                                    width: double.infinity,
                                    fit: BoxFit.cover,
                                    loadingBuilder: (_, child, progress) =>
                                        progress == null
                                            ? child
                                            : _previewFallback(user),
                                    errorBuilder: (_, __, ___) =>
                                        _previewFallback(user))
                                : _previewFallback(user),
                            // Free users see a blurred photo behind a premium lock.
                            if (!premium)
                              Positioned.fill(
                                child: ClipRRect(
                                  child: BackdropFilter(
                                    filter: ImageFilter.blur(
                                        sigmaX: 18, sigmaY: 18),
                                    child: Container(
                                      color: Colors.black
                                          .withValues(alpha: 0.28),
                                      alignment: Alignment.center,
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(Icons.lock_rounded,
                                              color: Colors.white, size: 30),
                                          const SizedBox(height: 8),
                                          Text('Photos are a Premium perk',
                                              style: AppText.label.copyWith(
                                                  color: Colors.white)),
                                          const SizedBox(height: 2),
                                          Text('Unlock to see who you\'re talking to',
                                              style: AppText.caption.copyWith(
                                                  color: Colors.white
                                                      .withValues(alpha: 0.8))),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
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
                      // Like button overlay
                      Positioned(
                        top: 12,
                        right: 12,
                        child: GestureDetector(
                          onTap: _toggleLike,
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.5),
                              shape: BoxShape.circle,
                            ),
                            child: _likeLoading
                                ? const Padding(
                                    padding: EdgeInsets.all(10),
                                    child: CircularProgressIndicator(
                                        strokeWidth: 1.5,
                                        color: Colors.white))
                                : Icon(
                                    _liked
                                        ? Icons.favorite_rounded
                                        : Icons.favorite_border_rounded,
                                    color: _liked
                                        ? AppColors.like
                                        : Colors.white,
                                    size: 20,
                                  ),
                          ),
                        ),
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
                                if (user.inCall) ...[
                                  const SizedBox(height: 6),
                                  _TalkingBadge(since: user.callStartedAt),
                                ],
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
                      Text('"${user.bio}"', style: AppText.body),
                      const SizedBox(height: 14),
                      Wrap(
                        spacing: 7,
                        runSpacing: 7,
                        children: [
                          for (final i in user.interests) Chip2(i),
                        ],
                      ),
                      const SizedBox(height: 18),
                      // Add-friend only makes sense when they're not already a
                      // friend. For existing friends show a green "Friends" badge.
                      if (user.isFriend)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          decoration: BoxDecoration(
                            color: AppColors.success.withValues(alpha: 0.14),
                            borderRadius: BorderRadius.circular(Radii.lg),
                            border: Border.all(
                                color: AppColors.success.withValues(alpha: 0.45)),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.verified_rounded,
                                  size: 18, color: AppColors.success),
                              const SizedBox(width: 8),
                              Text('Friends',
                                  style: AppText.label
                                      .copyWith(color: AppColors.success)),
                            ],
                          ),
                        )
                      else
                        GhostButton(
                          _friendSent
                              ? '✓ Friend request sent'
                              : _friendLoading
                                  ? 'Sending...'
                                  : '👤 Add friend',
                          onTap:
                              (_friendSent || _friendLoading) ? null : _addFriend,
                        ),
                      const SizedBox(height: 10),
                      if (user.isConnected) ...[
                        // Already connected → can chat & call.
                        Row(
                          children: [
                            Expanded(
                                child: PrimaryButton('💬 Message',
                                    onTap: () => _message(context))),
                            const SizedBox(width: 10),
                            Expanded(
                                child: user.inCall
                                    ? GhostButton('📞 In a call', onTap: null)
                                    : GhostButton('📞 Call now',
                                        onTap: () => _call(context))),
                          ],
                        ),
                      ] else ...[
                        // Not connected yet → must invite & be accepted first.
                        PrimaryButton(
                          !premium
                              ? '🔒 Unlock to invite'
                              : _inviteSent
                                  ? '✓ Invite sent'
                                  : _inviteLoading
                                      ? 'Sending...'
                                      : '🗣 Invite to speak',
                          onTap: (_inviteSent || _inviteLoading)
                              ? null
                              : () => _invite(context),
                        ),
                        const SizedBox(height: 8),
                        Center(
                          child: Text(
                            _inviteSent
                                ? 'We\'ll let you know when they accept.'
                                : 'Chat & calls unlock once they accept.',
                            style: AppText.caption
                                .copyWith(color: AppColors.n300),
                          ),
                        ),
                      ],
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
