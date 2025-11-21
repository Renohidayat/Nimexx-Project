import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import '../pages/anime_detail_page.dart';
import 'package:google_fonts/google_fonts.dart';

class HeroBanner extends StatefulWidget {
  const HeroBanner({super.key});

  @override
  State<HeroBanner> createState() => _HeroBannerState();
}

class _HeroBannerState extends State<HeroBanner> {
  final List<Map<String, dynamic>> animeList = [
    {
      "title": "Solo Leveling",
      "thumb": "assets/images/solo.jpg",
      "genres": ["Action", "Adventure", "Fantasy"],
      "rating": "8.29",
      "endpoint": "level-solo-sub-indo",
    },
    {
      "title": "One Piece",
      "thumb": "assets/images/one_piece.jpg",
      "genres": [
        "Action",
        "Adventure",
        "Comedy",
        "Drama",
        "Fantasy",
        "Shounen",
        "Super",
        "Power",
      ],
      "status": ["Ongoing"],
      "rating": "8.54",
      "endpoint": "1piece-sub-indo",
    },
    {
      "title": "One Punch Man BD",
      "thumb": "assets/images/one_punch.jpg",
      "genres": [
        "Action",
        "Comedy",
        "Parody",
        "Sci-Fi",
        "Seinen",
        "Super Power",
        "Supernatural",
      ],
      "status": ["Completed"],
      "rating": "8.75",
      "endpoint": "one-punch-sub-indo",
    },
    {
      "title": "Fate Zero",
      "thumb": "assets/images/zero.jpg",
      "genres": ["Action", "Fantasy", "Magic", "Supernatural"],
      "rating": "8.46",
      "endpoint": "fat-zero-subtitle-indonesia",
    },
    {
      "title": "Boruto",
      "thumb": "assets/images/boruto.jpg",
      "genres": [
        "Action",
        "Adventure",
        "Martial Arts",
        "Shounen",
        "Super Power",
      ],
      "status": ["Ongoing"],
      "rating": "6.15",
      "endpoint": "borot-sub-indo",
    },
    {
      "title": "Sword Art Online",
      "thumb": "assets/images/sao.jpg",
      "genres": ["Action", " Adventure", " Fantasy", " Game", " Romance"],
      "status": ["Ongoing"],
      "rating": "7.76",
      "endpoint": "sawo-sub-indo",
    },
    {
      "title": "Jujutsu Kaisen",
      "thumb": "assets/images/jujutsu.jpg",
      "genres": [
        "Action",
        "Demons",
        "Horror",
        "School",
        "Shounen",
        "Supernatural",
      ],
      "status": ["Completed"],
      "rating": "8.78",
      "endpoint": "jjk-sub-indo",
    },
    {
      "title": "Tensei shitara",
      "thumb": "assets/images/tensei.jpg",
      "genres": ["Adventure", "Fantasy", "Reincarnation"],
      "status": ["Completed"],
      "rating": "7.45",
      "endpoint": "slime-s3-sub-indo",
    },
    {
      "title": "Bleach: Sennen Kessen-hen",
      "thumb": "assets/images/bleach.jpg",
      "genres": ["Action", "Adventure", "Fantasy", "Shounen"],
      "status": ["Completed"],
      "rating": "9.11",
      "endpoint": "blch-kesen-hen-sub-indo",
    },
    {
      "title": "Vinland Saga",
      "thumb": "assets/images/vinlan.jpg",
      "genres": ["Action", "Adventure", "Drama", "Historical", "Seinen"],
      "rating": "8.77",
      "endpoint": "vld-saga-sub-indo",
    },
    {
      "title": "Dororo",
      "thumb": "assets/images/dororo.jpg",
      "genres": [
        "Action",
        "Adventure",
        "Demons",
        "Historical",
        "Shounen",
        "Supernatural",
      ],
      "rating": "8.35",
      "endpoint": "droro-subtitle-indonesia",
    },
    {
      "title": "Zankyou no Terror",
      "thumb": "assets/images/teror.jpg",
      "genres": ["Psychological", " Thriller"],
      "rating": "8.23",
      "endpoint": "zankyou-no-terror",
    },
    {
      "title": "Kimetsu no Yaiba",
      "thumb": "assets/images/kny.jpg",
      "genres": ["Action", "Demons", "Historical", "Shounen", "Supernatural"],
      "rating": "8.93",
      "endpoint": "kimetsu-yaiba-subtitle-indonesia",
    },
    {
      "title": "Vivy",
      "thumb": "assets/images/vivy.jpg",
      "genres": ["Action", "Music", "Sci-Fi", "Thriller"],
      "rating": "8.59",
      "endpoint": "vivy-sub-indo",
    },
    {
      "title": "Eighty Six",
      "thumb": "assets/images/86.jpg",
      "genres": ["Action", "Drama", "Mecha", "Military", "Sci-Fi"],
      "rating": "8.23",
      "endpoint": "86-sub-indo",
    },
  ];

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isMobile = width < 600;
    final isTablet = width >= 600 && width < 900;

    final double bannerHeight = isMobile ? 260 : (isTablet ? 380 : 520);
    final double titleFontSize = isMobile ? 18 : (isTablet ? 24 : 36);
    final double descFontSize = isMobile ? 11 : 14;
    final double buttonFontSize = isMobile ? 12 : 16;
    final double radius = 20;

    return CarouselSlider.builder(
      itemCount: animeList.length,
      options: CarouselOptions(
        height: bannerHeight,
        autoPlay: true,
        autoPlayInterval: const Duration(seconds: 5),
        viewportFraction: isMobile ? 0.9 : 1.0,
        enlargeCenterPage: isMobile,
      ),
      itemBuilder: (context, index, realIndex) {
        final anime = animeList[index];
        final title = anime['title'] as String;
        final genres = (anime['genres'] as List).join(', ');
        final thumb = anime['thumb'] as String;

        return Container(
          margin: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(radius),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(radius),
            child: Stack(
              children: [
                SizedBox(
                  width: double.infinity,
                  height: bannerHeight,
                  child: Image.asset(
                    thumb,
                    fit: BoxFit.cover,
                    errorBuilder:
                        (context, error, stackTrace) => const Center(
                          child: Icon(
                            Icons.broken_image,
                            size: 50,
                            color: Colors.grey,
                          ),
                        ),
                  ),
                ),
                Container(
                  height: bannerHeight,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      stops: [0.0, 0.9],
                      colors: [
                        Colors.black.withOpacity(0.7),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
                Positioned(
                  left: 20,
                  bottom: 20,
                  right: 20,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title.toUpperCase(),
                        style: GoogleFonts.oswald(
                          fontSize: titleFontSize,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          shadows: [
                            Shadow(
                              blurRadius: 4,
                              color: Colors.black.withOpacity(0.8),
                              offset: const Offset(1, 2),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        genres,
                        style: TextStyle(
                          fontSize: descFontSize,
                          color: Colors.white70,
                        ),
                      ),
                      const SizedBox(height: 10),
                      ElevatedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder:
                                  (_) => AnimeDetailPage(
                                    endpoint: anime['endpoint'],
                                    title: title,
                                  ),
                            ),
                          );
                        },
                        icon: const Icon(Icons.play_arrow),
                        label: Text(
                          'Mulai Menonton',
                          style: TextStyle(
                            fontSize: buttonFontSize,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color.fromARGB(255, 255, 0, 0),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                          elevation: 5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
