class_name ControlPartido
extends Node3D

## Sistema de Control Manual de Jugadores estilo EA Sports FC 26.
## Permite al usuario tomar el control interactivo de su equipo en el partido 3D,
## manejando al portador del balón o al defensor más cercano en tiempo real.

signal modo_cambiado(es_jugador: bool)
signal disparo_efectuado(potencia: float)
signal pase_efectuado(destino: Vector3)

const MEDIO_LARGO := 52.5
const MEDIO_ANCHO := 34.0

var activo := false
var jugadores_equipo: Array = []
var todos_los_jugadores: Array = []
var balon: Balon3D = null
var rig: CameraRig = null
var radar: RadarPartido = null
var playback: MatchPlayback = null
var es_local_user := true

var jugador_activo: Dictionary = {}
var tiene_posesion := false
var potencia_tiro := 0.0
var cargando_tiro := false

# Indicador visual sobre la cabeza
var _cursor_root: Node3D
var _cursor_malla: MeshInstance3D
var _cursor_anillo: MeshInstance3D

func setup(all_players: Array, ball_ref: Balon3D, camera_rig: CameraRig, es_local: bool, pb: MatchPlayback, rad: RadarPartido = null) -> void:
	todos_los_jugadores = all_players
	balon = ball_ref
	rig = camera_rig
	es_local_user = es_local
	playback = pb
	radar = rad

	jugadores_equipo.clear()
	for p in todos_los_jugadores:
		if p.get("es_local") == es_local_user and not bool(p.get("arbitro", false)):
			jugadores_equipo.append(p)

	_crear_cursor()
	seleccionar_mas_cercano_al_balon()
	set_activo(false)

func _crear_cursor() -> void:
	_cursor_root = Node3D.new()
	_cursor_root.name = "CursorJugador"
	add_child(_cursor_root)

	# Triángulo invertido neón sobre la cabeza
	_cursor_malla = MeshInstance3D.new()
	var prism := PrismMesh.new()
	prism.size = Vector3(0.45, 0.5, 0.2)
	_cursor_malla.mesh = prism
	_cursor_malla.rotation.x = PI  # invertir hacia abajo
	_cursor_malla.position = Vector3(0, 2.45, 0)

	var mat_neon := StandardMaterial3D.new()
	mat_neon.albedo_color = Color("3fa06a")
	mat_neon.emission_enabled = true
	mat_neon.emission = Color("4caf6d")
	mat_neon.emission_energy_multiplier = 2.2
	mat_neon.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_cursor_malla.material_override = mat_neon
	_cursor_root.add_child(_cursor_malla)

	# Anillo pulsante en el césped bajo los pies
	_cursor_anillo = MeshInstance3D.new()
	var torus := TorusMesh.new()
	torus.inner_radius = 0.55
	torus.outer_radius = 0.65
	_cursor_anillo.mesh = torus
	_cursor_anillo.position = Vector3(0, 0.03, 0)
	_cursor_anillo.material_override = mat_neon
	_cursor_root.add_child(_cursor_anillo)

func set_activo(valor: bool) -> void:
	activo = valor
	if _cursor_root != null:
		_cursor_root.visible = activo
	if activo and rig != null:
		rig.objetivo_seguimiento = jugador_activo.get("node")
	modo_cambiado.emit(activo)

func alternar_modo() -> void:
	set_activo(not activo)

func seleccionar_jugador(p: Dictionary) -> void:
	jugador_activo = p
	if rig != null:
		rig.objetivo_seguimiento = p.get("node")
	if radar != null:
		radar.jugador_activo = p.get("node")

func seleccionar_mas_cercano_al_balon() -> void:
	if jugadores_equipo.is_empty() or not is_instance_valid(balon):
		return
	var b_pos := balon.global_position
	var mejor_p: Dictionary = jugadores_equipo[0]
	var mejor_dist := 99999.0
	for p in jugadores_equipo:
		var node: Node3D = p.get("node")
		if is_instance_valid(node):
			var d := node.global_position.distance_to(b_pos)
			# Los porteros no se seleccionan a menos que el balón esté a bocajarro
			if str(p.get("slot_code", "")) == "POR" and d > 6.0:
				continue
			if d < mejor_dist:
				mejor_dist = d
				mejor_p = p
	seleccionar_jugador(mejor_p)

