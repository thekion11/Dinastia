extends Node
## La tienda deportiva de la plaza (M-188) con la cámara a pie: xvfb-run -a godot --path . --rendering-driver opengl3 --resolution 1280x720 res://pruebas/captura_tienda_deportiva.tscn
var _n := 0
var _p: Node
var _v: VistaCiudad

func _ready() -> void:
	AjustesCiudad.guardar("tutorial_visto", true)
	_p = load("res://escenas/principal.tscn").instantiate()
	add_child(_p)

func _foto(n: String) -> void:
	get_viewport().get_texture().get_image().save_png("res://pruebas/capturas/%s.png" % n)

func _process(_d: float) -> void:
	_n += 1
	if _n == 6:
		_p.call("_ver_ciudad_propia")
		for h in _p.get_children():
			if h is VistaCiudad:
				_v = h
		_v.set("_ciclo_activo", false)
		_v.set("_hora", 13.0)
		_v.call("_aplicar_hora")
		_v.explorar("pie")
		var e: ExploradorCiudad = _v.get("_explorador")
		var tp := Vector3.ZERO
		for pc: Dictionary in e.cb.puntos_clic:
			if String(pc.get("k", "")).begins_with("deportes_"):
				tp = pc["pos"]
		print("TIENDA en ", tp)
		e.cuerpo.position = tp + Vector3(0.0, 0.2, 7.5)
		e.rumbo = PI
	if _n == 39:
		var e2: ExploradorCiudad = _v.get("_explorador")
		for n in get_tree().get_nodes_in_group("rotulo_mapa"):
			var l := n as Label3D
			if l.text.contains("DEPORTIVA") or l.text.contains("BANCO"):
				print("LABEL ", l.text, " vis=", l.visible, " en_arbol=", l.is_visible_in_tree(), " pos=", l.global_position, " px=", l.pixel_size, " fixed=", l.fixed_size, " rango=", l.visibility_range_end, " cuerpo=", e2.cuerpo.global_position, " depth=", l.no_depth_test, " fs=", l.font_size)
	if _n == 40:
		_foto("tienda_deportiva")
		get_tree().quit()
