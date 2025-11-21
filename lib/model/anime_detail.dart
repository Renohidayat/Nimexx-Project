class AnimeDetail {
  final String title;
  final String thumb;
  final List<String> sinopsis;
  final List<String> detail;
  final List<Episode> episodes;

  AnimeDetail({
    required this.title,
    required this.thumb,
    required this.sinopsis,
    required this.detail,
    required this.episodes,
  });

  factory AnimeDetail.fromJson(Map<String, dynamic> json) {
    return AnimeDetail(
      title: json['title'] ?? 'No Title',
      thumb: json['thumb'] ?? '',
      sinopsis:
          json['sinopsis'] != null
              ? List<String>.from(
                (json['sinopsis'] as List).map((e) => e.toString()),
              )
              : [],
      detail:
          json['detail'] != null
              ? List<String>.from(
                (json['detail'] as List).map((e) => e.toString()),
              )
              : [],
      episodes:
          json['episode_list'] != null
              ? (json['episode_list'] as List)
                  .map((e) => Episode.fromJson(e as Map<String, dynamic>))
                  .toList()
              : [],
    );
  }
}

class Episode {
  final String title;
  final String endpoint;
  final String date;

  Episode({required this.title, required this.endpoint, required this.date});

  factory Episode.fromJson(Map<String, dynamic> json) {
    return Episode(
      title: json['episode_title'] ?? 'No Title',
      endpoint: json['episode_endpoint'] ?? '',
      date: json['episode_date'] ?? 'Unknown Date',
    );
  }
}

/// ✅ Tambahan Extension: Proxy Image Getter untuk AnimeDetail
extension AnimeDetailProxy on AnimeDetail {
  String proxyThumb(String baseUrl) {
    if (thumb.isEmpty) return '';
    final encoded = Uri.encodeComponent(thumb);
    return '$baseUrl/proxy-image?url=$encoded';
  }
}
