extends Node3D
## [Capa 1/2 de `camera_rig.gd`] _add, build_for, current_name, _efectos, lectura_jugada, altura_segura … (+8)

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
const FOV_TRANSMISION := 33.0
const ALTURA_TRANSMISION := 17.0
var _trans_foco := Vector3.ZERO
var _trans_z := 0.0
var _trans_fov := FOV_TRANSMISION
## La velocidad del balón (para adelantar el plano a la jugada).
var _bola_antes := Vector3.ZERO
const ALTURA_TELE := 36.0
## Era una constante de 46 m (23-9-2026). En la forma mas chica ("ingles",
## dx=45) eso deja la camara FUERA del muro exterior del estadio, y con el
## seguimiento lateral (`t_pos.x*0.28 + 46`) se iba hasta 55,5 m: el rayo al
## balon cruzaba la losa del techo y el balon quedaba tapado por la cubierta.
## Ahora se ajusta al recinto en `build_for()` y nunca sale del cuenco.
const DISTANCIA_TELE_X_MAX := 46.0
var _dist_tele: float = DISTANCIA_TELE_X_MAX

var _mira_grada := Vector3.ZERO

## EFECTOS DE CÁMARA (14-10-2026): `impacto()` sacude la cámara (goles, entradas
## fuertes, tarjetas) y `golpe_de_zoom()` cierra el plano un instante (remates,
## goles). Se aplican al final de cada fotograma, encima de cualquier plano.
var _sacudida := 0.0
var _sacudida_dur := 0.01
var _zoom_t := 0.0
var _zoom_dur := 0.01
var _zoom_fuerza := 0.0
var _fov_base_golpe := -1.0


# --- LA TRANSMISIÓN INTELIGENTE (16-10-2026) ----------------------------------
## Pendiente desde el vídeo de FC 26 (COMPARACION_FC26_VIDEO.md, «cámaras»): el
## plano de la tele se ACERCA cuando la jugada entra en el área o hay ocasión,
## se ABRE en los contraataques y en los balones largos, ANTICIPA hacia dónde va
## el balón y no da tirones: zona muerta, amortiguador crítico (sin rebote) y
## velocidad máxima en el foco, en el carro de la cámara, en la altura y en el
## zoom. La cámara no sale nunca de su raíl (x fija dentro del cuenco, z acotada
## antes de los fondos) y baja si la losa del techo le queda a la altura.
##
## Las PISTAS las pone `VistaEstadio` leyendo el motor (sin tocarlo); sin motor
## la cámara se las arregla con el balón solo.
var plano_tanda := false    ## la tanda de penales: cámara detrás del lanzador
var pista_estado := ""      ## juego | saque | gol | descanso | fin ("" = sin motor)
var pista_ataca := 0.0      ## +1 / -1: portería que ataca quien lleva el balón; 0 = nadie
var pista_ocasion := 0.0    ## segundos de «ocasión» que quedan (tiro en el aire…)
var pista_saque := ""       ## tipo del saque en curso (corner, penal, falta, banda, …)
## Lo que decidió en el último fotograma (para las pruebas y el realizador).
var trans_plano := "normal" ## abierto | normal | area | ocasion | parado
var trans_cerca := 0.0      ## 0..1 cuánto cierra el plano
var trans_abre := 0.0       ## 0..1 cuánto lo abre
var _trans_ini := false
var _vel_suave := Vector3.ZERO
var _ancla := Vector3.ZERO
var _foco_vx := 0.0
var _foco_vz := 0.0
var _cam_vz := 0.0
var _fov_v := 0.0
var _alt_v := 0.0
var _trans_alt := ALTURA_TRANSMISION
var _zoom_usuario := 0.0
## Topes: el foco nunca corre más que esto (m/s), ni el carro, ni el zoom (°/s).
const FOCO_VMAX := 24.0
const FOCO_VMAX_ABIERTO := 34.0
const CARRO_VMAX := 15.0
const ZOOM_VMAX := 7.0
const ALTURA_VMAX := 2.5
## La zona muerta (m): dentro de ella el balón se mueve y el plano no.
const ZONA_MUERTA_X := 1.6
const ZONA_MUERTA_Z := 2.6
const FOV_CERCA := 7.5   ## grados que cierra en el área / ocasión
const FOV_ABRE := 6.0    ## grados que abre en el contraataque
const CARRO_Z_MAX := 38.0

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

	# 0. TRANSMISIÓN (13-10-2026, comparada con el vídeo de FC 26): alta, desde
	# la tribuna principal, siguiendo el balón a lo largo del campo y cerrando
	# el plano cerca del área. Es la cámara del partido con el motor real.
	_add("Transmisión", Vector3(_dist_tele, ALTURA_TRANSMISION, 0.0), Vector3(0, 0, 0), FOV_TRANSMISION)

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

