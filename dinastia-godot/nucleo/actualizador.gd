class_name Actualizador
extends Node
## EL ACTUALIZADOR DENTRO DEL JUEGO (4-11-2026, pedido del dueño). Ajustes → «Buscar actualización» consulta la API de Releases de GitHub (solo las PUBLICADAS:
## ni borradores ni prerrelease) con el nombre `parche-<versión>-<escritorio|android>`, la compara con `application/config/version` y, SI LA PERSONA LO ACEPTA, baja
## `parche_<versión>.pck` a `user://parches/` (el autoload `Parches` lo monta en el próximo arranque). Nada se baja ni se instala solo.
## Pasa por la red solo mientras la persona lo pide; envía nada propio (ni identificador, ni correo, ni versión): una petición GET normal con un nombre de cliente genérico.
## Nunca se cuelga: la consulta tiene un tiempo límite y la descarga se corta si deja de llegar un solo byte durante `ESPERA_SIN_DATOS` segundos; cada fallo trae un mensaje claro.
## La descarga se verifica (tamaño anunciado y, si la Release lo trae, SHA-256) antes de dejar el archivo con su nombre definitivo.
signal consultado(hay: bool, info: Dictionary, mensaje: String)
signal progreso(recibido: int, total: int)
signal descargado(ruta: String, info: Dictionary)
signal fallo(mensaje: String)

const REPO := "thekion11/Dinastia"
const CARPETA := "user://parches"
const PREFIJO_TAG := "parche-"
const ESPERA_CONSULTA := 12.0        ## segundos para toda la consulta
const ESPERA_SIN_DATOS := 15.0       ## segundos sin recibir ni un byte en la descarga
const CLIENTE := "Dinastia-Actualizador"

## Las pruebas lo apuntan a un servidor local; en el juego es la API de GitHub.
static var url_api := "https://api.github.com/repos/%s/releases?per_page=30" % REPO
static var espera_consulta := ESPERA_CONSULTA
static var espera_sin_datos := ESPERA_SIN_DATOS

var _http: HTTPRequest
var _estado := "libre"               ## libre · consultando · descargando
var _info: Dictionary = {}
var _tmp := ""
var _ultimo := -1
var _t_sin_datos := 0.0
var _t_consulta := 0.0

# ------------------------------------------------------------------ lógica pura

static func sistema() -> String:
	return "android" if OS.has_feature("android") else "escritorio"

static func version_actual() -> String:
	return String(ProjectSettings.get_setting("application/config/version", "0.0.0"))

## «v0.9.2» → [0, 9, 2]; lo que no es número se ignora en esa parte («0.9.2-beta» → [0, 9, 2]).
static func partes(v: String) -> Array[int]:
	var s := v.strip_edges().trim_prefix("v").trim_prefix("V")
	var out: Array[int] = []
	for trozo: String in s.split("."):
		var n := ""
		for c in trozo:
			if c >= "0" and c <= "9":
				n += c
			else:
				break
		out.append(int(n) if n != "" else 0)
	while out.size() < 3:
		out.append(0)
	return out

## -1 si a < b, 0 si iguales, 1 si a > b.
static func comparar(a: String, b: String) -> int:
	var pa := partes(a)
	var pb := partes(b)
	for i in maxi(pa.size(), pb.size()):
		var x := pa[i] if i < pa.size() else 0
		var y := pb[i] if i < pb.size() else 0
		if x != y:
			return -1 if x < y else 1
	return 0

## «parche-0.9.2-escritorio» → {version, sistema}; {} si no tiene esa forma.
static func leer_tag(tag: String) -> Dictionary:
	var re := RegEx.create_from_string("^parche-(\\d+(?:\\.\\d+){0,3}(?:-[a-z0-9]+)?)-(escritorio|android)$")
	var m := re.search(tag)
	if m == null:
		return {}
	return {"version": m.get_string(1), "sistema": m.get_string(2)}

static func nombre_archivo(version: String) -> String:
	return "parche_%s.pck" % version

static func ruta_destino(version: String) -> String:
	return CARPETA.path_join(nombre_archivo(version))

