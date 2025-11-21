class ReleaseSchedule {
  final String title;
  final String thumb;
  final String totalEpisode;
  final String updatedOn;
  final String updatedDay;
  final String endpoint;

  ReleaseSchedule({
    required this.title,
    required this.thumb,
    required this.totalEpisode,
    required this.updatedOn,
    required this.updatedDay,
    required this.endpoint,
  });

  factory ReleaseSchedule.fromJson(Map<String, dynamic> json) {
    return ReleaseSchedule(
      title: json['title'] ?? '',
      thumb: json['thumb'] ?? '',
      totalEpisode: json['total_episode'] ?? '',
      updatedOn: json['updated_on'] ?? '',
      updatedDay: json['updated_day']?.trim() ?? '',
      endpoint: json['endpoint'] ?? '',
    );
  }
}

/// ✅ Tambahan Extension: Proxy Image Getter untuk AnimeDetail
extension AnimeScheduleProxy on ReleaseSchedule {
  String proxyThumb(String baseUrl) {
    if (thumb.isEmpty) return '';
    final encoded = Uri.encodeComponent(thumb);
    return '$baseUrl/proxy-image?url=$encoded';
  }
}
