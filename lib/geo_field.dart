import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

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
  Future<void> _openMap() async {
    Position? current;
    try {
      current = await Geolocator.getCurrentPosition();
    } catch (_) {
      current = null;
    }
    LatLng initial = current != null
        ? LatLng(current.latitude, current.longitude)
        : const LatLng(10.5, -66.9); // default fallback

    LatLng? picked = await showDialog<LatLng>(
      context: context,
      builder: (context) {
        LatLng? selected = initial;
        return AlertDialog(
          title: const Text('Seleccione ubicación'),
          content: SizedBox(
            width: 300,
            height: 350,
            child: GoogleMap(
              initialCameraPosition: CameraPosition(target: initial, zoom: 16),
              markers: {
                Marker(
                  markerId: const MarkerId('pick'),
                  position: selected,
                  draggable: true,
                  onDragEnd: (p) {
                    selected = p;
                  },
                ),
              },
              onTap: (point) {
                selected = point;
                (context as Element).markNeedsBuild();
              },
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancelar")),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, selected),
              child: const Text("Usar ubicación"),
            ),
          ],
        );
      },
    );
    if (picked != null) {
      widget.controller.text = "${picked.latitude},${picked.longitude}";
      setState(() {});
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
          suffixIcon: IconButton(
            icon: const Icon(Icons.map, color: Colors.blueAccent),
            onPressed: widget.enabled ? _openMap : null,
            tooltip: 'Seleccionar en mapa',
          ),
        ),
        readOnly: true,
        onTap: widget.enabled ? _openMap : null,
      ),
    );
  }
}