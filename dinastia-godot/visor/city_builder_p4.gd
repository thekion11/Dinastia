extends "res://visor/city_builder_p3.gd"
## [Capa 4/12 de `city_builder.gd`] _estadio_maqueta, _estadio, _lineas_campo, _un_campo, _campos, _rotulo … (+8)

## Respaldo: la maqueta de siempre, por si no llega perfil -por ejemplo desde
## una prueba que solo pasa `inst`-. Mejor una maqueta que un hueco.
func _estadio_maqueta() -> void:
	var malla := load(RUTA_ESTADIO)
	if malla == null:
		return
	var mi := MeshInstance3D.new()
	mi.mesh = malla
	var aforo := float(datos.get("club", {}).get("cap", 20000))
	var k: float = clampf(sqrt(aforo / 20000.0), 0.65, 1.8)
	## Escala MEDIDA, no a ojo: el OBJ mide 7.298 unidades de largo y un estadio real
	## ronda los 220 m, asi que 220/7298 = 0.030. Con el 0.09 que puse a ojo salia de
	## 650 metros y se comia la escena entera.
	## Su origen ya esta en Y=0 y centrado en X, asi que apoya solo en el suelo.
	mi.scale = Vector3.ONE * 0.030 * k
	mi.position = Vector3(0, 0, -150)
	## El OBJ no trae materiales. Se le daba el color SECUNDARIO del club, pero en
	## la mayoria de los escudos ese color es el blanco, asi que el estadio salia
	## de un blanco yeso y parecia una maqueta sin terminar. Ahora es hormigon
	## teñido hacia el color PRINCIPAL: se reconoce al club y sigue leyendose como
	## un edificio.
	var hormigon := Color(0.62, 0.63, 0.64)
	var mat := StandardMaterial3D.new()
	mat.albedo_color = hormigon.lerp(_color_club("c1", hormigon), 0.45)
	mat.roughness = 0.6
	mat.metallic = 0.06
	mat.metallic_specular = 0.4
	mi.material_override = mat
	add_child(mi)
	## Cesped dentro del recinto: sin el, el hueco del estadio se ve del mismo color
	## que las gradas y no se entiende que ahi dentro hay un campo.
	var cesp := MeshInstance3D.new()
	var cp := PlaneMesh.new()
	cp.size = Vector2(38 * k, 25 * k)
	cesp.mesh = cp
	var cmat := StandardMaterial3D.new()
	cmat.albedo_color = Color(0.19, 0.45, 0.23)
	cmat.roughness = 1.0
	cesp.material_override = cmat
	cesp.position = Vector3(0, 0.6, -150)
	add_child(cesp)
	etiquetas.append({
		"pos": Vector3(0, 75 * k, -150),
		"texto": str(datos.get("club", {}).get("estadioNom", "Estadio")),
		"nivel": int(datos.get("inst", {}).get("trib", 0)),
	})

