extends "res://visor/city_builder_p5.gd"
## (Parte 6 de 12 de `city_builder.gd`.)

# ---------------------------------------------------------------- edificios

func _complejo() -> void:
	## Solo se levanta lo CONSTRUIDO: una instalacion a nivel 0 no existe todavia y
	## no debe aparecer, o el complejo se veria igual de lleno el primer dia que en
	## la temporada quince y la inversion no se notaria.
	var inst: Dictionary = datos.get("inst", {})
	var obras: Array = datos.get("obras", [])
	var enObra := {}
	for o in obras:
		enObra[str(o.get("k", ""))] = int(o.get("semanas", 0))

	## SITIO FIJO POR INSTALACIÓN (B7). Antes se compactaban solo las
	## construidas y un edificio cambiaba de sitio al levantar otro; ahora cada
	## una tiene su parcela, y la que no existe todavía se ve como SOLAR con su
	## cartel: es lo que permite construir desde el mapa.
	var i := -1
	for e in EDIFICIOS:
		i += 1
		var niv := int(inst.get(e["k"], 0))
		var obra: bool = enObra.has(e["k"])
		## Cuatro por fila y no cinco: con cinco la parrilla se salia de la valla por
		## el lado, y un complejo con edificios fuera del recinto no se lee como un
		## complejo, se lee como un error de colocacion.
		## Cuatro por fila como siempre, pero con el DOBLE de separación: los
		## edificios pasaron de 9-16 m a 19-34 m de fachada y con la parrilla
		## vieja (42 x 32 m) se solapaban unos con otros.
		var fila := i / 4
		var col := i % 4
		var x := -111.0 + col * 74.0
		## B7: filas cada 43 m desde z=108. Con 48 desde 118 la cuarta fila
		## (que ahora siempre existe, como solares) caía encima de la calle
		## exterior de z=262.
		var z := FILA_0_Z + fila * FILA_PASO
		var pos := Vector3(x, 0, z)
		if niv <= 0 and not obra:
			_solar_libre(e, pos)
			continue
		_edificio(e, niv, obra, pos)
		if obra:
			var total := float(Instalaciones.SEMANAS.get(String(e["k"]), Instalaciones.SEMANAS_POR_DEFECTO))
			var faltan := float(enObra[e["k"]])
			_obra_en_curso(pos, float(e["ancho"]), float(e["fondo"]), 6.0 * maxi(1, niv + 1), 1.0 - faltan / maxf(total, 1.0))
		var texto_r: String = ("%s 🏗 %d sem" % [str(e["n"]), int(enObra[e["k"]])]) if obra else ("%s  N%d" % [str(e["n"]), niv])
		_rotulo(pos + Vector3(0, 6.0 * maxi(1, niv) + 8.0, 0), texto_r,
			Color(1.0, 0.85, 0.4) if obra else Color(1, 1, 1))
		puntos_clic.append({"k": String(e["k"]), "n": str(e["n"]), "pos": pos + Vector3(0, 6.0 * maxi(1, niv) * 0.5, 0),
			"estado": "obra" if obra else "hecho"})
	_campus()

## El cartel de una parcela: un poste y el nombre en grande. `Label3D` y no una
## textura: se lee desde cualquier ángulo (mira siempre a la cámara) y no hay
## que rasterizar nada. El tamaño es de MAPA -letras de ~9 m- porque la cámara
## por defecto está a 470 m: a tamaño de cartel real no se leería ninguno.
func _cartel(pos: Vector3, texto: String, mio: bool) -> void:
	var poste := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = 0.5
	cm.bottom_radius = 0.6
	cm.height = 16.0
	poste.mesh = cm
	var pm: StandardMaterial3D = Texturas.metal(Color(0.32, 0.33, 0.35), 0.6).duplicate()
	pm.metallic = 0.3
	poste.mesh.material = pm
	poste.position = pos + Vector3(0, 8.0, 0)
	add_child(poste)

	var l := Label3D.new()
	l.text = texto
	## Letras de ~5 m: a la altura de cámara del mapa (165 m) se leen sin
	## esfuerzo, y al bajar a mirar una parcela de cerca no tapan el edificio.
	## A 9 m -el primer intento- los carteles eran más anchos que su parcela.
	l.font_size = 36
	l.pixel_size = 0.14
	l.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	l.modulate = Color(1, 1, 1) if mio else Color(0.85, 0.85, 0.88)
	l.outline_size = 14
	l.outline_modulate = Color(0.06, 0.08, 0.07, 0.9)
	l.no_depth_test = false
	l.position = pos + Vector3(0, 21.0, 0)
	add_child(l)