## La mejor Release: publicada (ni borrador ni prerrelease), de este sistema, más nueva que `actual` y con su `parche_<versión>.pck`.
## Devuelve {version, tag, url, tam, nombre, sha256, notas} o {} si no hay.
static func elegir(releases: Array, actual: String, sist: String) -> Dictionary:
	var mejor: Dictionary = {}
	for r: Variant in releases:
		if not (r is Dictionary):
			continue
		var rel: Dictionary = r
		if bool(rel.get("draft", false)) or bool(rel.get("prerelease", false)):
			continue
		var t := leer_tag(String(rel.get("tag_name", "")))
		if t.is_empty() or String(t["sistema"]) != sist or comparar(String(t["version"]), actual) <= 0:
			continue
		if not mejor.is_empty() and comparar(String(t["version"]), String(mejor["version"])) <= 0:
			continue
		var esperado := nombre_archivo(String(t["version"]))
		for a: Variant in rel.get("assets", []):
			if a is Dictionary and String((a as Dictionary).get("name", "")) == esperado and int((a as Dictionary).get("size", 0)) > 0 \
					and String((a as Dictionary).get("browser_download_url", "")).begins_with("http"):
				var sha := String((a as Dictionary).get("digest", ""))
				mejor = {"version": String(t["version"]), "tag": String(rel["tag_name"]), "url": String(a["browser_download_url"]), "tam": int(a["size"]),
					"nombre": esperado, "sha256": sha.trim_prefix("sha256:") if sha.begins_with("sha256:") else "", "notas": String(rel.get("body", "")).left(600)}
				break
	return mejor

## Un mensaje claro para cada manera de fallar.
static func mensaje_de(resultado: int, codigo: int) -> String:
	match resultado:
		HTTPRequest.RESULT_SUCCESS:
			if codigo == 403 or codigo == 429:
				return "GitHub limita las consultas por un rato. Prueba más tarde."
			if codigo == 404:
				return "No se encontró la página de actualizaciones."
			if codigo >= 500:
				return "El servidor de actualizaciones falló (%d). Prueba más tarde." % codigo
			return "El servidor respondió con un error (%d)." % codigo
		HTTPRequest.RESULT_CANT_RESOLVE, HTTPRequest.RESULT_CANT_CONNECT, HTTPRequest.RESULT_CONNECTION_ERROR, HTTPRequest.RESULT_NO_RESPONSE:
			return "No hay conexión con el servidor de actualizaciones."
		HTTPRequest.RESULT_TLS_HANDSHAKE_ERROR:
			return "No se pudo establecer una conexión segura."
		HTTPRequest.RESULT_TIMEOUT:
			return "El servidor tardó demasiado en responder."
		HTTPRequest.RESULT_DOWNLOAD_FILE_CANT_OPEN, HTTPRequest.RESULT_DOWNLOAD_FILE_WRITE_ERROR:
			return "No se pudo guardar el archivo descargado (¿falta espacio?)."
	return "No se pudo completar la descarga (error %d)." % resultado

# ------------------------------------------------------------------ red

func ocupado() -> bool:
	return _estado != "libre"

func _preparar() -> void:
	if _http != null and is_instance_valid(_http):
		_http.cancel_request()
		_http.queue_free()
	_http = HTTPRequest.new()
	add_child(_http)

func _cabeceras() -> PackedStringArray:
	return PackedStringArray(["User-Agent: " + CLIENTE, "Accept: application/vnd.github+json"])

## Pregunta qué Releases hay. Termina SIEMPRE con la señal `consultado` o con `fallo`.
func consultar() -> void:
	if ocupado():
		return
	_estado = "consultando"
	_t_consulta = 0.0
	_preparar()
	_http.timeout = espera_consulta
	_http.request_completed.connect(_al_consultar)
	var e := _http.request(url_api, _cabeceras())
	if e != OK:
		_terminar_con_fallo("No se pudo iniciar la consulta (error %d)." % e)

