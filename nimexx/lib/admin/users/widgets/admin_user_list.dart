import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AdminUserList extends StatefulWidget {
  const AdminUserList({super.key});

  @override
  State<AdminUserList> createState() => _AdminUserListState();
}

class _AdminUserListState extends State<AdminUserList> {
  final int _initialItemCount = 3;
  bool _showAll = false;

  Future<void> _banUser(String uid) async {
    await FirebaseFirestore.instance.collection('users').doc(uid).update({
      'isBanned': true,
    });
  }

  Future<void> _unbanUser(String uid) async {
    await FirebaseFirestore.instance.collection('users').doc(uid).update({
      'isBanned': false,
    });
  }

  Future<void> _resetHistory(String uid) async {
    final historyRef = FirebaseFirestore.instance
        .collection('watch_history')
        .doc(uid)
        .collection('history');

    final snap = await historyRef.get();
    for (var doc in snap.docs) {
      await doc.reference.delete();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: Colors.grey.withOpacity(0.1),
                    width: 1,
                  ),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.people_alt, size: 24, color: Colors.blue),
                  const SizedBox(width: 12),
                  Text(
                    "User Management",
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            StreamBuilder<QuerySnapshot>(
              stream:
                  FirebaseFirestore.instance.collection('users').snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      "No users found",
                      style: Theme.of(
                        context,
                      ).textTheme.bodyMedium?.copyWith(color: Colors.grey),
                    ),
                  );
                }

                final users = snapshot.data!.docs;
                final visibleUsers =
                    _showAll ? users : users.take(_initialItemCount).toList();

                return Column(
                  children: [
                    ...List.generate(visibleUsers.length, (index) {
                      final data =
                          visibleUsers[index].data() as Map<String, dynamic>;
                      final uid = visibleUsers[index].id;
                      final isBanned = data['isBanned'] == true;

                      return Container(
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(
                              color: Colors.grey.withOpacity(0.1),
                              width: 1,
                            ),
                          ),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          leading: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color:
                                  isBanned
                                      ? Colors.red.withOpacity(0.2)
                                      : Colors.blue.withOpacity(0.2),
                            ),
                            child: Icon(
                              isBanned ? Icons.block : Icons.person,
                              color: isBanned ? Colors.red : Colors.blue,
                              size: 20,
                            ),
                          ),
                          title: Text(
                            data['email'] ?? 'No email',
                            style: Theme.of(
                              context,
                            ).textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w500,
                              color: isBanned ? Colors.red : null,
                            ),
                          ),
                          subtitle: Text(
                            "Role: ${data['role'] ?? 'user'}",
                            style: Theme.of(
                              context,
                            ).textTheme.bodySmall?.copyWith(
                              color: isBanned ? Colors.red : Colors.grey,
                            ),
                          ),
                          trailing: PopupMenuButton<String>(
                            icon: const Icon(Icons.more_vert, size: 20),
                            itemBuilder:
                                (context) => [
                                  PopupMenuItem(
                                    value: isBanned ? 'unban' : 'ban',
                                    child: Row(
                                      children: [
                                        Icon(
                                          isBanned
                                              ? Icons.lock_open
                                              : Icons.block,
                                          color:
                                              isBanned
                                                  ? Colors.green
                                                  : Colors.red,
                                          size: 20,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          isBanned ? 'Unban User' : 'Ban User',
                                        ),
                                      ],
                                    ),
                                  ),
                                  PopupMenuItem(
                                    value: 'reset',
                                    child: Row(
                                      children: [
                                        const Icon(
                                          Icons.restore,
                                          color: Colors.blue,
                                          size: 20,
                                        ),
                                        const SizedBox(width: 8),
                                        Text('Reset History'),
                                      ],
                                    ),
                                  ),
                                ],
                            onSelected: (value) async {
                              if (value == 'ban') {
                                await _banUser(uid);
                              } else if (value == 'unban') {
                                await _unbanUser(uid);
                              } else if (value == 'reset') {
                                await _resetHistory(uid);
                              }
                            },
                          ),
                        ),
                      );
                    }),
                    if (users.length > _initialItemCount)
                      TextButton(
                        onPressed: () {
                          setState(() {
                            _showAll = !_showAll;
                          });
                        },
                        child: Text(
                          _showAll ? 'Show Less' : 'Show More',
                          style: Theme.of(
                            context,
                          ).textTheme.bodyMedium?.copyWith(color: Colors.blue),
                        ),
                      ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
