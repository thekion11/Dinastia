class_name CameraRig
extends Node3D

## Sistema multicámara profesional para el estadio y partido 3D.
## Soporta 9 tipos de cámara (incluyendo Primera Persona POV, Pro Tercera Persona,
## Tele Dinámica, TV Broadcast, etc.) con ajuste dinámico de zoom y altura.

signal camera_changed(name: String)

var cameras: Array[Camera3D] = []
var camera_names: Array[String] = []
var current_index: int = 0

## Referencias para seguimiento dinámico
var objetivo_seguimiento: Node3D = null
var balon_ref: Node3D = null
## El árbitro, para su cámara subjetiva (26-9-2026).
var arbitro_ref: Node3D = null
var _mira_arbitro: Vector3 = Vector3.ZERO

var _dx: float = 49.0
var _dz: float = 68.0
var _alto: float = 13.0
var _cara_x: float = 43.5
var _cara_z: float = 62.5
var _y_principal: float = 11.5
var _foco_tele: Vector3 = Vector3.ZERO
const FOV_TELE := 21.0
const ALTURA_TELE := 36.0
## Era una constante de 46 m (23-9-2026). En la forma mas chica ("ingles",
## dx=45) eso deja la camara FUERA del muro exterior del estadio, y con el
## seguimiento lateral (`t_pos.x*0.28 + 46`) se iba hasta 55,5 m: el rayo al
## balon cruzaba la losa del techo y el balon quedaba tapado por la cubierta.
## Ahora se ajusta al recinto en `build_for()` y nunca sale del cuenco.
const DISTANCIA_TELE_X_MAX := 46.0
var _dist_tele: float = DISTANCIA_TELE_X_MAX

func _add(cam_name: String, pos: Vector3, mira: Vector3, fov: float) -> Camera3D:
	var cam := Camera3D.new()
	cam.position = pos
	cam.fov = fov
	cam.far = 500.0
	cam.near = 1.0
	cam.projection = Camera3D.PROJECTION_PERSPECTIVE
	cam.current = cameras.is_empty()
	add_child(cam)
	cam.look_at(mira, Vector3.UP)
	cameras.append(cam)
	camera_names.append(cam_name)
	return cam

## dx/dz: centro de las tribunas laterales / de fondo. alto: altura del graderio.
func build_for(dx: float, dz: float, alto: float) -> void:
	_dx = dx
	_dz = dz
	_alto = alto
	_cara_x = dx - 5.5
	_cara_z = dz - 5.5
	var centro := Vector3(0, 1.4, 0)
	_y_principal = minf(alto * 0.55 + 4.0, alto - 1.5)
	_dist_tele = minf(DISTANCIA_TELE_X_MAX, dx - 7.0)

	# 1. Principal (TV Broadcast clásico)
	_add("Principal (TV)", Vector3(_cara_x - 2.0, _y_principal, 7.0), centro, 46)

	# 2. Tele Dinámica: teleobjetivo de transmisión (FOV 21°). El gran angular
	# aplastaba a los futbolistas; el documento maestro pide 20-22° y seguimiento
	# amortiguado a lo largo de la BANDA (eje X de este visor, no Z).
	_add("Tele Dinámica", Vector3(_dist_tele, ALTURA_TELE, 0.0), Vector3(0, 0.4, 0), FOV_TELE)

	# 3. Primera Persona (POV - A la altura de los ojos del jugador)
	_add("Primera Persona (POV)", Vector3(0, 1.72, 0), Vector3(0, 1.72, -10.0), 75)

	# 4. Pro / Tercera Persona (Detrás del hombro del futbolista)
	_add("Pro (Tercera Persona)", Vector3(0, 2.4, 5.0), Vector3(0, 1.4, -15.0), 62)

	# 5. Tribuna alta (Palco / Gran angular táctico)
	## BUG REAL (23-9-2026): esto era `clampf(alto*0.55, 12.0, 34.0)`, y como
	## `alto` no pasa nunca de 19,5, `alto*0.55` no pasa de 10,7 -o sea que la
	## expresion **nunca superaba su propio minimo y siempre devolvia 12,0**:
	## el parametro era codigo muerto-. Con 1 nivel eso son 12 m de altura
	## sobre un estadio cuyo techo esta en 7,15, y ademas en x=34, que es la
	## LINEA DE BANDA y no una tribuna: el "palco" flotaba en el aire sobre el
	## corner. Ahora sale del recinto: dentro del graderio lateral y por
	## debajo de su propia cubierta.
	_add("Tribuna alta", Vector3(dx - 9.0, minf(alto * 0.8 + 2.0, alto - 1.0), 26.0),
		Vector3(0, 1.0, -2.0), 52)

	# 6. Detrás del arco (End-to-End longitudinal)
	var y_arco := minf(alto * 0.35 + 4.0, alto - 1.5)
	_add("Detras del arco", Vector3(0, y_arco, _cara_z - 2.0), Vector3(0, 1.4, 10.0), 55)

	# 7. A ras de campo (Banda y banquillos)
	_add("A ras de campo", Vector3(36.0, 1.75, 2.0), Vector3(0, 1.3, 6.0), 60)

	# 8. Cenital táctica (90° vertical)
	_add("Cenital táctica", Vector3(0, 88.0, 0.5), Vector3(0, 0, 0), 46)

	# 9. Dron orbital
	_add("Dron orbital", Vector3(0, alto + 28.0, 60.0), Vector3(0, 0, 0), 48)

	# 10. POV del árbitro (26-9-2026, pedido: "pov desde el árbitro"): a la
	# altura de sus ojos, siguiendo el balón con la cabeza, con el vaivén de
	# quien corre.
	_add("Árbitro (POV)", Vector3(6.0, 1.75, 8.0), Vector3(0, 1.2, 0), 70)

