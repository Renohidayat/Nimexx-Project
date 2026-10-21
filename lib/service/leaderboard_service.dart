import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/leaderboard_user.dart';
import 'rank_service.dart';

class LeaderboardService {
  static final LeaderboardService _instance = LeaderboardService._internal();
  factory LeaderboardService() => _instance;
  LeaderboardService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Pemicu sinkronisasi otomatis seluruh akun ke rank service
  Future<void> autoSyncAllUsers({bool force = false}) async {
    await RankService().autoSyncAllUsers(force: force);
  }

  /// Stream realtime peringkat pengguna murni dari database Firestore users
  /// Mengurutkan berdasarkan Level tertinggi, lalu Total EXP
  Stream<List<LeaderboardUser>> getLeaderboardStream({int limit = 100}) {
    return _firestore.collection('users').snapshots().map((snapshot) {
      final currentUid = FirebaseAuth.instance.currentUser?.uid;
      final List<LeaderboardUser> users = [];

      for (var doc in snapshot.docs) {
        final data = doc.data();
        final uid = doc.id;

        // 1. Ekstraksi Display Name dengan prioritas cerdas
        final rawDisplayName = (data['displayName'] as String?)?.trim() ?? '';
        final rawName = (data['name'] as String?)?.trim() ?? '';
        final rawUsername = (data['username'] as String?)?.trim() ?? '';
        final email = (data['email'] as String?)?.trim() ?? '';
        final emailPrefix = email.contains('@') ? email.split('@')[0].trim() : '';

        String displayName;
        if (rawDisplayName.isNotEmpty && rawDisplayName != 'Pengguna Nimexx') {
          displayName = rawDisplayName;
        } else if (rawName.isNotEmpty && rawName != 'Pengguna Nimexx') {
          displayName = rawName;
        } else if (rawUsername.isNotEmpty && rawUsername != 'pengguna' && !rawUsername.startsWith('user_')) {
          displayName = rawUsername;
        } else if (emailPrefix.isNotEmpty) {
          displayName = emailPrefix;
        } else if (rawDisplayName.isNotEmpty) {
          displayName = rawDisplayName;
        } else {
          displayName = 'Pengguna Nimexx';
        }

        final username = rawUsername.isNotEmpty
            ? rawUsername
            : (emailPrefix.isNotEmpty ? emailPrefix : 'pengguna');

        // 2. Resolusi photoUrl dari Google / database / alternatif
        final photoUrl = (data['photoUrl'] as String?)?.trim().isNotEmpty == true
            ? (data['photoUrl'] as String).trim()
            : ((data['photoURL'] as String?)?.trim().isNotEmpty == true
                ? (data['photoURL'] as String).trim()
                : ((data['photo'] as String?)?.trim().isNotEmpty == true
                    ? (data['photo'] as String).trim()
                    : ((data['avatar'] as String?)?.trim().isNotEmpty == true
                        ? (data['avatar'] as String).trim()
                        : ((data['profile_image'] as String?)?.trim().isNotEmpty == true
                            ? (data['profile_image'] as String).trim()
                            : ''))));

        // 3. Resolusi Level & Total EXP Pintar (Otomatis hitung dari riwayat nyata akun lama)
        int epCount = (data['synced_episodes'] as int?) ?? 0;
        int favCount = (data['synced_favorites'] as int?) ?? 0;
        int commentCount = (data['synced_comments'] as int?) ?? 0;

        final pubHist = data['public_history'] ?? data['recent_history'] ?? data['history'] ?? data['watched_episodes'];
        if (pubHist is List && pubHist.length > epCount) {
          epCount = pubHist.length;
        }
        final pubFavs = data['public_favorites'] ?? data['favorites'] ?? data['my_favorites'];
        if (pubFavs is List && pubFavs.length > favCount) {
          favCount = pubFavs.length;
        }
        final myComments = data['my_comments'] ?? data['commented_episodes'];
        if (myComments is List && myComments.length > commentCount) {
          commentCount = myComments.length;
        }

        // Hitung estimasi EXP historis dari aktivitas nyata:
        // 1 Episode = 15 EXP, 1 Favorit = 10 EXP, 1 Komentar = 5 EXP
        final int calculatedHistoricalExp = (epCount * 15) + (favCount * 10) + (commentCount * 5);

        final int recordedTotalExp = data['totalExp'] as int? ?? 0;
        final int recordedLevel = data['level'] as int? ?? 1;
        final int recordedExp = data['exp'] as int? ?? 0;

        // Cegah artifact lama di mana akun belum aktif tercatat 100 EXP karena fallback formula lama (level 1 * 100 + 0)
        int effectiveRecordedExp = recordedTotalExp;
        if (effectiveRecordedExp == 100 && recordedLevel <= 1 && recordedExp == 0 && calculatedHistoricalExp == 0) {
          effectiveRecordedExp = 0;
        }

        // Gunakan nilai EXP tertinggi antara yang tercatat di database atau hasil hitungan historis
        int totalExp = effectiveRecordedExp > calculatedHistoricalExp ? effectiveRecordedExp : calculatedHistoricalExp;

        int level = recordedLevel;
        int exp = recordedExp;

        if (totalExp > 0) {
          // Hitung level asli dari totalExp progresif
          int calcLevel = 1;
          int remExp = totalExp;
          int expNeed = RankService.getExpForNextLevel(calcLevel);
          while (remExp >= expNeed) {
            remExp -= expNeed;
            calcLevel += 1;
            expNeed = RankService.getExpForNextLevel(calcLevel);
          }
          if (calcLevel > level) {
            level = calcLevel;
            exp = remExp;
          }
        } else {
          // Pengguna baru yang belum ada aktivitas: Level 1, 0 EXP (bukan default 100)
          totalExp = (level > 1) ? (level * 100 + exp) : 0;
        }

        // 4. Resolusi rank tier badge asli berdasarkan level (tidak terkunci di 'E')
        String rankCode = (data['active_badge'] as String?) ?? '';
        final calculatedRank = RankService.getRankForLevel(level).code;
        if (rankCode.isEmpty || (rankCode == 'E' && calculatedRank != 'E')) {
          rankCode = calculatedRank;
        }

        DateTime? createdAt;
        final createdRaw = data['createdAt'];
        if (createdRaw is Timestamp) {
          createdAt = createdRaw.toDate();
        }

        users.add(LeaderboardUser(
          uid: uid,
          displayName: displayName,
          username: username,
          photoUrl: photoUrl,
          level: level,
          exp: exp,
          totalExp: totalExp,
          rankCode: rankCode,
          createdAt: createdAt,
          rankNumber: 0,
          isCurrentUser: uid == currentUid,
        ));
      }

      // Urutkan realtime: Level tertinggi dulu, jika sama urutkan Total EXP tertinggi
      users.sort((a, b) {
        final cmpLevel = b.level.compareTo(a.level);
        if (cmpLevel != 0) return cmpLevel;
        return b.totalExp.compareTo(a.totalExp);
      });

      // Sematkan nomor peringkat definitif (1 sampai batas limit)
      final List<LeaderboardUser> rankedList = [];
      final maxCount = users.length < limit ? users.length : limit;
      for (int i = 0; i < maxCount; i++) {
        rankedList.add(users[i].copyWith(rankNumber: i + 1));
      }

      return rankedList;
    });
  }

  /// Ambil satu kali (Future) jika diperlukan
  Future<List<LeaderboardUser>> getLeaderboardOnce({int limit = 100}) async {
    return await getLeaderboardStream(limit: limit).first;
  }
}
