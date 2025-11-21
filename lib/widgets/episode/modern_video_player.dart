// widgets/episode/modern_video_player.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../pages/episode_webview_mobile.dart';

class ModernVideoPlayer extends StatelessWidget {
  final String streamingUrl;

  // Modern color scheme
  static const Color primaryOrange = Color(0xFFFF6B35);
  static const Color cardBackground = Color(0xFF1A1A1A);
  static const Color surfaceColor = Color(0xFF252525);

  const ModernVideoPlayer({super.key, required this.streamingUrl});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 220,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          colors: [cardBackground, surfaceColor],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: primaryOrange.withOpacity(0.2),
            blurRadius: 25,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          children: [
            EpisodeWebView(url: streamingUrl),
            Positioned(
              top: 12,
              right: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.live_tv, color: primaryOrange, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      'LIVE',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
