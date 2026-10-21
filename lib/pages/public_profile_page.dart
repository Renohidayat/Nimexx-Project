import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:cached_network_image/cached_network_image.dart';
import '../service/user_service.dart';
import '../service/history_service.dart';
import '../service/favorite_service.dart';
import '../service/comment_service.dart';
import '../service/notification_service.dart';
import '../service/rank_service.dart';
import '../widgets/rank_badge_widget.dart';
import 'private_chat_page.dart';
import 'anime_detail_page.dart';
import 'episode_page.dart';

class PublicProfilePage extends StatefulWidget {
  final String userId;

  const PublicProfilePage({super.key, required this.userId});

  @override
  State<PublicProfilePage> createState() => _PublicProfilePageState();
}

class _PublicProfilePageState extends State<PublicProfilePage> {
  final _userService = UserService();
  final _historyService = HistoryService();
  late final CommentService _commentService;
  final _currentUser = FirebaseAuth.instance.currentUser;
  
  Map<String, dynamic>? _userData;
  bool _isLoading = true;

  late Stream<QuerySnapshot<Map<String, dynamic>>> _historyStream;
  late Stream<QuerySnapshot<Map<String, dynamic>>> _favoritesStream;

  List<Map<String, dynamic>> _fallbackHistory = [];
  List<Map<String, dynamic>> _fallbackFavorites = [];

  int _selectedTab = 0; // 0: Tontonan, 1: Favorit, 2: Komentar
  List<Map<String, dynamic>> _userComments = [];
  bool _isLoadingComments = true;

  static const Color primaryOrange = Color(0xFFFF5E1E);
  static const Color darkBg = Color(0xFF07080B);
  static const Color surfaceCard = Color(0xFF0F1118);
  static const Color elevatedCard = Color(0xFF171924);

  @override
  void initState() {
    super.initState();
    _commentService = CommentService(NotificationService());
    _initStreams();
    _loadUser();
    _loadComments();
  }

  void _initStreams() {
    _historyStream = _historyService.getUserWatchHistoryStream(widget.userId);
    _favoritesStream = FavoriteService.getUserFavoritesStream(widget.userId);
  }

