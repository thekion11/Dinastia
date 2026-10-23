extends "res://visor/city_builder_p8.gd"
## (Parte 9 de 12 de `city_builder.gd`.)

func tenir(n: Node, semilla: int) -> void:
	var t: int = absi(semilla) % TINTES.size()
	for mi in n.find_children("*", "MeshInstance3D", true, false):
		var m3 := mi as MeshInstance3D
		if m3.mesh == null:
			continue
		for s in m3.mesh.get_surface_count():
			var orig := m3.mesh.surface_get_material(s) as StandardMaterial3D
			if orig == null:
				continue
			var clave := "%d|%d" % [orig.get_instance_id(), t]
			var m: StandardMaterial3D = _cache_tintes.get(clave)
			if m == null:
				m = orig.duplicate() as StandardMaterial3D
				m.albedo_color = orig.albedo_color * TINTES[t]
				_cache_tintes[clave] = m
			m3.set_surface_override_material(s, m)

## Una fila de edificios a lo largo de una acera. Se salta los cruces, el
## ramal del barrio y los ramales y solares de las parcelas.
func _fila_urbana(calle: Vector3, dir: Vector3, afuera: Vector3, medio_largo: float,
		detalle: Array[PackedScene], bloques: Array[PackedScene], toldos: Array[PackedScene],
		rng: RandomNumberGenerator, lleno: float) -> void:
	## La línea de fachada: justo detrás de la acera (calzada/2 + bordillo +
	## acera + un metro de retranqueo).
	var linea: float = ANCHO_CALLE * 0.5 + BORDILLO + ACERA + 1.0
	## Los edificios del kit miran a +Z: se giran para dar la cara a su calle.
	var giro: float = atan2(-afuera.x, -afuera.z)
	var u := -medio_largo + ANCHO_CALLE
	var orden := 0
	while u < medio_largo - ANCHO_CALLE:
		var eje: Vector3 = calle + dir * u
		if _hueco_urbano(eje, afuera, linea):
			u += 6.0
			continue
		## Tramos vacíos con un club chico: la calle se va llenando.
		if rng.randf() > lleno:
			u += rng.randf_range(18.0, 30.0)
			continue
		var esc: PackedScene = detalle[(orden * 5 + rng.randi() % 3) % detalle.size()]
		orden += 1
		var nodo: Node3D = esc.instantiate()
		var s: float = 5.5 * rng.randf_range(0.9, 1.1)
		nodo.scale = Vector3.ONE * s
		var caja := _caja_de(nodo)
		var ancho: float = maxf(caja.size.x * s, 6.0)
		var fondo: float = maxf(caja.size.z * s, 6.0)
		## No invadir el hueco siguiente (cruce, ramal o parcela).
		if _hueco_urbano(calle + dir * (u + ancho), afuera, linea):
			nodo.free()
			u += 6.0
			continue
		var c: Vector3 = calle + dir * (u + ancho * 0.5) + afuera * (linea + fondo * 0.5)
		nodo.rotation.y = giro
		nodo.position = Vector3(c.x, altura_en(c.x, c.z) - 0.2, c.z)
		add_child(nodo)
		_frentes.append(_rect_de(c, dir, ancho, fondo))
		## Un toldo o marquesina sobre la acera, uno de cada tres locales.
		if not toldos.is_empty() and rng.randf() < 0.33:
			var tl: Node3D = toldos[rng.randi() % toldos.size()].instantiate()
			tl.scale = Vector3.ONE * 4.5
			tl.rotation.y = giro
			var tp: Vector3 = calle + dir * (u + ancho * 0.5) + afuera * (linea - 1.6)
			tl.position = Vector3(tp.x, altura_en(tp.x, tp.z), tp.z)
			add_child(tl)
		## Segunda fila: un bloque simple detrás, más alto, que asoma por
		## encima de la fachada como en cualquier centro.
		if not bloques.is_empty() and rng.randf() < 0.8:
			var b: Node3D = bloques[rng.randi() % bloques.size()].instantiate()
			vestir_torre(b, int(b.get_instance_id()))
			if rng.randf() < 0.45:
				tenir(b, rng.randi())
			var sb: float = 6.0 * rng.randf_range(0.9, 1.2)
			b.scale = Vector3.ONE * sb
			var cb := _caja_de(b)
			var fondo_b: float = maxf(cb.size.z * sb, 6.0)
			var pb: Vector3 = c + afuera * (fondo * 0.5 + 4.0 + fondo_b * 0.5)
			if not _hueco_urbano(pb - afuera * (linea + fondo * 0.5 + 4.0 + fondo_b * 0.5), afuera, linea + fondo + 4.0 + fondo_b):
				b.rotation.y = giro
				b.position = Vector3(pb.x, altura_en(pb.x, pb.z) - 0.2, pb.z)
				add_child(b)
				_frentes.append(_rect_de(pb, dir, maxf(cb.size.x * sb, 6.0), fondo_b))
			else:
				b.free()
		u += ancho + rng.randf_range(0.5, 3.5)

