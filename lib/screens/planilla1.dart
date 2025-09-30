import 'package:flutter/material.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';
import 'package:planta_externa/geo_field.dart';
import 'dart:io';
import 'dart:convert';
import 'package:path_provider/path_provider.dart';
void main() {
  runApp(const FormularioPage());
}

class FormularioPage extends StatelessWidget {
  const FormularioPage({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Auditoría de Mantenimiento',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const FormularioPlantaExterna(),
    );
  }
}

class FormularioPlantaExterna extends StatefulWidget {
  const FormularioPlantaExterna({super.key});
  @override
  State<FormularioPlantaExterna> createState() => _FormularioPlantaExternaState();
}

class _FormularioPlantaExternaState extends State<FormularioPlantaExterna> {
  final _formKey = GlobalKey<FormState>();
  final List<Map<String, dynamic>> _tabla = [];
  int _contador = 1;
  int? _editNro; // para la edición

  // Persistencia local
  Future<File> get _localFile async {
    final directory = await getApplicationDocumentsDirectory();
    return File('${directory.path}/planilla1_data.json');
  }

  Future<void> _cargarDatos() async {
    try {
      final file = await _localFile;
      if (await file.exists()) {
        final contents = await file.readAsString();
        final List<dynamic> jsonData = json.decode(contents);
        _tabla.clear();
        _tabla.addAll(jsonData.cast<Map<String, dynamic>>());
        if (_tabla.isNotEmpty) {
          _contador = _tabla.map((e) => e['contador'] as int).reduce((a, b) => a > b ? a : b) + 1;
          _bloquearCabecera = true;
        }
        setState(() {});
      }
    } catch (_) {}
  }

  Future<void> _guardarDatos() async {
    try {
      final file = await _localFile;
      await file.writeAsString(json.encode(_tabla));
    } catch (_) {}
  }

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  // Nuevos campos encabezado
  final TextEditingController _unidadNegocioController = TextEditingController();
  String _tipoCable = 'Cable alimentador';
  String _hilos = '144 Hilos';
  final TextEditingController _identificacionTramoController = TextEditingController();

  // Bloqueo de casillas iniciales al grabar la primera fila
  bool _bloquearCabecera = false;

  // Observaciones en diseño
  String _observacionesDiseno = 'Sí';

  // Campos unificados y modificados
  final TextEditingController _soporteRetencionController = TextEditingController();
  final TextEditingController _soporteSuspensionController = TextEditingController();
  String _morseteriaIdentificada = 'Bajo Norma';
  String _tipoElemento = 'NAP';
  String _modeloElementoFijado = 'IP65';
  String _elementoFijacion = 'Tirraje';
  final TextEditingController _cantidadElementoController = TextEditingController();
  final TextEditingController _geolocalizacionElementoController = TextEditingController();
  final TextEditingController _tendidoInicioController = TextEditingController();
  final TextEditingController _tendidoFinController = TextEditingController();

  // Reservas
  String _reservasActual = '';
  String _reservasAccion = '';

  final TextEditingController _zonasPodaInicioController = TextEditingController();
  final TextEditingController _zonasPodaFinController = TextEditingController();
  final TextEditingController _postesInstaladosController = TextEditingController();
  final TextEditingController _observacionesController = TextEditingController();
  final TextEditingController _trabajosPendientesController = TextEditingController();
  // Nuevo campo YK01
  final TextEditingController _yk01Controller = TextEditingController();

  // Dropdown para Tendido (Actual/Acción) y Reservas
  String _tendidoActual = 'Bajo norma';
  String _tendidoAccion = 'Se ejecuto mantenimiento';
  final List<String> _opcionesActual = ['Bajo norma', 'Fuera de norma'];
  final List<String> _opcionesAccion = [
    'Se ejecuto mantenimiento',
    'Se agendo mantenimiento',
    'No se procedio mantenimiento'
  ];

