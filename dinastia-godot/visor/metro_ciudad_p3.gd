extends "res://visor/metro_ciudad_p2.gd"
## [Capa 3/4 de `metro_ciudad.gd`] _tren_real, _tren_fantasma, _centro_anden, _totem, montar, tren_parado_en … (+11)

## El tren de verdad: tres coches HUECOS con su interior (asientos, barras,
## asideros, luces, ventanas, puertas que se abren) y un panel LED con la
## próxima estación. Se ve desde fuera por las ventanas y se puede viajar dentro.
func _tren_real(col: Color) -> Node3D:
	var n := Node3D.new()
	var blanco := _mat(Color(0.93, 0.94, 0.96), 0.35)
	var franja := _mat(col, 0.4, 0.2)
	var vidrio := StandardMaterial3D.new()
	vidrio.albedo_color = Color(0.6, 0.75, 0.85, 0.22)
	vidrio.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	vidrio.roughness = 0.05
	## Después de los rótulos (Label3D, también transparentes): si no, el
	## motor dibujaba el cartel del andén ENCIMA del cristal y desde dentro
	## parecía pegado a la ventana, sin el tinte del vidrio.
	vidrio.render_priority = 1
	var metal := _mat(Color(0.75, 0.76, 0.78), 0.25)
	metal.metallic = 0.8
	var luz := _mat(Color(1, 0.96, 0.86), 0.3, 0.6)
	var puerta_m := _mat(Color(0.82, 0.84, 0.86), 0.3)
	var oscuro := _mat(Color(0.06, 0.06, 0.07), 0.5)
	var cabina := _mat(Color(0.08, 0.12, 0.16), 0.08)
	cabina.metallic = 0.4
	var leds: Array = []
	var puertas: Array = []
	var f := PISO_COCHE
	## EL INTERIOR (16-10-2026, «se ve casi blanco»): suelo, forros de pared y
	## techo, asientos uno a uno, marcos, asideros, anuncios y planos de línea
	## en UNA malla con colores de vértice (compartida por los trenes de la línea).
	var interior := MeshInstance3D.new()
	interior.name = "Interior"
	interior.mesh = _interior_malla(col)
	interior.material_override = _mat_interior()
	interior.visibility_range_end = 120.0
	n.add_child(interior)
	for k in 3:
		var z := (float(k) - 1.0) * 16.6
		_caja(n, Vector3(0, f - 0.3, z), Vector3(3.0, 0.6, 16.0), blanco)          ## bastidor
		_caja(n, Vector3(0, f + 2.65, z), Vector3(3.0, 0.15, 16.0), blanco)        ## techo
		for lado: float in [-1.0, 1.0]:
			var x := lado * 1.45
			_caja(n, Vector3(x, f + 2.4, z), Vector3(0.1, 0.4, 16.0), blanco)        ## sobre ventanas
			## Entre puertas: panel bajo, franja y ventana. Antes iban de punta a
			## punta y tapaban la parte baja de las puertas abiertas.
			for tr: Array in TRAMOS_PARED:
				var zc := z + (float(tr[0]) + float(tr[1])) * 0.5
				var lz := float(tr[1]) - float(tr[0])
				_caja(n, Vector3(x, f + 0.45, zc), Vector3(0.1, 0.9, lz), blanco)       ## panel bajo
				_caja(n, Vector3(x * 1.04, f + 0.35, zc), Vector3(0.02, 0.25, lz), franja)
				_caja(n, Vector3(x, f + 1.55, zc), Vector3(0.04, 1.3, lz), vidrio)      ## ventanas
			## Anuncios sobre las ventanas (el fondo de color va en la malla).
			for q in TRAMOS_ASIENTO.size():
				var ad := Label3D.new()
				var texto: String = ANUNCIOS[(k * 6 + q * 2 + (0 if lado > 0.0 else 1)) % ANUNCIOS.size()]
				ad.text = texto
				ad.font_size = 30
				ad.pixel_size = 0.0033
				ad.outline_size = 5
				ad.outline_modulate = Color(0, 0, 0, 0.6)
				ad.width = 440.0
				ad.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
				ad.double_sided = false
				ad.position = Vector3(lado * 1.355, f + 2.38, z + float(TRAMOS_ASIENTO[q][0]))
				ad.rotation.y = atan2(-lado, 0.0)
				ad.visibility_range_end = 18.0
				n.add_child(ad)
			## Puertas: dos por lado; se deslizan al abrir.
			for dz: float in [-3.5, 3.5]:
				for hoja: float in [-1.0, 1.0]:
					var base := Vector3(x * 1.03, f + 1.15, z + dz + hoja * 0.37)
					var p := _caja(n, base, Vector3(0.06, 2.2, 0.72), puerta_m)
					puertas.append([p, base, hoja])
		## Barras y asideros.
		for q in 5:
			var b := MeshInstance3D.new()
			var cm := CylinderMesh.new()
			cm.top_radius = 0.03
			cm.bottom_radius = 0.03
			cm.height = 2.6
			b.mesh = cm
			b.material_override = metal
			b.position = Vector3(0, f + 1.3, z - 6.0 + float(q) * 3.0)
			n.add_child(b)
		for lado3: float in [-0.55, 0.55]:
			_caja(n, Vector3(lado3, f + 2.25, z), Vector3(0.04, 0.04, 15.0), metal)
		_caja(n, Vector3(0, f + 2.535, z), Vector3(0.26, 0.03, 15.0), luz)
		## Testeros con ventana (los extremos del coche).
		for e: float in [-1.0, 1.0]:
			_caja(n, Vector3(0, f + 1.3, z + e * 8.0), Vector3(3.0, 2.6, 0.1), blanco)
		## Panel LED en el testero de cada coche, mirando dentro. FALLO (15-10-2026):
		## era un solo Label3D de una línea («Línea 1 ▸ Próxima: Mercado Este»)
		## de ~4,5 m de ancho en un coche de 3 m: atravesaba las paredes y desde
		## el andén se veía el final del cartel saliendo por los lados del tren.
		## Ahora: dos líneas con ancho fijo dentro de una caja negra, de una sola
		## cara, y sin pasar de 2,2 m.
		var cz := z + 7.9
		_caja(n, Vector3(0, f + 2.2, cz - 0.02), Vector3(2.3, 0.42, 0.06), oscuro)
		var led := Label3D.new()
		led.font_size = 28
		led.pixel_size = 0.0055
		led.modulate = Color(1.0, 0.6, 0.1)
		led.outline_size = 0
		led.double_sided = false
		led.position = Vector3(0, f + 2.2, cz - 0.06)
		led.rotation.y = PI
		led.visibility_range_end = 40.0
		n.add_child(led)
		leds.append(led)
		## Fuelle entre coches: tapaba el hueco por donde se veía la vía.
		if k < 2:
			_caja(n, Vector3(0, f + 1.25, z + 8.3), Vector3(2.2, 2.5, 0.62), oscuro)
	## LAS CABEZAS (15-10-2026): por fuera el tren era una caja blanca lisa.
	## Ahora cada punta lleva parabrisas oscuro, faros, franja de la línea y el
	## letrero de destino.
	var faro := _mat(Color(1.0, 0.97, 0.85), 0.2, 2.5)
	var piloto := _mat(Color(0.9, 0.1, 0.08), 0.3, 1.5)
	for e: float in [-1.0, 1.0]:
		var zc := e * (16.6 + 8.0)
		_caja(n, Vector3(0, f + 1.15, zc + e * 0.1), Vector3(2.9, 2.0, 0.12), blanco)
		_caja(n, Vector3(0, f + 1.75, zc + e * 0.17), Vector3(2.3, 0.95, 0.04), cabina)
		_caja(n, Vector3(0, f + 0.55, zc + e * 0.17), Vector3(2.95, 0.22, 0.04), franja)
		_caja(n, Vector3(0, f + 2.42, zc + e * 0.17), Vector3(1.6, 0.26, 0.04), oscuro)
		for xs: float in [-1.0, 1.0]:
			_caja(n, Vector3(xs * 1.1, f + 0.85, zc + e * 0.18), Vector3(0.32, 0.14, 0.04), faro)
			_caja(n, Vector3(xs * 0.7, f + 0.85, zc + e * 0.18), Vector3(0.16, 0.1, 0.04), piloto)
		var dest := Label3D.new()
		dest.font_size = 24
		dest.pixel_size = 0.0045
		dest.modulate = Color(1.0, 0.6, 0.1)
		dest.outline_size = 0
		dest.double_sided = false
		dest.position = Vector3(0, f + 2.42, zc + e * 0.2)
		dest.rotation.y = 0.0 if e > 0.0 else PI
		dest.visibility_range_end = 90.0
		n.add_child(dest)
		leds.append(dest)
	n.set_meta("led", leds[0])
	n.set_meta("leds", leds)
	n.set_meta("puertas", puertas)
	return n

