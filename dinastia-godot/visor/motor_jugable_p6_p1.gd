extends "res://visor/motor_jugable_p5.gd"
## (Parte 1 de 2 de `motor_jugable_p6.gd`: la norma de 450 líneas lo partió en capas, cada una extiende a la anterior; la última, `motor_jugable_p6.gd`, conserva la clase.)

## [Capa 6/12 de `motor_jugable.gd`] _patear, _companero_cerca, _cabezazo, _entrada, _disputas, _punto_de_recepcion … (+11)

## Patea el balón hacia `destino` con una velocidad horizontal `vh` y la parábola que haga falta para llegar ahí (más `loft` de altura extra).
## El saque de mano: el balón sigue en la mano del portero hasta `SUELTA_MANO` s después (el clip carga el brazo antes de lanzar).
const SUELTA_MANO := 0.45
var _en_mano: Dictionary = {}

# ---------------------------------------------------------------- disputas

## Cuánto más rápido hay que lanzar para llegar con el tiempo previsto: el aire quita ≈ K·v²·t en el vuelo; tope +25 % (a más, el balón pasaría de 36 m/s y la sonda de física lo contaría como salto).
static func compensa_arrastre(vh: float, tv: float) -> float:
	return 1.0 / (1.0 - minf(ARRASTRE_CUAD * vh * tv, 0.2))


## (16-11, paso a C++) El enfriamiento de los 22 y, con el balón suelto, quién lo controla: `disputas_inicio` (gemela `_disputas_inicio_gd`).
## Igualdad: `probar_nativo` (con `comparar_disputas`).
static var comparar_disputas := false
static var disputas_comparadas := 0
static var disputas_distintas := 0

func _patear(p: Dictionary, destino: Vector3, vh: float, loft := 0.0, efecto := 0.0, anim := "pase") -> void:
	if MotorReglas.doble_toque(self as Object as MotorJugable, p): return   ## (16-11, M6-20) el que sacó no repite antes que otro
	MotorReglas.marcar_ejecutor(self as Object as MotorJugable, p)
	_ultima_anim = anim
	_n_patada += 1
	## SAQUE DE MANO (31-10): el portero con el balón en las manos que pasa raso y corto lo lanza con la mano (clip de la UAL2):
	## el balón sale desde arriba del hombro y rueda; los envíos largos siguen siendo de volea.
	if bool(p.get("en_manos", false)) and loft <= 0.0 and Vector2(destino.x - balon.position.x, destino.z - balon.position.z).length() < 32.0 \
			and AnimExtra.asegurar(p.get("anim"), FutbolistaQ.esqueleto_de(p["node"]), "saque_mano"):
		anim = "saque_mano"
		_ctx_golpeo = "mano"
		balon.position.y = maxf(balon.position.y, 1.7)
		vh = minf(vh, 17.0)
	p["en_manos"] = false
	var b := balon.position
	var d := Vector3(destino.x - b.x, 0, destino.z - b.z)
	var dist := maxf(d.length(), 0.1)
	var tv := dist / maxf(vh, 1.0)
	var vy := 0.0
	if loft > 0.0:
		## Envío por arriba: `loft` fija la ALTURA de la parábola y de ahí sale
		## el tiempo de vuelo, para que el balón CAIGA donde se apuntó (antes se
		## sumaba encima de la parábola y los despejes cruzaban el campo).
		var cumbre := maxf(1.5 + loft * 1.8, destino.y - b.y + 1.0)
		vy = sqrt(2.0 * G * cumbre)
		var caida := vy * vy - 2.0 * G * (destino.y - b.y)
		tv = (vy + sqrt(maxf(caida, 0.0))) / G
		vh = dist / maxf(tv, 0.2)
	elif destino.y > R + 0.05:
		vy = ((destino.y - b.y) + 0.5 * G * tv * tv) / tv
	## El arrastre frena: se compensa un poco para que llegue.
	var h := d / dist * vh * _compensa_aire(vh, tv)
	if vy <= 0.0:
		h = d / dist * vh
	vel_balon = Vector3(h.x, vy, h.z)
	giro_balon = Vector3(0, efecto, 0)
	Sonido.toca("tiro_potente" if vh > 22.0 else "pase_corto", Sonido.Bus.EFECTOS, clampf(remap(vh, 6.0, 30.0, -9.0, 2.0), -9.0, 2.0))   ## golpeo de League-Soccer; más fuerte cuanto más potente (M-320)
	if anim == "saque_mano":
		## Lo retiene en la mano mientras carga el brazo y lo suelta al lanzar (`_retener_en_mano`, 31-10).
		_en_mano = {"p": p, "hasta": t + SUELTA_MANO, "vel": vel_balon}
		vel_balon = Vector3.ZERO
	if depurar:
		Registro.depurar("PATADA", "%s(%s) desde %s a %s vh %.1f loft %.1f vel %s" % [String(p.get("slot_code", "")), "L" if bool(p["es_local"]) else "V", str(b), str(destino), vh, loft, str(vel_balon)])
	if OS.get_environment("DEPURAR_AIRE") != "" and vy > 2.0:
		var clave := "%s/%s" % [_ctx_golpeo if _ctx_golpeo != "" else anim, estado]
		cuenta_aire[clave] = int(cuenta_aire.get(clave, 0)) + 1
	_foto_offside(p)
	penultimo_toque = ultimo_toque
	ultimo_toque = p
	poseedor = {}
	p["enfriar"] = 0.35
	balon.position.y = maxf(balon.position.y, R + 0.01)
	## Se gira hacia el destino en un giro rápido pero continuo (M-115): antes
	## se encaraba de golpe en un fotograma (giros de más de 720°/s).
	_mirar(p, atan2(d.x, d.z), 0.35)
	var ap: AnimationPlayer = p.get("anim")
	if is_instance_valid(ap):
		_anim(p, _golpeo_anim(p, ap, anim, destino, b, vh, loft, efecto), true)
	_ctx_golpeo = ""
	if p == usuario:
		stats["toques"] += 1

