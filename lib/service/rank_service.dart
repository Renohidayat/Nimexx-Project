// service/rank_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class RankTier {
  final String code; // 'E', 'D', 'C', 'B', 'A', 'S', 'SS', 'SSS', 'MYTHIC'
  final String title;
  final String badgeName;
  final int minLevel;
  final int maxLevel;
  final Color primaryColor;
  final Color secondaryColor;
  final IconData icon;
  final String description;
  final String assetImage;

  const RankTier({
    required this.code,
    required this.title,
    required this.badgeName,
    required this.minLevel,
    required this.maxLevel,
    required this.primaryColor,
    required this.secondaryColor,
    required this.icon,
    required this.description,
    required this.assetImage,
  });
}

class ExpRewardResult {
  final bool success;
  final int expAdded;
  final bool leveledUp;
  final int newLevel;
  final String? newRankUnlocked;
  final String message;

  const ExpRewardResult({
    required this.success,
    this.expAdded = 0,
    this.leveledUp = false,
    this.newLevel = 1,
    this.newRankUnlocked,
    required this.message,
  });
}

class RankService {
  static final RankService _instance = RankService._internal();
  factory RankService() => _instance;
  RankService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Daftar Semua Tingkatan Rank
  static const List<RankTier> allRanks = [
    RankTier(
      code: 'E',
      title: 'Bronze Hunter',
      badgeName: 'Rank E (Bronze)',
      minLevel: 1,
      maxLevel: 10,
      primaryColor: Color(0xFF9E9E9E),
      secondaryColor: Color(0xFF616161),
      icon: Icons.shield_outlined,
      description: 'Pemula di dunia anime. Langkah awal petualangan!',
      assetImage: 'assets/badges/rank_e.jpg',
    ),
    RankTier(
      code: 'D',
      title: 'Silver Scout',
      badgeName: 'Rank D (Silver)',
      minLevel: 11,
      maxLevel: 30,
      primaryColor: Color(0xFFCFD8DC),
      secondaryColor: Color(0xFF90A4AE),
      icon: Icons.shield_rounded,
      description: 'Mulai memahami berbagai alur dan genre anime.',
      assetImage: 'assets/badges/rank_d.jpg',
    ),
    RankTier(
      code: 'C',
      title: 'Gold Fighter',
      badgeName: 'Rank C (Gold)',
      minLevel: 31,
      maxLevel: 60,
      primaryColor: Color(0xFFFFD700),
      secondaryColor: Color(0xFFFFA000),
      icon: Icons.military_tech_rounded,
      description: 'Penonton aktif dengan wawasan anime yang luas.',
      assetImage: 'assets/badges/rank_c.jpg',
    ),
    RankTier(
      code: 'B',
      title: 'Platinum Knight',
      badgeName: 'Rank B (Platinum)',
      minLevel: 61,
      maxLevel: 100,
      primaryColor: Color(0xFF29B6F6),
      secondaryColor: Color(0xFF0288D1),
      icon: Icons.workspace_premium_rounded,
      description: 'Penggemar sejati yang setia mengikuti episode terkini.',
      assetImage: 'assets/badges/rank_b.jpg',
    ),
    RankTier(
      code: 'A',
      title: 'Diamond Elite',
      badgeName: 'Rank A (Diamond)',
      minLevel: 101,
      maxLevel: 200,
      primaryColor: Color(0xFF00E5FF),
      secondaryColor: Color(0xFF00B0FF),
      icon: Icons.diamond_rounded,
      description: 'Elite Nimexx dengan status diamond berkilau.',
      assetImage: 'assets/badges/rank_a.jpg',
    ),
    RankTier(
      code: 'S',
      title: 'Master Dominator',
      badgeName: 'Rank S (Master)',
      minLevel: 201,
      maxLevel: 400,
      primaryColor: Color(0xFFFF1744),
      secondaryColor: Color(0xFFD50000),
      icon: Icons.local_fire_department_rounded,
      description: 'Tingkatan Master! Kehadiranmu disegani di komunitas.',
      assetImage: 'assets/badges/rank_s.jpg',
    ),
    RankTier(
      code: 'SS',
      title: 'Grandmaster Warlord',
      badgeName: 'Rank SS (Grandmaster)',
      minLevel: 401,
      maxLevel: 700,
      primaryColor: Color(0xFFE040FB),
      secondaryColor: Color(0xFFAA00FF),
      icon: Icons.auto_awesome_rounded,
      description: 'Kekuatan magis ungu neon. Sang penakluk ratusan anime.',
      assetImage: 'assets/badges/rank_ss.jpg',
    ),
    RankTier(
      code: 'SSS',
      title: 'Legendary Sovereign',
      badgeName: 'Rank SSS (Legend)',
      minLevel: 701,
      maxLevel: 999,
      primaryColor: Color(0xFFFFAB00),
      secondaryColor: Color(0xFFFF6D00),
      icon: Icons.stars_rounded,
      description: 'Legenda hidup Nimexx bermahkotakan emas abadi.',
      assetImage: 'assets/badges/rank_sss.jpg',
    ),
    RankTier(
      code: 'MYTHIC',
      title: 'Mythic Overlord',
      badgeName: 'Mythic Overlord',
      minLevel: 1000,
      maxLevel: 999999,
      primaryColor: Color(0xFFFF3D00),
      secondaryColor: Color(0xFFFFD600),
      icon: Icons.emoji_events_rounded,
      description: 'Dewa anime yang melampaui segala batas kekuatan!',
      assetImage: 'assets/badges/rank_overlord.jpg',
    ),
  ];

