extends Node
## (Parte 1 de 2 de `repeticion.gd`: la norma de 450 líneas lo partió en capas, cada una extiende a la anterior; la última, `repeticion.gd`, conserva la clase.)

## LA REPETICIÓN (25-9-2026, plan maestro B3; realización de TV el 25-10-2026, M-134/M-135).
## Como en una transmisión: tras el gol (o a pedido), la jugada otra vez, con cortes entre
## varios ángulos y la velocidad en RAMPA (casi a tiempo real en el armado, súper lenta en
## el remate), como la realización del vídeo de FC 26.
##
## CÓMO. Mientras se juega, `_process` guarda 20 veces por segundo el estado de cada jugador
## (transform, animación y punto de la animación) y del balón, y conserva los últimos
## `SEGUNDOS_GUARDADOS`. `reproducir()`:
##   1. fotografía el estado EN VIVO de todos (para devolverlo luego tal cual);
##   2. busca el MOMENTO CLAVE (el golpeo: donde más acelera el balón) y planifica los planos:
##        tele    alta y cerrada desde el lado de la tribuna principal (el armado, a 0,8);
##        remate  a ras de césped detrás del que remata (el golpeo, a 0,3);
##        arco / linea   detrás de la red o en la LÍNEA DE GOL (el balón entrando, a 0,45),
##                alternando entre una repetición y la siguiente;
##        ras     el contraplano bajo desde la otra banda (las jugadas que no son gol);
##   3. recorre los fotogramas guardados INTERPOLANDO entre cuadros (posiciones y punto de
##      cada animación: sin saltos de 20 Hz en la cámara lenta), con la cámara que encuadra
##      con inercia de operador (sin latigazos) y ninguna dentro de la grada (`dx`/`dz`);
##   4. con el balón en la red aguanta un instante, sale con el barrido de marca (si hay
##      `ui_barrido`), devuelve a cada uno a su estado en vivo y emite `terminada`.
## Quien la usa (`VistaEstadio`, `PartidoJugable`) congela el reloj del partido mientras
## tanto: la repetición no juega minutos ni toca `Azar`. `saltar()` la acaba (con barrido)
## y `cortar()` la corta en seco.

signal terminada

const HZ := 20.0
const SEGUNDOS_GUARDADOS := 12.0
## La cámara lenta de referencia (sin momento clave claro).
const VELOCIDAD := 0.5
const VEL_ARMADO := 0.8
const VEL_REMATE := 0.3
const VEL_FINAL := 0.45
## Cuánto cambia la velocidad por segundo real: la rampa, sin saltos de velocidad.
const RAMPA := 1.4
## Segundos reales con el balón quieto en la red antes de salir.
const PAUSA_FINAL := 0.7
const SEG_BARRIDO := 0.45
## Un golpeo: el balón gana al menos esto (m/s) de un cuadro al siguiente.
const ACELERON_MIN := 6.0

var reproduciendo := false
## Sin grabar (la celebración del motor real): la repetición termina en el gol.
var congelar := false
## La geometría del estadio (centro de las tribunas laterales / de fondo): ninguna cámara
## de la repetición se mete en la grada. Por defecto, el estadio más chico.
var dx := 43.5
var dz := 62.5
## El barrido de marca a la entrada y a la salida (opcional): dónde y con qué club.
var ui_barrido: Control
var club_barrido: Club
## Lo que se planificó (para las pruebas): [{n, desde, hasta, vel}] y el plano en pantalla.
var planos: Array = []
var plano_actual := ""
var t_clave := -1.0
var es_gol := false

var _jugadores: Array = []     ## los diccionarios de `_en_campo` (node, anim)
var _balon: Node3D
var _cuadros: Array = []       ## [{t, j: [[Transform3D, anim, pos]], b: Transform3D}]
var _t := 0.0
var _prox := 0.0
var _vivo: Array = []
var _cams: Dictionary = {}     ## nombre del plano -> Camera3D
var _cam_previa: Camera3D
var _rep_t := 0.0
var _rep_desde := 0.0
var _rep_hasta := 0.0
var _vel := VELOCIDAD
var _i := 0
var _espera := 0.0             ## la entrada: el barrido cubre la pantalla antes del corte
var _pausa := 0.0
var _salida := -1.0
var _mira := Vector3.ZERO
var _lado := 1.0
var _n_repes := 0