func _companero_cerca(p: Dictionary, punto: Vector3) -> Dictionary:
	var mejor: Dictionary = {}
	var md := 999.0
	for q: Dictionary in jugadores:
		if q != p and bool(q["es_local"]) == bool(p["es_local"]) and not bool(q["por"]):
			var d := pos(q).distance_to(punto)
			if d < md:
				md = d
				mejor = q
	return mejor

func _cabezazo(p: Dictionary) -> void:
	if _pitar_offside(p) or MotorReglas.doble_toque(self as Object as MotorJugable, p):   ## (16-11, M6-04 y M6-20) fuera de juego o doble toque
		return
	var arco := _arco_rival(p)
	var cerca := absf(pos(p).z - arco.z) < 18.0
	if cerca:
		var destino := Vector3(_rng.randf_range(-PALO + 0.4, PALO - 0.4), _rng.randf_range(0.3, 2.0), arco.z)
		## EL CABEZAZO NO ES UN DISPARO TELEDIRIGIDO (25-10-2026): iba siempre entre
		## los palos y entraba más de la mitad (en el fútbol, ~1 de cada 8). Ahora
		## se busca un palo, abajo, y se desvía según el remate y la distancia.
		if tiro_pulido:
			var err := (0.5 + (1.0 - GestoTecnico.tiro(p, "cabeza")) * 1.4) * (0.4 + absf(pos(p).z - arco.z) / 11.0) * GestoTecnico.factor(self, p, true)
			destino = Vector3((1.0 if _rng.randf() < 0.5 else -1.0) * _rng.randf_range(0.8, PALO - 0.3) + _rng.randf_range(-err, err),
				clampf(_rng.randf_range(0.3, 1.4) + _rng.randf_range(-err, err) * 0.6, 0.15, 3.5), arco.z)
		destino = MejorasC4Cabeza.destino(self, p, MotorCorner.cabeza(self as Object as MotorJugable, p, destino))   ## ciclo 26 + C4_CABEZA (12-11)
		_patear(p, destino, MejorasC4Cabeza.velocidad(self, 14.0 + float(p["attr"]["tir"]) * 6.0), 0.0, 0.0, "cabezazo")
		tiros[0 if bool(p["es_local"]) else 1] += 1
		_cerrar_tiro("fallo")   ## (01-11) el remate anterior aún abierto se cierra (ver `_tirar`)
		_tiro_vivo = {"p": p, "t": t, "clase": "cabeza"}
		_contar("tiro_cabeza")
	else:
		## Despeje o pase de cabeza: a un compañero de delante si lo hay, bajo.
		var fwd := Vector3(_rng.randf_range(-8, 8), 0, dir_ataque(bool(p["es_local"])) * 14.0)
		var q := _companero_cerca(p, pos(p) + fwd)
		var destino := pos(q) if not q.is_empty() and pos(q).distance_to(pos(p)) < 22.0 else pos(p) + fwd
		_patear(p, destino, 11.0, 0.0, 0.0, "cabezazo")
		if not q.is_empty():
			pase_a = q

