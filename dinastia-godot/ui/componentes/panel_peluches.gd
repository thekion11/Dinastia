class_name PanelPeluches
extends PanelContainer
## LA MÁQUINA DE PELUCHES (27-10-2026, pieza D): vista cenital del cristal. Se inserta una moneda de 1 € (del EFECTIVO de `CarteraDT`), se mueve la garra con
## A/D/W/S o las flechas y se suelta con ESPACIO: baja, cierra, sube y lleva lo que haya agarrado a la salida. Lo que cae va al álbum (`Peluches.conseguir`) y puede dar un
## LOGRO. La probabilidad la decide `Peluches.intento` (baja con el peso y la distancia, y sube con cada fallo seguido: nunca es imposible). Mientras está abierta la
## máquina, el explorador no mueve al DT (`juego_abierto`), porque comparten teclas. Se cierra con Esc o si el DT se aleja.
const DISTANCIA_MAX := 7.0
const CAMPO := Rect2(14, 8, 412, 300)     ## el cristal, en píxeles del panel
const MAX_LINEAS := 4                      ## líneas del mensaje de abajo (la altura del panel las reserva)
const VEL_GARRA := 0.55                    ## fracción del campo por segundo
const T_BAJA := 0.9
const T_CIERRA := 0.45
const T_SUBE := 0.9
const T_LLEVA := 1.0
const T_SALIDA := 0.7

enum { ESPERA, MOVER, BAJA, CIERRA, SUBE, LLEVA, SALE, FIN }

signal cerrado

var maquina := 0
var roles: Roles
var dia := 0
var pos_maquina := Vector3.ZERO
var expl: Node
var fase := ESPERA
var garra := Vector2(0.5, 0.5)
var campo: Array = []
var _jugadas := 0
var _t := 0.0
var _agarrado := -1               ## índice en `campo` del peluche que lleva la garra
var _gana := ""                   ## id del peluche que cae por la salida
var _mensaje := ""
var _logros_nuevos: Array = []
var _rng := RandomNumberGenerator.new()
var _caja := Control.new()
var _botones := HBoxContainer.new()
var _vista: VistaGarra3D          ## la máquina en 3D (`vista_garra3d.gd`) si los peluches tienen modelo; si no, el dibujo 2D de siempre

static func abrir(capa: CanvasLayer, roles_: Roles, dia_: int, maquina_: int, pos: Vector3, quien: Node) -> PanelPeluches:
	var p := PanelPeluches.new()
	p.roles = roles_
	p.dia = dia_
	p.maquina = maquina_
	p.pos_maquina = pos
	p.expl = quien
	p.set_anchors_preset(Control.PRESET_CENTER)
	p.offset_left = -230
	p.offset_right = 230
	p.offset_top = -270
	p.offset_bottom = 270
	p.add_theme_stylebox_override("panel", CuadroDialogo.estilo_panel())
	p._montar()
	capa.add_child(p)
	if quien != null:
		quien.set_meta("juego_abierto", true)
	return p

func _montar() -> void:
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 6)
	add_child(v)
	v.add_child(CuadroDialogo.placa("🧸 " + Idiomas.t("Máquina de peluches")))
	_caja.custom_minimum_size = Vector2(440, 462)
	_caja.draw.connect(_pintar)
	v.add_child(_caja)
	if ResourceLoader.exists(String(Peluches.PELUCHES[0].get("modelo", ""))):
		_vista = VistaGarra3D.en(_caja, CAMPO)
	_botones.alignment = BoxContainer.ALIGNMENT_CENTER
	_botones.add_theme_constant_override("separation", 10)
	v.add_child(_botones)
	_mensaje = Idiomas.t("Mueve la garra con A/D/W/S (o las flechas) y suéltala con espacio.")
	_botones_de_espera()

func _botones_de_espera() -> void:
	for b in _botones.get_children():
		b.queue_free()
	var ins := Button.new()
	ins.text = Idiomas.t("Insertar moneda (%d €)") % Peluches.MONEDA
	ins.pressed.connect(_insertar)
	_botones.add_child(ins)
	var sal := Button.new()
	sal.text = Idiomas.t("Salir")
	sal.pressed.connect(salir)
	_botones.add_child(sal)

func _saldo_texto() -> String:
	return Idiomas.t("Efectivo") + " " + Eco.dinero_euros(float(roles.cartera.efectivo)) + " · " + Idiomas.t("Álbum: %d de %d peluches") % [roles.peluches.distintos(), Peluches.PELUCHES.size()]

