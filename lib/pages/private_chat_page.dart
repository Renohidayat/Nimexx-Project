import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import '../service/chat_service.dart';
import '../widgets/chat/chat_tag_sheet.dart';
import 'anime_detail_page.dart';
import 'episode_page.dart';
import 'public_profile_page.dart';

class PrivateChatPage extends StatefulWidget {
  final String peerId;
  final String peerName;
  final String peerAvatar;
  final Map<String, dynamic>? initialTagData;

  const PrivateChatPage({
    Key? key,
    required this.peerId,
    required this.peerName,
    required this.peerAvatar,
    this.initialTagData,
  }) : super(key: key);

  @override
  State<PrivateChatPage> createState() => _PrivateChatPageState();
}

class _PrivateChatPageState extends State<PrivateChatPage> {
  final _chatService = ChatService();
  final _messageCtrl = TextEditingController();
  final _currentUser = FirebaseAuth.instance.currentUser;
  
  Map<String, dynamic>? _currentTagData;
  String? _replyingToMessageId;
  String? _replyingToName;
  String? _replyingToText;
  String? _editingMessageId;

  @override
  void initState() {
    super.initState();
    _currentTagData = widget.initialTagData;
  }

  void _sendMessage() {
    final text = _messageCtrl.text.trim();
    if (text.isEmpty && _currentTagData == null) return;

    if (_editingMessageId != null) {
      _chatService.editPrivateMessage(widget.peerId, _editingMessageId!, text);
      setState(() {
        _editingMessageId = null;
      });
    } else {
      _chatService.sendPrivateMessage(
        widget.peerId, 
        text, 
        replyToMessageId: _replyingToMessageId,
        tagData: _currentTagData,
      );
      // Hapus tag setelah dikirim
      _currentTagData = null;
    }

    _messageCtrl.clear();
    _cancelReply();
  }

  void _setReply(String messageId, String name, String text) {
    setState(() {
      _replyingToMessageId = messageId;
      _replyingToName = name;
      _replyingToText = text;
      _editingMessageId = null; // Batal edit jika pilih reply
    });
  }

  void _cancelReply() {
    setState(() {
      _replyingToMessageId = null;
      _replyingToName = null;
      _replyingToText = null;
    });
  }

