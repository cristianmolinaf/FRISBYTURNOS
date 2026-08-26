import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'login_page.dart';

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
          seedColor: const Color(0xFFAC0017),
          primary: const Color(0xFFAC0017),
          secondary: const Color(0xFFF7B640),
          surface: const Color(0xFFF8F9FB),
        ),
        useMaterial3: true,
        textTheme: (Theme.of(context).platform == TargetPlatform.iOS)
            ? null
            : GoogleFonts.hankenGroteskTextTheme(
                Theme.of(context).textTheme,
              ),
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const LoginPage(),
      },
    );
  }
}