func setup(jugadores: Array, balon: Node3D) -> void:
	_jugadores = jugadores
	_balon = balon

func _process(delta: float) -> void:
	if reproduciendo:
		_avanzar_repeticion(delta)
		return
	if congelar:
		return
	_t += delta
	if _t < _prox:
		return
	_prox = _t + 1.0 / HZ
	var j: Array = []
	for f: Dictionary in _jugadores:
		var n: Node3D = f.get("node")
		var ap: AnimationPlayer = f.get("anim")
		if not is_instance_valid(n):
			j.append(null)
			continue
		var anim := ""
		var pos := 0.0
		if is_instance_valid(ap) and ap.current_animation != "":
			anim = ap.current_animation
			pos = ap.current_animation_position
		j.append([n.global_transform, anim, pos])
	_cuadros.append({"t": _t, "j": j, "b": _balon.global_transform if is_instance_valid(_balon) else Transform3D.IDENTITY})
	while not _cuadros.is_empty() and _t - float(_cuadros[0]["t"]) > SEGUNDOS_GUARDADOS:
		_cuadros.pop_front()

## Cuántos segundos hay guardados (para las pruebas).
func segundos_guardados() -> float:
	if _cuadros.size() < 2:
		return 0.0
	return float(_cuadros[-1]["t"]) - float(_cuadros[0]["t"])

## Repite los últimos `segundos` (o los que haya). Devuelve false si no hay nada.
## `con_barrido`: entra con el barrido de marca (la repetición a pedido; tras la realización
## del gol ya lo pone `CineGol`).
func reproducir(segundos: float = 8.0, con_barrido := false) -> bool:
	if reproduciendo or _cuadros.size() < int(HZ):
		return false
	reproduciendo = true
	## Estado en vivo, para devolverlo tal cual al terminar.
	_vivo.clear()
	for f: Dictionary in _jugadores:
		var n: Node3D = f.get("node")
		var ap: AnimationPlayer = f.get("anim")
		if not is_instance_valid(n):
			_vivo.append(null)
			continue
		var anim: String = ap.current_animation if is_instance_valid(ap) else ""
		var pos: float = ap.current_animation_position if is_instance_valid(ap) and anim != "" else 0.0
		var vel: float = ap.speed_scale if is_instance_valid(ap) else 1.0
		_vivo.append([n.global_transform, anim, pos, vel])
		if is_instance_valid(ap):
			ap.speed_scale = 0.0
	_vivo.append(_balon.global_transform if is_instance_valid(_balon) else Transform3D.IDENTITY)
	_rep_hasta = float(_cuadros[-1]["t"])
	_rep_desde = maxf(float(_cuadros[0]["t"]), _rep_hasta - segundos)
	_rep_t = _rep_desde
	_i = 0
	_pausa = 0.0
	_salida = -1.0
	_planificar()
	_n_repes += 1
	_cam_previa = get_viewport().get_camera_3d()
	_espera = 0.0
	if con_barrido and _barrido(SEG_BARRIDO):
		_espera = SEG_BARRIDO * 0.5
	else:
		_entrar()
	return true

## La acaba ya, con su salida (barrido incluido): el botón de saltar.
func saltar() -> void:
	if not reproduciendo or _salida >= 0.0:
		return
	if _espera > 0.0:
		_espera = 0.0
		_entrar()
	_rep_t = _rep_hasta
	_pausa = PAUSA_FINAL
	_aplicar(_rep_t)
	_empezar_salida()

## La corta en seco (otro suceso encima): sin barrido.
func cortar() -> void:
	if reproduciendo:
		(self as Repeticion)._terminar()

# --------------------------------------------------------------- la realización

## El balón en el cuadro guardado `k`.
func _b(k: int) -> Vector3:
	return (_cuadros[clampi(k, 0, _cuadros.size() - 1)]["b"] as Transform3D).origin

