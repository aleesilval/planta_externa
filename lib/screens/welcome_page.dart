import 'package:flutter/material.dart';
import 'package:planta_externa/screens/planilla2.dart';
import 'package:planta_externa/screens/planilla3.dart';
import 'package:planta_externa/screens/planilla1.dart';

class WelcomePage extends StatefulWidget {
  const WelcomePage({super.key});

  @override
  State<WelcomePage> createState() => _WelcomePageState();
}

class _WelcomePageState extends State<WelcomePage> {
  int _selectedPlanilla = 1;

  void _navigateToPlanilla(BuildContext context) {
    Widget page;
    switch (_selectedPlanilla) {
      case 1: page = const FormularioPage(); break;
      case 2: page = const Planilla2Page(); break;
      case 3: page = const Planilla3Page(); break;
      default: page = const FormularioPage();
    }
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => page));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Bienvenido')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Seleccione la planilla a utilizar',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            DropdownButton<int>(
              value: _selectedPlanilla,
              items: const [
                DropdownMenuItem(value: 1, child: Text('Planilla Principal')),
                DropdownMenuItem(value: 2, child: Text('Planilla Secundaria')),
                DropdownMenuItem(value: 3, child: Text('Planilla Tercera')),
              ],
              onChanged: (val) => setState(() => _selectedPlanilla = val ?? 1),
            ),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: () => _navigateToPlanilla(context),
              child: const Text('Ir a la planilla'),
            ),
          ],
        ),
      ),
    );
  }
}