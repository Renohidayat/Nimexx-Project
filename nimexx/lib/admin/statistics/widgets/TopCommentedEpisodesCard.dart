import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class TopCommentedChart extends StatelessWidget {
  final Map<String, int> commentCountByEpisode;
  const TopCommentedChart({super.key, required this.commentCountByEpisode});

  @override
  Widget build(BuildContext context) {
    final sortedEntries =
        commentCountByEpisode.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));
    final top5 = sortedEntries.take(5).toList();
    if (top5.isEmpty) return _buildEmptyState();

    final maxValue = top5.map((e) => e.value).reduce((a, b) => a > b ? a : b);
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.all(16),
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              theme.colorScheme.surface.withOpacity(0.8),
              theme.colorScheme.surface.withOpacity(0.95),
            ],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.bar_chart_rounded,
                    color: theme.colorScheme.primary,
                    size: 24,
                  ),
                  const SizedBox(width: 8),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 260, // Increased height for better label visibility
                child: BarChart(
                  BarChartData(
                    maxY: maxValue.toDouble() * 1.2,
                    minY: 0,
                    alignment: BarChartAlignment.spaceAround,
                    barTouchData: BarTouchData(
                      enabled: true,
                      touchTooltipData: BarTouchTooltipData(
                        getTooltipItem: (group, groupIndex, rod, rodIndex) {
                          return BarTooltipItem(
                            '${top5[group.x.toInt()].key.replaceAll('-', ' ')}\n',
                            TextStyle(
                              color: theme.colorScheme.onSurface,
                              fontWeight: FontWeight.bold,
                            ),
                            children: [
                              TextSpan(
                                text: '${rod.toY.toInt()} comments',
                                style: TextStyle(
                                  color: theme.colorScheme.primary,
                                  fontWeight: FontWeight.normal,
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                    titlesData: FlTitlesData(
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 40,
                          getTitlesWidget: (value, meta) {
                            if (value == meta.min || value == meta.max) {
                              return const SizedBox();
                            }
                            return Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: Text(
                                value.toInt().toString(),
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurface
                                      .withOpacity(0.6),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      rightTitles: const AxisTitles(),
                      topTitles: const AxisTitles(),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize:
                              50, // Increased reserved size for labels
                          getTitlesWidget: (value, meta) {
                            if (value.toInt() < top5.length) {
                              final title =
                                  top5[value.toInt()].key
                                      .replaceAll('-', ' ')
                                      .toUpperCase();
                              return Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Tooltip(
                                  message: title, // Full title in tooltip
                                  child: Text(
                                    _getShortLabel(title),
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: theme.colorScheme.onSurface
                                          .withOpacity(0.8),
                                      fontWeight: FontWeight.w500,
                                    ),
                                    textAlign: TextAlign.center,
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 2,
                                  ),
                                ),
                              );
                            }
                            return const SizedBox();
                          },
                        ),
                      ),
                    ),
                    gridData: FlGridData(
                      show: true,
                      drawVerticalLine: false,
                      getDrawingHorizontalLine:
                          (value) => FlLine(
                            color: theme.colorScheme.onSurface.withOpacity(0.1),
                            strokeWidth: 1,
                          ),
                    ),
                    borderData: FlBorderData(
                      show: true,
                      border: Border(
                        bottom: BorderSide(
                          color: theme.colorScheme.onSurface.withOpacity(0.2),
                          width: 1,
                        ),
                        left: BorderSide(
                          color: theme.colorScheme.onSurface.withOpacity(0.2),
                          width: 1,
                        ),
                      ),
                    ),
                    barGroups: List.generate(top5.length, (index) {
                      final e = top5[index];
                      return BarChartGroupData(
                        x: index,
                        barRods: [
                          BarChartRodData(
                            toY: e.value.toDouble(),
                            width: 20,
                            borderRadius: BorderRadius.circular(4),
                            gradient: LinearGradient(
                              colors: [
                                theme.colorScheme.primary.withOpacity(0.8),
                                theme.colorScheme.primary.withOpacity(0.4),
                              ],
                              stops: const [0.1, 1.0],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            ),
                            backDrawRodData: BackgroundBarChartRodData(
                              show: true,
                              toY: maxValue.toDouble(),
                              color: theme.colorScheme.onSurface.withOpacity(
                                0.05,
                              ),
                            ),
                          ),
                        ],
                        showingTooltipIndicators: [0],
                      );
                    }),
                  ),
                  swapAnimationDuration: const Duration(milliseconds: 600),
                  swapAnimationCurve: Curves.easeOutQuint,
                ),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.only(left: 40),
                child: Text(
                  "Most active episodes by comment count",
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
              ),
              // Added episode list for full clarity
              if (top5.isNotEmpty) ...[
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Episode Details:",
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onSurface.withOpacity(0.8),
                        ),
                      ),
                      const SizedBox(height: 8),
                      ...top5.map(
                        (e) => Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Row(
                            children: [
                              Container(
                                width: 12,
                                height: 12,
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.primary,
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  e.key.replaceAll('-', ' ').toUpperCase(),
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.onSurface
                                        .withOpacity(0.8),
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                "${e.value} comments",
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _getShortLabel(String title) {
    final words = title.split(' ');
    if (words.length > 3) {
      return '${words[0]} ${words[1]}...';
    }
    return title.length > 12 ? '${title.substring(0, 10)}...' : title;
  }

  Widget _buildEmptyState() {
    return Card(
      margin: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: const Padding(
        padding: EdgeInsets.all(24),
        child: Center(
          child: Text(
            "No comment data available",
            style: TextStyle(color: Colors.grey),
          ),
        ),
      ),
    );
  }
}
