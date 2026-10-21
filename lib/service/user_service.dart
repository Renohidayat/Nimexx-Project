import 'package:cloud_firestore/cloud_firestore.dart';
import 'notification_service.dart';

class UserService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Search users by username or displayName
  Future<List<Map<String, dynamic>>> searchUsers(String query) async {
    if (query.trim().isEmpty) return [];

    final q = query.trim().toLowerCase();

    // Untuk pencarian sederhana di Firestore, kita bisa menggunakan >= dan <= trik
    // agar bisa mencari text awalan (prefix match).
    final snapshot = await _firestore
        .collection('users')
        .where('username', isGreaterThanOrEqualTo: q)
        .where('username', isLessThanOrEqualTo: '$q\uf8ff')
        .limit(20)
        .get();

    return snapshot.docs.map((doc) {
      final data = doc.data();
      data['uid'] = doc.id; // Ensure UID is included
      return data;
    }).toList();
  }

  // --- Friend System ---

  Future<void> sendFriendRequest(String currentUid, String targetUid) async {
    // Tambahkan currentUid ke array 'friendRequests' di dokumen targetUid
    await _firestore.collection('users').doc(targetUid).set({
      'friendRequests': FieldValue.arrayUnion([currentUid]),
    }, SetOptions(merge: true));

    // Kirim notifikasi
    await NotificationService().sendFriendRequestNotification(targetUid);
  }

  Future<void> acceptFriendRequest(String currentUid, String targetUid) async {
    final batch = _firestore.batch();
    
    final currentUserRef = _firestore.collection('users').doc(currentUid);
    final targetUserRef = _firestore.collection('users').doc(targetUid);

    // Tambah ke daftar friends masing-masing
    batch.set(currentUserRef, {
      'friends': FieldValue.arrayUnion([targetUid]),
      'friendRequests': FieldValue.arrayRemove([targetUid]), // Hapus dari request
    }, SetOptions(merge: true));

    batch.set(targetUserRef, {
      'friends': FieldValue.arrayUnion([currentUid]),
    }, SetOptions(merge: true));

    await batch.commit();
  }

  Future<void> removeFriend(String currentUid, String targetUid) async {
    final batch = _firestore.batch();
    
    final currentUserRef = _firestore.collection('users').doc(currentUid);
    final targetUserRef = _firestore.collection('users').doc(targetUid);

    batch.set(currentUserRef, {
      'friends': FieldValue.arrayRemove([targetUid]),
    }, SetOptions(merge: true));

    batch.set(targetUserRef, {
      'friends': FieldValue.arrayRemove([currentUid]),
    }, SetOptions(merge: true));

    await batch.commit();
  }
}
