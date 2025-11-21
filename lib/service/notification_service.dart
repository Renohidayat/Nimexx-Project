import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class NotificationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<void> sendReplyNotification({
    required String targetUserId,
    required String episodeId,
    required String commentId,
    required String episodeTitle, // ✅ Tambahkan ini
    required String animeTitle, // ✅ Tambahkan ini
    required String thumbUrl, // ✅ Tambahkan ini
  }) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null || targetUserId == currentUser.uid) {
      print(
        '⛔ Tidak mengirim notifikasi karena user tidak login atau membalas diri sendiri.',
      );
      return;
    }

    final String fromUsername = currentUser.displayName ?? 'Anonim';

    final Map<String, dynamic> notificationData = {
      'type': 'reply',
      'fromUserId': currentUser.uid,
      'fromUsername': fromUsername,
      'episodeId': episodeId,
      'episodeTitle': episodeTitle, // ✅ Untuk navigasi
      'animeTitle': animeTitle, // ✅ Untuk tampilan
      'thumbUrl': thumbUrl, // ✅ Untuk tampilan
      'commentId': commentId,
      'message': '$fromUsername membalas komentar Anda',
      'timestamp': FieldValue.serverTimestamp(),
      'read': false,
    };

    try {
      await _firestore
          .collection('users')
          .doc(targetUserId)
          .collection('notifications')
          .add(notificationData);

      print('✅ Notifikasi berhasil dikirim ke $targetUserId');
    } catch (e) {
      print('❌ Gagal mengirim notifikasi: $e');
    }
  }
}
