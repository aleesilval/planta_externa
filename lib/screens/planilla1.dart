// Importaciones necesarias para el formulario de auditoría
// ignore_for_file: use_build_context_synchronously, unnecessary_import, prefer_const_declarations, avoid_print, prefer_const_constructors, prefer_interpolation_to_compose_strings



import 'package:flutter/material.dart';
import 'package:pdf/widgets.dart' as pw; // Para generar PDFs
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart'; // Para imprimir/exportar PDFs Widget personalizado para geolocalización
import 'package:planta_externa/geo_field.dart'; // Widget personalizado para geolocalización
import 'dart:io';
import 'dart:convert'; // Para JSON
import 'dart:math' as math; // Para funciones matemáticas
import 'package:path_provider/path_provider.dart'; // Para acceso al sistema de archivos
import 'package:file_picker/file_picker.dart'; // Para selección de archivos
import 'package:flutter/services.dart'; // Para cargar assets
import 'package:http/http.dart' as http;
import 'package:flutter_map/flutter_map.dart' show FlutterMap, MapOptions, Marker, MarkerLayer, Polyline, PolylineLayer, TileLayer;
import 'package:latlong2/latlong.dart';
import '../data/form_data_manager.dart';
import 'dart:typed_data'; // Para Uint8List

/// Calcula la distancia entre dos puntos (Haversine, en metros)


/// Widget de mapa con flutter_map
class MapaConFondo extends StatelessWidget {
  final List<Map<String, dynamic>> coordenadas;
  
  const MapaConFondo({super.key, required this.coordenadas});
  
  @override
  Widget build(BuildContext context) {
    if (coordenadas.isEmpty) {
      return Container(
        height: 300,
        decoration: BoxDecoration(border: Border.all(color: Colors.grey)),
        child: const Center(child: Text('No hay coordenadas para mostrar')),
      );
    }
    
    final points = coordenadas.map((c) => LatLng(c['lat']! as double, c['lng']! as double)).toList();
    
    final markers = coordenadas.map((coord) {
      return Marker(
        point: LatLng(coord['lat']! as double, coord['lng']! as double),
        width: 30,
        height: 30,
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.red,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              '${coord['poste']}',
              style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      );
    }).toList();
    
    return Container(
      height: 300,
      decoration: BoxDecoration(border: Border.all(color: Colors.grey)),
      child: FlutterMap(
        options: MapOptions(
          initialCenter: points.length == 1
              ? points.first
              : LatLng(
                  points.map((p) => p.latitude).reduce((a, b) => a + b) / points.length,
                  points.map((p) => p.longitude).reduce((a, b) => a + b) / points.length,
                ),
          initialZoom: points.length == 1 ? 13.0 : 12.0,
        ),
        children: [
          TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            userAgentPackageName: 'com.example.planta_externa',
          ),
          if (points.length > 1)
            PolylineLayer(
              polylines: [
                Polyline(
                  points: points,
                  color: Colors.red,
                  strokeWidth: 3,
                ),
              ],
            ),
          MarkerLayer(markers: markers),
        ],
      ),
    );
  }
}



/// Widget wrapper que contiene el formulario principal
class FormularioPage extends StatelessWidget {
  const FormularioPage({super.key});
  @override
  Widget build(BuildContext context) {
    return const FormularioPlantaExterna(); // Solo el widget, sin MaterialApp
  }
}

/// Formulario principal para auditoría de mantenimiento de planta externa
class FormularioPlantaExterna extends StatefulWidget {
  const FormularioPlantaExterna({super.key});
  @override
  State<FormularioPlantaExterna> createState() => _FormularioPlantaExternaState();
}

class _FormularioPlantaExternaState extends State<FormularioPlantaExterna> {
  // Campo para correcto etiquetado
  String _correctoEtiquetado = 'Si';
  /// Calcula la distancia entre dos puntos (Haversine, en metros)
  double _haversine(double lat1, double lon1, double lat2, double lon2) {
    const R = 6371000.0; // Radio de la Tierra en metros
    final dLat = _deg2rad(lat2 - lat1);
    final dLon = _deg2rad(lon2 - lon1);
    final a =
        math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_deg2rad(lat1)) * math.cos(_deg2rad(lat2)) *
        math.sin(dLon / 2) * math.sin(dLon / 2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return R * c;
  }






  double _deg2rad(double deg) => deg * math.pi / 180.0;

  // === VARIABLES DE CONTROL ===
  final _formKey = GlobalKey<FormState>(); // Clave para validación del formulario
  final List<Map<String, dynamic>> _tabla = []; // Lista que almacena todas las filas de datos
  int _contador = 1; // Contador automático para numerar filas
  int? _editNro; // Número de fila en edición (null = nueva fila)

