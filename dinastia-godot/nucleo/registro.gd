extends Node
## (Sin `class_name`: autoload `Registro`, el primero de la lista para oír
## también los fallos de carga de los demás autoloads.)
## EL REGISTRO DE FALLOS DEL JUGADOR (26-10-2026, plan §10). En el ordenador de
## otro nadie ve la consola: sin un registro, un fallo en hardware ajeno no se
## puede arreglar. Este autoload engancha un `Logger` del motor (Godot ≥ 4.5),
## así recoge TODO `push_error`/`push_warning` -los del juego, los de
## `PartidaArchivo`/`Partida` al leer una partida dañada, los de una escena que
## no carga, los de scripts y shaders- sin tocar cada sitio donde se detectan.
##
## - Escribe `user://registro.txt`; al pasar de `TAMANO_MAX` rota a
##   `registro.1.txt` y `registro.2.txt` (3 archivos, ~768 KB como mucho).
## - Solo errores y avisos: los `print` normales no se guardan.
## - SIN DATOS PERSONALES (idea 1097): las rutas absolutas se reescriben a
##   `user://`, `res://` o `~`, y el nombre de usuario del SO se tacha. No
##   sale nada de la máquina: el jugador copia el informe si quiere.
## - Un fallo que se repite en cada fotograma no llena el disco: las líneas
##   iguales seguidas se cuentan, y hay un tope de líneas por sesión.

const RUTA := "user://registro.txt"
const TAMANO_MAX := 256 * 1024
const ARCHIVOS := 3
const TOPE_SESION := 4000
const LINEAS_INFORME := 200
## M-430 (28-10-2026): ADÓNDE SE MANDA EL INFORME. Lo pone el dueño (el mismo correo que la política de privacidad);
## mientras esté vacío, el juego dice que el contacto llegará con la versión publicada.
const CONTACTO := ""

## Errores (ERROR, SCRIPT, SHADER) que dejó la sesión ANTERIOR: al arrancar, la pantalla principal ofrece copiar el informe.
var errores_previos := 0

var _registrador: _Registrador
var _cerrojo := Mutex.new()
var _ultima := ""
var _repetida := 0
var _escritas := 0
## Sustituciones para quitar rutas y nombre de usuario: [buscar, poner].
var _limpiezas: Array = []

func _init() -> void:
	_preparar_limpiezas()
	errores_previos = _contar_errores_ultima_sesion()
	_escribir_linea(_cabecera_sesion())
	_registrador = _Registrador.new()
	_registrador.dueno = self
	OS.add_logger(_registrador)

func _exit_tree() -> void:
	if _registrador != null:
		OS.remove_logger(_registrador)
		_registrador = null
	_soltar_repetida()

## Para apuntar a mano algo que no es un error del motor (p. ej. «la partida
## se abrió desde la copia de respaldo»).
func nota(texto: String) -> void:
	apuntar("NOTA", texto)

func apuntar(tipo: String, texto: String) -> void:
	_cerrojo.lock()
	var limpio := limpiar(texto.strip_edges())
	if limpio == _ultima:
		_repetida += 1
	else:
		_soltar_repetida()
		_ultima = limpio
		if _escritas < TOPE_SESION:
			_escritas += 1
			_escribir_linea("%s %s: %s" % [Time.get_time_string_from_system(), tipo, limpio])
			if _escritas == TOPE_SESION:
				_escribir_linea("(tope de %d líneas en esta sesión: el resto no se guarda)" % TOPE_SESION)
	_cerrojo.unlock()

## Diagnóstico de DESARROLLO (sondas que se encienden con variables de entorno
## como DEPURAR_TIROS): va a la consola con su etiqueta y NO al registro del
## jugador. Es el único `print` del código del juego: así hay un solo sitio donde
## silenciarlo o redirigirlo.
func depurar(tema: String, texto: String) -> void:
	print("[%s] %s" % [tema, texto])

## Quita de un texto lo que podría identificar al jugador.
func limpiar(texto: String) -> String:
	var r := texto
	for par: Array in _limpiezas:
		r = r.replace(String(par[0]), String(par[1]))
	return r

## Las últimas `n` líneas, del archivo más viejo al actual.
func ultimas(n: int = LINEAS_INFORME) -> PackedStringArray:
	_cerrojo.lock()
	_soltar_repetida()
	var todas := PackedStringArray()
	for i in range(ARCHIVOS - 1, -1, -1):
		var ruta := _ruta(i)
		if FileAccess.file_exists(ruta):
			for l: String in FileAccess.get_file_as_string(ruta).split("\n", false):
				todas.append(l)
	_cerrojo.unlock()
	return todas.slice(maxi(0, todas.size() - n))

## Lo que se copia al portapapeles: datos del sistema + últimas líneas.
func informe(n: int = LINEAS_INFORME) -> String:
	var partes := PackedStringArray(["INFORME DE FALLOS — DINASTÍA", datos_sistema()])
	if CONTACTO != "":
		partes.append("Mandar a: " + CONTACTO)
	partes.append("---")
	partes.append_array(ultimas(n))
	return "\n".join(partes)

