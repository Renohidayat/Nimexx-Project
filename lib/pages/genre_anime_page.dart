import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import '../service/anime_service.dart';
import '../model/anime_model.dart';
import 'anime_detail_page.dart';
import '../widgets/web_app_bar.dart';
import '../widgets/anime_loading_screens.dart';
import 'package:google_fonts/google_fonts.dart';

class GenreAnimePage extends StatefulWidget {
  final String endpoint;
  final String title;

  const GenreAnimePage({
    super.key,
    required this.endpoint,
    required this.title,
  });

  @override
  State<GenreAnimePage> createState() => _GenreAnimePageState();
}

class _GenreAnimePageState extends State<GenreAnimePage> {
  final AnimeService _service = AnimeService();
  final ScrollController _scrollController = ScrollController();

  List<AnimeModel> _animeList = [];
  int _currentPage = 1;
  bool _isLoading = false;
  bool _hasMore = true;

  @override
  void initState() {
    super.initState();
    _fetchAnime();

    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
              _scrollController.position.maxScrollExtent - 100 &&
          !_isLoading &&
          _hasMore) {
        _fetchAnime();
      }
    });
  }

  Future<void> _fetchAnime() async {
    setState(() => _isLoading = true);

    final newAnimes = await _service.fetchAnimeByGenre(
      widget.endpoint,
      page: _currentPage,
    );

    setState(() {
      if (newAnimes.isEmpty) {
        _hasMore = false;
      } else {
        _animeList.addAll(newAnimes);
        _currentPage++;
      }
      _isLoading = false;
    });
  }

  void _onWebNavSelected(int index) {
    switch (index) {
      case 0:
        Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
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
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isMobile = width < 600;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar:
          !kIsWeb
              ? AppBar(
                backgroundColor: Colors.black,
                title: Text(
                  widget.title,
                  style: GoogleFonts.oswald(
                    textStyle: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              )
              : null,
      body: CustomScrollView(
        controller: _scrollController,
        slivers: [
          if (kIsWeb)
            SliverToBoxAdapter(
              child: WebAppBar(selectedIndex: 4, onSelected: _onWebNavSelected),
            ),

          SliverPadding(
            padding: EdgeInsets.symmetric(
              horizontal: isMobile ? 16 : 60,
              vertical: 20,
            ),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                if (kIsWeb)
                  Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                        tooltip: 'Kembali',
                      ),
                      const SizedBox(width: 8),
                      Text(
                        widget.title,
                        style: GoogleFonts.oswald(
                          fontSize: isMobile ? 20 : 26,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ],
                  ),
                if (kIsWeb) const SizedBox(height: 20),
              ]),
            ),
          ),

          SliverPadding(
            padding: EdgeInsets.symmetric(horizontal: isMobile ? 16 : 60),
            sliver: _animeList.isEmpty && _isLoading
                ? const SliverToBoxAdapter(child: SizedBox()) // Ditangani oleh loader di bawah
                : SliverGrid(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        return _AnimeCard(
                          anime: _animeList[index],
                          baseUrl: _service.baseUrl,
                        );
                      },
                      childCount: _animeList.length,
                    ),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: width >= 1200 ? 6 : width >= 992 ? 5 : width >= 768 ? 4 : width >= 600 ? 3 : 2,
                      mainAxisSpacing: isMobile ? 20 : 40,
                      crossAxisSpacing: isMobile ? 12 : 30,
                      childAspectRatio: isMobile ? 0.58 : 0.6,
                    ),
                  ),
          ),

          if (_isLoading)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Center(
                  child: _animeList.isEmpty 
                    ? ModernLoadingScreens.buildLoadingScreen()
                    : const CircularProgressIndicator(),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _AnimeCard extends StatelessWidget {
  final AnimeModel anime;
  final String baseUrl;

  const _AnimeCard({required this.anime, required this.baseUrl});

  @override
  Widget build(BuildContext context) {
    final slug = anime.link.replaceAll(RegExp(r'^/+|/+$'), '');

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 160),
        child: InkWell(
          onTap: () {
            if (slug.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Link anime tidak tersedia.')),
              );
              return;
            }
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => AnimeDetailPage(endpoint: slug)),
            );
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AspectRatio(
                aspectRatio: 0.65,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.network(
                    kIsWeb ? anime.proxyThumb(baseUrl) : anime.thumb,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const ColoredBox(color: Colors.grey),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                anime.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class DummySearchDelegate extends SearchDelegate {
  @override
  List<Widget>? buildActions(BuildContext context) => [
    IconButton(onPressed: () => query = '', icon: const Icon(Icons.clear)),
  ];

  @override
  Widget? buildLeading(BuildContext context) => IconButton(
    onPressed: () => close(context, null),
    icon: const Icon(Icons.arrow_back),
  );

  @override
  Widget buildResults(BuildContext context) =>
      Center(child: Text('Hasil pencarian: $query'));

  @override
  Widget buildSuggestions(BuildContext context) =>
      Center(child: Text('Cari: $query'));
}
