import 'package:flutter/material.dart';
// Paquetes para PDF
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';

// Punto de entrada de la app
void main() {
  runApp(const MyApp());
}

// Widget principal de la aplicación
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Configuración de tema y pantalla inicial
    return MaterialApp(
      title: 'Formulario Planta Externa',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const FormularioPlantaExterna(),
    );
  }
}

// Widget de la pantalla principal con estado
class FormularioPlantaExterna extends StatefulWidget {
  const FormularioPlantaExterna({super.key});

  @override
  State<FormularioPlantaExterna> createState() => _FormularioPlantaExternaState();
}

// Estado del formulario y la tabla
class _FormularioPlantaExternaState extends State<FormularioPlantaExterna> {
  final _formKey = GlobalKey<FormState>(); // Clave para el formulario
  final Map<String, TextEditingController> _controllers = {}; // Controladores de texto
  final List<Map<String, String>> _tabla = []; // Lista de filas de la tabla
  int _contador = 1; // Contador de filas

  // Definición de los campos del formulario
  final List<Map<String, String>> _campos = [
    {'label': 'Soporte de Morseteria', 'key': 'soporte_morseteria'},
    {'label': 'Morseteria SR (Soporte de retención para F.O 12, 144H)', 'key': 'morseteria_sr'},
    {'label': 'Morseteria SS (Soporte de Suspensión)', 'key': 'morseteria_ss'},
    {'label': 'Morseteria identificada Color Amarillo Inter', 'key': 'morseteria_color'},
    {'label': 'Modelo del elemento Instalado CL288, CL144, NAP: IP65, NAP: IP67', 'key': 'modelo_elemento'},
    {'label': 'Fijación del elemento Tiraje o Fleje cantidad', 'key': 'fijacion_elemento'},
    {'label': 'Geolocalización', 'key': 'geolocalizacion'},
    {'label': 'Morseteria Fibra 4H', 'key': 'morseteria_fibra_4h'},
    {'label': 'Soporte de fibra plana', 'key': 'soporte_fibra_plana'},
    {'label': 'Tendido de Fibras con perdida de tensión Geolocalización Punto Inicial', 'key': 'tendido_fibras_inicial'},
    {'label': 'Tendido de Fibras con perdida de tensión Geolocalización Punto Final', 'key': 'tendido_fibras_final'},
    {'label': 'Cantidad de Reservas F.O 144H Actual', 'key': 'reservas_144h_actual'},
    {'label': 'Cantidad de Reservas F.O 144H Acción', 'key': 'reservas_144h_accion'},
    {'label': 'Cantidad de Reservas F.O 12H Actual', 'key': 'reservas_12h_actual'},
    {'label': 'Cantidad de Reservas F.O 12H Acción', 'key': 'reservas_12h_accion'},
    {'label': 'Zonas por Desmalezar o poda Geolocalización Punto Inicial', 'key': 'zonas_poda_inicial'},
    {'label': 'Zonas por Desmalezar o poda Geolocalización Punto Final', 'key': 'zonas_poda_final'},
    {'label': 'Postes propiedad INTER Geolocalización Instalados', 'key': 'postes_inter_instalados'},
    {'label': 'Observaciones', 'key': 'observaciones'},
    {'label': 'Trabajos pendientes o realizados', 'key': 'trabajos_pendientes'},
  ];

  // Inicializa los controladores de texto
  @override
  void initState() {
    super.initState();
    for (var campo in _campos) {
      _controllers[campo['key']!] = TextEditingController();
    }
  }

