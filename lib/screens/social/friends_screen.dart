import 'package:flutter/material.dart';

import '../../data/dto.dart';
import '../../data/repositories.dart';
import '../../models/models.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common.dart';
import '../../widgets/snack.dart';
import '../chat/conversation_screen.dart';

class FriendsScreen extends StatefulWidget {
  const FriendsScreen({super.key});

  @override
  State<FriendsScreen> createState() => _FriendsScreenState();
}

class _FriendsScreenState extends State<FriendsScreen> {
  List<FriendData> _friends = const [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final list = await Repos.friends.list();
      if (mounted) setState(() => _friends = list);
    } catch (_) {
      if (mounted) {
        showSnack(context, 'Could not load friends.', type: SnackType.error);
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _remove(FriendData f) async {
    try {
      await Repos.friends.remove(f.userId);
      setState(() => _friends = _friends.where((x) => x.userId != f.userId).toList());
      if (mounted) {
        showSnack(context, '${f.name} removed from friends.');
      }
    } catch (_) {
      if (mounted) {
        showSnack(context, 'Could not remove friend.', type: SnackType.error);
      }
    }
  }

  Future<void> _accept(FriendData f) async {
    try {
      await Repos.friends.addOrAccept(f.userId);
      // refresh the list to reflect updated status
      await _load();
    } catch (_) {
      if (mounted) {
        showSnack(context, 'Could not accept request.', type: SnackType.error);
      }
    }
  }

  List<FriendData> get _pending =>
      _friends.where((f) => f.isPending).toList();
  List<FriendData> get _accepted =>
      _friends.where((f) => f.isAccepted).toList();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.sBg,
      appBar: AppBar(
        backgroundColor: AppColors.sBg,
        title: Text('Friends', style: AppText.h2),
        elevation: 0,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: _friends.isEmpty
                  ? _empty()
                  : ListView(
                      padding: const EdgeInsets.only(bottom: 40),
                      children: [
                        if (_pending.isNotEmpty) ...[
                          _sectionHeader('Pending requests (${_pending.length})'),
                          for (final f in _pending) _FriendTile(
                            friend: f,
                            onAccept: () => _accept(f),
                            onDecline: () => _remove(f),
                          ),
                        ],
                        if (_accepted.isNotEmpty) ...[
                          _sectionHeader('Friends (${_accepted.length})'),
                          for (final f in _accepted) _FriendTile(
                            friend: f,
                            onMessage: () => _openChat(context, f),
                            onRemove: () => _remove(f),
                          ),
                        ],
                      ],
                    ),
            ),
    );
  }

  Widget _empty() => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('👤', style: TextStyle(fontSize: 52)),
            const SizedBox(height: 16),
            Text('No friends yet', style: AppText.h3),
            const SizedBox(height: 8),
            Text('Add friends from the map or after a call.',
                style: AppText.smMuted, textAlign: TextAlign.center),
          ],
        ),
      );

  Widget _sectionHeader(String label) => Padding(
        padding: const EdgeInsets.fromLTRB(Insets.x5, 20, Insets.x5, 8),
        child: Text(label,
            style: AppText.caption.copyWith(
                color: AppColors.sText2,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5)),
      );

  void _openChat(BuildContext context, FriendData f) {
    final user = SpeekUser(
      id: f.userId,
      name: f.name,
      age: 0,
      flag: f.flag,
      country: f.country,
      city: '',
      role: SpeakerRole.learner,
      photoUrl: f.photoUrl,
    );
    Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => ConversationScreen(user: user)));
  }
}

class _FriendTile extends StatelessWidget {
  final FriendData friend;
  final VoidCallback? onAccept;
  final VoidCallback? onDecline;
  final VoidCallback? onMessage;
  final VoidCallback? onRemove;

  const _FriendTile({
    required this.friend,
    this.onAccept,
    this.onDecline,
    this.onMessage,
    this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final isPending = friend.isPending;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: Insets.x5, vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.sFill(0.06),
        borderRadius: BorderRadius.circular(Radii.md),
      ),
      child: Row(
        children: [
          Avatar(friend.photoUrl, size: 46, name: friend.name),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(friend.name, style: AppText.label),
                const SizedBox(height: 2),
                Text(
                  isPending
                      ? (friend.isSentByMe ? 'Request sent' : 'Wants to be friends')
                      : '${friend.flag} ${friend.country}',
                  style: AppText.caption.copyWith(
                      color: isPending
                          ? AppColors.warning
                          : AppColors.sText2),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          if (isPending && !friend.isSentByMe) ...[
            // Incoming request — accept / decline
            GestureDetector(
              onTap: onDecline,
              child: Container(
                padding: const EdgeInsets.all(8),
                child: Icon(Icons.close, color: AppColors.danger, size: 20),
              ),
            ),
            const SizedBox(width: 4),
            GhostButton('Accept', onTap: onAccept),
          ] else if (!isPending) ...[
            GestureDetector(
              onTap: onMessage,
              child: Container(
                padding: const EdgeInsets.all(8),
                child: Icon(Icons.chat_bubble_outline_rounded,
                    color: AppColors.brand300, size: 20),
              ),
            ),
            GestureDetector(
              onTap: onRemove,
              child: Container(
                padding: const EdgeInsets.all(8),
                child: Icon(Icons.person_remove_outlined,
                    color: AppColors.sText3, size: 20),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