func current_name() -> String:
	if camera_names.size() > current_index:
		return camera_names[current_index]
	return ""

func _efectos(delta: float) -> void:
	if cameras.is_empty():
		return
	var cam: Camera3D = cameras[current_index]
	if _zoom_t > 0.0:
		_zoom_t = maxf(_zoom_t - delta, 0.0)
		## Sube rápido y se suelta despacio (curva de ataque corto).
		var k := _zoom_t / _zoom_dur
		cam.fov = maxf(cam.fov - _zoom_fuerza * k * k, 10.0)
	## Solo en los planos que reencuadran cada fotograma (el temblor no se acumula).
	var reencuadra := current_name() in ["Transmisión", "Tele Dinámica", "Pro (Tercera Persona)", "Primera Persona (POV)", "Desde la grada (sancionado)"]
	if _sacudida > 0.001 and reencuadra:
		var a := _sacudida * 0.012
		var t := Time.get_ticks_msec() * 0.001
		cam.rotate_object_local(Vector3.RIGHT, sin(t * 47.0) * a)
		cam.rotate_object_local(Vector3.UP, sin(t * 39.0 + 1.3) * a)
		cam.rotate_object_local(Vector3.FORWARD, sin(t * 53.0 + 2.1) * a * 0.5)
		_sacudida = maxf(_sacudida - delta * _sacudida / maxf(_sacudida_dur * 0.5, 0.05) - delta * 0.15, 0.0)

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

## La altura segura del raíl: si la losa del techo (alto + 0,4) queda a la
## altura de la cámara, se baja por debajo para no ver la losa por dentro.
func altura_segura(y: float) -> float:
	var losa := _alto + 0.4
	if y > losa - 1.2 and y < losa + 1.6:
		y = losa - 1.2
	return clampf(y, 9.0, 24.0)

## SmoothDamp (amortiguador crítico de Game Programming Gems 4): llega sin pasarse
## y con la velocidad acotada. Devuelve (valor, velocidad).
static func amortiguar(actual: float, objetivo: float, vel: float, tiempo: float, vmax: float, delta: float) -> Vector2:
	if delta <= 0.0:
		return Vector2(actual, vel)
	tiempo = maxf(tiempo, 0.0001)
	var omega := 2.0 / tiempo
	var x := omega * delta
	var e := 1.0 / (1.0 + x + 0.48 * x * x + 0.235 * x * x * x)
	var cambio := clampf(actual - objetivo, -vmax * tiempo, vmax * tiempo)
	var meta := actual - cambio
	var temp := (vel + omega * cambio) * delta
	var nv := (vel - omega * temp) * e
	var res := meta + (cambio + temp) * e
	if (objetivo - actual > 0.0) == (res > objetivo):
		res = objetivo
		nv = 0.0
	return Vector2(res, nv)

