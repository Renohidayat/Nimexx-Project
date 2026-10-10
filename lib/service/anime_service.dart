import 'dart:convert';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../model/ongoing_anime.dart';
import '../model/anime_detail.dart';
import '../model/episode_detail.dart';
import '../model/anime_list_item.dart';
import '../model/release_schedule.dart';
import '../model/search_anime_item.dart';
import '../model/genre_model.dart';
import '../model/anime_model.dart';
import 'remote_config_service.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:hive_flutter/hive_flutter.dart';

class AnimeService {
  final String baseUrl;
  // Box caching API global
  late final Box _cacheBox;

  AnimeService({String? baseUrl})
      : baseUrl = baseUrl ?? RemoteConfigService.baseUrl {
    // Inisialisasi referensi ke box, jika sudah di open di main
    if (Hive.isBoxOpen('api_cache')) {
      _cacheBox = Hive.box('api_cache');
    }
  }

  // ---------------------------------------------------------------------------
  // HTTP helper
  // ---------------------------------------------------------------------------

  Future<http.Response> get(
    Uri uri, {
    int maxRetries = 5,
    Duration timeout = const Duration(seconds: 3),
    int retryDelayMs = 300,
    bool forceRefresh = false,
  }) {
    return _getWithRetry(
      uri,
      maxRetries: maxRetries,
      timeout: timeout,
      retryDelayMs: retryDelayMs,
      forceRefresh: forceRefresh,
    );
  }

  Future<http.Response> _getWithRetry(
    Uri uri, {
    int maxRetries = 5,
    Duration timeout = const Duration(seconds: 3),
    int retryDelayMs = 300,
    bool forceRefresh = false,
  }) async {
    final cacheKey = uri.toString();
    Map? cachedData;

    // 1. Cek cache
    if (Hive.isBoxOpen('api_cache')) {
      cachedData = _cacheBox.get(cacheKey);
      if (!forceRefresh && cachedData != null) {
        final int timestamp = cachedData['timestamp'] ?? 0;
        final int now = DateTime.now().millisecondsSinceEpoch;
        
        // Berlaku 10 menit (600000 ms) agar update ongoing lebih realtime
        if (now - timestamp < 600000) {
          debugPrint('✅ [CACHE HIT] $cacheKey');
          return http.Response(
            cachedData['body'], 
            200,
            headers: {'content-type': 'application/json; charset=utf-8'},
          );
        }
      }
    }

    // 2. Fetch network
    http.Response? lastResponse;

    for (int attempt = 1; attempt <= maxRetries; attempt++) {
      final isLastAttempt = attempt == maxRetries;

      try {
        final res = await http.get(uri).timeout(timeout);

        if (res.statusCode < 500) {
          if (res.statusCode == 200 && Hive.isBoxOpen('api_cache')) {
            _cacheBox.put(cacheKey, {
              'body': res.body,
              'timestamp': DateTime.now().millisecondsSinceEpoch,
            });
            debugPrint('🌐 [NETWORK SUCCESS] Cached $cacheKey');
          }
          return res;
        }
        lastResponse = res;
      } catch (e) {
        if (isLastAttempt) {
          if (cachedData != null) {
            debugPrint('⚠️ [OFFLINE FALLBACK] $cacheKey');
            return http.Response(
              cachedData['body'], 
              200,
              headers: {'content-type': 'application/json; charset=utf-8'},
            );
          }
          rethrow;
        }
      }

      if (!isLastAttempt) {
        await Future.delayed(Duration(milliseconds: retryDelayMs * attempt));
      }
    }

    if (lastResponse != null) return lastResponse;
    throw Exception('Failed to fetch data after $maxRetries attempts');
  }

  // ---------------------------------------------------------------------------
  // Genres
  // ---------------------------------------------------------------------------

  Future<List<GenreModel>> fetchGenres() async {
    final res = await _getWithRetry(Uri.parse('$baseUrl/genres'));

    if (res.statusCode != 200) {
      throw Exception('HTTP ${res.statusCode}');
    }

    final data = jsonDecode(res.body);
    if (data['status'] != true) {
      throw Exception('API: ${data['message']}');
    }

    return (data['genres'] as List).map((g) => GenreModel.fromJson(g)).toList();
  }

