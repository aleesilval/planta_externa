// ignore_for_file: use_build_context_synchronously, prefer_const_constructors, sort_child_properties_last

import 'package:flutter/material.dart';
import 'package:planta_externa/screens/planilla2.dart';
import 'package:planta_externa/screens/planilla3.dart';
import 'package:planta_externa/screens/planilla1.dart';
import 'package:planta_externa/screens/autores_page.dart';
import 'package:planta_externa/screens/manual_page.dart';
import 'package:file_picker/file_picker.dart';
import 'package:geolocator/geolocator.dart';
import '../data/form_data_manager.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class WelcomePage extends StatefulWidget {
  const WelcomePage({super.key});

  @override
  State<WelcomePage> createState() => _WelcomePageState();
}

class _WelcomePageState extends State<WelcomePage> {
  int _selectedPlanilla = 1;
  final FormDataManager _dataManager = FormDataManager();
  String? _savePath;
  Position? _ubicacionActual;
  bool _obteniendoUbicacion = false;

  @override
  void initState() {
    super.initState();
    _loadSavePath();
  }

  void _loadSavePath() {
    final savedData = _dataManager.getPlanilla1Data();
    setState(() {
      _savePath = savedData['savePath'];
    });
  }

  Future<void> _obtenerUbicacion() async {
    setState(() {
      _obteniendoUbicacion = true;
    });
    
    try {
      final pos = await Geolocator.getCurrentPosition();
      setState(() {
        _ubicacionActual = pos;
        _obteniendoUbicacion = false;
      });
      
      await _showLocationOnMap(LatLng(pos.latitude, pos.longitude));

    } catch (e) {
      setState(() {
        _obteniendoUbicacion = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al obtener ubicación: $e')),
      );
    }
  }

  Future<void> _showLocationOnMap(LatLng location) async {
    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Ubicación Actual'),
          content: SizedBox(
            width: 320,
            height: 380,
            child: FlutterMap(
              options: MapOptions(
                initialCenter: location,
                initialZoom: 16,
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.example.planta_externa',
                ),
                MarkerLayer(
                  markers: [
                    Marker(
                      point: location,
                      width: 40,
                      height: 40,
                      child: const Icon(Icons.location_on, color: Colors.red, size: 40),
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cerrar'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _configureSavePath() async {
    String? selectedDirectory = await FilePicker.platform.getDirectoryPath();
    if (selectedDirectory != null) {
      setState(() {
        _savePath = selectedDirectory;
      });
      
      // Save to all planillas data
      final planilla1Data = _dataManager.getPlanilla1Data();
      planilla1Data['savePath'] = selectedDirectory;
      _dataManager.savePlanilla1Data(planilla1Data);
      
      final planilla2Data = _dataManager.getPlanilla2Data();
      planilla2Data['savePath'] = selectedDirectory;
      _dataManager.savePlanilla2Data(planilla2Data);
      
      final planilla3Data = _dataManager.getPlanilla3Data();
      planilla3Data['savePath'] = selectedDirectory;
      _dataManager.savePlanilla3Data(planilla3Data);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ruta de guardado configurada: $selectedDirectory')),
      );
    }
  }

  void _navigateToPlanilla(BuildContext context) {
    Widget page;
    switch (_selectedPlanilla) {
      case 1: page = const FormularioPage(); break;
      case 2: page =  Planilla2Page(); break;
      case 3: page = const Planilla3Page(); break;
      default: page = const FormularioPage();
    }
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => page));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 30, left: 16, right: 16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text('Bienvenido', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                        SizedBox(height: 8),
                        Text('Depto. Gestión Técnica\nPlanta Externa', style: TextStyle(fontSize: 16)),
                        SizedBox(height: 10),
                      ],
                    ),
                  ),
                  Image.asset(
                    'assets/images/LOGO_INTER.png',
                    height: 60,
                    errorBuilder: (context, error, stackTrace) {
                      return const Icon(Icons.image_not_supported, size: 60);
                    },
                  ),
                ],
              ),
            ),
            Center(
              child: DropdownButton<int>(
                value: _selectedPlanilla,
                items: const [
                  DropdownMenuItem(value: 1, child: Text('Auditoria de Mantenimiento ')),
                  DropdownMenuItem(value: 2, child: Text('Plantilla Certificacion de red')),
                  DropdownMenuItem(value: 3, child: Text('Informe de mantenimiento')),
                ],
                onChanged: (val) => setState(() => _selectedPlanilla = val ?? 1),
              ),
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: () => _navigateToPlanilla(context),
              child: const Text('Ir a la planilla'),
            ),
            const SizedBox(height: 30),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AutoresPage())),
                  child: const Text('Autores'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange[100],
                    foregroundColor: Colors.orange[800],
                  ),
                ),
                const SizedBox(width: 16),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ManualPage())),
                  child: const Text('Manual'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.purple[100],
                    foregroundColor: Colors.purple[800],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 30),
            Center(
              child: Column(
                children: [
                  ElevatedButton.icon(
                    icon: const Icon(Icons.folder_open),
                    label: const Text('Ajustar ruta de descarga'),
                    onPressed: _configureSavePath,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue[100],
                      foregroundColor: Colors.blue[800],
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    icon: _obteniendoUbicacion 
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.location_on),
                    label: const Text('Retornar geolocalización'),
                    onPressed: _obteniendoUbicacion ? null : _obtenerUbicacion,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green[100],
                      foregroundColor: Colors.green[800],
                    ),
                  ),
                  if (_savePath != null) ...[
                    const SizedBox(height: 8),
                    Text('Ruta actual: $_savePath', style: TextStyle(fontSize: 12, color: Colors.grey), textAlign: TextAlign.center),
                  ],
                  if (_ubicacionActual != null) ...[
                    const SizedBox(height: 8),
                    Text('Ubicación: ${_ubicacionActual!.latitude.toStringAsFixed(6)}, ${_ubicacionActual!.longitude.toStringAsFixed(6)}', style: TextStyle(fontSize: 12, color: Colors.grey), textAlign: TextAlign.center),
                  ],
                  const SizedBox(height: 20),
                  const Text('Alejandro Silva', style: TextStyle(color: Colors.grey, fontSize: 12), textAlign: TextAlign.center),
                  const Text('Edicxon Mendoza', style: TextStyle(color: Colors.grey, fontSize: 12), textAlign: TextAlign.center),
                  const SizedBox(height: 4),
                  const Text('Versión 1.0.0 - © 2025', style: TextStyle(color: Colors.grey, fontSize: 10, fontStyle: FontStyle.italic), textAlign: TextAlign.center),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
