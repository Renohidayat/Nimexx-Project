import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:google_fonts/google_fonts.dart';
import '../widgets/web_app_bar.dart';

import 'anime_detail_mobile.dart';
import 'anime_detail_web.dart';

class FavoritePage extends StatefulWidget {
  const FavoritePage({super.key});

  @override
  State<FavoritePage> createState() => _FavoritePageState();
}

class _FavoritePageState extends State<FavoritePage>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _slideController;
  bool _isDeleting = false;

  // Design Constants
  static const Color _primaryColor = Color(0xFFDC143C);
  static const Color _backgroundColor = Color(0xFF0A0A0A);
  static const Color _cardColor = Color(0xFF1A1A1A);
  static const Color _borderColor = Color(0xFF2A2A2A);
  static const Color _textSecondary = Color(0xFFB0B0B0);

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

  Future<void> _deleteFavorite(String endpoint) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('favorites')
          .doc(endpoint)
          .delete();

      if (mounted) {
        _showSnackBar('Anime berhasil dihapus dari favorit', Colors.green);
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar('Gagal menghapus anime: $e', _primaryColor);
      }
    }
  }

  Future<void> _deleteAllFavorites() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() => _isDeleting = true);

    try {
      final favs =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .collection('favorites')
              .get();

      // Batch delete untuk performa lebih baik
      final batch = FirebaseFirestore.instance.batch();
      for (var doc in favs.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();

      if (mounted) {
        _showSnackBar('Semua anime favorit berhasil dihapus', Colors.green);
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar('Gagal menghapus semua favorit: $e', _primaryColor);
      }
    } finally {
      if (mounted) {
        setState(() => _isDeleting = false);
      }
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: GoogleFonts.poppins(color: Colors.white)),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Future<bool?> _showDeleteDialog({required bool deleteAll}) {
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
                  deleteAll ? 'Hapus Semua Favorit' : 'Hapus dari Favorit',
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
            deleteAll
                ? 'Semua anime favorit akan dihapus secara permanen. Tindakan ini tidak dapat dibatalkan.'
                : 'Anime ini akan dihapus dari daftar favorit Anda.',
            style: GoogleFonts.poppins(color: _textSecondary, fontSize: 14),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(
                'Batal',
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
                deleteAll ? 'Hapus Semua' : 'Hapus',
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

  void _onWebNavSelected(int index, BuildContext context) {
    final routes = [
      '/home',
      '/list',
      '/schedule',
      '/ongoing',
      '/genre',
      '/search',
      '/notification',
      '/history',
    ];
    if (index < routes.length) {
      Navigator.pushNamed(context, routes[index]);
    }
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

    final favoriteStream =
        FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('favorites')
            .orderBy('savedAt', descending: true)
            .snapshots();

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
                        selectedIndex: -1,
                        onSelected:
                            (index) => _onWebNavSelected(index, context),
                      )
                      : _buildMobileAppBar(),
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
                      if (kIsWeb) _buildWebHeader(),
                      const SizedBox(height: 20),
                      _buildFavoritesList(favoriteStream),
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
              "Login Diperlukan",
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              "Silakan login untuk melihat anime favorit Anda",
              style: GoogleFonts.poppins(color: _textSecondary, fontSize: 16),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMobileAppBar() {
    return Container(
      decoration: const BoxDecoration(
        color: _cardColor,
        border: Border(bottom: BorderSide(color: _borderColor)),
      ),
      child: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          "Anime Favorit",
          style: GoogleFonts.oswald(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 24,
            letterSpacing: -0.5,
          ),
        ),
        actions: [_buildDeleteAllButton(), const SizedBox(width: 8)],
      ),
    );
  }

  Widget _buildWebHeader() {
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
                "Anime Favorit",
                style: GoogleFonts.oswald(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -1,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                "Koleksi anime terbaik pilihan Anda",
                style: GoogleFonts.poppins(color: _textSecondary, fontSize: 16),
              ),
            ],
          ),
          _buildDeleteAllButton(),
        ],
      ),
    );
  }

  Widget _buildDeleteAllButton() {
    return Container(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap:
              _isDeleting
                  ? null
                  : () async {
                    final confirm = await _showDeleteDialog(deleteAll: true);
                    if (confirm == true) {
                      await _deleteAllFavorites();
                    }
                  },
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
                    Icons.delete_forever_rounded,
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

  Widget _buildFavoritesList(Stream<QuerySnapshot> favoriteStream) {
    return StreamBuilder<QuerySnapshot>(
      stream: favoriteStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildLoadingState();
        }

        if (snapshot.hasError) {
          return _buildErrorState();
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return _buildEmptyState();
        }

        final favorites = snapshot.data!.docs;
        final screenWidth = MediaQuery.of(context).size.width;

        // Responsive grid
        int crossAxisCount;
        double childAspectRatio;

        if (kIsWeb) {
          if (screenWidth > 1400) {
            crossAxisCount = 4;
            childAspectRatio = 0.7;
          } else if (screenWidth > 1000) {
            crossAxisCount = 3;
            childAspectRatio = 0.65;
          } else {
            crossAxisCount = 2;
            childAspectRatio = 0.6;
          }
        } else {
          crossAxisCount = screenWidth > 600 ? 3 : 2;
          childAspectRatio = 0.65;
        }

        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 0.3),
            end: Offset.zero,
          ).animate(
            CurvedAnimation(
              parent: _slideController,
              curve: Curves.easeOutCubic,
            ),
          ),
          child: GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              childAspectRatio: childAspectRatio,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
            ),
            itemCount: favorites.length,
            itemBuilder: (context, index) {
              final fav = favorites[index];
              return _buildAnimeCard(fav);
            },
          ),
        );
      },
    );
  }

  Widget _buildAnimeCard(QueryDocumentSnapshot fav) {
    final title = fav['title'] ?? 'Tanpa Judul';
    final endpoint = fav['endpoint'] ?? '';
    final thumb = fav['thumb'] ?? '';

    return Container(
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            spreadRadius: 1,
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder:
                    (_) =>
                        kIsWeb
                            ? AnimeDetailWeb(endpoint: endpoint, title: title)
                            : AnimeDetailMobile(
                              endpoint: endpoint,
                              title: title,
                            ),
              ),
            );
          },
          borderRadius: BorderRadius.circular(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Thumbnail
              Expanded(
                flex: 4,
                child: Stack(
                  children: [
                    ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(16),
                      ),
                      child: Image.network(
                        thumb,
                        width: double.infinity,
                        height: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder:
                            (_, __, ___) => Container(
                              width: double.infinity,
                              height: double.infinity,
                              color: Colors.grey[800],
                              child: const Icon(
                                Icons.broken_image_rounded,
                                color: Colors.white54,
                                size: 40,
                              ),
                            ),
                      ),
                    ),
                    // Gradient overlay
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: Container(
                        height: 60,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.black.withOpacity(0.7),
                            ],
                          ),
                        ),
                      ),
                    ),
                    // Menu button
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.7),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: PopupMenuButton<String>(
                          icon: const Icon(
                            Icons.more_vert_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                          color: _borderColor,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: const BorderSide(color: Color(0xFF3A3A3A)),
                          ),
                          onSelected: (value) async {
                            if (value == 'delete') {
                              final confirm = await _showDeleteDialog(
                                deleteAll: false,
                              );
                              if (confirm == true) {
                                await _deleteFavorite(endpoint);
                              }
                            }
                          },
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
                                        'Hapus',
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
                      ),
                    ),
                  ],
                ),
              ),
              // Title
              Expanded(
                flex: 2,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                            height: 1.3,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: _primaryColor.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: _primaryColor.withOpacity(0.3),
                          ),
                        ),
                        child: Text(
                          'Favorit',
                          style: GoogleFonts.poppins(
                            color: _primaryColor,
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
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
              "Memuat anime favorit...",
              style: GoogleFonts.poppins(color: _textSecondary, fontSize: 14),
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
              "Gagal Memuat Data",
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Terjadi kesalahan saat mengambil data favorit.",
              style: GoogleFonts.poppins(color: _textSecondary, fontSize: 14),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => setState(() {}),
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text("Coba Lagi"),
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
              Icons.favorite_border_outlined,
              size: 64,
              color: Color(0xFF555555),
            ),
            const SizedBox(height: 20),
            Text(
              "Belum Ada Favorit",
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Mulai tambahkan anime ke favorit untuk melihatnya di sini 💖",
              style: GoogleFonts.poppins(color: _textSecondary, fontSize: 14),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
