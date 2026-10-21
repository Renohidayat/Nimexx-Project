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
  static const Color primaryOrange = Color(0xFFFF5E1E);
  static const Color surfaceElevated = Color(0xFF171924);
  static const Color surfaceColor = Color(0xFF0F1118);

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
    return _buildEpisodeList();
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

        return Column(
          children: [
            _buildSortControls(anime.episodes.length),
            const SizedBox(height: 16),
            
            // Kotak Pencarian Episode
            TextField(
              style: const TextStyle(color: Colors.white, fontSize: 13),
              decoration: InputDecoration(
                hintText: 'Cari episode...',
                hintStyle: const TextStyle(color: Colors.white54),
                prefixIcon: const Icon(Icons.search, color: Colors.white54, size: 18),
                filled: true,
                fillColor: surfaceElevated,
                contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
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
        );
      },
    );
  }

  Widget _buildSortControls(int episodeCount) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              width: 4,
              height: 16,
              decoration: BoxDecoration(
                color: primaryOrange,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 8),
            const Text(
              'DAFTAR EPISODE',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
        GestureDetector(
          onTap: () {
            setState(() {
              _isAscending = !_isAscending;
            });
            Future.delayed(const Duration(milliseconds: 100), () {
              _scrollToCurrentEpisode();
            });
          },
          child: Text(
            _isAscending ? "Urutkan: Awal → Akhir" : "Urutkan: Akhir → Awal",
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
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
    // Extract the episode number for the icon, or fallback to something short
    final match = RegExp(r'Episode\s*([\d\.]+)').firstMatch(ep.title);
    final String epNum = match != null ? match.group(1)! : 'EP';

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
                          pageBuilder: (context, animation, secondaryAnimation) =>
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

                      if (mounted && _scrollController.hasClients) {
                        Future.delayed(const Duration(milliseconds: 300), () {
                          _scrollToCurrentEpisode();
                        });
                      }
                    },
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isCurrentEpisode ? surfaceElevated : surfaceColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isCurrentEpisode ? primaryOrange.withOpacity(0.5) : Colors.white.withOpacity(0.05),
              ),
              boxShadow: isCurrentEpisode
                  ? [
                      BoxShadow(
                        color: primaryOrange.withOpacity(0.2),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      )
                    ]
                  : [],
            ),
            child: Row(
              children: [
                // Icon / EQ Block
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: isCurrentEpisode ? primaryOrange : Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: isCurrentEpisode ? null : Border.all(color: Colors.white.withOpacity(0.1)),
                  ),
                  child: isCurrentEpisode
                      ? const Padding(
                          padding: EdgeInsets.only(bottom: 12),
                          child: MusicEqualizer(),
                        )
                      : Center(
                          child: Text(
                            epNum.padLeft(2, '0'),
                            style: const TextStyle(
                              color: Colors.white70,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ),
                ),
                const SizedBox(width: 12),
                // Title
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _formatEpisodeTitle(ep.title),
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: isCurrentEpisode ? Colors.white : Colors.white70,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (isCurrentEpisode || isWatched) ...[
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: isCurrentEpisode ? primaryOrange.withOpacity(0.1) : Colors.green.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(
                              color: isCurrentEpisode ? primaryOrange.withOpacity(0.2) : Colors.green.withOpacity(0.2),
                            ),
                          ),
                          child: Text(
                            isCurrentEpisode ? 'NOW PLAYING' : 'WATCHED',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              color: isCurrentEpisode ? primaryOrange : Colors.green,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                // Play Button
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: isCurrentEpisode ? primaryOrange : surfaceElevated,
                    shape: BoxShape.circle,
                    border: isCurrentEpisode ? null : Border.all(color: Colors.white.withOpacity(0.1)),
                  ),
                  child: Center(
                    child: Icon(
                      Icons.play_arrow,
                      color: isCurrentEpisode ? Colors.white : Colors.grey[400],
                      size: 18,
                    ),
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

class MusicEqualizer extends StatefulWidget {
  const MusicEqualizer({super.key});

  @override
  State<MusicEqualizer> createState() => _MusicEqualizerState();
}

class _MusicEqualizerState extends State<MusicEqualizer> with TickerProviderStateMixin {
  late List<AnimationController> _controllers;
  late List<Animation<double>> _animations;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(
      3,
      (index) => AnimationController(
        duration: Duration(milliseconds: 300 + (index * 150)),
        vsync: this,
      )..repeat(reverse: true),
    );
    _animations = _controllers.map((controller) {
      return Tween<double>(begin: 4.0, end: 16.0).animate(
        CurvedAnimation(parent: controller, curve: Curves.easeInOut),
      );
    }).toList();
  }

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: List.generate(3, (index) {
        return AnimatedBuilder(
          animation: _animations[index],
          builder: (context, child) {
            return Container(
              width: 3,
              height: _animations[index].value,
              margin: const EdgeInsets.symmetric(horizontal: 1.5),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(2),
              ),
            );
          },
        );
      }),
    );
  }
}
