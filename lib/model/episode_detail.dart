class StreamLink {
  final String driver;
  final String link;
  final int index;

  StreamLink({required this.driver, required this.link, required this.index});

  factory StreamLink.fromJson(Map<String, dynamic> json, int index) {
    return StreamLink(
      driver: json['driver'] ?? '',
      link: json['link'] ?? '',
      index: index,
    );
  }
}

class EpisodeDetail {
  final String title;
  final String baseUrl;
  final String id;
  final List<StreamLink> mirror360p;
  final List<StreamLink> mirror480p;
  final List<StreamLink> mirror720p;
  final String? realStreamUrl; // Tambahan opsional

  EpisodeDetail({
    required this.title,
    required this.baseUrl,
    required this.id,
    required this.mirror360p,
    required this.mirror480p,
    required this.mirror720p,
    this.realStreamUrl,
  });

  factory EpisodeDetail.fromJson(Map<String, dynamic> json) {
    List<StreamLink> parseMirror(dynamic mirrorJson) {
      if (mirrorJson == null || mirrorJson['straming'] == null) return [];
      final list = List<Map<String, dynamic>>.from(mirrorJson['straming']);
      return list.asMap().entries.map((entry) {
        return StreamLink.fromJson(entry.value, entry.key);
      }).toList();
    }

    return EpisodeDetail(
      title: json['title'] ?? '',
      baseUrl: json['baseUrl'] ?? '',
      id: json['id']?.toString() ?? '',
      mirror360p: parseMirror(json['mirror_embed1']),
      mirror480p: parseMirror(json['mirror_embed2']),
      mirror720p: parseMirror(json['mirror_embed3']),
      realStreamUrl: json['real_stream_url'], // <- ini tambahan
    );
  }
}
