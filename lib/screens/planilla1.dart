import 'package:flutter/material.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';

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
      routes: {
        '/welcome_page': (context) => const Placeholder(), // Cambia esto por tu WelcomePage real
      },
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
  int? _editNro; // para edición

  // Encabezado y controladores
  final TextEditingController _unidadNegocioController = TextEditingController();
  String _tipoCable = 'Cable alimentador';
  String _hilos = 'Azul';
  final TextEditingController _identificacionTramoController = TextEditingController();

  bool _bloquearCabecera = false;
  String _observacionesDiseno = 'Sí';

  // Poste propiedad de Inter y acción
  String _posteInter = 'Sí';
  final TextEditingController _accionPosteInterController = TextEditingController();

  // Materiales utilizados
  String _materialesUtilizados = 'Adición de fleje faltante';

  // Campos modif./unificados/condicionales
  final TextEditingController _soporteRetencionController = TextEditingController();
  final TextEditingController _soporteSuspensionController = TextEditingController();
  String _morseteriaIdentificada = 'Bajo Norma';
  String _tipoElemento = 'CL';
  String _modeloElementoFijado = '288H';
  String _elementoFijacion = 'Tirraje';
  final TextEditingController _cantidadElementoController = TextEditingController();
  final TextEditingController _geolocalizacionElementoController = TextEditingController();
  final TextEditingController _tendidoInicioController = TextEditingController();
  final TextEditingController _tendidoFinController = TextEditingController();

  String _reservasActual = '';
  String _reservasAccion = '';

  final TextEditingController _zonasPodaInicioController = TextEditingController();
  final TextEditingController _zonasPodaFinController = TextEditingController();
  final TextEditingController _observacionesController = TextEditingController();
  final TextEditingController _trabajosPendientesController = TextEditingController();

  // Opciones
  final List<String> _opcionesTipoCable = [
    'Cable alimentador',
    'Cable de distribución',
    '4 Hilos'
  ];
  final List<String> _opcionesHilosDistribucion = [
    'Azul', 'Naranja', 'Verde', 'Marron', 'Gris', 'Blanco', 'Rojo',
    'Negro', 'Amarillo', 'Violeta', 'Rosa', 'Aqua'
  ];
  final Map<String, List<String>> _opcionesHilos = {
    'Cable alimentador': ['144 Hilos', '96 Hilos', '48 Hilos'],
    'Cable de distribución': [
      'Azul', 'Naranja', 'Verde', 'Marron', 'Gris', 'Blanco', 'Rojo',
      'Negro', 'Amarillo', 'Violeta', 'Rosa', 'Aqua'
    ],
    '4 Hilos': [
      'Azul', 'Naranja', 'Verde', 'Marron', 'Gris', 'Blanco', 'Rojo',
      'Negro', 'Amarillo', 'Violeta', 'Rosa', 'Aqua'
    ],
  };
  final List<String> _opcionesMorseteria = ['Bajo Norma', 'Fuera de Norma'];
  final List<String> _opcionesElementoFijacion = ['Tirraje', '1 Fleje', '2 Fleje', 'Otro'];
  final List<String> _opcionesMateriales = [
    'Adición de fleje faltante',
    'Adición de precinto en reserva',
    'Colocación de etiqueta',
    'Reemplazo de Soporte de Retención',
    'Reemplazo de Soporte de Suspensión',
    'Colocación de YK01',
  ];
  final List<String> _opcionesPosteInter = ['Sí', 'No'];
  final List<String> _opcionesReservasDistribucion = ['Bajo norma', 'Fuera de norma'];
  final List<String> _opcionesObsDiseno = ['Sí', 'No'];

  final Map<String, List<String>> _opcionesModeloElemento = {
    'NAP': ['IP65', 'IP67'],
    'CL': ['288H', '144H', 'mini96H'],
    'FDT': ['CL288', 'IP67'],
    '-': ['-'],
  };

  // Etiquetas condicionales
  String get labelTramo => _tipoCable == '4 Hilos' ? 'FDT padre' : 'Identificación de tramo';
  String get labelSoporteRetencion => _tipoCable == '4 Hilos' ? 'Soporte de Fibra Plana' : 'Soporte de Retención';
  String get labelSoporteSuspension => _tipoCable == '4 Hilos' ? 'Nomenclatura del NAP' : 'Soporte de Suspensión';
  List<String> get opcionesTipoElemento {
    if (_tipoCable == '4 Hilos') return ['NAP', '-'];
    if (_tipoCable == 'Cable de distribución') return ['CL', 'FDT'];
    if (_tipoCable == 'Cable alimentador') return ['CL', 'FDT']; // NAP no permitido
    return ['CL', 'FDT'];
  }
  bool get bloquearNomenclaturaNAP => _tipoCable == '4 Hilos' && _tipoElemento == '-';

  // Limpia todos los campos y la tabla
  void _limpiarTodo() {
    setState(() {
      _unidadNegocioController.clear();
      _tipoCable = 'Cable alimentador';
      _hilos = _opcionesHilos[_tipoCable]![0];
      _identificacionTramoController.clear();
      _observacionesDiseno = 'Sí';
      _posteInter = 'Sí';
      _accionPosteInterController.clear();
      _materialesUtilizados = _opcionesMateriales[0];
      _soporteRetencionController.clear();
      _soporteSuspensionController.clear();
      _morseteriaIdentificada = 'Bajo Norma';
      _tipoElemento = opcionesTipoElemento[0];
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
      _observacionesController.clear();
      _trabajosPendientesController.clear();
      _tabla.clear();
      _contador = 1;
      _bloquearCabecera = false;
      _editNro = null;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Formulario y tabla limpiados')),
    );
  }

  void _grabarFila() {
    if (_formKey.currentState!.validate()) {
      setState(() {
        if (_editNro != null) {
          final index = _tabla.indexWhere((el) => el['contador'] == _editNro);
          if (index != -1) {
            _tabla[index] = _filaActual(_editNro!);
          }
          _editNro = null;
        } else {
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
        _observacionesController.clear();
        _trabajosPendientesController.clear();
        _accionPosteInterController.clear();
        _materialesUtilizados = _opcionesMateriales[0];
        _posteInter = 'Sí';
      });
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
    'identificacionTramo': _identificacionTramoController.text,
    'observacionesDiseno': _observacionesDiseno,
    'posteInter': _posteInter,
    'accionPosteInter': _posteInter == 'Sí' ? _accionPosteInterController.text : ' - ',
    'materialesUtilizados': _materialesUtilizados,
    'soporteRetencion': _soporteRetencionController.text,
    'soporteSuspension': _tipoCable == '4 Hilos' && _tipoElemento == '-' ? ' - ' : _soporteSuspensionController.text,
    'morseteriaIdentificada': _morseteriaIdentificada,
    'tipoElemento': _tipoElemento,
    'modeloElementoFijado': _modeloElementoFijado,
    'elementoFijacion': _elementoFijacion,
    'cantidadElemento': _cantidadElementoController.text,
    'geolocalizacionElemento': _geolocalizacionElementoController.text,
    'tendidoInicio': _tendidoInicioController.text,
    'tendidoFin': _tendidoFinController.text,
    'reservasActual': _reservasActual,
    'reservasAccion': _reservasAccion,
    'zonasPodaInicio': _zonasPodaInicioController.text,
    'zonasPodaFin': _zonasPodaFinController.text,
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
        _posteInter = fila['posteInter'] ?? 'Sí';
        _accionPosteInterController.text = fila['accionPosteInter'] ?? '';
        _materialesUtilizados = fila['materialesUtilizados'] ?? _opcionesMateriales[0];
        _soporteRetencionController.text = fila['soporteRetencion'] ?? '';
        _soporteSuspensionController.text = fila['soporteSuspension'] == ' - ' ? '' : fila['soporteSuspension'] ?? '';
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
                '${_tipoCable == "4 Hilos" ? "FDT padre" : "Identificación de tramo"}: ${_identificacionTramoController.text}',
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
                      pw.Text('Nro', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8)),
                      pw.Text('Unidad Negocio', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8)),
                      pw.Text('Tipo cable', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8)),
                      pw.Text('Hilos', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8)),
                      pw.Text('Obs. Diseño', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8)),
                      pw.Text('Poste Inter', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8)),
                      pw.Text('Acción Poste Inter', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8)),
                      pw.Text('Materiales', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8)),
                      pw.Text(labelSoporteRetencion, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8)),
                      pw.Text(labelSoporteSuspension, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8)),
                      pw.Text('Morsetería', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8)),
                      pw.Text('Tipo de Elemento', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8)),
                      pw.Text('Modelo', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8)),
                      pw.Text('Elemento de fijación', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8)),
                      pw.Text('Cantidad', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8)),
                      pw.Text('Geolocalización', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8)),
                      pw.Text('Tendido inicio', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8)),
                      pw.Text('Tendido fin', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8)),
                      pw.Text('Reservas Actual', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8)),
                      pw.Text('Reservas Acción', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8)),
                      pw.Text('Zonas poda inicio', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8)),
                      pw.Text('Zonas poda fin', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8)),
                      pw.Text('Observaciones', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8)),
                      pw.Text('Trabajos pendientes', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8)),
                    ],
                  ),
                  ..._tabla.map((fila) => pw.TableRow(
                    children: [
                      pw.Text('${fila['contador']}', style: const pw.TextStyle(fontSize: 8)),
                      pw.Text(fila['unidadNegocio'] ?? '', style: const pw.TextStyle(fontSize: 8)),
                      pw.Text(fila['tipoCable'] ?? '', style: const pw.TextStyle(fontSize: 8)),
                      pw.Text(fila['hilos'] ?? '', style: const pw.TextStyle(fontSize: 8)),
                      pw.Text(fila['observacionesDiseno'] ?? '', style: const pw.TextStyle(fontSize: 8)),
                      pw.Text(fila['posteInter'] ?? '', style: const pw.TextStyle(fontSize: 8)),
                      pw.Text(fila['accionPosteInter'] ?? '', style: const pw.TextStyle(fontSize: 8)),
                      pw.Text(fila['materialesUtilizados'] ?? '', style: const pw.TextStyle(fontSize: 8)),
                      pw.Text(fila['soporteRetencion'] ?? '', style: const pw.TextStyle(fontSize: 8)),
                      pw.Text(fila['soporteSuspension'] ?? '', style: const pw.TextStyle(fontSize: 8)),
                      pw.Text(fila['morseteriaIdentificada'] ?? '', style: const pw.TextStyle(fontSize: 8)),
                      pw.Text(fila['tipoElemento'] ?? '', style: const pw.TextStyle(fontSize: 8)),
                      pw.Text(fila['modeloElementoFijado'] ?? '', style: const pw.TextStyle(fontSize: 8)),
                      pw.Text(fila['elementoFijacion'] ?? '', style: const pw.TextStyle(fontSize: 8)),
                      pw.Text(fila['cantidadElemento'] ?? '', style: const pw.TextStyle(fontSize: 8)),
                      pw.Text(fila['geolocalizacionElemento'] ?? '', style: const pw.TextStyle(fontSize: 8)),
                      pw.Text(fila['tendidoInicio'] ?? '', style: const pw.TextStyle(fontSize: 8)),
                      pw.Text(fila['tendidoFin'] ?? '', style: const pw.TextStyle(fontSize: 8)),
                      pw.Text(fila['reservasActual'] ?? '', style: const pw.TextStyle(fontSize: 8)),
                      pw.Text(fila['reservasAccion'] ?? '', style: const pw.TextStyle(fontSize: 8)),
                      pw.Text(fila['zonasPodaInicio'] ?? '', style: const pw.TextStyle(fontSize: 8)),
                      pw.Text(fila['zonasPodaFin'] ?? '', style: const pw.TextStyle(fontSize: 8)),
                      pw.Text(fila['observaciones'] ?? '', style: const pw.TextStyle(fontSize: 8)),
                      pw.Text(fila['trabajosPendientes'] ?? '', style: const pw.TextStyle(fontSize: 8)),
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
    final tipoElementoOptions = _tipoCable == '4 Hilos'
        ? ['NAP', '-']
        : ['CL', 'FDT'];
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
                    _buildTextField(labelTramo, _identificacionTramoController, enabled: !_bloquearCabecera),
                    _buildDropdownField('Hilos', _hilos, hilosOptions, (val) {
                      setState(() { _hilos = val!; });
                    }, enabled: !_bloquearCabecera),
                    _buildDropdownField('Observaciones en diseño', _observacionesDiseno, _opcionesObsDiseno, (val) {
                      setState(() { _observacionesDiseno = val!; });
                    }),
                    _buildDropdownField('Poste propiedad de Inter', _posteInter, _opcionesPosteInter, (val) {
                      setState(() { _posteInter = val!; if (_posteInter == 'No') _accionPosteInterController.text = ' - '; else _accionPosteInterController.clear(); });
                    }),
                    _buildTextField('Acción Poste propiedad de Inter', _accionPosteInterController, enabled: _posteInter == 'Sí'),
                    _buildDropdownField('Materiales utilizados', _materialesUtilizados, _opcionesMateriales, (val) {
                      setState(() { _materialesUtilizados = val!; });
                    }),
                    _buildTextField(labelSoporteRetencion, _soporteRetencionController),
                    _buildTextField(labelSoporteSuspension, _soporteSuspensionController, enabled: !bloquearNomenclaturaNAP),
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
                    _buildTextField('Geolocalización del elemento fijado', _geolocalizacionElementoController),
                    _buildTextField('Tendido con perdida de tensión Geolocalización inicio', _tendidoInicioController),
                    _buildTextField('Tendido con perdida de tensión Geolocalización fin', _tendidoFinController),
                    if (_tipoCable == 'Cable alimentador') ...[
                      _buildTextFieldReservas('Reservas $_hilos Actual', (val) => setState(() => _reservasActual = val), _reservasActual),
                      _buildTextFieldReservas('Reservas $_hilos Acción', (val) => setState(() => _reservasAccion = val), _reservasAccion),
                    ] else ...[
                      _buildDropdownField('Reservas 12H Actual', _reservasActual.isNotEmpty ? _reservasActual : _opcionesReservasDistribucion[0], _opcionesReservasDistribucion, (val) {
                        setState(() { _reservasActual = val!; });
                      }),
                      _buildDropdownField('Reservas 12H Acción', _reservasAccion.isNotEmpty ? _reservasAccion : _opcionesReservasDistribucion[0], _opcionesReservasDistribucion, (val) {
                        setState(() { _reservasAccion = val!; });
                      }),
                    ],
                    _buildTextField('Geolocalización de zona poda inicio', _zonasPodaInicioController),
                    _buildTextField('Geolocalización de zona poda fin', _zonasPodaFinController),
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
                          columns: [
                            const DataColumn(label: Text('Nro')),
                            const DataColumn(label: Text('Unidad Negocio')),
                            const DataColumn(label: Text('Tipo cable')),
                            const DataColumn(label: Text('Hilos')),
                            DataColumn(label: Text(labelTramo)),
                            const DataColumn(label: Text('Obs. Diseño')),
                            const DataColumn(label: Text('Poste Inter')),
                            const DataColumn(label: Text('Acción Poste Inter')),
                            const DataColumn(label: Text('Materiales')),
                            DataColumn(label: Text(labelSoporteRetencion)),
                            DataColumn(label: Text(labelSoporteSuspension)),
                            const DataColumn(label: Text('Morsetería')),
                            const DataColumn(label: Text('Tipo de Elemento')),
                            const DataColumn(label: Text('Modelo')),
                            const DataColumn(label: Text('Elemento de fijación')),
                            const DataColumn(label: Text('Cantidad')),
                            const DataColumn(label: Text('Geolocalización')),
                            const DataColumn(label: Text('Tendido inicio')),
                            const DataColumn(label: Text('Tendido fin')),
                            const DataColumn(label: Text('Reservas Actual')),
                            const DataColumn(label: Text('Reservas Acción')),
                            const DataColumn(label: Text('Zonas poda inicio')),
                            const DataColumn(label: Text('Zonas poda fin')),
                            const DataColumn(label: Text('Observaciones')),
                            const DataColumn(label: Text('Trabajos pendientes')),
                          ],
                          rows: _tabla.map((fila) {
                            return DataRow(
                              cells: [
                                DataCell(Text('${fila['contador']}')),
                                DataCell(Text(fila['unidadNegocio'] ?? '')),
                                DataCell(Text(fila['tipoCable'] ?? '')),
                                DataCell(Text(fila['hilos'] ?? '')),
                                DataCell(Text(fila['identificacionTramo'] ?? '')),
                                DataCell(Text(fila['observacionesDiseno'] ?? '')),
                                DataCell(Text(fila['posteInter'] ?? '')),
                                DataCell(Text(fila['accionPosteInter'] ?? '')),
                                DataCell(Text(fila['materialesUtilizados'] ?? '')),
                                DataCell(Text(fila['soporteRetencion'] ?? '')),
                                DataCell(Text(fila['soporteSuspension'] ?? '')),
                                DataCell(Text(fila['morseteriaIdentificada'] ?? '')),
                                DataCell(Text(fila['tipoElemento'] ?? '')),
                                DataCell(Text(fila['modeloElementoFijado'] ?? '')),
                                DataCell(Text(fila['elementoFijacion'] ?? '')),
                                DataCell(Text(fila['cantidadElemento'] ?? '')),
                                DataCell(Text(fila['geolocalizacionElemento'] ?? '')),
                                DataCell(Text(fila['tendidoInicio'] ?? '')),
                                DataCell(Text(fila['tendidoFin'] ?? '')),
                                DataCell(Text(fila['reservasActual'] ?? '')),
                                DataCell(Text(fila['reservasAccion'] ?? '')),
                                DataCell(Text(fila['zonasPodaInicio'] ?? '')),
                                DataCell(Text(fila['zonasPodaFin'] ?? '')),
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