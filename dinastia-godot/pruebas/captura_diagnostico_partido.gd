extends Node
## Diagnostico rapido: el usuario reporto que en el partido los jugadores no
## tienen cara y estan "caidos", y que el publico y el pasto se ven falsos.
## Esto saca capturas cercanas -camara "A ras de campo"- para ver de verdad
## que modelo esta cargando cada jugador (el realista o el respaldo de
## Kenney) y en que pose, en vez de adivinar.
##
##   godot --path . --rendering-driver opengl3 res://pruebas/captura_diagnostico_partido.tscn

const ARRANQUE := 24

var _n := 0
var _vista: VistaEstadio
var _mundo: Mundo
var _partido: Partido

func _ready() -> void:
	_mundo = Mundo.new()
	_mundo.generar(["CHI"], 777)
	_mundo.tomar_el_mando(_mundo.ligas[0].clubes[0].id)
	var par := _mundo.proximo_partido()
	_partido = Partido.new(par[0], par[1])
	_vista = VistaEstadio.new()
	add_child(_vista)
	_vista.abrir(par[0], 0.85, par[1], _partido)
	_vista.get("_juego").vel_idx = 2

func _process(_d: float) -> void:
	_n += 1
	if _n == ARRANQUE:
		var en_campo: Array = _vista.get("_en_campo")
		print("jugadores en el campo: %d" % en_campo.size())
		var realistas := 0
		var kenney := 0
		var caidos := 0
		for f: Dictionary in en_campo:
			var node: Node3D = f.get("node")
			if node == null or not is_instance_valid(node):
				continue
			## El modelo realista trae mallas con nombre Object_*; el de Kenney
			## trae otra jerarquia. Se distingue por el nombre del hijo, sin
			## adivinar.
			var es_realista := node.find_child("Object_7_001", true, false) != null
			if es_realista:
				realistas += 1
			else:
				kenney += 1
			## "Caido": si el nodo esta rotado de canto (X o Z cerca de +-90),
			## en vez de de pie.
			var rot: Vector3 = node.rotation
			if absf(rot.x) > 1.0 or absf(rot.z) > 1.0:
				caidos += 1
				print("  jugador %s: rotation=%s -> CAIDO/DE CANTO" % [f.get("id"), rot])
		print("modelo realista: %d | modelo Kenney (respaldo): %d | de pie mal orientados: %d" % [
			realistas, kenney, caidos])
		var rig: CameraRig = _vista.get("_rig")
		rig.switch_to(3)  # "A ras de campo"
		print("camara -> %s" % rig.current_name())
	if _n == ARRANQUE + 10:
		var img := get_viewport().get_texture().get_image()
		img.save_png("res://pruebas/capturas/diagnostico_ras_campo.png")
		print("captura: diagnostico_ras_campo.png")
	if _n == ARRANQUE + 14:
		var rig: CameraRig = _vista.get("_rig")
		rig.switch_to(0)  # "Principal (TV)"
		print("camara -> %s" % rig.current_name())
	if _n == ARRANQUE + 24:
		var img := get_viewport().get_texture().get_image()
		img.save_png("res://pruebas/capturas/diagnostico_tv.png")
		print("captura: diagnostico_tv.png")
		get_tree().quit()
