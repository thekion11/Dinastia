class_name PeluchesCiudad
extends RefCounted
## LAS MÁQUINAS DE PELUCHES FUNCIONALES (27-10-2026, pieza D): el gancho de la E (aparte de `ComercioCiudad.servicio`) que abre `PanelPeluches`, los puntos `peluches_<n>`
## que registra `CiudadArcade.montar` (una por máquina de la sala del centro comercial) y la ESTANTERÍA del álbum en la vivienda del DT. `album` lo pone `VidaCiudad.enganchar`.
static var album: Peluches = null

## La E ante una máquina de peluches: abre el panel con la cartera y el álbum del DT. true si era una de ellas.
static func servicio(e, k: String) -> bool:
	if not k.begins_with("peluches_"):
		return false
	var v = e.vida
	if v == null or v.mundo == null or v.mundo.roles == null:
		return false
	var abierto = e.get_meta("panel_peluches", null)
	if abierto != null and is_instance_valid(abierto):
		return true
	var m := clampi(int(k.substr(9)), 0, 2)
	var pos := Vector3.ZERO
	for pc: Dictionary in e.cb.puntos_clic:
		if String(pc.get("k", "")) == k:
			pos = pc["pos"]
	var dia := CarteraDT.clave_dia(v.mundo.anio, v.mundo.semana, v.mundo.reloj.dia)
	e.set_meta("panel_peluches", PanelPeluches.abrir(e._capa, v.mundo.roles, dia, m, pos, e))
	return true

## La estantería del álbum en la vivienda: una librería abierta con los peluches que el DT ha ganado (hasta cinco por balda) y su cuenta.
static func estanteria(ins: Node) -> int:
	var raiz: Node3D = ins.get("_raiz")
	var x := -5.74
	var z0 := 1.74
	ins.call("_poner", "bookcaseOpen", Vector3(x, 0, z0), PI * 0.5)
	var puestos := 0
	if album != null:
		for p: Dictionary in Peluches.PELUCHES:
			if not album.tiene(String(p["id"])):
				continue
			var fila := puestos / 5
			var col := puestos % 5
			var n := PelucheModelo.montar(p, 0.42)
			n.position = Vector3(x, 0.42 + float(fila) * 0.5, z0 - 0.36 + float(col) * 0.18)
			n.rotation.y = PI * 0.5
			raiz.add_child(n)
			puestos += 1
	var cuenta := album.distintos() if album != null else 0
	ins.call("_cartel", "🧸 %d/%d" % [cuenta, Peluches.PELUCHES.size()], Vector3(x + 0.2, 2.0, z0), 22, Color(1.0, 0.9, 0.6), PI * 0.5)
	return puestos
