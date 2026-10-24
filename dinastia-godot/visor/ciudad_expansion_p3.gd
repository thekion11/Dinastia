extends "res://visor/ciudad_expansion_p2.gd"
## [Capa 3/9 de `ciudad_expansion.gd`] _adornar_puente, _puente, _fin_acera, _libre_de_marcas, _dibujar_calles, _arboles_en … (+6)

func _adornar_puente(rx: float, z: float, ancho: float, agua0: float, agua1: float, rampa: float) -> void:
	var piedra := b._mat_simple(Color(0.78, 0.7, 0.58), 0.85)
	var piedra_osc := b._mat_simple(Color(0.6, 0.53, 0.44), 0.9)
	var forja := b._mat_simple(Color(0.1, 0.11, 0.12), 0.4)
	forja.metallic = 0.5
	var nombre := String(NOMBRES_PUENTE[absi(int(z / CELDA)) % NOMBRES_PUENTE.size()])
	var dovelas: Array[Transform3D] = []
	var timpanos: Array[Transform3D] = []
	var balaustres: Array[Transform3D] = []
	## Los arcos: dos vanos (entre los tres pilares), con su rosca de dovelas.
	var pilares := [agua0 + 6.0, rx, agua1 - 6.0]
	for v in 2:
		var xa: float = pilares[v] + 1.1
		var xb: float = pilares[v + 1] - 1.1
		var cx := (xa + xb) * 0.5
		var semi := (xb - xa) * 0.5
		var alto := PUENTE_ALTO - 1.4
		var n := 18
		for k in n:
			var t0 := PI * float(k) / float(n)
			var t1 := PI * float(k + 1) / float(n)
			var p0 := Vector3(cx - cos(t0) * semi, 0.3 + sin(t0) * alto, z)
			var p1 := Vector3(cx - cos(t1) * semi, 0.3 + sin(t1) * alto, z)
			var m := (p0 + p1) * 0.5
			var d := p1 - p0
			var ang := atan2(d.y, d.x)
			for lado: float in [-1.0, 1.0]:
				dovelas.append(Transform3D(Basis(Vector3(0, 0, 1), ang) * Basis.from_scale(Vector3(d.length() + 0.15, 0.9, 0.7)),
					m + Vector3(0, 0, lado * (ancho * 0.5 + 0.2))))
				## El tímpano: piedra maciza entre la rosca y el tablero.
				var y_arco := maxf(p0.y, p1.y) + 0.4
				var alto_t := PUENTE_ALTO - 0.3 - y_arco
				if alto_t > 0.05:
					timpanos.append(Transform3D(Basis.from_scale(Vector3(absf(d.x) + 0.05, alto_t, 0.55)),
						Vector3(m.x, y_arco + alto_t * 0.5, z + lado * (ancho * 0.5 + 0.2))))
	_multimesh(BoxMesh.new(), piedra_osc, dovelas, Vector3.ONE)
	_multimesh(BoxMesh.new(), piedra, timpanos, Vector3.ONE)
	## Tajamares: proas de piedra en los pilares, río arriba y río abajo.
	for px: float in pilares:
		for lado: float in [-1.0, 1.0]:
			## (fuera de la pila, que ahora ocupa todo el ancho del puente)
			var t := b._caja_en(Vector3(px, PUENTE_ALTO * 0.35, z + lado * (ancho * 0.5 + 1.3)), Vector3(1.6, PUENTE_ALTO * 0.7, 1.6), piedra)
			t.rotation.y = PI * 0.25
	## Cornisa a lo largo del tablero.
	for lado: float in [-1.0, 1.0]:
		b._caja_en(Vector3(rx, PUENTE_ALTO - 0.2, z + lado * (ancho * 0.5 + 0.55)), Vector3(agua1 - agua0, 0.35, 0.5), piedra)
	## Aceras sobre el tablero (los peatones van por los lados).
	for lado: float in [-1.0, 1.0]:
		b._caja_en(Vector3(rx, PUENTE_ALTO + 0.38, z + lado * (ancho * 0.5 - 1.1)), Vector3(agua1 - agua0, 0.18, 2.2), b._mat_simple(Color(0.72, 0.68, 0.62), 0.8))
	## La balaustrada: columnillas bajo un pasamanos de piedra (sustituye al
	## muro liso de hormigón).
	var largo := agua1 - agua0 + rampa * 2.0
	var cuantos := int(largo / 0.7)
	for lado: float in [-1.0, 1.0]:
		var zb := z + lado * (ancho * 0.5 + 0.2)
		for k in cuantos:
			var x := rx - largo * 0.5 + (float(k) + 0.5) * largo / float(cuantos)
			var y_base := _altura_puente(x, rx, agua0, agua1, rampa)
			balaustres.append(Transform3D(Basis.from_scale(Vector3(0.22, 0.85, 0.22)), Vector3(x, y_base + 0.75, zb)))
		b._caja_en(Vector3(rx, PUENTE_ALTO + 1.25, zb), Vector3(agua1 - agua0, 0.2, 0.42), piedra)
	var torno := CylinderMesh.new()
	torno.height = 1.0
	torno.top_radius = 0.38
	torno.bottom_radius = 0.5
	torno.radial_segments = 8
	_multimesh(torno, piedra, balaustres, Vector3.ONE)
	## Farolas de forja con banderolas del club, cada 11 m por lado.
	var c1 := b._color_club("c1", Color(0.2, 0.5, 0.3))
	var c2 := b._color_club("c2", Color(1, 1, 1))
	var postes: Array[Transform3D] = []
	var faroles: Array[Transform3D] = []
	var banderolas: Array[Transform3D] = []
	var band_col: Array[Color] = []
	var nf := int((agua1 - agua0) / 11.0)
	for lado: float in [-1.0, 1.0]:
		for k in nf + 1:
			var x := agua0 + float(k) * (agua1 - agua0) / float(nf)
			var base := Vector3(x, PUENTE_ALTO + 1.35, z + lado * (ancho * 0.5 + 0.2))
			postes.append(Transform3D(Basis.from_scale(Vector3(0.14, 4.2, 0.14)), base + Vector3(0, 2.1, 0)))
			faroles.append(Transform3D(Basis.from_scale(Vector3(0.45, 0.6, 0.45)), base + Vector3(0, 4.45, 0)))
			if k % 2 == 1:
				banderolas.append(Transform3D(Basis.from_scale(Vector3(0.05, 1.5, 0.7)), base + Vector3(0, 3.0, -lado * 0.45)))
				band_col.append(c1 if k % 4 == 1 else c2)
	var cil := CylinderMesh.new()
	cil.height = 1.0
	cil.top_radius = 0.5
	cil.bottom_radius = 0.5
	_multimesh(cil, forja, postes, Vector3.ONE)
	_multimesh(BoxMesh.new(), _mat_luz_farola(), faroles, Vector3.ONE)
	_multimesh(BoxMesh.new(), null, banderolas, Vector3.ONE, band_col)
	## Pilonos en las cuatro esquinas, con el nombre del puente.
	for xe: float in [agua0 - rampa - 1.0, agua1 + rampa + 1.0]:
		for lado: float in [-1.0, 1.0]:
			var pz := z + lado * (ancho * 0.5 + 0.9)
			b._caja_en(Vector3(xe, 2.0, pz), Vector3(1.6, 4.0, 1.6), piedra)
			b._caja_en(Vector3(xe, 4.15, pz), Vector3(2.0, 0.3, 2.0), piedra_osc)
			b._caja_en(Vector3(xe, 4.8, pz), Vector3(0.6, 1.0, 0.6), _mat_luz_farola())
		var l := Label3D.new()
		l.text = nombre
		l.font_size = 44
		l.pixel_size = 0.01
		l.modulate = Color(0.25, 0.2, 0.15)
		l.outline_size = 0
		l.position = Vector3(xe + (-0.82 if xe < rx else 0.82), 2.4, z + ancho * 0.5 + 0.9)
		l.rotation.y = -PI * 0.5 if xe < rx else PI * 0.5
		l.visibility_range_end = 120.0
		b.add_child(l)
	b._rotulo(Vector3(rx, PUENTE_ALTO + 9.0, z), "🌉 " + nombre, Color(0.95, 0.9, 0.75), 16)
	## Luces bajo el tablero, reflejadas en el agua de noche.
	var luces: Array[Transform3D] = []
	for k in 16:
		for lado: float in [-1.0, 1.0]:
			luces.append(Transform3D(Basis.from_scale(Vector3(0.6, 0.15, 0.3)), Vector3(agua0 + (float(k) + 0.5) * (agua1 - agua0) / 16.0, PUENTE_ALTO - 0.45, z + lado * (ancho * 0.5 + 0.85))))
	_multimesh(BoxMesh.new(), _mat_luz_farola(), luces, Vector3.ONE)

