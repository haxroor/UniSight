import 'package:flutter/material.dart';
import '../screens/graduation_screen.dart';
import '../screens/settings_screen.dart';

class myNavigationDrawer extends StatelessWidget {
  const myNavigationDrawer({super.key});

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
    accountName: const Text('UniSight',
        style: TextStyle(
            fontFamily: 'MinionPro',
            fontWeight: FontWeight.bold,
            fontSize: 20)),
    accountEmail: const Text("https://github.com/haxroor"),
    currentAccountPicture: const CircleAvatar(
      foregroundImage: AssetImage('assets/ico.jpeg'),
    ),
  );

  Widget buildMenuItems(BuildContext context) => Column(
    children: [
      ListTile(
        leading: const Icon(Icons.school_outlined),
        title: const Text('Voto di Laurea'),
        onTap: () {
          Navigator.pop(context);
          Navigator.of(context).push(MaterialPageRoute(
              builder: (context) => const GraduationScreen()));
        },
      ),
      ListTile(
        leading: const Icon(Icons.settings_outlined),
        title: const Text('Impostazioni'),
        onTap: () {
          Navigator.pop(context);
          Navigator.of(context).push(MaterialPageRoute(
              builder: (context) => const SettingsScreen()));
        },
      ),
    ],
  );
}