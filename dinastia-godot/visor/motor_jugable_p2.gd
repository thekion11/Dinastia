extends "res://visor/motor_jugable_p1.gd"
## [Capa 2/12 de `motor_jugable.gd`] _preparar_uno, dir_ataque, _orientar_formaciones, _poner_usuario, pos, _elegir_lanzador … (+29)

func _preparar_uno(p: Dictionary) -> void:
	var jd: Dictionary = p.get("jugador", {})
	var at: Dictionary = jd.get("atributos", {}) if jd.get("atributos") is Dictionary else {}
	p["attr"] = _atributos(at, int(jd.get("ovr", 60)))
	## La forma y la moral del día (con lo que traiga el jugador): de -4 % a +2 %.
	if jd.has("forma"):
		var dia := 0.94 + 0.0006 * float(jd.get("forma", 60)) + 0.0002 * float(jd.get("moral", 70))
		for k: String in p["attr"]:
			p["attr"][k] = float(p["attr"][k]) * dia
	p["attr_puro"] = (p["attr"] as Dictionary).duplicate()
	p["attr_base"] = (p["attr"] as Dictionary).duplicate()
	_dificultad_de(p)
	p["vel"] = Vector3.ZERO
	p["aguante"] = 1.0
	p["enfriar"] = 0.0
	p["regate_hasta"] = 0.0
	p["anim_actual"] = ""
	p["por"] = String(p.get("slot_code", "")) == "POR"
	_rasgos_duelo(p, jd)

static func dir_ataque(es_local: bool) -> float:
	return 1.0 if es_local else -1.0

## CADA EQUIPO EN SU MITAD (13-10-2026). Este motor juega con el local
## defendiendo -Z (`dir_ataque`), pero `PlayerSpawner` coloca las formaciones
## con la convención del visor (`MatchPlayback`): el local defiende +Z. Los dos
## onces salían invertidos -el portero local en +46, su delantero en -34- y en
## cada saque de centro cruzaban el campo entero; la sonda medía además más
## tiros para el que atacaba hacia +Z con el mismo once a los dos lados. Aquí
## se gira 180° la formación del equipo que esté al revés.
func _orientar_formaciones() -> void:
	for local: bool in [true, false]:
		var por_z := 0.0
		var hay := false
		for p: Dictionary in jugadores:
			if bool(p["es_local"]) == local and bool(p["por"]):
				por_z = (p["base_pos"] as Vector3).z
				hay = true
		if not hay or por_z * dir_ataque(local) < 0.0:
			continue
		for p: Dictionary in jugadores:
			if bool(p["es_local"]) != local:
				continue
			var bp: Vector3 = p["base_pos"]
			p["base_pos"] = Vector3(-bp.x, bp.y, -bp.z)
			var n: Node3D = p["node"]
			n.position = Vector3(-n.position.x, n.position.y, -n.position.z)
			n.rotation.y += PI

func _poner_usuario(q: Dictionary) -> void:
	## El que dejas de manejar vuelve a su paso normal.
	if not usuario.is_empty() and usuario != q:
		for k: String in ["freno", "jockey", "protege", "toque_corto", "giro_firme"]:
			usuario.erase(k)
	usuario = q
	q["manual"] = Vector3.ZERO

func pos(p: Dictionary) -> Vector3:
	return (p["node"] as Node3D).position

func _elegir_lanzador(tipo: String, saca_local: bool, lugar: Vector3) -> Dictionary:
	## Con el equipo en tus manos, el lanzador lo elige la IA y lo manejas tú.
	if control_equipo >= 0 and not autopiloto and not _eligiendo and (control_equipo == 0) == saca_local \
			and bool(lanza_usuario.get(tipo, false)):
		var guardado := usuario
		usuario = {}
		_eligiendo = true
		var m := _elegir_lanzador(tipo, saca_local, lugar)
		_eligiendo = false
		usuario = guardado
		if not m.is_empty():
			_poner_usuario(m)
			return m
	if not usuario.is_empty() and not autopiloto and bool(usuario["es_local"]) == saca_local \
			and bool(lanza_usuario.get(tipo, false)):
		return usuario
	var mejor: Dictionary = {}
	var md := 999.0
	for p: Dictionary in jugadores:
		if bool(p["es_local"]) != saca_local:
			continue
		if tipo == "puerta":
			if bool(p["por"]):
				return p
			continue
		if bool(p["por"]):
			continue
		var d := pos(p).distance_to(lugar)
		if tipo in ["penal", "falta"]:
			d -= float(p["attr"]["tir"]) * 40.0
		if d < md:
			md = d
			mejor = p
	return mejor

