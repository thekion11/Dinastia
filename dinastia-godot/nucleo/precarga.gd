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

## (10-11-2026, arranque del menú) Los scripts que COMPILA el montaje del menú (`Principal._ready`) y que no estaban ya en memoria: el retrato del DT en 3D (`PersonajeDT` y su familia), los diseños de camiseta, los
## escudos, las pantallas de Legado y de Despacho… (lista medida con `pruebas/medir_arranque_menu.tscn` con `NUEVOS=1`, sobre el `.pck` precompilado). Compilarlos dentro del montaje costaba ~0,4-0,6 s del hilo principal:
## se piden en el hilo de carga ANTES que los modelos, mientras el jugador está en la portada y en la entrada. Es la misma memoria que el montaje cargaría igual; solo se adelanta. La prueba de abajo comprueba que existen.
const SCRIPTS_MENU := [
	"res://nucleo/ciudad.gd", "res://nucleo/ciudad_p1.gd", "res://nucleo/editor.gd", "res://nucleo/eventos_club.gd", "res://nucleo/interiores_club.gd",
	"res://nucleo/mesa_agente.gd", "res://nucleo/tipo_titulo.gd", "res://ui/competiciones/trofeo_3d.gd", "res://ui/componentes/camisetas_retiradas.gd",
	"res://ui/componentes/escena_festejo.gd", "res://ui/componentes/evento_celebracion.gd", "res://ui/componentes/evento_dialogo.gd",
	"res://ui/componentes/evento_seleccion.gd", "res://ui/componentes/objetivo_directiva.gd", "res://ui/componentes/tablero_inicio.gd",
	"res://ui/disenos_kit.gd", "res://ui/disenos_kit_estructura.gd", "res://ui/disenos_kit_p1.gd", "res://ui/disenos_kit_p2.gd",
	"res://ui/disenos_kit_p3.gd", "res://ui/disenos_kit_p4.gd", "res://ui/escudo_emblemas.gd", "res://ui/pantallas/pantalla_ciudad.gd",
	"res://ui/pantallas/pantalla_club_estadio.gd", "res://ui/pantallas/pantalla_club_estadio_p1.gd", "res://ui/pantallas/pantalla_despacho.gd",
	"res://ui/pantallas/pantalla_elegir_club.gd", "res://ui/pantallas/pantalla_legado.gd", "res://ui/pantallas/pantalla_legado_p1.gd",
	"res://ui/pantallas/pantalla_legado_p2.gd", "res://ui/principal/informe_semana.gd", "res://ui/principal/jornada_celebracion.gd",
	"res://ui/principal/jornada_eventos.gd", "res://ui/principal/jornada_seleccion.gd", "res://visor/biblioteca_caras.gd", "res://visor/cara_malla.gd",
	"res://visor/expresion.gd", "res://visor/festejo_campo3d.gd", "res://visor/festejo_extra3d.gd", "res://visor/futbolista_q.gd",
	"res://visor/homenaje_campo3d.gd", "res://visor/idle_procedural.gd", "res://visor/pelo_capas.gd", "res://visor/pelo_capas_p1.gd",
	"res://visor/pelo_drive.gd", "res://visor/pelo_q.gd", "res://visor/persona_mh.gd", "res://visor/persona_realista.gd", "res://visor/personaje_dt.gd",
	"res://visor/personaje_dt_p1.gd", "res://visor/personaje_dt_p1_p1.gd", "res://visor/personaje_dt_vida.gd", "res://visor/ropa_separada.gd",
	"res://visor/vestidor_q.gd", "res://visor/vestidor_q_p1.gd", "res://visor/vestidor_q_p2.gd",
]
## ¿Ya están compilados los scripts del menú? (Lo mira `medir_arranque_menu` para simular el tiempo que el jugador pasa en la portada.)
static var menu_listo := false

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

var _cola_menu: Array[String] = []
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
	for r: String in SCRIPTS_MENU:
		_cola_menu.append(r)
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
	while not _cola_menu.is_empty():   ## primero los scripts del menú (cortos y los que el montaje va a pedir)
		var sc: String = _cola_menu.pop_front()
		if ResourceLoader.has_cached(sc) or not ResourceLoader.exists(sc):
			continue
		if ResourceLoader.load_threaded_request(sc) == OK:
			_actual = sc
			return
	menu_listo = true
	while not _cola.is_empty():
		var sig: String = _cola.pop_front()
		if ResourceLoader.has_cached(sig) or not ResourceLoader.exists(sig):
			continue
		if ResourceLoader.load_threaded_request(sig) == OK:
			_actual = sig
			return
	## Con los archivos ya leídos, las animaciones del personaje se arman en un hilo (M-348): el estadio y la ciudad ya las encuentran hechas.
	if PrecalentarAnim.permitido():
		PrecalentarAnim.lanzar()
	queue_free()
