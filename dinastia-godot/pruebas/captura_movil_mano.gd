extends Node
## Ciudad sin textos fijos y con el móvil en la mano al correr (13-10-2026).
## Fotos: movil_mano_1 (parado, sin textos), movil_mano_2 (corriendo, móvil
## arriba), movil_mano_3 (panel ⚙ de la ciudad).
##   xvfb-run -a godot --path . --rendering-driver opengl3 --resolution 1280x720 res://pruebas/captura_movil_mano.tscn
var _p: Node
var _v: VistaCiudad
var _e: ExploradorCiudad
var _n := 0

func _ready() -> void:
	Calidad.elegida = Calidad.MEDIO
	AjustesCiudad.guardar("tutorial_visto", true)
	_p = load("res://escenas/principal.tscn").instantiate()
	add_child(_p)

func _tecla(k: Key, si: bool) -> void:
	var ev := InputEventKey.new()
	ev.physical_keycode = k
	ev.keycode = k
	ev.pressed = si
	Input.parse_input_event(ev)

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
		_e.cuerpo.position = Vector3(990.0 + 15.0, 0, -500.0)
		_e.set("rumbo", PI)
	if _n == 14:
		get_viewport().get_texture().get_image().save_png("res://pruebas/capturas/movil_mano_1.png")
		_tecla(KEY_SHIFT, true)
		_tecla(KEY_W, true)
	if _n == 60:
		get_viewport().get_texture().get_image().save_png("res://pruebas/capturas/movil_mano_2.png")
		_tecla(KEY_SHIFT, false)
		_tecla(KEY_W, false)
		var a := AjustesCiudad.crear(Callable())
		_e.get("_capa").add_child(a)
	if _n == 66:
		get_viewport().get_texture().get_image().save_png("res://pruebas/capturas/movil_mano_3.png")
	if _n == 70:
		var t := AjustesCiudad.TutorialCiudad.new()
		_e.get("_capa").add_child(t)
	if _n == 100:
		get_viewport().get_texture().get_image().save_png("res://pruebas/capturas/movil_mano_4.png")
		get_tree().quit()
