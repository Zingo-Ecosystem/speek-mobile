import 'package:flutter/material.dart';

import '../../models/models.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common.dart';
import '../call/incoming_call_screen.dart';

/// A Telegram-style profile for *another* user: a large avatar header, the
/// name + presence, a row of quick actions (Message / Voice / Video / More) and
/// info cards (location, level, bio, interests).
///
/// Tapping **Voice** or **Video** places the call immediately — no extra
/// "choose call type" step.
class UserProfileScreen extends StatelessWidget {
  final SpeekUser user;

  /// When true the Message action just pops back to the chat that opened this
  /// screen; otherwise it's hidden (no chat context to return to).
  final bool cameFromChat;

  /// Optional overflow actions surfaced under the "More" button.
  final VoidCallback? onBlock;

  const UserProfileScreen({
    super.key,
    required this.user,
    this.cameFromChat = true,
    this.onBlock,
  });

  void _startCall(BuildContext context, {required bool video}) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => IncomingCallScreen(user: user, autoStartVideo: video),
    ));
  }

  String get _status => user.online ? 'online' : 'last seen recently';

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.of(context).padding.top;
    return Scaffold(
      backgroundColor: AppColors.sBg,
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          // ---- Header: avatar + name + presence -------------------------
          Container(
            padding: EdgeInsets.fromLTRB(Insets.x5, topPad + 8, Insets.x5, 24),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF241F4D), Color(0xFF14131F)],
              ),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    _circleBtn(Icons.arrow_back_rounded,
                        () => Navigator.of(context).pop()),
                    const Spacer(),
                    if (onBlock != null)
                      _circleBtn(Icons.more_horiz_rounded,
                          () => _showMore(context)),
                  ],
                ),
                const SizedBox(height: 10),
                GestureDetector(
                  onTap: () => _openPhotos(context),
                  child: Hero(
                    tag: 'avatar_${user.id}',
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                            color: Colors.white.withValues(alpha: 0.18),
                            width: 3),
                        boxShadow: [
                          BoxShadow(
                              color: AppColors.brand500.withValues(alpha: 0.4),
                              blurRadius: 28),
                        ],
                      ),
                      child: Avatar(user.photoUrl, size: 116, name: user.name),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text('${user.name}${user.flag.isNotEmpty ? ' ${user.flag}' : ''}',
                    style: AppText.displayMd.copyWith(fontSize: 26),
                    textAlign: TextAlign.center),
                const SizedBox(height: 4),
                Text(_status,
                    style: AppText.body.copyWith(
                        color: user.online
                            ? AppColors.success
                            : AppColors.sText2)),
              ],
            ),
          ),

          // ---- Quick actions (Telegram-style) ---------------------------
          Transform.translate(
            offset: const Offset(0, -20),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: Insets.x5),
              child: Row(
                children: [
                  if (cameFromChat)
                    _action(context, Icons.chat_bubble_rounded, 'Message',
                        () => Navigator.of(context).pop()),
                  _action(context, Icons.call_rounded, 'Call',
                      () => _startCall(context, video: false)),
                  _action(context, Icons.videocam_rounded, 'Video',
                      () => _startCall(context, video: true)),
                  if (onBlock != null)
                    _action(context, Icons.more_horiz_rounded, 'More',
                        () => _showMore(context)),
                ],
              ),
            ),
          ),

          // ---- Info card ------------------------------------------------
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: Insets.x5),
            child: _card([
              if ((user.city + user.country).trim().isNotEmpty)
                _infoRow(Icons.place_outlined, 'Location',
                    [user.city, user.country].where((s) => s.isNotEmpty).join(', ')),
              _infoRow(Icons.emoji_events_outlined, 'Level',
                  'Level ${user.levelXp}'),
              if (user.level.isNotEmpty)
                _infoRow(Icons.school_outlined, 'English', user.level),
              if (user.bio.trim().isNotEmpty)
                _infoRow(Icons.info_outline_rounded, 'Bio', user.bio),
            ]),
          ),

          // ---- Interests ------------------------------------------------
          if (user.interests.isNotEmpty) ...[
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: Insets.x5),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text('INTERESTS',
                    style: AppText.label
                        .copyWith(color: AppColors.n200, fontSize: 12)),
              ),
            ),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: Insets.x5),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [for (final i in user.interests) Chip2(i)],
              ),
            ),
          ],

          // ---- Photo gallery -------------------------------------------
          if (user.photos.length > 1) ...[
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: Insets.x5),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text('PHOTOS',
                    style: AppText.label
                        .copyWith(color: AppColors.n200, fontSize: 12)),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 110,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: Insets.x5),
                itemCount: user.photos.length,
                separatorBuilder: (_, _) => const SizedBox(width: 10),
                itemBuilder: (_, i) => ClipRRect(
                  borderRadius: BorderRadius.circular(Radii.md),
                  child: Image.network(
                    user.photos[i],
                    width: 100,
                    height: 110,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => Container(
                      width: 100,
                      height: 110,
                      color: AppColors.sFill(0.08),
                      child: const Icon(Icons.image_not_supported_outlined,
                          color: AppColors.n400),
                    ),
                  ),
                ),
              ),
            ),
          ],

          const SizedBox(height: 40),
        ],
      ),
    );
  }

  // ---- helpers ------------------------------------------------------------

  void _openPhotos(BuildContext context) {
    if (user.photoUrl.isEmpty) return;
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => _PhotoViewer(
        photos: user.photos.isNotEmpty ? user.photos : [user.photoUrl],
        heroTag: 'avatar_${user.id}',
      ),
    ));
  }

  void _showMore(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.n800,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 42,
              height: 5,
              decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(3)),
            ),
            ListTile(
              leading: Icon(Icons.block_rounded, color: AppColors.danger),
              title: Text('Block ${user.name}',
                  style: AppText.body.copyWith(color: AppColors.danger)),
              onTap: () {
                Navigator.of(ctx).pop();
                onBlock?.call();
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _circleBtn(IconData icon, VoidCallback onTap) => GestureDetector(
        onTap: onTap,
        child: Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.28),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: Colors.white, size: 20),
        ),
      );

  Widget _action(
          BuildContext context, IconData icon, String label, VoidCallback onTap) =>
      Expanded(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: GestureDetector(
            onTap: onTap,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.bgSurface,
                borderRadius: BorderRadius.circular(Radii.md),
                border: Border.all(color: AppColors.borderSubtle),
              ),
              child: Column(
                children: [
                  Icon(icon, color: AppColors.brand300, size: 22),
                  const SizedBox(height: 6),
                  Text(label,
                      style: AppText.caption
                          .copyWith(color: AppColors.brand200, fontSize: 12)),
                ],
              ),
            ),
          ),
        ),
      );

  Widget _card(List<Widget> rows) {
    final visible = rows.where((w) => w is! SizedBox).toList();
    return Container(
      decoration: BoxDecoration(
        color: AppColors.sFill(0.06),
        borderRadius: BorderRadius.circular(Radii.lg),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Column(
        children: [
          for (int i = 0; i < visible.length; i++) ...[
            visible[i],
            if (i != visible.length - 1)
              Divider(
                  height: 1,
                  thickness: 1,
                  indent: 52,
                  color: Colors.white.withValues(alpha: 0.06)),
          ],
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 20, color: AppColors.n300),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(value, style: AppText.body),
                  const SizedBox(height: 2),
                  Text(label,
                      style: AppText.caption.copyWith(color: AppColors.sText2)),
                ],
              ),
            ),
          ],
        ),
      );
}

/// Full-screen swipeable photo viewer.
class _PhotoViewer extends StatelessWidget {
  final List<String> photos;
  final String heroTag;
  const _PhotoViewer({required this.photos, required this.heroTag});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      extendBodyBehindAppBar: true,
      body: PageView.builder(
        itemCount: photos.length,
        itemBuilder: (_, i) => Center(
          child: InteractiveViewer(
            child: i == 0
                ? Hero(tag: heroTag, child: Image.network(photos[i]))
                : Image.network(photos[i]),
          ),
        ),
      ),
    );
  }
}
