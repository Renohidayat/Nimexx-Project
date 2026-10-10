// widgets/episode/modern_episode_list.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../model/anime_detail.dart';
import '../../pages/episode_page.dart';

class ModernEpisodeList extends StatefulWidget {
  final Future<AnimeDetail>? animeDetail;
  final String currentEndpoint;
  final String animeTitle;
  final String thumbUrl;
  final String? animeEndpoint;
  final List<String> watchedEpisodes;

  const ModernEpisodeList({
    super.key,
    required this.animeDetail,
    required this.currentEndpoint,
    required this.animeTitle,
    required this.thumbUrl,
    this.animeEndpoint,
    required this.watchedEpisodes,
  });

  @override
  State<ModernEpisodeList> createState() => _ModernEpisodeListState();
}

class _ModernEpisodeListState extends State<ModernEpisodeList> {
  bool _showEpisodeList = false;
  bool _isAscending = true;
  final ScrollController _scrollController = ScrollController();
  List<Episode> _cachedEpisodes = [];
  bool _isDataLoaded = false;
  String _searchQuery = '';

  // Modern color scheme
  static const Color primaryOrange = Color(0xFFFF6B35);
  static const Color secondaryOrange = Color(0xFFFF8C42);
  static const Color cardBackground = Color(0xFF1A1A1A);
  static const Color surfaceColor = Color(0xFF252525);

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToCurrentEpisode() {
    if (_cachedEpisodes.isEmpty) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Find current episode index in the displayed list (considering sort order)
      int currentIndex = -1;

      for (int i = 0; i < _cachedEpisodes.length; i++) {
        final episodeIndex = _isAscending ? i : _cachedEpisodes.length - 1 - i;
        final ep = _cachedEpisodes[episodeIndex];

        if (ep.endpoint == widget.currentEndpoint) {
          currentIndex = i; // This is the display index, not the data index
          break;
        }
      }

      if (currentIndex != -1 && _scrollController.hasClients) {
        // More accurate item height calculation (padding + content + margin)
        const double itemHeight =
            88.0; // 16 (padding top/bottom) + 60 (content) + 12 (margin bottom)

        final viewportHeight = _scrollController.position.viewportDimension;
        final maxScrollExtent = _scrollController.position.maxScrollExtent;

        // Calculate the exact position to center the item
        final itemTopPosition = currentIndex * itemHeight;
        final itemCenterPosition = itemTopPosition + (itemHeight / 2);
        final viewportCenter = viewportHeight / 2;

        // Target scroll offset to center the item
        final targetOffset = itemCenterPosition - viewportCenter;

        // Clamp to valid scroll range
        final clampedOffset = targetOffset.clamp(0.0, maxScrollExtent);

        // Use a shorter delay for more responsive scrolling
        Future.delayed(const Duration(milliseconds: 50), () {
          if (_scrollController.hasClients) {
            _scrollController.animateTo(
              clampedOffset,
              duration: const Duration(milliseconds: 600),
              curve: Curves.easeOutCubic,
            );
          }
        });
      }
    });
  }

  String _formatEpisodeTitle(String fullTitle) {
    if (fullTitle.toLowerCase().contains('batch')) return 'Batch';
    if (fullTitle.toLowerCase().contains('ova')) return 'OVA';
    if (fullTitle.toLowerCase().contains('movie')) return 'Movie';
    
    final match = RegExp(r'Episode\s*([\d\.\-]+)', caseSensitive: false).firstMatch(fullTitle);
    if (match != null) {
      return 'Episode ${match.group(1)}';
    }
    return fullTitle;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [cardBackground, surfaceColor.withOpacity(0.6)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildEpisodeListToggle(),
          if (_showEpisodeList)
            AnimatedContainer(
              duration: const Duration(milliseconds: 500),
              curve: Curves.easeInOut,
              child: _buildEpisodeList(),
            ),
        ],
      ),
    );
  }

  Widget _buildEpisodeListToggle() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(24),
          topRight: const Radius.circular(24),
          bottomLeft: Radius.circular(_showEpisodeList ? 0 : 24),
          bottomRight: Radius.circular(_showEpisodeList ? 0 : 24),
        ),
        onTap: () {
          setState(() {
            _showEpisodeList = !_showEpisodeList;
          });

          // Scroll to current episode when list is opened
          if (_showEpisodeList && _isDataLoaded) {
            Future.delayed(const Duration(milliseconds: 600), () {
              _scrollToCurrentEpisode();
            });
          }
        },
        child: Container(
          padding: const EdgeInsets.all(24),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [primaryOrange, secondaryOrange],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.playlist_play,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Daftar Episode',
                      style: GoogleFonts.oswald(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      _showEpisodeList
                          ? 'Tap untuk sembunyikan'
                          : 'Tap untuk melihat semua episode',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.white60,
                      ),
                    ),
                  ],
                ),
              ),
              AnimatedRotation(
                turns: _showEpisodeList ? 0.5 : 0,
                duration: const Duration(milliseconds: 300),
                child: const Icon(
                  Icons.keyboard_arrow_down,
                  color: primaryOrange,
                  size: 28,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEpisodeList() {
    if (widget.animeDetail == null) return const SizedBox.shrink();

    return FutureBuilder<AnimeDetail>(
      future: widget.animeDetail!,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Container(
            padding: const EdgeInsets.all(40),
            child: const Center(
              child: CircularProgressIndicator(color: primaryOrange),
            ),
          );
        } else if (snapshot.hasError) {
          return Container(
            padding: const EdgeInsets.all(24),
            child: Center(
              child: Text(
                'Gagal memuat daftar episode',
                style: GoogleFonts.poppins(color: Colors.red[400]),
              ),
            ),
          );
        } else if (!snapshot.hasData) {
          return Container(
            padding: const EdgeInsets.all(24),
            child: Center(
              child: Text(
                'Tidak ada episode tersedia',
                style: GoogleFonts.poppins(color: Colors.white70),
              ),
            ),
          );
        }

        final anime = snapshot.data!;

        // Cache episodes data when first loaded
        if (!_isDataLoaded) {
          _cachedEpisodes = anime.episodes;
          _isDataLoaded = true;

          // Auto scroll to current episode after data is loaded
          WidgetsBinding.instance.addPostFrameCallback((_) {
            Future.delayed(const Duration(milliseconds: 100), () {
              _scrollToCurrentEpisode();
            });
          });
        }

        return Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              _buildSortControls(anime.episodes.length),
              const SizedBox(height: 16),
              
              // Kotak Pencarian Episode
              TextField(
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Cari episode (cth: 12)...',
                  hintStyle: const TextStyle(color: Colors.white54),
                  prefixIcon: const Icon(Icons.search, color: Colors.white54),
                  filled: true,
                  fillColor: Colors.white10,
                  contentPadding: const EdgeInsets.symmetric(vertical: 0),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                ),
                onChanged: (val) {
                  setState(() {
                    _searchQuery = val;
                  });
                },
              ),
              const SizedBox(height: 16),

              _buildEpisodeListView(anime.episodes),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSortControls(int episodeCount) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '$episodeCount Episode',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () {
                setState(() {
                  _isAscending = !_isAscending;
                });

                // Maintain scroll position after sorting
                Future.delayed(const Duration(milliseconds: 100), () {
                  _scrollToCurrentEpisode();
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: primaryOrange.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _isAscending ? Icons.arrow_downward : Icons.arrow_upward,
                      color: primaryOrange,
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _isAscending ? "Awal → Akhir" : "Akhir → Awal",
                      style: GoogleFonts.poppins(
                        color: primaryOrange,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEpisodeListView(List<Episode> allEpisodes) {
    List<Episode> filtered = List.from(allEpisodes);
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((ep) {
        final formatted = _formatEpisodeTitle(ep.title).toLowerCase();
        return formatted.contains(_searchQuery.toLowerCase()) || 
               ep.title.toLowerCase().contains(_searchQuery.toLowerCase());
      }).toList();
    }

    return Container(
      constraints: const BoxConstraints(maxHeight: 400),
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(16)),
      child: ListView.builder(
        controller: _scrollController,
        shrinkWrap: true,
        itemCount: filtered.length,
        itemBuilder: (context, index) {
          final episodeIndex =
              _isAscending ? index : filtered.length - 1 - index;
          final ep = filtered[episodeIndex];
          final isCurrentEpisode = ep.endpoint == widget.currentEndpoint;
          final isWatched = widget.watchedEpisodes.contains(ep.endpoint);

          return _buildEpisodeItem(ep, isCurrentEpisode, isWatched);
        },
      ),
    );
  }

  Widget _buildEpisodeItem(Episode ep, bool isCurrentEpisode, bool isWatched) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap:
              isCurrentEpisode
                  ? null
                  : () {
                    Navigator.pushReplacement(
                      context,
                      PageRouteBuilder(
                        pageBuilder:
                            (context, animation, secondaryAnimation) =>
                                EpisodePage(
                                  endpoint: ep.endpoint,
                                  episodeTitle: ep.title,
                                  animeTitle: widget.animeTitle,
                                  thumbUrl: widget.thumbUrl,
                                  animeEndpoint: widget.animeEndpoint,
                                ),
                        transitionsBuilder: (
                          context,
                          animation,
                          secondaryAnimation,
                          child,
                        ) {
                          return SlideTransition(
                            position: animation.drive(
                              Tween(
                                begin: const Offset(1.0, 0.0),
                                end: Offset.zero,
                              ),
                            ),
                            child: child,
                          );
                        },
                      ),
                    );

                    // After returning, scroll to the NEW current episode (the one we just watched)
                    if (mounted && _scrollController.hasClients) {
                      // Give more time for the widget to rebuild with new currentEndpoint
                      Future.delayed(const Duration(milliseconds: 300), () {
                        _scrollToCurrentEpisode();
                      });
                    }
                  },
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient:
                  isCurrentEpisode
                      ? LinearGradient(
                        colors: [
                          primaryOrange.withOpacity(0.3),
                          secondaryOrange.withOpacity(0.2),
                        ],
                      )
                      : isWatched
                      ? LinearGradient(
                        colors: [
                          Colors.green.withOpacity(0.2),
                          Colors.green.withOpacity(0.1),
                        ],
                      )
                      : LinearGradient(
                        colors: [
                          Colors.white.withOpacity(0.08),
                          Colors.white.withOpacity(0.04),
                        ],
                      ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color:
                    isCurrentEpisode
                        ? primaryOrange.withOpacity(0.5)
                        : Colors.white.withOpacity(0.1),
                width: isCurrentEpisode ? 2 : 1,
              ),
              boxShadow:
                  isCurrentEpisode
                      ? [
                        BoxShadow(
                          color: primaryOrange.withOpacity(0.2),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ]
                      : null,
            ),
            child: Row(
              children: [
                // Episode indicator
                Container(
                  width: 6,
                  height: 40,
                  decoration: BoxDecoration(
                    gradient:
                        isCurrentEpisode
                            ? const LinearGradient(
                              colors: [primaryOrange, secondaryOrange],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            )
                            : LinearGradient(
                              colors:
                                  isWatched
                                      ? [Colors.green, Colors.green.shade300]
                                      : [Colors.white30, Colors.white10],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            ),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
                const SizedBox(width: 16),

                // Episode content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _formatEpisodeTitle(ep.title),
                        style: GoogleFonts.poppins(
                          fontSize: 15,
                          fontWeight:
                              isCurrentEpisode
                                  ? FontWeight.bold
                                  : FontWeight.w500,
                          color:
                              isCurrentEpisode ? primaryOrange : Colors.white,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (isCurrentEpisode || isWatched) ...[
                        const SizedBox(height: 4),
                        Text(
                          isCurrentEpisode
                              ? 'Sedang ditonton'
                              : 'Sudah ditonton',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color:
                                isCurrentEpisode
                                    ? primaryOrange.withOpacity(0.8)
                                    : Colors.green.withOpacity(0.8),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                // Status icons
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color:
                        isCurrentEpisode
                            ? primaryOrange.withOpacity(0.2)
                            : isWatched
                            ? Colors.green.withOpacity(0.2)
                            : Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    isCurrentEpisode
                        ? Icons.play_circle_filled
                        : isWatched
                        ? Icons.check_circle
                        : Icons.play_arrow,
                    color:
                        isCurrentEpisode
                            ? primaryOrange
                            : isWatched
                            ? Colors.green
                            : Colors.white54,
                    size: 20,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
