extends "res://visor/motor_jugable_p10.gd"
## [Capa 11/12 de `motor_jugable.gd`] _colocar_saque, _sitio_tanda, _siguiente_penal, _resultado_tanda, _vuelo_tanda, tanda_decidida … (+5)

## Coloca a todos para el saque y, cuando están, lo ejecuta (o espera al
## usuario si lanza él).
func _colocar_saque(delta: float) -> void:
	var tipo := String(saque.get("tipo", "centro"))
	var lugar: Vector3 = saque["lugar"]
	var lanzador: Dictionary = saque.get("lanzador", {})
	var saca_local := bool(saque["local"])
	for p: Dictionary in jugadores:
		var obj: Vector3
		if p == lanzador:
			var atras := (lugar - _arco_rival(p)).normalized() if tipo != "banda" else Vector3(signf(lugar.x), 0, 0)
			obj = lugar + atras * 0.6
		elif tipo == "centro":
			obj = p["base_pos"]
		elif tipo == "penal":
			obj = _fuera_del_area(p)
			if bool(p["por"]) and bool(p["es_local"]) != saca_local:
				obj = _arco_propio(p) + Vector3(0, 0, dir_ataque(bool(p["es_local"])) * 0.3)
		elif tipo in ["corner", "falta"]:
			obj = _pos_balon_parado(p, lugar, saca_local)
		else:
			obj = _forma(p, bool(p["es_local"]) == saca_local)
		if bool(p["por"]) and tipo != "puerta" and not (tipo == "penal"):
			obj = _ia_portero_saque(p)
		p["objetivo"] = obj
		p["correr"] = true
		## Se colocan rápido (en los saques el juego está parado), pero a paso
		## de persona: la ayuda solo completa hasta un esprint de 9 m/s. Antes
		## sumaba 14 m/s a su carrera y patinaban a 22 m/s (sonda de física).
		var n: Node3D = p["node"]
		## Y se apaga al acercarse (antes se cortaba de golpe al llegar: tirones
		## de más de 100 m/s² en la sonda).
		## La ayuda es una velocidad más, que crece suave (6 m/s²).
		var ayuda := maxf(0.0, 9.0 - (p["vel"] as Vector3).length()) * clampf(n.position.distance_to(obj) / 6.0, 0.0, 1.0)
		var hacia := obj - n.position
		hacia.y = 0.0
		var av_obj := hacia.normalized() * ayuda if hacia.length() > 0.05 else Vector3.ZERO
		var av: Vector3 = (p.get("ayuda_v", Vector3.ZERO) as Vector3).move_toward(av_obj, 6.0 * delta)
		## Nunca por encima de lo que le falta para el esprint (con los saques
		## rápidos, la ayuda que iba con retraso se sumaba a la carrera: >10 m/s).
		av = av.limit_length(maxf(0.0, 9.0 - (p["vel"] as Vector3).length()))
		p["ayuda_v"] = av
		n.position += av * delta
	if lanzador.is_empty():
		_reanudar()
		return
	if lanzador == usuario and not autopiloto:
		if not apuntando and _t_estado > 0.8:
			apuntando = true
			apunte = {"ang": 0.0, "loft": 0.35 if tipo == "corner" else 0.15, "fuerza": 0.0, "fase": 0.0, "x": 0.0, "y": 0.8}
			cambio_estado.emit("apuntar_" + tipo)
		if apuntando:
			_apuntar_usuario(delta)
		return
	## Se saca cuando están colocados (o, como mucho, 3 s después). El saque de
	## banda y el de puerta son rápidos, como en el fútbol de verdad: no esperan
	## a que todos lleguen (20-10-2026, más chispa: 1,6-1,9 s cada uno).
	var espera: float = {"centro": 1.0, "banda": 0.8, "puerta": 1.1}.get(tipo, 1.4)
	var rapido := tipo in ["banda", "puerta"]
	## GESTIÓN DEL TIEMPO (M-127, 20-10): desde el 75', el equipo de la CPU que
	## gana se toma su tiempo en cada saque y el que pierde los saca rápido.
	var ritmo := _ritmo_de_saque(lanzador)
	if ritmo > 1.0:
		rapido = false
	espera *= ritmo
	if _t_estado > espera and (rapido or _colocados() or _t_estado > espera + 3.0):
		_ejecutar_saque_ia(lanzador, tipo, lugar)

