import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'private_chat_page.dart';
import 'user_search_page.dart';

class FriendListPage extends StatefulWidget {
  const FriendListPage({Key? key}) : super(key: key);

  @override
  State<FriendListPage> createState() => _FriendListPageState();
}

class _FriendListPageState extends State<FriendListPage> {
  final _currentUser = FirebaseAuth.instance.currentUser;

  @override
  Widget build(BuildContext context) {
    if (_currentUser == null) {
      return const Scaffold(body: Center(child: Text("Harus login")));
    }

    return Scaffold(
      backgroundColor: const Color(0xFF101018),
      appBar: AppBar(
        backgroundColor: const Color(0xFF161622),
        elevation: 0,
        title: Text(
          'Daftar Teman',
          style: GoogleFonts.outfit(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add_rounded, color: Colors.white),
            tooltip: 'Tambah Teman',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const UserSearchPage()),
              );
            },
          ),
          const SizedBox(width: 8),
        ],
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
          StreamBuilder<DocumentSnapshot>(
            stream: FirebaseFirestore.instance.collection('users').doc(_currentUser!.uid).snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator(color: Color(0xFFE25822)));
              }

              if (!snapshot.hasData || !snapshot.data!.exists) {
                return const Center(child: Text('Data tidak ditemukan', style: TextStyle(color: Colors.white)));
              }

              final userData = snapshot.data!.data() as Map<String, dynamic>;
              final friends = List<String>.from(userData['friends'] ?? []);

              if (friends.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.people_outline_rounded, size: 64, color: Colors.grey[700]),
                      const SizedBox(height: 16),
                      Text(
                        'Belum ada teman',
                        style: GoogleFonts.outfit(color: Colors.grey[500], fontSize: 16),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Cari teman di Global Chat atau Menu Pencarian!',
                        style: TextStyle(color: Colors.grey[600], fontSize: 13),
                      ),
                    ],
                  ),
                );
              }

              return ListView.separated(
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: friends.length,
                separatorBuilder: (context, index) => const Divider(color: Colors.white10, height: 1, indent: 80),
                itemBuilder: (context, index) {
                  final peerId = friends[index];

                  return FutureBuilder<DocumentSnapshot>(
                    future: FirebaseFirestore.instance.collection('users').doc(peerId).get(),
                    builder: (context, userSnap) {
                      if (userSnap.connectionState == ConnectionState.waiting) {
                        return const ListTile(
                          leading: CircleAvatar(backgroundColor: Color(0xFF232332), radius: 26),
                          title: Text('Loading...', style: TextStyle(color: Colors.grey)),
                        );
                      }

                      String peerName = 'User';
                      String peerAvatar = '';
                      
                      if (userSnap.hasData && userSnap.data!.exists) {
                        final peerData = userSnap.data!.data() as Map<String, dynamic>;
                        peerName = peerData['displayName'] ?? 'User';
                        peerAvatar = peerData['photoUrl'] ?? '';
                      }

                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        leading: CircleAvatar(
                          radius: 26,
                          backgroundColor: const Color(0xFF232332),
                          backgroundImage: peerAvatar.isNotEmpty ? NetworkImage(peerAvatar) : null,
                          child: peerAvatar.isEmpty
                              ? Text(peerName.isNotEmpty ? peerName[0].toUpperCase() : '?', style: const TextStyle(color: Colors.white, fontSize: 20))
                              : null,
                        ),
                        title: Text(
                          peerName,
                          style: GoogleFonts.outfit(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Text(
                          'Teman Anda',
                          style: TextStyle(color: Colors.grey[500], fontSize: 13),
                        ),
                        trailing: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE25822).withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.chat_bubble_rounded, color: Color(0xFFE25822), size: 20),
                        ),
                        onTap: () {
                          // Gunakan pushReplacement agar ketika back dari chat, langsung ke ChatHistory
                          Navigator.pushReplacement(
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
    );
  }
}