func _process(delta: float) -> void:
	if not activo or jugador_activo.is_empty():
		return

	var node: Node3D = jugador_activo.get("node")
	if not is_instance_valid(node):
		seleccionar_mas_cercano_al_balon()
		return

	# Actualizar posición del cursor
	_cursor_root.global_position = node.global_position
	var t_bounce := Time.get_ticks_msec() * 0.005
	_cursor_malla.position.y = 2.45 + sin(t_bounce) * 0.08

	# Comprobar posesión del balón
	if is_instance_valid(balon):
		var dist_balon := node.global_position.distance_to(balon.global_position)
		tiene_posesion = dist_balon < 1.75
	else:
		tiene_posesion = false

	# Input de movimiento (WASD / Flechas / Joypad)
	var move_vec := Vector2.ZERO
	if Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP):
		move_vec.y -= 1.0
	if Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN):
		move_vec.y += 1.0
	if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT):
		move_vec.x -= 1.0
	if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT):
		move_vec.x += 1.0

	var joy_x := Input.get_joy_axis(0, JOY_AXIS_LEFT_X)
	var joy_y := Input.get_joy_axis(0, JOY_AXIS_LEFT_Y)
	if absf(joy_x) > 0.15 or absf(joy_y) > 0.15:
		move_vec = Vector2(joy_x, joy_y)

	move_vec = move_vec.normalized()

	var sprinting := Input.is_key_pressed(KEY_SHIFT) or Input.is_joy_button_pressed(0, JOY_BUTTON_RIGHT_SHOULDER)
	var velocidad_ms: float = 6.4 if sprinting else 3.8

	var ap: AnimationPlayer = jugador_activo.get("anim")

	if move_vec.length_squared() > 0.01:
		var dir_3d := Vector3(move_vec.x, 0, move_vec.y)
		node.position += dir_3d * velocidad_ms * delta
		node.position.x = clampf(node.position.x, -MEDIO_ANCHO + 1.0, MEDIO_ANCHO - 1.0)
		node.position.z = clampf(node.position.z, -MEDIO_LARGO + 1.5, MEDIO_LARGO - 1.5)

		var ang_dest := atan2(dir_3d.x, dir_3d.z)
		node.rotation.y = rotate_toward(node.rotation.y, ang_dest, 10.0 * delta)

		# Animar movimiento
		if is_instance_valid(ap):
			var anim := "correr" if sprinting else "trotar"
			if ap.current_animation != anim and ap.has_animation(anim):
				ap.play(anim)
				ap.speed_scale = 1.15 if sprinting else 1.0

		# Arrastrar balón con toques de conducción si tiene posesión
		if tiene_posesion and is_instance_valid(balon):
			var fwd := -node.global_transform.basis.z.normalized()
			var pos_b := node.global_position + fwd * 0.72 + Vector3(0, 0.11, 0)
			balon.global_position = balon.global_position.lerp(pos_b, 12.0 * delta)
	else:
		if is_instance_valid(ap):
			if ap.current_animation != "parado" and ap.has_animation("parado"):
				ap.play("parado")
				ap.speed_scale = 1.0

	# Carga de potencia de disparo
	if cargando_tiro:
		potencia_tiro = minf(1.0, potencia_tiro + delta * 1.5)

func _unhandled_input(event: InputEvent) -> void:
	if not activo or jugador_activo.is_empty():
		return

	var node: Node3D = jugador_activo.get("node")
	if not is_instance_valid(node):
		return

	# Cambio de jugador (Q o Botón LB)
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_Q:
			seleccionar_mas_cercano_al_balon()
			get_viewport().set_input_as_handled()
			return

	# Acciones con Balón
	if tiene_posesion:
		# Pase Corto (Barra espaciadora o Botón A)
		if event is InputEventKey and event.pressed and not event.echo:
			if event.keycode == KEY_SPACE:
				_ejecutar_pase_corto()
				get_viewport().set_input_as_handled()
				return
			if event.keycode == KEY_C:
				_ejecutar_pase_largo()
				get_viewport().set_input_as_handled()
				return

		# Tiro a Puerta (tecla F o D cargada)
		if event is InputEventKey:
			if (event.keycode == KEY_F or event.keycode == KEY_ENTER) and event.pressed and not event.echo:
				cargando_tiro = true
				potencia_tiro = 0.2
				get_viewport().set_input_as_handled()
			elif (event.keycode == KEY_F or event.keycode == KEY_ENTER) and not event.pressed and cargando_tiro:
				cargando_tiro = false
				_ejecutar_disparo(potencia_tiro)
				get_viewport().set_input_as_handled()

	else:
		# En defensa: Entrada / Barrida (tecla E)
		if event is InputEventKey and event.pressed and not event.echo:
			if event.keycode == KEY_E:
				_ejecutar_barrida()
				get_viewport().set_input_as_handled()

