import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:ui' show FontFeature;

import 'package:audio_service/audio_service.dart';
import 'package:audio_session/audio_session.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';

import 'radio_paquete.dart';

late Reproductor radio;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  radio = await AudioService.init<Reproductor>(
    builder: () => Reproductor(),
    config: const AudioServiceConfig(
      androidNotificationChannelId: 'com.example.gtaradio.audio',
      androidNotificationChannelName: 'Radio',
      androidNotificationOngoing: true,
      androidNotificationIcon: 'drawable/ic_notification',
    ),
  );
  await radio.iniciarSesion();
  await radio.cargarHistorial();
  await cargarIdiomaApp();
  await radio.inicializarEq();
  runApp(const RadioApp());
}

// ---------------------------------------------------------------------------
// Almacenamiento: carpeta interna de la app (no hace falta ningún permiso)
// ---------------------------------------------------------------------------

Future<Directory> carpetaRadios() async {
  final base = await getApplicationDocumentsDirectory();
  final dir = Directory('${base.path}/radios');
  await dir.create(recursive: true);
  return dir;
}

/// Carga y ordena todas las emisoras válidas guardadas en disco.
Future<List<Emisora>> cargarEmisorasDisco() async {
  final dir = await carpetaRadios();
  final lista = <Emisora>[];
  await for (final e in dir.list()) {
    if (e is! Directory) continue;
    final json = File('${e.path}/radio.json');
    if (!await json.exists()) continue;
    try {
      final datos = jsonDecode(await json.readAsString());
      if (datos is Map<String, dynamic>) {
        lista.add(await Emisora.desdeJsonAsync(datos, e.path));
      }
    } catch (_) {
      // radio.json mal formado: se ignora esa emisora
    }
  }
  lista.sort((a, b) => a.nombre.compareTo(b.nombre));
  return lista;
}

final idiomaApp = ValueNotifier<String>('es');

const Map<String, Map<String, String>> _textosApp = {
  'es': {
    'app_title': 'Radio GTA',
    'radio_title': 'Radio',
    'language_tooltip': 'Idioma / Language',
    'lang_es': 'Español',
    'lang_en': 'Inglés',
    'import_package_tooltip': 'Importar radio (.gtaradio)',
    'add_radio': 'Añadir radio',
    'no_stations': 'Todavía no hay emisoras.\nPulsa «Añadir radio» para importar una.',
    'segments_count': '{n} segmentos',
    'edit_tracks': 'Editar pistas',
    'export_radio': 'Exportar radio',
    'delete_radio': 'Borrar radio',
    'delete_radio_title': '¿Borrar "{nombre}"?',
    'delete_radio_body': 'Se elimina el archivo de la app. El original no se toca.',
    'cancel': 'Cancelar',
    'delete': 'Borrar',
    'preparing_radio': 'Preparando «{nombre}»…',
    'importing_radio': 'Importando radio…',
    'radio_imported': 'Radio importada.',
    'error_prefix': 'Error: {err}',
    'missing_import_fields': 'Falta el nombre, el archivo o la lista de pistas.',
    'cannot_read_duration': 'No se pudo leer la duración del archivo.',
    'no_timestamps': 'No he encontrado marcas de tiempo en la lista.',
    'station_name_label': 'Nombre de la emisora',
    'pick_media': 'Elegir vídeo o audio',
    'pick_logo': 'Elegir logotipo (opcional)',
    'pick_logo_short': 'Elegir logotipo',
    'change_logo': 'Cambiar logotipo',
    'remove_logo': 'Quitar logotipo',
    'remove': 'Quitar',
    'tracklist_label': 'Lista de pistas',
    'tracklist_hint': '0:00 Artista - Canción\n3:41 [loc] Locutor\n4:20 Artista - Canción\n8:02 [ad] Anuncio',
    'tracklist_helper': 'Una por línea, con su marca de tiempo. [loc] = locutor, [ad] = anuncio.',
    'import_btn': 'Importar',
    'working_long_file': 'Trabajando… con vídeos largos puede tardar varios minutos.',
    'type_cancion': 'Canción',
    'type_locutor': 'Locutor',
    'type_anuncio': 'Anuncio',
    'cannot_play_clip': 'No se pudo reproducir ese tramo.',
    'track_deleted': 'Pista borrada',
    'undo': 'Deshacer',
    'set_station_name': 'Pon un nombre a la emisora.',
    'need_one_track': 'Tiene que quedar al menos una pista.',
    'cannot_save': 'No se pudo guardar: {err}',
    'discard_changes_title': '¿Descartar los cambios?',
    'keep_editing': 'Seguir editando',
    'discard': 'Descartar',
    'save_tooltip': 'Guardar',
    'add_track': 'Añadir pista',
    'tracks_count': '{n} pistas',
    'tracks_and_duration': '{n} pistas · archivo de {dur}',
    'new_track': 'Nueva pista',
    'edit_track': 'Editar pista',
    'title_label': 'Título',
    'invalid_start': 'El inicio no es válido (usa 3:41 o 1:02:10).',
    'invalid_end': 'El final no es válido (usa 3:41 o 1:02:10).',
    'set_title': 'Pon un título.',
    'invalid_times': 'Los tiempos no son válidos (usa 3:41 o 1:02:10).',
    'end_before_start': 'El final tiene que ser posterior al inicio.',
    'end_exceeds_duration': 'El final supera la duración del archivo ({dur}).',
    'start_label': 'Inicio',
    'end_label': 'Final',
    'listen_start': 'Oír inicio',
    'listen_end': 'Oír final',
    'accept': 'Aceptar',
    'image_format_msg': 'Elige una imagen PNG, JPG o WEBP.',
    'close_tooltip': 'Cerrar',
    'pause_tooltip': 'Pausar',
    'resume_tooltip': 'Reanudar',
    'stop_radio': 'Detener radio',
    'up_next': 'A continuación',
    'recent_tracks': 'Últimas pistas',
    'clear_btn': 'Borrar',
    'live_badge': 'En directo',
    'paused_badge': 'En pausa',
    'live_upper': 'EN DIRECTO',
    'dial_mode_tooltip': 'Modo Dial GTA',
    'list_mode_tooltip': 'Modo Lista',
    'mode_live': 'EN DIRECTO',
    'mode_history': 'HISTORIAL',
    'mode_queue': 'SIGUIENTE',
    'turn_off': 'APAGAR',
    'radio_off': 'RADIO APAGADA',
    'tap_station_to_tune': 'Elige una emisora en el dial',
    'manage_stations': 'EMISORAS Y EDITAR',
    'no_stations_dial': 'AÚN NO HAY EMISORAS',
    'add_first_station': 'AÑADIR RADIO',
    'create_station': 'CREAR EMISORA',
    'new_station': 'Nueva emisora',
    'new_station_desc': 'Crear desde audio/vídeo, logo y lista de pistas',
    'import_gtaradio': 'Importar paquete (.gtaradio)',
    'import_gtaradio_desc': 'Cargar una emisora ya empaquetada',
    'edit_tracks_desc': 'Cambiar nombre, logotipo y tiempos de las pistas',
    'export_radio_desc': 'Compartir emisora como paquete .gtaradio',
    'settings': 'Ajustes',
    'settings_tooltip': 'Ajustes',
    'equalizer': 'Ecualizador',
    'eq_on': 'Activado',
    'eq_off': 'Desactivado',
    'eq_flat': 'Plano',
    'eq_bass': 'Bajos',
    'eq_rock': 'Rock',
    'eq_pop': 'Pop',
    'eq_electronic': 'Electrónica',
    'eq_voice': 'Voz',
    'eq_custom': 'Personalizado',
    'eq_reset': 'Restablecer',
    'eq_needs_android': 'El ecualizador necesita un dispositivo Android.',
    'language': 'Idioma',
  },
  'en': {
    'app_title': 'Radio GTA',
    'radio_title': 'Radio',
    'language_tooltip': 'Language / Idioma',
    'lang_es': 'Spanish',
    'lang_en': 'English',
    'import_package_tooltip': 'Import radio (.gtaradio)',
    'add_radio': 'Add radio',
    'no_stations': 'No stations yet.\nTap "Add radio" to import one.',
    'segments_count': '{n} segments',
    'edit_tracks': 'Edit tracks',
    'export_radio': 'Export radio',
    'delete_radio': 'Delete radio',
    'delete_radio_title': 'Delete "{nombre}"?',
    'delete_radio_body': 'The app file is removed. The original file is untouched.',
    'cancel': 'Cancel',
    'delete': 'Delete',
    'preparing_radio': 'Preparing "{nombre}"…',
    'importing_radio': 'Importing radio…',
    'radio_imported': 'Radio imported.',
    'error_prefix': 'Error: {err}',
    'missing_import_fields': 'Missing station name, media file, or tracklist.',
    'cannot_read_duration': 'Could not read the media file duration.',
    'no_timestamps': 'No timestamps found in the tracklist.',
    'station_name_label': 'Station name',
    'pick_media': 'Choose video or audio',
    'pick_logo': 'Choose logo (optional)',
    'pick_logo_short': 'Choose logo',
    'change_logo': 'Change logo',
    'remove_logo': 'Remove logo',
    'remove': 'Remove',
    'tracklist_label': 'Tracklist',
    'tracklist_hint': '0:00 Artist - Song\n3:41 [loc] Host\n4:20 Artist - Song\n8:02 [ad] Ad',
    'tracklist_helper': 'One per line with a timestamp. [loc] = host, [ad] = ad.',
    'import_btn': 'Import',
    'working_long_file': 'Working… long videos can take several minutes.',
    'type_cancion': 'Song',
    'type_locutor': 'Host',
    'type_anuncio': 'Ad',
    'cannot_play_clip': 'Could not play that segment.',
    'track_deleted': 'Track deleted',
    'undo': 'Undo',
    'set_station_name': 'Enter a station name.',
    'need_one_track': 'At least one track must remain.',
    'cannot_save': 'Could not save: {err}',
    'discard_changes_title': 'Discard changes?',
    'keep_editing': 'Keep editing',
    'discard': 'Discard',
    'save_tooltip': 'Save',
    'add_track': 'Add track',
    'tracks_count': '{n} tracks',
    'tracks_and_duration': '{n} tracks · {dur} file',
    'new_track': 'New track',
    'edit_track': 'Edit track',
    'title_label': 'Title',
    'invalid_start': 'Start time is invalid (use 3:41 or 1:02:10).',
    'invalid_end': 'End time is invalid (use 3:41 or 1:02:10).',
    'set_title': 'Enter a title.',
    'invalid_times': 'Times are invalid (use 3:41 or 1:02:10).',
    'end_before_start': 'End time must be after start time.',
    'end_exceeds_duration': 'End time exceeds file duration ({dur}).',
    'start_label': 'Start',
    'end_label': 'End',
    'listen_start': 'Play start',
    'listen_end': 'Play end',
    'accept': 'OK',
    'image_format_msg': 'Choose a PNG, JPG, or WEBP image.',
    'close_tooltip': 'Close',
    'pause_tooltip': 'Pause',
    'resume_tooltip': 'Resume',
    'stop_radio': 'Stop radio',
    'up_next': 'Up next',
    'recent_tracks': 'Recent tracks',
    'clear_btn': 'Clear',
    'live_badge': 'Live',
    'paused_badge': 'Paused',
    'live_upper': 'LIVE',
    'dial_mode_tooltip': 'GTA Dial Mode',
    'list_mode_tooltip': 'List Mode',
    'mode_live': 'LIVE RADIO',
    'mode_history': 'RECENT',
    'mode_queue': 'UP NEXT',
    'turn_off': 'TURN OFF',
    'radio_off': 'RADIO OFF',
    'tap_station_to_tune': 'Select a station on the dial',
    'manage_stations': 'STATIONS & EDIT',
    'no_stations_dial': 'NO STATIONS YET',
    'add_first_station': 'ADD STATION',
    'create_station': 'CREATE STATION',
    'new_station': 'New station',
    'new_station_desc': 'Create from audio/video, logo and tracklist',
    'import_gtaradio': 'Import package (.gtaradio)',
    'import_gtaradio_desc': 'Load an already packaged station',
    'edit_tracks_desc': 'Edit station name, logo and track timestamps',
    'export_radio_desc': 'Share station as a .gtaradio package',
    'settings': 'Settings',
    'settings_tooltip': 'Settings',
    'equalizer': 'Equalizer',
    'eq_on': 'On',
    'eq_off': 'Off',
    'eq_flat': 'Flat',
    'eq_bass': 'Bass',
    'eq_rock': 'Rock',
    'eq_pop': 'Pop',
    'eq_electronic': 'Electronic',
    'eq_voice': 'Voice',
    'eq_custom': 'Custom',
    'eq_reset': 'Reset',
    'eq_needs_android': 'Equalizer requires an Android device.',
    'language': 'Language',
  },
};

String _t(String key, [Map<String, String> params = const {}]) {
  final mapa = _textosApp[idiomaApp.value] ?? _textosApp['es']!;
  var s = mapa[key] ?? _textosApp['es']![key] ?? key;
  for (final e in params.entries) {
    s = s.replaceAll('{${e.key}}', e.value);
  }
  return s;
}

const _tiposSegmento = ['cancion', 'locutor', 'anuncio'];

String _etiquetaTipo(String tipo) {
  switch (tipo) {
    case 'locutor':
      return _t('type_locutor');
    case 'anuncio':
      return _t('type_anuncio');
    case 'cancion':
    default:
      return _t('type_cancion');
  }
}

Future<File> _archivoPreferencias() async {
  final base = await getApplicationDocumentsDirectory();
  return File('${base.path}/preferencias_radio.json');
}

Future<void> cargarIdiomaApp() async {
  try {
    final f = await _archivoPreferencias();
    if (!await f.exists()) return;
    final data = jsonDecode(await f.readAsString());
    if (data is Map<String, dynamic>) {
      final lang = data['idioma'];
      if (lang == 'es' || lang == 'en') {
        idiomaApp.value = lang;
      }
    }
  } catch (_) {}
}

Future<void> cambiarIdiomaApp(String codigo) async {
  if (codigo != 'es' && codigo != 'en') return;
  idiomaApp.value = codigo;
  try {
    final f = await _archivoPreferencias();
    Map<String, dynamic> data = {};
    if (await f.exists()) {
      final decoded = jsonDecode(await f.readAsString());
      if (decoded is Map<String, dynamic>) data = decoded;
    }
    data['idioma'] = codigo;
    await f.writeAsString(jsonEncode(data));
  } catch (_) {}
}

// ---------------------------------------------------------------------------
// Modelo
// ---------------------------------------------------------------------------

