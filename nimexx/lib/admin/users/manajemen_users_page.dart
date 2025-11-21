import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../widgets/sidebar_admin.dart';
import 'widgets/user_data_table.dart';
import 'widgets/admin_user_list.dart';

class ManajemenUsersPage extends StatelessWidget {
  const ManajemenUsersPage({super.key});

  @override
  Widget build(BuildContext context) {
    const Color background = Color(0xFF121212);
    const Color cardBackground = Color(0xFF1E1E1E);
    const Color textPrimary = Colors.white;

    return Scaffold(
      backgroundColor: background,
      drawer: const AdminSidebar(currentRoute: '/admin/users'),
      appBar: AppBar(
        backgroundColor: cardBackground,
        elevation: 1,
        iconTheme: const IconThemeData(color: textPrimary),
        title: Row(
          children: [
            const Icon(Icons.group, color: Colors.orangeAccent),
            const SizedBox(width: 8),
            Text(
              'Manajemen Pengguna',
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
        padding: const EdgeInsets.all(20),
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.admin_panel_settings,
                  color: Colors.cyanAccent,
                ),
                const SizedBox(width: 8),
                Text(
                  'Daftar Admin',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const AdminUserList(),

            const SizedBox(height: 32),
            Row(
              children: [
                const Icon(Icons.bar_chart, color: Colors.purpleAccent),
                const SizedBox(width: 8),
                Text(
                  'Statistik Pengguna',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const UserDataTable(),
          ],
        ),
      ),
    );
  }
}
