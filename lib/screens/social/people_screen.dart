import 'dart:async';
import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';

import '../../data/dto.dart';
import '../../data/repositories.dart';
import '../../models/models.dart';
import '../../realtime/realtime_service.dart';
import '../../state/app_state.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common.dart';
import '../../widgets/snack.dart';
import '../chat/chat_list_screen.dart';
import '../chat/conversation_screen.dart';
import '../subscription/paywall_screen.dart';

/// The "People" hub: manage friends (message / remove / block), respond to
/// incoming requests (map invites + friend requests), and — for Premium — see
/// who viewed your profile. Invites now land here, not in the chat list.
class PeopleScreen extends StatefulWidget {
  const PeopleScreen({super.key});

  @override
  State<PeopleScreen> createState() => _PeopleScreenState();

  /// Set by the live screen so the shell can refresh it when its tab is opened.
  static void Function()? refresh;
}

class _PeopleScreenState extends State<PeopleScreen>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late final TabController _tabs;
  StreamSubscription? _inviteSub;
  StreamSubscription? _msgSub;

  List<FriendData> _friends = const [];
  List<Chat> _invites = const [];
  List<SocialUserData> _views = const [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    PeopleScreen.refresh = () { if (mounted) _load(); };
    _tabs = TabController(length: 3, vsync: this);
    _load();
    // Incoming invites now surface here.
    _inviteSub = RealtimeService.instance.onInvite.listen((_) => _load());
    // A new request can also arrive as a plain message event (e.g. when the
    // invite push is delivered as a message); refresh on those too.
    _msgSub = RealtimeService.instance.onMessage.listen((_) => _load());
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Coming back to the foreground: make sure the realtime link is up and pull
    // any requests that landed while we were backgrounded, so they appear
    // without needing a full app restart.
    if (state == AppLifecycleState.resumed) {
      RealtimeService.instance.connect();
      _load();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    PeopleScreen.refresh = null;
    _tabs.dispose();
    _inviteSub?.cancel();
    _msgSub?.cancel();
    super.dispose();
  }

  List<FriendData> get _acceptedFriends =>
      _friends.where((f) => f.isAccepted).toList();
  List<FriendData> get _friendRequests =>
      _friends.where((f) => f.isPending && !f.isSentByMe).toList();
  int get _requestCount => _invites.length + _friendRequests.length;

  Future<void> _load() async {
    if (mounted) setState(() => _loading = true);
    try {
      final results = await Future.wait([
        Repos.friends.list().catchError((_) => <FriendData>[]),
        Repos.chat.conversations(take: 50).catchError((_) => <Chat>[]),
        // Loaded for everyone — free users see the list blurred behind a CTA.
        Repos.social.whoViewedMe().catchError((_) => <SocialUserData>[]),
      ]);
      if (!mounted) return;
      setState(() {
        _friends = results[0] as List<FriendData>;
        _invites =
            (results[1] as List<Chat>).where((c) => c.isRequest).toList();
        _views = results[2] as List<SocialUserData>;
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // ---- Actions ----
  void _openChat(String id, String name, String photo, String flag,
      String country) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => ConversationScreen(
        user: SpeekUser(
          id: id,
          name: name,
          age: 0,
          flag: flag,
          country: country,
          city: '',
          role: SpeakerRole.learner,
          photoUrl: photo,
        ),
      ),
    ));
  }

  Future<void> _acceptInvite(Chat c) async {
    // Optimistically drop it from the Requests list so the UI feels instant.
    setState(() => _invites = _invites.where((x) => x.id != c.id).toList());
    try {
      await Repos.chat.accept(c.id);
      // Becoming friends too keeps the relationship in one place.
      try {
        await Repos.friends.addOrAccept(c.user.id);
      } catch (_) {}
      if (!mounted) return;
      // The conversation is now accepted — make sure it shows in Chats and take
      // the user straight into it (accept → chat, as expected).
      ChatListScreen.refresh?.call();
      await Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => ConversationScreen(
          user: c.user,
          conversationId: c.id,
        ),
      ));
      await _load();
    } catch (_) {
      if (mounted) {
        showSnack(context, 'Could not accept.', type: SnackType.error);
        await _load(); // restore the request if the accept failed
      }
    }
  }

  Future<void> _declineInvite(Chat c) async {
    setState(() => _invites = _invites.where((x) => x.id != c.id).toList());
    try {
      await Repos.chat.decline(c.id);
    } catch (_) {}
  }

  Future<void> _acceptFriend(FriendData f) async {
    try {
      await Repos.friends.addOrAccept(f.userId);
      if (!mounted) return;
      // Accepting now establishes a "We're connected" conversation on the
      // backend — surface it in Chats and take the user straight into it
      // (accept → chat), exactly like accepting a speak invite.
      ChatListScreen.refresh?.call();
      await Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => ConversationScreen(
          user: SpeekUser(
            id: f.userId,
            name: f.name,
            age: 0,
            flag: f.flag,
            country: f.country,
            city: '',
            role: SpeakerRole.learner,
            photoUrl: f.photoUrl,
          ),
        ),
      ));
      await _load();
    } catch (_) {
      if (mounted) {
        showSnack(context, 'Could not accept.', type: SnackType.error);
        await _load();
      }
    }
  }

  Future<void> _removeFriend(FriendData f) async {
    setState(
        () => _friends = _friends.where((x) => x.userId != f.userId).toList());
    try {
      await Repos.friends.remove(f.userId);
      if (mounted) showSnack(context, '${f.name} removed');
    } catch (_) {}
  }

  Future<void> _blockUser(String id, String name) async {
    setState(() => _friends = _friends.where((x) => x.userId != id).toList());
    try {
      await Repos.friends.block(id);
      if (mounted) {
        showSnack(context, '$name blocked', type: SnackType.success);
      }
    } catch (_) {
      if (mounted) {
        showSnack(context, 'Could not block.', type: SnackType.error);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.of(context).padding.top;
    return Scaffold(
      backgroundColor: AppColors.sBg,
      body: Column(
        children: [
          // Gradient header
          Container(
            padding: EdgeInsets.fromLTRB(Insets.x5, topPad + 14, Insets.x5, 14),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF241F4D), Color(0xFF14131F)],
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text('People', style: AppText.displayMd),
                  ],
                ),
                const SizedBox(height: 14),
                _SegmentTabs(
                  controller: _tabs,
                  labels: const ['Friends', 'Requests', 'Viewed'],
                  badges: [
                    _acceptedFriends.length,
                    _requestCount,
                    _views.length,
                  ],
                  premiumIndex: 2,
                ),
              ],
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : TabBarView(
                    controller: _tabs,
                    children: [
                      _friendsTab(),
                      _requestsTab(),
                      _viewedTab(),
                    ],
                  ),
          ),
          _blockedFooter(),
        ],
      ),
    );
  }

  // Blocked-users access lives at the bottom of the screen (out of the way),
  // not crowding the header.
  Widget _blockedFooter() => SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(Insets.x5, 4, Insets.x5, 8),
          child: GestureDetector(
            onTap: _openBlocked,
            behavior: HitTestBehavior.opaque,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.borderSubtle),
              ),
              child: Row(
                children: [
                  Icon(Icons.block_rounded, size: 17, color: AppColors.n300),
                  const SizedBox(width: 10),
                  Text('Blocked users',
                      style: AppText.label.copyWith(color: AppColors.n200)),
                  const Spacer(),
                  Icon(Icons.chevron_right,
                      size: 18, color: AppColors.sText3),
                ],
              ),
            ),
          ),
        ),
      );

  // ---- Friends tab ----
  Widget _friendsTab() {
    final friends = _acceptedFriends;
    if (friends.isEmpty) {
      return _empty('🧑‍🤝‍🧑', 'No friends yet',
          'Accept a request or invite people from the map.');
    }
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(Insets.x5, 14, Insets.x5, 120),
        itemCount: friends.length,
        itemBuilder: (_, i) {
          final f = friends[i];
          return _PersonCard(
            name: f.name,
            photoUrl: f.photoUrl,
            flag: f.flag,
            subtitle: '${f.flag} ${f.country}',
            onMessage: () =>
                _openChat(f.userId, f.name, f.photoUrl, f.flag, f.country),
            onRemove: () => _confirmRemove(f),
            onBlock: () => _confirmBlock(f.userId, f.name),
          );
        },
      ),
    );
  }

  // ---- Requests tab ----
  Widget _requestsTab() {
    if (_requestCount == 0) {
      return _empty('📨', 'No requests',
          'Invites and friend requests will appear here.');
    }
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(Insets.x5, 14, Insets.x5, 120),
        children: [
          if (_invites.isNotEmpty) ...[
            _groupHeader('🗣  Speak invites', _invites.length),
            for (final c in _invites)
              _RequestCard(
                name: c.user.name,
                photoUrl: c.user.photoUrl,
                flag: c.user.country.split(' ').first,
                message: c.preview,
                accent: AppColors.brand400,
                onAccept: () => _acceptInvite(c),
                onDecline: () => _declineInvite(c),
              ),
          ],
          if (_friendRequests.isNotEmpty) ...[
            _groupHeader('👋  Friend requests', _friendRequests.length),
            for (final f in _friendRequests)
              _RequestCard(
                name: f.name,
                photoUrl: f.photoUrl,
                flag: f.flag,
                message: 'Wants to be your friend',
                accent: AppColors.gold,
                onAccept: () => _acceptFriend(f),
                onDecline: () => _removeFriend(f),
              ),
          ],
        ],
      ),
    );
  }

  // ---- Viewed tab ----
  // Anyone who opens your profile card from the map lands here. Premium users
  // see who + when; free users see the same list blurred behind an unlock CTA.
  Widget _viewedTab() {
    final premium = AppState.instance.isPremium;
    if (_views.isEmpty) {
      return _empty('👁', 'No profile views yet',
          'When someone checks out your profile from the map, they show up here.');
    }
    final list = RefreshIndicator(
      onRefresh: _load,
      child: ListView.builder(
        physics: premium
            ? const AlwaysScrollableScrollPhysics()
            : const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(Insets.x5, 14, Insets.x5, 120),
        itemCount: _views.length,
        itemBuilder: (_, i) {
          final v = _views[i];
          return _PersonCard(
            name: v.name,
            photoUrl: v.photoUrl,
            flag: v.flag,
            subtitle: v.at != null
                ? 'Viewed ${_ago(v.at!)}'
                : '${v.flag} ${v.country}',
            onMessage: () =>
                _openChat(v.userId, v.name, v.photoUrl, v.flag, v.country),
          );
        },
      ),
    );
    if (premium) return list;
    // Free: real list blurred, with an unlock overlay revealing the count.
    return Stack(
      children: [
        Positioned.fill(
          child: IgnorePointer(
            child: ImageFiltered(
              imageFilter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
              child: list,
            ),
          ),
        ),
        Positioned.fill(child: _ViewedPremiumGate(count: _views.length)),
      ],
    );
  }

  // ---- Helpers ----
  Widget _groupHeader(String label, int count) => Padding(
        padding: const EdgeInsets.only(top: 6, bottom: 10),
        child: Row(
          children: [
            Text(label,
                style: AppText.label.copyWith(color: AppColors.sText2)),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.brand500.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text('$count',
                  style: AppText.caption.copyWith(
                      color: AppColors.brand200,
                      fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      );

  Widget _empty(String emoji, String title, String body) => ListView(
        children: [
          const SizedBox(height: 80),
          Center(
            child: Column(
              children: [
                Text(emoji, style: const TextStyle(fontSize: 54)),
                const SizedBox(height: 16),
                Text(title, style: AppText.h3),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 50),
                  child: Text(body,
                      textAlign: TextAlign.center, style: AppText.smMuted),
                ),
              ],
            ),
          ),
        ],
      );

  static String _ago(DateTime d) {
    final diff = DateTime.now().difference(d);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  Future<void> _confirmRemove(FriendData f) async {
    final ok = await _confirmSheet(
        '👋', 'Remove ${f.name}?', 'They will be removed from your friends.',
        'Remove', AppColors.warning);
    if (ok == true) _removeFriend(f);
  }

  Future<void> _confirmBlock(String id, String name) async {
    final ok = await _confirmSheet('🚫', 'Block $name?',
        'They won\'t be able to message, call or find you on the map. You can unblock anytime.',
        'Block', AppColors.danger);
    if (ok == true) _blockUser(id, name);
  }

  Future<bool?> _confirmSheet(String emoji, String title, String body,
          String confirmLabel, Color confirmColor) =>
      showModalBottomSheet<bool>(
        context: context,
        backgroundColor: Colors.transparent,
        builder: (ctx) => _ConfirmSheet(
          emoji: emoji,
          title: title,
          body: body,
          confirmLabel: confirmLabel,
          confirmColor: confirmColor,
        ),
      );

  void _openBlocked() {
    Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => const BlockedUsersScreen()))
        .then((_) => _load());
  }
}

