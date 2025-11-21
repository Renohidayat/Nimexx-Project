import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../service/anime_service.dart';
import '../model/genre_model.dart';
import 'genre_anime_page.dart';
import '../widgets/web_app_bar.dart';
import 'package:google_fonts/google_fonts.dart';
import '../widgets/footer_widget.dart';
import '../widgets/anime_loading_screens.dart';

class GenreListPage extends StatefulWidget {
  const GenreListPage({Key? key}) : super(key: key);

  @override
  State<GenreListPage> createState() => _GenreListPageState();
}

class _GenreListPageState extends State<GenreListPage> {
  final AnimeService _service = AnimeService();
  late Future<List<GenreModel>> _genres;

  int _selectedIndex = 4;

  void _handleMenuSelected(int index) {
    setState(() {
      _selectedIndex = index;
    });
    _onWebNavSelected(index);
  }

  @override
  void initState() {
    super.initState();
    _genres = _service.fetchGenres();
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
        break;
      case 5:
        Navigator.pushNamed(context, '/search');
        break;
    }
  }

  int _calculateCrossAxisCount(double width) {
    if (width >= 1400) return 5;
    if (width >= 1100) return 4;
    if (width >= 800) return 3;
    return 2;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar:
          !kIsWeb
              ? AppBar(
                backgroundColor: Colors.black,
                title: Text(
                  'NimeXx',
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
      body: FutureBuilder<List<GenreModel>>(
        future: _genres,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return ModernLoadingScreens.buildLoadingScreen(
              selectedIndex: _selectedIndex,
              onMenuSelected: _handleMenuSelected,
            );
          }
          // Handle error state
          // Jika tidak ada data
          else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return ModernLoadingScreens.buildNoDataScreen(
              selectedIndex: _selectedIndex,
              onMenuSelected: _handleMenuSelected,
            );
          }
          final list = snapshot.data ?? [];

          return LayoutBuilder(
            builder: (context, constraints) {
              final crossAxisCount = _calculateCrossAxisCount(
                constraints.maxWidth,
              );
              final isMobile = constraints.maxWidth < 600;

              return CustomScrollView(
                slivers: [
                  if (kIsWeb)
                    SliverToBoxAdapter(
                      child: WebAppBar(
                        selectedIndex: 4,
                        onSelected: _onWebNavSelected,
                      ),
                    ),

                  SliverPadding(
                    padding: EdgeInsets.symmetric(
                      horizontal: isMobile ? 16 : 60,
                      vertical: 30,
                    ),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate([
                        Text(
                          'GENRE LIST',
                          style: GoogleFonts.oswald(
                            textStyle: const TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.5,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Container(
                            width: 70, // atur panjang sesuai selera
                            height: 4,
                            color: Colors.orange,
                          ),
                        ),

                        const SizedBox(height: 20),
                        GridView.builder(
                          itemCount: list.length,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: crossAxisCount,
                                crossAxisSpacing: 16,
                                mainAxisSpacing: 16,
                                childAspectRatio: 3.5,
                              ),
                          itemBuilder: (context, index) {
                            final genre = list[index];
                            return GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder:
                                        (_) => GenreAnimePage(
                                          endpoint: genre.endpoint,
                                          title: genre.genre,
                                        ),
                                  ),
                                );
                              },
                              child: Container(
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: Colors.orange,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  genre.genre,
                                  style: GoogleFonts.oswald(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1.0,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 40),
                      ]),
                    ),
                  ),

                  if (kIsWeb) const SliverToBoxAdapter(child: FooterWidget()),
                ],
              );
            },
          );
        },
      ),
    );
  }
}

class DummySearchDelegate extends SearchDelegate {
  @override
  List<Widget>? buildActions(BuildContext context) {
    return [
      IconButton(onPressed: () => query = '', icon: const Icon(Icons.clear)),
    ];
  }

  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(
      onPressed: () => close(context, null),
      icon: const Icon(Icons.arrow_back),
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return Center(child: Text('Hasil pencarian: $query'));
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return Center(child: Text('Cari: $query'));
  }
}
