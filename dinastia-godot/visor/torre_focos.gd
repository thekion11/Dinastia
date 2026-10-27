class_name TorreFocos
extends RefCounted
## LA TORRE DE FOCOS DEL DRIVE (27-10-2026, regalo del dueño: `assets/regalos/torre_focos.glb`, 23,2 m, ~21 800 triángulos): poste telescópico con
## escalerilla y un bastidor de 5 × 6 proyectores que miran a +Z, algo inclinados hacia abajo. Sustituye al poste de cilindro y a la cabeza de
## cajas (`StadiumBuilder._focos`) en las torres de las esquinas; sin el recurso se usa lo de siempre. Se escala para llegar a la altura de la torre
## de siempre, se gira para que los focos miren al campo y la emisión de los proyectores lleva el color de luz del club.
const RUTA := "res://assets/regalos/torre_focos.glb"
const ALTO := 23.2

static var _escena: PackedScene = null
static var _probada := false

static func disponible() -> bool:
	if OS.get_environment("SIN_TORRE_DRIVE") != "":   ## para medir antes/después
		return false
	if not _probada:
		_probada = true
		if ResourceLoader.exists(RUTA):
			_escena = load(RUTA) as PackedScene
	return _escena != null

## Pone la torre con el pie en `base` y los focos hacia `mira`, de `alto` m de alto, con la emisión `luz`. false si no hay recurso.
static func montar(root: Node3D, base: Vector3, alto: float, mira: Vector3, luz: Color) -> bool:
	if not disponible():
		return false
	var n := _escena.instantiate() as Node3D
	n.name = "TorreFocos"
	n.add_to_group("torres_focos")
	var d := mira - base
	n.rotation.y = atan2(d.x, d.z)
	n.scale = Vector3.ONE * (alto / ALTO)
	n.position = base
	root.add_child(n)
	for mi: Node in n.find_children("*", "MeshInstance3D", true, false):
		var m := mi as MeshInstance3D
		for s in m.mesh.get_surface_count():
			var mat := m.mesh.surface_get_material(s)
			if mat is StandardMaterial3D and (mat as StandardMaterial3D).emission_enabled:
				var c := (mat as StandardMaterial3D).duplicate() as StandardMaterial3D
				c.emission = luz
				c.emission_energy_multiplier = 1.8
				m.set_surface_override_material(s, c)
		m.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return true
