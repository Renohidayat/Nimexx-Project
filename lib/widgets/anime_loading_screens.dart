import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../widgets/web_app_bar.dart'; // Import WebAppBar
import 'package:shimmer/shimmer.dart';

class ModernLoadingScreens {
  static const Color cardBackground = Color(0xFF1A1A1A);

  static Widget buildLoadingScreen({
    int selectedIndex = 0,
    Function(int)? onMenuSelected,
  }) {
    Widget loadingContent = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          int crossAxisCount = 3;
          if (width >= 1200) crossAxisCount = 6;
          else if (width >= 992) crossAxisCount = 5;
          else if (width >= 768) crossAxisCount = 4;
          
          return GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              childAspectRatio: 0.65,
              crossAxisSpacing: 12,
              mainAxisSpacing: 16,
            ),
            itemCount: crossAxisCount * 3, // Tampilkan 3 baris skeleton
            itemBuilder: (context, index) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Shimmer.fromColors(
                      baseColor: Colors.grey[850]!,
                      highlightColor: Colors.grey[700]!,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.black,
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Shimmer.fromColors(
                    baseColor: Colors.grey[850]!,
                    highlightColor: Colors.grey[700]!,
                    child: Container(
                      height: 14,
                      width: double.infinity,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Shimmer.fromColors(
                    baseColor: Colors.grey[850]!,
                    highlightColor: Colors.grey[700]!,
                    child: Container(
                      height: 14,
                      width: 80,
                      color: Colors.black,
                    ),
                  ),
                ],
              );
            },
          );
        }
      ),
    );

    // Jika web, wrap dengan Column yang include WebAppBar
    if (kIsWeb && onMenuSelected != null) {
      return Column(
        children: [
          WebAppBar(selectedIndex: selectedIndex, onSelected: onMenuSelected),
          Expanded(child: loadingContent),
        ],
      );
    }

    // Jika mobile, return loading content biasa
    return loadingContent;
  }

  static Widget buildErrorScreen(
    String error, {
    int selectedIndex = 0,
    Function(int)? onMenuSelected,
    VoidCallback? onRetry,
  }) {
    Widget errorContent = Center(
      child: Container(
        margin: const EdgeInsets.all(24),
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: cardBackground,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.red.withOpacity(0.3)),
          boxShadow: [
            BoxShadow(
              color: Colors.red.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red[400]),
            const SizedBox(height: 16),
            Text(
              'Oops! Terjadi Kesalahan',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              style: GoogleFonts.poppins(fontSize: 14, color: Colors.white70),
              textAlign: TextAlign.center,
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: onRetry ?? () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red[400],
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
              child: Text(
                'Coba Lagi',
                style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
      ),
    );

    // Jika web, wrap dengan Column yang include WebAppBar
    if (kIsWeb && onMenuSelected != null) {
      return Column(
        children: [
          WebAppBar(selectedIndex: selectedIndex, onSelected: onMenuSelected),
          Expanded(child: errorContent),
        ],
      );
    }

    // Jika mobile, return error content biasa
    return errorContent;
  }

  static Widget buildNoDataScreen({
    int selectedIndex = 0,
    Function(int)? onMenuSelected,
  }) {
    Widget noDataContent = Center(
      child: Container(
        margin: const EdgeInsets.all(24),
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: cardBackground,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.white.withOpacity(0.05),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.movie_filter_outlined,
              size: 64,
              color: const Color.fromARGB(255, 255, 115, 0),
            ),
            const SizedBox(height: 16),
            Text(
              'Tidak Ada Data',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Sepertinya Ada Kesalahan Teknis\nAtau Jaringan Lu Lemot.',
              style: GoogleFonts.poppins(fontSize: 14, color: Colors.white70),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );

    // Jika web, wrap dengan Column yang include WebAppBar
    if (kIsWeb && onMenuSelected != null) {
      return Column(
        children: [
          WebAppBar(selectedIndex: selectedIndex, onSelected: onMenuSelected),
          Expanded(child: noDataContent),
        ],
      );
    }

    // Jika mobile, return no data content biasa
    return noDataContent;
  }
}
