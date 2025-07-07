import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';

//-------------------------------------------------------------------------------------------------------------
//                                               PROVIDERS
//-------------------------------------------------------------------------------------------------------------

class ExamProvider extends ChangeNotifier {
  List<Map<String, dynamic>> _allExams = [];
  bool _isLoading = true;
  bool get isLoading => _isLoading;

  // --- Getters for UI ---
  List<Map<String, dynamic>> get allExams => _allExams;

  List<Map<String, dynamic>> get completedExams {
    List<Map<String, dynamic>> exams = _allExams.where((exam) =>
    exam["voto"] != null && exam["voto"].toString().isNotEmpty
    ).toList();

    // Sort by date, most recent first
    exams.sort((a, b) {
      try {
        DateTime dateA = DateFormat('yyyy-MM-dd').parse(a["data"]);
        DateTime dateB = DateFormat('yyyy-MM-dd').parse(b["data"]);
        return dateB.compareTo(dateA);
      } catch (e) {
        return 0;
      }
    });
    return exams;
  }

  List<Map<String, dynamic>> get pendingExams {
    return _allExams.where((exam) =>
    exam["voto"] == null || exam["voto"].toString().isEmpty
    ).toList();
  }

  int get totalCfu {
    return _allExams.fold(0, (sum, exam) => sum + (exam['cfu'] as int));
  }

  int get acquiredCfu {
    return completedExams.fold(0, (sum, exam) => sum + (exam['cfu'] as int));
  }

  double get weightedAverage {
    if (completedExams.isEmpty || acquiredCfu == 0) return 0.0;
    double weightedSum = completedExams.fold(0, (sum, exam) {
      return sum + (int.parse(exam['voto'].toString()) * (exam['cfu'] as int));
    });
    return weightedSum / acquiredCfu;
  }

  double get arithmeticAverage {
    if (completedExams.isEmpty) return 0.0;
    double sum = completedExams.fold(0, (sum, exam) {
      return sum + int.parse(exam['voto'].toString());
    });
    return sum / completedExams.length;
  }

  // --- Data Loading and Initialization ---
  Future<void> loadCoursePlan() async {
    _isLoading = true;
    notifyListeners();
    _allExams = await Data.loadData();
    _isLoading = false;
    notifyListeners();
  }

  Future<bool> isCoursePlanSet() async {
    final courses = await Data.loadData();
    return courses.isNotEmpty;
  }

  // --- Course and Grade Management ---
  Future<void> setCoursePlan(List<Map<String, dynamic>> courses) async {
    _allExams = courses;
    await Data.saveData(_allExams);
    notifyListeners();
  }

  Future<void> addCourse(String name, int cfu) async {
    _allExams.add({"nome": name, "voto": null, "data": null, "cfu": cfu});
    await Data.saveData(_allExams);
    notifyListeners();
  }

  Future<void> editCourse(String oldName, String newName, int newCfu) async {
    final index = _allExams.indexWhere((exam) => exam['nome'] == oldName);
    if (index != -1) {
      _allExams[index]['nome'] = newName;
      _allExams[index]['cfu'] = newCfu;
      await Data.saveData(_allExams);
      notifyListeners();
    }
  }

  Future<void> deleteCourse(String name) async {
    _allExams.removeWhere((exam) => exam['nome'] == name);
    await Data.saveData(_allExams);
    notifyListeners();
  }

  Future<void> updateExamGrade(String examName, String grade, String date) async {
    final index = _allExams.indexWhere((exam) => exam['nome'] == examName);
    if (index != -1) {
      _allExams[index]['voto'] = grade;
      _allExams[index]['data'] = date;
      await Data.saveData(_allExams);
      notifyListeners();
    }
  }

  Future<void> deleteExamGrade(String examName) async {
    await updateExamGrade(examName, '', '');
  }
}

class ThemeProvider extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.system;
  ThemeMode get themeMode => _themeMode;

  void toggleTheme(ThemeMode mode) {
    _themeMode = mode;
    notifyListeners();
  }
}

