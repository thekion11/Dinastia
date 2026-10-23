class_name CiudadExpansion
extends "res://visor/ciudad_expansion_p8.gd"
## (Parte 9 de 9 de `ciudad_expansion.gd`.)

func _kenney_calles() -> void:
	var r := RandomNumberGenerator.new()
	r.seed = 20261014
	var postes := 0
	var brazos := 0
	var carteles := 0
	for t: Dictionary in tramos:
		if bool(t["puente"]):
			continue
		var a: Vector3 = t["a"]
		var c: Vector3 = t["b"]
		var vertical := absf(a.x - c.x) < 0.1
		var largo := a.distance_to(c)
		var ancho: float = t["ancho"]
		var m := (a + c) * 0.5
		if bool(t["av"]):
			## Avenidas: un brazo de farola curva cada ~48 m, alternando lados.
			## (Desde el 15-10-2026 todas las farolas son la curva de Kenney, en
			## `_farolas`; esto solo queda si el modelo no carga.)
			var n := int((largo - ancho) / 48.0) if _malla_kit("res://assets/ciudad/kenney_roads/light-curved.glb").is_empty() else 0
			for q in n:
				var f := (float(q) + 0.5) / float(maxi(1, n))
				var p := a.lerp(c, f)
				var lado := 1.0 if q % 2 == 0 else -1.0
				var off := (ancho * 0.5 + ACERA * 0.6) * lado
				var pos := p + (Vector3(off, 0.24, 0) if vertical else Vector3(0, 0.24, off))
				## El brazo (+Z local del modelo) apunta hacia la calzada.
				var giro := (PI * 0.5 if lado > 0.0 else -PI * 0.5) if vertical else (PI if lado > 0.0 else 0.0)
				if _prop_kenney("light-curved", pos, giro, 9.0) != null:
					brazos += 1
		elif r.randf() < 0.22 and largo > 60.0:
			## Calles de barrio: un poste con cable a un lado.
			var lado2 := 1.0 if r.randf() < 0.5 else -1.0
			var off2 := (ancho * 0.5 + ACERA * 0.8) * lado2
			var pos2 := m + (Vector3(off2, 0.24, 0) if vertical else Vector3(0, 0.24, off2))
			var giro2 := 0.0 if vertical else PI * 0.5
			if _prop_kenney("electricity-pole", pos2, giro2, 9.0) != null:
				postes += 1
	## Carteles colgantes sobre la calzada en cada cruce con semáforo.
	for p: Vector3 in cruces_semaforo:
		var esq := p + Vector3(ANCHO_AV * 0.5 + ACERA * 0.6, 0.24, -ANCHO_AV * 0.5 - ACERA * 0.6)
		if _prop_kenney("road-sign-empty-hanging", esq, PI * 0.5, 12.0) != null:
			carteles += 1
	cuenta["kenney_brazos"] = brazos
	cuenta["kenney_postes"] = postes
	cuenta["kenney_carteles"] = carteles

## EL PARQUE EÓLICO en las lomas del noroeste, fuera de la autopista: diez
## molinos de 45 m con las aspas girando (cada uno a su ritmo).
func _parque_eolico() -> void:
	var blanco := b._mat_simple(Color(0.93, 0.94, 0.95), 0.4)
	for k in 10:
		var ang := -2.3 + float(k) * 0.12
		var r := 1750.0 + float(k % 3) * 120.0
		var p := Vector3(cos(ang) * r, 0, sin(ang) * r)
		p.y = b.altura_en(p.x, p.z)
		b._cil_en(p + Vector3(0, 22.5, 0), 1.2, 45.0, blanco, 0.7)
		b._caja_en(p + Vector3(0, 45.5, 0.8), Vector3(2.2, 2.2, 5.0), blanco)
		var g := Girador.new()
		g.vel = 0.8 + float(k % 4) * 0.15
		g.position = p + Vector3(0, 45.5, 3.6)
		g.rotation.y = 0.0
		b.add_child(g)
		for a in 3:
			var pala := MeshInstance3D.new()
			var bm := BoxMesh.new()
			bm.size = Vector3(1.2, 20.0, 0.3)
			pala.mesh = bm
			pala.material_override = blanco
			pala.rotation.z = TAU * float(a) / 3.0
			pala.position = Vector3(sin(TAU * float(a) / 3.0) * -10.0, cos(TAU * float(a) / 3.0) * 10.0, 0)
			g.add_child(pala)
	cuenta["molinos"] = 10

