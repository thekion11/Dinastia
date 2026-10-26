extends "res://visor/metro_ciudad_p1.gd"
## [Capa 2/4 de `metro_ciudad.gd`] _kenney, _tam_lon, _amueblar_anden, _decorar_estacion, linea, _panel … (+3)

## Una pieza del kit, a escala, mirando hacia `mira` (su +Z), y con
## distancia de dibujo para no cargar la ciudad.
func _kenney(clave: String, pos: Vector3, mira: Vector3, padre: Node3D = null, rango: float = 140.0) -> Node3D:
	var info: Array = PIEZAS_ANDEN[clave]
	var ruta := KENNEY + String(info[0]) + ".glb"
	if not _escenas.has(ruta):
		_escenas[ruta] = load(ruta) if ResourceLoader.exists(ruta) else null
	var ps: PackedScene = _escenas[ruta]
	if ps == null:
		return null
	var n: Node3D = ps.instantiate()
	n.scale = Vector3.ONE * float(info[1])
	n.position = pos
	n.rotation.y = atan2(mira.x, mira.z)
	for mi: MeshInstance3D in n.find_children("*", "MeshInstance3D", true, false):
		mi.visibility_range_end = rango
	(padre if padre != null else self).add_child(n)
	return n

## Una caja de tamaño `t` (x = ancho, z = grosor) puesta de cara a lo largo de `lon`.
static func _tam_lon(lon: Vector3, t: Vector3) -> Vector3:
	return t if absf(lon.z) > 0.5 else Vector3(t.z, t.y, t.x)

