extends Node
## PERFIL DE MANEJO DEL MOTOR C4 (16-11, informe AAA, hito H1, criterios A1.1 y A1.2). Un partido REAL con `VistaEstadio`
## (como `prueba_control_equipo`), el motor movido A MANO a pasos fijos de 1/60 s y entradas reproducidas: lo sostenido con
## `Input.action_press` (palanca, sprint, carga del tiro) y las pulsaciones con `Mando.pasos_inyectar` (como el bucle del
## estadio, que las consume el primer paso). Vuelca en texto, por club:
##   · latencia en pasos entre la pulsación y la reacción del motor (pase, tiro al soltar, toque corto de tiro, cambio);
##   · aceleración 0 → punta (con y sin balón), radio de giro a punta y coste del giro de 90° y 180° con balón;
##   · error angular del pase manual, dónde se para un pase manual raso de 12 m (A1.2: 12 ± 1,5 m) y el primer toque.
## Nunca un solo club: tres partidos de tres países. El motor es el de por defecto (C4) salvo `MOTOR_PARTIDO`.
##   godot --headless --path . res://pruebas/_sonda/perfil_manejo.tscn
## Los rivales no entran (enfriados y apartados a 7 m) mientras se mide lo del usuario: se mide el mando, no el duelo.

const DT := 1.0 / 60.0
const CASOS := [["CHI", 4711, 0], ["ESP", 31, 2], ["ITA", 77, 5]]
var _m: MotorJugable
var _lineas: PackedStringArray = []

func _ready() -> void:
	var cfg := ConfigFile.new()
	cfg.load(CajonAjustes.RUTA)
	cfg.set_value(CajonAjustes.SECCION, "ceremonia", false)
	cfg.set_value(CajonAjustes.SECCION, "intro", false)
	cfg.save(CajonAjustes.RUTA)
	Mando.cargar()
	var ayudas_antes: Dictionary = Mando.ayudas.duplicate()
	Mando.ayudas["direccion"] = "campo"   ## arriba = hacia el arco rival, sin depender de la cámara
	Mando.ayudas["cambio"] = "manual"
	for caso: Array in CASOS:
		await _club(String(caso[0]), int(caso[1]), int(caso[2]))
	Mando.ayudas = ayudas_antes
	Mando.pasos_activar(false)
	cfg.set_value(CajonAjustes.SECCION, "ceremonia", true)
	cfg.set_value(CajonAjustes.SECCION, "intro", true)
	cfg.set_value(CajonAjustes.SECCION, "control_equipo", false)
	cfg.save(CajonAjustes.RUTA)
	print("\n".join(_lineas))
	print("FIN perfil de manejo")
	get_tree().quit()

func _club(pais: String, semilla: int, idx: int) -> void:
	var mu := Mundo.new()
	mu.generar([pais], semilla)
	mu.mi_club_id = mu.ligas[0].clubes[idx].id
	Partido.ctx_club_id = mu.mi_club_id
	var par := mu.proximo_partido()
	var vista := VistaEstadio.new()
	add_child(vista)
	vista.abrir(par[0], 0.8, par[1], Partido.new(par[0], par[1]))
	for i in 3:
		await get_tree().process_frame
	_m = vista.get("_motor")
	_m.set_physics_process(false)
	var juego: Variant = vista.get("_juego")
	if juego != null:
		juego.set("vel_idx", 0)
	if _m.control_equipo >= 0:
		vista.call("_alternar_control_motor")
	vista.call("_alternar_control_motor")
	Mando.pasos_activar(true)
	_pasos(30)
	_lineas.append("== %s: %s vs %s · motor %s · manejas a %s" % [pais, (par[0] as Club).nombre, (par[1] as Club).nombre,
		String(_m.get_meta("motor_id", "?")), String(_m.usuario.get("slot_code", "?"))])
	_latencias()
	_aceleracion(false)
	_aceleracion(true)
	_giro_punta()
	_giro_con_balon(90.0)
	_giro_con_balon(180.0)
	_pase_manual()
	_primer_toque()
	_soltar_todo()
	vista.queue_free()
	for i in 2:
		await get_tree().process_frame

## ---------- utilidades ----------
func _pasos(n: int, inyectar: Array = []) -> void:
	for i in n:
		for a: StringName in (inyectar if i == 0 else []):
			Mando.pasos_inyectar(a)
		_apartar_rivales()
		_m.paso(DT)
		Mando.pasos_consumir()

