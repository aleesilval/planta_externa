// main.dart
import 'package:flutter/material.dart';
import 'screens/welcome_page.dart';
import 'screens/planilla1.dart'; // Asegúrate de que esta ruta sea correcta
import 'screens/planilla2.dart';
import 'screens/planilla3.dart';

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
      home: const WelcomePage(),
      routes: {
        '/welcome': (context) => const WelcomePage(),
        '/planilla1': (context) => const FormularioPage(), // Planilla 1
        '/planilla2': (context) => const Planilla2Page(),
        '/planilla3': (context) => const Planilla3Page(),
      },
    );
  }
}