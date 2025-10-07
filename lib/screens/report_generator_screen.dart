import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:pdf/widgets.dart' as pw;
// ignore: unused_import
import 'package:printing/printing.dart';

import 'package:flutter/services.dart';
import 'report_logic.dart';
import '../data/form_data_manager.dart';

class ReportGeneratorScreen extends StatefulWidget {
  const ReportGeneratorScreen({super.key});

  @override
  State<ReportGeneratorScreen> createState() => _ReportGeneratorScreenState();
}

class _ReportGeneratorScreenState extends State<ReportGeneratorScreen> {
  // Campos fijos
  final TextEditingController _tecnicoController = TextEditingController();
  final TextEditingController _unidadNegocioController = TextEditingController();
  final TextEditingController _feederController = TextEditingController();
  final TextEditingController _closureController = TextEditingController();
  final TextEditingController _bufferController = TextEditingController();
  final TextEditingController _hiloController = TextEditingController();
  DateTime _fechaActual = DateTime.now();
  Position? _ubicacionActual;

  // Selección de elemento principal
  String? _elementoSeleccionado;
  final List<String> _elementos = ['FDT', 'Closure', 'NAP'];

  // Campos de nomenclatura para cada tipo
  final Map<String, TextEditingController> _napCampos = {
    'FDT padre': TextEditingController(),
    'Nro Distribución Secundario': TextEditingController(),
    'Nro de NAP': TextEditingController(),
  };

  final Map<String, TextEditingController> _fdtCamposNo = {
    'Closure padre': TextEditingController(),
    'Distribucion': TextEditingController(),
    'Nro FDT': TextEditingController(),
  };

  final Map<String, TextEditingController> _fdtCamposSi = {
    'Closure Secundario padre': TextEditingController(),
    'Distribucion': TextEditingController(),
    'Numero de FDT': TextEditingController(),
  };

  final Map<String, TextEditingController> _closureDistribucionCampos = {
    'Feeder': TextEditingController(),
    'Nro Closure': TextEditingController(),
  };

  final Map<String, TextEditingController> _closureSecundarioCampos = {
    'Closure padre': TextEditingController(),
    'Distribucion': TextEditingController(),
    'Closure secundario': TextEditingController(),
  };

  final Map<String, TextEditingController> _closureContinuidadCampos = {
    'Nro Closure': TextEditingController(),
  };

  final Map<String, TextEditingController> _closureReparacionCampos = {
    'Nro Closure de reparacion': TextEditingController(),
  };

  String? _closureNaturaleza;
  String? _fdtConClosureSecundario;

  // Nomenclatura final generada
  String _nomenclatura = "";

  // Campos técnicos comunes
  String _tipoInstalacion = 'Aerea';
  final TextEditingController _distanciaNapFdtController = TextEditingController();
  final TextEditingController _distanciaFdtOdfController = TextEditingController();
  final TextEditingController _cantidadEmpalmesController = TextEditingController();
  final TextEditingController _tipoSplitterController = TextEditingController();
  final TextEditingController _cantidadSplitterController = TextEditingController();
  String _contieneEtiquetaIdentificacion = 'Si';
  String _armadoBajoNorma = 'Si';
  String _fijacionBajoNorma = 'Si';
  final TextEditingController _cantidadCablesSalidaController = TextEditingController();
  bool _datosListos = false;
  
  // Mediciones guardadas
  final Map<String, Map<int, String>> _medicionesGuardadas = {};
  
  String? _longitudOnda;
  
  // Controladores para mediciones de puertos
  final Map<int, TextEditingController> _medicionesPuertos = {};
  
  // Archivo PDF de trazas OTDR
  PlatformFile? _archivoOtdr;

  // Secciones de fotos y adjuntos
  final Map<String, List<PlatformFile>> _fotosPorSeccion = {};

  // Control de pestañas retraíbles
  final Map<String, bool> _seccionesExpand = {};

  // Distribución por buffer para Closure Distribución
  final List<String> _distribucionBuffers = [];
  String? _bufferSeleccionado;

  bool _generando = false;
  final FormDataManager _dataManager = FormDataManager();

  @override
  void initState() {
    super.initState();
    _obtenerUbicacion();
    _loadSavedData();
  }
  
