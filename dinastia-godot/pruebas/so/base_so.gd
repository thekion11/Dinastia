class_name BaseSO
extends BaseIdea
## BASE DE LAS PRUEBAS POR SISTEMA (5-11-2026, rama sonar/bancos). Cada prueba de `pruebas/so/` es independiente, corre sola y
## sabe EN QUÉ SISTEMA corre: en vez de saltarse lo que no aplica, comprueba la expectativa PROPIA de ese sistema
## (`por_so({...})`). Al final imprime un marcador uniforme, que lee el CI de plataformas (Windows/Web/Android) y `especiales.sh`:
##     OK <nombre> [<sistema>]        o        FALLO <nombre> [<sistema>]
## y además el «===== FIN. N fallos =====» de siempre. Una prueba nueva:
##     extends BaseSO
##     func _nombre() -> String: return "com_algo"
##     func _probar() -> void: _comprobar(cond, "texto")
## más una escena de dos líneas y su fila en `pruebas/so/LISTA.txt` (nombre|familia|sistemas|escena|requiere).
## El tiempo de fotograma NO se mide aquí (--headless tiene un suelo de 6,9 ms): solo recuentos (triángulos, llamadas, nodos, memoria).

## Nombre corto de la prueba (el del marcador y el de LISTA.txt).
func _nombre() -> String:
	return "sin_nombre"

func _ready() -> void:
	await get_tree().process_frame
	await _probar()
	print("")
	print("%s %s [%s]" % ["OK" if _fallos.is_empty() else "FALLO", _nombre(), sistema()])
	print("===== FIN. %d fallos =====" % _fallos.size())
	get_tree().quit(0 if _fallos.is_empty() else 1)

## windows · linux · macos · android · ios · web (lo que dice el motor; `OS.has_feature` en la exportación).
static func sistema() -> String:
	for f: String in ["web", "android", "ios", "windows", "macos", "linux"]:
		if OS.has_feature(f):
			return f
	return OS.get_name().to_lower()

static func es_movil() -> bool:
	return OS.has_feature("android") or OS.has_feature("ios")

## ¿El sistema distingue mayúsculas en los nombres de archivo? Windows y macOS (por defecto) no; Linux y Android sí.
static func rutas_con_mayusculas() -> bool:
	return not (OS.has_feature("windows") or OS.has_feature("macos"))

## El valor propio de este sistema: `por_so({"web": 1, "movil": 2, "defecto": 3})`. Claves: el sistema, «movil» o «defecto».
static func por_so(tabla: Dictionary) -> Variant:
	var s := sistema()
	if tabla.has(s):
		return tabla[s]
	if es_movil() and tabla.has("movil"):
		return tabla["movil"]
	return tabla.get("defecto", null)

## ¿Hay extensión C++ para este sistema? (`bin_nativo/dinastia.gdextension`: hoy Linux y Windows; Web, Android y macOS usan GDScript.)
static func se_espera_nativo() -> bool:
	return OS.has_feature("linux") or OS.has_feature("windows")

## Carpeta propia de la prueba dentro de `user://` (se vacía al empezar y al acabar; nunca toca las partidas del jugador).
func _carpeta_user() -> String:
	var ruta := "user://pruebas_so/%s" % _nombre()
	_borrar_carpeta(ruta)
	DirAccess.make_dir_recursive_absolute(ruta)
	return ruta

func _borrar_carpeta(ruta: String) -> void:
	var d := DirAccess.open(ruta)
	if d == null:
		return
	for f: String in d.get_files():
		d.remove(f)
	for s: String in d.get_directories():
		_borrar_carpeta(ruta.path_join(s))
		d.remove(s)
	DirAccess.remove_absolute(ruta)

func _frames(n: int = 3) -> void:
	for i in n:
		await get_tree().process_frame