  Future<List<AnimeModel>> fetchAnimeByGenre(
    String endpoint, {
    int page = 1,
  }) async {
    final url = '$baseUrl/genres/$endpoint/$page';
    debugPrint('➡️ GET $url');

    final res = await _getWithRetry(Uri.parse(url));

    if (res.statusCode != 200) {
      throw Exception('HTTP ${res.statusCode}');
    }

    final data = jsonDecode(res.body);
    if (data['status'] != true) {
      throw Exception(data['message']);
    }

    return (data['genreAnime'] as List)
        .map((e) => AnimeModel.fromJson(e))
        .toList();
  }

  // ---------------------------------------------------------------------------
  // Search
  // ---------------------------------------------------------------------------

  Future<List<SearchAnimeItem>> searchAnime(String query) async {
    final uri = Uri.parse('$baseUrl/search/${Uri.encodeComponent(query)}');
    final res = await _getWithRetry(uri);

    if (res.statusCode != 200) {
      throw Exception('Failed to search');
    }

    final json = jsonDecode(res.body);

    if (json['status'] != true) {
      throw Exception(json['message'] ?? 'Search failed');
    }

    return (json['search'] as List)
        .map((e) => SearchAnimeItem.fromJson(e))
        .toList();
  }

  // ---------------------------------------------------------------------------
  // Lists
  // ---------------------------------------------------------------------------

  // Fetch jadwal rilis anime ongoing
  Future<List<ReleaseSchedule>> fetchSchedule() async {
    final response = await _getWithRetry(Uri.parse('$baseUrl/ongoing/1'));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final List list = data['ongoing'] ?? [];
      return list.map((json) => ReleaseSchedule.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load release schedule');
    }
  }

  // Fetch daftar anime umum
  Future<List<AnimeListItem>> fetchAnimeList() async {
    final response = await _getWithRetry(Uri.parse('$baseUrl/anime-list'));

    if (response.statusCode == 200) {
      final jsonData = jsonDecode(response.body);
      final List<dynamic> list = jsonData['anime_list'] ?? [];
      return list.map((item) => AnimeListItem.fromJson(item)).toList();
    } else {
      throw Exception('Failed to load anime list');
    }
  }

  // Fetch ongoing anime by page
  Future<List<OngoingAnime>> fetchOngoingAnime(int page) async {
    final response = await _getWithRetry(Uri.parse('$baseUrl/ongoing/$page'));

    if (response.statusCode == 200) {
      final jsonData = jsonDecode(response.body);
      final List<dynamic> animeList = jsonData['ongoing'] ?? [];
      return animeList.map((anime) => OngoingAnime.fromJson(anime)).toList();
    } else {
      throw Exception('Failed to load ongoing anime: ${response.statusCode}');
    }
  }

  // Fetch completed anime by page
  Future<List<OngoingAnime>> fetchCompletedAnime(int page) async {
    final response = await _getWithRetry(Uri.parse('$baseUrl/completed/$page'));

    if (response.statusCode == 200) {
      final jsonData = jsonDecode(response.body);
      final List<dynamic> animeList = jsonData['completed'] ?? [];
      return animeList.map((anime) => OngoingAnime.fromJson(anime)).toList();
    } else {
      throw Exception('Failed to load completed anime: ${response.statusCode}');
    }
  }

  // ---------------------------------------------------------------------------
  // Detail
  // ---------------------------------------------------------------------------

