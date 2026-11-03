class_name CacheAudio
extends RefCounted
## CACHÉ EN DISCO DEL AUDIO SINTETIZADO (R5, 3-11, orden 22: «menos subprocesos innecesarios»). Los 215 sonidos y las 6 músicas se SINTETIZAN con código,
## y cada arranque los rehacía en dos hilos de fondo: medido en un solo hilo, **19 s de CPU los sonidos y 8 s la música** (en un teléfono, minutos de CPU
## compitiendo con el menú, la carga y los primeros partidos). Son deterministas (semilla fija), así que se guardan una vez en `user://cache_audio/` y los
## arranques siguientes los LEEN (47 MB, un segundo) en vez de volver a calcularlos.
##
## · La carpeta lleva la versión del juego y `GENERACION`: SUBIR `GENERACION` al cambiar una receta de sonido o una pieza de música.
## · Desactivada en el editor (para no ver sonidos viejos mientras se trabaja) y con DINASTIA_SIN_CACHE_AUDIO=1.
## · Si un archivo falta o está roto, no pasa nada: se sintetiza como siempre y se vuelve a guardar.

const GENERACION := 1
const MAGIA := "DAU1"

## Las pruebas apuntan a otra carpeta (y la encienden) para no tocar la caché real.
static var carpeta_prueba := ""

static func activa() -> bool:
	if OS.get_environment("DINASTIA_SIN_CACHE_AUDIO") != "":
		return false
	return carpeta_prueba != "" or not OS.has_feature("editor")

static func carpeta() -> String:
	if carpeta_prueba != "":
		return carpeta_prueba
	return "user://cache_audio/%s_g%d" % [str(ProjectSettings.get_setting("application/config/version", "0")).replace(".", "_"), GENERACION]

static func _ruta(clave: String) -> String:
	return "%s/%s.bin" % [carpeta(), clave.validate_filename()]

## Los sonidos guardados de `clave` (vacío si no hay o están rotos).
static func leer(clave: String) -> Array:
	var f := FileAccess.open(_ruta(clave), FileAccess.READ)
	if f == null:
		return []
	var bytes := f.get_buffer(f.get_length())
	if bytes.size() < 8 or bytes.slice(0, 4).get_string_from_ascii() != MAGIA:   ## un archivo ajeno o a medias: ni se intenta leer
		return []
	var datos: Variant = bytes_to_var(bytes.slice(4))
	if not (datos is Array):
		return []
	var out: Array = []
	for d: Variant in datos as Array:
		if not (d is Dictionary) or not (d as Dictionary).has("data"):
			return []
		var w := AudioStreamWAV.new()
		w.data = d["data"]
		w.format = int(d["format"])
		w.mix_rate = int(d["mix_rate"])
		w.stereo = bool(d["stereo"])
		w.loop_mode = int(d["loop_mode"])
		w.loop_begin = int(d["loop_begin"])
		w.loop_end = int(d["loop_end"])
		if w.data.is_empty():
			return []
		out.append(w)
	return out

static func escribir(clave: String, sonidos: Array) -> void:
	DirAccess.make_dir_recursive_absolute(carpeta())
	var lista: Array = []
	for s: Variant in sonidos:
		var w := s as AudioStreamWAV
		if w == null:
			return
		lista.append({"data": w.data, "format": w.format, "mix_rate": w.mix_rate, "stereo": w.stereo,
			"loop_mode": w.loop_mode, "loop_begin": w.loop_begin, "loop_end": w.loop_end})
	var f := FileAccess.open(_ruta(clave), FileAccess.WRITE)
	if f != null:
		f.store_buffer(MAGIA.to_ascii_buffer())
		f.store_buffer(var_to_bytes(lista))
