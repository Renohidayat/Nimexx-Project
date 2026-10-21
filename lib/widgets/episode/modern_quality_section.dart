// widgets/episode/modern_quality_section.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../model/episode_detail.dart';

class ModernQualitySection extends StatefulWidget {
  final EpisodeDetail episode;
  final Function(String) onStreamButtonPressed;
  final bool isFetchingStream;

  const ModernQualitySection({
    super.key,
    required this.episode,
    required this.onStreamButtonPressed,
    this.isFetchingStream = false,
  });

  @override
  State<ModernQualitySection> createState() => _ModernQualitySectionState();
}

class _ModernQualitySectionState extends State<ModernQualitySection> {
  final Set<String> _expandedQualities = {};

  // Modern color scheme
  static const Color primaryOrange = Color(0xFFFF5E1E);
  static const Color surfaceColor = Color(0xFF0F1118);
  static const Color surfaceElevated = Color(0xFF171924);

  @override
  Widget build(BuildContext context) {
    final int totalServers = widget.episode.mirror360p.length +
        widget.episode.mirror480p.length +
        widget.episode.mirror720p.length;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: primaryOrange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: primaryOrange.withOpacity(0.2)),
                ),
                child: const Center(
                  child: Icon(Icons.high_quality, color: primaryOrange, size: 16),
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Kualitas Streaming',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    '$totalServers server tersedia online',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey[400],
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildQualityOption('720p', 'High Definition', 'HD', widget.episode.mirror720p),
          _buildQualityOption('480p', 'Standard', 'SD', widget.episode.mirror480p),
          _buildQualityOption('360p', 'Hemat Kuota', 'SD', widget.episode.mirror360p),
        ],
      ),
    );
  }

  Widget _buildQualityOption(
    String quality,
    String description,
    String badge,
    List<StreamLink> links,
  ) {
    final isExpanded = _expandedQualities.contains(quality);

    if (links.isEmpty) return const SizedBox.shrink();

    if (!isExpanded) {
      return GestureDetector(
        onTap: () {
          setState(() {
            _expandedQualities.add(quality);
          });
        },
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: surfaceElevated,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withOpacity(0.05)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Center(
                      child: Text(
                        badge,
                        style: TextStyle(
                          color: Colors.grey[300],
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '$quality $description (${links.length} Server)',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
              const Icon(Icons.keyboard_arrow_down, color: Colors.white54, size: 16),
            ],
          ),
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: primaryOrange.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: primaryOrange.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          GestureDetector(
            onTap: () {
              setState(() {
                _expandedQualities.remove(quality);
              });
            },
            child: Container(
              padding: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: primaryOrange.withOpacity(0.1))),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: primaryOrange,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Center(
                          child: Text(
                            badge,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '$quality $description',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  const Icon(Icons.keyboard_arrow_up, color: Colors.white54, size: 16),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 2.5,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemCount: links.length,
            itemBuilder: (context, index) {
              final link = links[index];
              return _buildStreamButton(link, index == 0); // first is "Recommended"
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStreamButton(StreamLink link, bool isRecommended) {
    return GestureDetector(
      onTap: () => widget.onStreamButtonPressed(link.link),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: isRecommended ? primaryOrange : surfaceElevated,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isRecommended ? Colors.transparent : Colors.white.withOpacity(0.05),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    link.driver,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: isRecommended ? FontWeight.bold : FontWeight.w600,
                      color: isRecommended ? Colors.white : Colors.grey[200],
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (widget.isFetchingStream)
                  SizedBox(
                    width: 12,
                    height: 12,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        isRecommended ? Colors.white : Colors.grey,
                      ),
                    ),
                  )
                else
                  Icon(
                    Icons.play_circle_outline,
                    color: isRecommended ? Colors.white : Colors.grey[400],
                    size: 14,
                  ),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              isRecommended ? 'Recommended' : 'Tersedia',
              style: TextStyle(
                fontSize: 10,
                color: isRecommended ? Colors.white.withOpacity(0.8) : Colors.grey[400],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
