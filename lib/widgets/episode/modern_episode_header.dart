// widgets/episode/modern_episode_header.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../model/episode_detail.dart';

class ModernEpisodeHeader extends StatelessWidget {
  final EpisodeDetail episode;
  final VoidCallback onBackPressed;
  final bool isWeb;

  // Modern color scheme
  static const Color primaryOrange = Color(0xFFFF6B35);
  static const Color secondaryOrange = Color(0xFFFF8C42);
  static const Color cardBackground = Color(0xFF1A1A1A);
  static const Color surfaceColor = Color(0xFF252525);

  const ModernEpisodeHeader({
    super.key,
    required this.episode,
    required this.onBackPressed,
    this.isWeb = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [cardBackground, surfaceColor.withOpacity(0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: primaryOrange.withOpacity(0.1),
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
                decoration: BoxDecoration(
                  color: primaryOrange.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: IconButton(
                  icon: const Icon(Icons.arrow_back_ios, color: primaryOrange),
                  onPressed: onBackPressed,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Tonton Episode",
                      style: GoogleFonts.oswald(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: primaryOrange,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      episode.title,
                      style: GoogleFonts.oswald(
                        fontSize: isWeb ? 28 : 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        height: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            height: 4,
            width: 120,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [primaryOrange, secondaryOrange],
              ),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ],
      ),
    );
  }
}
