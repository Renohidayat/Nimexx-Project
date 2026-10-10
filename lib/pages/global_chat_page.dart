import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../service/chat_service.dart';
import '../service/anime_service.dart';
import '../model/search_anime_item.dart';
import 'anime_detail_page.dart';

class GlobalChatPage extends StatefulWidget {
  const GlobalChatPage({super.key});

  @override
  State<GlobalChatPage> createState() => _GlobalChatPageState();
}

class _GlobalChatPageState extends State<GlobalChatPage> {
  final _chatService = ChatService();
  final _messageCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  final _currentUser = FirebaseAuth.instance.currentUser;

  String? _replyToId;
  String? _replyToName;
  String? _replyToText;

  @override
  void dispose() {
    _messageCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _sendMessage() {
    final text = _messageCtrl.text.trim();
    if (text.isEmpty) return;

    _chatService.sendGlobalMessage(text, replyToMessageId: _replyToId);
    _messageCtrl.clear();
    _cancelReply();
  }

  void _setReply(String messageId, String senderName, String text) {
    setState(() {
      _replyToId = messageId;
      _replyToName = senderName;
      _replyToText = text;
    });
  }

  void _cancelReply() {
    setState(() {
      _replyToId = null;
      _replyToName = null;
      _replyToText = null;
    });
  }

  void _showAnimeTagPicker() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AnimeTagSheet(
        onTagSelected: (title, endpoint, thumb, episodeLabel) {
          final tagText = episodeLabel != null
              ? '🎬 $title [$episodeLabel]'
              : '🎬 $title';
          // Append to current message or send directly
          _messageCtrl.text = '${_messageCtrl.text}$tagText ';
          _messageCtrl.selection = TextSelection.fromPosition(
            TextPosition(offset: _messageCtrl.text.length),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_currentUser == null) {
      return Scaffold(
        backgroundColor: Colors.black,
        appBar: _buildAppBar(),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.lock_outline_rounded, size: 64, color: Colors.grey[600]),
              const SizedBox(height: 16),
              Text(
                'Login dulu buat ikutan ngobrol',
                style: TextStyle(color: Colors.grey[400], fontSize: 16),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: _buildAppBar(),
      body: Column(
        children: [
          Expanded(child: _buildMessageList()),
          if (_replyToId != null) _buildReplyPreview(),
          _buildInputBar(),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: const Color(0xFF0D0D0D),
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
        onPressed: () => Navigator.pop(context),
      ),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFFF5722).withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.forum_rounded, color: Color(0xFFFF5722), size: 20),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Obrolan Global',
                style: GoogleFonts.outfit(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              StreamBuilder<QuerySnapshot>(
                stream: _chatService.getGlobalChatStream(),
                builder: (context, snapshot) {
                  final count = snapshot.data?.docs.length ?? 0;
                  return Text(
                    '$count pesan terbaru',
                    style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMessageList() {
    return StreamBuilder<QuerySnapshot>(
      stream: _chatService.getGlobalChatStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: Color(0xFFFF5722)),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.chat_bubble_outline_rounded, size: 64, color: Colors.grey[700]),
                const SizedBox(height: 16),
                Text(
                  'Belum ada pesan',
                  style: TextStyle(color: Colors.grey[500], fontSize: 16),
                ),
                const SizedBox(height: 4),
                Text(
                  'Jadilah yang pertama menyapa!',
                  style: TextStyle(color: Colors.grey[600], fontSize: 13),
                ),
              ],
            ),
          );
        }

        final messages = snapshot.data!.docs;

        return ListView.builder(
          controller: _scrollCtrl,
          reverse: true,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          itemCount: messages.length,
          itemBuilder: (context, index) {
            final msg = messages[index];
            final data = msg.data() as Map<String, dynamic>;
            final isMe = data['senderId'] == _currentUser?.uid;
            final replyId = data['replyToMessageId'];

            return _ChatBubble(
              messageId: msg.id,
              senderName: data['senderName'] ?? 'Anonim',
              senderPhotoUrl: data['senderPhotoUrl'] ?? '',
              text: data['text'] ?? '',
              timestamp: data['timestamp'] as Timestamp?,
              isMe: isMe,
              replyToMessageId: replyId,
              allMessages: messages,
              onReply: () => _setReply(
                msg.id,
                data['senderName'] ?? 'Anonim',
                data['text'] ?? '',
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildReplyPreview() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        border: Border(top: BorderSide(color: Colors.grey[850]!)),
      ),
      child: Row(
        children: [
          Container(
            width: 3,
            height: 36,
            decoration: BoxDecoration(
              color: const Color(0xFFFF5722),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _replyToName ?? '',
                  style: const TextStyle(
                    color: Color(0xFFFF5722),
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _replyToText ?? '',
                  style: TextStyle(color: Colors.grey[400], fontSize: 12),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(Icons.close_rounded, color: Colors.grey[500], size: 18),
            onPressed: _cancelReply,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  Widget _buildInputBar() {
    return Container(
      padding: EdgeInsets.fromLTRB(8, 8, 8, MediaQuery.of(context).padding.bottom + 8),
      decoration: BoxDecoration(
        color: const Color(0xFF0D0D0D),
        border: Border(top: BorderSide(color: Colors.grey[900]!)),
      ),
      child: Row(
        children: [
          // Tag anime button
          IconButton(
            icon: const Icon(Icons.movie_creation_outlined, color: Color(0xFFFF5722), size: 24),
            onPressed: _showAnimeTagPicker,
            tooltip: 'Tag Anime',
          ),
          Expanded(
            child: Container(
              constraints: const BoxConstraints(maxHeight: 120),
              decoration: BoxDecoration(
                color: const Color(0xFF1A1A1A),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.grey[850]!),
              ),
              child: TextField(
                controller: _messageCtrl,
                style: const TextStyle(color: Colors.white, fontSize: 14),
                maxLines: null,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  hintText: 'Tulis pesan...',
                  hintStyle: TextStyle(color: Colors.grey[600]),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                ),
                onSubmitted: (_) => _sendMessage(),
              ),
            ),
          ),
          const SizedBox(width: 6),
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFFFF5722),
              borderRadius: BorderRadius.circular(20),
            ),
            child: IconButton(
              icon: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
              onPressed: _sendMessage,
            ),
          ),
        ],
      ),
    );
  }
}

// --- Chat Bubble Widget ---

class _ChatBubble extends StatelessWidget {
  final String messageId;
  final String senderName;
  final String senderPhotoUrl;
  final String text;
  final Timestamp? timestamp;
  final bool isMe;
  final String? replyToMessageId;
  final List<QueryDocumentSnapshot> allMessages;
  final VoidCallback onReply;

  const _ChatBubble({
    required this.messageId,
    required this.senderName,
    required this.senderPhotoUrl,
    required this.text,
    required this.timestamp,
    required this.isMe,
    this.replyToMessageId,
    required this.allMessages,
    required this.onReply,
  });

  @override
  Widget build(BuildContext context) {
    final time = timestamp != null
        ? DateFormat('HH:mm').format(timestamp!.toDate())
        : '';

    // Resolve replied message
    Map<String, dynamic>? repliedData;
    if (replyToMessageId != null) {
      try {
        final repliedDoc = allMessages.firstWhere((d) => d.id == replyToMessageId);
        repliedData = repliedDoc.data() as Map<String, dynamic>;
      } catch (_) {}
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isMe) ...[
            CircleAvatar(
              radius: 16,
              backgroundImage: senderPhotoUrl.isNotEmpty
                  ? NetworkImage(senderPhotoUrl)
                  : null,
              backgroundColor: Colors.grey[800],
              child: senderPhotoUrl.isEmpty
                  ? Text(
                      senderName.isNotEmpty ? senderName[0].toUpperCase() : '?',
                      style: const TextStyle(color: Colors.white, fontSize: 13),
                    )
                  : null,
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: GestureDetector(
              onLongPress: onReply,
              child: Container(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 6),
                decoration: BoxDecoration(
                  color: isMe ? const Color(0xFF2B1810) : const Color(0xFF1A1A1A),
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(16),
                    topRight: const Radius.circular(16),
                    bottomLeft: Radius.circular(isMe ? 16 : 4),
                    bottomRight: Radius.circular(isMe ? 4 : 16),
                  ),
                  border: Border.all(
                    color: isMe
                        ? const Color(0xFFFF5722).withOpacity(0.2)
                        : Colors.grey[850]!,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (!isMe)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Text(
                          senderName,
                          style: TextStyle(
                            color: _nameColor(senderName),
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    // Replied message preview
                    if (repliedData != null) ...[
                      Container(
                        padding: const EdgeInsets.fromLTRB(8, 6, 8, 6),
                        margin: const EdgeInsets.only(bottom: 6),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(8),
                          border: Border(
                            left: BorderSide(
                              color: const Color(0xFFFF5722).withOpacity(0.6),
                              width: 2,
                            ),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              repliedData!['senderName'] ?? 'Anonim',
                              style: TextStyle(
                                color: const Color(0xFFFF5722).withOpacity(0.8),
                                fontWeight: FontWeight.w600,
                                fontSize: 11,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              repliedData!['text'] ?? '',
                              style: TextStyle(color: Colors.grey[500], fontSize: 11),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                    // Check if text contains anime tag
                    _buildMessageText(text, context),
                    const SizedBox(height: 4),
                    Align(
                      alignment: Alignment.bottomRight,
                      child: Text(
                        time,
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (isMe) const SizedBox(width: 24),
        ],
      ),
    );
  }

  Widget _buildMessageText(String text, BuildContext context) {
    // Detect anime tags (format: 🎬 Title [Episode X])
    final tagPattern = RegExp(r'🎬\s+(.+?)(?:\s+\[(.+?)\])?\s*');
    final match = tagPattern.firstMatch(text);

    if (match != null && text.startsWith('🎬')) {
      final animeTitle = match.group(1) ?? '';
      final episodeLabel = match.group(2);
      final remainingText = text.substring(match.end).trim();

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Anime tag card
          GestureDetector(
            onTap: () {
              // Navigate to search with that title
              // For now, just show a snackbar
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Mencari: $animeTitle')),
              );
            },
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFFF5722).withOpacity(0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFFF5722).withOpacity(0.2)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.movie_rounded, color: Color(0xFFFF5722), size: 18),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          animeTitle,
                          style: const TextStyle(
                            color: Color(0xFFFF5722),
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (episodeLabel != null)
                          Text(
                            episodeLabel,
                            style: TextStyle(color: Colors.grey[400], fontSize: 11),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 6),
                  Icon(Icons.chevron_right_rounded, color: Colors.grey[500], size: 18),
                ],
              ),
            ),
          ),
          if (remainingText.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              remainingText,
              style: const TextStyle(color: Colors.white, fontSize: 14),
            ),
          ],
        ],
      );
    }

    return Text(
      text,
      style: const TextStyle(color: Colors.white, fontSize: 14),
    );
  }

  // Generate consistent color from name for visual distinction
  Color _nameColor(String name) {
    final colors = [
      const Color(0xFF4FC3F7),
      const Color(0xFF81C784),
      const Color(0xFFFFB74D),
      const Color(0xFFE57373),
      const Color(0xFF9575CD),
      const Color(0xFF4DD0E1),
      const Color(0xFFF06292),
      const Color(0xFFAED581),
    ];
    final hash = name.codeUnits.fold(0, (prev, c) => prev + c);
    return colors[hash % colors.length];
  }
}

// --- Anime Tag Picker Bottom Sheet ---

class _AnimeTagSheet extends StatefulWidget {
  final void Function(String title, String endpoint, String thumb, String? episodeLabel) onTagSelected;

  const _AnimeTagSheet({required this.onTagSelected});

  @override
  State<_AnimeTagSheet> createState() => _AnimeTagSheetState();
}

class _AnimeTagSheetState extends State<_AnimeTagSheet> {
  final _searchCtrl = TextEditingController();
  Future<List<SearchAnimeItem>>? _searchFuture;
  bool _isSearching = false;

  void _doSearch(String query) {
    if (query.length < 3) return;
    setState(() {
      _isSearching = true;
      _searchFuture = AnimeService().searchAnime(query);
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      maxChildSize: 0.9,
      minChildSize: 0.4,
      builder: (context, scrollCtrl) {
        return Container(
          decoration: const BoxDecoration(
            color: Color(0xFF121212),
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Handle bar
              Center(
                child: Container(
                  margin: const EdgeInsets.only(top: 12),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[700],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Tag Anime ke Pesan',
                      style: GoogleFonts.outfit(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Cari judul anime lalu kirim ke chat.',
                      style: TextStyle(color: Colors.grey[500], fontSize: 13),
                    ),
                    const SizedBox(height: 16),
                    // Search field
                    Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF1A1A1A),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.grey[850]!),
                      ),
                      child: TextField(
                        controller: _searchCtrl,
                        style: const TextStyle(color: Colors.white, fontSize: 14),
                        decoration: InputDecoration(
                          hintText: 'Ketik judul anime...',
                          hintStyle: TextStyle(color: Colors.grey[600]),
                          prefixIcon: Icon(Icons.search_rounded, color: Colors.grey[500]),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        onChanged: (q) {
                          if (q.length >= 3) _doSearch(q);
                        },
                        onSubmitted: _doSearch,
                      ),
                    ),
                  ],
                ),
              ),
              // Results
              Expanded(
                child: _searchFuture == null
                    ? Center(
                        child: Text(
                          'Ketik minimal 3 huruf',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      )
                    : FutureBuilder<List<SearchAnimeItem>>(
                        future: _searchFuture,
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return const Center(
                              child: CircularProgressIndicator(color: Color(0xFFFF5722)),
                            );
                          }

                          if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
                            return Center(
                              child: Text(
                                'Tidak ditemukan',
                                style: TextStyle(color: Colors.grey[500]),
                              ),
                            );
                          }

                          final results = snapshot.data!;
                          return ListView.builder(
                            controller: scrollCtrl,
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: results.length,
                            itemBuilder: (context, index) {
                              final anime = results[index];
                              return _buildAnimeTagTile(anime);
                            },
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAnimeTagTile(SearchAnimeItem anime) {
    return InkWell(
      onTap: () {
        widget.onTagSelected(anime.title, anime.endpoint, anime.thumb, null);
        Navigator.pop(context);
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
        margin: const EdgeInsets.only(bottom: 6),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[850]!),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                anime.thumb,
                width: 44,
                height: 60,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  width: 44,
                  height: 60,
                  color: Colors.grey[800],
                  child: Icon(Icons.movie_rounded, color: Colors.grey[600]),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    anime.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                      fontSize: 13,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  if (anime.genres.isNotEmpty)
                    Text(
                      anime.genres.take(3).join(', '),
                      style: TextStyle(color: Colors.grey[500], fontSize: 11),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
            Icon(Icons.add_circle_outline_rounded, color: Colors.grey[500], size: 22),
          ],
        ),
      ),
    );
  }
}
