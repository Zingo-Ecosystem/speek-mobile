import 'dart:async';
import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart'
    show DefaultCacheManager;
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

import '../../core/api_client.dart';
import '../../core/session.dart';
import '../../data/repositories.dart';
import '../../models/models.dart';
import '../../realtime/realtime_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text.dart';
import '../../widgets/common.dart';
import '../call/incoming_call_screen.dart';
import '../profile/user_profile_screen.dart';

class ConversationScreen extends StatefulWidget {
  final SpeekUser user;
  final String conversationId;
  /// Pre-started fetch kicked off at tap time so messages arrive during the
  /// navigation animation rather than after the screen is fully visible.
  final Future<List<Message>>? prefetch;
  const ConversationScreen(
      {super.key,
      required this.user,
      this.conversationId = '',
      this.prefetch});

  @override
  State<ConversationScreen> createState() => _ConversationScreenState();
}

class _ConversationScreenState extends State<ConversationScreen> {
  // Oldest → newest order. Reversed ListView renders newest at bottom.
  List<Message> _messages = const [];
  bool _loading = true;
  bool _loadingMore = false;
  bool _hasMore = true;
  bool _peerIsTyping = false;
  bool _emojiOpen = false;

  // Resolved at load-time — may be resolved via API if widget.conversationId is empty.
  String _conversationId = '';

  final _controller = TextEditingController();
  final _composerFocusNode = FocusNode();
  final _scroll = ScrollController();
  StreamSubscription? _msgSub;
  StreamSubscription? _typingSub;
  Timer? _typingTimer;

  // Media state ---------------------------------------------------------------
  // Images: remote URL → downloaded local path
  final _imageLocalPaths = <String, String>{};
  final _downloadingImages = <String>{};
  // Voice: remote URL → downloaded local path
  final _voiceLocalPaths = <String, String>{};
  final _downloadingVoices = <String>{};
  String? _playingVoiceUrl;
  late final AudioPlayer _audioPlayer;

  @override
  void initState() {
    super.initState();
    _conversationId = widget.conversationId;
    RealtimeService.instance.activePeerId = widget.user.id;
    RealtimeService.instance.registerPeer(widget.user.id, widget.user.name);
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
    _msgSub = RealtimeService.instance.onMessage.listen((m) {
      // Incoming messages append live. Call-logs also arrive as "outgoing" for
      // the caller (sent on their behalf) and aren't added optimistically, so
      // let those through too — otherwise the caller wouldn't see the call entry.
      if (mounted && (!m.outgoing || m.kind == MessageKind.callLog)) {
        setState(() => _messages = [..._messages, m]);
      }
    });
    _typingSub = RealtimeService.instance.onTyping.listen((e) {
      if (mounted && e.from == widget.user.id) {
        setState(() => _peerIsTyping = e.isTyping);
      }
    });
    _controller.addListener(_onTextChanged);
    _scroll.addListener(_onScroll);

    _audioPlayer = AudioPlayer();
    _audioPlayer.onPlayerComplete.listen((_) {
      if (mounted) setState(() => _playingVoiceUrl = null);
    });
  }

  // In reverse:true ListView, maxScrollExtent is the top (oldest messages).
  void _onScroll() {
    if (_scroll.position.pixels >= _scroll.position.maxScrollExtent - 200 &&
        !_loadingMore &&
        _hasMore &&
        !_loading) {
      _loadMore();
    }
  }

  void _onTextChanged() {
    if (!Session.instance.isAuthenticated || widget.user.id.isEmpty) return;
    if (_controller.text.isNotEmpty) {
      RealtimeService.instance.sendTyping(widget.user.id, true);
      _typingTimer?.cancel();
      _typingTimer = Timer(const Duration(seconds: 2), () {
        RealtimeService.instance.sendTyping(widget.user.id, false);
      });
    }
  }

