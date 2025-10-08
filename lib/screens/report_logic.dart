import 'dart:io';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'package:archive/archive_io.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

Future<pw.Document> _generarPDFCompleto({
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
  required PlatformFile? archivoOtdr,
  Map<String, String>? datosTecnicos,
  Map<String, Map<int, String>>? mediciones,
  List<String>? distribucionBuffers,
}) async {
  final pdf = pw.Document();
  
  pdf.addPage(
    pw.Page(
      pageFormat: PdfPageFormat.letter,
      build: (pw.Context ctx) {
        return pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text('Reporte de Certificación', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 16),
            pw.Text('Técnico: $instalador'),
            pw.Text('Fecha: ${fecha.toLocal()}'),
            pw.Text('Ubicación: ${ubicacion != null ? "${ubicacion.latitude}, ${ubicacion.longitude}" : "No disponible"}'),
            pw.Text('Unidad de Negocios: $unidadNegocio'),
            pw.Text('Elemento: $elemento'),
            if (closureNaturaleza != null) pw.Text('Naturaleza: $closureNaturaleza'),
            if (fdtConClosureSecundario != null) pw.Text('¿Con closure secundario?: $fdtConClosureSecundario'),
            pw.SizedBox(height: 8),
            ...campos.entries.map((e) => pw.Text('${e.key}: ${e.value}')),
            pw.SizedBox(height: 8),
            pw.Text('Nomenclatura: $nomenclatura', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
            
            if (datosTecnicos != null && datosTecnicos.isNotEmpty) ...[
              pw.SizedBox(height: 16),
              pw.Text('Información Técnica $elemento', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
              ...datosTecnicos.entries.map((e) => pw.Text('${e.key}: ${e.value}')),
            ],
            
            if (distribucionBuffers != null && distribucionBuffers.isNotEmpty) ...[
              pw.SizedBox(height: 8),
              pw.Text('Distribución por buffer: ${distribucionBuffers.join(", ")}'),
            ],
            
            if (mediciones != null && mediciones.isNotEmpty) ...[
              pw.SizedBox(height: 16),
              pw.Text('Mediciones:', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
              ...mediciones.entries.map((entry) => 
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
                                    child: pw.Text('P${row * 4 + col + 1}: ${entry.value[row * 4 + col + 1] ?? "-"}', style: const pw.TextStyle(fontSize: 8)),
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
        );
      },
    ),
  );
  
  // Página de fotos y archivos adjuntos
  if (fotosPorSeccion.isNotEmpty || archivoOtdr != null) {
    pdf.addPage(
      pw.Page(
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('Fotos y Archivos Adjuntos', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 16),
              ...fotosPorSeccion.entries.map((entry) => 
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
              if (archivoOtdr != null) ...[
                pw.Text('Trazas OTDR:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                pw.Text('• ${archivoOtdr.name}'),
              ],
            ],
          );
        },
      ),
    );
  }
  
  return pdf;
}


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
  required PlatformFile? archivoOtdr,
  required BuildContext context,
  required String savePath,
  pw.Document? pdfDocument,
  Map<String, String>? datosTecnicos,
  Map<String, Map<int, String>>? mediciones,
  List<String>? distribucionBuffers,
}) async {
  try {
    // Usar el PDF proporcionado o generar uno nuevo
    final pdf = pdfDocument ?? await _generarPDFCompleto(
      instalador: instalador,
      fecha: fecha,
      ubicacion: ubicacion,
      unidadNegocio: unidadNegocio,
      elemento: elemento,
      closureNaturaleza: closureNaturaleza,
      fdtConClosureSecundario: fdtConClosureSecundario,
      campos: campos,
      nomenclatura: nomenclatura,
      fotosPorSeccion: fotosPorSeccion,
      archivoOtdr: archivoOtdr,
      datosTecnicos: datosTecnicos,
      mediciones: mediciones,
      distribucionBuffers: distribucionBuffers,
    );

    final archive = Archive();
    final pdfName = nomenclatura.isNotEmpty ? '$nomenclatura.pdf' : 'reporte.pdf';
    final pdfBytes = await pdf.save();
    archive.addFile(ArchiveFile(pdfName, pdfBytes.length, pdfBytes));

    // Agregar fotos al ZIP (no al PDF, ya están en el PDF)
    for (final entry in fotosPorSeccion.entries) {
      final seccion = entry.key;
      for (int i = 0; i < entry.value.length; i++) {
        final file = entry.value[i];
        final ext = file.extension ?? "jpg";
        final nombreFoto = "${seccion.replaceAll(" ", "_")}_${i + 1}.$ext";
        try {
          final bytes = file.bytes ?? await File(file.path!).readAsBytes();
          archive.addFile(ArchiveFile(
            nombreFoto,
            bytes.length,
            bytes,
          ));
        } catch (e) {
          debugPrint('Error adding photo $nombreFoto: $e');
        }
      }
    }

    // Agregar PDF OTDR al ZIP
    if (archivoOtdr != null) {
      try {
        final bytes = archivoOtdr.bytes ?? await File(archivoOtdr.path!).readAsBytes();
        archive.addFile(ArchiveFile(
          archivoOtdr.name,
          bytes.length,
          bytes,
        ));
      } catch (e) {
        debugPrint('Error adding OTDR PDF: $e');
      }
    }

    final safeName = nomenclatura.isNotEmpty ? nomenclatura.replaceAll(RegExp(r'[<>:"/\\|?*\x00-\x1F\s]'), '_') : 'reporte';
    final zipName = '$safeName.zip';
    final zipPath = '$savePath/$zipName';
    final zipFile = File(zipPath);
    final zipBytes = ZipEncoder().encode(archive);
    if (zipBytes != null) {
      await zipFile.writeAsBytes(zipBytes);
      return true;
    }
    return false;
  } catch (e) {
    debugPrint('Error generating ZIP: $e');
    return false;
  }
}

Future<bool> saveAndCompressToDownloads({
  required String nomenclatura,
  required pw.Document pdf,
  required Map<String, List<PlatformFile>> fotosPorSeccion,
  required BuildContext context,
}) async {
  try {
    // 1. Solicitar permiso (solo Android)
    if (Platform.isAndroid) {
      var status = await Permission.storage.request();
      if (!status.isGranted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Permiso de almacenamiento requerido")),
        );
        return false;
      }
    }

    // 2. Crear carpeta temporal
    final tempDir = await getTemporaryDirectory();
    final String safeName = nomenclatura.replaceAll(RegExp(r'[<>:"/\\|?*\x00-\x1F]'), '_');
    final Directory reportDir = Directory('${tempDir.path}/$safeName');
    if (await reportDir.exists()) {
      await reportDir.delete(recursive: true);
    }
    await reportDir.create(recursive: true);

    // 3. Guardar PDF
    final File pdfFile = File('${reportDir.path}/reporte.pdf');
    await pdfFile.writeAsBytes(await pdf.save());

    // 4. Guardar fotos
    for (final entry in fotosPorSeccion.entries) {
      String seccion = entry.key.replaceAll(RegExp(r'[^\w]'), '_');
      for (int i = 0; i < entry.value.length; i++) {
        final file = entry.value[i];
        String ext = file.extension ?? 'jpg';
        String nombre = '${seccion}_${i + 1}.$ext';
        File destino = File('${reportDir.path}/$nombre');

        if (file.path != null) {
          await File(file.path!).copy(destino.path);
        } else if (file.bytes != null) {
          await destino.writeAsBytes(file.bytes!);
        }
      }
    }

    // 5. Comprimir la carpeta en un ZIP
    final downloadsDir = await getDownloadsDirectory();
    if (downloadsDir == null) {
      throw Exception("No se pudo acceder a la carpeta de descargas");
    }
    final zipPath = '${downloadsDir.path}/Reporte_$safeName.zip';
    final encoder = ZipFileEncoder();
    encoder.create(zipPath);
    encoder.addDirectory(reportDir, includeDirName: true);
    encoder.close();

    // 7. Mostrar éxito
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Guardado en:\n$zipPath"),
        duration: const Duration(seconds: 5),
      ),
    );

    // Limpiar carpeta temporal
    await reportDir.delete(recursive: true);

    return true;

  } catch (e) {
    debugPrint("Error: $e");
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Error al guardar: $e")),
    );
    return false;
  }
}

