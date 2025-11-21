import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

class UserStatsCard extends StatefulWidget {
  const UserStatsCard({super.key});

  @override
  State<UserStatsCard> createState() => _UserStatsCardState();
}

class _UserStatsCardState extends State<UserStatsCard> {
  bool _loading = true;
  List<Map<String, dynamic>> _latestUsers = [];
  Map<String, int> _monthlyCounts = {};
  bool _showAll = false;
  int _selectedChartType = 0;

  @override
  void initState() {
    super.initState();
    _fetchUserStats();
  }

  Future<void> _fetchUserStats() async {
    try {
      final snapshot =
          await FirebaseFirestore.instance
              .collection('users')
              .orderBy('createdAt', descending: true)
              .limit(100)
              .get();

      final monthly = <String, int>{};
      final latest = <Map<String, dynamic>>[];

      for (var doc in snapshot.docs) {
        final data = doc.data();
        final createdAt = data['createdAt'];

        if (createdAt is Timestamp) {
          final date = createdAt.toDate();
          final key = DateFormat('yyyy-MM').format(date);
          monthly[key] = (monthly[key] ?? 0) + 1;
        }

        latest.add(data);
      }

      if (mounted) {
        setState(() {
          _monthlyCounts = monthly;
          _latestUsers = latest;
          _loading = false;
        });
      }
    } catch (e) {
      debugPrint('❌ Error fetching user stats: $e');
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final sortedMonths = _monthlyCounts.keys.toList()..sort();

    return _loading
        ? Center(
          child: Column(
            children: const [
              CircularProgressIndicator(),
              SizedBox(height: 12),
              Text("Loading user statistics..."),
            ],
          ),
        )
        : Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            const SizedBox(height: 12),

            // Card Latest Users
            _buildLatestUsersCard(isDark),
            const SizedBox(height: 24),

            // Analytics
            _buildAnalyticsSection(isDark, sortedMonths),
          ],
        );
  }

  Widget _buildLatestUsersCard(bool isDark) {
    return Card(
      color: isDark ? Colors.grey[900] : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                const Icon(Icons.group, color: Colors.blueAccent),
                const SizedBox(width: 8),
                Text(
                  "Pengguna Terbaru",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ..._latestUsers
                .take(_showAll ? _latestUsers.length : 3)
                .map((user) => _buildUserTile(user, isDark)),
            if (_latestUsers.length > 3)
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => setState(() => _showAll = !_showAll),
                  child: Text(
                    _showAll
                        ? 'Tampilkan Lebih Sedikit'
                        : 'Lihat Semua (${_latestUsers.length})',
                    style: const TextStyle(color: Colors.blueAccent),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserTile(Map<String, dynamic> user, bool isDark) {
    final email = user['email'] ?? 'No email';
    String dateText = 'Unknown date';

    if (user['createdAt'] is Timestamp) {
      final date = (user['createdAt'] as Timestamp).toDate();
      dateText = DateFormat('dd MMM yyyy - HH:mm').format(date);
    }

    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: const CircleAvatar(
        backgroundColor: Color(0xFFBBDEFB),
        child: Icon(Icons.person, color: Colors.blue),
      ),
      title: Text(
        email,
        style: TextStyle(color: isDark ? Colors.white : Colors.black87),
      ),
      subtitle: Text(
        dateText,
        style: TextStyle(
          color: isDark ? Colors.white54 : Colors.grey[600],
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _buildAnalyticsSection(bool isDark, List<String> sortedMonths) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.bar_chart, color: Colors.purpleAccent),
            const SizedBox(width: 8),
            Text(
              "Pertumbuhan Pengguna",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            const Spacer(),
            IconButton(
              icon: Icon(
                _selectedChartType == 0 ? Icons.pie_chart : Icons.bar_chart,
              ),
              tooltip: "Ubah jenis chart",
              onPressed: () {
                setState(() {
                  _selectedChartType = _selectedChartType == 0 ? 1 : 0;
                });
              },
            ),
          ],
        ),
        const SizedBox(height: 12),

        if (_monthlyCounts.isEmpty)
          Center(
            child: Text(
              "Belum ada data statistik",
              style: TextStyle(color: isDark ? Colors.white54 : Colors.grey),
            ),
          )
        else
          Card(
            color: isDark ? Colors.grey[900] : Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  SizedBox(
                    height: 250,
                    child:
                        _selectedChartType == 0
                            ? _buildPieChart(isDark, sortedMonths)
                            : _buildBarChart(isDark, sortedMonths),
                  ),
                  const SizedBox(height: 16),
                  _buildLegend(sortedMonths, isDark),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildPieChart(bool isDark, List<String> months) {
    return SfCircularChart(
      palette: _getChartColors(months.length),
      tooltipBehavior: TooltipBehavior(enable: true),
      series: <CircularSeries>[
        DoughnutSeries<MapEntry<String, int>, String>(
          dataSource: _monthlyCounts.entries.toList(),
          xValueMapper:
              (entry, _) => DateFormat(
                'MMM yyyy',
              ).format(DateTime.parse("${entry.key}-01")),
          yValueMapper: (entry, _) => entry.value,
          dataLabelMapper: (entry, _) => '${entry.value}',
          dataLabelSettings: const DataLabelSettings(isVisible: true),
          radius: '70%',
          innerRadius: '45%',
        ),
      ],
    );
  }

  Widget _buildBarChart(bool isDark, List<String> months) {
    return SfCartesianChart(
      tooltipBehavior: TooltipBehavior(enable: true),
      primaryXAxis: CategoryAxis(
        labelRotation: -45,
        labelStyle: TextStyle(
          color: isDark ? Colors.white70 : Colors.grey[700],
        ),
      ),
      primaryYAxis: NumericAxis(
        labelStyle: TextStyle(
          color: isDark ? Colors.white70 : Colors.grey[700],
        ),
      ),
      series: <CartesianSeries>[
        ColumnSeries<MapEntry<String, int>, String>(
          dataSource: _monthlyCounts.entries.toList(),
          xValueMapper:
              (entry, _) => DateFormat(
                'MMM yyyy',
              ).format(DateTime.parse("${entry.key}-01")),
          yValueMapper: (entry, _) => entry.value,
          color: Colors.purpleAccent,
          dataLabelSettings: const DataLabelSettings(isVisible: true),
        ),
      ],
    );
  }

  Widget _buildLegend(List<String> sortedMonths, bool isDark) {
    final colors = _getChartColors(sortedMonths.length);
    return Wrap(
      spacing: 12,
      children:
          sortedMonths.map((key) {
            final index = sortedMonths.indexOf(key);
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircleAvatar(
                  radius: 6,
                  backgroundColor: colors[index % colors.length],
                ),
                const SizedBox(width: 6),
                Text(
                  "${DateFormat('MMM yyyy').format(DateTime.parse('$key-01'))}: ${_monthlyCounts[key]}",
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.white70 : Colors.grey[700],
                  ),
                ),
              ],
            );
          }).toList(),
    );
  }

  List<Color> _getChartColors(int count) {
    return [
      Colors.purpleAccent,
      Colors.blueAccent,
      Colors.tealAccent,
      Colors.greenAccent,
      Colors.amberAccent,
      Colors.orangeAccent,
      Colors.redAccent,
      Colors.indigoAccent,
      Colors.pinkAccent,
    ].take(count).toList();
  }
}