## Un puente: tablero sobre pilares, con barandillas, más alto sobre el agua
## para que pase el bote, y rampas hasta las orillas.
func _puente(a: Vector3, c: Vector3, ancho: float) -> void:
	var x0 := minf(a.x, c.x) - ancho * 0.5
	var x1 := maxf(a.x, c.x) + ancho * 0.5
	var z := a.z
	var rx := CityBuilder.RIO_X
	var agua0 := rx - 44.0
	var agua1 := rx + 44.0
	var rampa := 20.0
	var hormigon := b._mat_simple(Color(0.7, 0.69, 0.66), 0.8)
	## Tramos a nivel fuera de las rampas.
	if agua0 - rampa > x0:
		_lote("asfalto", Vector3((x0 + agua0 - rampa) * 0.5, 0.07, z), Vector3(agua0 - rampa - x0, 0.12, ancho))
	if x1 > agua1 + rampa:
		_lote("asfalto", Vector3((agua1 + rampa + x1) * 0.5, 0.07, z), Vector3(x1 - agua1 - rampa, 0.12, ancho))
	## Cada cruce del río son DOS tramos de la red (a un lado y otro del nodo del
	## medio): el puente en sí se levanta una sola vez (16-10-2026; antes salía
	## dos veces, una encima de la otra).
	var clave_p := Vector2i(roundi(z), roundi(ancho))
	if _puentes_hechos.has(clave_p):
		return
	_puentes_hechos[clave_p] = true
	## Rampas inclinadas.
	for lado: float in [-1.0, 1.0]:
		var xa := agua0 - rampa if lado < 0.0 else agua1
		var cx := xa + rampa * 0.5
		var r := b._caja_en(Vector3(cx, PUENTE_ALTO * 0.5, z), Vector3(sqrt(rampa * rampa + PUENTE_ALTO * PUENTE_ALTO), 0.5, ancho), _mat["asfalto"])
		r.rotation.z = atan2(PUENTE_ALTO, rampa) * (-lado)
	## Tablero sobre el agua.
	_lote("asfalto", Vector3(rx, PUENTE_ALTO, z), Vector3(agua1 - agua0, 0.6, ancho))
	b._caja_en(Vector3(rx, PUENTE_ALTO - 0.8, z), Vector3(agua1 - agua0, 1.0, ancho + 1.0), hormigon)
	_apoyos_puente(rx, z, ancho, agua0, agua1, rampa)
	_adornar_puente(rx, z, ancho, agua0, agua1, rampa)
	cuenta["puentes"] = int(cuenta.get("puentes", 0)) + 1

