import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/foundation.dart'; // untuk kIsWeb
import 'dart:convert';

class RemoteConfigService {
  static String _baseUrl = 'http://localhost:8000/api/v1'; // Default fallback

  static String get baseUrl => _baseUrl;

  // ✅ Getter untuk maintenance
  static bool get isMaintenance {
    if (kIsWeb) return false; // Web tidak support maintenance
    final value = FirebaseRemoteConfig.instance.getBool('maintenance');
    debugPrint('🚧 isMaintenance: $value');
    return value;
  }

  // ✅ Getter untuk update link dengan validasi
  static String get updateLink {
    if (kIsWeb) return ''; // Web tidak butuh update link
    final value = FirebaseRemoteConfig.instance.getString('update_link');
    debugPrint('🔗 updateLink: $value');

    // Validasi URL
    if (value.isEmpty) {
      debugPrint('⚠️ Update link kosong!');
      return 'https://play.google.com/store/apps/details?id=com.rennv.nimexx'; // fallback
    }

    try {
      final uri = Uri.parse(value);
      if (!uri.hasScheme || (uri.scheme != 'http' && uri.scheme != 'https')) {
        debugPrint('⚠️ URL tidak valid: $value');
        return 'https://play.google.com/store/apps/details?id=com.rennv.nimexx'; // fallback
      }
    } catch (e) {
      debugPrint('❌ Error parsing URL: $e');
      return 'https://play.google.com/store/apps/details?id=com.rennv.nimexx'; // fallback
    }

    return value;
  }

  // 🆕 Getter untuk tanggal mulai maintenance
  static String? get maintenanceStartDate {
    if (kIsWeb) return null;
    final value = FirebaseRemoteConfig.instance.getString(
      'maintenance_start_date',
    );
    debugPrint('📅 maintenanceStartDate: $value');
    return value.isEmpty ? null : value;
  }

  // 🆕 Getter untuk tanggal selesai maintenance
  static String? get maintenanceEndDate {
    if (kIsWeb) return null;
    final value = FirebaseRemoteConfig.instance.getString(
      'maintenance_end_date',
    );
    debugPrint('📅 maintenanceEndDate: $value');
    return value.isEmpty ? null : value;
  }

  // 🆕 Getter untuk alasan maintenance
  static String? get maintenanceReason {
    if (kIsWeb) return null;
    final value = FirebaseRemoteConfig.instance.getString('maintenance_reason');
    debugPrint('📝 maintenanceReason: $value');
    return value.isEmpty ? null : value;
  }

  // 🆕 Getter untuk list fitur baru
  static List<String>? get newFeatures {
    if (kIsWeb) return null;

    try {
      final value = FirebaseRemoteConfig.instance.getString('new_features');
      debugPrint('✨ newFeatures JSON: $value');

      if (value.isEmpty) return null;

      final List<dynamic> featuresList = json.decode(value);
      final result = featuresList.cast<String>();
      debugPrint('✨ parsed newFeatures: $result');
      return result;
    } catch (e) {
      debugPrint('❌ Error parsing new_features: $e');
      return null;
    }
  }

  // 🆕 Getter untuk judul maintenance (opsional)
  static String? get maintenanceTitle {
    if (kIsWeb) return null;
    final value = FirebaseRemoteConfig.instance.getString('maintenance_title');
    debugPrint('🏷️ maintenanceTitle: $value');
    return value.isEmpty ? null : value;
  }

  // 🆕 Getter untuk estimasi durasi maintenance (dalam menit)
  static int? get maintenanceDurationMinutes {
    if (kIsWeb) return null;
    final value = FirebaseRemoteConfig.instance.getInt(
      'maintenance_duration_minutes',
    );
    debugPrint('⏱️ maintenanceDurationMinutes: $value');
    return value == 0 ? null : value;
  }