## Una entrada: quita el balón, o hace falta.
func _entrada(p: Dictionary, barrida: bool) -> void:
	if poseedor.is_empty():
		return
	var victima := poseedor
	p["enfriar"] = (1.0 if not barrida else 1.6) * MotorDuelo.enf   ## ciclo 10: menos intentos de entrada (1,0 = como antes)
	var def_loc := float(p["attr"]["def"])
	var reg := float(victima["attr"]["reg"])
	if t < float(victima["regate_hasta"]):
		reg += 0.35
	## Defensa contra regate al cuadrado: el buen defensor roba bastante más
	## que el malo (antes la proporción lineal igualaba a todos).
	var exito := def_loc * def_loc / (def_loc * def_loc + reg * reg) * (0.55 if barrida else 0.32) * MotorDuelo.k
	## La entrada de pie también es cuerpo: el fuerte se impone al débil (y
	## el que tiene equilibrio aguanta). De media no cambia nada.
	if not barrida:
		exito *= clampf(1.0 + (_fuerza(p) - (_fuerza(victima) * 0.6 + float(victima.get("equilibrio", 0.6)) * 0.4)) * 0.7, 0.6, 1.45)
	## Protegiendo el balón (LT) cuesta mucho más quitárselo de pie.
	if bool(victima.get("protege", false)) and not barrida:
		exito *= 0.55
	if p == usuario:
		stats["entradas"] += 1
	_contar("traza_entrada_intento")   ## ciclo 10: solo cuenta
	var de_lado := absf((pos(victima) - pos(p)).normalized().dot(Vector3(sin((p["node"] as Node3D).rotation.y), 0, cos((p["node"] as Node3D).rotation.y)))) < 0.5
	var gesto_e := "entrada_de_pie"
	if barrida:
		gesto_e = ["barrida_lateral", "barrida_corta", "barrida_rapida", "barrida_larga", "falta_barrida", "barrida_real", "barrida_real"][_rng.randi() % 7]
		## La barrida de la UAL2 (31-10: entra, se desliza y se levanta) se arma la primera vez que hace falta.
		if gesto_e == "barrida_real" and not AnimExtra.unir(p.get("anim"), FutbolistaQ.esqueleto_de(p["node"]), gesto_e, AnimExtra.BARRIDA_REAL):
			gesto_e = "barrida_larga"
	elif de_lado:
		gesto_e = "carga_hombro" if _rng.randf() < 0.5 else "entrada_lateral_pie"
	## La barrida del usuario ya va por el suelo (`_lanzar_barrida`): no se repite el gesto.
	if not (barrida and String(p.get("anim_actual", "")).begins_with("barrida") and float(p.get("gesto_hasta", 0.0)) > t):
		_anim(p, gesto_e, true, 1.9 if gesto_e == "barrida_real" else 1.4)
	var r := _rng.randf()
	if r < exito:
		if p == usuario:
			stats["entradas_ok"] += 1
		_contar("traza_entrada_exito")
		set_meta("_traza_ent", self.t)
		poseedor = {}
		ultimo_toque = p
		_offside = {}
		victima["enfriar"] = 0.6
		## ROBO LIMPIO (semana 3, 27-10-2026: «menos rebotes al defender»): de pie, el buen defensor se
		## queda el balón; antes siempre quedaba suelto rebotando, y el rechace lo recogía cualquiera.
		if not barrida and _rng.randf() < 0.25 + def_loc * 0.45:
			_tomar(p)
		else:
			vel_balon = (pos(p) - pos(victima)).normalized() * 3.0 + Vector3(_rng.randf_range(-2, 2), 0, 0)
	## FALTAS (17-10-2026): había ~4 por partido; una entrada que no llega al
	## balón acaba en falta más a menudo (sobre todo si el defensor es agresivo).
	elif r < exito + ((0.28 if barrida else 0.13) + float(p.get("agresividad", 0.5)) * 0.06) * preset_faltas:
		_falta(p, victima, 0.25, "", "deslizante" if barrida else "de_pie")

