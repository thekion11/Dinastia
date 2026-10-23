extends "res://visor/stadium_builder_p1.gd"
## (Parte 2 de 11 de `stadium_builder.gd`.)

static func _add_goal(root: Node3D, z: float, poste: Material, red_col: Color, red_tipo: String = "cuadrada") -> void:
	var width := 7.32
	var height := 2.44
	var r_tubo := 0.06
	var depth_top := 0.85
	var depth_bottom := 1.95
	var inward := -1.0 if z > 0.0 else 1.0

	var goal_root := Node3D.new()
	goal_root.name = "Arco_" + ("Norte" if z < 0 else "Sur")
	root.add_child(goal_root)

	# 1. Postes verticales (cilindros FIFA reglamentarios)
	for side in [-1.0, 1.0]:
		var p_vert := MeshInstance3D.new()
		var cm := CylinderMesh.new()
		cm.top_radius = r_tubo
		cm.bottom_radius = r_tubo
		cm.height = height
		cm.radial_segments = 16
		p_vert.mesh = cm
		p_vert.position = Vector3(side * width / 2.0, height / 2.0, z)
		p_vert.material_override = poste
		goal_root.add_child(p_vert)

	# 2. Larguero horizontal (cilindro rotado 90° en Z)
	var p_larg := MeshInstance3D.new()
	var cm_larg := CylinderMesh.new()
	cm_larg.top_radius = r_tubo
	cm_larg.bottom_radius = r_tubo
	cm_larg.height = width
	cm_larg.radial_segments = 16
	p_larg.mesh = cm_larg
	p_larg.rotation.z = PI / 2.0
	p_larg.position = Vector3(0, height, z)
	p_larg.material_override = poste
	goal_root.add_child(p_larg)

	# 3. Arquillos tensores traseros y marco de base (tubos tensores)
	var mat_tensor := poste.duplicate()
	if mat_tensor is StandardMaterial3D:
		(mat_tensor as StandardMaterial3D).albedo_color = Color(0.85, 0.86, 0.88)
		(mat_tensor as StandardMaterial3D).metallic = 0.4
		(mat_tensor as StandardMaterial3D).roughness = 0.4

	# Brazos superiores horizontales hacia atrás
	for side in [-1.0, 1.0]:
		var brazo := MeshInstance3D.new()
		var c_brazo := CylinderMesh.new()
		c_brazo.top_radius = 0.035
		c_brazo.bottom_radius = 0.035
		c_brazo.height = depth_top
		c_brazo.radial_segments = 10
		brazo.mesh = c_brazo
		brazo.rotation.x = PI / 2.0
		brazo.position = Vector3(side * width / 2.0, height, z - inward * (depth_top / 2.0))
		brazo.material_override = mat_tensor
		goal_root.add_child(brazo)

		# Tensores diagonales desde la punta trasera hacia el marco de base
		var diag := MeshInstance3D.new()
		var len_diag := sqrt(height * height + (depth_bottom - depth_top) * (depth_bottom - depth_top))
		var c_diag := CylinderMesh.new()
		c_diag.top_radius = 0.03
		c_diag.bottom_radius = 0.03
		c_diag.height = len_diag
		c_diag.radial_segments = 10
		diag.mesh = c_diag
		var ang_diag := atan2(depth_bottom - depth_top, height)
		diag.rotation.x = -inward * ang_diag
		diag.position = Vector3(side * width / 2.0, height / 2.0, z - inward * ((depth_top + depth_bottom) / 2.0))
		diag.material_override = mat_tensor
		goal_root.add_child(diag)

		# Barra lateral en el suelo
		var barra_suelo := MeshInstance3D.new()
		var c_suelo := CylinderMesh.new()
		c_suelo.top_radius = 0.035
		c_suelo.bottom_radius = 0.035
		c_suelo.height = depth_bottom
		c_suelo.radial_segments = 10
		barra_suelo.mesh = c_suelo
		barra_suelo.rotation.x = PI / 2.0
		barra_suelo.position = Vector3(side * width / 2.0, 0.035, z - inward * (depth_bottom / 2.0))
		barra_suelo.material_override = mat_tensor
		goal_root.add_child(barra_suelo)

	# Barra trasera en el suelo
	var barra_trasera := MeshInstance3D.new()
	var c_tras := CylinderMesh.new()
	c_tras.top_radius = 0.035
	c_tras.bottom_radius = 0.035
	c_tras.height = width
	c_tras.radial_segments = 10
	barra_trasera.mesh = c_tras
	barra_trasera.rotation.z = PI / 2.0
	barra_trasera.position = Vector3(0, 0.035, z - inward * depth_bottom)
	barra_trasera.material_override = mat_tensor
	goal_root.add_child(barra_trasera)

	# 4. Red texturizada con malla perforada real
	var mat_red := StandardMaterial3D.new()
	mat_red.albedo_texture = _make_net_texture(red_col, red_tipo)
	mat_red.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_DEPTH_PRE_PASS
	mat_red.cull_mode = BaseMaterial3D.CULL_DISABLED
	mat_red.roughness = 0.95
	mat_red.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS

	# Techo de red (desde larguero hasta depth_top)
	var techo_red := MeshInstance3D.new()
	var q_techo := QuadMesh.new()
	q_techo.size = Vector2(width, depth_top)
	techo_red.mesh = q_techo
	techo_red.rotation.x = PI / 2.0
	techo_red.position = Vector3(0, height - 0.01, z - inward * (depth_top / 2.0))
	## El techo y el fondo, subdivididos y con el shader de la onda (M-149):
	## la red se abomba al gol. Mismo dibujo y mismo cordel que antes.
	var tex_red: Texture2D = mat_red.albedo_texture
	var onda := RedArco.new()
	onda.name = "RedArco"
	q_techo.subdivide_width = 18
	q_techo.subdivide_depth = 3
	techo_red.name = "RedTecho"
	## En un grupo: así `Optimizar.agrupar` no la funde con otras piezas quietas
	## (perdería su material propio y la onda).
	techo_red.add_to_group("red_arco")
	techo_red.material_override = _mat_red_onda(tex_red, Vector2(32, 6), Vector2(width, depth_top) * 0.5)
	goal_root.add_child(techo_red)
	onda.panos.append(techo_red)

	# Fondo de red inclinado (desde depth_top a depth_bottom en el suelo)
	var fondo_red := MeshInstance3D.new()
	var q_fondo := QuadMesh.new()
	var alto_fondo := sqrt(height * height + (depth_bottom - depth_top) * (depth_bottom - depth_top))
	q_fondo.size = Vector2(width, alto_fondo)
	fondo_red.mesh = q_fondo
	var ang_fondo := atan2(depth_bottom - depth_top, height)
	fondo_red.rotation.x = -inward * ang_fondo
	fondo_red.position = Vector3(0, height / 2.0, z - inward * ((depth_top + depth_bottom) / 2.0))
	q_fondo.subdivide_width = 24
	q_fondo.subdivide_depth = 9
	fondo_red.name = "RedFondo"
	fondo_red.add_to_group("red_arco")
	fondo_red.material_override = _mat_red_onda(tex_red, Vector2(32, 14), Vector2(width, alto_fondo) * 0.5)
	goal_root.add_child(fondo_red)
	onda.panos.append(fondo_red)
	goal_root.add_child(onda)

	# Laterales de red
	for side in [-1.0, 1.0]:
		var lat_red := MeshInstance3D.new()
		var q_lat := QuadMesh.new()
		q_lat.size = Vector2(depth_bottom, height)
		lat_red.mesh = q_lat
		lat_red.rotation.y = PI / 2.0
		lat_red.position = Vector3(side * width / 2.0, height / 2.0, z - inward * (depth_bottom / 2.0))
		var m_lat: StandardMaterial3D = mat_red.duplicate()
		m_lat.uv1_scale = Vector3(12, 10, 1)
		lat_red.material_override = m_lat
		goal_root.add_child(lat_red)