  static Future<void> init() async {
    // 👉 Cek jika sedang berjalan di Web
    if (kIsWeb) {
      debugPrint(
        '⚠️ Remote Config tidak tersedia di Web. Menggunakan default baseUrl.',
      );
      return;
    }

    try {
      final remoteConfig = FirebaseRemoteConfig.instance;

      // 🆕 Set default values untuk parameter baru
      await remoteConfig.setDefaults({
        'api_base_url': _baseUrl,
        'maintenance': false,
        'update_link':
            'https://play.google.com/store/apps/details?id=com.rennv.nimexx',
        'maintenance_start_date': '',
        'maintenance_end_date': '',
        'maintenance_reason':
            'Aplikasi sedang dalam tahap pemeliharaan untuk meningkatkan performa dan menambahkan fitur-fitur terbaru.',
        'new_features': '[]',
        'maintenance_title': '',
        'maintenance_duration_minutes': 0,
      });

      await remoteConfig.setConfigSettings(
        RemoteConfigSettings(
          fetchTimeout: const Duration(seconds: 10),
          minimumFetchInterval: Duration.zero, // untuk testing
        ),
      );

      debugPrint('📡 Fetching Remote Config...');
      await remoteConfig.fetchAndActivate();

      final remoteUrl = remoteConfig.getString('api_base_url');

      if (remoteUrl.isNotEmpty) {
        _baseUrl = remoteUrl;
      }

      // Debug semua parameter (termasuk yang baru)
      debugPrint('✅ Remote Config initialized:');
      debugPrint('   - API base URL: $_baseUrl');
      debugPrint('   - Maintenance: ${remoteConfig.getBool('maintenance')}');
      debugPrint('   - Update Link: ${remoteConfig.getString('update_link')}');
      debugPrint(
        '   - Maintenance Start: ${remoteConfig.getString('maintenance_start_date')}',
      );
      debugPrint(
        '   - Maintenance End: ${remoteConfig.getString('maintenance_end_date')}',
      );
      debugPrint(
        '   - Maintenance Reason: ${remoteConfig.getString('maintenance_reason')}',
      );
      debugPrint(
        '   - New Features: ${remoteConfig.getString('new_features')}',
      );
      debugPrint(
        '   - Maintenance Title: ${remoteConfig.getString('maintenance_title')}',
      );
      debugPrint(
        '   - Maintenance Duration: ${remoteConfig.getInt('maintenance_duration_minutes')} minutes',
      );
      debugPrint('   - Last Fetch Time: ${remoteConfig.lastFetchTime}');
      debugPrint('   - Last Fetch Status: ${remoteConfig.lastFetchStatus}');
    } catch (e) {
      debugPrint('❌ Gagal inisialisasi Remote Config: $e');
    }
  }

  // 🔧 Method untuk force refresh (debugging only)
  static Future<void> forceRefresh() async {
    if (kIsWeb) return;

    try {
      final remoteConfig = FirebaseRemoteConfig.instance;

      debugPrint('🔄 Force refreshing Remote Config...');
      await remoteConfig.fetchAndActivate();

      debugPrint('🔄 Force refresh completed:');
      debugPrint('   - Maintenance: ${remoteConfig.getBool('maintenance')}');
      debugPrint('   - Update Link: ${remoteConfig.getString('update_link')}');
      debugPrint('   - API URL: ${remoteConfig.getString('api_base_url')}');
      debugPrint(
        '   - Maintenance Start: ${remoteConfig.getString('maintenance_start_date')}',
      );
      debugPrint(
        '   - Maintenance End: ${remoteConfig.getString('maintenance_end_date')}',
      );
      debugPrint(
        '   - Maintenance Reason: ${remoteConfig.getString('maintenance_reason')}',
      );
      debugPrint(
        '   - New Features: ${remoteConfig.getString('new_features')}',
      );
      debugPrint(
        '   - Maintenance Title: ${remoteConfig.getString('maintenance_title')}',
      );
      debugPrint(
        '   - Duration: ${remoteConfig.getInt('maintenance_duration_minutes')} minutes',
      );
    } catch (e) {
      debugPrint('❌ Error force refresh: $e');
    }
  }

  // 🆕 Helper method untuk mendapatkan semua data maintenance sekaligus
  static Map<String, dynamic> get maintenanceData {
    if (kIsWeb) return {};

    return {
      'is_maintenance': isMaintenance,
      'update_link': updateLink,
      'start_date': maintenanceStartDate,
      'end_date': maintenanceEndDate,
      'reason': maintenanceReason,
      'new_features': newFeatures,
      'title': maintenanceTitle,
      'duration_minutes': maintenanceDurationMinutes,
    };
  }
}
