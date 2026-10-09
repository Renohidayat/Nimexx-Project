import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:salomon_bottom_bar/salomon_bottom_bar.dart';
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
import '../widgets/footer_widget.dart';

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
    setState(() => _selectedIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    final isWeb = kIsWeb;

    return Scaffold(
      backgroundColor: Colors.black,
      body: IndexedStack(
        index: _selectedIndex,
        children: _pages,
      ),
      bottomNavigationBar:
          !isWeb
              ? SalomonBottomBar(
                currentIndex: _selectedIndex,
                onTap: _onSelected,
                items: [
                  SalomonBottomBarItem(
                    icon: Icon(Icons.home),
                    title: Text("Beranda"),
                    selectedColor: const Color.fromARGB(255, 255, 7, 7),
                  ),
                  SalomonBottomBarItem(
                    icon: Icon(Icons.list),
                    title: Text("List"),
                    selectedColor: Colors.purple,
                  ),
                  SalomonBottomBarItem(
                    icon: Icon(Icons.calendar_today),
                    title: Text("Jadwal"),
                    selectedColor: Colors.teal,
                  ),
                  SalomonBottomBarItem(
                    icon: Icon(Icons.play_circle_fill),
                    title: Text("Ongoing"),
                    selectedColor: Colors.red,
                  ),
                  SalomonBottomBarItem(
                    icon: Icon(Icons.category),
                    title: Text("Genre"),
                    selectedColor: Colors.orange,
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

class _BerandaTabMobile extends StatefulWidget {
  const _BerandaTabMobile();

  @override
  State<_BerandaTabMobile> createState() => _BerandaTabMobileState();
}

class _BerandaTabMobileState extends State<_BerandaTabMobile>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _scaleAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutBack,
    );
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeIn));
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _MobileHeader(),
            const SizedBox(height: 16),
            const HeroBanner(),
            const SizedBox(height: 24),
            Center(
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: ScaleTransition(
                  scale: _scaleAnimation,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 800),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFFF0000), Color(0xFFFF8800)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFFF7B00).withOpacity(0.3),
                              blurRadius: 10,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.asset(
                                'assets/images/logo.png',
                                height: 50,
                                width: 50,
                                fit: BoxFit.cover,
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Expanded(
                              child: Text(
                                'Duduk santai, siapkan camilan, dan mari tenggelam dalam dunia anime kesayanganmu!',
                                style: TextStyle(
                                  fontSize: 15,
                                  color: Colors.white,
                                  height: 1.3,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 32),
            const OngoingAnimeSection(),
            const SizedBox(height: 32),
            const CompletedAnimeSection(),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

class _MobileHeader extends StatefulWidget {
  const _MobileHeader();

  @override
  State<_MobileHeader> createState() => _MobileHeaderState();
}

class _MobileHeaderState extends State<_MobileHeader>
    with SingleTickerProviderStateMixin {
  bool showActions = false;

  late final AnimationController _controller;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
    _slide = Tween<Offset>(
      begin: const Offset(1, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

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
    final photoUrl = user?.photoURL;
    final userName = user?.displayName ?? 'Pengguna';
    final greeting = getGreeting();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          // 👉 Avatar Profil
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ProfilePage()),
              );
            },
            child: CircleAvatar(
              radius: 20,
              backgroundImage:
                  photoUrl != null
                      ? NetworkImage(photoUrl)
                      : const AssetImage('assets/images/default_profile.png')
                          as ImageProvider,
            ),
          ),
          const SizedBox(width: 12),

          // 👉 Sapaan dan Nama
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  greeting,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w300,
                    color: Colors.white70,
                  ),
                ),
                Text(
                  userName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),

          // 🔽 Toggle Tombol Aksi "<"
          _buildIcon(
            showActions ? Icons.chevron_right : Icons.chevron_left,
            Colors.white,
            () {
              setState(() {
                showActions = !showActions;
                if (showActions) {
                  _controller.forward();
                } else {
                  _controller.reverse();
                }
              });
            },
          ),

          const SizedBox(width: 4), // jarak antara "<" dan search
          // 🔍 Search (selalu tampil dengan border)
          _buildIcon(Icons.search, Colors.orange, () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SearchPage()),
            );
          }),

          // 🔽 Menu tambahan (fade + slide animasi)
          if (showActions)
            FadeTransition(
              opacity: _fade,
              child: SlideTransition(
                position: _slide,
                child: Row(
                  children: [
                    _buildIcon(Icons.favorite, Colors.redAccent, () {
                      Navigator.pushNamed(context, '/favorites');
                    }),
                    _buildIcon(Icons.history, Colors.orange, () {
                      Navigator.pushNamed(context, '/history');
                    }),
                    StreamBuilder<QuerySnapshot>(
                      stream:
                          FirebaseFirestore.instance
                              .collection('users')
                              .doc(user?.uid)
                              .collection('notifications')
                              .where('read', isEqualTo: false)
                              .snapshots(),
                      builder: (context, snapshot) {
                        final unread = snapshot.data?.docs.length ?? 0;
                        return Stack(
                          children: [
                            _buildIcon(Icons.notifications, Colors.white, () {
                              Navigator.pushNamed(context, '/notifications');
                            }),
                            if (unread > 0)
                              Positioned(
                                right: 6,
                                top: 6,
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: const BoxDecoration(
                                    color: Colors.red,
                                    shape: BoxShape.circle,
                                  ),
                                  constraints: const BoxConstraints(
                                    minWidth: 18,
                                    minHeight: 18,
                                  ),
                                  child: Center(
                                    child: Text(
                                      unread.toString(),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
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
            ),
        ],
      ),
    );
  }

  // ✅ Wrapper icon dengan border dan padding bulat
  Widget _buildIcon(IconData icon, Color color, VoidCallback onTap) {
    return Container(
      margin: const EdgeInsets.only(left: 6),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white10,
        border: Border.all(color: Colors.white30),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(30),
        child: Icon(icon, color: color, size: 20),
      ),
    );
  }
}
