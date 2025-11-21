// widgets/episode/modern_quality_section.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../model/episode_detail.dart';

class ModernQualitySection extends StatefulWidget {
  final EpisodeDetail episode;
  final Function(String) onStreamButtonPressed;

  const ModernQualitySection({
    super.key,
    required this.episode,
    required this.onStreamButtonPressed,
  });

  @override
  State<ModernQualitySection> createState() => _ModernQualitySectionState();
}

class _ModernQualitySectionState extends State<ModernQualitySection> {
  final Set<String> _expandedQualities = {};

  // Modern color scheme
  static const Color primaryOrange = Color(0xFFFF6B35);
  static const Color secondaryOrange = Color(0xFFFF8C42);
  static const Color cardBackground = Color(0xFF1A1A1A);
  static const Color surfaceColor = Color(0xFF252525);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
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
                  Icons.high_quality,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 16),
              Text(
                'Pilih Kualitas Streaming',
                style: GoogleFonts.oswald(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildQualityOption('360p', widget.episode.mirror360p, Icons.sd),
          _buildQualityOption('480p', widget.episode.mirror480p, Icons.hd),
          _buildQualityOption('720p', widget.episode.mirror720p, Icons.hd),
        ],
      ),
    );
  }

  Widget _buildQualityOption(
    String quality,
    List<StreamLink> links,
    IconData icon,
  ) {
    final isExpanded = _expandedQualities.contains(quality);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color:
              isExpanded
                  ? primaryOrange.withOpacity(0.5)
                  : Colors.white.withOpacity(0.1),
        ),
      ),
      child: Column(
        children: [
          Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () {
                setState(() {
                  if (isExpanded) {
                    _expandedQualities.remove(quality);
                  } else {
                    _expandedQualities.add(quality);
                  }
                });
              },
              child: Container(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors:
                              isExpanded
                                  ? [primaryOrange, secondaryOrange]
                                  : [Colors.white24, Colors.white12],
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(icon, color: Colors.white, size: 20),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            quality,
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: isExpanded ? primaryOrange : Colors.white,
                            ),
                          ),
                          Text(
                            '${links.length} server tersedia',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: Colors.white60,
                            ),
                          ),
                        ],
                      ),
                    ),
                    AnimatedRotation(
                      turns: isExpanded ? 0.5 : 0,
                      duration: const Duration(milliseconds: 300),
                      child: Icon(
                        Icons.keyboard_arrow_down,
                        color: isExpanded ? primaryOrange : Colors.white60,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (isExpanded)
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              padding: const EdgeInsets.only(left: 20, right: 20, bottom: 20),
              child: Column(
                children:
                    links.isEmpty
                        ? [_buildNoServerMessage()]
                        : links
                            .map((link) => _buildStreamButton(link))
                            .toList(),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildNoServerMessage() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.warning_amber, color: Colors.red[400], size: 20),
          const SizedBox(width: 12),
          Text(
            'Tidak ada server untuk kualitas ini',
            style: GoogleFonts.poppins(color: Colors.red[400], fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildStreamButton(StreamLink link) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => widget.onStreamButtonPressed(link.link),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  primaryOrange.withOpacity(0.8),
                  secondaryOrange.withOpacity(0.6),
                ],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: primaryOrange.withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.play_arrow,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        link.driver,
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        'Klik untuk streaming',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.launch, color: Colors.white70, size: 18),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
