extends "res://visor/city_builder_p7.gd"
## [Capa 8/12 de `city_builder.gd`] _parking_negocio, _centro_comercial, _clinica, _parcelas, _finca_enredadera, _parque_barrio … (+5)

## El estacionamiento: es subterráneo, así que lo que se ve es la RAMPA de
## bajada y el murete, no un edificio. Dibujar una torre de aparcamiento sería
## contradecir lo que dice el propio negocio.
func _parking_negocio() -> void:
	var pos := Vector3(334.0, 0, -145.0)
	var mat: StandardMaterial3D = Texturas.hormigon(Color(0.26, 0.27, 0.29)).duplicate()
	mat.roughness = 0.7
	var rampa := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(14.0, 0.6, 26.0)
	rampa.mesh = bm
	rampa.material_override = mat
	rampa.position = pos + Vector3(0, -1.2, 0)
	rampa.rotation.x = 0.14
	add_child(rampa)
	for lado in [-1.0, 1.0]:
		var muro := MeshInstance3D.new()
		var mm := BoxMesh.new()
		mm.size = Vector3(1.0, 2.4, 26.0)
		muro.mesh = mm
		muro.material_override = mat
		muro.position = pos + Vector3(lado * 7.5, 0.4, 0)
		add_child(muro)
	_cartel(pos + Vector3(0, 0, 18.0), "Estacionamiento", true)

## El centro comercial: cuatro edificios comerciales CC0 de Kenney (mismo pack
## "City Kit Commercial" que ya da los rascacielos del horizonte) en manzana,
## en vez de una caja lisa. Es LA joya del negocio según el propio juego, así
## que tiene que verse como una manzana entera, no como un galpón.
func _centro_comercial() -> void:
	var base := Vector3(-306.0, 0, 110.0)
	var mallas: Array = []
	for ruta in RUTAS_COMERCIAL:
		var esc: PackedScene = load(ruta)
		if esc != null:
			mallas.append(esc)
	if mallas.is_empty():
		return
	var sitios := [
		Vector3(-38, 0, -52), Vector3(12, 0, -52),
		Vector3(-38, 0, -8), Vector3(12, 0, -8),
		Vector3(-38, 0, 36), Vector3(12, 0, 36),
		Vector3(-38, 0, 72), Vector3(12, 0, 72),
	]
	## VARIEDAD, que era la primera pega del análisis: "los bloques se ven muy
	## idénticos entre sí". Con la misma escala y la misma orientación, ocho
	## edificios distintos siguen leyéndose como ocho copias. Tres cosas lo
	## arreglan casi gratis: cada uno a su altura (la escala en Y va aparte de
	## la del suelo), cada uno mirando a un lado, y la fila retranqueada -unos
	## pegados a la acera y otros metidos hacia dentro-, que es lo que de
	## verdad hace que una manzana parezca crecida y no estampada.
	var rng2 := RandomNumberGenerator.new()
	rng2.seed = 5150
	for i in range(sitios.size()):
		var esc: PackedScene = mallas[i % mallas.size()]
		var nodo: Node3D = esc.instantiate()
		## Los modelos de Kenney vienen en unidades de kit: la escala 6 es la
		## que ya se calibró para el horizonte.
		var base_esc := 6.0
		nodo.scale = Vector3(base_esc * rng2.randf_range(0.88, 1.12),
			base_esc * rng2.randf_range(0.7, 1.55),
			base_esc * rng2.randf_range(0.88, 1.12))
		nodo.position = base + (sitios[i] as Vector3) + Vector3(rng2.randf_range(-5.0, 5.0), 0, 0)
		nodo.rotation.y = (PI * 0.5) * float(rng2.randi() % 4)
		add_child(nodo)

	## El mobiliario de calle entre los dos frentes de la manzana: toldos y
	## parasoles del mismo kit. Es poca cosa y cambia mucho -sin ellos son
	## bloques en una parrilla; con ellos hay una calle comercial.
	var muebles: Array = []
	for ruta2 in RUTAS_MOBILIARIO:
		var e2: PackedScene = load(ruta2)
		if e2 != null:
			muebles.append(e2)
	if not muebles.is_empty():
		for i in range(6):
			var mu: Node3D = (muebles[i % muebles.size()] as PackedScene).instantiate()
			mu.scale = Vector3.ONE * 5.0
			mu.position = base + Vector3(-13.0, 0, -44.0 + i * 24.0)
			mu.rotation.y = PI * 0.5
			add_child(mu)
	_cartel(base + Vector3(0, 0, -92.0), "Centro comercial", true)