func _frentes_urbanos() -> void:
	var detalle: Array[PackedScene] = []
	for ruta in RUTAS_COMERCIAL:
		var e: PackedScene = load(ruta)
		if e != null:
			detalle.append(e)
	var bloques: Array[PackedScene] = []
	for ruta in RUTAS_NAVES:
		var e2: PackedScene = load(ruta)
		if e2 != null:
			bloques.append(e2)
	if detalle.is_empty():
		return
	var toldos: Array[PackedScene] = []
	for ruta in RUTAS_MOBILIARIO:
		var e3: PackedScene = load(ruta)
		if e3 != null:
			toldos.append(e3)
	var rng := RandomNumberGenerator.new()
	rng.seed = 26092026
	var lleno: float = lerpf(0.45, 1.0, _empuje_club())
	## Las cuatro aceras de fuera del anillo. `dir` es hacia dónde avanza la
	## fila, `afuera` hacia dónde queda el solar (lejos de la calle).
	var tramos := [
		{"calle": Vector3(0, 0, RING_Z_SUR), "dir": Vector3.RIGHT, "afuera": Vector3.BACK, "largo": RING_X},
		{"calle": Vector3(0, 0, RING_Z_NORTE), "dir": Vector3.RIGHT, "afuera": Vector3.FORWARD, "largo": RING_X},
		{"calle": Vector3(RING_X, 0, (RING_Z_SUR + RING_Z_NORTE) * 0.5), "dir": Vector3.BACK, "afuera": Vector3.RIGHT, "largo": (RING_Z_SUR - RING_Z_NORTE) * 0.5},
		{"calle": Vector3(-RING_X, 0, (RING_Z_SUR + RING_Z_NORTE) * 0.5), "dir": Vector3.BACK, "afuera": Vector3.LEFT, "largo": (RING_Z_SUR - RING_Z_NORTE) * 0.5},
	]
	for t in tramos:
		_fila_urbana(t["calle"], t["dir"], t["afuera"], float(t["largo"]), detalle, bloques, toldos, rng, lleno)

## Un punto del óvalo (rectas en X, curvas en los extremos), `t` de 0 a 1.
static func _en_ovalo(c: Vector3, largo: float, r: float, t: float) -> Vector3:
	var recta := largo
	var curva := PI * r
	var total := 2.0 * recta + 2.0 * curva
	var d := fposmod(t, 1.0) * total
	if d < recta:
		return c + Vector3(-largo * 0.5 + d, 0, -r)
	d -= recta
	if d < curva:
		var a := d / r
		return c + Vector3(largo * 0.5 + sin(a) * r, 0, -cos(a) * r)
	d -= curva
	if d < recta:
		return c + Vector3(largo * 0.5 - d, 0, r)
	d -= recta
	var a2 := d / r
	return c + Vector3(-largo * 0.5 - sin(a2) * r, 0, cos(a2) * r)

