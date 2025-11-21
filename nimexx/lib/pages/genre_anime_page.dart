import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import '../service/anime_service.dart';
import '../model/anime_model.dart';
import 'anime_detail_page.dart';
import '../widgets/web_app_bar.dart';
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
    final isMobile = MediaQuery.of(context).size.width < 600;

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
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate((context, index) {
                if (index >= _animeList.length) return null;
                final a = _animeList[index];
                final slug = a.link.replaceAll(RegExp(r'^/+|/+$'), '');

                return Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 0),
                    leading: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        kIsWeb ? a.proxyThumb(_service.baseUrl) : a.thumb,
                        width: 60,
                        height: 90,
                        fit: BoxFit.cover,
                        errorBuilder:
                            (_, __, ___) => const ColoredBox(
                              color: Colors.grey,
                              child: SizedBox(width: 60, height: 90),
                            ),
                      ),
                    ),
                    title: Text(
                      a.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Text(
                      a.genres.join(', '),
                      style: const TextStyle(color: Colors.white70),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    onTap: () {
                      if (slug.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Link anime tidak tersedia.'),
                          ),
                        );
                        return;
                      }
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => AnimeDetailPage(endpoint: slug),
                        ),
                      );
                    },
                  ),
                );
              }, childCount: _animeList.length),
            ),
          ),

          if (_isLoading)
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(child: CircularProgressIndicator()),
              ),
            ),
        ],
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
