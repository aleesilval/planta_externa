// ignore_for_file: prefer_const_constructors

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

/// Widget que muestra un mapa con una lista de coordenadas y/o un marcador único.
class MapaConFondo extends StatelessWidget {
  final List<Map<String, dynamic>> coordenadas;
  final LatLng? singleMarker;
  final Function(TapPosition, LatLng)? onTap;

  const MapaConFondo({
    super.key,
    this.coordenadas = const [],
    this.singleMarker,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
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

    if (singleMarker != null) {
      markers.add(Marker(
        point: singleMarker!,
        width: 40,
        height: 40,
        child: const Icon(Icons.location_on, color: Colors.red, size: 40),
      ));
    }

    return FlutterMap(
      options: MapOptions(
        initialCenter: points.isNotEmpty ? (points.length == 1 ? points.first : LatLng(points.map((p) => p.latitude).reduce((a, b) => a + b) / points.length, points.map((p) => p.longitude).reduce((a, b) => a + b) / points.length)) : (singleMarker ?? const LatLng(10.5, -66.9)),
        initialZoom: points.isNotEmpty ? (points.length == 1 ? 13.0 : 12.0) : 16.0,
        onTap: onTap,
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.example.planta_externa',
        ),
        if (points.length > 1) PolylineLayer(polylines: [Polyline(points: points, color: Colors.red, strokeWidth: 3)]),
        MarkerLayer(markers: markers),
        RichAttributionWidget(
          attributions: [
            TextSourceAttribution('OpenStreetMap contributors'),
          ],
        ),
      ],
    );
  }
}