## Zona tecnica: el rectangulo de lineas discontinuas donde puede moverse el
## entrenador. Se pinta con trazos, no con una linea continua, que es como es.
static func _zona_tecnica(root: Node3D, line_mat: Material) -> void:
	## Delante de los dos banquillos, 3.5 m fuera de la banda (X≈35), a ±14 m
	## del círculo. Antes estaba con X/Z invertidos y se pintaba dentro del área.
	var x_linea: float = PITCH_WID * 0.5 + 1.0
	for lado in [-1.0, 1.0]:
		var cz: float = lado * 14.0
		for k in range(14):
			var z: float = cz - 5.0 + k * 0.77
			_box(root, Vector3(x_linea, 0.02, z), Vector3(0.12, 0.03, 0.45), line_mat)
		for s in [-5.0, 5.0]:
			for k in range(7):
				var x: float = x_linea + k * 0.35
				_box(root, Vector3(x, 0.02, cz + s), Vector3(0.45, 0.03, 0.12), line_mat)

# ------------------------------------------------------- detalle del campo
#
# Lo que hay alrededor de un campo de futbol de verdad y aqui faltaba. No es
# adorno: son las cosas por las que el ojo reconoce un estadio y no "un cesped
# con rayas". Todo a medidas reales, que es lo que las hace servir de referencia
# de escala igual que los bancos de la ciudad.