  Future<void> _load() async {
    if (!Session.instance.isAuthenticated) {
      setState(() => _loading = false);
      return;
    }
    try {
      if (_conversationId.isEmpty) {
        final id = await Repos.chat.findConversationByPeer(widget.user.id);
        if (!mounted) return;
        _conversationId = id;
      }
      if (_conversationId.isEmpty) {
        setState(() => _loading = false);
        return;
      }
      final msgs = widget.prefetch != null
          ? await widget.prefetch!
          : await Repos.chat.messages(_conversationId);
      if (!mounted) return;
      setState(() {
        _messages = msgs;
        _loading = false;
        _hasMore = msgs.length >= 30;
      });
      Repos.chat.markRead(_conversationId).catchError((_) {});
      _restoreCachedMedia(msgs);
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _loadMore() async {
    if (_messages.isEmpty || _loadingMore || !_hasMore) return;
    setState(() => _loadingMore = true);
    try {
      final oldest = _messages.first.time;
      final older = await Repos.chat.messages(
        _conversationId,
        before: oldest,
      );
      if (!mounted) return;
      setState(() {
        _messages = [...older, ..._messages];
        _hasMore = older.length >= 30;
        _loadingMore = false;
      });
      _restoreCachedMedia(older);
    } catch (_) {
      if (mounted) setState(() => _loadingMore = false);
    }
  }

  /// After loading messages, restore any media already cached in a previous session.
  Future<void> _restoreCachedMedia(List<Message> msgs) async {
    for (final m in msgs) {
      final url = m.mediaUrl;
      if (url.isEmpty || !url.startsWith('http')) continue;
      final info = await DefaultCacheManager().getFileFromCache(url);
      if (info == null || !mounted) continue;
      if (m.kind == MessageKind.image) {
        setState(() => _imageLocalPaths[url] = info.file.path);
      } else if (m.kind == MessageKind.voice) {
        // Cache manager stores files with a .file extension which Android
        // MediaPlayer cannot decode. Copy to a temp path with the real extension.
        final ext = url.split('.').last.split('?').first;
        final dir = await getTemporaryDirectory();
        final localPath = '${dir.path}/${url.hashCode}.$ext';
        if (!File(localPath).existsSync()) {
          await info.file.copy(localPath);
        }
        if (mounted) setState(() => _voiceLocalPaths[url] = localPath);
      }
    }
  }

  Future<void> _send() async {
    final t = _controller.text.trim();
    if (t.isEmpty) return;
    _controller.clear();
    _typingTimer?.cancel();
    if (Session.instance.isAuthenticated && widget.user.id.isNotEmpty) {
      RealtimeService.instance.sendTyping(widget.user.id, false);
    }
    final optimistic = Message(text: t, outgoing: true, time: DateTime.now());
    setState(() => _messages = [..._messages, optimistic]);
    if (!Session.instance.isAuthenticated) return;
    try {
      final sent = await Repos.chat.send(
        peerId: widget.user.id,
        kind: MessageKind.text,
        text: t,
      );
      if (mounted) {
        setState(() {
          final idx = _messages.lastIndexOf(optimistic);
          if (idx >= 0) {
            final list = List<Message>.from(_messages);
            list[idx] = sent;
            _messages = list;
          }
        });
      }
    } catch (_) {}
  }

  Future<void> _sendImageMessage(String filePath) async {
    final optimistic = Message(
      kind: MessageKind.image,
      text: '',
      outgoing: true,
      mediaUrl: filePath,
      time: DateTime.now(),
    );
    setState(() => _messages = [..._messages, optimistic]);
    if (!Session.instance.isAuthenticated) return;
    try {
      final url = await Repos.chat.uploadMedia(filePath);
      // Cache under the remote URL so it never re-downloads.
      final bytes = await File(filePath).readAsBytes();
      final dir = await getTemporaryDirectory();
      final localPath = '${dir.path}/${url.hashCode}.jpg';
      await File(localPath).writeAsBytes(bytes);
      await DefaultCacheManager().putFile(url, bytes, fileExtension: 'jpg');
      final sent = await Repos.chat.send(
        peerId: widget.user.id,
        kind: MessageKind.image,
        mediaUrl: url,
      );
      if (mounted) {
        setState(() {
          // Key by sent.mediaUrl (normalized) so _imageNote lookup always hits.
          _imageLocalPaths[sent.mediaUrl] = localPath;
          final idx = _messages.lastIndexOf(optimistic);
          if (idx >= 0) {
            final list = List<Message>.from(_messages);
            list[idx] = sent;
            _messages = list;
          }
        });
      }
    } catch (_) {
      if (mounted) {
        setState(
            () => _messages = _messages.where((m) => m != optimistic).toList());
      }
    }
  }

  Future<void> _sendVoiceMessage(String filePath, int durationSecs) async {
    if (durationSecs < 1) return;
    final dur =
        '${durationSecs ~/ 60}:${(durationSecs % 60).toString().padLeft(2, '0')}';
    final optimistic = Message(
      kind: MessageKind.voice,
      text: '',
      outgoing: true,
      voiceDuration: dur,
      time: DateTime.now(),
    );
    setState(() => _messages = [..._messages, optimistic]);
    if (!Session.instance.isAuthenticated) return;
    try {
      final url = await Repos.chat.uploadMedia(filePath);
      final sent = await Repos.chat.send(
        peerId: widget.user.id,
        kind: MessageKind.voice,
        mediaUrl: url,
        durationSeconds: durationSecs,
      );
      if (mounted) {
        setState(() {
          final idx = _messages.lastIndexOf(optimistic);
          if (idx >= 0) {
            final list = List<Message>.from(_messages);
            list[idx] = sent;
            _messages = list;
          }
        });
      }
    } catch (_) {
      // Keep optimistic voice message visible on upload/send failure.
    }
  }

  Future<void> _editMessage(Message m) async {
    final ctrl = TextEditingController(text: m.text);
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text('Edit message', style: AppText.label),
        content: TextField(
          controller: ctrl,
          style: AppText.body.copyWith(fontSize: 14),
          autofocus: true,
          minLines: 1,
          maxLines: 5,
          cursorColor: AppColors.brand400,
          decoration: InputDecoration(
            isDense: true,
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide:
                    BorderSide(color: Colors.white.withValues(alpha: 0.15))),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.brand400),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text('Cancel',
                style: AppText.caption.copyWith(color: AppColors.n300)),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(ctrl.text.trim()),
            child: Text('Save',
                style: AppText.caption.copyWith(color: AppColors.brand400)),
          ),
        ],
      ),
    );
    if (result == null || result.isEmpty || result == m.text) return;
    final previous = _messages.toList();
    if (mounted) {
      setState(() {
        _messages = _messages
            .map((msg) => msg.id == m.id ? msg.copyWith(text: result) : msg)
            .toList();
      });
    }
    try {
      await Repos.chat.editMessage(m.id, result);
    } catch (_) {
      if (mounted) setState(() => _messages = previous);
    }
  }

  Future<void> _deleteMessage(Message m) async {
    final previous = _messages.toList();
    if (mounted) {
      setState(
          () => _messages = _messages.where((msg) => msg.id != m.id).toList());
    }
    try {
      await Repos.chat.deleteMessage(m.id);
    } catch (_) {
      if (mounted) setState(() => _messages = previous);
    }
  }

  // ---------------------------------------------------------------------------
  // Media helpers
  // ---------------------------------------------------------------------------

  Future<void> _downloadImage(String url) async {
    if (_downloadingImages.contains(url) || _imageLocalPaths.containsKey(url)) return;
    setState(() => _downloadingImages.add(url));
    try {
      final bytes = await ApiClient.instance.downloadBytes(url);
      final dir = await getTemporaryDirectory();
      final ext = url.split('.').last.split('?').first;
      final localPath = '${dir.path}/${url.hashCode}.$ext';
      await File(localPath).writeAsBytes(bytes);
      await DefaultCacheManager().putFile(url, bytes);
      debugPrint('[_downloadImage] saved to $localPath');
      if (mounted) {
        setState(() {
          _imageLocalPaths[url] = localPath;
          _downloadingImages.remove(url);
        });
      }
    } catch (e) {
      debugPrint('[_downloadImage] failed: $e');
      if (mounted) setState(() => _downloadingImages.remove(url));
    }
  }

  void _openImagePreview({String? localPath}) {
    if (localPath == null) return;
    final Widget img = Image.file(File(localPath), fit: BoxFit.contain);

    showDialog<void>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.93),
      barrierDismissible: true,
      builder: (ctx) => Stack(
        children: [
          InteractiveViewer(
            minScale: 0.5,
            maxScale: 5.0,
            child: SizedBox.expand(
              child: Center(child: img),
            ),
          ),
          SafeArea(
            child: Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: IconButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  icon: const Icon(Icons.close_rounded,
                      color: Colors.white, size: 26),
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.black45,
                    shape: const CircleBorder(),
                    padding: const EdgeInsets.all(8),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _downloadVoice(String url) async {
    if (_downloadingVoices.contains(url) || _voiceLocalPaths.containsKey(url)) return;
    setState(() => _downloadingVoices.add(url));
    try {
      final bytes = await ApiClient.instance.downloadBytes(url);
      final dir = await getTemporaryDirectory();
      final ext = url.split('.').last.split('?').first;
      final localPath = '${dir.path}/${url.hashCode}.$ext';
      await File(localPath).writeAsBytes(bytes);
      await DefaultCacheManager().putFile(url, bytes);
      debugPrint('[_downloadVoice] saved to $localPath');
      if (mounted) {
        setState(() {
          _voiceLocalPaths[url] = localPath;
          _downloadingVoices.remove(url);
        });
      }
    } catch (e) {
      debugPrint('[_downloadVoice] failed: $e');
      if (mounted) setState(() => _downloadingVoices.remove(url));
    }
  }

  Future<void> _togglePlayVoice(String url) async {
    final localPath = _voiceLocalPaths[url];
    if (localPath == null) return;
    if (_playingVoiceUrl == url) {
      await _audioPlayer.pause();
      setState(() => _playingVoiceUrl = null);
    } else {
      await _audioPlayer.stop();
      await _audioPlayer.play(DeviceFileSource(localPath));
      setState(() => _playingVoiceUrl = url);
    }
  }

  // ---------------------------------------------------------------------------

  void _showMessageActions(Message m, BuildContext bubbleCtx) async {
    final wasFocused = _composerFocusNode.hasFocus;

    final box = bubbleCtx.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return;
    final pos = box.localToGlobal(Offset.zero);
    final bSize = box.size;
    final screen = MediaQuery.sizeOf(context);

    final result = await showMenu<String>(
      context: context,
      color: const Color(0xFF1E1E2A),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      elevation: 6,
      position: RelativeRect.fromLTRB(
        // Outgoing bubbles sit on the right — pass the right edge as `left`
        // so Flutter can't fit the menu to the right and falls back to
        // right-aligning it with the bubble. Incoming bubbles: left-align.
        m.outgoing ? pos.dx + bSize.width : pos.dx,
        pos.dy + bSize.height + 4,
        screen.width - pos.dx - bSize.width,
        screen.height - pos.dy + 4,
      ),
      items: [
        if (m.outgoing && m.kind == MessageKind.text)
          PopupMenuItem(
            value: 'edit',
            height: 44,
            child: Row(children: [
              const Icon(Icons.edit_outlined, size: 17, color: Colors.white),
              const SizedBox(width: 10),
              Text('Edit', style: AppText.body.copyWith(fontSize: 14)),
            ]),
          ),
        PopupMenuItem(
          value: 'delete',
          height: 44,
          child: Row(children: [
            const Icon(Icons.delete_outline, size: 17, color: AppColors.danger),
            const SizedBox(width: 10),
            Text('Delete',
                style: AppText.body
                    .copyWith(fontSize: 14, color: AppColors.danger)),
          ]),
        ),
      ],
    );

    if (wasFocused && mounted) _composerFocusNode.requestFocus();

    if (result == 'edit') _editMessage(m);
    if (result == 'delete') _deleteMessage(m);
  }

  @override
  void dispose() {
    if (RealtimeService.instance.activePeerId == widget.user.id) {
      RealtimeService.instance.activePeerId = null;
    }
    _msgSub?.cancel();
    _typingSub?.cancel();
    _typingTimer?.cancel();
    _controller.removeListener(_onTextChanged);
    _scroll.removeListener(_onScroll);
    _controller.dispose();
    _composerFocusNode.dispose();
    _scroll.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final keyboardInset = MediaQuery.viewInsetsOf(context).bottom;
    final safeBottom = MediaQuery.paddingOf(context).bottom;
    final listBottomPad = _emojiOpen
        ? 62.0 + 280.0 + safeBottom
        : 62.0 + safeBottom + keyboardInset;

    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          SafeArea(
            bottom: false,
            child: Column(
              children: [
                _Header(user: widget.user, topPad: 0, isTyping: _peerIsTyping),
                Expanded(
                  child: _loading
                      ? const Center(
                          child: CircularProgressIndicator(
                              strokeWidth: 2.5, color: AppColors.brand400))
                      : ListView.builder(
                          controller: _scroll,
                          reverse: true,
                          // ignore: deprecated_member_use
                          cacheExtent: 300,
                          padding:
                              EdgeInsets.fromLTRB(14, 8, 14, listBottomPad),
                          itemCount: _messages.length + (_loadingMore ? 1 : 0),
                          itemBuilder: (ctx, i) {
                            if (i == _messages.length) {
                              return const Center(
                                child: Padding(
                                  padding: EdgeInsets.all(16),
                                  child: SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: AppColors.brand400),
                                  ),
                                ),
                              );
                            }
                            final msgIndex = _messages.length - 1 - i;
                            final m = _messages[msgIndex];
                            final showDate = msgIndex == 0 ||
                                !_sameDay(
                                    _messages[msgIndex - 1].time, m.time);
                            return Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (showDate) _dateSeparator(m.time),
                                _bubble(m),
                              ],
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _Composer(
              controller: _controller,
              focusNode: _composerFocusNode,
              onSend: _send,
              onEmojiToggled: (v) => setState(() => _emojiOpen = v),
              onSendImage: _sendImageMessage,
              onSendVoice: _sendVoiceMessage,
            ),
          ),
        ],
      ),
    );
  }

  static bool _sameDay(DateTime? a, DateTime? b) {
    if (a == null || b == null) return false;
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  static String _dateLabel(DateTime? t) {
    if (t == null) return '';
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(t.year, t.month, t.day);
    final diff = today.difference(day).inDays;
    if (diff == 0) return 'Today';
    if (diff == 1) return 'Yesterday';
    if (diff < 7) {
      const names = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      return names[t.weekday - 1];
    }
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${t.day} ${months[t.month - 1]}${t.year != now.year ? ' ${t.year}' : ''}';
  }

  Widget _dateSeparator(DateTime? time) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.07),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              _dateLabel(time),
              style:
                  AppText.caption.copyWith(fontSize: 11, color: AppColors.n200),
            ),
          ),
        ),
      );

  Widget _bubble(Message m) {
    if (m.kind == MessageKind.callLog) {
      return _callLogBubble(m);
    }

    final canAct = m.id.isNotEmpty && m.outgoing;
    final content = _buildBubbleContent(m);
    if (!canAct) return content;
    return Builder(
      builder: (bubbleCtx) => GestureDetector(
        behavior: HitTestBehavior.opaque,
        // Images and voice handle their own onTap; use long-press for the menu.
        onTapDown: (m.kind == MessageKind.image || m.kind == MessageKind.voice)
            ? null
            : (_) => _showMessageActions(m, bubbleCtx),
        onLongPress: (m.kind == MessageKind.image || m.kind == MessageKind.voice)
            ? () => _showMessageActions(m, bubbleCtx)
            : null,
        child: content,
      ),
    );
  }

  /// A Telegram-style call entry: direction icon + label + time/duration.
  Widget _callLogBubble(Message m) {
    final text = m.text;
    final isVideo = text.contains('📹') || text.toLowerCase().contains('video');
    final isMissed = text.contains('Missed') ||
        text.contains('Declined') ||
        text.contains('Cancelled');
    final out = m.outgoing;

    final title = isMissed
        ? (out
            ? (text.contains('Cancelled') ? 'Cancelled call' : 'Call ended')
            : (text.contains('Declined') ? 'Declined call' : 'Missed call'))
        : (out ? 'Outgoing call' : 'Incoming call');

    final accent = isMissed ? AppColors.danger : AppColors.brand300;
    final detail = StringBuffer(_clockLabel(m.time));
    if (m.durationSeconds > 0) {
      detail.write(', ${_durationWords(m.durationSeconds)}');
    }

    final content = Container(
      constraints:
          BoxConstraints(maxWidth: MediaQuery.sizeOf(context).width * 0.7),
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
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 34,
            height: 34,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: out ? 0.18 : 0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isVideo ? Icons.videocam_rounded : Icons.call_rounded,
              size: 18,
              color: out ? Colors.white : accent,
            ),
          ),
          const SizedBox(width: 10),
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: AppText.label.copyWith(
                      fontSize: 14,
                      color: out ? Colors.white : AppColors.n100)),
              const SizedBox(height: 2),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    out ? Icons.north_east_rounded : Icons.south_west_rounded,
                    size: 12,
                    color: out
                        ? Colors.white.withValues(alpha: 0.7)
                        : (isMissed ? accent : AppColors.n300),
                  ),
                  const SizedBox(width: 4),
                  Text(detail.toString(),
                      style: AppText.caption.copyWith(
                          fontSize: 11.5,
                          color: out
                              ? Colors.white.withValues(alpha: 0.75)
                              : AppColors.n300)),
                ],
              ),
            ],
          ),
        ],
      ),
    );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.5),
      child: Align(
        alignment: out ? Alignment.centerRight : Alignment.centerLeft,
        child: content,
      ),
    );
  }

  static String _durationWords(int seconds) {
    if (seconds < 60) return '$seconds second${seconds == 1 ? '' : 's'}';
    final m = seconds ~/ 60, s = seconds % 60;
    if (s == 0) return '$m minute${m == 1 ? '' : 's'}';
    return '${m}m ${s}s';
  }

  static String _clockLabel(DateTime? t) {
    if (t == null) return '';
    final h24 = t.hour;
    final ampm = h24 < 12 ? 'AM' : 'PM';
    final h12 = h24 % 12 == 0 ? 12 : h24 % 12;
    return '$h12:${t.minute.toString().padLeft(2, '0')} $ampm';
  }

  static String _timeLabel(DateTime? t) {
    if (t == null) return '';
    return '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
  }

  Widget _buildBubbleContent(Message m) {
    final out = m.outgoing;
    final timeStr = _timeLabel(m.time);
    final bubble = Container(
      constraints:
          BoxConstraints(maxWidth: MediaQuery.sizeOf(context).width * 0.74),
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 6),
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
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment:
            out ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          _bubbleBody(m),
          if (timeStr.isNotEmpty) ...[
            const SizedBox(height: 3),
            Text(
              timeStr,
              style: AppText.caption.copyWith(
                fontSize: 10,
                color: out
                    ? Colors.white.withValues(alpha: 0.55)
                    : AppColors.n300,
              ),
            ),
          ],
        ],
      ),
    );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.5),
      child: Align(
        alignment: out ? Alignment.centerRight : Alignment.centerLeft,
        child: bubble,
      ),
    );
  }

  Widget _bubbleBody(Message m) {
    switch (m.kind) {
      case MessageKind.voice:
        return _voiceNote(m);
      case MessageKind.image:
        return _imageNote(m);
      case MessageKind.document:
        return _documentNote(m);
      default:
        return Text(m.text, style: AppText.body.copyWith(fontSize: 14));
    }
  }

  Widget _voiceNote(Message m) {
    final url = m.mediaUrl;
    final isLocal = url.isNotEmpty && !url.startsWith('http');
    final localPath = isLocal ? url : _voiceLocalPaths[url];
    final isDownloading = _downloadingVoices.contains(url);
    final isPlaying = _playingVoiceUrl == url;

    // Waveform bars helper
    Widget waveform(Color color) => SizedBox(
          width: 90,
          height: 20,
          child: Row(
            children: [
              for (int i = 0; i < 18; i++)
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 1),
                    child: Container(
                      height: 4 + (i * 7 % 16).toDouble(),
                      decoration: BoxDecoration(
                          color: color, borderRadius: BorderRadius.circular(2)),
                    ),
                  ),
                ),
            ],
          ),
        );

    // Already have a local path → show play/pause
    if (localPath != null) {
      Future<void> togglePlay() async {
        if (isLocal) {
          if (isPlaying) {
            await _audioPlayer.pause();
            setState(() => _playingVoiceUrl = null);
          } else {
            await _audioPlayer.stop();
            await _audioPlayer.play(DeviceFileSource(localPath));
            setState(() => _playingVoiceUrl = url);
          }
        } else {
          _togglePlayVoice(url);
        }
      }

      return GestureDetector(
        onTap: togglePlay,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
              size: 30,
              color: AppColors.brand200,
            ),
            const SizedBox(width: 8),
            waveform(AppColors.brand300),
            const SizedBox(width: 8),
            Text(m.voiceDuration,
                style: AppText.caption.copyWith(color: AppColors.n200)),
          ],
        ),
      );
    }

    // Remote URL not yet downloaded
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (isDownloading)
          const SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(
                strokeWidth: 2, color: AppColors.brand300),
          )
        else
          GestureDetector(
            onTap: () => _downloadVoice(url),
            child: const Icon(Icons.download_rounded,
                size: 22, color: AppColors.brand200),
          ),
        const SizedBox(width: 8),
        waveform(AppColors.brand300.withValues(alpha: 0.4)),
        const SizedBox(width: 8),
        Text(m.voiceDuration,
            style: AppText.caption.copyWith(color: AppColors.n200)),
      ],
    );
  }

  Widget _imageNote(Message m) {
    final url = m.mediaUrl;
    if (url.isEmpty) {
      return const Icon(Icons.image_outlined, color: AppColors.n300, size: 40);
    }

    // Local file during optimistic update — show immediately with tap-to-preview.
    if (!url.startsWith('http')) {
      return GestureDetector(
        onTap: () => _openImagePreview(localPath: url),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Image.file(File(url), width: 200, height: 160, fit: BoxFit.cover),
        ),
      );
    }

    final localPath = _imageLocalPaths[url];
    final isDownloading = _downloadingImages.contains(url);

    // Downloaded — show from local file.
    if (localPath != null) {
      return GestureDetector(
        onTap: () => _openImagePreview(localPath: localPath),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Image.file(
            File(localPath),
            width: 200,
            height: 160,
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) => Container(
              width: 200,
              height: 160,
              color: Colors.white.withValues(alpha: 0.06),
              child: const Icon(Icons.broken_image_outlined,
                  color: AppColors.n300, size: 40),
            ),
          ),
        ),
      );
    }

    // Downloading — show spinner.
    if (isDownloading) {
      return Container(
        width: 200,
        height: 160,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Center(
          child: SizedBox(
            width: 26,
            height: 26,
            child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.brand400),
          ),
        ),
      );
    }

    // Not yet downloaded — show tap-to-download button.
    return GestureDetector(
      onTap: () => _downloadImage(url),
      child: Container(
        width: 200,
        height: 160,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.brand500.withValues(alpha: 0.18),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.download_rounded,
                  size: 22, color: AppColors.brand300),
            ),
            const SizedBox(height: 8),
            Text('Tap to load',
                style: AppText.caption
                    .copyWith(fontSize: 11, color: AppColors.n300)),
          ],
        ),
      ),
    );
  }

  Widget _documentNote(Message m) {
    final name = m.documentName.isNotEmpty ? m.documentName : 'File';
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Colors.blue.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(Icons.insert_drive_file_rounded,
              color: Colors.blue, size: 22),
        ),
        const SizedBox(width: 10),
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(name,
                  style: AppText.body.copyWith(fontSize: 13),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis),
              Text('Document',
                  style: AppText.caption
                      .copyWith(fontSize: 11, color: AppColors.n300)),
            ],
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------