## El tren «fantasma» de la línea subterránea: solo se ve en rayos X.
func _tren_fantasma(col: Color) -> Node3D:
	var n := Node3D.new()
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(col.r, col.g, col.b, 0.85)
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.no_depth_test = true
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	for k in 3:
		_caja(n, Vector3(0, 1.8, (float(k) - 1.0) * 17.0), Vector3(3.0, 3.4, 16.0), m)
	_xray.add_child(n)
	return n

## El centro del andén (lado +lateral) de la estación `i` de una línea, a la
## altura del suelo del andén.
func _centro_anden(l: Dictionary, i: int) -> Vector3:
	var p: Vector3 = l["estaciones"][i]
	var dir: Vector3 = l["dir"]
	var lat := Vector3(dir.z, 0, -dir.x).abs() if true else Vector3.ZERO
	var y := ALTO_VIADUCTO + 0.6 + PISO_COCHE if bool(l["elevada"]) else PROF_TUNEL + PISO_COCHE
	return p + lat * ANDEN_LAT + Vector3(0, y, 0)

## El tótem de la boca: poste alto con la «Ⓜ» y el nombre de la estación.
func _totem(pie: Vector3, nombre: String, col: Color) -> void:
	_caja(self, pie + Vector3(1.8, 2.2, 1.8), Vector3(0.18, 4.4, 0.18), _mat(Color(0.25, 0.25, 0.28), 0.4))
	_caja(self, pie + Vector3(1.8, 4.7, 1.8), Vector3(0.9, 0.9, 0.9), _mat(col, 0.4, 0.6))
	var l := Label3D.new()
	l.text = "Ⓜ\n%s" % nombre
	l.font_size = 40
	l.pixel_size = 0.005
	l.outline_size = 8
	l.outline_modulate = col.darkened(0.5)
	l.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	l.position = pie + Vector3(1.8, 5.9, 1.8)
	l.visibility_range_end = 220.0
	add_child(l)

