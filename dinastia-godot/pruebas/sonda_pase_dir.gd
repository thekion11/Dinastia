extends RefCounted
## Partes B y C de `sonda_mando_f3.gd` (frente 3, 16-11-2026): el pase por dirección de la palanca y el «bot humano».
## Solo LEE el motor (B no toca su azar: `_companero_en_direccion` es determinista); C juega con el mando simulado.

const ACC: Array[String] = ["jugar_izquierda", "jugar_derecha", "jugar_arriba", "jugar_abajo", "jugar_sprint", "jugar_pase", "jugar_filtrado", "jugar_tiro"]

var _b := {"n": 0, "hay30": 0, "obedece30": 0, "obedece45": 0, "mas_alineado": 0, "err_suma": 0.0, "detras": 0,
	"elegido_tapado": 0, "hay_limpio30": 0, "tapado_con_limpio": 0, "n_adelante": 0, "obedece30_adelante": 0, "hay30_adelante": 0}
var _errs: Array[float] = []
## (c) colocación y presión del que defiende: muestras cada segundo y cambios de posesión en cada paso.
var _f := {"muestras": 0, "entre_lineas": 0.0, "largo": 0.0, "ancho": 0.0, "presion_m": 0.0, "rivales_5m": 0.0,
	"recuperaciones": 0, "rec_campo_rival": 0, "rec_tercio": 0, "t_recuperar": 0.0, "partidos": 0}
var _c := {"pases": 0, "al_apuntado": 0, "ok": 0, "cortados": 0, "sueltos": 0, "hueco": 0, "hueco_ok": 0, "hueco_apuntado": 0,
	"corto": 0, "corto_ok": 0, "medio": 0, "medio_ok": 0, "largo": 0, "largo_ok": 0, "tiros": 0, "goles_u": 0, "pases_motor": 0, "pases_ok_motor": 0}

## La palanca simulada hacia `mundo` (sin cámara: adelante en la pantalla = hacia el arco rival, como `_a_mundo`).
static func apuntar(mundo: Vector3, d: float) -> void:
	if mundo.length() < 0.05:
		return
	var w := mundo.normalized()
	var sx := -w.x / d
	var sy := -w.z / d
	if sx < -0.05:
		Input.action_press("jugar_izquierda", minf(1.0, -sx))
	elif sx > 0.05:
		Input.action_press("jugar_derecha", minf(1.0, sx))
	if sy < -0.05:
		Input.action_press("jugar_arriba", minf(1.0, -sy))
	elif sy > 0.05:
		Input.action_press("jugar_abajo", minf(1.0, sy))

static func _soltar() -> void:
	for acc in ACC:
		Input.action_release(acc)

## Ángulo (grados) entre la dirección y el compañero.
static func _ang(motor: MotorJugable, p: Dictionary, q: Dictionary, dir: Vector3) -> float:
	var v := motor.pos(q) - motor.pos(p)
	v.y = 0.0
	return rad_to_deg(v.angle_to(dir)) if v.length() > 0.01 else 180.0

# ------------------------------------------------------------------ B) pase por dirección

func medir_direccion(motor: MotorJugable, dt: float) -> void:
	var pasos := 0
	var tope := int((motor.duracion_mitad * 2.0 * 1.6 + 300.0) / dt)
	var eq := -1
	var t_perdida := 0.0
	_f["partidos"] += 1
	while motor.estado != "fin" and pasos < tope:
		motor.paso(dt)
		pasos += 1
		if motor.estado == "juego" and not motor.poseedor.is_empty():
			var e := 0 if bool(motor.poseedor["es_local"]) else 1
			if eq >= 0 and e != eq:
				_recuperacion(motor, motor.poseedor, float(pasos) * dt - t_perdida)
				t_perdida = float(pasos) * dt
			elif eq < 0:
				t_perdida = float(pasos) * dt
			eq = e
		elif motor.estado != "juego":
			eq = -1
		if pasos % 30 == 0 and motor.estado == "juego" and not motor.poseedor.is_empty():
			_forma(motor, motor.poseedor)
		if pasos % 30 != 0 or motor.estado != "juego" or motor.poseedor.is_empty() or bool(motor.poseedor["por"]):
			continue
		var p: Dictionary = motor.poseedor
		var d := MotorJugable.dir_ataque(bool(p["es_local"]))
		for k in 8:
			_una_direccion(motor, p, Vector3(0, 0, d).rotated(Vector3.UP, deg_to_rad(45.0 * k)), k == 0 or k == 1 or k == 7)
	_sumar_tiros(motor)

