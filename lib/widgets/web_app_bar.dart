import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../pages/profil_web_page.dart';

typedef OnSelectedCallback = void Function(int);

class WebAppBar extends StatefulWidget implements PreferredSizeWidget {
  final int selectedIndex;
  final OnSelectedCallback onSelected;
  final double mobileBreakpoint;

  const WebAppBar({
    Key? key,
    required this.selectedIndex,
    required this.onSelected,
    this.mobileBreakpoint = 800,
  }) : super(key: key);

  @override
  Size get preferredSize => const Size.fromHeight(72);

  @override
  State<WebAppBar> createState() => _WebAppBarState();
}

class _WebAppBarState extends State<WebAppBar>
    with SingleTickerProviderStateMixin {
  User? _currentUser;
  static const double _avatarRadius = 18;
  bool _showMobileMenu = false;
  late AnimationController _menuController;
  late Animation<double> _menuAnimation;

  final List<Map<String, dynamic>> _menuItems = const [
    {
      'label': 'Home',
      'index': 0,
      'icon': Icons.home_outlined,
      'activeIcon': Icons.home,
    },
    {
      'label': 'List',
      'index': 1,
      'icon': Icons.list_alt_outlined,
      'activeIcon': Icons.list,
    },
    {
      'label': 'Schedule',
      'index': 2,
      'icon': Icons.calendar_today_outlined,
      'activeIcon': Icons.calendar_month,
    },
    {
      'label': 'Ongoing',
      'index': 3,
      'icon': Icons.play_circle_outline,
      'activeIcon': Icons.play_circle,
    },
    {
      'label': 'Genres',
      'index': 4,
      'icon': Icons.category_outlined,
      'activeIcon': Icons.category,
    },
  ];

  @override
  void initState() {
    super.initState();
    _initializeUser();
    _menuController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _menuAnimation = CurvedAnimation(
      parent: _menuController,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _menuController.dispose();
    super.dispose();
  }

  Future<void> _initializeUser() async {
    _currentUser = FirebaseAuth.instance.currentUser;
    if (mounted) setState(() {});
  }

  void _toggleMobileMenu() {
    setState(() {
      _showMobileMenu = !_showMobileMenu;
      _showMobileMenu ? _menuController.forward() : _menuController.reverse();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isMobile =
        MediaQuery.of(context).size.width < widget.mobileBreakpoint;
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.grey[900] : Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildLogo(isDarkMode),
                  if (!isMobile) _buildDesktopNavMenu(theme),
                  _buildActionIcons(context, isDarkMode),
                  if (isMobile) _buildMobileMenuButton(),
                ],
              ),
            ),
            if (isMobile) _buildMobileMenu(theme),
          ],
        ),
      ),
    );
  }

  Widget _buildLogo(bool isDarkMode) {
    final isMobile =
        MediaQuery.of(context).size.width < widget.mobileBreakpoint;

    return GestureDetector(
      onTap: () => widget.onSelected(0),
      child: Tooltip(
        message: 'Kembali ke Beranda',
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Image.asset(
              'assets/images/logo.png',
              height: 28,
              fit: BoxFit.contain,
              semanticLabel: 'Logo',
              errorBuilder:
                  (_, __, ___) => const Icon(
                    Icons.movie_filter_rounded,
                    size: 28,
                    color: Colors.orangeAccent,
                  ),
            ),
            if (!isMobile) ...[
              const SizedBox(width: 8),
              Text(
                'Nimexx',
                style: GoogleFonts.oswald(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: isDarkMode ? Colors.white : Colors.black,
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDesktopNavMenu(ThemeData theme) {
    return Expanded(
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children:
                _menuItems.map((item) {
                  final selected = widget.selectedIndex == item['index'];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      curve: Curves.easeInOut,
                      decoration: BoxDecoration(
                        color:
                            selected ? theme.primaryColor : Colors.transparent,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(20),
                          onTap: () => widget.onSelected(item['index']),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  selected ? item['activeIcon'] : item['icon'],
                                  size: 18,
                                  color:
                                      selected
                                          ? Colors.white
                                          : theme.iconTheme.color,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  item['label'],
                                  style: GoogleFonts.poppins(
                                    fontWeight: FontWeight.w500,
                                    fontSize: 12,
                                    color:
                                        selected
                                            ? Colors.white
                                            : theme.textTheme.bodyLarge?.color,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildActionIcons(BuildContext context, bool isDarkMode) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildIconButton(
          icon: Icons.search_rounded,
          tooltip: 'Search',
          color: isDarkMode ? Colors.white : Colors.grey[800],
          onPressed: () => widget.onSelected(5),
        ),
        _buildIconButton(
          icon: Icons.favorite_border_rounded,
          activeIcon: Icons.favorite_rounded,
          tooltip: 'Favorites',
          color: Colors.pinkAccent,
          onPressed: () => Navigator.pushNamed(context, '/favorites'),
        ),
        _buildIconButton(
          icon: Icons.history_outlined,
          activeIcon: Icons.history_rounded,
          tooltip: 'History',
          color: isDarkMode ? Colors.white : Colors.grey[800],
          onPressed: () => Navigator.pushNamed(context, '/history'),
        ),
        _buildNotificationIcon(isDarkMode),
        const SizedBox(width: 8),
        _buildProfileAvatar(isDarkMode),
      ],
    );
  }

  Widget _buildMobileMenuButton() {
    return IconButton(
      icon: AnimatedIcon(
        icon: AnimatedIcons.menu_close,
        progress: _menuAnimation,
        color:
            Theme.of(context).brightness == Brightness.dark
                ? Colors.white
                : Colors.black87,
      ),
      onPressed: _toggleMobileMenu,
    );
  }

  Widget _buildMobileMenu(ThemeData theme) {
    final isDarkMode = theme.brightness == Brightness.dark;

    return SizeTransition(
      sizeFactor: _menuAnimation,
      axis: Axis.vertical,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isDarkMode ? const Color(0xFF1E1E1E) : const Color(0xFFF9F9F9),
          border: Border(
            top: BorderSide(
              color: isDarkMode ? Colors.white12 : Colors.grey.withOpacity(0.2),
              width: 1,
            ),
          ),
        ),
        child: ListView(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children:
              _menuItems.map((item) {
                final selected = widget.selectedIndex == item['index'];
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: ListTile(
                    leading: Icon(
                      selected ? item['activeIcon'] : item['icon'],
                      color:
                          selected
                              ? theme.colorScheme.primary
                              : (isDarkMode ? Colors.white70 : Colors.black54),
                    ),
                    title: Text(
                      item['label'],
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w500,
                        color:
                            selected
                                ? theme.colorScheme.primary
                                : (isDarkMode
                                    ? Colors.white70
                                    : Colors.black87),
                      ),
                    ),
                    trailing:
                        selected
                            ? Icon(
                              Icons.arrow_forward_ios_rounded,
                              size: 16,
                              color: theme.colorScheme.primary,
                            )
                            : null,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    tileColor:
                        selected
                            ? theme.colorScheme.primary.withOpacity(0.1)
                            : Colors.transparent,
                    onTap: () {
                      widget.onSelected(item['index']);
                      _toggleMobileMenu();
                    },
                  ),
                );
              }).toList(),
        ),
      ),
    );
  }

  Widget _buildIconButton({
    required IconData icon,
    IconData? activeIcon,
    required String tooltip,
    required VoidCallback onPressed,
    Color? color,
  }) {
    return IconButton(
      tooltip: tooltip,
      iconSize: 20,
      icon: Icon(icon, color: color),
      onPressed: onPressed,
      splashRadius: 20,
    );
  }

  Widget _buildNotificationIcon(bool isDarkMode) {
    return StreamBuilder<QuerySnapshot>(
      stream:
          _currentUser?.uid != null
              ? FirebaseFirestore.instance
                  .collection('users')
                  .doc(_currentUser!.uid)
                  .collection('notifications')
                  .where('read', isEqualTo: false)
                  .snapshots()
              : null,
      builder: (context, snapshot) {
        final unreadCount = snapshot.data?.docs.length ?? 0;
        return Badge(
          label:
              unreadCount > 0
                  ? Text(
                    unreadCount > 9 ? '9+' : unreadCount.toString(),
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  )
                  : null,
          alignment: Alignment.topRight,
          child: _buildIconButton(
            icon: Icons.notifications_outlined,
            activeIcon: Icons.notifications_rounded,
            tooltip: 'Notifications',
            color: isDarkMode ? Colors.white : Colors.grey[800],
            onPressed: () => Navigator.pushNamed(context, '/notifications'),
          ),
        );
      },
    );
  }

  Widget _buildProfileAvatar(bool isDarkMode) {
    return GestureDetector(
      onTap:
          () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ProfileWebPage()),
          ),
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: isDarkMode ? Colors.grey[700]! : Colors.grey[300]!,
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: CircleAvatar(
          radius: _avatarRadius,
          backgroundColor:
              isDarkMode
                  ? const Color.fromARGB(255, 196, 75, 75)
                  : Colors.grey[200],
          child: ClipOval(
            child:
                _currentUser?.photoURL != null
                    ? CachedNetworkImage(
                      imageUrl: "${_currentUser!.photoURL}?sz=96",
                      width: _avatarRadius * 2,
                      height: _avatarRadius * 2,
                      fit: BoxFit.cover,
                      placeholder:
                          (_, __) => Center(
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: isDarkMode ? Colors.white : Colors.black,
                            ),
                          ),
                      errorWidget: (_, __, ___) => _buildDefaultAvatar(),
                    )
                    : _buildDefaultAvatar(),
          ),
        ),
      ),
    );
  }

  Widget _buildDefaultAvatar() {
    return Image.asset(
      'assets/images/default_profile.png',
      width: _avatarRadius * 2,
      height: _avatarRadius * 2,
      fit: BoxFit.cover,
      errorBuilder:
          (_, __, ___) => Icon(
            Icons.person_rounded,
            size: _avatarRadius * 1.5,
            color: Theme.of(context).iconTheme.color,
          ),
    );
  }
}