  // Opciones para campos dependientes
  final List<String> _opcionesTipoCable = ['Cable alimentador', 'Cable de distribución'];
  final Map<String, List<String>> _opcionesHilos = {
    'Cable alimentador': ['144 Hilos', '96 Hilos', '48 Hilos'],
    'Cable de distribución': [
      'Azul', 'Naranja', 'Verde', 'Marron', 'Gris', 'Blanco', 'Rojo',
      'Negro', 'Amarillo', 'Violeta', 'Rosa', 'Aqua'
    ],
  };
  final List<String> _opcionesMorseteria = ['Bajo Norma', 'Fuera de Norma'];
  final List<String> _opcionesTipoElemento = ['NAP', 'CL', 'FDT', 'FDT Secundario', '-'];
  final Map<String, List<String>> _opcionesModeloElemento = {
    'NAP': ['IP65', 'IP67'],
    'CL': ['288H Continuidad','288H Distribucion','288H Reparacion','144H Continuidad','144H Distribucion','144H Reparacion', 'mini96H'],
    'FDT': ['CL288 ', 'IP67','Otro'],
    'FDT Secundario': ['CL288 ', 'IP67', 'Otro'],
    '-': ['-'],
  };
  final List<String> _opcionesElementoFijacion = ['Tirraje', '1 Fleje', '2 Fleje', 'Otro'];
  final List<String> _opcionesReservasDistribucion = ['Bajo norma', 'Fuera de norma'];
  final List<String> _opcionesObsDiseno = ['Sí', 'No'];

