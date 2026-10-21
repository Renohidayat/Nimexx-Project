import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../service/chat_service.dart';
import 'anime_detail_page.dart';
import 'episode_page.dart';
import 'user_search_page.dart';
import 'public_profile_page.dart';
import '../widgets/chat/chat_tag_sheet.dart';

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
  
  Map<String, dynamic>? _selectedTag;
  String? _editingMessageId;

  @override
  void dispose() {
    _messageCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _sendMessage() {
    final text = _messageCtrl.text.trim();
    if (text.isEmpty && _selectedTag == null) return;

    if (_editingMessageId != null) {
      _chatService.editGlobalMessage(_editingMessageId!, text);
      setState(() {
        _editingMessageId = null;
      });
    } else {
      _chatService.sendGlobalMessage(
        text, 
        replyToMessageId: _replyToId,
        tagData: _selectedTag,
      );
    }
    
    _messageCtrl.clear();
    _cancelReply();
    setState(() {
      _selectedTag = null;
    });
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
      builder: (_) => ChatTagSheet(
        onTagSelected: (tagData) {
          setState(() {
            _selectedTag = tagData;
          });
        },
      ),
    );
  }

  void _showMessageOptions(String messageId, String currentText, bool isMe) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF161622),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.reply_rounded, color: Colors.white),
                title: const Text('Balas Pesan', style: TextStyle(color: Colors.white)),
                onTap: () {
                  Navigator.pop(context);
                  _setReply(messageId, 'User', currentText);
                },
              ),
              if (isMe) ...[
                ListTile(
                  leading: const Icon(Icons.edit_rounded, color: Colors.blueAccent),
                  title: const Text('Edit Pesan', style: TextStyle(color: Colors.blueAccent)),
                  onTap: () {
                    Navigator.pop(context);
                    setState(() {
                      _editingMessageId = messageId;
                      _messageCtrl.text = currentText;
                    });
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.delete_rounded, color: Colors.redAccent),
                  title: const Text('Hapus Pesan', style: TextStyle(color: Colors.redAccent)),
                  onTap: () {
                    Navigator.pop(context);
                    _chatService.deleteGlobalMessage(messageId);
                  },
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_currentUser == null) {
      return Scaffold(
        backgroundColor: const Color(0xFF0A0A10),
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
      backgroundColor: const Color(0xFF101018), // Deep dark space background
      appBar: _buildAppBar(),
      body: Stack(
        children: [
          // Subtle background decoration
          Positioned.fill(
            child: Opacity(
              opacity: 0.2,
              child: Image.asset(
                'assets/images/wibu.png', // Fallback pattern if available, or just colors
                fit: BoxFit.cover,
                errorBuilder: (_,__,___) => const SizedBox(),
              ),
            ),
          ),
          Column(
            children: [
              Expanded(child: _buildMessageList()),
              _buildInputContainer(),
            ],
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: const Color(0xFF101018),
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
        onPressed: () => Navigator.pop(context),
      ),
      title: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Obrolan Publik',
                style: GoogleFonts.outfit(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              Row(
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      color: Colors.green,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Live',
                    style: TextStyle(color: Colors.grey[400], fontSize: 12),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.person_search_rounded, color: Colors.white),
          tooltip: 'Cari Pengguna',
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const UserSearchPage()),
            );
          },
        ),
        const SizedBox(width: 8),
      ],
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
            child: Text(
              'Belum ada pesan',
              style: TextStyle(color: Colors.grey[500], fontSize: 16),
            ),
          );
        }

        final messages = snapshot.data!.docs;

        return ListView.builder(
          controller: _scrollCtrl,
          reverse: true,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          itemCount: messages.length,
          itemBuilder: (context, index) {
            final msg = messages[index];
            final data = msg.data() as Map<String, dynamic>;
            final isMe = data['senderId'] == _currentUser?.uid;
            
            return _ChatBubble(
              messageId: msg.id,
              senderId: data['senderId'] ?? '',
              senderName: data['senderName'] ?? 'Anonim',
              senderPhotoUrl: data['senderPhotoUrl'] ?? '',
              text: data['text'] ?? '',
              timestamp: data['timestamp'] as Timestamp?,
              tagData: data['tagData'],
              isMe: isMe,
              isEdited: data['isEdited'] ?? false,
              replyToMessageId: data['replyToMessageId'],
              allMessages: messages,
              onReply: () => _setReply(
                msg.id,
                data['senderName'] ?? 'Anonim',
                data['text'] ?? '',
              ),
              onLongPress: () => _showMessageOptions(
                msg.id,
                data['text'] ?? '',
                isMe,
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildInputContainer() {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF101018), // Match background
      ),
      padding: EdgeInsets.fromLTRB(16, 8, 16, MediaQuery.of(context).padding.bottom + 16),
      child: Column(
        children: [
          // PREVIEW REPLY
          if (_replyToId != null)
            Container(
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF1C1C28),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey[850]!),
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
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
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
                    icon: Icon(Icons.close_rounded, color: Colors.grey[500], size: 20),
                    onPressed: _cancelReply,
                  ),
                ],
              ),
            ),

          // PREVIEW TAG
          if (_selectedTag != null)
            Container(
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF1C1C28),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFF6C5CE7).withOpacity(0.5)),
              ),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      _selectedTag!['seriesThumb'] ?? '',
                      width: 44,
                      height: 56,
                      fit: BoxFit.cover,
                      errorBuilder: (_,__,___) => Container(
                        width: 44,
                        height: 56,
                        color: Colors.grey[800],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (_selectedTag!['episodeTitle'] != null)
                          Text(
                            _selectedTag!['episodeTitle'].toUpperCase(),
                            style: const TextStyle(
                              color: Color(0xFF6C5CE7),
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        Text(
                          _selectedTag!['seriesTitle'] ?? '',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          'Ketuk untuk pratinjau',
                          style: TextStyle(color: Colors.grey[500], fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close_rounded, color: Colors.grey[500], size: 24),
                    onPressed: () => setState(() => _selectedTag = null),
                  ),
                ],
              ),
            ),

          // INPUT BAR (TextField - Movie - Send)
          Row(
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF1C1C28),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _messageCtrl,
                          style: const TextStyle(color: Colors.white, fontSize: 15),
                          maxLines: null,
                          textCapitalization: TextCapitalization.sentences,
                          decoration: InputDecoration(
                            hintText: 'Ketik pesan...',
                            hintStyle: TextStyle(color: Colors.grey[600]),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          ),
                          onSubmitted: (_) => _sendMessage(),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.movie_creation_outlined, color: Colors.white54),
                        onPressed: _showAnimeTagPicker,
                      ),
                      const SizedBox(width: 4),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Container(
                decoration: const BoxDecoration(
                  color: Colors.white, // White send button like reference if preferred, or orange
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: const Icon(Icons.send_rounded, color: Colors.black, size: 20),
                  onPressed: _sendMessage,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// --- Chat Bubble Widget ---

class _ChatBubble extends StatelessWidget {
  final String messageId;
  final String senderId;
  final String senderName;
  final String senderPhotoUrl;
  final String text;
  final Timestamp? timestamp;
  final Map<String, dynamic>? tagData;
  final bool isMe;
  final bool isEdited;
  final String? replyToMessageId;
  final List<QueryDocumentSnapshot> allMessages;
  final VoidCallback onReply;
  final VoidCallback onLongPress;

  const _ChatBubble({
    required this.messageId,
    required this.senderId,
    required this.senderName,
    required this.senderPhotoUrl,
    required this.text,
    required this.timestamp,
    this.tagData,
    required this.isMe,
    this.isEdited = false,
    this.replyToMessageId,
    required this.allMessages,
    required this.onReply,
    required this.onLongPress,
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

    final avatar = CircleAvatar(
      radius: 18,
      backgroundImage: senderPhotoUrl.isNotEmpty ? NetworkImage(senderPhotoUrl) : null,
      backgroundColor: Colors.grey[800],
      child: senderPhotoUrl.isEmpty
          ? Text(
              senderName.isNotEmpty ? senderName[0].toUpperCase() : '?',
              style: const TextStyle(color: Colors.white, fontSize: 14),
            )
          : null,
    );

    final clickableAvatar = GestureDetector(
      onTap: () {
        if (senderId.isNotEmpty) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => PublicProfilePage(userId: senderId)),
          );
        }
      },
      child: avatar,
    );

    // Dynamic border color based on name
    final borderColor = isMe ? const Color(0xFFFF5722) : _nameColor(senderName);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Dismissible(
        key: Key(messageId),
        direction: DismissDirection.startToEnd,
        confirmDismiss: (direction) async {
          onReply();
          return false; // Never actually dismiss
        },
        background: Container(
          alignment: Alignment.centerLeft,
          padding: const EdgeInsets.only(left: 16),
          child: const Icon(Icons.reply_rounded, color: Colors.white54),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
          children: [
            if (!isMe) ...[
              clickableAvatar,
              const SizedBox(width: 8),
            ],
            Flexible(
              child: GestureDetector(
                onLongPress: onLongPress,
                child: Container(
                  padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
                decoration: BoxDecoration(
                  color: const Color(0xFF161622),
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(20),
                    topRight: const Radius.circular(20),
                    bottomLeft: Radius.circular(isMe ? 20 : 4),
                    bottomRight: Radius.circular(isMe ? 4 : 20),
                  ),
                  border: Border.all(
                    color: borderColor.withOpacity(0.3), // Soft border glow emulation
                    width: 1.5,
                  ),
                ),
                child: IntrinsicWidth(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              senderName,
                              style: TextStyle(
                                color: borderColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    
                    // Replied preview
                    if (repliedData != null) ...[
                      Container(
                        padding: const EdgeInsets.all(8),
                        margin: const EdgeInsets.only(bottom: 8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.04),
                          borderRadius: BorderRadius.circular(8),
                          border: Border(
                            left: BorderSide(
                              color: _nameColor(repliedData['senderName'] ?? ''),
                              width: 3,
                            ),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              repliedData['senderName'] ?? 'Anonim',
                              style: TextStyle(
                                color: _nameColor(repliedData['senderName'] ?? ''),
                                fontWeight: FontWeight.w600,
                                fontSize: 11,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              repliedData['text'] ?? '',
                              style: TextStyle(color: Colors.grey[400], fontSize: 12),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],

                    // Tag Data Rendering
                    if (tagData != null)
                      _buildAnimeTagCard(context, tagData!),

                    // Message Text
                    if (text.isNotEmpty)
                      Padding(
                        padding: EdgeInsets.only(top: tagData != null ? 8.0 : 0),
                        child: Text(
                          text,
                          style: const TextStyle(color: Colors.white, fontSize: 14.5, height: 1.4),
                        ),
                      ),

                    const SizedBox(height: 4),
                    Align(
                      alignment: Alignment.bottomRight,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (isEdited)
                            Padding(
                              padding: const EdgeInsets.only(right: 4),
                              child: Text(
                                '(diedit)',
                                style: TextStyle(color: Colors.grey[500], fontSize: 9, fontStyle: FontStyle.italic),
                              ),
                            ),
                          Text(
                            time,
                            style: TextStyle(color: Colors.grey[600], fontSize: 10),
                          ),
                        ],
                      ),
                    ),
                  ],
                ), // Column
              ), // IntrinsicWidth
            ), // Container
          ), // GestureDetector
        ), // Flexible
        if (isMe) ...[
          const SizedBox(width: 8),
          clickableAvatar,
        ],
        ],
      ), // Row
      ), // Dismissible
    );
  }

  Widget _buildAnimeTagCard(BuildContext context, Map<String, dynamic> data) {
    return GestureDetector(
      onTap: () {
        // Navigate based on data
        if (data['episodeEndpoint'] != null) {
           Navigator.push(context, MaterialPageRoute(
             builder: (_) => EpisodePage(
               endpoint: data['episodeEndpoint'],
               episodeTitle: data['episodeTitle'] ?? '',
               animeTitle: data['seriesTitle'] ?? '',
               thumbUrl: data['seriesThumb'] ?? '',
               animeEndpoint: data['seriesEndpoint'],
             )
           ));
        } else if (data['seriesEndpoint'] != null) {
           Navigator.push(context, MaterialPageRoute(
             builder: (_) => AnimeDetailPage(endpoint: data['seriesEndpoint'])
           ));
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 4),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFF232332), // Dark card inside bubble
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                data['seriesThumb'] ?? '',
                width: 50,
                height: 64,
                fit: BoxFit.cover,
                errorBuilder: (_,__,___) => Container(
                  width: 50,
                  height: 64,
                  color: Colors.grey[800],
                ),
              ),
            ),
            const SizedBox(width: 12),
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    data['episodeTitle'] != null 
                        ? data['episodeTitle'].toString().toUpperCase() 
                        : 'ANIME SERIES',
                    style: const TextStyle(
                      color: Color(0xFF6C5CE7), // Purple accent for tags
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    data['seriesTitle'] ?? '',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        'Ketuk untuk menonton',
                        style: TextStyle(color: Colors.grey[500], fontSize: 11),
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.play_circle_fill_rounded, color: Colors.white54, size: 14),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _nameColor(String name) {
    if (name.isEmpty) return const Color(0xFF4FC3F7);
    final colors = [
      const Color(0xFF4FC3F7),
      const Color(0xFF81C784),
      const Color(0xFFFFB74D),
      const Color(0xFFE57373),
      const Color(0xFF9575CD),
      const Color(0xFFF06292),
    ];
    final hash = name.codeUnits.fold(0, (prev, c) => prev + c);
    return colors[hash % colors.length];
  }
}
