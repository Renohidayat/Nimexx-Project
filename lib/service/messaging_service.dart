import 'dart:typed_data';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../pages/anime_detail_page.dart';

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Tangani pesan saat aplikasi di background
  debugPrint("Handling a background message: ${message.messageId}");
}

class MessagingService {
  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
  static final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _localNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static Future<void> init() async {
    // Meminta izin untuk menampilkan notifikasi (diperlukan untuk iOS dan Android 13+)
    NotificationSettings settings = await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      debugPrint('User granted permission for notifications');
    } else {
      debugPrint('User declined or has not accepted permission');
    }

    // Subscribe ke Topik Global
    try {
      await _firebaseMessaging.subscribeToTopic('anime_updates');
      debugPrint('✅ Berhasil subscribe ke topik: anime_updates');
    } catch (e) {
      debugPrint('❌ Gagal subscribe ke topik: $e');
    }

    // Setup Local Notifications untuk menampilkan pop-up saat aplikasi terbuka (Foreground)
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);
    await _localNotificationsPlugin.initialize(settings: initializationSettings);

    // Menerima notifikasi saat aplikasi di Foreground
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('Got a message whilst in the foreground!');
      debugPrint('Message data: ${message.data}');

      if (message.notification != null) {
        debugPrint('Message also contained a notification: ${message.notification}');
        _showNotification(message);
      }
    });

    // Menerima notifikasi di Background
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // Menerima KLIK notifikasi saat aplikasi di background/ditutup
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      _handleNotificationClick(message);
    });

    // Menerima KLIK notifikasi saat aplikasi benar-benar mati (Terminated)
    FirebaseMessaging.instance.getInitialMessage().then((RemoteMessage? message) {
      if (message != null) {
        _handleNotificationClick(message);
      }
    });
  }

  static void _handleNotificationClick(RemoteMessage message) {
    if (message.data.containsKey('endpoint')) {
      final endpoint = message.data['endpoint'];
      // Arahkan pengguna ke halaman detail anime
      navigatorKey.currentState?.push(
        MaterialPageRoute(
          builder: (_) => AnimeDetailPage(endpoint: endpoint),
        ),
      );
    }
  }

  static Future<void> _showNotification(RemoteMessage message) async {
    final Int64List vibrationPattern = Int64List.fromList([0, 1000, 500, 1000, 500, 1500]);
    
    // Gunakan ID channel baru agar Android me-reset aturan suara/getarnya
    final AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'nimexx_channel_premium_v1', 
      'Anime Updates', 
      channelDescription: 'Notifikasi update episode anime terbaru',
      importance: Importance.max,
      priority: Priority.high,
      sound: const RawResourceAndroidNotificationSound('notification'),
      playSound: true,
      enableVibration: true,
      vibrationPattern: vibrationPattern,
      color: Colors.amber, // Warna logo NimeXx
    );
    final NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);
    await _localNotificationsPlugin.show(
      id: message.hashCode,
      title: message.notification?.title,
      body: message.notification?.body,
      notificationDetails: platformChannelSpecifics,
    );
  }
}
