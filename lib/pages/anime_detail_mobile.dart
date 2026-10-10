import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../model/anime_detail.dart';
import '../service/anime_service.dart';
import 'episode_page.dart';
import '../service/history_service.dart';
import '../service/favorite_service.dart';
import '../service/remote_config_service.dart'; // pastikan ini diimport
import '../widgets/anime_detail_loading_screens.dart';

class AnimeDetailMobile extends StatefulWidget {
  final String endpoint;
  final String? title;

  const AnimeDetailMobile({super.key, required this.endpoint, this.title});

  @override
  State<AnimeDetailMobile> createState() => _AnimeDetailMobileState();
}

class _AnimeDetailMobileState extends State<AnimeDetailMobile> {
  late Future<AnimeDetail> _animeDetail;
  final String _baseUrl = RemoteConfigService.baseUrl;

  bool _showFullSinopsis = false;
  List<String> _watchedEpisodes = [];

  bool _isAscending = true; // Tambahkan ini di atas initState
  bool _isSaved = false;

  @override
  void initState() {
    _checkIfSaved();

    super.initState();
    _animeDetail = AnimeService().fetchAnimeDetail(widget.endpoint);
    _loadWatchedEpisodes();
  }

  Future<void> _loadWatchedEpisodes() async {
    final watched = await HistoryService().getWatchedEpisodeIds();
    setState(() {
      _watchedEpisodes = watched;
    });
  }

  Future<void> _checkIfSaved() async {
    final saved = await FavoriteService.isSaved(widget.endpoint);
    if (mounted) {
      setState(() {
        _isSaved = saved;
      });
    }
  }

  Future<void> _toggleFavorite(String title, String imageUrl) async {
    await FavoriteService.toggleFavorite(
      endpoint: widget.endpoint,
      title: title,
      imageUrl: imageUrl,
    );
    setState(() {
      _isSaved = !_isSaved;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _isSaved
              ? 'Anime disimpan ke favorit.'
              : 'Anime dihapus dari favorit.',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: FutureBuilder<AnimeDetail>(
        future: _animeDetail,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return ModernLoadingScreens.buildLoadingScreen();
          } else if (snapshot.hasError) {
            return ModernLoadingScreens.buildErrorScreen(
              snapshot.error.toString(),
              onRetry: () {
                setState(() {
                  _animeDetail = AnimeService().fetchAnimeDetail(widget.endpoint);
                });
              },
            );
          } else if (!snapshot.hasData) {
            return ModernLoadingScreens.buildNoDataScreen();
          }

          final anime = snapshot.data!;
          final imageUrl =
              anime.proxyThumb(_baseUrl).isNotEmpty
                  ? anime.proxyThumb(_baseUrl)
                  : anime.thumb;

          final double headerHeight = MediaQuery.of(context).size.height * 0.5;

          return Stack(
            children: [
              // BACKGROUND BLUR IMAGE
              SizedBox(
                height: headerHeight,
                width: double.infinity,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.network(imageUrl, fit: BoxFit.cover),
                    BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                      child: Container(color: Colors.black.withOpacity(0.2)),
                    ),
                    Positioned(
                      bottom: -10,
                      left: 0,
                      right: 0,
                      child: Container(
                        height: headerHeight * 0.4,
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.black87,
                              Colors.black,
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // FOREGROUND CONTENT
              SafeArea(
                child: Column(
                  children: [
                    _buildHeader(context),
                    Expanded(
                      child: ListView(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        children: [
                          const SizedBox(height: 16),
                          _buildPoster(imageUrl, anime),

                          const SizedBox(height: 16),
                          _buildInfo(anime),
                          _buildSinopsis(anime),
                          const SizedBox(height: 16),
                          _buildEpisodes(anime),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              widget.title ?? "Detail Anime",
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPoster(String imageUrl, AnimeDetail anime) {
    return Center(
      child: Column(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.network(
              imageUrl,
              height: 220,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return const Center(
                  child: Text(
                    'Gagal memuat gambar',
                    style: TextStyle(color: Colors.white),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 12),

          // Tombol branding
          ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white10,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            child: Text(
              "NimeXx",
              style: GoogleFonts.oswald(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          const SizedBox(height: 8),

          // Tombol Simpan ke Favorit
          ElevatedButton.icon(
            onPressed: () {
              final title = anime.title;
              final image =
                  anime.proxyThumb(_baseUrl).isNotEmpty
                      ? anime.proxyThumb(_baseUrl)
                      : anime.thumb;
              _toggleFavorite(title, image);
            },
            icon: Icon(
              _isSaved ? Icons.bookmark : Icons.bookmark_border,
              color: _isSaved ? Colors.red : Colors.white,
            ),
            label: Text(
              _isSaved ? "Favorit" : "Simpan",
              style: const TextStyle(color: Colors.white),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white10,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfo(AnimeDetail anime) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center(
          child: Text(
            anime.title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: 12),
        ...anime.detail.map(
          (detail) => Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text(detail, style: const TextStyle(color: Colors.white70)),
          ),
        ),
      ],
    );
  }

  Widget _buildSinopsis(AnimeDetail anime) {
    String sinopsisText = anime.sinopsis.join('\n');
    bool showButton = sinopsisText.length > 300;
    String displayedText =
        _showFullSinopsis || !showButton
            ? sinopsisText
            : '${sinopsisText.substring(0, 300)}...';

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white10,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Sinopsis",
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(displayedText, style: const TextStyle(color: Colors.white70)),
          if (showButton)
            TextButton(
              onPressed:
                  () => setState(() => _showFullSinopsis = !_showFullSinopsis),
              child: Text(
                _showFullSinopsis
                    ? "Lihat Lebih Sedikit"
                    : "Lihat Selengkapnya",
                style: const TextStyle(color: Color.fromARGB(255, 255, 0, 0)),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildEpisodes(AnimeDetail anime) {
    List<Episode> episodes = List.from(anime.episodes);
    if (!_isAscending) {
      episodes = episodes.reversed.toList();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              "Daftar Episode",
              style: TextStyle(
                color: Color.fromARGB(255, 255, 1, 1),
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            TextButton.icon(
              onPressed: () {
                setState(() {
                  _isAscending = !_isAscending;
                });
              },
              icon: Icon(
                _isAscending ? Icons.arrow_downward : Icons.arrow_upward,
                color: Colors.white,
                size: 18,
              ),
              label: Text(
                _isAscending ? "Urut: Awal → Akhir" : "Urut: Akhir → Awal",
                style: const TextStyle(color: Colors.white, fontSize: 13),
              ),
              style: TextButton.styleFrom(foregroundColor: Colors.white10),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ...episodes.map(
          (ep) => GestureDetector(
            onTap: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder:
                      (_) => EpisodePage(
                        endpoint: ep.endpoint,
                        episodeTitle: ep.title,
                        animeTitle: anime.title,
                        thumbUrl: anime.proxyThumb(_baseUrl),
                        animeEndpoint: widget.endpoint,
                      ),
                ),
              );
              await _loadWatchedEpisodes();
            },
            child: Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color:
                    _watchedEpisodes.contains(ep.endpoint)
                        ? Colors.green
                        : Colors.white10,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      ep.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  const Icon(Icons.play_arrow, color: Colors.white),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
