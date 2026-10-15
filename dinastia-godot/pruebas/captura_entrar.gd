extends Node
## Entrar a un edificio y pasearlo (etapa 6): bar, casa y taller en tercera y
## primera persona, y la salida a la calle. Salida: pruebas/capturas/entrar_N.png
##   xvfb-run -a godot --path . --rendering-driver opengl3 --resolution 1280x720 res://pruebas/captura_entrar.tscn
const CLAVES := ["ciudad_hospital", "edificio_bar|Bar El Rincón", "edificio_vivienda|Casa de la familia Ortega"]
var _p: Node
var _v: VistaCiudad
var _e: ExploradorCiudad
var _n := 0
var _pos_calle := Vector3.ZERO

func _ready() -> void:
	Calidad.elegida = Calidad.MEDIO
	## Sin el tutorial de la ciudad tapando el tercio de abajo de cada foto.
	AjustesCiudad.guardar("tutorial_visto", true)
	_p = load("res://escenas/principal.tscn").instantiate()
	add_child(_p)

func _foto(nombre: String) -> void:
	get_viewport().get_texture().get_image().save_png("res://pruebas/capturas/entrar_%s.png" % nombre)
	print("FOTO ", nombre, " estado=", _e.estado, " pos=", _e.cuerpo.position)

func _process(_d: float) -> void:
	_n += 1
	if _n == 5:
		_p.call("_ver_ciudad_propia")
		for h in _p.get_children():
			if h is VistaCiudad:
				_v = h
		_v.set("_ciclo_activo", false)
		_v.set("_hora", 11.0)
		_v.call("_aplicar_hora")
		_v.explorar("pie")
		_e = _v.get("_explorador")
	if _n == 12:
		_pos_calle = _e.cuerpo.position
	var fase := (_n - 12) / 40
	var paso := (_n - 12) % 40
	if _n > 12 and fase < CLAVES.size():
		if paso == 1:
			_e.call("_entrar_en_edificio", CLAVES[fase])
		if paso == 2:
			print("MUEBLES ", fase, " círculos=", _e._int_circulos.size())
		if paso == 12:
			_foto("%d_tercera" % fase)
			_e.primera_persona = true
		if paso == 14:
			_e.call("_colocar_camara", 1.0)
		if paso == 24:
			_foto("%d_primera" % fase)
			_e.primera_persona = false
		if paso == 30:
			_e.call("_salir_del_edificio")
		if paso == 34:
			print("SALIDA estado=", _e.estado, " pos_igual=", _e.cuerpo.position.distance_to(_pos_calle) < 0.1)
	if _n > 12 + 40 * CLAVES.size() + 5:
		get_tree().quit()
