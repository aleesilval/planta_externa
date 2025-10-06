import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:file_picker/file_picker.dart';
// ignore: unused_import
import 'dart:typed_data';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:archive/archive_io.dart';
import 'package:path_provider/path_provider.dart';
import '../data/form_data_manager.dart';

class Planilla3Page extends StatefulWidget {
  const Planilla3Page({super.key});
  @override
  State<Planilla3Page> createState() => _Planilla3PageState();
}

class _Planilla3PageState extends State<Planilla3Page> {
  // Campos básicos copiados de planilla2
  final TextEditingController _tecnicoController = TextEditingController();
  final TextEditingController _unidadNegocioController = TextEditingController();
  final DateTime _fechaActual = DateTime.now();
  Position? _ubicacionActual;

  // Nomenclatura
  final TextEditingController _nomenclaturaController = TextEditingController();

  // === CAMPOS PARA EL REPORTE ===
  final TextEditingController _tiempoAtencionController = TextEditingController();
  final TextEditingController _afectacionController = TextEditingController();
  final TextEditingController _direccionCortaController = TextEditingController();
  final TextEditingController _accionesRealizadasController = TextEditingController();
  final List<String> _soluciones = [];
  final TextEditingController _nuevaSolucionController = TextEditingController();
  final TextEditingController _conclusionesController = TextEditingController();
  
  // Evidencia fotográfica
  final List<Map<String, dynamic>> _evidenciaFotografica = [];
  final TextEditingController _descripcionFotoController = TextEditingController();
  
  // Trazas OTDR
  PlatformFile? _archivoOTDR;
  
  // Materiales utilizados
  final List<Map<String, String>> _materiales = [];
  final TextEditingController _codigoController = TextEditingController();
  final TextEditingController _materialController = TextEditingController();
  String? _unidadSeleccionada;
  final TextEditingController _cantidadController = TextEditingController();
  String? _descripcionSeleccionada;
  
  // Mediciones (16 puertos) - doble tabla para 1550nm y 1490nm
  final List<TextEditingController> _medicionesPuertos1550 = List.generate(16, (i) => TextEditingController());
  final List<TextEditingController> _medicionesPuertos1490 = List.generate(16, (i) => TextEditingController());
  
  // Tabla de artículos predefinida
  final FormDataManager _dataManager = FormDataManager();
  
  static const Map<String, String> _tablaArticulos = {
    '1001001': 'POSTE C.METAL 2 SECCIONES / 4 1/2" - 3 1/2" / 7 M',
    '1001005': 'POSTE 3 SECCIONES 5 1/2" 4 1/2" 3 1/2" 9 MTS',
    '1001008': 'POSTE 12,2 MTS TRES SECCIONES (6 5/8" - 5 1/2" - 4 1/2")',
    '1105029': 'FIBRA ÓPTICA ADSS C/TUBOS SEPARADORES – 144 FIBRAS',
    '1105034': 'FIBRA 12 HILOS HIBRIDA 12H G652 12H G655 ADSS CON BUFFER ANTIOEDOR SPAN 150M',
    '1105035': 'FIBRA 48 HILOS ADSS CON BUFFER ANTIOEDOR SPAN 150M',
    '1105044': 'FIBRA 48 HILOS HIBRIDA 24H G652 24H G655 ADSS CON BUFFER ANTIOEDOR SPAN 150M',
    '1925002': 'PINTURA BASE ACEITE NEGRO BRILLANTE P/POSTE (GALON)',
    '3502001': 'CAJAS NAP 8 PUERTOS NEGRA 2 BROCHES',
    '3502002': 'SPLITTERS 1:4 SIN CONECTORIZAR',
    '3502003': 'SPLITTERS 1:8 CON CONECTORES',
    '3502008': 'SPLITTERS 1:8 SIN CONECTORES',
    '3502009': 'FIBRA 4 HILOS BLINDADA ANTI RAT PLANA CON BUFFER',
    '3502012': 'FIBRA 144 HILOS BLINDADA ANTI RAT ADSS CON BUFFER',
    '3502013': 'CAJA DE EMPALME DE 288 FIBRAS',
    '3502014': 'CAJAS DE TERMINACIÓN 16 PUERTOS NEGRA 2 BROCHES IP65 (PARA CABLE PLANO)',
    '3502015': 'CAJAS DE TERMINACIÓN 16 PUERTOS NEGRA 2 BROCHES IP67 (DENTRO TANQUILLAS CABLE P)',
    '3502017': 'SOPORTE RETENCIÓN (FO 12)',
    '3502018': 'SOPORTE RETENCIÓN (FO 144)',
    '3502019': 'SOPORTE DIRECTO SUSPENSION HC 8-12 (FO12)',
    '3502020': 'SOPORTE DIRECTO SUASPENSION HC 10-15 (FO144)',
    '3502021': 'TENSOR FIBRA PLANA',
    '3502024': 'SPLITTERS 1:4 CON CONECTORES',
    '3502026': 'CAJA DE EMPALME 144 FUSIONES',
    '3502032': 'FIBRA 96 HILOS ADSS C/BUFFER ANTIOEDOR SPAN 200M',
    '3502035': 'SPLITTERS 1:16 SC/APC PLC CON CONECTORES',
    '3502039': 'FIBRA 144 HILOS ADSS ARAMIDA YARN SIN GLASS YARN',
    '3502040': 'FIBRA 12 HILOS ADSS ARAMIDA YARN SIN GLASS YARN',
    '3502043': 'PEDESTAL PARA NAP 16 PUERTOS INCLUYE ACC DE FIJACION',
    '3502053': 'TENSOR FIBRA PLANA PLASTICO',
  };

