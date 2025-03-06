import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';

//------------------------------------------------------------------------------------------------------------- PROVIDER

class ExamProvider extends ChangeNotifier {
  List<Map<String, dynamic>> _exams = [];
  int _totalCfu = 0;
  int _acquiredCfu = 0;
  double _arithmeticAverage = 0;
  double _weightedAverage = 0;

  List<Map<String, dynamic>> get exams => _exams;
  int get totalCfu => _totalCfu;
  int get acquiredCfu => _acquiredCfu;
  double get arithmeticAverage => _arithmeticAverage;
  double get weightedAverage => _weightedAverage;

  Future<void> loadExams() async {
    _exams = await Data.loadData();
    _exams = _exams.where((exam) =>
    exam["voto"] != null &&
        exam["voto"].toString().isNotEmpty
    ).toList();

    _exams.sort((a, b) {
      String dateA = a["data"]?.toString() ?? "";
      String dateB = b["data"]?.toString() ?? "";

      if (dateA.isEmpty || dateB.isEmpty) {
        return 0;
      }

      try {
        DateTime parsedDateA = DateFormat('yyyy-MM-dd').parse(dateA);
        DateTime parsedDateB = DateFormat('yyyy-MM-dd').parse(dateB);
        return parsedDateB.compareTo(parsedDateA);
      } catch (e) {
        return 0;
      }
    });

    _totalCfu = await Data.getTotalCfu();
    _acquiredCfu = await Data.getOwnedCfu();
    _arithmeticAverage = await Data.getArithmeticAverage();
    _weightedAverage = await Data.getWeightedAverage();

    notifyListeners();
  }

  Future<void> addExam(String examName, String grade, String date) async {
    await Data.saveExam(examName, grade, date);
    await loadExams();
  }

  Future<void> deleteExam(String examName) async {
    await Data.saveExam(examName, "", "");
    await loadExams();
  }
}

class ThemeProvider extends ChangeNotifier {
  ThemeMode _themeMode = LAST_THEME;
  ThemeMode get themeMode => _themeMode;

  void toggleTheme(ThemeMode mode) {
    _themeMode = mode;
    notifyListeners();
  }
}

//------------------------------------------------------------------------------------------------------------- MAIN

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Data.initializeData();
  Data.loadAsset();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => ExamProvider()),
        ChangeNotifierProvider(create: (context) => ThemeProvider()),
      ],
      child: UniSight(),
    ),
  );
}

//------------------------------------------------------------------------------------------------------------- CUSTOMS

dynamic LAST_THEME = ThemeMode.system;

class MyThemeData {
  static ThemeData getTheme(ColorScheme colorScheme) {
    return ThemeData(
      colorScheme: colorScheme,
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
      ),
    );
  }
}

const List<Map<String, dynamic>> esamiInformatica = [
  {"nome": "Analisi Matematica", "voto": null, "data": null, "cfu": 9},
  {"nome": "Architettura dei sistemi di elaborazione", "voto": null, "data": null, "cfu": 6},
  {"nome": "Geometria ed algebra", "voto": null, "data": null, "cfu": 6},
  {"nome": "Logica e reti logiche", "voto": null, "data": null, "cfu": 6},
  {"nome": "Matematica discreta", "voto": null, "data": null, "cfu": 9},
  {"nome": "Fisica", "voto": null, "data": null, "cfu": 6},
  {"nome": "Programmazione dei calcolatori con laboratorio", "voto": null, "data": null, "cfu": 9},
  {"nome": "Algoritmi e strutture dati", "voto": null, "data": null, "cfu": 12},
  {"nome": "Basi di dati e di conoscenza", "voto": null, "data": null, "cfu": 9},
  {"nome": "Calcolo delle probabilità e statistica", "voto": null, "data": null, "cfu": 6},
  {"nome": "Fondamenti di informatica", "voto": null, "data": null, "cfu": 9},
  {"nome": "Linguaggi e metodologie di programmazione", "voto": null, "data": null, "cfu": 12},
  {"nome": "Ricerca operativa", "voto": null, "data": null, "cfu": 6},
  {"nome": "Sistemi operativi e reti", "voto": null, "data": null, "cfu": 12},
  {"nome": "Calcolo numerico", "voto": null, "data": null, "cfu": 6},
  {"nome": "Data Mining", "voto": null, "data": null, "cfu": 6},
  {"nome": "Ingegneria del software", "voto": null, "data": null, "cfu": 12},
  {"nome": "Intelligenza artificiale", "voto": null, "data": null, "cfu": 9},
];