func _estadio() -> void:
	var perfil: Dictionary = datos.get("perfil_estadio", {})
	if not perfil.is_empty():
		var nodo := Node3D.new()
		nodo.position = ESTADIO_EN
		nodo.set_meta("en_ciudad", true)
		add_child(nodo)
		var aforo := int(perfil.get("aforo", datos.get("club", {}).get("cap", 20000)))
		## EL MISMO ESTADIO QUE EN EL PARTIDO Y EN EL VISOR (8-10-2026): misma
		## semilla (el id del club) y el club para escudos, telones y pantallas.
		## Antes la semilla era el aforo y sin club: butacas y detalles distintos.
		var club_obj: Club = datos.get("club_obj") as Club
		var semilla := club_obj._hash_id() if club_obj != null else aforo
		StadiumBuilder.build_pitch(nodo, perfil, club_obj)
		## Ocupación media-baja: fuera de partido el estadio no está lleno, pero
		## con 0,06 la grada salía de un gris uniforme y desde el mapa el
		## estadio se leía como una pista de hockey. Con 0,35 se distinguen las
		## butacas del club, que es lo que lo hace reconocible desde arriba.
		## Con la galería subterránea (2.0, fase 6) la puerta del sótano queda abierta.
		GaleriaClub.en_ciudad = true
		## El estadio es lo que se mira en el mapa: sin cortes por distancia
		## (si no, los jugadores del campo desaparecían desde la vista aérea).
		nodo.set_meta("sin_corte", true)
		StadiumBuilder.build(nodo, perfil, aforo, 0.85 if bool(datos.get("dia_partido", false)) else 0.35, semilla, club_obj)
		GaleriaClub.en_ciudad = false
		huellas.append(Rect2(ESTADIO_EN.x - 62.0, ESTADIO_EN.z - 80.0, 124.0, 160.0))
		## El vestuario del túnel sobresale por detrás de la tribuna (estadio 2.0).
		var tv := TunelVestuario.datos(perfil, StadiumBuilder.niveles_de(perfil, aforo))
		## La galería que une el sótano del club con el complejo, y su caseta.
		var g1 := _color_club("c1", Color(0.2, 0.5, 0.3))
		var g2 := _color_club("c2", Color(0.95, 0.95, 0.95))
		GaleriaClub.montar(nodo, tv, g1, g2, String(perfil.get("club_nombre", "")))
		GaleriaClub.montar_caseta(self, tv, g1)
		_rect_vestuario = Rect2(ESTADIO_EN.x + float(tv["x0"]) - TunelVestuario.VEST_MEDIO - 0.4,
			ESTADIO_EN.z + float(tv["z_out"]), TunelVestuario.VEST_MEDIO * 2.0 + 0.8, TunelVestuario.VEST_FONDO + 0.4)
		huellas.append(_rect_vestuario)
		## La entrada del club (8-10-2026): la garita del portero es sólida y
		## delante de la puerta no puede haber bolardos, bancos ni papeleras.
		var x0e := ESTADIO_EN.x + float(tv["x0"])
		var zfe := ESTADIO_EN.z + float(tv["z_fin"])
		var rg := EntradaClub.rect_garita(float(tv["x0"]), float(tv["z_fin"]))
		huellas.append(Rect2(rg.position + Vector2(ESTADIO_EN.x, ESTADIO_EN.z), rg.size))
		_rect_entrada = Rect2(EntradaClub.centro(x0e) - 7.5, zfe + 0.3, 15.0, 5.5)
		puntos_clic.append({"k": "estadio", "n": str(datos.get("club", {}).get("estadioNom", "Estadio")),
			"pos": ESTADIO_EN + Vector3(0, 15, 0), "estado": "estadio"})
		## Si se están ampliando las tribunas o mejorando el recinto, se nota.
		for o in datos.get("obras", []):
			if str(o.get("k", "")) in ["trib", "cal"]:
				_grua(ESTADIO_EN + Vector3(95.0, 0, 20.0), 70.0)
				break
		etiquetas.append({
			"pos": ESTADIO_EN + Vector3(0, 40, 0),
			"texto": str(datos.get("club", {}).get("estadioNom", "Estadio")),
			"nivel": int(datos.get("inst", {}).get("trib", 0)),
		})
		return
	_estadio_maqueta()

func _lineas_campo(centro: Vector3) -> void:
	## Las lineas van como cajas finisimas y no como material: un campo sin lineas
	## se lee como una alfombra verde, no como un campo de futbol.
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.92, 0.94, 0.92)
	mat.roughness = 0.9
	var media := func(ancho: float, fondo: float, off: Vector3) -> void:
		var b := MeshInstance3D.new()
		var bm := BoxMesh.new()
		bm.size = Vector3(ancho, 0.06, fondo)
		b.mesh = bm
		b.material_override = mat
		b.position = centro + off + Vector3(0, 0.04, 0)
		add_child(b)
	media.call(78.0, 0.3, Vector3.ZERO)                  # linea de medio campo (a lo ancho)
	media.call(0.3, 50.0, Vector3.ZERO)                  # linea central
	media.call(78.0, 0.3, Vector3(0, 0, -25.0))          # fondo
	media.call(78.0, 0.3, Vector3(0, 0, 25.0))           # fondo
	media.call(0.3, 50.0, Vector3(-39.0, 0, 0))          # banda
	media.call(0.3, 50.0, Vector3(39.0, 0, 0))           # banda