Future<bool> saveReportToFolder({
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
    // 1. Crear el PDF en memoria (misma lógica que antes)
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
    final pdfBytes = await pdf.save();

    // 2. Crear la carpeta de destino
    final downloadsDir = await getDownloadsDirectory();
    final folderName = 'Reporte_${nomenclatura.isNotEmpty ? nomenclatura : DateTime.now().millisecondsSinceEpoch}';
    final reportDir = Directory('${downloadsDir!.path}/$folderName');
    await reportDir.create(recursive: true);

    // 3. Guardar el PDF en la nueva carpeta
    final pdfFile = File('${reportDir.path}/Reporte_$nomenclatura.pdf');
    await pdfFile.writeAsBytes(pdfBytes);

    // 4. Guardar las fotos con nombres estructurados
    for (final entry in fotosPorSeccion.entries) {
      final seccion = entry.key;
      for (int i = 0; i < entry.value.length; i++) {
        final file = entry.value[i];
        final ext = file.extension ?? "jpg";
        final nombreFoto = "${seccion.replaceAll(" ", "_")}_${i + 1}.$ext";
        final fotoFile = File('${reportDir.path}/$nombreFoto');
        await fotoFile.writeAsBytes(file.bytes ?? await File(file.path!).readAsBytes());
      }
    }

    return true;
  } catch (e) {
    // Puedes agregar un log aquí para depurar si es necesario: print(e);
    return false;
  }
}