class _Header extends StatelessWidget {
  final SpeekUser user;
  final double topPad;
  final bool isTyping;
  const _Header(
      {required this.user, required this.topPad, this.isTyping = false});

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
          GestureDetector(
            onTap: () => _openProfile(context),
            behavior: HitTestBehavior.opaque,
            child: Row(
              children: [
                Hero(
                  tag: 'avatar_${user.id}',
                  child: Avatar(user.photoUrl, size: 40, name: user.name),
                ),
                const SizedBox(width: 10),
              ],
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => _openProfile(context),
              behavior: HitTestBehavior.opaque,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${user.name} ${user.flag}', style: AppText.label),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    child: Text(
                      isTyping
                          ? 'typing...'
                          : (user.online ? '● Online now' : 'Offline'),
                      key: ValueKey(isTyping),
                      style: AppText.caption.copyWith(
                        color: isTyping
                            ? AppColors.brand300
                            : (user.online
                                ? AppColors.success
                                : AppColors.n300),
                        fontSize: 11,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Voice + video both place the call immediately.
          _circle(Icons.call_rounded, null, () => _call(context, video: false)),
          const SizedBox(width: 8),
          _circle(Icons.videocam_rounded, null, () => _call(context, video: true),
              gradient: true),
        ],
      ),
    );
  }

  void _openProfile(BuildContext context) => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => UserProfileScreen(user: user, cameFromChat: true),
        ),
      );

  void _call(BuildContext context, {required bool video}) =>
      Navigator.of(context).push(
        PageRouteBuilder<void>(
          pageBuilder: (_, _, _) =>
              IncomingCallScreen(user: user, autoStartVideo: video),
          transitionDuration: const Duration(milliseconds: 380),
          reverseTransitionDuration: const Duration(milliseconds: 280),
          transitionsBuilder: (_, animation, _, child) {
            final curved = CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
              reverseCurve: Curves.easeInCubic,
            );
            return FadeTransition(
              opacity: curved,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 0.06),
                  end: Offset.zero,
                ).animate(curved),
                child: child,
              ),
            );
          },
        ),
      );

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

