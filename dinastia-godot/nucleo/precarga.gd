class_name Precarga
extends Node
## PRECARGA EN SEGUNDO PLANO (etapa 3, 8-10-2026).
##
## Medido con `pruebas/lista_precarga.gd` y el cronómetro de `CityBuilder`
## (TIEMPOS=1): la primera vez que se abre la ciudad o el estadio, ~2 s se van
## en LEER DEL DISCO el personaje (Superhero + sus texturas 2K), las
## animaciones (UAL1_Standard, 7,6 MB), las butacas y los edificios del kit. En
## un disco lento de un equipo modesto, bastante más. La segunda vez ya no
## cuesta: quedan en caché.
##
## (Armar las animaciones de fútbol en un hilo se probó y se bloquea: cargar e
## instanciar el modelo fuera del hilo principal no es seguro. Eso se resuelve
## con la caché de `AnimQuaternius.construir`.)
##
## Así que se cargan ANTES, mientras el jugador está en el menú: un hilo, de a
## uno (para no tironear la interfaz) y reteniéndolos para que no se suelten de
## la caché. Si la ciudad pide uno que está a medio cargar, `load()` espera a
## ese hilo en vez de leerlo dos veces.

const FIJOS := [
	"res://assets/characters/quaternius/Superhero_Male_FullBody.gltf",
	"res://assets/characters/quaternius/Superhero_Female_FullBody.gltf",
	"res://assets/characters/quaternius/anims/UAL1_Standard.glb",
	"res://assets/characters/quaternius/equipacion_coords.png",
	"res://assets/characters/quaternius/equipacion_mascara.png",
	"res://assets/ciudad/asientos_lod.glb",
]
## Carpetas de modelos que la ciudad usa casi enteras.
const CARPETAS := [
	"res://assets/ciudad/kenney_comercial",
	"res://assets/ciudad/kenney_comercial_extra",
	"res://assets/ciudad/kenney_buildings",
]

static var _guardados: Array[Resource] = []
static var _hecha := false

var _cola: Array[String] = []
var _actual := ""

## La arranca la portada una sola vez por sesión. No en las pruebas sin
## gráfica: ahí se mide la carga en frío a propósito.
static func empezar(arbol: SceneTree) -> void:
	if _hecha or DisplayServer.get_name() == "headless":
		return
	_hecha = true
	var p := Precarga.new()
	p.name = "Precarga"
	arbol.root.add_child.call_deferred(p)

func _ready() -> void:
	for r: String in FIJOS:
		_cola.append(r)
	for c: String in CARPETAS:
		var d := DirAccess.open(c)
		if d == null:
			continue
		for f in d.get_files():
			if f.ends_with(".glb.import"):
				_cola.append(c + "/" + f.trim_suffix(".import"))

func _process(_d: float) -> void:
	if _actual != "":
		var st := ResourceLoader.load_threaded_get_status(_actual)
		if st == ResourceLoader.THREAD_LOAD_IN_PROGRESS:
			return
		if st == ResourceLoader.THREAD_LOAD_LOADED:
			var r := ResourceLoader.load_threaded_get(_actual)
			if r != null:
				_guardados.append(r)
		_actual = ""
	while not _cola.is_empty():
		var sig: String = _cola.pop_front()
		if ResourceLoader.has_cached(sig) or not ResourceLoader.exists(sig):
			continue
		if ResourceLoader.load_threaded_request(sig) == OK:
			_actual = sig
			return
	queue_free()