## Cuánto se queda corta la acera de un lado (`lat`) antes del cruce `nodo`
## (`u` apunta del tramo al cruce). Negativo = pasa del centro del cruce.
##  · Si por ese lado sale otra calle, la acera acaba en su borde; la esquina
##    (el cuadrado entre las dos aceras) la pone el tramo horizontal.
##  · Si la calle sigue recta, llega al centro y empalma con la siguiente.
##  · Si no (esquina exterior de una L o de una T), da la vuelta a la esquina.
##  · Punta suelta (solo este brazo): como antes, a medio ancho.
func _fin_acera(nodo: Vector3, u: Vector3, lat: Vector3, ancho: float, horizontal: bool) -> float:
	var w_lado := ancho_brazo(nodo, lat)
	var w_sigue := ancho_brazo(nodo, u)
	var w_otro := ancho_brazo(nodo, -lat)
	if es_puente(nodo, -u) or es_puente(nodo, u) or (w_lado <= 0.0 and w_sigue <= 0.0 and w_otro <= 0.0):
		return ancho * 0.5
	if w_lado > 0.0:
		return w_lado * 0.5 if horizontal else w_lado * 0.5 + ACERA
	if w_sigue > 0.0:
		return 0.0
	return -(w_otro * 0.5 + ACERA) if horizontal else -(w_otro * 0.5)