func _insertar() -> void:
	if fase != ESPERA and fase != FIN:
		return
	var err := roles.cartera.pagar_efectivo(Peluches.MONEDA, "Máquina de peluches", dia)
	if err != "":
		_mensaje = Idiomas.t("No tienes monedas: necesitas 1 € en efectivo (sácalo en un cajero).")
		_caja.queue_redraw()
		return
	_jugadas += 1
	campo = Peluches.campo(maquina, hash([dia, maquina, _jugadas, roles.peluches.distintos()]))
	garra = Vector2(0.5, 0.5)
	_agarrado = -1
	_gana = ""
	_logros_nuevos = []
	_mensaje = Idiomas.t("Mueve la garra con A/D/W/S (o las flechas) y suéltala con espacio.")
	fase = MOVER
	_t = 0.0
	for b in _botones.get_children():
		b.queue_free()
	_caja.queue_redraw()

func salir() -> void:
	if expl != null and is_instance_valid(expl):
		expl.set_meta("juego_abierto", false)
	cerrado.emit()
	queue_free()

func _exit_tree() -> void:
	if expl != null and is_instance_valid(expl):
		expl.set_meta("juego_abierto", false)

func _input(ev: InputEvent) -> void:
	if ev is InputEventKey and ev.pressed and not ev.echo:
		if ev.physical_keycode == KEY_ESCAPE:
			salir()
			get_viewport().set_input_as_handled()
		elif fase == MOVER and (ev.physical_keycode == KEY_SPACE or ev.physical_keycode == KEY_ENTER):
			soltar()
			get_viewport().set_input_as_handled()

## La garra baja donde esté.
func soltar() -> void:
	if fase != MOVER:
		return
	fase = BAJA
	_t = 0.0

func _process(delta: float) -> void:
	if expl != null and is_instance_valid(expl):
		var cuerpo: Node3D = expl.get("cuerpo")
		if cuerpo != null and cuerpo.global_position.distance_to(pos_maquina) > DISTANCIA_MAX:
			salir()
			return
	_t += delta
	match fase:
		MOVER:
			var d := Vector2(float(Input.is_physical_key_pressed(KEY_D) or Input.is_physical_key_pressed(KEY_RIGHT)) - float(Input.is_physical_key_pressed(KEY_A) or Input.is_physical_key_pressed(KEY_LEFT)),
				float(Input.is_physical_key_pressed(KEY_S) or Input.is_physical_key_pressed(KEY_DOWN)) - float(Input.is_physical_key_pressed(KEY_W) or Input.is_physical_key_pressed(KEY_UP)))
			mover(d, delta)
		BAJA:
			if _t >= T_BAJA:
				fase = CIERRA
				_t = 0.0
		CIERRA:
			if _t >= T_CIERRA:
				_cerrar_garra()
		SUBE:
			if _t >= T_SUBE:
				fase = LLEVA
				_t = 0.0
		LLEVA:
			if _t >= T_LLEVA:
				fase = SALE
				_t = 0.0
				if _agarrado >= 0:
					_gana = String(campo[_agarrado]["id"])
		SALE:
			if _t >= T_SALIDA:
				_terminar()
	if _vista != null:
		_vista.actualizar(self)
	_caja.queue_redraw()

## Mueve la garra `d` (−1..1 en cada eje) durante `delta` segundos, sin salirse del cristal.
func mover(d: Vector2, delta: float) -> void:
	garra = (garra + d * VEL_GARRA * delta).clamp(Vector2(0.04, 0.05), Vector2(0.96, 0.95))

func _cerrar_garra() -> void:
	_rng.seed = hash([dia, maquina, _jugadas, roles.peluches.fallos_seguidos, roles.cartera.efectivo, roles.peluches.distintos()])
	var r := roles.peluches.intento(campo, garra.x, garra.y, _rng)
	if bool(r["exito"]):
		_agarrado = int(r["indice"])
	else:
		_agarrado = -1
		_mensaje = Idiomas.t("Se te escapó. ¡Inténtalo otra vez!") if int(r["indice"]) >= 0 else Idiomas.t("Cerraste la garra en el aire.")
	fase = SUBE
	_t = 0.0

func _terminar() -> void:
	if _gana != "":
		_logros_nuevos = roles.peluches.conseguir(_gana)
		_mensaje = Idiomas.t("¡Lo tienes! %s cae por la salida y va a tu álbum.") % Idiomas.t(String(Peluches.def(_gana)["nombre"]))
		for l: String in _logros_nuevos:
			_mensaje += "\n🏆 " + Idiomas.t("Logro desbloqueado: %s") % Peluches.nombre_logro(l)
	fase = FIN
	for b in _botones.get_children():
		b.queue_free()
	var otra := Button.new()
	otra.text = Idiomas.t("Otra vez (%d €)") % Peluches.MONEDA
	otra.pressed.connect(_insertar)
	_botones.add_child(otra)
	var sal := Button.new()
	sal.text = Idiomas.t("Salir")
	sal.pressed.connect(salir)
	_botones.add_child(sal)

# ---------------------------------------------------------------- dibujo

func _punto(p: Vector2) -> Vector2:
	return CAMPO.position + Vector2(p.x * CAMPO.size.x, p.y * CAMPO.size.y) - Vector2(0, 0)