func _gesto_arbitro(nombre: String, retraso := 0.0, dur := 1.6, extra := {}) -> void:
	if arbitros.is_empty() or estado == "tanda":
		return
	_gestos_arb.append([_t_arb + retraso, nombre, dur, extra])
	## Un gesto nuevo «ahora» corta la cola vieja que ya no viene a cuento.
	if retraso <= 0.0:
		var vivos: Array = []
		for g: Array in _gestos_arb:
			if float(g[0]) >= _t_arb - 0.01:
				vivos.append(g)
		_gestos_arb = vivos

# ---------------------------------------------------------------- balón parado

func _empezar_saque(tipo: String, saca_local: bool, lugar: Vector3) -> void:
	estado = "saque"
	_t_estado = 0.0
	poseedor = {}
	_linea_def = [INF, INF]
	pase_a = {}
	_jugada = {}
	vel_balon = Vector3.ZERO
	balon.position = lugar
	var lanzador := _elegir_lanzador(tipo, saca_local, lugar)
	saque = {"tipo": tipo, "local": saca_local, "lugar": lugar, "lanzador": lanzador}
	_receptor_i = -1
	_receptor_marcado = {}
	if tipo == "corner":
		corners[0 if saca_local else 1] += 1
		_gesto_arbitro("arbitro_corner", 0.3, 1.6, {"mira": lugar})
	elif tipo == "puerta":
		_gesto_arbitro("arbitro_saque_meta", 0.3, 1.6, {"mira": lugar})
	apuntando = false
	cargando = false
	if tipo != "centro":
		aviso.emit({"banda": "Saque de banda", "corner": "Córner", "puerta": "Saque de puerta",
			"falta": "Tiro libre", "penal": "Penal"}.get(tipo, tipo))
	cambio_estado.emit("saque_" + tipo)

func _saque_de_centro(saca_local: bool) -> void:
	_goleador = {}
	for p: Dictionary in jugadores:
		(p["node"] as Node3D).position = p["base_pos"]
		p["vel"] = Vector3.ZERO
		p["gesto_hasta"] = 0.0
	_empezar_saque("centro", saca_local, Vector3(0, R, 0))

# ---------------------------------------------------------------- montaje

func preparar(lista: Array, ball: Node3D, jugador_usuario_id: String, semilla: int = 1) -> void:
	_rng.seed = semilla
	jugadores = []
	arbitros = []
	for p: Dictionary in lista:
		if bool(p.get("arbitro", false)):
			arbitros.append(p)
			continue
		_preparar_uno(p)
		jugadores.append(p)
		if String(p.get("id", "")) == jugador_usuario_id:
			usuario = p
	balon = ball
	## Para las sondas que montan el estadio entero (como DEPURAR_PASES).
	if OS.get_environment("SIN_DUELOS") != "":
		duelos_activos = false
	if OS.get_environment("SIN_CUERPOS") != "":
		cuerpos_activos = false
	_orientar_formaciones()
	Mando.registrar()
	_saque_de_centro(true)

## Lo jugado en segundos reales (sin añadidos), contando la prórroga.
func tiempo_jugado() -> float:
	if mitad <= 2:
		return float(mitad - 1) * duracion_mitad + t
	return 2.0 * duracion_mitad + float(mitad - 3) * duracion_mitad / 3.0 + t

## EL DESGASTE DEL PARTIDO (MEGAPLAN fase 3): la forma física que queda, de
## 1 a ~0,6 en 90' según el físico, más lo que pese el sprint. NO toca la
## velocidad (eso lo lleva `aguante`, como siempre: cuando el desgaste frenaba
## a todos, los ataques no llegaban y los tiros bajaban de 7-8 a 1-4 por
## partido). Es la barra que ves y lo que mira el DT para cambiarte.
func forma_fisica(p: Dictionary) -> float:
	if p.is_empty():
		return 1.0
	## En la prórroga el cansancio sigue subiendo (hasta un tercio más).
	var jugado := clampf(tiempo_jugado() / (2.0 * duracion_mitad), 0.0, 1.35)
	var fis := float(p["attr"]["fis"]) if p.has("attr") else 0.6
	var por_tiempo := jugado * 0.42 * (1.3 - fis)
	## Quien entró desde el banco llega fresco: solo cuenta lo que jugó.
	por_tiempo *= clampf(1.0 - float(p.get("entro_en", 0.0)), 0.0, 1.0) if jugado > 0.0 else 1.0
	return clampf(1.0 - por_tiempo - (1.0 - float(p.get("aguante", 1.0))) * 0.5, 0.2, 1.0)

