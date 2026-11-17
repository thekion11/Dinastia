class_name FotosEstadioMenu
extends Node
## LAS FOTOS DEL ESTADIO DEL MENÚ DEL PARTIDO (17-11-2026, Auditoría: «la vista del estadio real del partido, una captura 3D hecha una vez y congelada»).
## Monta el estadio REAL del partido (`StadiumBuilder.build_pitch` + `build`: el perfil del club local, sus tribunas con los colores del club, la
## grada según el aforo y la LUZ del clima del día: noche, tarde, mediodía), saca una foto por cada pose de cámara que se le pida (la vista del
## estadio y una por cada distancia de la cámara Pro) y DESMONTA la escena: quedan solo las imágenes.
## NUNCA BLOQUEA (Auditoría): la pestaña abre al instante con su dibujo y la foto entra con un fundido; el montaje cede un fotograma entre zonas
## (`StadiumBuilder.ceder`, como la ciudad por partes). Las fotos se guardan en DISCO (user://fotos_estadio, clave = estadio + luz + calidad): cada
## estadio se fotografía UNA vez. En gama baja (BAJA o menos) y en el móvil, a media resolución y sin público.
## Lo usa `PanelesVistas3D` con `load()` (la memoria del menú no nombra clases del estadio 3D). Sin pantalla (`--headless`) no hace fotos.

signal listo(fotos: Dictionary)

## Poses: [posición de la cámara, punto al que mira, fov]. El campo va a lo largo de Z (arcos en ±52,5) y la tribuna principal en −X.
const POSES := {
	"estadio": [Vector3(-78, 46, -78), Vector3(0, 0, 4), 50.0],
	## La cámara PRO (la de jugar) va DETRÁS del jugador, como en `CameraRig` («Pro (Tercera Persona)», fov 62): a d metros, a 0,52·d de alto,
	## mirando 8 m por delante de él. El jugador de la foto está en JUGADOR, de cara al arco de enfrente (+Z).
	"cerca": [JUGADOR + Vector3(0, 3.0 * 0.52, -3.0), JUGADOR + Vector3(0, 1.2, 8.0), 62.0],
	"normal": [JUGADOR + Vector3(0, 4.2 * 0.52, -4.2), JUGADOR + Vector3(0, 1.2, 8.0), 62.0],
	"lejos": [JUGADOR + Vector3(0, 6.5 * 0.52, -6.5), JUGADOR + Vector3(0, 1.2, 8.0), 62.0],
}
const JUGADOR := Vector3(-6.0, 0.0, -14.0)
const TAM := Vector2i(960, 540)
const DIR := "user://fotos_estadio"

static var _hechas := {}   ## clave -> {pose: ImageTexture}; solo los últimos `EN_MEMORIA` estadios (el resto sigue en disco)
const EN_MEMORIA := 2      ## (17-11, Auditoría: la memoria subía ~8 MB por partido, una tanda de fotos por estadio nuevo, sin límite)
static var _en_curso := {}  ## clave -> el que las está haciendo (si se piden dos veces, no se monta otro estadio)
static var medida := {}     ## memoria (MB) antes, durante y después del último montaje (para las pruebas y las capturas)

## `StadiumBuilder.ceder` lo usa como a la ciudad por partes: cede un fotograma cada ~40 ms de obra.
var por_partes := true
var _cede_en := ""
var _clave := ""
var _club: Club
var _jugador: Jugador   ## el que sale de espaldas en las fotos de la cámara Pro
var _perfil: Dictionary
var _ligera := false
var _vp: SubViewport

## Gama baja: BAJA o menos, o el móvil.
static func ligera() -> bool:
	return Calidad.elegida <= Calidad.BAJA or OS.has_feature("mobile")

static func clave_de(local: Club, perfil: Dictionary, luz: String) -> String:
	return "v2_%s_%d_%s_%s" % [local.id.md5_text().left(10), absi(str(perfil).hash()), luz, "baja" if ligera() else "alta"]

## Pide las fotos del estadio de `local` con la luz de `clima_clave`. Si ya están hechas (en memoria o en disco), avisa al momento. Null sin pantalla.
static func pedir(padre: Node, local: Club, perfil: Dictionary, clima_clave: String, al_terminar: Callable, jugador: Jugador = null) -> FotosEstadioMenu:
	if DisplayServer.get_name() == "headless" or local == null:
		return null
	var luz := clima_clave if clima_clave in ["dia", "tarde", "noche"] else "tarde"
	var clave := clave_de(local, perfil, luz)
	if not _hechas.has(clave):
		var de_disco := _leer_disco(clave)
		if not de_disco.is_empty():
			_guardar(clave, de_disco)
	if _hechas.has(clave):
		al_terminar.call(_hechas[clave])
		return null
	if _en_curso.has(clave) and is_instance_valid(_en_curso[clave]):
		(_en_curso[clave] as FotosEstadioMenu).listo.connect(al_terminar)
		return null
	var f := FotosEstadioMenu.new()
	_en_curso[clave] = f
	f._clave = clave
	f._club = local
	f._jugador = jugador
	f._perfil = perfil.duplicate()
	f._perfil["clima"] = luz
	f._ligera = ligera()
	f.listo.connect(al_terminar)
	padre.add_child(f)
	return f

