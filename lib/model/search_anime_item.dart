class SearchAnimeItem {
  final String title;
  final String thumb;
  final List<String> genres;
  final List<String> status;
  final String rating;
  final String endpoint;

  SearchAnimeItem({
    required this.title,
    required this.thumb,
    required this.genres,
    required this.status,
    required this.rating,
    required this.endpoint,
  });

  factory SearchAnimeItem.fromJson(Map<String, dynamic> json) {
    return SearchAnimeItem(
      title: json['title']?.toString() ?? 'Unknown Title',
      thumb: json['thumb']?.toString() ?? '',
      genres:
          (json['genres'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      status:
          (json['status'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      rating: json['rating']?.toString() ?? 'N/A',
      endpoint: json['endpoint']?.toString() ?? '',
    );
  }
}

extension SearchAnimeProxy on SearchAnimeItem {
  String proxyThumb(String baseUrl) {
    if (thumb.isEmpty) return '';
    final encoded = Uri.encodeComponent(thumb);
    return '$baseUrl/proxy-image?url=$encoded';
  }
}