func montar(exp: CiudadExpansion) -> void:
	var cel := CiudadExpansion.CELDA
	lineas = [
		{"nombre": "Línea 1", "color": Color(0.85, 0.15, 0.15), "elevada": true,
			"a": Vector3(6 * cel, 0, -11 * cel), "b": Vector3(6 * cel, 0, 11 * cel),
			"estaciones": [-9, -6, -3, 0, 3, 6, 9]},
		{"nombre": "Línea 2", "color": Color(0.15, 0.4, 0.9), "elevada": false,
			"a": Vector3(-11 * cel, 0, -6 * cel), "b": Vector3(11 * cel, 0, -6 * cel),
			"estaciones": [-9, -6, -3, 0, 3, 6, 9]},
	]
	_xray = Node3D.new()
	_xray.name = "MetroRayosX"
	_xray.visible = false
	add_child(_xray)
	for l: Dictionary in lineas:
		var a: Vector3 = l["a"]
		var b: Vector3 = l["b"]
		var largo := a.distance_to(b)
		var dir := (b - a).normalized()
		var est_s := PackedFloat32Array()
		var est_pos: Array = []
		for k: int in l["estaciones"]:
			var p := Vector3(float(k) * cel, 0, a.z) if absf(dir.x) > 0.5 else Vector3(a.x, 0, float(k) * cel)
			est_pos.append(p)
			est_s.append(a.distance_to(p))
		l["estaciones"] = est_pos
		l["est_s"] = est_s
		l["largo"] = largo
		l["dir"] = dir
		var col: Color = l["color"]
		var nombres: Array = NOMBRES[l["nombre"]]
		if bool(l["elevada"]):
			_viaducto(a, b, col)
		else:
			_tunel_xray(a, b, col)
			_tunel(a, b, est_pos, dir)
		for i in est_pos.size():
			var p: Vector3 = est_pos[i]
			if bool(l["elevada"]):
				_estacion_elevada(p, dir, col, String(nombres[i]), String(l["nombre"]), i)
			else:
				_estacion_subterranea(p, dir, col, String(nombres[i]), String(l["nombre"]), i)
			_decorar_estacion(p, dir, col, String(nombres[i]), bool(l["elevada"]))
			## Las pantallas colgadas del andén, a su línea y su estación.
			for pa: Dictionary in _paneles:
				if pa.has("pantalla") and not pa.has("linea"):
					pa["linea"] = l
					pa["s"] = est_s[i]
			_panel(p, l, est_s[i])
		var trenes: Array = []
		var nodos: Array = []
		var nodos_x: Array = []
		for k in 3:
			var t := Tren.new(largo, est_s, largo * (float(k) + 0.5) / 3.0, 1.0 if k % 2 == 0 else -1.0)
			trenes.append(t)
			var real := _tren_real(col)
			add_child(real)
			nodos.append(real)
			if not bool(l["elevada"]):
				nodos_x.append(_tren_fantasma(col))
		l["trenes"] = trenes
		l["nodos"] = nodos
		l["nodos_x"] = nodos_x
	exp.lineas_metro = []
	for l: Dictionary in lineas:
		exp.lineas_metro.append({"nombre": l["nombre"], "color": l["color"], "estaciones": l["estaciones"], "elevada": l["elevada"]})
	## Accesos de la línea subterránea: las bocas de la acera (las dibuja
	## `CiudadExpansion._bocas_metro` en esta misma posición).
	var l2: Dictionary = lineas[1]
	for i in (l2["estaciones"] as Array).size():
		var p2: Vector3 = l2["estaciones"][i]
		var boca := p2 + Vector3(CiudadExpansion.ANCHO_AV * 0.5 + CiudadExpansion.ACERA + 3.0, 0, CiudadExpansion.ANCHO_AV * 0.5 + CiudadExpansion.ACERA + 3.0)
		accesos.append({"pie": boca, "anden": _centro_anden(l2, i), "linea": "Línea 2", "idx": i, "elevada": false,
			"nombre": String(NOMBRES["Línea 2"][i])})
	## Un tótem «Ⓜ» con el nombre en cada acceso de la calle.
	for acc: Dictionary in accesos:
		_totem(acc["pie"], String(acc["nombre"]), Color(0.85, 0.15, 0.15) if bool(acc["elevada"]) else Color(0.15, 0.4, 0.9))