// ---------------------------------------------------------------------------

class _Composer extends StatefulWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final VoidCallback onSend;
  final void Function(bool) onEmojiToggled;
  final Future<void> Function(String path) onSendImage;
  final Future<void> Function(String path, int durationSecs) onSendVoice;

  const _Composer({
    required this.controller,
    required this.focusNode,
    required this.onSend,
    required this.onEmojiToggled,
    required this.onSendImage,
    required this.onSendVoice,
  });

  @override
  State<_Composer> createState() => _ComposerState();
}

class _ComposerState extends State<_Composer> {
  bool _showEmoji = false;
  final _recorder = AudioRecorder();
  bool _isRecording = false;
  bool _cancelRecord = false;
  bool _pointerDown = false;    // tracks live finger contact on mic button
  double _pointerStartX = 0;   // for swipe-to-cancel detection
  DateTime? _recordStart;
  Timer? _recordTimer;
  int _recordSeconds = 0;
  // Recorded but not yet sent — shown as a preview with a send button.
  String? _recordedPath;
  int _recordedDuration = 0;

  @override
  void initState() {
    super.initState();
    widget.focusNode.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    widget.focusNode.removeListener(_onFocusChange);
    _recordTimer?.cancel();
    _recorder.dispose();
    super.dispose();
  }

