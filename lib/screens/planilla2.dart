import 'package:flutter/material.dart';

class Planilla2Page extends StatefulWidget {
  const Planilla2Page({super.key});
  @override
  State<Planilla2Page> createState() => _Planilla2Page();
}

class _Planilla2Page extends State<Planilla2Page> {
  @override
/*************  ✨ Windsurf Command ⭐  *************/
  /// Builds a [Scaffold] with an [AppBar] and a centered [Text]
  /// widget. The [Text] widget displays the text 'Aquí irá la lógica
  /// y los campos de la Planilla 2' with a font size of 18.
/*******  d3db5b1f-c3b1-446f-9f9a-707b8582a389  *******/  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Planilla Secundaria')),
      body: Center(
        child: const Text(
          'Aquí irá la lógica y los campos de la Planilla 2',
          style: TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}