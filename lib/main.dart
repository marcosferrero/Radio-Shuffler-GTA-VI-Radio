import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:ui' show FontFeature;

import 'package:audio_service/audio_service.dart';
import 'package:audio_session/audio_session.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
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
  final List<Segmento> segmentos;
  final String? logo; // ruta absoluta de la imagen, si la emisora tiene logotipo

  Emisora(this.nombre, this.carpeta, this.segmentos, {this.logo});

  factory Emisora.desdeJson(Map<String, dynamic> j, String carpeta) {
    final archivo = '$carpeta/${j['archivo']}';
    Duration d(num s) => Duration(milliseconds: (s * 1000).round());
    final segs = (j['segmentos'] as List)
        .map((s) => Segmento(
      archivo: archivo,
      inicio: d(s['inicio']),
      fin: d(s['fin']),
      tipo: s['tipo'] ?? 'cancion',
      titulo: s['titulo'] ?? 'Sin título',
    ))
        .toList();
    final nombreLogo = j['logo'];
    final rutaLogo = nombreLogo is String ? '$carpeta/$nombreLogo' : null;
    return Emisora(
      j['nombre'] ?? 'Emisora',
      carpeta,
      segs,
      logo: rutaLogo != null && File(rutaLogo).existsSync() ? rutaLogo : null,
    );
  }
}

class EntradaHistorial {
  final String emisora;
  final String carpeta;
  final String titulo;
  final String tipo;
  final int horaMs;

  const EntradaHistorial({
    required this.emisora,
    required this.carpeta,
    required this.titulo,
    required this.tipo,
    required this.horaMs,
  });

  Map<String, dynamic> toJson() => {
    'emisora': emisora,
    'carpeta': carpeta,
    'titulo': titulo,
    'tipo': tipo,
    'horaMs': horaMs,
  };