## El que espera en la banda. Si es el usuario, entra en `minuto_entrada`.
func poner_extra(p: Dictionary, es_usuario: bool, minuto_entrada: int = -1) -> void:
	_preparar_uno(p)
	p["por"] = false
	extra = p
	(p["node"] as Node3D).position = Vector3(ANCHO + 2.5, 0, 6.0 if bool(p["es_local"]) else -6.0)
	if es_usuario:
		usuario = {}
		entra_usuario_min = maxi(1, minuto_entrada)

## Segundos reales que dura la mitad `m` (la en curso por defecto): las dos de
## la prórroga son de 15', un tercio de las normales.
func dur_mitad(m := -1) -> float:
	var mm := mitad if m < 0 else m
	return duracion_mitad if mm <= 2 else duracion_mitad / 3.0

func minutos_de_mitad(m := -1) -> float:
	return 45.0 if (mitad if m < 0 else m) <= 2 else 15.0

## El minuto en que empieza la mitad: 0, 45, 90 o 105.
func minuto_base(m := -1) -> int:
	return [0, 45, 90, 105][clampi((mitad if m < 0 else m) - 1, 0, 3)]

func minuto() -> int:
	var d := dur_mitad()
	return int(minf(t, d) / d * minutos_de_mitad()) + minuto_base()

func _cambiar(sale: Dictionary, entra: Dictionary, entra_es_usuario: bool) -> void:
	var i := jugadores.find(sale)
	if i < 0 or entra.is_empty():
		return
	_cambio_hecho = true
	## El que entra hereda el sitio táctico del que sale.
	entra["slot_code"] = sale["slot_code"]
	entra["entro_en"] = clampf(tiempo_jugado() / (2.0 * duracion_mitad), 0.0, 1.0)
	entra["base_pos"] = sale["base_pos"]
	(entra["node"] as Node3D).position = Vector3(ANCHO - 0.5, 0, 0)
	(entra["node"] as Node3D).visible = true
	jugadores[i] = entra
	var ns: Node3D = sale["node"]
	## Para la vista (cartel y palmada en la Carrera de Jugador): de dónde sale.
	ultimo_cambio = {"sale": sale, "entra": entra, "pos": ns.position}
	ns.position = Vector3(ANCHO + 2.5, 0, 4.0)
	ns.visible = false
	if poseedor == sale:
		poseedor = {}
	if entra_es_usuario:
		usuario = entra
	elif sale == usuario:
		usuario = {}
		usuario_sustituido = true
	extra = {}
	var nom_s := String((sale.get("jugador", {}) as Dictionary).get("nombre", ""))
	var nom_e := String((entra.get("jugador", {}) as Dictionary).get("nombre", ""))
	aviso.emit("🔁 Cambio: entra %s, sale %s" % [nom_e, nom_s])
	sustitucion.emit(nom_s, nom_e, bool(entra["es_local"]))

## El compañero que deja su sitio al que entra: el de su línea más cansado.
func _quien_sale_por(entra: Dictionary) -> Dictionary:
	var grupo := String((entra.get("jugador", {}) as Dictionary).get("pos", "MED"))
	var peor: Dictionary = {}
	for q: Dictionary in jugadores:
		if bool(q["es_local"]) != bool(entra["es_local"]) or bool(q["por"]):
			continue
		var g := String((q.get("jugador", {}) as Dictionary).get("pos", ""))
		var nota := forma_fisica(q) + (0.0 if g == grupo else 0.5)
		if peor.is_empty() or nota < float(peor["_nota_cambio"]):
			q["_nota_cambio"] = nota
			peor = q
	return peor

# ---------------------------------------------------------------- resumen