## El MOMENTO CLAVE: el último golpeo fuerte de la jugada (el balón gana de golpe al menos
## el 60 % del mayor acelerón visto). Para un gol, el remate. -1 si no hay ninguno claro.
static func momento_clave(tiempos: PackedFloat32Array, bolas: PackedVector3Array, desde: float, hasta: float) -> float:
	var golpes: Array = []   ## [t, acelerón]
	var mayor := 0.0
	var v_antes := -1.0
	for k in range(1, tiempos.size()):
		var tk := tiempos[k]
		if tk < desde + 0.6 or tk > hasta:
			v_antes = -1.0
			continue
		var v := bolas[k].distance_to(bolas[k - 1]) / maxf(tk - tiempos[k - 1], 0.001)
		## Un salto de sitio (reinicio, saque tras gol) no es un golpeo; el balón queda
		## colocado (quieto) y lo que salga de ahí sí cuenta (un tiro libre, un penal).
		if v > 60.0:
			v_antes = 0.0
			continue
		if v_antes >= 0.0 and v - v_antes >= ACELERON_MIN:
			golpes.append([tiempos[k - 1], v - v_antes])
			mayor = maxf(mayor, v - v_antes)
		v_antes = v
	for i in range(golpes.size() - 1, -1, -1):
		if float(golpes[i][1]) >= mayor * 0.6:
			return float(golpes[i][0])
	return -1.0

func _momento_clave() -> float:
	var ts := PackedFloat32Array()
	var bs := PackedVector3Array()
	for k in _cuadros.size():
		ts.append(float(_cuadros[k]["t"]))
		bs.append(_b(k))
	return momento_clave(ts, bs, _rep_desde, _rep_hasta)

func _cuadro_de(t: float) -> int:
	for k in _cuadros.size():
		if float(_cuadros[k]["t"]) >= t:
			return k
	return _cuadros.size() - 1

func _planificar() -> void:
	planos.clear()
	var fin := _b(_cuadros.size() - 1)
	es_gol = congelar or (absf(fin.z) > MotorJugable.LARGO - 0.9 and absf(fin.x) < 5.0)
	t_clave = _momento_clave()
	var tk := t_clave
	## Hacia qué portería va la jugada: la del gol, o hacia donde salió el golpeo.
	if es_gol:
		_lado = signf(fin.z) if absf(fin.z) > 1.0 else 1.0
	elif tk >= 0.0:
		var k := _cuadro_de(tk)
		var dir := _b(k + 2) - _b(k)
		_lado = signf(dir.z) if absf(dir.z) > 0.3 else (signf(fin.z) if absf(fin.z) > 1.0 else 1.0)
	else:
		_lado = signf(fin.z) if absf(fin.z) > 1.0 else 1.0
	var d := _rep_desde
	var h := _rep_hasta
	if tk >= 0.0:
		var a := maxf(d, tk - 1.1)
		if a - d > 0.6:
			planos.append({"n": "tele", "desde": d, "hasta": a, "vel": VEL_ARMADO})
		else:
			a = d
		if es_gol:
			var r := clampf(tk + 0.5, a + 0.6, maxf(h - 0.4, a + 0.6))
			planos.append({"n": "remate", "desde": a, "hasta": minf(r, h), "vel": VEL_REMATE})
			if h - r > 0.05:
				planos.append({"n": "linea" if _n_repes % 2 == 1 else "arco", "desde": r, "hasta": h, "vel": VEL_FINAL})
		else:
			var r2 := minf(tk + 1.3, h)
			planos.append({"n": "remate", "desde": a, "hasta": r2, "vel": VEL_REMATE + 0.05})
			if h - r2 > 0.3:
				planos.append({"n": "ras", "desde": r2, "hasta": h, "vel": 0.6})
	else:
		var m := d + (h - d) * (0.7 if es_gol else 0.5)
		planos.append({"n": "tele", "desde": d, "hasta": m, "vel": 0.6})
		planos.append({"n": "arco" if es_gol else "ras", "desde": m, "hasta": h, "vel": VEL_FINAL})
	_vel = float(planos[0]["vel"])

func _entrar() -> void:
	_montar_camaras()
	plano_actual = ""
	_aplicar(_rep_t)
	_elegir_plano(0.0)

