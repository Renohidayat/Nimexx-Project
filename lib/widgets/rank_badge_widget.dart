// widgets/rank_badge_widget.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../service/rank_service.dart';

/// Palet material & pencahayaan metalik premium untuk setiap tingkatan rank
class RankVisualTheme {
  final List<Color> rimGradient;
  final List<Color> coreGradient;
  final Color primaryGlow;
  final Color secondaryGlow;
  final Color textColor;
  final Color gemColor;
  final Color levelBgColor;
  final double glowBlur;
  final double glowSpread;
  final bool hasShimmer;
  final String insigniaName;

  const RankVisualTheme({
    required this.rimGradient,
    required this.coreGradient,
    required this.primaryGlow,
    required this.secondaryGlow,
    required this.textColor,
    required this.gemColor,
    required this.levelBgColor,
    required this.glowBlur,
    required this.glowSpread,
    required this.hasShimmer,
    required this.insigniaName,
  });

  static RankVisualTheme getTheme(String? rankCode) {
    switch (rankCode?.toUpperCase()) {
      case 'D': // Bronze / Copper Scout
        return const RankVisualTheme(
          rimGradient: [Color(0xFFFFCC80), Color(0xFFFF7043), Color(0xFFD84315), Color(0xFFBF360C)],
          coreGradient: [Color(0xFF4A2011), Color(0xFF261008)],
          primaryGlow: Color(0xFFFF7043),
          secondaryGlow: Color(0xFFD84315),
          textColor: Color(0xFFFFE0B2),
          gemColor: Color(0xFFFFB74D),
          levelBgColor: Color(0xFF3E180A),
          glowBlur: 12.0,
          glowSpread: 1.2,
          hasShimmer: false,
          insigniaName: 'BRONZE SCOUT',
        );
      case 'C': // Silver / Ice Cyan Fighter
        return const RankVisualTheme(
          rimGradient: [Color(0xFFFFFFFF), Color(0xFF80DEEA), Color(0xFF4DD0E1), Color(0xFF00ACC1), Color(0xFFFFFFFF)],
          coreGradient: [Color(0xFF0F3B44), Color(0xFF072025)],
          primaryGlow: Color(0xFF26C6DA),
          secondaryGlow: Color(0xFF00ACC1),
          textColor: Color(0xFFE0F7FA),
          gemColor: Color(0xFF4DD0E1),
          levelBgColor: Color(0xFF09292F),
          glowBlur: 14.0,
          glowSpread: 1.4,
          hasShimmer: false,
          insigniaName: 'SILVER FIGHTER',
        );
      case 'B': // 24K Liquid Gold Knight
        return const RankVisualTheme(
          rimGradient: [Color(0xFFFFF9C4), Color(0xFFFFD54F), Color(0xFFFFB300), Color(0xFFFF8F00), Color(0xFFFFD54F)],
          coreGradient: [Color(0xFF5A3906), Color(0xFF2D1B00)],
          primaryGlow: Color(0xFFFFC107),
          secondaryGlow: Color(0xFFFF8F00),
          textColor: Color(0xFFFFF8E1),
          gemColor: Color(0xFFFFD54F),
          levelBgColor: Color(0xFF462A02),
          glowBlur: 16.0,
          glowSpread: 1.8,
          hasShimmer: true,
          insigniaName: 'SOLAR GOLD KNIGHT',
        );
      case 'A': // Diamond Prism & Electric Blue Elite
        return const RankVisualTheme(
          rimGradient: [Color(0xFFE0F7FA), Color(0xFF00E5FF), Color(0xFF0091EA), Color(0xFF80D8FF), Color(0xFFFFFFFF)],
          coreGradient: [Color(0xFF05455C), Color(0xFF02202C)],
          primaryGlow: Color(0xFF00E5FF),
          secondaryGlow: Color(0xFF0091EA),
          textColor: Color(0xFFE1F5FE),
          gemColor: Color(0xFF00E5FF),
          levelBgColor: Color(0xFF033547),
          glowBlur: 19.0,
          glowSpread: 2.0,
          hasShimmer: true,
          insigniaName: 'DIAMOND PRISM',
        );
      case 'S': // Blazing Ruby Crimson Dominator
        return const RankVisualTheme(
          rimGradient: [Color(0xFFFF8A80), Color(0xFFFF1744), Color(0xFFFFD700), Color(0xFFD50000), Color(0xFFFF5252)],
          coreGradient: [Color(0xFF6B0813), Color(0xFF330107)],
          primaryGlow: Color(0xFFFF1744),
          secondaryGlow: Color(0xFFFF5252),
          textColor: Color(0xFFFFEBEE),
          gemColor: Color(0xFFFF1744),
          levelBgColor: Color(0xFF52040C),
          glowBlur: 22.0,
          glowSpread: 2.5,
          hasShimmer: true,
          insigniaName: 'INFERNAL CRIMSON',
        );
      case 'SS': // Void Ultraviolet & Gold Warlord
        return const RankVisualTheme(
          rimGradient: [Color(0xFFFFD54F), Color(0xFFEA80FC), Color(0xFFE040FB), Color(0xFFAA00FF), Color(0xFF7C4DFF)],
          coreGradient: [Color(0xFF590C70), Color(0xFF270233)],
          primaryGlow: Color(0xFFE040FB),
          secondaryGlow: Color(0xFF7C4DFF),
          textColor: Color(0xFFF3E5F5),
          gemColor: Color(0xFFEA80FC),
          levelBgColor: Color(0xFF450657),
          glowBlur: 26.0,
          glowSpread: 2.8,
          hasShimmer: true,
          insigniaName: 'VOID ULTRAVIOLET',
        );
      case 'SSS': // Celestial Amethyst & Starlight Gold Sovereign
        return const RankVisualTheme(
          rimGradient: [Color(0xFFFFFFFF), Color(0xFFFFD54F), Color(0xFFE040FB), Color(0xFFFF6D00), Color(0xFFEA80FC), Color(0xFFFFFFFF)],
          coreGradient: [Color(0xFF521163), Color(0xFF593003), Color(0xFF1D0326)],
          primaryGlow: Color(0xFFFFD54F),
          secondaryGlow: Color(0xFFE040FB),
          textColor: Color(0xFFFFF8E1),
          gemColor: Color(0xFFFFD54F),
          levelBgColor: Color(0xFF491059),
          glowBlur: 30.0,
          glowSpread: 3.2,
          hasShimmer: true,
          insigniaName: 'CELESTIAL SOVEREIGN',
        );
      case 'MYTHIC': // Imperial Supernova Singularity Overlord
        return const RankVisualTheme(
          rimGradient: [Color(0xFFFFFFFF), Color(0xFFFFD700), Color(0xFFFF3D00), Color(0xFFE040FB), Color(0xFF00E5FF), Color(0xFFFFFFFF)],
          coreGradient: [Color(0xFF7A1305), Color(0xFF52075C), Color(0xFF190021)],
          primaryGlow: Color(0xFFFF3D00),
          secondaryGlow: Color(0xFFFFD700),
          textColor: Color(0xFFFFFFFF),
          gemColor: Color(0xFFFFD700),
          levelBgColor: Color(0xFF630B00),
          glowBlur: 35.0,
          glowSpread: 3.8,
          hasShimmer: true,
          insigniaName: 'DIVINE DRAGON OVERLORD',
        );
      case 'E': // Tactical Gunmetal Steel Hunter
      default:
        return const RankVisualTheme(
          rimGradient: [Color(0xFFCFD8DC), Color(0xFF78909C), Color(0xFF455A64), Color(0xFF37474F)],
          coreGradient: [Color(0xFF263238), Color(0xFF161D21)],
          primaryGlow: Color(0xFF78909C),
          secondaryGlow: Color(0xFF455A64),
          textColor: Color(0xFFECEFF1),
          gemColor: Color(0xFF90A4AE),
          levelBgColor: Color(0xFF1F292E),
          glowBlur: 8.0,
          glowSpread: 0.5,
          hasShimmer: false,
          insigniaName: 'BRONZE HUNTER',
        );
    }
  }
}

