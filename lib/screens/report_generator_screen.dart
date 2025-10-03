import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:pdf/widgets.dart' as pw;
// ignore: unused_import
import 'package:printing/printing.dart';
import 'report_logic.dart';

class ReportGeneratorScreen extends StatefulWidget {
  const ReportGeneratorScreen({super.key});

  @override
  State<ReportGeneratorScreen> createState() => _ReportGeneratorScreenState();
}

class _ReportGeneratorScreenState extends State<ReportGeneratorScreen> {
  // Campos fijos
  final TextEditingController _tecnicoController = TextEditingController();
  final TextEditingController _unidadNegocioController = TextEditingController();
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

  // Campos específicos para NAP
  final TextEditingController _tipoInstalacionController = TextEditingController();
  final TextEditingController _distanciaNapFdtController = TextEditingController();
  final TextEditingController _distanciaFdtOdfController = TextEditingController();
  final TextEditingController _cantidadEmpalmesController = TextEditingController();
  final TextEditingController _referenciaOltController = TextEditingController();
  
  String? _longitudOnda;
  String? _tipoSplitter;
  String? _splitterSeleccionado;
  
  // Controladores para mediciones de puertos
  final Map<int, TextEditingController> _medicionesPuertos = {};
  
  // Archivo PDF de trazas OTDR
  PlatformFile? _archivoOtdr;

  // Secciones de fotos y adjuntos
  final Map<String, List<PlatformFile>> _fotosPorSeccion = {};

  // Control de pestañas retraíbles
  final Map<String, bool> _seccionesExpand = {};

  bool _generando = false;

  @override
  void initState() {
    super.initState();
    _obtenerUbicacion();
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
      
      // Campos adicionales para NAP
      if (_nomenclatura.isNotEmpty) {
        campos.addAll([
          const SizedBox(height: 16),
          const Text("Información Técnica", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          TextField(
            controller: _tipoInstalacionController,
            decoration: const InputDecoration(labelText: "Tipo de Instalación"),
          ),
          TextField(
            controller: _distanciaNapFdtController,
            decoration: const InputDecoration(labelText: "Distancia NAP a FDT"),
            keyboardType: TextInputType.number,
          ),
          TextField(
            controller: _distanciaFdtOdfController,
            decoration: const InputDecoration(labelText: "Distancia FDT a ODF"),
            keyboardType: TextInputType.number,
          ),
          TextField(
            controller: _cantidadEmpalmesController,
            decoration: const InputDecoration(labelText: "Cantidad de empalmes desde ODF"),
            keyboardType: TextInputType.number,
          ),
          TextField(
            controller: _referenciaOltController,
            decoration: const InputDecoration(labelText: "Referencia OLT"),
          ),
          DropdownButtonFormField<String>(
            initialValue: _longitudOnda,
            items: ["1310", "1490", "1550"].map((s) => DropdownMenuItem(value: s, child: Text("${s}nm"))).toList(),
            onChanged: (v) {
              setState(() {
                _longitudOnda = v;
                _tipoSplitter = null;
                _splitterSeleccionado = null;
                _medicionesPuertos.clear();
              });
            },
            decoration: const InputDecoration(labelText: "Longitud de onda"),
          ),
          if (_longitudOnda != null) ..._buildSplitterConfig(),
        ]);
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
    }
    return Column(children: campos);
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

  List<Widget> _buildSplitterConfig() {
    List<Widget> widgets = [];
    
    widgets.add(
      DropdownButtonFormField<String>(
        initialValue: _tipoSplitter,
        items: ["1:8", "1:16"].map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
        onChanged: (v) {
          setState(() {
            _tipoSplitter = v;
            _splitterSeleccionado = null;
            _medicionesPuertos.clear();
            if (v == "1:8") {
              for (int i = 1; i <= 16; i++) {
                _medicionesPuertos[i] = TextEditingController();
              }
            } else if (v == "1:16") {
              for (int i = 1; i <= 16; i++) {
                _medicionesPuertos[i] = TextEditingController();
              }
            }
          });
        },
        decoration: const InputDecoration(labelText: "Tipo de Splitter"),
      ),
    );
    
    if (_tipoSplitter == "1:8") {
      widgets.add(
        DropdownButtonFormField<String>(
          initialValue: _splitterSeleccionado,
          items: ["Splitter 1", "Splitter 2"].map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
          onChanged: (v) => setState(() => _splitterSeleccionado = v),
          decoration: const InputDecoration(labelText: "Seleccionar Splitter"),
        ),
      );
      
      if (_splitterSeleccionado != null) {
        int startPort = _splitterSeleccionado == "Splitter 1" ? 1 : 9;
        int endPort = _splitterSeleccionado == "Splitter 1" ? 8 : 16;
        widgets.add(_buildMedicionesTable(startPort, endPort, 4, 2));
      }
    } else if (_tipoSplitter == "1:16") {
      widgets.add(_buildMedicionesTable(1, 16, 4, 4));
    }
    
    return widgets;
  }
  
  Widget _buildMedicionesTable(int startPort, int endPort, int rows, int cols) {
    List<TableRow> tableRows = [];
    int currentPort = startPort;
    
    for (int row = 0; row < rows; row++) {
      List<Widget> cells = [];
      for (int col = 0; col < cols; col++) {
        if (currentPort <= endPort) {
          cells.add(
            Padding(
              padding: const EdgeInsets.all(4.0),
              child: TextField(
                controller: _medicionesPuertos[currentPort],
                decoration: InputDecoration(
                  labelText: "P$currentPort",
                  border: const OutlineInputBorder(),
                  isDense: true,
                ),
                keyboardType: TextInputType.number,
              ),
            ),
          );
          currentPort++;
        } else {
          cells.add(const SizedBox());
        }
      }
      tableRows.add(TableRow(children: cells));
    }
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Table(
        border: TableBorder.all(),
        children: tableRows,
      ),
    );
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

  Future<void> _generarResumenCertificacion() async {
    setState(() => _generando = true);

    try {
      // Recopilar los campos para enviar a la lógica
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

      // Generar PDF en memoria
      final pdf = pw.Document();
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
                pw.Text('Nomenclatura generada: $_nomenclatura', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
              ],
            );
          },
        ),
      );

