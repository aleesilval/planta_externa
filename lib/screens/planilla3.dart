import 'package:flutter/material.dart';

class Planilla3Page extends StatefulWidget {
  const Planilla3Page({super.key});
  @override
  State<Planilla3Page> createState() => _Planilla3PageState();
}

class _Planilla3PageState extends State<Planilla3Page> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Planilla Tercera')),
      body: Center(
        child: const Text(
          'Aquí irá la lógica y los campos de la Planilla 3',
          style: TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}