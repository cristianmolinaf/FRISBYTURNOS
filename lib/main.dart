import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'login_page.dart';
import 'admin_dashboard_page.dart';
import 'dashboard_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://pmegjmvqnffogtmbahdw.supabase.co',
    publishableKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InBtZWdqbXZxbmZmb2d0bWJhaGR3Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODc0NDgyODMsImV4cCI6MjEwMzAyNDI4M30.Q_2cmbTCVZVW3IY-f91QDAAyflME1rY-a1a9cCou84Q',
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Frisby Turnos',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFC8102E),
          primary: const Color(0xFFC8102E),
          secondary: const Color(0xFFFFC72C),
          surface: const Color(0xFFF9F9FB),
        ),
        scaffoldBackgroundColor: const Color(0xFFF9F9FB),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFFC8102E),
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        useMaterial3: true,
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const LoginPage(),
        '/dashboard': (context) => const DashboardPage(username: '10002'),
        '/admin': (context) => const AdminDashboardPage(
              username: '10001',
              profileName: 'Laura Restrepo (Admin)',
              role: 'administrador',
            ),
        '/login': (context) => const LoginPage(),
      },
    );
  }
}