## Dónde espera cada uno: los de campo en el círculo central, en fila por
## equipo; el portero que no defiende, junto al área.
func _sitio_tanda(p: Dictionary) -> Vector3:
	var eq := 0 if bool(p["es_local"]) else 1
	if bool(p["por"]):
		return Vector3(-9.0 if eq == 0 else 9.0, 0, LARGO - AREA_Z - 1.5)
	var orden: Array = tanda["orden"][eq]
	var i := maxi(orden.find(p), 0)
	var lado := -1.0 if eq == 0 else 1.0
	return Vector3(lado * (1.0 + float(i % 10) * 0.8), 0, 1.0)

func _siguiente_penal() -> void:
	var eq := tanda_turno()
	## El orden se rehace cada vez: un cambio de última hora deja fuera al que
	## salió (su nodo ya no existe) y mete al que entró en su sitio por tiro.
	tanda["orden"] = [_orden_tanda(true), _orden_tanda(false)]
	var orden: Array = tanda["orden"][eq]
	var hechos: int = (tanda["tiros"][eq] as Array).size()
	var lz: Dictionary = orden[hechos % orden.size()] if not orden.is_empty() else {}
	var gk: Dictionary = {}
	for q: Dictionary in jugadores:
		if bool(q["por"]) and bool(q["es_local"]) != (eq == 0):
			gk = q
	## El lanzador anterior vuelve al círculo y el portero que deja de
	## defender, a su sitio de espera.
	for antes: Dictionary in [tanda["lanzador"], tanda["portero"]]:
		if not antes.is_empty() and antes != gk and antes != lz and jugadores.has(antes):
			(antes["node"] as Node3D).position = _sitio_tanda(antes)
			antes["vel"] = Vector3.ZERO
			antes["gesto_hasta"] = 0.0
	tanda["lanzador"] = lz
	tanda["portero"] = gk
	tanda["lado"] = SIN_ELEGIR
	tanda["cruzo"] = false
	tanda["fase"] = "preparar"
	_t_estado = 0.0
	usuario = {}
	balon.position = TANDA_PUNTO
	vel_balon = Vector3.ZERO
	giro_balon = Vector3.ZERO
	if not lz.is_empty():
		## Sale del círculo: aparece camino del punto (sin cruzar medio campo).
		(lz["node"] as Node3D).position = TANDA_PUNTO + Vector3(-2.2, -R, -5.5)
		lz["vel"] = Vector3.ZERO
		lz["gesto_hasta"] = 0.0
	if not gk.is_empty():
		(gk["node"] as Node3D).position = TANDA_ARCO - Vector3(0, 0, 0.3)
		gk["vel"] = Vector3.ZERO
		gk["gesto_hasta"] = 0.0
	var nombre := String((lz.get("jugador", {}) as Dictionary).get("nombre", ""))
	aviso.emit("🥅 Penal %d: %s" % [hechos + 1, nombre])
	cambio_estado.emit("tanda_penal")

func _resultado_tanda(marcado: bool, texto: String) -> void:
	var lz: Dictionary = tanda["lanzador"]
	var eq := tanda_turno()
	(tanda["tiros"][eq] as Array).append(marcado)
	tanda["fase"] = "resultado"
	_t_estado = 0.0
	if not lz.is_empty() and jugadores.has(lz):
		_anim(lz, "celebrar" if marcado else ["lamento", "manos_cabeza"][_rng.randi() % 2], true, 2.0)
	aviso.emit(texto)
	tanda_tiro.emit(eq, String(lz.get("id", "")), marcado)

