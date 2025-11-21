import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../widgets/web_app_bar.dart'; // Import WebAppBar

class ModernLoadingScreens {
  static const Color cardBackground = Color(0xFF1A1A1A);

  static Widget buildLoadingScreen({
    int selectedIndex = 0,
    Function(int)? onMenuSelected,
  }) {
    Widget loadingContent = Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(
            'assets/images/love-anime.gif',
            width: 200,
            height: 200,
            fit: BoxFit.contain,
            // Optimasi untuk mencegah crash dan macet
            cacheWidth: 200,
            cacheHeight: 200,
            filterQuality: FilterQuality.medium,
            // Error handling jika GIF gagal load
            errorBuilder: (context, error, stackTrace) {
              return Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  color: Colors.grey[800],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.image_not_supported,
                  color: Colors.white54,
                  size: 64,
                ),
              );
            },
            // Optimasi loading frame
            frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
              if (wasSynchronouslyLoaded) return child;
              return frame != null
                  ? child
                  : Container(
                    width: 200,
                    height: 200,
                    decoration: BoxDecoration(
                      color: Colors.grey[800],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Center(
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Colors.white54,
                        ),
                      ),
                    ),
                  );
            },
          ),
          const SizedBox(height: 24),
          Text(
            'Memuat Halaman...',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.white70,
            ),
          ),
        ],
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
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                // Implementasi retry logic di sini
              },
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
