import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'report_logic.dart';

class ReportGeneratorScreen extends StatefulWidget {
  const ReportGeneratorScreen({Key? key}) : super(key: key);

  @override
  State<ReportGeneratorScreen> createState() => _ReportGeneratorScreenState();
}

class _ReportGeneratorScreenState extends State<ReportGeneratorScreen> {
  // Campos fijos
  final TextEditingController _instaladorController = TextEditingController();
  final TextEditingController _unidadNegocioController = TextEditingController();
  DateTime _fechaActual = DateTime.now();
  Position? _ubicacionActual;

  // Selección de elemento principal
  String? _elementoSeleccionado;
  final List<String> _elementos = ['FDT', 'Closure', 'NAP'];

  // Campos dinámicos (según selección)
  Map<String, TextEditingController> _camposDinamicos = {};
  String? _closureNaturaleza;
  String? _fdtConClosureSecundario;

  // Nomenclatura final generada
  String _nomenclatura = "";

  // Secciones de fotos y adjuntos
  Map<String, List<PlatformFile>> _fotosPorSeccion = {};

  // Control de pestañas retraíbles
  Map<String, bool> _seccionesExpand = {};

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
      // Manejo básico de error de ubicación
    }
  }

  void _actualizarNomenclatura() {
    // LOGICA para generar la nomenclatura según la selección y campos
    // (Ver archivo aparte para mantener limpio si crece)
    setState(() {
      _nomenclatura = obtenerNomenclatura(
        elemento: _elementoSeleccionado,
        closureNaturaleza: _closureNaturaleza,
        fdtConClosureSecundario: _fdtConClosureSecundario,
        campos: _camposDinamicos.map((k, v) => MapEntry(k, v.text)),
      );
    });
  }

  List<String> _seccionesFotos() {
    // Devuelve las secciones de adjuntos según selección
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
    _camposDinamicos.clear();

    if (_elementoSeleccionado == "NAP") {
      campos.addAll([
        _buildCampo("Numero de FDT"),
        _buildCampo("Numero de cable secundario"),
        _buildCampo("Numero de NAP"),
      ]);
    } else if (_elementoSeleccionado == "Closure") {
      campos.add(
        DropdownButtonFormField<String>(
          value: _closureNaturaleza,
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
          decoration: InputDecoration(labelText: "Naturaleza"),
        ),
      );
      if (_closureNaturaleza == "Distribucion") {
        campos.addAll([
          _buildCampo("Feeder"),
          _buildCampo("Nro Closure"),
        ]);
      } else if (_closureNaturaleza == "Secundario") {
        campos.addAll([
          _buildCampo("Closure padre"),
          _buildCampo("Distribucion"),
          _buildCampo("Closure secundario"),
        ]);
      } else if (_closureNaturaleza == "Continuidad") {
        campos.add(_buildCampo("Nro Closure"));
      } else if (_closureNaturaleza == "Reparacion") {
        campos.add(_buildCampo("Nro Closure de reparacion"));
      }
    } else if (_elementoSeleccionado == "FDT") {
      campos.add(
        DropdownButtonFormField<String>(
          value: _fdtConClosureSecundario,
          items: ["Si", "No"].map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
          onChanged: (v) {
            setState(() {
              _fdtConClosureSecundario = v;
              _actualizarNomenclatura();
            });
          },
          decoration: InputDecoration(labelText: "¿Con closure secundario?"),
        ),
      );
      if (_fdtConClosureSecundario == "No") {
        campos.addAll([
          _buildCampo("Closure padre"),
          _buildCampo("Distribucion"),
          _buildCampo("Nro FDT"),
        ]);
      } else if (_fdtConClosureSecundario == "Si") {
        campos.addAll([
          _buildCampo("Closure Secundario padre"),
          _buildCampo("Distribucion"),
          _buildCampo("Numero de FDT"),
        ]);
      }
    }
    return Column(children: campos);
  }

  Widget _buildCampo(String label) {
    final controller = _camposDinamicos.putIfAbsent(label, () => TextEditingController());
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(labelText: label),
        onChanged: (_) => _actualizarNomenclatura(),
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

  Widget _buildFotosSeccion() {
    // Pestañas retraíbles por sección
    final secciones = _seccionesFotos();
    if (secciones.isEmpty) return SizedBox.shrink();
    return Column(
      children: secciones.map((seccion) {
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
                    title: Text("${seccion}_${entry.key + 1}.${entry.value.extension}"),
                  )),
            ],
          ),
        );
      }).toList(),
    );
  }

  Future<void> _generarYComprimirReporte() async {
    setState(() => _generando = true);
    final success = await generateAndCompressReport(
      instalador: _instaladorController.text,
      fecha: _fechaActual,
      ubicacion: _ubicacionActual,
      unidadNegocio: _unidadNegocioController.text,
      elemento: _elementoSeleccionado,
      closureNaturaleza: _closureNaturaleza,
      fdtConClosureSecundario: _fdtConClosureSecundario,
      campos: _camposDinamicos.map((k, v) => MapEntry(k, v.text)),
      nomenclatura: _nomenclatura,
      fotosPorSeccion: _fotosPorSeccion,
      context: context,
    );
    setState(() => _generando = false);

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(success ? "Éxito" : "Error"),
        content: Text(success
            ? "Reporte generado y comprimido con éxito en la carpeta Descargas."
            : "Hubo un error al generar el reporte."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text("OK")),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Generar Reporte")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Campos fijos
            TextField(
              controller: _instaladorController,
              decoration: const InputDecoration(labelText: "Instalador"),
            ),
            const SizedBox(height: 8),
            Text("Fecha actual: ${_fechaActual.toLocal()}"),
            const SizedBox(height: 8),
            Text("Ubicación: ${_ubicacionActual != null ? "${_ubicacionActual!.latitude}, ${_ubicacionActual!.longitude}" : "Obteniendo..."}"),
            const SizedBox(height: 8),
            TextField(
              controller: _unidadNegocioController,
              decoration: const InputDecoration(labelText: "Unidad de Negocios"),
            ),
            const SizedBox(height: 16),

            // Selección de elemento principal
            DropdownButtonFormField<String>(
              value: _elementoSeleccionado,
              items: _elementos.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
              onChanged: (val) {
                setState(() {
                  _elementoSeleccionado = val;
                  _closureNaturaleza = null;
                  _fdtConClosureSecundario = null;
                  _camposDinamicos.clear();
                  _fotosPorSeccion.clear();
                  _seccionesExpand.clear();
                });
                _actualizarNomenclatura();
              },
              decoration: const InputDecoration(labelText: "Elemento"),
            ),
            const SizedBox(height: 8),

            // Campos dinámicos según selección
            _buildCamposDinamicos(),
            const SizedBox(height: 8),

            // Nomenclatura generada
            if (_nomenclatura.isNotEmpty)
              Text("Nomenclatura: $_nomenclatura", style: TextStyle(fontWeight: FontWeight.bold)),

            const SizedBox(height: 16),

            // Sección de fotos/adjuntos
            _buildFotosSeccion(),

            const SizedBox(height: 16),
            ElevatedButton.icon(
              icon: _generando ? SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : Icon(Icons.archive),
              label: const Text("GENERAR Y COMPRIMIR REPORTE"),
              onPressed: _generando ? null : _generarYComprimirReporte,
            ),
          ],
        ),
      ),
    );
  }
}