func _montar_camaras() -> void:
	for c: Camera3D in _cams.values():
		if is_instance_valid(c):
			c.queue_free()
	_cams.clear()
	for p: Dictionary in planos:
		var n := String(p["n"])
		if _cams.has(n):
			continue
		var c := Camera3D.new()
		c.name = "Repeticion_" + n
		c.far = 600.0
		add_child(c)
		_cams[n] = c
	## Los planos fijos se colocan ya; los que siguen al balón, en cada fotograma.
	var x_tv := minf(dx - 7.5, 40.0)
	var gol_z := _lado * MotorJugable.LARGO
	if _cams.has("remate"):
		var k := _cuadro_de(t_clave if t_clave >= 0.0 else _rep_desde)
		var b := _b(k)
		var hacia := Vector3(0.0, 0.0, gol_z) - Vector3(b.x, 0.0, b.z)
		hacia = hacia.normalized() if hacia.length() > 0.5 else Vector3(0, 0, _lado)
		## Detrás del que remata y un poco hacia la tribuna principal (no cruza el eje).
		var lado_tv := Vector3(-hacia.z, 0.0, hacia.x)
		if lado_tv.x < 0.0:
			lado_tv = -lado_tv
		var p := b - hacia * 9.5 + lado_tv * 2.5
		(_cams["remate"] as Camera3D).global_position = Vector3(clampf(p.x, -32.5, 32.5), 2.5, clampf(p.z, -51.0, 51.0))
	if _cams.has("arco"):
		var fin := _b(_cuadros.size() - 1)
		(_cams["arco"] as Camera3D).global_position = Vector3(fin.x * 0.3, 4.2, _lado * minf(MotorJugable.LARGO + 8.0, dz - 6.5))
	if _cams.has("linea"):
		## La cámara de la LÍNEA DE GOL (M-135): sobre la propia línea, del lado de la tribuna
		## principal, baja: se ve si el balón entró entero.
		(_cams["linea"] as Camera3D).global_position = Vector3(minf(24.0, x_tv), 1.3, gol_z)
	if _cams.has("ras"):
		(_cams["ras"] as Camera3D).global_position = Vector3(-29.0, 2.4, _b(_cuadros.size() - 1).z * 0.7)
	if _cams.has("tele"):
		(_cams["tele"] as Camera3D).global_position = Vector3(x_tv, 7.0, clampf(_b(_cuadro_de(_rep_desde)).z * 0.8, -40.0, 40.0))

## El plano que toca en `_rep_t`; al cambiar, CORTE (la mirada salta al balón, sin barrer).
func _elegir_plano(_delta: float) -> Dictionary:
	var elegido: Dictionary = planos[planos.size() - 1]
	for p: Dictionary in planos:
		if _rep_t < float(p["hasta"]):
			elegido = p
			break
	var n := String(elegido["n"])
	if n != plano_actual:
		plano_actual = n
		var c: Camera3D = _cams.get(n)
		if is_instance_valid(c):
			c.current = true
		_mira = _objetivo(n)
		_encuadrar(n, 1.0, 0.0)
	return elegido

## Adónde mira cada plano: al balón (la línea de gol, a la boca del arco con algo de balón).
func _objetivo(n: String) -> Vector3:
	var b := _balon.global_position if is_instance_valid(_balon) else Vector3.ZERO
	if n == "linea":
		return Vector3(0.0, 1.1, _lado * MotorJugable.LARGO).lerp(Vector3(b.x, maxf(b.y, 0.5), _lado * MotorJugable.LARGO), 0.35)
	return b + Vector3(0, 0.35, 0)

## Mueve y encuadra la cámara del plano `n`. `k`: cuánto se acerca a su objetivo este fotograma.
func _encuadrar(n: String, k: float, delta: float) -> void:
	var c: Camera3D = _cams.get(n)
	if not is_instance_valid(c):
		return
	var b := _balon.global_position if is_instance_valid(_balon) else Vector3.ZERO
	_mira = _mira.lerp(_objetivo(n), k)
	var p: Dictionary = {}
	for q: Dictionary in planos:
		if String(q["n"]) == n:
			p = q
	var f := 0.0
	if not p.is_empty():
		f = clampf((_rep_t - float(p["desde"])) / maxf(float(p["hasta"]) - float(p["desde"]), 0.01), 0.0, 1.0)
	match n:
		"tele":
			## Por el raíl de la tribuna principal, a la altura de la jugada, con el zoom que
			## deja ~24 m de campo a lo ancho.
			var z_obj := clampf(b.z * 0.8, -40.0, 40.0)
			c.global_position.z = lerpf(c.global_position.z, z_obj, clampf(2.0 * delta, 0.0, 1.0)) if delta > 0.0 else z_obj
			var dist := c.global_position.distance_to(_mira)
			c.fov = clampf(rad_to_deg(2.0 * atan(7.5 / maxf(dist, 1.0))), 13.0, 40.0)
		"remate":
			c.fov = lerpf(34.0, 26.0, f)
		"arco":
			c.fov = lerpf(42.0, 32.0, f)
		"linea":
			c.fov = 22.0
		"ras":
			c.fov = 30.0
	if c.global_position.distance_to(_mira) > 0.5:
		c.look_at(_mira, Vector3.UP)

