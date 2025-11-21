class Episode {
  final String title;
  final String endpoint;
  final String streamLink; // Properti untuk stream link
  final Map<String, List<Map<String, String>>> qualityLinks;

  Episode({
    required this.title,
    required this.endpoint,
    required this.streamLink,
    required this.qualityLinks,
  });

  factory Episode.fromJson(Map<String, dynamic> json) {
    var qualityLinks = json['mirror_embed'] as Map<String, dynamic>;
    Map<String, List<Map<String, String>>> parsedQualityLinks = {};

    String firstStreamLink = '';

    qualityLinks.forEach((key, value) {
      List<Map<String, String>> linkList = [];
      for (var item in value['straming']) {
        linkList.add({
          'driver': item['driver'] ?? '',
          'link': item['link'] ?? '',
        });
      }
      parsedQualityLinks[key] = linkList;

      // Ambil link pertama yang ketemu
      if (firstStreamLink.isEmpty && linkList.isNotEmpty) {
        firstStreamLink = linkList.first['link'] ?? '';
      }
    });

    return Episode(
      title: json['title'] ?? 'No Title',
      endpoint: json['endpoint'] ?? '',
      streamLink: firstStreamLink, // Menyimpan link pertama yang ditemukan
      qualityLinks: parsedQualityLinks,
    );
  }
}