class Segmento {
  final String archivo; // ruta absoluta del audio/vídeo largo
  final Duration inicio;
  final Duration fin;
  final String tipo; // cancion | locutor | anuncio
  final String titulo;

  const Segmento({
    required this.archivo,
    required this.inicio,
    required this.fin,
    required this.tipo,
    required this.titulo,
  });
}

class Emisora {
  final String nombre;
  final String carpeta;
  final String archivo; // ruta absoluta del archivo de audio/vídeo
  final List<Segmento> segmentos;
  final String? logo; // ruta absoluta de la imagen, si la emisora tiene logotipo

  /// Semilla de la programación en vivo. Las radios importadas de otra persona
  /// reciben una nueva (ver importarRadio). Si es null (radios anteriores a este
  /// campo), se usa el hash del nombre, así su programación no cambia.
  final int? semilla;

  Emisora(
      this.nombre,
      this.carpeta,
      this.segmentos, {
        required this.archivo,
        this.logo,
        this.semilla,
      });

  static int? _leerSemilla(Map<String, dynamic> j) {
    final v = j['semilla'];
    return v is num ? v.toInt() : null;
  }

  static List<Segmento> _parseSegmentos(Map<String, dynamic> j, String archivo) {
    Duration d(num s) => Duration(milliseconds: (s * 1000).round());
    final lista = j['segmentos'];
    if (lista is! List) return const [];
    return lista
        .whereType<Map<String, dynamic>>()
        .map((s) => Segmento(
      archivo: archivo,
      inicio: d((s['inicio'] as num?) ?? 0),
      fin: d((s['fin'] as num?) ?? 0),
      tipo: (s['tipo'] as String?) ?? 'cancion',
      titulo: (s['titulo'] as String?) ?? 'Sin título',
    ))
        .toList();
  }

  factory Emisora.desdeJson(Map<String, dynamic> j, String carpeta) {
    final archivo = '$carpeta/${j['archivo'] ?? ''}';
    final segs = _parseSegmentos(j, archivo);
    final nombreLogo = j['logo'];
    final rutaLogo = nombreLogo is String ? '$carpeta/$nombreLogo' : null;
    return Emisora(
      (j['nombre'] as String?) ?? 'Emisora',
      carpeta,
      segs,
      archivo: archivo,
      logo: rutaLogo != null && File(rutaLogo).existsSync() ? rutaLogo : null,
      semilla: _leerSemilla(j),
    );
  }

  static Future<Emisora> desdeJsonAsync(Map<String, dynamic> j, String carpeta) async {
    final archivo = '$carpeta/${j['archivo'] ?? ''}';
    final segs = _parseSegmentos(j, archivo);
    final nombreLogo = j['logo'];
    final rutaLogo = nombreLogo is String ? '$carpeta/$nombreLogo' : null;
    final tieneLogo = rutaLogo != null && await File(rutaLogo).exists();
    return Emisora(
      (j['nombre'] as String?) ?? 'Emisora',
      carpeta,
      segs,
      archivo: archivo,
      logo: tieneLogo ? rutaLogo : null,
      semilla: _leerSemilla(j),
    );
  }
}

class EntradaHistorial {
  final String emisora;
  final String carpeta;
  final String titulo;
  final String tipo;
  final int horaMs;

  /// Instante en que empezó esa emisión en la parrilla (null en entradas antiguas).
  /// Es el mismo valor para una misma emisión aunque se sintonice varias veces.
  final int? inicioMs;

  const EntradaHistorial({
    required this.emisora,
    required this.carpeta,
    required this.titulo,
    required this.tipo,
    required this.horaMs,
    this.inicioMs,
  });

  /// Misma emisora, mismo tipo y mismo título (sin distinguir mayúsculas ni espacios).
  String get clave =>
      '$carpeta|$tipo|${titulo.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ')}';

  /// ¿Es [o] la misma emisión que esta? Con inicioMs en ambas se compara exacto;
  /// si alguna es antigua y no lo tiene, se considera la misma si ocurrió a menos de un minuto.
  bool esMismaEmision(EntradaHistorial o) {
    if (clave != o.clave) return false;
    final a = inicioMs, b = o.inicioMs;
    if (a != null && b != null) return a == b;
    return (horaMs - o.horaMs).abs() < 60000;
  }

  Map<String, dynamic> toJson() => {
    'emisora': emisora,
    'carpeta': carpeta,
    'titulo': titulo,
    'tipo': tipo,
    'horaMs': horaMs,
    if (inicioMs != null) 'inicioMs': inicioMs,
  };

  factory EntradaHistorial.desdeJson(Map<String, dynamic> j) => EntradaHistorial(
    emisora: j['emisora'] ?? '',
    carpeta: j['carpeta'] ?? '',
    titulo: j['titulo'] ?? 'Sin título',
    tipo: j['tipo'] ?? 'cancion',
    horaMs: (j['horaMs'] as num?)?.toInt() ?? 0,
    inicioMs: (j['inicioMs'] as num?)?.toInt(),
  );
}

// ---------------------------------------------------------------------------
// Lista de pistas: "3:41 Título", "[1:02:10] Título", "0:00 - Título"...
// Prefijo [loc] = locutor, [ad] = anuncio, sin prefijo = canción.
// ---------------------------------------------------------------------------

final _reLinea = RegExp(r'^\s*[\[\(]?(\d+(?::\d+){1,2})[\]\)]?\s*[-–—:]?\s*(.+?)\s*$');
final _reTipo = RegExp(r'^\[(loc|ad)\]\s*(.*)$', caseSensitive: false);

double _aSegundos(String t) {
  var total = 0.0;
  for (final p in t.split(':')) {
    total = total * 60 + double.parse(p);
  }
  return total;
}

typedef JsonMap = Map<String, dynamic>;

List<JsonMap> segmentosDesdeLista(String texto, double totalSeg) {
  final marcas = <MapEntry<double, String>>[];
  for (final linea in texto.split('\n')) {
    final m = _reLinea.firstMatch(linea);
    if (m != null) marcas.add(MapEntry(_aSegundos(m.group(1)!), m.group(2)!));
  }
  marcas.sort((a, b) => a.key.compareTo(b.key));

  final List<JsonMap> segs = [];
  for (var i = 0; i < marcas.length; i++) {
    final inicio = marcas[i].key;
    final fin = i + 1 < marcas.length ? marcas[i + 1].key : totalSeg;
    if (fin <= inicio) continue;
    var titulo = marcas[i].value;
    var tipo = 'cancion';
    final t = _reTipo.firstMatch(titulo);
    if (t != null) {
      tipo = t.group(1)!.toLowerCase() == 'loc' ? 'locutor' : 'anuncio';
      titulo = t.group(2)!;
    }
    segs.add({'inicio': inicio, 'fin': fin, 'tipo': tipo, 'titulo': titulo});
  }
  return segs;
}

// ---------------------------------------------------------------------------
// Programación en vivo: cada emisora tiene una "parrilla" infinita y
// determinista dividida en bloques de 1 hora (salto O(1) al bloque actual).
// ---------------------------------------------------------------------------

const fundidoCanciones = 3000; // ms de solape entre dos canciones
const fundidoVoz = 1200; // ms de solape si interviene un locutor o anuncio

int _durMs(Segmento s) => (s.fin - s.inicio).inMilliseconds;

/// Solape (ms) entre dos pistas consecutivas. Lo usan la parrilla y el reproductor,
/// para que los horarios cuadren con lo que de verdad suena.
int calcularFade(Segmento a, Segmento b) {
  final base = (a.tipo == 'cancion' && b.tipo == 'cancion') ? fundidoCanciones : fundidoVoz;
  return max(1, min(base, min(_durMs(a), _durMs(b)) ~/ 2));
}

/// Hash estable (FNV-1a) para la semilla: String.hashCode no es estable entre ejecuciones.
int _hash(String s) {
  var h = 0x811c9dc5;
  for (final c in s.codeUnits) {
    h ^= c;
    h = (h * 0x01000193) & 0xFFFFFFFF;
  }
  return h;
}

void _barajar<T>(List<T> l, Random r) {
  for (var i = l.length - 1; i > 0; i--) {
    final j = r.nextInt(i + 1);
    final t = l[i];
    l[i] = l[j];
    l[j] = t;
  }
}

/// Instante (ms desde 1970) en el que "empieza" la emisión de todas las radios.
final int _epocaMs = DateTime.utc(2026, 1, 1).millisecondsSinceEpoch;

/// Duración fija de la ventana de cada bloque de programación (1 hora en ms).
const int _bloqueMs = 60 * 60 * 1000;

class Posicion {
  final int bloque;
  final int indice;
  final Segmento seg;
  final int inicioMs; // instante absoluto en que empieza esta pista
  const Posicion(this.bloque, this.indice, this.seg, this.inicioMs);
}

class Programacion {
  final Emisora emisora;
  final int _semilla;
  final Map<int, List<Segmento>> _bloques = {};
  Posicion? _cache;

  Programacion(this.emisora) : _semilla = emisora.semilla ?? _hash(emisora.nombre);

  int _inicioBloqueMs(int b) => _epocaMs + b * _bloqueMs;

  /// Un bloque cubre al menos 1 h efectiva (descontando solapes): 2-3 canciones,
  /// luego un locutor/anuncio, sin repetir canción hasta agotarlas todas.
  List<Segmento> _generarBloque(int b) {
    final rng = Random((_semilla * 31 + b * 7919 + 17) & 0x7FFFFFFF);
    final canciones = emisora.segmentos.where((s) => s.tipo == 'cancion').toList();
    final voces = emisora.segmentos.where((s) => s.tipo != 'cancion').toList();
    final base = canciones.isEmpty ? voces : canciones;

    final lista = <Segmento>[];
    var ronda = <Segmento>[];
    var totalEfectivo = 0;
    var seguidas = 0;
    var objetivo = 2 + rng.nextInt(2);
    Segmento? ultimaVoz;

    while ((totalEfectivo < _bloqueMs || lista.isEmpty) && lista.length < 500) {
      Segmento s;
      if (voces.isNotEmpty && canciones.isNotEmpty && seguidas >= objetivo) {
        final candidatas =
        voces.length > 1 ? voces.where((v) => v != ultimaVoz).toList() : voces;
        s = candidatas[rng.nextInt(candidatas.length)];
        ultimaVoz = s;
        seguidas = 0;
        objetivo = 2 + rng.nextInt(2);
      } else {
        if (ronda.isEmpty) {
          ronda = [...base];
          _barajar(ronda, rng);
        }
        s = ronda.removeLast();
        seguidas++;
      }
      final solape = lista.isEmpty ? 0 : calcularFade(lista.last, s);
      lista.add(s);
      totalEfectivo += max(1, _durMs(s) - solape);
    }
    return lista;
  }

  List<Segmento> _bloque(int b) {
    final existente = _bloques[b];
    if (existente != null) return existente;
    if (_bloques.length > 6) _bloques.clear();
    return _bloques[b] = _generarBloque(b);
  }

  /// La pista que viene después de [p]; empieza cuando la anterior acaba menos el solape.
  Posicion siguiente(Posicion p) {
    final actual = _bloque(p.bloque);
    final hayMas = p.indice + 1 < actual.length;
    final b = hayMas ? p.bloque : p.bloque + 1;
    final i = hayMas ? p.indice + 1 : 0;
    final s = _bloque(b)[i];
    final inicio = p.inicioMs + _durMs(p.seg) - calcularFade(p.seg, s);
    return Posicion(b, i, s, inicio);
  }

  /// Qué pista está en el aire en el instante [ahoraMs].
  /// Salta directamente al bloque horario correspondiente en O(1).
  Posicion en(int ahoraMs) {
    final b = ahoraMs <= _epocaMs ? 0 : (ahoraMs - _epocaMs) ~/ _bloqueMs;
    Posicion p = (_cache != null && _cache!.bloque == b && _cache!.inicioMs <= ahoraMs)
        ? _cache!
        : Posicion(b, 0, _bloque(b)[0], _inicioBloqueMs(b));
    while (true) {
      final n = siguiente(p);
      if (n.inicioMs > ahoraMs || n.bloque != b) break;
      p = n;
    }
    _cache = p;
    return p;
  }
}

// ---------------------------------------------------------------------------
// Reproductor: un único archivo largo, se reproduce solo el tramo del segmento
// ---------------------------------------------------------------------------

class Reproductor extends BaseAudioHandler {
  final actual = ValueNotifier<Segmento?>(null);
  final emisoraActual = ValueNotifier<Emisora?>(null);
  final sonando = ValueNotifier<bool>(false);
  final historial = ValueNotifier<List<EntradaHistorial>>(const []);

  static const _maxHistorial = 50;

  /// Si se pausa más de este tiempo, al reanudar vuelve al punto "en directo".
  static const _maxPausa = Duration(seconds: 5);

  // ---- Ecualizador (Android only) ----
  final AndroidEqualizer _eqA = AndroidEqualizer();
  final AndroidEqualizer _eqB = AndroidEqualizer();
  final eqActivo = ValueNotifier<bool>(false);
  AndroidEqualizerParameters? _eqParams;
  bool get eqDisponible => !Platform.isAndroid ? false : true;

  Future<void> inicializarEq() async {
    if (!Platform.isAndroid) return;
    // Cargar preferencias de EQ guardadas
    try {
      final f = await _archivoPreferencias();
      if (await f.exists()) {
        final data = jsonDecode(await f.readAsString());
        if (data is Map<String, dynamic>) {
          if (data['eq_activo'] == true) {
            await _eqA.setEnabled(true);
            await _eqB.setEnabled(true);
            eqActivo.value = true;
          }
        }
      }
    } catch (_) {}
  }

  Future<AndroidEqualizerParameters?> obtenerParametrosEq() async {
    if (!Platform.isAndroid) return null;
    _eqParams ??= await _eqA.parameters;
    return _eqParams;
  }

  Future<void> setEqActivo(bool activo) async {
    eqActivo.value = activo;
    await _eqA.setEnabled(activo);
    await _eqB.setEnabled(activo);
    await _guardarPrefsEq();
  }

  Future<void> setEqBanda(int index, double gain) async {
    final paramsA = await _eqA.parameters;
    final paramsB = await _eqB.parameters;
    if (index < paramsA.bands.length) {
      await paramsA.bands[index].setGain(gain);
    }
    if (index < paramsB.bands.length) {
      await paramsB.bands[index].setGain(gain);
    }
    await _guardarPrefsEq();
  }

  Future<void> resetEq() async {
    final params = await _eqA.parameters;
    final paramsB = await _eqB.parameters;
    for (final b in params.bands) {
      await b.setGain(0);
    }
    for (final b in paramsB.bands) {
      await b.setGain(0);
    }
    await _guardarPrefsEq();
  }

