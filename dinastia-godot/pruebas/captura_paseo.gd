extends Node
## Un paseo a pie por la ciudad, con fotos a la altura de los ojos: avenida
## comercial, barrio de casas, parque, puente y cruce con placas.
##   xvfb-run -a godot --path . --rendering-driver opengl3 --resolution 1280x720 res://pruebas/captura_paseo.tscn
var _n := 0
var _p: Node
var _v: VistaCiudad
var _e: ExploradorCiudad
## [nombre, posición, rumbo]
const PARADAS := [
	["paseo_1_avenida", Vector3(990.0 + 15.0, 0, -500.0), PI],
	["paseo_2_casas", Vector3(120.0, 0, 1150.0), -PI * 0.5],
	["paseo_3_parque", Vector3(-605.0, 0, 432.0), PI],
	["paseo_4_puente", Vector3(-575.0, 0, -982.0), PI * 0.5],
	["paseo_5_cruce", Vector3(345.0, 0, -658.0), PI * 0.75],
	["paseo_6_calle", Vector3(-224.0, 0, -880.0), PI * 0.5],
]

func _ready() -> void:
	_p = load("res://escenas/principal.tscn").instantiate()
	add_child(_p)

func _process(_d: float) -> void:
	_n += 1
	if _n == 6:
		_p.call("_ver_ciudad_propia")
		for h in _p.get_children():
			if h is VistaCiudad:
				_v = h
		_v.set("_ciclo_activo", false)
		_v.set("_hora", 11.0)
		_v.call("_aplicar_hora")
		_v.explorar("pie")
		_e = _v.get("_explorador")
	var k := (_n - 8) / 8
	if _n >= 8 and (_n - 8) % 8 == 0 and k < PARADAS.size():
		var par: Array = PARADAS[k]
		_e.cuerpo.position = par[1]
		_e.cuerpo.position.y = _e.altura_suelo(par[1].x, par[1].z)
		_e.set("rumbo", float(par[2]))
		_e.cuerpo.rotation.y = float(par[2])
		_e.call("_colocar_camara", 1.0)
	if _n >= 8 and (_n - 8) % 8 == 6 and k < PARADAS.size():
		get_viewport().get_texture().get_image().save_png("res://pruebas/capturas/%s.png" % PARADAS[k][0])
		print("FOTO ", PARADAS[k][0])
	if k >= PARADAS.size():
		get_tree().quit()
