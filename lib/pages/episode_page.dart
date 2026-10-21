// pages/episode_page.dart (Refactored Version)
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:url_launcher/url_launcher.dart';
import '../model/episode_detail.dart';
import '../model/anime_detail.dart';
import '../service/anime_service.dart';
import '../widgets/web_app_bar.dart';
import '../widgets/footer_widget.dart';
import '../service/history_service.dart';
import '../service/comment_service.dart';
import '../service/notification_service.dart';
import '../service/remote_config_service.dart';
import '../service/rank_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

// Import modular widgets
import '../widgets/episode/modern_episode_header.dart';
import '../widgets/episode/modern_video_player.dart';
import '../widgets/episode/modern_quality_section.dart';
import '../widgets/episode/modern_episode_list.dart';
import '../widgets/episode/modern_loading_screens.dart';
import '../widgets/episode/modern_snackbar_helper.dart';
import '../widgets/episode/modern_comment_section_wrapper.dart';

class EpisodePage extends StatefulWidget {
  final String endpoint;
  final String episodeTitle;
  final String animeTitle;
  final String thumbUrl;
  final String? highlightCommentId;
  final String? animeEndpoint;

  const EpisodePage({
    super.key,
    required this.endpoint,
    required this.episodeTitle,
    required this.animeTitle,
    required this.thumbUrl,
    this.highlightCommentId,
    this.animeEndpoint,
  });

  @override
  State<EpisodePage> createState() => _EpisodePageState();
}

