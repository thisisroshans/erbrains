import 'package:flutter/material.dart';

import 'design_system/nocturne_theme.dart';
import 'features/auth/auth_gate.dart';

class FitRingApp extends StatelessWidget {
  const FitRingApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FitRing',
      debugShowCheckedModeBanner: false,
      theme: NocturneTheme.dark,
      darkTheme: NocturneTheme.dark,
      themeMode: ThemeMode.dark,
      home: const AuthGate(),
    );
  }
}