//------------------------------------------------------------------------------------------------------------- HOMEPAGE

class UniSight extends StatelessWidget {
  const UniSight({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return MaterialApp(
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              brightness: Brightness.light,
              seedColor: Colors.green,
            ),
          ),
          darkTheme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              brightness: Brightness.dark,
              seedColor: Colors.green,
            ),
          ),
          themeMode: themeProvider.themeMode,
          home: HomePage(),
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
  late final NavigationDrawer _navigationDrawer;

  @override
  void initState() {
    super.initState();
    _navigationDrawer = NavigationDrawer();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ExamProvider>(context, listen: false).loadExams();
    });
  }

  void _showInputDialog(BuildContext context) async {
    String? selectedExam;
    TextEditingController _gradeController = TextEditingController();
    TextEditingController _dateController = TextEditingController();
    final _formKey = GlobalKey<FormState>();

    List<Map<String, dynamic>> pendingExams = await Data.loadData();
    pendingExams = pendingExams.where((exam) =>
    exam["voto"] == null || exam["voto"].toString().isEmpty).toList();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Inserisci un voto"),
          content: Container(
            width: double.maxFinite,
            child: Form(
              key: _formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<String>(
                      isExpanded: true,
                      decoration: InputDecoration(
                        labelText: "Esame",
                        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.7),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Seleziona un esame';
                        }
                        return null;
                      },
                      items: pendingExams.map<DropdownMenuItem<String>>((exam) {
                        return DropdownMenuItem<String>(
                          value: exam["nome"] as String,
                          child: Text(
                            exam["nome"] as String,
                            overflow: TextOverflow.ellipsis,
                          ),
                        );
                      }).toList(),
                      onChanged: (value) {
                        selectedExam = value;
                      },
                    ),
                    TextFormField(
                      controller: _gradeController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: "Voto",
                        hintText: "Inserisci un voto tra 18 e 31",
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Inserisci un voto';
                        }

                        // Try to parse as a number
                        try {
                          int grade = int.parse(value);
                          if (grade < 18) {
                            return 'Il voto non può essere inferiore a 18';
                          }
                          if (grade > 31) {
                            return 'Il voto non può essere superiore a 31';
                          }
                        } catch (e) {
                          return 'Inserisci un voto valido';
                        }
                        return null;
                      },
                    ),
                    TextFormField(
                      controller: _dateController,
                      decoration: InputDecoration(labelText: "Data"),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Inserisci una data';
                        }
                        return null;
                      },
                      onTap: () async {
                        // Unfocus to prevent keyboard from showing up
                        FocusScope.of(context).requestFocus(new FocusNode());

                        DateTime? pickedDate = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now(),
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
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text("Annulla"),
            ),
            ElevatedButton(
              onPressed: () async {
                if (_formKey.currentState!.validate()) {
                  await Provider.of<ExamProvider>(context, listen: false)
                      .addExam(selectedExam!, _gradeController.text, _dateController.text);
                  Navigator.pop(context);

                  // Show success message
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Voto salvato con successo'),
                      backgroundColor: Colors.green,
                      duration: Duration(seconds: 2),
                    ),
                  );
                }
              },
              child: Text("Salva"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('UniSight', style: TextStyle(fontFamily: 'MinionPro', fontWeight: FontWeight.bold, fontSize: 25)),
        centerTitle: true,
      ),
      drawer: _navigationDrawer,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ProgressWidget(),
            Text(""), // Spacer
            if (Provider.of<ExamProvider>(context).exams.length > 1)
              GraphWidget()
            else
              Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Center(child:Text('Grafico non disponibile: inserisci almeno due esami',))
                ],
              ),
            if (Provider.of<ExamProvider>(context).exams.isNotEmpty)
              Text('\n   Lista degli esami conseguiti:', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold))
            else
              Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Center(child: Text('\nNessun esame conseguito. Datti da fare!\n   (o, semplicemente, inserisci un voto)',
                      style: TextStyle(fontSize: 18))),
                ],
              ),
            ExamListWidget(),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showInputDialog(context),
        child: Icon(Icons.add),
      ),
    );
  }
}