class _EpisodePageState extends State<EpisodePage>
    with TickerProviderStateMixin {
  late Future<EpisodeDetail> _episodeDetail;
  Future<AnimeDetail>? _animeDetail;
  String? _streamingUrlMobile;
  String? _highlightCommentId;
  late final CommentService _commentService;
  late AnimationController _animationController;
  late AnimationController _pulseController;
  late Animation<double> _fadeAnimation;
  bool _isFetchingStream = false;
  bool _isInitialStreamFetched = false;

  List<String> _watchedEpisodes = [];

  // Modern color scheme
  static const Color darkBackground = Color(0xFF07080B);
  static const Color cardBackground = Color(0xFF171924);
  static const Color surfaceColor = Color(0xFF0F1118);
  static const Color primaryOrange = Color(0xFFFF5E1E);
  
  int _activeTab = 0;

  @override
  void dispose() {
    _animationController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _episodeDetail = AnimeService().fetchEpisodeDetail(widget.endpoint);
    _commentService = CommentService(NotificationService());
    _highlightCommentId = widget.highlightCommentId;

    // Initialize animations
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat(reverse: true);

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _animationController.forward();

    String? animeEp = widget.animeEndpoint;
    if (animeEp == null || animeEp.isEmpty) {
      final clean = widget.endpoint.replaceAll(RegExp(r'^/episode/|/$'), '');
      final derived = clean.replaceAll(RegExp(r'-episode-\d+'), '');
      if (derived.isNotEmpty) {
        animeEp = derived;
      }
    }
    if (animeEp != null && animeEp.isNotEmpty) {
      _animeDetail = AnimeService().fetchAnimeDetail(animeEp);
    }

    _loadWatchedEpisodes();
  }

  Future<void> _loadWatchedEpisodes() async {
    final watched = await HistoryService().getWatchedEpisodeIds();
    if (mounted) {
      setState(() {
        _watchedEpisodes = watched;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: darkBackground,
      body: SafeArea(
        child: Column(
          children: [
            if (kIsWeb) _buildModernWebAppBar(),
            Expanded(
              child: FutureBuilder<EpisodeDetail>(
                future: _episodeDetail,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return ModernLoadingScreens.buildLoadingScreen();
                  } else if (snapshot.hasError) {
                    return ModernLoadingScreens.buildErrorScreen(
                      snapshot.error.toString(),
                      onRetry: () {
                        setState(() {
                          _episodeDetail = AnimeService().fetchEpisodeDetail(widget.endpoint);
                        });
                      },
                    );
                  } else if (!snapshot.hasData) {
                    return ModernLoadingScreens.buildNoDataScreen();
                  }

                  final episode = snapshot.data!;
                  
                  if (!_isInitialStreamFetched) {
                    _isInitialStreamFetched = true;
                    String? megaLink;
                    for (final link in episode.mirror720p) {
                      if (link.driver.toLowerCase().contains('mega')) { megaLink = link.link; break; }
                    }
                    if (megaLink == null) {
                      for (final link in episode.mirror480p) {
                        if (link.driver.toLowerCase().contains('mega')) { megaLink = link.link; break; }
                      }
                    }
                    if (megaLink == null) {
                      for (final link in episode.mirror360p) {
                        if (link.driver.toLowerCase().contains('mega')) { megaLink = link.link; break; }
                      }
                    }
                    if (megaLink == null && episode.mirror720p.isNotEmpty) megaLink = episode.mirror720p.first.link;
                    if (megaLink == null && episode.mirror480p.isNotEmpty) megaLink = episode.mirror480p.first.link;
                    if (megaLink == null && episode.mirror360p.isNotEmpty) megaLink = episode.mirror360p.first.link;
                    
                    if (megaLink != null) {
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (mounted && !kIsWeb) {
                          _onStreamButtonPressed(megaLink!);
                        }
                      });
                    }
                  }

                  _streamingUrlMobile ??= _findFirstStreamingUrl(episode);
                  return Column(
                    children: [
                      ModernEpisodeHeader(
                        episode: episode,
                        onBackPressed: () => Navigator.pop(context),
                        isWeb: kIsWeb,
                      ),
                      Expanded(
                        child: _buildContentWithFooter(episode),
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

  Widget _buildModernWebAppBar() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [darkBackground, cardBackground],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFF6B35).withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: WebAppBar(
        selectedIndex: 0,
        onSelected: (index) {
          Navigator.pushNamed(
            context,
            [
              '/home',
              '/list',
              '/jadwal',
              '/ongoing',
              '/genre',
              '/search',
            ][index],
          );
        },
      ),
    );
  }

  Widget _buildContentWithFooter(EpisodeDetail episode) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: _buildEpisodeContent(episode),
          ),
          if (kIsWeb) const SliverToBoxAdapter(child: FooterWidget()),
        ],
      ),
    );
  }

  Widget _buildEpisodeContent(EpisodeDetail episode) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Video Player (Mobile only) - Edge to edge
        if (!kIsWeb && _streamingUrlMobile != null)
          ModernVideoPlayer(streamingUrl: _streamingUrlMobile!),

        // Content padding
        Padding(
          padding: EdgeInsets.all(kIsWeb ? 24 : 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Meta Info & Tabs
              _buildAnimeMetaInfo(episode),
              _buildModernTabBar(),

              // Tab Content
              _buildTabContent(episode),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAnimeMetaInfo(EpisodeDetail episode) {
    return FutureBuilder<AnimeDetail>(
      future: _animeDetail,
      builder: (context, snapshot) {
        String status = 'UNKNOWN';
        String score = '-';
        String genre = 'Unknown Genre';

        if (snapshot.hasData) {
          final details = snapshot.data!.detail;
          for (var item in details) {
            final lower = item.toLowerCase();
            final parts = item.split(':');
            final val = parts.length > 1 ? parts.sublist(1).join(':').trim() : '';

            if (lower.contains('status')) {
              if (val.isNotEmpty) status = val.toUpperCase();
            } else if (lower.contains('skor') || lower.contains('score') || lower.contains('rating')) {
              if (val.isNotEmpty) score = val;
            } else if (lower.contains('genre')) {
              if (val.isNotEmpty) genre = val;
            }
          }
        }

        return Padding(
          padding: const EdgeInsets.only(top: 8.0, bottom: 8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: primaryOrange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: primaryOrange.withOpacity(0.3)),
                    ),
                    child: Text(
                      'ANIME ${status != "UNKNOWN" ? status : "ONGOING"}',
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: primaryOrange,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFF171924),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: Colors.amber.withOpacity(0.3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.star_rounded, color: Colors.amber, size: 14),
                        const SizedBox(width: 3),
                        Text(
                          score != '-' ? score : '8.5',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (genre != 'Unknown Genre' && genre.isNotEmpty) ...[
                    const SizedBox(width: 8),
                    Text('•', style: TextStyle(fontSize: 11, color: Colors.grey[500])),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        genre,
                        style: TextStyle(fontSize: 11, color: Colors.grey[400]),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      widget.animeTitle,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF171924),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: primaryOrange.withOpacity(0.3)),
                    ),
                    child: Text(
                      _extractEpisodeNumber(widget.episodeTitle),
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: primaryOrange,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'Tonton Petualangan ${widget.animeTitle} - Subtitle Indonesia Resmi',
                style: TextStyle(fontSize: 11, color: Colors.grey[400]),
              ),
            ],
          ),
        );
      }
    );
  }

  String _extractEpisodeNumber(String fullTitle) {
    final match = RegExp(r'Episode\s+(\d+)').firstMatch(fullTitle);
    if (match != null) {
      return 'EP ${match.group(1)}';
    }
    return 'EP';
  }

  Widget _buildModernTabBar() {
    return Container(
      margin: const EdgeInsets.only(top: 16.0, bottom: 20.0),
      padding: const EdgeInsets.all(4.0),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Row(
        children: [
          _buildTabButton(0, 'Episode', Icons.list),
          _buildTabButton(1, 'Server', Icons.hd_outlined),
          _buildTabButton(2, 'Komentar', Icons.chat_bubble_outline),
        ],
      ),
    );
  }

  Widget _buildTabButton(int index, String title, IconData icon) {
    final isActive = _activeTab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _activeTab = index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isActive ? const Color(0xFFFF5E1E) : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            boxShadow: isActive
                ? [
                    BoxShadow(
                      color: const Color(0xFFFF5E1E).withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    )
                  ]
                : [],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 14,
                color: isActive ? Colors.white : Colors.grey[400],
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: isActive ? FontWeight.bold : FontWeight.w600,
                    color: isActive ? Colors.white : Colors.grey[400],
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

  Widget _buildTabContent(EpisodeDetail episode) {
    switch (_activeTab) {
      case 0:
        return widget.animeEndpoint != null
            ? ModernEpisodeList(
                animeDetail: _animeDetail,
                currentEndpoint: widget.endpoint,
                animeTitle: widget.animeTitle,
                thumbUrl: widget.thumbUrl,
                animeEndpoint: widget.animeEndpoint,
                watchedEpisodes: _watchedEpisodes,
              )
            : const SizedBox.shrink();
      case 1:
        return ModernQualitySection(
          episode: episode,
          onStreamButtonPressed: _onStreamButtonPressed,
          isFetchingStream: _isFetchingStream,
        );
      case 2:
        return ModernCommentSectionWrapper(
          episodeId: widget.endpoint,
          episodeTitle: widget.episodeTitle,
          animeTitle: widget.animeTitle,
          thumbUrl: widget.thumbUrl,
          commentService: _commentService,
          highlightCommentId: _highlightCommentId,
        );
      default:
        return const SizedBox.shrink();
    }
  }

  Future<void> _onStreamButtonPressed(String apiPath) async {
    if (_isFetchingStream) return;
    
    setState(() {
      _isFetchingStream = true;
    });

    final cleanPath = apiPath.replaceFirst(RegExp(r'^/api/v1'), '');
    final apiUrl = Uri.parse('${RemoteConfigService.baseUrl}$cleanPath');

    try {
      final futures = List.generate(3, (index) => _raceApiRequest(apiUrl));
      final response = await Future.any(futures);
      
      if (response.statusCode != 200) {
        if (mounted) {
          setState(() { _isFetchingStream = false; });
          ModernSnackBarHelper.showSnackBar(
            context,
            'Gagal mengambil link streaming (HTTP ${response.statusCode})',
            isError: true,
          );
        }
        return;
      }

      final data = json.decode(response.body);
      final streamUrl = data['streaming_url'];

      if (streamUrl == null || streamUrl.isEmpty) {
        if (mounted) {
          setState(() { _isFetchingStream = false; });
          ModernSnackBarHelper.showSnackBar(
            context,
            'Link streaming tidak ditemukan dalam respons API.',
            isError: true,
          );
        }
        return;
      }

      await HistoryService().saveWatchHistory(
        episodeId: widget.endpoint,
        episodeTitle: widget.episodeTitle,
        animeTitle: widget.animeTitle,
        thumbUrl: widget.thumbUrl,
        animeEndpoint: widget.animeEndpoint ?? '',
      );

      // Berikan reward EXP tontonan episode (+15 EXP, maks 3/hari)
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        try {
          final res = await RankService().addExp(uid: currentUser.uid, actionType: 'watch');
          if (res.success && mounted) {
            ModernSnackBarHelper.showSnackBar(
              context,
              '⚔️ ${res.message}',
            );
          }
        } catch (_) {}
      }

      await _loadWatchedEpisodes();

      if (kIsWeb) {
        if (mounted) {
          setState(() { _isFetchingStream = false; });
        }
        final streamUri = Uri.parse(streamUrl);
        if (await canLaunchUrl(streamUri)) {
          await launchUrl(streamUri, mode: LaunchMode.externalApplication);
          if (mounted) {
            ModernSnackBarHelper.showSnackBar(
              context,
              'Membuka streaming di aplikasi eksternal...',
            );
          }
        } else {
          if (mounted) {
            ModernSnackBarHelper.showSnackBar(
              context,
              'Tidak dapat membuka link: $streamUrl',
              isError: true,
            );
          }
        }
      } else {
        if (mounted) {
          setState(() {
            _streamingUrlMobile = streamUrl;
            _isFetchingStream = false;
          });
          ModernSnackBarHelper.showSnackBar(
            context,
            'Stream dimuat! Scroll ke atas untuk menonton.',
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() { _isFetchingStream = false; });
        ModernSnackBarHelper.showSnackBar(
          context,
          'Terjadi kesalahan saat membuka link: $e',
          isError: true,
        );
      }
    }
  }

  Future<http.Response> _raceApiRequest(Uri apiUrl) async {
    for (int i = 0; i < 10; i++) {
      try {
        final res = await http.get(apiUrl).timeout(const Duration(milliseconds: 1500));
        if (res.statusCode == 200) return res;
      } catch (_) {}
      await Future.delayed(const Duration(milliseconds: 100));
    }
    return http.Response('Error', 500);
  }

  String? _findFirstStreamingUrl(EpisodeDetail episode) {
    if (episode.realStreamUrl != null && episode.realStreamUrl!.isNotEmpty) {
      return episode.realStreamUrl;
    }
    // Jika tidak ada URL streaming asli, kembalikan null
    // Ini akan menyembunyikan video player sampai user memilih resolusi
    return null;
  }
}
