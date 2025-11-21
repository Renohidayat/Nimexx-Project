// widgets/episode/modern_snackbar_helper.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ModernSnackBarHelper {
  // Modern color scheme
  static const Color primaryOrange = Color(0xFFFF6B35);
  static const Color cardBackground = Color(0xFF1A1A1A);

  static void showSnackBar(
    BuildContext context,
    String message, {
    bool isError = false,
  }) {
    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Container(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color:
                      isError
                          ? Colors.red.withOpacity(0.2)
                          : primaryOrange.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  isError ? Icons.error_outline : Icons.info_outline,
                  color: isError ? Colors.red[300] : primaryOrange,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  message,
                  style: GoogleFonts.oswald(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
        backgroundColor: cardBackground,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color:
                isError
                    ? Colors.red.withOpacity(0.3)
                    : primaryOrange.withOpacity(0.3),
          ),
        ),
        margin: const EdgeInsets.all(16),
        duration: Duration(seconds: isError ? 4 : 3),
      ),
    );
  }
}