## El huerto: bancales de cultivo en hileras y un invernadero al lado. Cuántos
## bancales salen depende del nivel, igual que las plantas de un edificio: es
## la misma promesa de siempre -lo que construyes se VE-, solo que aquí crece
## a lo ancho porque un huerto no tiene pisos.
func _huerto() -> void:
	var niv := int(datos.get("inst", {}).get("huerto", 0))
	if niv <= 0:
		return
	var hileras: int = clampi(niv * 2, 2, 10)

	var tierra: StandardMaterial3D = Texturas.hormigon(Color(0.32, 0.23, 0.16)).duplicate()
	tierra.roughness = 0.98
	var planta := StandardMaterial3D.new()
	planta.albedo_color = Color(0.28, 0.52, 0.20)
	planta.roughness = 0.9

	for i in range(hileras):
		var z: float = HUERTO_EN.z - (hileras - 1) * 2.4 + i * 4.8
		var bancal := MeshInstance3D.new()
		var bm := BoxMesh.new()
		bm.size = Vector3(26.0, 0.5, 3.0)
		bancal.mesh = bm
		bancal.material_override = tierra
		bancal.position = Vector3(HUERTO_EN.x, 0.25, z)
		add_child(bancal)
		## La mata de encima, en cubos bajos: a la altura de cámara del mapa,
		## un bancal de tierra pelada y uno plantado tienen que distinguirse.
		var mata := MeshInstance3D.new()
		var mm := BoxMesh.new()
		mm.size = Vector3(24.0, 0.9, 1.9)
		mata.mesh = mm
		mata.material_override = planta
		mata.position = Vector3(HUERTO_EN.x, 0.9, z)
		add_child(mata)

	## El invernadero: cristal de verdad -el mismo material translúcido que
	## usan las ventanas de los edificios- sobre un zócalo claro.
	var inv := MeshInstance3D.new()
	var im := BoxMesh.new()
	im.size = Vector3(10.0, 5.0, 14.0)
	inv.mesh = im
	var cristal := StandardMaterial3D.new()
	cristal.albedo_color = Color(0.72, 0.88, 0.80, 0.45)
	cristal.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	cristal.metallic = 0.5
	cristal.roughness = 0.12
	inv.material_override = cristal
	inv.position = HUERTO_EN + Vector3(-22.0, 2.5, 0)
	add_child(inv)
	_cartel(HUERTO_EN + Vector3(0, 0, -(hileras * 2.4 + 10.0)), "Huerto del club", true)

# ---------------------------------------------------------- deporte de verdad
#
# "Para potenciar el concepto de CIUDAD DEPORTIVA, sumar un polideportivo
# cerrado, una piscina olímpica o canchas secundarias" -del análisis que trajo
# el usuario, y es la pega más justa de todas: un complejo con cuatro cajas de
# oficinas y unos campos de fútbol es una sede administrativa, no una ciudad
# deportiva. Las tres cosas van atadas a instalaciones que YA existen en
# `Instalaciones.CATALOGO`, así que aparecen cuando las construyes y no antes.