## El balón en el aire: parada, palo, gol o fuera.
func _vuelo_tanda() -> void:
	var b := balon.position
	var gk: Dictionary = tanda["portero"]
	var lado: int = int(tanda["lado"])
	if not bool(tanda["cruzo"]) and b.z >= LARGO - 0.8:
		tanda["cruzo"] = true
		## ¿Llega el portero? Tirado al lado bueno tapa hasta ~2,5 m del centro
		## (menos arriba); quieto, solo lo que va al medio.
		var para := false
		if not gk.is_empty() and absf(b.x) < PALO + 0.2 and b.y < LARGUERO:
			var alcance := 1.4 + (float(gk["attr"]["div"]) + float(gk["attr"]["ref"])) * 0.6
			if lado == 0:
				para = absf(b.x) < 1.1 and b.y < 2.0
			elif signf(b.x) == float(lado):
				var dentro := absf(b.x) > 0.3 and absf(b.x) < alcance and b.y < (1.6 if absf(b.x) > 2.3 else 2.1)
				## 17-10: entraban ~9 de cada 10; con esto, ~3 de cada 4 (como en la realidad).
				para = dentro and _rng.randf() < 0.62 + float(gk["attr"]["ref"]) * 0.3
		if para:
			vel_balon = Vector3(signf(b.x + 0.01) * _rng.randf_range(3, 7), _rng.randf_range(1, 3), -absf(vel_balon.z) * 0.3)
			_resultado_tanda(false, "¡Qué parada!")
			return
	if b.z >= LARGO:
		var dentro := absf(b.x) < PALO and b.y < LARGUERO
		var palo := (absf(absf(b.x) - PALO) < 0.12 + R and b.y < LARGUERO + R) or (absf(b.x) < PALO and absf(b.y - LARGUERO) < 0.12 + R)
		if palo:
			vel_balon = Vector3(-signf(b.x) * 2.0, -absf(vel_balon.y) * 0.4, -vel_balon.z * 0.5)
			balon.position.z = LARGO - 0.2
			_resultado_tanda(false, "¡AL PALO!")
		elif dentro:
			vel_balon *= 0.2
			_resultado_tanda(true, "⚽ ¡Dentro!")
		else:
			_resultado_tanda(false, "¡Fuera!")
		return
	## Se quedó corto: fallado.
	if _t_estado > 3.0:
		_resultado_tanda(false, "¡Fallado!")

## ¿Ya está decidida? Cinco cada uno con cuentas imposibles, o muerte súbita.
static func tanda_decidida(tiros_: Array) -> bool:
	var na: int = (tiros_[0] as Array).size()
	var nb: int = (tiros_[1] as Array).size()
	var ga := 0
	var gb := 0
	for b: bool in tiros_[0]:
		ga += 1 if b else 0
	for b: bool in tiros_[1]:
		gb += 1 if b else 0
	if na <= 5 and nb <= 5:
		if ga + (5 - na) < gb or gb + (5 - nb) < ga:
			return true
		return na == 5 and nb == 5 and ga != gb
	return na == nb and ga != gb

func goles_tanda(eq: int) -> int:
	var n := 0
	if tanda.is_empty():
		return 0
	for b: bool in tanda["tiros"][eq]:
		if b:
			n += 1
	return n

func _cerrar_tanda() -> void:
	var gl := goles_tanda(0)
	var gv := goles_tanda(1)
	tanda["fase"] = "fin"
	usuario = {}
	aviso.emit("🥅 Penales: %d-%d" % [gl, gv])
	tanda_terminada.emit(gl, gv)
	var gana_local := gl > gv
	for p: Dictionary in jugadores:
		if bool(p["es_local"]) == gana_local:
			_anim(p, "celebrar" if _rng.randf() < 0.6 else "aplauso_arriba", true, 99.0)
		elif _rng.randf() < 0.5:
			_anim(p, ["lamento", "manos_cabeza", "cuclillas_lamento", "brazos_jarra"][_rng.randi() % 4], true, 99.0)
	_terminar()