// Lógica de nomenclatura (puede moverse a un archivo separado si crece)
String obtenerNomenclatura({
  String? elemento,
  String? closureNaturaleza,
  String? fdtConClosureSecundario,
  required Map<String, String> campos,
}) {
  switch (elemento) {
    case "NAP":
      return "M${campos["Numero de FDT"] ?? ""}-CS${campos["Numero de cable secundario"] ?? ""}-M${campos["Numero de NAP"] ?? ""}";
    case "Closure":
      switch (closureNaturaleza) {
        case "Distribucion":
          return "${campos["Feeder"] ?? ""}-CL${campos["Nro Closure"] ?? ""}";
        case "Secundario":
          return "CL${campos["Closure padre"] ?? ""}-D${campos["Distribucion"] ?? ""}-CLS${campos["Closure secundario"] ?? ""}";
        case "Continuidad":
          return "CLC${campos["Nro Closure"] ?? ""}";
        case "Reparacion":
          return "CLR${campos["Nro Closure de reparacion"] ?? ""}";
        default:
          return "";
      }
    case "FDT":
      if (fdtConClosureSecundario == "No") {
        return "CL${campos["Closure padre"] ?? ""}-D${campos["Distribucion"] ?? ""}-M${campos["Nro FDT"] ?? ""}";
      } else if (fdtConClosureSecundario == "Si") {
        return "CLS${campos["Closure Secundario padre"] ?? ""}-D${campos["Distribucion"] ?? ""}-M${campos["Numero de FDT"] ?? ""}";
      }
      return "";
    default:
      return "";
  }
}