## Hasta dónde no se pintan rayas desde el cruce `nodo` hacia dentro del tramo
## (`d` apunta del cruce al tramo).
func _libre_de_marcas(nodo: Vector3, d: Vector3) -> float:
	var medio := medio_cruce(nodo, d)
	if es_puente(nodo, d) or brazos.get(clave_cruce(nodo), [0.0, 0.0, 0.0, 0.0]).count(0.0) == 3:
		## Punta sin cruce de la red (llega a una calle del núcleo): como antes.
		return ancho_brazo(nodo, d) * 0.6
	if medio <= 0.0:
		return 0.0
	if tiene_semaforo(nodo):
		return linea_detencion(medio) + 1.0
	return medio + 2.0

## Calzadas, aceras, marcas viales y puentes.
func _dibujar_calles() -> void:
	var marcas: Array[Transform3D] = []
	for t: Dictionary in tramos:
		var a: Vector3 = t["a"]
		var c: Vector3 = t["b"]
		var ancho: float = t["ancho"]
		var vertical := absf(a.x - c.x) < 0.1
		var largo := a.distance_to(c)
		var m := (a + c) * 0.5
		var d := (c - a).normalized()
		var tam := Vector3(ancho, 0.12, largo + ancho) if vertical else Vector3(largo + ancho, 0.12, ancho)
		if bool(t["puente"]):
			_puente(a, c, ancho)
			continue
		_lote("asfalto", Vector3(m.x, 0.07, m.z), tam)
		## Aceras a los dos lados (más altas que la calzada). Cada punta llega
		## hasta el BORDE de la calle que cruza (no hasta su propio medio ancho,
		## que metía la acera de una calle 5 m dentro de la avenida), y la
		## esquina la pone el tramo horizontal (`_fin_acera`).
		for lado: float in [-1.0, 1.0]:
			var lat := Vector3(-d.z, 0, d.x) * lado
			var xa := _fin_acera(a, -d, lat, ancho, not vertical)
			var xc := _fin_acera(c, d, lat, ancho, not vertical)
			var l_acera := largo - xa - xc
			if l_acera < 0.5:
				continue
			var off := ancho * 0.5 + ACERA * 0.5
			var p := a + d * (xa + l_acera * 0.5) + lat * off
			p.y = 0.12
			var ta := Vector3(ACERA, 0.24, l_acera) if vertical else Vector3(l_acera, 0.24, ACERA)
			_lote("acera", p, ta)
		## Línea discontinua al centro (doble en las avenidas). Las rayas no
		## entran en el cruce ni pisan la cebra: se reparten solo por el tramo
		## libre entre las dos líneas de detención.
		var paso := 12.2 if bool(t["av"]) else 11.0
		var largo_raya := 8.8 if bool(t["av"]) else 4.0
		var la := _libre_de_marcas(a, d)
		var lc := _libre_de_marcas(c, -d)
		var util := largo - la - lc
		var n := int((util + paso - largo_raya) / paso)
		if n > 0:
			var sobra := util - (float(n - 1) * paso + largo_raya)
			for q in n:
				var dist := la + sobra * 0.5 + largo_raya * 0.5 + float(q) * paso
				var p2 := a + d * dist
				var esc := Vector3(0.25, 1.0, largo_raya) if vertical else Vector3(largo_raya, 1.0, 0.25)
				if bool(t["av"]):
					for dl: float in [-0.35, 0.35]:
						var pp := p2 + (Vector3(dl, 0, 0) if vertical else Vector3(0, 0, dl))
						marcas.append(Transform3D(Basis.from_scale(esc), pp + Vector3(0, 0.14, 0)))
				else:
					marcas.append(Transform3D(Basis.from_scale(esc), p2 + Vector3(0, 0.14, 0)))
	## Pasos de cebra en los cruces con semáforo: solo en los brazos que
	## existen, a todo el ancho de la calle, justo pasado el borde de la que
	## cruza, y detrás la línea de detención en los carriles que llegan.
	for p: Vector3 in cruces_semaforo:
		for dir: Vector3 in [Vector3(1, 0, 0), Vector3(-1, 0, 0), Vector3(0, 0, 1), Vector3(0, 0, -1)]:
			var w := ancho_brazo(p, dir)
			if w <= 0.0 or es_puente(p, dir):
				continue
			var medio := medio_cruce(p, dir)
			var en_x := absf(dir.x) > 0.5
			var base := p + dir * (medio + CEBRA_HUECO + CEBRA_LARGO * 0.5)
			var franjas := int((w - 2.0) / 1.6)
			for s in franjas:
				var lat := (float(s) - float(franjas - 1) * 0.5) * 1.6
				var pos := base + (Vector3(0, 0, lat) if en_x else Vector3(lat, 0, 0))
				var esc2 := Vector3(CEBRA_LARGO, 1.0, 0.8) if en_x else Vector3(0.8, 1.0, CEBRA_LARGO)
				marcas.append(Transform3D(Basis.from_scale(esc2), pos + Vector3(0, 0.14, 0)))
			## Línea de detención: se circula por la derecha, así que los que
			## llegan al cruce (van hacia -dir) ocupan el lado (-dir) x arriba.
			var llega := (-dir).cross(Vector3.UP)
			var pl := p + dir * (linea_detencion(medio) - 0.25) + llega * (w * 0.25)
			var esc3 := Vector3(0.5, 1.0, w * 0.5 - 0.6) if en_x else Vector3(w * 0.5 - 0.6, 1.0, 0.5)
			marcas.append(Transform3D(Basis.from_scale(esc3), pl + Vector3(0, 0.14, 0)))
	_multimesh(BoxMesh.new(), _mat["linea"], marcas, Vector3(1, 0.02, 1))
	cuenta["marcas"] = marcas.size()