## La luz que toca según el clima del partido (el de `Clima.del_partido`).
static func luz_de(clima: Dictionary) -> String:
	var k := String(clima.get("clave", ""))
	if k in ["dia", "tarde", "noche"]:
		return k
	return "noche" if k in ["tormenta"] else "tarde"

## Guarda las fotos de un estadio en memoria y suelta las del más antiguo si ya hay `EN_MEMORIA` (orden de llegada; el diccionario lo conserva).
static func _guardar(clave: String, fotos: Dictionary) -> void:
	_hechas.erase(clave)
	_hechas[clave] = fotos
	while _hechas.size() > EN_MEMORIA:
		_hechas.erase(_hechas.keys()[0])

static func _ruta(clave: String, pose: String) -> String:
	return "%s/%s_%s.png" % [DIR, clave, pose]

static func _leer_disco(clave: String) -> Dictionary:
	var fotos := {}
	for pose: String in POSES:
		if not FileAccess.file_exists(_ruta(clave, pose)):
			return {}
		var img := Image.load_from_file(_ruta(clave, pose))
		if img == null or img.is_empty():
			return {}
		fotos[pose] = ImageTexture.create_from_image(img)
	return fotos

static func _mb() -> float:
	return Performance.get_monitor(Performance.MEMORY_STATIC) / 1048576.0

## Monta el estadio dentro de `raiz` (lo usa también la prueba del banco, sin pantalla, para comprobar que montar y desmontar no deja nodos).
static func montar_estadio(raiz: Node3D, local: Club, perfil: Dictionary, ligera_: bool, quien_cede: Object) -> void:
	var builder = load("res://visor/stadium_builder.gd")
	var antes = builder.ceder
	builder.ceder = quien_cede
	Ambience.apply(raiz, perfil, null, Calidad.elegida)
	builder.build_pitch(raiz, perfil, local)
	await builder.build(raiz, perfil, int(perfil.get("aforo", 20000)), 0.0 if ligera_ else 0.85, local._hash_id(), local)
	builder.ceder = antes

func _ready() -> void:
	await get_tree().process_frame   ## primero se dibuja la pestaña (con su dibujo); después se monta
	medida = {"antes": _mb()}
	_vp = SubViewport.new()
	_vp.own_world_3d = true
	_vp.size = TAM / 2 if _ligera else TAM
	_vp.msaa_3d = Viewport.MSAA_DISABLED if _ligera else Viewport.MSAA_4X
	_vp.render_target_update_mode = SubViewport.UPDATE_DISABLED
	add_child(_vp)
	var raiz := Node3D.new()
	_vp.add_child(raiz)
	await montar_estadio(raiz, _club, _perfil, _ligera, self)
	_poner_jugador(raiz)
	var cam := Camera3D.new()
	cam.far = 900.0
	raiz.add_child(cam)
	cam.current = true
	var builder = load("res://visor/stadium_builder.gd")
	var fotos := {}
	for clave: String in POSES:
		var p: Array = POSES[clave]
		cam.fov = float(p[2])
		cam.look_at_from_position(p[0], p[1])
		builder.ocultar_techo_ante(cam)
		_vp.render_target_update_mode = SubViewport.UPDATE_ONCE
		await RenderingServer.frame_post_draw
		await RenderingServer.frame_post_draw
		var img := _vp.get_texture().get_image()
		fotos[clave] = ImageTexture.create_from_image(img)
		DirAccess.make_dir_recursive_absolute(DIR)
		img.save_png(_ruta(_clave, clave))
	medida["durante"] = _mb()
	_guardar(_clave, fotos)
	_en_curso.erase(_clave)
	_vp.queue_free()   ## fuera la escena 3D: quedan solo las fotos
	listo.emit(fotos)
	await get_tree().process_frame
	await get_tree().process_frame
	medida["despues"] = _mb()
	queue_free()

## El futbolista de espaldas para las fotos de la cámara Pro: el mismo modelo del partido con la equipación del club, quieto.
func _poner_jugador(raiz: Node3D) -> void:
	if _jugador == null:
		return
	var nodo := Node3D.new()
	nodo.position = JUGADOR
	nodo.rotation.y = 0.0   ## el modelo ya mira a +Z (como en el retrato): de espaldas a la cámara
	raiz.add_child(nodo)
	var spawner = load("res://visor/player_spawner.gd").new()
	var kit: Dictionary = load("res://visor/puente3d.gd").kit(_club)
	spawner.set("_kit_x", kit.get("x", {}) if kit.get("x") is Dictionary else {})
	var datos: Dictionary = load("res://visor/puente3d.gd").jugador(_jugador)
	var look: Array = load("res://visor/player_spawner.gd")._look_de(datos)
	spawner._crear_jugador(nodo, _jugador.id, "DEL", "", Color(String(kit.get("c1", _club.color1))), Color(String(kit.get("c2", _club.color2))),
		String(kit.get("estilo", "liso")), maxi(_jugador.dorsal, 1), look[0], look[1], look[2], Color(0, 0, 0, 0), datos)
	if spawner is Node:
		(spawner as Node).queue_free()