func _ejecutar_pase_corto() -> void:
	if not is_instance_valid(balon):
		return
	var node: Node3D = jugador_activo["node"]
	var fwd := -node.global_transform.basis.z.normalized()

	# Buscar compañero en la dirección a la que mira el jugador
	var mejor_dest: Dictionary = {}
	var mejor_score := -9999.0
	for p in jugadores_equipo:
		if p == jugador_activo:
			continue
		var n: Node3D = p.get("node")
		if is_instance_valid(n):
			var to_mate := (n.global_position - node.global_position).normalized()
			var dot := fwd.dot(to_mate)
			var dist := node.global_position.distance_to(n.global_position)
			var score := dot * 100.0 - dist * 0.8
			if score > mejor_score:
				mejor_score = score
				mejor_dest = p

	var target_pos := node.global_position + fwd * 8.0
	if not mejor_dest.is_empty():
		target_pos = (mejor_dest["node"] as Node3D).global_position

	var dist := node.global_position.distance_to(target_pos)
	var ap: AnimationPlayer = jugador_activo.get("anim")
	if is_instance_valid(ap) and ap.has_animation("patear"):
		ap.play("patear")

	balon.enviar(target_pos, clampf(dist / 14.0, 0.25, 1.4), 0.08)
	if not mejor_dest.is_empty():
		seleccionar_jugador(mejor_dest)
	pase_efectuado.emit(target_pos)

func _ejecutar_pase_largo() -> void:
	if not is_instance_valid(balon):
		return
	var node: Node3D = jugador_activo["node"]
	var fwd := -node.global_transform.basis.z.normalized()
	var target_pos := node.global_position + fwd * 24.0
	target_pos.x = clampf(target_pos.x, -32.0, 32.0)
	target_pos.z = clampf(target_pos.z, -50.0, 50.0)

	var ap: AnimationPlayer = jugador_activo.get("anim")
	if is_instance_valid(ap) and ap.has_animation("patear"):
		ap.play("patear")

	balon.enviar(target_pos, 1.4, 2.2)
	pase_efectuado.emit(target_pos)

func _ejecutar_disparo(potencia: float) -> void:
	if not is_instance_valid(balon):
		return
	var node: Node3D = jugador_activo["node"]
	var z_arco: float = -52.5 if es_local_user else 52.5
	var x_offset := (randf() - 0.5) * (1.0 - potencia * 0.5) * 4.0
	var y_dest := clampf(potencia * 2.3, 0.3, 2.2)
	var target_tiro := Vector3(x_offset, y_dest, z_arco - (0.8 if es_local_user else -0.8))

	var ap: AnimationPlayer = jugador_activo.get("anim")
	if is_instance_valid(ap) and ap.has_animation("patear"):
		ap.play("patear")

	node.look_at(Vector3(0, node.position.y, z_arco), Vector3.UP)
	var es_gol: bool = absf(x_offset) < 3.2 and y_dest < 2.35
	balon.enviar(target_tiro, clampf(0.9 - potencia * 0.3, 0.45, 0.9), 0.5, es_gol)

	# Si es gol, festejar
	if es_gol and playback != null:
		playback.suceso({
			"min": playback.current_minute(),
			"t": "golMi" if es_local_user else "golR",
			"equipo": "local" if es_local_user else "visita",
			"tx": "¡GOLAZO de %s!" % jugador_activo.get("id", "Jugador"),
			"jugadorId": jugador_activo.get("id", ""),
		})

	disparo_efectuado.emit(potencia)

func _ejecutar_barrida() -> void:
	var node: Node3D = jugador_activo["node"]
	var ap: AnimationPlayer = jugador_activo.get("anim")
	if is_instance_valid(ap) and ap.has_animation("falta_barrida"):
		ap.play("falta_barrida")
	var fwd := -node.global_transform.basis.z.normalized()
	node.position += fwd * 2.4
