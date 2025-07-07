import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '/providers/exam_provider.dart';

class ProgressWidget extends StatelessWidget {
  const ProgressWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final examProvider = Provider.of<ExamProvider>(context);
    final acquired = examProvider.acquiredCfu;
    final total = examProvider.totalCfu;
    final remaining = total > acquired ? total - acquired : 0;
    final percentage = total > 0 ? (acquired / total) * 100 : 0.0;
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            SizedBox(
              height: 150,
              width: 150,
              child: Stack(
                children: [
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '${percentage.toStringAsFixed(1)}%',
                          style: Theme.of(context)
                              .textTheme
                              .headlineMedium
                              ?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: colorScheme.primary),
                        ),
                        Text('Completato',
                            style: Theme.of(context).textTheme.bodySmall),
                      ],
                    ),
                  ),
                  PieChart(
                    PieChartData(
                      sectionsSpace: 3,
                      centerSpaceRadius: 55,
                      sections: [
                        PieChartSectionData(
                          color: colorScheme.primary,
                          value: acquired.toDouble(),
                          title: '',
                          radius: 25,
                        ),
                        PieChartSectionData(
                          color: colorScheme.onSurface.withOpacity(0.1),
                          value: remaining.toDouble(),
                          title: '',
                          radius: 25,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatColumn(
                    'CFU', '$acquired / $total', Icons.school_outlined, context),
                _buildStatColumn('Media Pond.',
                    examProvider.weightedAverage.toStringAsFixed(2), Icons.balance_outlined, context),
                _buildStatColumn('Media Arit.',
                    examProvider.arithmeticAverage.toStringAsFixed(2), Icons.functions_outlined, context),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _buildStatColumn(
      String title, String value, IconData icon, BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      children: [
        Icon(icon, color: colorScheme.secondary),
        const SizedBox(height: 4),
        Text(value,
            style: Theme.of(context)
                .textTheme
                .titleLarge
                ?.copyWith(fontWeight: FontWeight.bold)),
        Text(title, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}