## La pista de karting, al sur del anillo: óvalo de asfalto con piano de
## colores, barrera de neumáticos, conos, boxes con su taller, y los cinco
## karts del kit dando vueltas (una ruta más de `TraficoCiudad`).
func _karting() -> void:
	puntos_clic.append({"k": "karting", "n": "Karting · contrarreloj", "pos": KARTING_EN, "estado": "ciudad"})
	if _extra(KARTS[0]) == null:
		return
	var c := KARTING_EN
	var largo := 70.0
	var radio := 22.0
	var ancho_p := 9.0
	var asf := Texturas.asfalto(Color(0.15, 0.15, 0.16), 77)
	var cesp := StandardMaterial3D.new()
	cesp.albedo_color = Color(0.2, 0.42, 0.16)
	## El óvalo: tramo recto + dos curvas (discos), y dentro el césped.
	for capa: Array in [[radio, asf, 0.05], [radio - ancho_p, cesp, 0.07]]:
		var r: float = capa[0]
		var bm := BoxMesh.new()
		bm.size = Vector3(largo, 0.1, r * 2.0)
		var caja := MeshInstance3D.new()
		caja.mesh = bm
		caja.material_override = capa[1]
		caja.position = c + Vector3(0, capa[2], 0)
		add_child(caja)
		for s in [-1.0, 1.0]:
			var cm := CylinderMesh.new()
			cm.top_radius = r
			cm.bottom_radius = r
			cm.height = 0.1
			cm.radial_segments = 40
			var disco := MeshInstance3D.new()
			disco.mesh = cm
			disco.material_override = capa[1]
			disco.position = c + Vector3(s * largo * 0.5, capa[2], 0)
			add_child(disco)
	## Piano rojo y blanco en el borde interior de las rectas.
	var rojo := StandardMaterial3D.new()
	rojo.albedo_color = Color(0.85, 0.12, 0.12)
	var blanco := StandardMaterial3D.new()
	blanco.albedo_color = Color(0.95, 0.95, 0.95)
	for s in [-1.0, 1.0]:
		for k in 14:
			var pz := MeshInstance3D.new()
			var pb := BoxMesh.new()
			pb.size = Vector3(largo / 14.0, 0.06, 0.8)
			pz.mesh = pb
			pz.material_override = rojo if k % 2 == 0 else blanco
			pz.position = c + Vector3(-largo * 0.5 + (k + 0.5) * largo / 14.0, 0.12, s * (radio - ancho_p - 0.4))
			add_child(pz)
	## Barrera de neumáticos por fuera, a lo largo de todo el contorno.
	var n_bar := 64
	for k in n_bar:
		var t := float(k) / float(n_bar)
		var p := _en_ovalo(c, largo, radio + 1.5, t)
		_poner_extra("wheel-dark" if k % 3 != 0 else "wheel-default", p, 2.4, 0.0)
		_poner_extra("wheel-dark", p + Vector3(0, 0.5, 0), 2.4, 0.4)
	## Conos en las curvas.
	for k in 10:
		var t2 := 0.2 + 0.05 * k if k < 5 else 0.7 + 0.05 * (k - 5)
		_poner_extra("cone-flat" if k % 2 == 0 else "cone-flat", _en_ovalo(c, largo, radio - ancho_p - 1.2, t2), 2.5, 0.0)
	## Boxes: una nave baja con el taller de ruedas y piezas al lado.
	var boxes := MeshInstance3D.new()
	var bb := BoxMesh.new()
	bb.size = Vector3(26.0, 5.0, 9.0)
	boxes.mesh = bb
	boxes.material_override = Texturas.hormigon(Color(0.7, 0.7, 0.72), 88)
	boxes.position = c + Vector3(0, 2.5, -radio - 9.0)
	add_child(boxes)
	var techo := MeshInstance3D.new()
	var tb := BoxMesh.new()
	tb.size = Vector3(28.0, 0.4, 11.0)
	techo.mesh = tb
	techo.material_override = rojo
	techo.position = c + Vector3(0, 5.2, -radio - 9.0)
	add_child(techo)
	_desguace(c + Vector3(largo * 0.5 + radio + 10.0, 0, -radio - 6.0), 9021)
	_rotulo(c + Vector3(0, 10.0, -radio - 9.0), "🏎 Karting", Color(1, 1, 1), 26)
	_frentes.append(Rect2(c.x - largo * 0.5 - radio - 18.0, c.z - radio - 16.0, largo + radio * 2.0 + 36.0, radio * 2.0 + 20.0))
	## Los cinco karts en carrera.
	var ruta := PackedVector3Array()
	for k in 48:
		ruta.append(_en_ovalo(c, largo, radio - ancho_p * 0.5, float(k) / 48.0) + Vector3(0, 0.12, 0))
	_karts_pendientes = {"ruta": ruta}