func datos_sistema() -> String:
	var idioma := "?"
	var idiomas := get_node_or_null("/root/Idiomas")
	if idiomas != null:
		idioma = String(idiomas.get("idioma"))
	var ver := String(ProjectSettings.get_setting("application/config/version", ""))
	return "Juego %s (guardado v%d) · Godot %s · %s %s · %s · %s · idioma %s · %dx%d" % [
		ver if ver != "" else "dev", Partida.VERSION, Engine.get_version_info().get("string", "?"),
		OS.get_name(), OS.get_version(), _renderizador(), RenderingServer.get_video_adapter_name(),
		idioma, DisplayServer.window_get_size().x, DisplayServer.window_get_size().y]

func carpeta() -> String:
	return ProjectSettings.globalize_path("user://")

## En móvil y web no hay explorador de archivos que abrir.
func puede_abrir_carpeta() -> bool:
	return OS.has_feature("pc")

func abrir_carpeta() -> void:
	if puede_abrir_carpeta():
		OS.shell_open(carpeta())

## --- por dentro -------------------------------------------------------------

func _renderizador() -> String:
	var m := RenderingServer.get_current_rendering_method()
	return m if m != "" else String(ProjectSettings.get_setting("rendering/renderer/rendering_method", "?"))

func _cabecera_sesion() -> String:
	return "===== sesión %s · %s %s · Godot %s · %s" % [Time.get_datetime_string_from_system(),
		OS.get_name(), OS.get_version(), Engine.get_version_info().get("string", "?"),
		String(ProjectSettings.get_setting("rendering/renderer/rendering_method", "?"))]

func _preparar_limpiezas() -> void:
	## De la ruta más larga a la más corta: la carpeta de usuario cuelga de HOME.
	_limpiezas = [[ProjectSettings.globalize_path("user://").trim_suffix("/"), "user:/"]]
	var res := ProjectSettings.globalize_path("res://").trim_suffix("/")
	if res != "":
		_limpiezas.append([res, "res:/"])
	for v: String in ["HOME", "USERPROFILE"]:
		var h := OS.get_environment(v)
		if h.length() > 3:
			_limpiezas.append([h, "~"])
			_limpiezas.append([h.replace("\\", "/"), "~"])
	for v: String in ["USER", "USERNAME", "LOGNAME"]:
		var u := OS.get_environment(v)
		## Un nombre de 1-2 letras («pi») tacharía media palabra de cualquier mensaje.
		if u.length() > 2:
			_limpiezas.append([u, "<usuario>"])

## Cuenta los errores entre la última cabecera «===== sesión» del registro y el final (la sesión que acaba de cerrarse).
func _contar_errores_ultima_sesion(ruta := RUTA) -> int:
	if not FileAccess.file_exists(ruta):
		return 0
	var n := 0
	for l: String in FileAccess.get_file_as_string(ruta).split("\n", false):
		if l.begins_with("===== sesión"):
			n = 0
		elif l.contains(" ERROR: ") or l.contains(" SCRIPT: ") or l.contains(" SHADER: "):
			n += 1
	return n

func _soltar_repetida() -> void:
	if _repetida > 0:
		_escribir_linea("    (repetido %d veces más)" % _repetida)
		_repetida = 0

func _ruta(i: int) -> String:
	return RUTA if i == 0 else RUTA.replace(".txt", ".%d.txt" % i)

func _escribir_linea(linea: String) -> void:
	var f: FileAccess
	if FileAccess.file_exists(RUTA):
		f = FileAccess.open(RUTA, FileAccess.READ_WRITE)
		if f != null and f.get_length() + linea.length() > TAMANO_MAX:
			f.close()
			_rotar()
			f = FileAccess.open(RUTA, FileAccess.WRITE)
	else:
		f = FileAccess.open(RUTA, FileAccess.WRITE)
	if f == null:
		return
	f.seek_end()
	f.store_line(linea)
	f.close()

func _rotar() -> void:
	for i in range(ARCHIVOS - 1, 0, -1):
		var origen := ProjectSettings.globalize_path(_ruta(i - 1))
		if FileAccess.file_exists(_ruta(i - 1)):
			if FileAccess.file_exists(_ruta(i)):
				DirAccess.remove_absolute(ProjectSettings.globalize_path(_ruta(i)))
			DirAccess.rename_absolute(origen, ProjectSettings.globalize_path(_ruta(i)))

## El `Logger` del motor. Puede llamarse desde cualquier hilo: todo pasa por
## `apuntar()`, que va con cerrojo. Nunca hace `push_error` (sería un bucle).
class _Registrador extends Logger:
	var dueno: Node

	func _log_error(funcion: String, archivo: String, linea: int, codigo: String, motivo: String,
			_editor: bool, tipo: int, trazas: Array[ScriptBacktrace]) -> void:
		if dueno == null:
			return
		var nombre: String = ["ERROR", "AVISO", "SCRIPT", "SHADER"][clampi(tipo, 0, 3)]
		var texto := motivo if motivo != "" else codigo
		## Un `push_error` del juego dice dónde está en C++ (`variant_utility.cpp`):
		## lo útil es la línea del script que lo lanzó, la primera de la traza.
		var donde := "%s:%d %s" % [archivo.get_file(), linea, funcion]
		for t: ScriptBacktrace in trazas:
			if t != null and t.get_frame_count() > 0:
				donde = "%s:%d %s" % [t.get_frame_file(0).get_file(), t.get_frame_line(0), t.get_frame_function(0)]
				break
		dueno.apuntar(nombre, "%s  [%s]" % [texto, donde])

	func _log_message(_mensaje: String, _es_error: bool) -> void:
		pass
