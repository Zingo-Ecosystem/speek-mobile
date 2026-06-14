import 'package:flutter/material.dart';

import '../../data/mock_data.dart';
import '../../models/models.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text.dart';
import '../../widgets/common.dart';
import '../call/incoming_call_screen.dart';

class ConversationScreen extends StatefulWidget {
  final SpeekUser user;
  const ConversationScreen({super.key, required this.user});

  @override
  State<ConversationScreen> createState() => _ConversationScreenState();
}

class _ConversationScreenState extends State<ConversationScreen> {
  late List<Message> _messages = List.of(_seed());
  final _controller = TextEditingController();

  List<Message> _seed() {
    final c = Mock.chats.firstWhere(
      (c) => c.user.id == widget.user.id,
      orElse: () => Mock.chats.first,
    );
    return c.user.id == widget.user.id ? c.messages : const [];
  }

  void _send() {
    final t = _controller.text.trim();
    if (t.isEmpty) return;
    setState(() {
      _messages = [..._messages, Message(text: t, outgoing: true)];
      _controller.clear();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.of(context).padding.top;
    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: Column(
        children: [
          _Header(user: widget.user, topPad: topPad),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(14),
              children: [
                Center(
                  child: Text('Today',
                      style: AppText.caption.copyWith(fontSize: 11)),
                ),
                const SizedBox(height: 8),
                for (final m in _messages) _bubble(m),
              ],
            ),
          ),
          _Composer(controller: _controller, onSend: _send),
        ],
      ),
    );
  }

  Widget _bubble(Message m) {
    if (m.kind == MessageKind.callLog) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
            decoration: BoxDecoration(
              color: AppColors.brand500.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.brand500.withValues(alpha: 0.3)),
            ),
            child: Text.rich(
              TextSpan(
                style: AppText.caption.copyWith(fontSize: 12.5, color: AppColors.n100),
                children: [
                  const TextSpan(text: '📞 Missed voice call · '),
                  TextSpan(
                      text: 'Call back',
                      style: AppText.caption.copyWith(
                          color: AppColors.brand300,
                          fontWeight: FontWeight.w700,
                          fontSize: 12.5)),
                ],
              ),
            ),
          ),
        ),
      );
    }

    final out = m.outgoing;
    final bubble = Container(
      constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.74),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        gradient: out ? AppColors.grad : null,
        color: out ? null : Colors.white.withValues(alpha: 0.07),
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(18),
          topRight: const Radius.circular(18),
          bottomLeft: Radius.circular(out ? 18 : 6),
          bottomRight: Radius.circular(out ? 6 : 18),
        ),
      ),
      child: m.kind == MessageKind.voice
          ? _voiceNote(m)
          : Text(m.text, style: AppText.body.copyWith(fontSize: 14)),
    );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.5),
      child: Align(
        alignment: out ? Alignment.centerRight : Alignment.centerLeft,
        child: bubble,
      ),
    );
  }

  Widget _voiceNote(Message m) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.play_arrow_rounded, size: 22, color: AppColors.brand200),
          const SizedBox(width: 8),
          SizedBox(
            width: 110,
            height: 20,
            child: Row(
              children: [
                for (int i = 0; i < 22; i++)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 1),
                      child: Container(
                        height: 4 + (i * 7 % 16).toDouble(),
                        decoration: BoxDecoration(
                            color: AppColors.brand300,
                            borderRadius: BorderRadius.circular(2)),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(m.voiceDuration,
              style: AppText.caption.copyWith(color: AppColors.n200)),
        ],
      );
}

class _Header extends StatelessWidget {
  final SpeekUser user;
  final double topPad;
  const _Header({required this.user, required this.topPad});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(8, topPad + 8, 14, 12),
      decoration: BoxDecoration(
        color: const Color(0xFF0C0C12).withValues(alpha: 0.92),
        border: Border(
            bottom: BorderSide(color: Colors.white.withValues(alpha: 0.07))),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.of(context).pop(),
          ),
          Avatar(user.photoUrl, size: 40),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${user.name} ${user.flag}', style: AppText.label),
                Text(user.online ? '● Online now' : 'Offline',
                    style: AppText.caption.copyWith(
                        color: user.online ? AppColors.success : AppColors.n300,
                        fontSize: 11)),
              ],
            ),
          ),
          _circle(Icons.mic_rounded, Colors.white.withValues(alpha: 0.06),
              () => _call(context)),
          const SizedBox(width: 8),
          _circle(Icons.videocam_rounded, null, () => _call(context),
              gradient: true),
        ],
      ),
    );
  }

  void _call(BuildContext context) => Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => IncomingCallScreen(user: user)));

  Widget _circle(IconData icon, Color? bg, VoidCallback onTap,
          {bool gradient = false}) =>
      GestureDetector(
        onTap: onTap,
        child: Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: bg,
            gradient: gradient ? AppColors.grad : null,
            borderRadius: BorderRadius.circular(13),
            border: gradient
                ? null
                : Border.all(color: Colors.white.withValues(alpha: 0.1)),
          ),
          child: Icon(icon, size: 18, color: Colors.white),
        ),
      );
}

class _Composer extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onSend;
  const _Composer({required this.controller, required this.onSend});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
          12, 8, 12, 8 + MediaQuery.of(context).padding.bottom),
      color: AppColors.bgApp,
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.06),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.add, color: Colors.white),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Container(
              constraints: const BoxConstraints(minHeight: 46),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(23),
                border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: controller,
                      style: AppText.body.copyWith(fontSize: 14),
                      cursorColor: AppColors.brand400,
                      minLines: 1,
                      maxLines: 4,
                      onSubmitted: (_) => onSend(),
                      decoration: InputDecoration(
                        isDense: true,
                        border: InputBorder.none,
                        hintText: 'Message…',
                        hintStyle:
                            AppText.body.copyWith(color: AppColors.n300, fontSize: 14),
                      ),
                    ),
                  ),
                  const Icon(Icons.emoji_emotions_outlined,
                      size: 20, color: AppColors.n300),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: onSend,
            child: Container(
              width: 46,
              height: 46,
              decoration: const BoxDecoration(
                  gradient: AppColors.grad, shape: BoxShape.circle),
              child: ValueListenableBuilder<TextEditingValue>(
                valueListenable: controller,
                builder: (_, v, __) => Icon(
                    v.text.trim().isEmpty ? Icons.mic_rounded : Icons.send_rounded,
                    size: 18,
                    color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