func _en_frente_urbano(x: float, z: float) -> bool:
	for r in _frentes:
		if r.grow(4.0).has_point(Vector2(x, z)):
			return true
	## Ni sobre ninguna calle con sus aceras (ramales incluidos).
	for v in _vias:
		var rv := _rect_en(v, true)
		if x > rv[0] - 8.0 and x < rv[1] + 8.0 and z > rv[2] - 8.0 and z < rv[3] + 8.0:
			return true
	return false

## Arbolado alrededor del complejo. Es lo que mas hace por que la escena deje de
## parecer una maqueta: rompe la horizontal, da sombras y da ESCALA — sin nada
## vivo al lado, un edificio de 30 m y uno de 6 se ven igual de grandes.
##
## Van en un MultiMesh y no como nodos sueltos: son varios cientos y cada uno
## como nodo propio hundiria los fotogramas en una Intel UHD. Con MultiMesh el
## motor los dibuja de una sola pasada.
func _arbolado() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 77123

	var tronco_mm := MultiMesh.new()
	tronco_mm.transform_format = MultiMesh.TRANSFORM_3D
	var cil := CylinderMesh.new()
	cil.top_radius = 0.28
	cil.bottom_radius = 0.42
	cil.height = 4.6
	cil.radial_segments = 7
	tronco_mm.mesh = cil

	var copa_mm := MultiMesh.new()
	copa_mm.transform_format = MultiMesh.TRANSFORM_3D
	copa_mm.use_colors = true
	var esf := SphereMesh.new()
	esf.radius = 3.4
	esf.height = 7.2
	esf.radial_segments = 10
	esf.rings = 6
	copa_mm.mesh = esf

	## Posiciones: en el cesped, FUERA de la explanada y fuera del estadio, y
	## alineados a lo largo del vial como una avenida arbolada.
	var sitios: Array = []
	for i in range(210):
		var x := rng.randf_range(-520.0, 520.0)
		var z := rng.randf_range(-380.0, 520.0)
		if absf(x) < 145.0 and z > -275.0 and z < 250.0:
			continue                      # todo el recinto del club
		## NUEVO (12-9-2026): ni encima de las calles ni dentro de las
		## parcelas. Un árbol plantado en mitad de la calzada, o dentro de un
		## solar cercado, delata que las dos cosas se colocaron sin mirarse.
		if absf(absf(x) - RING_X) < ANCHO_CALLE and z > RING_Z_NORTE - 20.0 and z < RING_Z_SUR + 20.0:
			continue
		if absf(z - RING_Z_NORTE) < ANCHO_CALLE or absf(z - RING_Z_SUR) < ANCHO_CALLE:
			continue
		if absf(x - BARRIO_EN.x) < ANCHO_CALLE and z > RING_Z_SUR:
			continue                      # ramal del barrio
		if Vector2(x - BARRIO_EN.x, z - BARRIO_EN.z).length() < 70.0:
			continue                      # el propio barrio
		var en_parcela := false
		for clave: String in PARCELAS:
			var p: Dictionary = PARCELAS[clave]
			var c: Vector2 = p["pos"]
			if absf(x - c.x) < float(p["ancho"]) * 0.5 + 6.0 and absf(z - c.y) < float(p["fondo"]) * 0.5 + 6.0:
				en_parcela = true
				break
		if en_parcela:
			continue
		if x < RIO_X + 55.0 and x > RIO_X - 55.0:
			continue                      # el río
		if _en_frente_urbano(x, z):
			continue                      # las manzanas de edificios
		sitios.append(Vector3(x, 0, z))
	for lado in [-1.0, 1.0]:
		for i in range(9):
			sitios.append(Vector3(lado * 12.5, 0, -55.0 + i * 22.0))

	## ARBOLADO DENTRO DEL RECINTO Y EN LAS PARCELAS (12-9-2026): "las áreas
	## entre los bloques se sienten algo vacías". Tenía razón: los árboles
	## estaban TODOS fuera de la valla, así que el interior -que es donde más
	## se mira- era pavimento pelado. Se plantan en los huecos entre edificios
	## y en el perímetro de cada parcela, esquivando lo que ya hay.
	for i in range(80):
		var x2 := rng.randf_range(-140.0, 140.0)
		var z2 := rng.randf_range(-240.0, 290.0)
		## Ni sobre los campos, ni sobre la avenida, ni encima de un edificio.
		if absf(x2) < 90.0 and z2 > -55.0 and z2 < 70.0:
			continue                      # campos de entrenamiento
		if absf(x2) < 12.0:
			continue                      # avenida de acceso
		if z2 > 100.0 and z2 < 290.0 and absf(fmod(absf(x2) + 37.0, 74.0) - 37.0) < 22.0:
			continue                      # columnas de edificios
		if Vector2(x2, z2 + 150.0).length() < 95.0:
			continue                      # el estadio
		if absf(x2 - 112.0) < 32.0 and z2 > -150.0 and z2 < 10.0:
			continue                      # polideportivo y canchas
		if absf(x2 + 112.0) < 36.0 and z2 > -85.0 and z2 < 60.0:
			continue                      # piscina y huerto
		sitios.append(Vector3(x2, 0, z2))
	## Y una orla de arbolado alrededor de cada parcela, que es lo que las ata
	## al paisaje en vez de dejarlas como pegatinas sobre el césped.
	for clave: String in PARCELAS:
		var pp: Dictionary = PARCELAS[clave]
		var c2: Vector2 = pp["pos"]
		var an: float = float(pp["ancho"]) * 0.5 + 9.0
		var fo: float = float(pp["fondo"]) * 0.5 + 9.0
		for i in range(16):
			var t2: float = float(i) / 16.0 * TAU
			sitios.append(Vector3(c2.x + cos(t2) * an, 0, c2.y + sin(t2) * fo))

	tronco_mm.instance_count = sitios.size()
	copa_mm.instance_count = sitios.size()
	for i in range(sitios.size()):
		var p: Vector3 = sitios[i]
		var esc: float = rng.randf_range(0.75, 1.45)
		var t := Transform3D(Basis().rotated(Vector3.UP, rng.randf() * TAU).scaled(Vector3(esc, esc, esc)),
			p + Vector3(0, 2.3 * esc, 0))
		tronco_mm.set_instance_transform(i, t)
		var tc := Transform3D(Basis().rotated(Vector3.UP, rng.randf() * TAU).scaled(
			Vector3(esc * rng.randf_range(0.85, 1.15), esc, esc * rng.randf_range(0.85, 1.15))),
			p + Vector3(0, 6.2 * esc, 0))
		copa_mm.set_instance_transform(i, tc)
		## Cada copa de un verde distinto: un bosque de un solo verde se lee como
		## papel pintado por muchos arboles que tenga.
		copa_mm.set_instance_color(i, Color(0.14, 0.30, 0.13).lerp(
			Color(0.34, 0.52, 0.20), rng.randf()))

	## Troncos de TODOS los arboles del mapa (MultiMesh), madera real (17-9-2026).
	var mt: StandardMaterial3D = Texturas.madera(Color(0.26, 0.19, 0.13)).duplicate()
	mt.roughness = 0.95
	var mi_t := MultiMeshInstance3D.new()
	mi_t.multimesh = tronco_mm
	mi_t.material_override = mt
	add_child(mi_t)

	## VIENTO EN EL FOLLAJE (13-9-2026): antes un `StandardMaterial3D` fijo
	## dejaba cientos de copas completamente rígidas, lo que más delata una
	## ciudad de maqueta. `follaje_viento.gdshader` hace lo mismo -color por
	## instancia sobre un tinte base, mismo roughness/specular de siempre-
	## pero además mece cada copa con una fase propia sacada de su posición.
	var mc := ShaderMaterial.new()
	mc.shader = load("res://visor/follaje_viento.gdshader")
	## El verde ya viene por copa: con el tinte base encima se multiplicaba dos
	## veces y las copas salían NEGRAS (8-10-2026).
	mc.set_shader_parameter("tinte_base", Color(1.0, 1.0, 1.0))
	var mi_c := MultiMeshInstance3D.new()
	mi_c.multimesh = copa_mm
	mi_c.material_override = mc
	add_child(mi_c)