func _un_campo(pos: Vector3, principal: bool) -> void:
	var m := MeshInstance3D.new()
	var pl := PlaneMesh.new()
	## 105x68 son las medidas reales; aquí van a 3/4, que es lo que permite
	## meter cuatro campos sin que el recinto se estire un kilómetro.
	pl.size = Vector2(78, 50)
	m.mesh = pl
	var mat := StandardMaterial3D.new()
	## CON CORTE DE CÉSPED, no un verde plano. Sobre el césped general del
	## recinto -que es otro verde parecido- un campo liso no se distinguía: se
	## veía un rectángulo apenas más oscuro. Con las rayas del corte se lee como
	## campo de fútbol al primer vistazo, incluso desde la cámara del mapa. La
	## textura es la MISMA que usa el estadio de verdad (`StadiumBuilder`), así
	## que los campos de entrenamiento y la cancha del estadio se parecen entre
	## sí, como en un club real.
	## RAYAS EN LOS DOS, cambiando la dirección. Con "damero" en los campos
	## secundarios aquello se leía como un tablero de ajedrez, no como césped
	## cortado: el damero de un estadio de verdad es mucho más fino que el que
	## sale aquí a esta escala. Dos direcciones de raya bastan para que los
	## campos no parezcan copiados y sigan leyéndose como campos.
	mat.albedo_texture = StadiumBuilder._make_grass_texture(
		"rayas" if principal else "rayasH",
		Color(0.29, 0.60, 0.30), Color(0.17, 0.42, 0.20))
	mat.roughness = 0.98
	m.material_override = mat
	m.position = pos
	add_child(m)
	_lineas_campo(pos)

# ---------------------------------------------------------------- campos

func _campos() -> void:
	## Un campo de entrenamiento por cada nivel del centro de entrenamiento, con un
	## minimo de uno: sin campos no hay club. Es el lector mas directo de esa
	## inversion — subes 'ct' y aparece cesped nuevo.
	var niv := int(datos.get("inst", {}).get("ct", 0))
	var n: int = clampi(niv + 1, 1, 6)
	## DOS POR FILA Y MÁS GRANDES (12-9-2026): con tres campos de 35 m por fila
	## el complejo parecía un patio de colegio al lado de un estadio de 110 m
	## de ancho. Ahora cada campo mide 78x50 -tres cuartos de uno reglamentario-
	## y se entiende que ahí entrena un plantel profesional.
	for i in range(n):
		var fila := i / 2
		var col := i % 2
		var x := -45.0 + col * 90.0
		var z := -25.0 + fila * 64.0
		_un_campo(Vector3(x, 0.02, z), i == 0)

## Un rótulo flotante: siempre del mismo tamaño en pantalla y mirando a cámara.
func _rotulo(pos: Vector3, texto: String, color: Color, tam: int = 28) -> void:
	var l := Label3D.new()
	l.text = texto
	l.font_size = tam
	l.outline_size = 10
	l.modulate = color
	l.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	l.fixed_size = true
	l.pixel_size = 0.0007
	l.no_depth_test = true
	l.position = pos
	l.add_to_group("rotulo_mapa")
	_rotulos.add_child(l)


# ---------------------------------------------------------------------------
#  B7 (25-9-2026, plan maestro): SOLARES, OBRAS, RÓTULOS Y DÍA DE PARTIDO
# ---------------------------------------------------------------------------

## La parcela de una instalación que todavía no existe: tierra, un borde de
## bordillo y un cartel "Solar". Se clica para construirla.
func _solar_libre(e: Dictionary, pos: Vector3) -> void:
	var tierra := StandardMaterial3D.new()
	tierra.albedo_color = Color(0.46, 0.38, 0.27)
	tierra.roughness = 1.0
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(float(e["ancho"]), 0.3, float(e["fondo"]))
	mi.mesh = bm
	mi.material_override = tierra
	mi.position = pos + Vector3(0, 0.15, 0)
	add_child(mi)
	_rotulo(pos + Vector3(0, 6.0, 0), "＋ %s" % str(e["n"]), Color(0.75, 0.85, 0.78, 0.8), 22)
	puntos_clic.append({"k": String(e["k"]), "n": str(e["n"]), "pos": pos + Vector3(0, 1.0, 0), "estado": "solar"})

func _mat_simple(c: Color, rug := 0.6, emi := 0.0) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = rug
	if emi > 0.0:
		m.emission_enabled = true
		m.emission = c
		m.emission_energy_multiplier = emi
	return m

func _caja_en(pos: Vector3, tam: Vector3, m: Material, giro := 0.0) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var b := BoxMesh.new()
	b.size = tam
	mi.mesh = b
	mi.material_override = m
	mi.position = pos
	mi.rotation.y = giro
	add_child(mi)
	return mi

