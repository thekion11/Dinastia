class_name CarreraJugadorUI
extends "res://ui/carrera_jugador_ui_p1.gd"
## [Capa 2/2 de `carrera_jugador_ui.gd`] _pintar_semana, _ready

func _pintar_semana() -> void:
	_limpiar()
	var j := carrera.jugador(mundo) if carrera != null else null
	var club := carrera.club(mundo) if carrera != null else null
	if j == null or club == null:
		_pintar_crear()
		return
	var raiz := VBoxContainer.new()
	raiz.set_anchors_preset(Control.PRESET_FULL_RECT)
	raiz.offset_left = 20; raiz.offset_right = -20; raiz.offset_top = 14; raiz.offset_bottom = -14
	raiz.add_theme_constant_override("separation", 12)
	_cuerpo.add_child(raiz)
	raiz.add_child(RutaCabecera.pintar(self, j, club))
	var resumen := RutaResumen.pendiente(self)
	if _msg != "" and not resumen:
		raiz.add_child(RutaCabecera.aviso(_msg))
	match _pestana:
		"yo": raiz.add_child(RutaYo.pintar(self, j, club))
		"ruta": raiz.add_child(RutaCamino.pintar(self))
		_: raiz.add_child(RutaHoy.pintar(self, j, club))
	if resumen:
		_pestana = "hoy"
		_cuerpo.add_child(RutaResumen.pintar(self, _msg))
	Idiomas.traducir_arbol(_cuerpo)

func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	var fondo := ColorRect.new()
	fondo.set_anchors_preset(Control.PRESET_FULL_RECT)
	fondo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var mat := ShaderMaterial.new()
	mat.shader = load("res://ui/fondo_menu.gdshader")
	mat.set_shader_parameter("estilo", 3)
	mat.set_shader_parameter("c1", RutaEstilo.NOCHE)
	mat.set_shader_parameter("c2", Color("101a3a"))
	mat.set_shader_parameter("c3", RutaEstilo.ORO)
	mat.set_shader_parameter("aspecto", Vector2(1.78, 1.0))
	if AhorroMenu.fondo_estatico():
		fondo.color = RutaEstilo.NOCHE
	else:
		fondo.material = mat
	add_child(fondo)
	_cuerpo = Control.new()
	_cuerpo.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_cuerpo)
	if mundo != null and mundo.carrera_jugador != null:
		carrera = mundo.carrera_jugador
		_pintar_semana()
	else:
		_pintar_crear()