  // Libera los controladores al cerrar el widget
  @override
  void dispose() {
    for (var controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  // Agrega una fila a la tabla con los datos del formulario
  void _grabarFila() {
    if (_formKey.currentState!.validate()) {
      Map<String, String> fila = {'N°': _contador.toString()};
      for (var campo in _campos) {
        fila[campo['key']!] = _controllers[campo['key']!]!.text;
      }
      setState(() {
        _tabla.add(fila);
        _contador++;
        for (var controller in _controllers.values) {
          controller.clear();
        }
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Fila agregada a la tabla')),
      );
    }
  }

  // Limpia los campos y la tabla
  void _limpiarTodo() {
    setState(() {
      for (var controller in _controllers.values) {
        controller.clear();
      }
      _tabla.clear();
      _contador = 1;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Formulario y tabla limpiados')),
    );
  }

  // Exporta la tabla a un PDF con formato horizontal y columnas centradas
  Future<void> _exportarPDF() async {
    final pdf = pw.Document();

    // Encabezados principales y secundarios de la tabla
    final List<String> encabezados1 = [
      'Cantidad de\nPostes en el\ntendido',
      'Morseteria SR\n(Soporte de retención para F.O 12, 144H)',
      'Morseteria SS\n(Soporte de Suspensión)',
      'Morseteria\nidentificada\nColor Amarillo\nInter',
      'Modelo del elemento Instalado CL288,\nCL144, NAP: IP65, NAP: IP67',
      'Morseteria\nFibra 4H',
      'Tendido de Fibras con perdida de tensión\nGeolocalización',
      'Cantidad de Reservas\nF.O 144H',
      'Cantidad de Reservas\nF.O 12H',
      'Zonas por Desmalezar o poda\nGeolocalización',
      'Postes propiedad INTER\nGeolocalización',
      'Observaciones',
      'Trabajos pendientes o realizados',
    ];

    final List<List<String>> encabezados2 = [
      ['YK01'],
      ['S.R 144H', 'SR. 12H'],
      ['S.S 144H', 'S.S 12H'],
      ['SS, SR, YK01'],
      ['Modelo', 'Fijación del elemento\nTiraje o Fleje cantidad', 'Geolocalización'],
      ['Soporte de fibra plana'],
      ['Punto Inicial', 'Punto Final'],
      ['Actual', 'Acción'],
      ['Actual', 'Accion'],
      ['Punto Inicial', 'Punto Final'],
      ['Instalados'],
      ['Breve Comentario'],
      ['Breve Comentario'],
    ];

    // Construcción de la hoja PDF
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4.landscape, // Orientación horizontal
        margin: const pw.EdgeInsets.all(12),
        build: (context) {
          return pw.Column(
            children: [
              // Título del reporte
              pw.Text('Mantenimiento Preventivo, Predictivo o Correctivo',
                  style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 8),
              // Tabla con encabezados y filas de datos
              pw.Table(
                border: pw.TableBorder.all(width: 0.5, color: PdfColors.black),
                defaultVerticalAlignment: pw.TableCellVerticalAlignment.middle,
                columnWidths: {
                  0: const pw.FixedColumnWidth(50),
                  1: const pw.FixedColumnWidth(80),
                  2: const pw.FixedColumnWidth(80),
                  3: const pw.FixedColumnWidth(70),
                  4: const pw.FixedColumnWidth(120),
                  5: const pw.FixedColumnWidth(70),
                  6: const pw.FixedColumnWidth(100),
                  7: const pw.FixedColumnWidth(60),
                  8: const pw.FixedColumnWidth(60),
                  9: const pw.FixedColumnWidth(100),
                  10: const pw.FixedColumnWidth(70),
                  11: const pw.FixedColumnWidth(70),
                  12: const pw.FixedColumnWidth(70),
                },
                children: [
                  // Fila de encabezados principales
                  pw.TableRow(
                    children: encabezados1.map((e) {
                      return pw.Container(
                        alignment: pw.Alignment.center,
                        padding: const pw.EdgeInsets.all(4),
                        child: pw.Text(
                          e,
                          textAlign: pw.TextAlign.center,
                          style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold),
                        ),
                      );
                    }).toList(),
                  ),
                  // Fila de sub-encabezados
                  pw.TableRow(
                    children: encabezados2.map((sublist) {
                      return pw.Column(
                        children: sublist.map((sub) => pw.Container(
                          alignment: pw.Alignment.center,
                          padding: const pw.EdgeInsets.all(2),
                          child: pw.Text(
                            sub,
                            textAlign: pw.TextAlign.center,
                            style: const pw.TextStyle(fontSize: 8),
                          ),
                        )).toList(),
                      );
                    }).toList(),
                  ),
                  // Filas de datos de la tabla
                  ..._tabla.map((fila) {
                    return pw.TableRow(
                      children: [
                        pw.Container(
                          alignment: pw.Alignment.center,
                          padding: const pw.EdgeInsets.all(2),
                          child: pw.Text(fila['soporte_morseteria'] ?? '', textAlign: pw.TextAlign.center, style: const pw.TextStyle(fontSize: 8)),
                        ),
                        pw.Column(children: [
                          pw.Container(
                            alignment: pw.Alignment.center,
                            child: pw.Text(fila['morseteria_sr'] ?? '', textAlign: pw.TextAlign.center, style: const pw.TextStyle(fontSize: 8)),
                          ),
                          pw.Container(
                            alignment: pw.Alignment.center,
                            child: pw.Text(fila['morseteria_sr'] ?? '', textAlign: pw.TextAlign.center, style: const pw.TextStyle(fontSize: 8)),
                          ),
                        ]),
                        pw.Column(children: [
                          pw.Container(
                            alignment: pw.Alignment.center,
                            child: pw.Text(fila['morseteria_ss'] ?? '', textAlign: pw.TextAlign.center, style: const pw.TextStyle(fontSize: 8)),
                          ),
                          pw.Container(
                            alignment: pw.Alignment.center,
                            child: pw.Text(fila['morseteria_ss'] ?? '', textAlign: pw.TextAlign.center, style: const pw.TextStyle(fontSize: 8)),
                          ),
                        ]),
                        pw.Container(
                          alignment: pw.Alignment.center,
                          child: pw.Text(fila['morseteria_color'] ?? '', textAlign: pw.TextAlign.center, style: const pw.TextStyle(fontSize: 8)),
                        ),
                        pw.Column(children: [
                          pw.Container(
                            alignment: pw.Alignment.center,
                            child: pw.Text(fila['modelo_elemento'] ?? '', textAlign: pw.TextAlign.center, style: const pw.TextStyle(fontSize: 8)),
                          ),
                          pw.Container(
                            alignment: pw.Alignment.center,
                            child: pw.Text(fila['fijacion_elemento'] ?? '', textAlign: pw.TextAlign.center, style: const pw.TextStyle(fontSize: 8)),
                          ),
                          pw.Container(
                            alignment: pw.Alignment.center,
                            child: pw.Text(fila['geolocalizacion'] ?? '', textAlign: pw.TextAlign.center, style: const pw.TextStyle(fontSize: 8)),
                          ),
                        ]),
                        pw.Container(
                          alignment: pw.Alignment.center,
                          child: pw.Text(fila['morseteria_fibra_4h'] ?? '', textAlign: pw.TextAlign.center, style: const pw.TextStyle(fontSize: 8)),
                        ),
                        pw.Column(children: [
                          pw.Container(
                            alignment: pw.Alignment.center,
                            child: pw.Text(fila['tendido_fibras_inicial'] ?? '', textAlign: pw.TextAlign.center, style: const pw.TextStyle(fontSize: 8)),
                          ),
                          pw.Container(
                            alignment: pw.Alignment.center,
                            child: pw.Text(fila['tendido_fibras_final'] ?? '', textAlign: pw.TextAlign.center, style: const pw.TextStyle(fontSize: 8)),
                          ),
                        ]),
                        pw.Column(children: [
                          pw.Container(
                            alignment: pw.Alignment.center,
                            child: pw.Text(fila['reservas_144h_actual'] ?? '', textAlign: pw.TextAlign.center, style: const pw.TextStyle(fontSize: 8)),
                          ),
                          pw.Container(
                            alignment: pw.Alignment.center,
                            child: pw.Text(fila['reservas_144h_accion'] ?? '', textAlign: pw.TextAlign.center, style: const pw.TextStyle(fontSize: 8)),
                          ),
                        ]),
                        pw.Column(children: [
                          pw.Container(
                            alignment: pw.Alignment.center,
                            child: pw.Text(fila['reservas_12h_actual'] ?? '', textAlign: pw.TextAlign.center, style: const pw.TextStyle(fontSize: 8)),
                          ),
                          pw.Container(
                            alignment: pw.Alignment.center,
                            child: pw.Text(fila['reservas_12h_accion'] ?? '', textAlign: pw.TextAlign.center, style: const pw.TextStyle(fontSize: 8)),
                          ),
                        ]),
                        pw.Column(children: [
                          pw.Container(
                            alignment: pw.Alignment.center,
                            child: pw.Text(fila['zonas_poda_inicial'] ?? '', textAlign: pw.TextAlign.center, style: const pw.TextStyle(fontSize: 8)),
                          ),
                          pw.Container(
                            alignment: pw.Alignment.center,
                            child: pw.Text(fila['zonas_poda_final'] ?? '', textAlign: pw.TextAlign.center, style: const pw.TextStyle(fontSize: 8)),
                          ),
                        ]),
                        pw.Container(
                          alignment: pw.Alignment.center,
                          child: pw.Text(fila['postes_inter_instalados'] ?? '', textAlign: pw.TextAlign.center, style: const pw.TextStyle(fontSize: 8)),
                        ),
                        pw.Container(
                          alignment: pw.Alignment.center,
                          child: pw.Text(fila['observaciones'] ?? '', textAlign: pw.TextAlign.center, style: const pw.TextStyle(fontSize: 8)),
                        ),
                        pw.Container(
                          alignment: pw.Alignment.center,
                          child: pw.Text(fila['trabajos_pendientes'] ?? '', textAlign: pw.TextAlign.center, style: const pw.TextStyle(fontSize: 8)),
                        ),
                      ],
                    );
                  }).toList(),
                ],
              ),
              pw.SizedBox(height: 12),
              // Muestra el total de registros
              pw.Text('Total de registros: ${_tabla.length}', style: pw.TextStyle(fontSize: 12)),
            ],
          );
        },
      ),
    );

    // Muestra el PDF usando Printing
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
    );
  }

