extends "res://visor/ciudad_expansion_p1.gd"
## [Capa 2/9 de `ciudad_expansion.gd`] armar_red, ancho_brazo, medio_cruce, es_puente, tiene_semaforo, fin_de_cebra … (+15)

func armar_red() -> void:
	nodos.clear()
	tramos.clear()
	vecinos.clear()
	for i in range(-K, K + 1):
		for j in range(-K, K + 1):
			nodos[Vector2i(i, j)] = Vector3(float(i) * CELDA, 0, float(j) * CELDA)
	for i in range(-K, K + 1):
		for j in range(-K, K + 1):
			var a: Vector3 = nodos[Vector2i(i, j)]
			if i < K:
				_tramo_rejilla(Vector2i(i, j), Vector2i(i + 1, j), j % 3 == 0)
			if j < K:
				## Ninguna calle a lo largo del cauce del río.
				if absf(a.x - CityBuilder.RIO_X) >= RIO_MEDIO + 10.0:
					_tramo_rejilla(Vector2i(i, j), Vector2i(i, j + 1), i % 3 == 0)
	## Conectores con los anillos del núcleo (el tráfico entra y sale).
	for par: Array in [
			[Vector3(CityBuilder.RING_X + 187.0, 0, 0), Vector3(NUC_X1, 0, 0)],
			[Vector3(-CityBuilder.RING_X - 187.0, 0, 0), Vector3(NUC_X0, 0, 0)],
			[Vector3(330, 0, CityBuilder.EX_N), Vector3(330, 0, NUC_Z0)],
			[Vector3(-330, 0, CityBuilder.EX_N), Vector3(-330, 0, NUC_Z0)],
			[Vector3(330, 0, CityBuilder.EX_S), Vector3(330, 0, NUC_Z1)],
			[Vector3(-330, 0, CityBuilder.EX_S), Vector3(-330, 0, NUC_Z1)],
		]:
		var p0: Vector3 = par[0]
		var p1: Vector3 = par[1]
		tramos.append({"a": p0, "b": p1, "av": true, "puente": _cruza_rio(p0, p1),
			"ancho": ANCHO_AV, "conector": true})
	## Semáforos: cada cruce con al menos una avenida y tres o más brazos.
	cruces_semaforo.clear()
	for k: Vector2i in vecinos:
		var lista: Array = vecinos[k]
		if lista.size() < 3:
			continue
		var p: Vector3 = nodos[k]
		if dentro_nucleo(p.x, p.z, -1.0):
			continue
		if k.x % 3 == 0 or k.y % 3 == 0 or _es_borde(p):
			cruces_semaforo.append(p)
	cuenta["tramos"] = tramos.size()
	cuenta["semaforos"] = cruces_semaforo.size()
	_armar_brazos()

## Ancho de la calle que sale del cruce `p` hacia `d` (0 si no sale ninguna).
func ancho_brazo(p: Vector3, d: Vector3) -> float:
	var k := clave_cruce(p)
	if not brazos.has(k):
		return 0.0
	return float(brazos[k][_indice_brazo(d)])

## Medio ancho de la calle que CRUZA en `p` a una que llega con dirección `d`
## (0 si en ese cruce no la cruza ninguna: sigue recta o termina).
func medio_cruce(p: Vector3, d: Vector3) -> float:
	var lat := Vector3(-d.z, 0, d.x)
	return maxf(ancho_brazo(p, lat), ancho_brazo(p, -lat)) * 0.5

## ¿El brazo de `p` hacia `d` es un puente? (allí mandan sus rampas)
func es_puente(p: Vector3, d: Vector3) -> bool:
	var k := clave_cruce(p)
	return _punta_puente.has(k) and (_punta_puente[k] as Dictionary).has(_indice_brazo(d))

func tiene_semaforo(p: Vector3) -> bool:
	return _con_semaforo.has(clave_cruce(p))
func fin_de_cebra(medio: float) -> float:
	return medio + CEBRA_HUECO + CEBRA_LARGO
func linea_detencion(medio: float) -> float:
	return fin_de_cebra(medio) + LINEA_DETENCION

## El camino más corto entre dos cruces de la rejilla (BFS sobre el grafo):
## la base para que un NPC, un coche o el jugador vayan de un sitio a otro.
func camino_entre(desde: Vector2i, hasta: Vector2i) -> Array:
	if not vecinos.has(desde) or not vecinos.has(hasta):
		return []
	var previo := {desde: desde}
	var cola: Array = [desde]
	while not cola.is_empty():
		var k: Vector2i = cola.pop_front()
		if k == hasta:
			break
		for v: Vector2i in vecinos[k]:
			if not previo.has(v):
				previo[v] = k
				cola.append(v)
	if not previo.has(hasta):
		return []
	var camino: Array = [hasta]
	var k2: Vector2i = hasta
	while k2 != desde:
		k2 = previo[k2]
		camino.push_front(k2)
	return camino

