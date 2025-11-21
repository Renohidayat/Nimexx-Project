import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class TopFavoritChart extends StatefulWidget {
  const TopFavoritChart({super.key});

  @override
  State<TopFavoritChart> createState() => _TopFavoritChartState();
}

class _TopFavoritChartState extends State<TopFavoritChart> {
  bool _isLoading = true;
  List<AnimeFavorite> _topFavorites = [];
  final List<Color> _barColors = [
    Colors.pinkAccent,
    Colors.blueAccent,
    Colors.purpleAccent,
    Colors.orangeAccent,
    Colors.greenAccent,
  ];

  @override
  void initState() {
    super.initState();
    _fetchTopFavoritAnime();
  }

  Future<void> _fetchTopFavoritAnime() async {
    try {
      final snapshot =
          await FirebaseFirestore.instance.collectionGroup('favorites').get();

      final animeMap = <String, AnimeFavorite>{};

      for (var doc in snapshot.docs) {
        final data = doc.data();
        final animeId = data['endpoint'];
        final title = data['title'] ?? 'Unknown Title';
        final thumb = data['thumb'];

        if (animeId == null) continue;

        if (animeMap.containsKey(animeId)) {
          animeMap[animeId] = animeMap[animeId]!.incrementCount();
        } else {
          animeMap[animeId] = AnimeFavorite(
            animeId: animeId,
            title: title,
            thumb: thumb,
            count: 1,
          );
        }
      }

      final sortedList =
          animeMap.values.toList()..sort((a, b) => b.count.compareTo(a.count));

      if (!mounted) return; // ✅ Cegah setState jika sudah dispose

      setState(() {
        _topFavorites = sortedList.take(5).toList();
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('❌ Error fetching favorites: $e');

      if (!mounted) return; // ✅ Tambahkan juga di sini

      setState(() {
        _topFavorites = [];
        _isLoading = false;
      });
    }
  }

  Widget _buildChart() {
    if (_topFavorites.isEmpty) {
      return const Center(
        child: Text(
          "Belum ada data favorit",
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    return Column(
      children: [
        SizedBox(
          height: 250,
          child: BarChart(
            BarChartData(
              alignment: BarChartAlignment.spaceAround,
              maxY: (_topFavorites.first.count + 1).toDouble(),
              minY: 0,
              barTouchData: BarTouchData(
                enabled: true,
                touchTooltipData: BarTouchTooltipData(
                  getTooltipItem: (group, groupIndex, rod, rodIndex) {
                    final anime = _topFavorites[group.x.toInt()];
                    return BarTooltipItem(
                      '${anime.title}\n${rod.toY.toInt()} favorit',
                      const TextStyle(color: Colors.white),
                    );
                  },
                ),
              ),
              titlesData: FlTitlesData(
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 40,
                    interval: _calculateInterval(_topFavorites.first.count),
                    getTitlesWidget:
                        (value, meta) => Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: Text(
                            value.toInt().toString(),
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                        ),
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      if (value.toInt() >= _topFavorites.length) {
                        return const SizedBox.shrink();
                      }
                      final anime = _topFavorites[value.toInt()];
                      return Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Tooltip(
                          message: anime.title,
                          child: Text(
                            _shortenTitle(anime.title),
                            style: const TextStyle(
                              fontSize: 10,
                              color: Colors.grey,
                            ),
                            textAlign: TextAlign.center,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      );
                    },
                  ),
                ),
                rightTitles: AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                topTitles: AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
              ),
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                horizontalInterval: _calculateInterval(
                  _topFavorites.first.count,
                ),
                getDrawingHorizontalLine:
                    (value) => FlLine(
                      color: Colors.grey.withOpacity(0.1),
                      strokeWidth: 1,
                    ),
              ),
              borderData: FlBorderData(show: false),
              barGroups:
                  _topFavorites.asMap().entries.map((entry) {
                    final index = entry.key;
                    final anime = entry.value;
                    return BarChartGroupData(
                      x: index,
                      barRods: [
                        BarChartRodData(
                          toY: anime.count.toDouble(),
                          color: _barColors[index % _barColors.length],
                          width: 22,
                          borderRadius: BorderRadius.circular(4),
                          backDrawRodData: BackgroundBarChartRodData(
                            show: true,
                            toY: (_topFavorites.first.count + 1).toDouble(),
                            color: Colors.grey.withOpacity(0.1),
                          ),
                        ),
                      ],
                    );
                  }).toList(),
            ),
          ),
        ),
        const SizedBox(height: 16),
        _buildLegend(),
      ],
    );
  }

  Widget _buildLegend() {
    return Wrap(
      spacing: 12,
      runSpacing: 8,
      children:
          _topFavorites.asMap().entries.map((entry) {
            final index = entry.key;
            final anime = entry.value;
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: _barColors[index % _barColors.length],
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  _shortenTitle(anime.title, maxLength: 20),
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            );
          }).toList(),
    );
  }

  String _shortenTitle(String title, {int maxLength = 10}) {
    if (title.length <= maxLength) return title;
    return '${title.substring(0, maxLength)}...';
  }

  double _calculateInterval(int maxCount) {
    if (maxCount <= 5) return 1;
    if (maxCount <= 10) return 2;
    if (maxCount <= 20) return 5;
    return 10;
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Theme.of(context).dividerColor, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.star, color: Theme.of(context).primaryColor),
                const SizedBox(width: 8),
                Text(
                  "Top 5 Anime Favorit",
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _isLoading
                ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: CircularProgressIndicator(),
                  ),
                )
                : _buildChart(),
          ],
        ),
      ),
    );
  }
}

class AnimeFavorite {
  final String animeId;
  final String title;
  final String? thumb;
  final int count;

  AnimeFavorite({
    required this.animeId,
    required this.title,
    this.thumb,
    required this.count,
  });

  AnimeFavorite incrementCount() {
    return AnimeFavorite(
      animeId: animeId,
      title: title,
      thumb: thumb,
      count: count + 1,
    );
  }
}
