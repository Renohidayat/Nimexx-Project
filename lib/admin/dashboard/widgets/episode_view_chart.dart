import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class EpisodeViewChart extends StatefulWidget {
  const EpisodeViewChart({super.key});

  @override
  State<EpisodeViewChart> createState() => _EpisodeViewChartState();
}

class _EpisodeViewChartState extends State<EpisodeViewChart> {
  final Map<String, int> _viewsPerDay = {};
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _getViewingData();
  }

  Future<void> _getViewingData() async {
    final firestore = FirebaseFirestore.instance;
    final auth = FirebaseAuth.instance;
    final now = DateTime.now();
    final DateTime limitDate = now.subtract(const Duration(days: 30));

    try {
      final user = auth.currentUser;
      if (user == null) throw Exception("🔒 User belum login.");

      final userDoc = await firestore.collection('users').doc(user.uid).get();
      final role = userDoc.data()?['role'] ?? 'user';

      // Ambil data tergantung role
      final snapshot =
          role == 'admin'
              ? await firestore.collectionGroup('history').get()
              : await firestore
                  .collection('watch_history')
                  .doc(user.uid)
                  .collection('history')
                  .get();

      for (var doc in snapshot.docs) {
        final data = doc.data();
        final Timestamp? watchedAt = data['watchedAt'];
        final bool isWatched = data['isWatched'] ?? false;

        if (watchedAt != null && isWatched) {
          final date = watchedAt.toDate();
          if (date.isAfter(limitDate)) {
            final key = DateFormat('yyyy-MM-dd').format(date);
            _viewsPerDay[key] = (_viewsPerDay[key] ?? 0) + 1;
          }
        }
      }

      setState(() {
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (_loading) {
      return const Center(child: CircularProgressIndicator(strokeWidth: 2));
    }

    if (_error != null) {
      return _errorDisplay(_error!);
    }

    if (_viewsPerDay.isEmpty) {
      return _emptyDisplay(isDark);
    }

    return _chartCard(isDark);
  }

  Widget _errorDisplay(String message) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, color: Colors.red[400]),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              message,
              style: TextStyle(color: Colors.red[400], fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _emptyDisplay(bool isDark) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.insert_chart_outlined,
              size: 40,
              color: isDark ? Colors.white24 : Colors.black26,
            ),
            const SizedBox(height: 8),
            Text(
              "Belum ada data tontonan.",
              style: TextStyle(color: isDark ? Colors.white60 : Colors.black45),
            ),
            const SizedBox(height: 4),
            Text(
              "30 hari terakhir",
              style: TextStyle(
                fontSize: 12,
                color: isDark ? Colors.white38 : Colors.black38,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _chartCard(bool isDark) {
    final sortedDates = _viewsPerDay.keys.toList()..sort();
    final maxViews = _viewsPerDay.values.reduce((a, b) => a > b ? a : b);
    final todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 20),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[900]!.withOpacity(0.7) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow:
            isDark
                ? []
                : [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 8,
                    spreadRadius: 2,
                    offset: const Offset(0, 6),
                  ),
                ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Episode Views (30 hari terakhir)",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 200,
            child: CustomPaint(
              painter: ChartBackgroundPainter(isDark: isDark, lineCount: 5),
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: sortedDates.length,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                itemBuilder: (context, index) {
                  final dateStr = sortedDates[index];
                  final count = _viewsPerDay[dateStr]!;
                  final height = (count / maxViews) * 120;
                  final isToday = dateStr == todayStr;

                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          height: height,
                          width: 24,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(6),
                            gradient: LinearGradient(
                              colors:
                                  isToday
                                      ? [
                                        Colors.blueAccent,
                                        Colors.lightBlueAccent,
                                      ]
                                      : isDark
                                      ? [
                                        Colors.indigoAccent,
                                        Colors.deepPurpleAccent,
                                      ]
                                      : [Colors.indigo, Colors.purpleAccent],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          DateFormat('dd').format(DateTime.parse(dateStr)),
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight:
                                isToday ? FontWeight.bold : FontWeight.normal,
                            color:
                                isToday
                                    ? (isDark
                                        ? Colors.lightBlueAccent
                                        : Colors.blueAccent)
                                    : (isDark
                                        ? Colors.white60
                                        : Colors.black54),
                          ),
                        ),
                        Text(
                          DateFormat('E').format(DateTime.parse(dateStr)),
                          style: TextStyle(
                            fontSize: 10,
                            color:
                                isToday
                                    ? (isDark
                                        ? Colors.lightBlueAccent
                                        : Colors.blueAccent)
                                    : (isDark
                                        ? Colors.white38
                                        : Colors.black38),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors:
                        isDark
                            ? [Colors.indigoAccent, Colors.purpleAccent]
                            : [Colors.indigo, Colors.purpleAccent],
                  ),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                "Jumlah tontonan",
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? Colors.white60 : Colors.black54,
                ),
              ),
              const Spacer(),
              Text(
                "Tertinggi: $maxViews",
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? Colors.white60 : Colors.black54,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class ChartBackgroundPainter extends CustomPainter {
  final bool isDark;
  final int lineCount;

  ChartBackgroundPainter({required this.isDark, required this.lineCount});

  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..color = isDark ? Colors.white10 : Colors.black12
          ..strokeWidth = 0.8;

    final spacing = size.height / (lineCount + 1);

    for (int i = 1; i <= lineCount; i++) {
      final y = spacing * i;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