## Banderines de corner: 1,5 m de asta y bandera de 40x30 cm. Reglamento FIFA.
## `tipo` (16-9-2026, Fase 2 "Componentes"), catalogo `EST_CORNER`. El default
## ("clasico") es el dibujo de siempre -palo + una bandera-, asi que un rival
## (que nunca trae esta clave) sigue saliendo identico.
## `est` (16-9-2026, ronda 3 de calidad visual): si trae `asiento1` -SOLO el
## estadio propio lo trae, `Club.perfil_estadio()` nunca lo incluye- el
## banderin sale del color de la camiseta, igual que ya heredan las butacas.
## Sin esa clave (cualquier rival) el fallback es EXACTAMENTE el dorado de
## siempre, asi que ningun estadio ajeno cambia por este retoque.
static func _corners(root: Node3D, tipo: String = "clasico", est: Dictionary = {}) -> void:
	if tipo == "sin":
		return
	## `Texturas.tela()` (16-9-2026) en vez de un color plano: sin trama ni
	## relieve, un banderin de tela se lee como carton pintado por mucha luz
	## rasante que le de el sol.
	var asta := Texturas.metal(Color(0.88, 0.88, 0.9), 0.35)
	var col_bandera := _c(est.get("asiento1"), "#f2c71f")
	var tela := Texturas.tela(col_bandera)
	var tela2 := Texturas.tela(Color(0.85, 0.87, 0.9))
	var led := StandardMaterial3D.new()
	led.albedo_color = col_bandera
	led.emission_enabled = true
	led.emission = col_bandera
	led.emission_energy_multiplier = 2.2
	var alto_asta := 2.4 if tipo == "alto" else 1.5
	for sx in [1.0, -1.0]:
		for sz in [1.0, -1.0]:
			var p := Vector3(sx * 34.0, 0, sz * 52.5)
			var m := MeshInstance3D.new()
			var c := CylinderMesh.new()
			c.top_radius = 0.015 if tipo == "alto" else 0.02
			c.bottom_radius = 0.025
			c.height = alto_asta
			c.radial_segments = 6
			m.mesh = c
			m.material_override = asta
			m.position = p + Vector3(0, alto_asta / 2.0, 0)
			if tipo == "alto":
				## Un poste largo se lee mas flexible con una inclinacion fija
				## hacia afuera del campo -el "doblado por el viento" del
				## catalogo, sin animar nada nuevo.
				m.rotation.z = -sx * 0.12
			root.add_child(m)
			var b := _box(root, p + Vector3(-sx * 0.2, alto_asta * 0.85, 0), Vector3(0.4, 0.3, 0.01), tela)
			b.rotation.y = -sx * 0.35
			if tipo == "doble":
				var b2 := _box(root, p + Vector3(-sx * 0.2, alto_asta * 0.85 - 0.32, 0), Vector3(0.36, 0.26, 0.01), tela2)
				b2.rotation.y = -sx * 0.35
			if tipo == "led":
				var base_led := MeshInstance3D.new()
				var cm := CylinderMesh.new()
				cm.top_radius = 0.09
				cm.bottom_radius = 0.09
				cm.height = 0.06
				base_led.mesh = cm
				base_led.material_override = led
				base_led.position = p + Vector3(0, 0.03, 0)
				root.add_child(base_led)

## La tinta se decide contra el fondo, no a ojo: sobre un panel claro un texto
## blanco desaparece, y la mitad de las 38 marcas traen colores claros.
static func _anuncio(texto: String, fondo: Color) -> Dictionary:
	var tinta := Color(0.06, 0.07, 0.09) if fondo.get_luminance() > 0.45 \
		else Color(0.97, 0.98, 1.0)
	return {"texto": texto.to_upper(), "fondo": fondo, "tinta": tinta}