func _disputas(delta: float) -> void:
	var b := balon.position
	var nat := Nativo.obj()
	var k := -2
	if nat != null and nat.has_method("disputas_inicio") and not (_gancho_tiro() and not _tiro_vivo.is_empty()):   ## (17-11) con el gancho de C4 encendido y un remate en vuelo, la gemela GDScript (C++ no lo conoce)
		if comparar_disputas:
			_comparar_disputas(nat, delta, b)
		k = nat.disputas_inicio(jugadores, delta, poseedor.is_empty(), b, t, pase_a.get("id") if not pase_a.is_empty() else null,
			PackedFloat64Array([_arco_propio({"es_local": true}).z, _arco_propio({"es_local": false}).z]), AREA_X, AREA_Z)
	else:
		k = _disputas_inicio_gd(delta, b)
	if poseedor.is_empty():
		if not _en_mano.is_empty(): return   ## (16-11, M6-22) el saque de mano: el balón está en la mano del portero, no suelto
		var mejor: Dictionary = jugadores[k] if k >= 0 else {}
		_disputa_suelto(mejor, b)
		return
	_disputa_con_dueno(b)

## Prueba: las dos versiones sobre copias del mismo estado (enfriamiento y elegido).
func _comparar_disputas(nat: Object, delta: float, b: Vector3) -> void:
	var copia_c: Array = []
	var copia_g: Array = []
	for p: Dictionary in jugadores:
		copia_c.append(p.duplicate())
		copia_g.append(p.duplicate())
	var orig := jugadores
	jugadores = copia_g
	var pa := pase_a
	if not pase_a.is_empty():
		pase_a = copia_g[orig.find(pa)] if orig.find(pa) >= 0 else pa
	var kg := _disputas_inicio_gd(delta, b)
	jugadores = orig
	pase_a = pa
	var kc: int = nat.disputas_inicio(copia_c, delta, poseedor.is_empty(), b, t, pase_a.get("id") if not pase_a.is_empty() else null,
		PackedFloat64Array([_arco_propio({"es_local": true}).z, _arco_propio({"es_local": false}).z]), AREA_X, AREA_Z)
	disputas_comparadas += 1
	var igual := kg == kc
	for i in copia_c.size():
		igual = igual and var_to_bytes(copia_c[i]["enfriar"]) == var_to_bytes(copia_g[i]["enfriar"])
	if not igual:
		disputas_distintas += 1