  void _onFocusChange() {
    if (widget.focusNode.hasFocus && _showEmoji) {
      setState(() => _showEmoji = false);
      widget.onEmojiToggled(false);
    }
  }

  void _toggleEmoji() {
    final next = !_showEmoji;
    if (next) {
      widget.focusNode.unfocus();
    } else {
      widget.focusNode.requestFocus();
    }
    setState(() => _showEmoji = next);
    widget.onEmojiToggled(next);
  }

  Future<void> _pickImage() async {
    widget.focusNode.unfocus();
    if (_showEmoji) {
      setState(() => _showEmoji = false);
      widget.onEmojiToggled(false);
    }
    final image = await ImagePicker()
        .pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (image != null && mounted) widget.onSendImage(image.path);
  }

  Future<void> _startRecording() async {
    final hasPermission = await _recorder.hasPermission();
    if (!hasPermission || !mounted) return;

    final dir = await getTemporaryDirectory();
    final path =
        '${dir.path}/voice_${DateTime.now().millisecondsSinceEpoch}.aac';

    await _recorder.start(
      const RecordConfig(encoder: AudioEncoder.aacLc),
      path: path,
    );

    // If the finger was released while we were setting up (permission / IO),
    // stop immediately instead of leaving a ghost recording running.
    if (!_pointerDown || !mounted) {
      await _recorder.stop();
      return;
    }

    _recordStart = DateTime.now();
    _recordSeconds = 0;
    _cancelRecord = false;
    _recordTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _recordSeconds++);
    });
    setState(() => _isRecording = true);
  }

  Future<void> _stopRecording({bool cancel = false}) async {
    _recordTimer?.cancel();
    _recordTimer = null;
    final path = await _recorder.stop();
    final duration =
        DateTime.now().difference(_recordStart ?? DateTime.now()).inSeconds;
    if (!cancel && path != null && path.isNotEmpty && duration >= 1) {
      setState(() {
        _isRecording = false;
        _cancelRecord = false;
        _recordSeconds = 0;
        _recordedPath = path;
        _recordedDuration = duration;
      });
    } else {
      setState(() {
        _isRecording = false;
        _cancelRecord = false;
        _recordSeconds = 0;
      });
    }
  }

  void _sendPendingVoice() {
    final path = _recordedPath;
    final dur = _recordedDuration;
    if (path == null) return;
    setState(() {
      _recordedPath = null;
      _recordedDuration = 0;
    });
    widget.onSendVoice(path, dur);
  }

  void _discardPendingVoice() {
    setState(() {
      _recordedPath = null;
      _recordedDuration = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    final keyboardInset = MediaQuery.viewInsetsOf(context).bottom;
    final safeBottom = MediaQuery.paddingOf(context).bottom;
    final panelHeight = 280.0 + safeBottom;

    return ColoredBox(
      color: AppColors.bgApp,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(
              12,
              8,
              12,
              _showEmoji ? 8 : 8 + keyboardInset + safeBottom,
            ),
            child: _buildRow(),
          ),
          ClipRect(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 280),
              curve: Curves.easeOut,
              height: _showEmoji ? panelHeight : 0,
              child: SizedBox(
                height: panelHeight,
                child: Padding(
                  padding: EdgeInsets.only(bottom: safeBottom),
                  child: EmojiPicker(
                    textEditingController: widget.controller,
                    config: Config(
                      height: 280,
                      checkPlatformCompatibility: false,
                      emojiViewConfig: EmojiViewConfig(
                        backgroundColor: AppColors.bgApp,
                        columns: 8,
                        emojiSizeMax: 26,
                      ),
                      categoryViewConfig: CategoryViewConfig(
                        backgroundColor: AppColors.bgApp,
                        iconColor: AppColors.n300,
                        iconColorSelected: AppColors.brand400,
                        indicatorColor: AppColors.brand400,
                        initCategory: Category.SMILEYS,
                      ),
                      bottomActionBarConfig: BottomActionBarConfig(
                        backgroundColor: AppColors.bgApp,
                        buttonColor: AppColors.brand400,
                        buttonIconColor: Colors.white,
                        showSearchViewButton: false,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRow() {
    // Pending-send state: recording done, waiting for user to confirm.
    if (_recordedPath != null) {
      return Row(
        children: [
          GestureDetector(
            onTap: _discardPendingVoice,
            child: Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(child: _buildVoicePreview()),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: _sendPendingVoice,
            child: Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                gradient: AppColors.grad,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.send_rounded, size: 18, color: Colors.white),
            ),
          ),
        ],
      );
    }

    // Recording in progress OR normal text-input state.
    // Listener stays at the same Row position (index 4) across both so the
    // active pointer tracking survives the _isRecording setState rebuild.
    return Row(
      children: [
        // Left button: attach ↔ cancel-recording
        GestureDetector(
          onTap: _isRecording
              ? () => _stopRecording(cancel: true)
              : _pickImage,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: _isRecording
                  ? Colors.red.withValues(alpha: 0.15)
                  : Colors.white.withValues(alpha: 0.06),
              shape: BoxShape.circle,
            ),
            child: Icon(
              _isRecording ? Icons.delete_outline : Icons.attach_file,
              color: _isRecording ? Colors.red : Colors.white,
              size: 20,
            ),
          ),
        ),
        const SizedBox(width: 8),
        // Middle: text field ↔ recording indicator
        Expanded(
          child: _isRecording ? _buildRecordingIndicator() : _buildTextField(),
        ),
        const SizedBox(width: 8),
        // Right button: immediate pointer-down via Listener (no 500 ms delay).
        Listener(
          behavior: HitTestBehavior.opaque,
          onPointerDown: (e) {
            _pointerDown = true;
            _pointerStartX = e.localPosition.dx;
            if (!_isRecording && widget.controller.text.trim().isEmpty) {
              _startRecording();
            }
          },
          onPointerMove: (e) {
            if (_isRecording) {
              final dx = e.localPosition.dx - _pointerStartX;
              final shouldCancel = dx < -60;
              if (shouldCancel != _cancelRecord) {
                setState(() => _cancelRecord = shouldCancel);
              }
            }
          },
          onPointerUp: (e) {
            _pointerDown = false;
            if (_isRecording) {
              _stopRecording(cancel: _cancelRecord);
            } else if (widget.controller.text.trim().isNotEmpty) {
              widget.onSend();
            }
          },
          onPointerCancel: (e) {
            _pointerDown = false;
            if (_isRecording) _stopRecording(cancel: true);
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              gradient: _isRecording ? null : AppColors.grad,
              color: _isRecording ? Colors.red : null,
              shape: BoxShape.circle,
            ),
            child: ValueListenableBuilder<TextEditingValue>(
              valueListenable: widget.controller,
              builder: (_, v, _) => Icon(
                _isRecording
                    ? Icons.mic_rounded
                    : (v.text.trim().isEmpty
                        ? Icons.mic_rounded
                        : Icons.send_rounded),
                size: 18,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildVoicePreview() {
    final secs = _recordedDuration;
    final dur =
        '${secs ~/ 60}:${(secs % 60).toString().padLeft(2, '0')}';
    return Container(
      height: 46,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(23),
        border: Border.all(color: AppColors.brand400.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          const Icon(Icons.mic_rounded, size: 18, color: AppColors.brand300),
          const SizedBox(width: 6),
          // Static waveform visual
          ...List.generate(16, (i) {
            final h = 6.0 + (i * 7 % 14).toDouble();
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 1.5),
              child: Container(
                width: 3,
                height: h,
                decoration: BoxDecoration(
                  color: AppColors.brand300.withValues(alpha: 0.65),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            );
          }),
          const Spacer(),
          Text(
            dur,
            style: AppText.caption.copyWith(
              color: AppColors.brand300,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField() {
    return Container(
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
              controller: widget.controller,
              focusNode: widget.focusNode,
              readOnly: _showEmoji,
              style: AppText.body.copyWith(fontSize: 14),
              cursorColor: AppColors.brand400,
              minLines: 1,
              maxLines: 4,
              onSubmitted: (_) => widget.onSend(),
              decoration: InputDecoration(
                isDense: true,
                border: InputBorder.none,
                hintText: 'Message…',
                hintStyle:
                    AppText.body.copyWith(color: AppColors.n300, fontSize: 14),
              ),
            ),
          ),
          GestureDetector(
            onTap: _toggleEmoji,
            child: Icon(
              _showEmoji
                  ? Icons.keyboard_rounded
                  : Icons.emoji_emotions_outlined,
              size: 26,
              color: _showEmoji ? AppColors.brand400 : AppColors.n300,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecordingIndicator() {
    final secs = _recordSeconds;
    final durStr = '${secs ~/ 60}:${(secs % 60).toString().padLeft(2, '0')}';
    return Container(
      height: 46,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(23),
        border: Border.all(
          color: _cancelRecord
              ? Colors.red.withValues(alpha: 0.8)
              : Colors.red.withValues(alpha: 0.35),
        ),
      ),
      child: Row(
        children: [
          const _PulsingDot(),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _cancelRecord ? 'Release to cancel' : '← slide to cancel',
              style: AppText.caption.copyWith(
                fontSize: 12,
                color: _cancelRecord ? Colors.red : AppColors.n300,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(
            durStr,
            style: AppText.caption.copyWith(
              color: Colors.red,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------

class _PulsingDot extends StatefulWidget {
  const _PulsingDot();

  @override
  State<_PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<_PulsingDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 800));
    _anim = Tween<double>(begin: 0.3, end: 1.0)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
    _ctrl.repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: _anim,
        builder: (_, _) => Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: Colors.red.withValues(alpha: _anim.value),
            shape: BoxShape.circle,
          ),
        ),
      );
}
