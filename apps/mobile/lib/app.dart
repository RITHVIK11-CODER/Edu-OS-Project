import 'package:flutter/material.dart';

import 'models.dart';
import 'screens.dart';

class EduOSApp extends StatefulWidget {
  const EduOSApp({super.key});

  @override
  State<EduOSApp> createState() => _EduOSAppState();
}

class _EduOSAppState extends State<EduOSApp> {
  final StudentSession session = StudentSession();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'EduOS',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: const Color(0xFF2457D6),
        scaffoldBackgroundColor: const Color(0xFFF7F9FC),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
        ),
      ),
      home: LoginScreen(session: session),
    );
  }
}