## Una bóveda de cañón sobre un muro: medio cilindro a lo ancho, aplanado.
func _boveda(base: Vector3, ancho: float, fondo: float, m: Material, aplanado: float) -> void:
	var b := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = fondo * 0.5
	cm.bottom_radius = fondo * 0.5
	cm.height = ancho
	cm.radial_segments = 24
	b.mesh = cm
	b.material_override = m
	b.rotation.z = PI * 0.5
	b.scale = Vector3(1.0, 1.0, 1.0)
	b.position = base
	## Aplanado en vertical: el eje local X queda vertical tras el giro.
	b.scale = Vector3(aplanado * 2.0, 1.0, 1.0)
	add_child(b)

func _ventanas(pos: Vector3, ancho: float, fondo: float, plantas: int) -> void:
	## Una tira de ventanas por planta. Sin esto las cajas parecen contenedores;
	## con esto se leen como edificios y ademas se CUENTAN las plantas de un vistazo.
	## CRISTAL de verdad, no una franja azul pintada: metalico y muy pulido, para
	## que refleje el cielo. Es el detalle que mas hace por el realismo de un
	## edificio — un cristal que no refleja nada se lee como carton.
	##
	## CADA TIRA CON SU PROPIO MATERIAL (12-9-2026): antes había UN solo
	## material por edificio entero, compartido por todas sus plantas y caras,
	## así que de noche el edificio se encendía como un bloque -todo o nada-,
	## que no es como se ve una oficina real. Con un material por tira y un
	## azar propio guardado en cada uno, `encender_luces()` las enciende en
	## umbrales distintos: unas plantas ya de tarde, otras bien entrada la
	## noche, y unas pocas se quedan más apagadas siempre -el piso vacío o el
	## que ya se fue a casa-. La semilla sale de la posición del edificio, no
	## de `randf()` a secas, para que el mismo edificio se vea IGUAL cada vez
	## que se construye la ciudad, no parpadeando entre partidas.
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(pos)
	## Marco oscuro entre plantas: separa los pisos y da grosor a la fachada.
	## Este sí se comparte -no depende de la hora, no necesita variar-.
	## Compartido entre TODAS las plantas de TODOS los edificios del mapa.
	var marco: StandardMaterial3D = Texturas.metal(Color(0.13, 0.13, 0.14), 0.5).duplicate()
	marco.metallic = 0.35
	for p in range(plantas):
		var y := 6.0 * p + 3.0
		for lado in [-1.0, 1.0]:
			for eje in [0, 1]:
				var mat := StandardMaterial3D.new()
				mat.albedo_color = Color(0.10, 0.14, 0.18)
				mat.metallic = 0.95
				mat.metallic_specular = 0.9
				mat.roughness = 0.06
				mat.emission_enabled = true
				## De día un reflejo apagado; de noche, luz encendida dentro.
				## Lo sube `encender_luces()`, que lee `_azar_ventana` de aquí.
				mat.emission = Color(0.98, 0.86, 0.58)
				mat.emission_energy_multiplier = 0.18
				mat.set_meta("_azar_ventana", rng.randf())
				_ventanas_mat.append(mat)
				var v := MeshInstance3D.new()
				var vm := BoxMesh.new()
				var m2 := MeshInstance3D.new()
				var mm := BoxMesh.new()
				var off: Vector3
				if eje == 0:
					vm.size = Vector3(ancho * 0.84, 1.9, 0.12)
					mm.size = Vector3(ancho * 0.88, 2.5, 0.09)
					off = Vector3(0, y, lado * (fondo * 0.5 + 0.07))
				else:
					## Tambien en los costados: antes solo habia ventanas en dos
					## caras y desde media vuelta el edificio parecia un muro ciego.
					vm.size = Vector3(0.12, 1.9, fondo * 0.8)
					mm.size = Vector3(0.09, 2.5, fondo * 0.84)
					off = Vector3(lado * (ancho * 0.5 + 0.07), y, 0)
				v.mesh = vm
				v.material_override = mat
				v.position = pos + off
				m2.mesh = mm
				m2.material_override = marco
				m2.position = pos + off * 0.995
				add_child(m2)
				add_child(v)

func _vidrio_oscuro() -> StandardMaterial3D:
	var v := StandardMaterial3D.new()
	v.albedo_color = Color(0.12, 0.18, 0.24)
	v.metallic = 0.7
	v.roughness = 0.12
	return v

func _cil_en(pos: Vector3, r: float, h: float, m: Material, r_arriba := -1.0) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var c := CylinderMesh.new()
	c.top_radius = r if r_arriba < 0.0 else r_arriba
	c.bottom_radius = r
	c.height = h
	mi.mesh = c
	mi.material_override = m
	mi.position = pos
	add_child(mi)
	return mi

