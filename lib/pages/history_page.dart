import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../widgets/web_app_bar.dart';
import 'episode_page.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _slideController;
  String _searchQuery = '';

  void _onWebNavSelected(int index, BuildContext context) {
    switch (index) {
      case 0:
        Navigator.pushNamed(context, '/home');
        break;
      case 1:
        Navigator.pushNamed(context, '/list');
        break;
      case 2:
        Navigator.pushNamed(context, '/schedule');
        break;
      case 3:
        Navigator.pushNamed(context, '/ongoing');
        break;
      case 4:
        Navigator.pushNamed(context, '/genre');
        break;
      case 5:
        Navigator.pushNamed(context, '/search');
        break;
      case 6:
        Navigator.pushNamed(context, '/notification');
        break;
      case 7:
        Navigator.pushNamed(context, '/history');
        break;
    }
  }

  @override
  void initState() {
    super.initState();
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

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final screenWidth = MediaQuery.of(context).size.width;

    if (user == null) {
      return Scaffold(
        backgroundColor: const Color(0xFF0A0A0A),
        body: Center(child: _buildLoginPrompt()),
      );
    }

    final historyCollection = FirebaseFirestore.instance
        .collection('watch_history')
        .doc(user.uid)
        .collection('history');

    final historyQuery = historyCollection.orderBy(
      'watchedAt',
      descending: true,
    );

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF1A0A0A), Color(0xFF0A0A0A)],
          ),
        ),
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child:
                  kIsWeb
                      ? WebAppBar(
                        selectedIndex: 7,
                        onSelected:
                            (index) => _onWebNavSelected(index, context),
                      )
                      : _buildMobileAppBar(
                        context,
                        user.uid,
                        historyCollection,
                      ),
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
                      if (kIsWeb)
                        _buildWebHeader(context, user.uid, historyCollection),
                      if (kIsWeb) const SizedBox(height: 20),
                      _buildSearchBar(),
                      const SizedBox(height: 20),
                      StreamBuilder<QuerySnapshot>(
                        stream: historyQuery.snapshots(),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return _buildLoadingState();
                          }

                          if (snapshot.hasError) {
                            return _buildErrorState();
                          }

                          final docs = snapshot.data?.docs ?? [];

                          if (docs.isEmpty) {
                            return _buildEmptyState();
                          }

                          // Filter berdasarkan search query
                          final filteredDocs =
                              _searchQuery.isEmpty
                                  ? docs
                                  : docs.where((doc) {
                                    final data =
                                        doc.data() as Map<String, dynamic>;
                                    final title =
                                        (data['title'] ?? '')
                                            .toString()
                                            .toLowerCase();
                                    final animeTitle =
                                        (data['animeTitle'] ?? '')
                                            .toString()
                                            .toLowerCase();
                                    return title.contains(
                                          _searchQuery.toLowerCase(),
                                        ) ||
                                        animeTitle.contains(
                                          _searchQuery.toLowerCase(),
                                        );
                                  }).toList();

                          if (filteredDocs.isEmpty && _searchQuery.isNotEmpty) {
                            return _buildNoSearchResults();
                          }

                          return _buildHistoryList(
                            filteredDocs,
                            user.uid,
                            context,
                          );
                        },
                      ),
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

  Widget _buildLoginPrompt() {
    return FadeTransition(
      opacity: _fadeController,
      child: Container(
        padding: const EdgeInsets.all(40),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: const Color(0xFFDC143C).withOpacity(0.3),
            width: 1,
          ),
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
            const Icon(Icons.login_rounded, size: 60, color: Color(0xFFDC143C)),
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
              "Please login to view your watch history",
              style: GoogleFonts.poppins(
                color: const Color(0xFFB0B0B0),
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMobileAppBar(
    BuildContext context,
    String userId,
    CollectionReference historyRef,
  ) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF1A1A1A),
        border: Border(bottom: BorderSide(color: Color(0xFF2A2A2A), width: 1)),
      ),
      child: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          "Watch History",
          style: GoogleFonts.oswald(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 24,
            letterSpacing: -0.5,
          ),
        ),
        actions: [
          _buildClearAllButton(context, userId, historyRef),
          const SizedBox(width: 8),
        ],
      ),
    );
  }

  Widget _buildWebHeader(
    BuildContext context,
    String userId,
    CollectionReference historyRef,
  ) {
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
                "Watch History",
                style: GoogleFonts.oswald(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -1,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                "Continue where you left off",
                style: GoogleFonts.poppins(
                  color: const Color(0xFFB0B0B0),
                  fontSize: 16,
                ),
              ),
            ],
          ),
          _buildClearAllButton(context, userId, historyRef),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF2A2A2A), width: 1),
      ),
      child: TextField(
        onChanged: (value) => setState(() => _searchQuery = value),
        style: GoogleFonts.poppins(color: Colors.white),
        decoration: InputDecoration(
          hintText: 'Search watch history...',
          hintStyle: GoogleFonts.poppins(color: const Color(0xFF666666)),
          prefixIcon: const Icon(Icons.search, color: Color(0xFF666666)),
          suffixIcon:
              _searchQuery.isNotEmpty
                  ? IconButton(
                    icon: const Icon(Icons.clear, color: Color(0xFF666666)),
                    onPressed: () => setState(() => _searchQuery = ''),
                  )
                  : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.all(16),
        ),
      ),
    );
  }

  Widget _buildClearAllButton(
    BuildContext context,
    String userId,
    CollectionReference historyRef,
  ) {
    return Container(
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(12)),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showClearAllDialog(context, userId, historyRef),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
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
              "Loading watch history...",
              style: GoogleFonts.poppins(
                color: const Color(0xFFB0B0B0),
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(30),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: const Color(0xFFDC143C).withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              size: 48,
              color: Color(0xFFDC143C),
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
              "An error occurred while loading your watch history.",
              style: GoogleFonts.poppins(
                color: const Color(0xFFB0B0B0),
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
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
          color: const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFF2A2A2A), width: 1),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.history, size: 64, color: Color(0xFF555555)),
            const SizedBox(height: 20),
            Text(
              "No Watch History",
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Start watching to see your history here.",
              style: GoogleFonts.poppins(
                color: const Color(0xFFB0B0B0),
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoSearchResults() {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(30),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFF2A2A2A), width: 1),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.search_off, size: 48, color: Color(0xFF555555)),
            const SizedBox(height: 16),
            Text(
              "No Results Found",
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Try searching with different keywords.",
              style: GoogleFonts.poppins(
                color: const Color(0xFFB0B0B0),
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryList(
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
          final data = doc.data() as Map<String, dynamic>;
          return _buildHistoryCard(doc, data, userId, context);
        },
      ),
    );
  }

  Widget _buildHistoryCard(
    QueryDocumentSnapshot doc,
    Map<String, dynamic> data,
    String userId,
    BuildContext context,
  ) {
    final watchedAt = (data['watchedAt'] as Timestamp?)?.toDate();
    final thumbUrl = data['thumb'] ?? '';
    final episodeId = data['episodeId'] ?? '';
    final title = data['title'] ?? '-';
    final animeTitle = data['animeTitle'] ?? '-';

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF2A2A2A), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap:
              () => _navigateToEpisode(
                context,
                data,
                episodeId,
                title,
                animeTitle,
                thumbUrl,
              ),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Thumbnail
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child:
                      thumbUrl.isNotEmpty
                          ? Image.network(
                            thumbUrl,
                            width: 80,
                            height: 60,
                            fit: BoxFit.cover,
                            errorBuilder:
                                (_, __, ___) => _buildErrorThumbnail(),
                          )
                          : _buildErrorThumbnail(),
                ),
                const SizedBox(width: 16),

                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        animeTitle,
                        style: GoogleFonts.poppins(
                          color: const Color(0xFFDC143C),
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            Icons.access_time_rounded,
                            size: 16,
                            color: const Color(0xFF666666),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            watchedAt != null
                                ? timeago.format(watchedAt, locale: 'en')
                                : 'Unknown',
                            style: GoogleFonts.poppins(
                              color: const Color(0xFF666666),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
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
                  color: const Color(0xFF2A2A2A),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: const BorderSide(color: Color(0xFF3A3A3A), width: 1),
                  ),
                  onSelected:
                      (value) =>
                          _handleMenuAction(value, doc.id, userId, context),
                  itemBuilder:
                      (context) => [
                        PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              const Icon(
                                Icons.delete_outline_rounded,
                                color: Color(0xFFDC143C),
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

  Widget _buildErrorThumbnail() {
    return Container(
      width: 80,
      height: 60,
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A2A),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Icon(
        Icons.broken_image_outlined,
        color: Color(0xFF666666),
        size: 24,
      ),
    );
  }

  void _navigateToEpisode(
    BuildContext context,
    Map<String, dynamic> data,
    String episodeId,
    String title,
    String animeTitle,
    String thumbUrl,
  ) {
    print('Data from history: $data'); // Debug ini
    print('animeEndpoint: ${data['animeEndpoint']}'); // Debug ini

    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (_) => EpisodePage(
              endpoint: episodeId,
              episodeTitle: title,
              animeTitle: animeTitle,
              thumbUrl: thumbUrl,
              animeEndpoint: data['animeEndpoint'],
            ),
      ),
    );
  }

  void _handleMenuAction(
    String action,
    String docId,
    String userId,
    BuildContext context,
  ) async {
    if (action == 'delete') {
      final confirm = await _showDeleteDialog(context, single: true);
      if (confirm == true) {
        await _deleteSingleHistory(userId, docId, context);
      }
    }
  }

  void _showClearAllDialog(
    BuildContext context,
    String userId,
    CollectionReference historyRef,
  ) async {
    final confirm = await _showDeleteDialog(context, single: false);
    if (confirm == true) {
      await _clearAllHistory(userId, historyRef, context);
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
          backgroundColor: const Color(0xFF1A1A1A),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: const BorderSide(color: Color(0xFF2A2A2A), width: 1),
          ),
          title: Row(
            children: [
              const Icon(
                Icons.delete_outline_rounded,
                color: Color(0xFFDC143C),
                size: 28,
              ),
              const SizedBox(width: 12),
              Text(
                single ? 'Delete History' : 'Clear All History',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          content: Text(
            single
                ? 'This history entry will be deleted permanently.'
                : 'All watch history will be deleted permanently. This action cannot be undone.',
            style: GoogleFonts.poppins(
              color: const Color(0xFFB0B0B0),
              fontSize: 14,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(
                'Cancel',
                style: GoogleFonts.poppins(
                  color: const Color(0xFFB0B0B0),
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFDC143C),
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

  Future<void> _clearAllHistory(
    String userId,
    CollectionReference historyRef,
    BuildContext context,
  ) async {
    try {
      final snapshots = await historyRef.get();
      for (var doc in snapshots.docs) {
        await doc.reference.delete();
      }
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "All history cleared successfully",
              style: GoogleFonts.poppins(color: Colors.white),
            ),
            backgroundColor: const Color(0xFF2A7C2A),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "Failed to clear history: $e",
              style: GoogleFonts.poppins(color: Colors.white),
            ),
            backgroundColor: const Color(0xFFDC143C),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    }
  }

  Future<void> _deleteSingleHistory(
    String userId,
    String docId,
    BuildContext context,
  ) async {
    try {
      await FirebaseFirestore.instance
          .collection('watch_history')
          .doc(userId)
          .collection('history')
          .doc(docId)
          .delete();

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "History deleted successfully",
              style: GoogleFonts.poppins(color: Colors.white),
            ),
            backgroundColor: const Color(0xFF2A7C2A),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "Failed to delete history: $e",
              style: GoogleFonts.poppins(color: Colors.white),
            ),
            backgroundColor: const Color(0xFFDC143C),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    }
  }
}
