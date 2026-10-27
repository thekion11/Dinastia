class_name CiudadArcade
extends RefCounted
## LAS MÁQUINAS DE PELUCHES DEL CENTRO COMERCIAL (27-10-2026, regalo del dueño, licencia libre confirmada por él).
## `assets/ciudad/maquina_peluches.glb` es la `Toy_Claw_01` del regalo, re-exportada con Godot con texturas de 256 px
## (893 KB, 11,8 k triángulos). Se instancia entera (son 21 mallas) y se arrima a la fachada (`FachadaModular`).
const RUTA := "res://assets/ciudad/maquina_peluches.glb"
const ALTO := 2.8
## Tres recreativas agrupadas junto a la entrada: dos a un lado de la puerta y una al otro (metros desde el centro).
const SITIOS := [-14.0, -11.5, 14.0]

## Pone las máquinas ante la fachada del solar `c` (`w` × `f`). Devuelve cuántas puso (0 si falta el archivo).
static func montar(b: Node3D, c: Vector3, w: float, f: float) -> int:
	var ps := load(RUTA) as PackedScene
	if ps == null:
		return 0
	var z := c.z + f * 0.175 + FachadaModular.FONDO + 1.0
	var puestas := 0
	for dx: float in SITIOS:
		var m := ps.instantiate() as Node3D
		b.add_child(m)
		m.scale = Vector3.ONE * (ALTO / 2.98)
		m.position = Vector3(c.x + dx, c.y + 0.3, z)
		## De cara a la calle (lado sur, +Z).
		m.rotation.y = PI
		puestas += 1
	return puestas