func _apartar_rivales() -> void:
	var u := _m.usuario
	if u.is_empty():
		return
	for q: Dictionary in _m.jugadores:
		if bool(q["es_local"]) == bool(u["es_local"]) or bool(q["por"]):
			continue
		q["enfriar"] = 3.0
		var d: Vector3 = _m.pos(q) - _m.pos(u)
		d.y = 0.0
		if d.length() < 7.0:
			(q["node"] as Node3D).position = _m.pos(u) + (d.normalized() if d.length() > 0.01 else Vector3.RIGHT) * 7.0

func _soltar_todo() -> void:
	for a in ["jugar_arriba", "jugar_abajo", "jugar_izquierda", "jugar_derecha", "jugar_sprint", "jugar_tiro", "jugar_mod"]:
		Input.action_release(a)

func _sostener(acciones: Array) -> void:
	_soltar_todo()
	for a: String in acciones:
		Input.action_press(a)

func _d() -> float:
	return MotorJugable.dir_ataque(bool(_m.usuario["es_local"]))

## El jugador que manejas, quieto en (x, z) de su campo de ataque (z en su sentido) y con el balón si `con_balon`.
func _colocar(x: float, z: float, con_balon: bool) -> Dictionary:
	var u: Dictionary = _m.usuario
	var d := _d()
	_m.estado = "juego"
	_m.set("_tiro_vivo", {})
	_m.set("_offside", {})
	_m.bloqueo = true
	(u["node"] as Node3D).position = Vector3(x, 0, z * d)
	(u["node"] as Node3D).rotation.y = 0.0 if d > 0.0 else PI
	u["vel"] = Vector3.ZERO
	_m.poseedor = {}
	_m.vel_balon = Vector3.ZERO
	_m.giro_balon = Vector3.ZERO
	if con_balon:
		_m.balon.position = Vector3(x, 0.11, z * d + 0.4 * d)
		_m.call("_tomar", u)
	else:
		_companero_con_balon(Vector3(signf(-x + 0.01) * 28.0, 0, -44.0 * d))
	return u

## Sin balón para el que manejas: lo guarda un compañero lejos (sin decidir en 30 s), para que nadie corte la medida.
func _companero_con_balon(lugar: Vector3) -> void:
	for q: Dictionary in _m.jugadores:
		if q != _m.usuario and bool(q["es_local"]) == bool(_m.usuario["es_local"]) and not bool(q["por"]):
			(q["node"] as Node3D).position = lugar
			q["vel"] = Vector3.ZERO
			_m.balon.position = lugar + Vector3(0, 0.11, 0.4)
			_m.call("_tomar", q)
			_m.set("_decision_en", _m.t + 30.0)
			return

func _vel(u: Dictionary) -> Vector3:
	var v: Vector3 = u["vel"]
	return Vector3(v.x, 0, v.z)

## ---------- 1. latencias ----------
func _latencias() -> void:
	_soltar_todo()
	## Pase: pulsación inyectada; pasos hasta que cuenta el pase y hasta que el balón sale (> 3 m/s lejos del pie).
	var r_pase: Array = []
	for k in 3:
		var u := _colocar(0.0, -10.0 + k * 6.0, true)
		_pasos(12)
		var pases0 := int(_m.pases[0 if bool(u["es_local"]) else 1])
		var cuenta := -1
		var sale := -1
		for i in 30:
			_pasos(1, [&"jugar_pase"] if i == 0 else [])
			if cuenta < 0 and (int(_m.pases[0 if bool(u["es_local"]) else 1]) > pases0 or _m.poseedor != u):
				cuenta = i + 1
			if sale < 0 and _m.vel_balon.length() > 3.0:
				sale = i + 1
			if cuenta > 0 and sale > 0:
				break
		r_pase.append("%d/%d" % [cuenta, sale])
	## Tiro: se carga sosteniendo 10 pasos y sale al SOLTAR; y un toque de un paso.
	var r_tiro: Array = []
	for corto: bool in [false, true]:
		var u := _colocar(2.0, 30.0, true)
		_pasos(8)
		var t0 := int(_m.tiros[0 if bool(u["es_local"]) else 1])
		_sostener(["jugar_tiro"])
		_pasos(1 if corto else 10)
		Input.action_release("jugar_tiro")
		var cuenta := -1
		var sale := -1
		for i in 30:
			_pasos(1)
			if cuenta < 0 and int(_m.tiros[0 if bool(u["es_local"]) else 1]) > t0:
				cuenta = i + 1
			if sale < 0 and _m.vel_balon.length() > 6.0:
				sale = i + 1
		r_tiro.append("%s %d/%d" % ["toque" if corto else "cargado", cuenta, sale])
	## Cambio de jugador: con el balón en un rival, Q (jugar_cambiar) cambia al que manejas.
	var u0 := _colocar(0.0, -5.0, false)
	_m.bloqueo = false
	var rival := _rival_con_balon(Vector3(0, 0, 5.0 * _d()))
	_pasos(6)
	var antes := _m.usuario
	var cambio := -1
	for i in 10:
		_pasos(1, [&"jugar_cambiar"] if i == 0 else [])
		if _m.usuario != antes:
			cambio = i + 1
			break
	_lineas.append("  LATENCIA (pasos de 1/60 s; cuenta/sale): pase %s · tiro %s · cambio %d%s" % [
		", ".join(r_pase), ", ".join(r_tiro), cambio, "" if not rival.is_empty() and not u0.is_empty() else " (sin rival)"])