      // Usar la función de report_logic para generar RAR
      final success = await generateAndCompressReport(
        instalador: _tecnicoController.text,
        fecha: _fechaActual,
        ubicacion: _ubicacionActual,
        unidadNegocio: _unidadNegocioController.text,
        elemento: _elementoSeleccionado,
        closureNaturaleza: _closureNaturaleza,
        fdtConClosureSecundario: _fdtConClosureSecundario,
        campos: campos,
        nomenclatura: _nomenclatura,
        fotosPorSeccion: _fotosPorSeccion,
        context: context,
      );

      if (success) {
        // ignore: use_build_context_synchronously
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Resumen de certificación generado exitosamente')),
        );
      }
    } catch (e) {
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al generar resumen: $e')),
      );
    }

    setState(() => _generando = false);
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Generar reporte formato NAP Register")),
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
                  // Limpiar campos NAP específicos
                  _tipoInstalacionController.clear();
                  _distanciaNapFdtController.clear();
                  _distanciaFdtOdfController.clear();
                  _cantidadEmpalmesController.clear();
                  _referenciaOltController.clear();
                  _longitudOnda = null;
                  _tipoSplitter = null;
                  _splitterSeleccionado = null;
                  _medicionesPuertos.clear();
                  _archivoOtdr = null;
                  _fotosPorSeccion.clear();
                  _seccionesExpand.clear();
                  _nomenclatura = "";
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
            ElevatedButton.icon(
              icon: _generando ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.archive),
              label: const Text("GENERAR RESUMEN DE CERTIFICACIÓN"),
              onPressed: _generando ? null : _generarResumenCertificacion,
            ),
          ],
        ),
      ),
    );
  }
}