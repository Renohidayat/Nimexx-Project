import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../widgets/sidebar_admin.dart';
import 'widgets/comment_list_view.dart';

class CommentsManagementPage extends StatelessWidget {
  const CommentsManagementPage({super.key});

  @override
  Widget build(BuildContext context) {
    const Color background = Color(0xFF121212);
    const Color cardBackground = Color(0xFF1E1E1E);
    const Color textPrimary = Colors.white;

    return Scaffold(
      backgroundColor: background,
      drawer: const AdminSidebar(currentRoute: '/admin/comments'),
      appBar: AppBar(
        backgroundColor: cardBackground,
        elevation: 1,
        iconTheme: const IconThemeData(color: textPrimary),
        title: Row(
          children: [
            const Icon(Icons.comment_rounded, color: Colors.orangeAccent),
            const SizedBox(width: 8),
            Text(
              'Manajemen Komentar',
              style: GoogleFonts.poppins(
                color: textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: IntrinsicHeight(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.list, color: Colors.cyanAccent),
                        const SizedBox(width: 8),
                        Text(
                          "Daftar Komentar",
                          style: GoogleFonts.poppins(
                            fontSize: 22,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const KomentarStatistikCard(),
                    const SizedBox(height: 24),
                    // Tambahkan list komentar di sini jika ada
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