func _rival_con_balon(lugar: Vector3) -> Dictionary:
	for q: Dictionary in _m.jugadores:
		if bool(q["es_local"]) != bool(_m.usuario["es_local"]) and not bool(q["por"]):
			(q["node"] as Node3D).position = lugar
			_m.balon.position = lugar + Vector3(0, 0.11, 0.4)
			_m.poseedor = {}
			_m.call("_tomar", q)
			_m.set("_decision_en", _m.t + 30.0)
			return q
	return {}

## ---------- 2. aceleración 0 → punta ----------
func _aceleracion(con_balon: bool) -> void:
	var cifras: Array = []
	for sprint: bool in [false, true]:
		var u := _colocar(0.0, -30.0, con_balon)
		_pasos(6)
		_sostener(["jugar_arriba", "jugar_sprint"] if sprint else ["jugar_arriba"])
		var vs: Array = []
		for i in 240:
			_pasos(1)
			vs.append(_vel(u).length())
		var vmax: float = vs.max()
		var t90 := -1
		for i in vs.size():
			if float(vs[i]) >= 0.9 * vmax:
				t90 = i + 1
				break
		var en1 := float(vs[59])
		cifras.append("%s punta %.2f m/s, 90%% en %.2f s, a 1 s %.2f m/s%s" % ["sprint" if sprint else "trote", vmax, t90 * DT, en1,
			(", balón %s" % ("sí" if _m.poseedor == u else "PERDIDO")) if con_balon else ""])
	_soltar_todo()
	_lineas.append("  ACELERACIÓN %s: %s" % ["CON balón" if con_balon else "sin balón", " | ".join(cifras)])

## ---------- 3. radio de giro a punta (sin balón) ----------
func _giro_punta() -> void:
	var u := _colocar(-12.0, -35.0, false)
	_sostener(["jugar_arriba", "jugar_sprint"])
	_pasos(180)
	var v0 := _vel(u).length()
	var p0 := _m.pos(u)
	var adelante := Vector3(0, 0, _d())
	var nuevo := Vector3(-_d(), 0, 0)   ## «derecha» con dirección de campo
	_sostener(["jugar_derecha", "jugar_sprint"])
	var t90 := -1
	var vmin := v0
	var avance := 0.0
	for i in 240:
		_pasos(1)
		var v := _vel(u)
		vmin = minf(vmin, v.length())
		if t90 < 0 and v.length() > 0.5 and v.normalized().dot(nuevo) > cos(deg_to_rad(10.0)):
			t90 = i + 1
			avance = (_m.pos(u) - p0).dot(adelante)
			break
	_soltar_todo()
	if t90 < 0:
		print("  [giro] sin rumbo: vel=", _vel(u), " nuevo=", nuevo, " pos=", _m.pos(u), " manual=", u.get("manual"), " estado=", _m.estado, " usuario=", _m.usuario == u)
	_lineas.append("  GIRO 90° A PUNTA (sin balón): a %.2f m/s, rumbo nuevo (±10°) en %.2f s, radio ≈ %.2f m (avance tras ordenar el giro), velocidad mínima %.2f m/s" % [
		v0, t90 * DT, avance, vmin])

## ---------- 4. coste del giro de 90/180° con balón ----------
func _giro_con_balon(grados: float) -> void:
	var u := _colocar(-10.0, -35.0, true)
	_sostener(["jugar_arriba", "jugar_sprint"])
	_pasos(150)
	var v0 := _vel(u).length()
	var con := _m.poseedor == u
	var nuevo := Vector3(-_d(), 0, 0) if grados < 135.0 else Vector3(0, 0, -_d())
	_sostener(["jugar_derecha", "jugar_sprint"] if grados < 135.0 else ["jugar_abajo", "jugar_sprint"])
	var t_rumbo := -1
	var t_vuelve := -1
	var vmin := v0
	for i in 300:
		_pasos(1)
		var v := _vel(u)
		vmin = minf(vmin, v.length())
		if t_rumbo < 0 and v.length() > 0.5 and v.normalized().dot(nuevo) > cos(deg_to_rad(20.0)):
			t_rumbo = i + 1
		if t_rumbo > 0 and t_vuelve < 0 and v.length() >= 0.8 * v0:
			t_vuelve = i + 1
			break
	_soltar_todo()
	_lineas.append("  GIRO %d° CON BALÓN: a %.2f m/s%s, rumbo nuevo (±20°) en %.2f s, mínima %.2f m/s (−%d %%), de vuelta al 80 %% en %.2f s, balón %s" % [
		int(grados), v0, "" if con else " (sin balón al empezar)", t_rumbo * DT, vmin, int(round(100.0 * (1.0 - vmin / maxf(v0, 0.01)))),
		t_vuelve * DT, "sí" if _m.poseedor == u else "PERDIDO"])

