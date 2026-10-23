class_name MetroCiudad
extends "res://visor/metro_ciudad_p3.gd"
## (Parte 4 de 4 de `metro_ciudad.gd`.)

## Camina a cada uno hacia su siguiente punto, sin atravesar a los demás.
func _mover_caminantes(delta: float) -> void:
	if _caminantes.is_empty():
		return
	var quedan: Array = []
	for c: Dictionary in _caminantes:
		var d: Dictionary = c["d"]
		var n: Node3D = d["nodo"]
		if not is_instance_valid(n):
			continue
		if float(c["espera"]) > 0.0:
			c["espera"] = float(c["espera"]) - delta
			quedan.append(c)
			continue
		if not bool(c["andando"]):
			c["andando"] = true
			Mini3D.anim(d, "caminar", "")
		var ruta: Array = c["ruta"]
		var obj: Vector3 = ruta[0]
		var hacia := Vector3(obj.x - n.position.x, 0, obj.z - n.position.z)
		var dist := hacia.length()
		var paso := VEL_GENTE * delta
		## Los puntos de paso no hace falta pisarlos exactos (si alguien espera
		## justo ahí, se quedaba atascado empujándolo); el último sí.
		var tolerancia := 0.12 if ruta.size() == 1 else 0.45
		if dist <= maxf(paso, tolerancia):
			if ruta.size() == 1:
				n.position = obj
			ruta.pop_front()
			if ruta.is_empty():
				_fin_caminante(c)
				continue
			quedan.append(c)
			continue
		var dir := hacia / dist
		var antes := n.position
		var p := n.position + dir * paso
		## Al cruzar la puerta ya no se esquiva (dentro del coche no hay nadie del
		## andén); y quien lleva un rato atascado pasa rozando (el tren espera).
		var atasco := float(c.get("atasco", 0.0))
		if (ruta.size() > 1 or String(c["fin"]) != "subir") and atasco < 1.2:
			p = _apartar_de_otros(p, n, dir, paso)
		var avance := Vector2(p.x - antes.x, p.z - antes.z).dot(Vector2(dir.x, dir.z))
		if avance < paso * 0.3:
			c["atasco"] = atasco + delta
		elif atasco >= 1.2:
			c["atasco"] = atasco + delta if atasco < 2.5 else 0.0
		else:
			c["atasco"] = 0.0
		p.y = lerpf(n.position.y, obj.y, minf(1.0, delta * 6.0))
		n.position = p
		n.rotation.y = lerp_angle(n.rotation.y, atan2(dir.x, dir.z), minf(1.0, delta * 8.0))
		quedan.append(c)
	_caminantes = quedan

## Los sitios que quedaron libres se vuelven a ocupar al rato.
func _llegadas(delta: float) -> void:
	if _huecos.is_empty() or _gente == null:
		return
	var quedan: Array = []
	for h: Dictionary in _huecos:
		h["t"] = float(h["t"]) - delta
		if float(h["t"]) <= 0.0:
			_cola_gente.append({"tipo": "llegar", "s": h["s"], "e": h["e"]})
		else:
			quedan.append(h)
	_huecos = quedan

func _pasajeros_cerca(yo: Vector3) -> void:
	var mejor: Node3D = null
	var dmin := 45.0
	for l: Dictionary in lineas:
		for n: Node3D in l["nodos"]:
			var d := n.position.distance_to(yo)
			if d < dmin:
				dmin = d
				mejor = n
	if mejor == _pas_tren:
		return
	_pas_tren = mejor
	if _pas_nodo != null and is_instance_valid(_pas_nodo):
		_pas_nodo.queue_free()
	_pas_nodo = null
	_cola_pas.clear()
	if mejor == null:
		return
	_pas_nodo = Node3D.new()
	_pas_nodo.name = "Pasajeros"
	mejor.add_child(_pas_nodo)
	var rng := RandomNumberGenerator.new()
	rng.seed = mejor.get_instance_id()
	## Asientos (en coordenadas del coche): los mismos de `_interior_coche`.
	var libres: Array = []
	for k in 3:
		for lado: float in [-1.0, 1.0]:
			for tramo: Array in TRAMOS_ASIENTO:
				var n_as := int(float(tramo[1]) / PASO_ASIENTO)
				for q in n_as:
					var z := (float(k) - 1.0) * 16.6 + float(tramo[0]) + (float(q) - float(n_as - 1) * 0.5) * PASO_ASIENTO
					libres.append(Vector3(lado, 0, z))
	for _i in 8:
		var a: Vector3 = libres.pop_at(rng.randi() % libres.size())
		## No delante de la cámara del viajero (coche central, z ≈ -5).
		if a.z > -7.0 and a.z < -3.0:
			continue
		_cola_pas.append({"pos": Vector3(a.x * 1.04, PISO_COCHE, a.z), "giro": atan2(-a.x, 0.0), "sentado": true})
	## De pie, junto a las barras del centro.
	for z2: float in [0.0, -16.6, 22.6]:
		_cola_pas.append({"pos": Vector3(rng.randf_range(0.25, 0.45) * (1.0 if rng.randf() < 0.5 else -1.0), PISO_COCHE, z2 + 0.35), "giro": rng.randf_range(-PI, PI), "sentado": false})

