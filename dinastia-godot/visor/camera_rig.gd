class_name CameraRig
extends "res://visor/camera_rig_p1.gd"
## [Capa 2/2 de `camera_rig.gd`] impacto, golpe_de_zoom, cycle, ajustar_zoom, ajustar_altura, ayuda, _unhandled_input, planos de inserto, en_cuadro, foco_con_balon

func impacto(fuerza: float, dur: float = 0.5) -> void:
	_sacudida = maxf(_sacudida, clampf(fuerza, 0.0, 1.5))
	_sacudida_dur = maxf(dur, 0.05)

func golpe_de_zoom(grados: float, dur: float = 0.6) -> void:
	_zoom_fuerza = grados
	_zoom_t = dur
	_zoom_dur = maxf(dur, 0.05)

func cycle() -> void:
	if cameras.is_empty():
		return
	switch_to((current_index + 1) % cameras.size())

## Ajustes en tiempo real
func ajustar_zoom(delta_fov: float) -> void:
	if current_index >= 0 and current_index < cameras.size():
		var cam: Camera3D = cameras[current_index]
		## En la transmisión el zoom se recalcula cada fotograma: lo del
		## usuario se guarda como un ajuste que se suma al plano automático.
		if current_name() == "Transmisión":
			_zoom_usuario = clampf(_zoom_usuario + delta_fov, -12.0, 24.0)
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

## Cuánto cierra (área/ocasión) y cuánto abre (contraataque, balón largo) el
## plano según la jugada. Estático para poder probarlo sin escena.
static func lectura_jugada(b: Vector3, vel: Vector3, ataca: float, ocasion: bool, saque: String, estado: String) -> Vector2:
	if estado in ["gol", "descanso", "fin"]:
		return Vector2(0.0, 0.35)
	var dist_arco := (52.5 - b.z * ataca) if ataca != 0.0 else (52.5 - absf(b.z))
	## El área y su frontal: a menos de ~30 m de la línea y por dentro.
	var area := clampf((30.0 - dist_arco) / 13.0, 0.0, 1.0) * clampf((30.0 - absf(b.x)) / 10.0, 0.0, 1.0)
	var cerca := maxf(area * 0.85, 1.0 if ocasion or saque in ["corner", "penal"] else 0.0)
	if saque in ["puerta", "centro", "banda"]:
		cerca = 0.0
	## Contraataque: el balón avanza rápido hacia la portería rival y aún lejos.
	var avance := vel.z * ataca if ataca != 0.0 else absf(vel.z)
	var contra := clampf((avance - 6.0) / 5.0, 0.0, 1.0) * clampf((dist_arco - 32.0) / 18.0, 0.0, 1.0)
	## Transición larga: un balón que viaja muy rápido (pase largo, cambio de banda).
	var largo := clampf((Vector2(vel.x, vel.z).length() - 15.0) / 8.0, 0.0, 1.0) * 0.75
	var abre := maxf(contra, largo) * (1.0 - cerca)
	return Vector2(cerca, abre)

# --- EL ENCUADRE (25-10-2026) -----------------------------------------------------

## Dónde cae `p` en el cuadro de una cámara en `desde` que mira a `mira`: -1..1 en cada eje
## (de borde a borde; fuera de ese rango, fuera de la pantalla). `fov` vertical (el de
## Godot con `KEEP_HEIGHT`) y `aspecto` = ancho / alto. Detrás de la cámara: (9, 9).
static func en_cuadro(desde: Vector3, mira: Vector3, fov: float, aspecto: float, p: Vector3) -> Vector2:
	var adelante := mira - desde
	if adelante.length() < 0.01:
		return Vector2(9, 9)
	var base := Basis.looking_at(adelante, Vector3.UP)
	var l := base.transposed() * (p - desde)
	if l.z > -0.05:
		return Vector2(9, 9)
	var tv := tan(deg_to_rad(fov) * 0.5)
	return Vector2(l.x / -l.z / (tv * aspecto), l.y / -l.z / tv)

## El foco, deslizado hacia el balón `b` lo justo para que este quede dentro de `margen`
## del cuadro (búsqueda binaria sobre la recta foco → balón: en el balón, queda centrado).
static func foco_con_balon(desde: Vector3, foco: Vector3, fov: float, aspecto: float, b: Vector3, margen: float) -> Vector3:
	var s := en_cuadro(desde, foco, fov, aspecto, b)
	if absf(s.x) <= margen and absf(s.y) <= margen:
		return foco
	var lo := 0.0
	var hi := 1.0
	for i in 12:
		var m := (lo + hi) * 0.5
		var s2 := en_cuadro(desde, foco.lerp(b, m), fov, aspecto, b)
		if absf(s2.x) <= margen and absf(s2.y) <= margen:
			hi = m
		else:
			lo = m
	return foco.lerp(b, hi)