  // Rumus EXP Dibutuhkan untuk Naik ke Level Berikutnya (User-Friendly & Progressive)
  static int getExpForNextLevel(int currentLevel) {
    if (currentLevel <= 10) return 50;
    if (currentLevel <= 30) return 80;
    if (currentLevel <= 60) return 120;
    if (currentLevel <= 100) return 160;
    if (currentLevel <= 200) return 200;
    if (currentLevel <= 400) return 250;
    if (currentLevel <= 700) return 300;
    if (currentLevel <= 999) return 350;
    return 400;
  }

  // Ambil RankTier berdasarkan kode (misal 'E', 'S', dsb)
  static RankTier getRankByCode(String? code) {
    if (code == null) return allRanks.first;
    return allRanks.firstWhere(
      (r) => r.code.toUpperCase() == code.toUpperCase(),
      orElse: () => allRanks.first,
    );
  }

  // Ambil RankTier yang seharusnya berdasarkan level
  static RankTier getRankForLevel(int level) {
    for (int i = allRanks.length - 1; i >= 0; i--) {
      if (level >= allRanks[i].minLevel) {
        return allRanks[i];
      }
    }
    return allRanks.first;
  }

  // Format string tanggal hari ini (YYYY-MM-DD)
  static String getTodayKey() {
    final now = DateTime.now();
    return "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
  }