  // Fetch detail anime by endpoint
  Future<AnimeDetail> fetchAnimeDetail(String endpoint) async {
    try {
      final safeEndpoint = Uri.encodeComponent(Uri.decodeComponent(endpoint));
      final response =
          await _getWithRetry(Uri.parse('$baseUrl/detail/$safeEndpoint'));

      if (response.statusCode != 200) {
        throw Exception('Failed to load anime detail: ${response.statusCode}');
      }

      final jsonData = jsonDecode(response.body);

      if (jsonData is Map && jsonData['anime_detail'] != null) {
        if (jsonData['anime_detail'] is Map) {
          final detailData = Map<String, dynamic>.from(jsonData['anime_detail']);
          detailData['episode_list'] = jsonData['episode_list'] ?? [];

          return AnimeDetail.fromJson(detailData);
        } else if (jsonData['anime_detail'] is List && (jsonData['anime_detail'] as List).isEmpty) {
          throw Exception('Data detail anime kosong atau tidak tersedia dari server.');
        }
      }

      throw Exception('No valid anime details found in the response.');
    } catch (e) {
      debugPrint('Error in fetchAnimeDetail: $e');
      if (Hive.isBoxOpen('api_cache')) {
        final safeEndpoint = Uri.encodeComponent(Uri.decodeComponent(endpoint));
        final cacheKey = Uri.parse('$baseUrl/detail/$safeEndpoint').toString();
        _cacheBox.delete(cacheKey);
        debugPrint('🗑️ [CACHE DELETED] $cacheKey (Karena data kosong/error)');
      }
      rethrow;
    }
  }

  // Fetch episode detail dan ekstrak real streaming link
  Future<EpisodeDetail> fetchEpisodeDetail(String endpoint) async {
    try {
      final safeEndpoint = Uri.encodeComponent(Uri.decodeComponent(endpoint));
      final response =
          await _getWithRetry(Uri.parse('$baseUrl/episode/$safeEndpoint'));

      if (response.statusCode != 200) {
        throw Exception(
          'Failed to load episode detail: ${response.statusCode}',
        );
      }

      final jsonData = jsonDecode(response.body) as Map<String, dynamic>;

      final mirrorEmbed2 = jsonData['mirror_embed2']; // 480p
      final mirrorEmbed3 = jsonData['mirror_embed3']; // 720p

      // Prioritaskan 720p, fallback ke 480p
      final String? selectedLink =
          _pickStreamLink(mirrorEmbed3) ?? _pickStreamLink(mirrorEmbed2);

      if (selectedLink != null) {
        final realStreamUrl = await _fetchRealVideoUrl(selectedLink);
        if (realStreamUrl != null) {
          jsonData['real_stream_url'] = realStreamUrl;
        }
      }

      return EpisodeDetail.fromJson(jsonData);
    } catch (e) {
      debugPrint('Error in fetchEpisodeDetail: $e');
      rethrow;
    }
  }

  // ---------------------------------------------------------------------------
  // PRIVATE helpers
  // ---------------------------------------------------------------------------

  /// Cari link streaming dari satu mirror.
  /// Prioritas: driver yang mengandung "mega", lalu link valid pertama.
  /// Mengembalikan null jika tidak ada link yang bisa dipakai.
  String? _pickStreamLink(dynamic mirrorEmbed) {
    if (mirrorEmbed is! Map) return null;

    final streams = mirrorEmbed['straming'];
    if (streams is! List || streams.isEmpty) return null;

    String? linkOf(dynamic item) {
      if (item is! Map) return null;
      final link = item['link']?.toString();
      return (link == null || link.isEmpty) ? null : link;
    }

    // 1. Prioritaskan driver Mega
    for (final item in streams) {
      if (item is Map &&
          item['driver'] != null &&
          item['driver'].toString().toLowerCase().contains('mega')) {
        final link = linkOf(item);
        if (link != null) return link;
      }
    }

    // 2. Fallback: link valid pertama
    for (final item in streams) {
      final link = linkOf(item);
      if (link != null) return link;
    }

    return null;
  }

  // Ambil real video url dari streaming endpoint
  Future<String?> _fetchRealVideoUrl(String apiStreamingLink) async {
    try {
      final cleanPath = apiStreamingLink.replaceFirst(RegExp(r'^/api/v1'), '');
      final fullUrl = '$baseUrl$cleanPath';
      final response = await _getWithRetry(Uri.parse(fullUrl));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is Map) {
          if (data.containsKey('streaming_url')) {
            return data['streaming_url']?.toString();
          } else if (data['status'] == true && data.containsKey('video_url')) {
            return data['video_url']?.toString();
          }
        }
      }
      return null;
    } catch (e) {
      debugPrint('Error fetching real video url: $e');
      return null;
    }
  }
}