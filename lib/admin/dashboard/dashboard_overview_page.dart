import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../widgets/sidebar_admin.dart';
import 'widgets/total_pengunjung_card.dart';
import 'widgets/episode_view_chart.dart';
import 'widgets/total_favorit_card.dart';
import 'widgets/statistik_komentar_card.dart';

class DashboardOverviewPage extends StatelessWidget {
  const DashboardOverviewPage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final String email = user?.email ?? '-';
    final String? photoUrl = user?.photoURL;
    final String lastLogin =
        user?.metadata.lastSignInTime != null
            ? DateFormat(
              'dd MMM yyyy • HH:mm',
              'id_ID',
            ).format(user!.metadata.lastSignInTime!)
            : '-';

    const Color darkBackground = Color(0xFF121212);
    const Color cardBackground = Color(0xFF1E1E1E);
    const Color textPrimary = Colors.white;
    const Color textSecondary = Colors.white70;

    return Scaffold(
      backgroundColor: darkBackground,
      drawer: const AdminSidebar(currentRoute: '/admin/dashboard'),
      appBar: AppBar(
        backgroundColor: cardBackground,
        elevation: 1,
        title: Row(
          children: [
            const Icon(Icons.dashboard_customize, color: textPrimary),
            const SizedBox(width: 8),
            Text(
              'Dashboard Overview',
              style: GoogleFonts.poppins(
                color: textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Info Admin
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              margin: const EdgeInsets.only(bottom: 32),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: Colors.white.withOpacity(0.05),
                border: Border.all(color: Colors.white10),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.15),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 32,
                    backgroundImage:
                        photoUrl != null ? NetworkImage(photoUrl) : null,
                    backgroundColor: Colors.grey.shade800,
                    child:
                        photoUrl == null
                            ? const Icon(
                              Icons.person,
                              size: 32,
                              color: Colors.white70,
                            )
                            : null,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Selamat Datang, Admin",
                          style: GoogleFonts.poppins(
                            color: textPrimary,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          email,
                          style: GoogleFonts.poppins(
                            color: textSecondary,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Login terakhir: $lastLogin',
                          style: GoogleFonts.poppins(
                            color: textSecondary,
                            fontSize: 12,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // 📊 Statistik Utama
            Row(
              children: [
                const Icon(Icons.bar_chart, color: Colors.purpleAccent),
                const SizedBox(width: 8),
                Text(
                  "Statistik Utama",
                  style: GoogleFonts.poppins(
                    color: textPrimary,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: const [
                Expanded(child: TotalPengunjungCard()),
                SizedBox(width: 16),
                Expanded(child: TotalFavoritCard()),
              ],
            ),

            const SizedBox(height: 32),
            Row(
              children: [
                const Icon(Icons.show_chart, color: Colors.cyanAccent),
                const SizedBox(width: 8),
                Text(
                  'Statistik Kunjungan Episode',
                  style: GoogleFonts.poppins(
                    color: textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: cardBackground,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 10,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: const EpisodeViewChart(),
            ),

            const SizedBox(height: 32),
            Row(
              children: [
                const Icon(Icons.comment, color: Colors.greenAccent),
                const SizedBox(width: 8),
                Text(
                  'Statistik Komentar',
                  style: GoogleFonts.poppins(
                    color: textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: cardBackground,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 10,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: const KomentarStatistikCard(),
            ),

            const SizedBox(height: 36),
            Center(
              child: Text(
                "Terakhir diperbarui: ${DateFormat('EEE, dd MMM yyyy • HH:mm').format(DateTime.now())}",
                style: GoogleFonts.poppins(
                  color: textSecondary,
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