## La piscina olímpica: 50 x 25 m reales, con sus ocho calles marcadas y el
## borde de playa. Sale del nivel de `piscina`.
func _piscina_olimpica() -> void:
	if int(datos.get("inst", {}).get("piscina", 0)) <= 0:
		return
	var centro := Vector3(-112.0, 0, -60.0)

	var borde := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(62.0, 0.4, 37.0)
	borde.mesh = bm
	## El borde de la piscina, hormigon real (17-9-2026).
	var mb: StandardMaterial3D = Texturas.hormigon(Color(0.86, 0.86, 0.83)).duplicate()
	mb.roughness = 0.85
	borde.material_override = mb
	borde.position = centro + Vector3(0, 0.2, 0)
	add_child(borde)

	var agua := MeshInstance3D.new()
	var pl := PlaneMesh.new()
	pl.size = Vector2(50, 25)
	## Subdividido para que el shader del agua tenga vértices que mover: es la
	## misma trampa que ya se pagó con el río.
	pl.subdivide_width = 26
	pl.subdivide_depth = 14
	agua.mesh = pl
	var sh := load(RUTA_SHADER_AGUA)
	if sh != null:
		var sm := ShaderMaterial.new()
		sm.shader = sh
		## Agua de piscina: turquesa, casi sin ola -una piscina no tiene
		## oleaje de río- y con la escala de onda mucho más fina.
		sm.set_shader_parameter("color_hondo", Color(0.05, 0.34, 0.44))
		sm.set_shader_parameter("color_orilla", Color(0.30, 0.70, 0.78))
		sm.set_shader_parameter("altura_ola", 0.09)
		sm.set_shader_parameter("escala_ola", 0.42)
		sm.set_shader_parameter("velocidad", 0.9)
		agua.material_override = sm
	agua.position = centro + Vector3(0, 0.45, 0)
	add_child(agua)

	## Las ocho calles: corcheras a lo largo. Sin ellas es un estanque azul.
	var corchera := StandardMaterial3D.new()
	corchera.albedo_color = Color(0.92, 0.72, 0.18)
	corchera.roughness = 0.7
	for i in range(7):
		var c := MeshInstance3D.new()
		var cbm := BoxMesh.new()
		cbm.size = Vector3(50.0, 0.22, 0.3)
		c.mesh = cbm
		c.material_override = corchera
		c.position = centro + Vector3(0, 0.6, -10.9 + i * 3.12)
		add_child(c)
	_cartel(centro + Vector3(0, 0, -24.0), "Piscina olímpica", true)

## El polideportivo: una nave con cubierta curva -lo que de lejos distingue un
## pabellón de una caja de oficinas-. Sale del nivel de `gim`.
func _polideportivo() -> void:
	if int(datos.get("inst", {}).get("gim", 0)) < 2:
		return
	var centro := Vector3(112.0, 0, -130.0)
	## Hormigon real (17-9-2026).
	var muro: StandardMaterial3D = Texturas.hormigon(Color(0.80, 0.81, 0.83)).duplicate()
	muro.roughness = 0.6
	var cuerpo := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(46.0, 11.0, 30.0)
	cuerpo.mesh = bm
	cuerpo.material_override = muro
	cuerpo.position = centro + Vector3(0, 5.5, 0)
	add_child(cuerpo)
	_ventanas(centro, 46.0, 30.0, 1)

	## La cubierta curva, hecha con medio cilindro tumbado. Es LA silueta de un
	## pabellón: sin ella, esto sería otra caja más del complejo.
	var techo := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = 15.5
	cm.bottom_radius = 15.5
	cm.height = 46.0
	cm.radial_segments = 22
	techo.mesh = cm
	## Cubierta metalica real (17-9-2026), duplicada para conservar el color
	## mezclado con el del club y el metalico ya afinado.
	var mt: StandardMaterial3D = Texturas.metal(
		_color_club("c1", Color(0.2, 0.5, 0.3)).lerp(Color(0.75, 0.76, 0.78), 0.45), 0.45).duplicate()
	mt.metallic = 0.35
	techo.material_override = mt
	techo.position = centro + Vector3(0, 11.0, 0)
	techo.rotation = Vector3(0, 0, PI * 0.5)
	techo.scale = Vector3(1.0, 1.0, 0.42)
	add_child(techo)
	_cartel(centro + Vector3(0, 0, -20.0), "Polideportivo", true)

## Canchas de tenis y pádel, en batería. Salen del nivel del centro de
## entrenamiento: son las "canchas secundarias" que pedía el análisis.
func _canchas_secundarias() -> void:
	var niv := int(datos.get("inst", {}).get("ct", 0))
	if niv < 2:
		return
	var cuantas: int = clampi(niv, 2, 6)
	var base := Vector3(112.0, 0, -20.0)
	var suelo := StandardMaterial3D.new()
	suelo.albedo_color = Color(0.32, 0.44, 0.58)
	suelo.roughness = 0.9
	var linea := StandardMaterial3D.new()
	linea.albedo_color = Color(0.94, 0.94, 0.92)
	linea.roughness = 0.8
	## Es tela de verdad -una red de tenis-, no plastico (17-9-2026).
	var red: StandardMaterial3D = Texturas.tela(Color(0.16, 0.17, 0.18)).duplicate()
	red.roughness = 0.85
	for i in range(cuantas):
		var c := base + Vector3((i % 2) * 26.0 - 13.0, 0, (i / 2) * 18.0)
		var pista := MeshInstance3D.new()
		var pl := PlaneMesh.new()
		pl.size = Vector2(22, 14)
		pista.mesh = pl
		pista.material_override = suelo
		pista.position = c + Vector3(0, 0.05, 0)
		add_child(pista)
		## Líneas y red: cuatro cajas finas. A la escala del mapa es justo lo
		## que hace falta para que se lea "cancha" y no "rectángulo azul".
		for l in [
				{"s": Vector3(18.0, 0.03, 0.2), "p": Vector3(0, 0, -4.6)},
				{"s": Vector3(18.0, 0.03, 0.2), "p": Vector3(0, 0, 4.6)},
				{"s": Vector3(0.2, 0.03, 9.4), "p": Vector3(-9.0, 0, 0)},
				{"s": Vector3(0.2, 0.03, 9.4), "p": Vector3(9.0, 0, 0)},
			]:
			var m := MeshInstance3D.new()
			var bm2 := BoxMesh.new()
			bm2.size = l["s"]
			m.mesh = bm2
			m.material_override = linea
			m.position = c + (l["p"] as Vector3) + Vector3(0, 0.08, 0)
			add_child(m)
		var neta := MeshInstance3D.new()
		var nm := BoxMesh.new()
		nm.size = Vector3(0.12, 1.05, 9.6)
		neta.mesh = nm
		neta.material_override = red
		neta.position = c + Vector3(0, 0.55, 0)
		add_child(neta)
	_cartel(base + Vector3(0, 0, -14.0), "Tenis y pádel", true)

