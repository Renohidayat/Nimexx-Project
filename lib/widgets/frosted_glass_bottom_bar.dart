import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

/// Item data model untuk Frosted Glass Bottom Navigation Bar
class FrostedGlassBarItem {
  final IconData icon;
  final IconData? activeIcon;
  final String label;
  final Color color;

  const FrostedGlassBarItem({
    required this.icon,
    this.activeIcon,
    required this.label,
    required this.color,
  });
}

/// Widget Navigation Bar bertema Liquid Glass / Frosted Glass (iOS iPhone Style)
/// Desain modern, melayang (floating pill), transparan optik nyata,
/// simetris tanpa kaku, dan mendukung animasi sembunyi/muncul saat scroll.
class FrostedGlassBottomBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final List<FrostedGlassBarItem> items;
  final bool isVisible;

  const FrostedGlassBottomBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.items,
    this.isVisible = true,
  });

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).padding.bottom;

    // Animasi meluncur ke bawah saat sembunyi dan kembali muncul saat berhenti scroll
    return AnimatedSlide(
      offset: isVisible ? Offset.zero : const Offset(0, 1.8),
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeInOutCubicEmphasized,
      child: AnimatedOpacity(
        opacity: isVisible ? 1.0 : 0.0,
        duration: const Duration(milliseconds: 240),
        child: Padding(
          // Margin melayang di atas gesture bar iPhone / Android
          padding: EdgeInsets.only(
            left: 18,
            right: 18,
            bottom: bottomInset > 0 ? bottomInset + 4 : 14,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(34),
            child: BackdropFilter(
              // Blur kaca es kuat seperti efek blur native iOS
              filter: ImageFilter.blur(sigmaX: 28, sigmaY: 28),
              child: Container(
                height: 68,
                decoration: BoxDecoration(
                  // Transparansi kaca es cair (Liquid Frosted Glass)
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      const Color(0xFF282838).withValues(alpha: 0.38),
                      const Color(0xFF12121A).withValues(alpha: 0.48),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(34),
                  // Bevel Glass Rim (Garis tepi kaca memantulkan cahaya)
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.22),
                    width: 1.1,
                  ),
                  boxShadow: [
                    // Deep Ambient Shadow
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.42),
                      blurRadius: 30,
                      offset: const Offset(0, 10),
                    ),
                    // Aura warna halus dari tab aktif
                    BoxShadow(
                      color: items[currentIndex].color.withValues(alpha: 0.16),
                      blurRadius: 22,
                      spreadRadius: -4,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Stack(
                  children: [
                    // Specular Sheen (Pantulan kilauan cahaya di bibir atas kaca)
                    Positioned(
                      top: 0,
                      left: 36,
                      right: 36,
                      child: Container(
                        height: 1.2,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.white.withValues(alpha: 0.0),
                              Colors.white.withValues(alpha: 0.50),
                              Colors.white.withValues(alpha: 0.0),
                            ],
                          ),
                        ),
                      ),
                    ),

                    // Barisan Tab Simetris (Layout proporsional rapi tanpa pergeseran kaku)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                        child: Row(
                          children: List.generate(items.length, (index) {
                            final item = items[index];
                            final isSelected = index == currentIndex;

                            return Expanded(
                              child: _GlassTabItem(
                                item: item,
                                isSelected: isSelected,
                                onTap: () {
                                  HapticFeedback.selectionClick();
                                  onTap(index);
                                },
                              ),
                            );
                          }),
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
    );
  }
}

/// Satu Tab Item dengan tata letak simetris dan kapsul liquid saat aktif
class _GlassTabItem extends StatelessWidget {
  final FrostedGlassBarItem item;
  final bool isSelected;
  final VoidCallback onTap;

  const _GlassTabItem({
    required this.item,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Center(
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 260),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            // Kapsul Liquid Glass saat Aktif
            gradient: isSelected
                ? LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      item.color.withValues(alpha: 0.28),
                      item.color.withValues(alpha: 0.12),
                    ],
                  )
                : null,
            border: isSelected
                ? Border.all(
                    color: item.color.withValues(alpha: 0.52),
                    width: 1.0,
                  )
                : Border.all(
                    color: Colors.transparent,
                    width: 1.0,
                  ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: item.color.withValues(alpha: 0.32),
                      blurRadius: 10,
                      spreadRadius: -2,
                    ),
                  ]
                : null,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Icon dengan efek scale halus
              AnimatedScale(
                scale: isSelected ? 1.12 : 1.0,
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOutBack,
                child: Icon(
                  isSelected ? (item.activeIcon ?? item.icon) : item.icon,
                  size: 21,
                  color: isSelected
                      ? item.color
                      : Colors.white.withValues(alpha: 0.50),
                ),
              ),
              const SizedBox(height: 3),
              // Label Teks Simetris Gaya Apple iOS
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOutCubic,
                style: GoogleFonts.outfit(
                  fontSize: 10.5,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected
                      ? Colors.white
                      : Colors.white.withValues(alpha: 0.50),
                  letterSpacing: 0.2,
                ),
                child: Text(
                  item.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