  /// Menambahkan EXP ke akun pengguna dengan validasi batas harian & kenaikan level
  Future<ExpRewardResult> addExp({
    required String uid,
    required String actionType, // 'watch', 'comment', 'login'
    int? customAmount,
  }) async {
    final userRef = _firestore.collection('users').doc(uid);

    return _firestore.runTransaction<ExpRewardResult>((transaction) async {
      final snapshot = await transaction.get(userRef);
      if (!snapshot.exists) {
        return const ExpRewardResult(success: false, message: 'User tidak ditemukan');
      }

      final data = snapshot.data() ?? {};
      final today = getTodayKey();

      final tracker = (data['daily_exp_tracker'] as Map<String, dynamic>?) ?? {};
      final trackerDate = tracker['date'] ?? '';

      int watchCount = (trackerDate == today) ? (tracker['watch_count'] as int? ?? 0) : 0;
      int commentCount = (trackerDate == today) ? (tracker['comment_count'] as int? ?? 0) : 0;
      bool loginClaimed = (trackerDate == today) ? (tracker['login_claimed'] as bool? ?? false) : false;

      int expToAdd = 0;
      String actionMsg = '';

      if (actionType == 'watch') {
        const maxWatchPerDay = 3;
        if (watchCount >= maxWatchPerDay) {
          return const ExpRewardResult(
            success: false,
            message: 'Batas harian tontonan episode tercapai (Maksimal 3/hari)',
          );
        }
        expToAdd = customAmount ?? 15;
        watchCount += 1;
        actionMsg = '+15 EXP Tontonan Episode ($watchCount/$maxWatchPerDay)';
      } else if (actionType == 'comment') {
        const maxCommentPerDay = 5;
        if (commentCount >= maxCommentPerDay) {
          return const ExpRewardResult(
            success: false,
            message: 'Batas harian komentar tercapai (Maksimal 5/hari)',
          );
        }
        expToAdd = customAmount ?? 5;
        commentCount += 1;
        actionMsg = '+5 EXP Komentar Berkualitas ($commentCount/$maxCommentPerDay)';
      } else if (actionType == 'login') {
        if (loginClaimed) {
          return const ExpRewardResult(
            success: false,
            message: 'Bonus login harian sudah diklaim hari ini',
          );
        }
        expToAdd = customAmount ?? 10;
        loginClaimed = true;
        actionMsg = '+10 EXP Login Harian!';
      } else {
        expToAdd = customAmount ?? 0;
      }

      if (expToAdd <= 0) {
        return const ExpRewardResult(success: false, message: 'Tidak ada EXP yang ditambahkan');
      }

      int currentExp = data['exp'] as int? ?? 0;
      int currentTotalExp = data['totalExp'] as int? ?? 0;
      int currentLevel = data['level'] as int? ?? 1;
      List<dynamic> unlockedBadges = List<dynamic>.from(data['unlocked_badges'] ?? ['E']);

      currentExp += expToAdd;
      currentTotalExp += expToAdd;

      bool leveledUp = false;
      int expNeeded = getExpForNextLevel(currentLevel);

      while (currentExp >= expNeeded) {
        currentExp -= expNeeded;
        currentLevel += 1;
        leveledUp = true;
        expNeeded = getExpForNextLevel(currentLevel);
      }

      // Cek apakah ada rank baru yang memenuhi syarat
      final correctRank = getRankForLevel(currentLevel);
      String? newRankUnlocked;
      if (!unlockedBadges.contains(correctRank.code)) {
        newRankUnlocked = correctRank.code;
      }

      transaction.update(userRef, {
        'exp': currentExp,
        'totalExp': currentTotalExp,
        'level': currentLevel,
        'daily_exp_tracker': {
          'date': today,
          'watch_count': watchCount,
          'comment_count': commentCount,
          'login_claimed': loginClaimed,
        },
      });

      return ExpRewardResult(
        success: true,
        expAdded: expToAdd,
        leveledUp: leveledUp,
        newLevel: currentLevel,
        newRankUnlocked: newRankUnlocked,
        message: leveledUp ? '$actionMsg • LEVEL UP! Sekarang Level $currentLevel' : actionMsg,
      );
    });
  }

  /// Klaim badge rank yang telah memenuhi syarat level
  Future<bool> claimBadge(String uid, String rankCode) async {
    final userRef = _firestore.collection('users').doc(uid);
    final rank = getRankByCode(rankCode);

    final snapshot = await userRef.get();
    if (!snapshot.exists) return false;

    final data = snapshot.data() ?? {};
    final level = data['level'] as int? ?? 1;
    final List unlockedBadges = List.from(data['unlocked_badges'] ?? ['E']);

    if (level < rank.minLevel) {
      throw Exception('Level Anda ($level) belum mencapai syarat (${rank.minLevel}) untuk klaim badge ${rank.badgeName}');
    }

    if (!unlockedBadges.contains(rank.code)) {
      unlockedBadges.add(rank.code);
    }

    await userRef.update({
      'unlocked_badges': unlockedBadges,
      'active_badge': rank.code,
    });

    return true;
  }

  /// Pasang badge aktif dari koleksi yang sudah pernah diklaim
  Future<bool> setActiveBadge(String uid, String rankCode) async {
    final userRef = _firestore.collection('users').doc(uid);
    final snapshot = await userRef.get();
    if (!snapshot.exists) return false;

    final data = snapshot.data() ?? {};
    final List unlockedBadges = List.from(data['unlocked_badges'] ?? ['E']);

    if (!unlockedBadges.contains(rankCode)) {
      throw Exception('Badge ini belum diklaim');
    }

    await userRef.update({
      'active_badge': rankCode,
    });

    return true;
  }

