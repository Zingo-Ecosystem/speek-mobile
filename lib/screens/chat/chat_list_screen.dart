import 'package:flutter/material.dart';

import '../../data/mock_data.dart';
import '../../models/models.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common.dart';
import 'conversation_screen.dart';

class ChatListScreen extends StatelessWidget {
  const ChatListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.of(context).padding.top;
    return Scaffold(
      body: ListView(
        padding: EdgeInsets.fromLTRB(Insets.x5, topPad + 16, Insets.x5, 120),
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Chats', style: AppText.displayMd.copyWith(fontSize: 26)),
              const SquareIconButton(Icons.edit_outlined),
            ],
          ),
          const SizedBox(height: 16),
          _searchBar(),
          const SizedBox(height: 22),
          _requestsHeader(),
          const SizedBox(height: 10),
          for (final r in Mock.requests) _RequestCard(chat: r),
          const SizedBox(height: 20),
          Text('MESSAGES',
              style: AppText.label
                  .copyWith(color: AppColors.n200, fontSize: 13)),
          const SizedBox(height: 4),
          for (final c in Mock.chats) _ChatRow(chat: c),
        ],
      ),
    );
  }

  Widget _searchBar() => Container(
        height: 44,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(Radii.md),
          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        ),
        child: Row(
          children: [
            const Icon(Icons.search, size: 18, color: AppColors.n300),
            const SizedBox(width: 8),
            Text('Search', style: AppText.body.copyWith(color: AppColors.n300)),
          ],
        ),
      );

  Widget _requestsHeader() => Row(
        children: [
          Text('REQUESTS',
              style: AppText.label
                  .copyWith(color: AppColors.n200, fontSize: 13)),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
                color: AppColors.like,
                borderRadius: BorderRadius.circular(100)),
            child: Text('3',
                style: AppText.caption.copyWith(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w700)),
          ),
        ],
      );
}

class _RequestCard extends StatelessWidget {
  final Chat chat;
  const _RequestCard({required this.chat});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.like.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.like.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Avatar(chat.user.photoUrl, size: 46),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${chat.user.name} ${chat.user.flag}',
                    style: AppText.label),
                const SizedBox(height: 2),
                Text(chat.preview,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.smMuted),
              ],
            ),
          ),
          const SizedBox(width: 8),
          _reqBtn(Icons.check, AppColors.success, const Color(0xFF062206)),
          const SizedBox(width: 6),
          _reqBtn(Icons.close, Colors.white.withValues(alpha: 0.08),
              AppColors.n200),
        ],
      ),
    );
  }

  Widget _reqBtn(IconData icon, Color bg, Color fg) => Container(
        width: 34,
        height: 34,
        decoration:
            BoxDecoration(color: bg, borderRadius: BorderRadius.circular(11)),
        child: Icon(icon, size: 16, color: fg),
      );
}

class _ChatRow extends StatelessWidget {
  final Chat chat;
  const _ChatRow({required this.chat});
  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => ConversationScreen(user: chat.user))),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 11),
        child: Row(
          children: [
            Avatar(chat.user.photoUrl, size: 52),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${chat.user.name} ${chat.user.flag}',
                      style: AppText.label.copyWith(fontSize: 15)),
                  const SizedBox(height: 2),
                  Text(
                    chat.previewIsVoice ? '🎙 ${chat.preview}' : chat.preview,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.caption.copyWith(
                        fontSize: 13,
                        color: chat.previewIsVoice
                            ? AppColors.brand300
                            : AppColors.n300),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(chat.timeLabel,
                    style: AppText.caption.copyWith(fontSize: 11)),
                if (chat.unread > 0) ...[
                  const SizedBox(height: 4),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 7, vertical: 1),
                    decoration: BoxDecoration(
                        color: AppColors.brand500,
                        borderRadius: BorderRadius.circular(100)),
                    child: Text('${chat.unread}',
                        style: AppText.caption.copyWith(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w700)),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
