import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../widgets/sidebar_admin.dart';
import 'widgets/top_favorit_list.dart';
import 'widgets/top_view_anime_list.dart';
import 'widgets/top_favorit_chart.dart';
import 'widgets/top_view_chart.dart';
import 'widgets/section_title.dart';
import 'widgets/user_stats_card.dart';
import 'widgets/TopCommentedEpisodesCard.dart'; // ✅ Rename sesuai konvensi

class StatisticsPage extends StatefulWidget {
  const StatisticsPage({super.key});

  @override
  State<StatisticsPage> createState() => _StatisticsPageState();
}

class _StatisticsPageState extends State<StatisticsPage> {
  Map<String, int> _commentCountByEpisode = {};
  bool _isLoading = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _loadCommentData();
  }

  Future<void> _loadCommentData() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      final snapshot = await FirebaseFirestore.instance
          .collectionGroup('comments')
          .get()
          .timeout(const Duration(seconds: 10));

      final Map<String, int> counts = {};

      for (var doc in snapshot.docs) {
        final paths = doc.reference.path.split('/');
        if (paths.length >= 2) {
          final episodeId = paths[1];
          counts[episodeId] = (counts[episodeId] ?? 0) + 1;
        }
      }

      if (mounted) {
        setState(() {
          _commentCountByEpisode = counts;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("❌ Failed to fetch comments: $e");
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasError = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color background = Color(0xFF121212);
    const Color cardBackground = Color(0xFF1E1E1E);
    const Color textPrimary = Colors.white;

    return Scaffold(
      backgroundColor: background,
      drawer: const AdminSidebar(currentRoute: '/admin/statistics'),
      appBar: AppBar(
        backgroundColor: cardBackground,
        elevation: 1,
        iconTheme: const IconThemeData(
          color: Colors.white,
        ), // agar icon sidebar tetap terlihat
        title: Row(
          children: [
            const Icon(Icons.bar_chart, color: Colors.purpleAccent),
            const SizedBox(width: 8),
            Text(
              'Statistik Detail',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: textPrimary,
              ),
            ),
          ],
        ),
      ),

      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _hasError
              ? _buildErrorState()
              : RefreshIndicator(
                onRefresh: _loadCommentData,
                color: Colors.orangeAccent,
                backgroundColor: background,
                child: CustomScrollView(
                  slivers: [
                    SliverPadding(
                      padding: const EdgeInsets.all(20),
                      sliver: SliverList(
                        delegate: SliverChildListDelegate([
                          const UserStatsCard(),
                          const SizedBox(height: 24),
                          _buildSection(
                            title: 'Top Favorite Anime',
                            icon: Icons.favorite_rounded,
                            listWidget: const TopFavoritAnimeList(),
                            chartWidget: const TopFavoritChart(),
                          ),
                          _buildSection(
                            title: 'Most Viewed Anime',
                            icon: Icons.visibility_rounded,
                            listWidget: const TopViewAnimeList(),
                            chartWidget: const TopViewAnimeChart(),
                          ),
                          const SizedBox(height: 16),
                          SectionTitle(
                            title: 'Most Commented Episodes',
                            icon: Icons.comment_rounded,
                            textStyle: GoogleFonts.poppins(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: textPrimary,
                            ),
                          ),
                          const SizedBox(height: 12),
                          TopCommentedChart(
                            commentCountByEpisode: _commentCountByEpisode,
                          ),
                          const SizedBox(height: 32),
                        ]),
                      ),
                    ),
                  ],
                ),
              ),
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required Widget listWidget,
    required Widget chartWidget,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: Colors.orangeAccent),
            const SizedBox(width: 8),
            Text(
              title,
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        listWidget,
        const SizedBox(height: 20),
        chartWidget,
        const SizedBox(height: 32),
      ],
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.redAccent),
            const SizedBox(height: 16),
            Text(
              'Gagal memuat data',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Periksa koneksi internet Anda dan coba lagi.',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(color: Colors.grey, fontSize: 14),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              icon: const Icon(Icons.refresh),
              label: Text(
                'Coba Lagi',
                style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orangeAccent,
                foregroundColor: Colors.black,
              ),
              onPressed: _loadCommentData,
            ),
          ],
        ),
      ),
    );
  }
}
