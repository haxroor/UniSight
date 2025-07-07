import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '/providers/exam_provider.dart';

class ExamListWidget extends StatelessWidget {
  final Function(Map<String, dynamic>) onEdit;
  const ExamListWidget({super.key, required this.onEdit});

  @override
  Widget build(BuildContext context) {
    final examProvider = Provider.of<ExamProvider>(context);
    final colorScheme = Theme.of(context).colorScheme;

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: examProvider.completedExams.length,
      itemBuilder: (context, index) {
        final exam = examProvider.completedExams[index];
        return Card(
          elevation: 2,
          margin: const EdgeInsets.symmetric(vertical: 6),
          child: ExpansionTile(
            leading: CircleAvatar(
              backgroundColor: colorScheme.primaryContainer.withOpacity(0.8),
              child: Text(
                exam["voto"].toString(),
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onPrimaryContainer),
              ),
            ),
            title: Text(exam["nome"],
                style: const TextStyle(fontWeight: FontWeight.w600)),
            subtitle: Text("${exam['cfu']} CFU"),
            trailing: const Icon(Icons.keyboard_arrow_down),
            children: [
              Padding(
                padding:
                const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("Data: ${exam['data']}",
                        style: Theme.of(context).textTheme.bodySmall),
                    Row(
                      children: [
                        TextButton.icon(
                          icon: const Icon(Icons.edit_outlined, size: 18),
                          label: const Text('Modifica'),
                          onPressed: () => onEdit(exam),
                        ),
                        TextButton.icon(
                          style: TextButton.styleFrom(
                              foregroundColor: colorScheme.error),
                          icon: const Icon(Icons.delete_outline, size: 18),
                          label: const Text('Rimuovi'),
                          onPressed: () async {
                            await examProvider
                                .deleteExamGrade(exam["nome"] as String);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text('Voto rimosso.'),
                                  backgroundColor: Colors.orange),
                            );
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              )
            ],
          ),
        );
      },
    );
  }
}