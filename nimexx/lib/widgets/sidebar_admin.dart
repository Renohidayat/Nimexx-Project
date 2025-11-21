import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AdminSidebar extends StatelessWidget {
  final String currentRoute;

  const AdminSidebar({super.key, required this.currentRoute});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF1F1F1F), Color(0xFF121212)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: ListView(
          padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 16),
          children: [
            // Header Branding dengan logo PNG
            ListTile(
              leading: Image.asset(
                'assets/images/logo.png', // GANTI dengan path gambar kamu
                width: 32,
                height: 32,
                fit: BoxFit.contain,
              ),
              title: const Text(
                'NimeXx',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.orangeAccent,
                ),
              ),
            ),
            const SizedBox(height: 32),

            // Navigasi
            _navItem(
              context,
              currentRoute,
              icon: Icons.dashboard,
              label: 'Dashboard',
              route: '/admin/dashboard',
            ),
            _navItem(
              context,
              currentRoute,
              icon: Icons.analytics,
              label: 'Statistik Detail',
              route: '/admin/statistics',
            ),
            _navItem(
              context,
              currentRoute,
              icon: Icons.comment,
              label: 'Komentar',
              route: '/admin/comments',
            ),
            _navItem(
              context,
              currentRoute,
              icon: Icons.people,
              label: 'User',
              route: '/admin/users',
            ),

            const Divider(color: Colors.white24, height: 32),

            // Logout
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.redAccent),
              title: const Text(
                'Logout',
                style: TextStyle(
                  color: Colors.redAccent,
                  fontWeight: FontWeight.bold,
                ),
              ),
              onTap: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder:
                      (context) => AlertDialog(
                        title: const Text('Konfirmasi Logout'),
                        content: const Text('Apakah Anda yakin ingin keluar?'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(false),
                            child: const Text('Batal'),
                          ),
                          ElevatedButton(
                            onPressed: () => Navigator.of(context).pop(true),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.redAccent,
                            ),
                            child: const Text('Logout'),
                          ),
                        ],
                      ),
                );

                if (confirm == true) {
                  await FirebaseAuth.instance.signOut();
                  if (context.mounted) {
                    Navigator.pushReplacementNamed(context, '/');
                  }
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  /// Navigasi Sidebar
  Widget _navItem(
    BuildContext context,
    String currentRoute, {
    required IconData icon,
    required String label,
    required String route,
  }) {
    final bool isSelected = currentRoute == route;

    return ListTile(
      selected: isSelected,
      selectedTileColor: Colors.orange.withOpacity(0.15),
      leading: Icon(
        icon,
        color: isSelected ? Colors.orangeAccent : Colors.white,
      ),
      title: Text(
        label,
        style: TextStyle(
          color: isSelected ? Colors.orangeAccent : Colors.white,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      onTap: () {
        Navigator.pop(context); // Tutup drawer dulu

        if (!isSelected) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (context.mounted) {
              Navigator.pushReplacementNamed(context, route);
            }
          });
        }
      },
    );
  }
}
