import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FavoriteService {
  static final _firestore = FirebaseFirestore.instance;
  static final _auth = FirebaseAuth.instance;

  static Future<bool> isSaved(String endpoint) async {
    final user = _auth.currentUser;
    if (user == null) return false;

    final doc =
        await _firestore
            .collection('users')
            .doc(user.uid)
            .collection('favorites')
            .doc(endpoint)
            .get();

    return doc.exists;
  }

  static Future<void> toggleFavorite({
    required String endpoint,
    required String title,
    required String imageUrl,
  }) async {
    final user = _auth.currentUser;
    if (user == null) return;

    final docRef = _firestore
        .collection('users')
        .doc(user.uid)
        .collection('favorites')
        .doc(endpoint);

    final userDocRef = _firestore.collection('users').doc(user.uid);
    final doc = await docRef.get();

    if (doc.exists) {
      await docRef.delete();
      try {
        final userDoc = await userDocRef.get();
        if (userDoc.exists) {
          final list = List<dynamic>.from(userDoc.data()?['public_favorites'] ?? []);
          list.removeWhere((item) => item is Map && item['endpoint'] == endpoint);
          await userDocRef.update({
            'public_favorites': list,
            'synced_favorites': list.length,
          });
        }
      } catch (_) {}
    } else {
      await docRef.set({
        'title': title,
        'endpoint': endpoint,
        'thumb': imageUrl,
        'savedAt': FieldValue.serverTimestamp(),
      });
      try {
        final userDoc = await userDocRef.get();
        final list = List<dynamic>.from(userDoc.data()?['public_favorites'] ?? []);
        list.removeWhere((item) => item is Map && item['endpoint'] == endpoint);
        list.insert(0, {
          'title': title,
          'endpoint': endpoint,
          'thumb': imageUrl,
        });
        if (list.length > 50) list.removeLast();
        await userDocRef.set({
          'public_favorites': list,
          'synced_favorites': list.length,
        }, SetOptions(merge: true));
      } catch (_) {}
    }
  }

  static Future<List<Map<String, dynamic>>> getFavorites() async {
    final user = _auth.currentUser;
    if (user == null) return [];
    return getUserFavorites(user.uid);
  }

  static Future<List<Map<String, dynamic>>> getUserFavorites(String uid) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(uid)
          .collection('favorites')
          .get();

      if (snapshot.docs.isNotEmpty) {
        final list = snapshot.docs.map((doc) => doc.data()).toList();
        list.sort((a, b) {
          final aTime = _parseDateTime(a['savedAt'] ?? a['timestamp'] ?? a['createdAt']);
          final bTime = _parseDateTime(b['savedAt'] ?? b['timestamp'] ?? b['createdAt']);
          if (aTime == null && bTime == null) return 0;
          if (aTime == null) return 1;
          if (bTime == null) return -1;
          return bTime.compareTo(aTime);
        });
        return list;
      }
    } catch (_) {}

    // Fallback: baca dari dokumen utama users/{uid}
    try {
      final userDoc = await _firestore.collection('users').doc(uid).get();
      if (userDoc.exists) {
        final data = userDoc.data();
        final publicFavs = data?['public_favorites'] ?? data?['favorites'] ?? data?['my_favorites'];
        if (publicFavs is List && publicFavs.isNotEmpty) {
          return List<Map<String, dynamic>>.from(
            publicFavs.map((e) => Map<String, dynamic>.from(e as Map)),
          );
        }
      }
    } catch (_) {}

    return [];
  }

  static Stream<QuerySnapshot<Map<String, dynamic>>> getUserFavoritesStream(String uid) {
    return _firestore
        .collection('users')
        .doc(uid)
        .collection('favorites')
        .snapshots();
  }

  static DateTime? _parseDateTime(dynamic val) {
    if (val == null) return null;
    if (val is Timestamp) return val.toDate();
    if (val is int) return DateTime.fromMillisecondsSinceEpoch(val);
    if (val is DateTime) return val;
    if (val is String) return DateTime.tryParse(val);
    return null;
  }
}

