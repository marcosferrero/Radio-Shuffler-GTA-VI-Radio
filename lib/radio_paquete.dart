import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:archive/archive_io.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

// ---------------------------------------------------------------------------
// Paquete de radio (.gtaradio)
//
// Es un ZIP sin compresión (el audio ya viene comprimido) con, en plano:
//   radio.json   -> nombre, archivo, logo (opcional), segmentos
//   audio.<ext>  -> el archivo largo de audio/vídeo
//   logo_*.<ext> -> el logotipo, si lo hay
//
// Es exactamente el contenido de la carpeta de una emisora, así que exportar
// es empaquetarla e importar es desempaquetarla en una carpeta nueva.
// ---------------------------------------------------------------------------

const extensionPaquete = 'gtaradio';

class ErrorPaquete implements Exception {
  final String mensaje;
  ErrorPaquete(this.mensaje);
  @override
  String toString() => mensaje;
}

/// Solo nombres de archivo planos: nada de rutas ni "..".
bool _nombreSeguro(String n) =>
    n.isNotEmpty && n == n.split(RegExp(r'[\\/]')).last && n != '.' && n != '..';

String _nombreArchivoSeguro(String nombre) =>
    nombre.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_').trim();

// ---------------------------------------------------------------------------
// Exportar
// ---------------------------------------------------------------------------

/// Empaqueta la carpeta de una emisora y abre el menú de compartir del sistema
/// (desde ahí se puede guardar en Drive, enviar por mensajería, etc.).
Future<void> exportarRadio({
  required String carpeta,
  required String nombre,
}) async {
  final jsonFile = File('$carpeta/radio.json');
  if (!await jsonFile.exists()) throw ErrorPaquete('La emisora no tiene radio.json.');
  final datos = jsonDecode(await jsonFile.readAsString()) as Map<String, dynamic>;

  // Solo se empaqueta lo que radio.json usa (se descartan logos antiguos sueltos).
  final nombres = <String>{'radio.json'};
  final archivo = datos['archivo'];
  if (archivo is String && _nombreSeguro(archivo)) nombres.add(archivo);
  final logo = datos['logo'];
  if (logo is String && _nombreSeguro(logo) && await File('$carpeta/$logo').exists()) {
    nombres.add(logo);
  }

  final tmp = await getTemporaryDirectory();
  final destino = '${tmp.path}/${_nombreArchivoSeguro(nombre)}.$extensionPaquete';
  final f = File(destino);
  if (await f.exists()) await f.delete();

  final zip = ZipFileEncoder();
  zip.create(destino);
  try {
    for (final n in nombres) {
      final origen = File('$carpeta/$n');
      if (!await origen.exists()) throw ErrorPaquete('Falta el archivo «$n» de la emisora.');
      // Nivel 0 = almacenar sin comprimir. Se lee en streaming, sin cargarlo en memoria.
      await zip.addFile(origen, n, 0);
    }
  } finally {
    await zip.close();
  }

  await SharePlus.instance.share(
    ShareParams(
      files: [XFile(destino, mimeType: 'application/zip')],
      subject: nombre,
    ),
  );
}

// ---------------------------------------------------------------------------
// Importar
// ---------------------------------------------------------------------------

/// Importa un paquete. Devuelve la carpeta creada dentro de [base].
///
/// - Valida radio.json antes de dar nada por bueno.
/// - Extrae a una carpeta temporal y solo al final la renombra: si algo falla,
///   no queda una emisora a medias.
/// - Si ya existe una carpeta con ese nombre, crea "Nombre (2)", etc.
/// - Genera una semilla nueva para la radio importada: la programación en vivo
///   depende de la semilla, así que no sonará igual que en el móvil de quien
///   la exportó (ni que otra importación del mismo paquete).
Future<String> importarRadio({
  required File paquete,
  required Directory base,
}) async {
  final tmp = Directory('${base.path}/.importando_${DateTime.now().millisecondsSinceEpoch}');
  await tmp.create(recursive: true);

  final entrada = InputFileStream(paquete.path);
  try {
    final zip = ZipDecoder().decodeStream(entrada);

    // 1) radio.json, validado antes de extraer nada pesado.
    final entradaJson = zip.files.where((f) => f.isFile && f.name == 'radio.json');
    if (entradaJson.isEmpty) throw ErrorPaquete('No es un paquete de radio válido (falta radio.json).');
    final datos = _validarJson(
      jsonDecode(utf8.decode(entradaJson.first.content as List<int>)),
    );
    final archivo = datos['archivo'] as String;
    final logo = datos['logo'] as String?;

    // 2) Extraer solo lo que radio.json referencia, a disco y en streaming.
    final necesarios = {'radio.json', archivo, if (logo != null) logo};
    final extraidos = <String>{};
    for (final f in zip.files) {
      if (!f.isFile || !necesarios.contains(f.name)) continue;
      final out = OutputFileStream('${tmp.path}/${f.name}');
      f.writeContent(out);
      await out.close();
      extraidos.add(f.name);
    }
    if (!extraidos.contains(archivo)) {
      throw ErrorPaquete('El paquete no incluye el audio «$archivo».');
    }
    // El logo es opcional: si falta, se quita la referencia.
    if (logo != null && !extraidos.contains(logo)) datos.remove('logo');

    // Semilla nueva (la del paquete, si la trae, se descarta).
    datos['semilla'] = Random.secure().nextInt(0x7FFFFFFF);
    await File('${tmp.path}/radio.json').writeAsString(jsonEncode(datos));

    // 3) Carpeta final, sin pisar ninguna existente.
    final nombre = (datos['nombre'] as String).trim();
    final baseNombre = _nombreArchivoSeguro(nombre).isEmpty ? 'Radio' : _nombreArchivoSeguro(nombre);
    var destino = '${base.path}/$baseNombre';
    for (var i = 2; await Directory(destino).exists(); i++) {
      destino = '${base.path}/$baseNombre ($i)';
    }
    await tmp.rename(destino);
    return destino;
  } on ErrorPaquete {
    rethrow;
  } on FormatException {
    throw ErrorPaquete('El archivo no es un paquete de radio válido.');
  } finally {
    await entrada.close();
    if (await tmp.exists()) await tmp.delete(recursive: true);
  }
}

/// Comprueba la estructura mínima que necesita Emisora.desdeJson.
Map<String, dynamic> _validarJson(dynamic j) {
  if (j is! Map<String, dynamic>) throw ErrorPaquete('radio.json no es válido.');
  final nombre = j['nombre'];
  if (nombre is! String || nombre.trim().isEmpty) throw ErrorPaquete('La radio no tiene nombre.');
  final archivo = j['archivo'];
  if (archivo is! String || !_nombreSeguro(archivo)) throw ErrorPaquete('Nombre de audio no válido.');
  final logo = j['logo'];
  if (logo != null && (logo is! String || !_nombreSeguro(logo))) {
    throw ErrorPaquete('Nombre de logotipo no válido.');
  }
  final segs = j['segmentos'];
  if (segs is! List || segs.isEmpty) throw ErrorPaquete('La radio no tiene pistas.');
  for (final s in segs) {
    if (s is! Map || s['inicio'] is! num || s['fin'] is! num || (s['fin'] as num) <= (s['inicio'] as num)) {
      throw ErrorPaquete('Hay una pista con tiempos no válidos.');
    }
  }
  return j;
}