## Amuebla un andén. `fondo`: punto de la pared del fondo a la altura 0;
## `hacia`: de la pared hacia la vía; `y`: altura del suelo del andén.
## Medidas (desde la pared): bancos a 0,6 m, papeleras y plantas a 0,5 m; la
## gente de pie, a 1,8-2,6 m de la franja amarilla. Nada en los pilares de la
## marquesina (±9 y ±27 a lo largo) ni en la llegada de la escalera (+25..+30).
func _amueblar_anden(p: Vector3, fondo: Vector3, hacia: Vector3, lon: Vector3, y: float, nombre: String, col: Color, elevada: bool) -> void:
	var base := fondo + Vector3(0, y, 0)
	var en := func(db: float, f: float) -> Vector3: return base + hacia * db + lon * f
	## Hasta el borde del andén (franja amarilla incluida).
	var ancho := (ANDEN_ANCHO - 0.15) if elevada else (2.0 + 8.0 - 0.45 - 2.0)
	var sitios: Array = []
	## Máquinas de billetes y expendedora, al lado del plano de la red.
	_kenney("expendedora", en.call(0.65, -25.6), hacia)
	_kenney("billetes", en.call(0.5, -23.6), hacia)
	_kenney("billetes", en.call(0.5, -22.6), hacia)
	## Bancos de espaldas a la pared, papeleras entre ellos y plantas grandes.
	for f: float in [-12.0, -4.0, 4.0, 12.0]:
		## El banco del kit mira a su -Z (el respaldo queda en +Z): de espaldas a
		## la pared hay que girarlo hacia la pared.
		_kenney("banco", en.call(0.6, f), -hacia)
		for s: float in [-0.42, 0.42]:
			sitios.append({"p": en.call(0.6 + BANCO_FONDO, f + s), "giro": atan2(hacia.x, hacia.z), "sentado": true})
	for f: float in [-8.0, 8.0]:
		_kenney("papelera", en.call(0.45, f), hacia)
	for f: float in [-19.6, 19.6]:
		_kenney("planta", en.call(0.45, f), hacia)
	if not elevada:
		_kenney("planta", en.call(0.45, -29.0), hacia)
		_kenney("papelera", en.call(0.45, 27.0), hacia)
	## Pantallas del próximo tren colgadas del techo, de dos caras (una mira a
	## cada punta del andén).
	var techo := (y + 4.35) if elevada else (PROF_TUNEL + 6.2)
	for f: float in [-6.0, 14.0]:
		var c: Vector3 = en.call(ancho * 0.45, f)
		var alto_p := y + 2.75
		## Caja negra con dos pantallas (la tele del kit traía su pie de mesa).
		_caja(self, Vector3(c.x, alto_p + 0.45, c.z), _tam_lon(lon, Vector3(1.5, 0.82, 0.16)), _mat(Color(0.08, 0.08, 0.09), 0.4))
		for s: float in [-1.0, 1.0]:
			_caja(self, Vector3(c.x, alto_p + 0.45, c.z) + lon * s * 0.085, _tam_lon(lon, Vector3(1.36, 0.68, 0.01)), _mat(Color(0.05, 0.1, 0.22), 0.2, 0.6))
			var lab := Label3D.new()
			lab.font_size = 28
			lab.pixel_size = 0.0042
			lab.modulate = Color(1.0, 0.78, 0.25)
			lab.outline_size = 0
			lab.double_sided = false
			lab.width = 300.0
			lab.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			lab.position = Vector3(c.x, alto_p + 0.45, c.z) + lon * s * 0.1
			lab.rotation.y = atan2(lon.x * s, lon.z * s)
			lab.visibility_range_end = 60.0
			add_child(lab)
			_paneles.append({"label": lab, "linea_n": "", "s": 0.0, "pantalla": true, "est": nombre, "elevada": elevada})
		## Las varillas que la cuelgan.
		for s2: float in [-0.45, 0.45]:
			var lado_v := hacia.cross(Vector3.UP).normalized()
			var largo_v := techo - (alto_p + 0.86)
			_caja(self, Vector3(c.x, alto_p + 0.86 + largo_v * 0.5, c.z) + lado_v * s2, Vector3(0.04, largo_v, 0.04), _mat(Color(0.3, 0.3, 0.32), 0.4))
	## Gente de pie esperando: cerca del borde (sin pisar la franja), unos
	## sueltos mirando a la vía y algunas parejas charlando.
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(nombre) + (7 if elevada else 0) + int(absf(fondo.x) + absf(fondo.z))
	var usados: Array = []
	for k in 7:
		var f := rng.randf_range(-24.0, 22.0)
		for _intento in 6:
			var libre := true
			for u: float in usados:
				if absf(u - f) < 2.2:
					libre = false
			if libre:
				break
			f = rng.randf_range(-24.0, 22.0)
		usados.append(f)
		## Ni delante de la escalera ni pegados a las pantallas.
		var db := ancho - rng.randf_range(1.0, 1.9)
		var giro := atan2(hacia.x, hacia.z) + rng.randf_range(-0.5, 0.5)
		if k % 3 == 2:
			## Pareja: dos de cara, a 0,9 m.
			var g2 := atan2(lon.x, lon.z)
			sitios.append({"p": en.call(db, f - 0.45), "giro": g2, "sentado": false, "charla": true})
			sitios.append({"p": en.call(db, f + 0.45), "giro": g2 + PI, "sentado": false, "charla": true})
		else:
			sitios.append({"p": en.call(db, f), "giro": giro, "sentado": false})
	## La salida del andén (la llegada de la escalera, +25..+30 a lo largo):
	## por ahí se van los que bajan del tren y llegan los que vienen a esperar.
	var centro: Vector3 = base + hacia * (ancho * 0.5)
	_sitios.append({"centro": centro, "clave": "%s|%s|%d" % [nombre, str(elevada), int(fondo.x + fondo.z)],
		"sitios": sitios, "elevada": elevada, "col": col, "p": p, "salida": centro + lon * 27.5})

