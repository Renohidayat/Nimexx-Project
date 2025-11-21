import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';

class TopFavoritAnimeList extends StatefulWidget {
  const TopFavoritAnimeList({super.key});

  @override
  State<TopFavoritAnimeList> createState() => _TopFavoritAnimeListState();
}

class _TopFavoritAnimeListState extends State<TopFavoritAnimeList> {
  bool _isLoading = true;
  List<AnimeFavorite> _topFavorites = [];
  bool _isExpanded = false;
  final int _initialItemCount = 5;
  final int _expandedItemCount = 10;

  @override
  void initState() {
    super.initState();
    _fetchTopFavoritAnime();
  }

  Future<void> _fetchTopFavoritAnime() async {
    try {
      final snapshot =
          await FirebaseFirestore.instance
              .collectionGroup('favorites')
              .limit(500)
              .get();

      final animeMap = <String, AnimeFavorite>{};

      for (var doc in snapshot.docs) {
        final data = doc.data();
        final animeId = data['endpoint'];
        final title = data['title'] ?? 'Unknown Title';
        final thumb = data['thumb'];

        if (animeId == null) continue;

        if (animeMap.containsKey(animeId)) {
          animeMap[animeId] = animeMap[animeId]!.incrementCount();
        } else {
          animeMap[animeId] = AnimeFavorite(
            animeId: animeId,
            title: title,
            thumb: thumb,
            count: 1,
          );
        }
      }

      final sortedList =
          animeMap.values.toList()..sort((a, b) => b.count.compareTo(a.count));

      if (mounted) {
        setState(() {
          _topFavorites = sortedList;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching top favorite anime: $e');
      if (mounted) {
        setState(() {
          _topFavorites = [];
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
            ? _topFavorites.take(_expandedItemCount).toList()
            : _topFavorites.take(_initialItemCount).toList();

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
                : _topFavorites.isEmpty
                ? _buildEmptyState(theme)
                : Column(
                  children: [
                    ...displayedAnime.map(
                      (anime) => _buildAnimeItem(
                        anime,
                        _topFavorites.indexOf(anime) + 1,
                        theme,
                      ),
                    ),
                    if (_topFavorites.length > _initialItemCount)
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
              Icons.favorite_rounded,
              color: theme.colorScheme.secondary,
              size: 24,
            ),
            const SizedBox(width: 8),
            Text(
              "Top Anime Favorit",
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        if (_topFavorites.length > _initialItemCount)
          IconButton(
            icon: Icon(
              _isExpanded ? Icons.expand_less : Icons.expand_more,
              color: theme.colorScheme.secondary,
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
            Icons.favorite_border_rounded,
            size: 40,
            color: theme.disabledColor,
          ),
          const SizedBox(height: 8),
          Text(
            "Belum ada data favorit",
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.disabledColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnimeItem(AnimeFavorite anime, int rank, ThemeData theme) {
    final isDark = theme.brightness == Brightness.dark;
    final rankColor = _getRankColor(rank);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
                          Icons.favorite_rounded,
                          size: 14,
                          color: theme.colorScheme.secondary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${anime.count} favorit',
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Chevron Icon
              Icon(
                Icons.chevron_right_rounded,
                color: theme.textTheme.bodySmall?.color,
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
      style: TextButton.styleFrom(foregroundColor: theme.colorScheme.secondary),
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

class AnimeFavorite {
  final String animeId;
  final String title;
  final String? thumb;
  final int count;

  AnimeFavorite({
    required this.animeId,
    required this.title,
    this.thumb,
    required this.count,
  });

  AnimeFavorite incrementCount() {
    return AnimeFavorite(
      animeId: animeId,
      title: title,
      thumb: thumb,
      count: count + 1,
    );
  }
}