## La clínica abierta al público: dentro del recinto (su terreno es la
## periferia, o sea el propio complejo), con la cruz a la vista.
func _clinica() -> void:
	var pos := Vector3(112.0, 0, 45.0)
	var alto := 12.0
	var cuerpo := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(22.0, alto, 17.0)
	cuerpo.mesh = bm
	var mat: StandardMaterial3D = Texturas.hormigon(Color(0.92, 0.93, 0.94)).duplicate()
	mat.roughness = 0.55
	cuerpo.material_override = mat
	cuerpo.position = pos + Vector3(0, alto * 0.5, 0)
	add_child(cuerpo)
	_ventanas(pos, 22.0, 17.0, 2)
	var rojo := StandardMaterial3D.new()
	rojo.albedo_color = Color(0.78, 0.14, 0.14)
	rojo.emission_enabled = true
	rojo.emission = Color(0.78, 0.14, 0.14)
	rojo.emission_energy_multiplier = 0.4
	for par in [Vector3(5.0, 1.2, 0.4), Vector3(1.4, 4.2, 0.4)]:
		var c := MeshInstance3D.new()
		var cbm := BoxMesh.new()
		cbm.size = par
		c.mesh = cbm
		c.material_override = rojo
		c.position = pos + Vector3(0, alto + 3.4, -8.8)
		add_child(c)
	_cartel(pos + Vector3(0, 0, -15.0), "Clínica deportiva", true)

# ---------------------------------------------------------------- parcelas

## Las cinco parcelas del mapa. Una parcela SIN comprar se ve igual de
## delimitada que una comprada -un solar con su cerco y su cartel-, solo que
## en tierra y con el cerco apagado: el jugador tiene que poder ver lo que
## todavía no es suyo, o la pantalla de compra no significa nada.
func _parcelas() -> void:
	var mios: Array = datos.get("terrenos", [])
	var negocios: Dictionary = datos.get("negocios", {})
	for clave: String in PARCELAS:
		var p: Dictionary = PARCELAS[clave]
		var pos: Vector2 = p["pos"]
		var ancho: float = p["ancho"]
		var fondo: float = p["fondo"]
		var mio: bool = mios.has(clave)
		_solar(Vector3(pos.x, 0, pos.y), ancho, fondo, mio)
		_cartel(Vector3(pos.x, 0, pos.y - fondo * 0.5 + 8.0), _nombre_terreno(clave), mio)
		if clave == "ribera":
			_rio()
			if mio:
				_casa_ribera(Vector3(pos.x, 0, pos.y))
		if clave == "sur" and mio:
			_zona_industrial()
	## El recinto del club ES el terreno "periferia" ("fundo en la periferia:
	## perfecto para la ciudad deportiva", dice la tabla), así que lleva cartel
	## dentro en vez de parcela aparte.
	_cartel(Vector3(118.0, 0, 60.0), _nombre_terreno("periferia"), mios.has("periferia"))

	## Y encima de las parcelas, los negocios que ya se construyeron.
	for neg: String in NEGOCIOS_EN_PARCELA:
		if not bool(negocios.get(neg, false)):
			continue
		match neg:
			"hotel": _hotel()
			"parking": _parking_negocio()
			"comercial": _centro_comercial()
			"clinica": _clinica()

