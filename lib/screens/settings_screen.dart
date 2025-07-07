import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../screens/course_setup_screen.dart';
import '../widgets/app_background.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Impostazioni'),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: AppBackground(
        child: SafeArea(
          child: ListView(
            children: [
              const ListTile(
                title: Text('Generale',
                    style:
                    TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
              ),
              ListTile(
                leading: const Icon(Icons.contrast),
                title: const Text('Tema'),
                subtitle:
                const Text('Scegli tra tema scuro, chiaro o quello di default.'),
                onTap: () {
                  _showThemeDialog(context);
                },
              ),
              const ListTile(
                title: Text('Corso di Studi',
                    style:
                    TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
              ),
              ListTile(
                leading: const Icon(Icons.edit_note),
                title: const Text('Gestisci Esami'),
                subtitle:
                const Text('Aggiungi, modifica o elimina esami dal tuo piano.'),
                onTap: () {
                  Navigator.of(context).push(MaterialPageRoute(
                      builder: (context) => const CourseSetupScreen(isEditing: true)));
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