// widgets/episode/modern_comment_section_wrapper.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../widgets/comment_section.dart';
import '../../service/comment_service.dart';

class ModernCommentSectionWrapper extends StatelessWidget {
  final String episodeId;
  final String episodeTitle;
  final String animeTitle;
  final String thumbUrl;
  final CommentService commentService;
  final String? highlightCommentId;

  // Modern color scheme
  static const Color primaryOrange = Color(0xFFFF6B35);
  static const Color secondaryOrange = Color(0xFFFF8C42);
  static const Color cardBackground = Color(0xFF1A1A1A);
  static const Color surfaceColor = Color(0xFF252525);

  const ModernCommentSectionWrapper({
    super.key,
    required this.episodeId,
    required this.episodeTitle,
    required this.animeTitle,
    required this.thumbUrl,
    required this.commentService,
    this.highlightCommentId,
  });

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
                  Icons.chat_bubble_outline,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 16),
              Text(
                'Komentar Episode',
                style: GoogleFonts.oswald(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          CommentSection(
            episodeId: episodeId,
            episodeTitle: episodeTitle,
            animeTitle: animeTitle,
            thumbUrl: thumbUrl,
            commentService: commentService,
            highlightCommentId: highlightCommentId,
          ),
        ],
      ),
    );
  }
}