func _peluche(c: Vector2, d: Dictionary, r: float) -> void:
	var col: Color = d["color"]
	var forma := String(d["forma"])
	if forma == "oso":
		for s: float in [-1.0, 1.0]:
			_caja.draw_circle(c + Vector2(s * r * 0.75, -r * 0.8), r * 0.38, col)
	elif forma == "puntas":
		for s2: float in [-1.0, 1.0]:
			_caja.draw_colored_polygon(PackedVector2Array([c + Vector2(s2 * r * 0.35, -r * 0.7), c + Vector2(s2 * r * 0.95, -r * 1.4), c + Vector2(s2 * r * 0.95, -r * 0.5)]), col)
	_caja.draw_circle(c, r, col)
	_caja.draw_circle(c + Vector2(0, r * 0.25), r * 0.5, col.lerp(Color.WHITE, 0.5))
	for s3: float in [-1.0, 1.0]:
		_caja.draw_circle(c + Vector2(s3 * r * 0.35, -r * 0.2), r * 0.11, Color(0.05, 0.05, 0.06))

func _pintar() -> void:
	_caja.draw_rect(Rect2(Vector2.ZERO, _caja.size), Color(0.08, 0.1, 0.16))
	if _vista != null:
		_textos()
		return
	_caja.draw_rect(CAMPO, Color(0.3, 0.42, 0.55, 0.35))
	_caja.draw_rect(CAMPO, Color(0.7, 0.85, 1.0), false, 3.0)
	_caja.draw_rect(Rect2(CAMPO.position + Vector2(0, CAMPO.size.y - 50), Vector2(70, 50)), Color(0.9, 0.5, 0.15, 0.55))      ## la salida
	_caja.draw_string(ThemeDB.fallback_font, CAMPO.position + Vector2(6, CAMPO.size.y - 18), Idiomas.t("SALIDA"), HORIZONTAL_ALIGNMENT_LEFT, 64, 14, Color.WHITE)
	for i in campo.size():
		if i == _agarrado and fase >= SUBE and fase <= LLEVA:
			continue
		_peluche(_punto(Vector2(float(campo[i]["x"]), float(campo[i]["y"]))), Peluches.def(String(campo[i]["id"])), 24.0)
	if fase >= MOVER and fase != FIN:
		var salida := Vector2(0.09, 0.9)
		var c := garra
		var alto := 0.0                                      ## 0 arriba … 1 abajo
		match fase:
			BAJA:
				alto = clampf(_t / T_BAJA, 0.0, 1.0)
			CIERRA:
				alto = 1.0
			SUBE:
				alto = 1.0 - clampf(_t / T_SUBE, 0.0, 1.0)
			LLEVA:
				c = garra.lerp(salida, clampf(_t / T_LLEVA, 0.0, 1.0))
			SALE:
				c = salida
		var pc := _punto(c)
		var r := 18.0 - alto * 6.0
		var cierre := 0.0
		if fase == CIERRA:
			cierre = clampf(_t / T_CIERRA, 0.0, 1.0)
		elif fase >= SUBE:
			cierre = 1.0
		_caja.draw_line(Vector2(pc.x, CAMPO.position.y - 12), pc, Color(0.8, 0.8, 0.85), 2.0)       ## el cable
		_caja.draw_circle(pc + Vector2(6, 8) * alto, r * 0.9, Color(0, 0, 0, 0.28))                    ## la sombra
		if _agarrado >= 0 and fase >= SUBE and fase <= LLEVA:
			_peluche(pc + Vector2(0, 8), Peluches.def(String(campo[_agarrado]["id"])), 22.0)
		for k in 3:
			var ang := TAU * float(k) / 3.0 + 0.5
			var abre := lerpf(1.0, 0.45, cierre)
			_caja.draw_line(pc, pc + Vector2(cos(ang), sin(ang)) * r * abre, Color(0.95, 0.8, 0.2), 4.0)
		_caja.draw_circle(pc, 5.0, Color(0.95, 0.8, 0.2))
	if fase == SALE and _gana != "":
		var q := clampf(_t / T_SALIDA, 0.0, 1.0)
		_peluche(_punto(Vector2(0.09, 0.9)) + Vector2(0, q * 24.0), Peluches.def(_gana), 22.0 * (1.0 - q * 0.3))
	_textos()

func _textos() -> void:
	## Todo lo que es texto SE PARTE en líneas (en alemán, ruso... una frase no cabe en 420 px): `draw_string` la cortaba.
	_caja.draw_multiline_string(ThemeDB.fallback_font, Vector2(14, 334), _saldo_texto(), HORIZONTAL_ALIGNMENT_LEFT, 420, 15, 2, Color(1, 0.9, 0.6))
	_caja.draw_multiline_string(ThemeDB.fallback_font, Vector2(14, 382), _mensaje, HORIZONTAL_ALIGNMENT_LEFT, 420, 15, MAX_LINEAS, Color.WHITE)
