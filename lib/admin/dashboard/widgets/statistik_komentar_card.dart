import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:timeago/timeago.dart' as timeago;

class KomentarStatistikCard extends StatefulWidget {
  const KomentarStatistikCard({super.key});

  @override
  State<KomentarStatistikCard> createState() => _KomentarStatistikCardState();
}

class _KomentarStatistikCardState extends State<KomentarStatistikCard> {
  bool _loading = true;
  List<Map<String, dynamic>> _latestComments = [];
  Map<String, int> _commentCountByEpisode = {};
  bool _showAll = false;

  @override
  void initState() {
    super.initState();
    _loadKomentarData();
  }

  Future<void> _loadKomentarData() async {
    try {
      final snapshot =
          await FirebaseFirestore.instance
              .collectionGroup('comments')
              .orderBy('timestamp', descending: true)
              .limit(30)
              .get();

      final comments =
          snapshot.docs.map((doc) {
            final data = doc.data();
            return {
              'username': data['username'] ?? 'Anonim',
              'content': data['content'] ?? '',
              'timestamp': (data['timestamp'] as Timestamp?)?.toDate(),
            };
          }).toList();

      final counts = <String, int>{};
      for (var doc in snapshot.docs) {
        final episodeId = doc.reference.path.split('/')[1];
        counts[episodeId] = (counts[episodeId] ?? 0) + 1;
      }

      setState(() {
        _latestComments = comments;
        _commentCountByEpisode = counts;
        _loading = false;
      });
    } catch (e) {
      debugPrint('❌ Gagal mengambil komentar: $e');
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final commentsToShow =
        _showAll ? _latestComments : _latestComments.take(5).toList();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color:
            isDark
                ? Colors.grey[900]!.withOpacity(0.6)
                : Colors.white.withOpacity(0.96),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          if (!isDark)
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              blurRadius: 20,
              spreadRadius: 2,
              offset: const Offset(0, 10),
            ),
        ],
      ),
      child:
          _loading
              ? _buildLoadingState(isDark)
              : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeaderSection(isDark),
                  const SizedBox(height: 16),
                  if (commentsToShow.isEmpty) _buildEmptyState(isDark),
                  if (commentsToShow.isNotEmpty) ...[
                    _buildCommentsList(commentsToShow, isDark),
                    if (_latestComments.length > 5)
                      _buildShowMoreButton(isDark),
                  ],
                  const SizedBox(height: 24),
                  _buildTopEpisodesSection(isDark),
                ],
              ),
    );
  }

  Widget _buildLoadingState(bool isDark) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: isDark ? Colors.white70 : Colors.black54,
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.forum_outlined,
              size: 40,
              color: isDark ? Colors.white38 : Colors.black26,
            ),
            const SizedBox(height: 8),
            Text(
              "No comments yet",
              style: TextStyle(
                color: isDark ? Colors.white54 : Colors.black45,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderSection(bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Row(
        children: [
          Icon(
            Icons.forum_rounded,
            color: isDark ? Colors.blueAccent[200] : Colors.blueAccent,
            size: 24,
          ),
          const SizedBox(width: 12),
          Text(
            "Recent Comments",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : Colors.black87,
              letterSpacing: -0.2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommentsList(List<Map<String, dynamic>> comments, bool isDark) {
    return Column(
      children:
          comments
              .map((comment) => _buildCommentItem(comment, isDark))
              .toList(),
    );
  }

  Widget _buildCommentItem(Map<String, dynamic> comment, bool isDark) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[800]!.withOpacity(0.4) : Colors.grey[50],
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  isDark ? Colors.blueAccent[400]! : Colors.blueAccent,
                  isDark
                      ? Colors.lightBlueAccent[200]!
                      : Colors.lightBlueAccent,
                ],
              ),
            ),
            child: Icon(Icons.person, size: 20, color: Colors.white),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      comment['username'],
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      comment['timestamp'] != null
                          ? timeago.format(comment['timestamp'])
                          : '',
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark ? Colors.white38 : Colors.black45,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  comment['content'],
                  style: TextStyle(
                    color: isDark ? Colors.white70 : Colors.black54,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShowMoreButton(bool isDark) {
    return Center(
      child: TextButton(
        onPressed: () => setState(() => _showAll = !_showAll),
        style: TextButton.styleFrom(
          foregroundColor: isDark ? Colors.blueAccent[200] : Colors.blueAccent,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _showAll ? 'Show Less' : 'Show More',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
            const SizedBox(width: 4),
            Icon(
              _showAll ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
              size: 18,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopEpisodesSection(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.trending_up_rounded,
                color: isDark ? Colors.purpleAccent[200] : Colors.purpleAccent,
                size: 24,
              ),
              const SizedBox(width: 12),
              Text(
                "Top Episodes",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : Colors.black87,
                  letterSpacing: -0.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_commentCountByEpisode.isEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Text(
                "No episode data available",
                style: TextStyle(
                  color: isDark ? Colors.white38 : Colors.black26,
                  fontSize: 13,
                ),
              ),
            ),
          ..._commentCountByEpisode.entries
              .toList()
              .take(5)
              .map((e) => _buildEpisodeItem(e.key, e.value, isDark)),
        ],
      ),
    );
  }

  Widget _buildEpisodeItem(String episodeId, int count, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[800]!.withOpacity(0.4) : Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  isDark ? Colors.purpleAccent[400]! : Colors.purpleAccent,
                  isDark
                      ? Colors.deepPurpleAccent[200]!
                      : Colors.deepPurpleAccent,
                ],
              ),
            ),
            child: Icon(
              Icons.play_arrow_rounded,
              color: Colors.white,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              "Episode $episodeId",
              style: TextStyle(
                fontSize: 14,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  isDark ? Colors.purpleAccent[400]! : Colors.purpleAccent,
                  isDark
                      ? Colors.deepPurpleAccent[200]!
                      : Colors.deepPurpleAccent,
                ],
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              "$count comments",
              style: const TextStyle(
                fontSize: 12,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
