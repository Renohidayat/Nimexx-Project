import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'firebase_options.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:intl/date_symbol_data_local.dart';
import 'service/remote_config_service.dart';
import 'auth_wrapper.dart';
import 'service/messaging_service.dart'; // Import fitur notifikasi
import 'pages/login_web_page.dart';
import 'pages/home_page.dart';
import 'pages/genre_list_page.dart';
import 'pages/release_schedule_page.dart';
import 'pages/ongoing_anime_page.dart';
import 'pages/search_page.dart';
import 'pages/anime_list_page.dart';
import 'pages/login_android_page.dart';
import 'pages/profile_page.dart';
import 'pages/history_page.dart';
import 'pages/favorite_page.dart';
import 'pages/notifications_page.dart';
import 'pages/episode_page.dart';
import 'admin/admin_home.dart';
import 'admin/dashboard/dashboard_overview_page.dart';
import 'admin/comments/comments_management_page.dart';
import 'admin/statistics/statistics_page.dart';
import 'admin/users/manajemen_users_page.dart';
import 'widgets/maintenance_dialog.dart'; // Import file maintenance yang baru

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ✅ Inisialisasi Hive untuk Caching
  await Hive.initFlutter();
  await Hive.openBox('api_cache');

  // ✅ Inisialisasi Firebase
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await RemoteConfigService.init();

  // ✅ Inisialisasi Firebase Cloud Messaging & Berlangganan Topik
  await MessagingService.init();

  // ✅ Persist login
  await _setFirebasePersistence();

  // ✅ Locale Indonesia untuk timeago & tanggal
  timeago.setLocaleMessages('id', timeago.IdMessages());
  await initializeDateFormatting('id_ID', null);

  // ✅ Pengecekan maintenance
  final isMaintenance = RemoteConfigService.isMaintenance;
  final updateLink = RemoteConfigService.updateLink;

  // ✅ Data maintenance tambahan dari Remote Config
  final maintenanceStartDate = RemoteConfigService.maintenanceStartDate;
  final maintenanceEndDate = RemoteConfigService.maintenanceEndDate;
  final maintenanceReason = RemoteConfigService.maintenanceReason;
  final newFeatures = RemoteConfigService.newFeatures;
  final maintenanceTitle = RemoteConfigService.maintenanceTitle;
  final maintenanceDuration = RemoteConfigService.maintenanceDurationMinutes;

  if (isMaintenance) {
    runApp(
      MaintenanceApp(
        downloadUrl: updateLink,
        startDate: maintenanceStartDate,
        endDate: maintenanceEndDate,
        reason: maintenanceReason,
        newFeatures: newFeatures,
        title: maintenanceTitle,
        durationMinutes: maintenanceDuration,
      ),
    );
  } else {
    runApp(const MyApp());
  }
}

Future<void> _setFirebasePersistence() async {
  try {
    await FirebaseAuth.instance.setPersistence(Persistence.LOCAL);
  } catch (e) {
    debugPrint("❌ Set persistence error: $e");
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Nimexx',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.dark,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: Colors.black,
      ),
      navigatorKey: MessagingService.navigatorKey, // Kunci rahasia untuk routing dari background
      initialRoute: '/',
      onGenerateRoute: (settings) {
        final isLoggedIn = FirebaseAuth.instance.currentUser != null;

        // ⛔️ Default route fallback
        Widget errorPage = const Scaffold(
          body: Center(child: Text("❌ Halaman tidak ditemukan")),
        );

        switch (settings.name) {
          case '/':
            return MaterialPageRoute(builder: (_) => const AuthWrapper());
          case '/login':
            return MaterialPageRoute(
              builder: (_) => const WelcomeAndLoginAndroidPage(),
            );
          case '/login_web':
            return MaterialPageRoute(
              builder: (_) => const WelcomeToLoginPage(),
            );
          case '/home':
            return _guardedRoute(const HomePage(), isLoggedIn);
          case '/admin':
            return _guardedRoute(const AdminHome(), isLoggedIn);
          case '/admin/dashboard':
            return _guardedRoute(const DashboardOverviewPage(), isLoggedIn);
          case '/admin/comments':
            return _guardedRoute(const CommentsManagementPage(), isLoggedIn);
          case '/admin/statistics':
            return _guardedRoute(const StatisticsPage(), isLoggedIn);
          case '/admin/users':
            return _guardedRoute(const ManajemenUsersPage(), isLoggedIn);
          case '/list':
            return _guardedRoute(const AnimeListPage(), isLoggedIn);
          case '/schedule':
            return _guardedRoute(const ReleaseSchedulePage(), isLoggedIn);
          case '/ongoing':
            return _guardedRoute(const OngoingAnimePage(), isLoggedIn);
          case '/genre':
            return _guardedRoute(const GenreListPage(), isLoggedIn);
          case '/search':
            return _guardedRoute(const SearchPage(), isLoggedIn);
          case '/profile':
            return _guardedRoute(const ProfilePage(), isLoggedIn);
          case '/history':
            return _guardedRoute(const HistoryPage(), isLoggedIn);
          case '/favorites':
            return _guardedRoute(const FavoritePage(), isLoggedIn);
          case '/notifications':
            return _guardedRoute(const NotificationPage(), isLoggedIn);
          case '/episode':
            final args = settings.arguments;
            if (args is! Map<String, dynamic> ||
                !args.containsKey('endpoint')) {
              return MaterialPageRoute(builder: (_) => errorPage);
            }
            return MaterialPageRoute(
              builder:
                  (_) => EpisodePage(
                    endpoint: args['endpoint'],
                    episodeTitle: args['episodeTitle'] ?? '',
                    animeTitle: args['animeTitle'] ?? '',
                    thumbUrl: args['thumbUrl'] ?? '',
                    highlightCommentId: args['highlightCommentId'],
                  ),
            );
          default:
            return MaterialPageRoute(builder: (_) => errorPage);
        }
      },
    );
  }

  // 🔐 Fungsi pembungkus route dengan pengecekan login
  MaterialPageRoute _guardedRoute(Widget page, bool isLoggedIn) {
    return MaterialPageRoute(
      builder: (_) => isLoggedIn ? page : const WelcomeToLoginPage(),
    );
  }
}