func _process(delta: float) -> void:
	if cameras.is_empty():
		return
	var c_name := current_name()
	var cam: Camera3D = cameras[current_index]

	# Objetivo de referencia prioritario: jugador activo o balón
	var target: Node3D = objetivo_seguimiento if is_instance_valid(objetivo_seguimiento) else balon_ref
	if not is_instance_valid(target):
		return

	var t_pos := target.global_position

	if c_name == "Árbitro (POV)":
		if is_instance_valid(arbitro_ref) and is_instance_valid(balon_ref):
			var ojos := arbitro_ref.global_position + Vector3(0, 1.72, 0)
			## Vaivén de la carrera: más cuanto más rápido se mueve.
			var vel := (ojos - cam.global_position).length() / maxf(delta, 0.001)
			var vaiven := sin(Time.get_ticks_msec() * 0.012) * clampf(vel * 0.004, 0.0, 0.035)
			cam.global_position = ojos + Vector3(0, vaiven, 0)
			_mira_arbitro = _mira_arbitro.lerp(balon_ref.global_position + Vector3(0, 0.3, 0), 4.0 * delta)
			if cam.global_position.distance_to(_mira_arbitro) > 0.5:
				cam.look_at(_mira_arbitro, Vector3.UP)
		return

	match c_name:
		"Tele Dinámica":
			# Documento maestro, remapeado: aquí Z es el largo y X la banda.
			var cam_z := clampf(t_pos.z * 0.72, -36.0, 36.0)
			var cam_x := (t_pos.x * 0.28) + _dist_tele
			var cam_y := ALTURA_TELE + (absf(t_pos.z) * 0.05)
			var pos_obj := Vector3(cam_x, cam_y, cam_z)
			cam.global_position = cam.global_position.lerp(pos_obj, 3.8 * delta)
			if cam.fov > FOV_TELE + 0.5 or cam.fov < FOV_TELE - 0.5:
				## El usuario puede haber hecho zoom; no se lo pisamos. Si está
				## cerca del valor de fábrica, lo mantenemos en 21°.
				pass
			else:
				cam.fov = FOV_TELE
			var foco_deseado := Vector3(t_pos.x * 0.65, 0.4, t_pos.z * 0.85)
			_foco_tele = _foco_tele.lerp(foco_deseado, 5.0 * delta)
			cam.look_at(_foco_tele, Vector3.UP)

		"Primera Persona (POV)":
			# Anclada a la cabeza del jugador, mirando hacia adelante
			cam.global_position = t_pos + Vector3(0, 1.72, 0)
			var fwd := -target.global_transform.basis.z.normalized()
			if fwd.length_squared() > 0.01:
				cam.look_at(cam.global_position + fwd * 10.0, Vector3.UP)

		"Pro (Tercera Persona)":
			# Detrás del hombro del jugador
			var fwd2 := -target.global_transform.basis.z.normalized()
			var pos_atras := t_pos - fwd2 * 4.2 + Vector3(0, 2.2, 0)
			cam.global_position = cam.global_position.lerp(pos_atras, 6.0 * delta)
			cam.look_at(t_pos + fwd2 * 8.0 + Vector3(0, 1.2, 0), Vector3.UP)

func switch_to(idx: int) -> void:
	if idx < 0 or idx >= cameras.size():
		return
	current_index = idx
	for i in range(cameras.size()):
		cameras[i].current = (i == idx)
	camera_changed.emit(camera_names[idx])

func cycle() -> void:
	if cameras.is_empty():
		return
	switch_to((current_index + 1) % cameras.size())

func current_name() -> String:
	if camera_names.size() > current_index:
		return camera_names[current_index]
	return ""

## Ajustes en tiempo real
func ajustar_zoom(delta_fov: float) -> void:
	if current_index >= 0 and current_index < cameras.size():
		var cam: Camera3D = cameras[current_index]
		cam.fov = clampf(cam.fov + delta_fov, 18.0, 88.0)
		camera_changed.emit("%s (FOV: %d°)" % [current_name(), int(cam.fov)])

func ajustar_altura(delta_y: float) -> void:
	if current_index >= 0 and current_index < cameras.size():
		var cam: Camera3D = cameras[current_index]
		cam.position.y = clampf(cam.position.y + delta_y, 1.2, 110.0)
		camera_changed.emit("%s (Y: %.1fm)" % [current_name(), cam.position.y])

func ayuda() -> String:
	return "1-%d / Tab: Cámaras  ·  +/- / Rueda: Zoom  ·  RePág/AvPág: Altura" % cameras.size()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			ajustar_zoom(-2.5)
			get_viewport().set_input_as_handled()
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			ajustar_zoom(2.5)
			get_viewport().set_input_as_handled()

	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_TAB:
			cycle()
			get_viewport().set_input_as_handled()
			return
		if event.keycode == KEY_EQUAL or event.keycode == KEY_KP_ADD:
			ajustar_zoom(-3.0)
			get_viewport().set_input_as_handled()
			return
		if event.keycode == KEY_MINUS or event.keycode == KEY_KP_SUBTRACT:
			ajustar_zoom(3.0)
			get_viewport().set_input_as_handled()
			return
		if event.keycode == KEY_PAGEUP:
			ajustar_altura(1.5)
			get_viewport().set_input_as_handled()
			return
		if event.keycode == KEY_PAGEDOWN:
			ajustar_altura(-1.5)
			get_viewport().set_input_as_handled()
			return
		var idx: int = int(event.keycode) - int(KEY_1)
		if idx >= 0 and idx < cameras.size():
			switch_to(idx)
			get_viewport().set_input_as_handled()