  Future<void> _guardarPrefsEq() async {
    try {
      final f = await _archivoPreferencias();
      Map<String, dynamic> data = {};
      if (await f.exists()) {
        final decoded = jsonDecode(await f.readAsString());
        if (decoded is Map<String, dynamic>) data = decoded;
      }
      data['eq_activo'] = eqActivo.value;
      final params = await _eqA.parameters;
      data['eq_bandas'] = [
        for (final b in params.bands) b.gain,
      ];
      await f.writeAsString(jsonEncode(data));
    } catch (_) {}
  }

  Future<void> _restaurarBandasEq() async {
    if (!Platform.isAndroid) return;
    try {
      final f = await _archivoPreferencias();
      if (!await f.exists()) return;
      final data = jsonDecode(await f.readAsString());
      if (data is! Map<String, dynamic>) return;
      final bandas = data['eq_bandas'];
      if (bandas is! List) return;
      final paramsA = await _eqA.parameters;
      final paramsB = await _eqB.parameters;
      for (var i = 0; i < bandas.length && i < paramsA.bands.length; i++) {
        final g = (bandas[i] as num).toDouble();
        await paramsA.bands[i].setGain(g);
        if (i < paramsB.bands.length) {
          await paramsB.bands[i].setGain(g);
        }
      }
    } catch (_) {}
  }

  // Dos reproductores: mientras uno termina, el otro empieza y se mezclan.
  // El audio session lo gestionamos nosotros (ver iniciarSesion).
  late final AudioPlayer _a = AudioPlayer(
    handleInterruptions: false,
    handleAudioSessionActivation: false,
    audioPipeline: AudioPipeline(androidAudioEffects: [_eqA]),
  );
  late final AudioPlayer _b = AudioPlayer(
    handleInterruptions: false,
    handleAudioSessionActivation: false,
    audioPipeline: AudioPipeline(androidAudioEffects: [_eqB]),
  );
  late AudioPlayer _cur = _a; // el que suena
  late AudioPlayer _sig = _b; // el que tiene la siguiente pista preparada

  final Map<String, Programacion> _programaciones = {};
  Programacion? _prog;
  Emisora? _emisora;
  Posicion? _posCur;
  Posicion? _posSig;
  bool _sigListo = false;
  bool _fundiendo = false;
  int _fadeMs = fundidoCanciones;
  int _gen = 0; // invalida preparaciones pendientes al cambiar de emisora
  DateTime? _pausadoEn;
  Timer? _timer;
  AudioSession? _sesion;

  Future<void> iniciarSesion() async {
    final s = await AudioSession.instance;
    await s.configure(const AudioSessionConfiguration.music());
    _sesion = s;
    s.interruptionEventStream.listen((e) {
      if (e.begin) pause();
    });
    s.becomingNoisyEventStream.listen((_) => pause());
  }

  // ----- API que usa la interfaz -----

  /// Devuelve el segmento que suena (o estaría sonando en vivo en [e]),
  /// reutilizando la instancia cacheada de [Programacion].
  Segmento? segmentoEnVivo(Emisora e) {
    if (e.segmentos.isEmpty) return null;
    final activa = emisoraActual.value;
    final segActual = actual.value;
    if (activa != null && activa.carpeta == e.carpeta && segActual != null) {
      return segActual;
    }
    final prog = _programaciones.putIfAbsent(e.carpeta, () => Programacion(e));
    return prog.en(DateTime.now().millisecondsSinceEpoch).seg;
  }

  /// Sintoniza la emisora "en directo": entra en la pista y el punto exacto
  /// que estaría sonando ahora mismo según la hora.
  Future<void> sintonizar(Emisora e) async {
    if (e.segmentos.isEmpty) return;
    await _parar();
    final gen = _gen;
    final prog = _programaciones.putIfAbsent(e.carpeta, () => Programacion(e));
    _prog = prog;
    _emisora = e;
    emisoraActual.value = e;

    final ahora = DateTime.now().millisecondsSinceEpoch;
    final pos = prog.en(ahora);
    final tope = max(0, _durMs(pos.seg) - 500);
    final offset = (ahora - pos.inicioMs).clamp(0, tope).toInt();

    await _sesion?.setActive(true);
    await _cargar(_cur, pos.seg, Duration(milliseconds: offset));
    if (gen != _gen) return;
    await _cur.setVolume(1);
    _posCur = pos;
    _pausadoEn = null;
    _publicar(pos.seg, pos.inicioMs);
    sonando.value = true;
    _estado();
    _cur.play(); // sin await: el Future termina cuando se pausa o acaba
    _iniciarTimer();
    _prepararSiguiente();
  }

  Future<void> detener() async {
    await _parar();
    _pausadoEn = null;
    actual.value = null;
    emisoraActual.value = null;
    sonando.value = false;
    mediaItem.add(null);
    playbackState.add(PlaybackState(
      processingState: AudioProcessingState.idle,
      playing: false,
    ));
    await _sesion?.setActive(false);
  }

  /// Hay que llamarlo cuando una emisora se edita o se borra: descarta su parrilla
  /// guardada y, si estaba sonando, la detiene.
  Future<void> olvidar(String carpeta) async {
    _programaciones.remove(carpeta);
    if (_emisora?.carpeta == carpeta) await detener();
  }

  Future<File> _archivoHistorial() async {
    final base = await getApplicationDocumentsDirectory();
    return File('${base.path}/historial_radio.json');
  }

  Future<void> cargarHistorial() async {
    try {
      final f = await _archivoHistorial();
      if (!await f.exists()) return;
      final datos = jsonDecode(await f.readAsString());
      if (datos is! List) return;
      // De más reciente a más antiguo. Se descartan las entradas que son la misma
      // emisión que la anterior de su emisora (duplicados que ya estaban guardados);
      // repeticiones reales de una canción (otra emisión) se respetan.
      final ultimaPorEmisora = <String, EntradaHistorial>{};
      final limpia = <EntradaHistorial>[];
      for (final item in datos) {
        if (item is! JsonMap) continue;
        final h = EntradaHistorial.desdeJson(item);
        final previa = ultimaPorEmisora[h.carpeta];
        if (previa != null && previa.esMismaEmision(h)) continue;
        ultimaPorEmisora[h.carpeta] = h;
        limpia.add(h);
      }
      historial.value = limpia.take(_maxHistorial).toList();
    } catch (_) {
      // Si el fichero está corrupto, arrancamos con historial vacío.
    }
  }

  Future<void> _guardarHistorial() async {
    try {
      final f = await _archivoHistorial();
      await f.writeAsString(jsonEncode([
        for (final h in historial.value) h.toJson(),
      ]));
    } catch (_) {}
  }

  Future<void> limpiarHistorial([String? carpeta]) async {
    if (carpeta == null) {
      historial.value = const [];
    } else {
      historial.value =
          historial.value.where((h) => h.carpeta != carpeta).toList();
    }
    await _guardarHistorial();
  }

  void _anotarHistorial(Segmento s, int inicioMs) {
    final e = _emisora;
    if (e == null) return;
    final lista = historial.value;
    final nueva = EntradaHistorial(
      emisora: e.nombre,
      carpeta: e.carpeta,
      titulo: s.titulo,
      tipo: s.tipo,
      horaMs: DateTime.now().millisecondsSinceEpoch,
      inicioMs: inicioMs,
    );
    // El historial mezcla todas las emisoras: si has cambiado de radio y vuelves,
    // lo último anotado de ESTA emisora no es lo primero de la lista. Si es la
    // misma emisión (misma pista en el mismo momento de la parrilla), no se repite.
    for (final h in lista) {
      if (h.carpeta != e.carpeta) continue;
      if (h.esMismaEmision(nueva)) return;
      break; // la última de esta emisora es otra pista: se anota la nueva
    }
    historial.value = [nueva, ...lista].take(_maxHistorial).toList();
    unawaited(_guardarHistorial());
  }

  /// Duración total de un archivo (con un reproductor temporal).
  Future<Duration?> medirDuracion(String ruta) async {
    final p = AudioPlayer(
      handleInterruptions: false,
      handleAudioSessionActivation: false,
    );
    try {
      return await p.setFilePath(ruta);
    } finally {
      await p.dispose();
    }
  }

  // ----- Información para la pantalla de reproducción -----

  /// Posición dentro de la pista que suena (0 = principio de su tramo).
  Duration get posicionPista => _cur.position;

  /// Las próximas [n] pistas de la parrilla, tal y como van a sonar.
  List<Posicion> proximas(int n) {
    final prog = _prog;
    final cur = _posCur;
    if (prog == null || cur == null) return const [];
    final lista = <Posicion>[];
    Posicion p = cur;
    for (var i = 0; i < n; i++) {
      p = prog.siguiente(p);
      lista.add(p);
    }
    return lista;
  }

  // ----- Controles del sistema (notificación, auriculares...) -----

  @override
  Future<void> play() async {
    final e = _emisora;
    if (_prog == null || e == null) return;
    final desde = _pausadoEn;
    _pausadoEn = null;
    // Como una radio de verdad: si estuvo pausada un rato, vuelve al directo.
    if (desde != null && DateTime.now().difference(desde) > _maxPausa) {
      await sintonizar(e);
      return;
    }
    await _sesion?.setActive(true);
    sonando.value = true;
    _cur.play();
    if (_fundiendo) _sig.play();
    _iniciarTimer();
    _estado();
  }

  @override
  Future<void> pause() async {
    _pausadoEn ??= DateTime.now();
    sonando.value = false;
    _pararTimer();
    await _cur.pause();
    if (_fundiendo) await _sig.pause();
    _estado();
  }

  @override
  Future<void> stop() => detener();

  // ----- Motor interno -----

  void _iniciarTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(milliseconds: 50), (_) => _tick());
  }

  void _pararTimer() {
    _timer?.cancel();
    _timer = null;
  }

  Future<void> _parar() async {
    _gen++;
    _pararTimer();
    _fundiendo = false;
    _sigListo = false;
    _prog = null;
    _posCur = null;
    _posSig = null;
    await _a.stop();
    await _b.stop();
  }

  Future<void> _cargar(AudioPlayer p, Segmento s,
      [Duration inicial = Duration.zero]) async {
    await p.setAudioSource(
      ClippingAudioSource(
        child: AudioSource.file(s.archivo),
        start: s.inicio,
        end: s.fin,
      ),
      initialPosition: inicial,
    );
  }

  /// Deja la siguiente pista de la parrilla cargada (en pausa, volumen 0) en el reproductor libre.
  Future<void> _prepararSiguiente() async {
    final gen = _gen;
    _sigListo = false;
    final prog = _prog;
    final cur = _posCur;
    if (prog == null || cur == null) return;
    var pos = prog.siguiente(cur);
    for (var intento = 0; intento < 3; intento++) {
      final p = _sig;
      try {
        await p.setVolume(0);
        await _cargar(p, pos.seg);
      } catch (_) {
        if (gen != _gen) return;
        pos = prog.siguiente(pos); // archivo ilegible: se prueba con la siguiente
        continue;
      }
      if (gen != _gen) return;
      _posSig = pos;
      _fadeMs = calcularFade(cur.seg, pos.seg);
      _sigListo = true;
      return;
    }
  }

  void _empezarFundido() {
    if (_fundiendo || !_sigListo) return;
    _fundiendo = true;
    _sigListo = false;
    _sig.setVolume(0);
    _sig.play();
  }

  void _terminarFundido() {
    if (!_fundiendo) return;
    _fundiendo = false;
    final vieja = _cur;
    _cur = _sig;
    _sig = vieja;
    _posCur = _posSig;
    _cur.setVolume(1);
    vieja.pause();
    vieja.setVolume(0);
    final pc = _posCur;
    if (pc != null) _publicar(pc.seg, pc.inicioMs);
    _prepararSiguiente();
  }

  void _tick() {
    final cur = _posCur?.seg;
    if (cur == null) return;

    if (_fundiendo) {
      // Mezcla de potencia constante; el progreso lo marca la posición de la nueva pista.
      final t = (_sig.position.inMilliseconds / _fadeMs).clamp(0.0, 1.0).toDouble();
      unawaited(_cur.setVolume(cos(t * pi / 2)));
      unawaited(_sig.setVolume(sin(t * pi / 2)));
      if (t >= 1.0 || _cur.processingState == ProcessingState.completed) {
        _terminarFundido();
      }
      return;
    }

    if (!_sigListo) return;
    if (_cur.processingState == ProcessingState.completed) {
      _fadeMs = 1; // la pista acabó antes de lo previsto: salto directo
      _empezarFundido();
      return;
    }
    if (!_cur.playing) return;
    final restante = _durMs(cur) - _cur.position.inMilliseconds;
    if (restante <= _fadeMs) _empezarFundido();
  }

  void _publicar(Segmento s, int inicioMs) {
    actual.value = s;
    _anotarHistorial(s, inicioMs);
    final logo = _emisora?.logo;
    mediaItem.add(MediaItem(
      id: '${s.archivo}#${s.inicio.inMilliseconds}',
      title: s.titulo,
      album: _emisora?.nombre,
      artUri: logo == null ? null : Uri.file(logo),
    ));
  }

  void _estado() {
    final reproduciendo = sonando.value;
    playbackState.add(PlaybackState(
      controls: [reproduciendo ? MediaControl.pause : MediaControl.play],
      androidCompactActionIndices: const [0],
      processingState:
      _prog == null ? AudioProcessingState.idle : AudioProcessingState.ready,
      playing: reproduciendo,
    ));
  }
}

// ---------------------------------------------------------------------------
// UI
// ---------------------------------------------------------------------------

class RadioApp extends StatelessWidget {
  const RadioApp({super.key});

  @override
  Widget build(BuildContext context) => ValueListenableBuilder<String>(
    valueListenable: idiomaApp,
    builder: (_, lang, __) => MaterialApp(
      locale: Locale(lang),
      title: _t('app_title'),
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: Colors.pink,
        brightness: Brightness.dark,
        useMaterial3: true,
      ),
      home: const PantallaInicioGTA(),
    ),
  );
}

class _BotonIdioma extends StatelessWidget {
  final Color? color;
  final double? tam;
  const _BotonIdioma({this.color, this.tam});

