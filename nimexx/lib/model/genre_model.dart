class GenreModel {
  final String genre;
  final String endpoint;

  GenreModel({required this.genre, required this.endpoint});

  factory GenreModel.fromJson(Map<String, dynamic> json) {
    return GenreModel(
      genre: json['genre'] ?? '',
      endpoint: json['endpoint'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {'genre': genre, 'endpoint': endpoint};
  }
}
