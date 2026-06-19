import 'package:flutter/material.dart';

import '../../data/dto.dart';
import '../../data/repositories.dart';
import '../../models/models.dart';
import '../../state/app_state.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common.dart';
import '../../widgets/snack.dart';
import '../chat/conversation_screen.dart';
import '../subscription/paywall_screen.dart';

class SocialScreen extends StatefulWidget {
  const SocialScreen({super.key});

  @override
  State<SocialScreen> createState() => _SocialScreenState();
}

class _SocialScreenState extends State<SocialScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;
  List<SocialUserData> _likes = const [];
  List<SocialUserData> _views = const [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    if (!AppState.instance.isPremium) return;
    setState(() => _loading = true);
    try {
      final results = await Future.wait([
        Repos.social.whoLikedMe(),
        Repos.social.whoViewedMe(),
      ]);
      if (mounted) {
        setState(() {
          _likes = results[0];
          _views = results[1];
        });
      }
    } catch (_) {
      if (mounted) {
        showSnack(context, 'Could not load social data.', type: SnackType.error);
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isPremium = AppState.instance.isPremium;

    return Scaffold(
      backgroundColor: AppColors.sBg,
      appBar: AppBar(
        backgroundColor: AppColors.sBg,
        title: Text('Social', style: AppText.h2),
        elevation: 0,
        bottom: TabBar(
          controller: _tabs,
          labelStyle: AppText.label,
          unselectedLabelColor: AppColors.sText3,
          labelColor: AppColors.brand300,
          indicatorColor: AppColors.brand500,
          tabs: const [
            Tab(text: '❤️  Liked me'),
            Tab(text: '👁  Viewed me'),
          ],
        ),
      ),
      body: isPremium
          ? (_loading
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                  onRefresh: _load,
                  child: TabBarView(
                    controller: _tabs,
                    children: [
                      _SocialList(users: _likes, emptyLabel: 'No likes yet'),
                      _SocialList(users: _views, emptyLabel: 'No profile views yet'),
                    ],
                  ),
                ))
          : _PremiumGate(),
    );
  }
}

class _SocialList extends StatelessWidget {
  final List<SocialUserData> users;
  final String emptyLabel;
  const _SocialList({required this.users, required this.emptyLabel});

  @override
  Widget build(BuildContext context) {
    if (users.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🔍', style: TextStyle(fontSize: 48)),
            const SizedBox(height: 16),
            Text(emptyLabel, style: AppText.h3),
          ],
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.only(top: 8, bottom: 40),
      itemCount: users.length,
      itemBuilder: (_, i) => _SocialTile(user: users[i]),
    );
  }
}

class _SocialTile extends StatelessWidget {
  final SocialUserData user;
  const _SocialTile({required this.user});

  void _openChat(BuildContext context) {
    final speekUser = SpeekUser(
      id: user.userId,
      name: user.name,
      age: 0,
      flag: user.flag,
      country: user.country,
      city: '',
      role: SpeakerRole.learner,
      photoUrl: user.photoUrl,
    );
    Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => ConversationScreen(user: speekUser)));
  }

  String _timeLabel(DateTime? at) {
    if (at == null) return '';
    final diff = DateTime.now().difference(at);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: Insets.x5, vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.sFill(0.06),
        borderRadius: BorderRadius.circular(Radii.md),
      ),
      child: Row(
        children: [
          Avatar(user.photoUrl, size: 46, name: user.name),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(user.name, style: AppText.label),
                const SizedBox(height: 2),
                Text('${user.flag} ${user.country}',
                    style: AppText.caption.copyWith(color: AppColors.sText2)),
              ],
            ),
          ),
          if (user.at != null)
            Text(_timeLabel(user.at),
                style: AppText.caption.copyWith(color: AppColors.sText3)),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () => _openChat(context),
            child: Container(
              padding: const EdgeInsets.all(8),
              child: Icon(Icons.chat_bubble_outline_rounded,
                  color: AppColors.brand300, size: 20),
            ),
          ),
        ],
      ),
    );
  }
}

class _PremiumGate extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: Insets.x6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('👑', style: TextStyle(fontSize: 56)),
            const SizedBox(height: 16),
            Text('Premium feature', style: AppText.h2),
            const SizedBox(height: 8),
            Text(
              'See who liked and viewed your profile with a Premium subscription.',
              style: AppText.smMuted,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            PrimaryButton('Go Premium',
                onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const PaywallScreen()))),
          ],
        ),
      ),
    );
  }
}
