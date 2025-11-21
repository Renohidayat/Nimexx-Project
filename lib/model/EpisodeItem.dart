class EpisodeItem {
  final String title;
  final String endpoint;

  EpisodeItem({required this.title, required this.endpoint});

  factory EpisodeItem.fromJson(Map<String, dynamic> json) {
    return EpisodeItem(
      title: json['episode_title'] ?? 'No Title',
      endpoint: json['episode_endpoint'] ?? '',
    );
  }
}
