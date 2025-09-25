import 'package:flutter/material.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';

// Punto de entrada de la app
void main() {
  runApp(const MyApp());
}

// Widget principal
class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Formulario Planta Externa',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const FormularioPlantaExterna(),
    );
  }
}

// Pantalla principal con estado
class FormularioPlantaExterna extends StatefulWidget {
  const FormularioPlantaExterna({super.key});
  @override
  State<FormularioPlantaExterna> createState() => _FormularioPlantaExternaState();
}

class _FormularioPlantaExternaState extends State<FormularioPlantaExterna> {
  final _formKey = GlobalKey<FormState>();
  final List<Map<String, dynamic>> _tabla = [];
  int _contador = 1;

  // Controladores y valores de los campos
  final TextEditingController _yk01Controller = TextEditingController();
  final TextEditingController _sr144hController = TextEditingController();
  final TextEditingController _sr12hController = TextEditingController();
  final TextEditingController _ss144hController = TextEditingController();
  final TextEditingController _ss12hController = TextEditingController();
  String _morseteriaIdentificada = 'SS';
  final TextEditingController _modeloController = TextEditingController();
  String _tirrajeFleje = 'Tirraje';
  final TextEditingController _tirrajeCantidadController = TextEditingController();
  final TextEditingController _geolocalizacionModeloController = TextEditingController();
  final TextEditingController _fibraPlanaController = TextEditingController();
  final TextEditingController _tendidoInicioController = TextEditingController();
  final TextEditingController _tendidoFinController = TextEditingController();
  final TextEditingController _reservas144hActualController = TextEditingController();
  final TextEditingController _reservas144hAccionController = TextEditingController();
  final TextEditingController _reservas12hActualController = TextEditingController();
  final TextEditingController _reservas12hAccionController = TextEditingController();
  final TextEditingController _zonasPodaInicioController = TextEditingController();
  final TextEditingController _zonasPodaFinController = TextEditingController();
  final TextEditingController _postesInstaladosController = TextEditingController();
  final TextEditingController _observacionesController = TextEditingController();
  final TextEditingController _trabajosPendientesController = TextEditingController();