func _disputas_inicio_gd(delta: float, b: Vector3) -> int:
	for p: Dictionary in jugadores:
		p["enfriar"] = maxf(0.0, float(p["enfriar"]) - delta)
	if not poseedor.is_empty():
		return -1
	## Balón suelto: lo controla el más cercano que llegue.
	var mejor := -1
	var md := 99.0
	for i in jugadores.size():
		var p: Dictionary = jugadores[i]
		if float(p["enfriar"]) > 0.0 or float(p.get("levanta_hasta", 0.0)) > t:   ## (10-11) en el suelo no se toca el balón (p4_saque_barrida)
			continue
		if not _tiro_vivo.is_empty() and not _puede_tomar_tiro(p): continue   ## (16-11, H1) gancho: aquí siempre puede (C4: `C4_TIRO_COMPANERO`)
		var d := Vector2(pos(p).x - b.x, pos(p).z - b.z).length()
		var alcance := 1.6 if bool(p["por"]) and _en_su_area(p, b) else 0.9
		## El que espera el pase va al encuentro del balón y se perfila:
		## llega antes que su marca (sin esto la sonda medía 4 de cada 10
		## pases cortados por el defensor que marcaba a 1,6 m).
		var ventaja := 0.0
		if p == pase_a:
			alcance = 1.25
			ventaja = 0.55
		if d < alcance and b.y < (2.4 if bool(p["por"]) and _en_su_area(p, b) else 1.5) and d - ventaja < md:
			md = d - ventaja
			mejor = i
	return mejor

## Balón suelto: control, corte o rechace del elegido (o cabezazo si nadie lo controla).
func _disputa_suelto(mejor: Dictionary, b: Vector3) -> void:
	if not mejor.is_empty():
		var rapido := vel_balon.length()
		## Un balón muy fuerte se escapa si el control es malo.
		var control: float = float(mejor["attr"]["reg"]) * 0.5 + 0.5
		if bool(mejor["por"]):
			control = float(mejor["attr"]["par"]) * 0.6 + 0.35
		## CORTAR UN PASE TENSO (14-10-2026): el rival que se cruza en la
		## línea de un pase rápido no siempre lo controla: a veces lo
		## desvía y a veces se le cuela entre las piernas.
		var corta := not pase_a.is_empty() and mejor != pase_a and bool(mejor["es_local"]) != bool(pase_a["es_local"])
		if corta and rapido > 8.0 and _rng.randf() > clampf(1.25 - rapido / 15.0, 0.18, 1.0) * control:
			mejor["enfriar"] = 0.35
			if _rng.randf() < 0.45:
				vel_balon = Vector3(vel_balon.x * 0.4 + _rng.randf_range(-3, 3), _rng.randf_range(0.3, 1.5), vel_balon.z * 0.4)
				penultimo_toque = ultimo_toque
				ultimo_toque = mejor
				pase_a = {}
		elif rapido < 14.0 or _rng.randf() < control:
			_tomar(mejor)
		else:
			## Rechace.
			vel_balon = Vector3(-vel_balon.x * 0.3 + _rng.randf_range(-3, 3), 1.5, -vel_balon.z * 0.35)
			penultimo_toque = ultimo_toque
			ultimo_toque = mejor
			mejor["enfriar"] = 0.4
			## Un rechace del rival rompe el fuera de juego (no el de un compañero).
			if not _offside.is_empty() and bool(mejor["es_local"]) != bool(_offside["local"]):
				_offside = {}
	## Cabezazos: balón alto a la altura de la cabeza.
	elif b.y > 1.5 and b.y < 2.4:
		for p: Dictionary in jugadores:
			if float(p["enfriar"]) > 0.0 or bool(p["por"]) or float(p.get("levanta_hasta", 0.0)) > t:   ## (16-11, M6-26) tumbado no se cabecea
				continue
			if Vector2(pos(p).x - b.x, pos(p).z - b.z).length() < _radio_cabezazo(p):
				_cabezazo(p)
				break

