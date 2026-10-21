// widgets/episode/modern_comment_section_wrapper.dart
import 'package:flutter/material.dart';
import '../../widgets/comment_section.dart';
import '../../service/comment_service.dart';

class ModernCommentSectionWrapper extends StatefulWidget {
  final String episodeId;
  final String episodeTitle;
  final String animeTitle;
  final String thumbUrl;
  final CommentService commentService;
  final String? highlightCommentId;

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
  State<ModernCommentSectionWrapper> createState() => _ModernCommentSectionWrapperState();
}

class _ModernCommentSectionWrapperState extends State<ModernCommentSectionWrapper> {
  bool _isDescending = true;
  static const Color primaryOrange = Color(0xFFFF5E1E);
  static const Color surfaceColor = Color(0xFF0F1118);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: Colors.white.withOpacity(0.05))),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: primaryOrange.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: primaryOrange.withOpacity(0.3)),
                    ),
                    child: const Center(
                      child: Icon(Icons.chat_bubble_outline, color: primaryOrange, size: 20),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'DISKUSI & KOMENTAR',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 0.5,
                        ),
                      ),
                      Text(
                        'Komentar Episode',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              PopupMenuButton<bool>(
                initialValue: _isDescending,
                color: const Color(0xFF171924),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: const BorderSide(color: Colors.white12),
                ),
                onSelected: (bool value) {
                  setState(() {
                    _isDescending = value;
                  });
                },
                itemBuilder: (BuildContext context) => [
                  PopupMenuItem<bool>(
                    value: true,
                    child: Row(
                      children: [
                        Icon(
                          Icons.schedule,
                          size: 16,
                          color: _isDescending ? primaryOrange : Colors.grey[400],
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Terbaru',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: _isDescending ? FontWeight.bold : FontWeight.normal,
                            color: _isDescending ? primaryOrange : Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                  PopupMenuItem<bool>(
                    value: false,
                    child: Row(
                      children: [
                        Icon(
                          Icons.history,
                          size: 16,
                          color: !_isDescending ? primaryOrange : Colors.grey[400],
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Terlama',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: !_isDescending ? FontWeight.bold : FontWeight.normal,
                            color: !_isDescending ? primaryOrange : Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: surfaceColor,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.white.withOpacity(0.1)),
                  ),
                  child: Row(
                    children: [
                      Text(
                        _isDescending ? 'Terbaru' : 'Terlama',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[300],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(Icons.keyboard_arrow_down, color: Colors.grey[400], size: 14),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        CommentSection(
          episodeId: widget.episodeId,
          episodeTitle: widget.episodeTitle,
          animeTitle: widget.animeTitle,
          thumbUrl: widget.thumbUrl,
          commentService: widget.commentService,
          highlightCommentId: widget.highlightCommentId,
          isDescending: _isDescending,
        ),
      ],
    );
  }
}