## Tiros, goles y cómo acaba cada remate (`diag.remate_<clase>_<tipo>`), pases del motor, sumados por partido.
var _t := {}
func _sumar_tiros(motor: MotorJugable) -> void:
	_t["partidos"] = int(_t.get("partidos", 0)) + 1
	_t["goles"] = int(_t.get("goles", 0)) + int(motor.goles[0]) + int(motor.goles[1])
	_t["tiros"] = int(_t.get("tiros", 0)) + int(motor.tiros[0]) + int(motor.tiros[1])
	_t["pases"] = int(_t.get("pases", 0)) + int(motor.pases[0]) + int(motor.pases[1])
	_t["pases_ok"] = int(_t.get("pases_ok", 0)) + int(motor.pases_ok[0]) + int(motor.pases_ok[1])
	for k: String in motor.diag:
		if k.begins_with("remate_"):
			var tipo := k.get_slice("_", k.get_slice_count("_") - 1)
			_t["fin_" + tipo] = int(_t.get("fin_" + tipo, 0)) + int(motor.diag[k])

func resumen_tiros() -> Dictionary:
	var pj := maxf(float(_t.get("partidos", 0)), 1.0)
	var r := {}
	for k: String in _t:
		r[k + "_pp"] = snappedf(float(_t[k]) / pj, 0.01)
	var tiros := maxf(float(_t.get("tiros", 0)), 1.0)
	r["goles_por_tiro_pct"] = snappedf(100.0 * float(_t.get("goles", 0)) / tiros, 0.1)
	r["acierto_pase_pct"] = snappedf(100.0 * float(_t.get("pases_ok", 0)) / maxf(float(_t.get("pases", 0)), 1.0), 0.1)
	var ata := float(_t.get("fin_atajada", 0))
	r["paradas_pct"] = snappedf(100.0 * ata / maxf(ata + float(_t.get("goles", 0)), 1.0), 0.1)
	r["a_puerta_pct"] = snappedf(100.0 * (ata + float(_t.get("goles", 0))) / tiros, 0.1)
	return r

## El compañero del equipo (3 a 45 m) más alineado con `dir`; y si hay pase limpio a 30°.
func _mas_alineado(motor: MotorJugable, p: Dictionary, dir: Vector3, local: bool) -> Dictionary:
	var min_ang := 999.0
	var min_id := ""
	var hay_limpio := false
	for c: Dictionary in motor.jugadores:
		if c == p or bool(c["es_local"]) != local or bool(c["por"]):
			continue
		var dist := motor.pos(c).distance_to(motor.pos(p))
		if dist < 3.0 or dist > 45.0:
			continue
		var a := _ang(motor, p, c, dir)
		if a < min_ang:
			min_ang = a
			min_id = String(c["id"])
		if a <= 30.0 and not motor._linea_tapada(motor.pos(p), motor.pos(c), local):
			hay_limpio = true
	return {"ang": min_ang, "id": min_id, "limpio": hay_limpio}

func _una_direccion(motor: MotorJugable, p: Dictionary, dir: Vector3, adelante: bool) -> void:
	var q: Dictionary = motor._companero_en_direccion(p, dir)
	if q.is_empty():
		return
	var local := bool(p["es_local"])
	var mejor := _mas_alineado(motor, p, dir, local)
	var min_ang: float = mejor["ang"]
	var min_id: String = mejor["id"]
	var hay_limpio: bool = mejor["limpio"]
	var err := _ang(motor, p, q, dir)
	var tapado: bool = motor._linea_tapada(motor.pos(p), motor.pos(q), local)
	_b["n"] += 1
	_b["err_suma"] += err
	_errs.append(err)
	if min_ang <= 30.0:
		_b["hay30"] += 1
		if err <= 30.0:
			_b["obedece30"] += 1
		if adelante:
			_b["hay30_adelante"] += 1
			if err <= 30.0:
				_b["obedece30_adelante"] += 1
	if min_ang <= 45.0:
		if err <= 45.0:
			_b["obedece45"] += 1
		if err > 90.0:
			_b["detras"] += 1
	if adelante:
		_b["n_adelante"] += 1
	if String(q["id"]) == min_id:
		_b["mas_alineado"] += 1
	if tapado:
		_b["elegido_tapado"] += 1
	if hay_limpio:
		_b["hay_limpio30"] += 1
		if tapado:
			_b["tapado_con_limpio"] += 1

## Recupera `p` tras `dur` segundos de posesión rival: dónde (campo rival, último tercio).
func _recuperacion(motor: MotorJugable, p: Dictionary, dur: float) -> void:
	var z := motor.pos(p).z * MotorJugable.dir_ataque(bool(p["es_local"]))
	_f["recuperaciones"] += 1
	_f["t_recuperar"] += dur
	if z > 0.0:
		_f["rec_campo_rival"] += 1
	if z > MotorJugable.LARGO / 3.0:
		_f["rec_tercio"] += 1

