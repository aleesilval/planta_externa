import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AutoresPage extends StatefulWidget {
  const AutoresPage({super.key});

  @override
  State<AutoresPage> createState() => _AutoresPageState();
}

class _AutoresPageState extends State<AutoresPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Autores'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            const Center(
              child: Text(
                'Autores del Proyecto',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 30),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.person, color: Colors.blue, size: 24),
                        SizedBox(width: 8),
                        Text(
                          'Alejandro Silva',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Desarrollador Principal',
                      style: TextStyle(fontSize: 14, color: Colors.grey, fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Responsable del desarrollo de la aplicación, implementación de funcionalidades principales, arquitectura del sistema y integración de componentes.',
                      style: TextStyle(fontSize: 14),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const Icon(Icons.link, color: Colors.blue, size: 16),
                        const SizedBox(width: 4),
                        GestureDetector(
                          onTap: () {
                            Clipboard.setData(const ClipboardData(text: 'https://www.linkedin.com/in/aleesilval/'));
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('LinkedIn copiado al portapapeles')),
                            );
                          },
                          child: const Text(
                            'LinkedIn: aleesilval',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.blue,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.person, color: Colors.green, size: 24),
                        SizedBox(width: 8),
                        Text(
                          'Edicxon Mendoza',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Colaborador de Desarrollo',
                      style: TextStyle(fontSize: 14, color: Colors.grey, fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Contribución en el desarrollo de funcionalidades, testing, y mejoras en la experiencia de usuario.',
                      style: TextStyle(fontSize: 14),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const Icon(Icons.link, color: Colors.green, size: 16),
                        const SizedBox(width: 4),
                        GestureDetector(
                          onTap: () {
                            Clipboard.setData(const ClipboardData(text: 'https://www.linkedin.com/in/edicxon-jose-mendoza-carrasco-33850534a/'));
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('LinkedIn copiado al portapapeles')),
                            );
                          },
                          child: const Text(
                            'LinkedIn: Edicxon Mendoza',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.green,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 30),
            Card(
              color: Colors.grey[50],
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.orange, size: 24),
                        SizedBox(width: 8),
                        Text(
                          'Información del Proyecto',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Text('• Versión: 1.0.0', style: TextStyle(fontSize: 14)),
                    const SizedBox(height: 4),
                    const Text('• Fecha de desarrollo: 2025', style: TextStyle(fontSize: 14)),
                    const SizedBox(height: 4),
                    const Text('• Departamento: Gestión Técnica - Planta Externa', style: TextStyle(fontSize: 14)),
                    const SizedBox(height: 4),
                    const Text('• Tecnología: Flutter/Dart', style: TextStyle(fontSize: 14)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Center(
              child: Text(
                '© 2025 - Todos los derechos reservados',
                style: TextStyle(fontSize: 12, color: Colors.grey, fontStyle: FontStyle.italic),
              ),
            ),
            ],
          ),
        ),
      ),
    );
  }
}