## La nota de tu partido, como la de los diarios: 6 de base.
func nota_usuario() -> float:
	var s := stats
	var n := 6.0 + float(s["goles"]) * 1.0 + float(s["asist"]) * 0.6 + float(s["pases_ok"]) * 0.03 \
		- float(maxi(0, int(s["pases"]) - int(s["pases_ok"]))) * 0.05 + float(s["a_puerta"]) * 0.12 \
		+ float(s["entradas_ok"]) * 0.12 - float(s["faltas"]) * 0.1
	if not usuario.is_empty():
		var mio := 0 if bool(usuario["es_local"]) else 1
		n += 0.3 if goles[mio] > goles[1 - mio] else (-0.3 if goles[mio] < goles[1 - mio] else 0.0)
	return clampf(snappedf(n, 0.1), 3.0, 10.0)

## ¿Toca hacer el cambio en este balón parado?
## `forzar`: sin balón parado desde hace rato, el árbitro para el juego para
## el cambio (con mitades cortas podía pasar media parte sin una interrupción y
## el suplente no entraba nunca).
func _revisar_cambio(forzar := false) -> void:
	if extra.is_empty() or _cambio_hecho:
		return
	var minu := minuto()
	if forzar:
		minu = maxi(minu, 0)
	if entra_usuario_min >= 0:
		if minu >= entra_usuario_min:
			_cambiar(_quien_sale_por(extra), extra, true)
		return
	## Tú en el campo: el DT lo decide UNA vez, en el primer balón parado
	## pasada la hora. Pesa su exigencia, tu nota y tu cansancio.
	if usuario.is_empty() or minu < 60 or _cambio_decidido:
		return
	_cambio_decidido = true
	var prob := 0.05 + exigencia_dt * 0.35 + maxf(0.0, 6.6 - nota_usuario()) * 0.3 \
		+ maxf(0.0, 0.75 - forma_fisica(usuario)) * 1.2 + prob_cambio_extra
	if _rng.randf() < clampf(prob, 0.0, 0.95 + prob_cambio_extra):
		_cambiar(usuario, extra, false)

## La perilla `k` del equipo (1 = término medio). La dificultad de la CPU
## puede subir o bajar su presión.
func _tac(local: bool, k: String) -> int:
	var tc: Dictionary = tacticas[0 if local else 1]
	var v := int(tc.get(k, 1))
	if k == "presion" and equipo_cpu() == (0 if local else 1):
		v = clampi(v + int(DIFICULTADES[dificultad_cpu]["presion"]), 0, 2)
	return v

## Cambia la dificultad (o recalcula al cambiar quién maneja a quién).
func fijar_dificultad(nivel: String) -> void:
	if DIFICULTADES.has(nivel):
		dificultad_cpu = nivel
	for p: Dictionary in jugadores + ([extra] if not extra.is_empty() else []):
		_dificultad_de(p)

## Lo que piensa el portador de este equipo antes de decidir (por la dificultad).
func _pausa_dificultad(p: Dictionary) -> float:
	if equipo_cpu() == (0 if bool(p["es_local"]) else 1):
		return float(DIFICULTADES[dificultad_cpu]["pausa"])
	return 1.0

func empezar_practica() -> void:
	practica = true
	duracion_mitad = 99999.0
	_practica_pos.clear()
	for p: Dictionary in jugadores:
		_practica_pos[String(p["id"])] = pos(p)

func _arco_rival(p: Dictionary) -> Vector3:
	if estado == "tanda":
		return TANDA_ARCO
	return Vector3(0, 0, LARGO * dir_ataque(bool(p["es_local"])))

## El rival no va a por el balón (cada uno vuelve a su sitio) y no se lo
## queda: si lo toca, el balón vuelve delante de tu jugador.
func _paso_practica() -> void:
	var mio := control_equipo if control_equipo >= 0 else 0
	for p: Dictionary in jugadores:
		if (0 if bool(p["es_local"]) else 1) != mio and _practica_pos.has(String(p["id"])):
			p["objetivo"] = _practica_pos[String(p["id"])]
			p["correr"] = false
	if not poseedor.is_empty() and (0 if bool(poseedor["es_local"]) else 1) != mio and not usuario.is_empty():
		var u := pos(usuario)
		var hacia := (_arco_rival(usuario) - u).normalized()
		balon.position = Vector3(u.x, 0.11, u.z) + hacia * 0.9
		vel_balon = Vector3.ZERO
		poseedor = {}
		ultimo_toque = usuario

