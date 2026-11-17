class_name FotosEstadioMenu
extends Node
## LAS FOTOS DEL ESTADIO DEL MENÚ DEL PARTIDO (17-11-2026, Auditoría: «la vista del estadio real del partido, una captura 3D hecha una vez y congelada»).
## Monta el estadio REAL del partido (`StadiumBuilder.build_pitch` + `build`: el perfil del club local, sus tribunas con los colores del club, la
## grada según el aforo y la LUZ del clima del día: noche, tarde, mediodía), saca una foto por cada pose de cámara que se le pida (la vista del
## estadio y una por cada distancia de la cámara Pro) y DESMONTA la escena: quedan solo las imágenes, guardadas por partido. Nada se monta hasta
## que se abre la pestaña que lo pide. Sin pantalla (`--headless`) no hace nada y los paneles se quedan con sus dibujos.
## Lo usa `PanelesMenuPartido` con `load()` (la memoria del menú no nombra clases del estadio 3D).

signal listo(fotos: Dictionary)

## Poses: [posición de la cámara, punto al que mira, fov]. El campo va a lo largo de Z (arcos en ±52,5) y la tribuna principal en −X.
const POSES := {
	"estadio": [Vector3(-78, 46, -78), Vector3(0, 0, 4), 50.0],
	"cerca": [Vector3(-36, 16, 0), Vector3(0, 0, 0), 46.0],
	"normal": [Vector3(-52, 24, 0), Vector3(0, 0, 0), 46.0],
	"lejos": [Vector3(-58, 42, 0), Vector3(4, 0, 0), 50.0],   ## alta y por encima de la tribuna (más atrás, la cámara quedaba dentro del palco)
}
const TAM := Vector2i(960, 540)

static var _hechas := {}   ## clave del partido -> {pose: ImageTexture}
static var _en_curso := {}  ## clave -> el que las está haciendo (si se piden dos veces, no se monta otro estadio)

var _clave := ""
var _club: Club
var _perfil: Dictionary
var _vp: SubViewport

## Pide las fotos del estadio de `local` con la luz de `clima_clave`. Si ya están hechas, avisa al momento. Devuelve null sin pantalla.
static func pedir(padre: Node, local: Club, perfil: Dictionary, clima_clave: String, al_terminar: Callable) -> FotosEstadioMenu:
	if DisplayServer.get_name() == "headless" or local == null:
		return null
	var clave := "%s|%s" % [local.id, clima_clave]
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
	f._perfil = perfil.duplicate()
	f._perfil["clima"] = clima_clave if clima_clave in ["dia", "tarde", "noche"] else "tarde"
	f.listo.connect(al_terminar)
	padre.add_child(f)
	return f

## La luz que toca según el clima del partido (el de `Clima.del_partido`).
static func luz_de(clima: Dictionary) -> String:
	var k := String(clima.get("clave", ""))
	if k in ["dia", "tarde", "noche"]:
		return k
	return "noche" if k in ["tormenta"] else "tarde"

func _ready() -> void:
	_vp = SubViewport.new()
	_vp.own_world_3d = true
	_vp.size = TAM
	_vp.msaa_3d = Viewport.MSAA_4X
	_vp.render_target_update_mode = SubViewport.UPDATE_DISABLED
	add_child(_vp)
	var raiz := Node3D.new()
	_vp.add_child(raiz)
	var builder = load("res://visor/stadium_builder.gd")
	Ambience.apply(raiz, _perfil, null, Calidad.elegida)
	builder.build_pitch(raiz, _perfil, _club)
	await builder.build(raiz, _perfil, int(_perfil.get("aforo", 20000)), 0.85, _club._hash_id(), _club)
	var cam := Camera3D.new()
	cam.far = 900.0
	raiz.add_child(cam)
	cam.current = true
	var fotos := {}
	for clave: String in POSES:
		var p: Array = POSES[clave]
		cam.fov = float(p[2])
		cam.look_at_from_position(p[0], p[1])
		builder.ocultar_techo_ante(cam)
		_vp.render_target_update_mode = SubViewport.UPDATE_ONCE
		await RenderingServer.frame_post_draw
		await RenderingServer.frame_post_draw
		fotos[clave] = ImageTexture.create_from_image(_vp.get_texture().get_image())
	_hechas[_clave] = fotos
	_en_curso.erase(_clave)
	listo.emit(fotos)
	queue_free()   ## fuera la escena 3D: quedan solo las fotos