  // Limpia todos los campos y la tabla
  void _limpiarTodo() {
    setState(() {
      _yk01Controller.clear();
      _sr144hController.clear();
      _sr12hController.clear();
      _ss144hController.clear();
      _ss12hController.clear();
      _morseteriaIdentificada = 'SS';
      _modeloController.clear();
      _tirrajeFleje = 'Tirraje';
      _tirrajeCantidadController.clear();
      _geolocalizacionModeloController.clear();
      _fibraPlanaController.clear();
      _tendidoInicioController.clear();
      _tendidoFinController.clear();
      _reservas144hActualController.clear();
      _reservas144hAccionController.clear();
      _reservas12hActualController.clear();
      _reservas12hAccionController.clear();
      _zonasPodaInicioController.clear();
      _zonasPodaFinController.clear();
      _postesInstaladosController.clear();
      _observacionesController.clear();
      _trabajosPendientesController.clear();
      _tabla.clear();
      _contador = 1;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Formulario y tabla limpiados')),
    );
  }

  // Agrega una fila a la tabla
  void _grabarFila() {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _tabla.add({
          'contador': _contador,
          'yk01': _yk01Controller.text,
          'sr144h': _sr144hController.text,
          'sr12h': _sr12hController.text,
          'ss144h': _ss144hController.text,
          'ss12h': _ss12hController.text,
          'morseteriaIdentificada': _morseteriaIdentificada,
          'modelo': _modeloController.text,
          'tirrajeFleje': _tirrajeFleje,
          'tirrajeCantidad': _tirrajeCantidadController.text,
          'geolocalizacionModelo': _geolocalizacionModeloController.text,
          'fibraPlana': _fibraPlanaController.text,
          'tendidoInicio': _tendidoInicioController.text,
          'tendidoFin': _tendidoFinController.text,
          'reservas144hActual': _reservas144hActualController.text,
          'reservas144hAccion': _reservas144hAccionController.text,
          'reservas12hActual': _reservas12hActualController.text,
          'reservas12hAccion': _reservas12hAccionController.text,
          'zonasPodaInicio': _zonasPodaInicioController.text,
          'zonasPodaFin': _zonasPodaFinController.text,
          'postesInstalados': _postesInstaladosController.text,
          'observaciones': _observacionesController.text,
          'trabajosPendientes': _trabajosPendientesController.text,
        });
        _contador++;
        _yk01Controller.clear();
        _sr144hController.clear();
        _sr12hController.clear();
        _ss144hController.clear();
        _ss12hController.clear();
        _modeloController.clear();
        _tirrajeCantidadController.clear();
        _geolocalizacionModeloController.clear();
        _fibraPlanaController.clear();
        _tendidoInicioController.clear();
        _tendidoFinController.clear();
        _reservas144hActualController.clear();
        _reservas144hAccionController.clear();
        _reservas12hActualController.clear();
        _reservas12hAccionController.clear();
        _zonasPodaInicioController.clear();
        _zonasPodaFinController.clear();
        _postesInstaladosController.clear();
        _observacionesController.clear();
        _trabajosPendientesController.clear();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Fila agregada a la tabla')),
      );
    }
  }

  // Exporta la tabla a PDF
  Future<void> _exportarPDF() async {
    final pdf = pw.Document();
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.letter.landscape,
        margin: const pw.EdgeInsets.all(12),
        build: (context) {
          return pw.Column(
            children: [
              pw.Text('Mantenimiento Preventivo, Predictivo o Correctivo',
                  style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 8),
              pw.Table(
                border: pw.TableBorder.all(width: 0.5, color: PdfColors.black),
                defaultVerticalAlignment: pw.TableCellVerticalAlignment.middle,
                columnWidths: {
                  0: const pw.FlexColumnWidth(), // Dinámico
                  1: const pw.FlexColumnWidth(),
                  2: const pw.FlexColumnWidth(),
                  3: const pw.FlexColumnWidth(),
                  4: const pw.FlexColumnWidth(),
                  5: const pw.FlexColumnWidth(),
                  6: const pw.FlexColumnWidth(),
                  7: const pw.FlexColumnWidth(),
                  8: const pw.FlexColumnWidth(),
                  9: const pw.FlexColumnWidth(),
                  10: const pw.FlexColumnWidth(),
                  11: const pw.FlexColumnWidth(),
                  12: const pw.FlexColumnWidth(),
                  13: const pw.FlexColumnWidth(),
                  14: const pw.FlexColumnWidth(),
                  15: const pw.FlexColumnWidth(),
                  16: const pw.FlexColumnWidth(),
                  17: const pw.FlexColumnWidth(),
                  18: const pw.FlexColumnWidth(),
                  19: const pw.FlexColumnWidth(),
                  20: const pw.FlexColumnWidth(),
                  21: const pw.FlexColumnWidth(),
                  22: const pw.FlexColumnWidth(),
                },
                children: [
                  // Encabezados
                  pw.TableRow(
                    children: [
                      pw.Container(
                        alignment: pw.Alignment.center,
                        padding: const pw.EdgeInsets.all(2),
                        child: pw.Wrap(
                          alignment: pw.WrapAlignment.center,
                          children: [
                            pw.Text('Nro de poste en el tendido', textAlign: pw.TextAlign.center, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8)),
                          ],
                        ),
                      ),
                      pw.Container(alignment: pw.Alignment.center, child: pw.Text('YK01', textAlign: pw.TextAlign.center, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9))),
                      pw.Container(alignment: pw.Alignment.center, child: pw.Text('S.R 144H', textAlign: pw.TextAlign.center, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9))),
                      pw.Container(alignment: pw.Alignment.center, child: pw.Text('S.R 12H', textAlign: pw.TextAlign.center, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9))),
                      pw.Container(alignment: pw.Alignment.center, child: pw.Text('S.S 144H', textAlign: pw.TextAlign.center, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9))),
                      pw.Container(alignment: pw.Alignment.center, child: pw.Text('S.S 12H', textAlign: pw.TextAlign.center, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9))),
                      pw.Container(alignment: pw.Alignment.center, child: pw.Text('Identificacion', textAlign: pw.TextAlign.center, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 5))),
                      pw.Container(alignment: pw.Alignment.center, child: pw.Text('Modelo', textAlign: pw.TextAlign.center, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9))),
                      pw.Container(alignment: pw.Alignment.center, child: pw.Text('Tirraje Fleje', textAlign: pw.TextAlign.center, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9))),
                      pw.Container(alignment: pw.Alignment.center, child: pw.Text('Cantidad', textAlign: pw.TextAlign.center, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8))),
                      pw.Container(alignment: pw.Alignment.center, child: pw.Text('Geo localización ', textAlign: pw.TextAlign.center, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 6))),
                      pw.Container(alignment: pw.Alignment.center, child: pw.Text('Morseteria Fibra 4H Soporte Fibra plana', textAlign: pw.TextAlign.center, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 6))),
                      pw.Container(alignment: pw.Alignment.center, child: pw.Text('Tendido con perdida de tension inicio', textAlign: pw.TextAlign.center, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 6))),
                      pw.Container(alignment: pw.Alignment.center, child: pw.Text('Tendido con perdida de tension fin', textAlign: pw.TextAlign.center, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 6))),
                      pw.Container(alignment: pw.Alignment.center, child: pw.Text('Reservas 144H Actual', textAlign: pw.TextAlign.center, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 7))),
                      pw.Container(alignment: pw.Alignment.center, child: pw.Text('Reservas 144H Acción', textAlign: pw.TextAlign.center, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 7))),
                      pw.Container(alignment: pw.Alignment.center, child: pw.Text('Reservas 12H Actual', textAlign: pw.TextAlign.center, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 7))),
                      pw.Container(alignment: pw.Alignment.center, child: pw.Text('Reservas 12H Acción', textAlign: pw.TextAlign.center, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 7))),
                      pw.Container(alignment: pw.Alignment.center, child: pw.Text('Zonas poda inicio', textAlign: pw.TextAlign.center, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9))),
                      pw.Container(alignment: pw.Alignment.center, child: pw.Text('Zonas poda fin', textAlign: pw.TextAlign.center, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9))),
                      pw.Container(alignment: pw.Alignment.center, child: pw.Text('Postes instalados', textAlign: pw.TextAlign.center, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 7))),
                      pw.Container(alignment: pw.Alignment.center, child: pw.Text('Observaciones', textAlign: pw.TextAlign.center, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 4))),
                      pw.Container(alignment: pw.Alignment.center, child: pw.Text('Trabajos pendientes', textAlign: pw.TextAlign.center, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 6))),
                    ],
                  ),
                  // Filas de datos
                  ..._tabla.map((fila) {
                    return pw.TableRow(
                      children: [
                        pw.Container(
                          alignment: pw.Alignment.center,
                          padding: const pw.EdgeInsets.all(2),
                          child: pw.Wrap(
                            alignment: pw.WrapAlignment.center,
                            children: [
                              pw.Text('${fila['contador']}', textAlign: pw.TextAlign.center, style: const pw.TextStyle(fontSize: 8)),
                            ],
                          ),
                        ),
                        pw.Container(alignment: pw.Alignment.center, child: pw.Text(fila['yk01'] ?? '', textAlign: pw.TextAlign.center, style: const pw.TextStyle(fontSize: 8))),
                        pw.Container(alignment: pw.Alignment.center, child: pw.Text(fila['sr144h'] ?? '', textAlign: pw.TextAlign.center, style: const pw.TextStyle(fontSize: 8))),
                        pw.Container(alignment: pw.Alignment.center, child: pw.Text(fila['sr12h'] ?? '', textAlign: pw.TextAlign.center, style: const pw.TextStyle(fontSize: 8))),
                        pw.Container(alignment: pw.Alignment.center, child: pw.Text(fila['ss144h'] ?? '', textAlign: pw.TextAlign.center, style: const pw.TextStyle(fontSize: 8))),
                        pw.Container(alignment: pw.Alignment.center, child: pw.Text(fila['ss12h'] ?? '', textAlign: pw.TextAlign.center, style: const pw.TextStyle(fontSize: 8))),
                        pw.Container(alignment: pw.Alignment.center, child: pw.Text(fila['morseteriaIdentificada'] ?? '', textAlign: pw.TextAlign.center, style: const pw.TextStyle(fontSize: 8))),
                        pw.Container(alignment: pw.Alignment.center, child: pw.Text(fila['modelo'] ?? '', textAlign: pw.TextAlign.center, style: const pw.TextStyle(fontSize: 8))),
                        pw.Container(alignment: pw.Alignment.center, child: pw.Text(fila['tirrajeFleje'] ?? '', textAlign: pw.TextAlign.center, style: const pw.TextStyle(fontSize: 8))),
                        pw.Container(alignment: pw.Alignment.center, child: pw.Text(fila['tirrajeCantidad'] ?? '', textAlign: pw.TextAlign.center, style: const pw.TextStyle(fontSize: 8))),
                        pw.Container(alignment: pw.Alignment.center, child: pw.Text(fila['geolocalizacionModelo'] ?? '', textAlign: pw.TextAlign.center, style: const pw.TextStyle(fontSize: 8))),
                        pw.Container(alignment: pw.Alignment.center, child: pw.Text(fila['fibraPlana'] ?? '', textAlign: pw.TextAlign.center, style: const pw.TextStyle(fontSize: 8))),
                        pw.Container(alignment: pw.Alignment.center, child: pw.Text(fila['tendidoInicio'] ?? '', textAlign: pw.TextAlign.center, style: const pw.TextStyle(fontSize: 8))),
                        pw.Container(alignment: pw.Alignment.center, child: pw.Text(fila['tendidoFin'] ?? '', textAlign: pw.TextAlign.center, style: const pw.TextStyle(fontSize: 8))),
                        pw.Container(alignment: pw.Alignment.center, child: pw.Text(fila['reservas144hActual'] ?? '', textAlign: pw.TextAlign.center, style: const pw.TextStyle(fontSize: 8))),
                        pw.Container(alignment: pw.Alignment.center, child: pw.Text(fila['reservas144hAccion'] ?? '', textAlign: pw.TextAlign.center, style: const pw.TextStyle(fontSize: 8))),
                        pw.Container(alignment: pw.Alignment.center, child: pw.Text(fila['reservas12hActual'] ?? '', textAlign: pw.TextAlign.center, style: const pw.TextStyle(fontSize: 8))),
                        pw.Container(alignment: pw.Alignment.center, child: pw.Text(fila['reservas12hAccion'] ?? '', textAlign: pw.TextAlign.center, style: const pw.TextStyle(fontSize: 8))),
                        pw.Container(alignment: pw.Alignment.center, child: pw.Text(fila['zonasPodaInicio'] ?? '', textAlign: pw.TextAlign.center, style: const pw.TextStyle(fontSize: 8))),
                        pw.Container(alignment: pw.Alignment.center, child: pw.Text(fila['zonasPodaFin'] ?? '', textAlign: pw.TextAlign.center, style: const pw.TextStyle(fontSize: 8))),
                        pw.Container(alignment: pw.Alignment.center, child: pw.Text(fila['postesInstalados'] ?? '', textAlign: pw.TextAlign.center, style: const pw.TextStyle(fontSize: 8))),
                        pw.Container(alignment: pw.Alignment.center, child: pw.Text(fila['observaciones'] ?? '', textAlign: pw.TextAlign.center, style: const pw.TextStyle(fontSize: 8))),
                        pw.Container(alignment: pw.Alignment.center, child: pw.Text(fila['trabajosPendientes'] ?? '', textAlign: pw.TextAlign.center, style: const pw.TextStyle(fontSize: 8))),
                      ],
                    );
                  })
                ],
              ),
              pw.SizedBox(height: 12),
              pw.Text('Postes : ${_tabla.length}', style: pw.TextStyle(fontSize: 12)),
            ],
          );
        },
      ),
    );
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
    );
  }

  // Construye la interfaz principal
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Formulario Planta Externa')),
      body: Column(
        children: [
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Form(
                key: _formKey,
                child: ListView(
                  children: [
                    // Campos de ingreso agrupados y personalizados
                    _buildTextField('Cantidad de YK01', _yk01Controller),
                    _buildTextField('S.R 144H', _sr144hController),
                    _buildTextField('S.R 12H', _sr12hController),
                    _buildTextField('S.S 144H', _ss144hController),
                    _buildTextField('S.S 12H', _ss12hController),
                    _buildDropdownField('Identificacion de la morseteria', _morseteriaIdentificada, ['SS', 'SR', 'YK01'], (val) {
                      setState(() { _morseteriaIdentificada = val!; });
                    }),
                    _buildTextField('Tipo de elemento de fijacion', _modeloController),
                    _buildDropdownField('Tirraje / Fleje', _tirrajeFleje, ['Tirraje', 'Fleje', 'Otro'], (val) {
                      setState(() { _tirrajeFleje = val!; });
                    }),
                    _buildTextField('Cantidad de elementos de fijacion', _tirrajeCantidadController),
                    _buildTextField('Geolocalización del elemento fijado ', _geolocalizacionModeloController),
                    _buildTextField('Morseteria Fibra de 4H Soporte de Fibra plana', _fibraPlanaController),
                    _buildTextField('Tendido con perdida de tension Geolocalizacion inicio', _tendidoInicioController),
                    _buildTextField('Tendido con perdida de tension Geolocalizacion fin', _tendidoFinController),
                    _buildTextField('Reservas 144H Actual', _reservas144hActualController),
                    _buildTextField('Reservas 144H Acción', _reservas144hAccionController),
                    _buildTextField('Reservas 12H Actual', _reservas12hActualController),
                    _buildTextField('Reservas 12H Acción', _reservas12hAccionController),
                    _buildTextField('Geolocalizacion de zona poda inicio', _zonasPodaInicioController),
                    _buildTextField('Geolocalizacion de zona poda fin', _zonasPodaFinController),
                    _buildTextField('Postes propiedad de Inter instalados', _postesInstaladosController),
                    _buildTextField('Observaciones', _observacionesController),
                    _buildTextField('Trabajos pendientes', _trabajosPendientesController),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        ElevatedButton.icon(
                          icon: const Icon(Icons.add),
                          label: const Text('Grabar'),
                          onPressed: _grabarFila,
                        ),
                        ElevatedButton.icon(
                          icon: const Icon(Icons.picture_as_pdf),
                          label: const Text('Exportar'),
                          onPressed: _tabla.isEmpty ? null : _exportarPDF,
                        ),
                        ElevatedButton.icon(
                          icon: const Icon(Icons.cleaning_services),
                          label: const Text('Limpiar'),
                          onPressed: _limpiarTodo,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Sección inferior separada y con scroll independiente
          Expanded(
            flex: 1,
            child: Container(
              color: Colors.grey[100],
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Text('Tabla de datos:', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                    scrollDirection: Axis.vertical,
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,                      
                         physics: const AlwaysScrollableScrollPhysics(), // 👈 fuerza el scroll
                         child: ConstrainedBox(
                            constraints: BoxConstraints(minWidth: 1500), // 👈 fuerza ancho mínimo
                          child: DataTable(
                            columns: [
                              DataColumn(label: Text('Nro de poste en el tendido')),
                              DataColumn(label: Text('YK01')),
                              DataColumn(label: Text('S.R 144H')),
                              DataColumn(label: Text('S.R 12H')),
                              DataColumn(label: Text('S.S 144H')),
                              DataColumn(label: Text('S.S 12H')),
                              DataColumn(label: Text('Identificacion')),
                              DataColumn(label: Text('Elemento de fijado')),
                              DataColumn(label: Text('Tirraje/Fleje')),
                              DataColumn(label: Text('Cantidad')),
                              DataColumn(label: Text('Geolocalización')),
                              DataColumn(label: Text('Fibra plana')),
                              DataColumn(label: Text('Tendido inicio')),
                              DataColumn(label: Text('Tendido fin')),
                              DataColumn(label: Text('Reservas 144H Actual')),
                              DataColumn(label: Text('Reservas 144H Acción')),
                              DataColumn(label: Text('Reservas 12H Actual')),
                              DataColumn(label: Text('Reservas 12H Acción')),
                              DataColumn(label: Text('Zonas poda inicio')),
                              DataColumn(label: Text('Zonas poda fin')),
                              DataColumn(label: Text('Postes instalados')),
                              DataColumn(label: Text('Observaciones')),
                              DataColumn(label: Text('Trabajos pendientes')),
                            ],
                            rows: _tabla.map((fila) {
                              return DataRow(
                                cells: [
                                  DataCell(Text('${fila['contador']}')),
                                  DataCell(Text(fila['yk01'] ?? '')),
                                  DataCell(Text(fila['sr144h'] ?? '')),
                                  DataCell(Text(fila['sr12h'] ?? '')),
                                  DataCell(Text(fila['ss144h'] ?? '')),
                                  DataCell(Text(fila['ss12h'] ?? '')),
                                  DataCell(Text(fila['morseteriaIdentificada'] ?? '')),
                                  DataCell(Text(fila['modelo'] ?? '')),
                                  DataCell(Text(fila['tirrajeFleje'] ?? '')),
                                  DataCell(Text(fila['tirrajeCantidad'] ?? '')),
                                  DataCell(Text(fila['geolocalizacionModelo'] ?? '')),
                                  DataCell(Text(fila['fibraPlana'] ?? '')),
                                  DataCell(Text(fila['tendidoInicio'] ?? '')),
                                  DataCell(Text(fila['tendidoFin'] ?? '')),
                                  DataCell(Text(fila['reservas144hActual'] ?? '')),
                                  DataCell(Text(fila['reservas144hAccion'] ?? '')),
                                  DataCell(Text(fila['reservas12hActual'] ?? '')),
                                  DataCell(Text(fila['reservas12hAccion'] ?? '')),
                                  DataCell(Text(fila['zonasPodaInicio'] ?? '')),
                                  DataCell(Text(fila['zonasPodaFin'] ?? '')),
                                  DataCell(Text(fila['postesInstalados'] ?? '')),
                                  DataCell(Text(fila['observaciones'] ?? '')),
                                  DataCell(Text(fila['trabajosPendientes'] ?? '')),
                                ],
                              );
                            }).toList(),
                          ),
                         ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Campo de texto estándar
  Widget _buildTextField(String label, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          isDense: true,
        ),
      ),
    );
  }

  // Campo de selección tipo dropdown
  Widget _buildDropdownField(String label, String value, List<String> items, ValueChanged<String?> onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: DropdownButtonFormField<String>(
        initialValue: value,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          isDense: true,
        ),
        items: items.map((item) => DropdownMenuItem(value: item, child: Text(item))).toList(),
        onChanged: onChanged,
      ),
    );
  }
}