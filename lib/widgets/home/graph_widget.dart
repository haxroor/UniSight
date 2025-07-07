import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '/providers/exam_provider.dart';

class GraphWidget extends StatelessWidget {
  const GraphWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ExamProvider>(
      builder: (context, examProvider, child) {
        List<Map<String, dynamic>> sortedExams =
        List.from(examProvider.completedExams);
        sortedExams.sort((a, b) => DateFormat('yyyy-MM-dd')
            .parse(a["data"])
            .compareTo(DateFormat('yyyy-MM-dd').parse(b["data"])));

        return SizedBox(
          height: 160,
          child: LineChart(
            LineChartData(
              minY: 18,
              maxY: 30,
              borderData: FlBorderData(show: false),
              gridData: FlGridData(show: false),
              titlesData: FlTitlesData(
                leftTitles: AxisTitles(
                    sideTitles:
                    SideTitles(showTitles: true, reservedSize: 30, interval: 4)),
                rightTitles:
                AxisTitles(sideTitles: SideTitles(showTitles: false)),
                topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                bottomTitles:
                AxisTitles(sideTitles: SideTitles(showTitles: false)),
              ),
              lineBarsData: [
                LineChartBarData(
                  spots: sortedExams.asMap().entries.map((entry) {
                    return FlSpot(
                        entry.key.toDouble(), double.parse(entry.value["voto"]));
                  }).toList(),
                  dotData: FlDotData(show: true),
                  isCurved: true,
                  color: Theme.of(context).colorScheme.primary,
                  barWidth: 3,
                  belowBarData: BarAreaData(
                    show: true,
                    gradient: LinearGradient(
                      colors: [
                        Theme.of(context).colorScheme.primary.withOpacity(0.5),
                        Theme.of(context).colorScheme.primary.withOpacity(0.0),
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}