## El depósito de agua de la ciudad: una torre con su tanque, en el oeste.
func _deposito_agua() -> void:
	var p := Vector3(-990, 0, 440)
	var gris := b._mat_simple(Color(0.62, 0.64, 0.66), 0.6)
	for sx: float in [-1.0, 1.0]:
		for sz: float in [-1.0, 1.0]:
			b._cil_en(p + Vector3(sx * 5.0, 14.0, sz * 5.0), 0.6, 28.0, gris)
	b._cil_en(p + Vector3(0, 33.0, 0), 9.0, 10.0, b._mat_simple(Color(0.85, 0.87, 0.9), 0.4))
	var l := Label3D.new()
	l.text = String(b.datos.get("club", {}).get("nombre", "")).to_upper()
	l.font_size = 72
	l.pixel_size = 0.04
	l.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	l.modulate = b._color_club("c1", Color(0.2, 0.5, 0.3))
	l.outline_size = 10
	l.position = p + Vector3(0, 33.0, 0)
	b.add_child(l)

func _volcar_lotes() -> void:
	for clave: String in _lotes:
		var lista: Array[Transform3D] = []
		lista.assign(_lotes[clave])
		_multimesh(BoxMesh.new(), _mat[clave], lista, Vector3.ONE)
	_lotes.clear()

# ============================================================================
#  EL DIBUJO
# ============================================================================

func construir() -> void:
	armar_red()
	armar_bloques()
	armar_transporte()
	_cargar_modelos()
	_materiales()
	_dibujar_calles()
	semaforos = Semaforos.new()
	semaforos.name = "Semaforos"
	b.add_child(semaforos)
	semaforos.montar(cruces_semaforo, self)
	cuenta["edificios"] = 0
	for bl: Dictionary in bloques:
		_dibujar_bloque(bl)
	_edificios_lejanos()
	_casas_multimesh()
	_modular_multimesh()
	metro = MetroCiudad.new()
	metro.name = "Metro"
	b.add_child(metro)
	metro.montar(self)
	_bocas_metro()
	_marquesinas_bus()
	_guirnaldas()
	_farolas()
	_mobiliario_urbano()
	_placas_de_calle()
	_orillas_nucleo()
	_obras_en_calle()
	_kenney_calles()
	cuenta["autopista"] = Autopista.montar(b)
	_parque_eolico()
	_deposito_agua()
	_volcar_lotes()

## Un bloque alto hecho con el mismo modelo apilado planta sobre planta (en
## vez de estirarlo): crece en pisos y las ventanas conservan su forma.
func _kit_apilado(esc: PackedScene, pos: Vector3, s: float, pisos: int, giro: float) -> void:
	var tmp: Node3D = esc.instantiate()
	var alto := b._caja_de(tmp).size.y * s
	tmp.free()
	for k in pisos:
		_kit(esc, pos + Vector3(0, float(k) * alto * 0.98, 0), Vector3.ONE * s, giro)

## 0 de día, 1 de noche: guirnaldas, farolas y ventanas lejanas.
func encender(noche: float) -> void:
	for m in _bombillas:
		m.emission_energy_multiplier = lerpf(0.15, 1.4, noche)
	if _farola_luz != null:
		_farola_luz.emission_energy_multiplier = lerpf(0.0, 2.6, noche)
	if _farola_charco != null:
		_farola_charco.albedo_color.a = lerpf(0.0, 0.55, noche)
	if _farola_cono != null:
		_farola_cono.set_shader_parameter("fuerza", lerpf(0.0, 0.16, noche))
	if _ventanas_lejanas != null:
		_ventanas_lejanas.set_shader_parameter("noche", noche)

## `luz`: la máscara de las ventanas encendidas (blanco = ventana, unas sí y
## otras no) para la emisión nocturna.
func _textura_ventanas(luz: bool = false) -> ImageTexture:
	var img := Image.create(64, 64, false, Image.FORMAT_RGB8)
	img.fill(Color(0, 0, 0) if luz else Color(1, 1, 1))
	if luz:
		var rr := RandomNumberGenerator.new()
		rr.seed = 99
		for vy in 4:
			for vx in 4:
				if rr.randf() < 0.35:
					for y in range(vy * 16 + 4, vy * 16 + 12):
						for x in range(vx * 16 + 4, vx * 16 + 13):
							img.set_pixel(x, y, Color(1, 1, 1))
		return ImageTexture.create_from_image(img)
	for y in 64:
		for x in 64:
			var vx := (x % 16) >= 4 and (x % 16) < 13
			var vy := (y % 16) >= 4 and (y % 16) < 12
			if vx and vy:
				img.set_pixel(x, y, Color(0.35, 0.45, 0.55))
	return ImageTexture.create_from_image(img)

