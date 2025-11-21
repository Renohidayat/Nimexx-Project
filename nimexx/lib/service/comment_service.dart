import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'notification_service.dart';

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

    final commentData = {
      'content': content,
      'uid': user.uid,
      'username': user.displayName ?? 'Anonim',
      'photoURL': user.photoURL,
      'timestamp': FieldValue.serverTimestamp(),
      'parentId': parentId,
      'parentUserId': parentUserId,
      'parentUsername': parentUsername,
    };

    final newCommentRef = await _commentCollection(episodeId).add(commentData);
    final newCommentId = newCommentRef.id;
    // Misalnya untuk logging atau navigasi:
    print("Komentar baru ditambahkan dengan ID: $newCommentId");

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

  /// Mengambil semua komentar untuk satu episode
  Stream<QuerySnapshot<Map<String, dynamic>>> getComments(String episodeId) {
    return _commentCollection(
      episodeId,
    ).orderBy('timestamp', descending: false).snapshots();
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
}
