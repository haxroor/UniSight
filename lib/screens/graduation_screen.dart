import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '/providers/exam_provider.dart';
import '/widgets/app_background.dart';

class GraduationScreen extends StatefulWidget {
  const GraduationScreen({super.key});

  @override
  State<GraduationScreen> createState() => _GraduationScreenState();
}

class _GraduationScreenState extends State<GraduationScreen> {
  final List<String> _statusOptions = [
    "Terzo Anno In Corso",
    "Primo Anno Fuori Corso",
    "Secondo Anno Fuori Corso o Oltre",
  ];
  late String _selectedStatus;

  @override
  void initState() {
    super.initState();
    _selectedStatus = _statusOptions.first;
  }

  int _getStatusBonus() {
    switch (_selectedStatus) {
      case "Terzo Anno In Corso":
        return 2;
      case "Primo Anno Fuori Corso":
        return 1;
      case "Secondo Anno Fuori Corso o Oltre":
        return 0;
      default:
        return 0;
    }
  }

  String _formatFinalGrade(int score) {
    if (score > 110) {
      return '110L';
    }
    return score.toString();
  }

  @override
  Widget build(BuildContext context) {
    final examProvider = Provider.of<ExamProvider>(context);
    final weightedAvg = examProvider.weightedAverage;

    int roundedStartingGrade = 0;
    if (weightedAvg > 0) {
      final rawStartingGrade = (weightedAvg * 110 / 30);
      roundedStartingGrade = rawStartingGrade.round();
    }

    final statusBonus = _getStatusBonus();

    final minFinal = roundedStartingGrade + 0 + statusBonus;
    final avgFinal = roundedStartingGrade + 6 + statusBonus;
    final maxFinal = roundedStartingGrade + 11 + statusBonus;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Voto di Laurea'),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: AppBackground(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(24.0),
            children: [
              const Text(
                'Previsione Voto di Laurea',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                '= Media Ponderata in 110imi (arrotondata per eccesso)\n+ 0-2 Punti Bonus in Corso\n+ 0-11 Punti Tesi',
                style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 16),
              _buildInfoCard(
                context,
                'Media Ponderata Attuale:',
                weightedAvg.toStringAsFixed(2),
              ),
              const SizedBox(height: 8),
              _buildInfoCard(
                context,
                'Voto di Partenza:',
                roundedStartingGrade > 0 ? roundedStartingGrade.toString() : 'N/A',
                isHighlighted: true,
              ),
              const SizedBox(height: 8),
              _buildStatusSelector(context),
              const SizedBox(height: 16),
              Text(
                'Range Voto Finale Stimato:',
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              _buildFinalGradeRange(
                context,
                minGrade: _formatFinalGrade(minFinal),
                avgGrade: _formatFinalGrade(avgFinal),
                maxGrade: _formatFinalGrade(maxFinal),
                hasData: roundedStartingGrade > 0,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusSelector(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        child: DropdownButtonFormField<String>(
          value: _selectedStatus,
          decoration: const InputDecoration(
            labelText: 'Status Studente',
            border: InputBorder.none,
          ),
          items: _statusOptions.map((String status) {
            return DropdownMenuItem<String>(
              value: status,
              child: Text(status),
            );
          }).toList(),
          onChanged: (String? newValue) {
            if (newValue != null) {
              setState(() {
                _selectedStatus = newValue;
              });
            }
          },
        ),
      ),
    );
  }

  Widget _buildInfoCard(BuildContext context, String title, String value,
      {bool isHighlighted = false}) {
    return Card(
      color: isHighlighted
          ? Theme.of(context).colorScheme.primaryContainer.withOpacity(0.5)
          : null,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title, style: const TextStyle(fontSize: 16)),
            Text(
              value,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFinalGradeRange(BuildContext context,
      {required String minGrade,
        required String avgGrade,
        required String maxGrade,
        required bool hasData}) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 20.0),
        child: !hasData
            ? Center(
            child: Text("N/A",
                style: Theme.of(context)
                    .textTheme
                    .headlineSmall
                    ?.copyWith(color: Colors.grey)))
            : IntrinsicHeight(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildGradeColumn(
                context,
                grade: minGrade,
                label: 'Tesi Minima (0)',
                icon: Icons.trending_down,
              ),
              const VerticalDivider(thickness: 1, width: 20, indent: 10, endIndent: 10),
              _buildGradeColumn(
                context,
                grade: avgGrade,
                label: 'Tesi Media (6)',
                icon: Icons.horizontal_rule,
                isHighlighted: true,
              ),
              const VerticalDivider(thickness: 1, width: 20, indent: 10, endIndent: 10),
              _buildGradeColumn(
                context,
                grade: maxGrade,
                label: 'Tesi Massima (11)',
                icon: Icons.trending_up,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGradeColumn(BuildContext context,
      {required String grade,
        required String label,
        required IconData icon,
        bool isHighlighted = false}) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          color: isHighlighted
              ? colorScheme.primary
              : colorScheme.onSurface.withOpacity(0.6),
          size: 28,
        ),
        const SizedBox(height: 8),
        Text(
          grade,
          style: textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: isHighlighted ? colorScheme.primary : colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: textTheme.bodySmall?.copyWith(
            color: colorScheme.onSurface.withOpacity(0.8),
          ),
        ),
      ],
    );
  }
}