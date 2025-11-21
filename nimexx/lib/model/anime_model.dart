class AnimeModel {
  final String title;
  final String thumb;
  final List<String> genres;
  final String link;

  AnimeModel({
    required this.title,
    required this.thumb,
    required this.genres,
    required this.link,
  });

  factory AnimeModel.fromJson(Map<String, dynamic> json) {
    // Coba ambil link dari beberapa kemungkinan key yang umum
    String link = '';
    if (json.containsKey('endpoint') &&
        json['endpoint'] != null &&
        json['endpoint'].toString().isNotEmpty) {
      link = json['endpoint'].toString();
    } else if (json.containsKey('link') &&
        json['link'] != null &&
        json['link'].toString().isNotEmpty) {
      link = json['link'].toString();
    } else if (json.containsKey('slug') &&
        json['slug'] != null &&
        json['slug'].toString().isNotEmpty) {
      link = json['slug'].toString();
    }

    print('AnimeModel.fromJson: title=${json['title']}, link=$link');

    return AnimeModel(
      title: json['title'] ?? '',
      thumb: json['thumb'] ?? '',
      genres:
          (json['genres'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      link: link,
    );
  }

  Map<String, dynamic> toJson() {
    return {'title': title, 'thumb': thumb, 'genres': genres, 'endpoint': link};
  }

  /// ✅ Proxy Image Getter
  String proxyThumb(String baseUrl) {
    final encodedUrl = Uri.encodeComponent(thumb);
    return '$baseUrl/proxy-image?url=$encodedUrl';
  }
}