## ---------- 5. pase manual: error angular y dónde se para el raso de 12 m ----------
func _pase_manual() -> void:
	var ayuda_antes := String(Mando.ayudas.get("pase", "asistido"))
	Mando.ayudas["pase"] = "manual"
	var errores: Array = []
	var paradas: Array = []
	var dirs := [["jugar_arriba"], ["jugar_derecha"], ["jugar_izquierda"], ["jugar_arriba", "jugar_derecha"], ["jugar_arriba", "jugar_izquierda"], ["jugar_abajo"]]
	for k in dirs.size():
		var u := _colocar(0.0, -8.0, true)
		_sostener(dirs[k])
		_pasos(4)
		var quiero: Vector3 = (u["manual"] as Vector3)
		var p0 := _m.pos(u)
		var salio := false
		for i in 20:
			_pasos(1, [&"jugar_pase"] if i == 0 else [])
			if _m.vel_balon.length() > 3.0:
				salio = true
				break
		_soltar_todo()
		if not salio or quiero.length() < 0.5:
			errores.append("—")
			continue
		var vb := Vector3(_m.vel_balon.x, 0, _m.vel_balon.z)
		errores.append("%.1f°" % rad_to_deg(vb.angle_to(quiero)))
		## Rueda solo con la física del balón del motor (nadie lo toca): ¿dónde se para?
		_m.poseedor = {}
		_m.estado = "saque"
		for i in 900:
			_m._mover_balon(DT)
			if _m.vel_balon.length() < 0.05:
				break
		var b := Vector3(_m.balon.position.x, 0, _m.balon.position.z)
		paradas.append((b - Vector3(p0.x, 0, p0.z)).length())
		_m.estado = "juego"
	Mando.ayudas["pase"] = ayuda_antes
	var media := 0.0
	for x: float in paradas:
		media += x
	media /= maxf(1.0, paradas.size())
	var txt: Array = []
	for x: float in paradas:
		txt.append("%.1f" % x)
	_lineas.append("  PASE MANUAL 12 m: error angular %s · se para a %s m (media %.1f; A1.2 pide 12 ± 1,5) %s" % [
		", ".join(errores), ", ".join(txt), media, "OK" if absf(media - 12.0) <= 1.5 else "FUERA"])

## ---------- 6. primer toque ----------
func _primer_toque() -> void:
	var u := _colocar(0.0, -15.0, false)
	var q: Dictionary = {}
	for c: Dictionary in _m.jugadores:
		if c != u and bool(c["es_local"]) == bool(u["es_local"]) and not bool(c["por"]):
			q = c
			break
	var d := _d()
	(q["node"] as Node3D).position = Vector3(-14.0, 0, -15.0 * d)
	q["vel"] = Vector3.ZERO
	_m.balon.position = Vector3(-14.0, 0.11, -15.0 * d + 0.4 * d)
	_m.poseedor = {}
	_m.call("_tomar", q)
	_m.call("_pasar_a", q, u)
	var v_sale := _m.vel_balon.length()
	var control := -1
	var v_llega := 0.0
	var sep_max := 0.0
	var v_prev := v_sale
	for i in 240:
		if control < 0:
			v_prev = _m.vel_balon.length()
		_pasos(1)
		if control < 0 and _m.poseedor == u:
			control = i + 1
			v_llega = v_prev
		if control > 0:
			var b := _m.balon.position - _m.pos(u)
			sep_max = maxf(sep_max, Vector2(b.x, b.z).length())
			if i + 1 - control >= 45:
				break
	_lineas.append("  PRIMER TOQUE: pase de 14 m a %.1f m/s, controlado a los %.2f s llegando a %.1f m/s; en el 0,75 s siguiente el balón se aleja hasta %.2f m del pie%s" % [
		v_sale, control * DT, v_llega, sep_max, "" if control > 0 else " (NO lo controló)"])
