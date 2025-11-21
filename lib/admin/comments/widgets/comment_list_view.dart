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
  List<Map<String, dynamic>> _reportedComments = [];
  List<Map<String, dynamic>> _filteredComments = [];
  String _selectedEpisodeId = '';
  List<String> _episodeOptions = [];
  bool _showAll = false;

  @override
  void initState() {
    super.initState();
    _loadReportedComments();
    timeago.setLocaleMessages('id', timeago.IdMessages());
  }

  Future<void> _loadReportedComments() async {
    setState(() => _loading = true);
    try {
      final snapshot =
          await FirebaseFirestore.instance
              .collection('reports')
              .orderBy('reportedAt', descending: true)
              .limit(100)
              .get();

      final reports = await Future.wait(
        snapshot.docs.map((doc) async {
          try {
            final data = doc.data();
            final episodeId = data['episodeId'];
            final commentId = data['commentId'];

            final commentSnapshot =
                await FirebaseFirestore.instance
                    .collection('episodes')
                    .doc(episodeId)
                    .collection('comments')
                    .doc(commentId)
                    .get();

            if (!commentSnapshot.exists) return null;

            final commentData = commentSnapshot.data()!;
            final timestamp = commentData['timestamp'] as Timestamp?;
            final reportedAt = data['reportedAt'] as Timestamp?;

            return {
              'reportId': doc.id,
              'commentId': commentId,
              'episodeId': episodeId,
              'content': commentData['content'] ?? '',
              'username': commentData['username'] ?? 'Anonim',
              'timestamp': timestamp?.toDate(),
              'reportedAt': reportedAt?.toDate(),
              'reportedUserId': data['reportedUserId'],
              'reportedBy': data['uid'],
            };
          } catch (e) {
            debugPrint('⚠️ Gagal memuat komentar laporan: $e');
            return null;
          }
        }),
      );

      final cleaned = reports.whereType<Map<String, dynamic>>().toList();
      final episodeIds =
          cleaned.map((r) => r['episodeId'] as String).toSet().toList();
      episodeIds.sort();

      if (mounted) {
        setState(() {
          _reportedComments = cleaned;
          _filteredComments = cleaned;
          _episodeOptions = episodeIds;
          _loading = false;
        });
      }
    } catch (e) {
      debugPrint('❌ Gagal mengambil laporan komentar: $e');
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  void _filterByEpisode(String episodeId) {
    setState(() {
      _selectedEpisodeId = episodeId;
      _filteredComments =
          episodeId.isEmpty
              ? _reportedComments
              : _reportedComments
                  .where((c) => c['episodeId'] == episodeId)
                  .toList();
      _showAll = false;
    });
  }

  Future<void> _hapusKomentarDanLaporan(
    String episodeId,
    String commentId,
    String reportId,
  ) async {
    try {
      await Future.wait([
        FirebaseFirestore.instance
            .collection('episodes')
            .doc(episodeId)
            .collection('comments')
            .doc(commentId)
            .delete(),
        FirebaseFirestore.instance.collection('reports').doc(reportId).delete(),
      ]);

      if (mounted) {
        setState(() {
          _reportedComments.removeWhere((c) => c['reportId'] == reportId);
          _filteredComments.removeWhere((c) => c['reportId'] == reportId);
        });
      }
      _showSnackBar('✅ Komentar dan laporan berhasil dihapus');
    } catch (e) {
      debugPrint('❌ Gagal menghapus komentar & laporan: $e');
      _showSnackBar('❌ Gagal menghapus komentar & laporan');
    }
  }

  Future<void> _hapusHanyaLaporan(String reportId) async {
    try {
      await FirebaseFirestore.instance
          .collection('reports')
          .doc(reportId)
          .delete();
      if (mounted) {
        setState(() {
          _reportedComments.removeWhere((c) => c['reportId'] == reportId);
          _filteredComments.removeWhere((c) => c['reportId'] == reportId);
        });
      }
      _showSnackBar('✅ Laporan berhasil diabaikan');
    } catch (e) {
      debugPrint('❌ Gagal menghapus laporan saja: $e');
      _showSnackBar('❌ Gagal menghapus laporan');
    }
  }

  Future<void> _blokirUser(String userId) async {
    try {
      final userRef = FirebaseFirestore.instance
          .collection('users')
          .doc(userId);
      await userRef.set({
        'isBanned': true,
        'bannedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      _showSnackBar('✅ Pengguna berhasil diblokir');
    } catch (e) {
      debugPrint('❌ Gagal memblokir pengguna: $e');
      _showSnackBar('❌ Gagal memblokir pengguna');
    }
  }

  void _showSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final commentsToShow =
        _showAll ? _filteredComments : _filteredComments.take(5).toList();

    return Card(
      elevation: 0,
      margin: const EdgeInsets.all(0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: theme.dividerColor.withOpacity(0.1), width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.flag, color: theme.colorScheme.error),
                const SizedBox(width: 8),
                Text(
                  "Komentar Dilaporkan",
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                if (_loading)
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
              ],
            ),
            const SizedBox(height: 16),

            // Filter Dropdown
            DecoratedBox(
              decoration: BoxDecoration(
                border: Border.all(color: theme.dividerColor.withOpacity(0.2)),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: DropdownButton<String>(
                  value: _selectedEpisodeId,
                  isExpanded: true,
                  underline: const SizedBox(),
                  icon: Icon(
                    Icons.arrow_drop_down,
                    color: theme.colorScheme.primary,
                  ),
                  hint: Text(
                    "Filter episode",
                    style: theme.textTheme.bodyMedium,
                  ),
                  style: theme.textTheme.bodyMedium,
                  items: [
                    DropdownMenuItem(
                      value: '',
                      child: Text(
                        "Semua Episode",
                        style: theme.textTheme.bodyMedium,
                      ),
                    ),
                    ..._episodeOptions.map(
                      (id) => DropdownMenuItem(
                        value: id,
                        child: Text(id, style: theme.textTheme.bodyMedium),
                      ),
                    ),
                  ],
                  onChanged: (value) => _filterByEpisode(value ?? ''),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Content
            if (commentsToShow.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      Icon(Icons.inbox, size: 48, color: theme.disabledColor),
                      const SizedBox(height: 8),
                      Text(
                        "Tidak ada komentar yang dilaporkan",
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.disabledColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ...commentsToShow.map(
              (comment) => _buildCommentCard(comment, theme),
            ),

            // Show More/Less Button
            if (_filteredComments.length > 5)
              Center(
                child: TextButton(
                  onPressed: () => setState(() => _showAll = !_showAll),
                  child: Text(
                    _showAll ? 'Tampilkan Lebih Sedikit' : 'Tampilkan Semua',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCommentCard(Map<String, dynamic> comment, ThemeData theme) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
                  radius: 20,
                  child: Icon(
                    Icons.person,
                    size: 16,
                    color: theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        comment['username'],
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (comment['timestamp'] != null)
                        Text(
                          timeago.format(comment['timestamp'], locale: 'id'),
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.onSurface.withOpacity(0.5),
                          ),
                        ),
                    ],
                  ),
                ),
                _buildActionMenu(comment),
              ],
            ),
            const SizedBox(height: 8),

            // Comment Content
            Text(comment['content'], style: theme.textTheme.bodyMedium),
            const SizedBox(height: 12),

            // Metadata
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                _buildMetaChip(
                  icon: Icons.flag,
                  label:
                      "Dilaporkan ${timeago.format(comment['reportedAt'], locale: 'id')}",
                  color: theme.colorScheme.error,
                  theme: theme,
                ),
                _buildMetaChip(
                  icon: Icons.movie,
                  label: comment['episodeId'],
                  color: theme.colorScheme.primary,
                  theme: theme,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionMenu(Map<String, dynamic> comment) {
    return PopupMenuButton(
      icon: Icon(
        Icons.more_vert,
        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
      ),
      itemBuilder:
          (context) => [
            PopupMenuItem(
              child: ListTile(
                leading: Icon(
                  Icons.delete,
                  color: Theme.of(context).colorScheme.error,
                ),
                title: Text(
                  "Hapus Komentar",
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _hapusKomentarDanLaporan(
                    comment['episodeId'],
                    comment['commentId'],
                    comment['reportId'],
                  );
                },
              ),
            ),
            PopupMenuItem(
              child: ListTile(
                leading: const Icon(Icons.check),
                title: const Text("Abaikan Laporan"),
                onTap: () {
                  Navigator.pop(context);
                  _hapusHanyaLaporan(comment['reportId']);
                },
              ),
            ),
            PopupMenuItem(
              child: ListTile(
                leading: Icon(
                  Icons.block,
                  color: Theme.of(context).colorScheme.error,
                ),
                title: Text(
                  "Blokir Pengguna",
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
                onTap: () async {
                  Navigator.pop(context);
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder:
                        (context) => AlertDialog(
                          title: const Text("Konfirmasi Blokir"),
                          content: const Text(
                            "Apakah Anda yakin ingin memblokir pengguna ini?",
                          ),
                          actions: [
                            TextButton(
                              child: const Text("Batal"),
                              onPressed: () => Navigator.pop(context, false),
                            ),
                            TextButton(
                              style: TextButton.styleFrom(
                                foregroundColor:
                                    Theme.of(context).colorScheme.error,
                              ),
                              child: const Text("Blokir"),
                              onPressed: () => Navigator.pop(context, true),
                            ),
                          ],
                        ),
                  );
                  if (confirm == true) {
                    await _blokirUser(comment['reportedUserId']);
                  }
                },
              ),
            ),
          ],
    );
  }

  Widget _buildMetaChip({
    required IconData icon,
    required String label,
    required Color color,
    required ThemeData theme,
  }) {
    return Chip(
      avatar: Icon(icon, size: 14, color: color),
      label: Text(
        label,
        style: theme.textTheme.labelSmall?.copyWith(
          color: theme.colorScheme.onSurface.withOpacity(0.8),
        ),
      ),
      backgroundColor: color.withOpacity(0.1),
      visualDensity: VisualDensity.compact,
      side: BorderSide.none,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    );
  }
}
