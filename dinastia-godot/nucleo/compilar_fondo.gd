class_name CompilarFondo
extends Node
## LOS SCRIPTS DEL JUEGO, COMPILADOS EN SEGUNDO PLANO (30-10-2026, arranque). Antes Godot compilaba
## los ~600 scripts ANTES de enseñar el menú (3,3 s del arranque exportado). Ahora el menú solo
## necesita ~30 (ver `inicio_pesado.gd`) y el resto se compila aquí, de uno en uno y en un hilo,
## mientras el jugador mira el menú: al abrir el estadio o la ciudad ya están listos (si no, se
## compilarían allí y la primera apertura tardaría ~1,5-2 s más, medido). Lo arranca `Inicio`.

const CARPETAS_FUERA := ["res://pruebas", "res://addons", "res://herramientas", "res://.godot"]

static var _hecho := false
static var _retenidos: Array[Resource] = []   ## que no se suelten de la caché

var _cola: PackedStringArray = PackedStringArray()
var _en_curso: PackedStringArray = PackedStringArray()
## DE UNO EN UNO Y NADA MÁS A LA VEZ, medido: con varias compilaciones simultáneas (4 aquí, o la
## escena de «Nuevo juego» en otro hilo) los scripts compilados junto a sus dependencias quedaban
## sin tipos resueltos y el código iba ~1,5× más lento (la ciudad, 4,1 → 5,6-6,4 s). Por eso la
## escena de entrada también pasa por esta cola, después de `inicio_pesado.gd`.
const EN_PARALELO := 1

## `primeros`: lo que va antes que los scripts (p. ej. la escena de «Nuevo juego»).
static func empezar(arbol: SceneTree, primeros: PackedStringArray = PackedStringArray()) -> void:
	if _hecho:
		return
	_hecho = true
	var n := CompilarFondo.new()
	n._cola = primeros.duplicate()
	n.name = "CompilarFondo"
	arbol.root.add_child.call_deferred(n)

func _ready() -> void:
	_listar("res://")

func _listar(d: String) -> void:
	for f in DirAccess.get_files_at(d):
		var n := f.trim_suffix(".remap")
		if n.ends_with(".gdc"):
			n = n.trim_suffix(".gdc") + ".gd"
		if n.ends_with(".gd") and not _cola.has(d.path_join(n)):
			_cola.append(d.path_join(n))
	for sub in DirAccess.get_directories_at(d):
		var ruta := d.path_join(sub)
		if not sub.begins_with(".") and not CARPETAS_FUERA.has(ruta):
			_listar(ruta)

func _process(_d: float) -> void:
	for i in range(_en_curso.size() - 1, -1, -1):
		var ruta := _en_curso[i]
		if ResourceLoader.load_threaded_get_status(ruta) == ResourceLoader.THREAD_LOAD_IN_PROGRESS:
			continue
		var r := ResourceLoader.load_threaded_get(ruta)
		if r != null:
			_retenidos.append(r)
		_en_curso.remove_at(i)
	while _en_curso.size() < EN_PARALELO and not _cola.is_empty():
		var sig := _cola[0]
		_cola.remove_at(0)
		if not ResourceLoader.has_cached(sig) and ResourceLoader.load_threaded_request(sig) == OK:
			_en_curso.append(sig)
	if _en_curso.is_empty() and _cola.is_empty():
		print_verbose("CompilarFondo: %d scripts listos a los %d ms" % [_retenidos.size(), Time.get_ticks_msec()])
		Engine.set_meta("compilado_ms", Time.get_ticks_msec())
		queue_free()
