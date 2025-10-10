// ignore_for_file: unnecessary_import, use_build_context_synchronously, deprecated_member_use, unused_import, duplicate_ignore

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:planta_externa/screens/report_logic.dart';
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
  final TextEditingController _nomenclaturaMedicionController = TextEditingController();
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
    '1911006': 'TERMOCONTRAIBLES DESARTICULADOS P/FUSION DE F.O.',
    '1931001': 'PRECINTO SUJETADOR DE FIBRA OPTICA',
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
        _nomenclaturaMedicionController.text = savedData['nomenclaturaMedicion'] ?? '';
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

        // Cargar archivos
        if (savedData['evidenciaFotografica'] != null) {
          _evidenciaFotografica.clear();
          for (var item in (savedData['evidenciaFotografica'] as List<dynamic>)) {
            final fileData = item['foto'] as Map<String, dynamic>;
            final file = PlatformFile(name: fileData['name'], path: fileData['path'], size: fileData['size']);
            _evidenciaFotografica.add({
              'foto': file,
              'bytes': null, // Se cargará bajo demanda
              'descripcion': item['descripcion'],
            });
          }
        }
        if (savedData['archivoOTDR'] != null) {
          final otdrData = savedData['archivoOTDR'] as Map<String, dynamic>;
          _archivoOTDR = PlatformFile(
            name: otdrData['name'],
            path: otdrData['path'],
            size: otdrData['size'],
          );
        }
      });
    }
  }
  
  Future<void> _guardarDatos() async {
    // 1. Crear directorio temporal para esta planilla si no existe
    final tempDir = await getTemporaryDirectory();
    final planillaDir = Directory('${tempDir.path}/planilla3_files');
    if (!await planillaDir.exists()) {
      await planillaDir.create();
    }

    // 2. Copiar fotos y guardar sus nuevas rutas
    List<Map<String, dynamic>> evidenciaParaGuardar = [];
    for (var evidencia in _evidenciaFotografica) {
      final file = evidencia['foto'] as PlatformFile;
      Map<String, dynamic> newEvidencia = {'descripcion': evidencia['descripcion']};
      if (file.path != null && !file.path!.startsWith(planillaDir.path)) {
        final newPath = '${planillaDir.path}/${DateTime.now().millisecondsSinceEpoch}_${file.name}';
        await File(file.path!).copy(newPath);
        newEvidencia['foto'] = {'name': file.name, 'path': newPath, 'size': file.size};
      } else if (file.path != null) { // Ya está en la carpeta temporal
        newEvidencia['foto'] = {'name': file.name, 'path': file.path, 'size': file.size};
      }
      evidenciaParaGuardar.add(newEvidencia);
    }

    // 3. Copiar archivo OTDR y guardar su nueva ruta
    Map<String, dynamic>? otdrParaGuardar;
    if (_archivoOTDR != null && _archivoOTDR!.path != null && !_archivoOTDR!.path!.startsWith(planillaDir.path)) {
        final newPath = '${planillaDir.path}/${DateTime.now().millisecondsSinceEpoch}_${_archivoOTDR!.name}';
        await File(_archivoOTDR!.path!).copy(newPath);
        otdrParaGuardar = {'name': _archivoOTDR!.name, 'path': newPath, 'size': _archivoOTDR!.size};
    } else if (_archivoOTDR != null && _archivoOTDR!.path != null) { // Ya está en la carpeta temporal
        otdrParaGuardar = {'name': _archivoOTDR!.name, 'path': _archivoOTDR!.path, 'size': _archivoOTDR!.size};
    }

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
      'nomenclaturaMedicion': _nomenclaturaMedicionController.text,
      'medicionesPuertos1550': _medicionesPuertos1550.map((c) => c.text).toList(),
      'medicionesPuertos1490': _medicionesPuertos1490.map((c) => c.text).toList(),
      'evidenciaFotografica': evidenciaParaGuardar,
      'archivoOTDR': otdrParaGuardar,
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
    
    // Página 2: Bitácora
    pdf.addPage(
      pw.Page(
        build: (pw.Context context) {
          return pw.Stack(
            children: [
              if (logoImage != null)
                pw.Center(
                  child: pw.Opacity(
                    opacity: 0.1,
                    child: pw.Image(logoImage, width: 300, height: 300),
                  ),
                ),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('Fecha: $fechaFormateada'),
                  pw.SizedBox(height: 8),
                  pw.Text('Responsable: ${_tecnicoController.text}'),
                  pw.SizedBox(height: 8),
                  pw.Text('Ubicación: ${_ubicacionActual != null ? "${_ubicacionActual!.latitude}, ${_ubicacionActual!.longitude}" : "No disponible"}'),
                  pw.SizedBox(height: 8),
                  pw.Text('Tiempo de atención: ${_tiempoAtencionController.text}'),
                  pw.SizedBox(height: 8),
                  pw.Text('Bitácora:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                  pw.SizedBox(height: 4),
                  pw.Text('El día $fechaFormateada se presenta ${_afectacionController.text} en ${_direccionCortaController.text}'),
                  pw.SizedBox(height: 8),
                  pw.Text(_accionesRealizadasController.text),
                  pw.SizedBox(height: 8),
                  pw.Text('Solución:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                  pw.SizedBox(height: 4),
                  ..._soluciones.asMap().entries.map((entry) => pw.Text('${entry.key + 1}. ${entry.value}')),
                  pw.SizedBox(height: 8),
                  pw.Text('Conclusiones:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                  pw.SizedBox(height: 4),
                  pw.Text(_conclusionesController.text),
                ],
              ),
            ],
          );
        },
      ),
    );
    
    // Página 3: Materiales utilizados
    if (_materiales.isNotEmpty) {
      pdf.addPage(
        pw.Page(
          build: (pw.Context context) {
            return pw.Stack(
              children: [
                if (logoImage != null)
                  pw.Center(
                    child: pw.Opacity(
                      opacity: 0.1,
                      child: pw.Image(logoImage, width: 300, height: 300),
                    ),
                  ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('Materiales Utilizados', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
                    pw.SizedBox(height: 16),
                    pw.Table(
                      border: pw.TableBorder.all(),
                      children: [
                        pw.TableRow(
                          children: [
                            pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text('Artículo', style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
                            pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text('Descripción del Artículo', style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
                            pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text('Unidades', style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
                            pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text('Cantidad', style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
                          ],
                        ),
                        ..._materiales.map((material) => pw.TableRow(
                          children: [
                            pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text(material['codigo'] ?? '')),
                            pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text(material['material'] ?? '')),
                            pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text(material['unidades'] ?? '')),
                            pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text(material['cantidad'] ?? '')),
                          ],
                        )),
                      ],
                    ),
                  ],
                ),
              ],
            );
          },
        ),
      );
    }
    
    // Página 4: Mediciones
    bool hasMeasurements = _medicionesPuertos1550.any((c) => c.text.isNotEmpty) || _medicionesPuertos1490.any((c) => c.text.isNotEmpty);
    if (hasMeasurements) {
      pdf.addPage(
        pw.Page(
          build: (pw.Context context) {
            return pw.Stack(
              children: [
                if (logoImage != null)
                  pw.Center(
                    child: pw.Opacity(
                      opacity: 0.1,
                      child: pw.Image(logoImage, width: 300, height: 300),
                    ),
                  ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('Mediciones', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
                    pw.SizedBox(height: 16),
                    if (_nomenclaturaMedicionController.text.isNotEmpty) ...[
                      pw.Text('Elemento inspeccionado: ${_nomenclaturaMedicionController.text}',
                          style: pw.TextStyle(fontSize: 12, fontStyle: pw.FontStyle.italic)),
                      pw.SizedBox(height: 12),
                    ],
                    pw.Text('Mediciones 1550nm:', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
                    pw.SizedBox(height: 8),
                    pw.Table(
                      border: pw.TableBorder.all(),
                      children: [
                        for (int i = 0; i < 16; i += 4)
                          pw.TableRow(
                            children: [
                              for (int j = 0; j < 4; j++)
                                pw.Padding(
                                  padding: const pw.EdgeInsets.all(4),
                                  child: pw.Text('P${i + j + 1}: ${_medicionesPuertos1550[i + j].text} dBm', style: const pw.TextStyle(fontSize: 10)),
                                ),
                            ],
                          ),
                      ],
                    ),
                    pw.SizedBox(height: 16),
                    pw.Text('Mediciones 1490nm:', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
                    pw.SizedBox(height: 8),
                    pw.Table(
                      border: pw.TableBorder.all(),
                      children: [
                        for (int i = 0; i < 16; i += 4)
                          pw.TableRow(
                            children: [
                              for (int j = 0; j < 4; j++)
                                pw.Padding(
                                  padding: const pw.EdgeInsets.all(4),
                                  child: pw.Text('P${i + j + 1}: ${_medicionesPuertos1490[i + j].text} dBm', style: const pw.TextStyle(fontSize: 10)),
                                ),
                            ],
                          ),
                      ],
                    ),
                  ],
                ),
              ],
            );
          },
        ),
      );
    }
    
    // Página 5: Evidencia fotográfica
    if (_evidenciaFotografica.isNotEmpty) {
      const int fotosPorPagina = 2;
      final fotos = _evidenciaFotografica;
      for (int i = 0; i < fotos.length; i += fotosPorPagina) {
        final fotosPagina = fotos.sublist(i, (i + fotosPorPagina > fotos.length) ? fotos.length : i + fotosPorPagina);
        pdf.addPage(
          pw.Page(
            build: (pw.Context context) {
              return pw.Stack(
                children: [
                  if (logoImage != null)
                    pw.Center(
                      child: pw.Opacity(
                        opacity: 0.1,
                        child: pw.Image(logoImage, width: 300, height: 300),
                      ),
                    ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('Evidencia Fotográfica', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
                      pw.SizedBox(height: 16),
                      ...fotosPagina.map((foto) {
                        final bytes = foto['bytes'] as Uint8List?;
                        return pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            if (bytes != null)
                              pw.Container(
                                height: 200,
                                width: double.infinity,
                                child: pw.Image(pw.MemoryImage(bytes)),
                              )
                            else
                              pw.Container(
                                height: 200,
                                width: double.infinity,
                                decoration: pw.BoxDecoration(border: pw.Border.all()),
                                child: pw.Center(child: pw.Text('Sin imagen disponible')),
                              ),
                            pw.SizedBox(height: 8),
                            pw.Text('Descripción: ${foto['descripcion']}'),
                            pw.SizedBox(height: 16),
                          ],
                        );
                      }),
                    ],
                  ),
                ],
              );
            },
          ),
        );
      }
    }

      await Printing.layoutPdf(
        onLayout: (format) async => pdf.save(),
      );
    } catch (e) {
      // Show error message if PDF generation fails
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al generar PDF: $e')),
        );
      }
    }
  }
  
  Future<void> _adjuntarFoto() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      type: FileType.image,
    );
    if (result != null && _descripcionFotoController.text.isNotEmpty) {
      for (final file in result.files) {
        Uint8List? bytes = file.bytes;
        String? filePath = file.path;

        if (bytes == null && file.path != null) {
          bytes = await File(file.path!).readAsBytes();
        }

        // Si es una foto de la cámara en web, no tendrá path.
        // En este caso, guardamos los bytes directamente.
        // En móvil, siempre tendremos un path.
        if (filePath == null && bytes != null) {
          // Podríamos guardarlo en un archivo temporal si quisiéramos ser consistentes
          // pero por ahora, lo mantenemos en memoria para este caso.
        }

        setState(() {
          _evidenciaFotografica.add({
            'foto': file,
            'bytes': bytes,
            'descripcion': _descripcionFotoController.text,
          });
        });
      }
      _descripcionFotoController.clear();
    } else if (_descripcionFotoController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor ingrese una descripción')),
      );
    }
  }
  
  Future<void> _seleccionarArchivoOTDR() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      allowMultiple: false,
      type: FileType.any,
    );
    if (result != null) {
      setState(() {
        _archivoOTDR = result.files.first;
      });
    }
  }
  
  Future<void> _generarZIP() async {
    String? selectedDirectory = await FilePicker.platform.getDirectoryPath();
    if (selectedDirectory == null) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Generación cancelada')));
      return;
    }

    try {
      final pdf = await _generarPDF();

      Map<String, List<PlatformFile>> fotosPorSeccion = {
        'Evidencia': _evidenciaFotografica.map((e) => e['foto'] as PlatformFile).toList()
      };

      final success = await generateAndCompressReport(
        instalador: _tecnicoController.text,
        fecha: _fechaActual,
        ubicacion: _ubicacionActual,
        unidadNegocio: _unidadNegocioController.text,
        elemento: "Mantenimiento", // Elemento fijo para esta planilla
        closureNaturaleza: null,
        fdtConClosureSecundario: null,
        campos: {}, // No aplica campos dinámicos de nomenclatura
        feeder: "-", // No aplica
        buffer: "-", // No aplica
        nomenclatura: _nomenclaturaController.text,
        fotosPorSeccion: fotosPorSeccion,
        archivoOtdr: _archivoOTDR,
        context: context,
        savePath: selectedDirectory,
        pdfDocument: pdf,
        datosTecnicos: null, // No aplica
        mediciones: null, // No aplica
        distribucionBuffers: null, // No aplica
      );

      if (mounted) {
        if (success) {
          final safeNomenclatura = _nomenclaturaController.text.isNotEmpty ? _nomenclaturaController.text.replaceAll(RegExp(r'[<>:"/\\|?*\x00-\x1F\s]'), '_') : 'reporte';
          // El nombre se construye en report_logic.dart como 'feeder-buffer-nomenclatura'.
          final zipName = '---$safeNomenclatura.zip';
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Archivo $zipName generado exitosamente en:\n$selectedDirectory'),
              duration: const Duration(seconds: 5),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Error: No se pudo generar el archivo comprimido')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al generar ZIP: $e')),
        );
      }
    }
  }
  
  Future<pw.Document> _generarPDF() async {
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
              if (logoImage != null)
                pw.Center(
                  child: pw.Opacity(
                    opacity: 0.1,
                    child: pw.Image(logoImage, width: 300, height: 300),
                  ),
                ),
              pw.Column(
                children: [
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
    
    // Página 2: Bitácora
    pdf.addPage(
      pw.Page(
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('Fecha: $fechaFormateada'),
              pw.SizedBox(height: 8),
              pw.Text('Responsable: ${_tecnicoController.text}'),
              pw.SizedBox(height: 8),
              pw.Text('Ubicación: ${_ubicacionActual != null ? "${_ubicacionActual!.latitude}, ${_ubicacionActual!.longitude}" : "No disponible"}'),
              pw.SizedBox(height: 8),
              pw.Text('Tiempo de atención: ${_tiempoAtencionController.text}'),
              pw.SizedBox(height: 8),
              pw.Text('Bitácora:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 4),
              pw.Text('El día $fechaFormateada se presenta ${_afectacionController.text} en ${_direccionCortaController.text}'),
              pw.SizedBox(height: 8),
              pw.Text(_accionesRealizadasController.text),
              pw.SizedBox(height: 8),
              pw.Text('Solución:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 4),
              ..._soluciones.asMap().entries.map((entry) => pw.Text('${entry.key + 1}. ${entry.value}')),
              pw.SizedBox(height: 8),
              pw.Text('Conclusiones:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 4),
              pw.Text(_conclusionesController.text),
            ],
          );
        },
      ),
    );
    
    // Página 3: Materiales utilizados
    if (_materiales.isNotEmpty) {
      pdf.addPage(
        pw.Page(
          build: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('Materiales Utilizados', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 16),
                pw.Table(
                  border: pw.TableBorder.all(),
                  children: [
                    pw.TableRow(
                      children: [
                        pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text('Artículo', style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
                        pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text('Descripción del Artículo', style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
                        pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text('Unidades', style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
                        pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text('Cantidad', style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
                      ],
                    ),
                    ..._materiales.map((material) => pw.TableRow(
                      children: [
                        pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text(material['codigo'] ?? '')),
                        pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text(material['material'] ?? '')),
                        pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text(material['unidades'] ?? '')),
                        pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text(material['cantidad'] ?? '')),
                      ],
                    )),
                  ],
                ),
              ],
            );
          },
        ),
      );
    }
    
    // Página 4: Mediciones
    bool hasMeasurements = _medicionesPuertos1550.any((c) => c.text.isNotEmpty) || _medicionesPuertos1490.any((c) => c.text.isNotEmpty);
    if (hasMeasurements) {
      pdf.addPage(
        pw.Page(
          build: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('Mediciones', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 16),
                if (_nomenclaturaMedicionController.text.isNotEmpty) ...[
                  pw.Text('Elemento inspeccionado: ${_nomenclaturaMedicionController.text}',
                      style: pw.TextStyle(fontSize: 12, fontStyle: pw.FontStyle.italic)),
                  pw.SizedBox(height: 12),
                ],
                pw.Text('Mediciones 1550nm:', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 8),
                pw.Table(
                  border: pw.TableBorder.all(),
                  children: [
                    for (int i = 0; i < 16; i += 4)
                      pw.TableRow(
                        children: [
                          for (int j = 0; j < 4; j++)
                            pw.Padding(
                              padding: const pw.EdgeInsets.all(4),
                              child: pw.Text('P${i + j + 1}: ${_medicionesPuertos1550[i + j].text} dBm', style: const pw.TextStyle(fontSize: 10)),
                            ),
                        ],
                      ),
                  ],
                ),
                pw.SizedBox(height: 16),
                pw.Text('Mediciones 1490nm:', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 8),
                pw.Table(
                  border: pw.TableBorder.all(),
                  children: [
                    for (int i = 0; i < 16; i += 4)
                      pw.TableRow(
                        children: [
                          for (int j = 0; j < 4; j++)
                            pw.Padding(
                              padding: const pw.EdgeInsets.all(4),
                              child: pw.Text('P${i + j + 1}: ${_medicionesPuertos1490[i + j].text} dBm', style: const pw.TextStyle(fontSize: 10)),
                            ),
                        ],
                      ),
                  ],
                ),
              ],
            );
          },
        ),
      );
    }
    
    // Página 5: Evidencia fotográfica
    if (_evidenciaFotografica.isNotEmpty) {
      const int fotosPorPagina = 2;
      final fotos = _evidenciaFotografica;
      for (int i = 0; i < fotos.length; i += fotosPorPagina) {
        final fotosPagina = fotos.sublist(i, (i + fotosPorPagina > fotos.length) ? fotos.length : i + fotosPorPagina);
        pdf.addPage(
          pw.Page(
            build: (pw.Context context) {
              return pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('Evidencia Fotográfica', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
                  pw.SizedBox(height: 16),
                  ...fotosPagina.map((foto) {
                    final bytes = foto['bytes'] as Uint8List?;
                    return pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        if (bytes != null)
                          pw.Container(
                            height: 200,
                            width: double.infinity,
                            child: pw.Image(pw.MemoryImage(bytes)),
                          )
                        else
                          pw.Container(
                            height: 200,
                            width: double.infinity,
                            decoration: pw.BoxDecoration(border: pw.Border.all()),
                            child: pw.Center(child: pw.Text('Sin imagen disponible')),
                          ),
                        pw.SizedBox(height: 8),
                        pw.Text('Descripción: ${foto['descripcion']}'),
                        pw.SizedBox(height: 16),
                      ],
                    );
                  }),
                ],
              );
            },
          ),
        );
      }
    }
    
    return pdf;
  }
  
  Future<void> _limpiarCampos() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar'),
        content: const Text('¿Está seguro de que desea limpiar todos los campos?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Limpiar'),
          ),
        ],
      ),
    );
    
    if (confirmed == true) {
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
        _archivoOTDR = null;

        _materiales.clear();
        _codigoController.clear();
        _descripcionSeleccionada = null;
        _unidadSeleccionada = null;
        _cantidadController.clear();
        _nomenclaturaMedicionController.clear();
        for (final c in _medicionesPuertos1550) { c.clear(); }
        for (final c in _medicionesPuertos1490) { c.clear(); }
      });
      
      await _limpiarArchivosTemporalesPlanilla3();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Campos limpiados')),
      );
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
          IconButton(
            tooltip: "Limpiar todo",
            icon: const Icon(Icons.cleaning_services),
            onPressed: _limpiarCampos,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // === CAMPOS BÁSICOS ===
            TextField(
              controller: _tecnicoController,
              decoration: const InputDecoration(
                labelText: "Técnico",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _unidadNegocioController,
              decoration: const InputDecoration(
                labelText: "Unidad de Negocios",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            Text("Fecha actual: ${_fechaActual.toLocal()}"),
            const SizedBox(height: 8),
            Text("Ubicación: ${_ubicacionActual != null ? "${_ubicacionActual!.latitude}, ${_ubicacionActual!.longitude}" : "Obteniendo..."}"),
            const SizedBox(height: 16),

            // === IDENTIFICADOR DE RED ===
            TextField(
              controller: _nomenclaturaController,
              decoration: const InputDecoration(
                labelText: "Identificador de red",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),

            // === CAMPOS PARA EL REPORTE ===
            const Text("Información del Reporte", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            TextField(
              controller: _tiempoAtencionController,
              decoration: const InputDecoration(
                labelText: "Tiempo de Atención",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _afectacionController,
              decoration: const InputDecoration(
                labelText: "Afectación",
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
              keyboardType: TextInputType.multiline,
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _direccionCortaController,
              decoration: const InputDecoration(
                labelText: "Dirección Corta",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _accionesRealizadasController,
              decoration: const InputDecoration(
                labelText: "Acciones Realizadas",
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
              keyboardType: TextInputType.multiline,
            ),
            const SizedBox(height: 8),
            // Lista de Soluciones
            const Text("Soluciones", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _nuevaSolucionController,
                    decoration: const InputDecoration(
                      labelText: "Agregar solución",
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () {
                    if (_nuevaSolucionController.text.isNotEmpty) {
                      setState(() {
                        _soluciones.add(_nuevaSolucionController.text);
                        _nuevaSolucionController.clear();
                      });
                    }
                  },
                  child: const Text("Agregar"),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ..._soluciones.asMap().entries.map((entry) => ListTile(
              title: Text("${entry.key + 1}. ${entry.value}"),
              trailing: IconButton(
                icon: const Icon(Icons.delete),
                onPressed: () {
                  setState(() {
                    _soluciones.removeAt(entry.key);
                  });
                },
              ),
            )),
            const SizedBox(height: 8),
            TextField(
              controller: _conclusionesController,
              decoration: const InputDecoration(
                labelText: "Conclusiones",
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
              keyboardType: TextInputType.multiline,
            ),
            
            const SizedBox(height: 16),
            // === MATERIALES UTILIZADOS ===
            const Text("Materiales Utilizados", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  SizedBox(
                    width: 120,
                    child: TextField(
                      controller: _codigoController,
                      enabled: _descripcionSeleccionada == "Otro",
                      decoration: const InputDecoration(
                        labelText: "Artículo",
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 200,
                    child: _descripcionSeleccionada == "Otro" 
                      ? TextField(
                          controller: _materialController,
                          decoration: const InputDecoration(
                            labelText: "Descripción del Artículo",
                            border: OutlineInputBorder(),
                          ),
                        )
                      : DropdownButtonFormField<String>(
                          initialValue: _descripcionSeleccionada,
                          items: [
                            ..._tablaArticulos.values.map((descripcion) => 
                              DropdownMenuItem(
                                value: descripcion, 
                                child: SizedBox(
                                  width: double.infinity,
                                  child: Text(
                                    descripcion,
                                    style: const TextStyle(fontSize: 12),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                )
                              )
                            ),
                            const DropdownMenuItem(
                              value: "Otro", 
                              child: Text("Otro", style: TextStyle(fontSize: 12))
                            ),
                          ],
                          selectedItemBuilder: (BuildContext context) {
                            return [
                              ..._tablaArticulos.values.map((descripcion) => 
                                Text(
                                  descripcion.length > 15 ? '${descripcion.substring(0, 15)}...' : descripcion,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontSize: 12),
                                )
                              ),
                              const Text("Otro", style: TextStyle(fontSize: 12)),
                            ];
                          },
                          onChanged: (descripcion) {
                            setState(() {
                              _descripcionSeleccionada = descripcion;
                              if (descripcion == "Otro") {
                                _codigoController.text = '';
                                _materialController.text = '';
                              } else {
                                _onDescripcionChanged(descripcion);
                              }
                            });
                          },
                          decoration: const InputDecoration(
                            labelText: "Descripción",
                            border: OutlineInputBorder(),
                          ),
                        ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 100,
                    child: DropdownButtonFormField<String>(
                      initialValue: _unidadSeleccionada,
                      items: const [
                        DropdownMenuItem(value: "mts", child: Text("metros")),
                        DropdownMenuItem(value: "cms", child: Text("centimetros")),
                        DropdownMenuItem(value: "un", child: Text("unidades")),
                      ],
                      selectedItemBuilder: (BuildContext context) {
                        return const [
                          Text("mts", overflow: TextOverflow.ellipsis),
                          Text("cms", overflow: TextOverflow.ellipsis),
                          Text("un", overflow: TextOverflow.ellipsis),
                        ];
                      },
                      onChanged: (v) => setState(() => _unidadSeleccionada = v),
                      decoration: const InputDecoration(
                        labelText: "Unidades",
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 100,
                    child: TextField(
                      controller: _cantidadController,
                      decoration: const InputDecoration(
                        labelText: "Cantidad",
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: () {
                      final descripcion = _descripcionSeleccionada == "Otro" ? _materialController.text : _descripcionSeleccionada;
                      if (_codigoController.text.isNotEmpty && descripcion != null && descripcion.isNotEmpty && _unidadSeleccionada != null) {
                        setState(() {
                          _materiales.add({
                            'codigo': _codigoController.text,
                            'material': descripcion,
                            'unidades': _unidadSeleccionada!,
                            'cantidad': _cantidadController.text,
                          });
                          _codigoController.clear();
                          _materialController.clear();
                          _descripcionSeleccionada = null;
                          _unidadSeleccionada = null;
                          _cantidadController.clear();
                        });
                      }
                    },
                    icon: const Icon(Icons.add),
                    label: const Text("Agregar"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            if (_materiales.isNotEmpty)
              Container(
                height: 200,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: SingleChildScrollView(
                  scrollDirection: Axis.vertical,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      columnSpacing: 8,
                      headingRowHeight: 30,
                      dataRowHeight: 35,
                      columns: const [
                        DataColumn(label: Text('Artículo', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold))),
                        DataColumn(label: Text('Descripción', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold))),
                        DataColumn(label: Text('Unidades', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold))),
                        DataColumn(label: Text('Cantidad', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold))),
                        DataColumn(label: Text('Acción', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold))),
                      ],
                      rows: _materiales.asMap().entries.map((entry) => DataRow(
                        cells: [
                          DataCell(Text(entry.value['codigo'] ?? '', style: const TextStyle(fontSize: 9))),
                          DataCell(
                            SizedBox(
                              width: 200,
                              child: Text(
                                entry.value['material'] ?? '',
                                style: const TextStyle(fontSize: 9),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                          DataCell(Text(entry.value['unidades'] ?? '', style: const TextStyle(fontSize: 9))),
                          DataCell(Text(entry.value['cantidad'] ?? '', style: const TextStyle(fontSize: 9))),
                          DataCell(
                            IconButton(
                              icon: const Icon(Icons.delete, size: 16),
                              onPressed: () => setState(() => _materiales.removeAt(entry.key)),
                            ),
                          ),
                        ],
                      )).toList(),
                    ),
                  ),
                ),
              ),
            
            const SizedBox(height: 16),
            // === MEDICIONES ===
            const Text("Mediciones", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: _nomenclaturaMedicionController,
                      decoration: const InputDecoration(
                        labelText: "Nomenclatura de elemento inspeccionado para confirmar servicio",
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text("Mediciones (Puertos 1-16) 1550nm:", style: TextStyle(fontWeight: FontWeight.bold)),
                    Table(
                      border: TableBorder.all(color: Colors.grey),
                      children: List.generate(4, (r) =>
                        TableRow(
                          children: List.generate(4, (c) =>
                            Padding(
                              padding: const EdgeInsets.all(4.0),
                              child: TextFormField(
                                controller: _medicionesPuertos1550[r * 4 + c],
                                keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                                decoration: InputDecoration(
                                  labelText: "P${r * 4 + c + 1}",
                                  isDense: true,
                                  border: const OutlineInputBorder(),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text("Mediciones (Puertos 1-16) 1490nm:", style: TextStyle(fontWeight: FontWeight.bold)),
                    Table(
                      border: TableBorder.all(color: Colors.grey),
                      children: List.generate(4, (r) =>
                        TableRow(
                          children: List.generate(4, (c) =>
                            Padding(
                              padding: const EdgeInsets.all(4.0),
                              child: TextFormField(
                                controller: _medicionesPuertos1490[r * 4 + c],
                                keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                                decoration: InputDecoration(
                                  labelText: "P${r * 4 + c + 1}",
                                  isDense: true,
                                  border: const OutlineInputBorder(),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            // === TRAZAS OTDR ===
            const Text("Trazas OTDR", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Text(
                    _archivoOTDR != null ? 'Archivo: ${_archivoOTDR!.name}' : 'No hay archivo seleccionado',
                    style: TextStyle(color: _archivoOTDR != null ? Colors.green : Colors.grey),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _seleccionarArchivoOTDR,
                  child: const Text("Seleccionar Archivo"),
                ),
                if (_archivoOTDR != null) ...[
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () => setState(() => _archivoOTDR = null),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                    child: const Text("Quitar"),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 16),
            // === EVIDENCIA FOTOGRÁFICA ===
            const Text("Evidencia Fotográfica", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            
            // Campo de descripción y botón
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _descripcionFotoController,
                    decoration: const InputDecoration(
                      labelText: "Descripción de la foto",
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 2,
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _adjuntarFoto,
                  child: const Text("Adjuntar Foto"),
                ),
              ],
            ),
            
            const SizedBox(height: 8),
            if (_evidenciaFotografica.isNotEmpty)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Fotos adjuntadas:", style: TextStyle(fontWeight: FontWeight.bold)),
                  ..._evidenciaFotografica.asMap().entries.map((entry) => Card(
                    child: ListTile(
                      dense: true,
                      leading: const Icon(Icons.photo),
                      title: Text("${entry.value['foto'].name}"),
                      subtitle: Text(entry.value['descripcion']),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete, size: 16),
                        onPressed: () => setState(() => _evidenciaFotografica.removeAt(entry.key)),
                      ),
                    ),
                  )),
                ],
              ),

            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  icon: const Icon(Icons.picture_as_pdf),
                  label: const Text("EXPORTAR PDF"),
                  onPressed: _exportarPDFBitacora,
                ),
                ElevatedButton.icon(
                  icon: const Icon(Icons.archive),
                  label: const Text("GENERAR ZIP"),
                  onPressed: _generarZIP,
                ),
              ],
            ),
            const SizedBox(height: 50),
          ],
        ),
      ),
    );
  }
  
  Future<void> _limpiarArchivosTemporalesPlanilla3() async {}
}