static func _con_paleta(lista: Array, paleta: String, mi: Club) -> Array:
	if paleta == "marcas" or paleta == "" or paleta == "propia":
		return lista
	var c1 := _c(mi.color_escudo1() if mi != null else "", "#1f5f3d")
	var c2 := _c(mi.color_escudo2() if mi != null else "", "#f2f2f2")
	## Dos colores de club casi iguales no se leerían: el segundo pasa a blanco
	## o negro, el que más contraste dé con el primero.
	if absf(c1.get_luminance() - c2.get_luminance()) < 0.25:
		c2 = Color(0.96, 0.96, 0.97) if c1.get_luminance() < 0.5 else Color(0.07, 0.08, 0.1)
	var salida: Array = []
	for k in lista.size():
		var a: Dictionary = (lista[k] as Dictionary).duplicate()
		match paleta:
			"club":
				a["fondo"] = c1 if k % 2 == 0 else c2
				a["tinta"] = c2 if k % 2 == 0 else c1
			"neon":
				a["fondo"] = Color(0.03, 0.03, 0.05)
				a["tinta"] = NEON[k % NEON.size()]
			"oro":
				a["fondo"] = Color(0.05, 0.05, 0.06) if k % 2 == 0 else Color(0.96, 0.95, 0.92)
				a["tinta"] = Color(0.85, 0.68, 0.25) if k % 2 == 0 else Color(0.06, 0.06, 0.07)
			"arcoiris":
				a["fondo"] = Color.from_hsv(float(k) / float(maxi(lista.size(), 1)), 0.78, 0.82)
				a["tinta"] = _anuncio("", a["fondo"])["tinta"]
			"retro":
				a["fondo"] = Color(0.93, 0.92, 0.86)
				a["tinta"] = [Color(0.72, 0.1, 0.12), Color(0.1, 0.2, 0.55), Color(0.08, 0.08, 0.09)][k % 3]
		salida.append(a)
	return salida

## QUE DICEN LAS VALLAS. Nada inventado: el club de casa, la marca del juego
## -igual que "EA FC25"/"SOCCER MANAGER 2026" en los videos- y cuatro de las 38
## marcas de la tabla `MARCAS`, que ya existian y hasta hoy solo se veian en la
## pantalla de auspicios. Elegidas por el hash del club: el mismo estadio
## anuncia siempre lo mismo, dos estadios distintos no.
static func _anuncios_de(est: Dictionary, mi: Club) -> Array:
	var lista: Array = []
	if mi != null:
		lista.append(_anuncio(Nombres.visible(mi.nombre), _c(mi.color_escudo1(), "#1f5f3d")))
	lista.append(_anuncio("DINASTÍA", Color(0.06, 0.08, 0.12)))
	if Datos.tiene("MARCAS"):
		var t: Variant = Datos.tabla("MARCAS")
		if t is Array and not (t as Array).is_empty():
			var arr: Array = t
			var base: int = absi(mi._hash_id()) if mi != null else 7
			for k in 4:
				var m: Array = arr[(base + k * 7) % arr.size()]
				lista.append(_anuncio(Nombres.limpiar(String(m[0])),
					_c(m[1] if m.size() > 1 else "", "#e8b13a")))
	## Un color de la casa para cerrar el ciclo, si hay club.
	if mi != null:
		lista.append(_anuncio("VAMOS " + Nombres.visible(mi.nombre),
			_c(est.get("asiento1"), "#1f5f3d")))
	lista = _con_paleta(lista, String(est.get("ledPaleta", "marcas")), mi)
	## Colores elegidos a mano: el fondo y/o la letra mandan sobre la paleta.
	## Si solo se elige el fondo, la letra se busca por contraste.
	var f_propio := str(est.get("ledFondo", ""))
	var t_propia := str(est.get("ledTinta", ""))
	if f_propio != "" or t_propia != "":
		for a: Dictionary in lista:
			if f_propio != "":
				a["fondo"] = Color(f_propio)
			if t_propia != "":
				a["tinta"] = Color(t_propia)
			elif f_propio != "":
				a["tinta"] = _anuncio("", a["fondo"])["tinta"]
	return lista

## Un panel: la caja de siempre mas el rotulo por delante. `rot_y` gira el
## rotulo para que MIRE AL CAMPO -un `Label3D` sin girar mira a +Z, asi que la
## valla del lado +X necesita -90 grados y la del fondo +Z necesita 180-.
static func _una_valla(led: VallasLed, pos: Vector3, largo: float, rot_y: float,
		lateral: bool, idx: int) -> void:
	var tam := Vector3(0.25, 1.1, largo - 0.25) if lateral \
		else Vector3(largo - 0.25, 1.1, 0.25)
	var caja := _box(led, pos, tam, null)
	if led.has_meta("marco"):
		var mm := StandardMaterial3D.new()
		mm.albedo_color = led.get_meta("marco")
		mm.roughness = 0.5
		caja.material_override = mm
	var l := Label3D.new()
	l.text = ""
	l.font_size = 64
	## 64 x 0,0068 = 0,44 m de alto de letra sobre una valla de 1,1 m. Es la
	## misma proporcion que en los dos videos: el texto ocupa poco menos de la
	## mitad del alto del panel, no lo llena.
	l.pixel_size = 0.0068
	l.width = 720.0
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	## Sin sombreado: un LED emite su propia luz, no la recibe. Y de una sola
	## cara, para que no se lea del reves desde la grada de enfrente.
	l.shaded = false
	l.double_sided = false
	l.alpha_cut = Label3D.ALPHA_CUT_DISCARD
	l.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
	l.rotation.y = rot_y
	## Delante de la cara de la valla, en la direccion a la que mira el rotulo.
	var dir := Vector3(sin(rot_y), 0.0, cos(rot_y))
	l.position = pos + dir * 0.16
	led.add_child(l)
	led.registrar(caja, l, idx)