  /// Sinkronisasi retroaktif riwayat lama (tontonan, favorit, komentar) menjadi EXP & Level
  /// Memastikan akun-akun yang sudah lama aktif dan banyak menonton anime tidak ter-reset ke Level 1
  Future<Map<String, dynamic>> syncUserHistoricalExp(String uid, {bool force = false}) async {
    try {
      final userRef = _firestore.collection('users').doc(uid);
      final userSnap = await userRef.get();
      Map<String, dynamic> userData = {};

      if (!userSnap.exists) {
        // Cek apakah akun lama ini punya data di watch_history
        try {
          final checkSnap = await _firestore
              .collection('watch_history')
              .doc(uid)
              .collection('history')
              .limit(1)
              .get();
          if (checkSnap.docs.isNotEmpty) {
            await userRef.set({
              'uid': uid,
              'displayName': 'Pengguna Nimexx',
              'username': 'user_${uid.length > 6 ? uid.substring(0, 6) : uid}',
              'createdAt': FieldValue.serverTimestamp(),
              'role': 'user',
            }, SetOptions(merge: true));
            userData = {
              'uid': uid,
              'displayName': 'Pengguna Nimexx',
              'username': 'user_${uid.length > 6 ? uid.substring(0, 6) : uid}',
            };
          } else {
            return {'success': false, 'message': 'User tidak ditemukan'};
          }
        } catch (_) {
          return {'success': false, 'message': 'User tidak ditemukan'};
        }
      } else {
        userData = userSnap.data() ?? {};
      }

      final bool alreadySynced = userData['historical_synced'] as bool? ?? false;
      final int currentTotalExp = userData['totalExp'] as int? ?? 0;
      final int currentLevel = userData['level'] as int? ?? 1;
      final bool hasPublicHistory = (userData['public_history'] as List?)?.isNotEmpty == true;
      final bool hasPublicFavs = (userData['public_favorites'] as List?)?.isNotEmpty == true;

      // Jika sudah pernah disinkronkan, sudah memiliki EXP dan level > 1, serta sudah memiliki data public, baru lewati jika tidak dipaksa
      if (alreadySynced && currentTotalExp > 0 && currentLevel > 1 && hasPublicHistory && hasPublicFavs && !force) {
        return {
          'success': false,
          'message': 'Riwayat tontonan sudah pernah disinkronkan sebelumnya.',
        };
      }

      // 1. Ambil jumlah episode yang pernah ditonton
      int watchedCount = 0;
      List<Map<String, dynamic>> publicHistoryList = [];
      try {
        final historySnap = await _firestore
            .collection('watch_history')
            .doc(uid)
            .collection('history')
            .get();
        // Hitung episode yang ditonton
        watchedCount = historySnap.docs.where((doc) {
          final data = doc.data();
          return data['isWatched'] != false;
        }).length;
        publicHistoryList = historySnap.docs.take(50).map((d) {
          final dData = d.data();
          return {
            'episodeId': dData['episodeId'] ?? d.id,
            'title': dData['title'] ?? 'Episode',
            'animeTitle': dData['animeTitle'] ?? 'Anime',
            'thumb': dData['thumb'] ?? '',
            'animeEndpoint': dData['animeEndpoint'] ?? '',
            'isWatched': dData['isWatched'] ?? true,
            if (dData['watchedAt'] != null) 'watchedAt': dData['watchedAt'],
          };
        }).toList();
      } catch (e) {
        debugPrint('⚠️ Error membaca watch_history untuk sync EXP: $e');
      }

      // Fallback jika collection kosong tapi ada data cache synced_episodes/public_history
      final cachedSyncedEpisodes = userData['synced_episodes'] as int? ?? 0;
      final cachedPubHistory = (userData['public_history'] as List?)?.length ?? 0;
      if (cachedSyncedEpisodes > watchedCount) watchedCount = cachedSyncedEpisodes;
      if (cachedPubHistory > watchedCount) watchedCount = cachedPubHistory;

      // 2. Ambil jumlah anime favorit
      int favoriteCount = 0;
      List<Map<String, dynamic>> publicFavList = [];
      try {
        final favSnap = await _firestore
            .collection('users')
            .doc(uid)
            .collection('favorites')
            .get();
        favoriteCount = favSnap.docs.length;
        publicFavList = favSnap.docs.take(50).map((d) {
          final dData = d.data();
          return {
            'endpoint': dData['endpoint'] ?? d.id,
            'title': dData['title'] ?? 'Anime',
            'thumb': dData['thumb'] ?? '',
            if (dData['savedAt'] != null) 'savedAt': dData['savedAt'],
          };
        }).toList();
      } catch (e) {
        debugPrint('⚠️ Error membaca favorites untuk sync EXP: $e');
      }

      final cachedSyncedFavs = userData['synced_favorites'] as int? ?? 0;
      final cachedPubFavs = (userData['public_favorites'] as List?)?.length ?? 0;
      if (cachedSyncedFavs > favoriteCount) favoriteCount = cachedSyncedFavs;
      if (cachedPubFavs > favoriteCount) favoriteCount = cachedPubFavs;

      // 3. Ambil jumlah komentar yang pernah ditulis
      int commentCount = 0;
      final myComments = userData['my_comments'];
      if (myComments is List) {
        commentCount = myComments.length;
      }
      if (commentCount == 0) {
        try {
          final commentSnap = await _firestore
              .collection('users')
              .doc(uid)
              .collection('user_comments')
              .get();
          commentCount = commentSnap.docs.length;
        } catch (_) {}
      }

      // Perhitungan EXP Historis:
      // - 1 Episode = 15 EXP
      // - 1 Anime Favorit = 10 EXP
      // - 1 Komentar = 5 EXP
      final int historicalExp = (watchedCount * 15) + (favoriteCount * 10) + (commentCount * 5);

      final List<dynamic> currentUnlockedBadges = List<dynamic>.from(userData['unlocked_badges'] ?? ['E']);
      final String currentActiveBadge = userData['active_badge'] as String? ?? 'E';

      // Gunakan nilai total EXP tertinggi (antara historical atau yang sudah tercatat)
      final int finalTotalExp = (historicalExp > currentTotalExp) ? historicalExp : currentTotalExp;

      // Hitung Level dan Sisa EXP dari finalTotalExp
      int calculatedLevel = 1;
      int remainingExp = finalTotalExp;
      int expNeeded = getExpForNextLevel(calculatedLevel);

      while (remainingExp >= expNeeded) {
        remainingExp -= expNeeded;
        calculatedLevel += 1;
        expNeeded = getExpForNextLevel(calculatedLevel);
      }

      // Jangan pernah turunkan level user jika level saat ini sudah lebih tinggi
      final int finalLevel = (calculatedLevel > currentLevel) ? calculatedLevel : currentLevel;
      final int finalExp = (calculatedLevel > currentLevel) ? remainingExp : (userData['exp'] as int? ?? 0);

      // Hitung badge yang pantas dibuka
      final correctRank = getRankForLevel(finalLevel);
      final Set<String> newUnlockedBadges = Set<String>.from(currentUnlockedBadges);

      // Buka semua rank tier dari E hingga rank level saat ini
      for (final rank in allRanks) {
        if (finalLevel >= rank.minLevel) {
          newUnlockedBadges.add(rank.code);
        }
      }

      // Update badge aktif jika saat ini masih 'E' dan sudah membuka rank yang lebih tinggi
      String finalActiveBadge = currentActiveBadge;
      if (currentActiveBadge == 'E' && correctRank.code != 'E') {
        finalActiveBadge = correctRank.code;
      }

      // Resolusi nama & foto profil asli (Google / username / email)
      final rawDisplayName = (userData['displayName'] as String?)?.trim() ?? '';
      final rawName = (userData['name'] as String?)?.trim() ?? '';
      final rawUsername = (userData['username'] as String?)?.trim() ?? '';
      final rawEmail = (userData['email'] as String?)?.trim() ?? '';
      final emailPrefix = rawEmail.contains('@') ? rawEmail.split('@')[0].trim() : '';

      String? enrichedDisplayName;
      if (rawDisplayName.isEmpty || rawDisplayName == 'Pengguna Nimexx') {
        if (rawName.isNotEmpty && rawName != 'Pengguna Nimexx') {
          enrichedDisplayName = rawName;
        } else if (rawUsername.isNotEmpty && rawUsername != 'pengguna' && !rawUsername.startsWith('user_')) {
          enrichedDisplayName = rawUsername;
        } else if (emailPrefix.isNotEmpty) {
          enrichedDisplayName = emailPrefix;
        }
      }

      final rawPhoto = (userData['photoUrl'] as String?)?.trim() ?? '';
      String? enrichedPhoto;
      if (rawPhoto.isEmpty || rawPhoto.contains('default_profile.png')) {
        final photoAlt = (userData['photoURL'] as String?)?.trim() ??
            (userData['photo'] as String?)?.trim() ??
            (userData['avatar'] as String?)?.trim() ??
            (userData['profile_image'] as String?)?.trim() ?? '';
        if (photoAlt.isNotEmpty && (photoAlt.startsWith('http://') || photoAlt.startsWith('https://'))) {
          enrichedPhoto = photoAlt;
        }
      }

      final Map<String, dynamic> updatePayload = {
        'level': finalLevel,
        'exp': finalExp,
        'totalExp': finalTotalExp,
        'unlocked_badges': newUnlockedBadges.toList(),
        'active_badge': finalActiveBadge,
        'historical_synced': true,
        'synced_episodes': watchedCount,
        'synced_favorites': favoriteCount,
        'synced_comments': commentCount,
        if (publicHistoryList.isNotEmpty) 'public_history': publicHistoryList,
        if (publicFavList.isNotEmpty) 'public_favorites': publicFavList,
        if (enrichedDisplayName != null) 'displayName': enrichedDisplayName,
        if (enrichedPhoto != null) 'photoUrl': enrichedPhoto,
        'last_synced_at': FieldValue.serverTimestamp(),
      };

      try {
        await userRef.update(updatePayload);
      } catch (_) {
        await userRef.set(updatePayload, SetOptions(merge: true));
      }

      debugPrint('🎉 [RankService] Berhasil sinkronisasi historis untuk $uid: $watchedCount episode, $favoriteCount favorit -> Level $finalLevel ($finalTotalExp EXP)');

      return {
        'success': true,
        'level': finalLevel,
        'exp': finalExp,
        'totalExp': finalTotalExp,
        'watchedCount': watchedCount,
        'favoriteCount': favoriteCount,
        'commentCount': commentCount,
        'rank': correctRank.title,
        'badgeCode': correctRank.code,
        'message': 'Berhasil menyinkronkan $watchedCount episode & $favoriteCount favorit! Akun Anda kini Level $finalLevel (${correctRank.badgeName})',
      };
    } catch (e) {
      debugPrint('❌ [RankService] Gagal sinkronisasi historis: $e');
      return {'success': false, 'message': 'Gagal sinkronisasi: $e'};
    }
  }

