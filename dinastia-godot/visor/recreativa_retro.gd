class_name RecreativaRetro
extends RefCounted
## LA RECREATIVA DEL FÚTBOL RETRO (01-11-2026, orden del dueño: «agarrar todo» de soccer5v5). Una máquina de videojuegos del kit
## «mini arcade» de Kenney (CC0, guardado sin usar desde el 15-10) junto a las de peluches del centro comercial; con la E abre el
## minijuego retro 5 contra 5 (`Retro5v5`, de github.com/Habeeb-Rahman-CA/soccer5v5-game-godot, MIT) encima de la ciudad, que queda
## en pausa hasta salir con Esc.
const RUTA := "res://assets/kenney/mini_arcade/arcade-machine.glb"
const ALTO := 1.85
const CLAVE := "recreativa_retro"

## Pone la máquina en `pos` (en el suelo) mirando a la calle (+Z). Devuelve false si falta el modelo.
static func montar(b: Node3D, pos: Vector3) -> bool:
	var ps := load(RUTA) as PackedScene
	if ps == null:
		return false
	var m := ps.instantiate() as Node3D
	b.add_child(m)
	var caja := AABB()
	var primera := true
	for mi: MeshInstance3D in m.find_children("*", "MeshInstance3D", true, false):
		var a := mi.transform * mi.get_aabb()
		caja = a if primera else caja.merge(a)
		primera = false
	m.scale = Vector3.ONE * (ALTO / maxf(caja.size.y, 0.01))
	m.position = pos
	b.puntos_clic.append({"k": CLAVE, "n": Idiomas.t("Recreativa: fútbol retro 5 contra 5"), "pos": pos + Vector3(0, 0, 1.0), "estado": "ciudad", "radio": 9.0, "alcance": 1.5})
	var rot := Label3D.new()
	rot.text = "🕹 " + Idiomas.t("FÚTBOL RETRO")
	rot.font_size = 40
	rot.pixel_size = 0.01
	rot.modulate = Color(0.6, 0.95, 1.0)
	rot.outline_size = 8
	rot.position = pos + Vector3(0, ALTO + 0.5, 0)
	rot.billboard = BaseMaterial3D.BILLBOARD_FIXED_Y
	b.add_child(rot)
	return true

## El gancho de la E (`CargaCiudad.de("ComercioCiudad").servicio`).
static func servicio(e, k: String) -> bool:
	if k != CLAVE:
		return false
	var abierto = (e.get_meta("retro5v5") if e.has_meta("retro5v5") else null)
	if abierto != null and is_instance_valid(abierto):
		return true
	e.set_meta("retro5v5", Retro5v5.abrir(e.get_tree()))
	return true