func _arboles_en(puntos: Array, escala: float) -> void:
	var tr: Array[Transform3D] = []
	var co: Array[Transform3D] = []
	for p: Vector3 in puntos:
		var s := escala * _rng.randf_range(0.8, 1.2)
		tr.append(Transform3D(Basis.from_scale(Vector3(0.35, 4.0, 0.35) * s), p + Vector3(0, 2.0 * s, 0)))
		co.append(Transform3D(Basis.from_scale(Vector3(3.2, 3.6, 3.2) * s), p + Vector3(0, 5.6 * s, 0)))
	_multimesh(CylinderMesh.new(), _mat["tronco"], tr, Vector3.ONE)
	var esf := SphereMesh.new()
	esf.radial_segments = 8
	esf.rings = 5
	_multimesh(esf, _mat["hoja"], co, Vector3.ONE)

func _paseo_rio(r: Rect2) -> void:
	## Las orillas son paseo arbolado; el agua la pone `_rio_largo` de una vez.
	var rx := CityBuilder.RIO_X
	for lado: float in [-1.0, 1.0]:
		var x0 := rx + lado * 50.0
		var x1 := r.end.x if lado > 0.0 else r.position.x
		if (x1 - x0) * lado <= 2.0:
			continue
		var cx := (x0 + x1) * 0.5
		_lote("cesped", Vector3(cx, 0.05, r.get_center().y), Vector3(absf(x1 - x0), 0.1, r.size.y))
		_lote("acera", Vector3(x0 + lado * 4.0, 0.1, r.get_center().y), Vector3(5.0, 0.2, r.size.y))
		var pts: Array = []
		for k in 5:
			pts.append(Vector3(x0 + lado * 10.0, 0, r.position.y + r.size.y * (float(k) + 0.5) / 5.0))
		_arboles_en(pts, 0.9)

