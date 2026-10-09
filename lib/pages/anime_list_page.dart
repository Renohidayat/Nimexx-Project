import 'package:flutter/material.dart';
import '../model/anime_list_item.dart';
import '../service/anime_service.dart';
import 'anime_detail_page.dart';
import '../widgets/web_app_bar.dart';
import '../widgets/footer_widget.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../widgets/anime_loading_screens.dart';

class AnimeListPage extends StatefulWidget {
  const AnimeListPage({super.key});

  @override
  State<AnimeListPage> createState() => _AnimeListPageState();
}

class _AnimeListPageState extends State<AnimeListPage> {
  late Future<List<AnimeListItem>> _animeListFuture;
  final ScrollController _scrollController = ScrollController();
  final Map<String, GlobalKey> _letterKeys = {};

  List<AnimeListItem> _animeList = [];
  List<AnimeListItem> _filteredAnimeList = [];
  int _selectedIndex = 1;

  @override
  void initState() {
    super.initState();
    _animeListFuture = AnimeService().fetchAnimeList().then((data) {
      _animeList = data;
      _filteredAnimeList = data;
      return data;
    });
  }

  void _scrollToLetter(String letter) {
    final key = _letterKeys[letter];
    if (key != null && key.currentContext != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Scrollable.ensureVisible(
          key.currentContext!,
          duration: const Duration(milliseconds: 400),
          alignment: 0,
          curve: Curves.easeInOut,
        );
      });
    }
  }

  void _filterAnimeByCharacter(String character) {
    setState(() {
      if (character == '#') {
        _filteredAnimeList =
            _animeList.where((anime) {
              final firstChar = anime.title.trim();
              return firstChar.isEmpty ||
                  !RegExp(r'[A-Za-z]').hasMatch(firstChar[0]);
            }).toList();
      } else {
        _filteredAnimeList =
            _animeList.where((anime) {
              final firstChar = anime.title.trim();
              return firstChar.isNotEmpty &&
                  firstChar.toUpperCase().startsWith(character.toUpperCase());
            }).toList();
      }
    });
  }

  void _handleMenuSelected(int index) {
    setState(() {
      _selectedIndex = index;
    });

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

  Widget _buildAZBar(List<String> letters) {
    return Container(
      color: Colors.black,
      height: 40,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: letters.length,
        itemBuilder: (context, index) {
          final letter = letters[index];
          return GestureDetector(
            onTap: () {
              _filterAnimeByCharacter(letter);
              _scrollToLetter(letter);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              alignment: Alignment.center,
              child: Text(
                letter,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  fontSize: 14,
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
    return Scaffold(
      backgroundColor: Colors.black,
      appBar:
          kIsWeb
              ? null
              : AppBar(
                backgroundColor: Colors.black,
                elevation: 2,
                title: Text(
                  'NimeXx',
                  style: GoogleFonts.oswald(
                    textStyle: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                    ),
                  ),
                ),
              ),
      body: FutureBuilder<List<AnimeListItem>>(
        future: _animeListFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return ModernLoadingScreens.buildLoadingScreen(
              selectedIndex: _selectedIndex,
              onMenuSelected: _handleMenuSelected,
            );
          }
          // Jika terjadi error saat fetch (termasuk timeout)
          else if (snapshot.hasError) {
            return ModernLoadingScreens.buildErrorScreen(
              snapshot.error.toString(),
              selectedIndex: _selectedIndex,
              onMenuSelected: _handleMenuSelected,
              onRetry: () {
                setState(() {
                  _animeListFuture = AnimeService().fetchAnimeList().then((data) {
                    _animeList = data;
                    _filteredAnimeList = data;
                    return data;
                  });
                });
              },
            );
          }
          // Jika tidak ada data
          else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return ModernLoadingScreens.buildNoDataScreen(
              selectedIndex: _selectedIndex,
              onMenuSelected: _handleMenuSelected,
            );
          }

          final groupedAnime = <String, List<AnimeListItem>>{};
          for (var anime in _filteredAnimeList) {
            final firstChar =
                anime.title.trim().isNotEmpty
                    ? anime.title.trim()[0].toUpperCase()
                    : '#';
            final key = RegExp(r'[A-Z]').hasMatch(firstChar) ? firstChar : '#';
            groupedAnime.putIfAbsent(key, () => []).add(anime);
          }

          final sortedKeys =
              groupedAnime.keys.toList()..sort((a, b) {
                if (a == '#') return 1;
                if (b == '#') return -1;
                return a.compareTo(b);
              });

          return CustomScrollView(
            controller: _scrollController,
            slivers: [
              if (kIsWeb)
                SliverToBoxAdapter(
                  child: WebAppBar(
                    selectedIndex: _selectedIndex,
                    onSelected: _handleMenuSelected,
                  ),
                ),

              // Sisanya tetap sama
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 30, 20, 10),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        'ANIME LIST',
                        style: GoogleFonts.oswald(
                          textStyle: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: 1.5,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Container(width: 40, height: 4, color: Colors.orange),
                    ],
                  ),
                ),
              ),
              SliverPersistentHeader(
                pinned: true,
                delegate: _SliverAppBarDelegate(
                  minHeight: 40,
                  maxHeight: 40,
                  child: _buildAZBar(sortedKeys),
                ),
              ),
              SliverList(
                delegate: SliverChildBuilderDelegate((context, index) {
                  final letter = sortedKeys[index];
                  _letterKeys[letter] = GlobalKey();
                  final animeGroup = groupedAnime[letter]!;

                  return Column(
                    key: _letterKeys[letter],
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 20, 20, 4),
                        child: Text(
                          letter,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      ...animeGroup.map((anime) {
                        return Column(
                          children: [
                            Padding(
                              padding: const EdgeInsets.fromLTRB(
                                32,
                                14,
                                20,
                                14,
                              ),
                              child: GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder:
                                          (_) => AnimeDetailPage(
                                            endpoint: anime.endpoint,
                                          ),
                                    ),
                                  );
                                },
                                child: Align(
                                  alignment: Alignment.centerLeft,
                                  child: Text(
                                    '° ${anime.title}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            Container(
                              margin: const EdgeInsets.symmetric(
                                horizontal: 20,
                              ),
                              height: 1,
                              color: Colors.white12,
                            ),
                          ],
                        );
                      }).toList(),
                    ],
                  );
                }, childCount: sortedKeys.length),
              ),
              const SliverToBoxAdapter(
                child: Column(children: [SizedBox(height: 32), FooterWidget()]),
              ),
            ],
          );
        },
      ),
    );
  }
}

// Delegate untuk bar huruf A-Z agar tetap di atas saat scroll
class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  final double minHeight;
  final double maxHeight;
  final Widget child;

  _SliverAppBarDelegate({
    required this.minHeight,
    required this.maxHeight,
    required this.child,
  });

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return SizedBox.expand(child: child);
  }

  @override
  double get maxExtent => maxHeight;

  @override
  double get minExtent => minHeight;

  @override
  bool shouldRebuild(covariant SliverPersistentHeaderDelegate oldDelegate) {
    return false;
  }
}