func _avanzar_repeticion(delta: float) -> void:
	if _espera > 0.0:
		_espera -= delta
		if _espera <= 0.0:
			_entrar()
		return
	if _salida >= 0.0:
		_salida -= delta
		if _salida < 0.0:
			(self as Repeticion)._terminar()
		return
	if _rep_t >= _rep_hasta:
		## El balón en la red: un instante quieto (el «beat» de la tele) y fuera.
		_pausa += delta
		if _pausa >= (PAUSA_FINAL if es_gol else 0.25):
			_empezar_salida()
		return
	var p := _elegir_plano(delta)
	_vel = move_toward(_vel, float(p["vel"]), RAMPA * delta)
	_rep_t = minf(_rep_t + delta * _vel, _rep_hasta)
	_aplicar(_rep_t)
	_encuadrar(plano_actual, 1.0 - exp(-7.0 * delta), delta)

func _empezar_salida() -> void:
	if _salida >= 0.0:
		return
	if _barrido(SEG_BARRIDO):
		_salida = SEG_BARRIDO * 0.5
	else:
		(self as Repeticion)._terminar()

func _barrido(seg: float) -> bool:
	if not is_instance_valid(ui_barrido) or club_barrido == null:
		return false
	CineGol.barrido(ui_barrido, club_barrido, seg)
	return true

## Coloca a todos en el instante `t` de lo grabado, INTERPOLANDO entre los dos cuadros que lo
## rodean: a 0,3 de velocidad, 20 Hz serían 6 saltos por segundo en pantalla.
func _aplicar(t: float) -> void:
	if _cuadros.is_empty():
		return
	while _i + 1 < _cuadros.size() and float(_cuadros[_i + 1]["t"]) <= t:
		_i += 1
	var ca: Dictionary = _cuadros[_i]
	var cb: Dictionary = _cuadros[mini(_i + 1, _cuadros.size() - 1)]
	var ta := float(ca["t"])
	var tb := float(cb["t"])
	var f := clampf((t - ta) / (tb - ta), 0.0, 1.0) if tb > ta else 0.0
	var ja: Array = ca["j"]
	var jb: Array = cb["j"]
	for i in mini(ja.size(), _jugadores.size()):
		var ea: Variant = ja[i]
		if ea == null:
			continue
		var eb: Variant = jb[i] if i < jb.size() and jb[i] != null else ea
		var fd: Dictionary = _jugadores[i]
		var n: Node3D = fd.get("node")
		var ap: AnimationPlayer = fd.get("anim")
		if not is_instance_valid(n):
			continue
		var xa: Transform3D = (ea as Array)[0]
		var xb: Transform3D = (eb as Array)[0]
		## Un salto de sitio (cambio, reinicio) no se interpola: se corta.
		n.global_transform = xa.interpolate_with(xb, f) if xa.origin.distance_to(xb.origin) < 3.0 else xa
		var anim := String(ea[1])
		if is_instance_valid(ap) and anim != "" and ap.has_animation(anim):
			if ap.current_animation != anim:
				ap.play(anim, 0.0)
				ap.speed_scale = 0.0
			ap.seek(Repeticion._punto_anim(ap, anim, float(ea[2]), String(eb[1]), float(eb[2]), f, tb - ta), true)
	if is_instance_valid(_balon):
		var ba: Transform3D = ca["b"]
		var bb: Transform3D = cb["b"]
		_balon.global_transform = ba.interpolate_with(bb, f) if ba.origin.distance_to(bb.origin) < 4.0 else ba