  Future<void> _abrirMenu(BuildContext context) async {
    final actual = idiomaApp.value;
    final elegido = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: const Color(0xFF101016),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        side: BorderSide(color: Colors.white12),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 38,
                height: 4,
                margin: const EdgeInsets.only(bottom: 14),
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Text(
                _t('language_tooltip').toUpperCase(),
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.4,
                ),
              ),
              const SizedBox(height: 12),
              _OpcionIdiomaGTA(
                codigo: 'ES',
                titulo: 'ESPAÑOL',
                subtitulo: _t('lang_es'),
                activo: actual == 'es',
                onTap: () => Navigator.pop(ctx, 'es'),
              ),
              const SizedBox(height: 10),
              _OpcionIdiomaGTA(
                codigo: 'EN',
                titulo: 'ENGLISH',
                subtitulo: _t('lang_en'),
                activo: actual == 'en',
                onTap: () => Navigator.pop(ctx, 'en'),
              ),
            ],
          ),
        ),
      ),
    );
    if (elegido != null && elegido != actual) {
      await cambiarIdiomaApp(elegido);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: idiomaApp,
      builder: (context, lang, _) => Tooltip(
        message: _t('language_tooltip'),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: () => _abrirMenu(context),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.42),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white24),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.language,
                    color: color ?? Colors.white,
                    size: (tam ?? 20) * 0.8,
                  ),
                  const SizedBox(width: 5),
                  Text(
                    lang.toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 11.5,
                      letterSpacing: 1.0,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _OpcionIdiomaGTA extends StatelessWidget {
  final String codigo;
  final String titulo;
  final String subtitulo;
  final bool activo;
  final VoidCallback onTap;

  const _OpcionIdiomaGTA({
    required this.codigo,
    required this.titulo,
    required this.subtitulo,
    required this.activo,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: activo ? 0.11 : 0.05),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: activo ? Colors.white38 : Colors.white12,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: activo ? Colors.white : Colors.white.withValues(alpha: 0.14),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  codigo,
                  style: TextStyle(
                    color: activo ? Colors.black : Colors.white,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.6,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      titulo,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 13.5,
                        letterSpacing: 0.9,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitulo,
                      style: const TextStyle(
                        color: Colors.white60,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                activo ? Icons.check_circle : Icons.chevron_right,
                color: activo ? Colors.white : Colors.white54,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
Future<bool> _ejecutarConEspera(
    BuildContext context,
    String texto,
    Future<void> Function() tarea,
    ) async {
  showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (_) => PopScope(
      canPop: false,
      child: AlertDialog(
        backgroundColor: const Color(0xFF101016),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: const BorderSide(color: Colors.white12),
        ),
        content: Row(children: [
          const CircularProgressIndicator(color: Colors.white),
          const SizedBox(width: 20),
          Expanded(
            child: Text(
              texto,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ]),
      ),
    ),
  );
  try {
    await tarea();
    return true;
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_t('error_prefix', {'err': '$e'}))),
      );
    }
    return false;
  } finally {
    if (context.mounted) Navigator.of(context, rootNavigator: true).pop();
  }
}

Future<bool> _importarPaqueteConDialogo(BuildContext context) async {
  final f = await FilePicker.pickFile();
  final ruta = f?.path;
  if (f == null || ruta == null || !context.mounted) return false;
  final base = await carpetaRadios();
  if (!context.mounted) return false;
  final ok = await _ejecutarConEspera(
    context,
    _t('importing_radio'),
        () async {
      await importarRadio(paquete: File(ruta), base: base);
      try {
        await File(ruta).delete();
      } catch (_) {}
    },
  );
  if (ok && context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(_t('radio_imported'))),
    );
  }
  return ok;
}

// ---------------------------------------------------------------------------
// Helpers visuales estilo GTA para formularios y diálogos
// ---------------------------------------------------------------------------

class _FondoAtmosfericoGTA extends StatelessWidget {
  final Color color;
  final String? logoRuta;
  final Widget child;

  const _FondoAtmosfericoGTA({
    required this.color,
    this.logoRuta,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: const Alignment(0, -0.35),
              radius: 1.2,
              colors: [
                color.withValues(alpha: 0.34),
                const Color(0xFF0B0B10),
                Colors.black,
              ],
            ),
          ),
        ),
        if (logoRuta != null)
          Opacity(
            opacity: 0.14,
            child: Image.file(
              File(logoRuta!),
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => const SizedBox.shrink(),
            ),
          ),
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withValues(alpha: 0.65),
                Colors.black.withValues(alpha: 0.45),
                Colors.black.withValues(alpha: 0.90),
              ],
            ),
          ),
        ),
        child,
      ],
    );
  }
}

InputDecoration _inputDecorationGTA({
  required String label,
  String? hint,
  String? helper,
  Color? acento,
}) {
  return InputDecoration(
    labelText: label.toUpperCase(),
    hintText: hint,
    helperText: helper,
    helperMaxLines: 2,
    filled: true,
    fillColor: Colors.white.withValues(alpha: 0.06),
    labelStyle: const TextStyle(
      color: Colors.white70,
      fontSize: 12,
      fontWeight: FontWeight.w800,
      letterSpacing: 1.0,
    ),
    floatingLabelStyle: TextStyle(
      color: acento ?? Colors.white,
      fontSize: 12,
      fontWeight: FontWeight.w900,
      letterSpacing: 1.1,
    ),
    hintStyle: const TextStyle(color: Colors.white30),
    helperStyle: const TextStyle(color: Colors.white54, fontSize: 11.5),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: Colors.white24),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: acento ?? Colors.white, width: 1.6),
    ),
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
  );
}

class _BotonSelectorGTA extends StatelessWidget {
  final IconData icono;
  final String titulo;
  final String? subtitulo;
  final bool seleccionado;
  final Color? acento;
  final Widget? leadingCustom;
  final VoidCallback onTap;
  final VoidCallback? onLimpiar;

  const _BotonSelectorGTA({
    required this.icono,
    required this.titulo,
    required this.onTap,
    this.subtitulo,
    this.seleccionado = false,
    this.acento,
    this.leadingCustom,
    this.onLimpiar,
  });