func _paso_tanda(delta: float) -> void:
	var fase := String(tanda["fase"])
	var lz: Dictionary = tanda["lanzador"]
	var gk: Dictionary = tanda["portero"]
	## Un cambio durante la tanda (el lanzador o el portero ya no están): ese
	## penal se vuelve a preparar con el que toque.
	if fase in ["preparar", "apuntar"] and ((not lz.is_empty() and not jugadores.has(lz)) or (not gk.is_empty() and not jugadores.has(gk))):
		usuario = {}
		apuntando = false
		cargando = false
		_siguiente_penal()
		return
	var detras := TANDA_PUNTO + Vector3(0, -R, -0.9)
	for p: Dictionary in jugadores:
		if p == lz and fase in ["preparar", "apuntar"]:
			p["objetivo"] = detras
			p["correr"] = false
		elif p == gk:
			if fase in ["preparar", "apuntar"]:
				p["objetivo"] = TANDA_ARCO - Vector3(0, 0, 0.3)
				p["correr"] = false
		elif p == lz:
			pass
		else:
			p["objetivo"] = _sitio_tanda(p)
			p["correr"] = pos(p).distance_to(p["objetivo"]) > 12.0
			## Desde el saque de la prórroga hasta el círculo: rápido, como en
			## los saques (el juego está parado).
			if fase == "entrar":
				var n: Node3D = p["node"]
				n.position = n.position.move_toward(p["objetivo"], 14.0 * delta)
	_mover_jugadores(delta)
	if fase in ["vuelo", "resultado"]:
		_mover_balon(delta)
	_actualizar_balon_visual(delta)
	match fase:
		"entrar":
			if _t_estado > 2.5:
				_siguiente_penal()
		"preparar":
			## El portero en la línea, mirando al lanzador.
			if not gk.is_empty():
				(gk["node"] as Node3D).rotation.y = PI
			## Tu portero: el stick elige el lado (con la cámara detrás del
			## lanzador, la derecha de la pantalla es -X).
			var tu := tanda_equipo_usuario()
			if tu >= 0 and tanda_turno() != tu:
				var mx := Mando.movimiento().x
				if absf(mx) > 0.3:
					tanda["lado"] = -1 if mx > 0.0 else 1
				elif Input.is_action_pressed("jugar_tiro"):
					tanda["lado"] = 0
			if lz.is_empty():
				_resultado_tanda(false, "¡Fallado!")
				return
			if pos(lz).distance_to(detras) < 0.6 or _t_estado > 4.0:
				var lanza_tu := tu >= 0 and tanda_turno() == tu
				if lanza_tu and _t_estado > 1.0:
					tanda["fase"] = "apuntar"
					_t_estado = 0.0
					usuario = lz
					saque = {"tipo": "penal", "local": bool(lz["es_local"]), "lugar": TANDA_PUNTO, "lanzador": lz}
					apuntando = true
					apunte = {"ang": 0.0, "loft": 0.15, "fuerza": 0.0, "fase": 0.0, "x": 0.0, "y": 0.8}
					cambio_estado.emit("apuntar_penal")
				elif not lanza_tu and _t_estado > (2.8 if tu >= 0 else 1.6):
					saque = {"tipo": "penal", "local": bool(lz["es_local"]), "lugar": TANDA_PUNTO, "lanzador": lz}
					_ejecutar_saque_ia(lz, "penal", TANDA_PUNTO)
		"apuntar":
			(lz["node"] as Node3D).rotation.y = 0.0
			_apuntar_usuario(delta)
		"vuelo":
			_vuelo_tanda()
		"resultado":
			if _t_estado > 2.0:
				if tanda_decidida(tanda["tiros"]):
					_cerrar_tanda()
				else:
					_siguiente_penal()