static func tunel_x(est: Dictionary) -> float:
	return 24.0 if str(est.get("tunel", "central")) == "esquina" else 0.0

## Vallas de publicidad perimetrales. Es lo mas caracteristico de un campo visto
## por television, y ademas tapa la union entre el cesped y el graderio, que era
## una linea seca que delataba la geometria.
##
## CON MARCA DE VERDAD Y CAMBIANDO SOLAS (23-9-2026). Hasta hoy eran 54 cajas de
## color liso alternando tres tonos: la silueta estaba, el contenido no -el
## mismo hueco que tenia la pantalla gigante-. Los dos videos de referencia del
## usuario coinciden en esto por encima de cualquier otra cosa del estadio: el
## anillo se LEE ("EA FC25", "SOCCER MANAGER 2026"), cada panel lleva su color y
## el anuncio cambia. Ver `visor/vallas_led.gd` para el porque de cada decision.
##
## El texto va con `Label3D`, no con una textura generada: rasterizar texto a
## una `Image` en Godot 4 obliga a montar un `SubViewport` con un `Label`
## dentro, y esto es codigo ESTATICO que construye mallas fuera del arbol.
## `Label3D` resuelve lo mismo sin viewport, con el filo de la fuente MSDF que
## el proyecto ya tiene encendido.
static func _vallas_publicidad(root: Node3D, est: Dictionary, mi: Club = null) -> void:
	var largo := 6.0
	var led := VallasLed.new()
	led.name = "VallasLed"
	root.add_child(led)
	## El marco de las vallas en el color que eligió el club (si eligió uno).
	if str(est.get("vallaCol", "")) != "":
		led.set_meta("marco", Color(str(est["vallaCol"])))
	led.sembrar(_anuncios_de(est, mi))
	var i := 0
	for lado in [1.0, -1.0]:
		var n: int = int(96.0 / largo)
		for k in range(n):
			var z: float = -48.0 + (k + 0.5) * largo
			## BUG REAL (23-9-2026): los dos banquillos viven en x≈37,5 y
			## z=±14 (`_banquillos_detalle()`), o sea justo encima de este
			## anillo. Los paneles de z=±9 y z=±15 del lado +X pasaban POR
			## DENTRO del cristal lateral y de la losa del dugout. En el lado
			## -X no hay banquillos, asi que ahi no se salta ninguno.
			if lado > 0.0 and absf(z) > 9.0 and absf(z) < 19.0:
				continue
			_una_valla(led, Vector3(lado * 37.0, 0.55, z), largo, -lado * PI / 2.0, true, i)
			i += 1
		var m2: int = int(66.0 / largo)
		for k in range(m2):
			var x: float = -33.0 + (k + 0.5) * largo
			## Delante de la boca del túnel no hay valla: es el paso a la cancha.
			if lado > 0.0 and absf(x - tunel_x(est)) < 3.0:
				continue
			_una_valla(led, Vector3(x, 0.55, lado * 55.5), largo,
				PI if lado > 0.0 else 0.0, false, i)
			i += 1

## Banquillos: la caja de metacrilato con su fila de asientos. Van en la banda
## de la tribuna principal, uno a cada lado del circulo central, como siempre.
## OJO: ya existia un _banquillos(root, dx) mas arriba, mucho mas simple. Dos
## funciones con el mismo nombre son un ERROR DE SINTAXIS en GDScript, y el motor
## no lo dice en este fichero: solo avisa de que no puede resolver la clase en
## todos los que dependen de ella. Por eso este se llama distinto.
## El asiento de plastico simple -"cristal"/"bunker"/"foso"-, sin textura a
## proposito: no todo banquillo tiene por que ser de lujo. `tinte` (ronda 4 de
## calidad visual): color de la camiseta si se conoce, gris neutro si no -es
## plastico de banquillo, no cuero, asi que se queda opaco y sin brillo.
static func _asiento_simple(tinte: Color = Color(0.14, 0.15, 0.17)) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = tinte
	m.roughness = 0.6
	return m
