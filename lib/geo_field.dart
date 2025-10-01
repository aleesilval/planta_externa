import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class GeoField extends StatefulWidget {
  final TextEditingController controller;
  final String label;
  final bool enabled;

  const GeoField({
    super.key,
    required this.controller,
    required this.label,
    this.enabled = true,
  });

  @override
  State<GeoField> createState() => _GeoFieldState();
}

class _GeoFieldState extends State<GeoField> {
  Future<bool> _ensurePermission() async {
    // Verificar que los servicios de ubicación estén activos
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Activa los servicios de ubicación (GPS).')),
        );
      }
      return false;
    }

    // Verificar y solicitar permisos
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.deniedForever) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Permiso de ubicación denegado permanentemente. Habilítalo en Ajustes.')),
        );
      }
      return false;
    }
    if (permission == LocationPermission.denied) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Se requiere permiso de ubicación para continuar.')),
        );
      }
      return false;
    }
    return true;
  }

  Future<void> _getCurrentLocation() async {
    if (!widget.enabled) return;
    final hasPerm = await _ensurePermission();
    if (!hasPerm) return;

    try {
      final pos = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      final lat = pos.latitude.toStringAsFixed(6);
      final lng = pos.longitude.toStringAsFixed(6);
      widget.controller.text = "$lat,$lng";
      if (mounted) setState(() {});
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No se pudo obtener la ubicación: $e')),
        );
      }
    }
  }

  Future<void> _openMap() async {
    if (!widget.enabled) return;
    Position? current;
    try {
      final hasPerm = await _ensurePermission();
      if (!hasPerm) {
        current = null;
      } else {
        current = await Geolocator.getCurrentPosition();
      }
    } catch (_) {
      current = null;
    }

    final LatLng initial = current != null
        ? LatLng(current.latitude, current.longitude)
        : const LatLng(10.500000, -66.900000); // Fallback

    final LatLng? picked = await showDialog<LatLng>(
      context: context,
      builder: (context) {
        LatLng selected = initial;
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: const Text('Seleccione ubicación'),
              content: SizedBox(
                width: 320,
                height: 380,
                child: FlutterMap(
                  options: MapOptions(
                    initialCenter: initial,
                    initialZoom: 16,
                    onTap: (tapPosition, point) {
                      setStateDialog(() {
                        selected = point;
                      });
                    },
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: 'https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}.png',
                      subdomains: const ['a', 'b', 'c', 'd'],
                      userAgentPackageName: 'com.example.planta_externa',
                    ),
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: selected,
                          width: 40,
                          height: 40,
                          child: const Icon(Icons.location_on, color: Colors.red, size: 40),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context, selected),
                  child: const Text('Usar ubicación'),
                ),
              ],
            );
          },
        );
      },
    );

    if (picked != null) {
      final lat = picked.latitude.toStringAsFixed(6);
      final lng = picked.longitude.toStringAsFixed(6);
      widget.controller.text = "$lat,$lng";
      if (mounted) setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: TextFormField(
        controller: widget.controller,
        enabled: widget.enabled,
        decoration: InputDecoration(
          labelText: widget.label,
          border: const OutlineInputBorder(),
          isDense: true,
          suffixIcon: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.my_location, color: Colors.green),
                onPressed: widget.enabled ? _getCurrentLocation : null,
                tooltip: 'Usar GPS',
              ),
              IconButton(
                icon: const Icon(Icons.map, color: Colors.blueAccent),
                onPressed: widget.enabled ? _openMap : null,
                tooltip: 'Seleccionar en mapa',
              ),
            ],
          ),
        ),
        readOnly: true,
        onTap: widget.enabled ? _getCurrentLocation : null,
      ),
    );
  }
}