  factory EntradaHistorial.desdeJson(Map<String, dynamic> j) => EntradaHistorial(
    emisora: j['emisora'] ?? '',
    carpeta: j['carpeta'] ?? '',
    titulo: j['titulo'] ?? 'Sin título',
    tipo: j['tipo'] ?? 'cancion',
    horaMs: (j['horaMs'] as num?)?.toInt() ?? 0,
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

List<Map<String, dynamic>> segmentosDesdeLista(String texto, double totalSeg) {
  final marcas = <MapEntry<double, String>>[];
  for (final linea in texto.split('\n')) {
    final m = _reLinea.firstMatch(linea);
    if (m != null) marcas.add(MapEntry(_aSegundos(m.group(1)!), m.group(2)!));
  }
  marcas.sort((a, b) => a.key.compareTo(b.key));

  final segs = <Map<String, dynamic>>[];
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
// determinista (depende solo del nombre de la emisora y de la hora), así que
// en cualquier momento se sabe qué estaría sonando, aunque no la estés oyendo.
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

/// Duración mínima de cada bloque de programación (ms).
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

  Programacion(this.emisora) : _semilla = _hash(emisora.nombre);

  /// Un bloque son unas ~1 h de pistas: 2-3 canciones, luego un locutor/anuncio,
  /// sin repetir canción hasta agotarlas todas. Depende solo de (emisora, bloque).
  List<Segmento> _generarBloque(int b) {
    final rng = Random((_semilla * 31 + b * 7919 + 17) & 0x7FFFFFFF);
    final canciones = emisora.segmentos.where((s) => s.tipo == 'cancion').toList();
    final voces = emisora.segmentos.where((s) => s.tipo != 'cancion').toList();
    final base = canciones.isEmpty ? voces : canciones;

    final lista = <Segmento>[];
    var ronda = <Segmento>[];
    var total = 0;
    var seguidas = 0;
    var objetivo = 2 + rng.nextInt(2);
    Segmento? ultimaVoz;

    while ((total < _bloqueMs || lista.isEmpty) && lista.length < 500) {
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
      lista.add(s);
      total += max(1, _durMs(s));
    }
    return lista;
  }

  List<Segmento> _bloque(int b) {
    final existente = _bloques[b];
    if (existente != null) return existente;
    if (_bloques.length > 6) _bloques.clear();
    return _bloques[b] = _generarBloque(b);
  }

  Posicion _primera() => Posicion(0, 0, _bloque(0)[0], _epocaMs);

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
  Posicion en(int ahoraMs) {
    Posicion p = _cache ?? _primera();
    if (p.inicioMs > ahoraMs) p = _primera();
    while (true) {
      final n = siguiente(p);
      if (n.inicioMs > ahoraMs) break;
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

  // Dos reproductores: mientras uno termina, el otro empieza y se mezclan.
  // El audio session lo gestionamos nosotros (ver iniciarSesion).
  final AudioPlayer _a =
  AudioPlayer(handleInterruptions: false, handleAudioSessionActivation: false);
  final AudioPlayer _b =
  AudioPlayer(handleInterruptions: false, handleAudioSessionActivation: false);
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
    _publicar(pos.seg);
    sonando.value = true;
    _estado();
    _cur.play(); // sin await: el Future termina cuando se pausa o acaba
    _timer = Timer.periodic(const Duration(milliseconds: 50), (_) => _tick());
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
      historial.value = datos
          .whereType<Map<String, dynamic>>()
          .map(EntradaHistorial.desdeJson)
          .take(_maxHistorial)
          .toList();
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

  void _anotarHistorial(Segmento s) {
    final e = _emisora;
    if (e == null) return;
    final lista = historial.value;
    if (lista.isNotEmpty &&
        lista.first.carpeta == e.carpeta &&
        lista.first.titulo == s.titulo &&
        lista.first.tipo == s.tipo) {
      return;
    }
    final nueva = EntradaHistorial(
      emisora: e.nombre,
      carpeta: e.carpeta,
      titulo: s.titulo,
      tipo: s.tipo,
      horaMs: DateTime.now().millisecondsSinceEpoch,
    );
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
    _estado();
  }

  @override
  Future<void> pause() async {
    _pausadoEn ??= DateTime.now();
    sonando.value = false;
    await _cur.pause();
    if (_fundiendo) await _sig.pause();
    _estado();
  }

  @override
  Future<void> stop() => detener();

  // ----- Motor interno -----

  Future<void> _parar() async {
    _gen++;
    _timer?.cancel();
    _timer = null;
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
    final s = _posCur?.seg;
    if (s != null) _publicar(s);
    _prepararSiguiente();
  }

  void _tick() {
    final cur = _posCur?.seg;
    if (cur == null) return;

    if (_fundiendo) {
      // Mezcla de potencia constante; el progreso lo marca la posición de la nueva pista.
      final t = (_sig.position.inMilliseconds / _fadeMs).clamp(0.0, 1.0).toDouble();
      _cur.setVolume(cos(t * pi / 2));
      _sig.setVolume(sin(t * pi / 2));
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

  void _publicar(Segmento s) {
    actual.value = s;
    _anotarHistorial(s);
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
      key: ValueKey(lang),
      locale: Locale(lang),
      title: _t('app_title'),
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: Colors.pink,
        brightness: Brightness.dark,
        useMaterial3: true,
      ),
      home: const PantallaEmisoras(),
    ),
  );
}

class PantallaEmisoras extends StatefulWidget {
  const PantallaEmisoras({super.key});

  @override
  State<PantallaEmisoras> createState() => _PantallaEmisorasState();
}

class _PantallaEmisorasState extends State<PantallaEmisoras> {
  final repro = radio;
  List<Emisora> emisoras = [];
  bool cargando = true;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    setState(() => cargando = true);
    final dir = await carpetaRadios();
    final lista = <Emisora>[];
    await for (final e in dir.list()) {
      if (e is! Directory) continue;
      final json = File('${e.path}/radio.json');
      if (!await json.exists()) continue;
      try {
        lista.add(Emisora.desdeJson(jsonDecode(await json.readAsString()), e.path));
      } catch (_) {
        // radio.json mal formado: se ignora esa emisora
      }
    }
    lista.sort((a, b) => a.nombre.compareTo(b.nombre));
    setState(() {
      emisoras = lista;
      cargando = false;
    });
  }

  Future<void> _anadir() async {
    final creada = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => PantallaImportar(repro: repro)),
    );
    if (creada == true) _cargar();
  }

  Future<void> _editar(Emisora e) async {
    final guardado = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => PantallaEditar(emisora: e)),
    );
    if (guardado == true) _cargar();
  }

  /// Muestra un diálogo de espera mientras dura [tarea] (empaquetar/desempaquetar
  /// archivos grandes puede tardar) y enseña el error si falla.
  Future<bool> _conEspera(String texto, Future<void> Function() tarea) async {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => PopScope(
        canPop: false,
        child: AlertDialog(
          content: Row(children: [
            const CircularProgressIndicator(),
            const SizedBox(width: 20),
            Expanded(child: Text(texto)),
          ]),
        ),
      ),
    );
    try {
      await tarea();
      return true;
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
      return false;
    } finally {
      if (mounted) Navigator.of(context, rootNavigator: true).pop();
    }
  }

  Future<void> _exportar(Emisora e) async {
    await _conEspera(
      _t('preparing_radio', {'nombre': e.nombre}),
          () => exportarRadio(carpeta: e.carpeta, nombre: e.nombre),
    );
  }

  Future<void> _importarPaquete() async {
    // La extensión .gtaradio no tiene tipo MIME conocido: se deja elegir cualquier archivo
    // y es importarRadio quien valida que sea un paquete.
    final f = await FilePicker.pickFile();
    final ruta = f?.path;
    if (f == null || ruta == null || !mounted) return;
    final base = await carpetaRadios();
    final ok = await _conEspera(
      _t('importing_radio'),
          () async {
        await importarRadio(paquete: File(ruta), base: base);
        // La copia de la caché del selector ya no hace falta.
        try {
          await File(ruta).delete();
        } catch (_) {}
      },
    );
    if (ok) {
      await _cargar();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_t('radio_imported'))),
        );
      }
    }
  }

  Future<void> _borrar(Emisora e) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(_t('delete_radio_title', {'nombre': e.nombre})),
        content: Text(_t('delete_radio_body')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(_t('cancel'))),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: Text(_t('delete'))),
        ],
      ),
    );
    if (ok != true) return;
    await repro.olvidar(e.carpeta);
    await Directory(e.carpeta).delete(recursive: true);
    _cargar();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_t('radio_title')),
        actions: [
          PopupMenuButton<String>(
            tooltip: _t('language_tooltip'),
            icon: const Icon(Icons.language),
            onSelected: cambiarIdiomaApp,
            itemBuilder: (_) => [
              CheckedPopupMenuItem(
                value: 'es',
                checked: idiomaApp.value == 'es',
                child: Text(_t('lang_es')),
              ),
              CheckedPopupMenuItem(
                value: 'en',
                checked: idiomaApp.value == 'en',
                child: Text(_t('lang_en')),
              ),
            ],
          ),
          IconButton(
            tooltip: _t('import_package_tooltip'),
            icon: const Icon(Icons.file_download_outlined),
            onPressed: _importarPaquete,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _anadir,
        icon: const Icon(Icons.add),
        label: Text(_t('add_radio')),
      ),
      body: cargando
          ? const Center(child: CircularProgressIndicator())
          : emisoras.isEmpty
          ? Padding(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: Text(
            _t('no_stations'),
            textAlign: TextAlign.center,
          ),
        ),
      )
          : ListView.builder(
        padding: const EdgeInsets.only(bottom: 88),
        itemCount: emisoras.length,
        itemBuilder: (_, i) {
          final e = emisoras[i];
          return ListTile(
            leading: _LogoMini(ruta: e.logo, nombre: e.nombre, tam: 48),
            title: Text(e.nombre),
            subtitle: Text(_t('segments_count', {'n': '${e.segmentos.length}'})),
            onTap: () => repro.sintonizar(e),
            trailing: PopupMenuButton<String>(
              onSelected: (v) {
                if (v == 'editar') _editar(e);
                if (v == 'exportar') _exportar(e);
                if (v == 'borrar') _borrar(e);
              },
              itemBuilder: (_) => [
                PopupMenuItem(value: 'editar', child: Text(_t('edit_tracks'))),
                PopupMenuItem(value: 'exportar', child: Text(_t('export_radio'))),
                PopupMenuItem(value: 'borrar', child: Text(_t('delete_radio'))),
              ],
            ),
          );
        },
      ),
      bottomNavigationBar: _BarraReproduccion(repro: repro),
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
    final seguro = nombre.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_');
    final carpeta = Directory('${base.path}/$seguro');
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

      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (await carpeta.exists()) await carpeta.delete(recursive: true);
      if (mounted) _aviso(_t('error_prefix', {'err': '$e'}));
    } finally {
      if (mounted) setState(() => _trabajando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_t('add_radio'))),
      body: AbsorbPointer(
        absorbing: _trabajando,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextField(
              controller: _nombre,
              decoration: InputDecoration(
                labelText: _t('station_name_label'),
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: _elegirArchivo,
              icon: const Icon(Icons.video_file),
              label: Text(_archivo == null ? _t('pick_media') : _nombreArchivo),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                if (_logo != null) ...[
                  _LogoMini(ruta: _logo!.path, nombre: _nombre.text, tam: 48),
                  const SizedBox(width: 12),
                ],
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _elegirLogo,
                    icon: const Icon(Icons.image),
                    label: Text(_logo == null
                        ? _t('pick_logo')
                        : _t('change_logo')),
                  ),
                ),
                if (_logo != null)
                  IconButton(
                    tooltip: _t('remove_logo'),
                    icon: const Icon(Icons.close),
                    onPressed: () => setState(() => _logo = null),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _pistas,
              minLines: 8,
              maxLines: 14,
              decoration: InputDecoration(
                labelText: _t('tracklist_label'),
                hintText: _t('tracklist_hint'),
                helperText: _t('tracklist_helper'),
                helperMaxLines: 2,
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _importar,
              child: Text(_t('import_btn')),
            ),
            if (_trabajando) ...[
              const SizedBox(height: 24),
              const Center(child: CircularProgressIndicator()),
              const SizedBox(height: 12),
              Text(
                _t('working_long_file'),
                textAlign: TextAlign.center,
              ),
            ],
          ],
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

const _nombresTipo = {'cancion': 'Canción', 'locutor': 'Locutor', 'anuncio': 'Anuncio'};

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
  late final String _archivo = widget.emisora.segmentos.first.archivo;
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
    return PopScope(
      canPop: !_cambios,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final salir = await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            title: Text(_t('discard_changes_title')),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(_t('keep_editing')),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text(_t('discard')),
              ),
            ],
          ),
        );
        if (salir == true && mounted) Navigator.pop(context);
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(_t('edit_tracks')),
          actions: [
            IconButton(
              icon: const Icon(Icons.check),
              tooltip: _t('save_tooltip'),
              onPressed: _cambios ? _guardar : null,
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: _anadir,
          icon: const Icon(Icons.add),
          label: Text(_t('add_track')),
        ),
        body: ListView.builder(
          padding: const EdgeInsets.only(bottom: 88),
          itemCount: _segs.length + 1,
          itemBuilder: (_, i) {
            if (i == 0) {
              return Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        _LogoMini(
                          ruta: _logoVista,
                          nombre: widget.emisora.nombre,
                          tam: 72,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Wrap(
                            spacing: 8,
                            children: [
                              OutlinedButton.icon(
                                onPressed: _cambiarLogo,
                                icon: const Icon(Icons.image),
                                label: Text(_logoVista == null
                                    ? _t('pick_logo').replaceAll(' (opcional)', '')
                                    : _t('change_logo')),
                              ),
                              if (_logoVista != null)
                                TextButton(
                                  onPressed: _quitarLogo,
                                  child: Text(_t('remove')),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _nombre,
                      onChanged: (_) {
                        if (!_cambios) setState(() => _cambios = true);
                      },
                      decoration: InputDecoration(
                        labelText: _t('station_name_label'),
                        border: const OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _total == null
                          ? _t('tracks_count', {'n': '${_segs.length}'})
                          : _t('tracks_and_duration', {
                        'n': '${_segs.length}',
                        'dur': _fmt(_total!),
                      }),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              );
            }
            final idx = i - 1;
            final s = _segs[idx];
            return ListTile(
              leading: Icon(_iconoTipo(s.tipo)),
              title: Text(s.titulo, maxLines: 1, overflow: TextOverflow.ellipsis),
              subtitle: Text('${_fmt(s.inicio)} – ${_fmt(s.fin)} · ${_fmt(s.fin - s.inicio)}'),
              trailing: IconButton(
                icon: const Icon(Icons.delete_outline),
                tooltip: _t('delete'),
                onPressed: () => _borrarPista(idx),
              ),
              onTap: () => _editarPista(idx),
            );
          },
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
      title: Text(widget.inicial == null ? _t('new_track') : _t('edit_track')),
      scrollable: true,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _titulo,
            decoration: InputDecoration(labelText: _t('title_label')),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            children: [
              for (final e in _nombresTipo.entries)
                ChoiceChip(
                  label: Text(_etiquetaTipo(e.key)),
                  selected: _tipo == e.key,
                  onSelected: (_) => setState(() => _tipo = e.key),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _ini,
                  keyboardType: TextInputType.datetime,
                  decoration: InputDecoration(labelText: _t('start_label'), hintText: '3:41'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _fin,
                  keyboardType: TextInputType.datetime,
                  decoration: InputDecoration(labelText: _t('end_label'), hintText: '7:05'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              TextButton.icon(
                onPressed: _oirInicio,
                icon: const Icon(Icons.play_arrow),
                label: Text(_t('listen_start')),
              ),
              TextButton.icon(
                onPressed: _oirFinal,
                icon: const Icon(Icons.play_arrow),
                label: Text(_t('listen_end')),
              ),
            ],
          ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                _error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ),
        ],
      ),
      actions: [
        TextButton(onPressed: _cancelar, child: Text(_t('cancel'))),
        FilledButton(onPressed: _aceptar, child: Text(_t('accept'))),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Pantalla de reproducción
// ---------------------------------------------------------------------------

/// Abre la pantalla de reproducción deslizándola desde abajo.
Future<void> abrirReproduccion(BuildContext context) {
  return Navigator.of(context).push(PageRouteBuilder<void>(
    transitionDuration: const Duration(milliseconds: 300),
    reverseTransitionDuration: const Duration(milliseconds: 250),
    pageBuilder: (_, __, ___) => const PantallaReproduccion(),
    transitionsBuilder: (_, anim, __, child) => SlideTransition(
      position: Tween(begin: const Offset(0, 1), end: Offset.zero).animate(
        CurvedAnimation(
          parent: anim,
          curve: Curves.easeOutCubic,
          reverseCurve: Curves.easeInCubic,
        ),
      ),
      child: child,
    ),
  ));
}

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

class PantallaReproduccion extends StatelessWidget {
  const PantallaReproduccion({super.key});

  @override
  Widget build(BuildContext context) {
    final repro = radio;
    final cs = Theme.of(context).colorScheme;

    return ValueListenableBuilder<Segmento?>(
      valueListenable: repro.actual,
      builder: (context, seg, _) {
        // La radio se detuvo (por ejemplo desde la notificación): se cierra sola.
        if (seg == null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (context.mounted && ModalRoute.of(context)?.isCurrent == true) {
              Navigator.of(context).pop();
            }
          });
          return const Scaffold();
        }

        final emisora = repro.emisoraActual.value;
        final nombre = emisora?.nombre ?? '';
        final color = _colorEmisora(nombre);
        final fondo = Color.alphaBlend(color.withValues(alpha: 0.16), cs.surface);
        final proximas = repro.proximas(6);

        return Scaffold(
          backgroundColor: fondo,
          appBar: AppBar(
            backgroundColor: fondo,
            surfaceTintColor: Colors.transparent,
            leading: IconButton(
              icon: const Icon(Icons.keyboard_arrow_down, size: 32),
              tooltip: _t('close_tooltip'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            centerTitle: true,
            title: Text(nombre, maxLines: 1, overflow: TextOverflow.ellipsis),
          ),
          body: SafeArea(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
              children: [
                Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 300),
                    child: AspectRatio(
                      aspectRatio: 1,
                      child: _Portada(
                        nombre: nombre,
                        tipo: seg.tipo,
                        color: color,
                        logo: emisora?.logo,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 28),
                Wrap(
                  alignment: WrapAlignment.center,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 16,
                  runSpacing: 4,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(_iconoTipo(seg.tipo), size: 18, color: color),
                        const SizedBox(width: 6),
                        Text(
                          _etiquetaTipo(seg.tipo),
                          style: Theme.of(context).textTheme.labelLarge,
                        ),
                      ],
                    ),
                    _InsigniaDirecto(repro: repro),
                  ],
                ),
                const SizedBox(height: 12),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: _TituloPista(key: ValueKey(seg), seg: seg),
                ),
                const SizedBox(height: 24),
                _ProgresoPista(repro: repro, seg: seg, color: color),
                const SizedBox(height: 20),
                Center(
                  child: ValueListenableBuilder<bool>(
                    valueListenable: repro.sonando,
                    builder: (_, sonando, __) => IconButton.filled(
                      iconSize: 44,
                      padding: const EdgeInsets.all(20),
                      style: IconButton.styleFrom(
                        backgroundColor: color,
                        foregroundColor: _sobre(color),
                      ),
                      tooltip: sonando ? _t('pause_tooltip') : _t('resume_tooltip'),
                      icon: Icon(sonando ? Icons.pause : Icons.play_arrow),
                      onPressed: sonando ? repro.pause : repro.play,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Center(
                  child: TextButton.icon(
                    onPressed: repro.detener,
                    icon: const Icon(Icons.stop),
                    label: Text(_t('stop_radio')),
                  ),
                ),
                const SizedBox(height: 24),
                Text(_t('up_next'), style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 4),
                for (final p in proximas)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Text(
                      _hora(p.inicioMs),
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: cs.onSurfaceVariant,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                    title: Text(p.seg.titulo, maxLines: 1, overflow: TextOverflow.ellipsis),
                    trailing: Icon(_iconoTipo(p.seg.tipo), size: 20),
                  ),
                ValueListenableBuilder<List<EntradaHistorial>>(
                  valueListenable: repro.historial,
                  builder: (context, items, _) {
                    final carpetaActual = emisora?.carpeta;
                    final recientes = items
                        .where((h) => carpetaActual == null || h.carpeta == carpetaActual)
                        .where((h) => !(h.titulo == seg.titulo && h.tipo == seg.tipo))
                        .take(8)
                        .toList();
                    if (recientes.isEmpty) return const SizedBox.shrink();

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _t('recent_tracks'),
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            TextButton(
                              onPressed: () => repro.limpiarHistorial(carpetaActual),
                              child: Text(_t('clear_btn')),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        for (final h in recientes)
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: Text(
                              _hora(h.horaMs),
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                color: cs.onSurfaceVariant,
                                fontFeatures: const [FontFeature.tabularFigures()],
                              ),
                            ),
                            title: Text(
                              h.titulo,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            trailing: Icon(_iconoTipo(h.tipo), size: 20),
                          ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Logotipo grande de la emisora. Sin imagen: cuadrado de color con su nombre.
class _Portada extends StatelessWidget {
  final String nombre;
  final String tipo;
  final Color color;
  final String? logo;
  const _Portada({
    required this.nombre,
    required this.tipo,
    required this.color,
    this.logo,
  });

  Widget _rotulo() {
    final texto = _sobre(color);
    return Container(
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
      ),
      padding: const EdgeInsets.all(20),
      child: Stack(
        children: [
          Center(
            child: Text(
              nombre,
              textAlign: TextAlign.center,
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: texto,
                fontSize: 36,
                fontWeight: FontWeight.w800,
                height: 1.05,
              ),
            ),
          ),
          Positioned(
            right: 0,
            bottom: 0,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: Icon(_iconoTipo(tipo), key: ValueKey(tipo), color: texto, size: 28),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final rotulo = _rotulo();
    if (logo == null) return rotulo;
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: Image.file(
        File(logo!),
        fit: BoxFit.cover,
        cacheWidth: 900,
        errorBuilder: (_, __, ___) => rotulo,
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

class _TituloPista extends StatelessWidget {
  final Segmento seg;
  const _TituloPista({super.key, required this.seg});

  @override
  Widget build(BuildContext context) {
    final partes = _separarTitulo(seg);
    final tema = Theme.of(context).textTheme;
    return Column(
      children: [
        Text(
          partes.titulo,
          textAlign: TextAlign.center,
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
          style: tema.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
        if (partes.artista != null)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              partes.artista!,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: tema.titleMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
      ],
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
// Barra inferior de reproducción
// ---------------------------------------------------------------------------

class _BarraReproduccion extends StatelessWidget {
  final Reproductor repro;
  const _BarraReproduccion({required this.repro});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Segmento?>(
      valueListenable: repro.actual,
      builder: (_, seg, __) {
        if (seg == null) return const SizedBox.shrink();
        return SafeArea(
          child: ListTile(
            tileColor: Theme.of(context).colorScheme.surfaceContainerHigh,
            onTap: () => abrirReproduccion(context),
            leading: Icon(_iconoTipo(seg.tipo)),
            title: Text(seg.titulo, maxLines: 1, overflow: TextOverflow.ellipsis),
            subtitle: Text('${repro.emisoraActual.value?.nombre ?? ''} · ${_t('live_upper')}'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                ValueListenableBuilder<bool>(
                  valueListenable: repro.sonando,
                  builder: (_, sonando, __) => IconButton(
                    icon: Icon(sonando ? Icons.pause : Icons.play_arrow),
                    onPressed: sonando ? repro.pause : repro.play,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}