func _decorar_estacion(p: Vector3, dir: Vector3, col: Color, nombre: String, elevada: bool) -> void:
	var vertical := absf(dir.z) > 0.5
	var lat := Vector3(1, 0, 0) if vertical else Vector3(0, 0, 1)
	var lon := Vector3(0, 0, 1) if vertical else Vector3(1, 0, 0)
	var tema: Array = TEMAS.get(nombre, ["Ⓜ", col, ""])
	var tcol: Color = tema[1]
	var y := (ALTO_VIADUCTO + 0.6 + PISO_COCHE) if elevada else (PROF_TUNEL + PISO_COCHE)
	## Lado del andén donde va el mural: en la subterránea, la pared del fondo
	## del vestíbulo; en la elevada, un panel en cada andén (de espaldas a la vía).
	var lados: Array = [1.0, -1.0] if elevada else [1.0]
	for lado: float in lados:
		var fondo := p + lat * lado * ((ANDEN_LAT + ANDEN_ANCHO * 0.5 - 0.15) if elevada else (2.0 + 8.0 - 0.45))
		var hacia := -lat * lado
		## El mural: tres paneles del color del tema con el icono y el lema.
		for k in 3:
			var c := fondo + lon * (float(k) - 1.0) * 16.0 + Vector3(0, y + (1.7 if elevada else 2.4), 0)
			_caja(self, c, (Vector3(0.12, 2.6 if elevada else 3.2, 10.0) if vertical else Vector3(10.0, 2.6 if elevada else 3.2, 0.12)), _mat(tcol, 0.6, 0.15))
			var ico := Label3D.new()
			## Los paneles de los lados repiten el NOMBRE (como en un metro de
			## verdad, se lee desde la ventana del tren); el icono-emoji no se
			## dibujaba (la fuente no lo tiene) y el panel quedaba vacío.
			ico.text = ("Ⓜ %s" % nombre) if k != 1 else "%s\n%s" % [nombre, String(tema[2])]
			## Más contenido: con 0,011 el lema llenaba la ventana del tren.
			ico.font_size = 64 if k != 1 else 54
			ico.pixel_size = 0.0085 if k != 1 else 0.0075
			ico.width = 1000.0
			ico.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			ico.outline_size = 10
			ico.outline_modulate = tcol.darkened(0.5)
			ico.position = c + hacia * 0.1
			ico.rotation.y = atan2(hacia.x, hacia.z)
			ico.visibility_range_end = 90.0
			add_child(ico)
		## Plano de la red: un panel blanco con las dos líneas y sus estaciones.
		var pl := fondo + lon * 24.0 + Vector3(0, y + 1.6, 0) + hacia * 0.05
		_caja(self, pl, (Vector3(0.1, 1.8, 2.6) if vertical else Vector3(2.6, 1.8, 0.1)), _mat(Color(0.96, 0.96, 0.94), 0.6))
		## Marco y trasera oscuros: por detrás era una placa blanca lisa.
		_caja(self, pl - hacia * 0.06, (Vector3(0.06, 1.95, 2.75) if vertical else Vector3(2.75, 1.95, 0.06)), _mat(Color(0.18, 0.2, 0.24), 0.5))
		var plano := Label3D.new()
		plano.text = "PLANO DE LA RED\n🔴 L1: %s\n🔵 L2: %s\n\nUsted está en: %s" % [" · ".join(NOMBRES["Línea 1"]), " · ".join(NOMBRES["Línea 2"]), nombre]
		plano.font_size = 22
		plano.pixel_size = 0.0045
		plano.modulate = Color(0.1, 0.1, 0.15)
		plano.outline_size = 0
		plano.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		plano.width = 520.0
		plano.position = pl + hacia * 0.07
		plano.rotation.y = atan2(hacia.x, hacia.z)
		plano.visibility_range_end = 40.0
		add_child(plano)
		## Máquinas, bancos, papeleras, plantas y pantallas (kit de Kenney), y
		## los sitios donde espera la gente.
		_amueblar_anden(p, fondo, hacia, lon, y, nombre, col, elevada)
		## El reloj de la estación, colgado.
		var rl := fondo + lon * 8.0 + hacia * 1.5 + Vector3(0, y + 3.3, 0)
		var reloj := MeshInstance3D.new()
		var cm := CylinderMesh.new()
		cm.top_radius = 0.45
		cm.bottom_radius = 0.45
		cm.height = 0.1
		reloj.mesh = cm
		reloj.material_override = _mat(Color.WHITE, 0.4, 0.3)
		reloj.position = rl
		reloj.rotation = Vector3(PI * 0.5, atan2(hacia.x, hacia.z), 0)
		add_child(reloj)

func linea(nombre: String) -> Dictionary:
	for l: Dictionary in lineas:
		if String(l["nombre"]) == nombre:
			return l
	return {}

func _panel(p: Vector3, linea: Dictionary, s: float) -> void:
	## Arreglo de los paneles subterráneos creados antes de tener la línea.
	for pa: Dictionary in _paneles:
		if pa.has("pend") and String(pa["linea_n"]) == String(linea["nombre"]) and not pa.has("linea"):
			pa["linea"] = linea
			pa["s"] = s
			pa.erase("pend")
			return
	var l := Label3D.new()
	l.font_size = 40
	l.pixel_size = 0.022
	l.modulate = Color(1.0, 0.85, 0.3)
	l.outline_size = 6
	l.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	l.position = p + Vector3(0, ALTO_VIADUCTO + 8.6, 0)
	## Es para verlo desde la calle; en el andén ya están las pantallas colgadas
	## (desde allí quedaba cortado detrás del tren).
	l.visibility_range_begin = 30.0
	add_child(l)
	_paneles.append({"label": l, "linea": linea, "s": s})