## Con dueño: entradas de los rivales cercanos (la del usuario va aparte).
func _disputa_con_dueno(b: Vector3) -> void:
	## Al portero con el balón en las manos no se le entra; fuera de su área es un jugador más (16-11, M6-10).
	if _portero_intocable(poseedor):
		return
	## El toque largo: si el balón va suelto por delante y un rival llega
	## antes, se lo lleva sin entrada.
	var lejos_dueno := Vector2(b.x - pos(poseedor).x, b.z - pos(poseedor).z).length()
	if lejos_dueno > 1.4:
		for q: Dictionary in jugadores:
			if bool(q["es_local"]) == bool(poseedor["es_local"]) or float(q["enfriar"]) > 0.0 or (q == usuario and not autopiloto) or float(q.get("levanta_hasta", 0.0)) > t:
				continue
			var dq := Vector2(b.x - pos(q).x, b.z - pos(q).z).length()
			if dq < 0.6 and dq < lejos_dueno * 0.6:
				poseedor["enfriar"] = 0.4
				poseedor = {}
				set_meta("_traza_tl", self.t)   ## traza (ciclo 10): toque largo
				_tomar(q)
				return
	for p: Dictionary in jugadores:
		if bool(p["es_local"]) == bool(poseedor["es_local"]) or p == usuario and not autopiloto:
			continue
		if float(p["enfriar"]) > 0.0 or bool(p["por"]):
			continue
		if pos(p).distance_to(pos(poseedor)) < _radio_entrada(p, poseedor, 1.25 + 0.12 * float(_tac(bool(p["es_local"]), "presion") - 1)):   ## ciclo 12: entrar en el momento bueno
			_entrada(p, false)
			break

## Dónde conviene recibir el pase que va en camino.
func _punto_de_recepcion() -> Vector3:
	var b := balon.position
	var v := Vector3(vel_balon.x, 0, vel_balon.z)
	var sp := v.length()
	if sp < 1.0:
		return b
	## Dónde para (o por dónde pasa en un segundo).
	var t_para := minf(sp / (ROCE_SUELO * sp + ROCE_FIJO + 0.01), 1.2)
	return Vector3(b.x, 0, b.z) + v * t_para * 0.6

func _aplicar_fase() -> void:
	var fase: Dictionary = (_jugada["fases"] as Array)[int(_jugada["i"])]
	var d := dir_ataque(bool(_jugada["local"]))
	var dest := {}
	var fd: Dictionary = fase.get("destinos", {})
	for rol: String in fd:
		var v: Vector3 = fd[rol]
		## Catálogo: ataque hacia -Z. Para atacar hacia +Z, espejo completo.
		dest[rol] = Vector3(-v.x * d, 0, -v.z * d) if d > 0.0 else v
	_jugada["destinos"] = dest
	_jugada["pase_a"] = String(fase.get("pase_a", ""))

## LAS JUGADAS PREHECHAS COMO GUÍA. Cuando un equipo tiene el balón en campo rival, elige una del catálogo y sus fases le dicen a cada
## puesto adónde desmarcarse y a quién conviene pasarla. El catálogo está escrito para un ataque hacia -Z; para el que ataca hacia +Z se da la vuelta.
func _guiar_jugada(delta: float) -> void:
	var local := bool(poseedor["es_local"])
	var d := dir_ataque(local)
	var en_campo_rival := balon.position.z * d > -5.0
	if _jugada.is_empty():
		if not en_campo_rival:
			return
		var id: String = CatalogoJugadas.IDS_ATQ[_rng.randi() % CatalogoJugadas.IDS_ATQ.size()]
		var def := CatalogoJugadas.obtener_definicion(id)
		var fases: Array = def.get("fases", [])
		if fases.is_empty():
			return
		_jugada = {"id": id, "local": local, "fases": fases, "i": 0, "t": 0.0}
		_aplicar_fase()
		return
	_jugada["t"] = float(_jugada["t"]) + delta
	var fase: Dictionary = (_jugada["fases"] as Array)[int(_jugada["i"])]
	if float(_jugada["t"]) > float(fase.get("duracion", 1.0)) * 1.8:
		_jugada["i"] = int(_jugada["i"]) + 1
		_jugada["t"] = 0.0
		if int(_jugada["i"]) >= (_jugada["fases"] as Array).size():
			_jugada = {}
			return
		_aplicar_fase()
func prisa() -> float:
	if prisa_ref <= 0.0 or duracion_mitad <= 0.0:
		return 1.0
	return clampf(prisa_ref / duracion_mitad, 1.0, 2.0)

