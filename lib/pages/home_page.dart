import 'dart:async';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../widgets/frosted_glass_bottom_bar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'anime_list_page.dart';
import 'release_schedule_page.dart';
import 'ongoing_anime_page.dart';
import 'genre_list_page.dart';
import 'search_page.dart';
import 'profile_page.dart';
import '../widgets/web_app_bar.dart';
import '../widgets/hero_banner.dart';
import '../widgets/ongoing_anime_section.dart';
import '../widgets/completed_anime_section.dart';
import '../widgets/home_personal_section.dart';
import '../widgets/footer_widget.dart';
import 'chat_history_page.dart';
import '../widgets/global_chat_preview.dart';
import '../service/rank_service.dart';
import '../widgets/home_rank_banner_switcher.dart';
import '../widgets/user_avatar_widget.dart';

class BerandaTabWebOrMobile extends StatelessWidget {
  const BerandaTabWebOrMobile({super.key});

  @override
  Widget build(BuildContext context) {
    return kIsWeb ? const _BerandaTabWeb() : const _BerandaTabMobile();
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;
  bool _isNavBarVisible = true;
  Timer? _scrollStopTimer;

  @override
  void initState() {
    super.initState();
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      RankService().syncUserHistoricalExp(user.uid);
    }
  }

  @override
  void dispose() {
    _scrollStopTimer?.cancel();
    super.dispose();
  }

  void _onScrollNotification(ScrollNotification notification) {
    if (notification is UserScrollNotification) {
      if (notification.direction == ScrollDirection.reverse) {
        // User sedang scroll ke bawah -> sembunyikan navigasi agar halaman lebih lega
        _scrollStopTimer?.cancel();
        if (_isNavBarVisible) {
          setState(() => _isNavBarVisible = false);
        }
      } else if (notification.direction == ScrollDirection.forward) {
        // User scroll ke atas -> munculkan navigasi kembali
        _scrollStopTimer?.cancel();
        if (!_isNavBarVisible) {
          setState(() => _isNavBarVisible = true);
        }
      } else if (notification.direction == ScrollDirection.idle) {
        // User berhenti scroll -> munculkan navigasi kembali
        _scrollStopTimer?.cancel();
        _scrollStopTimer = Timer(const Duration(milliseconds: 350), () {
          if (mounted && !_isNavBarVisible) {
            setState(() => _isNavBarVisible = true);
          }
        });
      }
    } else if (notification is ScrollEndNotification) {
      // Saat momentum scroll berhenti
      _scrollStopTimer?.cancel();
      _scrollStopTimer = Timer(const Duration(milliseconds: 350), () {
        if (mounted && !_isNavBarVisible) {
          setState(() => _isNavBarVisible = true);
        }
      });
    }
  }

  final List<Widget> _pages = const [
    BerandaTabWebOrMobile(),
    AnimeListPage(),
    ReleaseSchedulePage(),
    OngoingAnimePage(),
    GenreListPage(),
    SearchPage(),
    ProfilePage(),
  ];

  void _onSelected(int index) {
    _scrollStopTimer?.cancel();
    setState(() {
      _selectedIndex = index;
      _isNavBarVisible = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    const isWeb = kIsWeb;

    return Scaffold(
      backgroundColor: Colors.black,
      extendBody: true,
      body: NotificationListener<ScrollNotification>(
        onNotification: (notification) {
          _onScrollNotification(notification);
          return false;
        },
        child: IndexedStack(
          index: _selectedIndex,
          children: _pages,
        ),
      ),
      bottomNavigationBar:
          !isWeb
              ? FrostedGlassBottomBar(
                  currentIndex: _selectedIndex,
                  isVisible: _isNavBarVisible,
                  onTap: _onSelected,
                  items: const [
                    FrostedGlassBarItem(
                      icon: Icons.home_outlined,
                      activeIcon: Icons.home_rounded,
                      label: "Beranda",
                      color: Color(0xFFFF2A3C),
                    ),
                    FrostedGlassBarItem(
                      icon: Icons.format_list_bulleted_rounded,
                      activeIcon: Icons.format_list_bulleted_rounded,
                      label: "List",
                      color: Color(0xFFAF52DE),
                    ),
                    FrostedGlassBarItem(
                      icon: Icons.calendar_month_outlined,
                      activeIcon: Icons.calendar_month_rounded,
                      label: "Jadwal",
                      color: Color(0xFF00C7BE),
                    ),
                    FrostedGlassBarItem(
                      icon: Icons.play_circle_outline_rounded,
                      activeIcon: Icons.play_circle_fill_rounded,
                      label: "Ongoing",
                      color: Color(0xFFFF5722),
                    ),
                    FrostedGlassBarItem(
                      icon: Icons.grid_view_outlined,
                      activeIcon: Icons.grid_view_rounded,
                      label: "Genre",
                      color: Color(0xFFFFB300),
                    ),
                  ],
                )
              : null,
    );
  }
}

class _BerandaTabWeb extends StatelessWidget {
  const _BerandaTabWeb();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          WebAppBar(
            selectedIndex: 0,
            onSelected: (index) => _handleMenuSelected(context, index),
          ),
          const HeroBanner(),
          const SizedBox(height: 16),
          const HomePersonalSection(),
          const SizedBox(height: 16),
          const OngoingAnimeSection(),
          const SizedBox(height: 32),
          const CompletedAnimeSection(),
          const SizedBox(height: 32),
          const FooterWidget(),
        ],
      ),
    );
  }

  void _handleMenuSelected(BuildContext context, int index) {
    switch (index) {
      case 0:
        Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
        break;
      case 1:
        Navigator.pushNamed(context, '/list');
        break;
      case 2:
        Navigator.pushNamed(context, '/schedule');
        break;
      case 3:
        Navigator.pushNamed(context, '/ongoing');
        break;
      case 4:
        Navigator.pushNamed(context, '/genre');
        break;
      case 5:
        Navigator.pushNamed(context, '/search');
        break;
      case 6:
        Navigator.pushNamed(context, '/profile');
        break;
    }
  }
}