  @override
  Widget build(BuildContext context) {
    final borde = seleccionado
        ? (acento?.withValues(alpha: 0.65) ?? Colors.white38)
        : Colors.white12;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: seleccionado ? 0.09 : 0.055),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: borde),
          ),
          child: Row(
            children: [
              leadingCustom ??
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: seleccionado
                          ? Colors.white
                          : Colors.white.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Icon(
                      icono,
                      size: 18,
                      color: seleccionado ? Colors.black : Colors.white,
                    ),
                  ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      titulo.toUpperCase(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 12.5,
                        letterSpacing: 0.9,
                      ),
                    ),
                    if (subtitulo != null && subtitulo!.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitulo!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white60,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (onLimpiar != null)
                IconButton(
                  tooltip: _t('remove_logo'),
                  visualDensity: VisualDensity.compact,
                  icon: const Icon(Icons.close, color: Colors.white70, size: 20),
                  onPressed: onLimpiar,
                )
              else
                Icon(
                  seleccionado ? Icons.check_circle : Icons.chevron_right,
                  color: seleccionado ? Colors.white : Colors.white54,
                  size: 20,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CaratulaPreviewGTA extends StatelessWidget {
  final String? logoRuta;
  final String nombre;
  final double tam;

  const _CaratulaPreviewGTA({
    required this.logoRuta,
    required this.nombre,
    this.tam = 92,
  });

  @override
  Widget build(BuildContext context) {
    final titulo = nombre.trim().isEmpty ? 'GTA RADIO' : nombre.trim();
    final color = _colorEmisora(titulo);
    return Container(
      width: tam,
      height: tam,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.white, width: 2.5),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.45),
            blurRadius: 18,
            spreadRadius: 1,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(3.5),
        child: logoRuta != null
            ? Image.file(
          File(logoRuta!),
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _CaratulaFallbackGTA(nombre: titulo),
        )
            : _CaratulaFallbackGTA(nombre: titulo),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Importar una radio: elegir archivo + pegar la lista de pistas
// ---------------------------------------------------------------------------

class PantallaImportar extends StatefulWidget {
  final Reproductor repro;
  const PantallaImportar({super.key, required this.repro});

  @override
  State<PantallaImportar> createState() => _PantallaImportarState();
}

class _PantallaImportarState extends State<PantallaImportar> {
  final _nombre = TextEditingController();
  final _pistas = TextEditingController();
  File? _archivo;
  String _nombreArchivo = '';
  File? _logo;
  bool _trabajando = false;

  @override
  void dispose() {
    _nombre.dispose();
    _pistas.dispose();
    super.dispose();
  }

  void _aviso(String texto) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(texto)));
  }

  Future<void> _elegirArchivo() async {
    setState(() => _trabajando = true);
    try {
      // En Android el selector copia el archivo a la caché de la app:
      // con vídeos largos puede tardar un rato.
      final f = await FilePicker.pickFile();
      final ruta = f?.path;
      if (f != null && ruta != null) {
        setState(() {
          _archivo = File(ruta);
          _nombreArchivo = f.name;
        });
      }
    } finally {
      if (mounted) setState(() => _trabajando = false);
    }
  }

  Future<void> _elegirLogo() async {
    final f = await elegirImagen(context);
    if (f != null && mounted) setState(() => _logo = f);
  }

  Future<void> _importar() async {
    final nombre = _nombre.text.trim();
    if (nombre.isEmpty || _archivo == null || _pistas.text.trim().isEmpty) {
      _aviso(_t('missing_import_fields'));
      return;
    }
    setState(() => _trabajando = true);

    final base = await carpetaRadios();
    var seguro = nombre.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_').trim();
    if (seguro.isEmpty) seguro = 'emisora';
    var carpeta = Directory('${base.path}/$seguro');
    if (await carpeta.exists()) {
      carpeta = Directory('${base.path}/${seguro}_${DateTime.now().millisecondsSinceEpoch}');
    }

    try {
      await carpeta.create(recursive: true);
      final ext = _archivo!.path.contains('.') ? _archivo!.path.split('.').last : 'mp4';
      final destino = '${carpeta.path}/audio.$ext';

      // La caché y esta carpeta están en la misma partición: rename es instantáneo.
      try {
        await _archivo!.rename(destino);
      } catch (_) {
        await _archivo!.copy(destino);
        await _archivo!.delete();
      }

      final dur = await widget.repro.medirDuracion(destino);
      if (dur == null) throw _t('cannot_read_duration');

      final segs = segmentosDesdeLista(_pistas.text, dur.inMilliseconds / 1000);
      if (segs.isEmpty) throw _t('no_timestamps');

      final nombreLogo =
      _logo == null ? null : await guardarLogo(_logo!, carpeta.path);

      await File('${carpeta.path}/radio.json').writeAsString(jsonEncode({
        'nombre': nombre,
        'archivo': 'audio.$ext',
        if (nombreLogo != null) 'logo': nombreLogo,
        'segmentos': segs,
      }));

      if (mounted) Navigator.pop(context, carpeta.path);
    } catch (e) {
      if (await carpeta.exists()) await carpeta.delete(recursive: true);
      if (mounted) _aviso(_t('error_prefix', {'err': '$e'}));
    } finally {
      if (mounted) setState(() => _trabajando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final nombreVista = _nombre.text.trim();
    final color = nombreVista.isEmpty
        ? const Color(0xFFFF2E93)
        : _colorEmisora(nombreVista);

    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(
          _t('new_station').toUpperCase(),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.3,
          ),
        ),
      ),
      body: _FondoAtmosfericoGTA(
        color: color,
        logoRuta: _logo?.path,
        child: SafeArea(
          child: AbsorbPointer(
            absorbing: _trabajando,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
              children: [
                Center(
                  child: GestureDetector(
                    onTap: _elegirLogo,
                    child: _CaratulaPreviewGTA(
                      logoRuta: _logo?.path,
                      nombre: nombreVista,
                      tam: 104,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: _nombre,
                  onChanged: (_) => setState(() {}),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                  ),
                  cursorColor: Colors.white,
                  decoration: _inputDecorationGTA(
                    label: _t('station_name_label'),
                    acento: color,
                  ),
                ),
                const SizedBox(height: 14),
                _BotonSelectorGTA(
                  icono: Icons.video_file_outlined,
                  titulo: _t('pick_media'),
                  subtitulo: _archivo == null ? null : _nombreArchivo,
                  seleccionado: _archivo != null,
                  acento: color,
                  onTap: _elegirArchivo,
                ),
                const SizedBox(height: 12),
                _BotonSelectorGTA(
                  icono: Icons.image_outlined,
                  titulo: _logo == null ? _t('pick_logo') : _t('change_logo'),
                  seleccionado: _logo != null,
                  acento: color,
                  leadingCustom: _logo == null
                      ? null
                      : _LogoMini(ruta: _logo!.path, nombre: _nombre.text, tam: 36),
                  onTap: _elegirLogo,
                  onLimpiar: _logo == null ? null : () => setState(() => _logo = null),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _pistas,
                  minLines: 7,
                  maxLines: 13,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13.5,
                    height: 1.35,
                    fontFeatures: [FontFeature.tabularFigures()],
                  ),
                  cursorColor: Colors.white,
                  decoration: _inputDecorationGTA(
                    label: _t('tracklist_label'),
                    hint: _t('tracklist_hint'),
                    helper: _t('tracklist_helper'),
                    acento: color,
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  height: 48,
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                    ),
                    onPressed: _importar,
                    icon: const Icon(Icons.check, size: 20),
                    label: Text(
                      _t('import_btn').toUpperCase(),
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 13,
                        letterSpacing: 1.3,
                      ),
                    ),
                  ),
                ),
                if (_trabajando) ...[
                  const SizedBox(height: 18),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.white12),
                    ),
                    child: Row(
                      children: [
                        const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.5,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Text(
                            _t('working_long_file'),
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Editor de pistas
// ---------------------------------------------------------------------------

String _fmt(Duration d) {
  final h = d.inHours;
  final m = d.inMinutes % 60;
  final sg = (d.inSeconds % 60).toString().padLeft(2, '0');
  final ms = d.inMilliseconds % 1000;
  final frac =
  ms == 0 ? '' : '.${ms.toString().padLeft(3, '0').replaceFirst(RegExp(r'0+$'), '')}';
  return h > 0 ? '$h:${m.toString().padLeft(2, '0')}:$sg$frac' : '${d.inMinutes}:$sg$frac';
}

/// Acepta "3:41", "1:02:10", "3:41.5" o segundos sueltos ("221").
Duration? _parseTiempo(String t) {
  final txt = t.trim().replaceAll(',', '.');
  if (txt.isEmpty) return null;
  try {
    return Duration(milliseconds: (_aSegundos(txt) * 1000).round());
  } catch (_) {
    return null;
  }
}

IconData _iconoTipo(String t) =>
    t == 'cancion' ? Icons.music_note : (t == 'locutor' ? Icons.mic : Icons.campaign);

class PantallaEditar extends StatefulWidget {
  final Emisora emisora;
  const PantallaEditar({super.key, required this.emisora});

  @override
  State<PantallaEditar> createState() => _PantallaEditarState();
}

class _PantallaEditarState extends State<PantallaEditar> {
  late final List<Segmento> _segs = [...widget.emisora.segmentos];
  late final TextEditingController _nombre =
  TextEditingController(text: widget.emisora.nombre);
  late final String _archivo = widget.emisora.archivo;
  final AudioPlayer _previa = AudioPlayer();
  Duration? _total;
  bool _cambios = false;
  late String? _logoVista = widget.emisora.logo; // lo que se ve ahora
  File? _logoNuevo; // imagen elegida, aún sin copiar a la carpeta
  bool _logoCambiado = false;

  @override
  void initState() {
    super.initState();
    _medir();
  }

  @override
  void dispose() {
    _previa.dispose();
    _nombre.dispose();
    super.dispose();
  }

  Future<void> _medir() async {
    final d = await radio.medirDuracion(_archivo);
    if (mounted) setState(() => _total = d);
  }

  void _aviso(String texto) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(texto)));
  }

  Future<void> _cambiarLogo() async {
    final f = await elegirImagen(context);
    if (f == null || !mounted) return;
    setState(() {
      _logoVista = f.path;
      _logoNuevo = f;
      _logoCambiado = true;
      _cambios = true;
    });
  }

  void _quitarLogo() => setState(() {
    _logoVista = null;
    _logoNuevo = null;
    _logoCambiado = true;
    _cambios = true;
  });

  void _ordenar() => _segs.sort((a, b) => a.inicio.compareTo(b.inicio));

  /// Preescucha de un tramo, para comprobar dónde empieza o acaba una pista.
  Future<void> _escuchar(Duration desde, Duration hasta) async {
    try {
      if (radio.sonando.value) await radio.pause();
      await _previa.setAudioSource(
        ClippingAudioSource(child: AudioSource.file(_archivo), start: desde, end: hasta),
      );
      _previa.play();
    } catch (_) {
      if (mounted) _aviso(_t('cannot_play_clip'));
    }
  }

  Future<void> _pararPrevia() => _previa.stop();

  Future<Segmento?> _abrirDialogo(Segmento? s) => showDialog<Segmento>(
    context: context,
    barrierDismissible: false,
    builder: (_) => _DialogoPista(
      inicial: s,
      archivo: _archivo,
      total: _total,
      escuchar: _escuchar,
      parar: _pararPrevia,
    ),
  );

  Future<void> _editarPista(int i) async {
    final r = await _abrirDialogo(_segs[i]);
    if (r == null) return;
    setState(() {
      _segs[i] = r;
      _ordenar();
      _cambios = true;
    });
  }

  Future<void> _anadir() async {
    final r = await _abrirDialogo(null);
    if (r == null) return;
    setState(() {
      _segs.add(r);
      _ordenar();
      _cambios = true;
    });
  }

  void _borrarPista(int i) {
    final borrada = _segs[i];
    setState(() {
      _segs.removeAt(i);
      _cambios = true;
    });
    final m = ScaffoldMessenger.of(context);
    m.clearSnackBars();
    m.showSnackBar(SnackBar(
      content: Text(_t('track_deleted')),
      action: SnackBarAction(
        label: _t('undo'),
        onPressed: () => setState(() {
          _segs.add(borrada);
          _ordenar();
        }),
      ),
    ));
  }

  Future<void> _guardar() async {
    final nombre = _nombre.text.trim();
    if (nombre.isEmpty) {
      _aviso(_t('set_station_name'));
      return;
    }
    if (_segs.isEmpty) {
      _aviso(_t('need_one_track'));
      return;
    }
    try {
      final f = File('${widget.emisora.carpeta}/radio.json');
      final datos = jsonDecode(await f.readAsString()) as Map<String, dynamic>;
      datos['nombre'] = nombre;
      datos['segmentos'] = [
        for (final s in _segs)
          {
            'inicio': s.inicio.inMilliseconds / 1000,
            'fin': s.fin.inMilliseconds / 1000,
            'tipo': s.tipo,
            'titulo': s.titulo,
          },
      ];
      if (_logoCambiado) {
        if (_logoNuevo != null) {
          datos['logo'] = await guardarLogo(_logoNuevo!, widget.emisora.carpeta);
        } else {
          datos.remove('logo');
        }
      }
      await f.writeAsString(jsonEncode(datos));
      // El logotipo anterior ya no hace falta.
      final viejo = widget.emisora.logo;
      if (_logoCambiado && viejo != null) {
        try {
          await File(viejo).delete();
        } catch (_) {}
      }
      // La parrilla en vivo depende de las pistas: hay que regenerarla.
      await radio.olvidar(widget.emisora.carpeta);
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) _aviso(_t('cannot_save', {'err': '$e'}));
    }
  }

  @override
  Widget build(BuildContext context) {
    final nombreVista =
    _nombre.text.trim().isEmpty ? widget.emisora.nombre : _nombre.text.trim();
    final color = _colorEmisora(nombreVista);

    return PopScope(
      canPop: !_cambios,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final salir = await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            backgroundColor: const Color(0xFF101016),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
              side: const BorderSide(color: Colors.white12),
            ),
            title: Text(
              _t('discard_changes_title').toUpperCase(),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.0,
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(
                  _t('keep_editing').toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white70,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black,
                ),
                onPressed: () => Navigator.pop(context, true),
                child: Text(
                  _t('discard').toUpperCase(),
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
            ],
          ),
        );
        if (salir == true && mounted) Navigator.pop(context);
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          surfaceTintColor: Colors.transparent,
          foregroundColor: Colors.white,
          elevation: 0,
          title: Text(
            _t('edit_tracks').toUpperCase(),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.3,
            ),
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Opacity(
                opacity: _cambios ? 1.0 : 0.35,
                child: InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: _cambios ? _guardar : null,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: _cambios
                          ? Colors.white
                          : Colors.white.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.check,
                          size: 16,
                          color: _cambios ? Colors.black : Colors.white70,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          _t('save_tooltip').toUpperCase(),
                          style: TextStyle(
                            color: _cambios ? Colors.black : Colors.white70,
                            fontSize: 11.5,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.0,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
        floatingActionButton: _BotonHudGTA(
          icono: Icons.add,
          etiqueta: _t('add_track').toUpperCase(),
          acento: color,
          onTap: _anadir,
        ),
        body: _FondoAtmosfericoGTA(
          color: color,
          logoRuta: _logoVista,
          child: SafeArea(
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 92),
              itemCount: _segs.length + 1,
              itemBuilder: (_, i) {
                if (i == 0) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 14),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            GestureDetector(
                              onTap: _cambiarLogo,
                              child: _CaratulaPreviewGTA(
                                logoRuta: _logoVista,
                                nombre: nombreVista,
                                tam: 76,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _BotonSelectorGTA(
                                    icono: Icons.image_outlined,
                                    titulo: _logoVista == null
                                        ? _t('pick_logo_short')
                                        : _t('change_logo'),
                                    seleccionado: _logoVista != null,
                                    acento: color,
                                    onTap: _cambiarLogo,
                                    onLimpiar: _logoVista == null ? null : _quitarLogo,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: _nombre,
                          onChanged: (_) => setState(() => _cambios = true),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5,
                          ),
                          cursorColor: Colors.white,
                          decoration: _inputDecorationGTA(
                            label: _t('station_name_label'),
                            acento: color,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          (_total == null
                              ? _t('tracks_count', {'n': '${_segs.length}'})
                              : _t('tracks_and_duration', {
                            'n': '${_segs.length}',
                            'dur': _fmt(_total!),
                          }))
                              .toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white60,
                            fontSize: 11.5,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.0,
                            fontFeatures: [FontFeature.tabularFigures()],
                          ),
                        ),
                      ],
                    ),
                  );
                }
                final idx = i - 1;
                final s = _segs[idx];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(14),
                      onTap: () => _editarPista(idx),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.055),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: Colors.white12),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 34,
                              height: 34,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.1),
                                shape: BoxShape.circle,
                              ),
                              alignment: Alignment.center,
                              child: Icon(
                                _iconoTipo(s.tipo),
                                color: Colors.white,
                                size: 17,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    s.titulo.toUpperCase(),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w800,
                                      fontSize: 13,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${_fmt(s.inicio)} – ${_fmt(s.fin)} · ${_fmt(s.fin - s.inicio)}',
                                    style: const TextStyle(
                                      color: Colors.white60,
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w600,
                                      fontFeatures: [FontFeature.tabularFigures()],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.delete_outline,
                                color: Colors.white54,
                                size: 20,
                              ),
                              tooltip: _t('delete'),
                              onPressed: () => _borrarPista(idx),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _DialogoPista extends StatefulWidget {
  final Segmento? inicial; // null = pista nueva
  final String archivo;
  final Duration? total;
  final Future<void> Function(Duration desde, Duration hasta) escuchar;
  final Future<void> Function() parar;

  const _DialogoPista({
    required this.inicial,
    required this.archivo,
    required this.total,
    required this.escuchar,
    required this.parar,
  });

  @override
  State<_DialogoPista> createState() => _DialogoPistaState();
}

class _DialogoPistaState extends State<_DialogoPista> {
  late final TextEditingController _titulo =
  TextEditingController(text: widget.inicial?.titulo ?? '');
  late final TextEditingController _ini = TextEditingController(
      text: widget.inicial == null ? '' : _fmt(widget.inicial!.inicio));
  late final TextEditingController _fin = TextEditingController(
      text: widget.inicial == null ? '' : _fmt(widget.inicial!.fin));
  late String _tipo = widget.inicial?.tipo ?? 'cancion';
  String? _error;

  @override
  void dispose() {
    _titulo.dispose();
    _ini.dispose();
    _fin.dispose();
    super.dispose();
  }

  Future<void> _oirInicio() async {
    final i = _parseTiempo(_ini.text);
    if (i == null) {
      setState(() => _error = _t('invalid_start'));
      return;
    }
    final f = _parseTiempo(_fin.text);
    final tope = i + const Duration(seconds: 6);
    final hasta = (f != null && f > i && f < tope) ? f : tope;
    setState(() => _error = null);
    await widget.escuchar(i, hasta);
  }

  Future<void> _oirFinal() async {
    final f = _parseTiempo(_fin.text);
    if (f == null) {
      setState(() => _error = _t('invalid_end'));
      return;
    }
    final i = _parseTiempo(_ini.text) ?? Duration.zero;
    final desde = f - const Duration(seconds: 6);
    setState(() => _error = null);
    await widget.escuchar(desde > i ? desde : i, f);
  }

  void _cancelar() {
    widget.parar();
    Navigator.pop(context);
  }

  void _aceptar() {
    final i = _parseTiempo(_ini.text);
    final f = _parseTiempo(_fin.text);
    final t = _titulo.text.trim();
    String? err;
    if (t.isEmpty) {
      err = _t('set_title');
    } else if (i == null || f == null) {
      err = _t('invalid_times');
    } else if (f <= i) {
      err = _t('end_before_start');
    } else if (widget.total != null && f > widget.total!) {
      err = _t('end_exceeds_duration', {'dur': _fmt(widget.total!)});
    }
    if (err != null) {
      setState(() => _error = err);
      return;
    }
    widget.parar();
    Navigator.pop(
      context,
      Segmento(archivo: widget.archivo, inicio: i!, fin: f!, tipo: _tipo, titulo: t),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF101016),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(color: Colors.white12),
      ),
      title: Text(
        (widget.inicial == null ? _t('new_track') : _t('edit_track')).toUpperCase(),
        style: const TextStyle(
          color: Colors.white,
          fontSize: 15,
          fontWeight: FontWeight.w900,
          letterSpacing: 1.2,
        ),
      ),
      scrollable: true,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _titulo,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
            cursorColor: Colors.white,
            decoration: _inputDecorationGTA(label: _t('title_label')),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final tipo in _tiposSegmento)
                GestureDetector(
                  onTap: () => setState(() => _tipo = tipo),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 160),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                    decoration: BoxDecoration(
                      color: _tipo == tipo
                          ? Colors.white
                          : Colors.white.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: _tipo == tipo ? Colors.white : Colors.white24,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _iconoTipo(tipo),
                          size: 14,
                          color: _tipo == tipo ? Colors.black : Colors.white70,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          _etiquetaTipo(tipo).toUpperCase(),
                          style: TextStyle(
                            color: _tipo == tipo ? Colors.black : Colors.white70,
                            fontSize: 11.5,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _ini,
                  keyboardType: TextInputType.datetime,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontFeatures: [FontFeature.tabularFigures()],
                  ),
                  cursorColor: Colors.white,
                  decoration: _inputDecorationGTA(
                    label: _t('start_label'),
                    hint: '3:41',
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _fin,
                  keyboardType: TextInputType.datetime,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontFeatures: [FontFeature.tabularFigures()],
                  ),
                  cursorColor: Colors.white,
                  decoration: _inputDecorationGTA(
                    label: _t('end_label'),
                    hint: '7:05',
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: Colors.white24),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                ),
                onPressed: _oirInicio,
                icon: const Icon(Icons.play_arrow, size: 16),
                label: Text(
                  _t('listen_start').toUpperCase(),
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.7,
                  ),
                ),
              ),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: Colors.white24),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                ),
                onPressed: _oirFinal,
                icon: const Icon(Icons.play_arrow, size: 16),
                label: Text(
                  _t('listen_end').toUpperCase(),
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.7,
                  ),
                ),
              ),
            ],
          ),
          if (_error != null)
            Container(
              margin: const EdgeInsets.only(top: 12),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.redAccent.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.redAccent.withValues(alpha: 0.5)),
              ),
              child: Text(
                _error!,
                style: const TextStyle(
                  color: Colors.redAccent,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _cancelar,
          child: Text(
            _t('cancel').toUpperCase(),
            style: const TextStyle(
              color: Colors.white70,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.8,
            ),
          ),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: Colors.white,
            foregroundColor: Colors.black,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
          ),
          onPressed: _aceptar,
          child: Text(
            _t('accept').toUpperCase(),
            style: const TextStyle(
              fontWeight: FontWeight.w900,
              letterSpacing: 0.9,
            ),
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Utilidades visuales y de formato
// ---------------------------------------------------------------------------

/// Cada emisora tiene su propio color, estable: sale del nombre.
Color _colorEmisora(String nombre) =>
    HSLColor.fromAHSL(1, (_hash(nombre) % 360).toDouble(), 0.62, 0.48).toColor();

Color _sobre(Color fondo) =>
    ThemeData.estimateBrightnessForColor(fondo) == Brightness.dark
        ? Colors.white
        : Colors.black87;

/// "Artista - Canción" → artista y título. Si no sigue ese formato, todo es título.
({String? artista, String titulo}) _separarTitulo(Segmento s) {
  if (s.tipo != 'cancion') return (artista: null, titulo: s.titulo);
  final i = s.titulo.indexOf(' - ');
  if (i <= 0) return (artista: null, titulo: s.titulo);
  final artista = s.titulo.substring(0, i).trim();
  final titulo = s.titulo.substring(i + 3).trim();
  if (artista.isEmpty || titulo.isEmpty) return (artista: null, titulo: s.titulo);
  return (artista: artista, titulo: titulo);
}

/// Duración como reloj, sin décimas: 3:41 o 1:02:10.
String _reloj(Duration d) {
  final m = (d.inMinutes % 60).toString().padLeft(2, '0');
  final s = (d.inSeconds % 60).toString().padLeft(2, '0');
  return d.inHours > 0 ? '${d.inHours}:$m:$s' : '${d.inMinutes}:$s';
}

/// Hora del día (local) de un instante en ms desde 1970.
String _hora(int ms) {
  final d = DateTime.fromMillisecondsSinceEpoch(ms);
  return '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
}

const _extensionesImagen = {'png', 'jpg', 'jpeg', 'webp'};

/// Pide una imagen. Devuelve null si se cancela o el archivo no es una imagen.
Future<File?> elegirImagen(BuildContext context) async {
  final f = await FilePicker.pickFile();
  final ruta = f?.path;
  if (f == null || ruta == null) return null;
  final ext = ruta.contains('.') ? ruta.split('.').last.toLowerCase() : '';
  if (!_extensionesImagen.contains(ext)) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_t('image_format_msg'))),
      );
    }
    return null;
  }
  return File(ruta);
}