  // Construye la interfaz principal
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Formulario Planta Externa')),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              // Genera los campos del formulario
              ..._campos.map((campo) => _buildFila(campo['label']!, campo['key']!)),
              const SizedBox(height: 16),
              // Botones de acción
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
              const SizedBox(height: 24),
              // Muestra la tabla en pantalla
              const Text('Tabla de datos:', style: TextStyle(fontWeight: FontWeight.bold)),
              _tabla.isEmpty
                  ? const Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Text('No hay datos en la tabla'),
                    )
                  : SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: DataTable(
                        columns: [
                          const DataColumn(label: Text('N°')),
                          ..._campos.map((c) => DataColumn(label: Text(c['label']!))),
                        ],
                        rows: _tabla.map((fila) {
                          return DataRow(
                            cells: [
                              DataCell(Text(fila['N°'] ?? '')),
                              ..._campos.map((c) => DataCell(Text(fila[c['key']] ?? ''))),
                            ],
                          );
                        }).toList(),
                      ),
                    ),
            ],
          ),
        ),
      ),
    );
  }

  // Genera una fila de entrada de texto para el formulario
  Widget _buildFila(String label, String key) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(label, style: const TextStyle(fontSize: 13)),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 2,
            child: TextFormField(
              controller: _controllers[key],
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                isDense: true,
                contentPadding: EdgeInsets.symmetric(vertical: 8, horizontal: 8),
              ),
              validator: (value) => null, // Puedes agregar validaciones si lo deseas
            ),
          ),
        ],
      ),
    );
  }
}