  static bool _isSyncingAll = false;
  static bool _hasSyncedAllOnce = false;

  /// Sinkronisasi otomatis SEMUA akun di Firestore yang memiliki riwayat tontonan/favorit.
  /// Menghitung EXP, Level, dan Rank Badge asli mereka secara otomatis tanpa perlu login akun satu per satu.
  Future<void> autoSyncAllUsers({bool force = false}) async {
    if (_isSyncingAll) return;
    if (_hasSyncedAllOnce && !force) return;

    _isSyncingAll = true;
    try {
      debugPrint('🔄 [RankService] Memulai auto-sync level & leaderboard untuk semua akun...');

      // 1. Ambil semua dokumen user di koleksi 'users'
      final usersSnapshot = await _firestore.collection('users').get();
      final Set<String> uidsToCheck = {};
      final Map<String, Map<String, dynamic>> existingUserData = {};

      for (var doc in usersSnapshot.docs) {
        uidsToCheck.add(doc.id);
        existingUserData[doc.id] = doc.data();
      }

      // 2. Kumpulkan juga dokumen di 'watch_history' untuk akun lama
      try {
        final watchHistorySnap = await _firestore.collection('watch_history').get();
        for (var doc in watchHistorySnap.docs) {
          uidsToCheck.add(doc.id);
        }
      } catch (e) {
        debugPrint('⚠️ [RankService] Catatan scan watch_history: $e');
      }

      debugPrint('ℹ️ [RankService] Total akun yang terdeteksi untuk sync: ${uidsToCheck.length}');

      // 3. Jalankan sinkronisasi secara paralel berkelompok (batch 5)
      final List<String> listUids = uidsToCheck.toList();
      const int batchSize = 5;

      for (int i = 0; i < listUids.length; i += batchSize) {
        final chunk = listUids.sublist(
          i,
          (i + batchSize > listUids.length) ? listUids.length : i + batchSize,
        );

        await Future.wait(chunk.map((uid) async {
          final data = existingUserData[uid] ?? {};
          final bool alreadySynced = data['historical_synced'] as bool? ?? false;
          final int currentTotalExp = data['totalExp'] as int? ?? 0;
          final int currentLevel = data['level'] as int? ?? 1;
          final bool hasPublicHist = (data['public_history'] as List?)?.isNotEmpty == true;
          final bool hasPublicFav = (data['public_favorites'] as List?)?.isNotEmpty == true;

          // Jika sudah tersinkron dan EXP > 0 serta level > 1 dan sudah ada data publik, lewati jika bukan force
          if (alreadySynced && currentTotalExp > 0 && currentLevel > 1 && hasPublicHist && hasPublicFav && !force) {
            return;
          }

          await syncUserHistoricalExp(uid, force: force);
        }));
      }

      _hasSyncedAllOnce = true;
      debugPrint('✅ [RankService] Auto-sync semua akun selesai! Leaderboard otomatis ter-update.');
    } catch (e) {
      debugPrint('❌ [RankService] Gagal auto-sync akun: $e');
    } finally {
      _isSyncingAll = false;
    }
  }
}