/// Copia la imagen a la carpeta de la emisora y devuelve el nombre del archivo.
/// El nombre lleva la hora para que Flutter no enseñe una versión antigua en caché.
Future<String> guardarLogo(File origen, String carpeta) async {
  final ext = origen.path.split('.').last.toLowerCase();
  final nombre = 'logo_${DateTime.now().millisecondsSinceEpoch}.$ext';
  await origen.copy('$carpeta/$nombre');
  return nombre;
}

/// Logotipo cuadrado y pequeño. Sin imagen: el color de la emisora con su inicial.
class _LogoMini extends StatelessWidget {
  final String? ruta;
  final String nombre;
  final double tam;
  const _LogoMini({required this.ruta, required this.nombre, required this.tam});

  @override
  Widget build(BuildContext context) {
    final color = _colorEmisora(nombre);
    final limpio = nombre.trim();
    final inicial =
    limpio.isEmpty ? '?' : String.fromCharCode(limpio.runes.first).toUpperCase();
    final alternativa = Container(
      color: color,
      alignment: Alignment.center,
      child: Text(
        inicial,
        style: TextStyle(
          color: _sobre(color),
          fontSize: tam * 0.45,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
    return ClipRRect(
      borderRadius: BorderRadius.circular(tam * 0.18),
      child: SizedBox(
        width: tam,
        height: tam,
        child: ruta == null
            ? alternativa
            : Image.file(
          File(ruta!),
          fit: BoxFit.cover,
          cacheWidth: (tam * 3).round(),
          errorBuilder: (_, __, ___) => alternativa,
        ),
      ),
    );
  }
}

class _InsigniaDirecto extends StatelessWidget {
  final Reproductor repro;
  const _InsigniaDirecto({required this.repro});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: repro.sonando,
      builder: (_, sonando, __) {
        final c = sonando ? Colors.redAccent : Theme.of(context).colorScheme.outline;
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.circle, size: 10, color: c),
            const SizedBox(width: 6),
            Text(
              sonando ? _t('live_badge') : _t('paused_badge'),
              style: Theme.of(context).textTheme.labelLarge?.copyWith(color: c),
            ),
          ],
        );
      },
    );
  }
}

/// Barra de progreso de la pista. Es una radio en directo: no se puede mover.
class _ProgresoPista extends StatefulWidget {
  final Reproductor repro;
  final Segmento seg;
  final Color color;
  const _ProgresoPista({required this.repro, required this.seg, required this.color});

  @override
  State<_ProgresoPista> createState() => _ProgresoPistaState();
}