//-------------------------------------------------------------------------------------------------------------
//                                                   MAIN
//-------------------------------------------------------------------------------------------------------------

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  bool coursePlanExists = (await Data.loadData()).isNotEmpty;

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => ExamProvider()),
        ChangeNotifierProvider(create: (context) => ThemeProvider()),
      ],
      child: UniSight(coursePlanExists: coursePlanExists),
    ),
  );
}

//-------------------------------------------------------------------------------------------------------------
//                                               UI HELPERS
//-------------------------------------------------------------------------------------------------------------

class AppBackground extends StatelessWidget {
  final Widget child;
  const AppBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            colorScheme.surface,
            colorScheme.background,
          ],
        ),
      ),
      child: child,
    );
  }
}

//-------------------------------------------------------------------------------------------------------------
//                                              APP & HOME
//-------------------------------------------------------------------------------------------------------------

class UniSight extends StatelessWidget {
  final bool coursePlanExists;
  const UniSight({super.key, required this.coursePlanExists});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return MaterialApp(
          title: 'UniSight',
          theme: ThemeData(
            useMaterial3: true,
            colorScheme: ColorScheme.fromSeed(
              brightness: Brightness.light,
              seedColor: Colors.green,
            ),
          ),
          darkTheme: ThemeData(
            useMaterial3: true,
            colorScheme: ColorScheme.fromSeed(
              brightness: Brightness.dark,
              seedColor: Colors.green,
            ),
          ),
          themeMode: themeProvider.themeMode,
          home: coursePlanExists ? const HomePage() : const CourseSetupPage(),
        );
      },
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
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
        const SnackBar(content: Text('Tutti gli esami sono stati registrati!'), backgroundColor: Colors.orange),
      );
      return;
    }
    _showGradeDialog(context: context);
  }

  void _showEditGradeDialog(BuildContext context, Map<String, dynamic> examToEdit) {
    _showGradeDialog(context: context, examToEdit: examToEdit);
  }

  void _showGradeDialog({required BuildContext context, Map<String, dynamic>? examToEdit}) {
    String? selectedExam = examToEdit?['nome'];
    final _gradeController = TextEditingController(text: examToEdit?['voto']?.toString() ?? '');
    final _dateController = TextEditingController(text: examToEdit?['data']?.toString() ?? '');
    final _formKey = GlobalKey<FormState>();

    final isEditing = examToEdit != null;

    showDialog(
      context: context,
      builder: (context) {
        final examProvider = Provider.of<ExamProvider>(context, listen: false);
        List<Map<String, dynamic>> availableExams = isEditing ? [] : examProvider.pendingExams;

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
                      title: Text("Esame", style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary)),
                      subtitle: Text(selectedExam ?? ''),
                    )
                  else
                    DropdownButtonFormField<String>(
                      isExpanded: true,
                      decoration: InputDecoration(
                        labelText: "Esame",
                        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.7),
                      ),
                      validator: (value) => value == null || value.isEmpty ? 'Seleziona un esame' : null,
                      items: availableExams.map<DropdownMenuItem<String>>((exam) {
                        return DropdownMenuItem<String>(
                          value: exam["nome"] as String,
                          child: Text(exam["nome"] as String, overflow: TextOverflow.ellipsis),
                        );
                      }).toList(),
                      onChanged: (value) => selectedExam = value,
                    ),
                  TextFormField(
                    controller: _gradeController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: "Voto", hintText: "18-31"),
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
                    validator: (value) => value == null || value.isEmpty ? 'Inserisci una data' : null,
                    onTap: () async {
                      FocusScope.of(context).requestFocus(FocusNode());
                      DateTime? pickedDate = await showDatePicker(
                        context: context,
                        initialDate: _dateController.text.isNotEmpty ? DateFormat('yyyy-MM-dd').parse(_dateController.text) : DateTime.now(),
                        firstDate: DateTime(2000),
                        lastDate: DateTime.now(),
                      );
                      if (pickedDate != null) {
                        _dateController.text = DateFormat('yyyy-MM-dd').format(pickedDate);
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
        title: const Text('UniSight', style: TextStyle(fontFamily: 'MinionPro', fontWeight: FontWeight.bold, fontSize: 25)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      drawer: const NavigationDrawer(),
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
                  ProgressWidget(),
                  const SizedBox(height: 24),
                  if (examProvider.completedExams.length > 1)
                    GraphWidget()
                  else
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Text('Inserisci almeno due esami per visualizzare il grafico.', textAlign: TextAlign.center),
                      ),
                    ),
                  const SizedBox(height: 24),
                  Text(
                    'Esami Conseguiti',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
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

//-------------------------------------------------------------------------------------------------------------
//                                              HOME WIDGETS
//-------------------------------------------------------------------------------------------------------------

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
                          style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold, color: colorScheme.primary),
                        ),
                        Text('Completato', style: Theme.of(context).textTheme.bodySmall),
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
                _buildStatColumn('CFU', '$acquired / $total', Icons.school_outlined, context),
                _buildStatColumn('Media Pond.', examProvider.weightedAverage.toStringAsFixed(2), Icons.balance_outlined, context),
                _buildStatColumn('Media Arit.', examProvider.arithmeticAverage.toStringAsFixed(2), Icons.functions_outlined, context),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _buildStatColumn(String title, String value, IconData icon, BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      children: [
        Icon(icon, color: colorScheme.secondary),
        const SizedBox(height: 4),
        Text(value, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
        Text(title, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}

class GraphWidget extends StatelessWidget {
  const GraphWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ExamProvider>(
      builder: (context, examProvider, child) {
        List<Map<String, dynamic>> sortedExams = List.from(examProvider.completedExams);
        sortedExams.sort((a, b) => DateFormat('yyyy-MM-dd').parse(a["data"]).compareTo(DateFormat('yyyy-MM-dd').parse(b["data"])));

        return SizedBox(
          height: 180,
          child: LineChart(
            LineChartData(
              minY: 18, maxY: 31,
              borderData: FlBorderData(show: false),
              gridData: FlGridData(show: false),
              titlesData: FlTitlesData(
                leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 30, interval: 4)),
                rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
              ),
              lineBarsData: [
                LineChartBarData(
                  spots: sortedExams.asMap().entries.map((entry) {
                    return FlSpot(entry.key.toDouble(), double.parse(entry.value["voto"]));
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
                    color: colorScheme.onPrimaryContainer
                ),
              ),
            ),
            title: Text(exam["nome"], style: const TextStyle(fontWeight: FontWeight.w600)),
            subtitle: Text("${exam['cfu']} CFU"),
            trailing: const SizedBox.shrink(), // Hides the default arrow
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("Data: ${exam['data']}", style: Theme.of(context).textTheme.bodySmall),
                    Row(
                      children: [
                        TextButton.icon(
                          icon: const Icon(Icons.edit_outlined, size: 18),
                          label: const Text('Modifica'),
                          onPressed: () => onEdit(exam),
                        ),
                        TextButton.icon(
                          style: TextButton.styleFrom(foregroundColor: colorScheme.error),
                          icon: const Icon(Icons.delete_outline, size: 18),
                          label: const Text('Rimuovi'),
                          onPressed: () async {
                            await examProvider.deleteExamGrade(exam["nome"] as String);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Voto rimosso.'), backgroundColor: Colors.orange),
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


//-------------------------------------------------------------------------------------------------------------
//                                              NAVIGATION
//-------------------------------------------------------------------------------------------------------------

class NavigationDrawer extends StatelessWidget {
  const NavigationDrawer({super.key});

  @override
  Widget build(BuildContext context) => Drawer(
    child: SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          buildHeader(context),
          buildMenuItems(context),
        ],
      ),
    ),
  );

  Widget buildHeader(BuildContext context) => UserAccountsDrawerHeader(
    decoration: BoxDecoration(color: Color(0xFF285424)),
    accountName: const Text('UniSight', style: TextStyle(fontFamily: 'MinionPro', fontWeight: FontWeight.bold, fontSize: 20)),
    accountEmail: const Text("https://github.com/haxroor"),
    currentAccountPicture: const CircleAvatar(
      foregroundImage: AssetImage('assets/ico.jpeg'),
    ),
  );

  Widget buildMenuItems(BuildContext context) => Column(
    children: [
      ListTile(
        leading: const Icon(Icons.school_outlined),
        title: const Text('Graduation Forecast'),
        onTap: () {
          Navigator.pop(context);
          Navigator.of(context).push(MaterialPageRoute(builder: (context) => const GraduationPage()));
        },
      ),
      ListTile(
        leading: const Icon(Icons.settings_outlined),
        title: const Text('Settings'),
        onTap: () {
          Navigator.pop(context);
          Navigator.of(context).push(MaterialPageRoute(builder: (context) => const SettingsPage()));
        },
      ),
    ],
  );
}

//-------------------------------------------------------------------------------------------------------------
//                                             NEW PAGES
//-------------------------------------------------------------------------------------------------------------

class CourseSetupPage extends StatefulWidget {
  final bool isEditing;
  const CourseSetupPage({super.key, this.isEditing = false});

  @override
  _CourseSetupPageState createState() => _CourseSetupPageState();
}

class _CourseSetupPageState extends State<CourseSetupPage> {
  late List<Map<String, dynamic>> _courses;

  @override
  void initState() {
    super.initState();
    if(widget.isEditing) {
      _courses = List.from(Provider.of<ExamProvider>(context, listen: false).allExams);
    } else {
      _courses = [];
    }
  }

  void _showCourseDialog({Map<String, dynamic>? courseToEdit}) {
    final _nameController = TextEditingController(text: courseToEdit?['nome'] ?? '');
    final _cfuController = TextEditingController(text: courseToEdit?['cfu']?.toString() ?? '');
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
                  validator: (value) => value == null || value.isEmpty ? 'Inserisci un nome' : null,
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
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annulla')),
            ElevatedButton(
              onPressed: () {
                if (_formKey.currentState!.validate()) {
                  final name = _nameController.text;
                  final cfu = int.parse(_cfuController.text);
                  setState(() {
                    if(isEditingDialog) {
                      final index = _courses.indexWhere((c) => c['nome'] == courseToEdit['nome']);
                      if(index != -1) {
                        _courses[index] = {"nome": name, "voto": courseToEdit['voto'], "data": courseToEdit['data'], "cfu": cfu};
                      }
                    } else {
                      _courses.add({"nome": name, "voto": null, "data": null, "cfu": cfu});
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
      if(widget.isEditing) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Piano di studi aggiornato!'), backgroundColor: Colors.green));
      } else {
        Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const HomePage()));
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
              if(!widget.isEditing)
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
                    ? const Center(child: Text('Nessun corso aggiunto. Premi + per iniziare.'))
                    : ListView.builder(
                  itemCount: _courses.length,
                  itemBuilder: (context, index) {
                    final course = _courses[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      child: ListTile(
                        title: Text(course['nome']),
                        subtitle: Text('${course['cfu']} CFU'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(icon: const Icon(Icons.edit_outlined), iconSize: 20, onPressed: () => _showCourseDialog(courseToEdit: course)),
                            IconButton(
                              icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
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

class GraduationPage extends StatelessWidget {
  const GraduationPage({super.key});

  @override
  Widget build(BuildContext context) {
    final examProvider = Provider.of<ExamProvider>(context);
    final weightedAvg = examProvider.weightedAverage;

    double startingGrade = 0;
    if (weightedAvg > 0) {
      startingGrade = (weightedAvg * 110 / 30) + 2;
    }

    final gradeWithMinThesis = startingGrade;
    final gradeWithAvgThesis = startingGrade + 6;
    final gradeWithMaxThesis = startingGrade + 11;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Graduation Forecast'),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: AppBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Previsione Voto di Laurea',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Questa stima si basa sulla tua media ponderata attuale e non tiene conto di eventuali punti bonus.',
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
                const SizedBox(height: 32),
                _buildInfoCard(
                  context,
                  'Media Ponderata Attuale:',
                  weightedAvg.toStringAsFixed(3),
                ),
                const SizedBox(height: 16),
                _buildInfoCard(
                  context,
                  'Voto di Partenza (su 110):',
                  startingGrade > 0 ? startingGrade.toStringAsFixed(2) : 'N/A',
                  isHighlighted: true,
                ),
                const SizedBox(height: 32),
                Text(
                  'Range Voto Finale (con Tesi):',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                _buildGradeRange(
                  context,
                  min: gradeWithMinThesis,
                  avg: gradeWithAvgThesis,
                  max: gradeWithMaxThesis,
                  hasData: startingGrade > 0,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard(BuildContext context, String title, String value, {bool isHighlighted = false}) {
    return Card(
      color: isHighlighted ? Theme.of(context).colorScheme.primaryContainer.withOpacity(0.5) : null,
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

  Widget _buildGradeRange(BuildContext context, {required double min, required double avg, required double max, required bool hasData}) {
    final style = Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold);
    final noDataText = Text("N/A", style: style?.copyWith(color: Colors.grey));
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 24.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            hasData ? Text(min.toStringAsFixed(1), style: style) : noDataText,
            const Text('--', style: TextStyle(fontSize: 20)),
            hasData ? Text(avg.toStringAsFixed(1), style: style?.copyWith(color: Theme.of(context).colorScheme.primary)) : noDataText,
            const Text('--', style: TextStyle(fontSize: 20)),
            hasData ? Text(max.toStringAsFixed(1), style: style) : noDataText,
          ],
        ),
      ),
    );
  }
}

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Settings'),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: AppBackground(
        child: SafeArea(
          child: ListView(
            children: [
              const ListTile(
                title: Text('Generale', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
              ),
              ListTile(
                leading: const Icon(Icons.contrast),
                title: const Text('Change Theme'),
                onTap: () {
                  _showThemeDialog(context);
                },
              ),
              const ListTile(
                title: Text('Corso di Studi', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
              ),
              ListTile(
                leading: const Icon(Icons.edit_note),
                title: const Text('Manage Courses'),
                subtitle: const Text('Aggiungi, modifica o elimina esami dal tuo piano.'),
                onTap: () {
                  Navigator.of(context).push(MaterialPageRoute(builder: (context) => const CourseSetupPage(isEditing: true)));
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showThemeDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
        return AlertDialog(
          title: const Text('Change Theme'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.light_mode),
                title: const Text('Light'),
                onTap: () {
                  themeProvider.toggleTheme(ThemeMode.light);
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.dark_mode),
                title: const Text('Dark'),
                onTap: () {
                  themeProvider.toggleTheme(ThemeMode.dark);
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.settings_brightness),
                title: const Text('System Default'),
                onTap: () {
                  themeProvider.toggleTheme(ThemeMode.system);
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }
}


//-------------------------------------------------------------------------------------------------------------
//                                            DATA MANAGEMENT
//-------------------------------------------------------------------------------------------------------------

class Data {
  static Future<String> get _filePath async {
    final directory = await getApplicationDocumentsDirectory();
    return '${directory.path}/course_data.json';
  }

  static Future<List<Map<String, dynamic>>> loadData() async {
    try {
      final file = File(await _filePath);
      if (!await file.exists()) {
        return [];
      }
      final contents = await file.readAsString();
      if (contents.isEmpty) {
        return [];
      }
      return await compute(_decodeJson, contents);
    } catch (e) {
      print("Error loading data: $e");
      return [];
    }
  }

  static Future<void> saveData(List<Map<String, dynamic>> data) async {
    try {
      final file = File(await _filePath);
      final encodedData = await compute(_encodeJson, data);
      await file.writeAsString(encodedData);
    } catch (e) {
      print("Error saving data: $e");
    }
  }
}

List<Map<String, dynamic>> _decodeJson(String jsonString) {
  return List<Map<String, dynamic>>.from(jsonDecode(jsonString));
}

String _encodeJson(List<Map<String, dynamic>> data) {
  return jsonEncode(data);
}