## La forma del equipo que defiende: distancia entre la línea de defensas (los 4 más atrás) y la de medios (los 3 siguientes), largo y ancho del bloque y presión al portador.
func _forma(motor: MotorJugable, por: Dictionary) -> void:
	var def_local := not bool(por["es_local"])
	var d := MotorJugable.dir_ataque(def_local)
	var zs: Array[float] = []
	var xs: Array[float] = []
	var cerca := 99.0
	var a5 := 0
	for q: Dictionary in motor.jugadores:
		if bool(q["es_local"]) != def_local or bool(q["por"]):
			continue
		zs.append(motor.pos(q).z * d)
		xs.append(motor.pos(q).x)
		var dd := motor.pos(q).distance_to(motor.pos(por))
		cerca = minf(cerca, dd)
		if dd < 5.0:
			a5 += 1
	if zs.size() < 8:
		return
	zs.sort()
	var lin_def := (zs[0] + zs[1] + zs[2] + zs[3]) / 4.0
	var lin_med := (zs[4] + zs[5] + zs[6]) / 3.0
	_f["muestras"] += 1
	_f["entre_lineas"] += lin_med - lin_def
	_f["largo"] += zs[zs.size() - 1] - zs[0]
	_f["ancho"] += float(xs.max()) - float(xs.min())
	_f["presion_m"] += cerca
	_f["rivales_5m"] += a5

func resumen_forma() -> Dictionary:
	var n := maxf(float(_f["muestras"]), 1.0)
	var pj := maxf(float(_f["partidos"]), 1.0)
	return {"entre_lineas_m": snappedf(float(_f["entre_lineas"]) / n, 0.1), "largo_bloque_m": snappedf(float(_f["largo"]) / n, 0.1),
		"ancho_bloque_m": snappedf(float(_f["ancho"]) / n, 0.1), "presion_m": snappedf(float(_f["presion_m"]) / n, 0.1),
		"defensores_a_5m": snappedf(float(_f["rivales_5m"]) / n, 0.01), "recuperaciones_pp": snappedf(float(_f["recuperaciones"]) / pj, 0.1),
		"rec_campo_rival_pct": snappedf(100.0 * float(_f["rec_campo_rival"]) / maxf(float(_f["recuperaciones"]), 1.0), 0.1),
		"rec_tercio_pp": snappedf(float(_f["rec_tercio"]) / pj, 0.1), "posesion_media_s": snappedf(float(_f["t_recuperar"]) / maxf(float(_f["recuperaciones"]), 1.0), 0.1)}

func resumen_dir() -> Dictionary:
	var n := maxf(float(_b["n"]), 1.0)
	_errs.sort()
	return {"muestras": _b["n"], "err_medio": snappedf(float(_b["err_suma"]) / n, 0.1), "err_mediana": snappedf(_errs[_errs.size() / 2] if not _errs.is_empty() else 0.0, 0.1),
		"obedece30_pct": snappedf(100.0 * float(_b["obedece30"]) / maxf(float(_b["hay30"]), 1.0), 0.1),
		"obedece30_adelante_pct": snappedf(100.0 * float(_b["obedece30_adelante"]) / maxf(float(_b["hay30_adelante"]), 1.0), 0.1),
		"obedece45_pct": snappedf(100.0 * float(_b["obedece45"]) / n, 0.1), "detras_pct": snappedf(100.0 * float(_b["detras"]) / n, 0.1),
		"mas_alineado_pct": snappedf(100.0 * float(_b["mas_alineado"]) / n, 0.1), "elegido_tapado_pct": snappedf(100.0 * float(_b["elegido_tapado"]) / n, 0.1),
		"tapado_con_limpio_pct": snappedf(100.0 * float(_b["tapado_con_limpio"]) / maxf(float(_b["hay_limpio30"]), 1.0), 0.1)}

# ------------------------------------------------------------------ C) bot humano

## El compañero al que un jugador «con criterio» querría pasar: libre, con la línea limpia, que avance (sin azar del motor).
static func intencion(motor: MotorJugable, p: Dictionary) -> Dictionary:
	var yo := motor.pos(p)
	var local := bool(p["es_local"])
	var d := MotorJugable.dir_ataque(local)
	var mejor: Dictionary = {}
	var mejor_nota := -99.0
	for q: Dictionary in motor.jugadores:
		if q == p or bool(q["es_local"]) != local or bool(q["por"]):
			continue
		var qp := motor.pos(q)
		var dist := qp.distance_to(yo)
		if dist < 6.0 or dist > 35.0:
			continue
		var libre := 99.0
		for r: Dictionary in motor.jugadores:
			if bool(r["es_local"]) != local:
				libre = minf(libre, motor.pos(r).distance_to(qp))
		var nota := clampf((qp.z - yo.z) * d, -10.0, 15.0) * 0.12 + minf(libre, 8.0) * 0.25 - dist * 0.03 - (2.0 if motor._linea_tapada(yo, qp, local) else 0.0)
		if nota > mejor_nota:
			mejor_nota = nota
			mejor = q
	return mejor