## La finca del barrio: muro de 5,5 m cubierto de enredadera, con la copa de
## la hiedra desbordando por arriba (bultos irregulares, no una arista recta),
## un portón de hierro hacia la calle y árboles dentro.
func _finca_enredadera(centro: Vector3, tam: Vector2) -> void:
	var hiedra := Texturas.enredadera()
	var alto := 5.5
	var grosor := 1.2
	var portal := 9.0
	var mitad := tam * 0.5
	## Cuatro lados; el norte (hacia el ramal) con el hueco del portón.
	var lados := [
		{"c": Vector3(0, 0, mitad.y), "t": Vector3(tam.x, alto, grosor)},
		{"c": Vector3(-mitad.x, 0, 0), "t": Vector3(grosor, alto, tam.y)},
		{"c": Vector3(mitad.x, 0, 0), "t": Vector3(grosor, alto, tam.y)},
		{"c": Vector3(-(tam.x + portal) * 0.25, 0, -mitad.y), "t": Vector3((tam.x - portal) * 0.5, alto, grosor)},
		{"c": Vector3((tam.x + portal) * 0.25, 0, -mitad.y), "t": Vector3((tam.x - portal) * 0.5, alto, grosor)},
	]
	var bultos: Array[Transform3D] = []
	var rng := RandomNumberGenerator.new()
	rng.seed = 4401
	for l in lados:
		var t: Vector3 = l["t"]
		var p: Vector3 = centro + (l["c"] as Vector3)
		var mi := MeshInstance3D.new()
		var bm := BoxMesh.new()
		bm.size = t
		mi.mesh = bm
		mi.material_override = hiedra
		mi.position = p + Vector3(0, alto * 0.5, 0)
		add_child(mi)
		## La hiedra que desborda: bultos cada ~2 m por arriba y algunos
		## colgando por las caras.
		var largo: float = maxf(t.x, t.z)
		var eje := Vector3(1, 0, 0) if t.x > t.z else Vector3(0, 0, 1)
		var d := -largo * 0.5 + 1.0
		while d < largo * 0.5 - 0.5:
			var r := rng.randf_range(0.9, 1.5)
			var q := p + eje * d + Vector3(0, alto + rng.randf_range(-0.5, 0.1), 0)
			bultos.append(Transform3D(Basis().scaled(Vector3(r * 1.3, r * 0.8, r * 1.1)), q))
			if rng.randf() < 0.35:
				var lado_c: float = -1.0 if rng.randf() < 0.5 else 1.0
				var normal := Vector3(0, 0, 1) if t.x > t.z else Vector3(1, 0, 0)
				var q2 := p + eje * d + normal * lado_c * grosor * 0.5 + Vector3(0, rng.randf_range(1.0, alto - 1.0), 0)
				bultos.append(Transform3D(Basis().scaled(Vector3(0.9, 1.6, 0.9) * rng.randf_range(0.5, 0.8)), q2))
			d += rng.randf_range(1.6, 2.4)
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	var esf := SphereMesh.new()
	esf.radius = 1.0
	esf.height = 2.0
	esf.radial_segments = 10
	esf.rings = 6
	mm.mesh = esf
	mm.instance_count = bultos.size()
	for k in bultos.size():
		mm.set_instance_transform(k, bultos[k])
	var mmi := MultiMeshInstance3D.new()
	mmi.multimesh = mm
	mmi.material_override = hiedra
	add_child(mmi)
	## Pilares de piedra y portón de hierro.
	var piedra := Texturas.hormigon(Color(0.62, 0.6, 0.56), 77)
	var hierro := StandardMaterial3D.new()
	hierro.albedo_color = Color(0.08, 0.08, 0.09)
	hierro.metallic = 0.7
	hierro.roughness = 0.4
	for s in [-1.0, 1.0]:
		var pil := MeshInstance3D.new()
		var pb := BoxMesh.new()
		pb.size = Vector3(1.6, alto + 0.8, 1.6)
		pil.mesh = pb
		pil.material_override = piedra
		pil.position = centro + Vector3(s * portal * 0.5, (alto + 0.8) * 0.5, -mitad.y)
		add_child(pil)
	var barrotes := int(portal / 0.35)
	for b in barrotes:
		var bar := MeshInstance3D.new()
		var cm := CylinderMesh.new()
		cm.top_radius = 0.035
		cm.bottom_radius = 0.035
		cm.height = alto - 1.0
		bar.mesh = cm
		bar.material_override = hierro
		bar.position = centro + Vector3(-portal * 0.5 + 0.9 + b * (portal - 1.8) / float(maxi(barrotes - 1, 1)), (alto - 1.0) * 0.5, -mitad.y)
		add_child(bar)
	for y in [0.6, alto - 1.2]:
		var trav := MeshInstance3D.new()
		var tb := BoxMesh.new()
		tb.size = Vector3(portal - 1.6, 0.1, 0.08)
		trav.mesh = tb
		trav.material_override = hierro
		trav.position = centro + Vector3(0, y, -mitad.y)
		add_child(trav)
	## Dentro, sobre el propio césped del terreno: árboles que asoman por
	## encima del muro.
	var tronco := StandardMaterial3D.new()
	tronco.albedo_color = Color(0.3, 0.2, 0.12)
	var copa := StandardMaterial3D.new()
	copa.albedo_color = Color(0.13, 0.34, 0.12)
	copa.roughness = 0.9
	for k in 14:
		var pos := centro + Vector3(rng.randf_range(-mitad.x + 5.0, mitad.x - 5.0), 0, rng.randf_range(-mitad.y + 8.0, mitad.y - 5.0))
		var h := rng.randf_range(8.0, 12.0)
		var tr := MeshInstance3D.new()
		var tc := CylinderMesh.new()
		tc.top_radius = 0.3
		tc.bottom_radius = 0.45
		tc.height = h
		tr.mesh = tc
		tr.material_override = tronco
		tr.position = pos + Vector3(0, h * 0.5, 0)
		add_child(tr)
		var cp := MeshInstance3D.new()
		var cs := SphereMesh.new()
		cs.radius = rng.randf_range(3.2, 4.6)
		cs.height = cs.radius * 1.8
		cp.mesh = cs
		cp.material_override = copa
		cp.position = pos + Vector3(0, h, 0)
		add_child(cp)

