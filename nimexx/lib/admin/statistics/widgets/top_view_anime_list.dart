import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';

class TopViewAnimeList extends StatefulWidget {
  const TopViewAnimeList({super.key});

  @override
  State<TopViewAnimeList> createState() => _TopViewAnimeListState();
}

class _TopViewAnimeListState extends State<TopViewAnimeList> {
  bool _isLoading = true;
  List<AnimeView> _topViewedAnime = [];
  bool _isExpanded = false;
  final int _initialItemCount = 5;
  final int _expandedItemCount = 15;

  @override
  void initState() {
    super.initState();
    _fetchTopViewedAnime();
  }

  Future<void> _fetchTopViewedAnime() async {
    try {
      final snapshot =
          await FirebaseFirestore.instance
              .collectionGroup('history')
              .where('isWatched', isEqualTo: true)
              .limit(1000)
              .get();

      final animeMap = <String, AnimeView>{};

      for (var doc in snapshot.docs) {
        final data = doc.data();
        final animeId = data['animeId'] ?? data['episodeId'];
        final title = data['animeTitle'] ?? 'Unknown Title';
        final thumb = data['thumb'];

        if (animeId == null) continue;

        if (animeMap.containsKey(animeId)) {
          animeMap[animeId] = animeMap[animeId]!.incrementView();
        } else {
          animeMap[animeId] = AnimeView(
            animeId: animeId,
            title: title,
            thumb: thumb,
            viewCount: 1,
          );
        }
      }

      final sortedList =
          animeMap.values.toList()
            ..sort((a, b) => b.viewCount.compareTo(a.viewCount));

      if (mounted) {
        setState(() {
          _topViewedAnime = sortedList;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching top viewed anime: $e');
      if (mounted) {
        setState(() {
          _topViewedAnime = [];
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final displayedAnime =
        _isExpanded
            ? _topViewedAnime.take(_expandedItemCount).toList()
            : _topViewedAnime.take(_initialItemCount).toList();

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: theme.dividerColor.withOpacity(0.1), width: 1),
      ),
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(theme),
            const SizedBox(height: 12),
            _isLoading
                ? _buildShimmerLoading(theme)
                : _topViewedAnime.isEmpty
                ? _buildEmptyState(theme)
                : Column(
                  children: [
                    ...displayedAnime.asMap().entries.map((entry) {
                      final index = entry.key;
                      final anime = entry.value;
                      return _buildAnimeItem(
                        anime,
                        index + 1,
                        theme,
                        isLast: index == displayedAnime.length - 1,
                      );
                    }),
                    if (_topViewedAnime.length > _initialItemCount)
                      _buildExpandButton(theme),
                  ],
                ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeData theme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Icon(
              Icons.trending_up_rounded,
              color: theme.colorScheme.primary,
              size: 24,
            ),
            const SizedBox(width: 8),
            Text(
              "Top Anime Ditonton",
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        if (_topViewedAnime.length > _initialItemCount)
          IconButton(
            icon: Icon(
              _isExpanded ? Icons.expand_less : Icons.expand_more,
              color: theme.colorScheme.primary,
            ),
            onPressed: () => setState(() => _isExpanded = !_isExpanded),
          ),
      ],
    );
  }

  Widget _buildShimmerLoading(ThemeData theme) {
    return Shimmer.fromColors(
      baseColor:
          theme.brightness == Brightness.dark
              ? Colors.grey[800]!
              : Colors.grey[300]!,
      highlightColor:
          theme.brightness == Brightness.dark
              ? Colors.grey[600]!
              : Colors.grey[100]!,
      child: Column(
        children: List.generate(
          _initialItemCount,
          (index) => Container(
            margin: const EdgeInsets.only(bottom: 12),
            child: Row(
              children: [
                Container(
                  width: 60,
                  height: 80,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        height: 16,
                        width: double.infinity,
                        color: Colors.white,
                      ),
                      const SizedBox(height: 8),
                      Container(height: 14, width: 100, color: Colors.white),
                    ],
                  ),
                ),
                Container(
                  width: 60,
                  height: 24,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Column(
        children: [
          Icon(
            Icons.visibility_off_rounded,
            size: 40,
            color: theme.disabledColor,
          ),
          const SizedBox(height: 8),
          Text(
            "Belum ada data tontonan",
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.disabledColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnimeItem(
    AnimeView anime,
    int rank,
    ThemeData theme, {
    bool isLast = false,
  }) {
    final rankColor = _getRankColor(rank);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      margin: EdgeInsets.only(bottom: isLast ? 0 : 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color:
            isDark
                ? Colors.grey.withOpacity(0.1)
                : Colors.grey.withOpacity(0.05),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          // Navigate to anime detail
        },
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Rank Badge
              Container(
                width: 32,
                height: 32,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [rankColor.withOpacity(0.8), rankColor],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: rankColor.withOpacity(0.3),
                      blurRadius: 6,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Text(
                  '$rank',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Anime Thumbnail
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: CachedNetworkImage(
                  imageUrl: anime.thumb ?? '',
                  width: 60,
                  height: 80,
                  fit: BoxFit.cover,
                  placeholder:
                      (context, url) => Container(
                        color: isDark ? Colors.grey[800] : Colors.grey[200],
                      ),
                  errorWidget:
                      (context, url, error) => Container(
                        color: isDark ? Colors.grey[800] : Colors.grey[200],
                        child: Icon(
                          Icons.broken_image,
                          color: isDark ? Colors.grey[600] : Colors.grey[400],
                        ),
                      ),
                ),
              ),
              const SizedBox(width: 12),
              // Anime Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      anime.title,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.remove_red_eye_outlined,
                          size: 14,
                          color: theme.textTheme.bodySmall?.color,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${anime.viewCount} views',
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Rank Indicator
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: rankColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: rankColor.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Text(
                  '#$rank',
                  style: TextStyle(
                    color: rankColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildExpandButton(ThemeData theme) {
    return TextButton(
      onPressed: () => setState(() => _isExpanded = !_isExpanded),
      style: TextButton.styleFrom(foregroundColor: theme.colorScheme.primary),
      child: Text(
        _isExpanded ? 'Tampilkan Lebih Sedikit' : 'Tampilkan Lebih Banyak',
      ),
    );
  }

  Color _getRankColor(int rank) {
    switch (rank) {
      case 1:
        return const Color(0xFFFFD700); // Gold
      case 2:
        return const Color(0xFFC0C0C0); // Silver
      case 3:
        return const Color(0xFFCD7F32); // Bronze
      default:
        return Colors.blueGrey;
    }
  }
}

class AnimeView {
  final String animeId;
  final String title;
  final String? thumb;
  final int viewCount;

  AnimeView({
    required this.animeId,
    required this.title,
    this.thumb,
    required this.viewCount,
  });

  AnimeView incrementView() {
    return AnimeView(
      animeId: animeId,
      title: title,
      thumb: thumb,
      viewCount: viewCount + 1,
    );
  }
}