  @override
  void initState() {
    super.initState();
    _obtenerUbicacion();
    _loadSavedData();
  }
  
  void _loadSavedData() {
    final savedData = _dataManager.getPlanilla3Data();
    if (savedData.isNotEmpty) {
      setState(() {
        _tecnicoController.text = savedData['tecnico'] ?? '';
        _unidadNegocioController.text = savedData['unidadNegocio'] ?? '';
        _nomenclaturaController.text = savedData['nomenclatura'] ?? '';
        _tiempoAtencionController.text = savedData['tiempoAtencion'] ?? '';
        _afectacionController.text = savedData['afectacion'] ?? '';
        _direccionCortaController.text = savedData['direccionCorta'] ?? '';
        _accionesRealizadasController.text = savedData['accionesRealizadas'] ?? '';
        _conclusionesController.text = savedData['conclusiones'] ?? '';
        if (savedData['soluciones'] != null) {
          _soluciones.clear();
          _soluciones.addAll(List<String>.from(savedData['soluciones']));
        }
        if (savedData['materiales'] != null) {
          _materiales.clear();
          _materiales.addAll(List<Map<String, String>>.from(savedData['materiales']));
        }
        if (savedData['medicionesPuertos1550'] != null) {
          final l1550 = List<String>.from(savedData['medicionesPuertos1550']);
          for (int i = 0; i < 16; i++) {
            _medicionesPuertos1550[i].text = i < l1550.length ? l1550[i] : '';
          }
        }
        if (savedData['medicionesPuertos1490'] != null) {
          final l1490 = List<String>.from(savedData['medicionesPuertos1490']);
          for (int i = 0; i < 16; i++) {
            _medicionesPuertos1490[i].text = i < l1490.length ? l1490[i] : '';
          }
        }
      });
    }
  }
  
