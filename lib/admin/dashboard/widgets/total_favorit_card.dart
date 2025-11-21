import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';

class TotalFavoritCard extends StatefulWidget {
  const TotalFavoritCard({super.key});

  @override
  State<TotalFavoritCard> createState() => _TotalFavoritCardState();
}

class _TotalFavoritCardState extends State<TotalFavoritCard> {
  int _totalFavorites = 0;
  List<double> _weeklyTrend = [];
  bool _isLoading = true;
  bool _error = false;

  @override
  void initState() {
    super.initState();
    _fetchFavoriteData();
  }

  Future<void> _fetchFavoriteData() async {
    try {
      // Ambil data total favorit
      final favoritesSnapshot =
          await FirebaseFirestore.instance.collectionGroup('favorites').get();

      // Ambil data tren mingguan (contoh dummy, bisa disesuaikan dengan data real)
      final trendData = [120.0, 190.0, 210.0, 240.0, 280.0, 320.0, 350.0];

      if (mounted) {
        setState(() {
          _totalFavorites = favoritesSnapshot.size;
          _weeklyTrend = trendData;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching favorite data: $e');
      if (mounted) {
        setState(() {
          _error = true;
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final cardColor = isDark ? theme.cardColor : Colors.white;
    final primaryColor = isDark ? Colors.pinkAccent : Colors.pink;

    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: cardColor,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child:
            _isLoading
                ? _buildLoadingState()
                : _error
                ? _buildErrorState()
                : _buildContent(context, primaryColor, isDark),
      ),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: SizedBox(
        width: 40,
        height: 40,
        child: CircularProgressIndicator(strokeWidth: 2),
      ),
    );
  }

  Widget _buildErrorState() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.error_outline, color: Colors.red, size: 40),
        const SizedBox(height: 16),
        Text(
          'Gagal memuat data favorit',
          style: TextStyle(color: Colors.grey[600], fontSize: 16),
        ),
        const SizedBox(height: 8),
        OutlinedButton(
          onPressed: _fetchFavoriteData,
          child: const Text('Coba Lagi'),
        ),
      ],
    );
  }

  Widget _buildContent(BuildContext context, Color primaryColor, bool isDark) {
    final trendPercentage = _calculateTrendPercentage();
    final isTrendPositive = trendPercentage >= 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "Statistik Favorit",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color:
                    isTrendPositive
                        ? Colors.green.withOpacity(isDark ? 0.2 : 0.1)
                        : Colors.red.withOpacity(isDark ? 0.2 : 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(
                    isTrendPositive ? Icons.trending_up : Icons.trending_down,
                    size: 16,
                    color: isTrendPositive ? Colors.green : Colors.red,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    "${isTrendPositive ? '+' : ''}${trendPercentage.toStringAsFixed(1)}%",
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: isTrendPositive ? Colors.green : Colors.red,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              flex: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildStatCard(
                    value: _totalFavorites,
                    label: "Total Favorit",
                    icon: Icons.favorite,
                    color: primaryColor,
                    isDark: isDark,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    "Diperbarui: ${DateFormat('dd MMM yyyy').format(DateTime.now())}",
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? Colors.white54 : Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 20),
            Expanded(flex: 3, child: _buildTrendChart(primaryColor, isDark)),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required int value,
    required String label,
    required IconData icon,
    required Color color,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? color.withOpacity(0.1) : color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? color.withOpacity(0.3) : color.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 12),
          Text(
            NumberFormat.compact().format(value),
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: isDark ? Colors.white70 : Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrendChart(Color primaryColor, bool isDark) {
    return SizedBox(
      height: 150,
      child: LineChart(
        LineChartData(
          gridData: FlGridData(show: false),
          titlesData: FlTitlesData(show: false),
          borderData: FlBorderData(show: false),
          minX: 0,
          maxX: _weeklyTrend.length.toDouble() - 1,
          minY: 0,
          maxY: _weeklyTrend.reduce((a, b) => a > b ? a : b) * 1.2,
          lineBarsData: [
            LineChartBarData(
              spots:
                  _weeklyTrend.asMap().entries.map((e) {
                    return FlSpot(e.key.toDouble(), e.value);
                  }).toList(),
              isCurved: true,
              color: primaryColor,
              barWidth: 3,
              isStrokeCapRound: true,
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  colors: [
                    primaryColor.withOpacity(0.3),
                    primaryColor.withOpacity(0.1),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              dotData: FlDotData(show: false),
            ),
          ],
        ),
      ),
    );
  }

  double _calculateTrendPercentage() {
    if (_weeklyTrend.length < 2) return 0.0;
    final lastValue = _weeklyTrend.last;
    final previousValue = _weeklyTrend[_weeklyTrend.length - 2];
    return ((lastValue - previousValue) / previousValue) * 100;
  }
}