// ===========================================================================
// Segmented tab control with count badges and a premium lock.
// ===========================================================================
class _SegmentTabs extends StatelessWidget {
  final TabController controller;
  final List<String> labels;
  final List<int> badges;
  final int premiumIndex;

  const _SegmentTabs({
    required this.controller,
    required this.labels,
    required this.badges,
    required this.premiumIndex,
  });

  @override
  Widget build(BuildContext context) {
    final isPremium = AppState.instance.isPremium;
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(16),
      ),
      child: AnimatedBuilder(
        animation: controller,
        builder: (context, _) {
          return Row(
            children: [
              for (int i = 0; i < labels.length; i++)
                Expanded(
                  child: GestureDetector(
                    onTap: () => controller.animateTo(i),
                    behavior: HitTestBehavior.opaque,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      curve: Curves.easeOut,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        gradient: controller.index == i
                            ? AppColors.grad
                            : null,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (i == premiumIndex && !isPremium) ...[
                            const Text('👑',
                                style: TextStyle(fontSize: 12)),
                            const SizedBox(width: 4),
                          ],
                          Text(
                            labels[i],
                            style: AppText.caption.copyWith(
                              color: controller.index == i
                                  ? Colors.white
                                  : AppColors.n200,
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                            ),
                          ),
                          if (badges[i] > 0) ...[
                            const SizedBox(width: 5),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 1),
                              decoration: BoxDecoration(
                                color: controller.index == i
                                    ? Colors.white.withValues(alpha: 0.25)
                                    : AppColors.brand500
                                        .withValues(alpha: 0.5),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text('${badges[i]}',
                                  style: AppText.caption.copyWith(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w800)),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

// ===========================================================================
// A friend / viewer card with a message button + overflow (remove / block).
// ===========================================================================
class _PersonCard extends StatelessWidget {
  final String name, photoUrl, flag, subtitle;
  final VoidCallback onMessage;
  final VoidCallback? onRemove;
  final VoidCallback? onBlock;

  const _PersonCard({
    required this.name,
    required this.photoUrl,
    required this.flag,
    required this.subtitle,
    required this.onMessage,
    this.onRemove,
    this.onBlock,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.sFill(0.06),
        borderRadius: BorderRadius.circular(Radii.lg),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Row(
        children: [
          Avatar(photoUrl, size: 50, name: name),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: AppText.label),
                const SizedBox(height: 2),
                Text(subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.caption.copyWith(color: AppColors.sText2)),
              ],
            ),
          ),
          GestureDetector(
            onTap: onMessage,
            child: Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                gradient: AppColors.grad,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.chat_bubble_rounded,
                  color: Colors.white, size: 19),
            ),
          ),
          if (onRemove != null || onBlock != null)
            PopupMenuButton<String>(
              icon: Icon(Icons.more_vert_rounded, color: AppColors.sText3),
              color: AppColors.bgSurface,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
              onSelected: (v) {
                if (v == 'remove') onRemove?.call();
                if (v == 'block') onBlock?.call();
              },
              itemBuilder: (_) => [
                if (onRemove != null)
                  PopupMenuItem(
                    value: 'remove',
                    child: Row(children: [
                      Icon(Icons.person_remove_outlined,
                          size: 18, color: AppColors.sText2),
                      const SizedBox(width: 10),
                      Text('Remove friend', style: AppText.body),
                    ]),
                  ),
                if (onBlock != null)
                  PopupMenuItem(
                    value: 'block',
                    child: Row(children: [
                      Icon(Icons.block_rounded,
                          size: 18, color: AppColors.danger),
                      const SizedBox(width: 10),
                      Text('Block',
                          style: AppText.body
                              .copyWith(color: AppColors.danger)),
                    ]),
                  ),
              ],
            ),
        ],
      ),
    );
  }
}

// ===========================================================================
// A request card with Accept / Decline.
// ===========================================================================
class _RequestCard extends StatelessWidget {
  final String name, photoUrl, flag, message;
  final Color accent;
  final VoidCallback onAccept, onDecline;

  const _RequestCard({
    required this.name,
    required this.photoUrl,
    required this.flag,
    required this.message,
    required this.accent,
    required this.onAccept,
    required this.onDecline,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            accent.withValues(alpha: 0.14),
            AppColors.sFill(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(Radii.lg),
        border: Border.all(color: accent.withValues(alpha: 0.35)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Avatar(photoUrl, size: 52, name: name, ringColor: accent),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Flexible(
                        child: Text(name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppText.h3.copyWith(fontSize: 16)),
                      ),
                      if (flag.isNotEmpty) ...[
                        const SizedBox(width: 6),
                        Text(flag, style: const TextStyle(fontSize: 15)),
                      ],
                    ]),
                    const SizedBox(height: 3),
                    Text(message,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppText.caption
                            .copyWith(color: AppColors.sText2)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: GhostButton('Decline', small: true, onTap: onDecline),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: PrimaryButton('Accept',
                    small: true,
                    gradient: AppColors.grad,
                    leading: const Icon(Icons.check_rounded,
                        size: 16, color: Colors.white),
                    onTap: onAccept),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ===========================================================================
class _ViewedPremiumGate extends StatelessWidget {
  final int count;
  const _ViewedPremiumGate({this.count = 0});

  @override
  Widget build(BuildContext context) {
    final headline = count > 0
        ? '$count ${count == 1 ? 'person' : 'people'} viewed you'
        : 'See who viewed you';
    return Container(
      // Subtle scrim so the blurred cards stay visible as a teaser behind it.
      color: AppColors.sBg.withValues(alpha: 0.35),
      alignment: Alignment.center,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: Insets.x6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 96,
              height: 96,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(colors: [
                  AppColors.gold.withValues(alpha: 0.3),
                  Colors.transparent,
                ]),
              ),
              child: const Text('👑', style: TextStyle(fontSize: 52)),
            ),
            const SizedBox(height: 16),
            Text(headline, style: AppText.h2, textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text(
              'Unlock Premium to discover everyone who checked out your profile.',
              style: AppText.smMuted,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            PrimaryButton('Unlock with Premium',
                gradient: AppColors.gradGold,
                textColor: const Color(0xFF3A2600),
                onTap: () => Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => const PaywallScreen()))),
          ],
        ),
      ),
    );
  }
}

// ===========================================================================
class _ConfirmSheet extends StatelessWidget {
  final String emoji, title, body, confirmLabel;
  final Color confirmColor;

