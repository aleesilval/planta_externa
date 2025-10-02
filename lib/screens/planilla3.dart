import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:file_picker/file_picker.dart';
// ignore: unused_import
import 'dart:typed_data';
import 'package:flutter/services.dart';

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
  final List<PlatformFile> _fotosAntes = [];
  final List<PlatformFile> _fotosDespues = [];
  final TextEditingController _descripcionFotosController = TextEditingController();
  final List<Map<String, dynamic>> _evidenciaFotografica = [];
  
  // Materiales utilizados
  final List<Map<String, String>> _materiales = [];
  final TextEditingController _codigoController = TextEditingController();
  final TextEditingController _materialController = TextEditingController();
  String? _unidadSeleccionada;
  final TextEditingController _cantidadController = TextEditingController();
  String? _descripcionSeleccionada;
  
  // Tabla de artículos predefinida
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
  }
  
  void _onCodigoChanged() {
    // No longer needed - will be replaced by dropdown selection
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
    
    // Página 1: Portada
    pdf.addPage(
      pw.Page(
        build: (pw.Context context) {
          return pw.Column(
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
    
    // Página 4: Evidencia fotográfica
    if (_evidenciaFotografica.isNotEmpty) {
      pdf.addPage(
        pw.Page(
          build: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('Evidencia Fotográfica', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 16),
                ..._evidenciaFotografica.asMap().entries.map((entry) => pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Row(
                      children: [
                        pw.Expanded(
                          child: pw.Container(
                            height: 150,
                            child: entry.value['fotoAntes'] != null
                                ? pw.Image(pw.MemoryImage(entry.value['fotoAntes'].bytes!))
                                : pw.Text('Sin foto'),
                          ),
                        ),
                        pw.SizedBox(width: 8),
                        pw.Expanded(
                          child: pw.Container(
                            height: 150,
                            child: entry.value['fotoDespues'] != null
                                ? pw.Image(pw.MemoryImage(entry.value['fotoDespues'].bytes!))
                                : pw.Text('Sin foto'),
                          ),
                        ),
                      ],
                    ),
                    pw.SizedBox(height: 8),
                    pw.Text('Descripcion: ${entry.value['descripcion']}'),
                    pw.SizedBox(height: 16),
                  ],
                )),
              ],
            );
          },
        ),
      );
    }

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
        _fotosAntes.clear();
        _fotosDespues.clear();
        _descripcionFotosController.clear();
        _evidenciaFotografica.clear();

        _materiales.clear();
        _codigoController.clear();
        _descripcionSeleccionada = null;
        _unidadSeleccionada = null;
        _cantidadController.clear();
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
  
  Future<void> _pickImages(String tipo) async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      type: FileType.image,
    );
    if (result != null) {
      setState(() {
        if (tipo == "antes") {
          _fotosAntes.addAll(result.files);
        } else {
          _fotosDespues.addAll(result.files);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Información del Reporte')),
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
            Row(
              children: [
                Expanded(
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
                Expanded(
                  child: _descripcionSeleccionada == "Otro" 
                    ? TextField(
                        controller: _materialController,
                        decoration: const InputDecoration(
                          labelText: "Descripción del Artículo",
                          border: OutlineInputBorder(),
                        ),
                      )
                    : DropdownButtonFormField<String>(
                        value: _descripcionSeleccionada,
                        items: [
                          ..._tablaArticulos.values.map((descripcion) => 
                            DropdownMenuItem(
                              value: descripcion, 
                              child: Text(
                                descripcion.length > 30 ? '${descripcion.substring(0, 30)}...' : descripcion,
                                overflow: TextOverflow.ellipsis
                              )
                            )
                          ),
                          const DropdownMenuItem(value: "Otro", child: Text("Otro")),
                        ],
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
                          labelText: "Descripción del Artículo",
                          border: OutlineInputBorder(),
                        ),
                      ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: _unidadSeleccionada,
                    items: const [
                      DropdownMenuItem(value: "mts", child: Text("metros")),
                      DropdownMenuItem(value: "cms", child: Text("centimetros")),
                      DropdownMenuItem(value: "un", child: Text("unidades")),
                    ],
                    onChanged: (v) => setState(() => _unidadSeleccionada = v),
                    decoration: const InputDecoration(
                      labelText: "Unidades",
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
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
                ElevatedButton(
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
                  child: const Text("Agregar"),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (_materiales.isNotEmpty)
              Table(
                border: TableBorder.all(),
                children: [
                  const TableRow(
                    children: [
                      Padding(padding: EdgeInsets.all(8), child: Text('Artículo', style: TextStyle(fontWeight: FontWeight.bold))),
                      Padding(padding: EdgeInsets.all(8), child: Text('Descripción del Artículo', style: TextStyle(fontWeight: FontWeight.bold))),
                      Padding(padding: EdgeInsets.all(8), child: Text('Unidades', style: TextStyle(fontWeight: FontWeight.bold))),
                      Padding(padding: EdgeInsets.all(8), child: Text('Cantidad', style: TextStyle(fontWeight: FontWeight.bold))),
                      Padding(padding: EdgeInsets.all(8), child: Text('', style: TextStyle(fontWeight: FontWeight.bold))),
                    ],
                  ),
                  ..._materiales.asMap().entries.map((entry) => TableRow(
                    children: [
                      Padding(padding: const EdgeInsets.all(8), child: Text(entry.value['codigo'] ?? '')),
                      Padding(padding: const EdgeInsets.all(8), child: Text(entry.value['material'] ?? '')),
                      Padding(padding: const EdgeInsets.all(8), child: Text(entry.value['unidades'] ?? '')),
                      Padding(padding: const EdgeInsets.all(8), child: Text(entry.value['cantidad'] ?? '')),
                      Padding(
                        padding: const EdgeInsets.all(4),
                        child: IconButton(
                          icon: const Icon(Icons.delete, size: 16),
                          onPressed: () => setState(() => _materiales.removeAt(entry.key)),
                        ),
                      ),
                    ],
                  )),
                ],
              ),
            
            const SizedBox(height: 16),
            // === EVIDENCIA FOTOGRÁFICA ===
            const Text("Evidencia Fotográfica", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            
            // Tabla de fotos
            Table(
              border: TableBorder.all(),
              children: [
                TableRow(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(8),
                      child: Column(
                        children: [
                          Text("Antes (${_fotosAntes.length})", style: const TextStyle(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          ElevatedButton(
                            onPressed: () => _pickImages("antes"),
                            child: const Text("Adjuntar Fotos"),
                          ),
                          ..._fotosAntes.asMap().entries.map((entry) => ListTile(
                            dense: true,
                            title: Text("antes_${entry.key + 1}.${entry.value.extension}", style: const TextStyle(fontSize: 12)),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete, size: 16),
                              onPressed: () => setState(() => _fotosAntes.removeAt(entry.key)),
                            ),
                          )),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8),
                      child: Column(
                        children: [
                          Text("Después (${_fotosDespues.length})", style: const TextStyle(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          ElevatedButton(
                            onPressed: () => _pickImages("despues"),
                            child: const Text("Adjuntar Fotos"),
                          ),
                          ..._fotosDespues.asMap().entries.map((entry) => ListTile(
                            dense: true,
                            title: Text("despues_${entry.key + 1}.${entry.value.extension}", style: const TextStyle(fontSize: 12)),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete, size: 16),
                              onPressed: () => setState(() => _fotosDespues.removeAt(entry.key)),
                            ),
                          )),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            
            const SizedBox(height: 8),
            // Campo de descripción y botón
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _descripcionFotosController,
                    decoration: const InputDecoration(
                      labelText: "Descripción",
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 2,
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () {
                    if (_descripcionFotosController.text.isNotEmpty && _fotosAntes.isNotEmpty && _fotosDespues.isNotEmpty) {
                      setState(() {
                        _evidenciaFotografica.add({
                          'fotoAntes': _fotosAntes.first,
                          'fotoDespues': _fotosDespues.first,
                          'descripcion': _descripcionFotosController.text,
                        });
                        _fotosAntes.clear();
                        _fotosDespues.clear();
                        _descripcionFotosController.clear();
                      });
                    }
                  },
                  child: const Text("Adicionar Foto"),
                ),
              ],
            ),
            
            const SizedBox(height: 8),
            if (_evidenciaFotografica.isNotEmpty)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Evidencia adjuntada:", style: TextStyle(fontWeight: FontWeight.bold)),
                  ..._evidenciaFotografica.asMap().entries.map((entry) => Card(
                    child: ListTile(
                      dense: true,
                      leading: const Icon(Icons.photo_library),
                      title: Text("Evidencia ${entry.key + 1}"),
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

            ElevatedButton.icon(
              icon: const Icon(Icons.picture_as_pdf),
              label: const Text("EXPORTAR PDF BITÁCORA"),
              onPressed: _exportarPDFBitacora,
            ),
          ],
        ),
      ),
    );
  }
}
