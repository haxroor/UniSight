import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import './providers/exam_provider.dart';
import './providers/theme_provider.dart';
import './screens/course_setup_screen.dart';
import './screens/home_screen.dart';
import './services/data_persistence.dart';

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
          home: coursePlanExists ? const HomeScreen() : const CourseSetupScreen(),
        );
      },
    );
  }
}