## ¿`q` está ahora en posición adelantada respecto de un pase de `p`?
func _adelantado(q: Dictionary, p: Dictionary) -> bool:
	var local := bool(q["es_local"])
	var d := dir_ataque(local)
	var z := pos(q).z * d
	if z <= 0.0 or z <= pos(p).z * d + 0.3:
		return false
	var prof: Array = []
	for r: Dictionary in jugadores:
		if bool(r["es_local"]) != local:
			prof.append(pos(r).z * d)
	if prof.size() < 2:
		return false
	prof.sort()
	return z > float(prof[prof.size() - 2]) + 0.3

## El mejor pase: progresión hacia el arco, compañero libre y línea limpia. Bonificaciones: el destinatario que marca la jugada prehecha, y tú si pediste el balón.
func _mejor_pase(p: Dictionary) -> Dictionary:
	var yo := pos(p)
	var d := dir_ataque(bool(p["es_local"]))
	var mejor: Dictionary = {}
	var mejor_nota := -99.0
	for q: Dictionary in jugadores:
		if q == p or bool(q["es_local"]) != bool(p["es_local"]) or bool(q["por"]):
			continue
		var qp := pos(q)
		var dist := qp.distance_to(yo)
		if dist < 4.0 or dist > 42.0:
			continue
		var progreso := MotorPaseMejora.progreso((qp.z - yo.z) * d)
		var lr := MotorPaseMejora.libre_y_riesgo(self as Object as MotorJugable, p, q, yo, qp)   ## (R2, 01-11: con PMOT_PASE=1, previsto)
		var libre: float = lr[0]
		var riesgo: float = lr[1]
		var nota := progreso * (chispa_avance * pow(prisa(), 0.7) + 0.025 * float(_tac(bool(p["es_local"]), "mentalidad") - 1) + 0.015 * float(_tac(bool(p["es_local"]), "ritmo") - 1) \
				+ 0.03 * float(_tac(bool(p["es_local"]), "verticalidad") - 1)) \
			+ minf(libre, 10.0) * 0.18 - riesgo * MotorPaseMejora.riesgo_k - dist * MotorPaseMejora.dist_k + MotorPaseMejora.bono_tercio(self as Object as MotorJugable, p, qp)
		## Un buen pasador ve el fuera de juego: con más visión (pase) casi
		## nunca se la da a un compañero adelantado.
		if _adelantado(q, p) and _rng.randf() < 0.55 + float(p["attr"]["pas"]) * 0.4:
			nota -= 6.0
		if not _jugada.is_empty() and String(_jugada.get("pase_a", "")) == _rol(q):
			nota += 1.2
		if q == usuario and t < pedido_hasta:
			nota += 2.5
		## Visión de juego: con poco pase se elige peor (ruido en la nota).
		nota += _rng.randf_range(-1.0, 1.0) * (1.0 - float(p["attr"]["pas"])) * 3.0
		if nota > mejor_nota:
			mejor_nota = nota
			mejor = q
	if not mejor.is_empty():
		mejor["_nota"] = mejor_nota
	return mejor

func _rival_mas_cercano(p: Dictionary) -> Dictionary:
	var mejor: Dictionary = {}
	var md := 999.0 * 999.0
	var yo := pos(p)
	var local := bool(p["es_local"])
	for q: Dictionary in jugadores:
		if bool(q["es_local"]) != local:
			var d := (q["node"] as Node3D).position.distance_squared_to(yo)
			if d < md:
				md = d
				mejor = q
	return mejor

func _presion(p: Dictionary) -> float:
	var r := _rival_mas_cercano(p)
	return MotorMente.pos_vista(self as Object as MotorJugable, p, r).distance_to(pos(p)) if not r.is_empty() else 99.0   ## lo que VE (F8, 03-11)

## GANCHO (16-11, H1): ¿puede `p` hacerse con el balón mientras va un remate? Aquí siempre (la huella no cambia); ver `MejorasC4Area`.
func _puede_tomar_tiro(_p: Dictionary) -> bool:
	return true

## (17-11) ¿Hay que mirar `_puede_tomar_tiro`? Aquí nunca (las disputas siguen en C++); C4 lo enciende con `C4_TIRO_COMPANERO`.
func _gancho_tiro() -> bool:
	return false
