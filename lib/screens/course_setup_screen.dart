import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/exam_provider.dart';
import '../screens/home_screen.dart';
import '../widgets/app_background.dart';

class CourseSetupScreen extends StatefulWidget {
  final bool isEditing;
  const CourseSetupScreen({super.key, this.isEditing = false});

  @override
  _CourseSetupScreenState createState() => _CourseSetupScreenState();
}

class _CourseSetupScreenState extends State<CourseSetupScreen> {
  late List<Map<String, dynamic>> _courses;

  @override
  void initState() {
    super.initState();
    if (widget.isEditing) {
      _courses =
          List.from(Provider.of<ExamProvider>(context, listen: false).allExams);
    } else {
      _courses = [];
    }
  }

  void _showCourseDialog({Map<String, dynamic>? courseToEdit}) {
    final _nameController =
    TextEditingController(text: courseToEdit?['nome'] ?? '');
    final _cfuController =
    TextEditingController(text: courseToEdit?['cfu']?.toString() ?? '');
    final _formKey = GlobalKey<FormState>();
    final isEditingDialog = courseToEdit != null;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(isEditingDialog ? 'Modifica Corso' : 'Aggiungi Corso'),
          content: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: 'Nome Esame'),
                  validator: (value) =>
                  value == null || value.isEmpty ? 'Inserisci un nome' : null,
                ),
                TextFormField(
                  controller: _cfuController,
                  decoration: const InputDecoration(labelText: 'CFU'),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Inserisci i CFU';
                    if (int.tryParse(value) == null) return 'Numero non valido';
                    return null;
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Annulla')),
            ElevatedButton(
              onPressed: () {
                if (_formKey.currentState!.validate()) {
                  final name = _nameController.text;
                  final cfu = int.parse(_cfuController.text);
                  setState(() {
                    if (isEditingDialog) {
                      final index = _courses
                          .indexWhere((c) => c['nome'] == courseToEdit['nome']);
                      if (index != -1) {
                        _courses[index] = {
                          "nome": name,
                          "voto": courseToEdit['voto'],
                          "data": courseToEdit['data'],
                          "cfu": cfu
                        };
                      }
                    } else {
                      _courses.add(
                          {"nome": name, "voto": null, "data": null, "cfu": cfu});
                    }
                  });
                  Navigator.pop(context);
                }
              },
              child: const Text('Salva'),
            ),
          ],
        );
      },
    );
  }

  void _onFinish() {
    final examProvider = Provider.of<ExamProvider>(context, listen: false);
    examProvider.setCoursePlan(_courses).then((_) {
      if (widget.isEditing) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Piano di studi aggiornato!'),
            backgroundColor: Colors.green));
      } else {
        Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const HomeScreen()));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(widget.isEditing ? 'Gestisci Corsi' : 'Crea Piano di Studi'),
        centerTitle: true,
        automaticallyImplyLeading: widget.isEditing,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: AppBackground(
        child: SafeArea(
          child: Column(
            children: [
              if (!widget.isEditing)
                const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text(
                    'Aggiungi tutti gli esami del tuo corso di laurea. Potrai modificarli in seguito dalle impostazioni.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16),
                  ),
                ),
              Expanded(
                child: _courses.isEmpty
                    ? const Center(
                    child: Text('Nessun corso aggiunto. Premi + per iniziare.'))
                    : ListView.builder(
                  itemCount: _courses.length,
                  itemBuilder: (context, index) {
                    final course = _courses[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 4),
                      child: ListTile(
                        title: Text(course['nome']),
                        subtitle: Text('${course['cfu']} CFU'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                                icon: const Icon(Icons.edit_outlined),
                                iconSize: 20,
                                onPressed: () =>
                                    _showCourseDialog(courseToEdit: course)),
                            IconButton(
                              icon: const Icon(Icons.delete_outline,
                                  color: Colors.redAccent),
                              iconSize: 20,
                              onPressed: () {
                                setState(() {
                                  _courses.removeAt(index);
                                });
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showCourseDialog,
        child: const Icon(Icons.add),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
            backgroundColor: Theme.of(context).colorScheme.primary,
            foregroundColor: Theme.of(context).colorScheme.onPrimary,
          ),
          onPressed: _courses.isNotEmpty ? _onFinish : null,
          child: Text(widget.isEditing ? 'Salva Modifiche' : 'Conferma e Inizia'),
        ),
      ),
    );
  }
}