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
	var borde := 10.0 if get_viewport_rect().size.x < 900.0 else 20.0
	raiz.offset_left = borde; raiz.offset_right = -borde; raiz.offset_top = borde - 4.0; raiz.offset_bottom = 4.0 - borde
	raiz.add_theme_constant_override("separation", 10 if borde < 20.0 else 12)
	_cuerpo.add_child(raiz)
	raiz.add_child(RutaCabecera.pintar(self, j, club))
	var resumen := RutaResumen.pendiente(self)
	CarreraLogros.revisar(carrera, mundo)
	if carrera.eventos.size() > _decisiones_vistas:
		RutaEstilo.son("notificacion")
	_decisiones_vistas = carrera.eventos.size()
	var nuevos := CarreraLogros.tomar_nuevos(carrera) if not resumen else []
	if (_msg != "" or not nuevos.is_empty()) and not resumen:
		raiz.add_child(RutaLogros.avisos(_msg, nuevos))
	if resumen:
		_pestana = "hoy"
	if resumen or RutaSub.abierta(self) == "":
		_sub = ""
	if _sub != "":
		raiz.add_child(RutaSub.pintar(self, j, club))
	else:
		match _pestana:
			"yo": raiz.add_child(RutaYo.pintar(self, j, club))
			"ruta": raiz.add_child(RutaCamino.pintar(self))
			_: raiz.add_child(RutaHoy.pintar(self, j, club))
	if RutaEstilo.estrecho(self):
		raiz.add_child(RutaCabecera.pestanas(self, true))
	if resumen:
		_cuerpo.add_child(RutaResumen.pintar(self, _msg))
	elif CarreraPremios.pendiente(carrera):
		_cuerpo.add_child(RutaTemporada.pintar(self))
	Idiomas.traducir_arbol(_cuerpo)
	RutaEstilo.enfocar(_cuerpo)

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

## El botón de cancelar del mando (o Escape) cierra la pantalla de dentro.
func _unhandled_input(e: InputEvent) -> void:
	if _sub != "" and e.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		RutaSub.cerrar(self)