func _puerto(r: Rect2) -> void:
	_paseo_rio(r)
	var rx := CityBuilder.RIO_X
	var madera := b._mat_simple(Color(0.45, 0.34, 0.22), 0.85)
	## Muelles que entran en el agua y barcos amarrados.
	for k in 3:
		var z := r.position.y + r.size.y * (float(k) + 0.5) / 3.0
		b._caja_en(Vector3(rx - 30.0, 0.6, z), Vector3(26.0, 0.4, 4.0), madera)
		var barco := b._hacer_velero()
		if barco != null:
			barco.position = Vector3(rx - 22.0, 0.1, z + 6.0)
			barco.rotation.y = PI * 0.5
			b.add_child(barco)
	## Grúa portuaria.
	b._grua(Vector3(rx - 62.0, 0, r.get_center().y), 26.0)
	var alm := b._mat_simple(Color(0.6, 0.45, 0.32), 0.8)
	b._caja_en(Vector3(r.position.x + 22.0, 5.0, r.get_center().y), Vector3(30.0, 10.0, r.size.y * 0.6), alm)
	b._rotulo(Vector3(rx - 40.0, 22.0, r.get_center().y), "⚓ Puerto fluvial", Color(0.8, 0.9, 1.0), 22)
	b.puntos_clic.append({"k": "ciudad_puerto", "n": "Puerto · pescar", "pos": Vector3(rx - 30.0, 0, r.get_center().y), "estado": "ciudad"})

## La finca de la Casa Grande: césped, seto alrededor con portón al norte
## (al bulevar), la casa en el centro, camino de entrada, fuente y jardín.
func _casa_grande(r: Rect2) -> void:
	var c := Vector3(r.get_center().x, 0, r.get_center().y)
	_lote("cesped", Vector3(c.x, 0.05, c.z), Vector3(r.size.x, 0.1, r.size.y))
	b._finca_enredadera(c, r.size)
	b._casa_gigante(c, Vector2(r.size.x - 70.0, r.size.y - 70.0))
	## Camino del portón (norte) a la casa, y una fuente en medio.
	b._caja_en(Vector3(c.x, 0.08, r.position.y + r.size.y * 0.18), Vector3(8.0, 0.1, r.size.y * 0.36), b._mat_simple(Color(0.78, 0.74, 0.66), 0.85))
	b._cil_en(Vector3(c.x, 0.6, r.position.y + r.size.y * 0.2), 5.0, 1.0, _mat["piedra"])
	b._cil_en(Vector3(c.x, 1.05, r.position.y + r.size.y * 0.2), 4.3, 0.2, _mat["agua"])
	var pts: Array = []
	for k in 18:
		var ang := TAU * float(k) / 18.0
		pts.append(c + Vector3(cos(ang) * r.size.x * 0.42, 0, sin(ang) * r.size.y * 0.42))
	_arboles_en(pts, 1.1)

func _malla_kit(ruta: String) -> Dictionary:
	if _mallas_kit.has(ruta):
		return _mallas_kit[ruta]
	var r := {}
	var ps := load(ruta) as PackedScene
	if ps != null:
		var inst := ps.instantiate()
		var mis := inst.find_children("*", "MeshInstance3D", true, false)
		if not mis.is_empty() and (mis[0] as MeshInstance3D).mesh != null:
			var m: Mesh = (mis[0] as MeshInstance3D).mesh
			r = {"malla": m, "caja": m.get_aabb()}
		inst.free()
	_mallas_kit[ruta] = r
	return r

## Una pieza de kit apoyada en el suelo, centrada en `centro`, girada y a escala.
func _pieza_kit(ruta: String, centro: Vector3, escala: float, giro: float, tinte := 0) -> MeshInstance3D:
	var k := _malla_kit(ruta)
	if k.is_empty():
		return null
	var caja: AABB = k["caja"]
	var base := Basis(Vector3.UP, giro).scaled(Vector3.ONE * escala)
	## Dentro de un nodo: `tenir` tiñe las mallas HIJAS del nodo que recibe.
	var n := Node3D.new()
	n.transform = Transform3D(base, centro - base * Vector3(caja.get_center().x, caja.position.y, caja.get_center().z))
	var mi := MeshInstance3D.new()
	mi.mesh = k["malla"]
	n.add_child(mi)
	b.add_child(n)
	if tinte != 0:
		b.tenir(n, tinte)
	return mi

## La escala para que el ancho (X) de la pieza mida `metros`.
func _escala_ancho(ruta: String, metros: float) -> float:
	var k := _malla_kit(ruta)
	if k.is_empty():
		return 1.0
	return metros / maxf((k["caja"] as AABB).size.x, 0.01)