func _zona(c: Vector2) -> String:
	if c.x < CityBuilder.RIO_X - RIO_MEDIO:
		return "oeste"
	if c.y < NUC_Z0 and absf(c.x) < 700.0:
		return "centro"
	if c.x > NUC_X1:
		return "este"
	if c.y > NUC_Z1:
		return "sur"
	return "norte"

func _uso_de_zona(zona: String, c: Vector2) -> String:
	var lejos := maxf(absf(c.x), absf(c.y)) > LEJOS
	match zona:
		"centro":
			if absf(c.x) < 340.0 and c.y > -1000.0:
				return "torres"
			return "lejano" if lejos else "comercial"
		"este":
			if lejos:
				return "lejano"
			return "comercial" if c.x < 800.0 else "pisos"
		"sur":
			return "casas"
		"oeste":
			return "industrial" if c.y > -700.0 and c.y < 700.0 else ("lejano" if lejos else "pisos")
		_:
			return "lejano" if lejos else "pisos"

## Uso y zona de cada manzana.
func armar_bloques() -> void:
	bloques.clear()
	for i in range(-K, K):
		for j in range(-K, K):
			var x0 := float(i) * CELDA
			var z0 := float(j) * CELDA
			var c := Vector2(x0 + CELDA * 0.5, z0 + CELDA * 0.5)
			if dentro_nucleo(c.x, c.y):
				continue
			var medio_av := ANCHO_AV * 0.5 + ACERA
			var medio_c := ANCHO_CALLE * 0.5 + ACERA
			var izq := medio_av if i % 3 == 0 or absf(x0 - NUC_X1) < 0.1 else medio_c
			var der := medio_av if (i + 1) % 3 == 0 or absf(x0 + CELDA - NUC_X0) < 0.1 else medio_c
			var arr := medio_av if j % 3 == 0 or absf(z0 - NUC_Z1) < 0.1 else medio_c
			var aba := medio_av if (j + 1) % 3 == 0 or absf(z0 + CELDA - NUC_Z0) < 0.1 else medio_c
			var r := Rect2(x0 + izq, z0 + arr, CELDA - izq - der, CELDA - arr - aba)
			var celda := Vector2i(i, j)
			var uso := ""
			var zona := _zona(c)
			if r.position.x < CityBuilder.RIO_X + RIO_MEDIO and r.end.x > CityBuilder.RIO_X - RIO_MEDIO:
				uso = "puerto" if ESPECIALES.get(celda, "") == "puerto" else "rio"
			elif ESPECIALES.has(celda):
				uso = String(ESPECIALES[celda])
			else:
				uso = _uso_de_zona(zona, c)
			bloques.append({"rect": r, "celda": celda, "zona": zona, "uso": uso})
	cuenta["manzanas"] = bloques.size()

func _linea_bus(nombre: String, esquinas: Array) -> Dictionary:
	var pts := PackedVector3Array()
	var carril := ANCHO_AV * 0.25
	for e: Vector2 in esquinas:
		pts.append(Vector3(e.x, 0.3, e.y))
	## Desplazado al carril derecho (sentido horario visto desde arriba).
	var n := pts.size()
	var sal := PackedVector3Array()
	for k in n:
		var prev := pts[(k - 1 + n) % n]
		var act := pts[k]
		var sig := pts[(k + 1) % n]
		var d1 := (act - prev).normalized()
		var d2 := (sig - act).normalized()
		var off := (Vector3(-d1.z, 0, d1.x) + Vector3(-d2.z, 0, d2.x)).normalized() * carril
		sal.append(act + off)
	var paradas: Array = []
	for k in n:
		var a := sal[k]
		var c := sal[(k + 1) % n]
		var largo := a.distance_to(c)
		var cuantas := int(largo / 330.0)
		for q in range(1, cuantas + 1):
			paradas.append(a.lerp(c, float(q) / float(cuantas + 1)))
	return {"nombre": nombre, "puntos": sal, "paradas": paradas}

