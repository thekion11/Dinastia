extends Node
## El rincón deportivo de la casa (M-188): xvfb-run -a godot --path . --rendering-driver opengl3 --resolution 1280x720 res://pruebas/captura_ropero_casa.tscn
var _n := 0
var _p: Node
var _v: VistaCiudad

func _ready() -> void:
	process_priority = 1000
	AjustesCiudad.guardar("tutorial_visto", true)
	_p = load("res://escenas/principal.tscn").instantiate()
	add_child(_p)

func _foto(n: String) -> void:
	get_viewport().get_texture().get_image().save_png("res://pruebas/capturas/%s.png" % n)

func _process(_d: float) -> void:
	_n += 1
	if _n == 6:
		var m: Mundo = _p.get("mundo")
		for id in ["camiseta_club", "bufanda_club", "botines", "balon", "balon", "balon_playa"]:
			RoperoDT.agregar(m.roles.ropero, id)
		_p.call("_ver_ciudad_propia")
		for h in _p.get_children():
			if h is VistaCiudad:
				_v = h
		_v.set("_ciclo_activo", false)
		_v.set("_hora", 13.0)
		_v.call("_aplicar_hora")
		_v.explorar("pie")
	if _n == 10:
		var e: ExploradorCiudad = _v.get("_explorador")
		if e.vida == null:
			e.vida = VidaCiudad.enganchar(e, _v, _p.get("mundo"))
		e.vida.entrar_casa()
	if _n == 30:
		var e2: ExploradorCiudad = _v.get("_explorador")
		e2.cuerpo.position = e2._INT_ORIGEN + Vector3(-2.4, 0.05, -1.2)
		e2.rumbo = atan2(-2.2, 1.6)
		e2.cuerpo.rotation.y = e2.rumbo
	if _n >= 40:
		var e3: ExploradorCiudad = _v.get("_explorador")
		var base := e3._INT_ORIGEN + RoperoCasa.BASE
		e3.camara.global_position = base + Vector3(2.6, 2.4, -2.6)
		e3.camara.look_at(base + Vector3(-0.4, 0.5, 0.2), Vector3.UP)
	if _n == 46:
		_foto("ropero_casa")
		get_tree().quit()