## Un tren detenido con las puertas abiertas en la estación `i` (o -1).
func tren_parado_en(nombre: String, i: int) -> int:
	var l := linea(nombre)
	if l.is_empty():
		return -1
	var s := float(l["est_s"][i])
	for k in (l["trenes"] as Array).size():
		var t: Tren = l["trenes"][k]
		if t.espera > 0.8 and absf(t.s - s) < 1.0:
			return k
	return -1

## La estación (índice) donde está parado el tren `k`, o -1 si va en marcha.
func estacion_del_tren(nombre: String, k: int) -> int:
	var l := linea(nombre)
	var t: Tren = l["trenes"][k]
	if t.espera <= 0.0:
		return -1
	for i in (l["est_s"] as PackedFloat32Array).size():
		if absf(t.s - float(l["est_s"][i])) < 1.0:
			return i
	return -1

## El nombre de la próxima estación del tren `k`.
func proxima_de(nombre: String, k: int) -> String:
	var l := linea(nombre)
	var t: Tren = l["trenes"][k]
	var obj := t.proxima()
	var est: PackedFloat32Array = l["est_s"]
	var mejor := 0
	for i in est.size():
		if absf(est[i] - obj) < absf(est[mejor] - obj):
			mejor = i
	if obj == INF:
		return String(NOMBRES[nombre][0 if t.sentido > 0.0 else est.size() - 1])
	return String(NOMBRES[nombre][mejor])

func eta_minima(nombre: String, i: int) -> float:
	var l := linea(nombre)
	var mejor := INF
	for t: Tren in l["trenes"]:
		mejor = minf(mejor, t.eta(float(l["est_s"][i])))
	return mejor

func alternar_rayos_x() -> bool:
	_xray.visible = not _xray.visible
	return _xray.visible

## Altura de la pelvis de pie (pose de reposo) respecto al origen de la
## persona (misma medida que `InteriorInstalacion._altura_cadera`).
static func altura_cadera(nodo: Node3D) -> float:
	var esqueletos := nodo.find_children("*", "Skeleton3D", true, false)
	if esqueletos.is_empty():
		return 0.0
	var sk: Skeleton3D = esqueletos[0]
	var b := sk.find_bone("pelvis")
	if b < 0:
		b = sk.find_bone("Hips")
	if b < 0:
		return 0.0
	var t := sk.get_bone_global_rest(b)
	var n: Node = sk
	while n != null and n != nodo:
		if n is Node3D:
			t = (n as Node3D).transform * t
		n = n.get_parent()
	return t.origin.y

