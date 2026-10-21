import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/leaderboard_user.dart';
import '../service/leaderboard_service.dart';
import '../service/rank_service.dart';
import '../widgets/rank_badge_widget.dart';
import '../widgets/user_avatar_widget.dart';
import 'public_profile_page.dart';

class LeaderboardPage extends StatefulWidget {
  const LeaderboardPage({super.key});

  @override
  State<LeaderboardPage> createState() => _LeaderboardPageState();
}

class _LeaderboardPageState extends State<LeaderboardPage> {
  final LeaderboardService _leaderboardService = LeaderboardService();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    // 🚀 Otomatis deteksi & sinkronkan seluruh akun di database yang aktif / punya riwayat
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _leaderboardService.autoSyncAllUsers();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToCurrentUser(List<LeaderboardUser> users) {
    final currentUid = FirebaseAuth.instance.currentUser?.uid;
    if (currentUid == null || users.isEmpty) return;

    final index = users.indexWhere((u) => u.uid == currentUid);
    if (index != -1) {
      final targetOffset = 320.0 + (index * 88.0);
      _scrollController.animateTo(
        targetOffset.clamp(0.0, _scrollController.position.maxScrollExtent),
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeOutCubic,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUid = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      backgroundColor: const Color(0xFF08090D),
      body: SafeArea(
        child: Column(
          children: [
            // 🔹 Custom App Bar Bertema Nimexx (Orange - Gold - Red)
            _buildAppBar(context),

            // 🔹 Stream Realtime Peringkat dari Firestore
            Expanded(
              child: StreamBuilder<List<LeaderboardUser>>(
                stream: _leaderboardService.getLeaderboardStream(limit: 100),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFFFF5E1E),
                      ),
                    );
                  }

                  final users = snapshot.data ?? [];

                  if (users.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.emoji_events_outlined,
                            size: 64,
                            color: Colors.white.withValues(alpha: 0.3),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Belum ada peringkat pengguna.',
                            style: GoogleFonts.outfit(
                              fontSize: 16,
                              color: Colors.white70,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  LeaderboardUser? myData;
                  if (currentUid != null) {
                    final found = users.where((u) => u.uid == currentUid);
                    if (found.isNotEmpty) myData = found.first;
                  }

                  return Stack(
                    children: [
                      RefreshIndicator(
                        color: const Color(0xFFFF5E1E),
                        backgroundColor: const Color(0xFF1E1512),
                        onRefresh: () async {
                          await _leaderboardService.autoSyncAllUsers(force: true);
                        },
                        child: ListView(
                          controller: _scrollController,
                          physics: const AlwaysScrollableScrollPhysics(
                            parent: BouncingScrollPhysics(),
                          ),
                          padding: const EdgeInsets.only(
                            left: 16,
                            right: 16,
                            bottom: 100,
                            top: 10,
                          ),
                          children: [
                            // 👑 Section "The Big 3" Podium jika pengguna >= 3
                            if (users.length >= 3) ...[
                              _buildTheBig3Podium(users),
                              const SizedBox(height: 24),
                            ],

                            // 📌 Header Daftar Peringkat
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      width: 4,
                                      height: 18,
                                      margin: const EdgeInsets.only(right: 8),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFFF3D00),
                                        borderRadius: BorderRadius.circular(2),
                                      ),
                                    ),
                                    Text(
                                      'PERINGKAT PENGGUNA TERATAS',
                                      style: GoogleFonts.oswald(
                                        fontSize: 16.5,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                        letterSpacing: 1.0,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        gradient: const LinearGradient(
                                          colors: [Color(0xFFFF3D00), Color(0xFFFF8800)],
                                        ),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Text(
                                        '${users.length} Member',
                                        style: GoogleFonts.outfit(
                                          fontSize: 10.5,
                                          fontWeight: FontWeight.w800,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),

                            const SizedBox(height: 14),

                            // 📜 Daftar List Peringkat
                            ListView.separated(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: users.length,
                              separatorBuilder: (_, __) => const SizedBox(height: 10),
                              itemBuilder: (context, index) {
                                final user = users[index];
                                return _buildLeaderboardTile(context, user);
                              },
                            ),
                          ],
                        ),
                      ),

                      // 🌟 Floating Bar Posisi Pengguna Saat Ini
                      if (myData != null)
                        Positioned(
                          left: 0,
                          right: 0,
                          bottom: 0,
                          child: _buildCurrentUserFloatingBar(myData, users),
                        ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ===================== WIDGET COMPONENTS =====================

  /// App Bar dengan Tema Warna Nimexx (Orange - Emas - Merah)
  Widget _buildAppBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => Navigator.pop(context),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white12),
                ),
                child: const Icon(
                  Icons.arrow_back_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'PAPAN PERINGKAT ELITE',
                  style: GoogleFonts.oswald(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 1.2,
                  ),
                ),
                Text(
                  'Kompetisi Level & Badge Pengguna Nimexx',
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFFFFB74D),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Section "The Big 3" Podium dengan palet oranye-emas-merah
  Widget _buildTheBig3Podium(List<LeaderboardUser> users) {
    final rank1 = users[0];
    final rank2 = users[1];
    final rank3 = users[2];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF74150D), // Merah Crimson nyata & jelas
            Color(0xFF5A1C08), // Merah Oranye Membara
            Color(0xFF3E2205), // Kuning Emas Amber hangat
            Color(0xFF221203), // Emas Gelap Obsidian
          ],
          stops: [0.0, 0.35, 0.7, 1.0],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: const Color(0xFFFF9800).withValues(alpha: 0.55),
          width: 1.4,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFF3D00).withValues(alpha: 0.35),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: const Color(0xFFFFB300).withValues(alpha: 0.18),
            blurRadius: 16,
            spreadRadius: -2,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Crown + Title
          Row(
            children: [
              const Text('👑', style: TextStyle(fontSize: 18)),
              const SizedBox(width: 8),
              Text(
                '3 BESAR JAWARA (THE BIG 3)',
                style: GoogleFonts.oswald(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFFFFD54F),
                  letterSpacing: 1.1,
                ),
              ),
            ],
          ),

          const SizedBox(height: 18),

          // Tiga Podium Column (Rank 2 kiri, Rank 1 tengah, Rank 3 kanan)
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // 🥈 Rank 2 (Kiri)
              Expanded(
                child: _buildPodiumUserItem(
                  user: rank2,
                  rankBadgeNumber: 2,
                  avatarRadius: 32,
                  borderColor: const Color(0xFFCFD8DC),
                  isCenterTop: false,
                ),
              ),

              // 🥇 Rank 1 (Tengah & Terangkat)
              Expanded(
                child: _buildPodiumUserItem(
                  user: rank1,
                  rankBadgeNumber: 1,
                  avatarRadius: 40,
                  borderColor: const Color(0xFFFFD700),
                  isCenterTop: true,
                ),
              ),

              // 🥉 Rank 3 (Kanan)
              Expanded(
                child: _buildPodiumUserItem(
                  user: rank3,
                  rankBadgeNumber: 3,
                  avatarRadius: 32,
                  borderColor: const Color(0xFFFF8A65),
                  isCenterTop: false,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Komponen Tiap Avatar di Podium dengan RankBadgeWidget Asli
  Widget _buildPodiumUserItem({
    required LeaderboardUser user,
    required int rankBadgeNumber,
    required double avatarRadius,
    required Color borderColor,
    required bool isCenterTop,
  }) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => PublicProfilePage(userId: user.uid),
          ),
        );
      },
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Mahkota untuk Juara 1
          if (isCenterTop)
            Container(
              margin: const EdgeInsets.only(bottom: 6),
              child: const Text('👑', style: TextStyle(fontSize: 26)),
            )
          else
            const SizedBox(height: 16),

          // Stack Avatar + Ring + Badge Nomor
          Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              // Outer Halo Glow
              Container(
                width: (avatarRadius * 2) + (isCenterTop ? 34 : 12),
                height: (avatarRadius * 2) + (isCenterTop ? 34 : 12),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      borderColor.withValues(alpha: isCenterTop ? 0.65 : 0.45),
                      borderColor.withValues(alpha: 0.0),
                    ],
                  ),
                ),
              ),

