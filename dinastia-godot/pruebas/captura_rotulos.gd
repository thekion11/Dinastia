extends Node
## RÓTULOS SIN AMONTONAR (MEGAPLAN fase 1): partido en juego, cámara de TV,
## capturas en tres momentos y cuántos nombres quedan visibles.
##   xvfb-run -a godot --path . --rendering-driver opengl3 --resolution 1600x900 res://pruebas/captura_rotulos.tscn
var _n := 0
var _vista: VistaEstadio

func _ready() -> void:
	var mundo := Mundo.new()
	mundo.generar(["CHI"], 777)
	mundo.tomar_el_mando(mundo.ligas[0].clubes[0].id)
	var par := mundo.proximo_partido()
	var partido := Partido.new(par[0], par[1])
	_vista = VistaEstadio.new()
	add_child(_vista)
	_vista.abrir(par[0], 0.85, par[1], partido)
	_vista.get("_juego").vel_idx = 2

func _process(_d: float) -> void:
	_n += 1
	for paso: int in [30, 70, 110]:
		if _n == paso:
			var vis := 0
			var tot := 0
			for f: Dictionary in _vista.get("_en_campo"):
				var nd: Node3D = f.get("node")
				if is_instance_valid(nd) and nd.has_node(PlayerSpawner.ROTULO):
					tot += 1
					if (nd.get_node(PlayerSpawner.ROTULO) as Node3D).visible:
						vis += 1
			print("ROTULOS fotograma %d: %d de %d visibles" % [paso, vis, tot])
			get_viewport().get_texture().get_image().save_png("res://pruebas/capturas/rotulos_%d.png" % paso)
	if _n == 115:
		get_tree().quit()