## Llena (o vacía) los andenes según dónde esté la cámara. Un andén elevado
## tiene dos lados: se llenan los dos de esa estación.
func _gente_cerca(delta: float) -> void:
	## Se crea una persona por fotograma (crear muchas de golpe da tirones).
	if not _cola_gente.is_empty() and _gente != null:
		_crear_persona(_cola_gente.pop_front())
	if not _cola_pas.is_empty() and _pas_nodo != null and is_instance_valid(_pas_nodo):
		_crear_pasajero(_cola_pas.pop_front())
	for f: Dictionary in _fijos_gente:
		if not bool(f["charla"]):
			continue
		f["t"] = float(f["t"]) - delta
		if float(f["t"]) <= 0.0:
			f["t"] = _rng_gente.randf_range(4.0, 9.0)
			Mini3D.anim(f["d"], "charla" if _rng_gente.randf() < 0.7 else "parado", "")
	## En pasos cortos: con fotogramas lentos, un paso de un metro de golpe hacía
	## que el esquive rebotara y la gente se quedara clavada.
	var pasos := mini(20, ceili(delta / 0.05))
	for _i in pasos:
		_mover_caminantes(delta / float(pasos))
	_llegadas(delta)
	_t_gente -= delta
	if _t_gente > 0.0:
		return
	_t_gente = 0.5
	var cam := get_viewport().get_camera_3d() if is_inside_tree() else null
	if cam == null:
		return
	var yo := cam.global_position
	_pasajeros_cerca(yo)
	var mejor: Dictionary = {}
	var dmin := RADIO_GENTE
	for e: Dictionary in _sitios:
		var d := yo.distance_to(e["centro"])
		if d < dmin:
			dmin = d
			mejor = e
	## La estación (los dos andenes de la elevada).
	var clave := "" if mejor.is_empty() else "%s" % str(mejor["p"])
	if clave == _gente_clave:
		return
	_gente_clave = clave
	if _gente != null:
		_gente.queue_free()
		_gente = null
	_cola_gente.clear()
	_fijos_gente.clear()
	_caminantes.clear()
	_embarque.clear()
	_huecos.clear()
	_gente_linea = ""
	_gente_idx = -1
	_gente_lados.clear()
	if clave == "":
		return
	_gente = Node3D.new()
	_gente.name = "GenteAnden"
	add_child(_gente)
	_rng_gente.seed = hash(clave)
	for e: Dictionary in _sitios:
		if str(e["p"]) == clave:
			_gente_lados.append(e)
			for s: Dictionary in e["sitios"]:
				## No todos los asientos ocupados.
				if bool(s["sentado"]) and _rng_gente.randf() < 0.45:
					continue
				_cola_gente.append({"tipo": "sitio", "s": s, "e": e})
	## Qué línea y qué estación es (para saber cuándo para su tren).
	for l: Dictionary in lineas:
		if bool(l["elevada"]) != bool(mejor["elevada"]):
			continue
		for i in (l["estaciones"] as Array).size():
			if (l["estaciones"][i] as Vector3).distance_to(mejor["p"]) < 0.5:
				_gente_linea = String(l["nombre"])
				_gente_idx = i

## La puerta del tren más cercana a `p` (en coordenadas del coche): [lado, z].
static func puerta_cercana(tren: Transform3D, p: Vector3) -> Array:
	var local := tren.affine_inverse() * p
	var mejor_z := 0.0
	var dmin := INF
	for k in 3:
		for dz: float in [-3.5, 3.5]:
			var z := (float(k) - 1.0) * 16.6 + dz
			if absf(z - local.z) < dmin:
				dmin = absf(z - local.z)
				mejor_z = z
	return [signf(local.x) if absf(local.x) > 0.01 else 1.0, mejor_z]

## La posición (en el espacio del metro) de un punto del coche: `x` lateral, `z` a lo largo.
static func _en_tren(tren: Transform3D, x: float, z: float) -> Vector3:
	return tren * Vector3(x, PISO_COCHE, z)