              // Avatar Pengguna Bergaya Akun Google (Foto Profil Asli / Inisial Huruf Google)
              UserAvatarWidget(
                photoUrl: user.photoUrl,
                displayName: user.displayName,
                radius: avatarRadius,
                border: Border.all(color: borderColor, width: 2.2),
                boxShadow: [
                  BoxShadow(
                    color: borderColor.withValues(alpha: 0.35),
                    blurRadius: 10,
                    spreadRadius: 1,
                  ),
                ],
              ),

              // Pin Nomor Badge (#1, #2, #3)
              Positioned(
                bottom: -2,
                right: isCenterTop ? 2 : 0,
                child: Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    color: borderColor,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.black, width: 1.5),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.6),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '$rankBadgeNumber',
                    style: GoogleFonts.outfit(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w900,
                      color: Colors.black,
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // Nama Pengguna
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              user.displayName,
              style: GoogleFonts.outfit(
                fontSize: isCenterTop ? 13.5 : 12,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
          ),

          const SizedBox(height: 3),

          // Usia Akun Realtime (Format Bulan Sesuai Profil)
          Text(
            user.accountAge,
            style: GoogleFonts.outfit(
              fontSize: isCenterTop ? 12 : 11,
              fontWeight: FontWeight.w700,
              color: const Color(0xFFFFB74D),
            ),
          ),

          const SizedBox(height: 6),

          // 🛡️ IMPLEMENTASI LEVEL BADGE RESMI PROJEK (RankBadgeWidget)
          RankBadgeWidget(
            rankCode: user.rankCode,
            level: user.level,
            compact: true,
          ),
        ],
      ),
    );
  }

  /// Tile Peringkat Pengguna Murni Database Realtime
  Widget _buildLeaderboardTile(BuildContext context, LeaderboardUser user) {
    final rankColor = user.rankColor;
    final isMe = user.isCurrentUser;
    final rankTier = RankService.getRankForLevel(user.level);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => PublicProfilePage(userId: user.uid),
            ),
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: isMe
                ? const Color(0xFF38150A)
                : (user.rankNumber == 1
                    ? const Color(0xFF24140A)
                    : (user.rankNumber <= 3
                        ? const Color(0xFF1E120D)
                        : const Color(0xFF14151D))),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isMe
                  ? const Color(0xFFFF5E1E)
                  : (user.rankNumber <= 3
                      ? rankColor.withValues(alpha: 0.55)
                      : Colors.white.withValues(alpha: 0.06)),
              width: isMe || user.rankNumber <= 3 ? 1.4 : 1.0,
            ),
            boxShadow: [
              BoxShadow(
                color: user.rankNumber <= 3
                    ? rankColor.withValues(alpha: 0.15)
                    : Colors.black.withValues(alpha: 0.35),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // 1. Nomor Peringkat (#1, #2, #3, ...)
              SizedBox(
                width: 32,
                child: Text(
                  '#${user.rankNumber}',
                  style: GoogleFonts.outfit(
                    fontSize: user.rankNumber <= 3 ? 15.5 : 13.5,
                    fontWeight: FontWeight.w900,
                    color: rankColor,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),

              const SizedBox(width: 8),

              // 2. Avatar Pengguna Bergaya Akun Google (Foto Profil Asli / Inisial Huruf Google)
              UserAvatarWidget(
                photoUrl: user.photoUrl,
                displayName: user.displayName,
                radius: 20,
                border: Border.all(
                  color: user.rankNumber <= 3
                      ? rankColor.withValues(alpha: 0.8)
                      : Colors.white24,
                  width: 1.2,
                ),
              ),

              const SizedBox(width: 12),

              // 3. Kolom Detail Nama + Badge Level Resmi Projek
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Baris Nama Pengguna + Tag Anda
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            user.displayName,
                            style: GoogleFonts.outfit(
                              fontSize: 14.5,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (isMe) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 1.5,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFF5722).withValues(alpha: 0.25),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'Kamu',
                              style: GoogleFonts.outfit(
                                fontSize: 9.5,
                                fontWeight: FontWeight.w800,
                                color: const Color(0xFFFF7043),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),

                    const SizedBox(height: 6),

                    // Baris Badges: [RankBadgeWidget Resmi Projek] [Usia Akun Bulan]
                    Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        // 🛡️ LEVEL BADGE RESMI PROJEK
                        RankBadgeWidget(
                          rankCode: user.rankCode,
                          level: user.level,
                          compact: true,
                        ),

                        // Usia Akun Bulan (Sinkron dengan Profil)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.1),
                            ),
                          ),
                          child: Text(
                            user.accountAge,
                            style: GoogleFonts.outfit(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: Colors.white70,
                            ),
                          ),
                        ),

                        // Gelar Rank
                        Text(
                          rankTier.title,
                          style: GoogleFonts.outfit(
                            fontSize: 10,
                            color: const Color(0xFFFFB74D),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 8),

              // 4. Highlight Total EXP di Sebelah Kanan (Kuning Emas)
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${LeaderboardUser.formatNumber(user.totalExp)} EXP',
                    style: GoogleFonts.outfit(
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                      color: const Color(0xFFFFD54F),
                    ),
                  ),
                  Text(
                    'Level ${user.level}',
                    style: GoogleFonts.outfit(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Colors.white54,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Floating Bar Bagian Bawah untuk Posisi Pengguna Saat Ini
  Widget _buildCurrentUserFloatingBar(
    LeaderboardUser myData,
    List<LeaderboardUser> users,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1E0E07),
        border: Border(
          top: BorderSide(
            color: const Color(0xFFFF5E1E).withValues(alpha: 0.4),
            width: 1.2,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.7),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            UserAvatarWidget(
              photoUrl: myData.photoUrl,
              displayName: myData.displayName,
              radius: 18,
              border: Border.all(
                color: const Color(0xFFFF5E1E),
                width: 1.2,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        'Peringkat Kamu: ',
                        style: GoogleFonts.outfit(
                          fontSize: 13,
                          color: Colors.white70,
                        ),
                      ),
                      Text(
                        '#${myData.rankNumber}',
                        style: GoogleFonts.outfit(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w900,
                          color: const Color(0xFFFFD54F),
                        ),
                      ),
                    ],
                  ),
                  Text(
                    'Level ${myData.level} • ${LeaderboardUser.formatNumber(myData.totalExp)} EXP',
                    style: GoogleFonts.outfit(
                      fontSize: 11.5,
                      color: const Color(0xFFFFB74D),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            ElevatedButton.icon(
              onPressed: () => _scrollToCurrentUser(users),
              icon: const Icon(Icons.my_location_rounded, size: 14),
              label: const Text('Posisi Saya'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF5722),
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                textStyle: GoogleFonts.outfit(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
