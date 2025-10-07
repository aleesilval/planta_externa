// main.dart
import 'package:flutter/material.dart';
import 'screens/welcome_page.dart';
import 'screens/planilla1.dart';
import 'screens/planilla2.dart';
import 'screens/planilla3.dart';
import 'security/security_wrapper.dart';
import 'security/pin_setup_screen.dart';
import 'security/pin_entry_screen.dart';
import 'security/pin_management_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Formularios para Planta Externa',
      theme: ThemeData(primarySwatch: Colors.cyan),
      home: const SecurityWrapper(child: WelcomePage()),
      routes: {
        '/welcome': (context) => const SecurityWrapper(child: WelcomePage()),
        '/planilla1': (context) => const SecurityWrapper(child: FormularioPage()),
        '/planilla2': (context) => const SecurityWrapper(child: Planilla2Page()),
        '/planilla3': (context) => const SecurityWrapper(child: Planilla3Page()),
        '/pin-setup': (context) => const PinSetupScreen(),
        '/pin-entry': (context) => const PinEntryScreen(),
        '/pin-management': (context) => const PinManagementScreen(),
      },
    );
  }
}