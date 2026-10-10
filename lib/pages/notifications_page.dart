import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../widgets/web_app_bar.dart';

class NotificationPage extends StatefulWidget {
  const NotificationPage({super.key});

  @override
  State<NotificationPage> createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _slideController;
  bool _isDeleting = false; // Tambah loading state untuk delete operations

  // Konstanta untuk mengurangi magic numbers
  static const Color _primaryColor = Color(0xFFFF6B35);
  static const Color _backgroundColor = Color(0xFF0A0A0A);
  static const Color _cardColor = Color(0xFF1A1A1A);
  static const Color _borderColor = Color(0xFF2A2A2A);
  static const Color _textSecondary = Color(0xFFB0B0B0);

  void _onWebNavSelected(int index, BuildContext context) {
    final routes = [
      '/home',
      '/list',
      '/schedule',
      '/ongoing',
      '/genre',
      '/search',
      '/notification',
    ];
    if (index < routes.length) {
      Navigator.pushNamed(context, routes[index]);
    }
  }

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
  }

  void _initializeAnimations() {
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _fadeController.forward();
    _slideController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  // Pindahkan query logic ke getter terpisah
  CollectionReference _getNotificationsRef(String userId) {
    return FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('notifications');
  }

  Query _getNotificationsQuery(String userId) {
    return _getNotificationsRef(userId).orderBy('timestamp', descending: true);
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final screenWidth = MediaQuery.of(context).size.width;

    if (user == null) {
      return Scaffold(
        backgroundColor: _backgroundColor,
        body: Center(child: _buildLoginPrompt()),
      );
    }

    return Scaffold(
      backgroundColor: _backgroundColor,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF1A0A0A), _backgroundColor],
          ),
        ),
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child:
                  kIsWeb
                      ? WebAppBar(
                        selectedIndex: 6,
                        onSelected:
                            (index) => _onWebNavSelected(index, context),
                      )
                      : _buildMobileAppBar(context, user.uid),
            ),
            SliverToBoxAdapter(
              child: FadeTransition(
                opacity: _fadeController,
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: screenWidth > 1200 ? 200 : 16,
                    vertical: 20,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (kIsWeb) _buildWebHeader(context, user.uid),
                      const SizedBox(height: 20),
                      _buildNotificationsStream(user.uid, context),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationsStream(String userId, BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: _getNotificationsQuery(userId).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildLoadingState();
        }

        if (snapshot.hasError) {
          return _buildErrorState(snapshot.error.toString());
        }

        final docs = snapshot.data?.docs ?? [];

        if (docs.isEmpty) {
          return _buildEmptyState();
        }

        return _buildNotificationsList(docs, userId, context);
      },
    );
  }

  Widget _buildLoginPrompt() {
    return FadeTransition(
      opacity: _fadeController,
      child: Container(
        padding: const EdgeInsets.all(40),
        decoration: BoxDecoration(
          color: _cardColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _primaryColor.withOpacity(0.3)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.5),
              spreadRadius: 2,
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.login_rounded, size: 60, color: _primaryColor),
            const SizedBox(height: 20),
            Text(
              "Login Required",
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              "Please login to view your notifications",
              style: GoogleFonts.poppins(color: _textSecondary, fontSize: 16),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMobileAppBar(BuildContext context, String userId) {
    return Container(
      decoration: const BoxDecoration(
        color: _cardColor,
        border: Border(bottom: BorderSide(color: _borderColor)),
      ),
      child: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          "Notifications",
          style: GoogleFonts.oswald(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 24,
            letterSpacing: -0.5,
          ),
        ),
        actions: [
          _buildClearAllButton(context, userId),
          const SizedBox(width: 8),
        ],
      ),
    );
  }

  Widget _buildWebHeader(BuildContext context, String userId) {
    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(0, -0.3),
        end: Offset.zero,
      ).animate(
        CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Notifications",
                style: GoogleFonts.oswald(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -1,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                "Stay updated with latest activities",
                style: GoogleFonts.poppins(color: _textSecondary, fontSize: 16),
              ),
            ],
          ),
          _buildClearAllButton(context, userId),
        ],
      ),
    );
  }

  Widget _buildClearAllButton(BuildContext context, String userId) {
    return Container(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap:
              _isDeleting ? null : () => _showClearAllDialog(context, userId),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_isDeleting)
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                else
                  const Icon(
                    Icons.delete_sweep_rounded,
                    color: Colors.white,
                    size: 37,
                  ),
                const SizedBox(width: 8),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 60),
        child: Column(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [_primaryColor, Color(0xFFFF6B6B)],
                ),
                borderRadius: BorderRadius.circular(25),
              ),
              child: const Center(
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              "Loading notifications...",
              style: GoogleFonts.poppins(color: _textSecondary, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(30),
        decoration: BoxDecoration(
          color: _cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _primaryColor.withOpacity(0.3)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              size: 48,
              color: _primaryColor,
            ),
            const SizedBox(height: 16),
            Text(
              "Failed to Load",
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "An error occurred while loading notifications.",
              style: GoogleFonts.poppins(color: _textSecondary, fontSize: 14),
              textAlign: TextAlign.center,
            ),
            // Tambah retry button untuk error state
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => setState(() {}), // Trigger rebuild
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text("Retry"),
              style: ElevatedButton.styleFrom(
                backgroundColor: _primaryColor,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(40),
        decoration: BoxDecoration(
          color: _cardColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _borderColor),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.notifications_off_outlined,
              size: 64,
              color: Color(0xFF555555),
            ),
            const SizedBox(height: 20),
            Text(
              "No Notifications",
              style: GoogleFonts.oswald(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "You're all caught up! No new notifications.",
              style: GoogleFonts.poppins(color: _textSecondary, fontSize: 14),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationsList(
    List<QueryDocumentSnapshot> docs,
    String userId,
    BuildContext context,
  ) {
    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(0, 0.3),
        end: Offset.zero,
      ).animate(
        CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic),
      ),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: docs.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final doc = docs[index];
          final data = doc.data() as Map<String, dynamic>?;

          if (data == null) return const SizedBox.shrink();

          return _buildNotificationCard(doc, data, userId, context);
        },
      ),
    );
  }

  Widget _buildNotificationCard(
    QueryDocumentSnapshot doc,
    Map<String, dynamic> data,
    String userId,
    BuildContext context,
  ) {
    final notifId = doc.id;
    final fromUsername = data['fromUsername'] ?? 'Someone';
    final message = data['message'] ?? '';
    final timestamp = (data['timestamp'] as Timestamp?)?.toDate();
    final isRead = data['read'] ?? false;

    return Container(
      decoration: BoxDecoration(
        color: isRead ? _cardColor : const Color(0xFF2A1A1A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isRead ? _borderColor : _primaryColor.withOpacity(0.3),
        ),
        boxShadow: [
          if (!isRead)
            BoxShadow(
              color: _primaryColor.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap:
              () => _handleNotificationTap(
                notifId,
                userId,
                isRead,
                data,
                context,
              ),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                // Icon
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color:
                        isRead ? _borderColor : _primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    isRead
                        ? Icons.notifications_none_rounded
                        : Icons.notifications_active_rounded,
                    color: isRead ? const Color(0xFF666666) : _primaryColor,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),

                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      RichText(
                        text: TextSpan(
                          children: [
                            TextSpan(
                              text: fromUsername,
                              style: GoogleFonts.poppins(
                                color: _primaryColor,
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            TextSpan(
                              text: ' $message',
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (timestamp != null) ...[
                        const SizedBox(height: 6),
                        Text(
                          timeago.format(timestamp, locale: 'en'),
                          style: GoogleFonts.poppins(
                            color: const Color(0xFF666666),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                // Menu Button
                PopupMenuButton<String>(
                  icon: const Icon(
                    Icons.more_vert_rounded,
                    color: Color(0xFF666666),
                    size: 20,
                  ),
                  color: _borderColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: const BorderSide(color: Color(0xFF3A3A3A)),
                  ),
                  onSelected:
                      (value) =>
                          _handleMenuAction(value, notifId, userId, context),
                  itemBuilder:
                      (context) => [
                        PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              const Icon(
                                Icons.delete_outline_rounded,
                                color: _primaryColor,
                                size: 18,
                              ),
                              const SizedBox(width: 12),
                              Text(
                                'Delete',
                                style: GoogleFonts.poppins(
                                  color: Colors.white,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _handleNotificationTap(
    String notifId,
    String userId,
    bool isRead,
    Map<String, dynamic> data,
    BuildContext context,
  ) async {
    try {
      // Mark as read if not already read
      if (!isRead) {
        await _getNotificationsRef(userId).doc(notifId).update({'read': true});
      }

      // Navigate to episode if episodeId exists
      final episodeId = data['episodeId'];
      if (episodeId != null && mounted) {
        Navigator.pushNamed(
          context,
          '/episode',
          arguments: {
            'endpoint': episodeId,
            'episodeTitle': data['episodeTitle'] ?? '',
            'animeTitle': data['animeTitle'] ?? '',
            'thumbUrl': data['thumbUrl'] ?? '',
            'highlightCommentId': data['commentId'],
          },
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to open notification: $e')),
        );
      }
    }
  }

  Future<void> _handleMenuAction(
    String action,
    String notifId,
    String userId,
    BuildContext context,
  ) async {
    if (action == 'delete') {
      final confirm = await _showDeleteDialog(context, single: true);
      if (confirm == true) {
        try {
          await _getNotificationsRef(userId).doc(notifId).delete();
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Notification deleted')),
            );
          }
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Failed to delete notification: $e')),
            );
          }
        }
      }
    }
  }

  Future<void> _showClearAllDialog(BuildContext context, String userId) async {
    final confirm = await _showDeleteDialog(context, single: false);
    if (confirm == true) {
      setState(() => _isDeleting = true);
      try {
        final snapshot = await _getNotificationsRef(userId).get();
        // Batch delete untuk performa yang lebih baik
        final batch = FirebaseFirestore.instance.batch();
        for (var doc in snapshot.docs) {
          batch.delete(doc.reference);
        }
        await batch.commit();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('All notifications cleared')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to clear notifications: $e')),
          );
        }
      } finally {
        if (mounted) {
          setState(() => _isDeleting = false);
        }
      }
    }
  }

  Future<bool?> _showDeleteDialog(
    BuildContext context, {
    required bool single,
  }) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: _cardColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: const BorderSide(color: _borderColor),
          ),
          title: Row(
            children: [
              const Icon(
                Icons.delete_outline_rounded,
                color: _primaryColor,
                size: 28,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  single ? 'Delete Notification' : 'Clear All Notifications',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          content: Text(
            single
                ? 'This notification will be deleted permanently.'
                : 'All notifications will be deleted permanently. This action cannot be undone.',
            style: GoogleFonts.poppins(color: _textSecondary, fontSize: 14),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(
                'Cancel',
                style: GoogleFonts.poppins(
                  color: _textSecondary,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: _primaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: Text(
                single ? 'Delete' : 'Clear All',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