# ------------------------------------------------------- parques y transporte

## EL PARQUE DEL BARRIO: "faltan parques urbanos o plazas recreativas dentro
## del barrio residencial para que los habitantes tengan zonas de descanso".
## Un césped propio más claro que el campo, caminos en cruz, un estanque y
## arbolado denso: es lo que convierte una hilera de casas en un sitio donde
## se vive.
func _parque_barrio() -> void:
	var centro := BARRIO_EN + Vector3(0, 0, 66.0)
	var cesp := MeshInstance3D.new()
	var pl := PlaneMesh.new()
	pl.size = Vector2(96, 72)
	cesp.mesh = pl
	## `Texturas.cesped()` (17-9-2026): el parque del barrio, y de paso su
	## primer call site en todo el proyecto -estaba escrita y sin conectar.
	var mc: StandardMaterial3D = Texturas.cesped(Color(0.26, 0.50, 0.26)).duplicate()
	mc.roughness = 0.96
	cesp.material_override = mc
	cesp.position = centro + Vector3(0, 0.07, 0)
	add_child(cesp)

	## `Texturas.asfalto()` reutilizado para el camino de tierra compactada
	## -mismo generador de grano/rugosidad, con un tinte claro de arena en vez
	## del gris oscuro habitual.
	var camino: StandardMaterial3D = Texturas.asfalto(Color(0.68, 0.62, 0.52)).duplicate()
	camino.roughness = 0.92
	for l in [
			{"s": Vector3(96.0, 0.06, 4.5), "p": Vector3.ZERO},
			{"s": Vector3(4.5, 0.06, 72.0), "p": Vector3.ZERO},
		]:
		var m := MeshInstance3D.new()
		var bm := BoxMesh.new()
		bm.size = l["s"]
		m.mesh = bm
		m.material_override = camino
		m.position = centro + (l["p"] as Vector3) + Vector3(0, 0.11, 0)
		add_child(m)

	## El estanque, con el mismo shader del río a escala de charca.
	var agua := MeshInstance3D.new()
	var pa := PlaneMesh.new()
	pa.size = Vector2(26, 16)
	pa.subdivide_width = 14
	pa.subdivide_depth = 10
	agua.mesh = pa
	var sh := load(RUTA_SHADER_AGUA)
	if sh != null:
		var sm := ShaderMaterial.new()
		sm.shader = sh
		sm.set_shader_parameter("color_hondo", Color(0.07, 0.20, 0.22))
		sm.set_shader_parameter("color_orilla", Color(0.22, 0.44, 0.44))
		sm.set_shader_parameter("altura_ola", 0.12)
		sm.set_shader_parameter("escala_ola", 0.5)
		sm.set_shader_parameter("velocidad", 0.5)
		agua.material_override = sm
	agua.position = centro + Vector3(-26.0, 0.16, 18.0)
	add_child(agua)
	_cartel(centro + Vector3(0, 0, -40.0), "Parque del barrio", false)

