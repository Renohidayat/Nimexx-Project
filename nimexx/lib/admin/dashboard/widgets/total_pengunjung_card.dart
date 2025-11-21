import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class TotalPengunjungCard extends StatefulWidget {
  const TotalPengunjungCard({super.key});

  @override
  State<TotalPengunjungCard> createState() => _TotalPengunjungCardState();
}

class _TotalPengunjungCardState extends State<TotalPengunjungCard> {
  int _totalUsers = 0;
  int _activeUsers = 0;
  int _lastWeekActive = 0;
  bool _loading = true;
  bool _error = false;

  @override
  void initState() {
    super.initState();
    _fetchUserStats();
  }

  Future<void> _fetchUserStats() async {
    try {
      final firestore = FirebaseFirestore.instance;
      final now = DateTime.now();
      final thirtyDaysAgo = now.subtract(const Duration(days: 30));
      final lastWeekStart = now.subtract(const Duration(days: 14));
      final lastWeekEnd = now.subtract(const Duration(days: 7));

      // Gunakan transaction untuk mengurangi pembacaan berulang
      final usersSnapshot = await firestore
          .collection('users')
          .get(const GetOptions(source: Source.server));

      int activeThisWeek = 0;
      int activeLastWeek = 0;

      // Gunakan batch processing untuk menghindari lag pada data besar
      for (var doc in usersSnapshot.docs) {
        final data = doc.data();
        final lastLogin = data['lastLogin'];

        if (lastLogin is Timestamp) {
          final loginTime = lastLogin.toDate();

          if (loginTime.isAfter(thirtyDaysAgo)) {
            activeThisWeek++;
          }

          if (loginTime.isAfter(lastWeekStart) &&
              loginTime.isBefore(lastWeekEnd)) {
            activeLastWeek++;
          }
        }
      }

      if (mounted) {
        setState(() {
          _totalUsers = usersSnapshot.docs.length;
          _activeUsers = activeThisWeek;
          _lastWeekActive = activeLastWeek;
          _loading = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching user stats: $e');
      if (mounted) {
        setState(() {
          _loading = false;
          _error = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final cardColor = isDark ? theme.cardColor : Colors.white;

    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: cardColor,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child:
            _loading
                ? _buildLoadingState()
                : _error
                ? _buildErrorState()
                : _buildContent(context, isDark),
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
          'Gagal memuat data',
          style: TextStyle(color: Colors.grey[600], fontSize: 16),
        ),
        const SizedBox(height: 8),
        OutlinedButton(
          onPressed: _fetchUserStats,
          child: const Text('Coba Lagi'),
        ),
      ],
    );
  }

  Widget _buildContent(BuildContext context, bool isDark) {
    final percentChange =
        _lastWeekActive == 0
            ? 0
            : (((_activeUsers - _lastWeekActive) / _lastWeekActive) * 100)
                .round();
    final isPositive = percentChange >= 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.people_alt_rounded,
              color: isDark ? Colors.blueAccent[200] : Colors.blueAccent,
              size: 24,
            ),
            const SizedBox(width: 8),
            Text(
              "Statistik Pengunjung",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                context,
                value: _totalUsers,
                label: "Total Pengguna",
                icon: Icons.group,
                color: Colors.blueAccent,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                context,
                value: _activeUsers,
                label: "Pengguna Aktif",
                icon: Icons.trending_up,
                color: isPositive ? Colors.greenAccent : Colors.redAccent,
                trendText: "${isPositive ? '+' : ''}$percentChange%",
                isPositive: isPositive,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          "Diperbarui: ${DateFormat('dd MMM yyyy, HH:mm').format(DateTime.now())}",
          style: TextStyle(
            fontSize: 12,
            color: isDark ? Colors.white54 : Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(
    BuildContext context, {
    required int value,
    required String label,
    required IconData icon,
    required Color color,
    String? trendText,
    bool? isPositive,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
              if (trendText != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color:
                        isPositive!
                            ? Colors.green.withOpacity(isDark ? 0.3 : 0.1)
                            : Colors.red.withOpacity(isDark ? 0.3 : 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    trendText,
                    style: TextStyle(
                      color: isPositive ? Colors.greenAccent : Colors.redAccent,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
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
}
