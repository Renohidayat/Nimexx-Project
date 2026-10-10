// pages/episode_page.dart (Refactored Version)
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:google_fonts/google_fonts.dart';
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

  List<String> _watchedEpisodes = [];

  // Modern color scheme
  static const Color darkBackground = Color(0xFF0D0D0D);
  static const Color cardBackground = Color(0xFF1A1A1A);

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

    if (widget.animeEndpoint != null) {
      _animeDetail = AnimeService().fetchAnimeDetail(widget.animeEndpoint!);
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
                  _streamingUrlMobile ??= _findFirstStreamingUrl(episode);
                  return _buildContentWithFooter(episode);
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
            child: Padding(
              padding: EdgeInsets.all(kIsWeb ? 24 : 16),
              child: _buildEpisodeContent(episode),
            ),
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
        // Modern Episode Header
        ModernEpisodeHeader(
          episode: episode,
          onBackPressed: () => Navigator.pop(context),
          isWeb: kIsWeb,
        ),
        const SizedBox(height: 24),

        // Video Player (Mobile only)
        if (!kIsWeb && _streamingUrlMobile != null) ...[
          ModernVideoPlayer(streamingUrl: _streamingUrlMobile!),
          const SizedBox(height: 32),
        ],

        // Quality Selection Section
        ModernQualitySection(
          episode: episode,
          onStreamButtonPressed: _onStreamButtonPressed,
        ),

        // Episode List Section
        if (widget.animeEndpoint != null) ...[
          const SizedBox(height: 40),
          ModernEpisodeList(
            animeDetail: _animeDetail,
            currentEndpoint: widget.endpoint,
            animeTitle: widget.animeTitle,
            thumbUrl: widget.thumbUrl,
            animeEndpoint: widget.animeEndpoint,
            watchedEpisodes: _watchedEpisodes,
          ),
        ],

        // Comment Section
        const SizedBox(height: 40),
        ModernCommentSectionWrapper(
          episodeId: widget.endpoint,
          episodeTitle: widget.episodeTitle,
          animeTitle: widget.animeTitle,
          thumbUrl: widget.thumbUrl,
          commentService: _commentService,
          highlightCommentId: _highlightCommentId,
        ),
      ],
    );
  }

  Future<void> _onStreamButtonPressed(String apiPath) async {
    final cleanPath = apiPath.replaceFirst(RegExp(r'^/api/v1'), '');
    final apiUrl = Uri.parse('${RemoteConfigService.baseUrl}$cleanPath');

    // Tampilkan Dialog Loading dengan Timer
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            return StreamBuilder<int>(
              stream: Stream.periodic(const Duration(seconds: 1), (i) => i + 1),
              builder: (context, snapshot) {
                final seconds = snapshot.data ?? 0;
                return Dialog(
                  backgroundColor: cardBackground,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(color: const Color(0xFFFF6B35).withOpacity(0.5)),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const CircularProgressIndicator(
                          color: Color(0xFFFF6B35),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'Menghubungkan ke server...',
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Mohon tunggu ($seconds detik)',
                          style: GoogleFonts.poppins(
                            color: Colors.white60,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );

    try {
      final futures = List.generate(3, (index) => _raceApiRequest(apiUrl));
      final response = await Future.any(futures);
      
      // Tutup dialog
      if (mounted) Navigator.pop(context);

      if (response.statusCode != 200) {
        ModernSnackBarHelper.showSnackBar(
          context,
          'Gagal mengambil link streaming (HTTP ${response.statusCode})',
          isError: true,
        );
        return;
      }

      final data = json.decode(response.body);
      final streamUrl = data['streaming_url'];

      if (streamUrl == null || streamUrl.isEmpty) {
        ModernSnackBarHelper.showSnackBar(
          context,
          'Link streaming tidak ditemukan dalam respons API.',
          isError: true,
        );
        return;
      }

      await HistoryService().saveWatchHistory(
        episodeId: widget.endpoint,
        episodeTitle: widget.episodeTitle,
        animeTitle: widget.animeTitle,
        thumbUrl: widget.thumbUrl,
        animeEndpoint: widget.animeEndpoint ?? '',
      );

      await _loadWatchedEpisodes();

      if (kIsWeb) {
        final streamUri = Uri.parse(streamUrl);
        if (await canLaunchUrl(streamUri)) {
          await launchUrl(streamUri, mode: LaunchMode.externalApplication);
          ModernSnackBarHelper.showSnackBar(
            context,
            'Membuka streaming di aplikasi eksternal...',
          );
        } else {
          ModernSnackBarHelper.showSnackBar(
            context,
            'Tidak dapat membuka link: $streamUrl',
            isError: true,
          );
        }
      } else {
        setState(() {
          _streamingUrlMobile = streamUrl;
        });
        ModernSnackBarHelper.showSnackBar(
          context,
          'Stream dimuat! Scroll ke atas untuk menonton.',
        );
      }
    } catch (e) {
      if (mounted) Navigator.pop(context); // Tutup dialog jika error
      ModernSnackBarHelper.showSnackBar(
        context,
        'Terjadi kesalahan saat membuka link: $e',
        isError: true,
      );
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
    final allLinks = [
      ...episode.mirror360p,
      ...episode.mirror480p,
      ...episode.mirror720p,
    ];
    if (allLinks.isNotEmpty) {
      return 'http://192.168.100.228:8000${allLinks.first.link}';
    }
    return null;
  }
}
