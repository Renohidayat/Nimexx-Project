import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:math' as math;

import '../service/auth_service.dart';
import '../widgets/web_app_bar.dart';

class ProfileWebPage extends StatefulWidget {
  const ProfileWebPage({super.key});

  @override
  State<ProfileWebPage> createState() => _ProfileWebPageState();
}

class _ProfileWebPageState extends State<ProfileWebPage>
    with TickerProviderStateMixin {
  late AnimationController _borderController;
  late AnimationController _fadeController;
  late AnimationController _slideController;

  void _onWebNavSelected(int index, BuildContext context) {
    switch (index) {
      case 0:
        Navigator.pushNamed(context, '/home');
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
        Navigator.pushNamed(context, '/notification');
        break;
      case 7:
        Navigator.pushNamed(context, '/history');
        break;
      default:
        break;
    }
  }

  @override
  void initState() {
    super.initState();
    _borderController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _fadeController.forward();
    _slideController.forward();
  }

  @override
  void dispose() {
    _borderController.dispose();
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final screenWidth = MediaQuery.of(context).size.width;

    String? optimizedPhotoUrl;
    if (user?.photoURL != null) {
      optimizedPhotoUrl =
          user!.photoURL!.contains('?')
              ? user.photoURL
              : "${user.photoURL}?sz=256";
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: WebAppBar(
              selectedIndex: -1,
              onSelected: (index) => _onWebNavSelected(index, context),
            ),
          ),
          SliverToBoxAdapter(
            child: Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFF1A0A0A), Color(0xFF0A0A0A)],
                ),
              ),
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: screenWidth > 1200 ? 200 : 24,
                  vertical: 40,
                ),
                child: FadeTransition(
                  opacity: _fadeController,
                  child: Column(
                    children: [
                      // Header Section with Profile Picture
                      SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(0, -0.3),
                          end: Offset.zero,
                        ).animate(
                          CurvedAnimation(
                            parent: _slideController,
                            curve: Curves.easeOutCubic,
                          ),
                        ),
                        child: _buildProfileHeader(optimizedPhotoUrl, user),
                      ),

                      const SizedBox(height: 60),

                      // Profile Information Cards
                      SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(0, 0.3),
                          end: Offset.zero,
                        ).animate(
                          CurvedAnimation(
                            parent: _slideController,
                            curve: Curves.easeOutCubic,
                          ),
                        ),
                        child: _buildProfileInfo(user),
                      ),

                      const SizedBox(height: 50),

                      // Action Buttons
                      SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(0, 0.5),
                          end: Offset.zero,
                        ).animate(
                          CurvedAnimation(
                            parent: _slideController,
                            curve: Curves.easeOutCubic,
                          ),
                        ),
                        child: _buildActionButtons(context),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileHeader(String? photoUrl, User? user) {
    return Column(
      children: [
        // Animated Profile Picture
        Center(
          child: AnimatedBuilder(
            animation: _borderController,
            builder: (context, child) {
              return Container(
                width: 160,
                height: 160,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: SweepGradient(
                    startAngle: 0.0,
                    endAngle: 2 * math.pi,
                    colors: const [
                      Color(0xFFDC143C),
                      Color(0xFFFF6B6B),
                      Color(0xFFDC143C),
                      Color(0xFF8B0000),
                      Color(0xFFDC143C),
                    ],
                    transform: GradientRotation(
                      2 * math.pi * _borderController.value,
                    ),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFDC143C).withOpacity(0.3),
                      spreadRadius: 2,
                      blurRadius: 20,
                      offset: const Offset(0, 0),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: Container(
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Color(0xFF1A1A1A),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(4),
                      child: ClipOval(
                        child:
                            photoUrl != null
                                ? CachedNetworkImage(
                                  imageUrl: photoUrl,
                                  width: 140,
                                  height: 140,
                                  fit: BoxFit.cover,
                                  placeholder:
                                      (context, url) => Container(
                                        width: 140,
                                        height: 140,
                                        color: const Color(0xFF2A2A2A),
                                        child: const Center(
                                          child: CircularProgressIndicator(
                                            color: Color(0xFFDC143C),
                                            strokeWidth: 2,
                                          ),
                                        ),
                                      ),
                                  errorWidget:
                                      (context, url, error) => Container(
                                        width: 140,
                                        height: 140,
                                        decoration: const BoxDecoration(
                                          color: Color(0xFF2A2A2A),
                                        ),
                                        child: const Icon(
                                          Icons.person,
                                          size: 60,
                                          color: Color(0xFFDC143C),
                                        ),
                                      ),
                                )
                                : Container(
                                  width: 140,
                                  height: 140,
                                  decoration: const BoxDecoration(
                                    color: Color(0xFF2A2A2A),
                                  ),
                                  child: const Icon(
                                    Icons.person,
                                    size: 60,
                                    color: Color(0xFFDC143C),
                                  ),
                                ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),

        const SizedBox(height: 30),

        // User Name
        Text(
          user?.displayName ?? 'Otaku',
          style: GoogleFonts.poppins(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            letterSpacing: -0.5,
          ),
        ),

        const SizedBox(height: 8),

        // User Email
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A1A),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: const Color(0xFFDC143C).withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Text(
            user?.email ?? 'email@example.com',
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: const Color(0xFFB0B0B0),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProfileInfo(User? user) {
    return Column(
      children: [
        _buildInfoCard(
          icon: Icons.person_outline_rounded,
          title: 'Display Name',
          value: user?.displayName ?? 'Not Set',
        ),
        const SizedBox(height: 16),
        _buildInfoCard(
          icon: Icons.email_outlined,
          title: 'Email Address',
          value: user?.email ?? 'No Email',
        ),
        const SizedBox(height: 16),
        _buildInfoCard(
          icon: Icons.verified_outlined,
          title: 'Account Status',
          value: user?.emailVerified == true ? 'Verified' : 'Unverified',
          isVerified: user?.emailVerified,
        ),
      ],
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required String value,
    bool? isVerified,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF2A2A2A), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            spreadRadius: 1,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFDC143C).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: const Color(0xFFDC143C), size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: const Color(0xFFB0B0B0),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        value,
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    if (isVerified != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color:
                              isVerified
                                  ? const Color(0xFF4CAF50).withOpacity(0.2)
                                  : const Color(0xFFFFC107).withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          isVerified ? 'Verified' : 'Pending',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color:
                                isVerified
                                    ? const Color(0xFF4CAF50)
                                    : const Color(0xFFFFC107),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Column(
      children: [
        // Logout Button
        Container(
          width: double.infinity,
          height: 56,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFDC143C), Color(0xFF8B0000)],
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFDC143C).withOpacity(0.3),
                spreadRadius: 1,
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: ElevatedButton.icon(
            onPressed: () => _showLogoutDialog(context),
            icon: const Icon(
              Icons.logout_rounded,
              color: Colors.white,
              size: 20,
            ),
            label: Text(
              'Logout',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              shadowColor: Colors.transparent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1A1A1A),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: const BorderSide(color: Color(0xFF2A2A2A), width: 1),
          ),
          title: Row(
            children: [
              Icon(
                Icons.logout_rounded,
                color: const Color(0xFFDC143C),
                size: 28,
              ),
              const SizedBox(width: 12),
              Text(
                'Confirm Logout',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          content: Text(
            'Are you sure you want to logout from your account?',
            style: GoogleFonts.poppins(
              color: const Color(0xFFB0B0B0),
              fontSize: 16,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Cancel',
                style: GoogleFonts.poppins(
                  color: const Color(0xFFB0B0B0),
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await AuthService().signOut();
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  '/',
                  (route) => false,
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFDC143C),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: Text(
                'Logout',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
