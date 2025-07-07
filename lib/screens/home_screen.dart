import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../providers/exam_provider.dart';
import '../widgets/app_background.dart';
import '../widgets/home/exam_list_widget.dart';
import '../widgets/home/graph_widget.dart';
import '../widgets/home/progress_widget.dart';
import '../widgets/navigation_drawer.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ExamProvider>(context, listen: false).loadCoursePlan();
    });
  }

  void _showAddGradeDialog(BuildContext context) {
    final examProvider = Provider.of<ExamProvider>(context, listen: false);
    if (examProvider.pendingExams.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Tutti gli esami sono stati registrati!'),
            backgroundColor: Colors.orange),
      );
      return;
    }
    _showGradeDialog(context: context);
  }

  void _showEditGradeDialog(
      BuildContext context, Map<String, dynamic> examToEdit) {
    _showGradeDialog(context: context, examToEdit: examToEdit);
  }

  void _showGradeDialog(
      {required BuildContext context, Map<String, dynamic>? examToEdit}) {
    String? selectedExam = examToEdit?['nome'];
    final _gradeController =
    TextEditingController(text: examToEdit?['voto']?.toString() ?? '');
    final _dateController =
    TextEditingController(text: examToEdit?['data']?.toString() ?? '');
    final _formKey = GlobalKey<FormState>();
    final isEditing = examToEdit != null;

    showDialog(
      context: context,
      builder: (context) {
        final examProvider = Provider.of<ExamProvider>(context, listen: false);
        List<Map<String, dynamic>> availableExams =
        isEditing ? [] : examProvider.pendingExams;

        return AlertDialog(
          title: Text(isEditing ? "Modifica Voto" : "Inserisci Voto"),
          content: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (isEditing)
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text("Esame",
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.primary)),
                      subtitle: Text(selectedExam ?? ''),
                    )
                  else
                    DropdownButtonFormField<String>(
                      isExpanded: true,
                      decoration: InputDecoration(
                        labelText: "Esame",
                        constraints: BoxConstraints(
                            maxWidth: MediaQuery.of(context).size.width * 0.7),
                      ),
                      validator: (value) =>
                      value == null || value.isEmpty ? 'Seleziona un esame' : null,
                      items: availableExams.map<DropdownMenuItem<String>>((exam) {
                        return DropdownMenuItem<String>(
                          value: exam["nome"] as String,
                          child: Text(exam["nome"] as String,
                              overflow: TextOverflow.ellipsis),
                        );
                      }).toList(),
                      onChanged: (value) => selectedExam = value,
                    ),
                  TextFormField(
                    controller: _gradeController,
                    keyboardType: TextInputType.number,
                    decoration:
                    const InputDecoration(labelText: "Voto", hintText: "18-31"),
                    validator: (value) {
                      if (value == null || value.isEmpty) return 'Inserisci un voto';
                      final grade = int.tryParse(value);
                      if (grade == null) return 'Inserisci un numero valido';
                      if (grade < 18 || grade > 31) return 'Voto non valido (18-31)';
                      return null;
                    },
                  ),
                  TextFormField(
                    controller: _dateController,
                    decoration: const InputDecoration(labelText: "Data"),
                    readOnly: true,
                    validator: (value) =>
                    value == null || value.isEmpty ? 'Inserisci una data' : null,
                    onTap: () async {
                      FocusScope.of(context).requestFocus(FocusNode());
                      DateTime? pickedDate = await showDatePicker(
                        context: context,
                        initialDate: _dateController.text.isNotEmpty
                            ? DateFormat('yyyy-MM-dd').parse(_dateController.text)
                            : DateTime.now(),
                        firstDate: DateTime(2000),
                        lastDate: DateTime.now(),
                      );
                      if (pickedDate != null) {
                        _dateController.text =
                            DateFormat('yyyy-MM-dd').format(pickedDate);
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Annulla"),
            ),
            ElevatedButton(
              onPressed: () async {
                if (_formKey.currentState!.validate()) {
                  await examProvider.updateExamGrade(
                    selectedExam!,
                    _gradeController.text,
                    _dateController.text,
                  );
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Voto salvato con successo!'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              },
              child: const Text("Salva"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('UniSight',
            style: TextStyle(
                fontFamily: 'MinionPro',
                fontWeight: FontWeight.bold,
                fontSize: 25)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      drawer: const myNavigationDrawer(),
      body: AppBackground(
        child: Consumer<ExamProvider>(
          builder: (context, examProvider, child) {
            if (examProvider.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }
            return SafeArea(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                children: [
                  const SizedBox(height: 16),
                  const ProgressWidget(),
                  const SizedBox(height: 24),
                  if (examProvider.completedExams.length > 1)
                    const GraphWidget()
                  else
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Text(
                            'Inserisci almeno due esami per visualizzare il grafico.',
                            textAlign: TextAlign.center),
                      ),
                    ),
                  const SizedBox(height: 24),
                  Text(
                    'Esami Conseguiti',
                    style: Theme.of(context)
                        .textTheme
                        .titleLarge
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  if (examProvider.completedExams.isEmpty)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 40.0),
                        child: Text(
                          'Nessun esame conseguito.\nPremi + per aggiungerne uno!',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 16),
                        ),
                      ),
                    )
                  else
                    ExamListWidget(
                      onEdit: (exam) => _showEditGradeDialog(context, exam),
                    ),
                  const SizedBox(height: 80),
                ],
              ),
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddGradeDialog(context),
        child: const Icon(Icons.add),
      ),
    );
  }
}