// class _BerandaTabMobile dan _MobileHeader tetap sama seperti sebelumnya.

class _BerandaTabMobile extends StatelessWidget {
  const _BerandaTabMobile();

  @override
  Widget build(BuildContext context) {
    return const SafeArea(
      bottom: false,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _MobileHeader(),
            SizedBox(height: 16),
            HeroBanner(),
            SizedBox(height: 24),
            HomeRankBannerSwitcher(),
            SizedBox(height: 32),
            HomePersonalSection(),
            SizedBox(height: 24),
            GlobalChatPreview(),
            SizedBox(height: 16),
            OngoingAnimeSection(),
            SizedBox(height: 32),
            CompletedAnimeSection(),
            SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

class _MobileHeader extends StatelessWidget {
  const _MobileHeader();

  String getGreeting() {
    final hour = DateTime.now().hour;
    if (hour >= 4 && hour < 10) return 'Selamat pagi';
    if (hour >= 10 && hour < 15) return 'Selamat siang';
    if (hour >= 15 && hour < 18) return 'Selamat sore';
    return 'Selamat malam';
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final greeting = getGreeting();

    if (user == null) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0xFF1C1C28),
            borderRadius: BorderRadius.circular(32),
            border: Border.all(color: Colors.white10),
            boxShadow: [
              BoxShadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 12, offset: const Offset(0, 4)),
            ],
          ),
          child: Row(
            children: [
              const UserAvatarWidget(
                photoUrl: null,
                displayName: 'Pengguna',
                radius: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      greeting,
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w300, color: Colors.white70),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const Text(
                      'Pengguna',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('users').doc(user.uid).snapshots(),
      builder: (context, snapshot) {
        String? photoUrl = user.photoURL;
        String userName = user.displayName ?? 'Pengguna';

        if (snapshot.hasData && snapshot.data!.data() != null) {
          final userData = snapshot.data!.data() as Map<String, dynamic>;
          photoUrl = userData['photoUrl'] ?? photoUrl;
          userName = userData['displayName'] ?? userName;
        }

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFF1C1C28),
              borderRadius: BorderRadius.circular(32),
              border: Border.all(color: Colors.white10),
              boxShadow: [
                BoxShadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 12, offset: const Offset(0, 4)),
              ],
            ),
            child: Row(
              children: [
                // 👉 Avatar Profil Bergaya Akun Google
                UserAvatarWidget(
                  photoUrl: photoUrl,
                  displayName: userName,
                  radius: 22,
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfilePage()));
                  },
                ),
                const SizedBox(width: 12),

                // 👉 Sapaan dan Nama (Aman dari Bug Squish)
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        greeting,
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w400, color: Colors.white70),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        userName,
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(width: 8),

                // 🔍 Search Action
                _buildActionBtn(Icons.search, Colors.white, () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const SearchPage()));
                }),

                // 💬 Chat History Action
                _buildActionBtn(Icons.chat_bubble_rounded, const Color(0xFFFF5722), () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const ChatHistoryPage()));
                }),

                // 🔔 Notifications Action
                StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('users')
                      .doc(user.uid)
                      .collection('notifications')
                      .where('read', isEqualTo: false)
                      .snapshots(),
                  builder: (context, snapshot) {
                    final unread = snapshot.data?.docs.length ?? 0;
                    return Stack(
                      clipBehavior: Clip.none,
                      children: [
                        _buildActionBtn(Icons.notifications_rounded, Colors.white, () {
                          Navigator.pushNamed(context, '/notifications');
                        }),
                        if (unread > 0)
                          Positioned(
                            right: 2,
                            top: 2,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFF5722),
                                border: Border.all(color: const Color(0xFF1C1C28), width: 2),
                                shape: BoxShape.circle,
                              ),
                              constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                              child: Center(
                                child: Text(
                                  unread > 9 ? '9+' : unread.toString(),
                                  style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                          ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ✅ Wrapper icon dengan efek hover modern
  Widget _buildActionBtn(IconData icon, Color color, VoidCallback onTap) {
    return Container(
      margin: const EdgeInsets.only(left: 6),
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white10,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(30),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Icon(icon, color: color, size: 20),
          ),
        ),
      ),
    );
  }
}
