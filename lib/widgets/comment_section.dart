import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../service/comment_service.dart';
import 'rank_badge_widget.dart';
import '../pages/public_profile_page.dart';
import '../pages/profile_page.dart';

class CommentSection extends StatefulWidget {
  final String episodeId;
  final CommentService commentService;
  final void Function(int)? onCommentCountChanged;
  final String? highlightCommentId;
  final String episodeTitle;
  final String animeTitle;
  final String thumbUrl;

  const CommentSection({
    super.key,
    required this.episodeId,
    required this.commentService,
    required this.episodeTitle,
    required this.animeTitle,
    required this.thumbUrl,
    this.highlightCommentId,
    this.onCommentCountChanged,
    this.isDescending = true,
  });

  final bool isDescending;

  @override
  State<CommentSection> createState() => _CommentSectionState();
}

class _CommentSectionState extends State<CommentSection>
    with TickerProviderStateMixin {
  final _commentController = TextEditingController();
  final _editController = TextEditingController();
  final _scrollController = ScrollController();
  final Map<String, GlobalKey> _commentKeys = {};

  late AnimationController _slideController;
  late AnimationController _fadeController;

  String? replyingToId;
  String? replyingToUsername;
  String? editingId;
  Map<String, bool> expandedReplies = {};

  late Stream<QuerySnapshot<Map<String, dynamic>>> _commentsStream;

  @override
  void initState() {
    super.initState();

    _commentsStream = widget.commentService.getComments(
      widget.episodeId,
      descending: widget.isDescending,
    );

    _slideController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _fadeController.forward();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToHighlightedComment();
    });
  }

  @override
  void didUpdateWidget(CommentSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isDescending != widget.isDescending ||
        oldWidget.episodeId != widget.episodeId) {
      setState(() {
        _commentsStream = widget.commentService.getComments(
          widget.episodeId,
          descending: widget.isDescending,
        );
      });
    }
  }

  void _scrollToHighlightedComment() {
    final key = _commentKeys[widget.highlightCommentId];
    if (key?.currentContext != null) {
      Scrollable.ensureVisible(
        key!.currentContext!,
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  void dispose() {
    _commentController.dispose();
    _editController.dispose();
    _scrollController.dispose();
    _slideController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;
    final screenWidth = MediaQuery.of(context).size.width;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildReplyInfo(screenWidth),
        _buildInputField(currentUser, screenWidth),
        SizedBox(height: screenWidth < 360 ? 12 : 20),
        _buildCommentsStream(currentUser, screenWidth),
      ],
    );
  }

  Widget _buildReplyInfo(double screenWidth) {
    if (replyingToId == null || replyingToUsername == null) {
      return const SizedBox.shrink();
    }

    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(-1, 0),
        end: Offset.zero,
      ).animate(
        CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic),
      ),
      child: Container(
        margin: EdgeInsets.symmetric(
          horizontal: screenWidth < 360 ? 12 : 16,
          vertical: screenWidth < 360 ? 6 : 8,
        ),
        padding: EdgeInsets.all(screenWidth < 360 ? 10 : 12),
        decoration: BoxDecoration(
          color: const Color(0xFFFF6B35).withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: const Color(0xFFFF6B35).withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.reply_rounded,
              color: const Color(0xFFFF6B35),
              size: screenWidth < 360 ? 14 : 16,
            ),
            SizedBox(width: screenWidth < 360 ? 6 : 8),
            Expanded(
              child: Text(
                'Membalas @${replyingToUsername!}',
                style: GoogleFonts.poppins(
                  color: const Color(0xFFFF6B35),
                  fontSize: screenWidth < 360 ? 12 : 14,
                  fontWeight: FontWeight.w500,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            SizedBox(
              width: 32,
              height: 32,
              child: IconButton(
                padding: EdgeInsets.zero,
                icon: Icon(
                  Icons.close_rounded,
                  color: const Color(0xFFFF6B35),
                  size: screenWidth < 360 ? 16 : 18,
                ),
                onPressed: () {
                  _slideController.reverse();
                  setState(() {
                    replyingToId = null;
                    replyingToUsername = null;
                    _commentController.clear();
                  });
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputField(User? currentUser, double screenWidth) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0F1118),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildProfileAvatar(
            currentUser?.photoURL,
            20,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      maxHeight: 100,
                    ),
                    child: TextField(
                      controller:
                          editingId == null ? _commentController : _editController,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                      ),
                      maxLines: null,
                      textInputAction: TextInputAction.newline,
                      decoration: InputDecoration(
                        hintText:
                            editingId != null
                                ? 'Edit komentar...'
                                : replyingToUsername != null
                                ? 'Balas @${replyingToUsername!}...'
                                : 'Tulis komentar kamu untuk episode ini...',
                        hintStyle: TextStyle(
                          color: Colors.grey[500],
                          fontSize: 14,
                        ),
                        filled: true,
                        fillColor: const Color(0xFF1E293B).withOpacity(0.5), // bg-slate-900/50
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: const Color(0xFFFF5E1E).withOpacity(0.5)),
                        ),
                        isDense: true,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF5E1E),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFFF5E1E).withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      )
                    ]
                  ),
                  child: IconButton(
                    padding: EdgeInsets.zero,
                    icon: const Icon(
                      Icons.send_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                    onPressed: () => _submitComment(currentUser),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _submitComment(User? currentUser) async {
    final controller = editingId == null ? _commentController : _editController;
    final content = controller.text.trim();

    if (content.isNotEmpty && currentUser != null) {
      if (editingId != null) {
        await widget.commentService.editComment(
          episodeId: widget.episodeId,
          commentId: editingId!,
          newContent: content,
        );
        setState(() {
          editingId = null;
        });
        _editController.clear();
      } else {
        await widget.commentService.addComment(
          episodeId: widget.episodeId,
          content: content,
          parentId: replyingToId,
          episodeTitle: widget.episodeTitle,
          animeTitle: widget.animeTitle,
          thumbUrl: widget.thumbUrl,
        );
        setState(() {
          replyingToId = null;
          replyingToUsername = null;
        });
        _commentController.clear();
      }
    }
  }

  Widget _buildCommentsStream(User? currentUser, double screenWidth) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _commentsStream,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Container(
            padding: EdgeInsets.all(screenWidth < 360 ? 30 : 40),
            child: const Center(
              child: CircularProgressIndicator(
                color: Color(0xFFFF6B35),
                strokeWidth: 2,
              ),
            ),
          );
        }

        final allComments =
            snapshot.data!.docs
                .map((doc) => {'id': doc.id, 'data': doc.data()})
                .toList();

        final mainComments =
            allComments
                .where(
                  (c) =>
                      (c['data'] as Map<String, dynamic>)['parentId'] == null,
                )
                .toList();

        mainComments.sort((a, b) {
          final tA = (a['data'] as Map<String, dynamic>)['timestamp'] as Timestamp?;
          final tB = (b['data'] as Map<String, dynamic>)['timestamp'] as Timestamp?;
          if (tA == null) return -1;
          if (tB == null) return 1;
          return widget.isDescending ? tB.compareTo(tA) : tA.compareTo(tB);
        });

        final replies =
            allComments
                .where(
                  (c) =>
                      (c['data'] as Map<String, dynamic>)['parentId'] != null,
                )
                .toList();

        widget.onCommentCountChanged?.call(mainComments.length);

        if (mainComments.isEmpty) {
          return Container(
            padding: EdgeInsets.symmetric(
              horizontal: screenWidth < 360 ? 16 : 24,
              vertical: screenWidth < 360 ? 32 : 40,
            ),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.chat_bubble_outline_rounded,
                    size: screenWidth < 360 ? 40 : 48,
                    color: const Color(0xFF666666),
                  ),
                  SizedBox(height: screenWidth < 360 ? 12 : 16),
                  Text(
                    'Belum ada komentar',
                    style: GoogleFonts.poppins(
                      color: const Color(0xFF666666),
                      fontSize: screenWidth < 360 ? 14 : 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(height: screenWidth < 360 ? 6 : 8),
                  Text(
                    'Jadilah yang pertama berkomentar!',
                    style: GoogleFonts.poppins(
                      color: const Color(0xFF888888),
                      fontSize: screenWidth < 360 ? 12 : 14,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        }

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: mainComments.length,
          itemBuilder: (context, index) {
            final comment = mainComments[index];
            final commentId = comment['id'] as String;
            final commentData = comment['data'] as Map<String, dynamic>;
            final commentReplies =
                replies
                    .where(
                      (r) =>
                          (r['data'] as Map<String, dynamic>)['parentId'] ==
                          commentId,
                    )
                    .toList();

            return _buildCommentItem(
              commentId,
              commentData,
              commentReplies,
              currentUser,
              screenWidth,
              isReply: false,
            );
          },
        );
      },
    );
  }

  Widget _buildCommentItem(
    String commentId,
    Map<String, dynamic> data,
    List<Map<String, dynamic>> replies,
    User? currentUser,
    double screenWidth, {
    bool isReply = false,
  }) {
    final key = _commentKeys.putIfAbsent(commentId, () => GlobalKey());
    final isHighlighted = commentId == widget.highlightCommentId;
    final isEditing = editingId == commentId;

    return Container(
      key: key,
      margin: EdgeInsets.only(
        left: isReply ? (screenWidth < 360 ? 24 : 32) : 0,
        bottom: 12,
      ),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF0F1118).withOpacity(0.8), // bg-surface/80
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isHighlighted 
            ? const Color(0xFFFF5E1E).withOpacity(0.5) 
            : Colors.white.withOpacity(0.05),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GestureDetector(
                onTap: () {
                  final uid = data['uid'];
                  if (uid != null && uid.isNotEmpty) {
                    if (currentUser != null && currentUser.uid == uid) {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfilePage()));
                    } else {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => PublicProfilePage(userId: uid)));
                    }
                  }
                },
                child: _buildProfileAvatar(
                  data['photoURL'],
                  18,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    GestureDetector(
                      onTap: () {
                        final uid = data['uid'];
                        if (uid != null && uid.isNotEmpty) {
                          if (currentUser != null && currentUser.uid == uid) {
                            Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfilePage()));
                          } else {
                            Navigator.push(context, MaterialPageRoute(builder: (_) => PublicProfilePage(userId: uid)));
                          }
                        }
                      },
                      child: Wrap(
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 6,
                        runSpacing: 4,
                        children: [
                          // [Logo_Badge_Rank] [Teks_Level]
                          RankBadgeWidget(
                            rankCode: data['userBadge'] ?? 'E',
                            level: (data['userLevel'] is int) ? data['userLevel'] : 1,
                            compact: true,
                          ),
                          // [Nama_User]
                          Text(
                            '@${data['username'] ?? 'Anonim'}',
                            style: GoogleFonts.outfit(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFFFF5E1E), // cyberOrange
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 3),
                    if (data['timestamp'] != null)
                      Text(
                        timeago.format((data['timestamp'] as Timestamp).toDate(), locale: 'id'),
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.grey[500],
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (isEditing)
            _buildEditField(commentId, data['content'], screenWidth)
          else
            Text(
              data['content'] ?? '',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[200],
                fontWeight: FontWeight.normal,
              ),
            ),
          if (!isEditing) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.only(top: 8),
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: Colors.white.withOpacity(0.05))),
              ),
              child: _buildActionButtons(commentId, data, currentUser, screenWidth),
            ),
          ],
          if (replies.isNotEmpty && !isReply)
            _buildRepliesSection(replies, currentUser, screenWidth),
        ],
      ),
    );
  }

  Widget _buildProfileAvatar(String? photoUrl, double radius) {
    return Container(
      width: radius * 2,
      height: radius * 2,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: const Color(0xFFFF5E1E).withOpacity(0.4),
          width: 1,
        ),
        color: const Color(0xFF1E293B), // slate-800
      ),
      child: ClipOval(
        child: photoUrl != null && photoUrl.isNotEmpty
            ? CachedNetworkImage(
                imageUrl: photoUrl,
                fit: BoxFit.cover,
                placeholder: (context, url) => const Center(
                  child: SizedBox(
                    width: 12, height: 12,
                    child: CircularProgressIndicator(
                      color: Color(0xFFFF5E1E),
                      strokeWidth: 1.5,
                    ),
                  ),
                ),
                errorWidget: (context, url, error) => Icon(
                  Icons.person,
                  size: radius,
                  color: Colors.grey[400],
                ),
              )
            : Icon(
                Icons.person,
                size: radius,
                color: Colors.grey[400],
              ),
      ),
    );
  }

  Widget _buildEditField(
    String commentId,
    String originalContent,
    double screenWidth,
  ) {
    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: screenWidth < 360 ? 80 : 100),
      child: TextField(
        controller: _editController,
        autofocus: true,
        maxLines: null,
        style: GoogleFonts.poppins(
          color: Colors.white,
          fontSize: screenWidth < 360 ? 12 : 14,
        ),
        decoration: InputDecoration(
          hintText: 'Edit komentar...',
          hintStyle: GoogleFonts.poppins(
            color: const Color(0xFF666666),
            fontSize: screenWidth < 360 ? 12 : 14,
          ),
          filled: true,
          fillColor: const Color(0xFF0A0A0A),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide.none,
          ),
          contentPadding: EdgeInsets.symmetric(
            horizontal: screenWidth < 360 ? 8 : 12,
            vertical: screenWidth < 360 ? 6 : 8,
          ),
          suffixIcon: Padding(
            padding: const EdgeInsets.only(right: 4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 32,
                  height: 32,
                  child: IconButton(
                    padding: EdgeInsets.zero,
                    icon: Icon(
                      Icons.check_rounded,
                      color: Colors.green,
                      size: screenWidth < 360 ? 16 : 18,
                    ),
                    onPressed: () => _submitEdit(commentId),
                  ),
                ),
                SizedBox(
                  width: 32,
                  height: 32,
                  child: IconButton(
                    padding: EdgeInsets.zero,
                    icon: Icon(
                      Icons.close_rounded,
                      color: Colors.red,
                      size: screenWidth < 360 ? 16 : 18,
                    ),
                    onPressed: () {
                      setState(() {
                        editingId = null;
                      });
                      _editController.clear();
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
        onSubmitted: (_) => _submitEdit(commentId),
      ),
    );
  }

  Future<void> _submitEdit(String commentId) async {
    final newContent = _editController.text.trim();
    if (newContent.isNotEmpty) {
      await widget.commentService.editComment(
        episodeId: widget.episodeId,
        commentId: commentId,
        newContent: newContent,
      );
      setState(() {
        editingId = null;
      });
      _editController.clear();
    }
  }



  Widget _buildActionButtons(
    String commentId,
    Map<String, dynamic> data,
    User? currentUser,
    double screenWidth,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            _buildActionButton(
              icon: Icons.reply,
              label: 'Balas',
              color: Colors.grey[400]!,
              onTap: () {
                setState(() {
                  replyingToId = data['parentId'] ?? commentId;
                  replyingToUsername = data['username'];
                  _commentController.text = '@${replyingToUsername!} ';
                  _commentController.selection = TextSelection.fromPosition(
                    TextPosition(offset: _commentController.text.length),
                  );
                });
                _slideController.forward();
              },
            ),
            const SizedBox(width: 16),
            _buildActionButton(
              icon: Icons.flag,
              label: 'Laporkan',
              color: Colors.amber.withOpacity(0.8),
              onTap: () => _reportComment(commentId, data),
            ),
          ],
        ),
        if (currentUser?.uid == data['uid'])
          Row(
            children: [
              _buildActionButton(
                icon: Icons.edit,
                label: 'Edit',
                color: Colors.grey[400]!,
                onTap: () {
                  setState(() {
                    editingId = commentId;
                    _editController.text = data['content'];
                  });
                },
              ),
              const SizedBox(width: 12),
              _buildActionButton(
                icon: Icons.delete,
                label: 'Hapus',
                color: Colors.red[400]!,
                onTap: () => _deleteComment(commentId),
              ),
            ],
          ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRepliesSection(
    List<Map<String, dynamic>> replies,
    User? currentUser,
    double screenWidth,
  ) {
    final commentId = replies.first['data']['parentId'];
    final isExpanded = expandedReplies[commentId] ?? false;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: screenWidth < 360 ? 8 : 12),
        Container(height: 1, color: const Color(0xFF2A2A2A)),
        SizedBox(height: screenWidth < 360 ? 8 : 12),
        GestureDetector(
          onTap: () {
            setState(() {
              expandedReplies[commentId] = !isExpanded;
            });
          },
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: screenWidth < 360 ? 6 : 8,
              vertical: screenWidth < 360 ? 4 : 6,
            ),
            decoration: BoxDecoration(
              color: const Color(0xFFFF6B35).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isExpanded ? Icons.expand_less : Icons.expand_more,
                  color: const Color(0xFFFF6B35),
                  size: screenWidth < 360 ? 16 : 20,
                ),
                SizedBox(width: screenWidth < 360 ? 4 : 8),
                Flexible(
                  child: Text(
                    isExpanded
                        ? 'Sembunyikan balasan'
                        : 'Lihat ${replies.length} balasan',
                    style: GoogleFonts.poppins(
                      fontSize: screenWidth < 360 ? 12 : 14,
                      color: const Color(0xFFFF6B35),
                      fontWeight: FontWeight.w500,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
        if (isExpanded) ...[
          SizedBox(height: screenWidth < 360 ? 8 : 12),
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  margin: EdgeInsets.only(
                    left: screenWidth < 360 ? 12 : 16,
                    right: screenWidth < 360 ? 8 : 12,
                  ),
                  width: 2,
                  decoration: BoxDecoration(
                    color: const Color(0xFF2A2A2A),
                    borderRadius: BorderRadius.circular(1),
                  ),
                ),
                Expanded(
                  child: Column(
                    children: replies.map(
                      (reply) => _buildCommentItem(
                        reply['id'],
                        reply['data'],
                        [],
                        currentUser,
                        screenWidth,
                        isReply: true,
                      ),
                    ).toList(),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Future<void> _reportComment(
    String commentId,
    Map<String, dynamic> data,
  ) async {
    await FirebaseFirestore.instance.collection('reports').add({
      'uid': FirebaseAuth.instance.currentUser!.uid,
      'commentId': commentId,
      'commentContent': data['content'],
      'reportedAt': FieldValue.serverTimestamp(),
      'episodeId': widget.episodeId,
      'reportedUserId': data['uid'],
    });

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Komentar telah dilaporkan',
            style: GoogleFonts.poppins(fontSize: 12),
          ),
          backgroundColor: const Color(0xFFFF6B35),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          margin: EdgeInsets.symmetric(
            horizontal: MediaQuery.of(context).size.width < 360 ? 12 : 16,
            vertical: 8,
          ),
        ),
      );
    }
  }

  Future<void> _deleteComment(String commentId) async {
    // Show confirmation dialog for mobile
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            backgroundColor: const Color(0xFF1A1A1A),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Text(
              'Hapus Komentar',
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: MediaQuery.of(context).size.width < 360 ? 16 : 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            content: Text(
              'Apakah Anda yakin ingin menghapus komentar ini?',
              style: GoogleFonts.poppins(
                color: const Color(0xFF888888),
                fontSize: MediaQuery.of(context).size.width < 360 ? 12 : 14,
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text(
                  'Batal',
                  style: GoogleFonts.poppins(
                    color: const Color(0xFF666666),
                    fontSize: MediaQuery.of(context).size.width < 360 ? 12 : 14,
                  ),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: Text(
                  'Hapus',
                  style: GoogleFonts.poppins(
                    color: const Color(0xFFFF4444),
                    fontSize: MediaQuery.of(context).size.width < 360 ? 12 : 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
    );

    if (shouldDelete == true) {
      await widget.commentService.deleteComment(
        episodeId: widget.episodeId,
        commentId: commentId,
      );
      setState(() {});
    }
  }
}