## El recorrido por el carril derecho de un circuito de esquinas.
func _carril(esquinas: Array, sentido: float) -> PackedVector3Array:
	var pts := PackedVector3Array()
	for e: Vector2 in esquinas:
		pts.append(Vector3(e.x, 0.25, e.y))
	if sentido < 0.0:
		pts.reverse()
	var n := pts.size()
	var sal := PackedVector3Array()
	var carril := ANCHO_AV * 0.25
	for k in n:
		var prev := pts[(k - 1 + n) % n]
		var act := pts[k]
		var sig := pts[(k + 1) % n]
		var d1 := (act - prev).normalized()
		var d2 := (sig - act).normalized()
		var off := (Vector3(-d1.z, 0, d1.x) + Vector3(-d2.z, 0, d2.x)).normalized() * carril * 1.414
		sal.append(act + off)
	return sal

## Mete las rampas y el tablero de cada puente en un recorrido llano.
func _subir_puentes(pts: PackedVector3Array) -> PackedVector3Array:
	var sal := PackedVector3Array()
	var rx := CityBuilder.RIO_X
	var n := pts.size()
	for k in n:
		var a := pts[k]
		var c := pts[(k + 1) % n]
		sal.append(a)
		if absf(a.z - c.z) > 0.5:
			continue
		if not (minf(a.x, c.x) < rx - 64.0 and maxf(a.x, c.x) > rx + 64.0):
			continue
		var dir := signf(c.x - a.x)
		for x: float in [rx - dir * 64.0, rx - dir * 44.0, rx + dir * 44.0, rx + dir * 64.0]:
			var y := 0.25 if absf(x - rx) > 50.0 else PUENTE_ALTO + 0.35
			sal.append(Vector3(x, y, a.z))
	return sal

## Una línea de detención antes de cada semáforo por el que pasa la ruta.
func _controles_de(t: TraficoCiudad, id: int) -> void:
	if semaforos == null:
		return
	for p: Vector3 in cruces_semaforo:
		var s := t.s_mas_cercano(id, p + Vector3(0, 0.25, 0))
		var r_en: Array = t._rutas[id].en(s)
		var q: Vector3 = r_en[0]
		if Vector2(q.x - p.x, q.z - p.z).length() > ANCHO_AV:
			continue
		var dir: Vector3 = r_en[1]
		var eje := 0 if absf(dir.z) > absf(dir.x) else 1
		## El coche (su centro: medio coche, ~2,4 m) para DETRÁS de la línea de
		## detención; antes paraba a 15 m del centro, encima de la cebra.
		var medio := medio_cruce(p, -dir)
		if medio <= 0.0:
			medio = ANCHO_AV * 0.5
		t.agregar_control(id, s - (linea_detencion(medio) + 2.8), eje)

# ============================================================================
#  EL TRÁFICO DE LA CIUDAD GRANDE
# ============================================================================

