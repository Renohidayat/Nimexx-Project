import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'pages/login_android_page.dart';
import 'pages/login_web_page.dart';
import 'pages/home_page.dart';
import 'service/auth_service.dart';
import 'admin/dashboard/dashboard_overview_page.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = AuthService();

    return StreamBuilder<User?>(
      stream: authService.authState,
      builder: (context, userSnapshot) {
        if (userSnapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (userSnapshot.hasError) {
          return const Scaffold(
            body: Center(
              child: Text(
                '❌ Gagal memuat akun.\nSilakan coba lagi nanti.',
                textAlign: TextAlign.center,
              ),
            ),
          );
        }

        final user = userSnapshot.data;

        // 🔒 Jika belum login, arahkan ke login
        if (user == null) {
          return kIsWeb
              ? const WelcomeToLoginPage()
              : const WelcomeAndLoginAndroidPage();
        }

        // 🔒 Cek status blokir realtime dari Firestore
        return StreamBuilder(
          stream: authService.userBanStatusStream(user.uid),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }

            final userData = snapshot.data?.data();
            final isBanned = userData?['isBanned'] == true;

            if (isBanned) {
              // ✅ Logout otomatis
              WidgetsBinding.instance.addPostFrameCallback((_) async {
                await authService.signOut();

                // Gunakan rootNavigator biar bisa navigasi meskipun context-nya jauh
                Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
                  MaterialPageRoute(
                    builder:
                        (_) =>
                            kIsWeb
                                ? const WelcomeToLoginPage()
                                : const WelcomeAndLoginAndroidPage(),
                  ),
                  (route) => false,
                );
              });

              return const Scaffold(
                body: Center(child: Text("🔒 Akun Anda telah diblokir.")),
              );
            }

            // 🔓 Jika tidak diblokir, cek role
            return FutureBuilder<String?>(
              future: authService.getUserRole(user.uid),
              builder: (context, roleSnapshot) {
                if (!roleSnapshot.hasData) {
                  return const Scaffold(
                    body: Center(child: CircularProgressIndicator()),
                  );
                }

                final role = roleSnapshot.data;
                if (role == 'admin') {
                  return const DashboardOverviewPage();
                } else {
                  return const HomePage();
                }
              },
            );
          },
        );
      },
    );
  }
}