  // === PERSISTENCIA LOCAL ===
  /// Muestra previsualización de la ruta
  Future<void> _previsualizarRuta() async {
    final coordenadas = <Map<String, dynamic>>[];
    for (final fila in _tabla) {
      final geo = fila['geolocalizacionElemento'] as String?;
      final poste = fila['contador'];
      if (geo != null && geo.isNotEmpty && geo.contains(',') && poste != null) {
        final parts = geo.split(',');
        if (parts.length >= 2) {
          final lat = double.tryParse(parts[0].trim());
          final lng = double.tryParse(parts[1].trim());
          if (lat != null && lng != null && lat.abs() <= 90 && lng.abs() <= 180) {
            coordenadas.add({'lat': lat, 'lng': lng, 'poste': poste});
          }
        }
      }
    }
    
    if (coordenadas.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No hay coordenadas válidas para mostrar la ruta')),
      );
      return;
    }
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Previsualización de Ruta'),
        content: SizedBox(
          width: 400,
          height: 500,
          child: Column(
            children: [
              _generarMapaLocal(),
              const SizedBox(height: 16),
              const Text('Postes en la ruta:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Expanded(
                child: SingleChildScrollView(
                  child: Table(
                    border: TableBorder.all(),
                    children: [
                      const TableRow(
                        children: [
                          Padding(padding: EdgeInsets.all(4), child: Text('Nro', style: TextStyle(fontWeight: FontWeight.bold))),
                          Padding(padding: EdgeInsets.all(4), child: Text('Coordenadas', style: TextStyle(fontWeight: FontWeight.bold))),
                        ],
                      ),
                      ...coordenadas.map((coord) => TableRow(
                        children: [
                          Padding(padding: const EdgeInsets.all(4), child: Text('${coord['poste']}')),
                          Padding(padding: const EdgeInsets.all(4), child: Text('${coord['lat']}, ${coord['lng']}')),
                        ],
                      )),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  /// Genera un widget de mapa con fondo real
  Widget _generarMapaLocal() {
    final coordenadas = <Map<String, dynamic>>[];
    for (final fila in _tabla) {
      final geo = fila['geolocalizacionElemento'] as String?;
      final poste = fila['contador'];
      if (geo != null && geo.isNotEmpty && geo.contains(',') && poste != null) {
        final parts = geo.split(',');
        if (parts.length >= 2) {
          final lat = double.tryParse(parts[0].trim());
          final lng = double.tryParse(parts[1].trim());
          if (lat != null && lng != null && lat.abs() <= 90 && lng.abs() <= 180) {
            coordenadas.add({'lat': lat, 'lng': lng, 'poste': poste});
          }
        }
      }
    }
    
    if (coordenadas.isEmpty) {
      return Container(
        height: 300,
        decoration: BoxDecoration(border: Border.all(color: Colors.grey)),
        child: const Center(child: Text('No hay coordenadas para mostrar')),
      );
    }
    
    return MapaConFondo(coordenadas: coordenadas);
  }
  
  /// Genera imagen del mapa para PDF (usa staticmap.openstreetmap.de con path y marcadores)
  Future<Uint8List?> _generarImagenMapaParaPDF() async {
    final coordenadas = <Map<String, dynamic>>[];
    for (final fila in _tabla) {
      final geo = fila['geolocalizacionElemento'] as String?;
      final poste = fila['contador'];
      if (geo != null && geo.isNotEmpty && geo.contains(',') && poste != null) {
        final parts = geo.split(',');
        if (parts.length >= 2) {
          final lat = double.tryParse(parts[0].trim());
          final lng = double.tryParse(parts[1].trim());
          if (lat != null && lng != null && lat.abs() <= 90 && lng.abs() <= 180) {
            coordenadas.add({'lat': lat, 'lng': lng, 'poste': poste});
          }
        }
      }
    }

    if (coordenadas.isEmpty) return null;

    // --- SUGERENCIA: muestreo automático de puntos si hay demasiados ---
    List<Map<String, dynamic>> sampledCoords = coordenadas;
    const int maxPoints = 60; // Limitar a 60 puntos para la URL
    if (coordenadas.length > maxPoints) {
      // Muestreo equidistante
      double step = coordenadas.length / maxPoints;
      sampledCoords = List.generate(maxPoints, (i) => coordenadas[(i * step).floor()]);
    }

    try {
      final lats = sampledCoords.map((c) => c['lat']! as double).toList();
      final lngs = sampledCoords.map((c) => c['lng']! as double).toList();
      final centerLat = lats.reduce((a, b) => a + b) / lats.length;
      final centerLng = lngs.reduce((a, b) => a + b) / lngs.length;

      // Calcular zoom aproximado en base al extent (ajusta según necesidad)
      final minLat = lats.reduce((a, b) => a < b ? a : b);
      final maxLat = lats.reduce((a, b) => a > b ? a : b);
      final minLng = lngs.reduce((a, b) => a < b ? a : b);
      final maxLng = lngs.reduce((a, b) => a > b ? a : b);
      final latDiff = maxLat - minLat;
      final lngDiff = maxLng - minLng;
      final maxDiff = math.max(latDiff.abs(), lngDiff.abs());

      int zoom;
      if (sampledCoords.length == 1) {
        zoom = 13;
      } else if (maxDiff > 10) {
        zoom = 3;
      } else if (maxDiff > 5) {
        zoom = 4;
      } else if (maxDiff > 2) {
        zoom = 6;
      } else if (maxDiff > 1) {
        zoom = 8;
      } else if (maxDiff > 0.5) {
        zoom = 9;
      } else if (maxDiff > 0.2) {
        zoom = 10;
      } else if (maxDiff > 0.1) {
        zoom = 11;
      } else if (maxDiff > 0.02) {
        zoom = 12;
      } else {
        zoom = 13;
      }

      // Construir path (traza) y marcadores
      final pathString = sampledCoords.map((c) => '${c['lat']},${c['lng']}').join('|');
      final pathParam = 'color:0xff0000|weight:3|$pathString';
      final markersParams = sampledCoords.map((c) => 'markers=${c['lat']},${c['lng']},red-pushpin').join('&');

      final int width = 1000;
      final int height = 500;

      final url =
          'https://staticmap.openstreetmap.de/staticmap.php?center=$centerLat,$centerLng&zoom=$zoom&size=${width}x$height&maptype=mapnik&$markersParams&path=${Uri.encodeComponent(pathParam)}';

      final response = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 12));
      if (response.statusCode == 200) {
        return response.bodyBytes;
      } else {
        print('Error al obtener static map: ${response.statusCode}');
      }
    } catch (e) {
      print('Error generando imagen de mapa para PDF: $e');
    }

    return null;
  }

  @override
  void initState() {
    super.initState();
    _loadSavedDataFromManager();
  }
  
  void _loadSavedDataFromManager() {
    final savedData = _dataManager.getPlanilla1Data();
    if (savedData.isNotEmpty) {
      setState(() {
        _unidadNegocioController.text = savedData['unidadNegocio'] ?? '';
        _feederController.text = savedData['feeder'] ?? '';
        _bufferController.text = savedData['buffer'] ?? '';
        _tipoCable = savedData['tipoCable'] ?? 'Cable alimentador';
        _hilos = savedData['hilos'] ?? 'Azul';
        _fdtPadreController.text = savedData['fdtPadre'] ?? '';
        if (savedData['tabla'] != null) {
          _tabla.clear();
          _tabla.addAll(List<Map<String, dynamic>>.from(savedData['tabla']));
        }
        _contador = savedData['contador'] ?? 1;
        _bloquearCabecera = savedData['bloquearCabecera'] ?? false;
        if (savedData['evidenciaFotografica'] != null) {
          final List<Map<String, dynamic>> loadedEvidencia = [];
          (savedData['evidenciaFotografica'] as List<dynamic>).forEach((item) {
            final fileData = item['foto'] as Map<String, dynamic>;
            final file = PlatformFile(name: fileData['name'], path: fileData['path'], size: fileData['size']);
            loadedEvidencia.add({
              'foto': file,
              'bytes': null, // Se cargará si se necesita una vista previa.
              'descripcion': item['descripcion'],
              'geolocalizacion': item['geolocalizacion'],
            });
          });
          _evidenciaFotografica.clear();
          _evidenciaFotografica.addAll(loadedEvidencia);
        }
      });
    }
  }

  // Encabezado y controladores
  final TextEditingController _unidadNegocioController = TextEditingController();
  final TextEditingController _feederController = TextEditingController();
  final TextEditingController _bufferController = TextEditingController();
  String _tipoCable = 'Cable alimentador';
  String _hilos = 'Azul';
  final TextEditingController _fdtPadreController = TextEditingController();

  bool _bloquearCabecera = false;
  String _observacionesDiseno = 'Sí';

  // Poste propiedad de Inter y acción
  String _posteInter = 'Sí';
  String _identificacionManual = 'Sí';
  String _mantenimientoPreventivo = 'Sí';
  String _accionPosteInter = ' - ';
  final TextEditingController _fechaCorreccionController = TextEditingController();

  // Poste ya inspeccionado
  String _posteInspeccionado = 'No';

  // Materiales utilizados
  String _materialesUtilizados = ' - ';

  // Campos condicionales
  final TextEditingController _soporteRetencionController = TextEditingController();
  final TextEditingController _soporteSuspensionController = TextEditingController();
  String _morseteriaIdentificada = 'Bajo Norma';
  String _tipoElemento = 'CL';
  String _modeloElementoFijado = '288H';
  String _elementoFijacion = ' - ';
  final TextEditingController _cantidadElementoController = TextEditingController();
  final TextEditingController _geolocalizacionElementoController = TextEditingController();
  final TextEditingController _yk01Controller = TextEditingController();
  final TextEditingController _nomenclaturaElementoController = TextEditingController();

  // Tarjeta de identificación y tendido
  String _tarjetaIdentificacion = 'Posee';
  String _tendidoActual = 'Bajo norma';
  String _tendidoAccion = ' - ';

  // Reservas
  String _reservasActual = 'Bajo norma';
  String _reservasAccion = ' - ';

  // Poda
  String _requierePoda = 'No';
  final TextEditingController _zonasPodaInicioController = TextEditingController();
  final TextEditingController _zonasPodaFinController = TextEditingController();
  final TextEditingController _observacionesController = TextEditingController();
  final TextEditingController _trabajosPendientesController = TextEditingController();
  
  // Evidencia fotográfica
  final TextEditingController _descripcionEvidenciaController = TextEditingController();
  final List<PlatformFile> _fotosEvidencia = [];
  final List<Map<String, dynamic>> _evidenciaFotografica = [];
  PlatformFile? _fotoSeleccionada;

  // Mediciones (4 Hilos) - 16 puertos, doble tabla para 1550nm y 1490nm
  final List<TextEditingController> _medicionesPuertos1550 = List.generate(16, (i) => TextEditingController());
  final List<TextEditingController> _medicionesPuertos1490 = List.generate(16, (i) => TextEditingController());
  
  final FormDataManager _dataManager = FormDataManager();

  // Opciones
  final List<String> _opcionesTipoCable = [
    'Cable alimentador',
    'Cable de distribución',
    '4 Hilos'
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
  final List<String> _opcionesElementoFijacion = [' - ','1 fleje','2 fleje','1 tirraje','2 tirraje','otro'];
  final List<String> _opcionesMateriales = [
    ' - ',
    'Adición de fleje faltante',
    'Adición de precinto en reserva',
    'Colocación de etiqueta',
    'Reemplazo de Soporte de Retención',
    'Reemplazo de Soporte de Suspensión',
    'Colocación de YK01',
  ];
  final List<String> _opcionesPosteInter = ['Sí', 'No'];
  final List<String> _opcionesIdentificacionManual = ['Sí', 'No'];
  final List<String> _opcionesMantenimientoPreventivo = ['Sí', 'No'];
  final List<String> _opcionesAccionPosteInter = [
    ' - ',
    'Se agenda pintado bajo norma',
    'Se ejecuta pintado bajo norma',
    'Se agenda correccion de poste doblado',
    'Se ejecuta correccion de poste doblado',
    'Se agenda correccion de poste caido',
    'Se ejecuta correccion de poste caido',
    'Se agenda correccion de poste corroido',
    'Se ejecuta correccion de poste corroido',
    'No procede'
  ];
  final List<String> _opcionesPosteInspeccionado = ['Sí', 'No'];
  final List<String> _opcionesObsDiseno = ['Sí', 'No'];
  final List<String> _opcionesTendidoActual = ['Bajo norma', 'Fuera de norma'];
  final List<String> _opcionesTendidoAccion = ['Se corrige', 'Se agenda correccion', 'No procede'];
  final List<String> _opcionesReservasActual = ['Bajo norma', 'Fuera de norma'];
  final List<String> _opcionesReservasAccion = ['Se rehace la reserva', 'Se coloca precinto', 'Se mueve reserva', 'Se agenda correccion', 'No procede'];
  final List<String> _opcionesTarjetaIdentificacion = ['Posee', 'Requiere identificacion', 'Se reemplaza', 'No Posee'];
  final List<String> _opcionesRequierePoda = ['Sí', 'No'];

  List<String> get _opcionesTendidoAccionDinamicas {
    if (_tendidoActual == 'Bajo norma') {
      return [' - '];
    }
    return _opcionesTendidoAccion;
  }

  List<String> get _opcionesReservasAccionDinamicas {
    if (_reservasActual == 'Bajo norma') {
      return [' - '];
    }
    return _opcionesReservasAccion;
  }

  final Map<String, List<String>> _opcionesModeloElemento = {
    'NAP': ['IP65', 'IP67'],
    'CL': ['288H distribucion','144H distribucion','144H continuidad','288H continuidad','144H reparacion','288H reparacion', 'mini96H'],
    'FDT': ['CL288', 'IP67'],
    'FDT Secundario': ['CL288', 'IP67'],
    '-': ['-'],
  };

  // Etiquetas condicionales
  String get labelTramo => _tipoCable == '4 Hilos' ? 'FDT padre' : 'Identificación de tramo';
  String get labelSoporteRetencion => _tipoCable == '4 Hilos' ? 'Soporte de Fibra Plana' : 'Soporte de Retención';
  String get labelSoporteSuspension => _tipoCable == '4 Hilos' ? 'Nomenclatura del NAP' : 'Soporte de Suspensión';
  List<String> get opcionesTipoElemento {
    if (_tipoCable == '4 Hilos') return ['NAP', '-'];
    if (_tipoCable == 'Cable de distribución') return ['FDT', '-'];
    if (_tipoCable == 'Cable alimentador') return ['CL', '-'];
    return ['CL', 'FDT'];
  }
  bool get bloquearNomenclaturaNAP => _tipoCable == '4 Hilos' && _tipoElemento == '-';

  int get totalPostesInspeccionados {
    if (_tabla.isEmpty) return 0;
    int total = _tabla.length;
    int inspeccionados = _tabla.where((fila) => fila['posteInspeccionado'] == 'Sí').length;
    return total - inspeccionados;
  }

  Future<void> _limpiarArchivosTemporalesPlanilla1() async {
    try {
      final tempDir = await getTemporaryDirectory();
      final planillaDir = Directory('${tempDir.path}/planilla1_files');
      if (await planillaDir.exists()) {
        await planillaDir.delete(recursive: true);
      }
    } catch (e) { /* Ignorar errores */ }
  }

  Future<void> _limpiarTodo() async {
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
        _unidadNegocioController.clear();
        _feederController.clear();
        _bufferController.clear();
        _tipoCable = 'Cable alimentador';
        _hilos = _opcionesHilos[_tipoCable]![0];
        _fdtPadreController.clear();
        _observacionesDiseno = 'Sí';
        _posteInter = 'Sí';
        _identificacionManual = 'Sí';
        _mantenimientoPreventivo = 'Sí';
        _accionPosteInter = ' - ';
        _fechaCorreccionController.clear();
        _posteInspeccionado = 'No';
        _materialesUtilizados = _opcionesMateriales[0];
        _soporteRetencionController.clear();
        _soporteSuspensionController.clear();
        _morseteriaIdentificada = 'Bajo Norma';
        _tipoElemento = opcionesTipoElemento[0];
        _modeloElementoFijado = _opcionesModeloElemento[_tipoElemento]![0];
        _elementoFijacion = ' - ';
        _cantidadElementoController.clear();
        _geolocalizacionElementoController.clear();
        _tarjetaIdentificacion = 'Posee';
        _tendidoActual = _opcionesTendidoActual[0];
        _tendidoAccion = ' - ';
        _reservasActual = _opcionesReservasActual[0];
        _reservasAccion = ' - ';
        _requierePoda = 'No';
        _zonasPodaInicioController.clear();
        _zonasPodaFinController.clear();
        _observacionesController.clear();
        _trabajosPendientesController.clear();
        _tabla.clear();
        _contador = 1;
        _bloquearCabecera = false;
        _editNro = null;
        _yk01Controller.clear();
        _descripcionEvidenciaController.clear();
        _fotosEvidencia.clear();
        _evidenciaFotografica.clear();
        _fotoSeleccionada = null;
        for (final c in _medicionesPuertos1550) { c.clear(); }
        for (final c in _medicionesPuertos1490) { c.clear(); }
      });
      await _saveDraft();
      await _limpiarArchivosTemporalesPlanilla1();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Formulario y tabla limpiados')),
      );
    }
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
          final fila = _filaActual(_contador);
          print('=== DEBUG GRABAR FILA ===');
          print('Geolocalización guardada: "${fila['geolocalizacionElemento']}"');
          _tabla.add(fila);

          _contador++;
          if (_tabla.length == 1) _bloquearCabecera = true;
        }
        _soporteRetencionController.clear();
        _soporteSuspensionController.clear();
        _cantidadElementoController.clear();
        _geolocalizacionElementoController.clear();
        _tarjetaIdentificacion = 'Posee';
        _tendidoActual = _opcionesTendidoActual[0];
        _tendidoAccion = ' - ';
        _reservasActual = _opcionesReservasActual[0];
        _reservasAccion = ' - ';
        _requierePoda = 'No';
        _zonasPodaInicioController.clear();
        _zonasPodaFinController.clear();
        _observacionesController.clear();
        _trabajosPendientesController.clear();
        _accionPosteInter = ' - ';
        _identificacionManual = 'Sí';
        _mantenimientoPreventivo = 'Sí';
        _materialesUtilizados = _opcionesMateriales[0];
        _posteInter = 'Sí';
        _posteInspeccionado = 'No';
        _yk01Controller.clear();
        _nomenclaturaElementoController.clear();
        _fotoSeleccionada = null;
        _nomenclaturaElementoController.clear();
        for (final c in _medicionesPuertos1550) { c.clear(); }
        for (final c in _medicionesPuertos1490) { c.clear(); }
      });
      await _saveDraft();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_editNro == null ? 'Fila agregada a la tabla' : 'Fila modificada')),
      );
    }
  }

  Map<String, dynamic> _filaActual(int nro) => {
    'contador': nro,
    'unidadNegocio': _unidadNegocioController.text,
    'feeder': _feederController.text,
    'buffer': _bufferController.text,
    'tipoCable': _tipoCable,
    'hilos': _hilos,
    'fdtPadre': _fdtPadreController.text,
    'yk01': _yk01Controller.text,
    'nomenclaturaElemento': _nomenclaturaElementoController.text,
    'observacionesDiseno': _observacionesDiseno,
    'posteInter': _posteInter,
    'identificacionManual': _posteInter == 'Sí' ? _identificacionManual : ' - ',
    'mantenimientoPreventivo': _posteInter == 'Sí' && _identificacionManual == 'Sí' ? _mantenimientoPreventivo : ' - ',
    'accionPosteInter': _posteInter == 'Sí' && _identificacionManual == 'Sí' && _mantenimientoPreventivo == 'Sí' ? _accionPosteInter : ' - ',
    'fechaCorreccion': _accionPosteInter.contains('Se agenda') && _fechaCorreccionController.text.isNotEmpty
        ? _fechaCorreccionController.text
        : ' - ',
    'posteInspeccionado': _posteInspeccionado,
    'materialesUtilizados': _materialesUtilizados,
    'soporteRetencion': _soporteRetencionController.text,
    'soporteSuspension': _tipoCable == '4 Hilos' && _tipoElemento == '-' ? ' - ' : _soporteSuspensionController.text,
    'morseteriaIdentificada': _morseteriaIdentificada,
    'tipoElemento': _tipoElemento,
    'modeloElementoFijado': _modeloElementoFijado,
    'elementoFijacion': _elementoFijacion,
    'cantidadElemento': _cantidadElementoController.text,
    'geolocalizacionElemento': _geolocalizacionElementoController.text,
    'tarjetaIdentificacion': _tarjetaIdentificacion,
    'tendidoActual': _tendidoActual,
    'tendidoAccion': _tendidoAccion,
    'reservasActual': _reservasActual,
    'reservasAccion': _reservasAccion,
    'requierePoda': _requierePoda,
    'zonasPodaInicio': _zonasPodaInicioController.text,
    'zonasPodaFin': _zonasPodaFinController.text,
    'observaciones': _observacionesController.text,
    'trabajosPendientes': _trabajosPendientesController.text,

    'medicionesPuertos1550': _tipoCable == '4 Hilos' ? _medicionesPuertos1550.map((c) => c.text).toList() : null,
    'medicionesPuertos1490': _tipoCable == '4 Hilos' ? _medicionesPuertos1490.map((c) => c.text).toList() : null,
  };

  void _cargarFila(int nro) {
    final fila = _tabla.firstWhere((el) => el['contador'] == nro, orElse: () => {});
    if (fila.isNotEmpty) {
      setState(() {
        _editNro = nro;
        _unidadNegocioController.text = fila['unidadNegocio'];
        _feederController.text = fila['feeder'] ?? '';
        _bufferController.text = fila['buffer'] ?? '';
        _tipoCable = fila['tipoCable'];
        _hilos = fila['hilos'];
        _fdtPadreController.text = fila['fdtPadre'] ?? '';
        _observacionesDiseno = fila['observacionesDiseno'] ?? 'Sí';
        _posteInter = fila['posteInter'] ?? 'Sí';
        _identificacionManual = fila['identificacionManual'] ?? 'Sí';
        _mantenimientoPreventivo = fila['mantenimientoPreventivo'] ?? 'Sí';
        _accionPosteInter = fila['accionPosteInter'] ?? ' - ';
        _fechaCorreccionController.text = fila['fechaCorreccion'] ?? '';
        _posteInspeccionado = fila['posteInspeccionado'] ?? 'No';
        _materialesUtilizados = fila['materialesUtilizados'] ?? _opcionesMateriales[0];
        _soporteRetencionController.text = fila['soporteRetencion'] ?? '';
        _soporteSuspensionController.text = fila['soporteSuspension'] == ' - ' ? '' : fila['soporteSuspension'] ?? '';
        _morseteriaIdentificada = fila['morseteriaIdentificada'];
        _tipoElemento = fila['tipoElemento'];
        _modeloElementoFijado = fila['modeloElementoFijado'];
        _elementoFijacion = fila['elementoFijacion'];
        _cantidadElementoController.text = fila['cantidadElemento'];
        _geolocalizacionElementoController.text = fila['geolocalizacionElemento'];
        _tarjetaIdentificacion = fila['tarjetaIdentificacion'] ?? 'Posee';
        _tendidoActual = fila['tendidoActual'] ?? _opcionesTendidoActual[0];
        _tendidoAccion = fila['tendidoAccion'] ?? _opcionesTendidoAccion[0];
        _reservasActual = fila['reservasActual'] ?? _opcionesReservasActual[0];
        _reservasAccion = fila['reservasAccion'] ?? _opcionesReservasAccion[0];
        _requierePoda = fila['requierePoda'] ?? 'No';
        _zonasPodaInicioController.text = fila['zonasPodaInicio'];
        _zonasPodaFinController.text = fila['zonasPodaFin'];
        _observacionesController.text = fila['observaciones'];
        _trabajosPendientesController.text = fila['trabajosPendientes'];
        _yk01Controller.text = fila['yk01'] ?? '';
  _nomenclaturaElementoController.text = fila['nomenclaturaElemento'] ?? '';
  _correctoEtiquetado = fila['correctoEtiquetado'] ?? 'Si';
        if (_tipoCable == '4 Hilos') {
          final l1550 = List<String>.from(fila['medicionesPuertos1550'] ?? []);
          final l1490 = List<String>.from(fila['medicionesPuertos1490'] ?? []);
          for (int i = 0; i < 16; i++) {
            _medicionesPuertos1550[i].text = i < l1550.length ? l1550[i] : '';
            _medicionesPuertos1490[i].text = i < l1490.length ? l1490[i] : '';
          }
        }
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No existe Nro en la tabla')),
      );
    }
  }

  Future<void> _saveDraft() async {
    // 1. Crear directorio temporal para esta planilla si no existe
    final tempDir = await getTemporaryDirectory();
    final planillaDir = Directory('${tempDir.path}/planilla1_files');
    if (!await planillaDir.exists()) {
      await planillaDir.create();
    }
    
    // 2. Copiar fotos y guardar sus nuevas rutas
    List<Map<String, dynamic>> evidenciaParaGuardar = [];
    for (var evidencia in _evidenciaFotografica) {
      final file = evidencia['foto'] as PlatformFile;
      Map<String, dynamic> newEvidencia = {
        'descripcion': evidencia['descripcion'],
        'geolocalizacion': evidencia['geolocalizacion'],
      };
      if (file.path != null && !file.path!.startsWith(planillaDir.path)) {
        final newPath = '${planillaDir.path}/${DateTime.now().millisecondsSinceEpoch}_${file.name}';
        await File(file.path!).copy(newPath);
        newEvidencia['foto'] = {'name': file.name, 'path': newPath, 'size': file.size};
      } else if (file.path != null) { // Ya está en la carpeta temporal
        newEvidencia['foto'] = {'name': file.name, 'path': file.path, 'size': file.size};
      }
      evidenciaParaGuardar.add(newEvidencia);
    }
    // Save to data manager for cross-planilla persistence
    final dataToSave = {
      'unidadNegocio': _unidadNegocioController.text,
      'feeder': _feederController.text,
      'buffer': _bufferController.text,
      'tipoCable': _tipoCable,
      'hilos': _hilos,
      'fdtPadre': _fdtPadreController.text,
      'tabla': List.from(_tabla),
      'contador': _contador,
      'bloquearCabecera': _bloquearCabecera,
      'evidenciaFotografica': evidenciaParaGuardar,
    };
    
    _dataManager.savePlanilla1Data(dataToSave);
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Progreso guardado localmente')),
    );
  }
  
  Future<void> _selectPhoto() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      allowMultiple: false,
      type: FileType.image,
    );
    if (result != null) {
      setState(() {
        _fotoSeleccionada = result.files.single;
      });
    }
  }

  Future<void> _loadPhoto() async {
    if (_fotoSeleccionada != null && _descripcionEvidenciaController.text.isNotEmpty) {
      Uint8List? bytes = _fotoSeleccionada!.bytes;
      // Load bytes from path if not available
      if (bytes == null && _fotoSeleccionada!.path != null) {
        bytes = await File(_fotoSeleccionada!.path!).readAsBytes();
      }
      setState(() {
        _evidenciaFotografica.add({
          'foto': _fotoSeleccionada!,
          'bytes': bytes,
          'descripcion': _descripcionEvidenciaController.text,
          'geolocalizacion': _geolocalizacionElementoController.text,
        });
        _fotoSeleccionada = null;
        _descripcionEvidenciaController.clear();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Foto agregada exitosamente')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Seleccione una foto y agregue una descripción')),
      );
    }
  }

  void _mostrarListaFotos() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Evidencia Fotográfica'),
        content: SizedBox(
          width: double.maxFinite,
          height: 400,
          child: ListView.builder(
            itemCount: _evidenciaFotografica.length,
            itemBuilder: (context, index) {
              final evidencia = _evidenciaFotografica[index];
              final bytes = evidencia['bytes'] as Uint8List?;
              return Card(
                child: ListTile(
                  leading: bytes != null 
                    ? GestureDetector(
                        onTap: () => _mostrarPreviewFoto(bytes),
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: Image.memory(bytes, fit: BoxFit.cover),
                          ),
                        ),
                      )
                    : const Icon(Icons.photo),
                  title: Text(evidencia['descripcion']),
                  subtitle: Text(evidencia['geolocalizacion'] ?? ''),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () {
                      setState(() {
                        _evidenciaFotografica.removeAt(index);
                      });
                      Navigator.of(context).pop();
                      if (_evidenciaFotografica.isNotEmpty) {
                        _mostrarListaFotos();
                      }
                    },
                  ),
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  void _mostrarPreviewFoto(Uint8List bytes) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 500, maxHeight: 500),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Expanded(
                child: Image.memory(bytes, fit: BoxFit.contain),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cerrar'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _exportarPDF() async {
    final pdf = pw.Document();
    int inspeccionados = _tabla.where((fila) => fila['posteInspeccionado'] == 'Sí').length;
    int totalPostes = _tabla.length;
    int totalPostesInspeccionados = totalPostes - inspeccionados;

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
        pageFormat: PdfPageFormat.letter.landscape,
        margin: const pw.EdgeInsets.all(12),
        build: (context) {
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
              pw.Text('Auditoría de Mantenimiento', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 8),
              pw.Text(
                'Unidad de negocio: ${_unidadNegocioController.text}, Feeder: ${_feederController.text}${(_tipoCable == 'Cable de distribución' || _tipoCable == '4 Hilos') && _bufferController.text.isNotEmpty ? ', Buffer: ${_bufferController.text}' : ''}${_tipoCable == "4 Hilos" ? '   FDT padre: ${_fdtPadreController.text}' : ''}   Tipo de cable: $_tipoCable',
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
                      pw.Text('Nro', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 3)),
                      pw.Text('Cantidad YK01', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 3)),
                      pw.Text('Obs. Diseño', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 3)),
                      pw.Text('Propiedad de Inter', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 3)),
                      pw.Text('Acción Poste Inter', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 3)),
                      pw.Text('Fecha Tentativa', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 3)),
                      pw.Text('Poste inspeccionado', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 3)),
                      pw.Text('Soporte de Retención', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 3)),
                      pw.Text('Soporte de Suspensión', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 3)),
                      pw.Text('Morsetería', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 3)),
                      pw.Text('Tipo de Elemento', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 3)),
                      pw.Text('Modelo', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 3)),
                      pw.Text('Elemento de fijación', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 3)),
                      pw.Text('Descripción de fijación', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 3)),
                      pw.Text('Geolocalización', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 3)),
                      pw.Text('Tarjeta Identificación', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 3)),
                      pw.Text('Tendido Actual', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 3)),
                      pw.Text('Tendido Acción', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 3)),
                      pw.Text('Reservas Actual', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 3)),
                      pw.Text('Reservas Acción', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 3)),
                      pw.Text('Geo. Poda', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 3)),
                      pw.Text('Obs. Poda', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 3)),

                      if (_tipoCable == '4 Hilos') pw.Text('Mediciones 1550nm', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 3)),
                      if (_tipoCable == '4 Hilos') pw.Text('Mediciones 1490nm', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 3)),
                      pw.Text('Observaciones', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 3)),
                      pw.Text('Trabajos pendientes', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 3)),
                    ],
                  ),
                  ..._tabla.map((fila) => pw.TableRow(
                    children: [
                      pw.Text('${fila['contador']}', style: const pw.TextStyle(fontSize: 3)),
                      pw.Text(fila['yk01'] ?? '', style: const pw.TextStyle(fontSize: 3)),
                      pw.Text(fila['observacionesDiseno'] ?? '', style: const pw.TextStyle(fontSize: 3)),
                      pw.Text(fila['posteInter'] ?? '', style: const pw.TextStyle(fontSize: 3)),
                      pw.Text(fila['accionPosteInter'] ?? '', style: const pw.TextStyle(fontSize: 3)),
                      pw.Text(fila['fechaCorreccion'] ?? ' - ', style: const pw.TextStyle(fontSize: 3)),
                      pw.Text(fila['posteInspeccionado'] ?? '', style: const pw.TextStyle(fontSize: 3)),
                      pw.Text(fila['soporteRetencion'] ?? '', style: const pw.TextStyle(fontSize: 3)),
                      pw.Text(fila['soporteSuspension'] ?? '', style: const pw.TextStyle(fontSize: 3)),
                      pw.Text(fila['morseteriaIdentificada'] ?? '', style: const pw.TextStyle(fontSize: 3)),
                      pw.Text(fila['tipoElemento'] ?? '', style: const pw.TextStyle(fontSize: 3)),
                      pw.Text(fila['modeloElementoFijado'] ?? '', style: const pw.TextStyle(fontSize: 3)),
                      pw.Text(fila['elementoFijacion'] ?? '', style: const pw.TextStyle(fontSize: 3)),
                      pw.Text(fila['cantidadElemento'] ?? '', style: const pw.TextStyle(fontSize: 3)),
                      pw.Text(fila['geolocalizacionElemento'] ?? '', style: const pw.TextStyle(fontSize: 3)),
                      pw.Text(fila['tarjetaIdentificacion'] ?? '', style: const pw.TextStyle(fontSize: 3)),
                      pw.Text(fila['tendidoActual'] ?? '', style: const pw.TextStyle(fontSize: 3)),
                      pw.Text(fila['tendidoAccion'] ?? '', style: const pw.TextStyle(fontSize: 3)),
                      pw.Text(fila['reservasActual'] ?? '', style: const pw.TextStyle(fontSize: 3)),
                      pw.Text(fila['reservasAccion'] ?? '', style: const pw.TextStyle(fontSize: 3)),
                      pw.Text((fila['requierePoda'] ?? 'No') == 'No' ? ' - ' : (fila['zonasPodaInicio'] ?? ''), style: const pw.TextStyle(fontSize: 3)),
                      pw.Text((fila['requierePoda'] ?? 'No') == 'No' ? ' - ' : (fila['zonasPodaFin'] ?? ''), style: const pw.TextStyle(fontSize: 3)),

                      if (_tipoCable == '4 Hilos')
                        pw.Container(
                          width: 150,
                          child: pw.Table(
                            border: pw.TableBorder.all(width: 0.5, color: PdfColors.grey600),
                            children: [
                              for (int i = 0; i < 16; i++)
                                pw.TableRow(children: [
                                  pw.Padding(
                                    padding: const pw.EdgeInsets.all(2),
                                    child: pw.Text('P${i + 1}: ${fila['medicionesPuertos1550']?[i] ?? ""} dBm', style: const pw.TextStyle(fontSize: 3)),
                                  ),
                                ]),
                            ],
                          ),
                        ),
                      if (_tipoCable == '4 Hilos')
                        pw.Container(
                          width: 150,
                          child: pw.Table(
                            border: pw.TableBorder.all(width: 0.5, color: PdfColors.grey600),
                            children: [
                              for (int i = 0; i < 16; i++)
                                pw.TableRow(children: [
                                  pw.Padding(
                                    padding: const pw.EdgeInsets.all(2),
                                    child: pw.Text('P${i + 1}: ${fila['medicionesPuertos1490']?[i] ?? ""} dBm', style: const pw.TextStyle(fontSize: 3)),
                                  ),
                                ]),
                            ],
                          ),
                        ),
                      pw.Text(fila['observaciones'] ?? '', style: const pw.TextStyle(fontSize: 3)),
                      pw.Text(fila['trabajosPendientes'] ?? '', style: const pw.TextStyle(fontSize: 3)),
                    ],
                  )),
                ],
              ),
              pw.SizedBox(height: 10),
                  pw.Text('Total de postes inspeccionados: $totalPostesInspeccionados', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
                ],
              ),
            ],
          );
        },
      ),
    );
    
    // Páginas de evidencia fotográfica
    if (_evidenciaFotografica.isNotEmpty) {
      const int photosPerPage = 3;
      for (int pageIndex = 0; pageIndex < (_evidenciaFotografica.length / photosPerPage).ceil(); pageIndex++) {
        final startIndex = pageIndex * photosPerPage;
        final endIndex = (startIndex + photosPerPage).clamp(0, _evidenciaFotografica.length);
        final photosForPage = _evidenciaFotografica.sublist(startIndex, endIndex);
        
        pdf.addPage(
          pw.Page(
            pageFormat: PdfPageFormat.letter,
            margin: const pw.EdgeInsets.all(12),
            build: (context) {
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
                  pw.Text('Evidencia Fotográfica - Página ${pageIndex + 1}', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
                  pw.SizedBox(height: 16),
                  ...photosForPage.map((evidencia) {
                    final bytes = evidencia['bytes'] as Uint8List?;
                    final descripcion = evidencia['descripcion'] as String;
                    final geolocalizacion = evidencia['geolocalizacion'] as String? ?? '';
                    
                    return pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        if (bytes != null)
                          pw.Container(
                            height: 180,
                            width: double.infinity,
                            child: pw.Image(pw.MemoryImage(bytes), fit: pw.BoxFit.contain),
                          )
                        else
                          pw.Container(
                            height: 180,
                            width: double.infinity,
                            decoration: pw.BoxDecoration(border: pw.Border.all()),
                            child: pw.Center(child: pw.Text('Sin imagen disponible')),
                          ),
                        pw.SizedBox(height: 8),
                        pw.Text('${_unidadNegocioController.text} ${_feederController.text} ${(_tipoCable == 'Cable de distribución' || _tipoCable == '4 Hilos') && _bufferController.text.isNotEmpty ? '${_bufferController.text} ' : ''}$geolocalizacion - $descripcion', style: const pw.TextStyle(fontSize: 10)),
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
    
    // Página de mapa de ruta (siempre se muestra si hay datos)
    if (_tabla.isNotEmpty) {
      final mapaBytes = await _generarImagenMapaParaPDF();
      final coordenadasValidas = _tabla.where((fila) =>
        fila['geolocalizacionElemento'] != null &&
        fila['geolocalizacionElemento'].toString().isNotEmpty &&
        fila['geolocalizacionElemento'].toString().contains(',')
      ).map((fila) {
        final parts = fila['geolocalizacionElemento'].toString().split(',');
        if (parts.length >= 2) {
          final lat = double.tryParse(parts[0].trim());
          final lng = double.tryParse(parts[1].trim());
          if (lat != null && lng != null) {
            return {'lat': lat, 'lng': lng};
          }
        }
        return null;
      }).where((c) => c != null).cast<Map<String, double>>().toList();

      // Calcular distancia total usando Haversine
      double totalDistanciaMetros = 0.0;
      for (int i = 1; i < coordenadasValidas.length; i++) {
        final a = coordenadasValidas[i - 1];
        final b = coordenadasValidas[i];
        totalDistanciaMetros += _haversine(a['lat']!, a['lng']!, b['lat']!, b['lng']!);
      }
      String distanciaStr;
      if (totalDistanciaMetros >= 1000) {
        distanciaStr = (totalDistanciaMetros / 1000).toStringAsFixed(2) + ' km';
      } else {
        distanciaStr = totalDistanciaMetros.toStringAsFixed(0) + ' m';
      }

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.letter,
          margin: const pw.EdgeInsets.all(12),
          build: (context) {
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
                    pw.Text('Ruta Recorrida', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
                    pw.SizedBox(height: 16),
                    pw.Container(
                      width: double.infinity,
                      height: 300,
                      decoration: pw.BoxDecoration(border: pw.Border.all()),
                      child: mapaBytes != null
                          ? pw.Center(
                              child: pw.Image(
                                pw.MemoryImage(mapaBytes),
                                width: 520,
                                height: 300,
                                fit: pw.BoxFit.contain,
                              ),
                            )
                          : pw.Center(
                              child: pw.Column(
                                mainAxisAlignment: pw.MainAxisAlignment.center,
                                children: [
                                  pw.Text('Mapa de Ruta', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
                                  pw.SizedBox(height: 8),
                                  pw.Text('Coordenadas válidas: ${coordenadasValidas.length}', style: const pw.TextStyle(fontSize: 12)),
                                  pw.Text('Total de postes: ${_tabla.length}', style: const pw.TextStyle(fontSize: 12)),
                                  pw.SizedBox(height: 8),
                                  pw.Text('Ver previsualización en la aplicación', style: const pw.TextStyle(fontSize: 10)),
                                ],
                              ),
                            ),
                    ),
                    pw.SizedBox(height: 12),
                    pw.Text('Distancia total recorrida: $distanciaStr', style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold, color: PdfColors.blue)),
                    pw.SizedBox(height: 12),
                    pw.Text('Postes inspeccionados:', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
                    pw.SizedBox(height: 8),
                    pw.Table(
                      border: pw.TableBorder.all(),
                      children: [
                        pw.TableRow(
                          children: [
                            pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text('Nro Poste', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10))),
                            pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text('Geolocalización', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10))),
                            pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text('Correcto etiquetado', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10))),
                          ],
                        ),
                        ..._tabla.map((fila) =>
                          pw.TableRow(
                            children: [
                              pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text('${fila['contador']}', style: const pw.TextStyle(fontSize: 9))),
                              pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text('${fila['geolocalizacionElemento'] ?? 'Sin coordenadas'}', style: const pw.TextStyle(fontSize: 9))),
                              pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text('${fila['correctoEtiquetado'] ?? 'Si'}', style: const pw.TextStyle(fontSize: 9))),
                            ],
                          )
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
    
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hilosOptions = _opcionesHilos[_tipoCable]!;
    if (!hilosOptions.contains(_hilos)) _hilos = hilosOptions[0];
    final tipoElementoOptions = opcionesTipoElemento;
    if (!tipoElementoOptions.contains(_tipoElemento)) _tipoElemento = tipoElementoOptions[0];
    final modeloOptions = _opcionesModeloElemento[_tipoElemento]!;
    if (!modeloOptions.contains(_modeloElementoFijado)) _modeloElementoFijado = modeloOptions[0];
    if (!_opcionesElementoFijacion.contains(_elementoFijacion)) _elementoFijacion = _opcionesElementoFijacion[0];

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
          title: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Auditoria Mantenimiento'),
              Text('Inspeccion por posteadura',style: TextStyle(fontSize: 12),
                ),
              ],
            ),
        actions: [
          IconButton(
            tooltip: "Guardar",
            icon: const Icon(Icons.save),
            onPressed: _saveDraft,
          ),
          IconButton(
            tooltip: "Limpiar todo",
            icon: const Icon(Icons.cleaning_services),
            onPressed: _limpiarTodo,
          ),
        ],
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
                    _buildTextField('Feeder', _feederController, enabled: !_bloquearCabecera),
                    if (_tipoCable == 'Cable de distribución' || _tipoCable == '4 Hilos')
                      _buildTextField('Buffer', _bufferController, enabled: !_bloquearCabecera),
                    if (_tipoCable == '4 Hilos')
                      _buildTextField('FDT padre', _fdtPadreController, enabled: !_bloquearCabecera),
                    _buildDropdownField('Tipo de cable', _tipoCable, _opcionesTipoCable, (val) {
                      setState(() { _tipoCable = val!; _hilos = _opcionesHilos[val]![0]; });
                    }, enabled: !_bloquearCabecera),
                    _buildDropdownField('Hilos', _hilos, hilosOptions, (val) {
                      setState(() { _hilos = val!; });
                    }, enabled: !_bloquearCabecera),
                    _buildTextField('Cantidad YK01', _yk01Controller, inputType: TextInputType.number),
                    GeoField(
                      controller: _geolocalizacionElementoController,
                      label: 'Geolocalización del elemento fijado',
                    ),
                    _buildDropdownField('Observaciones en diseño', _observacionesDiseno, _opcionesObsDiseno, (val) {
                      setState(() { _observacionesDiseno = val!; });
                    }),
                    _buildDropdownField('Poste ya inspeccionado?', _posteInspeccionado, _opcionesPosteInspeccionado, (val) {
                      setState(() { _posteInspeccionado = val!; });
                    }),
                    _buildDropdownField('Poste propiedad de Inter', _posteInter, _opcionesPosteInter, (val) {
                      setState(() { 
                        _posteInter = val!; 
                        if (_posteInter == 'No') {
                          _identificacionManual = 'Sí';
                          _mantenimientoPreventivo = 'Sí';
                          _accionPosteInter = ' - ';
                        }
                      });
                    }),
                    if (_posteInter == 'Sí')
                      _buildDropdownField('Identificación acorde al manual de mantenimiento', _identificacionManual, _opcionesIdentificacionManual, (val) {
                        setState(() { 
                          _identificacionManual = val!;
                          if (_identificacionManual == 'No') {
                            _mantenimientoPreventivo = 'Sí';
                            _accionPosteInter = ' - ';
                          }
                        });
                      }),
                    if (_posteInter == 'Sí' && _identificacionManual == 'Sí')
                      _buildDropdownField('Requiere mantenimiento preventivo', _mantenimientoPreventivo, _opcionesMantenimientoPreventivo, (val) {
                        setState(() { 
                          _mantenimientoPreventivo = val!;
                          if (_mantenimientoPreventivo == 'No') {
                            _accionPosteInter = ' - ';
                          }
                        });
                      }),
                    if (_posteInter == 'Sí' && _identificacionManual == 'Sí' && _mantenimientoPreventivo == 'Sí')
                      _buildDropdownField('Acción Poste Propiedad de Inter', _accionPosteInter, _opcionesAccionPosteInter, (val) {
                        setState(() { 
                          _accionPosteInter = val!;
                          if (!val.contains('Se agenda')) {
                            _fechaCorreccionController.clear();
                          }
                        });
                      }),
                    if (_posteInter == 'Sí' && _identificacionManual == 'Sí' && _mantenimientoPreventivo == 'Sí' && _accionPosteInter.contains('Se agenda'))
                      _buildDateField('Fecha de corrección', _fechaCorreccionController),
                    _buildDropdownField('Materiales utilizados', _materialesUtilizados, _opcionesMateriales, (val) {
                      setState(() { _materialesUtilizados = val!; });
                    }),
                    _buildTextField(labelSoporteRetencion, _soporteRetencionController, 
                      inputType: TextInputType.number,
                      enabled: _soporteSuspensionController.text.isEmpty,
                      onChanged: (value) {
                        if (value.isNotEmpty) {
                          _soporteSuspensionController.clear();
                        }
                      }
                    ),
                    _buildTextField(labelSoporteSuspension, _soporteSuspensionController, 
                      inputType: TextInputType.number,
                      enabled: !bloquearNomenclaturaNAP && _soporteRetencionController.text.isEmpty,
                      onChanged: (value) {
                        if (value.isNotEmpty) {
                          _soporteRetencionController.clear();
                        }
                      }
                    ),
                    _buildDropdownField('Identificación de la morsetería', _morseteriaIdentificada, _opcionesMorseteria, (val) {
                      setState(() { _morseteriaIdentificada = val!; });
                    }),
                    _buildDropdownField('Tipo de Elemento', _tipoElemento, tipoElementoOptions, (val) {
                      setState(() { _tipoElemento = val!; _modeloElementoFijado = _opcionesModeloElemento[val]![0]; });
                    }),
                    _buildDropdownField('Modelo de elemento fijado', _modeloElementoFijado, modeloOptions, (val) {
                      setState(() { _modeloElementoFijado = val!; });
                    }),
                    if (_tipoElemento == 'CL')
                      _buildTextField('Nomenclatura CL', _nomenclaturaElementoController),
                    if (_tipoElemento == 'FDT')
                      _buildTextField('Nomenclatura FDT', _nomenclaturaElementoController),
                    _buildDropdownField('Correcto etiquetado', _correctoEtiquetado, ['Si', 'No'], (val) {
                      setState(() {
                        _correctoEtiquetado = val ?? 'Si';
                      });
                    }),
                    _buildDropdownField('Elemento de fijación', _elementoFijacion, _opcionesElementoFijacion, (val) {
                      setState(() { _elementoFijacion = val!; });
                    }),
                    _buildTextField('Descripción de fijación', _cantidadElementoController, enabled: _elementoFijacion == 'otro'),
                    _buildDropdownField('Contiene tarjeta de identificación de FO', _tarjetaIdentificacion, _opcionesTarjetaIdentificacion, (val) {
                      setState(() { _tarjetaIdentificacion = val!; });
                    }),
                    // Tendido con perdida de tensión actual/acción
                    _buildDropdownField('Tendido con perdida de tensión actual', _tendidoActual, _opcionesTendidoActual, (val) { 
                      setState(() { 
                        _tendidoActual = val!; 
                        if (val == 'Bajo norma') {
                          _tendidoAccion = ' - ';
                        } else if (_tendidoAccion == ' - ') {
                          _tendidoAccion = _opcionesTendidoAccion[0];
                        }
                      }); 
                    }),
                    _buildDropdownField('Tendido con perdida de tensión acción', _tendidoAccion, _opcionesTendidoAccionDinamicas, (val) { setState(() { _tendidoAccion = val!; }); }),
                    _buildDropdownField('Reservas Actual', _opcionesReservasActual.contains(_reservasActual) ? _reservasActual : _opcionesReservasActual[0], _opcionesReservasActual, (val) {
                      setState(() { 
                        _reservasActual = val!; 
                        if (val == 'Bajo norma') {
                          _reservasAccion = ' - ';
                        } else if (_reservasAccion == ' - ') {
                          _reservasAccion = _opcionesReservasAccion[0];
                        }
                      });
                    }),
                    _buildDropdownField('Reservas Acción', _opcionesReservasAccionDinamicas.contains(_reservasAccion) ? _reservasAccion : _opcionesReservasAccionDinamicas[0], _opcionesReservasAccionDinamicas, (val) {
                      setState(() { _reservasAccion = val!; });
                    }),
                    _buildDropdownField('Requiere poda', _requierePoda, _opcionesRequierePoda, (val) {
                      setState(() { _requierePoda = val!; });
                    }),
                    GeoField(
                      controller: _zonasPodaInicioController,
                      label: 'Geolocalización de zona de poda o desmalezado',
                      enabled: _requierePoda == 'Sí',
                    ),
                    _buildTextField('Observaciones de zona de poda o desmalezado', _zonasPodaFinController, enabled: _requierePoda == 'Sí'),
                    if (_tipoCable == '4 Hilos')
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: Card(
                          elevation: 2,
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
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
                      ),
                    _buildTextField('Observaciones generales', _observacionesController),
                    _buildTextField('Trabajos pendientes', _trabajosPendientesController),
                    const SizedBox(height: 16),
                    const Text("Evidencia Fotográfica", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    _buildTextField('Descripción de evidencia fotográfica', _descripcionEvidenciaController),
                    const SizedBox(height: 8),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          SizedBox(
                            width: 140,
                            child: ElevatedButton.icon(
                              icon: const Icon(Icons.photo_library),
                              label: const Text('Seleccionar'),
                              onPressed: _selectPhoto,
                            ),
                          ),
                          const SizedBox(width: 8),
                          SizedBox(
                            width: 120,
                            child: ElevatedButton.icon(
                              icon: const Icon(Icons.upload),
                              label: const Text('Cargar'),
                              onPressed: _fotoSeleccionada != null && _descripcionEvidenciaController.text.isNotEmpty ? _loadPhoto : null,
                            ),
                          ),
                          const SizedBox(width: 8),
                          if (_evidenciaFotografica.isNotEmpty)
                            ElevatedButton.icon(
                              icon: const Icon(Icons.edit),
                              label: Text('Editar (${_evidenciaFotografica.length})'),
                              onPressed: () => _mostrarListaFotos(),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          ElevatedButton.icon(
                            icon: Icon(_editNro == null ? Icons.add : Icons.edit),
                            label: Text(_editNro == null ? 'Guardar' : 'Actualizar'),
                            onPressed: _grabarFila,
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton.icon(
                            icon: const Icon(Icons.picture_as_pdf),
                            label: const Text('Exportar'),
                            onPressed: _tabla.isEmpty ? null : _exportarPDF,
                          ),

                          const SizedBox(width: 8),
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
                          const SizedBox(width: 8),
                          ElevatedButton.icon(
                            icon: const Icon(Icons.route),
                            label: const Text('Previsualizar Ruta'),
                            onPressed: _tabla.isEmpty ? null : _previsualizarRuta,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.orange,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ],
                      ),
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
                          columns: [
                            const DataColumn(label: Text('Nro')),
                            const DataColumn(label: Text('Obs. Diseño')),
                            const DataColumn(label: Text('Poste Inter')),
                            const DataColumn(label: Text('Identificación Manual')),
                            const DataColumn(label: Text('Mantenimiento Preventivo')),
                            const DataColumn(label: Text('Acción Poste Inter')),
                            const DataColumn(label: Text('Poste inspeccionado')),
                            DataColumn(label: Text(labelSoporteRetencion)),
                            DataColumn(label: Text(labelSoporteSuspension)),
                            const DataColumn(label: Text('Morsetería')),
                            const DataColumn(label: Text('Tipo de Elemento')),
                            const DataColumn(label: Text('Modelo')),
                            const DataColumn(label: Text('Elemento de fijación')),
                            const DataColumn(label: Text('Descripción de fijación')),
                            const DataColumn(label: Text('Geolocalización')),
                            const DataColumn(label: Text('Tarjeta Identificación')),
                            const DataColumn(label: Text('Tendido Actual')),
                            const DataColumn(label: Text('Tendido Acción')),
                            const DataColumn(label: Text('Reservas Actual')),
                            const DataColumn(label: Text('Reservas Acción')),
                            const DataColumn(label: Text('Requiere poda')),

                            if (_tipoCable == '4 Hilos') const DataColumn(label: Text('Mediciones 1550nm')),
                            if (_tipoCable == '4 Hilos') const DataColumn(label: Text('Mediciones 1490nm')),
                            const DataColumn(label: Text('Observaciones')),
                            const DataColumn(label: Text('Trabajos pendientes')),
                          ],
                          rows: _tabla.map((fila) {
                            return DataRow(
                              cells: [
                                DataCell(Text('${fila['contador']}', style: const TextStyle(fontSize: 10))),
                                DataCell(Text(fila['observacionesDiseno'] ?? '', style: const TextStyle(fontSize: 10), overflow: TextOverflow.ellipsis, maxLines: 3)),
                                DataCell(Text(fila['posteInter'] ?? '', style: const TextStyle(fontSize: 10), overflow: TextOverflow.ellipsis, maxLines: 3)),
                                DataCell(Text(fila['identificacionManual'] ?? '', style: const TextStyle(fontSize: 10), overflow: TextOverflow.ellipsis, maxLines: 3)),
                                DataCell(Text(fila['mantenimientoPreventivo'] ?? '', style: const TextStyle(fontSize: 10), overflow: TextOverflow.ellipsis, maxLines: 3)),
                                DataCell(
                                  SizedBox(
                                    width: 144,
                                    child: SingleChildScrollView(
                                      scrollDirection: Axis.horizontal,
                                      child: Text(fila['accionPosteInter'] ?? '', style: const TextStyle(fontSize: 8)),
                                    ),
                                  ),
                                ),
                                DataCell(Text(fila['posteInspeccionado'] ?? '', style: const TextStyle(fontSize: 10), overflow: TextOverflow.ellipsis, maxLines: 3)),
                                DataCell(Text(fila['soporteRetencion'] ?? '', style: const TextStyle(fontSize: 10), overflow: TextOverflow.ellipsis, maxLines: 3)),
                                DataCell(Text(fila['soporteSuspension'] ?? '', style: const TextStyle(fontSize: 10), overflow: TextOverflow.ellipsis, maxLines: 3)),
                                DataCell(Text(fila['morseteriaIdentificada'] ?? '', style: const TextStyle(fontSize: 10), overflow: TextOverflow.ellipsis, maxLines: 3)),
                                DataCell(Text(fila['tipoElemento'] ?? '', style: const TextStyle(fontSize: 10), overflow: TextOverflow.ellipsis, maxLines: 3)),
                                DataCell(Text(fila['modeloElementoFijado'] ?? '', style: const TextStyle(fontSize: 10), overflow: TextOverflow.ellipsis, maxLines: 3)),
                                DataCell(Text(fila['elementoFijacion'] ?? '', style: const TextStyle(fontSize: 10), overflow: TextOverflow.ellipsis, maxLines: 3)),
                                DataCell(Text(fila['cantidadElemento'] ?? '', style: const TextStyle(fontSize: 10), overflow: TextOverflow.ellipsis, maxLines: 3)),
                                DataCell(Text(fila['geolocalizacionElemento'] ?? '', style: const TextStyle(fontSize: 10), overflow: TextOverflow.ellipsis, maxLines: 3)),
                                DataCell(Text(fila['tarjetaIdentificacion'] ?? '', style: const TextStyle(fontSize: 10), overflow: TextOverflow.ellipsis, maxLines: 3)),
                                DataCell(Text(fila['tendidoActual'] ?? '', style: const TextStyle(fontSize: 10), overflow: TextOverflow.ellipsis, maxLines: 3)),
                                DataCell(Text(fila['tendidoAccion'] ?? '', style: const TextStyle(fontSize: 10), overflow: TextOverflow.ellipsis, maxLines: 3)),
                                DataCell(Text(fila['reservasActual'] ?? '', style: const TextStyle(fontSize: 10), overflow: TextOverflow.ellipsis, maxLines: 3)),
                                DataCell(Text(fila['reservasAccion'] ?? '', style: const TextStyle(fontSize: 10), overflow: TextOverflow.ellipsis, maxLines: 3)),
                                DataCell(Text(fila['requierePoda'] ?? '', style: const TextStyle(fontSize: 10), overflow: TextOverflow.ellipsis, maxLines: 3)),

                                if (_tipoCable == '4 Hilos')
                                  DataCell(
                                    Table(
                                      border: TableBorder.all(color: Colors.grey),
                                      children: List.generate(16, (i) =>
                                        TableRow(children: [
                                          Padding(
                                            padding: const EdgeInsets.all(2),
                                            child: Text(
                                              "P${i+1}: "
                                                "${fila['medicionesPuertos1550'] != null && fila['medicionesPuertos1550'].length > i ? fila['medicionesPuertos1550'][i] : ''} dBm",
                                              style: const TextStyle(fontSize: 8, fontFamily: 'monospace'),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ]),
                                      ),
                                    ),
                                  ),
                                if (_tipoCable == '4 Hilos')
                                  DataCell(
                                    Table(
                                      border: TableBorder.all(color: Colors.grey),
                                      children: List.generate(16, (i) =>
                                        TableRow(children: [
                                          Padding(
                                            padding: const EdgeInsets.all(2),
                                            child: Text(
                                              "P${i+1}: "
                                                "${fila['medicionesPuertos1490'] != null && fila['medicionesPuertos1490'].length > i ? fila['medicionesPuertos1490'][i] : ''} dBm",
                                              style: const TextStyle(fontSize: 8, fontFamily: 'monospace'),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ]),
                                      ),
                                    ),
                                  ),
                                DataCell(Text(fila['observaciones'] ?? '', style: const TextStyle(fontSize: 10), overflow: TextOverflow.ellipsis, maxLines: 3)),
                                DataCell(Text(fila['trabajosPendientes'] ?? '', style: const TextStyle(fontSize: 10), overflow: TextOverflow.ellipsis, maxLines: 3)),
                              ],
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                    child: Text(
                      "Total de postes inspeccionados: $totalPostesInspeccionados",
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 10),
                    ),
                  )
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, {bool enabled = true, TextInputType? inputType, Function(String)? onChanged}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: TextFormField(
        controller: controller,
        enabled: enabled,
        keyboardType: inputType,
        onChanged: onChanged,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          isDense: true,
        ),
      ),
    );
  }

  Widget _buildDropdownField(String label, String value, List<String> items, ValueChanged<String?> onChanged, {bool enabled = true}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: DropdownButtonFormField<String>(
        initialValue: value,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          isDense: true,
        ),
        isExpanded: true,
        items: items.map((item) => DropdownMenuItem(
          value: item, 
          child: Text(item, overflow: TextOverflow.ellipsis, maxLines: 2)
        )).toList(),
        onChanged: enabled ? onChanged : null,
      ),
    );
  }

  Widget _buildDateField(String label, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: TextFormField(
        controller: controller,
        readOnly: true,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          isDense: true,
          suffixIcon: const Icon(Icons.calendar_today),
        ),
        onTap: () async {
          final date = await showDatePicker(
            context: context,
            initialDate: DateTime.now(),
            firstDate: DateTime.now(),
            lastDate: DateTime.now().add(const Duration(days: 365)),
          );
          if (date != null) {
            controller.text = '${date.day}/${date.month}/${date.year}';
          }
        },
      ),
    );
  }
}