import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import '../pages/global_chat_page.dart';

class GlobalChatPreview extends StatelessWidget {
  const GlobalChatPreview({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Obrolan Global',
                style: GoogleFonts.outfit(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const GlobalChatPage()),
                  );
                },
                child: const Text(
                  'Gabung →',
                  style: TextStyle(
                    color: Color(0xFFFF5722),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('global_chat')
                .orderBy('timestamp', descending: true)
                .limit(4)
                .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const GlobalChatPage()),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF121212),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.grey[900]!),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFF5722).withOpacity(0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.forum_rounded, color: Color(0xFFFF5722), size: 22),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Text(
                            'Belum ada obrolan. Yuk mulai ngeobrol!',
                            style: TextStyle(color: Colors.grey[400], fontSize: 14),
                          ),
                        ),
                        Icon(Icons.chevron_right_rounded, color: Colors.grey[600]),
                      ],
                    ),
                  ),
                );
              }

              final messages = snapshot.data!.docs;

              return GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const GlobalChatPage()),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFF121212),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.grey[900]!),
                  ),
                  child: Column(
                    children: [
                      ...messages.take(3).map((doc) {
                        final data = doc.data() as Map<String, dynamic>;
                        final name = data['senderName'] ?? 'Anonim';
                        final text = data['text'] ?? '';
                        final photoUrl = data['senderPhotoUrl'] ?? '';

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              CircleAvatar(
                                radius: 14,
                                backgroundImage: photoUrl.isNotEmpty
                                    ? NetworkImage(photoUrl)
                                    : null,
                                backgroundColor: Colors.grey[800],
                                child: photoUrl.isEmpty
                                    ? Text(
                                        name.isNotEmpty ? name[0].toUpperCase() : '?',
                                        style: const TextStyle(color: Colors.white, fontSize: 11),
                                      )
                                    : null,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      name,
                                      style: TextStyle(
                                        color: _nameColor(name),
                                        fontWeight: FontWeight.w600,
                                        fontSize: 12,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      text,
                                      style: TextStyle(
                                        color: Colors.grey[400],
                                        fontSize: 13,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                      if (messages.length > 3)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            'dan ${messages.length - 3} pesan lainnya...',
                            style: TextStyle(color: Colors.grey[600], fontSize: 12),
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  static Color _nameColor(String name) {
    const colors = [
      Color(0xFF4FC3F7),
      Color(0xFF81C784),
      Color(0xFFFFB74D),
      Color(0xFFE57373),
      Color(0xFF9575CD),
      Color(0xFF4DD0E1),
      Color(0xFFF06292),
      Color(0xFFAED581),
    ];
    final hash = name.codeUnits.fold(0, (prev, c) => prev + c);
    return colors[hash % colors.length];
  }
}