## Dos líneas de metro (en datos: estaciones en cruces) y dos de autobús.
func armar_transporte() -> void:
	## Mismas líneas que dibuja y mueve `MetroCiudad`: la 1 elevada por la
	## avenida x = 660 y la 2 subterránea bajo z = -660 (transbordo en el cruce).
	var l1: Array = []
	var l2: Array = []
	for k in [-9, -6, -3, 0, 3, 6, 9]:
		l1.append(Vector3(6.0 * CELDA, 0, float(k) * CELDA))
		l2.append(Vector3(float(k) * CELDA, 0, -6.0 * CELDA))
	lineas_metro = [
		{"nombre": "Línea 1", "color": Color(0.85, 0.15, 0.15), "estaciones": l1, "elevada": true},
		{"nombre": "Línea 2", "color": Color(0.15, 0.4, 0.9), "estaciones": l2, "elevada": false},
	]
	## Autobuses: recorridos cerrados por avenidas, por el carril derecho.
	lineas_bus = [
		_linea_bus("Bus 10", [Vector2(NUC_X0, NUC_Z0), Vector2(NUC_X1, NUC_Z0), Vector2(NUC_X1, NUC_Z1), Vector2(NUC_X0, NUC_Z1)]),
		_linea_bus("Bus 22", [Vector2(-660, -990), Vector2(990, -990), Vector2(990, 990), Vector2(-660, 990)]),
	]

func _cargar_modelos() -> void:
	for ruta in CityBuilder.RUTAS_COMERCIAL:
		var e: PackedScene = load(ruta)
		if e != null:
			_comercial.append(e)
	for ruta in CityBuilder.RUTAS_NAVES:
		var e2: PackedScene = load(ruta)
		if e2 != null:
			_naves.append(e2)
	for ruta in CityBuilder.RUTAS_HORIZONTE:
		var e3: PackedScene = load(ruta)
		if e3 != null:
			_altos.append(e3)

func _materiales() -> void:
	var asf: StandardMaterial3D = Texturas.asfalto(Color(0.3, 0.295, 0.29)).duplicate()
	asf.roughness = 0.85
	_mat["asfalto"] = asf
	## Etapa 4: acera de baldosa con juntas y solar de hormigón, no colores lisos.
	_mat["acera"] = Texturas.baldosa(Color(0.62, 0.61, 0.58), 53)
	_mat["solar"] = Texturas.hormigon(Color(0.42, 0.42, 0.41), 29)
	_mat["linea"] = b._mat_simple(Color(0.92, 0.9, 0.82), 0.7)
	_mat["cesped"] = Texturas.cesped(Color(0.27, 0.48, 0.24), 37)
	_mat["hoja"] = b._mat_simple(Color(0.18, 0.4, 0.2), 0.9)
	_mat["tronco"] = b._mat_simple(Color(0.35, 0.26, 0.18), 0.9)
	_mat["claro"] = b._mat_simple(Color(0.9, 0.89, 0.86), 0.7)
	_mat["vidrio"] = b._vidrio_oscuro()
	_mat["piedra"] = b._mat_simple(Color(0.84, 0.8, 0.7), 0.8)
	var agua := StandardMaterial3D.new()
	agua.albedo_color = Color(0.12, 0.4, 0.55)
	agua.roughness = 0.08
	agua.metallic = 0.3
	_mat["agua"] = agua

func _lote(mat: String, pos: Vector3, tam: Vector3) -> void:
	if not _lotes.has(mat):
		_lotes[mat] = [] as Array[Transform3D]
	(_lotes[mat] as Array).append(Transform3D(Basis.from_scale(tam), pos))

func _mat_det(clave: String, c: Color, rug: float) -> StandardMaterial3D:
	if not _mats_det.has(clave):
		_mats_det[clave] = b._mat_simple(c, rug)
	return _mats_det[clave]

