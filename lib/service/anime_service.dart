import 'dart:convert';
import 'dart:async';
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

class AnimeService {
  final String baseUrl;

  AnimeService({String? baseUrl})
    : baseUrl = baseUrl ?? RemoteConfigService.baseUrl;

  Future<http.Response> get(Uri uri, {int maxRetries = 3}) {
    return _getWithRetry(uri, maxRetries: maxRetries);
  }

  Future<http.Response> _getWithRetry(Uri uri, {int maxRetries = 3}) async {
    int attempts = 0;
    while (attempts < maxRetries) {
      try {
        final res = await http.get(uri).timeout(const Duration(seconds: 10));
        // Return immediately if successful or client error (4xx) 
        // Retrying only makes sense for timeouts, network errors, or 5xx server errors
        if (res.statusCode < 500) {
          return res;
        }
      } catch (e) {
        if (attempts >= maxRetries - 1) {
          rethrow;
        }
      }
      attempts++;
      // Wait before retrying (exponential backoff: 2s, 4s)
      await Future.delayed(Duration(seconds: 2 * attempts));
    }
    throw Exception('Failed to fetch data after $maxRetries attempts');
  }

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
    print('➡️ GET $url');

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

    final list =
        (json['search'] as List)
            .map((e) => SearchAnimeItem.fromJson(e))
            .toList();

    return list;
  }

  // Fetch jadwal rilis anime ongoing
  Future<List<ReleaseSchedule>> fetchSchedule() async {
    final response = await _getWithRetry(Uri.parse('$baseUrl/ongoing/1'));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final List list = data['ongoing'];
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
      final List<dynamic> list = jsonData['anime_list'];
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

  // Fetch detail anime by endpoint
  Future<AnimeDetail> fetchAnimeDetail(String endpoint) async {
    try {
      final response = await _getWithRetry(Uri.parse('$baseUrl/detail/$endpoint'));

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);

        if (jsonData != null &&
            jsonData.containsKey('anime_detail') &&
            jsonData['anime_detail'] != null) {
          final detailData = Map<String, dynamic>.from(
            jsonData['anime_detail'],
          );
          detailData['episode_list'] = jsonData['episode_list'] ?? [];

          return AnimeDetail.fromJson(detailData);
        } else {
          throw Exception('No valid anime details found in the response.');
        }
      } else {
        throw Exception('Failed to load anime detail: ${response.statusCode}');
      }
    } catch (e) {
      print('Error in fetchAnimeDetail: $e');
      rethrow;
    }
  }

  // Fetch episode detail dan ekstrak real streaming link
  Future<EpisodeDetail> fetchEpisodeDetail(String endpoint) async {
    try {
      final response = await _getWithRetry(Uri.parse('$baseUrl/episode/$endpoint'));

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);

        final mirrorEmbed2 = jsonData['mirror_embed2']; // 480p
        final mirrorEmbed3 = jsonData['mirror_embed3']; // 720p

        String? selectedLink;

        // Perbaiki typo key dari 'straming' ke 'streaming'
        if (mirrorEmbed3 != null &&
            mirrorEmbed3['streaming'] != null &&
            mirrorEmbed3['streaming'].isNotEmpty) {
          selectedLink = mirrorEmbed3['streaming'][0]['link'];
        } else if (mirrorEmbed2 != null &&
            mirrorEmbed2['streaming'] != null &&
            mirrorEmbed2['streaming'].isNotEmpty) {
          selectedLink = mirrorEmbed2['streaming'][0]['link'];
        }

        if (selectedLink != null) {
          final realStreamUrl = await _fetchRealVideoUrl(selectedLink);
          if (realStreamUrl != null) {
            jsonData['real_stream_url'] = realStreamUrl;
          }
        }

        return EpisodeDetail.fromJson(jsonData);
      } else {
        throw Exception(
          'Failed to load episode detail: ${response.statusCode}',
        );
      }
    } catch (e) {
      print('Error in fetchEpisodeDetail: $e');
      rethrow;
    }
  }

  // PRIVATE: ambil real video url dari streaming endpoint
  Future<String?> _fetchRealVideoUrl(String apiStreamingLink) async {
    try {
      final fullUrl = '$baseUrl$apiStreamingLink';
      final response = await _getWithRetry(Uri.parse(fullUrl));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == true && data.containsKey('video_url')) {
          return data['video_url']; // <- real URL video
        }
      }
      return null;
    } catch (e) {
      print('Error fetching real video url: $e');
      return null;
    }
  }
}