## La pizarra del club traducida al motor. «Ir a por todo» (`riesgo`) sube un
## punto la mentalidad y «cerrar el partido» (`tiempo`) la baja.
static func tactica_desde(tc: Tactica, riesgo := false, tiempo := false) -> Dictionary:
	if tc == null:
		return {}
	var m := tc.mentalidad + (1 if riesgo else 0) - (1 if tiempo else 0)
	return {"mentalidad": clampi(m, 0, 3), "presion": tc.presion, "linea": tc.linea,
		"amplitud": tc.amplitud, "ritmo": tc.ritmo, "trampa": 1 if tc.fuera_de_juego else 0}

## El añadido crece con lo que se pierde en el tiempo reglamentario (17-10):
## goles, cambios, expulsiones. Solo antes de que empiece y con tope.
func _sumar_anadido(minutos: float) -> void:
	if mitad < 1 or anadido.size() < mitad or t > dur_mitad():
		return
	var tope := (4.0 if mitad == 1 else (7.0 if mitad == 2 else 3.0)) / minutos_de_mitad() * dur_mitad()
	anadido[mitad - 1] = minf(float(anadido[mitad - 1]) + minutos / minutos_de_mitad() * dur_mitad(), tope)

## Un cambio en pleno partido: `entra` (un diccionario de `PlayerSpawner`) ocupa
## el sitio táctico de `sale_id` y aparece en la banda, a la altura del medio.
func reemplazar(sale_id: String, entra: Dictionary) -> bool:
	_sumar_anadido(0.5)
	var i := -1
	for k in jugadores.size():
		if String(jugadores[k].get("id", "")) == sale_id:
			i = k
			break
	if i < 0 or entra.is_empty():
		return false
	var sale: Dictionary = jugadores[i]
	_preparar_uno(entra)
	entra["slot_code"] = sale["slot_code"]
	entra["base_pos"] = sale["base_pos"]
	entra["es_local"] = sale["es_local"]
	entra["por"] = sale["por"]
	entra["entro_en"] = clampf(tiempo_jugado() / (2.0 * duracion_mitad), 0.0, 1.0)
	var n: Node3D = entra["node"]
	n.position = Vector3(signf(pos(sale).x + 0.01) * (ANCHO - 0.5), 0, clampf(pos(sale).z, -8.0, 8.0))
	n.visible = true
	jugadores[i] = entra
	if poseedor == sale:
		poseedor = {}
	if pase_a == sale:
		pase_a = {}
	if usuario == sale:
		usuario = {}
	return true

## La roja: sale del campo y el equipo sigue con uno menos.
func _expulsar(p: Dictionary) -> void:
	_sumar_anadido(0.5)
	jugadores.erase(p)
	expulsados.append(p)
	var n: Node3D = p["node"]
	n.position = Vector3(ANCHO + 3.0, 0, 0)
	n.visible = false
	if poseedor == p:
		poseedor = {}
	if pase_a == p:
		pase_a = {}
	if usuario == p:
		usuario = {}

## Para reabrir el partido a mitad (tras el descanso): el marcador y el reloj
## del `Partido`, y saque de centro.
func empezar_en(minuto_: int, gl: int, gv: int) -> void:
	goles = [gl, gv]
	if minuto_ >= 45:
		mitad = 2
		t = clampf(float(minuto_ - 45) / 45.0 * duracion_mitad, 0.0, duracion_mitad - 1.0)
		_saque_de_centro(false)
	else:
		t = clampf(float(minuto_) / 45.0 * duracion_mitad, 0.0, duracion_mitad - 1.0)

## Contadores para las sondas (remates por clase y cómo acaban: «remate_pie_atajada»…).
var diag := {}
func _contar(k: String) -> void:
	diag[k] = int(diag.get(k, 0)) + 1

## El remate en curso termina: atajada, palo o fuera.
func _cerrar_tiro(tipo: String) -> void:
	if _tiro_vivo.is_empty():
		return
	var p: Dictionary = _tiro_vivo["p"]
	_contar("remate_%s_%s" % [String(_tiro_vivo.get("clase", "pie")), tipo])
	_tiro_vivo = {}
	remate.emit(bool(p["es_local"]), String(p.get("id", "")), tipo)

func _arco_propio(p: Dictionary) -> Vector3:
	if estado == "tanda":
		return TANDA_ARCO
	return Vector3(0, 0, -LARGO * dir_ataque(bool(p["es_local"])))

func _en_su_area(p: Dictionary, b: Vector3) -> bool:
	var arco := _arco_propio(p)
	return absf(b.x) < AREA_X and absf(b.z - arco.z) < AREA_Z