## LOS APOYOS DEL PUENTE (16-10-2026, «los tableros flotan o tienen apoyos
## pobres»). Antes: tres machones de hormigón de solo el 70 % del ancho, así que
## los arcos de piedra de las dos caras nacían en el aire, y bajo las rampas no
## había nada (una losa inclinada sobre el paseo). Ahora:
##  · PILAS de sillería a TODO el ancho del tablero (las roscas de los arcos
##    apoyan en ellas), con zarpa ancha bajo el agua, imposta en el arranque de
##    los arcos y un capitel corrido bajo el tablero;
##  · ESTRIBOS en las dos orillas, donde el tablero acaba sobre tierra;
##  · TERRAPLÉN bajo cada rampa: muro de piedra en cuña que llena el hueco
##    (la rampa ya no es una losa colgada).
func _apoyos_puente(rx: float, z: float, ancho: float, agua0: float, agua1: float, rampa: float) -> void:
	var sillar := _mat_det("puente_sillar", Color(0.74, 0.67, 0.56), 0.9)
	var sillar_osc := _mat_det("puente_sillar_osc", Color(0.55, 0.49, 0.41), 0.95)
	var fondo := ancho + 1.4      ## de cara a cara del puente (los arcos están a ±(ancho/2 + 0,2))
	var bajo := PUENTE_ALTO - 1.3   ## cara de abajo del tablero
	for px: float in [agua0 + 6.0, rx, agua1 - 6.0]:
		## Zarpa (bajo el agua), fuste a todo el ancho, imposta y capitel.
		b._caja_en(Vector3(px, -0.35, z), Vector3(3.6, 1.3, fondo + 1.2), sillar_osc)
		b._caja_en(Vector3(px, (bajo + 0.3) * 0.5 - 0.3, z), Vector3(2.4, bajo + 0.6, fondo), sillar)
		b._caja_en(Vector3(px, 0.55, z), Vector3(2.8, 0.3, fondo + 0.3), sillar_osc)
		b._caja_en(Vector3(px, bajo - 0.15, z), Vector3(2.9, 0.3, fondo + 0.4), sillar_osc)
	## Estribos: un macizo en cada orilla bajo el final del tablero.
	for lado: float in [-1.0, 1.0]:
		var xe := agua0 + 1.5 if lado < 0.0 else agua1 - 1.5
		b._caja_en(Vector3(xe, bajo * 0.5, z), Vector3(4.2, bajo + 0.2, fondo + 0.6), sillar)
		b._caja_en(Vector3(xe, 0.35, z), Vector3(4.8, 0.7, fondo + 1.0), sillar_osc)
	## Terraplén bajo cada rampa: una cuña de piedra (prisma rectángulo) que sube
	## con ella hasta el estribo.
	for lado: float in [-1.0, 1.0]:
		var cuna := PrismMesh.new()
		cuna.left_to_right = 1.0 if lado < 0.0 else 0.0
		cuna.size = Vector3(rampa, PUENTE_ALTO - 0.35, fondo - 0.2)
		var mi := MeshInstance3D.new()
		mi.mesh = cuna
		mi.material_override = sillar
		var xa := agua0 - rampa if lado < 0.0 else agua1
		mi.position = Vector3(xa + rampa * 0.5, (PUENTE_ALTO - 0.35) * 0.5, z)
		b.add_child(mi)
		## Zócalo del terraplén.
		b._caja_en(Vector3(xa + rampa * 0.5, 0.3, z), Vector3(rampa, 0.6, fondo + 0.2), sillar_osc)
	cuenta["pilas_puente"] = int(cuenta.get("pilas_puente", 0)) + 3

func _multimesh(malla: Mesh, mat: Material, ts: Array[Transform3D], _esc: Vector3, colores: Array[Color] = []) -> void:
	if ts.is_empty():
		return
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = not colores.is_empty()
	mm.mesh = malla
	mm.instance_count = ts.size()
	for i in ts.size():
		var t := ts[i]
		if _esc != Vector3.ONE:
			t.basis = t.basis * Basis.from_scale(_esc)
		mm.set_instance_transform(i, t)
		if mm.use_colors:
			mm.set_instance_color(i, colores[i])
	var mi := MultiMeshInstance3D.new()
	mi.multimesh = mm
	if mat != null:
		mi.material_override = mat
	elif mm.use_colors:
		var m2 := StandardMaterial3D.new()
		m2.vertex_color_use_as_albedo = true
		m2.roughness = 0.8
		mi.material_override = m2
	b.add_child(mi)

## Altura del suelo del puente en x (rampas y tablero), para la balaustrada.
func _altura_puente(x: float, rx: float, agua0: float, agua1: float, rampa: float) -> float:
	if x >= agua0 and x <= agua1:
		return PUENTE_ALTO
	if x < agua0:
		return clampf((x - (agua0 - rampa)) / rampa, 0.0, 1.0) * PUENTE_ALTO
	return clampf(((agua1 + rampa) - x) / rampa, 0.0, 1.0) * PUENTE_ALTO

## El material de las luces de farola: uno solo para toda la ciudad (los
## puentes también lo usan), que la noche enciende.
func _mat_luz_farola() -> StandardMaterial3D:
	if _farola_luz == null:
		_farola_luz = StandardMaterial3D.new()
		_farola_luz.albedo_color = Color(1.0, 0.85, 0.6)
		_farola_luz.emission_enabled = true
		_farola_luz.emission = Color(1.0, 0.78, 0.45)
		_farola_luz.emission_energy_multiplier = 0.0
	return _farola_luz
