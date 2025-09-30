import 'package:flutter/material.dart';
import 'screens/welcome_page.dart';

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
    );
  }
}