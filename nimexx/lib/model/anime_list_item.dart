class AnimeListItem {
  final String title;
  final String endpoint;
  final String thumb;
  final String? rating;

  AnimeListItem({
    required this.title,
    required this.endpoint,
    required this.thumb,
    this.rating,
  });

  factory AnimeListItem.fromJson(Map<String, dynamic> json) {
    return AnimeListItem(
      title: json['title'] ?? 'Unknown',
      endpoint: json['endpoint'] ?? '',
      thumb: json['thumb'] ?? '',
      rating: json['rating'], // pastikan key ini sesuai API
    );
  }
}
