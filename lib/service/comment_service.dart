import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'notification_service.dart';
import 'rank_service.dart';

class CommentService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final NotificationService _notificationService;

  CommentService(this._notificationService);

  /// Referensi ke koleksi komentar berdasarkan episode
  CollectionReference<Map<String, dynamic>> _commentCollection(
    String episodeId,
  ) {
    return _firestore
        .collection('episodes')
        .doc(episodeId)
        .collection('comments');
  }

  /// Menambahkan komentar baru atau balasan
  Future<void> addComment({
    required String episodeId,
    required String content,
    String? parentId,
    required String episodeTitle,
    required String animeTitle,
    required String thumbUrl,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception("User belum login");

    String? parentUserId;
    String? parentUsername;

    if (parentId != null) {
      final parentSnapshot =
          await _commentCollection(episodeId).doc(parentId).get();
      parentUserId = parentSnapshot.data()?['uid'];
      parentUsername = parentSnapshot.data()?['username'];
    }

    // Ambil data level dan badge user saat ini
    int userLevel = 1;
    String userBadge = 'E';
    try {
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      if (userDoc.exists) {
        userLevel = userDoc.data()?['level'] as int? ?? 1;
        userBadge = userDoc.data()?['active_badge'] as String? ?? 'E';
      }
    } catch (_) {}

    final commentData = {
      'content': content,
      'uid': user.uid,
      'username': user.displayName ?? 'Anonim',
      'photoURL': user.photoURL,
      'timestamp': FieldValue.serverTimestamp(),
      'parentId': parentId,
      'parentUserId': parentUserId,
      'parentUsername': parentUsername,
      'episodeId': episodeId,
      'episodeTitle': episodeTitle,
      'animeTitle': animeTitle,
      'thumbUrl': thumbUrl,
      'userLevel': userLevel,
      'userBadge': userBadge,
    };

    final newCommentRef = await _commentCollection(episodeId).add(commentData);
    final newCommentId = newCommentRef.id;

    try {
      final userDocRef = _firestore.collection('users').doc(user.uid);
      await userDocRef.set({
        'commented_episodes': FieldValue.arrayUnion([episodeId]),
        'my_comments': FieldValue.arrayUnion([
          {
            'id': newCommentId,
            'commentId': newCommentId,
            'episodeId': episodeId,
            'episodeTitle': episodeTitle,
            'animeTitle': animeTitle,
            'thumbUrl': thumbUrl,
            'content': content,
            'parentId': parentId,
            'timestamp': Timestamp.now(),
          }
        ]),
      }, SetOptions(merge: true));
    } catch (_) {}

    try {
      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('user_comments')
          .doc(newCommentId)
          .set({
            ...commentData,
            'commentId': newCommentId,
          }, SetOptions(merge: true));
    } catch (_) {}

    // Berikan reward EXP komentar berkualitas (Anti-Spam: minimal 10 karakter, maks 5/hari)
    if (content.trim().length >= 10) {
      try {
        await RankService().addExp(uid: user.uid, actionType: 'comment');
      } catch (_) {}
    }

    // Jika ini adalah balasan komentar, kirim notifikasi ke pemilik komentar utama
    if (parentId != null) {
      final parentSnapshot =
          await _commentCollection(episodeId).doc(parentId).get();
      final targetUid = parentSnapshot.data()?['uid'];

      print('🟡 ParentId: $parentId, Target UID: $targetUid');

      if (targetUid != null && targetUid != user.uid) {
        await _notificationService.sendReplyNotification(
          targetUserId: targetUid,
          episodeId: episodeId,
          commentId: parentId,
          episodeTitle: episodeTitle,
          animeTitle: animeTitle,
          thumbUrl: thumbUrl,
        );
        print('✅ Notifikasi berhasil dikirim ke $targetUid');
      } else {
        print(
          '⚠️ Tidak mengirim notifikasi (user tidak ditemukan atau membalas diri sendiri)',
        );
      }
    }
  }

  /// Mengambil semua komentar untuk satu episode (dilimit 50 untuk performa)
  Stream<QuerySnapshot<Map<String, dynamic>>> getComments(
    String episodeId, {
    bool descending = true,
  }) {
    return _commentCollection(
      episodeId,
    ).orderBy('timestamp', descending: descending).limit(50).snapshots();
  }

  /// Mengedit komentar (hanya jika milik user)
  Future<void> editComment({
    required String episodeId,
    required String commentId,
    required String newContent,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception("User belum login");

    final docRef = _commentCollection(episodeId).doc(commentId);
    final doc = await docRef.get();

    if (!doc.exists) throw Exception("Komentar tidak ditemukan");
    if (doc.data()?['uid'] != user.uid) {
      throw Exception("Tidak punya izin mengedit komentar ini");
    }

    await docRef.update({
      'content': newContent,
      'editedAt': FieldValue.serverTimestamp(),
    });

    try {
      final userDocRef = _firestore.collection('users').doc(user.uid);
      final userSnap = await userDocRef.get();
      if (userSnap.exists) {
        final list = List<dynamic>.from(userSnap.data()?['my_comments'] ?? []);
        final updatedList = list.map((item) {
          final m = Map<String, dynamic>.from(item as Map);
          if (m['id'] == commentId || m['commentId'] == commentId) {
            m['content'] = newContent;
            m['editedAt'] = Timestamp.now();
          }
          return m;
        }).toList();
        await userDocRef.update({'my_comments': updatedList});
      }
    } catch (_) {}

    try {
      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('user_comments')
          .doc(commentId)
          .update({
            'content': newContent,
            'editedAt': FieldValue.serverTimestamp(),
          });
    } catch (_) {}
  }

  /// Menghapus komentar (hanya jika milik user)
  Future<void> deleteComment({
    required String episodeId,
    required String commentId,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception("User belum login");

    final docRef = _commentCollection(episodeId).doc(commentId);
    final doc = await docRef.get();

    if (!doc.exists) throw Exception("Komentar tidak ditemukan");
    if (doc.data()?['uid'] != user.uid) {
      throw Exception("Tidak punya izin menghapus komentar ini");
    }

    await docRef.delete();

    try {
      final userDocRef = _firestore.collection('users').doc(user.uid);
      final userSnap = await userDocRef.get();
      if (userSnap.exists) {
        final list = List<dynamic>.from(userSnap.data()?['my_comments'] ?? []);
        final updatedList = list.where((item) {
          final m = item as Map;
          return m['id'] != commentId && m['commentId'] != commentId;
        }).toList();
        await userDocRef.update({'my_comments': updatedList});
      }
    } catch (_) {}

    try {
      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('user_comments')
          .doc(commentId)
          .delete();
    } catch (_) {}
  }

  /// Mengambil semua balasan untuk komentar utama
  Stream<QuerySnapshot<Map<String, dynamic>>> getReplies({
    required String episodeId,
    required String parentId,
  }) {
    return _commentCollection(
      episodeId,
    ).where('parentId', isEqualTo: parentId).orderBy('timestamp').snapshots();
  }

  /// Stream komentar pengguna dari subkoleksi user_comments
  Stream<QuerySnapshot<Map<String, dynamic>>> getUserCommentsStream(String uid) {
    return _firestore
        .collection('users')
        .doc(uid)
        .collection('user_comments')
        .snapshots();
  }

  /// Mengambil riwayat komentar dari seorang pengguna di berbagai anime secara lengkap & tahan banting
  Future<List<Map<String, dynamic>>> getUserComments(String uid) async {
    final Map<String, Map<String, dynamic>> combined = {};
    final currentUser = _auth.currentUser;
    final isOwner = currentUser != null && currentUser.uid == uid;

    // 1. Baca dokumen utama users/{uid} (Izin 100% aman dan instan)
    final Set<String> knownEpisodes = {};
    try {
      final userDoc = await _firestore.collection('users').doc(uid).get();
      if (userDoc.exists) {
        final userData = userDoc.data() ?? {};
        final myComments = userData['my_comments'];
        if (myComments is List) {
          for (final item in myComments) {
            if (item is Map) {
              final m = Map<String, dynamic>.from(item);
              final id = (m['id'] ?? m['commentId'] ?? '').toString();
              if (id.isNotEmpty) {
                combined[id] = m;
              }
            }
          }
        }
        final cEps = userData['commented_episodes'];
        if (cEps is List) {
          for (final ep in cEps) {
            if (ep != null && ep.toString().isNotEmpty) {
              knownEpisodes.add(ep.toString());
            }
          }
        }
      }
      print('ℹ️ [CommentService] Ditemukan ${combined.length} komentar dari dokumen utama users/$uid');
    } catch (e) {
      print('⚠️ [CommentService] Gagal membaca dokumen utama user: $e');
    }

    // 2. Coba baca dari subkoleksi users/{uid}/user_comments (jika rules Firestore mengizinkan)
    try {
      final userDocComments = await _firestore
          .collection('users')
          .doc(uid)
          .collection('user_comments')
          .get();

      for (final doc in userDocComments.docs) {
        combined[doc.id] = {'id': doc.id, ...doc.data()};
      }
      print('ℹ️ [CommentService] Total setelah users/$uid/user_comments: ${combined.length}');
    } catch (_) {}

    // 3. Scan episode dari riwayat tontonan user (watch_history/{uid}/history) & episode yang pernah dikomentari
    // Hanya bisa dijalankan jika pemanggil adalah pemilik akun (isOwner)
    if (isOwner) {
      try {
        final watchSnap = await _firestore
            .collection('watch_history')
            .doc(uid)
            .collection('history')
            .limit(300) // Pindai hingga 300 episode agar seluruh episode lama tercover
            .get();

        final Set<String> episodesToScan = Set<String>.from(knownEpisodes);
        final Map<String, Map<String, String>> episodeMeta = {};

        for (final wDoc in watchSnap.docs) {
          final wData = wDoc.data();
          final epId = wDoc.id;
          episodesToScan.add(epId);
          episodeMeta[epId] = {
            'episodeTitle': (wData['title'] ?? 'Episode').toString(),
            'animeTitle': (wData['animeTitle'] ?? 'Anime').toString(),
            'thumb': (wData['thumb'] ?? '').toString(),
          };
        }

        print('ℹ️ [CommentService] Memindai ${episodesToScan.length} episode untuk komentar milik $uid...');

        final epList = episodesToScan.toList();
        const chunkSize = 15;

        for (var i = 0; i < epList.length; i += chunkSize) {
          final end = (i + chunkSize < epList.length) ? i + chunkSize : epList.length;
          final chunk = epList.sublist(i, end);
          final futures = chunk.map((epId) async {
            try {
              final cSnap = await _commentCollection(epId)
                  .where('uid', isEqualTo: uid)
                  .get();

              final meta = episodeMeta[epId] ?? {};
              final defaultEpTitle = meta['episodeTitle'] ?? 'Episode';
              final defaultAnimeTitle = meta['animeTitle'] ?? 'Anime';
              final defaultThumb = meta['thumb'] ?? '';

              for (final cDoc in cSnap.docs) {
                final cData = cDoc.data();
                final commentId = cDoc.id;

                final fullCommentData = {
                  'id': commentId,
                  'commentId': commentId,
                  'episodeId': epId,
                  'episodeTitle': cData['episodeTitle'] ?? defaultEpTitle,
                  'animeTitle': cData['animeTitle'] ?? defaultAnimeTitle,
                  'thumbUrl': cData['thumbUrl'] ?? defaultThumb,
                  ...cData,
                };

                combined[commentId] = fullCommentData;
              }
            } catch (_) {}
          });
          await Future.wait(futures);
        }

        print('ℹ️ [CommentService] Total setelah pemindaian episode: ${combined.length}');

        // Sinkronisasi otomatis ke users/{uid} agar pemanggilan selanjutnya instan & publik bisa membaca
        if (combined.isNotEmpty) {
          final commentsToCache = combined.values.map((c) {
            return {
              'id': c['id'] ?? c['commentId'],
              'commentId': c['commentId'] ?? c['id'],
              'episodeId': c['episodeId'] ?? '',
              'episodeTitle': c['episodeTitle'] ?? 'Episode',
              'animeTitle': c['animeTitle'] ?? 'Anime',
              'thumbUrl': c['thumbUrl'] ?? '',
              'content': c['content'] ?? '',
              'parentId': c['parentId'],
              'timestamp': c['timestamp'] ?? Timestamp.now(),
            };
          }).toList();

          final commentedEps = combined.values
              .map((c) => c['episodeId']?.toString())
              .where((id) => id != null && id.isNotEmpty)
              .toSet()
              .toList();

          _firestore.collection('users').doc(uid).set({
            'my_comments': commentsToCache,
            'commented_episodes': FieldValue.arrayUnion(commentedEps),
          }, SetOptions(merge: true)).catchError((e) {
            print('⚠️ Gagal auto-cache comments ke user doc: $e');
          });
        }
      } catch (e) {
        print('⚠️ [CommentService] Error scan history untuk komentar: $e');
      }
    }

    // 4. Fallback: collectionGroup('comments') query (jika user membuka rules di Firebase Console)
    try {
      final querySnapshot = await _firestore
          .collectionGroup('comments')
          .where('uid', isEqualTo: uid)
          .get();

      bool foundFromCollectionGroup = false;
      for (final doc in querySnapshot.docs) {
        if (!combined.containsKey(doc.id)) {
          final data = doc.data();
          final epId = data['episodeId'] ?? doc.reference.parent.parent?.id ?? '';
          final commentData = {
            'id': doc.id,
            'commentId': doc.id,
            'episodeId': epId,
            ...data,
          };
          combined[doc.id] = commentData;
          foundFromCollectionGroup = true;
        }
      }

      if (foundFromCollectionGroup && isOwner) {
        final commentsToCache = combined.values.toList();
        _firestore.collection('users').doc(uid).set({
          'my_comments': commentsToCache,
        }, SetOptions(merge: true)).catchError((_) {});
      }
      print('ℹ️ [CommentService] Total setelah collectionGroup where: ${combined.length}');
    } catch (_) {}

    // Sort descending berdasarkan waktu komentar terbaru secara aman
    final list = combined.values.toList();
    list.sort((a, b) {
      final tA = _parseTimestamp(a['timestamp']);
      final tB = _parseTimestamp(b['timestamp']);
      return tB.compareTo(tA);
    });

    return list;
  }

  /// Helper untuk parsing berbagai format timestamp secara aman tanpa crash
  DateTime _parseTimestamp(dynamic val) {
    if (val is Timestamp) return val.toDate();
    if (val is int) return DateTime.fromMillisecondsSinceEpoch(val);
    if (val is DateTime) return val;
    if (val is String) {
      final d = DateTime.tryParse(val);
      if (d != null) return d;
    }
    return DateTime(2000);
  }
}
