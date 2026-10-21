import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';

/// Widget Avatar Pengguna Bergaya Akun Google
/// Jika ada foto profil (Google / custom URL), tampilkan gambar beresolusi tinggi.
/// Jika belum ada atau gagal dimuat, tampilkan avatar huruf inisial bulat khas Google
/// dengan warna Material yang elegan dan tidak pernah menggunakan ikon apk Nimexx.
class UserAvatarWidget extends StatelessWidget {
  final String? photoUrl;
  final String displayName;
  final double radius;
  final BoxBorder? border;
  final List<BoxShadow>? boxShadow;
  final VoidCallback? onTap;

  const UserAvatarWidget({
    super.key,
    required this.photoUrl,
    required this.displayName,
    this.radius = 20,
    this.border,
    this.boxShadow,
    this.onTap,
  });

  // Palet Warna Google Material Design untuk Inisial Avatar
  static const List<Color> _googleColors = [
    Color(0xFF1A73E8), // Google Blue
    Color(0xFFD93025), // Google Red
    Color(0xFF1E8E3E), // Google Green
    Color(0xFFF9AB00), // Google Yellow / Amber
    Color(0xFF8E24AA), // Purple
    Color(0xFF00897B), // Teal
    Color(0xFFE53935), // Crimson
    Color(0xFFFB8C00), // Deep Orange
    Color(0xFF3949AB), // Indigo
    Color(0xFF00ACC1), // Cyan
    Color(0xFFD81B60), // Pink
  ];

  /// Menghasilkan warna konsisten berdasarkan teks nama/email
  static Color getAvatarColor(String text) {
    if (text.trim().isEmpty) return _googleColors[0];
    final hash = text.codeUnits.fold(0, (prev, elem) => prev + elem);
    return _googleColors[hash.abs() % _googleColors.length];
  }

  /// Mengambil inisial huruf pertama (kapital)
  static String getInitial(String name) {
    final clean = name.trim();
    if (clean.isEmpty) return 'U';
    return clean[0].toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final size = radius * 2;
    final initial = getInitial(displayName);
    final avatarBgColor = getAvatarColor(displayName);

    // Widget Inisial Huruf Ala Bawaan Akun Google
    final Widget initialAvatar = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: avatarBgColor,
      ),
      alignment: Alignment.center,
      child: Text(
        initial,
        style: GoogleFonts.outfit(
          fontSize: radius * 0.95,
          fontWeight: FontWeight.w700,
          color: Colors.white,
          letterSpacing: -0.5,
        ),
      ),
    );

    final cleanPhoto = (photoUrl ?? '').trim();
    final bool hasValidUrl = cleanPhoto.isNotEmpty &&
        (cleanPhoto.startsWith('http://') || cleanPhoto.startsWith('https://')) &&
        !cleanPhoto.contains('default_profile.png');

    Widget avatarContent;
    if (hasValidUrl) {
      avatarContent = CachedNetworkImage(
        imageUrl: cleanPhoto,
        width: size,
        height: size,
        fit: BoxFit.cover,
        placeholder: (context, url) => initialAvatar,
        errorWidget: (context, url, error) => initialAvatar,
      );
    } else {
      avatarContent = initialAvatar;
    }

    Widget result = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: border,
        boxShadow: boxShadow,
      ),
      child: ClipOval(child: avatarContent),
    );

    if (onTap != null) {
      result = GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: result,
      );
    }

    return result;
  }
}