func _barrio_residencial() -> void:
	## LA CASA YA NO SE VE (26-9-2026, pedido del usuario: "esa casa que es
	## un modelo 3D debería ser cubierta por un muro de enredaderas, para que
	## sea más lindo el paisaje sin verla"). Se mide para saber cuánto ocupaba
	## -el barrio se sigue ordenando alrededor de ese solar- y en su lugar va
	## una finca cerrada por un muro cubierto de hiedra, con su portón y
	## árboles que asoman por encima.
	_finca_enredadera(BARRIO_EN, FINCA_TAM)
	## La Casa Grande ya no cabe aquí: tiene finca propia en la ciudad grande
	## (`CiudadExpansion`, 2x2 manzanas al sur del barrio).
	_cartel(Vector3(BARRIO_EN.x + 14.0, 0, FINCA_PORTON_Z - 6.0), "Barrio residencial", false)

	## UN BARRIO ES MÁS DE UNA CASA. Con el complejo solo, aquello era una
	## mansión suelta en mitad del campo al final de una carretera; con una
	## hilera de casas a cada lado de la calle se lee como el vecindario con el
	## que el club comparte esquina, que es lo que el usuario pidió. Se
	## reutilizan los edificios CC0 de Kenney -los mismos del centro comercial-
	## a menos escala, que a este tamaño pasan por casas de barrio.
	var casas: Array = []
	for ruta in RUTAS_COMERCIAL:
		var e2: PackedScene = load(ruta)
		if e2 != null:
			casas.append(e2)
	if casas.is_empty():
		return
	## EL BARRIO CRECE CON LOS SOCIOS. No con la reputación: son los socios los
	## que viven al lado del club, y es el número que sube cuando la gente se
	## engancha. De 3 casas por acera a 8 -con 60.000 socios, el barrio entero-.
	var socios := float(datos.get("club", {}).get("socios", 8000))
	var por_acera: int = clampi(3 + int(socios / 9000.0), 3, 8)
	## Igual que la manzana comercial: cada casa a su altura, con su retranqueo
	## y mirando a su lado. Un barrio de casas clónicas alineadas a tiralíneas
	## se lee como un polígono, no como un barrio.
	var rng3 := RandomNumberGenerator.new()
	rng3.seed = 9012
	var k := 0
	for lado in [-1.0, 1.0]:
		for i in range(por_acera):
			var esc2: PackedScene = casas[k % casas.size()]
			var casa: Node3D = esc2.instantiate()
			var e3 := 3.2
			casa.scale = Vector3.ONE * e3 * rng3.randf_range(0.85, 1.2)
			casa.position = BARRIO_EN + Vector3(
				lado * rng3.randf_range(42.0, 52.0), 0, -60.0 + i * 30.0 + rng3.randf_range(-4.0, 4.0))
			casa.rotation.y = ((PI * 0.5) if lado < 0.0 else (-PI * 0.5)) + rng3.randf_range(-0.12, 0.12)
			add_child(casa)
			k += 1
	_parque_barrio()