/// Widget Shimmer Glint Animasi untuk Rank Tinggi (S, SS, SSS, MYTHIC)
class ShimmerSheenWrapper extends StatefulWidget {
  final Widget child;
  final bool enabled;

  const ShimmerSheenWrapper({
    super.key,
    required this.child,
    this.enabled = true,
  });

  @override
  State<ShimmerSheenWrapper> createState() => _ShimmerSheenWrapperState();
}

class _ShimmerSheenWrapperState extends State<ShimmerSheenWrapper>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    );
    if (widget.enabled) {
      _controller.repeat();
    }
  }

  @override
  void didUpdateWidget(covariant ShimmerSheenWrapper oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.enabled && !_controller.isAnimating) {
      _controller.repeat();
    } else if (!widget.enabled && _controller.isAnimating) {
      _controller.stop();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled) return widget.child;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Stack(
          children: [
            child!,
            Positioned.fill(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: FractionallySizedBox(
                  widthFactor: 0.35,
                  alignment: Alignment(-2.0 + (4.0 * _controller.value), 0),
                  child: Transform.rotate(
                    angle: 0.35,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.transparent,
                            Colors.white.withOpacity(0.4),
                            Colors.white.withOpacity(0.7),
                            Colors.white.withOpacity(0.4),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
      child: widget.child,
    );
  }
}

/// BADGE UTAMA: Ultra-Luxury 3D Game UI Crest Badge (Single-Layer, Presisi, Berkilau, Mencolok)
class RankBadgeWidget extends StatelessWidget {
  final String? rankCode;
  final int level;
  final bool compact;
  final bool showLevel;
  final bool hero;

  const RankBadgeWidget({
    super.key,
    this.rankCode,
    this.level = 1,
    this.compact = false,
    this.showLevel = true,
    this.hero = false,
  });

  @override
  Widget build(BuildContext context) {
    final rank = RankService.getRankByCode(rankCode);
    final theme = RankVisualTheme.getTheme(rank.code);

    // Dimensi responsif: Hero (Profil), Standard (Kartu), Compact (Komentar)
    final double crestSize = hero ? 48.0 : (compact ? 16.0 : 22.0);
    final double fontSize = hero ? 15.5 : (compact ? 10.0 : 12.0);
    final double levelFontSize = hero ? 13.0 : (compact ? 9.5 : 11.0);
    final double verticalPadding = hero ? 6.0 : (compact ? 3.0 : 4.0);
    final double horizontalPadding = hero ? 14.0 : (compact ? 7.0 : 9.0);
    final double borderRadius = hero ? 24.0 : (compact ? 12.0 : 16.0);
    final double crestRadius = hero ? 10.0 : (compact ? 4.0 : 6.0);

    return ShimmerSheenWrapper(
      enabled: theme.hasShimmer,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: horizontalPadding,
          vertical: verticalPadding,
        ),
        decoration: BoxDecoration(
          // 1 Lapis Background Bersih & Mewah (Tanpa Nesting/Lapis Ganda Slop)
          color: const Color(0xFF11131C),
          borderRadius: BorderRadius.circular(borderRadius),
          border: Border.all(
            color: theme.primaryGlow.withOpacity(hero ? 0.65 : 0.45),
            width: hero ? 1.5 : 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: theme.primaryGlow.withOpacity(compact ? 0.25 : (hero ? 0.45 : 0.35)),
              blurRadius: hero ? theme.glowBlur : (compact ? 6.0 : 10.0),
              spreadRadius: hero ? theme.glowSpread * 0.8 : (compact ? 0.5 : 1.0),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Ikon 3D Badge Crest Asli (Besar, Jelas, Bebas Tanpa Bingkai Bertumpuk)
            ClipRRect(
              borderRadius: BorderRadius.circular(crestRadius),
              child: Image.asset(
                rank.assetImage,
                width: crestSize,
                height: crestSize,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Icon(
                  Icons.shield_rounded,
                  size: crestSize * 0.85,
                  color: theme.primaryGlow,
                ),
              ),
            ),
            SizedBox(width: hero ? 10 : (compact ? 5 : 6)),

            // Huruf Rank (Chiseled Typography)
            Text(
              rank.code,
              style: GoogleFonts.cinzel(
                color: theme.textColor,
                fontSize: fontSize,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.8,
                shadows: [
                  Shadow(
                    color: theme.primaryGlow.withOpacity(0.8),
                    blurRadius: hero ? 8 : 4,
                  ),
                ],
              ),
            ),

            // Level Terintegrasi dalam 1 Kapsul Bersih (Kompak, Tidak Melar/Panjang)
            if (showLevel) ...[
              Container(
                margin: EdgeInsets.symmetric(horizontal: hero ? 8 : (compact ? 4 : 5)),
                width: 1,
                height: hero ? 18 : (compact ? 10 : 13),
                color: Colors.white24,
              ),
              Icon(
                Icons.bolt_rounded,
                size: hero ? 15 : (compact ? 10 : 12),
                color: theme.primaryGlow,
              ),
              const SizedBox(width: 1),
              Text(
                'Lv.$level',
                style: GoogleFonts.outfit(
                  color: Colors.white,
                  fontSize: levelFontSize,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Header Komentar Format Lengkap: [Logo_Badge_Rank] [Teks_Level] [Nama_User]
class CommentUserRankHeader extends StatelessWidget {
  final String username;
  final String? rankCode;
  final int level;
  final VoidCallback? onUserTap;

  const CommentUserRankHeader({
    super.key,
    required this.username,
    this.rankCode,
    this.level = 1,
    this.onUserTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onUserTap,
      behavior: HitTestBehavior.opaque,
      child: Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 6,
        runSpacing: 4,
        children: [
          // Logo Badge Rank & Level (Micro Esports Trophy Crest)
          RankBadgeWidget(
            rankCode: rankCode,
            level: level,
            compact: true,
          ),

          // Nama Pengguna
          Text(
            '@$username',
            style: GoogleFonts.outfit(
              fontSize: 12.5,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

/// Modal BottomSheet Interaktif untuk Menampilkan Tingkatan Rank & Klaim Badge
class RankOverviewBottomSheet extends StatefulWidget {
  final String uid;
  final int currentLevel;
  final int currentExp;
  final String currentActiveBadge;
  final List<dynamic> unlockedBadges;
  final VoidCallback? onBadgeChanged;

  const RankOverviewBottomSheet({
    super.key,
    required this.uid,
    required this.currentLevel,
    required this.currentExp,
    required this.currentActiveBadge,
    required this.unlockedBadges,
    this.onBadgeChanged,
  });

  static void show(
    BuildContext context, {
    required String uid,
    required int currentLevel,
    required int currentExp,
    required String currentActiveBadge,
    required List<dynamic> unlockedBadges,
    VoidCallback? onBadgeChanged,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => RankOverviewBottomSheet(
        uid: uid,
        currentLevel: currentLevel,
        currentExp: currentExp,
        currentActiveBadge: currentActiveBadge,
        unlockedBadges: unlockedBadges,
        onBadgeChanged: onBadgeChanged,
      ),
    );
  }

  @override
  State<RankOverviewBottomSheet> createState() => _RankOverviewBottomSheetState();
}

class _RankOverviewBottomSheetState extends State<RankOverviewBottomSheet> {
  late String _activeBadge;
  late List<dynamic> _unlockedBadges;
  late int _currentLevel;
  late int _currentExp;
  bool _isProcessing = false;
  bool _isSyncing = false;

  @override
  void initState() {
    super.initState();
    _activeBadge = widget.currentActiveBadge;
    _unlockedBadges = List.from(widget.unlockedBadges);
    _currentLevel = widget.currentLevel;
    _currentExp = widget.currentExp;
  }

  Future<void> _handleHistoricalSync() async {
    setState(() => _isSyncing = true);
    try {
      final res = await RankService().syncUserHistoricalExp(widget.uid, force: true);
      if (mounted) {
        final success = res['success'] as bool? ?? false;
        final msg = res['message'] as String? ?? 'Sinkronisasi selesai';
        if (success) {
          setState(() {
            _currentLevel = res['level'] as int? ?? _currentLevel;
            _currentExp = res['exp'] as int? ?? _currentExp;
            if (res['badgeCode'] != null) {
              _activeBadge = res['badgeCode'] as String;
            }
            for (final rank in RankService.allRanks) {
              if (_currentLevel >= rank.minLevel && !_unlockedBadges.contains(rank.code)) {
                _unlockedBadges.add(rank.code);
              }
            }
          });
        }
        setState(() => _isSyncing = false);
        widget.onBadgeChanged?.call();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(msg),
            backgroundColor: success ? const Color(0xFFFF5E1E) : Colors.redAccent,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSyncing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal: $e'), backgroundColor: Colors.redAccent),
        );
      }
    }
  }

  Future<void> _handleClaim(RankTier rank) async {
    setState(() => _isProcessing = true);
    try {
      await RankService().claimBadge(widget.uid, rank.code);
      if (mounted) {
        setState(() {
          if (!_unlockedBadges.contains(rank.code)) {
            _unlockedBadges.add(rank.code);
          }
          _activeBadge = rank.code;
          _isProcessing = false;
        });
        widget.onBadgeChanged?.call();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Selamat! Badge ${rank.badgeName} berhasil diklaim & dipasang!'),
            backgroundColor: const Color(0xFFFF5E1E),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isProcessing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: Colors.redAccent),
        );
      }
    }
  }

  Future<void> _handleEquip(RankTier rank) async {
    setState(() => _isProcessing = true);
    try {
      await RankService().setActiveBadge(widget.uid, rank.code);
      if (mounted) {
        setState(() {
          _activeBadge = rank.code;
          _isProcessing = false;
        });
        widget.onBadgeChanged?.call();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Badge aktif diubah ke ${rank.badgeName}'),
            backgroundColor: const Color(0xFFFF5E1E),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final expNeeded = RankService.getExpForNextLevel(_currentLevel);
    final progress = (_currentExp / expNeeded).clamp(0.0, 1.0);
    final currentRank = RankService.getRankForLevel(_currentLevel);
    final currentTheme = RankVisualTheme.getTheme(currentRank.code);

    return Container(
      height: MediaQuery.of(context).size.height * 0.88,
      decoration: const BoxDecoration(
        color: Color(0xFF07080B),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        children: [
          // Drag indicator
          Container(
            width: 48,
            height: 4,
            margin: const EdgeInsets.only(top: 14, bottom: 8),
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'HALL OF RANKS & TROPHIES',
                      style: GoogleFonts.cinzel(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.0,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Tingkatkan reputasimu & klaim lencana legendaris anime!',
                      style: TextStyle(color: Colors.grey[400], fontSize: 12),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, color: Colors.white70),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),

          // Master Showcase Card (Esports Trophy Aesthetic)
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF131520),
                  currentTheme.primaryGlow.withOpacity(0.12),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: currentTheme.primaryGlow.withOpacity(0.4), width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: currentTheme.primaryGlow.withOpacity(0.2),
                  blurRadius: 18,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    // Large Trophy Crest 3D Render
                    Container(
                      width: 58,
                      height: 58,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: currentTheme.primaryGlow.withOpacity(0.4),
                            blurRadius: 14,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: Image.asset(
                          currentRank.assetImage,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => RankBadgeWidget(
                            rankCode: _activeBadge,
                            level: _currentLevel,
                            compact: false,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            currentRank.title,
                            style: GoogleFonts.outfit(
                              color: Colors.white,
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            currentTheme.insigniaName,
                            style: TextStyle(
                              color: currentTheme.primaryGlow,
                              fontSize: 11,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Progres EXP Level $_currentLevel',
                      style: TextStyle(color: Colors.grey[400], fontSize: 11),
                    ),
                    Text(
                      '$_currentExp / $expNeeded EXP (${(progress * 100).toInt()}%)',
                      style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 8,
                    backgroundColor: Colors.white12,
                    valueColor: AlwaysStoppedAnimation<Color>(currentTheme.primaryGlow),
                  ),
                ),
                const SizedBox(height: 12),
                // Tombol Sinkronisasi Riwayat Lama
                InkWell(
                  onTap: _isSyncing ? null : _handleHistoricalSync,
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.06),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: currentTheme.primaryGlow.withOpacity(0.35)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _isSyncing
                            ? SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: currentTheme.primaryGlow,
                                ),
                              )
                            : Icon(Icons.sync_rounded, size: 16, color: currentTheme.primaryGlow),
                        const SizedBox(width: 8),
                        Text(
                          _isSyncing ? 'Menghitung Riwayat Tontonan...' : 'Hitung Riwayat Tontonan Lama ke EXP',
                          style: GoogleFonts.outfit(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 6),

          // List of All Ranks
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              itemCount: RankService.allRanks.length,
              itemBuilder: (context, index) {
                final rank = RankService.allRanks[index];
                final theme = RankVisualTheme.getTheme(rank.code);
                final isCurrentLevelRank = _currentLevel >= rank.minLevel && _currentLevel <= rank.maxLevel;
                final isUnlocked = _unlockedBadges.contains(rank.code);
                final isActive = _activeBadge.toUpperCase() == rank.code.toUpperCase();
                final canClaim = _currentLevel >= rank.minLevel && !isUnlocked;
                final isLocked = _currentLevel < rank.minLevel;

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10121A),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isActive
                          ? theme.primaryGlow
                          : (isUnlocked ? Colors.white24 : Colors.white.withOpacity(0.06)),
                      width: isActive ? 1.5 : 1,
                    ),
                    boxShadow: isActive
                        ? [
                            BoxShadow(
                              color: theme.primaryGlow.withOpacity(0.18),
                              blurRadius: 10,
                              offset: const Offset(0, 2),
                            ),
                          ]
                        : null,
                  ),
                  child: Row(
                    children: [
                      // 3D Metallic Badge Crest Box
                      ShimmerSheenWrapper(
                        enabled: !isLocked && theme.hasShimmer,
                        child: Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            color: const Color(0xFF12141C),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isLocked ? Colors.white12 : theme.primaryGlow.withOpacity(0.6),
                              width: 1.5,
                            ),
                            boxShadow: isLocked
                                ? null
                                : [
                                    BoxShadow(
                                      color: theme.primaryGlow.withOpacity(0.35),
                                      blurRadius: 10,
                                    ),
                                  ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(11),
                            child: isLocked
                                ? ColorFiltered(
                                    colorFilter: const ColorFilter.matrix([
                                      0.2126, 0.7152, 0.0722, 0, 0,
                                      0.2126, 0.7152, 0.0722, 0, 0,
                                      0.2126, 0.7152, 0.0722, 0, 0,
                                      0, 0, 0, 0.35, 0,
                                    ]),
                                    child: Image.asset(
                                      rank.assetImage,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) => Center(
                                        child: Text(
                                          rank.code,
                                          style: GoogleFonts.cinzel(
                                            color: Colors.grey[700],
                                            fontSize: 16,
                                            fontWeight: FontWeight.w900,
                                          ),
                                        ),
                                      ),
                                    ),
                                  )
                                : Image.asset(
                                    rank.assetImage,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => Center(
                                      child: Text(
                                        rank.code,
                                        style: GoogleFonts.cinzel(
                                          color: theme.textColor,
                                          fontSize: 16,
                                          fontWeight: FontWeight.w900,
                                        ),
                                      ),
                                    ),
                                  ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),

                      // Rank Details
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  rank.badgeName,
                                  style: GoogleFonts.outfit(
                                    color: isLocked ? Colors.grey[500] : Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                if (isActive) ...[
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                    decoration: BoxDecoration(
                                      color: theme.primaryGlow.withOpacity(0.25),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      'AKTIF',
                                      style: TextStyle(
                                        color: theme.primaryGlow,
                                        fontSize: 9,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ] else if (isCurrentLevelRank) ...[
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                    decoration: BoxDecoration(
                                      color: Colors.white10,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: const Text(
                                      'TIER SAAT INI',
                                      style: TextStyle(
                                        color: Colors.white70,
                                        fontSize: 9,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Syarat: Level ${rank.minLevel}${rank.maxLevel < 999999 ? ' - ${rank.maxLevel}' : '+'}',
                              style: TextStyle(
                                color: isLocked ? Colors.grey[600] : theme.primaryGlow,
                                fontSize: 11,
                                fontWeight: isLocked ? FontWeight.normal : FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              rank.description,
                              style: TextStyle(
                                color: isLocked ? Colors.grey[700] : Colors.white70,
                                fontSize: 11,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),

                      // Action Button
                      if (canClaim)
                        ElevatedButton(
                          onPressed: _isProcessing ? null : () => _handleClaim(rank),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFFF5E1E),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            elevation: 4,
                            shadowColor: const Color(0xFFFF5E1E).withOpacity(0.5),
                          ),
                          child: const Text('Klaim', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                        )
                      else if (isUnlocked && !isActive)
                        OutlinedButton(
                          onPressed: _isProcessing ? null : () => _handleEquip(rank),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white,
                            side: BorderSide(color: theme.primaryGlow),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          child: const Text('Pakai', style: TextStyle(fontSize: 12)),
                        )
                      else if (isActive)
                        const Icon(Icons.check_circle_rounded, color: Color(0xFFFF5E1E), size: 24)
                      else
                        Icon(Icons.lock_rounded, color: Colors.grey[700], size: 20),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
