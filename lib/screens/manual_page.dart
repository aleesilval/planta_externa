import 'package:flutter/material.dart';
import 'package:planta_externa/screens/pdf_viewer_page.dart';

class ManualPage extends StatelessWidget {
  const ManualPage({super.key});

  void _openPdf(BuildContext context, String assetPath, String title) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PdfViewerPage(assetPath: assetPath, title: title),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manual'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Manuales de Usuario',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              icon: const Icon(Icons.menu_book),
              label: const Text('Manual Técnico'),
              onPressed: () => _openPdf(
                context,
                'assets/manuals/manual_tecnico.pdf',
                'Manual Técnico',
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              icon: const Icon(Icons.menu_book),
              label: const Text('Manual Operativo'),
              onPressed: () => _openPdf(
                context,
                'assets/manuals/manual_operativo.pdf',
                'Manual Operativo',
              ),
            ),
          ],
        ),
      ),
    );
  }
}