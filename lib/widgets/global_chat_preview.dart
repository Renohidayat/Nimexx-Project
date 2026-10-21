import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import '../pages/global_chat_page.dart';

class GlobalChatPreview extends StatelessWidget {
  const GlobalChatPreview({super.key});

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    double fontSize = width < 600 ? 18 : 28;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Garis vertikal merah
              Container(
                width: 5,
                height: fontSize + 15,
                color: const Color.fromARGB(255, 255, 0, 0),
                margin: const EdgeInsets.only(right: 12),
              ),
              Text(
                'OBROLAN GLOBAL',
                style: GoogleFonts.oswald(
                  fontSize: fontSize,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(width: 8),
              // Live Text
              Text(
                '• LIVE',
                style: GoogleFonts.outfit(
                  color: Colors.redAccent,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1,
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const GlobalChatPage()));
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.red, // Merah seperti tombol lain
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    'Gabung',
                    style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('global_chat')
                .orderBy('timestamp', descending: true)
                .limit(2) // Cukup 2 pesan agar sangat tipis
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return _buildEmptyBox('Memuat...');
              }

              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return _buildEmptyBox('Belum ada obrolan.');
              }

              final messages = snapshot.data!.docs;

              return GestureDetector(
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const GlobalChatPage()));
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF161622),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.white10),
                  ),
                  child: Column(
                    children: messages.map((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      final name = data['senderName'] ?? 'Anonim';
                      final text = data['text'] ?? '';
                      final photoUrl = data['senderPhotoUrl'] ?? '';
                      final hasTag = data['tagData'] != null;

                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            CircleAvatar(
                              radius: 12,
                              backgroundColor: const Color(0xFF232332),
                              backgroundImage: photoUrl.isNotEmpty ? NetworkImage(photoUrl) : null,
                              child: photoUrl.isEmpty
                                  ? Text(
                                      name.isNotEmpty ? name[0].toUpperCase() : '?',
                                      style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                                    )
                                  : null,
                            ),
                            const SizedBox(width: 10),
                            Text(
                              name,
                              style: GoogleFonts.outfit(
                                color: _nameColor(name),
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: hasTag && text.isEmpty
                                  ? Row(
                                      children: [
                                        const Icon(Icons.movie_creation_rounded, color: Color(0xFF6C5CE7), size: 12),
                                        const SizedBox(width: 4),
                                        Text('Melampirkan Anime', style: TextStyle(color: Colors.grey[500], fontSize: 12, fontStyle: FontStyle.italic)),
                                      ],
                                    )
                                  : Text(
                                      text,
                                      style: const TextStyle(color: Colors.white70, fontSize: 12),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyBox(String msg) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF161622),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        children: [
          const Icon(Icons.forum_rounded, color: Colors.white24, size: 20),
          const SizedBox(width: 12),
          Text(msg, style: TextStyle(color: Colors.grey[500], fontSize: 12)),
        ],
      ),
    );
  }

  static Color _nameColor(String name) {
    const colors = [
      Color(0xFF4FC3F7), Color(0xFF81C784), Color(0xFFFFB74D),
      Color(0xFFE57373), Color(0xFF9575CD), Color(0xFF4DD0E1),
      Color(0xFFF06292), Color(0xFFAED581), Color(0xFFFFD54F),
    ];
    final hash = name.codeUnits.fold(0, (prev, c) => prev + c);
    return colors[hash % colors.length];
  }
}
