class_name CiudadArcade
extends RefCounted
## LAS MÁQUINAS DE PELUCHES DEL CENTRO COMERCIAL (27-10-2026, regalo del dueño, licencia libre confirmada por él).
## `assets/ciudad/maquina_peluches.glb` es la `Toy_Claw_01` del regalo, re-exportada con Godot con texturas de 256 px
## (893 KB, 11,8 k triángulos). Se instancia entera (son 21 mallas) y se alinea a la fachada acristalada.
const RUTA := "res://assets/ciudad/maquina_peluches.glb"
const ALTO := 2.8
const N := 7

## Pone la fila de máquinas ante la fachada del solar `c` (`w` × `f`). Devuelve cuántas puso (0 si falta el archivo).
static func montar(b: Node3D, c: Vector3, w: float, f: float) -> int:
	var ps := load(RUTA) as PackedScene
	if ps == null:
		return 0
	var z := c.z + f * 0.175 + 2.2
	var puestas := 0
	for k in N:
		var m := ps.instantiate() as Node3D
		b.add_child(m)
		var esc := ALTO / 2.98
		m.scale = Vector3.ONE * esc
		m.position = Vector3(c.x + (float(k) - float(N - 1) / 2.0) * w * 0.09, c.y + 0.3, z)
		## De cara a la calle (lado sur, +Z).
		m.rotation.y = PI
		puestas += 1
	return puestas
