import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import '../pages/anime_detail_page.dart';
import '../pages/episode_page.dart';
import '../service/remote_config_service.dart';

class HomePersonalSection extends StatelessWidget {
  const HomePersonalSection({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHistorySection(context, user.uid),
        const SizedBox(height: 32),
        _buildFavoriteSection(context, user.uid),
      ],
    );
  }

  Widget _buildHistorySection(BuildContext context, String uid) {
    final width = MediaQuery.of(context).size.width;
    final horizontalPadding = width < 600 ? 16.0 : 100.0;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 10),
          _SectionTitle(title: 'LANJUTKAN MENONTON'),
          const SizedBox(height: 20),
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('watch_history')
                .doc(uid)
                .collection('history')
                .orderBy('watchedAt', descending: true)
                .limit(10)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const Text(
                  'Belum ada riwayat tontonan.',
                  style: TextStyle(color: Colors.white54, fontSize: 14),
                );
              }

              final docs = snapshot.data!.docs;

              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: docs.map((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    return Padding(
                      padding: const EdgeInsets.only(right: 16.0),
                      child: SizedBox(
                        width: width < 600 ? 140 : 220,
                        child: _HistoryCard(
                          episodeId: data['episodeId'] ?? '',
                          episodeTitle: data['title'] ?? '',
                          animeTitle: data['animeTitle'] ?? 'Anime',
                          thumbUrl: data['thumb'] ?? '',
                          animeEndpoint: data['animeEndpoint'] ?? '',
                        ),
                      ),
                    );
                  }).toList(),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildFavoriteSection(BuildContext context, String uid) {
    final width = MediaQuery.of(context).size.width;
    final horizontalPadding = width < 600 ? 16.0 : 100.0;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionTitle(title: 'KOLEKSI SAYA'),
          const SizedBox(height: 20),
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('users')
                .doc(uid)
                .collection('favorites')
                .limit(10)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const Text(
                  'Belum ada anime favorit yang disimpan.',
                  style: TextStyle(color: Colors.white54, fontSize: 14),
                );
              }

              final docs = snapshot.data!.docs;

              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: docs.map((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    return Padding(
                      padding: const EdgeInsets.only(right: 16.0),
                      child: SizedBox(
                        width: width < 600 ? 140 : 220,
                        child: _FavoriteCard(
                          endpoint: doc.id,
                          title: data['title'] ?? 'Anime',
                          imageUrl: data['thumb'] ?? data['imageUrl'] ?? '',
                        ),
                      ),
                    );
                  }).toList(),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: const BoxDecoration(
        border: Border(
          left: BorderSide(color: Color.fromARGB(255, 255, 0, 0), width: 4),
        ),
      ),
      child: Text(
        title,
        style: GoogleFonts.oswald(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: Colors.white,
          letterSpacing: 1.5,
        ),
      ),
    );
  }
}

class _HistoryCard extends StatelessWidget {
  final String episodeId;
  final String episodeTitle;
  final String animeTitle;
  final String thumbUrl;
  final String animeEndpoint;

  const _HistoryCard({
    required this.episodeId,
    required this.episodeTitle,
    required this.animeTitle,
    required this.thumbUrl,
    required this.animeEndpoint,
  });

  @override
  Widget build(BuildContext context) {
    final String fullThumbUrl = thumbUrl.startsWith('http')
        ? thumbUrl
        : '${RemoteConfigService.baseUrl}/$thumbUrl';

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => EpisodePage(
              endpoint: episodeId,
              episodeTitle: episodeTitle,
              animeTitle: animeTitle,
              thumbUrl: thumbUrl,
              animeEndpoint: animeEndpoint.isNotEmpty ? animeEndpoint : null,
            ),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: const Color(0xFF1A1A1A),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.5),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                AspectRatio(
                  aspectRatio: 16 / 9,
                  child: Image.network(
                    fullThumbUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(color: Colors.grey[900]),
                  ),
                ),
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [
                          Colors.black.withOpacity(0.9),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 8,
                  left: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      _extractEpisodeNumber(episodeTitle),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const Positioned.fill(
                  child: Center(
                    child: Icon(Icons.play_circle_outline, color: Colors.white70, size: 40),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                animeTitle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  height: 1.2,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _extractEpisodeNumber(String fullTitle) {
    // Mencoba mencari kata "Episode X"
    final match = RegExp(r'Episode\s*([\d\.\-]+)', caseSensitive: false).firstMatch(fullTitle);
    if (match != null) {
      return 'Eps ${match.group(1)}';
    }
    // Mencoba mencari "OVA" atau "Movie"
    if (fullTitle.toLowerCase().contains('ova')) return 'OVA';
    if (fullTitle.toLowerCase().contains('movie')) return 'Movie';
    
    return 'Lanjutkan';
  }
}

class _FavoriteCard extends StatelessWidget {
  final String endpoint;
  final String title;
  final String imageUrl;

  const _FavoriteCard({
    required this.endpoint,
    required this.title,
    required this.imageUrl,
  });

  @override
  Widget build(BuildContext context) {
    final String fullImageUrl = imageUrl.startsWith('http')
        ? imageUrl
        : '${RemoteConfigService.baseUrl}/$imageUrl';

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => AnimeDetailPage(endpoint: endpoint),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: const Color(0xFF1A1A1A),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.5),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: 3 / 4,
              child: Image.network(
                fullImageUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(color: Colors.grey[900]),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  height: 1.2,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
