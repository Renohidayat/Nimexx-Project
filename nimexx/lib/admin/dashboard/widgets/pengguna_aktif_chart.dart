import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class PenggunaAktifChart extends StatelessWidget {
  final int aktif;
  final int total;

  const PenggunaAktifChart({
    super.key,
    required this.aktif,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    final tidakAktif = total - aktif;

    final sections = <PieChartSectionData>[
      PieChartSectionData(
        value: aktif.toDouble(),
        title: 'Aktif\n$aktif',
        color: Colors.green,
        radius: 60,
        titleStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
      PieChartSectionData(
        value: tidakAktif.toDouble(),
        title: 'Tidak\nAktif\n$tidakAktif',
        color: Colors.red,
        radius: 60,
        titleStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    ];

    return SizedBox(
      height: 250,
      child: PieChart(
        PieChartData(
          sections: sections,
          centerSpaceRadius: 40,
          sectionsSpace: 4,
        ),
      ),
    );
  }
}