## Circuitos por avenidas (dos sentidos, carril derecho), con sus líneas de
## detención en cada semáforo; las dos líneas de autobús con sus paradas; y
## peatones por las aceras del centro y del este.
func trafico(t: TraficoCiudad, coches: Array, rng: RandomNumberGenerator) -> void:
	t.semaforos = semaforos
	var circuitos := [
		[Vector2(-660, -990), Vector2(660, -990), Vector2(660, -660), Vector2(-660, -660)],
		[Vector2(660, -660), Vector2(990, -660), Vector2(990, 660), Vector2(660, 660)],
		[Vector2(-660, 660), Vector2(660, 660), Vector2(660, 990), Vector2(-660, 990)],
		[Vector2(-990, -660), Vector2(-660, -660), Vector2(-660, 660), Vector2(-990, 660)],
		[Vector2(-1320, -1320), Vector2(1320, -1320), Vector2(1320, 1320), Vector2(-1320, 1320)],
		[Vector2(NUC_X0, NUC_Z0), Vector2(NUC_X1, NUC_Z0), Vector2(NUC_X1, NUC_Z1), Vector2(NUC_X0, NUC_Z1)],
	]
	var por_sentido := int(round(lerpf(4.0, 9.0, b._empuje_club())))
	var n_coches := 0
	for esq: Array in circuitos:
		for sentido in [1.0, -1.0]:
			var pts := _carril(esq, sentido)
			pts = _subir_puentes(pts)
			var id := t.agregar_ruta(b._redondear(pts, 12.0))
			_controles_de(t, id)
			if coches.is_empty():
				continue
			var largo := t.largo_de(id)
			for i in por_sentido:
				var nodo: Node3D = CityBuilder.instanciar_coche(coches[rng.randi() % coches.size()], rng)
				t.agregar_vehiculo(nodo, id, largo * (float(i) + rng.randf() * 0.5) / float(por_sentido), rng.randf_range(10.0, 15.0), 0.0, 0.0)
				t.marcar_cola_al_ultimo()
				n_coches += 1
	cuenta["coches"] = n_coches
	## La autopista: tráfico más rápido, sin semáforos.
	for pts_a: PackedVector3Array in Autopista.rutas():
		var ida := t.agregar_ruta(b._redondear(pts_a, 30.0))
		if coches.is_empty():
			continue
		var largo_a := t.largo_de(ida)
		for i in 12:
			var na: Node3D = CityBuilder.instanciar_coche(coches[rng.randi() % coches.size()], rng)
			t.agregar_vehiculo(na, ida, largo_a * float(i) / 12.0 + rng.randf() * 40.0, rng.randf_range(22.0, 30.0), 0.0, 0.0)
			t.marcar_cola_al_ultimo()
	## Los autobuses.
	var n_bus := 0
	for l: Dictionary in lineas_bus:
		var pts2: PackedVector3Array = _subir_puentes(l["puntos"])
		var id2 := t.agregar_ruta(b._redondear(pts2, 12.0))
		_controles_de(t, id2)
		var paradas: Array = []
		for p: Vector3 in l["paradas"]:
			paradas.append(t.s_mas_cercano(id2, p))
		var largo2 := t.largo_de(id2)
		var col_bus := Color(0.85, 0.15, 0.12) if String(l["nombre"]).contains("10") else Color(0.15, 0.4, 0.8)
		for k in 2:
			var nb: Node3D = CityBuilder.autobus(col_bus, String(l["nombre"]).to_upper())
			t.agregar_vehiculo(nb, id2, largo2 * float(k) * 0.5, 9.0, 0.0, 0.0)
			t.agregar_paradas_al_ultimo(paradas, 7.0)
			t.marcar_cola_al_ultimo()
			n_bus += 1
	cuenta["autobuses"] = n_bus
	## Peatones: la vuelta a varias manzanas por su acera.
	var n_p := 0
	var elegidos := 0
	for bl: Dictionary in bloques:
		if not (String(bl["zona"]) in ["centro", "este"]) or String(bl["uso"]) in ["lejano", "rio"]:
			continue
		if rng.randf() > 0.25:
			continue
		var r: Rect2 = bl["rect"]
		var m := 1.6
		var pts3 := PackedVector3Array([
			Vector3(r.position.x - m, 0.3, r.position.y - m), Vector3(r.end.x + m, 0.3, r.position.y - m),
			Vector3(r.end.x + m, 0.3, r.end.y + m), Vector3(r.position.x - m, 0.3, r.end.y + m)])
		var id3 := t.agregar_ruta(b._redondear(pts3, 3.0))
		for q in 2:
			b._un_peaton(t, rng, id3, rng.randf() * 300.0)
			n_p += 1
		elegidos += 1
		if elegidos >= 16:
			break
	## GENTE EN TODOS LOS BARRIOS (13-10-2026): la acera de cada manzana queda
	## como ruta posible (solo datos); los peatones que quedan lejos de ti
	## reaparecen en las de tu alrededor (`TraficoCiudad.reciclar_peatones`).
	for bl2: Dictionary in bloques:
		if String(bl2["uso"]) in ["lejano", "rio"]:
			continue
		var r2: Rect2 = bl2["rect"]
		if r2.size.x < 12.0 or r2.size.y < 12.0:
			continue
		var m2 := 1.6
		var pts4 := PackedVector3Array([
			Vector3(r2.position.x - m2, 0.3, r2.position.y - m2), Vector3(r2.end.x + m2, 0.3, r2.position.y - m2),
			Vector3(r2.end.x + m2, 0.3, r2.end.y + m2), Vector3(r2.position.x - m2, 0.3, r2.end.y + m2)])
		t.registrar_ruta_gente(t.agregar_ruta(b._redondear(pts4, 3.0)))
	## Y más gente para repartir: el reciclaje la lleva donde estés.
	var rutas_g: Array = t.rutas_gente()
	for q2 in 34:
		if rutas_g.is_empty():
			break
		b._un_peaton(t, rng, int(rutas_g[rng.randi() % rutas_g.size()]), rng.randf() * 300.0)
		n_p += 1
	cuenta["peatones"] = n_p
