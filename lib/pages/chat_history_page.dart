import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../service/chat_service.dart';
import 'private_chat_page.dart';
import 'friend_list_page.dart';

class ChatHistoryPage extends StatefulWidget {
  const ChatHistoryPage({Key? key}) : super(key: key);

  @override
  State<ChatHistoryPage> createState() => _ChatHistoryPageState();
}

class _ChatHistoryPageState extends State<ChatHistoryPage> {
  final _chatService = ChatService();
  final _currentUser = FirebaseAuth.instance.currentUser;

  @override
  Widget build(BuildContext context) {
    if (_currentUser == null) return const Scaffold(body: Center(child: Text("Harus login")));

    return Scaffold(
      backgroundColor: const Color(0xFF101018),
      appBar: AppBar(
        backgroundColor: const Color(0xFF161622),
        elevation: 0,
        title: Text(
          'Obrolan',
          style: GoogleFonts.outfit(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
        ),
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: Opacity(
              opacity: 0.1,
              child: Image.asset(
                'assets/images/wibu.png',
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const SizedBox(),
              ),
            ),
          ),
          StreamBuilder<QuerySnapshot>(
            stream: _chatService.getChatHistoryStream(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator(color: Color(0xFFE25822)));
              }

              if (snapshot.hasError) {
                return Center(child: Text('Terjadi kesalahan', style: TextStyle(color: Colors.grey[500])));
              }

              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.chat_bubble_outline_rounded, size: 64, color: Colors.grey[700]),
                      const SizedBox(height: 16),
                      Text(
                        'Belum ada obrolan',
                        style: GoogleFonts.outfit(color: Colors.grey[500], fontSize: 16),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Mulai obrolan dengan temanmu!',
                        style: TextStyle(color: Colors.grey[600], fontSize: 13),
                      ),
                    ],
                  ),
                );
              }

              final docs = snapshot.data!.docs;
              return ListView.separated(
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: docs.length,
                separatorBuilder: (context, index) => const Divider(color: Colors.white10, height: 1, indent: 80),
                itemBuilder: (context, index) {
                  final data = docs[index].data() as Map<String, dynamic>;
                  final participants = List<String>.from(data['participants'] ?? []);
                  // Cari peerId (selain diri sendiri)
                  final peerId = participants.firstWhere(
                    (id) => id != _currentUser!.uid,
                    orElse: () => _currentUser!.uid, // Fallback jika chat dgn diri sendiri
                  );

                  final lastMessage = data['lastMessage'] ?? 'Pesan gambar/tag';
                  final lastTimestamp = data['lastTimestamp'] as Timestamp?;
                  final timeString = lastTimestamp != null ? _formatTime(lastTimestamp.toDate()) : '';
                  final isMeLast = data['lastSenderId'] == _currentUser!.uid;

                  return FutureBuilder<DocumentSnapshot>(
                    future: FirebaseFirestore.instance.collection('users').doc(peerId).get(),
                    builder: (context, userSnap) {
                      String peerName = 'User';
                      String peerAvatar = '';
                      
                      if (userSnap.hasData && userSnap.data!.exists) {
                        final userData = userSnap.data!.data() as Map<String, dynamic>;
                        peerName = userData['displayName'] ?? 'User';
                        peerAvatar = userData['photoUrl'] ?? '';
                      }

                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        leading: Stack(
                          children: [
                            CircleAvatar(
                              radius: 26,
                              backgroundColor: const Color(0xFF232332),
                              backgroundImage: peerAvatar.isNotEmpty ? NetworkImage(peerAvatar) : null,
                              child: peerAvatar.isEmpty
                                  ? Text(peerName.isNotEmpty ? peerName[0].toUpperCase() : '?', style: const TextStyle(color: Colors.white, fontSize: 20))
                                  : null,
                            ),
                            // Indikator online bisa ditambahkan nanti di sini
                          ],
                        ),
                        title: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                peerName,
                                style: GoogleFonts.outfit(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Text(
                              timeString,
                              style: TextStyle(color: Colors.grey[500], fontSize: 12),
                            ),
                          ],
                        ),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Row(
                            children: [
                              if (isMeLast)
                                const Padding(
                                  padding: EdgeInsets.only(right: 4),
                                  child: Icon(Icons.done_all_rounded, size: 14, color: Colors.blueAccent),
                                ),
                              Expanded(
                                child: Text(
                                  lastMessage,
                                  style: TextStyle(color: Colors.grey[400], fontSize: 13),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => PrivateChatPage(
                                peerId: peerId,
                                peerName: peerName,
                                peerAvatar: peerAvatar,
                              ),
                            ),
                          );
                        },
                      );
                    },
                  );
                },
              );
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFFE25822),
        child: const Icon(Icons.chat_rounded, color: Colors.white),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const FriendListPage()),
          );
        },
      ),
    );
  }

  String _formatTime(DateTime date) {
    final now = DateTime.now();
    if (date.year == now.year && date.month == now.month && date.day == now.day) {
      return DateFormat('HH:mm').format(date);
    } else if (date.year == now.year && date.month == now.month && date.day == now.day - 1) {
      return 'Kemarin';
    }
    return DateFormat('dd/MM/yy').format(date);
  }
}
