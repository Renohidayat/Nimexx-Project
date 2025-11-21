import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class HistoryService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<void> saveWatchHistory({
    required String episodeId,
    required String episodeTitle,
    required String animeTitle,
    required String thumbUrl,
    required String animeEndpoint, // ✅ Tambahkan parameter ini
    bool isWatched = true,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      debugPrint("⚠️ User belum login, histori tidak disimpan.");
      return;
    }

    final docRef = _firestore
        .collection('watch_history')
        .doc(user.uid)
        .collection('history')
        .doc(episodeId);

    try {
      await docRef.set({
        'episodeId': episodeId,
        'title': episodeTitle,
        'animeTitle': animeTitle,
        'thumb': thumbUrl,
        'animeEndpoint': animeEndpoint, // ✅ Simpan animeEndpoint
        'isWatched': isWatched,
        'watchedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      debugPrint("✅ Histori berhasil disimpan: $animeTitle - $episodeTitle");
    } catch (e) {
      debugPrint("❌ Gagal menyimpan histori: $e");
    }
  }

  // Method lainnya tetap sama...
  Future<List<String>> getWatchedEpisodeIds() async {
    final user = _auth.currentUser;
    if (user == null) {
      debugPrint("⚠️ User belum login, tidak ada histori.");
      return [];
    }

    try {
      final snapshot =
          await _firestore
              .collection('watch_history')
              .doc(user.uid)
              .collection('history')
              .where('isWatched', isEqualTo: true)
              .get();

      return snapshot.docs.map((doc) => doc.id).toList();
    } catch (e) {
      debugPrint("❌ Gagal mengambil histori: $e");
      return [];
    }
  }

  Future<void> toggleWatchStatus(String episodeId, bool isWatched) async {
    final user = _auth.currentUser;
    if (user == null) {
      debugPrint("⚠️ User belum login.");
      return;
    }

    try {
      final docRef = _firestore
          .collection('watch_history')
          .doc(user.uid)
          .collection('history')
          .doc(episodeId);

      await docRef.set({'isWatched': isWatched}, SetOptions(merge: true));

      debugPrint("✅ Progress updated untuk episode $episodeId => $isWatched");
    } catch (e) {
      debugPrint("❌ Gagal update progress: $e");
    }
  }
}