# --- LOS PLANOS DE INSERTO (25-10-2026) -------------------------------------------
## Como el realizador de la tele: un corte breve a un plano corto (la tarjeta en la mano del
## árbitro, el cartel del añadido) y vuelta a la cámara de antes. La cámara del rig se sigue
## calculando debajo, así que al volver está donde va la jugada. Solo desde los planos de
## tele (con la cámara del jugador o la subjetiva no se corta nada) y solo si en pantalla
## está la cámara del rig (no en plena realización del gol, repetición o ceremonia).

const PLANOS_TV := ["Transmisión", "Principal (TV)", "Tele Dinámica", "Tribuna alta"]
var inserto := ""            ## el inserto en pantalla ("" = ninguno)
var _ins_cam: Camera3D
var _ins_t := 0.0
var _ins_sigue: Node3D
var _ins_desfase := Vector3.ZERO
var _ins_mira := Vector3.ZERO

func insertar_plano(nombre: String, pos: Vector3, mira: Vector3, fov: float, dur: float, sigue: Node3D = null) -> bool:
	if cameras.is_empty() or not is_inside_tree() or not current_name() in PLANOS_TV or plano_tanda:
		return false
	var vista := get_viewport().get_camera_3d()
	if vista != cameras[current_index] and not (inserto != "" and vista == _ins_cam):
		return false
	if _ins_cam == null:
		_ins_cam = Camera3D.new()
		_ins_cam.name = "Inserto"
		_ins_cam.far = 500.0
		add_child(_ins_cam)
	_ins_cam.global_position = pos
	_ins_cam.fov = fov
	_ins_mira = mira
	_ins_sigue = sigue
	_ins_desfase = mira - sigue.global_position if is_instance_valid(sigue) else Vector3.ZERO
	_ins_cam.look_at(mira, Vector3.UP)
	_ins_cam.current = true
	_ins_t = dur
	inserto = nombre
	return true

func _inserto_paso(delta: float) -> void:
	if inserto == "":
		## Red de seguridad: si alguien devolvió la vista al inserto ya acabado (la cámara
		## «de antes» de una realización), vuelve la del rig.
		if _ins_cam != null and _ins_cam.current and cameras.size() > current_index:
			cameras[current_index].current = true
		return
	_ins_t -= delta
	if _ins_t <= 0.0:
		_cancelar_inserto()
		return
	## La mirada sigue a quien protagoniza el plano, con la inercia de un trípode.
	if is_instance_valid(_ins_sigue):
		_ins_mira = _ins_mira.lerp(_ins_sigue.global_position + _ins_desfase, clampf(4.0 * delta, 0.0, 1.0))
		if _ins_cam.global_position.distance_to(_ins_mira) > 0.5:
			_ins_cam.look_at(_ins_mira, Vector3.UP)

func _cancelar_inserto() -> void:
	if inserto == "":
		return
	inserto = ""
	_ins_t = 0.0
	## Solo devuelve la vista si sigue en el inserto (una realización pudo tomarla).
	if _ins_cam != null and _ins_cam.current and cameras.size() > current_index:
		cameras[current_index].current = true

## LA TARJETA, DE CERCA: el árbitro y el amonestado de perfil, desde el lado de la tribuna
## principal (no se cruza el eje de la transmisión), a la altura de los ojos.
func inserto_tarjeta(arbitro: Node3D, infractor: Node3D, dur := 2.3) -> bool:
	if not is_instance_valid(arbitro):
		return false
	var r := arbitro.global_position
	var i := infractor.global_position if is_instance_valid(infractor) else r + Vector3(0, 0, 1.2)
	var eje := Vector3(i.x - r.x, 0.0, i.z - r.z)
	var lado := Vector3(-eje.z, 0.0, eje.x).normalized() if eje.length() > 0.3 else Vector3.RIGHT
	if lado.x < 0.0:
		lado = -lado
	var medio := (r + i) * 0.5
	var pos := medio + lado * 6.5 + Vector3(0, 1.65, 0)
	pos.x = clampf(pos.x, -36.0, 36.0)
	pos.z = clampf(pos.z, -54.0, 54.0)
	return insertar_plano("tarjeta", pos, medio + Vector3(0, 1.45, 0), 28.0, dur, arbitro)

## EL CARTEL DEL AÑADIDO, DE CERCA (pendiente del 20-10: desde la toma abierta se veía
## pequeño, como en la tele, que corta a un primer plano): el cuarto árbitro con los brazos
## arriba, desde el césped, con la tribuna detrás.
func inserto_cartel(cuarto: Node3D, dur := 2.6) -> bool:
	if not is_instance_valid(cuarto):
		return false
	var c := cuarto.global_position
	return insertar_plano("cartel", Vector3(c.x - 6.8, 2.0, c.z + 4.4), c + Vector3(-0.2, 1.95, 0), 26.0, dur, cuarto)

## Corta el inserto en curso (otra realización toma la pantalla, la jugada se reanuda…).
func quitar_inserto() -> void:
	_cancelar_inserto()