# ---------------------------------------------------------------- horizonte

## Una ciudad de fondo, lejos del complejo. Antes del horizonte solo habia
## cesped hasta el borde del mundo (2.400 m, ver `_suelo()`): un complejo
## deportivo en mitad de la nada no se lee como parte de una ciudad de
## verdad. Con un puñado de edificios altos y lejanos -nunca dentro del
## recinto- se resuelve barato: son cinco mallas reutilizadas muchas veces,
## no un barrio entero modelado a mano.
##
## RADIO Y ESCALA, LOS DOS AJUSTADOS CON LA CAPTURA, NO A OJO. El primer
## intento los puso a 600-900 m -"la camara nunca pasa de 700 m, un radio
## mayor no se veria"-, y en la captura no se veía NINGUNO: la niebla
## volumétrica de `Calidad.gd` tiene solo 220 m de alcance
## (`volumetric_fog_length`), así que todo lo que queda más lejos se lava
## contra el cielo aunque el motor lo siga dibujando. Con radio 280-430 -justo
## fuera del recinto (que llega a z≈230) pero dentro de la niebla- y una
## escala más alta para que se lean como rascacielos y no como postes, el
## horizonte por fin aparece en la captura.
func _horizonte() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 90210
	var mallas: Array = []
	for ruta in RUTAS_HORIZONTE:
		var esc: PackedScene = load(ruta)
		if esc != null:
			mallas.append(esc)
	if mallas.is_empty():
		return
	## De 10 edificios al fondo con un club modesto a 46 con uno grande: es el
	## indicador más visible de todos, porque el skyline se ve desde cualquier
	## ángulo de cámara.
	var cuantos: int = int(round(lerpf(10.0, 46.0, _empuje_club())))
	for i in range(cuantos):
		var ang: float = rng.randf() * TAU
		## MÁS LEJOS QUE ANTES (12-9-2026): a 280-430 m el horizonte se metía
		## justo encima de las parcelas nuevas -que están a ~300 m- y salían
		## rascacielos plantados dentro de un solar. Ahora empieza donde acaba
		## el mapa jugable.
		## 7-10-2026: con la ciudad grande, el horizonte empieza donde acaba ella.
		var radio: float = rng.randf_range(1560.0, 1950.0)
		var pos := Vector3(sin(ang) * radio, 0, cos(ang) * radio)
		var esc: PackedScene = mallas[rng.randi() % mallas.size()]
		var nodo: Node3D = esc.instantiate()
		if rng.randf() < 0.45:
			tenir(nodo, rng.randi())
		## Y además más ALTOS con el club grande: una ciudad de primera no solo
		## tiene más edificios, los tiene más altos.
		var escala: float = 6.0 * rng.randf_range(0.8, 1.4) * lerpf(0.75, 1.35, _empuje_club())
		nodo.scale = Vector3.ONE * escala
		## Apoyado en la loma, no a y=0: desde que el terreno ondula, un
		## edificio a altura fija queda flotando en la ladera o enterrado hasta
		## el tercer piso, y es de lo primero que canta que el mundo es falso.
		nodo.position = Vector3(pos.x, altura_en(pos.x, pos.z) - 1.0, pos.z)
		nodo.rotation.y = rng.randf() * TAU
		add_child(nodo)
