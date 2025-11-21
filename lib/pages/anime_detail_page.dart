import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'anime_detail_mobile.dart';
import 'anime_detail_web.dart';

class AnimeDetailPage extends StatelessWidget {
  final String endpoint;
  final String? title;

  const AnimeDetailPage({super.key, required this.endpoint, this.title});

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) {
      return AnimeDetailWeb(endpoint: endpoint, title: title);
    } else {
      return AnimeDetailMobile(endpoint: endpoint, title: title);
    }
  }
}