  void _loadSavedData() {
    final savedData = _dataManager.getPlanilla2Data();
    if (savedData.isNotEmpty) {
      setState(() {
        _tecnicoController.text = savedData['tecnico'] ?? '';
        _unidadNegocioController.text = savedData['unidadNegocio'] ?? '';
        _feederController.text = savedData['feeder'] ?? '';
        _closureController.text = savedData['closure'] ?? '';
        _bufferController.text = savedData['buffer'] ?? '';
        _hiloController.text = savedData['hilo'] ?? '';
        _elementoSeleccionado = savedData['elemento'];
        _closureNaturaleza = savedData['closureNaturaleza'];
        _fdtConClosureSecundario = savedData['fdtConClosureSecundario'];
        _nomenclatura = savedData['nomenclatura'] ?? '';
        _tipoInstalacion = savedData['tipoInstalacion'] ?? 'Aerea';
        _contieneEtiquetaIdentificacion = savedData['contieneEtiquetaIdentificacion'] ?? 'Si';
        _armadoBajoNorma = savedData['armadoBajoNorma'] ?? 'Si';
        _fijacionBajoNorma = savedData['fijacionBajoNorma'] ?? 'Si';
        _longitudOnda = savedData['longitudOnda'];
        _datosListos = savedData['datosListos'] ?? false;
        if (savedData['distribucionBuffers'] != null) {
          _distribucionBuffers.clear();
          _distribucionBuffers.addAll(List<String>.from(savedData['distribucionBuffers']));
        }
      });
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

  void _actualizarNomenclatura() {
    setState(() {
      _nomenclatura = _getNomenclatura();
    });
  }

  String _getNomenclatura() {
    switch (_elementoSeleccionado) {
      case "NAP":
        return "M${_napCampos['FDT padre']?.text ?? ""}-CS${_napCampos['Nro Distribución Secundario']?.text ?? ""}-N${_napCampos['Nro de NAP']?.text ?? ""}";
      case "Closure":
        switch (_closureNaturaleza) {
          case "Distribucion":
            return "${_closureDistribucionCampos['Feeder']?.text ?? ""}-CL${_closureDistribucionCampos['Nro Closure']?.text ?? ""}";
          case "Secundario":
            return "CL${_closureSecundarioCampos['Closure padre']?.text ?? ""}-D${_closureSecundarioCampos['Distribucion']?.text ?? ""}-CLS${_closureSecundarioCampos['Closure secundario']?.text ?? ""}";
          case "Continuidad":
            return "CLC${_closureContinuidadCampos['Nro Closure']?.text ?? ""}";
          case "Reparacion":
            return "CLR${_closureReparacionCampos['Nro Closure de reparacion']?.text ?? ""}";
        }
        break;
      case "FDT":
        if (_fdtConClosureSecundario == "No") {
          return "CL${_fdtCamposNo['Closure padre']?.text ?? ""}-D${_fdtCamposNo['Distribucion']?.text ?? ""}-M${_fdtCamposNo['Nro FDT']?.text ?? ""}";
        } else if (_fdtConClosureSecundario == "Si") {
          return "CLS${_fdtCamposSi['Closure Secundario padre']?.text ?? ""}-D${_fdtCamposSi['Distribucion']?.text ?? ""}-M${_fdtCamposSi['Numero de FDT']?.text ?? ""}";
        }
        break;
    }
    return "";
  }

  List<String> _seccionesFotos() {
    if (_elementoSeleccionado == "NAP") {
      return [
        "Etiquetas del elemento",
        "Bandejas de puertos",
        "Bandejas de empalmes",
        "Instalacion Tanquilla o Poste",
      ];
    } else if (_elementoSeleccionado == "Closure") {
      switch (_closureNaturaleza) {
        case "Distribucion":
          return [
            "Etiquetado del elemento",
            "Instalacion Tanquilla o Poste",
            "Salidas del elemento",
            "Bandejas",
          ];
        case "Continuidad":
          return [
            "Instalacion Tanquilla o Poste",
            "Salidas del elemento",
            "Lateral derecho",
            "Lateral izquierdo",
            "Bandejas",
          ];
        case "Reparacion":
          return [
            "Instalacion Tanquilla o Poste",
            "Salidas del elemento",
            "lateral derecho",
            "Lateral izquierdo",
            "Bandejas",
          ];
        case "Secundario":
          return [
            "Etiquetado del elemento",
            "Instalacion Tanquilla o Poste",
            "Salidas del elemento",
            "Bandejas",
          ];
        default:
          return [];
      }
    } else if (_elementoSeleccionado == "FDT") {
      return [
        "Etiquetado del elemento",
        "Salidas del elemento",
        "Bandejas de alimentacion",
        "Bandejas de Splitter",
        "Instalacion de Tanquilla o Poste",
      ];
    }
    return [];
  }

  Widget _buildCamposDinamicos() {
    List<Widget> campos = [];
    if (_elementoSeleccionado == "NAP") {
      campos.addAll([
        _buildCampoNomenclatura(_napCampos, 'FDT padre', "FDT padre"),
        _buildCampoNomenclatura(_napCampos, 'Nro Distribución Secundario', "Nro Distribución Secundario"),
        _buildCampoNomenclatura(_napCampos, 'Nro de NAP', "Nro de NAP"),
      ]);
      
      if (_nomenclatura.isNotEmpty) {
        campos.add(_buildInformeTecnico());
      }
    } else if (_elementoSeleccionado == "Closure") {
      campos.add(
        DropdownButtonFormField<String>(
          initialValue: _closureNaturaleza,
          items: [
            "Distribucion",
            "Continuidad",
            "Secundario",
            "Reparacion",
          ].map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
          onChanged: (v) {
            setState(() {
              _closureNaturaleza = v;
              _actualizarNomenclatura();
            });
          },
          decoration: const InputDecoration(labelText: "Naturaleza"),
        ),
      );
      if (_closureNaturaleza == "Distribucion") {
        campos.addAll([
          _buildCampoNomenclatura(_closureDistribucionCampos, 'Feeder', "Feeder"),
          _buildCampoNomenclatura(_closureDistribucionCampos, 'Nro Closure', "Nro Closure"),
        ]);
      } else if (_closureNaturaleza == "Secundario") {
        campos.addAll([
          _buildCampoNomenclatura(_closureSecundarioCampos, 'Closure padre', "Closure padre"),
          _buildCampoNomenclatura(_closureSecundarioCampos, 'Distribucion', "Distribucion"),
          _buildCampoNomenclatura(_closureSecundarioCampos, 'Closure secundario', "Closure secundario"),
        ]);
      } else if (_closureNaturaleza == "Continuidad") {
        campos.add(_buildCampoNomenclatura(_closureContinuidadCampos, 'Nro Closure', "Nro Closure"));
      } else if (_closureNaturaleza == "Reparacion") {
        campos.add(_buildCampoNomenclatura(_closureReparacionCampos, 'Nro Closure de reparacion', "Nro Closure de reparacion"));
      }
      
      if (_nomenclatura.isNotEmpty) {
        campos.add(_buildInformeTecnico());
      }
    } else if (_elementoSeleccionado == "FDT") {
      campos.add(
        DropdownButtonFormField<String>(
          initialValue: _fdtConClosureSecundario,
          items: ["Si", "No"].map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
          onChanged: (v) {
            setState(() {
              _fdtConClosureSecundario = v;
              _actualizarNomenclatura();
            });
          },
          decoration: const InputDecoration(labelText: "¿Con closure secundario?"),
        ),
      );
      if (_fdtConClosureSecundario == "No") {
        campos.addAll([
          _buildCampoNomenclatura(_fdtCamposNo, 'Closure padre', "Closure padre"),
          _buildCampoNomenclatura(_fdtCamposNo, 'Distribucion', "Distribucion"),
          _buildCampoNomenclatura(_fdtCamposNo, 'Nro FDT', "Nro FDT"),
        ]);
      } else if (_fdtConClosureSecundario == "Si") {
        campos.addAll([
          _buildCampoNomenclatura(_fdtCamposSi, 'Closure Secundario padre', "Closure Secundario padre"),
          _buildCampoNomenclatura(_fdtCamposSi, 'Distribucion', "Distribucion"),
          _buildCampoNomenclatura(_fdtCamposSi, 'Numero de FDT', "Numero de FDT"),
        ]);
      }
      
      if (_nomenclatura.isNotEmpty) {
        campos.add(_buildInformeTecnico());
      }
    }
    return Column(children: campos);
  }
  
  Widget _buildInformeTecnico() {
    return Card(
      child: ExpansionTile(
        title: Text('Información Técnica $_elementoSeleccionado'),
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: _buildCamposInformeTecnico(),
            ),
          ),
        ],
      ),
    );
  }
  
  List<Widget> _buildCamposInformeTecnico() {
    List<Widget> campos = [];
    
    // Campos comunes para todos los elementos
    campos.addAll([
      DropdownButtonFormField<String>(
        initialValue: _tipoInstalacion,
        items: ['Aerea', 'Subterranea'].map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
        onChanged: (v) => setState(() => _tipoInstalacion = v!),
        decoration: const InputDecoration(labelText: "Tipo de Instalación"),
      ),
      const SizedBox(height: 8),
    ]);
    
    // Campos de splitter solo para NAP y FDT, no para Closure
    if (_elementoSeleccionado != "Closure") {
      campos.addAll([
        DropdownButtonFormField<String>(
          items: ['1:4', '1:8', '1:16'].map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
          onChanged: (v) => _tipoSplitterController.text = v ?? '',
          decoration: const InputDecoration(labelText: "Tipo de Splitter"),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _cantidadSplitterController,
          decoration: const InputDecoration(labelText: "Cantidad de Splitter"),
          keyboardType: TextInputType.number,
        ),
        const SizedBox(height: 8),
      ]);
    }
    
    campos.addAll([
      DropdownButtonFormField<String>(
        initialValue: _contieneEtiquetaIdentificacion,
        items: ['Si', 'No'].map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
        onChanged: (v) => setState(() => _contieneEtiquetaIdentificacion = v!),
        decoration: const InputDecoration(labelText: "Contiene etiqueta de identificacion"),
      ),
      const SizedBox(height: 8),
      DropdownButtonFormField<String>(
        initialValue: _armadoBajoNorma,
        items: ['Si', 'No'].map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
        onChanged: (v) => setState(() => _armadoBajoNorma = v!),
        decoration: const InputDecoration(labelText: "Armado bajo norma"),
      ),
      const SizedBox(height: 8),
      DropdownButtonFormField<String>(
        initialValue: _fijacionBajoNorma,
        items: ['Si', 'No'].map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
        onChanged: (v) => setState(() => _fijacionBajoNorma = v!),
        decoration: const InputDecoration(labelText: "Fijación bajo norma"),
      ),
      const SizedBox(height: 8),
      TextField(
        controller: _cantidadCablesSalidaController,
        decoration: const InputDecoration(labelText: "Cantidad de cables de salida"),
        keyboardType: TextInputType.number,
      ),
    ]);
    
    // Campo especial para Closure con Naturaleza Distribución
    if (_elementoSeleccionado == "Closure" && _closureNaturaleza == "Distribucion") {
      campos.addAll([
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<String>(
                value: _bufferSeleccionado,
                items: ['Azul', 'Naranja', 'Verde', 'Marron', 'Gris', 'Blanco', 'Rojo', 'Negro', 'Amarillo', 'Violeta', 'Rosa', 'Aqua']
                    .map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                onChanged: (v) => setState(() => _bufferSeleccionado = v),
                decoration: const InputDecoration(labelText: "Selección de Buffer"),
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: _bufferSeleccionado != null ? _agregarBuffer : null,
              child: const Text("Agregar Buffer"),
            ),
          ],
        ),
        if (_distribucionBuffers.isNotEmpty) ...[
          const SizedBox(height: 8),
          const Text("Distribución por buffer:", style: TextStyle(fontWeight: FontWeight.bold)),
          ..._distribucionBuffers.asMap().entries.map((entry) => 
            ListTile(
              title: Text(entry.value),
              trailing: IconButton(
                icon: const Icon(Icons.delete),
                onPressed: () => _eliminarBuffer(entry.key),
              ),
            )
          ),
        ],
      ]);
    }
    
    // Campos específicos para NAP
    if (_elementoSeleccionado == "NAP") {
      campos.addAll([
        const SizedBox(height: 8),
        TextField(
          controller: _distanciaNapFdtController,
          decoration: const InputDecoration(labelText: "Distancia NAP a FDT (mts)"),
          keyboardType: TextInputType.number,
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _distanciaFdtOdfController,
          decoration: const InputDecoration(labelText: "Distancia FDT a ODF (mts)"),
          keyboardType: TextInputType.number,
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _cantidadEmpalmesController,
          decoration: const InputDecoration(labelText: "Cantidad de empalmes desde ODF"),
          keyboardType: TextInputType.number,
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<String>(
                initialValue: _longitudOnda,
                items: ["1490", "1550"].map((s) => DropdownMenuItem(value: s, child: Text("${s}nm"))).toList(),
                onChanged: (v) {
                  setState(() {
                    _longitudOnda = v;
                    _cargarMedicionesLongitudOnda();
                  });
                },
                decoration: const InputDecoration(labelText: "Longitud de onda"),
              ),
            ),
            const SizedBox(width: 16),
            ElevatedButton(
              onPressed: _longitudOnda != null ? _guardarMediciones : null,
              child: const Text("Guardar Mediciones"),
            ),
          ],
        ),
        if (_longitudOnda != null) _buildMedicionesTable(),
      ]);
    }
    
    return campos;
  }

  Widget _buildCampoNomenclatura(Map<String, TextEditingController> map, String key, String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: TextField(
        controller: map[key],
        decoration: InputDecoration(labelText: label),
        onChanged: (_) => _actualizarNomenclatura(),
        maxLines: null,
        keyboardType: TextInputType.multiline,
      ),
    );
  }

  Future<void> _pickImages(String seccion) async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      type: FileType.image,
    );
    if (result != null) {
      setState(() {
        _fotosPorSeccion.putIfAbsent(seccion, () => []);
        _fotosPorSeccion[seccion]!.addAll(result.files);
      });
    }
  }

  Widget _buildMedicionesTable() {
    if (_medicionesPuertos.isEmpty) {
      for (int i = 1; i <= 16; i++) {
        _medicionesPuertos[i] = TextEditingController();
      }
    }
    
    List<TableRow> tableRows = [];
    for (int row = 0; row < 4; row++) {
      List<Widget> cells = [];
      for (int col = 0; col < 4; col++) {
        int puerto = row * 4 + col + 1;
        cells.add(
          Padding(
            padding: const EdgeInsets.all(4.0),
            child: TextField(
              controller: _medicionesPuertos[puerto],
              decoration: InputDecoration(
                labelText: "P$puerto",
                border: const OutlineInputBorder(),
                isDense: true,
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
            ),
          ),
        );
      }
      tableRows.add(TableRow(children: cells));
    }
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Mediciones ${_longitudOnda}nm', style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Table(
            border: TableBorder.all(),
            children: tableRows,
          ),
        ],
      ),
    );
  }
  
  void _cargarMedicionesLongitudOnda() {
    if (_longitudOnda == null) return;
    
    // Limpiar controladores actuales
    for (var controller in _medicionesPuertos.values) {
      controller.clear();
    }
    
    // Cargar mediciones guardadas si existen
    if (_medicionesGuardadas.containsKey('${_longitudOnda}nm')) {
      final mediciones = _medicionesGuardadas['${_longitudOnda}nm']!;
      mediciones.forEach((puerto, valor) {
        if (_medicionesPuertos.containsKey(puerto)) {
          _medicionesPuertos[puerto]!.text = valor;
        }
      });
    }
  }

  Future<void> _pickOtdrFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );
    if (result != null && result.files.single.path != null) {
      setState(() {
        _archivoOtdr = result.files.single;
      });
    }
  }

  Widget _buildFotosSeccion() {
    final secciones = _seccionesFotos();
    if (secciones.isEmpty) return const SizedBox.shrink();
    return Column(
      children: [
        ...secciones.map((seccion) {
          final expanded = _seccionesExpand[seccion] ?? false;
          final fotos = _fotosPorSeccion[seccion] ?? [];
          return Card(
            child: ExpansionTile(
              title: Text("$seccion (${fotos.length})"),
              initiallyExpanded: expanded,
              onExpansionChanged: (val) {
                setState(() {
                  _seccionesExpand[seccion] = val;
                });
              },
              children: [
                ElevatedButton(
                  onPressed: () => _pickImages(seccion),
                  child: const Text("Adjuntar Fotos"),
                ),
                ...fotos.asMap().entries.map((entry) => ListTile(
                      title: Text("${seccion.replaceAll(" ", "_")}_${entry.key + 1}.${entry.value.extension}"),
                    )),
              ],
            ),
          );
        }),
        // Sección para cargar PDF de trazas OTDR
        Card(
          child: ExpansionTile(
            title: Text("Trazas OTDR ${_archivoOtdr != null ? '(1)' : '(0)'}"),
            children: [
              ElevatedButton(
                onPressed: _pickOtdrFile,
                child: const Text("Cargar PDF OTDR"),
              ),
              if (_archivoOtdr != null)
                ListTile(
                  title: Text(_archivoOtdr!.name),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete),
                    onPressed: () => setState(() => _archivoOtdr = null),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
  Future<void> _previsualizarInforme() async {
    setState(() => _generando = true);

    try {
      final pdf = await _generarPDF(incluirFotos: false);
      await Printing.layoutPdf(
        onLayout: (format) async => pdf.save(),
        name: _nomenclatura.isNotEmpty ? '$_nomenclatura.pdf' : 'informe.pdf',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al previsualizar: $e')),
        );
      }
    }

    if (mounted) setState(() => _generando = false);
  }

  Future<void> _generarComprimido() async {
    // Preguntar por la ruta de guardado
    String? selectedDirectory = await FilePicker.platform.getDirectoryPath();
    if (selectedDirectory == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Generación cancelada - No se seleccionó ruta de guardado')),
        );
      }
      return;
    }

    if (mounted) setState(() => _generando = true);

    try {
      final success = await generateAndCompressReport(
        instalador: _tecnicoController.text,
        fecha: _fechaActual,
        ubicacion: _ubicacionActual,
        unidadNegocio: _unidadNegocioController.text,
        elemento: _elementoSeleccionado,
        closureNaturaleza: _closureNaturaleza,
        fdtConClosureSecundario: _fdtConClosureSecundario,
        campos: _getCampos(),
        nomenclatura: _nomenclatura,
        fotosPorSeccion: _fotosPorSeccion,
        archivoOtdr: _archivoOtdr,
        context: context,
        savePath: selectedDirectory,
      );

      if (mounted) {
        if (success) {
          final zipName = _nomenclatura.isNotEmpty ? '$_nomenclatura.zip' : 'reporte.zip';
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
          SnackBar(content: Text('Error al generar comprimido: $e')),
        );
      }
    }

    if (mounted) setState(() => _generando = false);
  }

  Map<String, String> _getCampos() {
    Map<String, String> campos = {};
    if (_elementoSeleccionado == "NAP") {
      campos = {
        "FDT padre": _napCampos['FDT padre']?.text ?? "",
        "Nro Distribución Secundario": _napCampos['Nro Distribución Secundario']?.text ?? "",
        "Nro de NAP": _napCampos['Nro de NAP']?.text ?? "",
      };
    } else if (_elementoSeleccionado == "FDT") {
      if (_fdtConClosureSecundario == "No") {
        campos = {
          "Closure padre": _fdtCamposNo['Closure padre']?.text ?? "",
          "Distribucion": _fdtCamposNo['Distribucion']?.text ?? "",
          "Nro FDT": _fdtCamposNo['Nro FDT']?.text ?? "",
        };
      } else if (_fdtConClosureSecundario == "Si") {
        campos = {
          "Closure Secundario padre": _fdtCamposSi['Closure Secundario padre']?.text ?? "",
          "Distribucion": _fdtCamposSi['Distribucion']?.text ?? "",
          "Numero de FDT": _fdtCamposSi['Numero de FDT']?.text ?? "",
        };
      }
    } else if (_elementoSeleccionado == "Closure") {
      switch (_closureNaturaleza) {
        case "Distribucion":
          campos = {
            "Feeder": _closureDistribucionCampos['Feeder']?.text ?? "",
            "Nro Closure": _closureDistribucionCampos['Nro Closure']?.text ?? "",
          };
          break;
        case "Secundario":
          campos = {
            "Closure padre": _closureSecundarioCampos['Closure padre']?.text ?? "",
            "Distribucion": _closureSecundarioCampos['Distribucion']?.text ?? "",
            "Closure secundario": _closureSecundarioCampos['Closure secundario']?.text ?? "",
          };
          break;
        case "Continuidad":
          campos = {
            "Nro Closure": _closureContinuidadCampos['Nro Closure']?.text ?? "",
          };
          break;
        case "Reparacion":
          campos = {
            "Nro Closure de reparacion": _closureReparacionCampos['Nro Closure de reparacion']?.text ?? "",
          };
          break;
      }
    }
    return campos;
  }

  Future<pw.Document> _generarPDF({bool incluirFotos = true}) async {
    final pdf = pw.Document();
    final campos = _getCampos();
    
    // Cargar logo como marca de agua
    pw.ImageProvider? logoImage;
    try {
      final logoBytes = await rootBundle.load('assets/images/LOGO_INTER.png');
      logoImage = pw.MemoryImage(logoBytes.buffer.asUint8List());
    } catch (_) {
      logoImage = null;
    }
    
    pdf.addPage(
      pw.Page(
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('Reporte de Instalación', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 16),
              pw.Text('Técnico: ${_tecnicoController.text}'),
              pw.Text('Fecha: ${_fechaActual.toLocal()}'),
              pw.Text('Ubicación: ${_ubicacionActual != null ? "${_ubicacionActual!.latitude}, ${_ubicacionActual!.longitude}" : "No disponible"}'),
              pw.Text('Unidad de Negocios: ${_unidadNegocioController.text}'),
              pw.Text('Elemento: $_elementoSeleccionado'),
              if (_closureNaturaleza != null) pw.Text('Naturaleza: $_closureNaturaleza'),
              if (_fdtConClosureSecundario != null) pw.Text('¿Con closure secundario?: $_fdtConClosureSecundario'),
              pw.SizedBox(height: 8),
              ...campos.entries.map((e) => pw.Text('${e.key}: ${e.value}')),
              pw.SizedBox(height: 8),
              pw.Text('Nomenclatura: $_nomenclatura', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
              if (_elementoSeleccionado != null) ...[
                pw.SizedBox(height: 16),
                pw.Text('Información Técnica $_elementoSeleccionado', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
                pw.Text('Tipo de Instalación: $_tipoInstalacion'),
                if (_elementoSeleccionado == "NAP") ...[
                  pw.Text('Distancia NAP a FDT: ${_distanciaNapFdtController.text} mts'),
                  pw.Text('Distancia FDT a ODF: ${_distanciaFdtOdfController.text} mts'),
                  pw.Text('Cantidad de empalmes desde ODF: ${_cantidadEmpalmesController.text}'),
                ],
                if (_elementoSeleccionado != "Closure") ...[
                  pw.Text('Tipo de Splitter: ${_tipoSplitterController.text}'),
                  pw.Text('Cantidad de Splitter: ${_cantidadSplitterController.text}'),
                ],
                if (_elementoSeleccionado == "Closure" && _closureNaturaleza == "Distribucion" && _distribucionBuffers.isNotEmpty) ...[
                  pw.Text('Distribución por buffer: ${_distribucionBuffers.join(", ")}')
                ],
                pw.Text('Contiene etiqueta de identificacion: $_contieneEtiquetaIdentificacion'),
                pw.Text('Armado bajo norma: $_armadoBajoNorma'),
                pw.Text('Fijación bajo norma: $_fijacionBajoNorma'),
                pw.Text('Cantidad de cables de salida: ${_cantidadCablesSalidaController.text}'),
                if (_medicionesGuardadas.isNotEmpty && _elementoSeleccionado != "NAP") ...[
                  pw.SizedBox(height: 8),
                  pw.Text('Mediciones:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                  ..._medicionesGuardadas.entries.map((entry) => 
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('Mediciones ${entry.key}:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                        pw.Container(
                          width: 400,
                          height: 200,
                          child: pw.Table(
                            border: pw.TableBorder.all(),
                            children: [
                              for (int row = 0; row < 4; row++)
                                pw.TableRow(
                                  children: [
                                    for (int col = 0; col < 4; col++)
                                      pw.Container(
                                        width: 100,
                                        height: 50,
                                        padding: const pw.EdgeInsets.all(4),
                                        child: pw.Text('P${row * 4 + col + 1}: - ${entry.value[row * 4 + col + 1] ?? ""}', style: const pw.TextStyle(fontSize: 8)),
                                      ),
                                  ],
                                ),
                            ],
                          ),
                        ),
                        pw.SizedBox(height: 8),
                      ],
                    )
                  ),
                ],
              ],
            ],
          );
        },
      ),
    );
    
    // Página separada para mediciones NAP
    if (_elementoSeleccionado == "NAP" && _tieneMediciones()) {
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
                    // Mediciones 1490nm
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('Mediciones 1490nm:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                        pw.Container(
                          width: 400,
                          height: 200,
                          child: pw.Table(
                            border: pw.TableBorder.all(),
                            children: [
                              for (int row = 0; row < 4; row++)
                                pw.TableRow(
                                  children: [
                                    for (int col = 0; col < 4; col++)
                                      pw.Container(
                                        width: 100,
                                        height: 50,
                                        padding: const pw.EdgeInsets.all(4),
                                        child: pw.Text('P${row * 4 + col + 1}: - ${_medicionesGuardadas['1490nm']?[row * 4 + col + 1] ?? ""}', style: const pw.TextStyle(fontSize: 8)),
                                      ),
                                  ],
                                ),
                            ],
                          ),
                        ),
                        pw.SizedBox(height: 16),
                      ],
                    ),
                    // Mediciones 1550nm
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('Mediciones 1550nm:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                        pw.Container(
                          width: 400,
                          height: 200,
                          child: pw.Table(
                            border: pw.TableBorder.all(),
                            children: [
                              for (int row = 0; row < 4; row++)
                                pw.TableRow(
                                  children: [
                                    for (int col = 0; col < 4; col++)
                                      pw.Container(
                                        width: 100,
                                        height: 50,
                                        padding: const pw.EdgeInsets.all(4),
                                        child: pw.Text('P${row * 4 + col + 1}: - ${_medicionesGuardadas['1550nm']?[row * 4 + col + 1] ?? ""}', style: const pw.TextStyle(fontSize: 8)),
                                      ),
                                  ],
                                ),
                            ],
                          ),
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
    
    if (incluirFotos) {
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
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                pw.Text('Fotos y Archivos Adjuntos', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 16),
                ..._fotosPorSeccion.entries.map((entry) => 
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('${entry.key}:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      ...entry.value.asMap().entries.map((foto) => 
                        pw.Text('• ${entry.key.replaceAll(" ", "_")}_${foto.key + 1}.${foto.value.extension}')
                      ),
                      pw.SizedBox(height: 8),
                    ],
                  )
                ),
                if (_archivoOtdr != null) ...[
                  pw.Text('Trazas OTDR:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                  pw.Text('• ${_archivoOtdr!.name}'),
                ],
                ],
              ),
            ],
          );
        },
      ),
    );
    }
    
    return pdf;
  }
  
  bool _tieneMediciones() {
    return _medicionesGuardadas.values.any((mediciones) => mediciones.isNotEmpty);
  }

  void _guardarMediciones() {
    if (_longitudOnda == null) return;
    
    String clave = '${_longitudOnda}nm';
    
    Map<int, String> mediciones = {};
    _medicionesPuertos.forEach((puerto, controller) {
      if (controller.text.isNotEmpty) {
        mediciones[puerto] = controller.text;
      }
    });
    
    setState(() {
      _medicionesGuardadas[clave] = mediciones;
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Mediciones guardadas para $clave')),
    );
  }
  
  void _agregarBuffer() {
    if (_bufferSeleccionado != null && !_distribucionBuffers.contains(_bufferSeleccionado!)) {
      setState(() {
        _distribucionBuffers.add(_bufferSeleccionado!);
        _bufferSeleccionado = null;
      });
    }
  }
  
  void _eliminarBuffer(int index) {
    setState(() {
      _distribucionBuffers.removeAt(index);
    });
  }

  void _guardarDatos() {
    final dataToSave = {
      'tecnico': _tecnicoController.text,
      'unidadNegocio': _unidadNegocioController.text,
      'feeder': _feederController.text,
      'closure': _closureController.text,
      'buffer': _bufferController.text,
      'hilo': _hiloController.text,
      'elemento': _elementoSeleccionado,
      'closureNaturaleza': _closureNaturaleza,
      'fdtConClosureSecundario': _fdtConClosureSecundario,
      'nomenclatura': _nomenclatura,
      'tipoInstalacion': _tipoInstalacion,
      'contieneEtiquetaIdentificacion': _contieneEtiquetaIdentificacion,
      'armadoBajoNorma': _armadoBajoNorma,
      'fijacionBajoNorma': _fijacionBajoNorma,
      'longitudOnda': _longitudOnda,
      'datosListos': _datosListos,
      'distribucionBuffers': List.from(_distribucionBuffers),
    };
    
    _dataManager.savePlanilla2Data(dataToSave);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Datos guardados exitosamente')),
    );
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
        _feederController.clear();
        _closureController.clear();
        _bufferController.clear();
        _hiloController.clear();
        _elementoSeleccionado = null;
        _closureNaturaleza = null;
        _fdtConClosureSecundario = null;
        
        for (var ctrl in _napCampos.values) {
          ctrl.clear();
        }
        for (var ctrl in _fdtCamposNo.values) {
          ctrl.clear();
        }
        for (var ctrl in _fdtCamposSi.values) {
          ctrl.clear();
        }
        for (var ctrl in _closureDistribucionCampos.values) {
          ctrl.clear();
        }
        for (var ctrl in _closureSecundarioCampos.values) {
          ctrl.clear();
        }
        for (var ctrl in _closureContinuidadCampos.values) {
          ctrl.clear();
        }
        for (var ctrl in _closureReparacionCampos.values) {
          ctrl.clear();
        }
        
        _tipoInstalacion = 'Aerea';
        _distanciaNapFdtController.clear();
        _distanciaFdtOdfController.clear();
        _cantidadEmpalmesController.clear();
        _tipoSplitterController.clear();
        _cantidadSplitterController.clear();
        _contieneEtiquetaIdentificacion = 'Si';
        _armadoBajoNorma = 'Si';
        _fijacionBajoNorma = 'Si';
        _cantidadCablesSalidaController.clear();
        _medicionesGuardadas.clear();
        _datosListos = false;
        for (var controller in _medicionesPuertos.values) {
          controller.clear();
        }
        _longitudOnda = null;
        _medicionesPuertos.clear();
        _archivoOtdr = null;
        _fotosPorSeccion.clear();
        _seccionesExpand.clear();
        _nomenclatura = "";
        _distribucionBuffers.clear();
        _bufferSeleccionado = null;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Campos limpiados')),
      );
    }
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Generar reporte certificacion"),
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
            // Campos fijos
            TextField(
              controller: _tecnicoController,
              decoration: const InputDecoration(labelText: "Técnico"),
              maxLines: null,
              keyboardType: TextInputType.multiline,
            ),
            const SizedBox(height: 8),
            Text("Fecha actual: ${_fechaActual.toLocal()}"),
            const SizedBox(height: 8),
            Text("Ubicación: ${_ubicacionActual != null ? "${_ubicacionActual!.latitude}, ${_ubicacionActual!.longitude}" : "Obteniendo..."}"),
            const SizedBox(height: 8),
            TextField(
              controller: _unidadNegocioController,
              decoration: const InputDecoration(labelText: "Unidad de Negocios"),
              maxLines: null,
              keyboardType: TextInputType.multiline,
            ),
            TextField(
              controller: _feederController,
              decoration: const InputDecoration(labelText: "Feeder"),
            ),
            TextField(
              controller: _closureController,
              decoration: const InputDecoration(labelText: "Closure"),
            ),
            DropdownButtonFormField<String>(
              items: ['-', 'Azul', 'Naranja', 'Verde', 'Marron', 'Gris', 'Blanco', 'Rojo', 'Negro', 'Amarillo', 'Violeta', 'Rosa', 'Aqua'].map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
              onChanged: (v) => _bufferController.text = v ?? '',
              decoration: const InputDecoration(labelText: "Buffer"),
            ),
            DropdownButtonFormField<String>(
              items: ['-', 'Azul', 'Naranja', 'Verde', 'Marron', 'Gris', 'Blanco', 'Rojo', 'Negro', 'Amarillo', 'Violeta', 'Rosa', 'Aqua'].map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
              onChanged: (v) => _hiloController.text = v ?? '',
              decoration: const InputDecoration(labelText: "Hilo"),
            ),
            const SizedBox(height: 16),

            // Selección de elemento principal
            DropdownButtonFormField<String>(
              initialValue: _elementoSeleccionado,
              items: _elementos.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
              onChanged: (val) {
                setState(() {
                  _elementoSeleccionado = val;
                  // Reset dependientes
                  _closureNaturaleza = null;
                  _fdtConClosureSecundario = null;
                  // Limpiar campos
                  for (var ctrl in _napCampos.values) {
                    ctrl.clear();
                  }
                  for (var ctrl in _fdtCamposNo.values) {
                    ctrl.clear();
                  }
                  for (var ctrl in _fdtCamposSi.values) {
                    ctrl.clear();
                  }
                  for (var ctrl in _closureDistribucionCampos.values) {
                    ctrl.clear();
                  }
                  for (var ctrl in _closureSecundarioCampos.values) {
                    ctrl.clear();
                  }
                  for (var ctrl in _closureContinuidadCampos.values) {
                    ctrl.clear();
                  }
                  for (var ctrl in _closureReparacionCampos.values) {
                    ctrl.clear();
                  }
                  // Limpiar campos técnicos
                  _tipoInstalacion = 'Aerea';
                  _distanciaNapFdtController.clear();
                  _distanciaFdtOdfController.clear();
                  _cantidadEmpalmesController.clear();
                  _tipoSplitterController.clear();
                  _cantidadSplitterController.clear();
                  _contieneEtiquetaIdentificacion = 'Si';
                  _armadoBajoNorma = 'Si';
                  _fijacionBajoNorma = 'Si';
                  _cantidadCablesSalidaController.clear();
                  _medicionesGuardadas.clear();
                  _datosListos = false;
                  for (var controller in _medicionesPuertos.values) {
                    controller.clear();
                  }
                  _longitudOnda = null;
                  _medicionesPuertos.clear();
                  _archivoOtdr = null;
                  _fotosPorSeccion.clear();
                  _seccionesExpand.clear();
                  _nomenclatura = "";
                  _distribucionBuffers.clear();
                  _bufferSeleccionado = null;
                });
              },
              decoration: const InputDecoration(labelText: "Elemento"),
            ),
            const SizedBox(height: 8),

            // Campos dinámicos según selección
            _buildCamposDinamicos(),
            const SizedBox(height: 8),

            // Nomenclatura generada
            if (_nomenclatura.isNotEmpty)
              Text("Nomenclatura: $_nomenclatura", style: const TextStyle(fontWeight: FontWeight.bold)),

            const SizedBox(height: 16),

            // Sección de fotos/adjuntos
            _buildFotosSeccion(),

            const SizedBox(height: 16),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  ElevatedButton.icon(
                    icon: const Icon(Icons.check),
                    label: const Text("Datos Listos"),
                    onPressed: () => setState(() => _datosListos = true),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    icon: _generando ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.preview),
                    label: const Text("Previsualizar Informe"),
                    onPressed: _generando ? null : _previsualizarInforme,
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    icon: _generando ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.archive),
                    label: const Text("Generar Comprimido"),
                    onPressed: (_generando || !_datosListos) ? null : _generarComprimido,
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.clear_all),
                    label: const Text("Limpiar Campos"),
                    onPressed: _limpiarCampos,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red[100],
                      foregroundColor: Colors.red[800],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}