  @override
  void didUpdateWidget(PublicProfilePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.userId != widget.userId) {
      _initStreams();
      _loadUser();
      _loadComments();
    }
  }

  Future<void> _loadUser() async {
    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(widget.userId).get();
      if (doc.exists) {
        final data = doc.data() ?? {};
        final isMe = widget.userId == FirebaseAuth.instance.currentUser?.uid;
        if (isMe || data['historical_synced'] != true || (data['totalExp'] as int? ?? 0) == 0) {
          RankService().syncUserHistoricalExp(widget.userId, force: isMe).then((_) {
            FirebaseFirestore.instance.collection('users').doc(widget.userId).get().then((updated) {
              if (mounted && updated.exists) {
                setState(() => _userData = updated.data());
              }
            });
          });
        }
        if (mounted) {
          setState(() {
            _userData = data;
            _isLoading = false;
          });
        }
      } else {
        if (mounted) setState(() => _isLoading = false);
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }

    // Ambil data tontonan & favorit secara direct get sebagai fallback jika stream terkendala izin subcollection
    _historyService.getUserWatchHistory(widget.userId).then((list) {
      if (mounted && list.isNotEmpty) {
        setState(() => _fallbackHistory = list);
      }
    }).catchError((_) {});

    FavoriteService.getUserFavorites(widget.userId).then((list) {
      if (mounted && list.isNotEmpty) {
        setState(() => _fallbackFavorites = list);
      }
    }).catchError((_) {});
  }

  Future<void> _loadComments() async {
    final comments = await _commentService.getUserComments(widget.userId);
    if (mounted) {
      setState(() {
        _userComments = comments;
        _isLoadingComments = false;
      });
    }
  }

  static DateTime? _parseDateTime(dynamic val) {
    if (val == null) return null;
    if (val is Timestamp) return val.toDate();
    if (val is int) return DateTime.fromMillisecondsSinceEpoch(val);
    if (val is DateTime) return val;
    if (val is String) return DateTime.tryParse(val);
    return null;
  }


  String _formatAccountAge(DateTime? createdDate) {
    if (createdDate == null) return 'Member Baru';
    final now = DateTime.now();
    final difference = now.difference(createdDate);
    final days = difference.inDays;

    if (days < 30) {
      if (days <= 0) return 'Baru Bergabung';
      return '< 1 Bulan';
    } else {
      final months = (days / 30).floor();
      return '$months Bulan';
    }
  }

  void _openPhotoPreview(BuildContext context, String photoUrl, String displayName) {
    if (photoUrl.isEmpty) return;
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        barrierDismissible: true,
        barrierColor: Colors.black.withOpacity(0.9),
        pageBuilder: (BuildContext context, _, __) {
          return Scaffold(
            backgroundColor: Colors.transparent,
            appBar: AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
              title: Text(
                displayName,
                style: GoogleFonts.outfit(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold),
              ),
            ),
            body: Center(
              child: Hero(
                tag: 'public_profile_photo_${widget.userId}',
                child: InteractiveViewer(
                  panEnabled: true,
                  minScale: 0.8,
                  maxScale: 4.0,
                  child: Container(
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width * 0.95,
                      maxHeight: MediaQuery.of(context).size.height * 0.75,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.6),
                          blurRadius: 24,
                          spreadRadius: 4,
                        ),
                      ],
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: CachedNetworkImage(
                      imageUrl: photoUrl,
                      fit: BoxFit.contain,
                      placeholder: (_, __) => const Center(child: CircularProgressIndicator(color: primaryOrange)),
                      errorWidget: (_, __, ___) => const Icon(Icons.broken_image, size: 80, color: Colors.white54),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _handleAction() async {
    if (_currentUser == null) return;
    
    final currentUid = _currentUser.uid;
    final targetUid = widget.userId;

    final List friends = _userData?['friends'] ?? [];
    final List requests = _userData?['friendRequests'] ?? [];

    if (friends.contains(currentUid)) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => PrivateChatPage(
            peerId: targetUid,
            peerName: _userData?['displayName'] ?? 'Unknown',
            peerAvatar: _userData?['photoUrl'] ?? '',
          ),
        ),
      );
    } else if (requests.contains(currentUid)) {
      await FirebaseFirestore.instance.collection('users').doc(targetUid).update({
        'friendRequests': FieldValue.arrayRemove([currentUid]),
      });
      _loadUser();
    } else {
      await _userService.sendFriendRequest(currentUid, targetUid);
      _loadUser();
    }
  }

  Future<void> _acceptRequest() async {
    if (_currentUser == null) return;
    await _userService.acceptFriendRequest(_currentUser.uid, widget.userId);
    _loadUser();
  }

  Future<void> _removeFriend() async {
    if (_currentUser == null) return;
    await _userService.removeFriend(_currentUser.uid, widget.userId);
    _loadUser();
  }

  Widget _buildActionButton(List friends, List requests) {
    if (_currentUser == null || _currentUser.uid == widget.userId) {
      return const SizedBox.shrink();
    }

    final currentUid = _currentUser.uid;
    final iSentRequest = requests.contains(currentUid);
    final isFriend = friends.contains(currentUid);

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('users').doc(currentUid).snapshots(),
      builder: (context, snapshot) {
        final myData = snapshot.data?.data() as Map<String, dynamic>?;
        final myRequests = (myData?['friendRequests'] as List?) ?? [];
        final theySentMeRequest = myRequests.contains(widget.userId);

        if (isFriend) {
          return Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton.icon(
                onPressed: _handleAction,
                icon: const Icon(Icons.chat_bubble_rounded, size: 16),
                label: const Text('Kirim Pesan'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryOrange,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                decoration: BoxDecoration(
                  color: Colors.redAccent.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: IconButton(
                  onPressed: _removeFriend,
                  icon: const Icon(Icons.person_remove_rounded, color: Colors.redAccent, size: 18),
                  tooltip: 'Hapus Teman',
                ),
              ),
            ],
          );
        }

        if (theySentMeRequest) {
          return ElevatedButton.icon(
            onPressed: _acceptRequest,
            icon: const Icon(Icons.check_circle_outline_rounded, size: 16),
            label: const Text('Terima Permintaan'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            ),
          );
        }

        if (iSentRequest) {
          return ElevatedButton.icon(
            onPressed: _handleAction,
            icon: const Icon(Icons.how_to_reg_rounded, size: 16),
            label: const Text('Permintaan Terkirim'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white12,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            ),
          );
        }

        return ElevatedButton.icon(
          onPressed: _handleAction,
          icon: const Icon(Icons.person_add_rounded, size: 16),
          label: const Text('Tambah Teman'),
          style: ElevatedButton.styleFrom(
            backgroundColor: primaryOrange,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: darkBg,
        body: Center(child: CircularProgressIndicator(color: primaryOrange)),
      );
    }

    if (_userData == null) {
      return Scaffold(
        backgroundColor: darkBg,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: const Center(child: Text("Pengguna tidak ditemukan", style: TextStyle(color: Colors.white))),
      );
    }

    final rawDisplayName = (_userData?['displayName'] as String?)?.trim() ?? '';
    final rawName = (_userData?['name'] as String?)?.trim() ?? '';
    final rawUsername = (_userData?['username'] as String?)?.trim() ?? '';
    final rawEmail = (_userData?['email'] as String?)?.trim() ?? '';
    final emailPrefix = rawEmail.contains('@') ? rawEmail.split('@')[0].trim() : '';

    final displayName = rawDisplayName.isNotEmpty && rawDisplayName != 'Pengguna Nimexx'
        ? rawDisplayName
        : (rawName.isNotEmpty && rawName != 'Pengguna Nimexx'
            ? rawName
            : (rawUsername.isNotEmpty && rawUsername != 'pengguna' && !rawUsername.startsWith('user_')
                ? rawUsername
                : (emailPrefix.isNotEmpty ? emailPrefix : (rawDisplayName.isNotEmpty ? rawDisplayName : 'Pengguna Nimexx'))));

    final photoUrl = (_userData?['photoUrl'] as String?)?.trim().isNotEmpty == true
        ? (_userData!['photoUrl'] as String).trim()
        : ((_userData?['photoURL'] as String?)?.trim().isNotEmpty == true
            ? (_userData!['photoURL'] as String).trim()
            : ((_userData?['photo'] as String?)?.trim().isNotEmpty == true
                ? (_userData!['photo'] as String).trim()
                : ((_userData?['avatar'] as String?)?.trim().isNotEmpty == true
                    ? (_userData!['avatar'] as String).trim()
                    : '')));
    final username = rawUsername.isNotEmpty ? rawUsername : (emailPrefix.isNotEmpty ? emailPrefix : 'pengguna');
    final bio = _userData?['bio'] ?? '';
    final friends = _userData?['friends'] ?? [];
    final requests = _userData?['friendRequests'] ?? [];

    // Level & Rank Data Dinamis (Dihitung cerdas dari riwayat nyata akun)
    int epCount = (_userData?['synced_episodes'] as int?) ?? 0;
    int favCount = (_userData?['synced_favorites'] as int?) ?? 0;
    int commentCount = (_userData?['synced_comments'] as int?) ?? 0;
    final pubHistCheck = _userData?['public_history'] ?? _userData?['recent_history'] ?? _userData?['history'] ?? _userData?['watched_episodes'];
    if (pubHistCheck is List && pubHistCheck.length > epCount) epCount = pubHistCheck.length;
    final pubFavCheck = _userData?['public_favorites'] ?? _userData?['favorites'] ?? _userData?['my_favorites'];
    if (pubFavCheck is List && pubFavCheck.length > favCount) favCount = pubFavCheck.length;

    final calcExp = (epCount * 15) + (favCount * 10) + (commentCount * 5);
    final recordedTotalExp = _userData?['totalExp'] as int? ?? 0;
    final recordedLevel = _userData?['level'] as int? ?? 1;
    final recordedExp = _userData?['exp'] as int? ?? 0;

    int effectiveRecordedExp = recordedTotalExp;
    if (effectiveRecordedExp == 100 && recordedLevel <= 1 && recordedExp == 0 && calcExp == 0) {
      effectiveRecordedExp = 0;
    }

    int totalExp = effectiveRecordedExp > calcExp ? effectiveRecordedExp : calcExp;
    int userLevel = recordedLevel;
    int userExp = recordedExp;

    if (totalExp > 0) {
      int calcLevel = 1;
      int remExp = totalExp;
      int expNeed = RankService.getExpForNextLevel(calcLevel);
      while (remExp >= expNeed) {
        remExp -= expNeed;
        calcLevel += 1;
        expNeed = RankService.getExpForNextLevel(calcLevel);
      }
      if (calcLevel > userLevel) {
        userLevel = calcLevel;
        userExp = remExp;
      }
    }

    final calculatedRankCode = RankService.getRankForLevel(userLevel).code;
    String activeBadge = _userData?['active_badge'] as String? ?? '';
    if (activeBadge.isEmpty || (activeBadge == 'E' && calculatedRankCode != 'E')) {
      activeBadge = calculatedRankCode;
    }
    final rankInfo = RankService.getRankForLevel(userLevel);
    final expNeeded = RankService.getExpForNextLevel(userLevel);

    // Hitung Usia Akun
    final createdAt = (_userData?['createdAt'] as Timestamp?)?.toDate();
    final accountAge = _formatAccountAge(createdAt);

    return Scaffold(
      backgroundColor: darkBg,
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: _historyStream,
        builder: (context, histSnap) {
          return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: _favoritesStream,
            builder: (context, favSnap) {
              // 1. Ambil seluruh riwayat tontonan real
              List<Map<String, dynamic>> historyItems = [];
              if (histSnap.hasData && histSnap.data!.docs.isNotEmpty) {
                historyItems = histSnap.data!.docs.map((d) {
                  final m = Map<String, dynamic>.from(d.data());
                  m['episodeId'] = m['episodeId'] ?? d.id;
                  return m;
                }).toList();
              } else if (_userData != null) {
                final pubHist = _userData!['public_history'] ??
                    _userData!['recent_history'] ??
                    _userData!['history'] ??
                    _userData!['watched_episodes'];
                if (pubHist is List && pubHist.isNotEmpty) {
                  historyItems = List<Map<String, dynamic>>.from(
                    pubHist.map((e) => Map<String, dynamic>.from(e as Map)),
                  );
                }
              }
              if (historyItems.isEmpty && _fallbackHistory.isNotEmpty) {
                historyItems = List<Map<String, dynamic>>.from(_fallbackHistory);
              }

              // Urutkan riwayat tontonan dari yang paling baru
              historyItems.sort((a, b) {
                final aTime = _parseDateTime(a['watchedAt'] ?? a['timestamp'] ?? a['createdAt']);
                final bTime = _parseDateTime(b['watchedAt'] ?? b['timestamp'] ?? b['createdAt']);
                if (aTime == null && bTime == null) return 0;
                if (aTime == null) return 1;
                if (bTime == null) return -1;
                return bTime.compareTo(aTime);
              });

              int historyDisplayCount = historyItems.length;
              final syncedEpisodes = _userData?['synced_episodes'] as int? ?? 0;
              if (syncedEpisodes > historyDisplayCount) {
                historyDisplayCount = syncedEpisodes;
              }

              // 2. Ambil seluruh anime favorit real
              List<Map<String, dynamic>> favoriteItems = [];
              if (favSnap.hasData && favSnap.data!.docs.isNotEmpty) {
                favoriteItems = favSnap.data!.docs.map((d) {
                  final m = Map<String, dynamic>.from(d.data());
                  m['endpoint'] = m['endpoint'] ?? d.id;
                  return m;
                }).toList();
              } else if (_userData != null) {
                final pubFav = _userData!['public_favorites'] ??
                    _userData!['favorites'] ??
                    _userData!['my_favorites'];
                if (pubFav is List && pubFav.isNotEmpty) {
                  favoriteItems = List<Map<String, dynamic>>.from(
                    pubFav.map((e) => Map<String, dynamic>.from(e as Map)),
                  );
                }
              }
              if (favoriteItems.isEmpty && _fallbackFavorites.isNotEmpty) {
                favoriteItems = List<Map<String, dynamic>>.from(_fallbackFavorites);
              }

              // Urutkan anime favorit dari yang paling baru
              favoriteItems.sort((a, b) {
                final aTime = _parseDateTime(a['savedAt'] ?? a['timestamp'] ?? a['createdAt']);
                final bTime = _parseDateTime(b['savedAt'] ?? b['timestamp'] ?? b['createdAt']);
                if (aTime == null && bTime == null) return 0;
                if (aTime == null) return 1;
                if (bTime == null) return -1;
                return bTime.compareTo(aTime);
              });

              int favoriteDisplayCount = favoriteItems.length;
              final syncedFavorites = _userData?['synced_favorites'] as int? ?? 0;
              if (syncedFavorites > favoriteDisplayCount) {
                favoriteDisplayCount = syncedFavorites;
              }

              // Hitung Level, EXP & Badge dinamis dari total aktivitas aktual Stream
              int currentEp = historyDisplayCount > epCount ? historyDisplayCount : epCount;
              int currentFav = favoriteDisplayCount > favCount ? favoriteDisplayCount : favCount;
              final dynamicCalcExp = (currentEp * 15) + (currentFav * 10) + (commentCount * 5);
              int activeTotalExp = effectiveRecordedExp > dynamicCalcExp ? effectiveRecordedExp : dynamicCalcExp;
              int activeLevel = userLevel;
              int activeExp = userExp;

              if (activeTotalExp > totalExp) {
                int cLvl = 1;
                int rExp = activeTotalExp;
                int nExp = RankService.getExpForNextLevel(cLvl);
                while (rExp >= nExp) {
                  rExp -= nExp;
                  cLvl += 1;
                  nExp = RankService.getExpForNextLevel(cLvl);
                }
                if (cLvl > activeLevel) {
                  activeLevel = cLvl;
                  activeExp = rExp;
                }
              }

              final activeRank = RankService.getRankForLevel(activeLevel);
              String activeBadgeCode = activeBadge;
              if (activeBadgeCode == 'E' && activeRank.code != 'E') {
                activeBadgeCode = activeRank.code;
              }
              final activeExpNeeded = RankService.getExpForNextLevel(activeLevel);

              // Auto-heal akun lama: jika data aktual dari stream lebih tinggi dari yang tersimpan di Firestore
              if (activeTotalExp > recordedTotalExp && activeTotalExp > 0) {
                FirebaseFirestore.instance.collection('users').doc(widget.userId).update({
                  'level': activeLevel,
                  'exp': activeExp,
                  'totalExp': activeTotalExp,
                  'synced_episodes': currentEp,
                  'synced_favorites': currentFav,
                  'active_badge': activeBadgeCode,
                }).catchError((_) {});
              }

              return RefreshIndicator(
                onRefresh: () async {
                  await Future.wait([
                    _loadUser(),
                    _loadComments(),
                  ]);
                },
                color: primaryOrange,
                backgroundColor: surfaceCard,
                child: CustomScrollView(
                  physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                  slivers: [
          SliverAppBar(
            expandedHeight: 270,
            pinned: true,
            backgroundColor: surfaceCard,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
              onPressed: () => Navigator.pop(context),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  if (photoUrl.isNotEmpty)
                    CachedNetworkImage(
                      imageUrl: photoUrl,
                      fit: BoxFit.cover,
                      errorWidget: (_, __, ___) => Container(color: surfaceCard),
                    )
                  else
                    Container(color: surfaceCard),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.transparent,
                          darkBg.withOpacity(0.85),
                          darkBg,
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                  Align(
                    alignment: Alignment.bottomCenter,
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 16.0),
                      child: GestureDetector(
                        onTap: () => _openPhotoPreview(context, photoUrl, displayName),
                        child: Hero(
                          tag: 'public_profile_photo_${widget.userId}',
                          child: Stack(
                            alignment: Alignment.bottomRight,
                            children: [
                              Container(
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(color: primaryOrange, width: 3),
                                  boxShadow: [
                                    BoxShadow(
                                      color: primaryOrange.withOpacity(0.4),
                                      blurRadius: 20,
                                      spreadRadius: 2,
                                    ),
                                  ],
                                ),
                                child: CircleAvatar(
                                  radius: 48,
                                  backgroundImage: photoUrl.isNotEmpty ? NetworkImage(photoUrl) : null,
                                  backgroundColor: elevatedCard,
                                  child: photoUrl.isEmpty
                                      ? Text(
                                          displayName.isNotEmpty ? displayName[0].toUpperCase() : '?',
                                          style: const TextStyle(fontSize: 38, color: Colors.white, fontWeight: FontWeight.bold),
                                        )
                                      : null,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.all(4),
                                decoration: const BoxDecoration(
                                  color: primaryOrange,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.verified_rounded, size: 16, color: Colors.white),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // 1. Display Name
                  Text(
                    displayName,
                    style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 3),

                  // 2. Username Tepat di Bawah Nama (Hapus usia akun di sampingnya!)
                  if (username.isNotEmpty)
                    Text(
                      '@$username',
                      style: TextStyle(
                        color: Colors.grey[400],
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  const SizedBox(height: 12),

                  // 3. Badge & Level (Mencolok, Ukuran Pas, Bersinar Terang!)
                  RankBadgeWidget(
                    rankCode: activeBadgeCode,
                    level: activeLevel,
                    compact: false,
                    hero: true,
                  ),
                  const SizedBox(height: 12),

                  // 4. Info Teman di Bawah Badge dan Level
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.06),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white.withOpacity(0.08)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.people_alt_rounded, size: 14, color: primaryOrange),
                        const SizedBox(width: 5),
                        Text(
                          '${friends.length} Teman',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Container(
                          margin: const EdgeInsets.symmetric(horizontal: 10),
                          width: 4,
                          height: 4,
                          decoration: const BoxDecoration(
                            color: Colors.white38,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const Icon(Icons.history_rounded, size: 14, color: Color(0xFF64B5F6)),
                        const SizedBox(width: 5),
                        Text(
                          'Aktif $accountAge',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  // BIO TAMPIL TEPAT DI BAWAH NAMA
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: surfaceCard,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white.withOpacity(0.06)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: primaryOrange.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.format_quote_rounded, color: primaryOrange, size: 16),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'BIO',
                                style: TextStyle(color: Colors.grey[500], fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.8),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                bio.isNotEmpty ? bio : 'Pengguna ini belum menuliskan bio.',
                                style: TextStyle(
                                  color: bio.isNotEmpty ? Colors.white70 : Colors.grey[600],
                                  fontSize: 13,
                                  fontStyle: bio.isNotEmpty ? FontStyle.normal : FontStyle.italic,
                                  height: 1.4,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Rank & Level Card for Public Profile
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          surfaceCard,
                          activeRank.primaryColor.withOpacity(0.1),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: activeRank.primaryColor.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: [
                              BoxShadow(
                                color: activeRank.primaryColor.withOpacity(0.35),
                                blurRadius: 10,
                                spreadRadius: 1,
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Image.asset(
                              activeRank.assetImage,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                decoration: BoxDecoration(
                                  color: activeRank.primaryColor.withOpacity(0.2),
                                  shape: BoxShape.circle,
                                  border: Border.all(color: activeRank.primaryColor, width: 1.5),
                                ),
                                child: Icon(activeRank.icon, color: activeRank.primaryColor, size: 18),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${activeRank.badgeName} • Level $activeLevel',
                                style: GoogleFonts.outfit(
                                  color: Colors.white,
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                activeRank.title,
                                style: TextStyle(color: Colors.grey[400], fontSize: 11),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: activeRank.primaryColor.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '$activeExp / $activeExpNeeded EXP',
                            style: TextStyle(
                              color: activeRank.primaryColor,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Action Button (Friend status / Add Friend)
                  _buildActionButton(friends, requests),
                  const SizedBox(height: 20),

                  // Modern 4-Capsule Stat Cards
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
                    decoration: BoxDecoration(
                      color: surfaceCard,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: Colors.white.withOpacity(0.05)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.25),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildStatItem('Tontonan', historyDisplayCount.toString(), Icons.play_circle_fill_rounded),
                        _buildStatDivider(),
                        _buildStatItem('Favorit', favoriteDisplayCount.toString(), Icons.bookmark_rounded),
                        _buildStatDivider(),
                        _buildStatItem('Komentar', _userComments.length.toString(), Icons.chat_bubble_rounded),
                        _buildStatDivider(),
                        _buildStatItem('Usia Akun', accountAge, Icons.schedule_rounded),
                      ],
                    ),
                  ),
                  const SizedBox(height: 22),

                  // Segmented Modern Tab Bar
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: surfaceCard,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.white.withOpacity(0.05)),
                    ),
                    child: Row(
                      children: [
                        _buildTabButton(0, 'Tontonan ($historyDisplayCount)', Icons.play_arrow_rounded),
                        _buildTabButton(1, 'Favorit ($favoriteDisplayCount)', Icons.favorite_rounded),
                        _buildTabButton(2, 'Komentar (${_userComments.length})', Icons.chat_bubble_outline_rounded),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),

          // Tab Content Area
          _buildSelectedTabContent(
            historyItems: historyItems,
            isLoadingHistory: histSnap.connectionState == ConnectionState.waiting && historyItems.isEmpty,
            historyDisplayCount: historyDisplayCount,
            favoriteItems: favoriteItems,
            isLoadingFavorites: favSnap.connectionState == ConnectionState.waiting && favoriteItems.isEmpty,
            favoriteDisplayCount: favoriteDisplayCount,
          ),

          const SliverToBoxAdapter(
            child: SizedBox(height: 40),
          ),
        ],
      ),
    );
  },
);
},
),
);
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: primaryOrange),
            const SizedBox(width: 4),
            Text(
              value,
              style: GoogleFonts.outfit(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(color: Colors.grey[500], fontSize: 11),
        ),
      ],
    );
  }

  Widget _buildStatDivider() {
    return Container(
      height: 24,
      width: 1,
      color: Colors.white.withOpacity(0.08),
    );
  }

  Widget _buildTabButton(int index, String label, IconData icon) {
    final isSelected = _selectedTab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() => _selectedTab = index);
          if (index == 2) {
            _loadComments();
          }
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? primaryOrange : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: primaryOrange.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    )
                  ]
                : [],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 16, color: isSelected ? Colors.white : Colors.grey[400]),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  color: isSelected ? Colors.white : Colors.grey[400],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSelectedTabContent({
    required List<Map<String, dynamic>> historyItems,
    required bool isLoadingHistory,
    required int historyDisplayCount,
    required List<Map<String, dynamic>> favoriteItems,
    required bool isLoadingFavorites,
    required int favoriteDisplayCount,
  }) {
    switch (_selectedTab) {
      case 0:
        return _buildWatchHistorySliver(historyItems, isLoadingHistory, historyDisplayCount);
      case 1:
        return _buildFavoritesSliver(favoriteItems, isLoadingFavorites, favoriteDisplayCount);
      case 2:
        return _buildCommentsSliver();
      default:
        return const SliverToBoxAdapter(child: SizedBox.shrink());
    }
  }

  // 1. Tontonan Tab
  Widget _buildWatchHistorySliver(List<Map<String, dynamic>> items, bool isLoading, int historyDisplayCount) {
    if (isLoading) {
      return const SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.all(32.0),
          child: Center(child: CircularProgressIndicator(color: primaryOrange)),
        ),
      );
    }

    if (items.isEmpty) {
      if (historyDisplayCount > 0) {
        return SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 36.0, horizontal: 24.0),
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
                decoration: BoxDecoration(
                  color: surfaceCard,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: primaryOrange.withOpacity(0.25)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: primaryOrange.withOpacity(0.12),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.lock_outline_rounded, size: 30, color: primaryOrange),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      '$historyDisplayCount Episode Telah Ditonton',
                      style: GoogleFonts.outfit(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Daftar rincian riwayat episode disimpan secara privat atau belum disinkronkan ke profil publik oleh pemilik akun.',
                      style: TextStyle(color: Colors.grey[400], fontSize: 12.5, height: 1.4),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }
      return _buildEmptyState(Icons.play_circle_outline_rounded, "Pengguna ini belum memiliki riwayat tontonan");
    }

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final item = items[index];
            final episodeTitle = item['title'] ?? item['episodeTitle'] ?? 'Episode';
            final animeTitle = item['animeTitle'] ?? 'Anime';
            final thumb = item['thumb'] ?? item['thumbUrl'] ?? '';
            final episodeId = item['episodeId'] ?? '';
            final animeEndpoint = item['animeEndpoint'] ?? '';
            final watchedAt = _parseDateTime(item['watchedAt'] ?? item['timestamp'] ?? item['createdAt']);
            final timeStr = watchedAt != null ? timeago.format(watchedAt, locale: 'id') : '';

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: surfaceCard,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.white.withOpacity(0.05)),
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.all(10),
                leading: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        width: 76,
                        height: 52,
                        color: elevatedCard,
                        child: thumb.isNotEmpty
                            ? CachedNetworkImage(
                                imageUrl: thumb,
                                fit: BoxFit.cover,
                                errorWidget: (_, __, ___) => const Icon(Icons.movie_creation_outlined, color: Colors.grey),
                              )
                            : const Icon(Icons.movie_creation_outlined, color: Colors.grey),
                      ),
                      Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.6),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.play_arrow_rounded, color: primaryOrange, size: 16),
                      ),
                    ],
                  ),
                ),
                title: Text(
                  animeTitle,
                  style: GoogleFonts.outfit(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 2),
                    Text(
                      episodeTitle,
                      style: TextStyle(color: Colors.grey[400], fontSize: 12),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (timeStr.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        timeStr,
                        style: TextStyle(color: primaryOrange.withOpacity(0.8), fontSize: 11),
                      ),
                    ],
                  ],
                ),
                trailing: const Icon(Icons.chevron_right_rounded, color: Colors.grey, size: 20),
                onTap: () {
                  if (episodeId.isNotEmpty) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => EpisodePage(
                          endpoint: episodeId,
                          episodeTitle: episodeTitle,
                          animeTitle: animeTitle,
                          thumbUrl: thumb,
                          animeEndpoint: animeEndpoint.isNotEmpty ? animeEndpoint : null,
                        ),
                      ),
                    );
                  }
                },
              ),
            );
          },
          childCount: items.length,
        ),
      ),
    );
  }

  // 2. Favorit Tab
  Widget _buildFavoritesSliver(List<Map<String, dynamic>> items, bool isLoading, int favoriteDisplayCount) {
    if (isLoading) {
      return const SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.all(32.0),
          child: Center(child: CircularProgressIndicator(color: primaryOrange)),
        ),
      );
    }

    if (items.isEmpty) {
      if (favoriteDisplayCount > 0) {
        return SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 36.0, horizontal: 24.0),
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
                decoration: BoxDecoration(
                  color: surfaceCard,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: primaryOrange.withOpacity(0.25)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: primaryOrange.withOpacity(0.12),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.bookmark_outline_rounded, size: 30, color: primaryOrange),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      '$favoriteDisplayCount Anime Favorit Tersimpan',
                      style: GoogleFonts.outfit(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Koleksi anime favorit pengguna ini disimpan dalam mode privat atau menunggu sinkronisasi publik.',
                      style: TextStyle(color: Colors.grey[400], fontSize: 12.5, height: 1.4),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }
      return _buildEmptyState(Icons.bookmark_border_rounded, "Pengguna ini belum menyimpan anime favorit");
    }

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.7,
          crossAxisSpacing: 14,
          mainAxisSpacing: 14,
        ),
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final fav = items[index];
            final title = fav['title'] ?? fav['animeTitle'] ?? 'Anime';
            final endpoint = fav['endpoint'] ?? fav['animeEndpoint'] ?? '';
            final thumb = fav['thumb'] ?? fav['thumbUrl'] ?? '';

            return GestureDetector(
              onTap: () {
                if (endpoint.isNotEmpty) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => AnimeDetailPage(endpoint: endpoint, title: title),
                    ),
                  );
                }
              },
              child: Container(
                decoration: BoxDecoration(
                  color: surfaceCard,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.white.withOpacity(0.05)),
                ),
                clipBehavior: Clip.antiAlias,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    thumb.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: thumb,
                            fit: BoxFit.cover,
                            errorWidget: (_, __, ___) => Container(color: elevatedCard),
                          )
                        : Container(color: elevatedCard),
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.transparent, Colors.black.withOpacity(0.85)],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 10,
                      left: 10,
                      right: 10,
                      child: Text(
                        title,
                        style: GoogleFonts.outfit(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
          childCount: items.length,
        ),
      ),
    );
  }

  // 3. Komentar Tab (DILENGKAPI GAMBAR ANIME & EPISODE DETAIL)
  Widget _buildCommentsSliver() {
    if (_isLoadingComments) {
      return const SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.all(32.0),
          child: Center(child: CircularProgressIndicator(color: primaryOrange)),
        ),
      );
    }

    if (_userComments.isEmpty) {
      return _buildEmptyState(Icons.chat_bubble_outline_rounded, "Pengguna ini belum pernah berkomentar di anime");
    }

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final comment = _userComments[index];
            final content = comment['content'] ?? '';
            final animeTitle = comment['animeTitle'] ?? 'Anime';
            final episodeTitle = comment['episodeTitle'] ?? 'Episode';
            final episodeId = comment['episodeId'] ?? '';
            final thumbUrl = comment['thumbUrl'] ?? '';
            final rawTimestamp = comment['timestamp'];
            DateTime? commentDate;
            if (rawTimestamp is Timestamp) {
              commentDate = rawTimestamp.toDate();
            } else if (rawTimestamp is int) {
              commentDate = DateTime.fromMillisecondsSinceEpoch(rawTimestamp);
            } else if (rawTimestamp is DateTime) {
              commentDate = rawTimestamp;
            } else if (rawTimestamp is String) {
              commentDate = DateTime.tryParse(rawTimestamp);
            }
            final timeStr = commentDate != null ? timeago.format(commentDate, locale: 'id') : '';

            return Container(
              margin: const EdgeInsets.only(bottom: 14),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: surfaceCard,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withOpacity(0.06)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // GAMBAR POSTER / THUMBNAIL ANIME
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      width: 66,
                      height: 88,
                      color: elevatedCard,
                      child: thumbUrl.isNotEmpty
                          ? CachedNetworkImage(
                              imageUrl: thumbUrl,
                              fit: BoxFit.cover,
                              errorWidget: (_, __, ___) => Container(
                                color: elevatedCard,
                                child: const Icon(Icons.movie_creation_outlined, color: primaryOrange, size: 28),
                              ),
                            )
                          : Container(
                              color: elevatedCard,
                              child: const Icon(Icons.movie_creation_outlined, color: primaryOrange, size: 28),
                            ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  // KONTEN KOMENTAR & METADATA
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                animeTitle,
                                style: GoogleFonts.outfit(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (timeStr.isNotEmpty) ...[
                              const SizedBox(width: 6),
                              Text(
                                timeStr,
                                style: TextStyle(color: Colors.grey[500], fontSize: 11),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: primaryOrange.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: primaryOrange.withOpacity(0.25)),
                          ),
                          child: Text(
                            episodeTitle,
                            style: const TextStyle(
                              color: primaryOrange,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          content,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 13,
                            height: 1.35,
                          ),
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (episodeId.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Align(
                            alignment: Alignment.centerRight,
                            child: GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => EpisodePage(
                                      endpoint: episodeId,
                                      episodeTitle: episodeTitle,
                                      animeTitle: animeTitle,
                                      thumbUrl: thumbUrl,
                                    ),
                                  ),
                                );
                              },
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    'Buka Episode',
                                    style: TextStyle(color: primaryOrange, fontSize: 11, fontWeight: FontWeight.bold),
                                  ),
                                  SizedBox(width: 4),
                                  Icon(Icons.arrow_forward_rounded, color: primaryOrange, size: 13),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
          childCount: _userComments.length,
        ),
      ),
    );
  }

  Widget _buildEmptyState(IconData icon, String message) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 40.0, horizontal: 20.0),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 48, color: Colors.grey[700]),
              const SizedBox(height: 12),
              Text(
                message,
                style: TextStyle(color: Colors.grey[500], fontSize: 13),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
