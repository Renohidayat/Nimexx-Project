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

    final doc = await docRef.get();

    if (doc.exists) {
      await docRef.delete();
    } else {
      await docRef.set({
        'title': title,
        'endpoint': endpoint,
        'thumb': imageUrl,
        'savedAt': FieldValue.serverTimestamp(),
      });
    }
  }

  static Future<List<Map<String, dynamic>>> getFavorites() async {
    final user = _auth.currentUser;
    if (user == null) return [];

    final snapshot =
        await _firestore
            .collection('users')
            .doc(user.uid)
            .collection('favorites')
            .orderBy('savedAt', descending: true)
            .get();

    return snapshot.docs.map((doc) => doc.data()).toList();
  }
}