func _transmision(cam: Camera3D, b: Vector3, delta: float) -> void:
	if delta <= 0.0:
		return
	var vel_b := (b - _bola_antes) / delta
	_bola_antes = b
	## Un salto (saque, reinicio, repetición) no es velocidad: no se anticipa.
	if vel_b.length() > 45.0:
		vel_b = Vector3.ZERO
	vel_b.y = 0.0
	_vel_suave = _vel_suave.lerp(vel_b, clampf(3.5 * delta, 0.0, 1.0))
	pista_ocasion = maxf(pista_ocasion - delta, 0.0)
	var lec := lectura_jugada(b, _vel_suave, pista_ataca, pista_ocasion > 0.0, pista_saque, pista_estado)
	## Histéresis: cerrar cuesta un poco, soltar cuesta más (sin parpadeo).
	trans_cerca = move_toward(trans_cerca, lec.x, (1.1 if lec.x > trans_cerca else 0.45) * delta)
	trans_abre = move_toward(trans_abre, lec.y, (0.9 if lec.y > trans_abre else 0.5) * delta)
	if pista_estado in ["gol", "descanso", "fin"]:
		trans_plano = "parado"
	elif trans_cerca > 0.55:
		trans_plano = "ocasion" if pista_ocasion > 0.0 or pista_saque in ["corner", "penal"] else "area"
	elif trans_abre > 0.45:
		trans_plano = "abierto"
	else:
		trans_plano = "normal"
	## ANTICIPAR: el foco va adonde estará el balón (más lejos al abrir) y deja
	## un poco de campo por delante del que ataca.
	var adelanto := _vel_suave * lerpf(0.45, 0.85, trans_abre)
	adelanto = adelanto.limit_length(lerpf(9.0, 15.0, trans_abre))
	var espacio := pista_ataca * 4.0 * (1.0 - trans_cerca) if pista_estado == "juego" else 0.0
	var foco := Vector3(b.x * 0.45 + adelanto.x * 0.4, 0.0, b.z + adelanto.z + espacio)
	## Con el plano cerrado se mete la portería en el cuadro.
	if trans_cerca > 0.0:
		var arco_z := signf(pista_ataca if pista_ataca != 0.0 else b.z) * 50.0
		foco.z = lerpf(foco.z, (foco.z + arco_z) * 0.5, 0.35 * trans_cerca)
	## Por la banda de la cámara el foco no pasa de x=4 (si no, plano cenital
	## encima de los jugadores); con el plano cerrado se deja llegar a x=10
	## para que un córner o un centro desde esa banda no quede en el borde.
	foco.x = clampf(foco.x, -18.0, lerpf(4.0, 10.0, trans_cerca))
	foco.z = clampf(foco.z, -47.0, 47.0)
	if not _trans_ini:
		_trans_ini = true
		_ancla = foco
		_trans_foco = foco
		_trans_z = clampf(foco.z * 0.78, -CARRO_Z_MAX, CARRO_Z_MAX)
		_trans_fov = FOV_TRANSMISION
		_trans_alt = altura_segura(ALTURA_TRANSMISION)
	## ZONA MUERTA (más estrecha con el plano cerrado: ahí cada metro cuenta).
	var zm := 1.0 - 0.6 * trans_cerca
	var ddx := foco.x - _ancla.x
	var ddz := foco.z - _ancla.z
	if absf(ddx) > ZONA_MUERTA_X * zm:
		_ancla.x = foco.x - signf(ddx) * ZONA_MUERTA_X * zm
	if absf(ddz) > ZONA_MUERTA_Z * zm:
		_ancla.z = foco.z - signf(ddz) * ZONA_MUERTA_Z * zm
	var t_foco := lerpf(0.5, 0.32, trans_cerca)
	var vmax := lerpf(FOCO_VMAX, FOCO_VMAX_ABIERTO, trans_abre)
	var rx := amortiguar(_trans_foco.x, _ancla.x, _foco_vx, t_foco, vmax, delta)
	var rz := amortiguar(_trans_foco.z, _ancla.z, _foco_vz, t_foco, vmax, delta)
	_trans_foco = Vector3(rx.x, 0.0, rz.x)
	_foco_vx = rx.y
	_foco_vz = rz.y
	## El carro de la cámara por la tribuna (algo menos que el foco).
	var rc := amortiguar(_trans_z, clampf(_trans_foco.z * 0.78, -CARRO_Z_MAX, CARRO_Z_MAX), _cam_vz, 0.9, CARRO_VMAX, delta)
	_trans_z = rc.x
	_cam_vz = rc.y
	## Zoom y altura: cerrar en el área, abrir en la contra.
	var fov_obj := clampf(FOV_TRANSMISION - FOV_CERCA * trans_cerca + FOV_ABRE * trans_abre + _zoom_usuario, 18.0, 60.0)
	var rf := amortiguar(_trans_fov, fov_obj, _fov_v, 0.8, ZOOM_VMAX, delta)
	_trans_fov = rf.x
	_fov_v = rf.y
	var alt_obj := altura_segura(ALTURA_TRANSMISION - 2.5 * trans_cerca + 2.0 * trans_abre)
	var ra := amortiguar(_trans_alt, alt_obj, _alt_v, 1.2, ALTURA_VMAX, delta)
	_trans_alt = ra.x
	_alt_v = ra.y
	cam.global_position = Vector3(_dist_tele, _trans_alt, _trans_z)
	cam.fov = _trans_fov
	cam.look_at(_trans_foco, Vector3.UP)

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

	## LA TANDA DE PENALES (17-10-2026): plano bajo detrás del punto de penal,
	## mirando al arco de +Z (todos tiran ahí), con el lanzador y el portero en
	## cuadro. Manda sobre cualquier cámara salvo la del DT sancionado.
	if plano_tanda and c_name != "Desde la grada (sancionado)":
		var pos_t := Vector3(0.0, 2.3, MotorJugable.LARGO - MotorJugable.PUNTO_PENAL - 7.5)
		cam.global_position = cam.global_position.lerp(pos_t, clampf(3.0 * delta, 0.0, 1.0)) if cam.global_position.distance_to(pos_t) < 30.0 else pos_t
		cam.fov = lerpf(cam.fov, 42.0, clampf(3.0 * delta, 0.0, 1.0))
		cam.look_at(Vector3(0.0, 1.0, MotorJugable.LARGO), Vector3.UP)
		_efectos(delta)
		return

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
		"Transmisión":
			## Sigue al BALÓN aunque haya un jugador elegido (como en FC: el plano
			## es de la jugada, no del que manejas).
			_transmision(cam, balon_ref.global_position if is_instance_valid(balon_ref) else t_pos, delta)
		"Desde la grada (sancionado)":
			## El DT sancionado sigue el partido con la cabeza desde su butaca.
			_mira_grada = _mira_grada.lerp(t_pos + Vector3(0, 0.4, 0), 3.0 * delta)
			cam.look_at(_mira_grada, Vector3.UP)
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
	_efectos(delta)

func impacto(fuerza: float, dur: float = 0.5) -> void:
	_sacudida = maxf(_sacudida, clampf(fuerza, 0.0, 1.5))
	_sacudida_dur = maxf(dur, 0.05)

func golpe_de_zoom(grados: float, dur: float = 0.6) -> void:
	_zoom_fuerza = grados
	_zoom_t = dur
	_zoom_dur = maxf(dur, 0.05)

func switch_to(idx: int) -> void:
	if idx < 0 or idx >= cameras.size():
		return
	current_index = idx
	## Al volver a la transmisión el plano arranca donde está la jugada (sin
	## un barrido largo desde donde se quedó).
	if camera_names[idx] == "Transmisión":
		_trans_ini = false
	for i in range(cameras.size()):
		cameras[i].current = (i == idx)
	camera_changed.emit(camera_names[idx])

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