## «Bot humano»: partido IA contra IA en el que, cada ~2 s que un jugador de campo del LOCAL tiene el balón, se hace lo que haría quien
## maneja: elige a un compañero libre (`intencion`), apunta hacia él con la palanca (±10° de error de pulso) y pulsa Pase (30 %: al
## hueco si va por delante). El receptor sale de `_companero_en_direccion` (el de siempre o `C4_PASE_DIR`) y el pase se da con `_pasar_a`.
## Mide si sale al que querías y si se completa (el siguiente que controla es un compañero).
func bot(motor: MotorJugable, dt: float, semilla: int) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = semilla
	var pasos := 0
	var tope := int((motor.duracion_mitad * 2.0 * 1.6 + 300.0) / dt)
	var pend := {}
	var proximo := 0.0
	while motor.estado != "fin" and pasos < tope:
		motor.paso(dt)
		pasos += 1
		var t := float(pasos) * dt
		if not pend.is_empty():
			pend = _resolver(motor, pend, t)
			continue
		var po: Dictionary = motor.poseedor
		if t < proximo or motor.estado != "juego" or po.is_empty() or not bool(po["es_local"]) or bool(po["por"]):
			continue
		proximo = t + 2.0
		var q := intencion(motor, po)
		if q.is_empty():
			continue
		var d := MotorJugable.dir_ataque(true)
		var v := motor.pos(q) - motor.pos(po)
		v.y = 0.0
		var dir := v.normalized().rotated(Vector3.UP, deg_to_rad(rng.randf_range(-10.0, 10.0)))
		var hueco := (motor.pos(q).z - motor.pos(po).z) * d > 8.0 and rng.randf() < 0.3
		var r: Dictionary = motor._companero_en_direccion(po, dir)
		if r.is_empty():
			continue
		pend = {"de": String(po["id"]), "local": true, "quiere": String(q["id"]), "a": String(r["id"]), "hueco": hueco, "dist": v.length(), "t": t}
		_contar_salida(pend)
		motor._pasar_a(po, r, false, hueco)
	_c["goles_u"] += int(motor.goles[0])

func _clase(dist: float) -> String:
	return "corto" if dist < 15.0 else ("medio" if dist < 28.0 else "largo")

func _contar_salida(pend: Dictionary) -> void:
	_c["pases"] += 1
	_c[_clase(float(pend["dist"]))] += 1
	var al := String(pend["a"]) == String(pend["quiere"])
	if al:
		_c["al_apuntado"] += 1
	if bool(pend["hueco"]):
		_c["hueco"] += 1
		if al:
			_c["hueco_apuntado"] += 1

## ¿Quién se queda el balón tras el pase? compañero = bueno; rival = cortado; nadie en 6 s = suelto.
func _resolver(motor: MotorJugable, pend: Dictionary, t: float) -> Dictionary:
	var po: Dictionary = motor.poseedor
	if not po.is_empty() and String(po["id"]) != String(pend["de"]):
		if bool(po["es_local"]) == bool(pend["local"]):
			_c["ok"] += 1
			_c[_clase(float(pend["dist"])) + "_ok"] += 1
			if bool(pend["hueco"]):
				_c["hueco_ok"] += 1
		else:
			_c["cortados"] += 1
		return {}
	if t - float(pend["t"]) > 6.0 or motor.estado != "juego":
		_c["sueltos"] += 1
		return {}
	return pend

func resumen_bot() -> Dictionary:
	var n := maxf(float(_c["pases"]), 1.0)
	var r := _c.duplicate()
	r["al_apuntado_pct"] = snappedf(100.0 * float(_c["al_apuntado"]) / n, 0.1)
	r["completados_pct"] = snappedf(100.0 * float(_c["ok"]) / n, 0.1)
	r["hueco_ok_pct"] = snappedf(100.0 * float(_c["hueco_ok"]) / maxf(float(_c["hueco"]), 1.0), 0.1)
	for k in ["corto", "medio", "largo"]:
		r[k + "_pct"] = snappedf(100.0 * float(_c[k + "_ok"]) / maxf(float(_c[k]), 1.0), 0.1)
	return r