## ============================================================================
##  LA CIUDAD CRECE CON EL CLUB (12-9-2026)
## ============================================================================
##
## La idea, en una frase: **si el club sube, la ciudad se nota**. Un club de
## reputación 30 está en un pueblo con cuatro edificios al fondo; uno de 90
## está en una ciudad con skyline, barrio grande y tráfico. No hace falta un
## sistema nuevo -la reputación y los socios ya existen y ya suben solos con
## los títulos-, hace falta que el mapa los LEA.
##
## Por qué importa más de lo que parece: hasta ahora ganar la liga cambiaba una
## tabla. Con esto, ganar la liga se ve desde la ventanilla del coche.

## 0 con reputación 20 o menos, 1 con 90 o más. Es la curva que decide cuánta
## ciudad hay alrededor.
func _empuje_club() -> float:
	var rep := float(datos.get("club", {}).get("rep", 50))
	return clampf((rep - 20.0) / 70.0, 0.0, 1.0)

## ¿Hay algo en este punto de la acera que no se puede tapar? El ramal del
## barrio, los ramales de las parcelas (con su solar) y el río.
func _hueco_urbano(eje: Vector3, afuera: Vector3, fondo: float) -> bool:
	var lejos: Vector3 = eje + afuera * (fondo + 30.0)
	if absf(eje.z - RING_Z_SUR) < 1.0 and absf(eje.x - BARRIO_EN.x) < 70.0:
		return true
	if absf(eje.z - RING_Z_SUR) < 1.0 and absf(eje.x - KARTING_EN.x) < ANCHO_CALLE + 6.0:
		return true                   # el acceso al karting
	## Los cruces con la circunvalación exterior (z = -282 y z = 262).
	if absf(absf(eje.x) - RING_X) < 1.0 and (absf(eje.z - EX_N) < ANCHO_CALLE + 6.0 or absf(eje.z - EX_S) < ANCHO_CALLE + 6.0):
		return true
	for clave: String in PARCELAS:
		var p: Dictionary = PARCELAS[clave]
		var c: Vector2 = p["pos"]
		var r := Rect2(c.x - float(p["ancho"]) * 0.5, c.y - float(p["fondo"]) * 0.5, float(p["ancho"]), float(p["fondo"])).grow(14.0)
		## El ramal que la ata al anillo corre a la altura de su centro.
		if absf(eje.z - c.y) < ANCHO_CALLE + 6.0 and signf(eje.x) == signf(c.x) and absf(eje.x) > RING_X - 1.0:
			return true
		if r.has_point(Vector2(eje.x, eje.z)) or r.has_point(Vector2(lejos.x, lejos.z)):
			return true
	if lejos.x < RIO_X + 60.0 and lejos.x > RIO_X - 60.0:
		return true
	return false

func altura_en(x: float, z: float) -> float:
	if _ruido_terreno == null:
		return 0.0
	return _altura_terreno(x, z, _ruido_terreno, _ruido_detalle)

func _rect_de(c: Vector3, dir: Vector3, ancho: float, fondo: float) -> Rect2:
	var ex: float = ancho if absf(dir.x) > 0.5 else fondo
	var ez: float = fondo if absf(dir.x) > 0.5 else ancho
	return Rect2(c.x - ex * 0.5, c.z - ez * 0.5, ex, ez)
