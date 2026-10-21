import 'package:flutter/material.dart';

class LeaderboardUser {
  final String uid;
  final String displayName;
  final String username;
  final String photoUrl;
  final int level;
  final int exp;
  final int totalExp;
  final String rankCode; // E, D, C, B, A, S, SS, SSS, MYTHIC
  final DateTime? createdAt;
  final int rankNumber;
  final bool isCurrentUser;

  const LeaderboardUser({
    required this.uid,
    required this.displayName,
    required this.username,
    required this.photoUrl,
    required this.level,
    required this.exp,
    required this.totalExp,
    required this.rankCode,
    this.createdAt,
    required this.rankNumber,
    this.isCurrentUser = false,
  });

  LeaderboardUser copyWith({
    String? uid,
    String? displayName,
    String? username,
    String? photoUrl,
    int? level,
    int? exp,
    int? totalExp,
    String? rankCode,
    DateTime? createdAt,
    int? rankNumber,
    bool? isCurrentUser,
  }) {
    return LeaderboardUser(
      uid: uid ?? this.uid,
      displayName: displayName ?? this.displayName,
      username: username ?? this.username,
      photoUrl: photoUrl ?? this.photoUrl,
      level: level ?? this.level,
      exp: exp ?? this.exp,
      totalExp: totalExp ?? this.totalExp,
      rankCode: rankCode ?? this.rankCode,
      createdAt: createdAt ?? this.createdAt,
      rankNumber: rankNumber ?? this.rankNumber,
      isCurrentUser: isCurrentUser ?? this.isCurrentUser,
    );
  }

  /// Usia akun dalam bulan yang sinkron persis dengan PublicProfilePage
  String get accountAge {
    if (createdAt == null) return 'Member Baru';
    final now = DateTime.now();
    final difference = now.difference(createdAt!);
    final days = difference.inDays;

    if (days < 30) {
      if (days <= 0) return 'Baru Bergabung';
      return '< 1 Bulan';
    } else {
      final months = (days / 30).floor();
      return '$months Bulan';
    }
  }

  /// Label pita/ribbon peringkat (e.g. TOP 1, TOP 2, TOP 3)
  String get topRankTag {
    if (rankNumber == 1) return 'TOP 1';
    if (rankNumber == 2) return 'TOP 2';
    if (rankNumber == 3) return 'TOP 3';
    if (rankNumber <= 10) return 'TOP 10';
    if (rankNumber <= 50) return 'TOP 50';
    return 'TOP 100';
  }

  /// Warna representatif dari nomor peringkat
  Color get rankColor {
    switch (rankNumber) {
      case 1:
        return const Color(0xFFFFD700); // Pure Gold
      case 2:
        return const Color(0xFFCFD8DC); // Silver
      case 3:
        return const Color(0xFFFF8A65); // Bronze Flame
      default:
        return const Color(0xFF90A4AE); // Steel Gray
    }
  }

  /// Format angka dengan pemisah titik (misal 12500 -> 12.500)
  static String formatNumber(num value) {
    final str = value.toInt().toString();
    final buffer = StringBuffer();
    int count = 0;
    for (int i = str.length - 1; i >= 0; i--) {
      buffer.write(str[i]);
      count++;
      if (count % 3 == 0 && i != 0) {
        buffer.write('.');
      }
    }
    return buffer.toString().split('').reversed.join('');
  }
}
