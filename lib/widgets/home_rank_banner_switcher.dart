import 'dart:async';
import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/leaderboard_user.dart';
import '../service/leaderboard_service.dart';
import '../widgets/rank_badge_widget.dart';
import '../widgets/user_avatar_widget.dart';
import '../pages/leaderboard_page.dart';

class HomeRankBannerSwitcher extends StatefulWidget {
  const HomeRankBannerSwitcher({super.key});

  @override
  State<HomeRankBannerSwitcher> createState() => _HomeRankBannerSwitcherState();
}

class _HomeRankBannerSwitcherState extends State<HomeRankBannerSwitcher>
    with SingleTickerProviderStateMixin {
  final LeaderboardService _leaderboardService = LeaderboardService();

  int _currentIndex = 0; // 0 = Banner Kalimat, 1 = Card Peringkat
  int _targetIndex = 0;
  bool _isTransitioning = false;

  Timer? _autoCycleTimer;
  late AnimationController _burnController;

  StreamSubscription<List<LeaderboardUser>>? _streamSubscription;
  List<LeaderboardUser> _topUsers = [];
  bool _isLoadingUsers = true;

  @override
  void initState() {
    super.initState();

    _burnController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1050),
    );

    _burnController.addListener(() {
      // Di pertengahan transisi (50%), ganti elemen yang ditampilkan
      if (_burnController.value >= 0.5 && _currentIndex != _targetIndex) {
        setState(() {
          _currentIndex = _targetIndex;
        });
      }
    });

    _burnController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        setState(() {
          _isTransitioning = false;
        });
        _burnController.reset();
      }
    });

    _initLeaderboardStream();
    _startAutoCycle();
  }

  @override
  void dispose() {
    _streamSubscription?.cancel();
    _autoCycleTimer?.cancel();
    _burnController.dispose();
    super.dispose();
  }

  void _initLeaderboardStream() {
    _streamSubscription = _leaderboardService.getLeaderboardStream(limit: 10).listen((users) {
      if (mounted) {
        setState(() {
          _topUsers = users;
          _isLoadingUsers = false;
        });
      }
    });
  }

  void _startAutoCycle() {
    _autoCycleTimer?.cancel();
    _autoCycleTimer = Timer.periodic(const Duration(seconds: 8), (_) {
      if (!mounted || _isTransitioning) return;
      _triggerSwitch((_currentIndex + 1) % 2);
    });
  }

  void _pauseAutoCycle() {
    _autoCycleTimer?.cancel();
  }

  void _resumeAutoCycle() {
    _startAutoCycle();
  }

  void _triggerSwitch(int nextIndex) {
    if (_isTransitioning || nextIndex == _currentIndex) return;

    setState(() {
      _targetIndex = nextIndex;
      _isTransitioning = true;
    });

    _burnController.forward(from: 0.0);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // 🌟 Area Elemen Utama (Banner <-> Leaderboard dengan Efek Terbakar Blur Redup)
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: GestureDetector(
                onHorizontalDragEnd: (details) {
                  if (details.primaryVelocity != null) {
                    if (details.primaryVelocity! < 0) {
                      _triggerSwitch((_currentIndex + 1) % 2);
                    } else if (details.primaryVelocity! > 0) {
                      _triggerSwitch((_currentIndex - 1 + 2) % 2);
                    }
                  }
                },
                onTapDown: (_) => _pauseAutoCycle(),
                onTapUp: (_) => _resumeAutoCycle(),
                onTapCancel: () => _resumeAutoCycle(),
                child: AnimatedBuilder(
                  animation: _burnController,
                  builder: (context, _) {
                    final progress = _burnController.value;

                    // Kurva intensitas efek: memuncak di nilai 0.5 (tengah)
                    final peakIntensity = 1.0 - (2.0 * (progress - 0.5).abs());
                    final safeIntensity = peakIntensity.clamp(0.0, 1.0);

                    // 1. Redup (Dimming effect)
                    final dimOpacity = safeIntensity * 0.45;

                    // 2. Blur sigma (Mencapai 10.0 saat terbakar)
                    final blurSigma = safeIntensity * 9.5;

                    // 3. Efek Scale bernapas (0.97 saat di tengah transisi)
                    final scale = 1.0 - (safeIntensity * 0.035);

                    return Transform.scale(
                      scale: scale,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(22),
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            // 🔹 Tampilan Elemen Aktif (Banner atau Leaderboard)
                            ImageFiltered(
                              imageFilter: ImageFilter.blur(
                                sigmaX: blurSigma,
                                sigmaY: blurSigma,
                                tileMode: TileMode.clamp,
                              ),
                              child: _currentIndex == 0
                                  ? _buildQuoteBanner()
                                  : _buildLeaderboardPreviewCard(),
                            ),

                            // 🔹 Overlay Redup / Vignette Gelap Saat Terbakar
                            if (_isTransitioning)
                              Positioned.fill(
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.black.withValues(alpha: dimOpacity),
                                  ),
                                ),
                              ),

                            // 🔥 Efek Terbakar & Percikan Api (Fiery Ember & Heat Distortion)
                            if (_isTransitioning)
                              Positioned.fill(
                                child: CustomPaint(
                                  painter: _FireEmberPainter(
                                    intensity: safeIntensity,
                                    progress: progress,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ),

        const SizedBox(height: 10),

        // 🔘 Indikator Titik (Pagination Dots ● ○)
        _buildDotIndicators(),
      ],
    );
  }

  // ===================== ELEMEN 0: BANNER KUTIPAN ASLI =====================

  Widget _buildQuoteBanner() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFF1100), Color(0xFFFF8800)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.18),
          width: 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFF7B00).withValues(alpha: 0.35),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          // Logo Nimexx
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: Container(
              color: Colors.black12,
              child: Image.asset(
                'assets/images/logo.png',
                height: 52,
                width: 52,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const Icon(
                  Icons.play_circle_fill_rounded,
                  size: 40,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),

          // Teks Motivasi & Kutipan
          const Expanded(
            child: Text(
              'Duduk santai, siapkan camilan, dan mari tenggelam dalam dunia anime kesayanganmu!',
              style: TextStyle(
                fontSize: 14.5,
                fontWeight: FontWeight.w600,
                color: Colors.white,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ===================== ELEMEN 1: KARTU LEADERBOARD HOME (ORANGE-GOLD-RED) =====================

  Widget _buildLeaderboardPreviewCard() {
    final top1 = _topUsers.isNotEmpty ? _topUsers[0] : null;
    final top2 = _topUsers.length > 1 ? _topUsers[1] : null;
    final top3 = _topUsers.length > 2 ? _topUsers[2] : null;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const LeaderboardPage()),
        );
      },
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: const Color(0xFFFF9800).withValues(alpha: 0.55),
            width: 1.4,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFFF3D00).withValues(alpha: 0.32),
              blurRadius: 20,
              offset: const Offset(0, 6),
            ),
            BoxShadow(
              color: const Color(0xFFFFB300).withValues(alpha: 0.16),
              blurRadius: 14,
              spreadRadius: -2,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 🔹 Baris Header: "👑 PAPAN PERINGKAT LEVEL"
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('👑', style: TextStyle(fontSize: 15)),
                const SizedBox(width: 6),
                Text(
                  'PAPAN PERINGKAT LEVEL',
                  style: GoogleFonts.oswald(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFFFFD54F),
                    letterSpacing: 1.0,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 10),

            // 🔹 Tampilan Podium Top 3 di Tengah Card
            if (_isLoadingUsers)
              const SizedBox(
                height: 90,
                child: Center(
                  child: CircularProgressIndicator(
                    color: Color(0xFFFF5722),
                    strokeWidth: 2,
                  ),
                ),
              )
            else if (_topUsers.isEmpty)
              const SizedBox(
                height: 80,
                child: Center(
                  child: Text(
                    'Belum ada pengguna terdaftar.',
                    style: TextStyle(color: Colors.white54, fontSize: 13),
                  ),
                ),
              )
            else ...[
              Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    // Rank 2 (Kiri)
                    if (top2 != null)
                      _buildMiniPodiumAvatar(
                        user: top2,
                        rankNum: 2,
                        radius: 20,
                        borderColor: const Color(0xFFCFD8DC),
                        isCenter: false,
                      ),

                    const SizedBox(width: 14),

                    // Rank 1 (Tengah Lebih Besar)
                    if (top1 != null)
                      _buildMiniPodiumAvatar(
                        user: top1,
                        rankNum: 1,
                        radius: 26,
                        borderColor: const Color(0xFFFFD700),
                        isCenter: true,
                      ),

                    const SizedBox(width: 14),

                    // Rank 3 (Kanan)
                    if (top3 != null)
                      _buildMiniPodiumAvatar(
                        user: top3,
                        rankNum: 3,
                        radius: 20,
                        borderColor: const Color(0xFFFF8A65),
                        isCenter: false,
                      ),
                  ],
                ),
              ),

              const SizedBox(height: 10),

              // 🔹 Baris Ringkasan Peringkat (Rank 1 & Rank 2)
              if (top1 != null) _buildMiniRankRow(top1, 1),
              const SizedBox(height: 4),
              if (top2 != null) _buildMiniRankRow(top2, 2),

              const SizedBox(height: 6),

              // 🔹 Baris Bawah Mini (Rank 3, 4, 5 dalam Pill Horizontal)
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                child: Row(
                  children: [
                    if (top3 != null) _buildHorizontalRankChip(top3, 3),
                    if (_topUsers.length > 3)
                      _buildHorizontalRankChip(_topUsers[3], 4),
                    if (_topUsers.length > 4)
                      _buildHorizontalRankChip(_topUsers[4], 5),
                    const SizedBox(width: 4),
                    // Tombol Lihat Semua
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFFF3D00), Color(0xFFFF8800)],
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Lihat Top 100',
                            style: GoogleFonts.outfit(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 2),
                          const Icon(
                            Icons.arrow_forward_ios_rounded,
                            size: 8,
                            color: Colors.white,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Avatar Mini untuk Podium di Kartu Beranda
  Widget _buildMiniPodiumAvatar({
    required LeaderboardUser user,
    required int rankNum,
    required double radius,
    required Color borderColor,
    required bool isCenter,
  }) {
    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.center,
      children: [
        // Avatar Bulat Bergaya Akun Google
        UserAvatarWidget(
          photoUrl: user.photoUrl,
          displayName: user.displayName,
          radius: radius,
          border: Border.all(color: borderColor, width: isCenter ? 2.2 : 1.8),
          boxShadow: [
            BoxShadow(
              color: borderColor.withValues(alpha: isCenter ? 0.6 : 0.35),
              blurRadius: isCenter ? 12 : 8,
            ),
          ],
        ),

        // Pin Mahkota Kecil untuk Juara 1
        if (isCenter)
          const Positioned(
            top: -12,
            child: Text('👑', style: TextStyle(fontSize: 14)),
          ),

        // Pin Angka (1, 2, 3)
        Positioned(
          bottom: -2,
          right: -2,
          child: Container(
            width: 16,
            height: 16,
            decoration: BoxDecoration(
              color: borderColor,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.black, width: 1.2),
            ),
            alignment: Alignment.center,
            child: Text(
              '$rankNum',
              style: GoogleFonts.outfit(
                fontSize: 9.5,
                fontWeight: FontWeight.w900,
                color: Colors.black,
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Baris Ringkas Peringkat #1 dan #2 dengan Badge Resmi
  Widget _buildMiniRankRow(LeaderboardUser user, int rankNum) {
    final rankColor = user.rankColor;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFF30140A).withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: const Color(0xFFFF7043).withValues(alpha: 0.25),
        ),
      ),
      child: Row(
        children: [
          Text(
            '#$rankNum',
            style: GoogleFonts.outfit(
              fontSize: 12,
              fontWeight: FontWeight.w900,
              color: rankColor,
            ),
          ),
          const SizedBox(width: 8),
          UserAvatarWidget(
            photoUrl: user.photoUrl,
            displayName: user.displayName,
            radius: 11,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Row(
              children: [
                Flexible(
                  child: Text(
                    user.displayName,
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 6),
                // Badge Level Resmi Compact
                RankBadgeWidget(
                  rankCode: user.rankCode,
                  level: user.level,
                  compact: true,
                ),
              ],
            ),
          ),
          Text(
            '${LeaderboardUser.formatNumber(user.totalExp)} EXP',
            style: GoogleFonts.outfit(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: const Color(0xFFFFD54F),
            ),
          ),
        ],
      ),
    );
  }

  /// Chip Horizontal untuk Peringkat #3, #4, #5
  Widget _buildHorizontalRankChip(LeaderboardUser user, int rankNum) {
    return Container(
      margin: const EdgeInsets.only(right: 6),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0xFF30140A),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: const Color(0xFFFF7043).withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '#$rankNum',
            style: GoogleFonts.outfit(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              color: user.rankColor,
            ),
          ),
          const SizedBox(width: 5),
          UserAvatarWidget(
            photoUrl: user.photoUrl,
            displayName: user.displayName,
            radius: 8,
          ),
          const SizedBox(width: 5),
          Text(
            user.displayName.length > 8
                ? '${user.displayName.substring(0, 8)}..'
                : user.displayName,
            style: GoogleFonts.outfit(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: Colors.white70,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            'Lv.${user.level}',
            style: GoogleFonts.outfit(
              fontSize: 9.5,
              fontWeight: FontWeight.w800,
              color: const Color(0xFFFFB74D),
            ),
          ),
        ],
      ),
    );
  }

  // ===================== INDIKATOR TITIK (● ○) =====================

  Widget _buildDotIndicators() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildSingleDot(0),
        const SizedBox(width: 8),
        _buildSingleDot(1),
      ],
    );
  }

  Widget _buildSingleDot(int index) {
    final isActive = _currentIndex == index;
    final activeColor = index == 0
        ? const Color(0xFFFF5722) // Merah-Oranye untuk Banner
        : const Color(0xFFFFB300); // Kuning Emas untuk Peringkat

    return GestureDetector(
      onTap: () => _triggerSwitch(index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
        width: isActive ? 20 : 8,
        height: 8,
        decoration: BoxDecoration(
          color: isActive ? activeColor : Colors.white24,
          borderRadius: BorderRadius.circular(4),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: activeColor.withValues(alpha: 0.5),
                    blurRadius: 8,
                    spreadRadius: 1,
                  ),
                ]
              : null,
        ),
      ),
    );
  }
}