func _ia_celebracion(_delta: float) -> void:
	var g := _goleador
	var hay := estado == "gol" and not g.is_empty() and jugadores.has(g)
	var esquina := Vector3.ZERO
	if hay:
		var gp := pos(g)
		esquina = Vector3(signf(gp.x + 0.01) * (ANCHO - 2.5), 0, clampf(gp.z, -LARGO + 3.0, LARGO - 3.0) * 0.85)
	for p: Dictionary in jugadores:
		if p == usuario and not autopiloto:
			continue
		if hay and p == g:
			var lejos := pos(p).distance_to(esquina)
			p["objetivo"] = esquina
			p["correr"] = lejos > 1.5
			if lejos <= 1.5 and float(p.get("gesto_hasta", 0.0)) <= t:
				## Llegó: su celebración (y se queda en ella).
				_anim(p, _celebra_anim, true, 99.0)
			continue
		if hay and bool(p["es_local"]) == bool(g["es_local"]) and not bool(p["por"]) and _t_estado > 0.8 \
				and pos(p).distance_to(pos(g)) < 34.0:
			## A abrazarlo: alrededor de él, sin meterse encima.
			var lado := Vector3(sin(float(absi(String(p.get("id", "")).hash()) % 628) / 100.0), 0,
				cos(float(absi(String(p.get("id", "")).hash()) % 628) / 100.0))
			p["objetivo"] = pos(g) + lado * 1.0
			p["correr"] = true
			if pos(p).distance_to(pos(g)) < 1.7 and float(p.get("gesto_hasta", 0.0)) <= t:
				_anim(p, "celebrar" if _rng.randf() < 0.5 else "aplauso_arriba", true, 99.0)
			continue
		p["objetivo"] = _forma(p, false)
		p["correr"] = false
		## El que encajó: lamento.
		if hay and bool(p["es_local"]) != bool(g["es_local"]) and _t_estado < 0.1:
			if _rng.randf() < 0.4:
				_anim(p, ["lamento", "manos_cabeza", "cuclillas_lamento", "brazos_jarra"][_rng.randi() % 4], true, 99.0)

## CUERPOS QUE NO SE ATRAVIESAN en el motor real: cada par a menos de dos
## radios de hombro se aparta por la línea que los une, el débil más que el
## fuerte (masa = fuerza), y se les quita la velocidad con que chocaban.
func _cuerpos() -> void:
	if not cuerpos_activos:
		return
	var minimo := RADIO_CUERPO * 2.0
	var n := jugadores.size()
	for i in n:
		var pa: Dictionary = jugadores[i]
		var a: Node3D = pa["node"]
		if not is_instance_valid(a):
			continue
		for j in range(i + 1, n):
			var pb: Dictionary = jugadores[j]
			var b: Node3D = pb["node"]
			if not is_instance_valid(b):
				continue
			var dx := b.position.x - a.position.x
			var dz := b.position.z - a.position.z
			var d2 := dx * dx + dz * dz
			if d2 >= minimo * minimo:
				continue
			var d := sqrt(d2)
			var nrm := Vector3(dx, 0, dz) / d if d > 0.001 else Vector3(1, 0, 0).rotated(Vector3.UP, float(i * 7 + j))
			var ma := 0.6 + _fuerza(pa) * 0.8
			var mb := 0.6 + _fuerza(pb) * 0.8
			var hueco := minimo - d
			a.position -= nrm * hueco * mb / (ma + mb)
			b.position += nrm * hueco * ma / (ma + mb)
			var va: Vector3 = pa["vel"]
			var vb: Vector3 = pb["vel"]
			var acerca := (va - vb).dot(nrm)
			if acerca > 0.0:
				pa["vel"] = va - nrm * acerca * mb / (ma + mb)
				pb["vel"] = vb + nrm * acerca * ma / (ma + mb)