## Deja a una persona en su sitio: sentada en el banco o de pie esperando.
func _asentar(d: Dictionary, s: Dictionary, e: Dictionary) -> void:
	var p: Vector3 = s["p"]
	var n: Node3D = d["nodo"]
	n.position = p
	n.rotation.y = float(s["giro"])
	var sentado := bool(s["sentado"])
	if sentado:
		var cadera := altura_cadera(n)
		if cadera > 0.0:
			n.position.y = p.y + BANCO_ASIENTO + 0.08 - cadera * 0.99
	var charla := bool(s.get("charla", false))
	Mini3D.anim(d, "sentado" if sentado else ("charla" if charla else "parado"), "")
	(d["anim"] as AnimationPlayer).seek(_rng_gente.randf() * 0.8, true)
	_fijos_gente.append({"d": d, "charla": charla, "t": _rng_gente.randf_range(2.0, 8.0), "s": s, "e": e})

func _crear_persona(item: Dictionary) -> void:
	match String(item["tipo"]):
		"sitio":
			var s: Dictionary = item["s"]
			var d := Mini3D.persona(_gente, _rng_gente, s["p"])
			if d.is_empty():
				return
			_asentar(d, s, item["e"])
		"bajar":
			var ruta: Array = item["ruta"]
			var d2 := Mini3D.persona(_gente, _rng_gente, ruta[0])
			if d2.is_empty():
				return
			(d2["nodo"] as Node3D).rotation.y = atan2((ruta[1] - ruta[0]).x, (ruta[1] - ruta[0]).z)
			_caminantes.append({"d": d2, "ruta": ruta.slice(1), "fin": "salir", "tren": item["tren"],
				"suelta": 1, "espera": float(item["espera"]), "andando": false})
		"llegar":
			var e: Dictionary = item["e"]
			var d3 := Mini3D.persona(_gente, _rng_gente, e["salida"])
			if d3.is_empty():
				return
			_caminantes.append({"d": d3, "ruta": [(item["s"] as Dictionary)["p"]], "fin": "sitio", "s": item["s"], "e": e,
				"tren": -1, "suelta": 99, "espera": 0.0, "andando": false})

func _crear_pasajero(item: Dictionary) -> void:
	var d := Mini3D.persona(_pas_nodo, _rng_gente, item["pos"])
	if d.is_empty():
		return
	var n: Node3D = d["nodo"]
	n.rotation.y = float(item["giro"])
	if bool(item["sentado"]):
		var cadera := altura_cadera(n)
		if cadera > 0.0:
			n.position.y = PISO_COCHE + ALTO_ASIENTO + 0.08 - cadera * 0.99
		Mini3D.anim(d, "sentado", "")
	else:
		Mini3D.anim(d, "parado", "")
	(d["anim"] as AnimationPlayer).seek(_rng_gente.randf() * 0.8, true)

func _fin_caminante(c: Dictionary) -> void:
	var d: Dictionary = c["d"]
	match String(c["fin"]):
		"subir":
			(d["nodo"] as Node3D).queue_free()
			_huecos.append({"s": c["s"], "e": c["e"], "t": _rng_gente.randf_range(8.0, 22.0)})
		"salir":
			(d["nodo"] as Node3D).queue_free()
		"sitio":
			_asentar(d, c["s"], c["e"])

## Los cuerpos de la gente del andén (esperando y caminando).
func _cuerpos_gente() -> Array:
	var r: Array = []
	for f: Dictionary in _fijos_gente:
		var n: Node3D = f["d"]["nodo"]
		if is_instance_valid(n):
			r.append(n)
	for c: Dictionary in _caminantes:
		var n2: Node3D = c["d"]["nodo"]
		if is_instance_valid(n2):
			r.append(n2)
	return r

## Separa `p` de la gente del andén (salvo `yo`): círculos de `RADIO_PERSONA`.
## Si el otro está delante (según `dir`), además se da un paso al costado para
## rodearlo (de frente, el empuje solo lo dejaba parado).
func _apartar_de_otros(p: Vector3, yo: Node3D, dir: Vector3, paso: float) -> Vector3:
	var minimo := RADIO_PERSONA * 2.0
	for o: Node3D in _cuerpos_gente():
		if o == yo:
			continue
		var dx := p.x - o.position.x
		var dz := p.z - o.position.z
		var d2 := dx * dx + dz * dz
		if d2 < minimo * minimo and d2 > 0.0001:
			var d := sqrt(d2)
			p.x = o.position.x + dx / d * minimo
			p.z = o.position.z + dz / d * minimo
			if -(dx * dir.x + dz * dir.z) > 0.0:
				var lado := Vector3(-dir.z, 0, dir.x)
				if lado.x * dx + lado.z * dz < 0.0:
					lado = -lado
				p += lado * paso * 0.8
	return p