  void _cancelEdit() {
    setState(() {
      _editingMessageId = null;
      _messageCtrl.clear();
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
            _currentTagData = tagData;
          });
        },
      ),
    );
  }

  void _showMessageOptions(BuildContext context, String messageId, bool isMe, String currentText) {
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
                  _setReply(messageId, isMe ? 'Anda' : widget.peerName, currentText);
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
                    _chatService.deletePrivateMessage(widget.peerId, messageId);
                  },
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  void _openProfilePhoto(BuildContext context) {
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        barrierDismissible: true,
        barrierColor: Colors.black.withOpacity(0.9),
        pageBuilder: (BuildContext context, _, __) {
          return Scaffold(
            backgroundColor: Colors.transparent,
            appBar: AppBar(
              backgroundColor: Colors.black.withOpacity(0.4),
              elevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
              title: Text(
                widget.peerName,
                style: GoogleFonts.outfit(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w700),
              ),
              actions: [
                if (widget.peerId.isNotEmpty)
                  IconButton(
                    icon: const Icon(Icons.person_rounded, color: Color(0xFFFF5E1E)),
                    tooltip: 'Lihat Profil Lengkap',
                    onPressed: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => PublicProfilePage(userId: widget.peerId)),
                      );
                    },
                  ),
              ],
            ),
            body: Center(
              child: Hero(
                tag: 'peer_avatar_${widget.peerId}',
                child: widget.peerAvatar.isNotEmpty
                    ? InteractiveViewer(
                        panEnabled: true,
                        minScale: 0.8,
                        maxScale: 4.0,
                        child: Container(
                          constraints: BoxConstraints(
                            maxWidth: MediaQuery.of(context).size.width * 0.95,
                            maxHeight: MediaQuery.of(context).size.height * 0.75,
                          ),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.6),
                                blurRadius: 24,
                                spreadRadius: 4,
                              ),
                            ],
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: Image.network(
                            widget.peerAvatar,
                            fit: BoxFit.contain,
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return const Center(
                                child: CircularProgressIndicator(color: Color(0xFFFF5E1E)),
                              );
                            },
                            errorBuilder: (_, __, ___) => const Center(
                              child: Icon(
                                Icons.broken_image_rounded,
                                size: 80,
                                color: Colors.white54,
                              ),
                            ),
                          ),
                        ),
                      )
                    : Container(
                        width: 180,
                        height: 180,
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E1E2E),
                          shape: BoxShape.circle,
                          border: Border.all(color: const Color(0xFFFF5E1E), width: 3),
                        ),
                        child: Center(
                          child: Text(
                            widget.peerName.isNotEmpty ? widget.peerName[0].toUpperCase() : '?',
                            style: const TextStyle(fontSize: 72, color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_currentUser == null) {
      return const Scaffold(body: Center(child: Text("Harus login")));
    }

    return Scaffold(
      backgroundColor: const Color(0xFF101018),
      appBar: AppBar(
        backgroundColor: const Color(0xFF161622),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            GestureDetector(
              onTap: () => _openProfilePhoto(context),
              child: Hero(
                tag: 'peer_avatar_${widget.peerId}',
                child: CircleAvatar(
                  radius: 18,
                  backgroundImage: widget.peerAvatar.isNotEmpty ? NetworkImage(widget.peerAvatar) : null,
                  backgroundColor: Colors.grey[800],
                  child: widget.peerAvatar.isEmpty
                      ? Text(widget.peerName.isNotEmpty ? widget.peerName[0].toUpperCase() : '?', style: const TextStyle(color: Colors.white, fontSize: 14))
                      : null,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: GestureDetector(
                onTap: () {
                  if (widget.peerId.isNotEmpty) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => PublicProfilePage(userId: widget.peerId)),
                    );
                  }
                },
                child: Text(
                  widget.peerName, 
                  style: GoogleFonts.outfit(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ],
        ),
        actions: [
          if (widget.peerId.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.info_outline_rounded, color: Colors.white70),
              tooltip: 'Info Profil',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => PublicProfilePage(userId: widget.peerId)),
                );
              },
            ),
        ],
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: Opacity(
              opacity: 0.2,
              child: Image.asset(
                'assets/images/wibu.png',
                fit: BoxFit.cover,
                errorBuilder: (_,__,___) => const SizedBox(),
              ),
            ),
          ),
          Column(
            children: [
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: _chatService.getPrivateChatStream(widget.peerId),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator(color: Color(0xFFE25822)));
                    }

                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return Center(
                        child: Text('Belum ada pesan, sapa ${widget.peerName}!', style: TextStyle(color: Colors.grey[500])),
                      );
                    }

                    final messages = snapshot.data!.docs;
                    return ListView.builder(
                      reverse: true,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      itemCount: messages.length,
                      itemBuilder: (context, index) {
                        final doc = messages[index];
                        final data = doc.data() as Map<String, dynamic>;
                        
                        return _PrivateChatBubble(
                          messageId: doc.id,
                          senderId: data['senderId'] ?? '',
                          text: data['text'] ?? '',
                          timestamp: data['timestamp'] as Timestamp?,
                          tagData: data['tagData'],
                          isMe: data['senderId'] == _currentUser!.uid,
                          isEdited: data['isEdited'] ?? false,
                          replyToMessageId: data['replyToMessageId'],
                          allMessages: messages,
                          onReply: () => _setReply(
                            doc.id, 
                            data['senderId'] == _currentUser!.uid ? 'Anda' : widget.peerName, 
                            data['text'] ?? ''
                          ),
                          onLongPress: () => _showMessageOptions(
                            context, doc.id, data['senderId'] == _currentUser!.uid, data['text'] ?? ''
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
              _buildInputContainer(),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInputContainer() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF161622),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.5),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_replyingToMessageId != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  border: const Border(left: BorderSide(color: Color(0xFFFF5722), width: 4)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.reply_rounded, color: Color(0xFFFF5722), size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Membalas $_replyingToName', style: const TextStyle(color: Color(0xFFFF5722), fontWeight: FontWeight.bold, fontSize: 12)),
                          Text(_replyingToText ?? '', style: TextStyle(color: Colors.grey[400], fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, color: Colors.grey, size: 18),
                      onPressed: _cancelReply,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              ),

            if (_editingMessageId != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.blueAccent.withOpacity(0.05),
                  border: const Border(left: BorderSide(color: Colors.blueAccent, width: 4)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.edit_rounded, color: Colors.blueAccent, size: 20),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text('Mengedit Pesan', style: TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold, fontSize: 12)),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, color: Colors.grey, size: 18),
                      onPressed: _cancelEdit,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              ),

            if (_currentTagData != null)
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 8, left: 16, right: 16, top: 8),
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
                        _currentTagData!['seriesThumb'] ?? '',
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
                          if (_currentTagData!['episodeTitle'] != null)
                            Text(
                              _currentTagData!['episodeTitle'].toUpperCase(),
                              style: const TextStyle(
                                color: Color(0xFF6C5CE7),
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          Text(
                            _currentTagData!['seriesTitle'] ?? '',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            'Tag dilampirkan',
                            style: TextStyle(color: Colors.grey[500], fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.close_rounded, color: Colors.grey[500], size: 24),
                      onPressed: () => setState(() => _currentTagData = null),
                    ),
                  ],
                ),
              ),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: Colors.white12),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _messageCtrl,
                              style: const TextStyle(color: Colors.white, fontSize: 15),
                              textInputAction: TextInputAction.send,
                              maxLines: 4,
                              minLines: 1,
                              decoration: const InputDecoration(
                                hintText: 'Ketik pesan...',
                                hintStyle: TextStyle(color: Colors.white30),
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                  GestureDetector(
                    onTap: _sendMessage,
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xFFFF5722), Color(0xFFFF9800)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PrivateChatBubble extends StatelessWidget {
  final String messageId;
  final String senderId;
  final String text;
  final Timestamp? timestamp;
  final Map<String, dynamic>? tagData;
  final bool isMe;
  final bool isEdited;
  final String? replyToMessageId;
  final List<QueryDocumentSnapshot> allMessages;
  final VoidCallback onReply;
  final VoidCallback onLongPress;

  const _PrivateChatBubble({
    required this.messageId,
    required this.senderId,
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

    final borderColor = isMe ? const Color(0xFFFF5722) : const Color(0xFF4FC3F7);

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
                                  color: repliedData['senderId'] == senderId ? borderColor : (isMe ? const Color(0xFF4FC3F7) : const Color(0xFFFF5722)),
                                  width: 3,
                                ),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  repliedData['senderId'] == FirebaseAuth.instance.currentUser?.uid ? 'Anda' : 'Teman Anda',
                                  style: TextStyle(
                                    color: repliedData['senderId'] == senderId ? borderColor : (isMe ? const Color(0xFF4FC3F7) : const Color(0xFFFF5722)),
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
          ],
        ), // Row
      ), // Dismissible
    );
  }

  Widget _buildAnimeTagCard(BuildContext context, Map<String, dynamic> data) {
    return GestureDetector(
      onTap: () {
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
          color: const Color(0xFF232332),
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
                      color: Color(0xFF6C5CE7),
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
}
