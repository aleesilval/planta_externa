import 'dart:io';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'package:archive/archive_io.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:geolocator/geolocator.dart';

Future<bool> generateAndCompressReport({
  required String instalador,
  required DateTime fecha,
  required Position? ubicacion,
  required String unidadNegocio,
  required String? elemento,
  required String? closureNaturaleza,
  required String? fdtConClosureSecundario,
  required Map<String, String> campos,
  required String nomenclatura,
  required Map<String, List<PlatformFile>> fotosPorSeccion,
  required BuildContext context,
}) async {
  try {
    final pdf = pw.Document();
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.letter,
        build: (pw.Context ctx) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('Reporte de Instalación', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 16),
              pw.Text('Instalador: $instalador'),
              pw.Text('Fecha: ${fecha.toLocal()}'),
              pw.Text('Ubicación: ${ubicacion != null ? "${ubicacion.latitude}, ${ubicacion.longitude}" : "No disponible"}'),
              pw.Text('Unidad de Negocios: $unidadNegocio'),
              pw.Text('Elemento: $elemento'),
              if (closureNaturaleza != null) pw.Text('Naturaleza: $closureNaturaleza'),
              if (fdtConClosureSecundario != null) pw.Text('¿Con closure secundario?: $fdtConClosureSecundario'),
              pw.SizedBox(height: 8),
              ...campos.entries.map((e) => pw.Text('${e.key}: ${e.value}')),
              pw.SizedBox(height: 8),
              pw.Text('Nomenclatura generada: $nomenclatura', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
            ],
          );
        },
      ),
    );

    final tempDir = await getTemporaryDirectory();
    final pdfPath = '${tempDir.path}/reporte.pdf';
    final pdfFile = File(pdfPath);
    await pdfFile.writeAsBytes(await pdf.save());

    final archive = Archive();

    archive.addFile(ArchiveFile('Reporte_$nomenclatura.pdf', await pdfFile.length(), await pdfFile.readAsBytes()));

    for (final entry in fotosPorSeccion.entries) {
      final seccion = entry.key;
      for (int i = 0; i < entry.value.length; i++) {
        final file = entry.value[i];
        final ext = file.extension ?? "jpg";
        final nombreFoto = "${seccion.replaceAll(" ", "_")}_${i + 1}.$ext";
        archive.addFile(ArchiveFile(
          nombreFoto,
          file.size,
          file.bytes ?? await File(file.path!).readAsBytes(),
        ));
      }
    }

    final downloadsDir = await getDownloadsDirectory();
    final zipPath = '${downloadsDir!.path}/Reporte_${nomenclatura.isNotEmpty ? nomenclatura : DateTime.now().millisecondsSinceEpoch}.zip';
    final zipFile = File(zipPath);
    await zipFile.writeAsBytes(ZipEncoder().encode(archive)!);

    return true;
  } catch (e) {
    return false;
  }
}