## Elige quién sube (de los que esperan) y crea a los que bajan.
func _planear_embarque(k: int, tren: Transform3D) -> void:
	var suben := 0
	var quedan: Array = []
	for f: Dictionary in _fijos_gente:
		var s: Dictionary = f["s"]
		var prob := 0.18 if bool(s["sentado"]) else (0.3 if bool(f["charla"]) else 0.55)
		if suben >= 5 or _rng_gente.randf() > prob:
			quedan.append(f)
			continue
		suben += 1
		var d: Dictionary = f["d"]
		var n: Node3D = d["nodo"]
		var pos := n.position
		pos.y = (s["p"] as Vector3).y
		n.position = pos
		var pu := puerta_cercana(tren, pos)
		var lado := float(pu[0])
		var z := float(pu[1]) + _rng_gente.randf_range(-0.25, 0.25)
		## Primero hacia la puerta por el andén, luego dentro del coche.
		var ruta: Array = [_en_tren(tren, lado * 2.7, z), _en_tren(tren, lado * 1.75, z),
			_en_tren(tren, lado * 0.8, z + _rng_gente.randf_range(-0.6, 0.6))]
		_caminantes.append({"d": d, "ruta": ruta, "fin": "subir", "tren": k, "suelta": -1,
			"espera": _rng_gente.randf_range(0.3, 1.8), "andando": false, "s": s, "e": f["e"]})
	_fijos_gente = quedan
	## Los que bajan: 1-3 por cada andén de la estación, escalonados.
	var retraso := 0.4
	for e: Dictionary in _gente_lados:
		var lado_e := float(puerta_cercana(tren, e["centro"])[0])
		for _q in _rng_gente.randi_range(1, 3):
			var coche := _rng_gente.randi_range(0, 2)
			var z := (float(coche) - 1.0) * 16.6 + (3.5 if _rng_gente.randf() < 0.5 else -3.5)
			var salida: Vector3 = e["salida"]
			var fuera := _en_tren(tren, lado_e * 3.2, z + _rng_gente.randf_range(-0.8, 0.8))
			_cola_gente.append({"tipo": "bajar", "tren": k, "espera": retraso,
				"ruta": [_en_tren(tren, lado_e * 0.7, z), _en_tren(tren, lado_e * 1.8, z), fuera,
					Vector3(salida.x, fuera.y, salida.z)]})
			retraso += _rng_gente.randf_range(0.5, 1.1)

## Dónde está el tren según su lógica (el nodo se mueve más tarde en el
## fotograma: con su posición vieja la gente iba a la puerta de otro sitio).
static func transform_tren(l: Dictionary, t: Tren) -> Transform3D:
	var a: Vector3 = l["a"]
	var dir: Vector3 = l["dir"]
	var y := ALTO_VIADUCTO + 0.6 if bool(l["elevada"]) else PROF_TUNEL
	var giro := atan2(dir.x, dir.z) + (0.0 if t.sentido > 0.0 else PI)
	return Transform3D(Basis(Vector3.UP, giro), a + dir * t.s + Vector3(0, y, 0))

## Los trenes que paran (o arrancan) en la estación con gente.
func _embarques(delta: float) -> void:
	if _gente_linea == "" or _gente == null:
		return
	var l := linea(_gente_linea)
	var s_est := float(l["est_s"][_gente_idx])
	for k in (l["trenes"] as Array).size():
		var t: Tren = l["trenes"][k]
		var en_estacion := absf(t.s - s_est) < 1.0
		if en_estacion and t.espera > 0.0 and not _embarque.has(k):
			_embarque[k] = {"t": 0.0}
			_planear_embarque(k, transform_tren(l, t))
		elif _embarque.has(k):
			if not en_estacion:
				## Ya se fue: los que no llegaron a la puerta se quedan esperando.
				_embarque.erase(k)
				for c: Dictionary in _caminantes:
					if int(c["tren"]) == k and String(c["fin"]) == "subir":
						c["fin"] = "sitio"
						c["tren"] = -1
						c["ruta"] = [(c["s"] as Dictionary)["p"]]
				continue
			var emb: Dictionary = _embarque[k]
			emb["t"] = float(emb["t"]) + delta
			## Retener el tren mientras alguien está entrando o saliendo por la puerta.
			var ocupado := false
			for c: Dictionary in _caminantes:
				if int(c["tren"]) == k and (c["ruta"] as Array).size() > int(c["suelta"]):
					ocupado = true
					break
			if not ocupado:
				for it: Dictionary in _cola_gente:
					if String(it["tipo"]) == "bajar" and int(it["tren"]) == k:
						ocupado = true
						break
			if ocupado and float(emb["t"]) < PARADA + RETENCION_MAX:
				t.espera = maxf(t.espera, 1.0 + delta)