/// Painter kustom untuk menggambar kilatan bara api & gelombang terbakar
class _FireEmberPainter extends CustomPainter {
  final double intensity;
  final double progress;

  _FireEmberPainter({
    required this.intensity,
    required this.progress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (intensity <= 0.01) return;

    final rect = Offset.zero & size;

    // 1. Sapuan Gelombang Api Membara (Fire Glow Sweep)
    final sweepCenter = size.width * progress;
    final flamePaint = Paint()
      ..shader = LinearGradient(
        colors: [
          Colors.transparent,
          const Color(0xFFFF3D00).withValues(alpha: intensity * 0.45),
          const Color(0xFFFF9100).withValues(alpha: intensity * 0.75),
          const Color(0xFFFFEA00).withValues(alpha: intensity * 0.65),
          const Color(0xFFFF3D00).withValues(alpha: intensity * 0.4),
          Colors.transparent,
        ],
        stops: const [0.0, 0.25, 0.5, 0.75, 0.9, 1.0],
      ).createShader(
        Rect.fromLTWH(
          sweepCenter - (size.width * 0.7),
          0,
          size.width * 1.4,
          size.height,
        ),
      )
      ..blendMode = BlendMode.screen;

    canvas.drawRect(rect, flamePaint);

    // 2. Percikan Partikel Bara (Fiery Sparks / Embers)
    final random = Random(42);
    final sparkPaint = Paint()..style = PaintingStyle.fill;

    for (int i = 0; i < 28; i++) {
      final sparkX = random.nextDouble() * size.width;
      final initialY = random.nextDouble() * size.height;
      final sparkY = (initialY - (progress * size.height * 0.5)) % size.height;
      final radius = (random.nextDouble() * 2.5 + 1.0) * intensity;
      final sparkColor = i % 3 == 0
          ? const Color(0xFFFFEA00)
          : (i % 3 == 1 ? const Color(0xFFFF9100) : const Color(0xFFFF3D00));

      sparkPaint.color = sparkColor.withValues(
        alpha: (random.nextDouble() * 0.7 + 0.3) * intensity,
      );

      canvas.drawCircle(Offset(sparkX, sparkY), radius, sparkPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _FireEmberPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.intensity != intensity;
  }
}