class _ProgresoPistaState extends State<_ProgresoPista> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(milliseconds: 250), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final total = widget.seg.fin - widget.seg.inicio;
    var pos = widget.repro.posicionPista;
    if (pos > total) pos = total;
    if (pos < Duration.zero) pos = Duration.zero;
    final valor =
    total.inMilliseconds <= 0 ? 0.0 : pos.inMilliseconds / total.inMilliseconds;
    final estilo = Theme.of(context).textTheme.bodySmall?.copyWith(
      fontFeatures: const [FontFeature.tabularFigures()],
    );

    return Column(
      children: [
        LinearProgressIndicator(
          value: valor,
          minHeight: 6,
          borderRadius: BorderRadius.circular(3),
          color: widget.color,
          backgroundColor: widget.color.withValues(alpha: 0.25),
        ),
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(_reloj(pos), style: estilo),
            Text('-${_reloj(total - pos)}', style: estilo),
          ],
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// UI Vertical estilo selector de radio GTA VI
// ---------------------------------------------------------------------------

Future<void> abrirDialGTA(BuildContext context, List<Emisora> emisoras) {
  return Navigator.of(context).push(PageRouteBuilder<void>(
    opaque: false,
    transitionDuration: const Duration(milliseconds: 280),
    reverseTransitionDuration: const Duration(milliseconds: 220),
    pageBuilder: (_, __, ___) => PantallaDialGTA(emisoras: emisoras),
    transitionsBuilder: (_, anim, __, child) => FadeTransition(
      opacity: CurvedAnimation(parent: anim, curve: Curves.easeOut),
      child: child,
    ),
  ));
}

class PantallaInicioGTA extends StatefulWidget {
  const PantallaInicioGTA({super.key});

  @override
  State<PantallaInicioGTA> createState() => _PantallaInicioGTAState();
}

class _PantallaInicioGTAState extends State<PantallaInicioGTA> {
  final repro = radio;
  final PageController _pageCtrl = PageController(viewportFraction: 0.62);
  List<Emisora> _emisoras = const [];
  bool _cargando = true;
  int _indice = 0;
  int _subModo = 0; // 0 = LIVE RADIO, 1 = UP NEXT, 2 = RECENT
  Timer? _relojTick;

  @override
  void initState() {
    super.initState();
    _relojTick = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
    _cargarEmisoras(sintonizarInicial: true);
  }

  @override
  void dispose() {
    _relojTick?.cancel();
    _pageCtrl.dispose();
    super.dispose();
  }

  Future<void> _cargarEmisoras({
    bool sintonizarInicial = false,
    String? enfocarCarpeta,
  }) async {
    final lista = await cargarEmisorasDisco();
    if (!mounted) return;

    var nuevoIndice = 0;
    var debeSintonizarNueva = false;
    if (lista.isNotEmpty) {
      if (enfocarCarpeta != null) {
        final idxNueva = lista.indexWhere((e) => e.carpeta == enfocarCarpeta);
        if (idxNueva >= 0) {
          nuevoIndice = idxNueva;
          debeSintonizarNueva = true;
        }
      } else {
        final actual = repro.emisoraActual.value;
        if (actual != null) {
          final idx = lista.indexWhere((e) => e.carpeta == actual.carpeta);
          if (idx >= 0) nuevoIndice = idx;
        } else {
          nuevoIndice = _indice.clamp(0, lista.length - 1);
        }
      }
    }

    setState(() {
      _emisoras = lista;
      _indice = nuevoIndice;
      _cargando = false;
    });

    if (lista.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _pageCtrl.hasClients) {
          _pageCtrl.jumpToPage(nuevoIndice);
        }
      });
    }

    if (debeSintonizarNueva) {
      unawaited(repro.sintonizar(lista[nuevoIndice]));
    } else if (sintonizarInicial &&
        lista.isNotEmpty &&
        repro.emisoraActual.value == null &&
        repro.actual.value == null) {
      unawaited(repro.sintonizar(lista[nuevoIndice]));
    }
  }

  Future<void> _anadirDirecto() async {
    final carpetaCreada = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (_) => PantallaImportar(repro: repro)),
    );
    if (carpetaCreada != null && mounted) {
      await _cargarEmisoras(
        sintonizarInicial: true,
        enfocarCarpeta: carpetaCreada,
      );
    }
  }

  Future<void> _importarDirecto() async {
    final antes = _emisoras.map((e) => e.carpeta).toSet();
    final ok = await _importarPaqueteConDialogo(context);
    if (!ok || !mounted) return;
    final lista = await cargarEmisorasDisco();
    String? nuevaCarpeta;
    for (final e in lista) {
      if (!antes.contains(e.carpeta)) {
        nuevaCarpeta = e.carpeta;
        break;
      }
    }
    await _cargarEmisoras(
      sintonizarInicial: true,
      enfocarCarpeta: nuevaCarpeta,
    );
  }

  Future<void> _abrirMenuCrear() async {
    final opcion = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: const Color(0xFF101016),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        side: BorderSide(color: Colors.white12),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 38,
                height: 4,
                margin: const EdgeInsets.only(bottom: 14),
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Text(
                _t('create_station'),
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.4,
                ),
              ),
              const SizedBox(height: 12),
              _OpcionMenuGTA(
                icono: Icons.add,
                titulo: _t('new_station').toUpperCase(),
                subtitulo: _t('new_station_desc'),
                destacado: true,
                onTap: () => Navigator.pop(ctx, 'crear'),
              ),
              const SizedBox(height: 10),
              _OpcionMenuGTA(
                icono: Icons.file_open_outlined,
                titulo: _t('import_gtaradio').toUpperCase(),
                subtitulo: _t('import_gtaradio_desc'),
                onTap: () => Navigator.pop(ctx, 'importar'),
              ),
            ],
          ),
        ),
      ),
    );
    if (!mounted || opcion == null) return;
    if (opcion == 'crear') {
      await _anadirDirecto();
    } else if (opcion == 'importar') {
      await _importarDirecto();
    }
  }

  Future<void> _abrirMenuEmisora(Emisora e) async {
    HapticFeedback.mediumImpact();
    final opcion = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: const Color(0xFF101016),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        side: BorderSide(color: Colors.white12),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 38,
                height: 4,
                margin: const EdgeInsets.only(bottom: 14),
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _LogoMini(ruta: e.logo, nombre: e.nombre, tam: 26),
                  const SizedBox(width: 10),
                  Flexible(
                    child: Text(
                      e.nombre.toUpperCase(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.3,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              _OpcionMenuGTA(
                icono: Icons.edit_outlined,
                titulo: _t('edit_tracks').toUpperCase(),
                subtitulo: _t('edit_tracks_desc'),
                destacado: true,
                onTap: () => Navigator.pop(ctx, 'editar'),
              ),
              const SizedBox(height: 10),
              _OpcionMenuGTA(
                icono: Icons.ios_share,
                titulo: _t('export_radio').toUpperCase(),
                subtitulo: _t('export_radio_desc'),
                onTap: () => Navigator.pop(ctx, 'exportar'),
              ),
              const SizedBox(height: 10),
              _OpcionMenuGTA(
                icono: Icons.delete_outline,
                titulo: _t('delete_radio').toUpperCase(),
                subtitulo: _t('delete_radio_body'),
                peligro: true,
                onTap: () => Navigator.pop(ctx, 'borrar'),
              ),
            ],
          ),
        ),
      ),
    );
    if (!mounted || opcion == null) return;
    if (opcion == 'editar') {
      final guardado = await Navigator.push<bool>(
        context,
        MaterialPageRoute(builder: (_) => PantallaEditar(emisora: e)),
      );
      if (guardado == true && mounted) {
        await _cargarEmisoras(enfocarCarpeta: e.carpeta);
      }
    } else if (opcion == 'exportar') {
      await _ejecutarConEspera(
        context,
        _t('preparing_radio', {'nombre': e.nombre}),
            () => exportarRadio(carpeta: e.carpeta, nombre: e.nombre),
      );
    } else if (opcion == 'borrar') {
      await _borrarEmisora(e);
    }
  }

  Future<void> _borrarEmisora(Emisora e) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF101016),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: const BorderSide(color: Colors.white12),
        ),
        title: Text(
          _t('delete_radio_title', {'nombre': e.nombre}).toUpperCase(),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 15,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.0,
          ),
        ),
        content: Text(
          _t('delete_radio_body'),
          style: const TextStyle(color: Colors.white70, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              _t('cancel').toUpperCase(),
              style: const TextStyle(
                color: Colors.white70,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.8,
              ),
            ),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              _t('delete').toUpperCase(),
              style: const TextStyle(
                fontWeight: FontWeight.w900,
                letterSpacing: 0.8,
              ),
            ),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await repro.olvidar(e.carpeta);
    await Directory(e.carpeta).delete(recursive: true);
    if (mounted) {
      await _cargarEmisoras(sintonizarInicial: true);
    }
  }

  Emisora get _enfocada => _emisoras[_indice.clamp(0, _emisoras.length - 1)];

  void _seleccionarIndice(int i, {bool animar = true}) {
    if (_emisoras.isEmpty) return;
    final destino = i.clamp(0, _emisoras.length - 1);
    if (animar && _pageCtrl.hasClients) {
      _pageCtrl.animateToPage(
        destino,
        duration: const Duration(milliseconds: 240),
        curve: Curves.easeOutCubic,
      );
    }
    setState(() => _indice = destino);
    final e = _emisoras[destino];
    if (repro.emisoraActual.value?.carpeta != e.carpeta || !repro.sonando.value) {
      repro.sintonizar(e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: idiomaApp,
      builder: (context, _, __) {
        if (_cargando) {
          return const Scaffold(
            backgroundColor: Colors.black,
            body: Center(child: CircularProgressIndicator(color: Colors.white)),
          );
        }

        if (_emisoras.isEmpty) {
          return Scaffold(
            backgroundColor: Colors.black,
            body: SafeArea(
              child: Stack(
                children: [
                  const Positioned(
                    top: 8,
                    right: 12,
                    child: _BotonIdioma(color: Colors.white70, tam: 22),
                  ),
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.all(28),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _t('no_stations_dial'),
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.2,
                            ),
                          ),
                          const SizedBox(height: 22),
                          _BotonHudGTA(
                            icono: Icons.add,
                            etiqueta: _t('create_station'),
                            onTap: _abrirMenuCrear,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        final e = _enfocada;
        final color = _colorEmisora(e.nombre);
        final total = _emisoras.length;

        return ValueListenableBuilder<Segmento?>(
          valueListenable: repro.actual,
          builder: (context, segRepro, _) {
            final apagada = segRepro == null;
            final seg = repro.segmentoEnVivo(e);
            final partes = seg == null ? null : _separarTitulo(seg);

            return Scaffold(
              backgroundColor: Colors.black,
              body: Stack(
                fit: StackFit.expand,
                children: [
                  // Fondo atmosférico con el arte/color de la emisora desenfocado
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 350),
                    decoration: BoxDecoration(
                      gradient: RadialGradient(
                        center: const Alignment(0, -0.25),
                        radius: 1.15,
                        colors: [
                          color.withValues(alpha: apagada ? 0.16 : 0.42),
                          const Color(0xFF0B0B10),
                          Colors.black,
                        ],
                      ),
                    ),
                  ),
                  if (e.logo != null)
                    Opacity(
                      opacity: apagada ? 0.08 : 0.22,
                      child: Image.file(
                        File(e.logo!),
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                      ),
                    ),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withValues(alpha: 0.72),
                          Colors.black.withValues(alpha: 0.35),
                          Colors.black.withValues(alpha: 0.88),
                        ],
                      ),
                    ),
                  ),

                  // Contenido vertical estilo HUD GTA VI
                  SafeArea(
                    child: LayoutBuilder(
                      builder: (context, box) {
                        final altoCarrusel =
                        (MediaQuery.sizeOf(context).width * 0.58).clamp(198.0, 260.0);
                        final espacioCentro =
                        ((box.maxHeight - 92 - altoCarrusel - 300) * 0.65)
                            .clamp(10.0, 140.0);
                        return Column(
                          children: [
                            // 1. Barra superior: Idioma | Selector vertical de modo | Botón TURN OFF
                            Padding(
                              padding: const EdgeInsets.fromLTRB(10, 8, 12, 4),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  const _BotonIdioma(color: Colors.white70, tam: 21),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Align(
                                      alignment: Alignment.centerLeft,
                                      child: FittedBox(
                                        fit: BoxFit.scaleDown,
                                        alignment: Alignment.centerLeft,
                                        child: _SelectorVerticalGTA(
                                          indice: _subModo,
                                          acento: color,
                                          etiquetas: [
                                            _t('mode_live'),
                                            _t('mode_queue'),
                                            _t('mode_history'),
                                          ],
                                          onChanged: (m) => setState(() => _subModo = m),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  InkWell(
                                    borderRadius: BorderRadius.circular(20),
                                    onTap: () {
                                      if (apagada) {
                                        repro.sintonizar(e);
                                      } else {
                                        repro.detener();
                                      }
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(color: Colors.white24),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Container(
                                            width: 20,
                                            height: 20,
                                            decoration: const BoxDecoration(
                                              color: Colors.white,
                                              shape: BoxShape.circle,
                                            ),
                                            alignment: Alignment.center,
                                            child: Icon(
                                              apagada ? Icons.power_settings_new : Icons.close,
                                              size: 14,
                                              color: Colors.black,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            apagada ? _t('live_upper') : _t('turn_off'),
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.w800,
                                              fontSize: 12,
                                              letterSpacing: 1.1,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            AnimatedContainer(
                              duration: const Duration(milliseconds: 260),
                              curve: Curves.easeOutCubic,
                              height: _subModo == 0 ? espacioCentro : 12.0,
                            ),

                            // 2. Carrusel horizontal de carátulas cuadradas con flechas < >
                            SizedBox(
                              height: altoCarrusel,
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  PageView.builder(
                                    controller: _pageCtrl,
                                    itemCount: total,
                                    onPageChanged: (i) {
                                      setState(() => _indice = i);
                                      final sel = _emisoras[i];
                                      if (repro.emisoraActual.value?.carpeta != sel.carpeta) {
                                        repro.sintonizar(sel);
                                      }
                                    },
                                    itemBuilder: (_, i) {
                                      final item = _emisoras[i];
                                      final seleccionada = i == _indice && !apagada;
                                      final cItem = _colorEmisora(item.nombre);
                                      return GestureDetector(
                                        onTap: () => _seleccionarIndice(i),
                                        onLongPress: () => _abrirMenuEmisora(item),
                                        child: AnimatedScale(
                                          scale: i == _indice ? 1.0 : 0.70,
                                          duration: const Duration(milliseconds: 220),
                                          curve: Curves.easeOutCubic,
                                          child: AnimatedOpacity(
                                            opacity: i == _indice ? 1.0 : 0.58,
                                            duration: const Duration(milliseconds: 220),
                                            child: Center(
                                              child: AspectRatio(
                                                aspectRatio: 1,
                                                child: Container(
                                                  decoration: BoxDecoration(
                                                    borderRadius: BorderRadius.circular(6),
                                                    border: Border.all(
                                                      color: seleccionada
                                                          ? Colors.white
                                                          : Colors.white24,
                                                      width: seleccionada ? 3.5 : 1,
                                                    ),
                                                    boxShadow: seleccionada
                                                        ? [
                                                      BoxShadow(
                                                        color: cItem.withValues(alpha: 0.55),
                                                        blurRadius: 22,
                                                        spreadRadius: 2,
                                                      ),
                                                    ]
                                                        : null,
                                                  ),
                                                  child: ClipRRect(
                                                    borderRadius: BorderRadius.circular(3),
                                                    child: item.logo != null
                                                        ? Image.file(
                                                      File(item.logo!),
                                                      fit: BoxFit.cover,
                                                      errorBuilder: (_, __, ___) =>
                                                          _CaratulaFallbackGTA(nombre: item.nombre),
                                                    )
                                                        : _CaratulaFallbackGTA(nombre: item.nombre),
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                  if (_indice > 0)
                                    Positioned(
                                      left: 8,
                                      child: IconButton(
                                        onPressed: () => _seleccionarIndice(_indice - 1),
                                        icon: const Icon(Icons.chevron_left, color: Colors.white70, size: 32),
                                      ),
                                    ),
                                  if (_indice < total - 1)
                                    Positioned(
                                      right: 8,
                                      child: IconButton(
                                        onPressed: () => _seleccionarIndice(_indice + 1),
                                        icon: const Icon(Icons.chevron_right, color: Colors.white70, size: 32),
                                      ),
                                    ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 12),

                            // 3. Barra indicadora del dial
                            _IndicadorDialGTA(
                              indice: _indice,
                              total: total,
                            ),

                            const SizedBox(height: 18),

                            // 4. Bloque central de metadatos en mayúsculas estilo GTA VI
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 24),
                              child: Column(
                                children: [
                                  Text(
                                    e.nombre.toUpperCase(),
                                    textAlign: TextAlign.center,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 25,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 1.2,
                                      height: 1.08,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  if (apagada || seg == null || partes == null)
                                    Text(
                                      _t('radio_off'),
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                        color: Colors.white60,
                                        fontSize: 15,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: 1.1,
                                      ),
                                    )
                                  else ...[
                                    Text(
                                      partes.titulo.toUpperCase(),
                                      textAlign: TextAlign.center,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 15,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: 0.8,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      (partes.artista ?? _etiquetaTipo(seg.tipo)).toUpperCase(),
                                      textAlign: TextAlign.center,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        color: Colors.white70,
                                        fontSize: 13.5,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: 0.9,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),

                            const SizedBox(height: 16),

                            // 5. Panel inferior dinámico según el selector vertical
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
                                child: _PanelInferiorGTA(
                                  repro: repro,
                                  emisora: e,
                                  seg: seg,
                                  color: color,
                                  subModo: _subModo,
                                  apagada: apagada,
                                ),
                              ),
                            ),

                            // 6. Botón inferior estilo HUD GTA para crear o importar emisora
                            Padding(
                              padding: const EdgeInsets.fromLTRB(20, 4, 20, 14),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  _BotonHudGTA(
                                    icono: Icons.add,
                                    etiqueta: _t('create_station'),
                                    acento: color,
                                    onTap: _abrirMenuCrear,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _BotonHudGTA extends StatelessWidget {
  final IconData icono;
  final String etiqueta;
  final Color? acento;
  final VoidCallback onTap;

  const _BotonHudGTA({
    required this.icono,
    required this.etiqueta,
    required this.onTap,
    this.acento,
  });

  @override
  Widget build(BuildContext context) {
    final borde = acento?.withValues(alpha: 0.55) ?? Colors.white30;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: borde),
            boxShadow: acento != null
                ? [
              BoxShadow(
                color: acento!.withValues(alpha: 0.22),
                blurRadius: 14,
              ),
            ]
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 22,
                height: 22,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Icon(icono, size: 15, color: Colors.black),
              ),
              const SizedBox(width: 9),
              Text(
                etiqueta,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 12,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OpcionMenuGTA extends StatelessWidget {
  final IconData icono;
  final String titulo;
  final String subtitulo;
  final bool destacado;
  final bool peligro;
  final VoidCallback onTap;

  const _OpcionMenuGTA({
    required this.icono,
    required this.titulo,
    required this.subtitulo,
    required this.onTap,
    this.destacado = false,
    this.peligro = false,
  });

  @override
  Widget build(BuildContext context) {
    final bgColor = peligro
        ? Colors.redAccent.withValues(alpha: 0.08)
        : Colors.white.withValues(alpha: destacado ? 0.09 : 0.05);
    final borderColor = peligro
        ? Colors.redAccent.withValues(alpha: 0.35)
        : (destacado ? Colors.white30 : Colors.white12);
    final badgeColor = peligro
        ? Colors.redAccent.withValues(alpha: 0.18)
        : (destacado ? Colors.white : Colors.white.withValues(alpha: 0.14));
    final iconColor = peligro
        ? Colors.redAccent
        : (destacado ? Colors.black : Colors.white);
    final titleColor = peligro ? Colors.redAccent : Colors.white;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: borderColor),
          ),
          child: Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: badgeColor,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Icon(icono, size: 18, color: iconColor),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      titulo,
                      style: TextStyle(
                        color: titleColor,
                        fontWeight: FontWeight.w900,
                        fontSize: 13.5,
                        letterSpacing: 0.9,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitulo,
                      style: const TextStyle(
                        color: Colors.white60,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: peligro ? Colors.redAccent.withValues(alpha: 0.7) : Colors.white54,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CaratulaFallbackGTA extends StatelessWidget {
  final String nombre;
  const _CaratulaFallbackGTA({required this.nombre});

  @override
  Widget build(BuildContext context) {
    final c = _colorEmisora(nombre);
    final texto = _sobre(c);
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            c,
            Color.lerp(c, Colors.black, 0.35)!,
          ],
        ),
      ),
      padding: const EdgeInsets.all(10),
      alignment: Alignment.center,
      child: Text(
        nombre.toUpperCase(),
        textAlign: TextAlign.center,
        maxLines: 3,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: texto,
          fontSize: 16,
          fontWeight: FontWeight.w900,
          height: 1.05,
          letterSpacing: 0.6,
        ),
      ),
    );
  }
}

class _SelectorVerticalGTA extends StatelessWidget {
  final int indice;
  final List<String> etiquetas;
  final ValueChanged<int> onChanged;
  final Color? acento;

  const _SelectorVerticalGTA({
    required this.indice,
    required this.etiquetas,
    required this.onChanged,
    this.acento,
  });

  @override
  Widget build(BuildContext context) {
    final colorAcento = acento ?? Colors.white;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.42),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white24),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (var i = 0; i < etiquetas.length; i++)
            GestureDetector(
              onTap: () => onChanged(i),
              behavior: HitTestBehavior.opaque,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOutCubic,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                decoration: BoxDecoration(
                  color: i == indice
                      ? Colors.white.withValues(alpha: 0.16)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      etiquetas[i],
                      textAlign: TextAlign.right,
                      maxLines: 1,
                      softWrap: false,
                      style: TextStyle(
                        color: i == indice ? Colors.white : Colors.white70,
                        fontSize: i == indice ? 12 : 11.5,
                        fontWeight: i == indice ? FontWeight.w900 : FontWeight.w700,
                        letterSpacing: 0.9,
                      ),
                    ),
                    const SizedBox(width: 8),
                    SizedBox(
                      width: 18,
                      height: 18,
                      child: Center(
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          width: i == indice ? 18 : 10,
                          height: i == indice ? 18 : 10,
                          decoration: BoxDecoration(
                            color: i == indice ? Colors.white : Colors.transparent,
                            shape: BoxShape.circle,
                            border: i == indice
                                ? Border.all(color: Colors.black, width: 1.5)
                                : Border.all(color: Colors.white60, width: 1.4),
                            boxShadow: i == indice
                                ? [
                              BoxShadow(
                                color: colorAcento.withValues(alpha: 0.65),
                                blurRadius: 8,
                              ),
                            ]
                                : null,
                          ),
                          alignment: Alignment.center,
                          child: i == indice
                              ? const Text(
                            'R',
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                            ),
                          )
                              : null,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _IndicadorDialGTA extends StatelessWidget {
  final int indice;
  final int total;

  const _IndicadorDialGTA({
    required this.indice,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    final frac = total <= 1 ? 0.5 : (indice / (total - 1)).clamp(0.0, 1.0);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 64),
      child: SizedBox(
        height: 14,
        child: LayoutBuilder(
          builder: (_, box) {
            final ancho = box.maxWidth;
            const anchoThumb = 24.0;
            final x = (ancho - anchoThumb) * frac;
            return Stack(
              alignment: Alignment.centerLeft,
              children: [
                Container(
                  height: 2,
                  width: ancho,
                  color: Colors.white30,
                ),
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOutCubic,
                  left: x,
                  child: Container(
                    width: anchoThumb,
                    height: 6,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _PanelInferiorGTA extends StatelessWidget {
  final Reproductor repro;
  final Emisora emisora;
  final Segmento? seg;
  final Color color;
  final int subModo;
  final bool apagada;

  const _PanelInferiorGTA({
    required this.repro,
    required this.emisora,
    required this.seg,
    required this.color,
    required this.subModo,
    required this.apagada,
  });

  @override
  Widget build(BuildContext context) {
    final Widget contenido;
    final Object clave;

    if (apagada || seg == null) {
      clave = 'apagada';
      contenido = Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton.filled(
              iconSize: 40,
              padding: const EdgeInsets.all(18),
              style: IconButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.black,
              ),
              icon: const Icon(Icons.play_arrow),
              onPressed: () => repro.sintonizar(emisora),
            ),
            const SizedBox(height: 10),
            Text(
              _t('tap_station_to_tune'),
              style: const TextStyle(color: Colors.white60, fontSize: 13),
            ),
          ],
        ),
      );
    } else if (subModo == 1) {
      final proximas = repro.proximas(5);
      clave = 'siguiente_${emisora.carpeta}';
      contenido = _ListaDesplegableGTA(
        key: ValueKey(clave),
        items: [
          for (final p in proximas)
            _ItemListaGTA(
              hora: _hora(p.inicioMs),
              titulo: p.seg.titulo,
              tipo: p.seg.tipo,
            ),
        ],
      );
    } else if (subModo == 2) {
      final actual = seg!;
      clave = 'historial_${emisora.carpeta}';
      contenido = ValueListenableBuilder<List<EntradaHistorial>>(
        valueListenable: repro.historial,
        builder: (_, items, __) {
          final recientes = items
              .where((h) => h.carpeta == emisora.carpeta)
              .where((h) => !(h.titulo == actual.titulo && h.tipo == actual.tipo))
              .take(6)
              .toList();
          return _ListaDesplegableGTA(
            key: ValueKey(clave),
            textoVacio: _t('recent_tracks'),
            items: [
              for (final h in recientes)
                _ItemListaGTA(
                  hora: _hora(h.horaMs),
                  titulo: h.titulo,
                  tipo: h.tipo,
                ),
            ],
          );
        },
      );
    } else {
      final actual = seg!;
      clave = 'directo';
      contenido = Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(_iconoTipo(actual.tipo), size: 16, color: color),
              const SizedBox(width: 6),
              Text(
                _etiquetaTipo(actual.tipo).toUpperCase(),
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(width: 14),
              _InsigniaDirecto(repro: repro),
            ],
          ),
          const SizedBox(height: 16),
          ValueListenableBuilder<bool>(
            valueListenable: repro.sonando,
            builder: (_, sonando, __) => IconButton.filled(
              iconSize: 40,
              padding: const EdgeInsets.all(18),
              style: IconButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.black,
              ),
              tooltip: sonando ? _t('pause_tooltip') : _t('resume_tooltip'),
              icon: Icon(sonando ? Icons.pause : Icons.play_arrow),
              onPressed: sonando ? repro.pause : repro.play,
            ),
          ),
          const SizedBox(height: 6),
        ],
      );
    }

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 240),
      reverseDuration: const Duration(milliseconds: 180),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      layoutBuilder: (currentChild, previousChildren) => Stack(
        fit: StackFit.expand,
        alignment: Alignment.center,
        children: [
          ...previousChildren,
          if (currentChild != null) currentChild,
        ],
      ),
      transitionBuilder: (child, anim) => FadeTransition(
        opacity: anim,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 0.06),
            end: Offset.zero,
          ).animate(anim),
          child: child,
        ),
      ),
      child: KeyedSubtree(
        key: ValueKey(clave),
        child: contenido,
      ),
    );
  }
}

class _ItemListaGTA {
  final String hora;
  final String titulo;
  final String tipo;

  const _ItemListaGTA({
    required this.hora,
    required this.titulo,
    required this.tipo,
  });
}

class _ListaDesplegableGTA extends StatelessWidget {
  final List<_ItemListaGTA> items;
  final String? textoVacio;

  const _ListaDesplegableGTA({
    super.key,
    required this.items,
    this.textoVacio,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 380),
      curve: Curves.easeOutCubic,
      builder: (context, t, _) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.06 * t),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.12 * t),
            ),
          ),
          child: items.isEmpty
              ? Center(
            child: Opacity(
              opacity: t,
              child: Text(
                textoVacio ?? '',
                style: const TextStyle(color: Colors.white54),
              ),
            ),
          )
              : ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            itemCount: items.length,
            itemBuilder: (_, idx) {
              final item = items[idx];
              final inicio = (idx * 0.09).clamp(0.0, 0.45);
              final itemT = ((t - inicio) / (1.0 - inicio)).clamp(0.0, 1.0);
              final curva = Curves.easeOutCubic.transform(itemT);
              return Opacity(
                opacity: curva,
                child: Transform.translate(
                  offset: Offset(0, (1.0 - curva) * 14),
                  child: ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    leading: Text(
                      item.hora,
                      style: const TextStyle(
                        color: Colors.white60,
                        fontWeight: FontWeight.w700,
                        fontFeatures: [FontFeature.tabularFigures()],
                      ),
                    ),
                    title: Text(
                      item.titulo.toUpperCase(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                    trailing: Icon(
                      _iconoTipo(item.tipo),
                      color: Colors.white70,
                      size: 18,
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Dial radial interactivo estilo GTA
// ---------------------------------------------------------------------------

class PantallaDialGTA extends StatefulWidget {
  final List<Emisora> emisoras;
  const PantallaDialGTA({super.key, required this.emisoras});

  @override
  State<PantallaDialGTA> createState() => _PantallaDialGTAState();
}

class _PantallaDialGTAState extends State<PantallaDialGTA> {
  final repro = radio;
  late int _indice;
  Timer? _relojTick;

  @override
  void initState() {
    super.initState();
    _indice = _indiceInicial();
    _relojTick = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  int _indiceInicial() {
    if (widget.emisoras.isEmpty) return 0;
    final actual = repro.emisoraActual.value;
    if (actual != null) {
      final idx = widget.emisoras.indexWhere((e) => e.carpeta == actual.carpeta);
      if (idx >= 0) return idx;
    }
    return 0;
  }

  @override
  void dispose() {
    _relojTick?.cancel();
    super.dispose();
  }

  Emisora get _enfocada =>
      widget.emisoras[_indice.clamp(0, widget.emisoras.length - 1)];

  void _seleccionar(int i) {
    if (widget.emisoras.isEmpty) return;
    final destino = i.clamp(0, widget.emisoras.length - 1);
    final e = widget.emisoras[destino];
    setState(() => _indice = destino);
    if (repro.emisoraActual.value?.carpeta != e.carpeta ||
        !repro.sonando.value) {
      repro.sintonizar(e);
    }
  }

  void _actualizarDesdeToque(
      Offset localPos,
      double centro,
      double radioAnillo,
      double radioNodo,
      ) {
    final total = widget.emisoras.length;
    if (total == 0) return;
    final dx = localPos.dx - centro;
    final dy = localPos.dy - centro;
    final dist = sqrt(dx * dx + dy * dy);

    // Ignora el arrastre si el dedo está sobre el botón central
    if (dist < radioAnillo - radioNodo * 1.15) return;

    // Ángulo desde las 12 en punto (-pi/2) en sentido horario [0, 2*pi)
    var angulo = atan2(dy, dx) + pi / 2;
    if (angulo < 0) angulo += 2 * pi;

    final paso = (2 * pi) / total;
    final idx = ((angulo + paso / 2) ~/ paso) % total;
    if (idx != _indice ||
        repro.emisoraActual.value?.carpeta != widget.emisoras[idx].carpeta) {
      _seleccionar(idx);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.emisoras.isEmpty) {
      return Scaffold(
        backgroundColor: Colors.black.withValues(alpha: 0.9),
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          leading: IconButton(
            icon: const Icon(Icons.close, color: Colors.white),
            tooltip: _t('close_tooltip'),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
      );
    }

    final e = _enfocada;
    final color = _colorEmisora(e.nombre);
    final total = widget.emisoras.length;

    return ValueListenableBuilder<Segmento?>(
      valueListenable: repro.actual,
      builder: (context, segRepro, _) {
        final apagada = segRepro == null;
        final seg = repro.segmentoEnVivo(e);
        final partes = seg == null ? null : _separarTitulo(seg);

        return Scaffold(
          backgroundColor: Colors.transparent,
          body: Stack(
            fit: StackFit.expand,
            children: [
              // Fondo translúcido compatible con PageRouteBuilder(opaque: false)
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: const Alignment(0, -0.15),
                    radius: 1.1,
                    colors: [
                      color.withValues(alpha: apagada ? 0.22 : 0.45),
                      const Color(0xEA09090E),
                      const Color(0xF7000000),
                    ],
                  ),
                ),
              ),
              SafeArea(
                child: Column(
                  children: [
                    // Barra superior: cerrar dial, título y apagar/encender
                    Padding(
                      padding: const EdgeInsets.fromLTRB(12, 8, 16, 4),
                      child: Row(
                        children: [
                          IconButton(
                            tooltip: _t('close_tooltip'),
                            icon: const Icon(
                              Icons.close,
                              color: Colors.white,
                              size: 28,
                            ),
                            onPressed: () => Navigator.of(context).pop(),
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              _t('dial_mode_tooltip').toUpperCase(),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 13,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1.3,
                              ),
                            ),
                          ),
                          InkWell(
                            borderRadius: BorderRadius.circular(20),
                            onTap: () {
                              if (apagada) {
                                repro.sintonizar(e);
                              } else {
                                repro.detener();
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 7,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: Colors.white24),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    apagada
                                        ? Icons.power_settings_new
                                        : Icons.volume_off,
                                    size: 16,
                                    color: Colors.white,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    apagada
                                        ? _t('live_upper')
                                        : _t('turn_off'),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w800,
                                      fontSize: 12,
                                      letterSpacing: 1.0,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Dial radial interactivo (toque o arrastre circular)
                    Expanded(
                      child: Center(
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            final lado = min(
                              constraints.maxWidth,
                              constraints.maxHeight,
                            ).clamp(240.0, 380.0);
                            final centro = lado / 2;
                            final radioNodo = total <= 6
                                ? 32.0
                                : (lado * 0.42 / total).clamp(20.0, 30.0);
                            final radioAnillo = centro - radioNodo - 12;

                            return GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onPanStart: (d) => _actualizarDesdeToque(
                                d.localPosition,
                                centro,
                                radioAnillo,
                                radioNodo,
                              ),
                              onPanUpdate: (d) => _actualizarDesdeToque(
                                d.localPosition,
                                centro,
                                radioAnillo,
                                radioNodo,
                              ),
                              child: SizedBox(
                                width: lado,
                                height: lado,
                                child: Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    Container(
                                      width: radioAnillo * 2,
                                      height: radioAnillo * 2,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: Colors.white
                                              .withValues(alpha: 0.14),
                                          width: 2,
                                        ),
                                      ),
                                    ),

                                    // Botón central: apagar/encender radio
                                    GestureDetector(
                                      onTap: () {
                                        if (apagada) {
                                          repro.sintonizar(e);
                                        } else {
                                          repro.detener();
                                        }
                                      },
                                      child: AnimatedContainer(
                                        duration:
                                        const Duration(milliseconds: 220),
                                        width: radioAnillo * 0.72,
                                        height: radioAnillo * 0.72,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: apagada
                                              ? Colors.white
                                              .withValues(alpha: 0.14)
                                              : Colors.black
                                              .withValues(alpha: 0.65),
                                          border: Border.all(
                                            color: apagada
                                                ? Colors.white54
                                                : color,
                                            width: 2.5,
                                          ),
                                          boxShadow: [
                                            if (!apagada)
                                              BoxShadow(
                                                color: color.withValues(
                                                    alpha: 0.35),
                                                blurRadius: 18,
                                              ),
                                          ],
                                        ),
                                        child: Column(
                                          mainAxisAlignment:
                                          MainAxisAlignment.center,
                                          children: [
                                            Icon(
                                              apagada
                                                  ? Icons.power_settings_new
                                                  : Icons.radio,
                                              color: Colors.white,
                                              size: 26,
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              apagada
                                                  ? 'OFF'
                                                  : '${_indice + 1}/$total',
                                              style: const TextStyle(
                                                color: Colors.white70,
                                                fontSize: 11,
                                                fontWeight: FontWeight.w900,
                                                letterSpacing: 0.8,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),

                                    // Emisoras en círculo
                                    for (var i = 0; i < total; i++)
                                      _construirNodoEmisora(
                                        indice: i,
                                        total: total,
                                        centro: centro,
                                        radioAnillo: radioAnillo,
                                        radioNodo: radioNodo,
                                        apagada: apagada,
                                      ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),

                    // Metadatos en directo y controles de reproducción
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 4, 24, 20),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            e.nombre.toUpperCase(),
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.2,
                            ),
                          ),
                          const SizedBox(height: 6),
                          if (apagada || seg == null || partes == null)
                            Text(
                              _t('radio_off'),
                              style: const TextStyle(
                                color: Colors.white60,
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1.0,
                              ),
                            )
                          else ...[
                            Text(
                              partes.titulo.toUpperCase(),
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14.5,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.7,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              (partes.artista ?? _etiquetaTipo(seg.tipo))
                                  .toUpperCase(),
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 12.5,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.8,
                              ),
                            ),
                            const SizedBox(height: 10),
                            _InsigniaDirecto(repro: repro),
                            const SizedBox(height: 10),
                            _ProgresoPista(
                              repro: repro,
                              seg: seg,
                              color: Colors.white,
                            ),
                            const SizedBox(height: 10),
                            ValueListenableBuilder<bool>(
                              valueListenable: repro.sonando,
                              builder: (_, sonando, __) => IconButton.filled(
                                iconSize: 34,
                                padding: const EdgeInsets.all(14),
                                style: IconButton.styleFrom(
                                  backgroundColor: Colors.white,
                                  foregroundColor: Colors.black,
                                ),
                                tooltip: sonando
                                    ? _t('pause_tooltip')
                                    : _t('resume_tooltip'),
                                icon: Icon(
                                  sonando ? Icons.pause : Icons.play_arrow,
                                ),
                                onPressed:
                                sonando ? repro.pause : repro.play,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _construirNodoEmisora({
    required int indice,
    required int total,
    required double centro,
    required double radioAnillo,
    required double radioNodo,
    required bool apagada,
  }) {
    final item = widget.emisoras[indice];
    final enfocada = indice == _indice;
    final activa = enfocada && !apagada;
    final cItem = _colorEmisora(item.nombre);

    final angulo = -pi / 2 + (2 * pi * indice) / total;
    final x = centro + radioAnillo * cos(angulo) - radioNodo;
    final y = centro + radioAnillo * sin(angulo) - radioNodo;

    return Positioned(
      left: x,
      top: y,
      child: GestureDetector(
        onTap: () => _seleccionar(indice),
        child: AnimatedScale(
          scale: enfocada ? 1.18 : 0.92,
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          child: AnimatedOpacity(
            opacity: enfocada ? 1.0 : 0.65,
            duration: const Duration(milliseconds: 180),
            child: Container(
              width: radioNodo * 2,
              height: radioNodo * 2,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: cItem,
                border: Border.all(
                  color: activa
                      ? Colors.white
                      : (enfocada ? Colors.white70 : Colors.white24),
                  width: activa ? 3.2 : 1.5,
                ),
                boxShadow: activa
                    ? [
                  BoxShadow(
                    color: cItem.withValues(alpha: 0.7),
                    blurRadius: 16,
                    spreadRadius: 2,
                  ),
                ]
                    : null,
              ),
              child: ClipOval(
                child: item.logo != null
                    ? Image.file(
                  File(item.logo!),
                  fit: BoxFit.cover,
                  cacheWidth: (radioNodo * 6).round(),
                  errorBuilder: (_, __, ___) =>
                      _CaratulaFallbackGTA(nombre: item.nombre),
                )
                    : _CaratulaFallbackGTA(nombre: item.nombre),
              ),
            ),
          ),
        ),
      ),
    );
  }
}