static func flota_coches() -> Array:
	var pool: Array = []
	for par in [[RUTA_COCHE_REAL_1, "res://assets/ciudad/Car Texture 1.png"], [RUTA_COCHE_REAL_2, "res://assets/ciudad/Car Texture 2.png"]]:
		if ResourceLoader.exists(par[0]):
			var e: PackedScene = load(par[0])
			if e != null:
				var tex: Texture2D = load(par[1]) if ResourceLoader.exists(par[1]) else null
				## Pesan como cuatro Kenney cada uno: son los que más se ven.
				for _r in range(4):
					pool.append({"esc": e, "escala": 1.1, "fbx": true, "tex": tex})
	for ruta in RUTAS_COCHES_KENNEY:
		var kc: PackedScene = load(ruta)
		if kc != null:
			pool.append({"esc": kc, "escala": 1.65, "fbx": false})
	return pool

## La caja de todas las mallas de un nodo que no está en el árbol.
static func _caja_local(n: Node, t: Transform3D) -> AABB:
	var caja := AABB()
	var hay := false
	var tt := t * (n as Node3D).transform if n is Node3D else t
	if n is MeshInstance3D and (n as MeshInstance3D).mesh != null:
		caja = tt * (n as MeshInstance3D).mesh.get_aabb()
		hay = true
	for h in n.get_children():
		var c := _caja_local(h, tt)
		if c.size != Vector3.ZERO:
			caja = c if not hay else caja.merge(c)
			hay = true
	return caja

static func escala_real(esc: PackedScene) -> Vector3:
	var ruta := esc.resource_path
	if _escalas_reales.has(ruta):
		return _escalas_reales[ruta]
	var nombre := ruta.get_file().get_basename()
	var res := Vector3.ONE * 1.65
	if MEDIDAS_REALES.has(nombre):
		var tmp: Node3D = esc.instantiate()
		var caja := _caja_local(tmp, Transform3D.IDENTITY)
		tmp.free()
		if caja.size.x > 0.01 and caja.size.y > 0.01 and caja.size.z > 0.01:
			var m: Vector3 = MEDIDAS_REALES[nombre]
			res = Vector3(m.x / caja.size.x, m.y / caja.size.y, m.z / caja.size.z)
			res.y = maxf(res.y, res.z * 0.72)
			res.x = maxf(res.x, res.z * 0.6)
	_escalas_reales[ruta] = res
	return res

