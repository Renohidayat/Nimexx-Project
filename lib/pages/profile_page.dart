import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:cached_network_image/cached_network_image.dart';
import 'edit_profile_page.dart';
import 'anime_detail_page.dart';
import 'episode_page.dart';
import '../service/auth_service.dart';
import '../service/history_service.dart';
import '../service/favorite_service.dart';
import '../service/comment_service.dart';
import '../service/notification_service.dart';
import '../service/rank_service.dart';
import '../widgets/rank_badge_widget.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _currentUser = FirebaseAuth.instance.currentUser;
  final _historyService = HistoryService();
  late final CommentService _commentService;

  int _selectedTab = 0; // 0: Tontonan, 1: Favorit, 2: Komentar
  List<Map<String, dynamic>> _userComments = [];
  bool _isLoadingComments = true;

  static const Color primaryOrange = Color(0xFFFF5E1E);
  static const Color darkBg = Color(0xFF07080B);
  static const Color surfaceCard = Color(0xFF0F1118);
  static const Color elevatedCard = Color(0xFF171924);

  @override
  void initState() {
    super.initState();
    _commentService = CommentService(NotificationService());
    _loadComments();
    _syncHistoricalRank();
  }

  void _syncHistoricalRank() {
    if (_currentUser != null) {
      RankService().syncUserHistoricalExp(_currentUser.uid);
    }
  }

  Future<void> _loadComments() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (mounted) setState(() => _isLoadingComments = false);
      return;
    }
    final comments = await _commentService.getUserComments(user.uid);
    if (mounted) {
      setState(() {
        _userComments = comments;
        _isLoadingComments = false;
      });
    }
  }

  String _formatAccountAge(DateTime? createdDate) {
    if (createdDate == null) return 'Member Baru';
    final now = DateTime.now();
    final difference = now.difference(createdDate);
    final days = difference.inDays;

    if (days < 30) {
      if (days <= 0) return 'Baru Bergabung';
      return '< 1 Bulan';
    } else {
      final months = (days / 30).floor();
      return '$months Bulan';
    }
  }

  void _openPhotoPreview(BuildContext context, String photoUrl, String displayName) {
    if (photoUrl.isEmpty) return;
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        barrierDismissible: true,
        barrierColor: Colors.black.withOpacity(0.9),
        pageBuilder: (BuildContext context, _, __) {
          return Scaffold(
            backgroundColor: Colors.transparent,
            appBar: AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
              title: Text(
                displayName,
                style: GoogleFonts.outfit(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold),
              ),
            ),
            body: Center(
              child: Hero(
                tag: 'profile_photo_${_currentUser?.uid}',
                child: InteractiveViewer(
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
                    child: CachedNetworkImage(
                      imageUrl: photoUrl,
                      fit: BoxFit.contain,
                      placeholder: (_, __) => const Center(child: CircularProgressIndicator(color: primaryOrange)),
                      errorWidget: (_, __, ___) => const Icon(Icons.broken_image, size: 80, color: Colors.white54),
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
      return const Scaffold(
        backgroundColor: darkBg,
        body: Center(child: Text("Silakan login terlebih dahulu", style: TextStyle(color: Colors.white))),
      );
    }

    return Scaffold(
      backgroundColor: darkBg,
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('users').doc(_currentUser.uid).snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator(color: primaryOrange));
          }

          final userData = snapshot.data!.data() as Map<String, dynamic>? ?? {};
          final photoUrl = userData['photoUrl'] ?? _currentUser.photoURL ?? '';
          final displayName = userData['displayName'] ?? _currentUser.displayName ?? 'Pengguna';
          final username = userData['username'] ?? '';
          final bio = userData['bio'] ?? '';
          final friends = userData['friends'] ?? [];

          // Level & Rank Data
          final userLevel = userData['level'] as int? ?? 1;
          final userExp = userData['exp'] as int? ?? 0;
          final activeBadge = userData['active_badge'] as String? ?? 'E';
          final unlockedBadges = List<dynamic>.from(userData['unlocked_badges'] ?? ['E']);
          final rankInfo = RankService.getRankForLevel(userLevel);
          final expNeeded = RankService.getExpForNextLevel(userLevel);
          final expProgress = (userExp / expNeeded).clamp(0.0, 1.0);

          // Hitung Usia Akun
          final createdAt = (userData['createdAt'] as Timestamp?)?.toDate() ?? _currentUser.metadata.creationTime;
          final accountAge = _formatAccountAge(createdAt);

          return RefreshIndicator(
            onRefresh: () async {
              await Future.wait([
                _loadComments(),
                RankService().syncUserHistoricalExp(_currentUser.uid, force: true),
              ]);
            },
            color: primaryOrange,
            backgroundColor: surfaceCard,
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
              slivers: [
              SliverAppBar(
                expandedHeight: 270,
                pinned: true,
                backgroundColor: surfaceCard,
                leading: Navigator.canPop(context)
                    ? IconButton(
                        icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
                        onPressed: () => Navigator.pop(context),
                      )
                    : null,
                actions: [
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.08),
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.edit_rounded, color: Colors.white, size: 18),
                      tooltip: 'Edit Profil',
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const EditProfilePage()),
                        );
                      },
                    ),
                  ),
                  Container(
                    margin: const EdgeInsets.only(right: 12, top: 8, bottom: 8),
                    decoration: BoxDecoration(
                      color: Colors.redAccent.withOpacity(0.12),
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.logout_rounded, color: Colors.redAccent, size: 18),
                      tooltip: 'Keluar',
                      onPressed: () => _showLogoutDialog(context),
                    ),
                  ),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      if (photoUrl.isNotEmpty)
                        CachedNetworkImage(
                          imageUrl: photoUrl,
                          fit: BoxFit.cover,
                          errorWidget: (_, __, ___) => Container(color: surfaceCard),
                        )
                      else
                        Container(color: surfaceCard),
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.transparent,
                              darkBg.withOpacity(0.85),
                              darkBg,
                            ],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                        ),
                      ),
                      Align(
                        alignment: Alignment.bottomCenter,
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 16.0),
                          child: GestureDetector(
                            onTap: () => _openPhotoPreview(context, photoUrl, displayName),
                            child: Hero(
                              tag: 'profile_photo_${_currentUser.uid}',
                              child: Stack(
                                alignment: Alignment.bottomRight,
                                children: [
                                  Container(
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(color: primaryOrange, width: 3),
                                      boxShadow: [
                                        BoxShadow(
                                          color: primaryOrange.withOpacity(0.4),
                                          blurRadius: 20,
                                          spreadRadius: 2,
                                        ),
                                      ],
                                    ),
                                    child: CircleAvatar(
                                      radius: 48,
                                      backgroundImage: photoUrl.isNotEmpty ? NetworkImage(photoUrl) : null,
                                      backgroundColor: elevatedCard,
                                      child: photoUrl.isEmpty
                                          ? Text(
                                              displayName.isNotEmpty ? displayName[0].toUpperCase() : '?',
                                              style: const TextStyle(fontSize: 38, color: Colors.white, fontWeight: FontWeight.bold),
                                            )
                                          : null,
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: const BoxDecoration(
                                      color: primaryOrange,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(Icons.verified_rounded, size: 16, color: Colors.white),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // 1. Display Name
                      Text(
                        displayName,
                        style: GoogleFonts.outfit(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 3),

                      // 2. Username Tepat di Bawah Nama (Hapus usia akun di sampingnya!)
                      if (username.isNotEmpty)
                        Text(
                          '@$username',
                          style: TextStyle(
                            color: Colors.grey[400],
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      const SizedBox(height: 12),

                      // 3. Badge & Level (Mencolok, Ukuran Pas, Bersinar Terang!)
                      GestureDetector(
                        onTap: () {
                          RankOverviewBottomSheet.show(
                            context,
                            uid: _currentUser.uid,
                            currentLevel: userLevel,
                            currentExp: userExp,
                            currentActiveBadge: activeBadge,
                            unlockedBadges: unlockedBadges,
                            onBadgeChanged: () => setState(() {}),
                          );
                        },
                        child: RankBadgeWidget(
                          rankCode: activeBadge,
                          level: userLevel,
                          compact: false,
                          hero: true,
                        ),
                      ),
                      const SizedBox(height: 12),

                      // 4. Info Teman di Bawah Badge dan Level
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.06),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.white.withOpacity(0.08)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.people_alt_rounded, size: 14, color: primaryOrange),
                            const SizedBox(width: 5),
                            Text(
                              '${friends.length} Teman',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Container(
                              margin: const EdgeInsets.symmetric(horizontal: 10),
                              width: 4,
                              height: 4,
                              decoration: const BoxDecoration(
                                color: Colors.white38,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const Icon(Icons.history_rounded, size: 14, color: Color(0xFF64B5F6)),
                            const SizedBox(width: 5),
                            Text(
                              'Aktif $accountAge',
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),

                      // BIO TAMPIL TEPAT DI BAWAH NAMA
                      Container(
                        width: double.infinity,
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: surfaceCard,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.white.withOpacity(0.06)),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: primaryOrange.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(Icons.format_quote_rounded, color: primaryOrange, size: 16),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'BIO',
                                    style: TextStyle(color: Colors.grey[500], fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.8),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    bio.isNotEmpty ? bio : 'Belum ada bio. Tulis bio kamu di edit profil!',
                                    style: TextStyle(
                                      color: bio.isNotEmpty ? Colors.white70 : Colors.grey[600],
                                      fontSize: 13,
                                      fontStyle: bio.isNotEmpty ? FontStyle.normal : FontStyle.italic,
                                      height: 1.4,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Interaktif Rank & EXP Progress Card
                      GestureDetector(
                        onTap: () {
                          RankOverviewBottomSheet.show(
                            context,
                            uid: _currentUser.uid,
                            currentLevel: userLevel,
                            currentExp: userExp,
                            currentActiveBadge: activeBadge,
                            unlockedBadges: unlockedBadges,
                            onBadgeChanged: () => setState(() {}),
                          );
                        },
                        child: Container(
                          width: double.infinity,
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                surfaceCard,
                                rankInfo.primaryColor.withOpacity(0.12),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: rankInfo.primaryColor.withOpacity(0.35)),
                            boxShadow: [
                              BoxShadow(
                                color: rankInfo.primaryColor.withOpacity(0.12),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    width: 42,
                                    height: 42,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(10),
                                      boxShadow: [
                                        BoxShadow(
                                          color: rankInfo.primaryColor.withOpacity(0.35),
                                          blurRadius: 10,
                                          spreadRadius: 1,
                                        ),
                                      ],
                                    ),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(10),
                                      child: Image.asset(
                                        rankInfo.assetImage,
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) => Container(
                                          decoration: BoxDecoration(
                                            color: rankInfo.primaryColor.withOpacity(0.2),
                                            shape: BoxShape.circle,
                                            border: Border.all(color: rankInfo.primaryColor, width: 1.5),
                                          ),
                                          child: Icon(rankInfo.icon, color: rankInfo.primaryColor, size: 20),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Text(
                                              rankInfo.badgeName,
                                              style: GoogleFonts.outfit(
                                                color: Colors.white,
                                                fontSize: 14,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            const SizedBox(width: 6),
                                            Text(
                                              '• Level $userLevel',
                                              style: TextStyle(
                                                color: rankInfo.primaryColor,
                                                fontSize: 12,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ],
                                        ),
                                        Text(
                                          rankInfo.title,
                                          style: TextStyle(color: Colors.grey[400], fontSize: 11),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                    decoration: BoxDecoration(
                                      color: rankInfo.primaryColor.withOpacity(0.18),
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(color: rankInfo.primaryColor.withOpacity(0.4)),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          'Klaim Badge',
                                          style: TextStyle(
                                            color: rankInfo.primaryColor,
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(width: 4),
                                        Icon(Icons.arrow_forward_ios_rounded, size: 10, color: rankInfo.primaryColor),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Progres EXP Level $userLevel',
                                    style: TextStyle(color: Colors.grey[400], fontSize: 10),
                                  ),
                                  Text(
                                    '$userExp / $expNeeded EXP (${(expProgress * 100).toInt()}%)',
                                    style: const TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 5),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(6),
                                child: LinearProgressIndicator(
                                  value: expProgress,
                                  minHeight: 6,
                                  backgroundColor: Colors.white10,
                                  valueColor: AlwaysStoppedAnimation<Color>(rankInfo.primaryColor),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),

                      // Modern 4-Capsule Stat Cards
                      StreamBuilder<QuerySnapshot>(
                        stream: _historyService.getUserWatchHistoryStream(_currentUser.uid),
                        builder: (context, histSnap) {
                          final histCount = histSnap.data?.docs.length ?? 0;
                          return StreamBuilder<QuerySnapshot>(
                            stream: FavoriteService.getUserFavoritesStream(_currentUser.uid),
                            builder: (context, favSnap) {
                              final favCount = favSnap.data?.docs.length ?? 0;
                              return Container(
                                padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
                                decoration: BoxDecoration(
                                  color: surfaceCard,
                                  borderRadius: BorderRadius.circular(18),
                                  border: Border.all(color: Colors.white.withOpacity(0.05)),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.25),
                                      blurRadius: 12,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                                  children: [
                                    _buildStatItem('Tontonan', histCount.toString(), Icons.play_circle_fill_rounded),
                                    _buildStatDivider(),
                                    _buildStatItem('Favorit', favCount.toString(), Icons.bookmark_rounded),
                                    _buildStatDivider(),
                                    _buildStatItem('Komentar', _userComments.length.toString(), Icons.chat_bubble_rounded),
                                    _buildStatDivider(),
                                    _buildStatItem('Usia Akun', accountAge, Icons.schedule_rounded),
                                  ],
                                ),
                              );
                            },
                          );
                        },
                      ),
                      const SizedBox(height: 22),

                      // Segmented Modern Tab Bar with Counters
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: surfaceCard,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: Colors.white.withOpacity(0.05)),
                        ),
                        child: Row(
                          children: [
                            _buildTabButton(0, 'Tontonan', Icons.play_arrow_rounded),
                            _buildTabButton(1, 'Favorit', Icons.favorite_rounded),
                            _buildTabButton(2, 'Komentar (${_userComments.length})', Icons.chat_bubble_outline_rounded),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),
                    ],
                  ),
                ),
              ),

              // Tab Content Area
              _buildSelectedTabContent(_currentUser.uid),

              const SliverToBoxAdapter(
                child: SizedBox(height: 40),
              ),
            ],
          ),
        );
        },
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: primaryOrange),
            const SizedBox(width: 4),
            Text(
              value,
              style: GoogleFonts.outfit(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 3),
        Text(
          label,
          style: TextStyle(color: Colors.grey[500], fontSize: 11),
        ),
      ],
    );
  }

  Widget _buildStatDivider() {
    return Container(
      height: 26,
      width: 1,
      color: Colors.white.withOpacity(0.08),
    );
  }

  Widget _buildTabButton(int index, String label, IconData icon) {
    final isSelected = _selectedTab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() => _selectedTab = index);
          if (index == 2) {
            _loadComments();
          }
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? primaryOrange : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: primaryOrange.withOpacity(0.35),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    )
                  ]
                : [],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 15, color: isSelected ? Colors.white : Colors.grey[400]),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                    color: isSelected ? Colors.white : Colors.grey[400],
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSelectedTabContent(String uid) {
    switch (_selectedTab) {
      case 0:
        return _buildWatchHistorySliver(uid);
      case 1:
        return _buildFavoritesSliver(uid);
      case 2:
        return _buildCommentsSliver();
      default:
        return const SliverToBoxAdapter(child: SizedBox.shrink());
    }
  }

  // 1. Tontonan Tab
  Widget _buildWatchHistorySliver(String uid) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _historyService.getUserWatchHistoryStream(uid),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.all(32.0),
              child: Center(child: CircularProgressIndicator(color: primaryOrange)),
            ),
          );
        }

        final docs = List.of(snapshot.data?.docs ?? []);
        docs.sort((a, b) {
          final aTime = _parseDateTime(a.data()['watchedAt'] ?? a.data()['timestamp'] ?? a.data()['createdAt']);
          final bTime = _parseDateTime(b.data()['watchedAt'] ?? b.data()['timestamp'] ?? b.data()['createdAt']);
          if (aTime == null && bTime == null) return 0;
          if (aTime == null) return 1;
          if (bTime == null) return -1;
          return bTime.compareTo(aTime);
        });

        if (docs.isEmpty) {
          return _buildEmptyState(Icons.play_circle_outline_rounded, "Belum ada riwayat tontonan");
        }

        return SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final item = docs[index].data();
                final episodeTitle = item['title'] ?? 'Episode';
                final animeTitle = item['animeTitle'] ?? 'Anime';
                final thumb = item['thumb'] ?? '';
                final episodeId = item['episodeId'] ?? '';
                final animeEndpoint = item['animeEndpoint'] ?? '';
                final watchedAt = _parseDateTime(item['watchedAt'] ?? item['timestamp'] ?? item['createdAt']);
                final timeStr = watchedAt != null ? timeago.format(watchedAt, locale: 'id') : '';

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: surfaceCard,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white.withOpacity(0.05)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(10),
                    leading: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Container(
                            width: 78,
                            height: 54,
                            color: elevatedCard,
                            child: thumb.isNotEmpty
                                ? CachedNetworkImage(
                                    imageUrl: thumb,
                                    fit: BoxFit.cover,
                                    errorWidget: (_, __, ___) => const Icon(Icons.movie_creation_outlined, color: Colors.grey),
                                  )
                                : const Icon(Icons.movie_creation_outlined, color: Colors.grey),
                          ),
                          Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.6),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.play_arrow_rounded, color: primaryOrange, size: 16),
                          ),
                        ],
                      ),
                    ),
                    title: Text(
                      animeTitle,
                      style: GoogleFonts.outfit(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 2),
                        Text(
                          episodeTitle,
                          style: TextStyle(color: Colors.grey[400], fontSize: 12),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (timeStr.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            timeStr,
                            style: TextStyle(color: primaryOrange.withOpacity(0.85), fontSize: 11),
                          ),
                        ],
                      ],
                    ),
                    trailing: const Icon(Icons.chevron_right_rounded, color: Colors.grey, size: 20),
                    onTap: () {
                      if (episodeId.isNotEmpty) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => EpisodePage(
                              endpoint: episodeId,
                              episodeTitle: episodeTitle,
                              animeTitle: animeTitle,
                              thumbUrl: thumb,
                              animeEndpoint: animeEndpoint.isNotEmpty ? animeEndpoint : null,
                            ),
                          ),
                        );
                      }
                    },
                  ),
                );
              },
              childCount: docs.length,
            ),
          ),
        );
      },
    );
  }

  // 2. Favorit Tab
  Widget _buildFavoritesSliver(String uid) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FavoriteService.getUserFavoritesStream(uid),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.all(32.0),
              child: Center(child: CircularProgressIndicator(color: primaryOrange)),
            ),
          );
        }

        final docs = List.of(snapshot.data?.docs ?? []);
        docs.sort((a, b) {
          final aTime = _parseDateTime(a.data()['savedAt'] ?? a.data()['timestamp'] ?? a.data()['createdAt']);
          final bTime = _parseDateTime(b.data()['savedAt'] ?? b.data()['timestamp'] ?? b.data()['createdAt']);
          if (aTime == null && bTime == null) return 0;
          if (aTime == null) return 1;
          if (bTime == null) return -1;
          return bTime.compareTo(aTime);
        });

        if (docs.isEmpty) {
          return _buildEmptyState(Icons.bookmark_border_rounded, "Belum ada anime favorit yang disimpan");
        }

        return SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.7,
              crossAxisSpacing: 14,
              mainAxisSpacing: 14,
            ),
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final fav = docs[index].data();
                final title = fav['title'] ?? 'Anime';
                final endpoint = fav['endpoint'] ?? '';
                final thumb = fav['thumb'] ?? '';

                return GestureDetector(
                  onTap: () {
                    if (endpoint.isNotEmpty) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => AnimeDetailPage(endpoint: endpoint, title: title),
                        ),
                      );
                    }
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: surfaceCard,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white.withOpacity(0.06)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        thumb.isNotEmpty
                            ? CachedNetworkImage(
                                imageUrl: thumb,
                                fit: BoxFit.cover,
                                errorWidget: (_, __, ___) => Container(color: elevatedCard),
                              )
                            : Container(color: elevatedCard),
                        Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Colors.transparent, Colors.black.withOpacity(0.85)],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            ),
                          ),
                        ),
                        Positioned(
                          bottom: 10,
                          left: 10,
                          right: 10,
                          child: Text(
                            title,
                            style: GoogleFonts.outfit(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
              childCount: docs.length,
            ),
          ),
        );
      },
    );
  }

  // 3. Komentar Tab (DILENGKAPI GAMBAR ANIME & EPISODE DETAIL)
  Widget _buildCommentsSliver() {
    if (_isLoadingComments) {
      return const SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.all(32.0),
          child: Center(child: CircularProgressIndicator(color: primaryOrange)),
        ),
      );
    }

    if (_userComments.isEmpty) {
      return _buildEmptyState(Icons.chat_bubble_outline_rounded, "Belum ada riwayat komentar di anime");
    }

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final comment = _userComments[index];
            final content = comment['content'] ?? '';
            final animeTitle = comment['animeTitle'] ?? 'Anime';
            final episodeTitle = comment['episodeTitle'] ?? 'Episode';
            final episodeId = comment['episodeId'] ?? '';
            final thumbUrl = comment['thumbUrl'] ?? '';
            final rawTimestamp = comment['timestamp'];
            DateTime? commentDate;
            if (rawTimestamp is Timestamp) {
              commentDate = rawTimestamp.toDate();
            } else if (rawTimestamp is int) {
              commentDate = DateTime.fromMillisecondsSinceEpoch(rawTimestamp);
            } else if (rawTimestamp is DateTime) {
              commentDate = rawTimestamp;
            } else if (rawTimestamp is String) {
              commentDate = DateTime.tryParse(rawTimestamp);
            }
            final timeStr = commentDate != null ? timeago.format(commentDate, locale: 'id') : '';

            return Container(
              margin: const EdgeInsets.only(bottom: 14),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: surfaceCard,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withOpacity(0.06)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // GAMBAR POSTER / THUMBNAIL ANIME
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      width: 66,
                      height: 88,
                      color: elevatedCard,
                      child: thumbUrl.isNotEmpty
                          ? CachedNetworkImage(
                              imageUrl: thumbUrl,
                              fit: BoxFit.cover,
                              errorWidget: (_, __, ___) => Container(
                                color: elevatedCard,
                                child: const Icon(Icons.movie_creation_outlined, color: primaryOrange, size: 28),
                              ),
                            )
                          : Container(
                              color: elevatedCard,
                              child: const Icon(Icons.movie_creation_outlined, color: primaryOrange, size: 28),
                            ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  // KONTEN KOMENTAR & METADATA
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                animeTitle,
                                style: GoogleFonts.outfit(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (timeStr.isNotEmpty) ...[
                              const SizedBox(width: 6),
                              Text(
                                timeStr,
                                style: TextStyle(color: Colors.grey[500], fontSize: 11),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: primaryOrange.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: primaryOrange.withOpacity(0.25)),
                          ),
                          child: Text(
                            episodeTitle,
                            style: const TextStyle(
                              color: primaryOrange,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          content,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 13,
                            height: 1.35,
                          ),
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (episodeId.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Align(
                            alignment: Alignment.centerRight,
                            child: GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => EpisodePage(
                                      endpoint: episodeId,
                                      episodeTitle: episodeTitle,
                                      animeTitle: animeTitle,
                                      thumbUrl: thumbUrl,
                                    ),
                                  ),
                                );
                              },
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    'Buka Episode',
                                    style: TextStyle(color: primaryOrange, fontSize: 11, fontWeight: FontWeight.bold),
                                  ),
                                  SizedBox(width: 4),
                                  Icon(Icons.arrow_forward_rounded, color: primaryOrange, size: 13),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
          childCount: _userComments.length,
        ),
      ),
    );
  }

  Widget _buildEmptyState(IconData icon, String message) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 40.0, horizontal: 20.0),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 48, color: Colors.grey[700]),
              const SizedBox(height: 12),
              Text(
                message,
                style: TextStyle(color: Colors.grey[500], fontSize: 13),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: elevatedCard,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          title: Text('Logout', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold)),
          content: const Text('Apakah Anda yakin ingin keluar dari akun?', style: TextStyle(color: Colors.grey)),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Batal', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () async {
                final nav = Navigator.of(context, rootNavigator: true);
                nav.pop();
                try {
                  await AuthService().signOut();
                } finally {
                  nav.pushNamedAndRemoveUntil('/', (route) => false);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('Keluar', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  static DateTime? _parseDateTime(dynamic val) {
    if (val == null) return null;
    if (val is Timestamp) return val.toDate();
    if (val is int) return DateTime.fromMillisecondsSinceEpoch(val);
    if (val is DateTime) return val;
    if (val is String) return DateTime.tryParse(val);
    return null;
  }
}