//------------------------------------------------------------------------------------------------------------- PROGRESS

class ProgressWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final examProvider = Provider.of<ExamProvider>(context);

    return Row(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('   Progresso (CFU):', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            Container(
              width: 180,
              height: 130,
              padding: EdgeInsets.all(5),
              child: PieChart(
                PieChartData(
                  sections: [
                    PieChartSectionData(
                      color: Colors.green,
                      value: examProvider.acquiredCfu.toDouble(),
                      title: '${examProvider.acquiredCfu}',
                      titleStyle: TextStyle(color: Colors.black),
                      radius: 38,
                    ),
                    PieChartSectionData(
                      color: Color.fromARGB(255, 159, 159, 159),
                      value: (examProvider.totalCfu - examProvider.acquiredCfu).toDouble(),
                      title: '${examProvider.totalCfu - examProvider.acquiredCfu}',
                      titleStyle: TextStyle(color: Colors.black),
                      radius: 30,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),

        Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(""), // Spacer
            Text.rich(
              TextSpan(
                children: [
                  TextSpan(text: '          Percentuale CFU: ', style: TextStyle(fontWeight: FontWeight.bold)),
                  TextSpan(text: '${examProvider.acquiredCfu > 0 ? ((examProvider.acquiredCfu / examProvider.totalCfu) * 100).toStringAsFixed(2) : '0.00'}%'),
                ],
              ),
            ),
            Text.rich(
              TextSpan(
                children: [
                  TextSpan(text: '          Media ponderata: ', style: TextStyle(fontWeight: FontWeight.bold)),
                  TextSpan(text: '${examProvider.weightedAverage.toStringAsFixed(2)}'),
                ],
              ),
            ),
            Text.rich(
              TextSpan(
                children: [
                  TextSpan(text: '          Media Aritmetica: ', style: TextStyle(fontWeight: FontWeight.bold)),
                  TextSpan(text: '${examProvider.arithmeticAverage.toStringAsFixed(2)}'),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}

//------------------------------------------------------------------------------------------------------------- GRAPH

class GraphWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Selector<ExamProvider, List<Map<String, dynamic>>>(
      selector: (context, examProvider) => examProvider.exams,
      builder: (context, exams, child) {
        List<Map<String, dynamic>> sortedExams = List.from(exams);
        sortedExams.sort((a, b) {
          try {
            DateTime dateA = DateFormat('yyyy-MM-dd').parse(a["data"]);
            DateTime dateB = DateFormat('yyyy-MM-dd').parse(b["data"]);
            return dateA.compareTo(dateB);
          } catch (e) {
            return 0;
          }
        });

        return SizedBox(
          height: 160,
          width: 380,
          child: LineChart(
            LineChartData(
              minY: 17.6,
              maxY: 31,
              minX: 0,
              maxX: sortedExams.isNotEmpty ? sortedExams.length.toDouble() - 1 : 0,
              borderData: FlBorderData(
                show: false,
              ),
              gridData: FlGridData(
                show: false,
              ),
              titlesData: FlTitlesData(
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 40,
                    getTitlesWidget: (value, meta) {
                      if (value == 17.6 || value == 24.0 || value == 31) {
                        return SideTitleWidget(
                          meta: meta,
                          child: Text(value.ceil().toString(), style: TextStyle(fontSize: 12)),
                        );
                      }
                      return Container();
                    },
                  ),
                ),
                rightTitles: AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                topTitles: AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    interval: 1,
                    getTitlesWidget: (value, meta) {
                      if (value.toInt() < sortedExams.length) {
                        final currentExam = sortedExams[value.toInt()];
                        try {
                          final currentDate = DateFormat('yyyy-MM-dd').parse(currentExam["data"]);

                          bool isLastExamOfMonth = value.toInt() == sortedExams.length - 1 ||
                              DateFormat('MM-yy').format(currentDate) !=
                                  DateFormat('MM-yy').format(DateFormat('yyyy-MM-dd').parse(sortedExams[value.toInt() + 1]["data"]));

                          if (isLastExamOfMonth) {
                            return SideTitleWidget(
                              meta: meta,
                              child: Text(
                                DateFormat('MM-yy').format(currentDate),
                                style: TextStyle(fontSize: 10),
                              ),
                            );
                          }
                        } catch (e) {
                          return Container();
                        }
                      }
                      return Container();
                    },
                  ),
                ),
              ),
              lineBarsData: [
                LineChartBarData(
                  spots: sortedExams
                      .asMap()
                      .entries
                      .map((entry) {
                    try {
                      return FlSpot(entry.key.toDouble(), double.parse(entry.value["voto"]));
                    } catch (e) {
                      return FlSpot(entry.key.toDouble(), 0.0);
                    }
                  }).toList(),
                  dotData: FlDotData(show: false),
                  isCurved: true,
                  color: Colors.green,
                  barWidth: 0,
                  belowBarData: BarAreaData(
                    show: true,
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.green,
                        Colors.green,
                        Colors.lightGreenAccent,
                      ],
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

//------------------------------------------------------------------------------------------------------------- EXAM LIST

class ExamListWidget extends StatelessWidget {
  const ExamListWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final examProvider = Provider.of<ExamProvider>(context);

    return Expanded(
      child: Padding(
        padding: EdgeInsets.only(
          bottom: 80.0, // to avoid FAB overlapping
          left: 8.0,
          right: 8.0,
        ),
        child: ListView.builder(
          itemCount: examProvider.exams.length,
          itemBuilder: (context, index) {
            final exam = examProvider.exams[index];

            return ListTile(
              title: Text(exam["nome"]),
              subtitle: Text("Voto: ${exam["voto"]}, Data: ${exam["data"]}"),
              trailing: IconButton(
                icon: Icon(Icons.delete, color: Color.fromARGB(179, 204, 24, 24)),
                onPressed: () async {
                  await examProvider.deleteExam(exam["nome"] as String);
                },
              ),
            );
          },
        ),
      ),
    );
  }
}

//------------------------------------------------------------------------------------------------------------- NAVIGATION DRAWER

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

  Widget buildHeader(BuildContext context) => Container(
    padding: EdgeInsets.all(0),
    child: Column(
      children: [
        UserAccountsDrawerHeader(
          decoration: BoxDecoration(color: Theme.of(context).primaryColor),
          accountName: Text('UniSight', style: TextStyle(fontFamily: 'MinionPro', fontWeight: FontWeight.bold, fontSize: 20)),
          accountEmail: Text("https://github.com/haxroor"),
          currentAccountPicture: CircleAvatar(
            foregroundImage: AssetImage('assets/ico.jpeg'),
          ),
        ),
      ],
    ),
  );

  Widget buildMenuItems(BuildContext context) => Column(
    children: [
      ListTile(
        leading: const Icon(Icons.settings),
        title: const Text('Settings'),
        onTap: () {
          Navigator.pop(context);
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => SettingsPage(),
            ),
          );
        },
      ),
    ],
  );
}

//------------------------------------------------------------------------------------------------------------- SETTINGS PAGE

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Settings'),
        centerTitle: true,
        backgroundColor: Colors.transparent,
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('    Theme'),
            ListTile(
              leading: Icon(Icons.contrast),
              title: Text('Change Theme'),
              onTap: () {
                showDialog(
                  context: context,
                  builder: (context) {
                    return AlertDialog(
                      title: Text('Change Theme'),
                      content: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ListTile(
                            leading: Icon(Icons.light_mode),
                            title: Text('Light'),
                            onTap: () {
                              LAST_THEME = ThemeMode.light;
                              Provider.of<ThemeProvider>(context, listen: false)
                                  .toggleTheme(LAST_THEME);
                              Navigator.pop(context);
                            },
                          ),
                          ListTile(
                            leading: Icon(Icons.dark_mode),
                            title: Text('Dark'),
                            onTap: () {
                              LAST_THEME = ThemeMode.dark;
                              Provider.of<ThemeProvider>(context, listen: false)
                                  .toggleTheme(LAST_THEME);
                              Navigator.pop(context);
                            },
                          ),
                          ListTile(
                            leading: Icon(Icons.settings_brightness),
                            title: Text('System Default'),
                            onTap: () {
                              LAST_THEME = ThemeMode.system;
                              Provider.of<ThemeProvider>(context, listen: false)
                                  .toggleTheme(LAST_THEME);
                              Navigator.pop(context);
                            },
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

//------------------------------------------------------------------------------------------------------------- DATA MANAGEMENT

class Data {
  static Future<String> get _filePath async {
    final directory = await getApplicationDocumentsDirectory();
    return '${directory.path}/data.json';
  }

  static Future<String> loadAsset() async {
    final String response = await rootBundle.loadString('assets/data.json');
    return response;
  }

  static Future<void> initializeData() async {
    final file = File(await _filePath);
    if (!await file.exists()) {
      List<Map<String, dynamic>> initialData = esamiInformatica;
      await file.writeAsString(jsonEncode(initialData));
    }
  }

  static Future<List<Map<String, dynamic>>> loadData() async {
    return await compute(_loadDataFromFile, await _filePath);
  }

  static List<Map<String, dynamic>> _loadDataFromFile(String filePath) {
    final file = File(filePath);
    if (!file.existsSync()) return [];
    String contents = file.readAsStringSync();
    return List<Map<String, dynamic>>.from(jsonDecode(contents));
  }

  static Future<void> saveExam(String examName, String voto, String data) async {
    List<Map<String, dynamic>> exams = await loadData();
    for (var exam in exams) {
      if (exam["nome"] == examName) {
        exam["voto"] = voto;
        exam["data"] = data;
      }
    }
    final file = File(await _filePath);
    await file.writeAsString(jsonEncode(exams));
  }

  static Future<int> getTotalCfu() async {
    List<Map<String, dynamic>> exams = await loadData();
    int totalCfu = 0;
    for (var exam in exams) {
      if (exam["cfu"] != null) {
        totalCfu += exam["cfu"] as int;
      }
    }
    return totalCfu;
  }

  static Future<int> getOwnedCfu() async {
    List<Map<String, dynamic>> exams = await loadData();
    int acquiredCfu = 0;
    for (var exam in exams) {
      if (exam["voto"] != null && exam["voto"].toString().isNotEmpty) {
        acquiredCfu += exam["cfu"] as int;
      }
    }
    return acquiredCfu;
  }

  static Future<double> getWeightedAverage() async {
    List<Map<String, dynamic>> exams = await loadData();
    double weightedSum = 0;
    int totalCfu = 0;

    for (var exam in exams) {
      if (exam["voto"] != null && exam["voto"].toString().isNotEmpty) {
        try {
          int grade = int.parse(exam["voto"].toString());
          int cfu = exam["cfu"] as int;
          weightedSum += grade * cfu;
          totalCfu += cfu;
        } catch (e) {}
      }
    }
    return totalCfu > 0 ? weightedSum / totalCfu : 0;
  }

  static Future<double> getArithmeticAverage() async {
    List<Map<String, dynamic>> exams = await loadData();
    double sum = 0;
    int count = 0;

    for (var exam in exams) {
      if (exam["voto"] != null && exam["voto"].toString().isNotEmpty) {
        try {
          int grade = int.parse(exam["voto"].toString());
          sum += grade;
          count++;
        } catch (e) {}
      }
    }
    return count > 0 ? sum / count : 0;
  }
}