## Abre o cierra las puertas (paneles que se deslizan a lo largo del coche).
func _puertas(n: Node3D, abiertas: bool) -> void:
	for d: Array in n.get_meta("puertas", []):
		var nodo: Node3D = d[0]
		var base: Vector3 = d[1]
		var hacia: float = d[2]
		var obj := base + Vector3(0, 0, hacia * (0.75 if abiertas else 0.0))
		nodo.position = nodo.position.lerp(obj, 0.18)

func _process(delta: float) -> void:
	_gente_cerca(delta)
	_embarques(delta)
	for l: Dictionary in lineas:
		var a: Vector3 = l["a"]
		var dir: Vector3 = l["dir"]
		var y := ALTO_VIADUCTO + 0.6 if bool(l["elevada"]) else PROF_TUNEL
		for i in (l["trenes"] as Array).size():
			var t: Tren = l["trenes"][i]
			t.simular(delta)
			var n: Node3D = l["nodos"][i]
			n.position = a + dir * t.s + Vector3(0, y, 0)
			n.rotation.y = atan2(dir.x, dir.z) + (0.0 if t.sentido > 0.0 else PI)
			_puertas(n, t.espera > 0.8 and t.espera < PARADA - 0.4)
			if not (l["nodos_x"] as Array).is_empty():
				var g: Node3D = l["nodos_x"][i]
				g.position = a + dir * t.s + Vector3(0, 0.9, 0)
				g.rotation.y = n.rotation.y
	_t_panel -= delta
	if _t_panel <= 0.0:
		_t_panel = 1.0
		for pa: Dictionary in _paneles:
			var mejor := INF
			for t: Tren in (pa["linea"] as Dictionary)["trenes"]:
				mejor = minf(mejor, t.eta(float(pa["s"])))
			var lab: Label3D = pa["label"]
			var cuando := "llegando" if mejor < 20.0 else "%d min" % int(ceil(mejor / 60.0))
			if pa.has("pantalla"):
				lab.text = "%s · %s\nPróximo tren: %s" % [String((pa["linea"] as Dictionary)["nombre"]), String(pa["est"]), cuando]
			else:
				lab.text = "%s · próximo tren: %s" % [String((pa["linea"] as Dictionary)["nombre"]), cuando]
		for l: Dictionary in lineas:
			for k in (l["trenes"] as Array).size():
				## Parado en una estación dice dónde está (antes decía «Próxima:
				## Cine» estando ya en Cine).
				var aqui := estacion_del_tren(String(l["nombre"]), k)
				var txt := "%s\n%s" % [String(l["nombre"]), ("Estación: %s" % String(NOMBRES[l["nombre"]][aqui])) if aqui >= 0 else ("Próxima: %s" % proxima_de(String(l["nombre"]), k))]
				for led: Label3D in (l["nodos"][k] as Node3D).get_meta("leds", []):
					led.text = txt

## EL PERSONAJE NO ATRAVIESA A LA GENTE DEL ANDÉN (16-10-2026): lo usa el
## explorador en el andén. Devuelve `p` empujado fuera de cada persona
## (círculos), así el personaje se desliza a su alrededor en vez de cruzarla.
func apartar(p: Vector3, radio: float) -> Vector3:
	if _gente == null:
		return p
	var minimo := radio + RADIO_PERSONA
	for _vuelta in 2:
		for o: Node3D in _cuerpos_gente():
			if absf(o.position.y - p.y) > 1.5:
				continue
			var dx := p.x - o.position.x
			var dz := p.z - o.position.z
			var d2 := dx * dx + dz * dz
			if d2 < minimo * minimo:
				var d := sqrt(d2)
				if d < 0.0001:
					dx = 1.0
					dz = 0.0
					d = 1.0
				p.x = o.position.x + dx / d * minimo
				p.z = o.position.z + dz / d * minimo
	return p

## Para las pruebas: cuánta gente hay y qué hace.
func estado_gente() -> Dictionary:
	var suben := 0
	var bajan := 0
	var llegan := 0
	for c: Dictionary in _caminantes:
		match String(c["fin"]):
			"subir": suben += 1
			"salir": bajan += 1
			"sitio": llegan += 1
	var pas := 0
	if _pas_nodo != null and is_instance_valid(_pas_nodo):
		pas = _pas_nodo.get_child_count()
	return {"esperando": _fijos_gente.size(), "suben": suben, "bajan": bajan, "llegan": llegan,
		"retenidos": _embarque.size(), "pasajeros": pas}

## Posiciones de la gente del andén (para las pruebas).
func posiciones_gente() -> Array:
	var r: Array = []
	for n: Node3D in _cuerpos_gente():
		r.append(n.position)
	return r