  // Limpia todos los campos y la tabla
  void _limpiarTodo() {
    setState(() {
      _unidadNegocioController.clear();
      _tipoCable = 'Cable alimentador';
      _hilos = _opcionesHilos[_tipoCable]![0];
      _identificacionTramoController.clear();
      _observacionesDiseno = 'No';
      _soporteRetencionController.clear();
      _soporteSuspensionController.clear();
      _morseteriaIdentificada = 'Bajo Norma';
      _tipoElemento = '-';
      _modeloElementoFijado = _opcionesModeloElemento[_tipoElemento]![0];
      _elementoFijacion = 'Tirraje';
      _cantidadElementoController.clear();
      _geolocalizacionElementoController.clear();
      _tendidoInicioController.clear();
      _tendidoFinController.clear();
      _reservasActual = '';
      _reservasAccion = '';
      _zonasPodaInicioController.clear();
      _zonasPodaFinController.clear();
      _postesInstaladosController.clear();
      _observacionesController.clear();
      _trabajosPendientesController.clear();
      _tabla.clear();
      _contador = 1;
      _bloquearCabecera = false;
      _editNro = null;
    });
    _guardarDatos();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Formulario y tabla limpiados')),
    );
  }

  void _grabarFila() {
    if (_formKey.currentState!.validate()) {
      setState(() {
        if (_editNro != null) {
          // Modificación existente
          final index = _tabla.indexWhere((el) => el['contador'] == _editNro);
          if (index != -1) {
            _tabla[index] = _filaActual(_editNro!);
          }
          _editNro = null;
        } else {
          // Nuevo registro
          _tabla.add(_filaActual(_contador));
          _contador++;
          if (_tabla.length == 1) _bloquearCabecera = true;
        }
        _soporteRetencionController.clear();
        _soporteSuspensionController.clear();
        _cantidadElementoController.clear();
        _geolocalizacionElementoController.clear();
        _tendidoInicioController.clear();
        _tendidoFinController.clear();
        _reservasActual = '';
        _reservasAccion = '';
        _zonasPodaInicioController.clear();
        _zonasPodaFinController.clear();
        _postesInstaladosController.clear();
        _observacionesController.clear();
        _trabajosPendientesController.clear();
      });
      _guardarDatos();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_editNro == null ? 'Fila agregada a la tabla' : 'Fila modificada')),
      );
    }
  }

  Map<String, dynamic> _filaActual(int nro) => {
    'contador': nro,
    'unidadNegocio': _unidadNegocioController.text,
    'tipoCable': _tipoCable,
    'hilos': _hilos,
    'yk01': _yk01Controller.text,
    'identificacionTramo': _identificacionTramoController.text,
    'observacionesDiseno': _observacionesDiseno,
    'soporteRetencion': _soporteRetencionController.text,
    'soporteSuspension': _soporteSuspensionController.text,
    'morseteriaIdentificada': _morseteriaIdentificada,
    'tipoElemento': _tipoElemento,
    'modeloElementoFijado': _modeloElementoFijado,
    'elementoFijacion': _elementoFijacion,
    'cantidadElemento': _cantidadElementoController.text,
    'geolocalizacionElemento': _geolocalizacionElementoController.text,
    'tendidoActual': _tendidoActual,
    'tendidoAccion': _tendidoAccion,
    'reservasActual': _reservasActual,
    'reservasAccion': _reservasAccion,
    'zonasPodaInicio': _zonasPodaInicioController.text,
    'zonasPodaFin': _zonasPodaFinController.text,
    'postesInstalados': _postesInstaladosController.text,
    'observaciones': _observacionesController.text,
    'trabajosPendientes': _trabajosPendientesController.text,
  };

  void _cargarFila(int nro) {
    final fila = _tabla.firstWhere((el) => el['contador'] == nro, orElse: () => {});
    if (fila.isNotEmpty) {
      setState(() {
        _editNro = nro;
        _unidadNegocioController.text = fila['unidadNegocio'];
        _tipoCable = fila['tipoCable'];
        _hilos = fila['hilos'];
        _identificacionTramoController.text = fila['identificacionTramo'];
        _observacionesDiseno = fila['observacionesDiseno'] ?? 'Sí';
        _soporteRetencionController.text = fila['soporteRetencion'];
        _soporteSuspensionController.text = fila['soporteSuspension'];
        _morseteriaIdentificada = fila['morseteriaIdentificada'];
        _tipoElemento = fila['tipoElemento'];
        _modeloElementoFijado = fila['modeloElementoFijado'];
        _elementoFijacion = fila['elementoFijacion'];
        _cantidadElementoController.text = fila['cantidadElemento'];
        _geolocalizacionElementoController.text = fila['geolocalizacionElemento'];
        _tendidoInicioController.text = fila['tendidoInicio'];
        _tendidoFinController.text = fila['tendidoFin'];
        _reservasActual = fila['reservasActual'];
        _reservasAccion = fila['reservasAccion'];
        _zonasPodaInicioController.text = fila['zonasPodaInicio'];
        _zonasPodaFinController.text = fila['zonasPodaFin'];
        _postesInstaladosController.text = fila['postesInstalados'];
        _observacionesController.text = fila['observaciones'];
        _trabajosPendientesController.text = fila['trabajosPendientes'];
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No existe Nro en la tabla')),
      );
    }
  }

  Future<void> _exportarPDF() async {
    final pdf = pw.Document();
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.letter.landscape,
        margin: const pw.EdgeInsets.all(12),
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('Auditoría de Mantenimiento', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 8),
              pw.Text(
                '${_unidadNegocioController.text}'  '     Identificación de tramo:     ${_identificacionTramoController.text}',
                style: pw.TextStyle(fontSize: 12),
              ),
              pw.Divider(),
              pw.Table(
                border: pw.TableBorder.all(width: 0.5, color: PdfColors.black),
                defaultVerticalAlignment: pw.TableCellVerticalAlignment.middle,
                children: [
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(color: PdfColors.grey300),
                    children: [
                      pw.Text('Nro', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 5)),
                      pw.Text('Ubicación    ', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 5)),
                      pw.Text('YK01 ', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 5)),
                      pw.Text('S.R. ', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 5)),
                      pw.Text('S.S. ', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 5)),
                      pw.Text('Morsetería ', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 5)),
                      pw.Text('Tipo de Elemento', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 5)),
                      pw.Text('Modelo   ', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 5)),
                      pw.Text('Elemento de fijación', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 5)),
                      pw.Text('Cantidad', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 5)),
                      pw.Text('Tendido inicio', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 5)),
                      pw.Text('Tendido fin', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 5)),
                      pw.Text('Reservas Actual', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 5)),
                      pw.Text('Reservas Acción', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 5)),
                      pw.Text('Zonas poda inicio  ', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 5)),
                      pw.Text('Zonas poda fin     ', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 5)),
                      pw.Text('Postes instalados', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 5)),
                      pw.Text('Obs. diseño', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 5)),
                      pw.Text('Obs general', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 5)),
                      pw.Text('Trabajos pendientes', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 5)),
                    ],
                  ),
                  ..._tabla.map((fila) => pw.TableRow(
                    children: [
pw.Text('${fila['contador']}', style: const pw.TextStyle(fontSize: 6)),
pw.Text(fila['geolocalizacionElemento'] ?? '', style: const pw.TextStyle(fontSize: 6)),
pw.Text(fila['yK01'] ?? '', style: const pw.TextStyle(fontSize: 6)),                    
pw.Text(fila['soporteRetencion'] ?? '', style: const pw.TextStyle(fontSize: 6)),
pw.Text(fila['soporteSuspension'] ?? '', style: const pw.TextStyle(fontSize: 6)),
pw.Text(fila['morseteriaIdentificada'] ?? '', style: const pw.TextStyle(fontSize: 6)),
pw.Text(fila['tipoElemento'] ?? '', style: const pw.TextStyle(fontSize: 6)),
pw.Text(fila['modeloElementoFijado'] ?? '', style: const pw.TextStyle(fontSize: 6)),
pw.Text(fila['elementoFijacion'] ?? '', style: const pw.TextStyle(fontSize: 6)),
pw.Text(fila['cantidadElemento'] ?? '', style: const pw.TextStyle(fontSize: 6)),
pw.Text(fila['tendidoInicio'] ?? '', style: const pw.TextStyle(fontSize: 6)),
pw.Text(fila['tendidoFin'] ?? '', style: const pw.TextStyle(fontSize: 6)),
pw.Text(fila['reservasActual'] ?? '', style: const pw.TextStyle(fontSize: 6)),
pw.Text(fila['reservasAccion'] ?? '', style: const pw.TextStyle(fontSize: 6)),
pw.Text(fila['zonasPodaInicio'] ?? '', style: const pw.TextStyle(fontSize: 6)),
pw.Text(fila['zonasPodaFin'] ?? '', style: const pw.TextStyle(fontSize: 6)),
pw.Text(fila['postesInstalados'] ?? '', style: const pw.TextStyle(fontSize: 6)),
pw.Text(fila['observacionesDiseno'] ?? '', style: const pw.TextStyle(fontSize: 6)),
pw.Text(fila['observaciones'] ?? '', style: const pw.TextStyle(fontSize: 6)),
            pw.Text(fila['trabajosPendientes'] ?? '', style: const pw.TextStyle(fontSize: 6)),
                    ],
                  )),
                ],
              ),
            ],
          );
        },
      ),
    );
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hilosOptions = _opcionesHilos[_tipoCable]!;
    if (!hilosOptions.contains(_hilos)) _hilos = hilosOptions[0];
    // Filtrado de Tipo de Elemento según Tipo de cable
    final tipoElementoOptions = _tipoCable == 'Cable alimentador'
        ? _opcionesTipoElemento.where((e) => e == 'CL' || e == '-').toList()
        : _opcionesTipoElemento.where((e) => e == 'FDT' || e == 'FDT Secundario' || e == 'NAP').toList();
    if (!tipoElementoOptions.contains(_tipoElemento)) _tipoElemento = tipoElementoOptions[0];
    final modeloOptions = _opcionesModeloElemento[_tipoElemento]!;
    if (!modeloOptions.contains(_modeloElementoFijado)) _modeloElementoFijado = modeloOptions[0];

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.of(context).pushReplacementNamed('/welcome_page');
          },
        ),
        title: const Text('Auditoría de Mantenimiento'),
      ),
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
                    _buildTextField('Unidad de Negocio', _unidadNegocioController, enabled: !_bloquearCabecera),
                    _buildDropdownField('Tipo de cable', _tipoCable, _opcionesTipoCable, (val) {
                      setState(() { _tipoCable = val!; _hilos = _opcionesHilos[val]![0]; });
                    }, enabled: !_bloquearCabecera),
                    _buildTextField('Identificación de tramo', _identificacionTramoController, enabled: !_bloquearCabecera),
                    _buildDropdownField('Hilos', _hilos, hilosOptions, (val) {
                      setState(() { _hilos = val!; });
                    }, enabled: !_bloquearCabecera),
                    _buildTextField('YK01', _yk01Controller),
                    GeoField(
                      controller: _geolocalizacionElementoController,
                      label: 'Geolocalización del elemento fijado',
                    ),
                    _buildDropdownField('Observaciones en diseño', _observacionesDiseno, _opcionesObsDiseno, (val) {
                      setState(() { _observacionesDiseno = val!; });
                    }),
                    _buildTextField('Soporte de Retención $_tipoCable $_hilos', _soporteRetencionController),
                    _buildTextField('Soporte de Suspensión $_tipoCable $_hilos', _soporteSuspensionController),
                    _buildDropdownField('Identificación de la morsetería', _morseteriaIdentificada, _opcionesMorseteria, (val) {
                      setState(() { _morseteriaIdentificada = val!; });
                    }),
                    _buildDropdownField('Tipo de Elemento', _tipoElemento, tipoElementoOptions, (val) {
                      setState(() { _tipoElemento = val!; _modeloElementoFijado = _opcionesModeloElemento[val]![0]; });
                    }),
                    _buildDropdownField('Modelo de elemento fijado', _modeloElementoFijado, modeloOptions, (val) {
                      setState(() { _modeloElementoFijado = val!; });
                    }),
                    _buildDropdownField('Elemento de fijación', _elementoFijacion, _opcionesElementoFijacion, (val) {
                      setState(() { _elementoFijacion = val!; });
                    }),
                    _buildTextField('Cantidad', _cantidadElementoController),
                    _buildDropdownField('Tendido con perdida de tensión Geolocalización Actual', _tendidoActual, _opcionesActual, (val) { setState(() { _tendidoActual = val!; }); }),
                    _buildDropdownField('Tendido con perdida de tensión Geolocalización Acción', _tendidoAccion, _opcionesAccion, (val) { setState(() { _tendidoAccion = val!; }); }),
                    // Reservas (dropdowns)
                    _buildDropdownField('Reservas Actual', _reservasActual.isNotEmpty ? _reservasActual : _opcionesActual[0], _opcionesActual, (val) {
                      setState(() { _reservasActual = val!; });
                    }),
                    _buildDropdownField('Reservas Acción', _reservasAccion.isNotEmpty ? _reservasAccion : _opcionesAccion[0], _opcionesAccion, (val) {
                      setState(() { _reservasAccion = val!; });
                    }),
                    GeoField(
                      controller: _zonasPodaInicioController,
                      label: 'Geolocalización de zona poda inicio',
                    ),
                    GeoField(
                      controller: _zonasPodaFinController,
                      label: 'Geolocalización de zona poda fin',
                    ),
                    _buildTextField('Postes propiedad de Inter instalados', _postesInstaladosController),
                    _buildTextField('Observaciones', _observacionesController),
                    _buildTextField('Trabajos pendientes', _trabajosPendientesController),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        ElevatedButton.icon(
                          icon: Icon(_editNro == null ? Icons.add : Icons.edit),
                          label: Text(_editNro == null ? 'Guardar' : 'Actualizar'),
                          onPressed: _grabarFila,
                        ),
                        ElevatedButton.icon(
                          icon: const Icon(Icons.picture_as_pdf),
                          label: const Text('Exportar'),
                          onPressed: _tabla.isEmpty ? null : _exportarPDF,
                        ),
                        ElevatedButton.icon(
                          icon: const Icon(Icons.cleaning_services),
                          label: const Text('Limpiar todo'),
                          onPressed: _limpiarTodo,
                        ),
                        ElevatedButton.icon(
                          icon: const Icon(Icons.search),
                          label: const Text('Modificar'),
                          onPressed: () async {
                            int? nro = await showDialog<int>(
                              context: context,
                              builder: (context) {
                                int? nroEditar;
                                return AlertDialog(
                                  title: const Text('Modificar fila'),
                                  content: TextField(
                                    autofocus: true,
                                    decoration: const InputDecoration(labelText: "Nro (fila)"),
                                    keyboardType: TextInputType.number,
                                    onChanged: (v) => nroEditar = int.tryParse(v),
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(context),
                                      child: const Text('Cancelar'),
                                    ),
                                    TextButton(
                                      onPressed: () => Navigator.pop(context, nroEditar),
                                      child: const Text('Cargar'),
                                    ),
                                  ],
                                );
                              },
                            );
                            if (nro != null) _cargarFila(nro);
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Tabla
          Expanded(
            flex: 1,
            child: Container(
              color: Colors.blue[100],
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
                        child: DataTable(
                          columns: const [
                            DataColumn(label: Text('Nro')),
                            DataColumn(label: Text('Unidad Negocio')),
                            DataColumn(label: Text('Tipo cable')),
                            DataColumn(label: Text('Hilos')),
                            DataColumn(label: Text('YK01')),
                            DataColumn(label: Text('Identificación tramo')),
                            DataColumn(label: Text('Obs. Diseño')),
                            DataColumn(label: Text('Soporte de Retención')),
                            DataColumn(label: Text('Soporte de Suspensión')),
                            DataColumn(label: Text('Morsetería')),
                            DataColumn(label: Text('Tipo de Elemento')),
                            DataColumn(label: Text('Modelo')),
                            DataColumn(label: Text('Elemento de fijación')),
                            DataColumn(label: Text('Cantidad')),
                            DataColumn(label: Text('Geolocalización')),
                            DataColumn(label: Text('Tendido Actual')),
                            DataColumn(label: Text('Tendido Acción')),
                            DataColumn(label: Text('Reservas Actual')),
                            DataColumn(label: Text('Reservas Acción')),
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
                                DataCell(Text(fila['unidadNegocio'] ?? '')),
                                DataCell(Text(fila['tipoCable'] ?? '')),
                                DataCell(Text(fila['hilos'] ?? '')),
                                DataCell(Text(fila['yk01'] ?? '')),
                                DataCell(Text(fila['identificacionTramo'] ?? '')),
                                DataCell(Text(fila['observacionesDiseno'] ?? '')),
                                DataCell(Text(fila['soporteRetencion'] ?? '')),
                                DataCell(Text(fila['soporteSuspension'] ?? '')),
                                DataCell(Text(fila['morseteriaIdentificada'] ?? '')),
                                DataCell(Text(fila['tipoElemento'] ?? '')),
                                DataCell(Text(fila['modeloElementoFijado'] ?? '')),
                                DataCell(Text(fila['elementoFijacion'] ?? '')),
                                DataCell(Text(fila['cantidadElemento'] ?? '')),
                                DataCell(Text(fila['geolocalizacionElemento'] ?? '')),
                                DataCell(Text(fila['tendidoActual'] ?? '')),
                                DataCell(Text(fila['tendidoAccion'] ?? '')),
                                DataCell(Text(fila['reservasActual'] ?? '')),
                                DataCell(Text(fila['reservasAccion'] ?? '')),
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
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, {bool enabled = true}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: TextFormField(
        controller: controller,
        enabled: enabled,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          isDense: true,
        ),
      ),
    );
  }

  Widget _buildTextFieldReservas(String label, Function(String) onChanged, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: TextFormField(
        initialValue: value,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          isDense: true,
        ),
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildDropdownField(String label, String value, List<String> items, ValueChanged<String?> onChanged, {bool enabled = true}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: DropdownButtonFormField<String>(
        value: value,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          isDense: true,
        ),
        items: items.map((item) => DropdownMenuItem(value: item, child: Text(item))).toList(),
        onChanged: enabled ? onChanged : null,
      ),
    );
  }
}