  void _guardarDatos() {
    final dataToSave = {
      'tecnico': _tecnicoController.text,
      'unidadNegocio': _unidadNegocioController.text,
      'nomenclatura': _nomenclaturaController.text,
      'tiempoAtencion': _tiempoAtencionController.text,
      'afectacion': _afectacionController.text,
      'direccionCorta': _direccionCortaController.text,
      'accionesRealizadas': _accionesRealizadasController.text,
      'conclusiones': _conclusionesController.text,
      'soluciones': List.from(_soluciones),
      'materiales': List.from(_materiales),
      'medicionesPuertos1550': _medicionesPuertos1550.map((c) => c.text).toList(),
      'medicionesPuertos1490': _medicionesPuertos1490.map((c) => c.text).toList(),
    };
    
    _dataManager.savePlanilla3Data(dataToSave);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Datos guardados exitosamente')),
    );
  }
  
  void _onDescripcionChanged(String? descripcion) {
    if (descripcion != null) {
      final codigo = _tablaArticulos.entries
          .firstWhere((entry) => entry.value == descripcion, orElse: () => const MapEntry('', ''))
          .key;
      _codigoController.text = codigo;
    }
  }

  Future<void> _obtenerUbicacion() async {
    try {
      final pos = await Geolocator.getCurrentPosition();
      setState(() {
        _ubicacionActual = pos;
      });
    } catch (e) {
      // Ignore location errors
    }
  }

  /// Exporta PDF con formato específico de bitácora
  Future<void> _exportarPDFBitacora() async {
    try {
      final pdf = pw.Document();
      final fechaFormateada = "${_fechaActual.day.toString().padLeft(2, '0')}/${_fechaActual.month.toString().padLeft(2, '0')}/${_fechaActual.year}";
      
      // Load logo image with error handling
      Uint8List? logoBytes;
      try {
        logoBytes = (await rootBundle.load('assets/images/header_logo.png')).buffer.asUint8List();
      } catch (e) {
        // Continue without logo if it fails to load
      }
      
      // Cargar logo como marca de agua
      pw.ImageProvider? logoImage;
      try {
        final logoWatermarkBytes = await rootBundle.load('assets/images/LOGO_INTER.png');
        logoImage = pw.MemoryImage(logoWatermarkBytes.buffer.asUint8List());
      } catch (_) {
        logoImage = null;
      }
    
    // Página 1: Portada
    pdf.addPage(
      pw.Page(
        build: (pw.Context context) {
          return pw.Stack(
            children: [
              // Marca de agua centrada
              if (logoImage != null)
                pw.Center(
                  child: pw.Opacity(
                    opacity: 0.1,
                    child: pw.Image(logoImage, width: 300, height: 300),
                  ),
                ),
              // Contenido principal
              pw.Column(
                children: [
                  // Header con logo fijo
                  if (logoBytes != null)
                    pw.Container(
                      height: 80,
                      width: double.infinity,
                      child: pw.Image(pw.MemoryImage(logoBytes)),
                    ),
                  pw.SizedBox(height: 20),
                  pw.Expanded(
                    child: pw.Center(
                      child: pw.Text(
                        'Informe de Reparación ${_afectacionController.text} - ${_nomenclaturaController.text} - ${_direccionCortaController.text}',
                        style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold),
                        textAlign: pw.TextAlign.center,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );

      await Printing.layoutPdf(
        onLayout: (format) async => pdf.save(),
      );
      
      // Limpiar todos los datos después de exportar
      setState(() {
        _tecnicoController.clear();
        _unidadNegocioController.clear();
        _nomenclaturaController.clear();
        _tiempoAtencionController.clear();
        _afectacionController.clear();
        _direccionCortaController.clear();
        _accionesRealizadasController.clear();
        _soluciones.clear();
        _nuevaSolucionController.clear();
        _conclusionesController.clear();
        _descripcionFotoController.clear();
        _evidenciaFotografica.clear();

        _materiales.clear();
        _codigoController.clear();
        _descripcionSeleccionada = null;
        _unidadSeleccionada = null;
        _cantidadController.clear();
        for (final c in _medicionesPuertos1550) { c.clear(); }
        for (final c in _medicionesPuertos1490) { c.clear(); }
      });
    } catch (e) {
      // Show error message if PDF generation fails
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al generar PDF: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Generar informe de mantenimiento correctivo'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _guardarDatos,
            tooltip: 'Guardar datos',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            ElevatedButton.icon(
              icon: const Icon(Icons.picture_as_pdf),
              label: const Text("EXPORTAR PDF"),
              onPressed: _exportarPDFBitacora,
            ),
            const SizedBox(height: 50),
          ],
        ),
      ),
    );
  }
}