## Un coche de la flota, ya con el morro hacia +Z y a su escala.
static func instanciar_coche(par: Dictionary, rng: RandomNumberGenerator = null) -> Node3D:
	var modelo: Node3D = (par["esc"] as PackedScene).instantiate()
	if not bool(par.get("fbx", false)):
		modelo.scale = escala_real(par["esc"])
		return modelo
	var raiz := Node3D.new()
	raiz.add_child(modelo)
	## Z arriba -> Y arriba (90° en X) y morro de -X a +Z (90° en Y).
	modelo.basis = Basis(Vector3.UP, PI * 0.5) * Basis(Vector3.RIGHT, PI * 0.5)
	raiz.scale = Vector3.ONE * float(par["escala"])
	var mat := StandardMaterial3D.new()
	if par.get("tex") != null:
		mat.albedo_texture = par["tex"]
	## Cada coche de un color: la textura lleva el detalle y el tinte la pintura.
	var tintes := [Color.WHITE, Color(0.85, 0.2, 0.18), Color(0.2, 0.35, 0.75), Color(0.2, 0.2, 0.22), Color(0.75, 0.75, 0.78), Color(0.9, 0.75, 0.2), Color(0.25, 0.5, 0.3)]
	if rng != null:
		mat.albedo_color = tintes[rng.randi() % tintes.size()]
	mat.roughness = 0.35
	mat.metallic = 0.3
	for mi in modelo.find_children("*", "MeshInstance3D", true, false):
		(mi as MeshInstance3D).material_override = mat
	return raiz

## En dos hileras a lo largo del vial de acceso, con el brazo hacia la calzada.
func _farolas() -> void:
	for i in range(9):
		for lado in [-1.0, 1.0]:
			## El brazo mira SIEMPRE hacia el eje de la calle: una farola con el
			## brazo hacia el campo alumbra el césped y deja la calzada a
			## oscuras, que es justo al revés de para lo que está.
			_una_farola(Vector3(lado * 11.0, 0, -60.0 + i * 42.0),
				(PI * 0.5) if lado < 0.0 else (-PI * 0.5))

func _aparcamiento() -> void:
	## Los coches salen del nivel de 'park': el jugador invierte en accesos y ve
	## el aparcamiento llenarse. Sin nivel, un par de coches del personal.
	##
	## AHORA CON VARIEDAD: a los dos FBX de siempre se suman los 7 GLB CC0 de
	## Kenney (`RUTAS_COCHES_KENNEY`). Cada fuente trae su propia escala -las
	## dos FBX ya estaban calibradas a 1.4-, y la de Kenney se ajustó aparte
	## con `captura_ciudad.gd` porque su pack no viene a la misma escala que
	## el resto de props de este proyecto.
	##
	## SOLO KENNEY DESDE EL 25-9-2026: `coche1.fbx`/`coche2.fbx` no tienen licencia
	## verificada (ver `LICENCIAS.md`) y los 7 de Kenney son CC0. Las versiones
	## publicables ni siquiera los llevan (`export_presets.cfg`).
	var pool: Array = flota_coches()
	if pool.is_empty():
		return
	var niv := int(datos.get("inst", {}).get("park", 0))
	var n: int = clampi(2 + niv * 4, 2, 22)
	var rng := RandomNumberGenerator.new()
	rng.seed = 45021

	## LAS PLAZAS PINTADAS. Sin ellas, los coches parecían abandonados sobre
	## una plancha de asfalto; con las líneas se entiende que eso es un
	## aparcamiento aunque esté medio vacío -que es justo lo que cuenta el
	## nivel de la instalación-.
	var pintura := StandardMaterial3D.new()
	pintura.albedo_color = Color(0.88, 0.88, 0.84)
	pintura.roughness = 0.8
	for fila in range(2):
		for col in range(8):
			var m := MeshInstance3D.new()
			var bm := BoxMesh.new()
			bm.size = Vector3(0.25, 0.04, 5.2)
			m.mesh = bm
			m.material_override = pintura
			m.position = Vector3(94.5 + col * 5.5, 0.06, -62.0 + fila * 8.0)
			add_child(m)
	for i in range(n):
		var par: Dictionary = pool[rng.randi() % pool.size()]
		var nodo: Node3D = instanciar_coche(par, rng)
		## Al este del acceso, entre el estadio y los campos: es donde de verdad
		## aparca la gente un día de partido, junto a la puerta.
		var fila := i / 7
		var col := i % 7
		nodo.position = Vector3(97.0 + col * 5.5, 0, -62.0 + fila * 8.0)
		## A lo largo de la plaza pintada (que corre en Z), unos de frente y
		## otros marcha atrás, como aparca la gente de verdad.
		nodo.rotation.y = 0.0 if rng.randf() < 0.6 else PI
		add_child(nodo)
	## Las dos plazas VIP junto a la puerta: los deportivos del kit (el del
	## presidente y el de la estrella del equipo).
	for k in 2:
		_poner_extra(["race", "race-future"][k], Vector3(141.0, 0, -62.0 + k * 8.0), 1.65, PI)
	_rotulo(Vector3(141.0, 4.0, -58.0), "VIP", Color(1.0, 0.85, 0.4), 22)

	_farolas()
