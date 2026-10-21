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

      // Mirror ke public_history di users/{user.uid} agar profil publik dapat melihatnya
      try {
        final userDocRef = _firestore.collection('users').doc(user.uid);
        final userDoc = await userDocRef.get();
        final list = List<dynamic>.from(userDoc.data()?['public_history'] ?? []);
        list.removeWhere((item) => item is Map && (item['episodeId'] == episodeId || item['animeTitle'] == animeTitle));
        list.insert(0, {
          'episodeId': episodeId,
          'title': episodeTitle,
          'animeTitle': animeTitle,
          'thumb': thumbUrl,
          'animeEndpoint': animeEndpoint,
          'isWatched': isWatched,
        });
        if (list.length > 50) list.removeLast();
        await userDocRef.set({
          'public_history': list,
          'synced_episodes': FieldValue.increment(1),
        }, SetOptions(merge: true));
      } catch (_) {}

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

  Stream<QuerySnapshot<Map<String, dynamic>>> getUserWatchHistoryStream(String uid) {
    return _firestore
        .collection('watch_history')
        .doc(uid)
        .collection('history')
        .snapshots();
  }

  Future<List<Map<String, dynamic>>> getUserWatchHistory(String uid) async {
    try {
      final snapshot = await _firestore
          .collection('watch_history')
          .doc(uid)
          .collection('history')
          .get();

      if (snapshot.docs.isNotEmpty) {
        final list = snapshot.docs.map((doc) => doc.data()).toList();
        list.sort((a, b) {
          final aTime = _parseDateTime(a['watchedAt'] ?? a['timestamp'] ?? a['createdAt']);
          final bTime = _parseDateTime(b['watchedAt'] ?? b['timestamp'] ?? b['createdAt']);
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
        final publicHistory = data?['public_history'] ?? data?['recent_history'] ?? data?['history'];
        if (publicHistory is List && publicHistory.isNotEmpty) {
          return List<Map<String, dynamic>>.from(
            publicHistory.map((e) => Map<String, dynamic>.from(e as Map)),
          );
        }
      }
    } catch (_) {}

    return [];
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