func _cuerpo_instalacion(forma: String, pos: Vector3, ancho: float, fondo: float, alto: float, plantas: int, mat: StandardMaterial3D) -> void:
	match forma:
		"nave":
			## Nave deportiva: muro bajo y bóveda de cañón a lo largo.
			var muro := alto * 0.55 + 2.0
			_caja_en(pos + Vector3(0, muro * 0.5, 0), Vector3(ancho, muro, fondo), mat)
			_boveda(pos + Vector3(0, muro, 0), ancho, fondo, _mat_simple(Color(0.78, 0.8, 0.82), 0.35, 0.0), 0.42)
			_ventanas(pos, ancho, fondo, maxi(1, plantas / 2))
		"cristal":
			## Pabellón de cristal con la lámina de agua dentro y bóveda.
			var muro2 := maxf(6.0, alto * 0.6)
			var vidrio := StandardMaterial3D.new()
			vidrio.albedo_color = Color(0.62, 0.82, 0.9, 0.38)
			vidrio.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			vidrio.roughness = 0.08
			vidrio.metallic = 0.3
			_caja_en(pos + Vector3(0, muro2 * 0.5, 0), Vector3(ancho, muro2, fondo), vidrio)
			var agua := StandardMaterial3D.new()
			agua.albedo_color = Color(0.1, 0.55, 0.78)
			agua.roughness = 0.05
			agua.emission_enabled = true
			agua.emission = Color(0.05, 0.25, 0.35)
			_caja_en(pos + Vector3(0, 0.35, 0), Vector3(ancho * 0.78, 0.3, fondo * 0.62), agua)
			_caja_en(pos + Vector3(0, 0.15, 0), Vector3(ancho - 0.6, 0.3, fondo - 0.6), _mat_simple(Color(0.9, 0.9, 0.88), 0.7))
			for k in 6:
				_caja_en(pos + Vector3(-ancho * 0.39 + float(k) * ancho * 0.156, 0.52, 0), Vector3(0.12, 0.06, fondo * 0.6), _mat_simple(Color.WHITE, 0.6))
			_boveda(pos + Vector3(0, muro2, 0), ancho, fondo, _mat_simple(Color(0.86, 0.9, 0.93), 0.3, 0.0), 0.35)
		"torre":
			## Residencia: torre estrecha y alta con balcones corridos.
			var a2 := ancho * 0.62
			var h := alto * 1.45 + 4.0
			_caja_en(pos + Vector3(0, 2.5, 0), Vector3(ancho, 5.0, fondo), mat)
			_caja_en(pos + Vector3(0, 5.0 + h * 0.5, -fondo * 0.12), Vector3(a2, h, fondo * 0.62), mat)
			var bal := _mat_simple(Color(0.95, 0.95, 0.93), 0.6)
			var pisos := int(h / 3.2)
			for k in pisos:
				_caja_en(pos + Vector3(0, 5.0 + 1.2 + float(k) * 3.2, -fondo * 0.12 + fondo * 0.31 + 0.6), Vector3(a2 + 0.4, 0.25, 1.2), bal)
			_ventanas(pos + Vector3(0, 0, -fondo * 0.12), a2, fondo * 0.62, maxi(2, int(h / 6.0)))
		"clinica":
			## Clínica: zócalo ancho y volumen blanco más estrecho encima.
			var blanco := _mat_simple(Color(0.95, 0.96, 0.97), 0.45)
			var bajo := maxf(5.0, alto * 0.55)
			_caja_en(pos + Vector3(0, bajo * 0.5, 0), Vector3(ancho, bajo, fondo), blanco)
			if alto > bajo + 1.0:
				_caja_en(pos + Vector3(-ancho * 0.12, bajo + (alto - bajo) * 0.5, -fondo * 0.1), Vector3(ancho * 0.7, alto - bajo, fondo * 0.75), blanco)
			_caja_en(pos + Vector3(0, bajo * 0.5, fondo * 0.5 + 0.05), Vector3(ancho * 0.9, bajo * 0.55, 0.1), _vidrio_oscuro())
			_ventanas(pos, ancho, fondo, plantas)
		"templo":
			## Museo: podio, cuerpo, columnata delante y frontón.
			var piedra := _mat_simple(Color(0.86, 0.82, 0.72), 0.75)
			_caja_en(pos + Vector3(0, 0.8, 1.5), Vector3(ancho + 4.0, 1.6, fondo + 7.0), piedra)
			var h2 := maxf(9.0, alto)
			_caja_en(pos + Vector3(0, 1.6 + h2 * 0.5, -1.0), Vector3(ancho, h2, fondo - 2.0), piedra)
			var cols := 6
			for k in cols:
				var x := -ancho * 0.42 + float(k) * ancho * 0.84 / float(cols - 1)
				_cil_en(pos + Vector3(x, 1.6 + (h2 - 1.2) * 0.5, fondo * 0.5 + 2.6), 0.75, h2 - 1.2, piedra)
			_caja_en(pos + Vector3(0, 1.6 + h2 - 0.6, fondo * 0.5 + 2.4), Vector3(ancho + 1.0, 1.2, 4.2), piedra)
			var fronton := MeshInstance3D.new()
			var pr := PrismMesh.new()
			pr.size = Vector3(ancho + 1.0, 3.2, 4.2)
			fronton.mesh = pr
			fronton.material_override = piedra
			fronton.position = pos + Vector3(0, 1.6 + h2 + 1.6, fondo * 0.5 + 2.4)
			add_child(fronton)
		"escuela":
			## Academia y guardería: escuela en L de ladrillo.
			var ladrillo := Texturas.hormigon(Color(0.66, 0.38, 0.3)).duplicate() as StandardMaterial3D
			ladrillo.roughness = 0.85
			_caja_en(pos + Vector3(0, alto * 0.5, -fondo * 0.22), Vector3(ancho, alto, fondo * 0.56), ladrillo)
			_caja_en(pos + Vector3(-ancho * 0.32, alto * 0.4, fondo * 0.18), Vector3(ancho * 0.36, alto * 0.8, fondo * 0.64), ladrillo)
			_ventanas(pos + Vector3(0, 0, -fondo * 0.22), ancho, fondo * 0.56, plantas)
		"pabellon":
			## Comedor y bienestar: planta baja acristalada y una cubierta que
			## vuela sobre la terraza.
			var h3 := maxf(5.0, alto * 0.7)
			_caja_en(pos + Vector3(0, h3 * 0.5, -1.0), Vector3(ancho - 2.0, h3, fondo - 2.0), mat)
			_caja_en(pos + Vector3(0, h3 * 0.5, fondo * 0.5 - 1.0 + 0.05), Vector3(ancho - 3.0, h3 * 0.7, 0.1), _vidrio_oscuro())
			_caja_en(pos + Vector3(0, h3 + 0.3, 1.5), Vector3(ancho + 3.0, 0.6, fondo + 5.0), _mat_simple(Color(0.88, 0.86, 0.8), 0.6))
			for sx in [-1.0, 1.0]:
				_cil_en(pos + Vector3(sx * (ancho * 0.5 + 0.8), h3 * 0.5, fondo * 0.5 + 3.2), 0.22, h3, _mat_simple(Color(0.3, 0.3, 0.32), 0.5))
		"medios":
			## Prensa, vídeo y juegos: caja con piel de cristal oscuro y franja.
			_caja_en(pos + Vector3(0, alto * 0.5, 0), Vector3(ancho, alto, fondo), mat)
			_caja_en(pos + Vector3(0, alto * 0.55, fondo * 0.5 + 0.06), Vector3(ancho * 0.94, alto * 0.7, 0.12), _vidrio_oscuro())
			_caja_en(pos + Vector3(ancho * 0.5 + 0.06, alto * 0.55, 0), Vector3(0.12, alto * 0.7, fondo * 0.9), _vidrio_oscuro())
		"tienda":
			## Tienda oficial: escaparate entero de cristal y cartel del club.
			_caja_en(pos + Vector3(0, alto * 0.5, 0), Vector3(ancho, alto, fondo), mat)
			var vit := _vidrio_oscuro()
			vit.emission_enabled = true
			vit.emission = Color(0.35, 0.3, 0.2)
			_caja_en(pos + Vector3(0, 2.4, fondo * 0.5 + 0.06), Vector3(ancho * 0.92, 4.2, 0.12), vit)
			_caja_en(pos + Vector3(0, alto + 1.4, fondo * 0.5 - 0.5), Vector3(ancho * 0.6, 2.4, 0.4), _mat_simple(_color_club("c1", Color(0.2, 0.5, 0.3)), 0.5, 0.25))
		_:
			_caja_en(pos + Vector3(0, alto * 0.5, 0), Vector3(ancho, alto, fondo), mat)
			_ventanas(pos, ancho, fondo, plantas)
