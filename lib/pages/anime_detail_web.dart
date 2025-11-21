import 'dart:ui';
import 'package:flutter/material.dart';
import '../model/anime_detail.dart';
import '../service/anime_service.dart';
import '../service/history_service.dart';
import '../service/favorite_service.dart';
import '../widgets/web_app_bar.dart';
import '../service/remote_config_service.dart';
import 'episode_page.dart';
import '../widgets/anime_detail_loading_screens.dart';

class AnimeDetailWeb extends StatefulWidget {
  final String endpoint;
  final String? title;

  const AnimeDetailWeb({super.key, required this.endpoint, this.title});

  @override
  State<AnimeDetailWeb> createState() => _AnimeDetailWebState();
}

class _AnimeDetailWebState extends State<AnimeDetailWeb> {
  late Future<AnimeDetail> _animeDetail;
  late final String _baseUrl;

  bool _showFullSinopsis = false;
  bool _isAscending = true;
  bool _isSaved = false;
  List<String> _watchedEpisodes = [];

  @override
  void initState() {
    super.initState();
    _baseUrl = RemoteConfigService.baseUrl;
    _animeDetail = AnimeService().fetchAnimeDetail(widget.endpoint);
    _loadWatchedEpisodes();
    _checkIfSaved();
  }

  Future<void> _loadWatchedEpisodes() async {
    final watched = await HistoryService().getWatchedEpisodeIds();
    if (mounted) {
      setState(() {
        _watchedEpisodes = watched;
      });
    }
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
      body: Column(
        children: [
          WebAppBar(
            selectedIndex: 0, // atau sesuaikan sesuai tab aktif
            onSelected: (index) {
              switch (index) {
                case 0:
                  Navigator.pushNamedAndRemoveUntil(
                    context,
                    '/home',
                    (_) => false,
                  );
                  break;
                case 1:
                  Navigator.pushNamed(context, '/completed');
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
              }
            },
          ),

          Expanded(
            child: FutureBuilder<AnimeDetail>(
              future: _animeDetail,
              builder: (context, snapshot) {
                // Gunakan loading screen yang sudah dioptimalkan
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return ModernLoadingScreens.buildLoadingScreen();
                }
                // Gunakan error screen yang sudah dioptimalkan
                // Jika tidak ada data
                else if (!snapshot.hasData) {
                  return ModernLoadingScreens.buildNoDataScreen();
                }

                final anime = snapshot.data!;
                final imageUrl =
                    anime.proxyThumb(_baseUrl).isNotEmpty
                        ? anime.proxyThumb(_baseUrl)
                        : anime.thumb;
                final double headerHeight =
                    MediaQuery.of(context).size.height * 0.6;

                return Stack(
                  children: [
                    SizedBox(
                      height: headerHeight,
                      width: double.infinity,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          Image.network(imageUrl, fit: BoxFit.cover),
                          BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                            child: Container(
                              color: Colors.black.withOpacity(0.2),
                            ),
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
                    SafeArea(
                      child: Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(12),
                            child: Row(
                              children: [
                                IconButton(
                                  icon: const Icon(
                                    Icons.arrow_back,
                                    color: Colors.white,
                                  ),
                                  onPressed: () => Navigator.pop(context),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    widget.title ?? "",
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
                          ),
                          Expanded(
                            child: ListView(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 32,
                              ),
                              children: [
                                const SizedBox(height: 16),
                                Center(
                                  child: Column(
                                    children: [
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(12),
                                        child: Image.network(
                                          imageUrl,
                                          height: 300,
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      ElevatedButton(
                                        onPressed: () {},
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.white10,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              20,
                                            ),
                                          ),
                                        ),
                                        child: const Text(
                                          "NimeXx",
                                          style: TextStyle(color: Colors.white),
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      ElevatedButton.icon(
                                        onPressed: () {
                                          final title = anime.title;
                                          final image = imageUrl;
                                          _toggleFavorite(title, image);
                                        },
                                        icon: Icon(
                                          _isSaved
                                              ? Icons.bookmark
                                              : Icons.bookmark_border,
                                          color:
                                              _isSaved
                                                  ? Colors.red
                                                  : Colors.white,
                                        ),
                                        label: Text(
                                          _isSaved ? "Favorit" : "Simpan",
                                          style: const TextStyle(
                                            color: Colors.white,
                                          ),
                                        ),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.white10,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Center(
                                  child: Text(
                                    anime.title,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                ...anime.detail.map(
                                  (detail) => Padding(
                                    padding: const EdgeInsets.only(bottom: 4),
                                    child: Text(
                                      detail,
                                      style: const TextStyle(
                                        color: Colors.white70,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: Colors.white10,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        "Sinopsis",
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        _showFullSinopsis ||
                                                anime.sinopsis
                                                        .join('\n')
                                                        .length <=
                                                    300
                                            ? anime.sinopsis.join('\n')
                                            : '${anime.sinopsis.join('\n').substring(0, 300)}...',
                                        style: const TextStyle(
                                          color: Colors.white70,
                                        ),
                                      ),
                                      if (anime.sinopsis.join('\n').length >
                                          300)
                                        TextButton(
                                          onPressed:
                                              () => setState(
                                                () =>
                                                    _showFullSinopsis =
                                                        !_showFullSinopsis,
                                              ),
                                          child: Text(
                                            _showFullSinopsis
                                                ? "Lihat Lebih Sedikit"
                                                : "Lihat Selengkapnya",
                                            style: const TextStyle(
                                              color: Colors.red,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text(
                                      "Daftar Episode",
                                      style: TextStyle(
                                        color: Colors.redAccent,
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    TextButton.icon(
                                      onPressed:
                                          () => setState(
                                            () => _isAscending = !_isAscending,
                                          ),
                                      icon: Icon(
                                        _isAscending
                                            ? Icons.arrow_downward
                                            : Icons.arrow_upward,
                                        color: Colors.white,
                                      ),
                                      label: Text(
                                        _isAscending
                                            ? "Urut: Awal → Akhir"
                                            : "Urut: Akhir → Awal",
                                        style: const TextStyle(
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                ...(_isAscending
                                        ? anime.episodes
                                        : anime.episodes.reversed)
                                    .map(
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
                                                    thumbUrl: anime.proxyThumb(
                                                      _baseUrl,
                                                    ),
                                                    animeEndpoint:
                                                        widget.endpoint,
                                                  ),
                                            ),
                                          );
                                          await _loadWatchedEpisodes();
                                        },
                                        child: Container(
                                          margin: const EdgeInsets.only(
                                            bottom: 8,
                                          ),
                                          padding: const EdgeInsets.all(12),
                                          decoration: BoxDecoration(
                                            color:
                                                _watchedEpisodes.contains(
                                                      ep.endpoint,
                                                    )
                                                    ? Colors.green
                                                    : Colors.white10,
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                          ),
                                          child: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
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
                                              const Icon(
                                                Icons.play_arrow,
                                                color: Colors.white,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    )
                                    .toList(),
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
          ),
        ],
      ),
    );
  }
}
