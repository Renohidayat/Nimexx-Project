class OngoingAnime {
  final String title;
  final String thumb;
  final String endpoint;
  final String
  totalEpisode; // Menggunakan String untuk totalEpisode karena di JSON berbentuk string
  final String updatedOn;

  OngoingAnime({
    required this.title,
    required this.thumb,
    required this.endpoint,
    required this.totalEpisode,
    required this.updatedOn, required String imageUrl,
  });

  factory OngoingAnime.fromJson(Map<String, dynamic> json) {
    return OngoingAnime(
      title: json['title'] ?? 'Unknown', // Menangani nilai null untuk title
      thumb: json['thumb'] ?? '', // Menangani nilai null untuk thumb
      endpoint: json['endpoint'] ?? '', // Menangani nilai null untuk endpoint
      totalEpisode:
          json['total_episode'] ??
          '0 Episode', // Menangani nilai null untuk total_episode
      updatedOn:
          json['updated_on'] ??
          'Unknown', imageUrl: '', // Menangani nilai null untuk updated_on
    );
  }
}

/// ✅ Tambahan Extension: Proxy Image Getter untuk AnimeDetail
extension AnimeOngoingProxy on OngoingAnime {
  String proxyThumb(String baseUrl) {
    if (thumb.isEmpty) return '';
    final encoded = Uri.encodeComponent(thumb);
    return '$baseUrl/proxy-image?url=$encoded';
  }
}