  const _ConfirmSheet({
    required this.emoji,
    required this.title,
    required this.body,
    required this.confirmLabel,
    required this.confirmColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.n800,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: Border(top: BorderSide(color: confirmColor.withValues(alpha: 0.4))),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(Insets.x6, 18, Insets.x6, 18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 42,
                height: 5,
                decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(3)),
              ),
              const SizedBox(height: 20),
              Text(emoji, style: const TextStyle(fontSize: 40)),
              const SizedBox(height: 12),
              Text(title, style: AppText.h3, textAlign: TextAlign.center),
              const SizedBox(height: 8),
              Text(body,
                  style: AppText.smMuted, textAlign: TextAlign.center),
              const SizedBox(height: 22),
              Row(
                children: [
                  Expanded(
                    child: GhostButton('Cancel',
                        onTap: () => Navigator.of(context).pop(false)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: PrimaryButton(confirmLabel,
                        gradient: LinearGradient(colors: [
                          confirmColor,
                          confirmColor.withValues(alpha: 0.7),
                        ]),
                        onTap: () => Navigator.of(context).pop(true)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ===========================================================================
// Blocked-users management screen.
// ===========================================================================
class BlockedUsersScreen extends StatefulWidget {
  const BlockedUsersScreen({super.key});

  @override
  State<BlockedUsersScreen> createState() => BlockedUsersScreenState();
}

class BlockedUsersScreenState extends State<BlockedUsersScreen> {
  List<BlockedUser> _blocked = const [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final list = await Repos.friends.blocked();
      if (mounted) setState(() => _blocked = list);
    } catch (_) {
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _unblock(BlockedUser b) async {
    setState(() => _blocked = _blocked.where((x) => x.userId != b.userId).toList());
    try {
      await Repos.friends.unblock(b.userId);
      if (mounted) showSnack(context, '${b.name} unblocked');
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.sBg,
      appBar: AppBar(
        backgroundColor: AppColors.sBg,
        elevation: 0,
        title: Text('Blocked users', style: AppText.h2),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _blocked.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('🚫', style: TextStyle(fontSize: 52)),
                      const SizedBox(height: 14),
                      Text('No blocked users', style: AppText.h3),
                      const SizedBox(height: 6),
                      Text('People you block will appear here.',
                          style: AppText.smMuted),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(Insets.x5, 14, Insets.x5, 40),
                  itemCount: _blocked.length,
                  itemBuilder: (_, i) {
                    final b = _blocked[i];
                    final sub = b.at != null
                        ? 'Blocked ${_PeopleScreenState._ago(b.at!)}'
                        : '${b.flag} ${b.country}'.trim();
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.sFill(0.05),
                        borderRadius: BorderRadius.circular(Radii.lg),
                        border:
                            Border.all(color: AppColors.danger.withValues(alpha: 0.22)),
                      ),
                      child: Row(
                        children: [
                          // Greyed avatar with a small block badge so the state reads instantly.
                          Stack(
                            clipBehavior: Clip.none,
                            children: [
                              ColorFiltered(
                                colorFilter: const ColorFilter.matrix(<double>[
                                  0.2126, 0.7152, 0.0722, 0, 0,
                                  0.2126, 0.7152, 0.0722, 0, 0,
                                  0.2126, 0.7152, 0.0722, 0, 0,
                                  0, 0, 0, 1, 0,
                                ]),
                                child: Avatar(b.photoUrl, size: 48, name: b.name),
                              ),
                              Positioned(
                                right: -2,
                                bottom: -2,
                                child: Container(
                                  width: 20,
                                  height: 20,
                                  decoration: BoxDecoration(
                                    color: AppColors.danger,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                        color: AppColors.sBg, width: 2),
                                  ),
                                  child: const Icon(Icons.block_rounded,
                                      size: 11, color: Colors.white),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(b.name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: AppText.label),
                                const SizedBox(height: 3),
                                Text(sub.isEmpty ? 'Blocked' : sub,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: AppText.caption
                                        .copyWith(color: AppColors.sText2)),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          GhostButton('Unblock',
                              small: true, onTap: () => _unblock(b)),
                        ],
                      ),
                    );
                  },
                ),
    );
  }
}