## Una caja en la malla de colores de vértice.
static func _caja_st(st: SurfaceTool, c: Vector3, t: Vector3, color: Color) -> void:
	var h := t * 0.5
	st.set_color(color)
	for eje in 3:
		for s: float in [-1.0, 1.0]:
			var nrm := Vector3.ZERO
			nrm[eje] = s
			var u := Vector3.ZERO
			var v := Vector3.ZERO
			u[(eje + 1) % 3] = 1.0
			v[(eje + 2) % 3] = 1.0
			var o := c + nrm * h[eje]
			var du := u * h[(eje + 1) % 3]
			var dv := v * h[(eje + 2) % 3]
			var q := [o - du - dv, o + du - dv, o + du + dv, o - du + dv]
			st.set_normal(nrm)
			for i: int in [0, 1, 2, 0, 2, 3]:
				st.add_vertex(q[i])

## La malla del interior de los tres coches (forros, asientos, marcos, asideros,
## fondos de anuncio y planos de línea), una por color de línea.
static func _interior_malla(col: Color) -> ArrayMesh:
	var clave := col.to_html()
	if _mallas_interior.has(clave):
		return _mallas_interior[clave]
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var f := PISO_COCHE
	var suelo := Color(0.23, 0.25, 0.29)
	var pasillo := Color(0.3, 0.32, 0.36)
	var amarillo := Color(0.93, 0.72, 0.12)
	var pared_baja := Color(0.5, 0.54, 0.6)
	var pared_alta := Color(0.8, 0.79, 0.75)
	var techo := Color(0.72, 0.72, 0.7)
	var marco := Color(0.42, 0.44, 0.48)
	var base_asiento := Color(0.3, 0.31, 0.35)
	var cojin := Color(col.r * 0.8, col.g * 0.8, col.b * 0.8).lerp(Color(0.3, 0.3, 0.35), 0.15)
	var cojin_b := cojin.darkened(0.3)
	var preferente := Color(0.95, 0.55, 0.12)
	var correa := Color(0.12, 0.12, 0.14)
	var asa := col.lightened(0.25)
	var metal := Color(0.72, 0.73, 0.76)
	var blanco := Color(0.95, 0.95, 0.93)
	for k in 3:
		var z := (float(k) - 1.0) * 16.6
		## Suelo, pasillo y franjas amarillas de las puertas.
		_caja_st(st, Vector3(0, f + 0.035, z), Vector3(2.84, 0.03, 15.9), suelo)
		_caja_st(st, Vector3(0, f + 0.052, z), Vector3(0.6, 0.004, 15.6), pasillo)
		## Techo forrado (antes, el blanco del exterior quemado por la luz).
		_caja_st(st, Vector3(0, f + 2.565, z), Vector3(2.8, 0.02, 15.9), techo)
		for lado: float in [-1.0, 1.0]:
			for dz: float in [-3.5, 3.5]:
				_caja_st(st, Vector3(lado * 1.2, f + 0.054, z + dz), Vector3(0.36, 0.006, 1.5), amarillo)
				## Dintel de la puerta y plano de la línea encima.
				_caja_st(st, Vector3(lado * 1.4, f + 2.25, z + dz), Vector3(0.06, 0.08, 1.56), marco)
				_caja_st(st, Vector3(lado * 1.37, f + 2.4, z + dz), Vector3(0.012, 0.2, 1.3), blanco)
				_caja_st(st, Vector3(lado * 1.364, f + 2.4, z + dz), Vector3(0.012, 0.025, 1.18), col)
				for e in 7:
					_caja_st(st, Vector3(lado * 1.36, f + 2.4, z + dz + (float(e) - 3.0) * 0.19), Vector3(0.014, 0.06, 0.06), Color(0.1, 0.1, 0.12) if e != 3 else amarillo)
			## Forro de la pared alta (encima de las ventanas, donde van los anuncios).
			_caja_st(st, Vector3(lado * 1.385, f + 2.38, z), Vector3(0.02, 0.36, 15.9), pared_alta)
			for tr: Array in TRAMOS_PARED:
				var z0 := z + float(tr[0])
				var z1 := z + float(tr[1])
				var lz := z1 - z0
				var zc := (z0 + z1) * 0.5
				## Forro bajo, alféizar y marco de arriba de la ventana.
				_caja_st(st, Vector3(lado * 1.385, f + 0.475, zc), Vector3(0.02, 0.85, lz), pared_baja)
				_caja_st(st, Vector3(lado * 1.37, f + 0.91, zc), Vector3(0.08, 0.04, lz), marco)
				_caja_st(st, Vector3(lado * 1.39, f + 2.19, zc), Vector3(0.06, 0.04, lz), marco)
				## Montantes: en las puntas del tramo y cada ~1,9 m.
				var n_m := maxi(1, int(round(lz / 1.9)))
				for q in n_m + 1:
					var zm := z0 + lz * float(q) / float(n_m)
					zm = clampf(zm, z0 + 0.05, z1 - 0.05)
					_caja_st(st, Vector3(lado * 1.4, f + 1.55, zm), Vector3(0.07, 1.3, 0.1), marco)
			## Asientos uno a uno, con base, cojín, respaldo y reposacabezas.
			for ti in TRAMOS_ASIENTO.size():
				var tramo: Array = TRAMOS_ASIENTO[ti]
				var tc := z + float(tramo[0])
				var tl := float(tramo[1])
				_caja_st(st, Vector3(lado * 1.12, f + 0.21, tc), Vector3(0.48, 0.36, tl), base_asiento)
				var n_as := int(tl / PASO_ASIENTO)
				for q in n_as:
					var zs := tc + (float(q) - float(n_as - 1) * 0.5) * PASO_ASIENTO
					var pref := ti != 1 and (q == 0 or q == n_as - 1) and absf(absf(zs - z) - 3.5) < 2.0
					var c1 := preferente if pref else (cojin if q % 2 == 0 else cojin.lerp(cojin_b, 0.35))
					_caja_st(st, Vector3(lado * 1.1, f + ALTO_ASIENTO - 0.045, zs), Vector3(0.5, 0.09, PASO_ASIENTO - 0.05), c1)
					_caja_st(st, Vector3(lado * 1.33, f + 0.8, zs), Vector3(0.08, 0.6, PASO_ASIENTO - 0.05), c1.darkened(0.12))
					_caja_st(st, Vector3(lado * 1.32, f + 1.13, zs), Vector3(0.09, 0.1, PASO_ASIENTO - 0.08), cojin_b)
				## Mamparas y barras en las puntas que dan a las puertas.
				for s: float in [-1.0, 1.0]:
					var ze := tc + s * (tl * 0.5 + 0.06)
					if absf(absf(ze - z) - 3.5) > 1.2:
						continue
					## Mampara de tubo (una placa opaca tapaba la vista del pasillo).
					_caja_st(st, Vector3(lado * 0.86, f + 1.12, ze), Vector3(0.045, 2.2, 0.045), metal)
					for yb: float in [0.62, 1.18]:
						_caja_st(st, Vector3(lado * 1.11, f + yb, ze), Vector3(0.5, 0.04, 0.04), metal)
				## Fondo del anuncio sobre el tramo (el texto es un Label3D).
				var c_ad: Color = COLORES_ANUNCIO[(k * 3 + ti + (0 if lado > 0.0 else 2)) % COLORES_ANUNCIO.size()]
				_caja_st(st, Vector3(lado * 1.37, f + 2.38, tc), Vector3(0.012, 0.3, 1.55), c_ad)
				_caja_st(st, Vector3(lado * 1.372, f + 2.38, tc), Vector3(0.01, 0.34, 1.6), marco)
			## Asideros colgados de las barras del techo.
			for q in 21:
				var za := z - 7.0 + float(q) * 0.7
				if absf(absf(za - z) - 3.5) < 0.5:
					continue
				_caja_st(st, Vector3(lado * 0.55, f + 2.14, za), Vector3(0.02, 0.2, 0.03), correa)
				_caja_st(st, Vector3(lado * 0.55, f + 2.02, za), Vector3(0.02, 0.035, 0.1), asa)
		## Testeros: forro y puerta de paso al coche de al lado.
		for e: float in [-1.0, 1.0]:
			_caja_st(st, Vector3(0, f + 1.3, z + e * 7.93), Vector3(2.76, 2.5, 0.02), pared_alta)
			_caja_st(st, Vector3(0, f + 1.0, z + e * 7.92), Vector3(0.95, 1.9, 0.02), Color(0.28, 0.3, 0.34))
			_caja_st(st, Vector3(0, f + 1.35, z + e * 7.915), Vector3(0.6, 0.7, 0.01), Color(0.12, 0.16, 0.2))
	st.index()
	var m := st.commit()
	_mallas_interior[clave] = m
	return m

static func _mat_interior() -> StandardMaterial3D:
	if _mat_int == null:
		_mat_int = StandardMaterial3D.new()
		_mat_int.vertex_color_use_as_albedo = true
		_mat_int.vertex_color_is_srgb = true
		_mat_int.roughness = 0.8
		_mat_int.cull_mode = BaseMaterial3D.CULL_DISABLED
	return _mat_int
