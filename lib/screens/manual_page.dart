import 'package:flutter/material.dart';

class ManualPage extends StatelessWidget {
  const ManualPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manual'),
      ),
      body: const SingleChildScrollView(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
            Text(
              'Manual de Usuario',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 20),
            Text(
              'Esta pantalla será desarrollada próximamente',
              style: TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
            ],
          ),
        ),
      ),
    );
  }
}