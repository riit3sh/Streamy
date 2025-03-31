import 'package:flutter/material.dart';
import 'package:streamy/pages/splashscreen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(url: "...", anonKey: "...");
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Streamy',

      theme: ThemeData.dark().copyWith(
        textSelectionTheme: const TextSelectionThemeData(
          cursorColor: Colors.redAccent, // Set cursor color
          selectionColor: Colors.redAccent, // Set text selection color
          selectionHandleColor: Colors.redAccent, // Set selection handle color
        ),
      ),
      home: const SplashScreen(),
    );
  }
}