func _al_consultar(resultado: int, codigo: int, _cab: PackedStringArray, cuerpo: PackedByteArray) -> void:
	if _estado != "consultando":
		return
	if resultado != HTTPRequest.RESULT_SUCCESS or codigo != 200:
		_terminar_con_fallo(mensaje_de(resultado, codigo))
		return
	var json := JSON.new()   ## (con la instancia, un JSON roto no escribe errores en el registro)
	var datos: Variant = json.data if json.parse(cuerpo.get_string_from_utf8()) == OK else null
	if not (datos is Array):
		_terminar_con_fallo("La respuesta del servidor no se entiende.")
		return
	_estado = "libre"
	var info := elegir(datos, version_actual(), sistema())
	if info.is_empty():
		consultado.emit(false, {}, "Ya tienes la última versión (%s)." % version_actual())
	else:
		_info = info
		consultado.emit(true, info, "Hay una versión nueva: %s." % info["version"])

## Baja el parche de `info` (lo que dio `consultado`) a `user://parches/`. Termina con `descargado` o `fallo`.
func descargar(info: Dictionary) -> void:
	if ocupado() or info.is_empty():
		return
	DirAccess.make_dir_recursive_absolute(CARPETA)
	_info = info
	_tmp = ruta_destino(String(info["version"])) + ".descarga"
	if FileAccess.file_exists(_tmp):
		DirAccess.remove_absolute(_tmp)
	_estado = "descargando"
	_ultimo = -1
	_t_sin_datos = 0.0
	_preparar()
	_http.timeout = 0.0
	_http.download_file = _tmp
	_http.request_completed.connect(_al_descargar)
	var e := _http.request(String(info["url"]), PackedStringArray(["User-Agent: " + CLIENTE]))
	if e != OK:
		_terminar_con_fallo("No se pudo iniciar la descarga (error %d)." % e)

func _process(delta: float) -> void:
	if _estado == "descargando" and _http != null:
		var recibido := _http.get_downloaded_bytes()
		if recibido != _ultimo:
			_ultimo = recibido
			_t_sin_datos = 0.0
			progreso.emit(recibido, int(_info.get("tam", 0)))
		else:
			_t_sin_datos += delta
			if _t_sin_datos >= espera_sin_datos:
				_terminar_con_fallo("La descarga se quedó parada. Prueba de nuevo.")
	elif _estado == "consultando":
		_t_consulta += delta
		if _t_consulta >= espera_consulta + 3.0:   ## por si HTTPRequest no llega a avisar
			_terminar_con_fallo(mensaje_de(HTTPRequest.RESULT_TIMEOUT, 0))

func _al_descargar(resultado: int, codigo: int, _cab: PackedStringArray, _cuerpo: PackedByteArray) -> void:
	if _estado != "descargando":
		return
	if resultado != HTTPRequest.RESULT_SUCCESS or codigo != 200:
		_terminar_con_fallo(mensaje_de(resultado, codigo))
		return
	var f := FileAccess.open(_tmp, FileAccess.READ)
	var tam := f.get_length() if f != null else -1
	if f != null:
		f.close()
	progreso.emit(tam, int(_info.get("tam", 0)))   ## el último aviso: lo que llegó de verdad
	if tam != int(_info.get("tam", -2)):
		_terminar_con_fallo("El archivo descargado no tiene el tamaño esperado (%d de %d bytes)." % [tam, int(_info.get("tam", 0))])
		return
	var sha := String(_info.get("sha256", ""))
	if sha != "" and FileAccess.get_sha256(_tmp).to_lower() != sha.to_lower():
		_terminar_con_fallo("El archivo descargado no coincide con el publicado (SHA-256).")
		return
	var destino := ruta_destino(String(_info["version"]))
	if FileAccess.file_exists(destino):
		DirAccess.remove_absolute(destino)
	if DirAccess.rename_absolute(_tmp, destino) != OK:
		_terminar_con_fallo("No se pudo dejar el parche en su sitio.")
		return
	_estado = "libre"
	descargado.emit(destino, _info)

func _terminar_con_fallo(mensaje: String) -> void:
	if _http != null and is_instance_valid(_http):
		_http.cancel_request()
	if _tmp != "" and FileAccess.file_exists(_tmp):
		DirAccess.remove_absolute(_tmp)
	_estado = "libre"
	fallo.emit(mensaje)

func cancelar() -> void:
	if _http != null and is_instance_valid(_http):
		_http.cancel_request()
	if _tmp != "" and FileAccess.file_exists(_tmp):
		DirAccess.remove_absolute(_tmp)
	_estado = "libre"

func _exit_tree() -> void:
	cancelar()
