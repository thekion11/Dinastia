class_name StadiumBuilder
extends RefCounted

## Construye el estadio en 3D a partir del perfil que exporta el HTML
## (perfilEstadio() en dinastia-futbol-manager base.html). Para el club del
## usuario ese perfil ES su estadio guardado en la pestaña Estadio (G.est);
## para un rival se deriva del hash de su id con los mismos catalogos, asi que
## cada club tiene un recinto propio y estable. Nada aqui se inventa al azar.

const PITCH_LEN := 105.0
const PITCH_WID := 68.0

# ---------------------------------------------------------------- utilidades

static func _c(hex, fallback := "#ffffff") -> Color:
	if typeof(hex) == TYPE_STRING and hex != "":
		return Color(hex)
	return Color(fallback)

## EL TECHO NO TAPA LA CÁMARA (MEGAPLAN fase 2): con techo de anillo la
## cámara de TV quedaba detrás de la losa cercana y medio campo se veía marrón.
## Cada losa sabe hacia dónde da afuera; la que queda entre la cámara y el
## campo pasa a una capa que las cámaras no dibujan, pero el sol sí: su sombra
## sobre la grada se mantiene (como en las retransmisiones de FC).
const CAPA_TECHO_OCULTO := 1 << 10

static func marcar_techo(mi: MeshInstance3D, fuera: Vector3) -> void:
	if mi == null:
		return
	mi.add_to_group("techo_estadio")
	mi.set_meta("fuera", Vector3(fuera.x, 0.0, fuera.z).normalized())

## Llamar cada fotograma con la cámara activa.
static func ocultar_techo_ante(cam: Camera3D) -> void:
	if cam == null or not cam.is_inside_tree():
		return
	cam.cull_mask &= ~CAPA_TECHO_OCULTO
	for n in cam.get_tree().get_nodes_in_group("techo_estadio"):
		var mi := n as MeshInstance3D
		if mi == null:
			continue
		var fuera: Vector3 = mi.get_meta("fuera", Vector3.ZERO)
		var d := (cam.global_position - mi.global_position)
		var detras := Vector3(d.x, 0.0, d.z).dot(fuera) > -3.0
		mi.layers = CAPA_TECHO_OCULTO if detras else 1

static func _box(root: Node3D, center: Vector3, size: Vector3, mat: Material) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var m := BoxMesh.new()
	m.size = size
	mi.mesh = m
	mi.position = center
	mi.material_override = mat
	root.add_child(mi)
	return mi

static func _rect_outline(root: Node3D, center: Vector3, w: float, d: float, line_w: float, y: float, mat: Material) -> void:
	_box(root, center + Vector3(0, y, d / 2.0), Vector3(w, 0.03, line_w), mat)
	_box(root, center + Vector3(0, y, -d / 2.0), Vector3(w, 0.03, line_w), mat)
	_box(root, center + Vector3(w / 2.0, y, 0), Vector3(line_w, 0.03, d), mat)
	_box(root, center + Vector3(-w / 2.0, y, 0), Vector3(line_w, 0.03, d), mat)

# ------------------------------------------------------------------- cancha

## Dibuja el corte del cesped como textura procedural. El patron y los dos tonos
## de verde salen del disenador de estadio del juego (EST_CESPED / EST_TONOS).
## CÉSPED DE VERDAD (MEGAPLAN fase 2): los verdes del diseñador salían
## fluorescentes y las dos franjas casi iguales (frente a EA FC: verde apagado y
## corte muy marcado). Se respeta el tono elegido pero con la saturación y la
## claridad de un césped real, y las franjas se separan al menos un 22 % (lo
## que da el corte en dos sentidos de la cortadora).
static func _verdes_reales(a: Color, b: Color) -> Array:
	var salida: Array = []
	for c: Color in [a, b]:
		salida.append(Color.from_hsv(c.h, minf(c.s, 0.5) * 0.9, clampf(c.v, 0.32, 0.5)))
	var ca: Color = salida[0]
	var cb: Color = salida[1]
	var claro := ca if ca.v >= cb.v else cb
	var oscuro := cb if ca.v >= cb.v else ca
	if claro.v < oscuro.v * 1.22:
		claro = Color.from_hsv(claro.h, claro.s * 0.94, minf(oscuro.v * 1.22, 0.62))
	## (El orden de vuelta respeta cuál era el "claro" del diseñador.)
	return [claro, oscuro] if ca.v >= cb.v else [oscuro, claro]

static func _make_grass_texture(patron: String, claro: Color, oscuro: Color) -> ImageTexture:
	var n := 256
	var img := Image.create(n, n, false, Image.FORMAT_RGB8)
	for y in range(n):
		for x in range(n):
			var u := float(x) / n
			var v := float(y) / n
			var band := 0
			match patron:
				## ~6 m por franja (20 a lo largo), como el corte real.
				"rayas":
					band = int(v * 20.0)
				"rayasH":
					band = int(u * 20.0)
				"damero":
					band = int(u * 10.0) + int(v * 10.0)
				"damGrande":
					band = int(u * 5.0) + int(v * 5.0)
				## (`Club` sortea "circulos": antes no casaba y salía liso.)
				"circular", "circulos":
					band = int(Vector2(u - 0.5, v - 0.5).length() * 16.0)
				"diagonal":
					band = int((u + v) * 10.0)
				"espiga":
					band = int((u + fmod(v * 6.0, 1.0)) * 8.0)
				"cruz":
					band = 1 if (absf(u - 0.5) < 0.12 or absf(v - 0.5) < 0.12) else 0
				"abanico":
					band = int(atan2(v - 0.5, u - 0.5) * 6.0)
				"rombos":
					band = int((absf(u - 0.5) + absf(v - 0.5)) * 14.0)
				"mitades":
					band = 0 if v < 0.5 else 1
				## "liso" (y lo desconocido): en un campo de verdad el corte
				## siempre se nota un poco -franjas muy suaves, un tercio-.
				_:
					band = int(v * 20.0)
					img.set_pixel(x, y, claro.lerp(oscuro, 0.33) if band % 2 == 0 else oscuro)
					continue
			img.set_pixel(x, y, claro if band % 2 == 0 else oscuro)
	var tex := ImageTexture.create_from_image(img)
	return tex

## `tipo` (16-9-2026, "el estadio por MODULOS", Fase 2 "Componentes"): el
## patron del tejido, catalogo `EST_REDTIPO`. El default ("cuadrada") es
## EXACTAMENTE el dibujo que ya existia antes de esta fase -un marco de 2 px
## repetido por el `uv1_scale` grande que ya le pone `_add_goal`-, asi que
## cualquier arco que no pida un tipo (todos los rivales, que no traen esta
## clave) sale identico a como salia siempre.
static func _make_net_texture(color: Color, tipo: String = "cuadrada") -> ImageTexture:
	var n := 32
	var img := Image.create(n, n, false, Image.FORMAT_RGBA8)
	var col_cordel := Color(color.r, color.g, color.b, 0.92)
	var col_hueco := Color(0, 0, 0, 0.0)
	## Grano en el cordel (16-9-2026), mismo truco que ya usa el grano de la
	## grada: sin variar ni el color ni el alfa pixel a pixel, el cordel sale
	## de un blanco perfectamente uniforme -una linea calculada, no una cuerda
	## real-, y con el `uv1_scale` grande de `_add_goal` esa uniformidad se
	## repite cientos de veces y se nota mucho mas que en una textura chica.
	var rng := RandomNumberGenerator.new()
	rng.seed = 17
	for y in range(n):
		for x in range(n):
			var en_cordel: bool
			match tipo:
				"fina":
					en_cordel = x < 1 or x >= n - 1 or y < 1 or y >= n - 1
				"gruesa":
					en_cordel = x < 4 or x >= n - 4 or y < 4 or y >= n - 4
				"rombo":
					## Cordel diagonal en vez de un marco recto: dos diagonales
					## cruzadas por celda, que a esta resolucion se lee como
					## una malla de rombos en vez de cuadrados.
					en_cordel = absf((x - y) % 16 - 8) < 2 or absf((x + y) % 16 - 8) < 2
				"hexagonal":
					## Aproximacion barata de un panal: filas de diagonales que
					## alternan de sentido cada 8 px, como el ladrillo hexagonal
					## visto de lejos -no hace falta la geometria real, a la
					## distancia de camara de este juego no se distingue-.
					var fila := int(y / 8.0)
					var desfase := 4 if fila % 2 == 0 else 0
					en_cordel = (x + desfase) % 8 < 2 or y % 8 < 2
				_:  # "cuadrada", el dibujo de siempre
					en_cordel = x < 2 or x >= n - 2 or y < 2 or y >= n - 2
			if en_cordel:
				var luz := 1.0 + (rng.randf() - 0.5) * 0.35
				var alfa := clampf(col_cordel.a + (rng.randf() - 0.5) * 0.12, 0.55, 1.0)
				img.set_pixel(x, y, Color(
					clampf(col_cordel.r * luz, 0.0, 1.0), clampf(col_cordel.g * luz, 0.0, 1.0),
					clampf(col_cordel.b * luz, 0.0, 1.0), alfa))
			else:
				img.set_pixel(x, y, col_hueco)
	return ImageTexture.create_from_image(img)

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
	var m_techo: StandardMaterial3D = mat_red.duplicate()
	m_techo.uv1_scale = Vector3(32, 6, 1)
	techo_red.material_override = m_techo
	goal_root.add_child(techo_red)

	# Fondo de red inclinado (desde depth_top a depth_bottom en el suelo)
	var fondo_red := MeshInstance3D.new()
	var q_fondo := QuadMesh.new()
	var alto_fondo := sqrt(height * height + (depth_bottom - depth_top) * (depth_bottom - depth_top))
	q_fondo.size = Vector2(width, alto_fondo)
	fondo_red.mesh = q_fondo
	var ang_fondo := atan2(depth_bottom - depth_top, height)
	fondo_red.rotation.x = -inward * ang_fondo
	fondo_red.position = Vector3(0, height / 2.0, z - inward * ((depth_top + depth_bottom) / 2.0))
	var m_fondo: StandardMaterial3D = mat_red.duplicate()
	m_fondo.uv1_scale = Vector3(32, 14, 1)
	fondo_red.material_override = m_fondo
	goal_root.add_child(fondo_red)

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

## `mi` (16-9-2026, Fase 2 "Componentes"): opcional, solo hace falta para
## pintar el escudo en el cesped cuando `escudoDonde` lo pide. `null` -el caso
## de siempre, y el unico que usan hoy los rivales y la ciudad- no dibuja
## ningun escudo, exactamente el comportamiento de antes de esta fase.
static func build_pitch(root: Node3D, est: Dictionary, mi: Club = null) -> void:
	var pitch := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2(PITCH_WID + 12.0, PITCH_LEN + 12.0)
	pitch.mesh = pm
	var gmat := StandardMaterial3D.new()
	var tonos := _verdes_reales(_c(est.get("cespedClaro"), "#2f8043"), _c(est.get("cespedOscuro"), "#3b9c53"))
	gmat.albedo_texture = _make_grass_texture(str(est.get("cesped", "rayas")), tonos[0], tonos[1])
	gmat.uv1_scale = Vector3(1, 1, 1)
	## El cesped se veia SINTETICO: dos verdes planos, sin grano y con la misma
	## rugosidad en los 7.000 m2. Un campo de verdad tiene brizna (relieve
	## menudo), zonas mas pisadas que otras y por eso brilla distinto segun donde
	## le da el sol. Se le anaden tres cosas, y las tres importan:
	##  1. un detalle multiplicativo de ruido fino = la brizna;
	##  2. un mapa de normales = el relieve que engancha la luz rasante;
	##  3. un mapa de rugosidad = el desgaste, que rompe el brillo uniforme.
	gmat.detail_enabled = true
	gmat.detail_blend_mode = BaseMaterial3D.BLEND_MODE_MUL
	gmat.detail_albedo = Texturas._tex_ruido(0.55, 91, false, 3)
	gmat.detail_uv_layer = BaseMaterial3D.DETAIL_UV_2
	gmat.uv2_scale = Vector3(38, 38, 1)
	gmat.normal_enabled = true
	gmat.normal_texture = Texturas._tex_ruido(0.42, 95, true, 4)
	gmat.normal_scale = 1.15
	gmat.uv1_triplanar = false
	gmat.roughness = 0.99
	## LA COLUMNA MISTERIOSA (18-9 → 25-9-2026): ERA ESTO. El ruido de rugosidad
	## iba de 0 a 1 en manchas grandes (frecuencia 0,03), así que había charcos
	## de césped con rugosidad ~0 -un espejo- y, con el relieve de brizna
	## (`bump_strength` 5), cada charco devolvía brillos redondos con volumen.
	## De día el sol va inclinado y el reflejo cae fuera; de noche `Ambience`
	## suma una luz de relleno casi vertical y el reflejo cae en el centro del
	## campo: "burbujas translúcidas quietas cerca del círculo central, solo de
	## noche". Reproducido con `pruebas/captura_columna_noche.gd`. El césped
	## nunca es un espejo: la rampa deja la rugosidad entre 0,78 y 1.
	var rugosidad := Texturas._tex_ruido(0.03, 97, false, 4)
	var rampa := Gradient.new()
	rampa.set_color(0, Color(0.78, 0.78, 0.78))
	rampa.set_color(1, Color(1, 1, 1))
	rugosidad.color_ramp = rampa
	gmat.roughness_texture = rugosidad
	gmat.roughness_texture_channel = BaseMaterial3D.TEXTURE_CHANNEL_RED
	gmat.metallic = 0.0
	gmat.metallic_specular = 0.18
	pitch.material_override = gmat
	root.add_child(pitch)

	var line_mat := StandardMaterial3D.new()
	line_mat.albedo_color = _c(est.get("lineaCol"), "#ffffff")
	## SIN `SHADING_MODE_UNSHADED` (23-9-2026). Estaba en "no iluminado", o sea
	## que la cal **no se oscurecia de noche, no recibia sombra y no recibia
	## niebla**: con el clima por defecto ("noche", donde `Ambience` baja el sol
	## a 0.25) el cesped se iba a penumbra y las rayas se quedaban en blanco
	## 1.0. Se leian como neon, y ademas entraban enteras al bloom. La cal es
	## pintura mate sobre hierba, tiene que apagarse con el resto del campo.
	line_mat.roughness = 1.0
	line_mat.metallic = 0.0

	## BUG REAL (23-9-2026): LA CANCHA ESTABA PINTADA MAS CHICA DE LO QUE ES.
	##
	## `PITCH_WID - 4` x `PITCH_LEN - 5` = **64 x 100**, sobre una cancha que
	## mide 68 x 105 y que TODO lo demas trata como tal: `_add_goal()` planta
	## los arcos en z=±52,5, los banderines de `_corners()` van a (±34, ±52,5),
	## y `control_partido.gd`/`match_playback.gd` mueven a los jugadores con
	## `MEDIO_LARGO = 52.5` / `MEDIO_ANCHO = 34.0`.
	##
	## Lo que se veia, en cada fotograma de cada camara: los arcos plantados
	## 2,5 m POR DETRAS de su propia linea de gol, sobre el cesped; los cuatro
	## banderines 2 m fuera del lateral; el punto de penal a 8,5 m de la raya
	## en vez de a 11; y las dos areas descolgadas, con sus lineas de fondo
	## asomando por FUERA de la linea de gol -tres rayas blancas paralelas
	## detras del arco-.
	_rect_outline(root, Vector3.ZERO, PITCH_WID, PITCH_LEN, 0.25, 0.02, line_mat)
	_box(root, Vector3(0, 0.02, 0), Vector3(PITCH_WID, 0.03, 0.25), line_mat)
	# areas grandes y chicas, a escala real y ancladas a la linea de gol
	for sgn in [1.0, -1.0]:
		## Area grande: 16,5 m desde la linea de gol, asi que su centro cae a
		## 52,5 - 8,25. Area chica: 5,5 m, centro a 52,5 - 2,75.
		_rect_outline(root, Vector3(0, 0, sgn * (PITCH_LEN / 2.0 - 8.25)), 40.3, 16.5, 0.2, 0.02, line_mat)
		_rect_outline(root, Vector3(0, 0, sgn * (PITCH_LEN / 2.0 - 2.75)), 18.3, 5.5, 0.2, 0.02, line_mat)
		## El penal, a 11 m de la linea de gol como manda el reglamento.
		_box(root, Vector3(0, 0.02, sgn * (PITCH_LEN / 2.0 - 11.0)), Vector3(0.35, 0.03, 0.35), line_mat)

	var center := MeshInstance3D.new()
	var cmesh := TorusMesh.new()
	cmesh.inner_radius = 9.0
	cmesh.outer_radius = 9.25
	center.mesh = cmesh
	center.position = Vector3(0, 0.02, 0)
	center.material_override = line_mat
	root.add_child(center)

	var poste := StandardMaterial3D.new()
	poste.albedo_color = _c(est.get("arcoCol"), "#ffffff")
	poste.roughness = 0.25
	poste.metallic = 0.15
	## Ronda 5 de calidad visual (17-9-2026): un pelin de variacion de
	## rugosidad y relieve -sin subir el metallic, que ya esta bien puesto
	## para un poste pintado, no cromado- para que no se lea como plastico
	## perfecto. `_tex_ruido()` directo (mismo patron que ya usa el cesped
	## unas lineas mas abajo en esta misma funcion) en vez de pasar por
	## `Texturas.metal()`, que fuerza un metallic de 0.75 -demasiado cromado
	## para un poste FIFA pintado de blanco.
	poste.roughness_texture = Texturas._tex_ruido(0.3, 141, false, 2)
	poste.normal_enabled = true
	poste.normal_texture = Texturas._tex_ruido(0.5, 143, true, 2)
	poste.normal_scale = 0.1
	var red_col := _c(est.get("redCol"), "#ffffff")
	var red_tipo := str(est.get("redTipo", "cuadrada"))
	_add_goal(root, 52.5, poste, red_col, red_tipo)
	_add_goal(root, -52.5, poste, red_col, red_tipo)

	## Lo que rodea al campo y antes faltaba: sin esto es "un cesped con rayas".
	_zona_tecnica(root, line_mat)
	_corners(root, str(est.get("corner", "clasico")), est)
	_vallas_publicidad(root, est, mi)
	_banquillos_detalle(root, str(est.get("banquillo", "cristal")), est)
	## El tunel tiene que saber donde empieza la tribuna del fondo: su boca va
	## a ras de la cara interior, no en un numero fijo (ver `_tunel()`).
	_tunel(root, str(est.get("tunel", "central")), est,
		float(geom_de_forma(String(est.get("forma", "cuenco")))["dz"]))
	_camarografos(root)
	if mi != null:
		_escudo_cancha(root, mi, str(est.get("escudoDonde", "sin")))

## El escudo pintado en el circulo central, sobre el cesped. `donde` viene del
## catalogo `EST_ESCUDOS` -esta funcion solo mira "cancha"/"todo", el resto de
## posiciones (grada/fachada/techo) las resuelve `_escudo_tribuna()` en
## `build()`, que es quien conoce la geometria del graderio-. El default de
## `est.get("escudoDonde", ...)` en TODOS los call sites de esta fase es
## "sin", a proposito distinto del default de fabrica de `EST_DEF`
## ("cancha"): un rival nunca trae esta clave, y el estadio que no ha tocado
## el diseñador tampoco debe empezar a mostrar un escudo que nunca pidio.
static func _escudo_cancha(root: Node3D, mi: Club, donde: String) -> void:
	if donde != "cancha" and donde != "todo":
		return
	## PINTURA, NO PEGATINA (29-9-2026, mapa de metas 20). De cerca -la
	## cinemática del fichaje- el escudo se veía tosco: 256 px sin mipmaps
	## estirados en 9 m, opaco y sin luz, como un plástico encima del césped.
	## Ahora: 1024 px con mipmaps y filtro anisótropo (bordes limpios de cerca y
	## sin parpadeo de lejos), recibe el sol y las sombras como el césped, y la
	## pintura deja ver un poco la hierba.
	var tex := Escudo.textura(mi, 1024)
	if tex == null:
		return
	var img := tex.get_image()
	if img != null and not img.is_empty():
		if img.is_compressed():
			img.decompress()
		img.generate_mipmaps()
		tex = ImageTexture.create_from_image(img)
	var mat := StandardMaterial3D.new()
	mat.albedo_texture = tex
	mat.albedo_color = Color(1, 1, 1, 0.55)
	mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.roughness = 1.0
	mat.metallic_specular = 0.1
	var quad := MeshInstance3D.new()
	var qm := QuadMesh.new()
	qm.size = Vector2(9.0, 9.0)
	quad.mesh = qm
	quad.rotation.x = -PI / 2.0
	quad.position = Vector3(0, 0.03, 0)
	quad.material_override = mat
	root.add_child(quad)

# ------------------------------------------------------------------ publico

## Textura de graderia: dibuja el patron de asientos elegido en el juego
## (EST_ASIENTOS) con los colores del club, y encima salpica el publico.
## Textura de graderio. Ojo con los ejes: en la cara de una BoxMesh el eje U de
## la textura cae a lo ANCHO de la rampa (subiendo el graderio) y el eje V a lo
## LARGO de la tribuna. Por eso aqui:
##   r = 0..1 subiendo la rampa   (eje X de la imagen)
##   s = 0..1 a lo largo de la tribuna (eje Y de la imagen)
## Las filas de gente son lineas de r constante (salen horizontales, como en un
## estadio real) y los sectores de asientos varian a lo largo de s.
## RESOLUCIÓN MÁS ALTA Y PÚBLICO SIN REJILLA (12-9-2026). El primer defecto real
## que el usuario reportó con una foto de verdad: la grada se ve "de mentira",
## como una tela estampada. La causa no era el patrón de asientos -esos SÍ son
## regulares en un estadio real, hasta "La Bombonera" es a rayas parejas-: era
## el PÚBLICO encima. Se pintaba en una rejilla perfecta -columna cada 3 px,
## fila cada 2, siempre las mismas columnas- y una rejilla perfecta vista de
## lejos y repetida muchas veces por el largo de la tribuna hace MOIRÉ: rayas
## verticales de color que no existen en los datos, un efecto óptico de la
## regularidad, no ruido real. Un público de verdad es un desorden, no una
## cuadrícula. Se cambia a un barrido aleatorio de posición -sin dos veces la
## misma columna- y se sube la resolución para que cada "persona" no sea un
## bloque de 2 píxeles tan burdo.
static func _make_stand_texture(patron: String, a1: Color, a2: Color, a3: Color, seed_val: int, lleno: float) -> ImageTexture:
	## 96, no 64 (23-9-2026). Hasta que se arreglo el atlas de UV del `BoxMesh`
	## (ver la nota en `build()`), de estos texeles solo se veia UN TERCIO: la
	## rampa entera se pintaba con ~21 texeles de ancho. Ahora que se ven los
	## 96, subir la resolucion de este eje si se nota -y es el eje que rayaba.
	var w := 96    # resolucion subiendo la rampa
	var h := 320   # resolucion a lo largo (se repite cada ~20 m, mismo tramo que antes)
	var img := Image.create(w, h, true, Image.FORMAT_RGB8)
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_val
	for y in range(h):
		for x in range(w):
			var r := float(x) / w
			var s := float(y) / h
			var col := a1
			match patron:
				"franjas", "vertical3":
					col = a1 if int(s * 8.0) % 2 == 0 else a2
				"aros":
					col = a1 if int(r * 5.0) % 2 == 0 else a2
				"damero":
					col = a1 if (int(s * 8.0) + int(r * 5.0)) % 2 == 0 else a2
				"degrade":
					col = a1.lerp(a2, r)
				"bicolor":
					col = a1 if s < 0.5 else a2
				"diagonal":
					col = a1 if int((s + r) * 8.0) % 2 == 0 else a2
				"moteado":
					col = a2 if int(s * 40.0 + r * 13.0) % 5 == 0 else a1
				"sectores", "mosaico":
					col = [a1, a2, a3][int(s * 3.0) % 3]
				"ola":
					col = a1.lerp(a2, 0.5 + 0.5 * sin(s * TAU * 2.0))
				"bandera":
					col = [a1, a2, a3][int(r * 3.0) % 3]
				_:
					col = a1
			## Un toque de grano por butaca -no por fila entera-: sin esto, cada
			## banda de color sale lisa como plástico pintado, ni una tela ni un
			## asiento de verdad tiene un tono 100% uniforme.
			var grano := (rng.randf() - 0.5) * 0.05
			col = Color(clampf(col.r + grano, 0, 1), clampf(col.g + grano, 0, 1), clampf(col.b + grano, 0, 1))
			img.set_pixel(x, y, col)
	_pintar_publico(img, w, h, a1, a2, lleno, rng)
	## BUG REAL ENCONTRADO Y CORREGIDO (21-9-2026): esta textura llevaba
	## `use_mipmaps=false` -sin generar mipmaps, el "ruido de gente" pixel a
	## pixel de esta imagen, repetido varias veces a lo largo de la tribuna y
	## visto de lejos, hace aliasing severo: sale como estatica de TV con
	## rayas verticales de color, no como publico. `generate_mipmaps()` rellena
	## la cadena de mip que `Image.create(..., true, ...)` solo reserva.
	img.generate_mipmaps()
	return ImageTexture.create_from_image(img)

## EL PUBLICO DE LA TEXTURA, EN FILAS DE VERDAD (23-9-2026).
##
## Compartido por `_make_stand_texture()` y `_make_stand_texture_tramos()`:
## estaba duplicado literal en las dos, y la del spike de tramos ya se quedo
## una vez sin un arreglo que la otra si recibio (los mipmaps del 21-9). Una
## sola funcion, un solo sitio donde arreglarlo.
##
## LA TERCERA VUELTA DEL MISMO PROBLEMA, y esta vez atacando la causa de raiz:
##   - 21-9: el publico se pintaba UN TEXEL por persona y salia "estatica de
##     TV". Se corrigio pintando bloques del tamaño real de una persona (8
##     texeles a lo largo) + mipmaps + filtro anisotropico. Mejoro, no cerro.
##   - 23-9 (hoy): seguia rayando fuerte en la rampa vista a la rasante. La
##     causa que quedaba: las personas se sorteaban en posicion LIBRE, asi que
##     en el eje que sube la rampa el dato seguia siendo ruido blanco a 0,2 m
##     -no hay nada coherente que un mip pueda promediar, por mucho bloque que
##     tenga en el otro eje-.
##
## Arreglo: el publico va en FILAS ALINEADAS, con su escalon oscuro entre fila
## y fila y sus escaleras cruzando la grada. Eso convierte el ruido en una
## señal PERIODICA, que es justo lo que un mip promedia bien, y ademas es lo
## que se ve en `ea_fc25_referencia.mp4`: filas, no una mancha de confeti.
static func _pintar_publico(img: Image, w: int, h: int, a1: Color, a2: Color,
		lleno: float, rng: RandomNumberGenerator) -> void:
	var piel := [Color(0.95, 0.78, 0.62), Color(0.80, 0.60, 0.42),
		Color(0.55, 0.38, 0.26), Color(0.36, 0.24, 0.17)]
	var ropa := [Color(0.85, 0.85, 0.88), Color(0.15, 0.16, 0.2), a1, a2,
		Color(0.7, 0.2, 0.2), Color(0.2, 0.3, 0.7)]
	## Un texel del eje largo mide 20 m (lo que repite la textura) / h. Una
	## persona sentada ocupa ~0,5 m: ese es el bloque del arreglo del 21-9.
	var alto_persona: int = maxi(2, int(round(0.5 / (20.0 / h))))
	var piel_persona: int = maxi(1, alto_persona / 3)
	## Y en el eje de la rampa, una fila de butacas ocupa ~0,85 m. Con la
	## rampa mas larga (3 niveles, ~21 m) y `w` texeles, eso son:
	var paso_fila: int = maxi(3, int(round(float(w) * 0.85 / 21.0)))
	var lleno_c := clampf(lleno, 0.0, 1.0)
	## Las escaleras: dos por cada tramo de 20 m, cruzando la grada de abajo
	## arriba. Rompen la repeticion y son lo que hace que una grada se lea como
	## grada -sin ellas es una alfombra de gente.
	var escaleras: Array[int] = [int(h * 0.31), int(h * 0.78)]
	var ancho_escalera: int = maxi(2, alto_persona / 3)
	for fila in range(int(w / paso_fila)):
		var x0 := fila * paso_fila
		## El escalon entre fila y fila: una linea mas oscura del propio color
		## del asiento, no un gris inventado.
		for y in range(h):
			img.set_pixel(x0, y, img.get_pixel(x0, y).darkened(0.42))
		var y_asiento := rng.randi_range(0, alto_persona - 1)
		while y_asiento < h:
			var en_escalera := false
			for e in escaleras:
				if absi(y_asiento - e) < ancho_escalera + alto_persona / 2:
					en_escalera = true
					break
			if not en_escalera and rng.randf() < lleno_c:
				var col_ropa: Color = ropa[rng.randi_range(0, ropa.size() - 1)]
				var col_piel: Color = piel[rng.randi_range(0, piel.size() - 1)]
				## Se deja el ultimo texel de la fila sin cubrir: es el respaldo
				## de la butaca asomando por detras del hincha, y es lo que
				## mantiene visible el patron de colores del club incluso con la
				## grada llena.
				for dy in range(alto_persona - 1):
					var yy := y_asiento + dy
					if yy >= h:
						break
					var col: Color = col_piel if dy < piel_persona else col_ropa
					for dx in range(1, maxi(2, paso_fila - 1)):
						img.set_pixel(mini(x0 + dx, w - 1), yy, col)
			y_asiento += alto_persona
	## Las escaleras se pintan al final, encima de todo: hormigon, sin gente.
	var cemento := Color(0.30, 0.31, 0.33)
	for e in escaleras:
		for dy in range(ancho_escalera):
			var yy := e + dy
			if yy >= h:
				continue
			for x in range(w):
				img.set_pixel(x, yy, cemento.darkened(rng.randf() * 0.10))

## FASE 3 "TRAMO" de "el estadio por MODULOS", conectada de verdad (22-9-2026).
## Nacio como spike (16-9-2026, `pruebas/spike_tramo.gd`) para decidir con una
## captura real si "tercios con patron completo distinto" se sostiene
## visualmente antes de comprometer una forma de datos -SI se sostuvo (ver
## LEEME.md, "SPIKE CORRIDO CON PANTALLA REAL", 18-9-2026), con una condicion:
## quien llame a esto tiene que usar `uv1_scale.y=1` en el material, NO el
## repetido-cada-20m que usa `_make_stand_texture()` -si no, el patron de
## tercios se repite ~4,5 veces sobre los 90m de tribuna y las 2 costuras
## reales se convierten en ~13 falsas-. `build()` ya respeta esto. Misma
## logica de dibujo que `_make_stand_texture()`, repetida tres veces -una por
## tercio de `s`- en vez de generalizada con parametros: se dejo asi a
## proposito en el spike y sigue rindiendo bien, no vale la pena abstraerla.
static func _make_stand_texture_tramos(patrones: Array, colores: Array, seed_val: int, lleno: float) -> ImageTexture:
	## 96 por el mismo motivo que su hermana, ver la nota alli.
	var w := 96
	var h := 320
	## `true` (con mipmaps) + `generate_mipmaps()` al final, igual que
	## `_make_stand_texture()`: esta funcion nacio de un spike aislado el
	## 16-9, ANTES de que el 21-9 encontrara y corrigiera la "estatica de TV"
	## de la grada por falta de mipmaps -el spike nunca se toco con esa
	## correccion porque no estaba conectado a nada real. Conectarla ahora sin
	## portar tambien ese arreglo habria reintroducido a proposito un bug ya
	## encontrado y cerrado, esta vez en una tribuna real.
	var img := Image.create(w, h, true, Image.FORMAT_RGB8)
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_val
	for y in range(h):
		var s := float(y) / h
		var tercio: int = clampi(int(s * 3.0), 0, 2)
		var patron: String = String(patrones[tercio]) if tercio < patrones.size() else "franjas"
		var trio: Array = colores[tercio] if tercio < colores.size() else [Color.WHITE, Color.BLACK, Color.GRAY]
		var a1: Color = trio[0]
		var a2: Color = trio[1]
		var a3: Color = trio[2] if trio.size() > 2 else trio[0]
		## `s_local` recalcula la posicion DENTRO del tercio -de 0 a 1-, no la
		## global: si no, un patron de rayas se veria comprimido a un tercio de
		## su frecuencia normal en vez de repetirse igual que en una tribuna
		## entera.
		var s_local := fmod(s * 3.0, 1.0)
		for x in range(w):
			var r := float(x) / w
			var col := a1
			match patron:
				"franjas", "vertical3":
					col = a1 if int(s_local * 8.0) % 2 == 0 else a2
				"aros":
					col = a1 if int(r * 5.0) % 2 == 0 else a2
				"damero":
					col = a1 if (int(s_local * 8.0) + int(r * 5.0)) % 2 == 0 else a2
				"degrade":
					col = a1.lerp(a2, r)
				"bicolor":
					col = a1 if s_local < 0.5 else a2
				"diagonal":
					col = a1 if int((s_local + r) * 8.0) % 2 == 0 else a2
				"moteado":
					col = a2 if int(s_local * 40.0 + r * 13.0) % 5 == 0 else a1
				"sectores", "mosaico":
					col = [a1, a2, a3][int(s_local * 3.0) % 3]
				"ola":
					col = a1.lerp(a2, 0.5 + 0.5 * sin(s_local * TAU * 2.0))
				"bandera":
					col = [a1, a2, a3][int(r * 3.0) % 3]
				_:
					col = a1
			var grano := (rng.randf() - 0.5) * 0.05
			col = Color(clampf(col.r + grano, 0, 1), clampf(col.g + grano, 0, 1), clampf(col.b + grano, 0, 1))
			img.set_pixel(x, y, col)
	## Publico: el mismo barrido aleatorio en BLOQUES del tamaño real de una
	## persona -no de un texel-, portado tal cual de `_make_stand_texture()`
	## (ver el comentario de esa funcion, 21-9-2026, para el bug real que este
	## calculo evita: un texel por persona en un eje que repite cada 20m deja
	## 7/8 del "cuerpo" como ruido independiente, y sale como estatica de TV en
	## vez de gente). Sigue con la ropa/piel del tercio central para los tres
	## tercios -no vale la pena bandear tambien el publico: la costura que
	## importa es la de la GRADA, no la de la gente encima-.
	var trio_c: Array = colores[1] if colores.size() > 1 else colores[0]
	_pintar_publico(img, w, h, trio_c[0], trio_c[1], lleno, rng)
	img.generate_mipmaps()
	return ImageTexture.create_from_image(img)

# ------------------------------------------------------------------ estadio

## El material del techo, por tipo -"membrana"/"retractil" son lona tensada
## de verdad (`Texturas.tela()`, mas clara y sin metal), el resto es la
## cubierta metalica estructural de siempre (`Texturas.metal()`, oscura).
## Ambas funciones cachean por color, asi que llamarla dos veces con el mismo
## `tipo` devuelve el mismo material -barato, y consistente con como ya
## comparten material las 4 tribunas cuando ninguna pide un techo distinto.
static func _techo_mat(tipo: String, col: String = "") -> StandardMaterial3D:
	if tipo == "membrana" or tipo == "retractil":
		return Texturas.tela(_c(col, "#e0e3d9"), 0.5)
	return Texturas.metal(_c(col, "#33383f"), 0.55)

## LA FACHADA (B6.2). Cinco pieles para el mismo muro; el color vacío deja el
## tono propio de cada material.
static func _mat_fachada(tipo: String, col: String) -> StandardMaterial3D:
	match tipo:
		"ladrillo":
			return Texturas.ladrillo(_c(col, "#8a4a2b"))
		"vidrio":
			var v: StandardMaterial3D = Texturas.cristal(true, false).duplicate()
			v.albedo_color = _c(col, "#6f8fa6")
			v.metallic = 0.6
			v.roughness = 0.12
			return v
		"membrana":
			return Texturas.tela(_c(col, "#e8e8e2"), 0.6)
		"metal":
			return Texturas.metal(_c(col, "#8a9097"), 0.45)
	return Texturas.hormigon(_c(col, "#6b7079"), 51)

## EL TÚNEL DE VERDAD (7-10-2026): medio ancho del hueco que abre en la
## tribuna del fondo +Z, y su eje X (el tipo «esquina» va hacia el córner).
const TUNEL_HUECO := 3.2
static func tunel_x(est: Dictionary) -> float:
	return 24.0 if str(est.get("tunel", "central")) == "esquina" else 0.0

## Los trozos [centro, largo] de un tramo `largo` centrado en `centro` que
## quedan a los dos lados del hueco [g0, g1]. Si el hueco no lo toca, uno solo.
static func _tramos_sin_hueco(centro: float, largo: float, g0: float, g1: float) -> Array:
	var a := centro - largo / 2.0
	var b := centro + largo / 2.0
	if g1 <= a or g0 >= b:
		return [Vector2(centro, largo)]
	var sal: Array = []
	if g0 > a + 0.05:
		sal.append(Vector2((a + g0) / 2.0, g0 - a))
	if b > g1 + 0.05:
		sal.append(Vector2((g1 + b) / 2.0, b - g1))
	return sal

## Geometria del recinto segun la forma elegida en el disenador del juego.
## dx/dz son la distancia del CENTRO de cada tribuna al centro del campo.
## La tribuna tiene 11 de fondo, asi que su cara interior queda en dx-5.5:
## esa cara nunca puede quedar por dentro de la valla perimetral (38 a lo ancho,
## 56.5 tras el arco) o el graderio se comeria la cancha. Por eso el minimo
## practico es dx>=44.5 y dz>=63.5, aunque "compacto ingles" se quede en ese
## limite justamente porque su gracia es estar encima del campo.
## Devuelve {dx, dz, esquinas, abierta} — abierta = indice de tribuna omitida.
static func geom_de_forma(forma: String) -> Dictionary:
	match forma:
		"ingles":
			return {"dz": 64.0, "dx": 45.0, "esquinas": true, "abierta": -1}
		"rect":
			return {"dz": 67.0, "dx": 48.0, "esquinas": false, "abierta": -1}
		"herradura":
			return {"dz": 66.0, "dx": 47.0, "esquinas": true, "abierta": 1}
		"caldera":
			return {"dz": 65.0, "dx": 46.0, "esquinas": true, "abierta": -1}
		"oval":
			return {"dz": 74.0, "dx": 54.0, "esquinas": true, "abierta": -1}
		## Formas nuevas (MEGAPLAN B6). "dos": solo las dos laterales, los
		## fondos a cielo abierto (campos chicos y de barrio). "principal":
		## cuatro cajas y una gran tribuna de honor una bandeja más alta.
		"dos":
			return {"dz": 67.0, "dx": 47.0, "esquinas": false, "abierta": -1, "abiertas": [0, 1]}
		"principal":
			return {"dz": 67.0, "dx": 48.0, "esquinas": false, "abierta": -1, "principal": 2}
		_:  # cuenco
			return {"dz": 68.0, "dx": 49.0, "esquinas": true, "abierta": -1}

## Altura total del graderio, para que las camaras se coloquen contra el estadio
## real y no contra numeros fijos (un recinto de 8.000 y uno de 90.000 no admiten
## el mismo encuadre — es la misma idea que ya documenta EST_CAMS en el juego).
## ============================================================================
## EL GRADERIO POR BANDEJAS DE VERDAD (23-9-2026)
## ============================================================================
## Pedido del usuario: *"el estadio debe ser modular para lo de reformar el
## estadio y habrá que hacerle más bandejas y variantes para cuando uno agrande
## el estadio (máximo 150.000)"*.
##
## Hasta hoy una tribuna era UNA rampa continua de 11 m de fondo, y su altura
## salia de multiplicar 6,5 m por el numero de bandejas. Eso tenia un problema
## de raiz que la auditoria de esta misma sesion dejo anotado: con 3 bandejas la
## rampa sube 18 m en 11 m de fondo, o sea **58,6 grados**. Ninguna grada real
## pasa de ~35, y a 5 bandejas habria sido un acantilado de 70 grados.
##
## Ahora cada bandeja es su propia rampa, con su propio fondo, su pendiente
## acotada y un FRENTE vertical entre una y la siguiente -que es exactamente el
## perfil de un estadio de varias bandejas, y de paso es donde cuelgan los
## telones-. La tribuna crece hacia AFUERA al sumar bandejas, no solo hacia
## arriba, que es lo que hace que 5 bandejas sigan pareciendo un estadio.
##
## La cara interior (la que da al cesped) NO se mueve: sigue a `FRENTE_TRIBUNA`
## del eje nominal `dx`/`dz`. Asi la relacion con la cancha, las camaras, las
## vallas y el tunel es la misma con 1 bandeja que con 5.

## Lo que sube una grada de verdad. 33 grados es el limite de lo comodo; por
## encima, una tribuna se lee como una pared.
const RAKE_GRADOS := 33.0
## Fondo en planta de UNA bandeja.
const FONDO_BANDEJA := 10.0
## Lo que se echa atras cada bandeja respecto de la de abajo.
const RETRANQUEO_BANDEJA := 3.5
## El frente vertical entre una bandeja y la siguiente: palcos, pasillo y la
## reja donde se cuelgan los trapos.
const FRENTE_BANDEJA := 3.0
## Distancia del eje nominal de la tribuna (dx/dz) a su cara interior.
const FRENTE_TRIBUNA := 5.5
## Altura del borde de la primera bandeja sobre el cesped.
const ALTURA_PIE := 1.5
const NIVELES_MAX := 5

## Cuantas bandejas se dibujan de verdad. Manda lo que el club diseño, acotado
## por lo que el aforo justifica -un estadio de 8.000 con 5 bandejas seria
## falso-. `EstadioPropio.niveles_maximos()` repite este criterio a proposito,
## para no ofrecer en la pantalla de diseño una bandeja que el visor no va a
## dibujar (y cobrarla).
static func niveles_de(est: Dictionary, cap_efectiva: int) -> int:
	var niveles_est := int(est.get("niveles", 2))
	var niveles_cap: int = clampi(
		int(floor(float(cap_efectiva) / 22000.0)) + 1, 1, NIVELES_MAX)
	return clampi(mini(niveles_est, niveles_cap), 1, NIVELES_MAX)

## Lo que sube UNA bandeja.
static func subida_bandeja() -> float:
	return FONDO_BANDEJA * tan(deg_to_rad(RAKE_GRADOS))

## Altura total del graderio: las bandejas mas los frentes que las separan.
static func altura_de(est: Dictionary, cap_efectiva: int) -> float:
	var n := niveles_de(est, cap_efectiva)
	return ALTURA_PIE + float(n) * subida_bandeja() + float(n - 1) * FRENTE_BANDEJA

## Lo que ocupa la tribuna en planta, de la cara interior hacia afuera.
static func fondo_tribuna(niveles: int) -> float:
	return FONDO_BANDEJA + float(maxi(niveles - 1, 0)) * RETRANQUEO_BANDEJA

## El centro de la tribuna en el eje que la cruza. La cara interior se queda
## clavada en `eje - FRENTE_TRIBUNA` cueste lo que cueste, y lo que se mueve al
## crecer es el centro y la cara exterior.
static func centro_tribuna(eje: float, niveles: int) -> float:
	return eje - FRENTE_TRIBUNA + fondo_tribuna(niveles) / 2.0

## `colores`: `[claro, oscuro]` de la piel elegida -ver `Comercial.color_balon()`-.
## Vacío se queda con la piel "clásico" (blanco y negro) de siempre, así que
## nada que llame a esto sin conocer todavía la piel del club se rompe.
static func spawn_ball(root: Node3D, pos: Vector3, colores: Array = []) -> Balon3D:
	var claro: Color = colores[0] if colores.size() > 0 else Color("#f8faf6")
	var oscuro: Color = colores[1] if colores.size() > 1 else Color("#1a1a1a")
	var ball := Balon3D.crear(pos, claro, oscuro, String(colores[2]) if colores.size() > 2 else "clasico")
	root.add_child(ball)
	return ball

## est: perfil de perfilEstadio(). cap_efectiva: aforo real ya ajustado por las
## obras del club (capEfectivo() en el HTML). ocupacion: 0..1 de gente en la grada.
## LA EXPLANADA DE FONDO (13-9-2026). El césped es una plancha de solo
## 80×117 m -PITCH_WID/LEN más 12 de margen-, y NINGUNA otra geometría cubre
## el suelo más allá de eso. Encontrado con una captura real desde "Detrás
## del arco": esa cámara queda apenas FUERA del borde de esa plancha, y mirar
## hacia el campo desde ahí enseña una franja de "nada" -el cielo asomando
## por abajo, aquí de un gris azulado plano- antes de llegar al verde. Una
## base grande y neutra, bien por debajo del césped para no pelear en el
## z-fighting, asegura que NINGUNA cámara del estadio -sea cual sea su forma
## o tamaño- pueda ver ese hueco, sin tener que calcular el caso por caso.
static func _explanada_de_fondo(root: Node3D) -> void:
	var pm := PlaneMesh.new()
	pm.size = Vector2(400.0, 400.0)
	var mi := MeshInstance3D.new()
	mi.mesh = pm
	mi.position = Vector3(0, -0.15, 0)
	## `Texturas.hormigon()` ya devuelve el MATERIAL completo, no una textura
	## suelta -asignarlo a `albedo_texture` no compila: son tipos distintos-.
	##
	## CORREGIDO (17-9-2026), reportado por el usuario como una franja
	## horizontal rota/temblorosa justo despues del perimetro: este plano de
	## 400x400 m con el `uv1_scale` normal de `hormigon()` (pensado para una
	## fachada de pocos metros, no para un suelo de fondo) se repite mas de
	## 200 veces de lado a lado. Visto en angulo rasante desde cualquier
	## camara del estadio -que es exactamente como se ve, nunca de frente-,
	## esa densidad de detalle fino (el mapa de normales sobre todo) hace
	## aliasing/muaré: no es un fallo de carga ni z-fighting, es la textura
	## repitiendose demasiadas veces para lo que el anti-aliasing del juego
	## puede filtrar a esa distancia. DUPLICADO y aflojado -mucho menos
	## repeticion y sin mapa de normales-, porque esta plancha es puro relleno
	## de fondo (el propio comentario de arriba ya lo dice: "para no pelear en
	## z-fighting", nunca se pensó como superficie protagonista).
	var mat_explanada: StandardMaterial3D = Texturas.hormigon(Color(0.30, 0.31, 0.33), 41).duplicate()
	## 26-9-2026: sin rayas en ángulo rasante. Se repite en el mundo (un
	## mosaico cada 2 m, el tamaño de una losa de hormigón) y con filtrado
	## anisótropo, en vez de estirar una textura sobre 400 m.
	mat_explanada.uv1_world_triplanar = true
	mat_explanada.uv1_scale = Vector3(0.5, 0.5, 0.5)
	mat_explanada.normal_enabled = false
	mi.material_override = mat_explanada
	root.add_child(mi)

## 0=sur 1=norte 2=este 3=oeste, mismo orden que el comentario de `stands` más
## abajo. `perfil()` (`nucleo/estadio_propio.gd`) usa estos mismos nombres para
## las claves de `est["bandejas"]`, así que este índice y ese diccionario
## siempre hablan el mismo idioma sin traducir nada en el medio.
const NOMBRE_BANDEJA := {0: "sur", 1: "norte", 2: "este", 3: "oeste"}

## `mi` (16-9-2026, Fase 2 "Componentes"): igual que en `build_pitch()`,
## opcional y solo para el escudo en grada/fachada/techo -`null` no cambia
## nada respecto a antes de esta fase.
static func build(root: Node3D, est: Dictionary, cap_efectiva: int, ocupacion: float, seed_val: int, mi: Club = null) -> void:
	_explanada_de_fondo(root)
	var forma := str(est.get("forma", "cuenco"))
	var g := geom_de_forma(forma)
	var dz: float = g["dz"]
	var dx: float = g["dx"]
	var abierta: int = g["abierta"]
	## Tribunas que no se construyen: la de `abierta` o varias ("dos").
	var abiertas: Array = g.get("abiertas", [abierta] if abierta >= 0 else [])
	var principal: int = int(g.get("principal", -1))
	## Dónde cruza el túnel la tribuna del fondo +Z (-1000 = sin túnel).
	var tunel_x0 := tunel_x(est) if not (0 in abiertas) else -1000.0

	# Niveles: los que el club realmente construyo, pero nunca mas bandejas de
	# las que el aforo justifica (un estadio de 8.000 con 3 bandejas seria falso).
	var niveles := niveles_de(est, cap_efectiva)
	var alto := altura_de(est, cap_efectiva)

	var techo := str(est.get("techo", "anillo"))

	## RONDA 5 DE CALIDAD VISUAL (17-9-2026): `stand_mat`/`roof_mat` eran color
	## plano puro -y no son un detalle chico como los banderines de corner, son
	## LA FACHADA ENTERA de las 4 tribunas y todo el techo, la superficie mas
	## grande y mas a la vista de todo el estadio despues del cesped. Hormigon
	## de verdad para el muro (misma factoria que ya usa el tunel y la
	## ciudad), y el techo por tipo: membrana es LONA tensada de verdad -PTFE/
	## ETFE, lo mismo que ya modela `Texturas.tela()`, no pintura sobre metal-,
	## el resto es la cubierta metalica estructural de siempre.
	## B6 (25-9-2026): la fachada y el techo, del material y color elegidos.
	var stand_mat := _mat_fachada(str(est.get("fachada", "hormigon")), str(est.get("fachadaCol", "")))
	var techo_col := str(est.get("techoCol", ""))
	var roof_mat := _techo_mat(techo, techo_col)
	var crowd_mat := StandardMaterial3D.new()
	crowd_mat.albedo_texture = _make_stand_texture(
		str(est.get("asientoP", "franjas")),
		_c(est.get("asiento1"), "#2b6b45"), _c(est.get("asiento2"), "#ffffff"),
		_c(est.get("asiento3"), "#20272a"), seed_val, clampf(ocupacion, 0.05, 0.98))
	crowd_mat.roughness = 1.0
	## BUG REAL, SEGUNDA PARTE (21-9-2026): generar mipmaps en la imagen (mas
	## arriba en `_make_stand_texture()`) no alcanzo por si solo -la grada se
	## ve casi rasante desde una camara a nivel de cancha, y el filtro por
	## defecto de un material (`LINEAR_WITH_MIPMAPS`, sin anisotropico) igual
	## sub-muestrea fuerte en ese angulo: sigue aliasing. El "publico" de esta
	## textura es ruido pixel a pixel -sin coherencia local que un mip
	## isotropico pueda promediar bien-, asi que es el caso de libro para
	## filtrado anisotropico explicito.
	crowd_mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC

	# 0 = fondo sur, 1 = fondo norte, 2 = lateral este, 3 = lateral oeste.
	# "cara" apunta desde la tribuna hacia el campo.
	#
	# `pos` ya NO es el eje nominal: es el centro REAL de la tribuna, que se
	# corre hacia afuera a medida que se le suman bandejas (ver
	# `centro_tribuna()`). La cara que da al cesped se queda siempre en el mismo
	# sitio, que es lo que importa para la cancha y las camaras.
	var fondo_trib := fondo_tribuna(niveles)
	var cz := centro_tribuna(dz, niveles)
	var cx := centro_tribuna(dx, niveles)
	var stands := [
		{"i": 0, "pos": Vector3(0, alto / 2.0, cz), "size": Vector3(dx * 2.0 - 4.0, alto, fondo_trib),
			"cara": Vector3(0, 0, -1)},
		{"i": 1, "pos": Vector3(0, alto / 2.0, -cz), "size": Vector3(dx * 2.0 - 4.0, alto, fondo_trib),
			"cara": Vector3(0, 0, 1)},
		{"i": 2, "pos": Vector3(cx, alto / 2.0, 0), "size": Vector3(fondo_trib, alto, dz * 2.0 - 4.0),
			"cara": Vector3(-1, 0, 0)},
		{"i": 3, "pos": Vector3(-cx, alto / 2.0, 0), "size": Vector3(fondo_trib, alto, dz * 2.0 - 4.0),
			"cara": Vector3(1, 0, 0)},
	]

	# El graderio va INCLINADO, no como un muro vertical: es lo que hace que se
	# lea como estadio y no como una caja, y ademas la superficie raqueada recibe
	# de frente la luz de los focos, asi que el publico se ve tambien de noche.
	# La pendiente ya NO sale de dividir la altura total entre el fondo total
	# -eso daba 58,6 grados con 3 bandejas-: es fija y acotada, y lo que crece
	# con las bandejas es el numero de rampas, no su inclinacion.
	var ang := deg_to_rad(RAKE_GRADOS)
	var subida_b := subida_bandeja()

	for s in stands:
		if s["i"] in abiertas:
			continue
		## FORMA "principal" (MEGAPLAN B6): la tribuna de los banquillos (+X)
		## lleva una bandeja más que el resto, como los estadios con una gran
		## tribuna de honor. Las demás tribunas no cambian.
		var niv_s := niveles
		var alto_s := alto
		var fondo_s := fondo_trib
		var pos: Vector3 = s["pos"]
		var size: Vector3 = s["size"]
		if s["i"] == principal:
			niv_s = mini(niveles + 1, NIVELES_MAX)
			alto_s = ALTURA_PIE + float(niv_s) * subida_bandeja() + float(niv_s - 1) * FRENTE_BANDEJA
			fondo_s = fondo_tribuna(niv_s)
			pos = Vector3(centro_tribuna(dx, niv_s), alto_s / 2.0, 0)
			size = Vector3(fondo_s, alto_s, dz * 2.0 - 4.0)
		var cara: Vector3 = s["cara"]
		var lateral: bool = absf(cara.x) > 0.5
		## BANDEJA (16-9-2026): si esta tribuna tiene un estilo propio en
		## `est["bandejas"]`, se usa en vez del global -asientoP y techo, los dos
		## únicos campos que esta primera fase deja variar por tribuna (altura y
		## forma siguen siendo del recinto entero, ver el comentario del contrato
		## en `estadio_propio.gd`)-. Sin `personalizar_bandejas` activo
		## `est.get("bandejas", {})` da `{}` y `estilo` sale siempre vacío, así
		## que el resto del loop sigue leyendo exactamente `asientoP`/`techo`
		## globales, cero cambio de comportamiento para cualquier estadio que no
		## haya tocado el interruptor -rivales incluidos, que nunca traen la clave.
		var estilo: Dictionary = (est.get("bandejas", {}) as Dictionary).get(NOMBRE_BANDEJA.get(s["i"], ""), {})
		var asientoP_i := str(estilo.get("asientoP", est.get("asientoP", "franjas")))
		var techo_i := str(estilo.get("techo", techo))
		## B6.1: los colores de ESTA tribuna. Si no se tocaron, `est_s` es el
		## mismo diccionario de siempre y nada cambia.
		var est_s: Dictionary = est
		var col_i1 := str(estilo.get("col1", ""))
		var col_i2 := str(estilo.get("col2", ""))
		if col_i1 != "" or col_i2 != "":
			est_s = est.duplicate()
			if col_i1 != "":
				est_s["asiento1"] = col_i1
			if col_i2 != "":
				est_s["asiento2"] = col_i2
		## TRAMO (22-9-2026): si esta tribuna tiene tercios propios en
		## `est["tramos"]" -independiente de "bandejas", ver el contrato en
		## `estadio_propio.gd`-, son 3 patrones ya resueltos (nunca vacíos: la
		## capa de `nucleo` ya rellenó cada tercio en blanco con `asientoP_i`).
		## Sin `personalizar_tramos` activo `est_s.get("tramos", {})` da `{}` y
		## esto sale `[]` siempre, cero cambio para cualquier estadio que no
		## haya tocado el interruptor.
		var tramos_i: Array = (est_s.get("tramos", {}) as Dictionary).get(NOMBRE_BANDEJA.get(s["i"], ""), [])
		# Muro exterior del recinto (la fachada). El interior NO se rellena con
		# una caja solida: si se hace, la rampa de asientos queda dentro de ella
		# y el publico no se ve desde ninguna camara.
		var muro_pos: Vector3 = pos + cara * (-fondo_s / 2.0 + 0.5)
		var muro_size := Vector3(1.0, alto_s, size.z) if lateral else Vector3(size.x, alto_s, 1.0)
		var pie: Vector3 = pos - cara * (fondo_s / 2.0 - FONDO_BANDEJA / 2.0)
		## EL TÚNEL ATRAVIESA ESTA TRIBUNA (7-10-2026, pedido: «la zona del
		## túnel debe ser más real; el estadio será navegable»). En la tribuna
		## del túnel (+Z) el muro, el zócalo y la primera bandeja se parten y
		## dejan un hueco de verdad: ahí va el pasillo de `TunelVestuario`.
		var hueco: bool = int(s["i"]) == 0 and tunel_x0 > -999.0
		if hueco:
			for tr: Vector2 in _tramos_sin_hueco(pos.x, size.x, tunel_x0 - TUNEL_HUECO, tunel_x0 + TUNEL_HUECO):
				_box(root, Vector3(tr.x, muro_pos.y, muro_pos.z), Vector3(tr.y, alto_s, 1.0), stand_mat)
				_box(root, Vector3(tr.x, ALTURA_PIE / 2.0, pie.z), Vector3(tr.y, ALTURA_PIE, FONDO_BANDEJA), stand_mat)
			## Sobre la puerta del muro, el muro sigue.
			var alto_puerta: float = TunelVestuario.ALTO + 0.4
			if alto_s > alto_puerta:
				_box(root, Vector3(tunel_x0, (alto_s + alto_puerta) / 2.0, muro_pos.z),
					Vector3(TUNEL_HUECO * 2.0, alto_s - alto_puerta, 1.0), stand_mat)
		else:
			_box(root, muro_pos, muro_size, stand_mat)
			# Zocalo bajo la primera bandeja, para que no se vea el hueco desde el
			# campo. Va pegado a la cara interior, no al centro de la tribuna: con
			# varias bandejas el centro se va muy hacia atras.
			var zocalo_size := Vector3(FONDO_BANDEJA, ALTURA_PIE, size.z) if lateral \
				else Vector3(size.x, ALTURA_PIE, FONDO_BANDEJA)
			_box(root, Vector3(pie.x, ALTURA_PIE / 2.0, pie.z), zocalo_size, stand_mat)

		var largo_rake := sqrt(FONDO_BANDEJA * FONDO_BANDEJA + subida_b * subida_b)
		## El angulo CON SIGNO, que es el que hay que deshacer en las butacas y
		## los hinchas para que queden de pie (ver `_butacas()`). Sin el signo
		## la mitad de las tribunas quedaria con el publico inclinado el doble
		## en vez de derecho.
		var rake_firmado: float = ang * (signf(-cara.x) if lateral else signf(cara.z))
		# La textura de graderio se repite cada ~20 m a lo largo. Sin esto se
		# estira sobre los 90 m de tribuna y el publico sale como churretones.
		var largo_tribuna: float = size.z if lateral else size.x
		## Si esta tribuna pidió un patrón de asiento propio, se genera SU PROPIA
		## textura -misma función, mismos colores globales (esta fase no varía
		## color por tribuna, solo patrón y techo), solo cambia `asientoP_i`- en
		## vez de reusar la compartida. Si no, sigue compartiendo `crowd_mat` como
		## siempre: nada nuevo se genera para un estadio sin bandejas propias.
		## TRAMO tiene prioridad sobre Bandeja cuando los dos aplican a la misma
		## tribuna: 3 patrones dicen más que 1, y `_tramos_personalizados()` ya
		## usó el patrón de Bandeja como base de los tercios en blanco, así que
		## no se pierde la elección de Bandeja, se refina.
		var deck_mat: StandardMaterial3D
		var es_tramo := tramos_i.size() == 3
		if es_tramo:
			var trio := [_c(est_s.get("asiento1"), "#2b6b45"), _c(est_s.get("asiento2"), "#ffffff"),
				_c(est_s.get("asiento3"), "#20272a")]
			deck_mat = StandardMaterial3D.new()
			deck_mat.albedo_texture = _make_stand_texture_tramos(tramos_i,
				[trio, trio, trio], seed_val, clampf(ocupacion, 0.05, 0.98))
			deck_mat.roughness = 1.0
			## Sin esto, esta textura queda con el filtro por defecto -no el
			## anisotropico que `crowd_mat` sí tiene (ver el bug real de
			## "estática de TV" del 21-9)-, y a la rasante con que se ve una
			## grada desde la cancha eso vuelve a hacer aliasing.
			deck_mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
		elif asientoP_i != str(est_s.get("asientoP", "franjas")) or est_s != est:
			deck_mat = StandardMaterial3D.new()
			deck_mat.albedo_texture = _make_stand_texture(asientoP_i,
				_c(est_s.get("asiento1"), "#2b6b45"), _c(est_s.get("asiento2"), "#ffffff"),
				_c(est_s.get("asiento3"), "#20272a"), seed_val, clampf(ocupacion, 0.05, 0.98))
			deck_mat.roughness = 1.0
			## Mismo arreglo que arriba -este material tampoco lo heredaba de
			## `crowd_mat`, un vacío ya existente desde la Fase 1 (Bandeja,
			## 16-9), anterior al hallazgo del 21-9. Se corrige de paso.
			deck_mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
		else:
			deck_mat = crowd_mat.duplicate()
		## El texto del spike lo advierte: la variante de tercios NO puede
		## reusar el repetido-cada-20m -convierte 2 costuras reales en ~13
		## falsas-, tiene que ir a repeticion 1 (la textura ya cubre la
		## tribuna entera, de punta a punta, sin repetir).
		var repite: float = 1.0 if es_tramo else maxf(1.0, largo_tribuna / 20.0)
		## BUG REAL, MEDIDO (23-9-2026, `pruebas/diagnostico_uv_caja.gd`): un
		## `BoxMesh` NO mapea la textura entera a cada cara, reparte las seis
		## en un atlas de 3x2. La cara de arriba del deck -o sea TODA LA GRADA,
		## la superficie mas grande del estadio- solo veia **U 0,333..0,667 y
		## V 0,5..1,0: el 17% de la imagen**, ampliado 3x a lo ancho y 2x a lo
		## largo. Consecuencias que se veian y no se sabian explicar: el patron
		## de butacas que el usuario elige en Club -> Estadio (franjas, damero,
		## sectores, bandera...) se dibujaba entero en `_make_stand_texture()`
		## pero en pantalla solo salia un SEXTO de el, y la densidad real de
		## texeles a lo ancho de la rampa era un tercio de la generada, que es
		## justo el eje que hacia el aliasing de "estatica de TV" del 21-9.
		##
		## Se corrige remapeando ese rectangulo a 0..1 en vez de cambiar la
		## malla: `uv = uv*escala + desplazamiento`, asi que para llevar
		## u:[1/3,2/3] -> [0,1] hace falta escala 3 y desplazamiento -1, y para
		## v:[1/2,1] -> [0,1] escala 2 y desplazamiento -1 (por la repeticion).
		## Las otras cinco caras quedan fuera de rango, y da igual: son los
		## cantos de una losa de 0,4 m que no se ven desde ninguna camara.
		deck_mat.uv1_scale = Vector3(3.0, 2.0 * repite, 1.0)
		deck_mat.uv1_offset = Vector3(-1.0, -repite, 0.0)

		## UNA RAMPA POR BANDEJA, no una sola para toda la tribuna. Cada una
		## arranca mas arriba y mas atras que la de abajo, y entre ellas va un
		## FRENTE vertical -el paño de palcos y pasillo de un estadio real, y
		## la reja de donde cuelgan los trapos-.
		var largo_deck: float = size.z - 1.0 if lateral else size.x - 1.0
		for b in niv_s:
			## El centro de ESTA bandeja, medido desde la cara interior de la
			## tribuna hacia afuera. `cara` apunta al campo, o sea que restarle
			## `cara` es alejarse de la cancha.
			var avance: float = float(b) * RETRANQUEO_BANDEJA + FONDO_BANDEJA / 2.0
			var centro_b: Vector3 = pos + cara * (fondo_s / 2.0) - cara * avance
			var y_pie: float = ALTURA_PIE + float(b) * (subida_b + FRENTE_BANDEJA)
			## La primera bandeja de la tribuna del túnel va en dos trozos.
			var piezas: Array = [Vector2(centro_b.x, largo_deck)]
			if hueco and b == 0:
				piezas = _tramos_sin_hueco(centro_b.x, largo_deck, tunel_x0 - TUNEL_HUECO, tunel_x0 + TUNEL_HUECO)
			for pz: Vector2 in piezas:
				var deck := MeshInstance3D.new()
				var dm := BoxMesh.new()
				dm.size = Vector3(largo_rake, 0.4, pz.y) if lateral \
					else Vector3(pz.y, 0.4, largo_rake)
				deck.mesh = dm
				deck.position = Vector3(pz.x, y_pie + subida_b / 2.0, centro_b.z)
				deck.rotation = Vector3(0, 0, rake_firmado) if lateral \
					else Vector3(rake_firmado, 0, 0)
				## Cada bandeja lleva SU COPIA del material: comparten la misma
				## textura, pero un material compartido significaria que tocarle el
				## `uv1_*` a una se lo toca a las cinco.
				## COLOR POR ANILLO (28-9-2026): si este anillo de esta tribuna
				## tiene color propio, su textura y sus butacas salen con él.
				var niveles_col: Array = estilo.get("niveles", [])
				var col_b := String(niveles_col[b]) if b < niveles_col.size() else ""
				var est_b: Dictionary = est_s
				if col_b != "" and not es_tramo:
					est_b = est_s.duplicate()
					est_b["asiento1"] = col_b
					var mat_b := StandardMaterial3D.new()
					mat_b.albedo_texture = _make_stand_texture(asientoP_i, _c(col_b, "#2b6b45"),
						_c(est_s.get("asiento2"), "#ffffff"), _c(est_s.get("asiento3"), "#20272a"), seed_val + b, clampf(ocupacion, 0.05, 0.98))
					mat_b.roughness = 1.0
					mat_b.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
					mat_b.uv1_scale = deck_mat.uv1_scale
					mat_b.uv1_offset = deck_mat.uv1_offset
					deck.material_override = mat_b
				else:
					deck.material_override = deck_mat.duplicate()
				root.add_child(deck)
				## Un trozo más corto repite la textura menos veces (misma densidad).
				if piezas.size() > 1 and not es_tramo and deck.material_override is StandardMaterial3D:
					var rp := maxf(1.0, pz.y / 20.0)
					(deck.material_override as StandardMaterial3D).uv1_scale.y = 2.0 * rp
					(deck.material_override as StandardMaterial3D).uv1_offset.y = -rp
				_butacas(deck, dm.size, lateral, est_b, ocupacion, alto_s, rake_firmado, b)
				_telones(deck, dm.size, lateral, est_s, seed_val + int(s["i"]) * 31 + b * 7)
			## El frente vertical bajo la bandeja: tapa el hueco que dejaria ver
			## por debajo y es lo que le da al estadio su perfil escalonado. La
			## primera bandeja no lo lleva -ahi va el zocalo.
			if b > 0:
				## SOLO EL PETO, NO UNA PARED HASTA ABAJO (corregido con una
				## captura, 23-9-2026). El primer intento le dio de alto
				## `FRENTE_BANDEJA + subida_b` = 9,5 m, y el resultado era un
				## muro negro colgando sobre la bandeja de abajo que se comía
				## media tribuna. La cuenta real: entre el borde alto de una
				## bandeja y el borde bajo de la siguiente hay exactamente
				## `FRENTE_BANDEJA`, porque `y_pie` sube `subida_b + FRENTE`.
				## Lo de debajo NO se tapa: es el voladizo, y debajo del
				## voladizo hay butacas de la bandeja de abajo, que es
				## justamente como se ve un estadio de varias bandejas.
				var frente_pos: Vector3 = centro_b + cara * (FONDO_BANDEJA / 2.0 - 0.4)
				var frente_size := Vector3(0.8, FRENTE_BANDEJA, largo_deck) if lateral \
					else Vector3(largo_deck, FRENTE_BANDEJA, 0.8)
				_box(root, Vector3(frente_pos.x, y_pie - FRENTE_BANDEJA / 2.0 + 0.2,
					frente_pos.z), frente_size, stand_mat)

		var techo_cabeceras_i := techo_i in ["anillo", "total", "membrana", "retractil", "visera"]
		var techo_lados_i := techo_i != "sin"
		var quiere_techo := techo_cabeceras_i if s["i"] < 2 else techo_lados_i
		if quiere_techo:
			## "total" promete "un anillo profundo que llega casi hasta la
			## raya" y dibujaba EXACTAMENTE lo mismo que "anillo" -mismo
			## material, mismas cabeceras, mismo vuelo de 4 m-: dos opciones
			## del catalogo, las dos cobradas, pixel por pixel iguales. Ahora
			## "total" vuela el doble, que es lo unico que promete.
			var vuelo := 7.0 if techo_i == "total" else (4.0 if techo_i == "anillo" else 2.0)
			## BUG REAL DE Z-FIGHTING (23-9-2026): la losa de una cabecera y la
			## de un lateral ocupaban **el mismo volumen** en las 4 esquinas
			## -con el default son 8,5 x 8,5 m con la Y identica y el mismo
			## material-. Dos planos coincidentes parpadean, y encima justo
			## donde apuntan las camaras de dron y cenital. Se recorta la losa
			## de las CABECERAS para que acabe donde empieza la del lateral;
			## la esquina la cubre su propia losa, mas abajo.
			var recorte: float = 2.0 * (fondo_s / 2.0 + vuelo)
			var rs := Vector3(maxf(size.x + 2.0 - recorte, 4.0), 0.5, size.z + vuelo) if not lateral \
				else Vector3(size.x + vuelo, 0.5, size.z + 2.0)
			## Mismo criterio que el `roof_mat` global -ver `_techo_mat()`-. Solo
			## se pide un material nuevo cuando esta tribuna pidió un techo
			## distinto del global; si no, sigue compartiendo `roof_mat` tal
			## cual, igual que antes de esta fase.
			var roof_mat_i := roof_mat if techo_i == techo else _techo_mat(techo_i, techo_col)
			marcar_techo(_box(root, pos + cara * (vuelo / 2.0) + Vector3(0, alto_s / 2.0 + 0.4, 0), rs, roof_mat_i), -cara)

	## LAS ESQUINAS TAMBIÉN LLEVAN GENTE (22-9-2026). "Falta un tramo" -el
	## usuario lo vio de inmediato justo después de la ronda de las butacas
	## reales-: en una forma "esquinas: true" (cuenco/oval/caldera/inglés/
	## herradura, todas menos "rect") estos 4 bloques cierran el hueco entre
	## dos tribunas rectas, pero usaban `stand_mat` -la misma fachada de
	## hormigón LISO de los muros, ni un solo asiento ni una sola cabeza-. En
	## un recinto ovalado de verdad la grada da toda la vuelta sin cortes; acá
	## se veía como un tramo de pared ciega metido a la fuerza entre dos
	## tribunas llenas. Misma textura de grada que ya usa el resto del
	## estadio (`_make_stand_texture()`, mismos colores/patrón/ocupación),
	## sin repetir (`uv1_scale=1`, el bloque es chico, 12m, no hace falta
	## repetir cada 20m) y con el mismo filtro anisotrópico que ya lleva
	## `crowd_mat` -mismo criterio que Tramo, no dejar una textura de grada
	## nueva sin la corrección de aliasing ya encontrada el 21-9-2026-.
	## BUG REAL (23-9-2026, ultimo de los 12 de la auditoria): la condicion era
	## `esquinas and abierta < 0`, o sea que en cuanto una tribuna faltaba
	## -"herradura"- se quitaban LAS CUATRO esquinas, incluidas las dos del
	## extremo CERRADO, donde las dos tribunas vecinas si existen y el hueco
	## entre ellas queda a la vista. Ahora se decide esquina por esquina.
	if bool(g["esquinas"]):
		var esquina_mat := StandardMaterial3D.new()
		esquina_mat.albedo_texture = _make_stand_texture(
			str(est.get("asientoP", "franjas")),
			_c(est.get("asiento1"), "#2b6b45"), _c(est.get("asiento2"), "#ffffff"),
			_c(est.get("asiento3"), "#20272a"), seed_val, clampf(ocupacion, 0.05, 0.98))
		esquina_mat.roughness = 1.0
		esquina_mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
		esquina_mat.uv1_scale = Vector3(1.0, 1.0, 1.0)
		## BUG REAL (23-9-2026): el bloque iba en `(dx-3, dz-3)` con 12 m de
		## lado, o sea x de dx-9 a dx+3. La cara interior de las tribunas está
		## en dx-5,5: **la esquina sobresalía 3,5 m hacia dentro del cuenco**,
		## como un pilar metido delante de las dos tribunas vecinas, y a la vez
		## enterraba el extremo de cada rampa con sus butacas. En la forma más
		## chica ("inglés", dx=45) llegaba a 2 m de la línea de banda.
		##
		## Y SEGUNDA VUELTA, con el graderío por bandejas: la esquina tiene que
		## usar el MISMO centro y el MISMO fondo que las tribunas, que ahora
		## dependen de cuántas bandejas hay. Dejada en `(dx, dz)` con 11 m
		## fijos, en un estadio de 5 bandejas quedaba como una torre suelta de
		## 46 m por delante de las dos tribunas, en vez de cerrando el hueco.
		for sx in [1.0, -1.0]:
			for sz in [1.0, -1.0]:
				## `stands` numera 0 = fondo en +dz, 1 = fondo en -dz. Una
				## esquina solo se quita si da al fondo que no existe.
				if (0 in abiertas and sz > 0.0) or (1 in abiertas and sz < 0.0):
					continue
				_esquina_grada(root, sx, sz, dx, dz, alto, niveles,
					esquina_mat, stand_mat, ang, est, ocupacion, seed_val,
					techo in ["anillo", "total", "membrana", "retractil"])

	# vallas perimetrales, siempre por dentro de la cara interior de la tribuna
	if bool(est.get("vallas", true)):
		## Metal de verdad (17-9-2026, ronda 5): es literalmente una malla/reja
		## perimetral, el material menos "plastico" posible para esto.
		var valla := Texturas.metal(Color(0.12, 0.13, 0.15), 0.5)
		## Con el paso del túnel abierto: la valla del fondo +Z se parte.
		for tr: Vector2 in _tramos_sin_hueco(0.0, 78.0, tunel_x(est) - 2.6, tunel_x(est) + 2.6):
			_box(root, Vector3(tr.x, 0.6, 56.5), Vector3(tr.y, 1.2, 0.3), valla)
		_box(root, Vector3(0, 0.6, -56.5), Vector3(78.0, 1.2, 0.3), valla)
		_box(root, Vector3(38.0, 0.6, 0), Vector3(0.3, 1.2, 113.0), valla)
		_box(root, Vector3(-38.0, 0.6, 0), Vector3(0.3, 1.2, 113.0), valla)

	## CONECTORES MUDOS DEL DISEÑADOR DE ESTADIO (23-9-2026). El usuario pidió
	## "una buena revisión a las bandejas en el ámbito de los conectores", y es
	## el mismo patrón que este proyecto ya persiguió dos veces en `nucleo/`:
	## cosas que EXISTEN en el catálogo, se cobran, y no las mira nadie. En el
	## visor había cuatro, y una de ellas es el capítulo MÁS CARO del diseñador.
	_pista_atletismo(root, est, dx, dz)
	## El túnel de verdad: pasillo, cubierta del hueco y vestuario.
	TunelVestuario.montar(root, est, niveles, mi)
	_banderas(root, est, dx, dz, alto, niveles, mi)
	## LOS GUIÑOS DEL ESTADIO REAL (MEGAPLAN fase 4, E9): lo que dice su rasgo.
	GuinosEstadio.montar(root, est, dx, dz, fondo_tribuna(niveles), alto)
	_focos(root, str(est.get("focos", "torres")), dx, dz, alto, color_luz(est), str(est.get("focosCol", "")))
	## B6.2: lo que hay FUERA del recinto: taquillas, tienda y estacionamiento.
	if bool(est.get("exterior", false)):
		_exterior(root, est, dx, dz, niveles, mi)
	_pantallas(root, str(est.get("pantalla", "dos")), dz, alto, est, mi, abierta, abiertas)
	if mi != null:
		_escudo_tribuna(root, mi, str(est.get("escudoDonde", "sin")), dx, dz, alto)
	## Obras con andamios y grúa, palcos, prensa, museo, tienda y la mascota
	## (26-9-2026, `EstadioExtras`).
	EstadioExtras.construir(root, est, dx, dz, alto, niveles, mi)

## LA ESQUINA, COMO GRADA DE VERDAD (23-9-2026).
##
## Pedido directo del usuario -"siento que un error grave son las bandejas de
## las esquinas, se ven feas"-, y tenía toda la razón. Eran **un cubo sólido**
## con la textura de grada encima, y ahí se juntaban dos cosas malas:
##
##   1. Por el atlas de UV de `BoxMesh` (medido hoy, ver `build()`), cada cara
##      del cubo solo mostraba **el 17% de la textura**, ampliado 3x2. Al lado
##      de unas tribunas que desde hoy sí muestran la textura entera, la
##      esquina se veía como un borrón gigante.
##   2. Era una PARED VERTICAL entre dos gradas inclinadas. Aunque la textura
##      hubiera estado bien, no había forma de que leyera como continuación del
##      cuenco.
##
## Ahora la esquina es lo que es en un estadio de verdad: la misma grada dando
## la vuelta, en diagonal a 45°, con una rampa por bandeja a la misma altura
## que las de las tribunas vecinas. Cada rampa es un `QuadMesh` -que sí mapea
## la textura entera- y detrás va un bloque oscuro que le da masa y tapa el
## exterior.
static func _esquina_grada(root: Node3D, sx: float, sz: float, dx: float, dz: float,
		alto: float, niveles: int, grada_mat: Material, muro_mat: Material,
		ang: float, est: Dictionary, ocupacion: float, seed_val: int,
		techo: bool = false) -> void:
	var dir := Vector3(sx, 0.0, sz).normalized()
	## Donde se cortarían las dos caras interiores de las tribunas vecinas: es
	## el vértice del que arranca el chaflán.
	var p0 := Vector3(sx * (dx - FRENTE_TRIBUNA), 0.0, sz * (dz - FRENTE_TRIBUNA))
	var subida_b := subida_bandeja()
	var largo_rake := sqrt(FONDO_BANDEJA * FONDO_BANDEJA + subida_b * subida_b)
	## El quad mira a +Z sin girar; se le da la vuelta para que mire AL CAMPO
	## (-dir) y se le echa el respaldo hacia atrás con la misma pendiente que
	## las tribunas.
	var giro := atan2(-sx, -sz)
	var masa := fondo_tribuna(niveles)
	## El bloque de atrás: da masa y cierra el exterior. Va detrás de la ÚLTIMA
	## bandeja, no detrás de la primera. Puesto a `masa/2 + medio fondo` -que es
	## lo que parecía razonable- su cara quedaba a 5,5 m del vértice y se tragaba
	## las bandejas 1 a 4, que arrancan a 8,5 m: en la captura se veía un hueco
	## negro donde tenía que haber grada. La cara delantera tiene que quedar a
	## `fondo_tribuna` exactos, que es donde acaba la última rampa.
	var centro_masa := p0 + dir * (fondo_tribuna(niveles) + masa * 0.5)
	var caja := _box(root, Vector3(centro_masa.x, alto / 2.0, centro_masa.z),
		Vector3(masa, alto, masa), muro_mat)
	caja.rotation.y = giro
	## La losa de techo de la esquina. El "anillo perimetral" tenia CUATRO
	## huecos sin techo justo sobre las esquinas -y a la vez dos losas
	## solapadas ahi mismo, que es el z-fighting que se arregla en `build()`-.
	if techo:
		var tapa := _box(root, Vector3(centro_masa.x, alto + 0.4, centro_masa.z),
			Vector3(masa * 1.5, 0.5, masa * 1.5), muro_mat)
		marcar_techo(tapa, Vector3(sx, 0.0, sz).normalized())
		tapa.rotation.y = giro
	for b in niveles:
		var avance: float = float(b) * RETRANQUEO_BANDEJA + FONDO_BANDEJA / 2.0
		var centro := p0 + dir * avance
		var y_pie: float = ALTURA_PIE + float(b) * (subida_b + FRENTE_BANDEJA)
		## El chaflán se ensancha con cada bandeja: cuanto más atrás, más largo
		## es el hueco que hay entre los extremos de las dos tribunas vecinas.
		var ancho: float = 12.0 + float(b) * RETRANQUEO_BANDEJA * 2.0
		## `PlaneMesh`, NO `QuadMesh` (23-9-2026). Dos motivos, y los dos eran
		## bugs de verdad del primer intento:
		##
		##  1. LA TEXTURA IBA GIRADA 90 GRADOS, que es la razon de fondo de que
		##     la esquina siguiera "viendose fea" despues de dejar de ser un
		##     cubo. `_make_stand_texture()` genera la imagen con **U = subiendo
		##     la rampa** y **V = a lo largo de la tribuna**: las filas de gente
		##     son lineas de U constante y las escaleras bandas de V constante.
		##     Un `QuadMesh` vive en su plano XY, asi que los ejes quedaban
		##     cruzados y en las cuatro esquinas las filas corrian VERTICALES
		##     subiendo la pendiente y las escaleras cruzaban la rampa de lado a
		##     lado. Un `PlaneMesh` vive en XZ con U en X y V en Z: exactamente
		##     el mismo reparto que la cara de arriba de un deck.
		##  2. La normal de un `QuadMesh` es +Z y la de un `PlaneMesh` es +Y.
		##     `_butacas()` coloca a la gente en el plano XZ del nodo y la
		##     levanta en Y, o sea que necesita la normal en +Y. Con el quad,
		##     los hinchas habrian quedado DENTRO del plano y mirando de canto.
		var q := MeshInstance3D.new()
		var pm := PlaneMesh.new()
		pm.size = Vector2(largo_rake, ancho)
		q.mesh = pm
		q.position = Vector3(centro.x, y_pie + subida_b / 2.0, centro.z)
		## Misma base que un deck de tribuna, girada al angulo de la esquina:
		## local X sube la rampa en diagonal, local Y es la normal, local Z
		## corre a lo largo del chaflan.
		var theta := atan2(-dir.z, dir.x)
		q.basis = Basis().rotated(Vector3(0, 0, 1), ang).rotated(Vector3.UP, theta)
		## Su propio material, para que la textura repita a lo largo del chaflan
		## con la misma densidad que en las tribunas (cada ~20 m). Con el
		## material compartido de las cuatro esquinas no se podia: `ancho`
		## cambia en cada bandeja.
		var mat_b: StandardMaterial3D = grada_mat.duplicate()
		mat_b.uv1_scale = Vector3(1.0, maxf(1.0, ancho / 20.0), 1.0)
		q.material_override = mat_b
		root.add_child(q)
		## Y hinchada de verdad, no solo textura: hasta ahora `_esquina_grada()`
		## recibia `est`, `ocupacion` y `seed_val` y **no usaba ninguno de los
		## tres** -el sintoma delator que esta misma auditoria ya documento para
		## el `_banquillos(root, dx)` que se borro-. En la practica las esquinas
		## no tenian ni una persona en 3D mientras las tribunas de al lado
		## estaban llenas. Se pasa `b + 1` como bandeja para que NUNCA pidan el
		## modelo caro de butacas: son cuatro rampas mas y solo se ven de lejos.
		_butacas(q, Vector3(largo_rake, 0.4, ancho), true, est, ocupacion,
			alto, ang, b + 1)

## El escudo en la grada/fachada/techo -las posiciones de `EST_ESCUDOS` que
## necesitan la geometria del recinto, por eso viven en `build()` y no en
## `build_pitch()` (ver `_escudo_cancha()` para "cancha"/"todo"). Uno solo por
## posicion, en la tribuna principal (la que da a la camara "Principal (TV)"),
## que es donde de verdad se ve -repetirlo en las 4 tribunas seria ruido.
static func _escudo_tribuna(root: Node3D, mi: Club, donde: String, dx: float, dz: float, alto: float) -> void:
	if donde not in ["grada", "fachada", "techo", "todo"]:
		return
	var tex := Escudo.textura(mi, 256)
	if tex == null:
		return
	var mat := StandardMaterial3D.new()
	mat.albedo_texture = tex
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	## LAS TRES POSICIONES, CORREGIDAS (23-9-2026). Las tres estaban con
	## metros fijos y las tres fallaban:
	##   - "grada": un cuadro VERTICAL de 6 m centrado en `alto*0.7`. Con 1
	##     nivel (alto=6,5) su borde de arriba caia en 7,55 y el techo va de
	##     6,65 a 7,15: **el escudo cruzaba la cubierta y asomaba por encima**,
	##     el mismo bug que la pantalla. Con 3 niveles quedaba a 13,65 m de
	##     altura pero en z=dz-5,4, donde la rampa esta a 1,5 m: **flotando 12
	##     m en el aire por delante de la grada**. Un escudo de grada se PINTA
	##     SOBRE LAS BUTACAS, asi que ahora se apoya en la rampa con su misma
	##     inclinacion y su tamaño escala con el recinto.
	##   - "fachada": estaba en `dz - 5.15`, o sea por DENTRO del cuenco. La
	##     fachada real -el muro exterior- esta al otro lado, en `dz + 5.2`.
	##   - "techo": un cuadro VERTICAL plantado en el plano de la losa, que la
	##     atravesaba y sobresalia 2 m por arriba. Va tumbado sobre ella.
	## La pendiente es la de UNA bandeja, no la de la tribuna entera -con el
	## graderío por bandejas esa segunda cuenta ya no existe-, y el escudo se
	## apoya en la PRIMERA bandeja, que es la que se ve de frente desde la
	## cancha.
	var ang := deg_to_rad(RAKE_GRADOS)
	var largo_rake := sqrt(FONDO_BANDEJA * FONDO_BANDEJA + subida_bandeja() * subida_bandeja())
	if donde == "grada" or donde == "todo":
		_escudo_en_grada(root, mat, dz, alto, ang, largo_rake)
	## "todo" también, que es lo que promete su propia etiqueta ("En todas
	## partes"). Estaba escrito `if donde == "fachada":` a secas, así que la
	## opción más cara del catálogo pintaba cancha + grada + techo y **nunca la
	## fachada** -justo lo contrario de lo que dice el comentario de esta misma
	## función-.
	if donde == "fachada" or donde == "todo":
		var tam_f: float = clampf(alto * 0.45, 3.0, 8.0)
		var quad := MeshInstance3D.new()
		var qm := QuadMesh.new()
		qm.size = Vector2(tam_f, tam_f)
		quad.mesh = qm
		quad.position = Vector3(0, maxf(alto * 0.5, tam_f * 0.6), dz + 5.75)
		## Mira hacia AFUERA del estadio: es la cara que ve quien llega.
		quad.material_override = mat
		root.add_child(quad)
	if donde == "techo" or donde == "todo":
		## "todo" ya cubrio "cancha" desde `_escudo_cancha()`; aqui se suma el
		## de techo ademas del de grada, para que "en todas partes" sea de
		## verdad las 4 posiciones y no solo dos.
		var mat2: StandardMaterial3D = mat.duplicate()
		var quad2 := MeshInstance3D.new()
		var qm2 := QuadMesh.new()
		qm2.size = Vector2(clampf(alto * 0.4, 3.0, 7.0), clampf(alto * 0.4, 3.0, 7.0))
		quad2.mesh = qm2
		## Tumbado sobre la losa (que ocupa y de alto+0.15 a alto+0.65) y
		## mirando al cielo, no de canto atravesandola.
		quad2.position = Vector3(0, alto + 0.68, dz - 3.0)
		quad2.rotation.x = -PI / 2.0
		quad2.material_override = mat2
		root.add_child(quad2)

## El escudo apoyado EN LA RAMPA de la tribuna principal, con su inclinacion.
## Un `QuadMesh` mira a +Z sin girar; para que quede tumbado sobre una rampa
## que sube hacia +Z con angulo `ang` hay que girarlo `-(PI/2 + ang)` en X
## -comprobado despejando `R_x(t)·(0,0,1) = (0, cos(ang), -sin(ang))`, que es
## la normal de esa rampa-.
static func _escudo_en_grada(root: Node3D, mat: Material, dz: float, alto: float,
		ang: float, largo_rake: float) -> void:
	var tam: float = clampf(FONDO_BANDEJA * 0.6, 3.0, 8.0)
	## A media rampa de la primera bandeja: abajo lo tapan las butacas reales y
	## arriba se lo come el peto de la bandeja siguiente.
	var f := 0.5
	var pos := Vector3(0,
		ALTURA_PIE + largo_rake * f * sin(ang) + 0.35,
		dz - FRENTE_TRIBUNA + largo_rake * f * cos(ang))
	var quad := MeshInstance3D.new()
	var qm := QuadMesh.new()
	qm.size = Vector2(tam, tam)
	quad.mesh = qm
	quad.position = pos
	quad.rotation.x = -(PI / 2.0 + ang)
	quad.material_override = mat
	root.add_child(quad)

## LA PISTA DE ATLETISMO (23-9-2026). `pista` es un bool del catálogo cuyo
## capítulo cuesta **480.000 -el más caro del diseñador de estadio- y hasta hoy
## no se dibujaba NADA**: `EstadioPropio.ambiente()` le restaba 3,5 de ánimo (la
## contrapartida de alejar al público) y esa penalización era todo lo que el
## jugador recibía por su dinero. Cero referencias en todo `visor/`.
##
## Se dibuja en la explanada que ya existe entre la reja perimetral y la cara
## interior de la tribuna, que es exactamente donde va una pista de verdad. En
## "óvalo" (dx=54) esa franja da 10,5 m -una pista completa-; en las formas
## compactas sale más estrecha, que es precisamente por lo que un recinto de
## atletismo se diseña ovalado.
static func _pista_atletismo(root: Node3D, est: Dictionary, dx: float, dz: float) -> void:
	if not bool(est.get("pista", false)):
		return
	var tartan := StandardMaterial3D.new()
	tartan.albedo_color = Color(0.62, 0.24, 0.17)
	tartan.roughness = 0.95
	var cal := StandardMaterial3D.new()
	cal.albedo_color = Color(0.92, 0.93, 0.92)
	cal.roughness = 1.0
	## De la reja hacia afuera, hasta donde empieza el graderío.
	var x0 := 38.0
	var z0 := 56.5
	var x1: float = dx - FRENTE_TRIBUNA
	var z1: float = dz - FRENTE_TRIBUNA
	var ancho_x: float = x1 - x0
	var ancho_z: float = z1 - z0
	if ancho_x < 1.0 or ancho_z < 1.0:
		return
	## El anillo: dos bandas largas, dos cortas y las cuatro esquinas.
	for sx in [1.0, -1.0]:
		_box(root, Vector3(sx * (x0 + ancho_x / 2.0), 0.012, 0.0),
			Vector3(ancho_x, 0.02, z0 * 2.0), tartan)
	for sz in [1.0, -1.0]:
		_box(root, Vector3(0.0, 0.012, sz * (z0 + ancho_z / 2.0)),
			Vector3(x0 * 2.0, 0.02, ancho_z), tartan)
		for sx in [1.0, -1.0]:
			_box(root, Vector3(sx * (x0 + ancho_x / 2.0), 0.012, sz * (z0 + ancho_z / 2.0)),
				Vector3(ancho_x, 0.02, ancho_z), tartan)
	## Las calles: una raya blanca cada 1,22 m, que es la medida reglamentaria.
	var calles: int = maxi(1, int(ancho_x / 1.22))
	for k in range(1, calles + 1):
		var off: float = x0 + float(k) * 1.22
		if off >= x1:
			break
		for sx in [1.0, -1.0]:
			_box(root, Vector3(sx * off, 0.025, 0.0), Vector3(0.05, 0.02, z0 * 2.0), cal)
	var calles_z: int = maxi(1, int(ancho_z / 1.22))
	for k in range(1, calles_z + 1):
		var off: float = z0 + float(k) * 1.22
		if off >= z1:
			break
		for sz in [1.0, -1.0]:
			_box(root, Vector3(0.0, 0.025, sz * off), Vector3(x0 * 2.0, 0.02, 0.05), cal)

## LAS BANDERAS DE LA HINCHADA (23-9-2026). Otro conector mudo: `banderas` tiene
## SEIS valores en el catálogo, `EstadioPropio.ambiente()` paga +1,5 de ánimo
## por "tifo" y por "bufandas"... y **en todo `visor/` no había una sola
## referencia**. El jugador elegía "Tifo gigante en la popular" y no aparecía
## ningún tifo.
static func _banderas(root: Node3D, est: Dictionary, dx: float, dz: float,
		alto: float, niveles: int, mi: Club) -> void:
	var tipo := String(est.get("banderas", "club"))
	if tipo == "sin":
		return
	var c1 := _c(est.get("asiento1"), "#1f5f3d")
	var c2 := _c(est.get("asiento2"), "#e8e8e8")
	var z_frente: float = dz - FRENTE_TRIBUNA
	match tipo:
		"tifo":
			## Un telón gigante sobre la popular: el escudo del club, a lo
			## ancho de media tribuna. Es lo que promete la etiqueta, y no hace
			## falta arte nuevo -se reutiliza `Escudo.textura()`-.
			if mi == null:
				return
			var tex := Escudo.textura(mi, 512)
			if tex == null:
				return
			var mat := StandardMaterial3D.new()
			mat.albedo_texture = tex
			mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			mat.roughness = 1.0
			var lado: float = clampf(alto * 0.75, 8.0, 26.0)
			var q := MeshInstance3D.new()
			var qm := QuadMesh.new()
			qm.size = Vector2(lado, lado)
			q.mesh = qm
			q.position = Vector3(0, alto * 0.55, -(z_frente + 1.0))
			q.material_override = mat
			root.add_child(q)
		"bufandas":
			## Una banda de color a media grada: miles de bufandas en alto se
			## leen de lejos como una franja maciza del color del club.
			var banda := Texturas.tela(c1)
			for sz in [1.0, -1.0]:
				var b := _box(root, Vector3(0, alto * 0.5, sz * (z_frente + 0.8)),
					Vector3(dx * 1.2, 2.6, 0.2), banda)
				b.name = "BandaBufandas"
		_:
			## "club", "paises" y "banderines": mástiles en lo alto del recinto.
			## Cambian el reparto y el color, que es lo que las distingue.
			var colores: Array[Color] = []
			if tipo == "club":
				colores = [c1, c2]
			else:
				colores = [Color(0.85, 0.2, 0.2), Color(0.95, 0.85, 0.25),
					Color(0.2, 0.4, 0.85), Color(0.95, 0.95, 0.95), Color(0.2, 0.7, 0.35)]
			var cuantos := 10 if tipo != "banderines" else 22
			var asta := Texturas.metal(Color(0.8, 0.81, 0.84), 0.4)
			for i in cuantos:
				var a := TAU * float(i) / float(cuantos)
				var d := Vector2(cos(a), sin(a))
				var k: float = maxf(absf(d.x) / (dx + 2.0), absf(d.y) / (dz + 2.0))
				if k <= 0.0001:
					continue
				var p := Vector3(d.x / k, alto + 1.0, d.y / k)
				var h := 3.2 if tipo != "banderines" else 1.6
				var m := MeshInstance3D.new()
				var cm := CylinderMesh.new()
				cm.top_radius = 0.05
				cm.bottom_radius = 0.07
				cm.height = h
				cm.radial_segments = 5
				m.mesh = cm
				m.material_override = asta
				m.position = p + Vector3(0, h / 2.0, 0)
				root.add_child(m)
				## Tela que ondea (25-9-2026): un plano subdividido con el
				## shader `bandera.gdshader`, sujeto al asta por un lado. Antes
				## era una caja rígida, como una chapa.
				var tam := Vector2(1.3, 0.85) if tipo != "banderines" else Vector2(0.6, 0.45)
				_bandera_ondeante(root, p + Vector3(0, h * 0.82, 0), tam, colores[i % colores.size()], a, float(i) * 1.7)

const SHADER_BANDERA := preload("res://visor/bandera.gdshader")

## Una bandera de tela que ondea, con el borde izquierdo en `pos` (el asta).
static func _bandera_ondeante(root: Node3D, pos: Vector3, tam: Vector2, color: Color, giro: float, fase: float) -> MeshInstance3D:
	var qm := QuadMesh.new()
	qm.size = tam
	qm.subdivide_width = 10
	qm.subdivide_depth = 4
	## El quad se centra en su origen: se corre medio ancho para que el borde
	## x=0 (UV 0, quieto) quede pegado al asta.
	qm.center_offset = Vector3(tam.x * 0.5, 0, 0)
	var m := MeshInstance3D.new()
	m.name = "Bandera"
	m.mesh = qm
	var mat := ShaderMaterial.new()
	mat.shader = SHADER_BANDERA
	mat.set_shader_parameter("color", color)
	## La misma trama de `Texturas.tela()`, para que se lea como tejido.
	mat.set_shader_parameter("tela", Texturas.tela(Color.WHITE).detail_albedo)
	mat.set_shader_parameter("ancho", tam.x)
	mat.set_shader_parameter("fase", fase)
	m.material_override = mat
	m.position = pos
	m.rotation.y = giro
	root.add_child(m)
	return m

## El color de la luz de los focos (B6.1). Lo usan las lámparas y la luz de
## relleno nocturna de `Ambience`.
static func color_luz(est: Dictionary) -> Color:
	match str(est.get("luzFocos", "neutra")):
		"calida":
			return Color(1.0, 0.86, 0.62)
		"fria":
			return Color(0.80, 0.90, 1.0)
		"club":
			return Color(1, 1, 1).lerp(_c(est.get("luzClub", ""), "#ffffff"), 0.45)
	return Color(1, 0.97, 0.85)

static func _focos(root: Node3D, tipo: String, dx: float, dz: float, alto: float, luz: Color = Color(1, 0.97, 0.85), estructura := "") -> void:
	if tipo == "sin":
		return
	## Torres de hasta `alto+12` metros -entre las estructuras mas altas y mas
	## a la vista del estadio, recortadas contra el cielo- eran color plano
	## puro (17-9-2026, ronda 5 de calidad visual). `estructura`: el color
	## que eligió el club (28-9-2026, colores por sección).
	var mat := Texturas.metal(Color(estructura) if estructura != "" else Color(0.72, 0.73, 0.76), 0.4)
	var lampara := StandardMaterial3D.new()
	lampara.albedo_color = luz
	lampara.emission_enabled = true
	lampara.emission = luz
	lampara.emission_energy_multiplier = 1.6

	if tipo == "torres" or tipo == "mixto":
		for sx in [1.0, -1.0]:
			for sz in [1.0, -1.0]:
				var base := Vector3(sx * (dx + 5.0), 0, sz * (dz + 6.0))
				var h := alto + 12.0
				var pole := MeshInstance3D.new()
				var cm := CylinderMesh.new()
				cm.height = h
				cm.top_radius = 0.35
				cm.bottom_radius = 0.55
				pole.mesh = cm
				pole.position = base + Vector3(0, h / 2.0, 0)
				pole.material_override = mat
				root.add_child(pole)
				_box(root, base + Vector3(0, h, 0), Vector3(6.0, 1.6, 0.6), lampara)
	if tipo == "corona" or tipo == "mixto" or tipo == "halo":
		## BUG REAL (23-9-2026): la corona se repartia sobre una ELIPSE
		## (`cos(a)*dx`, `sin(a)*dz`), y el anillo de tribunas es un
		## RECTANGULO. Con n=10, cuatro de las diez lamparas (a = 36, 144, 216
		## y 324 grados) caian en |x|~40 y |z|~40: por dentro de la cara de la
		## tribuna lateral (dx-5,5 = 43,5 en cuenco) y muy por dentro de la de
		## fondo (62,5), o sea **flotando sobre el campo a 20 m de altura sin
		## nada debajo**. Se proyecta el punto de la elipse al borde del
		## rectangulo: la direccion se respeta, el radio se ajusta al lado que
		## toque, y las diez quedan siempre sobre la estructura.
		var n := 10
		for i in range(n):
			var a := TAU * float(i) / n
			var d := Vector2(cos(a), sin(a))
			var k: float = maxf(absf(d.x) / (dx + 1.0), absf(d.y) / (dz + 1.0))
			if k <= 0.0001:
				continue
			var p := Vector3(d.x / k, alto + 1.2, d.y / k)
			_box(root, p, Vector3(2.0, 0.4, 0.6), lampara)

## LA PANTALLA, CON CONTENIDO DE VERDAD (22-9-2026): "esa pantalla azul puede
## mejorarse", con razón -era un rectángulo de UN SOLO COLOR LISO, sin nada
## encima, ni marcador ni escudo ni nada que sugiera una transmisión real. El
## motivo original de dejarla lisa -"una jumbotron encendida se ve uniforme,
## textura ahí se leería como un panel roto"- seguía siendo válido para la
## GRADA (ruido de alta frecuencia = estática de TV, ver el bug del 21-9),
## pero no aplicaba aquí: un gráfico de bienvenida (degradado + escudo del
## club, la imagen que cualquier jumbotron real muestra antes/entre jugadas)
## es contenido de baja frecuencia, sin el problema que motivó dejarla lisa.
## Reutiliza `Escudo.textura()` -ya usado para el círculo central y la
## fachada, cero arte nuevo- en vez de inventar un logo aparte.
static func _pantalla_textura(est: Dictionary, mi: Club) -> ImageTexture:
	## 240x128 = 1,875, la misma proporcion que la malla de la pantalla y que
	## el lienzo de `PantallaEstadio`. Antes era 256x144 (16:9) y el degradado
	## salia estirado a lo ancho -poco visible en un degradado, muy visible en
	## el escudo, que quedaba ovalado-.
	var w := 240
	var h := 128
	var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
	var a1 := _c(est.get("asiento1"), "#1a3a6b")
	var a2 := _c(est.get("asiento2"), "#0a0f1a")
	## Primer intento demasiado oscurecido (0.35/0.7): a la distancia real de
	## una camara de partido la pantalla leia casi negra, sin verse mas
	## "encendida" que la version anterior de un solo color -verificado con
	## una captura real, no supuesto-. Menos oscurecido para que se lea
	## prendida desde lejos, no solo de cerca.
	var fondo1 := a1.darkened(0.05)
	var fondo2 := a2.darkened(0.35)
	for y in range(h):
		var t := float(y) / float(h)
		var col := fondo1.lerp(fondo2, t)
		for x in range(w):
			img.set_pixel(x, y, col)
	## Marco angosto con el color de camiseta, como el borde de un grafico de
	## transmision real -no un panel completamente vacio hasta el borde.
	for y in [3, 4, h - 5, h - 4]:
		for x in range(w):
			img.set_pixel(x, y, a1)
	if mi != null:
		var esc_tex := Escudo.textura(mi, 128)
		if esc_tex != null:
			var esc_img := esc_tex.get_image()
			if esc_img != null:
				esc_img = esc_img.duplicate()
				esc_img.convert(Image.FORMAT_RGBA8)
				esc_img.resize(84, 84, Image.INTERPOLATE_LANCZOS)
				img.blend_rect(esc_img, Rect2i(0, 0, 84, 84), Vector2i((w - 84) / 2, (h - 84) / 2))
	img.generate_mipmaps()
	return ImageTexture.create_from_image(img)

## `abierta` (23-9-2026): qué tribuna NO existe en esta forma -1 = la de z
## negativo, en "herradura"; -1 = ninguna-. Sin este dato, el tipo "dos" (que
## es el por defecto) colgaba la segunda pantalla en el lado abierto: un marco
## de hasta 9 m flotando en el aire, sin tribuna ni techo detrás de él.
static func _pantallas(root: Node3D, tipo: String, dz: float, alto: float,
		est: Dictionary = {}, mi: Club = null, abierta: int = -1, abiertas: Array = []) -> void:
	if tipo == "sin":
		return
	var marco := Texturas.metal(Color(0.08, 0.08, 0.1), 0.5)
	var contenido := _pantalla_textura(est, mi)
	var pantalla := StandardMaterial3D.new()
	pantalla.albedo_texture = contenido
	pantalla.emission_enabled = true
	pantalla.emission_texture = contenido
	## HALLAZGO REAL (22-9-2026): la textura en si esta bien -confirmado
	## aislandola con `pruebas/diagnostico_pantalla_textura.gd`, se ve el
	## escudo perfecto-. El problema era el brillo: con emission alta (1.8,
	## para que se leyera "prendida" de lejos) el bloom del post-procesado
	## lava el contraste interno y el escudo desaparece en un blanco/azul
	## uniforme, visible SOLO en la imagen aislada, nunca en la escena real.
	## Bajado a un punto medio -se sigue leyendo "encendida" sin quemar el
	## contenido-.
	pantalla.emission_energy_multiplier = 1.1
	## BUG REAL DE ARQUITECTURA, ENCONTRADO CON UNA CAPTURA (23-9-2026): la
	## pantalla estaba clavada en `alto - 1.0` con 9 m de marco, o sea que su
	## mitad superior sobresalia POR ENCIMA del graderio y EL TECHO LE PASABA
	## POR DELANTE, partiendola en dos con una banda negra. Se veia clarisimo en
	## cuanto la pantalla dejo de ser un rectangulo liso y paso a tener texto:
	## con el degradado de antes, la banda negra del techo cruzandola no
	## delataba nada.
	##
	## Ahora CUELGA DEBAJO DE LA CUBIERTA, como en los dos videos de referencia
	## -en `ea_fc25_referencia.mp4` los dos paneles del fondo estan montados en
	## el frente de la tribuna, nunca asomando sobre el techo-, y ADEMAS ESCALA
	## CON EL RECINTO: una pantalla de 9 m en un estadio de 1 nivel (6,5 m de
	## alto) sobresalia por arriba Y se hundia bajo el cesped a la vez.
	## `_techos()` pone la cubierta en `alto + 0.4`; dejando el borde de arriba
	## del marco en `alto - 0.8` queda siempre por debajo, en cualquier forma.
	var alto_marco := clampf(alto * 0.46, 4.2, 9.0)
	## 1,875 exacto: es la proporcion del lienzo de `PantallaEstadio`
	## (960x512). Con 16x9 el contenido saldria estirado a lo ancho.
	var ancho_marco := alto_marco * 1.875
	var y_marco := alto - 0.8 - alto_marco / 2.0
	var lados: Array = [1.0]
	if tipo == "dos" or tipo == "todo":
		lados = [1.0, -1.0]
	## `stands` numera 0 = fondo en +dz, 1 = fondo en -dz. Se quita el lado
	## cuya tribuna no se construyó.
	if abierta == 0 or 0 in abiertas:
		lados.erase(1.0)
	if abierta == 1 or 1 in abiertas:
		lados.erase(-1.0)
	for sz in lados:
		var p := Vector3(0, y_marco, sz * (dz - 6.0))
		_box(root, p, Vector3(ancho_marco, alto_marco, 0.6), marco)
		## Nombrada (22-9-2026, "el resultado que van"): `ui/estadio.gd` la
		## busca por nombre después de construir el estadio para engancharle
		## un SubViewport en vivo con el marcador -no le hace falta a
		## `_pantalla_textura()` saber nada de partidos, sigue siendo el
		## degradado+escudo de siempre hasta que `estadio.gd` la reemplaza.
		_quad_pantalla(root, p + Vector3(0, 0, -sz * 0.36),
			Vector2(ancho_marco * 0.94, alto_marco * 0.94),
			PI if sz > 0.0 else 0.0, pantalla)
	if tipo == "cubo" or tipo == "todo":
		## El cubo suspendido sobre el centro del campo. Estaba a 26 m FIJOS,
		## o sea recortado contra el cielo y colgando de nada en cualquier
		## estadio de menos de 3 niveles. El primer arreglo de hoy (`alto + 4`)
		## seguia mal por lo mismo -el techo va en `alto + 0.4`, asi que
		## `alto + 4` esta SIEMPRE por encima-: se corrigio al mismo criterio
		## que ya usa la pantalla plana, colgando justo por debajo del plano de
		## cubierta, que es de donde cuelga en un estadio de verdad.
		var lado_cubo := clampf(alto * 0.42, 4.0, 9.0)
		var y_cubo: float = maxf(alto - 0.6 - lado_cubo / 2.0, lado_cubo / 2.0 + 6.0)
		var ancho_cubo := lado_cubo * 1.875
		_box(root, Vector3(0, y_cubo, 0),
			Vector3(ancho_cubo, lado_cubo, ancho_cubo), marco)
		## Las cuatro caras, una por lado del campo.
		for i in 4:
			var giro := float(i) * PI / 2.0
			var fuera := Vector3(sin(giro), 0.0, cos(giro)) * (ancho_cubo / 2.0 + 0.06)
			_quad_pantalla(root, Vector3(0, y_cubo, 0) + fuera,
				Vector2(ancho_cubo * 0.94, lado_cubo * 0.94), giro, pantalla)

## LA CARA DE LA PANTALLA VA EN UN `QuadMesh`, NO EN UN `BoxMesh`.
##
## BUG REAL, ENCONTRADO CON UNA CAPTURA (23-9-2026), y es el que explica de
## verdad el misterio que `LEEME.md` dejó abierto el 22-9 ("la textura aislada
## se ve perfecta pero en la escena no aparece el escudo, debe de ser el
## encuadre de la prueba"). NO era el encuadre: **`BoxMesh` no mapea la textura
## entera a cada cara**, reparte las seis caras en un atlas de UV. O sea que la
## cara que mira al campo enseñaba un RECORTE AMPLIADO de la imagen -se veía
## media abreviatura gigante y un trozo de escudo- por muy bien que estuviera
## generada la textura. `QuadMesh` sí mapea 0..1 sobre toda la cara.
##
## `giro`: un `QuadMesh` mira a +Z sin girar. La pantalla del fondo +Z tiene
## que mirar al campo, o sea a -Z, de ahí el PI.
static func _quad_pantalla(root: Node3D, pos: Vector3, tam: Vector2,
		giro: float, mat: Material) -> void:
	var mi := MeshInstance3D.new()
	var qm := QuadMesh.new()
	qm.size = tam
	mi.mesh = qm
	mi.material_override = mat
	mi.position = pos
	mi.rotation.y = giro
	## NOMBRE UNICO POR CARA (23-9-2026). Con `"PantallaMarcador"` a secas,
	## Godot le pone sufijo a los hermanos que colisionan y
	## `ui/estadio.gd::_montar_pantalla()` busca con coincidencia EXACTA, sin
	## comodin: **solo la primera recibia el marcador en vivo** y las demas se
	## quedaban con el degradado estatico. Es el mismo bug que ya se habia
	## encontrado y arreglado en los telones esta misma sesion, y aqui habia
	## quedado suelto -con `pantalla: "todo"` son seis caras y cinco mentian-.
	mi.name = "PantallaMarcador_%d" % root.get_child_count()
	root.add_child(mi)

## BORRADO EL 23-9-2026: HABIA DOS BANQUILLOS, UNO ENCIMA DEL OTRO.
##
## Aqui vivia un `_banquillos(root, dx)` que pintaba una caja fija en
## x∈[35.2, 37.4], z∈[4.5, 13.5]. `_banquillos_detalle()` -el del catalogo, el
## que de verdad responde a lo que el usuario elige en Club -> Estadio- quedo
## en x∈[35.7, 38.7], z∈[10, 18] despues de que se corrigiera el cambio de ejes
## X/Z del 13-9. **Desde ese arreglo los dos se cruzaban** en x∈[35.7, 37.4] ×
## z∈[10, 13.5]: el cristal lateral del dugout atravesaba la caja vieja. La
## nota de `LEEME.md` que decia que estaban lejos quedo obsoleta ese mismo dia
## y nadie lo noto, porque desde la camara de TV una caja dentro de otra caja
## del mismo color no se distingue.
##
## Sintoma delator, ademas: recibia `dx` y NO LO USABA -todas sus medidas eran
## constantes-. Es exactamente el patron que la auditoria del 23-9 buscaba.
##
## No se reemplaza por nada: `_banquillos_detalle()` ya se llama SIEMPRE desde
## `build_pitch()` y cubre los seis tipos del catalogo.

## Butacas de verdad en las primeras filas de cada tribuna.
##
## POR QUE SOLO EN LAS PRIMERAS FILAS
## El modelo de fila de tres butacas que trajo el usuario tiene 38.916 vertices;
## simplificado al 2,5% con Blender baja a 988 (assets/ciudad/asientos_lod.glb).
## Aun asi, llenar las cuatro tribunas enteras serian ~10.000 filas = 10 millones
## de vertices, que una Intel UHD no mueve. Puestas en las CINCO PRIMERAS filas
## salen unas 1.100 y se ven exactamente donde importa: al borde del cesped, que
## es donde la camara de TV pasa cerca.
##
## "DE LA SEXTA FILA HACIA ARRIBA... A ESA DISTANCIA NO SE DISTINGUE" -CIERTO
## SOLO EN UN GRADERIO DE 1 NIVEL, FALSO EN UNO DE 2-3 (22-9-2026). El usuario
## lo vio de inmediato comparando sus propias capturas: en un "Cuenco de 3
## niveles" (alto=19.5, `largo_rake`~21m) las 5 filas reales cubren solo 4.4m,
## ~21% de la rampa -el 79% restante es la textura de `_make_stand_texture()`
## SOLA, estirada sobre una pendiente larga y vista casi de canto desde una
## camara de estadio, que es justo la combinacion que hace aliasing severo
## (mismo fenomeno que la "estatica de TV" ya documentada, no una textura
## rota nueva). "De abajo se ve bien" (las 5 filas reales) vs. "de arriba" (la
## textura sola) no es una ilusion, es una cobertura real desigual que el
## supuesto original -pensado con un graderio de 1 nivel en mente- no preveia.
## Arreglo: escalar las filas reales CON el numero de niveles, no un numero
## fijo -un estadio de 1 nivel sigue costando exactamente lo mismo que
## siempre (el caso que ya se veia bien y no habia que tocar), uno de 3
## niveles cubre 3x mas alto sin disparar el costo a las ~10.000 filas que sí
## preocupaban al comentario original.
const RUTA_BUTACAS := "res://assets/ciudad/asientos_lod.glb"
const FILAS_REALES := 5
const PASO_FILA := 0.88          ## fondo de cada fila, en metros
const PASO_BUTACA := 1.52        ## ancho de una fila de tres butacas

## Hincha de mentira para las filas reales, deliberadamente low-poly -a
## diferencia de la butaca real (988 vertices, ver mas arriba), esto se repite
## por cada asiento OCUPADO de las 5 filas reales de las 4 tribunas, asi que el
## presupuesto por instancia tiene que ser minimo: un torso (capsula) y una
## cabeza (esfera), un puñado de segmentos cada una -a la distancia de camara
## donde esto se ve (borde del cesped, nunca un primer plano de cara), no hace
## falta mas- unidas en una sola malla para que un unico MultiMesh alcance.
static var _malla_hincha: Mesh

static func _malla_hincha_cache() -> Mesh:
	if _malla_hincha != null:
		return _malla_hincha
	var torso := CapsuleMesh.new()
	torso.radius = 0.18
	torso.height = 0.55
	torso.radial_segments = 6
	torso.rings = 1
	var cabeza := SphereMesh.new()
	cabeza.radius = 0.11
	cabeza.height = 0.22
	cabeza.radial_segments = 6
	cabeza.rings = 4
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	st.append_from(torso, 0, Transform3D(Basis(), Vector3(0, 0.28, 0)))
	st.append_from(cabeza, 0, Transform3D(Basis(), Vector3(0, 0.61, 0)))
	_malla_hincha = st.commit()
	return _malla_hincha

## EL HINCHA DE LAS PRIMERAS FILAS (29-9-2026). Pedido del usuario al ver el
## partido jugable de la Carrera de Jugador ("ese público se ve horrible"):
## ahí la cámara va a ras de césped y las primeras filas quedan a pocos metros.
## La cápsula+esfera de arriba, de cerca, es una pastilla con una bola. Esta
## lleva hombros, brazos, cuello y cabeza -el pelo lo pinta el shader por
## altura-, ~150 vértices, y SOLO se usa en las filas bajas de la bandeja de
## abajo: las de arriba siguen con la barata, que a 30 m no se distingue.
static var _malla_hincha_det: Mesh

static func _malla_hincha_detalle() -> Mesh:
	if _malla_hincha_det != null:
		return _malla_hincha_det
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var torso := CylinderMesh.new()
	torso.top_radius = 0.16
	torso.bottom_radius = 0.13
	torso.height = 0.40
	torso.radial_segments = 7
	torso.rings = 1
	st.append_from(torso, 0, Transform3D(Basis().scaled(Vector3(1.0, 1.0, 0.72)), Vector3(0, 0.29, 0)))
	var hombros := CapsuleMesh.new()
	hombros.radius = 0.075
	hombros.height = 0.44
	hombros.radial_segments = 6
	hombros.rings = 1
	st.append_from(hombros, 0, Transform3D(Basis(Vector3(0, 0, 1), PI * 0.5).scaled(Vector3(1.0, 1.0, 0.8)), Vector3(0, 0.47, 0)))
	var brazo := CapsuleMesh.new()
	brazo.radius = 0.045
	brazo.height = 0.40
	brazo.radial_segments = 5
	brazo.rings = 1
	for lado in [-1.0, 1.0]:
		## Brazos caídos y un poco adelantados, como sentado con las manos en
		## las rodillas.
		var b := Basis(Vector3(1, 0, 0), -0.35).rotated(Vector3(0, 0, 1), 0.10 * lado)
		st.append_from(brazo, 0, Transform3D(b, Vector3(0.20 * lado, 0.31, 0.05)))
	var cuello := CylinderMesh.new()
	cuello.top_radius = 0.045
	cuello.bottom_radius = 0.05
	cuello.height = 0.08
	cuello.radial_segments = 5
	cuello.rings = 1
	st.append_from(cuello, 0, Transform3D(Basis(), Vector3(0, 0.56, 0)))
	var cabeza := SphereMesh.new()
	cabeza.radius = 0.10
	cabeza.height = 0.23
	cabeza.radial_segments = 8
	cabeza.rings = 5
	st.append_from(cabeza, 0, Transform3D(Basis(), Vector3(0, 0.67, 0)))
	st.generate_normals()
	_malla_hincha_det = st.commit()
	return _malla_hincha_det

## `ocupacion` (22-9-2026): antes estas 5 filas reales -las que la camara de TV
## ve de cerca, ver el comentario de mas arriba- se quedaban con la butaca
## vacia aunque `_make_stand_texture()` ya pinte gente de verdad desde la fila
## 6 para arriba. Exactamente al reves de lo que importa: la grada se veia mas
## llena lejos que cerca. Aqui se decide, asiento por asiento y con el mismo
## `rng` -asi el patron sale estable entre recargas del mismo estadio, no
## parpadea de una partida a otra-, si va ocupado, respetando la MISMA
## `ocupacion` real (asistencia del partido) que ya gobierna la textura: un
## estadio semivacio en la simulacion economica se ve semivacio tambien aqui,
## esto no es decoracion aparte con su propio numero inventado.
## LOS TRAPOS DE LA HINCHADA (23-9-2026).
##
## En `ea_fc25_referencia.mp4` los telones colgados sobre las primeras filas
## son LO QUE MAS ROMPE la uniformidad de la grada: sin ellos el graderio se
## lee como una alfombra de puntos por muy bien que este el publico. Y en una
## cancha chilena son media identidad del estadio.
##
## SE MONTAN COMO HIJOS DEL `deck`, EN COORDENADAS LOCALES, a proposito: el
## deck ya viene inclinado, asi que la pendiente, la orientacion y la posicion
## sobre la rampa salen gratis del propio nodo. Calcularlas en coordenadas de
## mundo habria significado deshacer a mano la rotacion de cada una de las 4
## tribunas -justo el tipo de cuenta que produjo la mitad de los bugs que se
## arreglaron hoy-.
##
## Un `PlaneMesh` mira hacia +Y (esta tumbado), que es exactamente como queda
## un trapo extendido sobre las butacas. `size` es (x, z) en local.
static func _telones(deck: MeshInstance3D, tam: Vector3, lateral: bool,
		est: Dictionary, seed_val: int) -> void:
	var largo: float = tam.z if lateral else tam.x
	var fondo: float = tam.x if lateral else tam.z
	if largo < 12.0 or fondo < 4.0:
		return
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_val
	var c1 := _c(est.get("asiento1"), "#1f5f3d")
	var c2 := _c(est.get("asiento2"), "#e8e8e8")
	## Tela de verdad, no color plano: un trapo pintado se lee como cartulina.
	## Sin brillo -es una sabana vieja atada a la reja, no un pendon nuevo.
	## Uno claro SIEMPRE entre los tres: los trapos de una hinchada son en su
	## mayoria sabanas blancas pintadas, y contra una grada del color del club
	## es lo unico que destaca de verdad. Si el segundo color del club ya es
	## claro, se usa ese; si no, se aclara el primero.
	var claro: Color = c2 if c2.get_luminance() > 0.55 else c1.lightened(0.7)
	var telas: Array[StandardMaterial3D] = [
		Texturas.tela(claro), Texturas.tela(c1), Texturas.tela(claro.darkened(0.12)),
	]
	## EL BORDE OSCURO NO ES DECORACION (23-9-2026). Los colores del trapo son
	## los MISMOS que los de las butacas -es la hinchada de ese club-, asi que
	## un panel liso de ese color sobre esa grada es invisible: se funde con el
	## fondo. El reborde negro le da silueta contra cualquier patron, que es
	## exactamente lo que hace que se lean en el video de referencia.
	var borde := Texturas.tela(Color(0.06, 0.07, 0.08))
	var cuantos := 3
	for k in cuantos:
		## Mas hondos de lo que parece necesario (23-9-2026, corregido mirando
		## la captura): un trapo tumbado sobre una rampa de casi 60 grados se
		## ve MUY escorzado desde la cancha, asi que 1,6 m de fondo daban una
		## rayita. 2,8-4,2 m se leen como un telon.
		var ancho: float = rng.randf_range(8.0, 15.0)
		var hondo: float = rng.randf_range(2.8, 4.2)
		## Reparto a lo largo, con holgura, para que no se amontonen ni se
		## salgan por las puntas de la tribuna.
		var centro: float = -largo * 0.5 + largo * (float(k) + 0.5) / float(cuantos) \
			+ rng.randf_range(-largo * 0.08, largo * 0.08)
		## POR ENCIMA DE LA ZONA DE BUTACAS REALES (corregido con una captura,
		## 23-9-2026). El primer intento los puso en el tercio bajo de la rampa
		## y NO SE VEIA NINGUNO: ahi es justo donde `_butacas()` pone las filas
		## de butacas 3D, que miden ~0,8 m, asi que un trapo tumbado a 0,34 m
		## quedaba enterrado entre ellas. De la mitad de la rampa hacia arriba
		## solo hay textura, asi que el telon se ve entero -y ademas es donde
		## cuelgan en `ea_fc25_referencia.mp4`, arriba, no al borde del cesped.
		## SIN PISAR LOS VOMITORIOS (23-9-2026). Los dos iban a la misma franja
		## alta de la rampa y a 1 cm de altura de diferencia (borde del telón a
		## 0,32 y boca a 0,33): se solapaban casi siempre, así que o el trapo
		## tapaba la boca de acceso o la boca aparecía pintada sobre el trapo, y
		## a la rasante con que se ve una grada eso además parpadea. Los telones
		## se quedan en la franja media-alta y los vomitorios se van al borde de
		## arriba del todo.
		var d: float = -fondo * 0.5 + fondo * rng.randf_range(0.45, 0.70)
		var pos_borde := Vector3(d, 0.32, centro) if lateral else Vector3(centro, 0.32, d)
		var m0 := MeshInstance3D.new()
		var pm0 := PlaneMesh.new()
		pm0.size = Vector2(hondo + 0.26, ancho + 0.26) if lateral \
			else Vector2(ancho + 0.26, hondo + 0.26)
		m0.mesh = pm0
		m0.position = pos_borde
		m0.material_override = borde
		deck.add_child(m0)
		var m := MeshInstance3D.new()
		var pm := PlaneMesh.new()
		pm.size = Vector2(hondo, ancho) if lateral else Vector2(ancho, hondo)
		m.mesh = pm
		## 0,36 m sobre el plano del deck: por encima del cojin de las butacas
		## (0,24) y del propio reborde (0,32), sin peleas de profundidad.
		m.position = pos_borde + Vector3(0, 0.04, 0)
		m.material_override = telas[rng.randi_range(0, telas.size() - 1)]
		## Nombre UNICO por telon, no el mismo para los tres. Con el nombre
		## repetido Godot le pone un sufijo a los hermanos y la busqueda por
		## nombre de la prueba solo encontraba uno por tribuna -parecia que
		## faltaban ocho de doce y estaban todos ahi.
		m.name = "TelonHinchada_%d" % k
		deck.add_child(m)
	_vomitorios(deck, largo, fondo, lateral)

## LAS BOCAS DE ACCESO (23-9-2026). En `ea_fc25_referencia.mp4` la grada del
## fondo está picada de huecos oscuros: son los vomitorios por donde sale la
## gente, y sin ellos una tribuna se lee como un bloque macizo de público.
## Van en lo alto de la rampa -que es donde están en un estadio real- y también
## como hijos del `deck`, por el mismo motivo que los telones: la inclinación
## la pone el nodo, no una cuenta a mano.
static func _vomitorios(deck: MeshInstance3D, largo: float, fondo: float,
		lateral: bool) -> void:
	var boca := StandardMaterial3D.new()
	boca.albedo_color = Color(0.035, 0.04, 0.05)
	boca.roughness = 1.0
	## Uno cada ~26 m, que es el reparto real de un graderío.
	var cuantas: int = clampi(int(largo / 26.0), 2, 6)
	## Al borde de arriba y POR DEBAJO del borde del telón (0,32), para que las
	## dos capas no compitan -ver la nota de `_telones()`-.
	var d: float = fondo * 0.5 - 1.45
	for k in cuantas:
		var centro: float = -largo * 0.5 + largo * (float(k) + 0.5) / float(cuantas)
		var m := MeshInstance3D.new()
		var pm := PlaneMesh.new()
		pm.size = Vector2(2.6, 3.0) if lateral else Vector2(3.0, 2.6)
		m.mesh = pm
		m.position = Vector3(d, 0.30, centro) if lateral else Vector3(centro, 0.30, d)
		m.material_override = boca
		m.name = "Vomitorio_%d" % k
		deck.add_child(m)

## `rake` (23-9-2026): la inclinacion REAL de esta rampa, en radianes. Las
## butacas y los hinchas son hijos del `deck` YA INCLINADO, asi que heredaban
## la pendiente entera: con 3 niveles el graderio va a `atan2(18, 11)` = **58,6
## grados**, o sea que el publico estaba tumbado hacia atras casi 60 grados,
## como en un despegue. Ninguna grada real pasa de ~35, y en las de verdad las
## butacas van sobre ESCALONES horizontales, no sobre el plano inclinado.
## Contrarrotando cada instancia por -rake alrededor del eje que inclino el
## deck, la butaca y el hincha quedan de pie y en su sitio de la pendiente,
## que es exactamente lo que pasa en un estadio.
## `bandeja` (23-9-2026): qué piso del graderío es este, contando desde el
## césped. Decide cuántas filas de butacas 3D se pueden permitir -ver la nota
## del presupuesto, más abajo-.
static func _butacas(deck: MeshInstance3D, tam: Vector3, lateral: bool, est: Dictionary,
		ocupacion: float, alto: float = 6.5, rake: float = 0.0, bandeja: int = 0) -> void:
	var esc := load(RUTA_BUTACAS)
	if esc == null:
		return
	## Se instancia solo para sacar la malla: el nodo se libera enseguida (antes
	## quedaba suelto, y al cerrar el juego el motor avisaba «material is null»).
	var tmp: Node = esc.instantiate() if esc is PackedScene else null
	var malla: Mesh = _primera_malla(tmp)
	if tmp != null:
		tmp.free()
	if malla == null:
		return

	## Largo de la tribuna y fondo del graderio, en el espacio LOCAL del deck (que
	## ya viene inclinado, asi que las butacas heredan la pendiente gratis).
	var largo: float = tam.z if lateral else tam.x
	var fondo: float = tam.x if lateral else tam.z
	var cuantas_fila: int = maxi(1, int(largo / PASO_BUTACA))
	## `alto/6.5` recupera cuantos niveles tiene ESTE graderio -6.5 es la
	## altura por nivel de `altura_de()`, la misma constante, no un numero
	## nuevo-. `FILAS_REALES` sigue siendo el presupuesto de UN nivel: un
	## estadio de 1 nivel no cambia (5 filas, igual que siempre), uno de 2 o 3
	## cubre proporcionalmente mas alto sin que el costo crezca sin control.
	## EL PRESUPUESTO DE BUTACAS 3D SE GASTA ABAJO (23-9-2026, con el graderío
	## por bandejas). Con 5 bandejas × 4 tribunas son 20 rampas: poner las 5
	## filas de butacas del modelo real en todas serían 8,5 millones de
	## vértices, más que el estadio entero de una sola bandeja. Y no hace falta:
	## el motivo documentado de que exista el modelo detallado es que **la
	## cámara de TV pasa cerca del borde del césped**, o sea de la bandeja de
	## abajo. Las de arriba se ven a 30 m o más, donde la textura de grada +
	## los hinchas 3D ya cuentan la misma historia.
	##   bandeja 0 -> las 5 filas de siempre
	##   bandeja 1 -> 2 filas
	##   bandeja 2+ -> ninguna (textura + hinchas, que sí siguen en todas)
	## Total: ~2,4 millones de vértices, MENOS que antes de esta tanda.
	var presupuesto: int = FILAS_REALES if bandeja == 0 \
		else (maxi(1, FILAS_REALES / 2) if bandeja == 1 else 0)
	## LA HINCHADA LLEGA ARRIBA DEL TODO; LAS BUTACAS 3D, NO (23-9-2026).
	##
	## Pedido directo del usuario -"ese modelo de público debe estar en toda la
	## grada, siempre falta una parte"-, y tenía razón: con 3 niveles las 15
	## filas de butacas cubrían 13 m de una rampa de 21, o sea que **el tercio
	## de arriba de cada tribuna no tenía ni una persona en 3D**, solo la
	## textura. Se notaba como un corte horizontal a media grada.
	##
	## Se separan los dos presupuestos, que es lo que faltaba: una fila de tres
	## butacas del modelo real cuesta **988 vértices** y un hincha cuesta
	## **~70**. Subir las butacas a toda la rampa sería pasar de 4,4 a 6,7
	## millones de vértices -una Intel UHD no lo mueve, que es justo el motivo
	## documentado de que estuvieran limitadas-. Subir SOLO los hinchas cuesta
	## unos 400.000 en total: se puede de sobra, y es lo que de verdad se ve,
	## porque las butacas de arriba ya las dibuja la textura de la grada.
	var filas_todas: int = maxi(1, int(fondo / PASO_FILA))
	## LA GRADA ENTERA CON BUTACAS (29-9-2026). Pedido del usuario: «ponelas en
	## la totalidad de la grada, deja de hacer lo de poner una versión fea en la
	## zona de arriba». Ahora TODAS las filas tienen butaca 3D: las cercanas al
	## césped con el modelo real, y el resto con `_malla_butaca_lejos()`, la
	## misma butaca con las medidas del modelo pero ~120 vértices en vez de 994
	## -a esa distancia no se distinguen, y poner el modelo real en toda la
	## rampa serían más de 15 millones de vértices-. La textura con gente
	## pintada desaparece: debajo queda cemento.
	var filas: int = mini(presupuesto, filas_todas)
	## ¿QUÉ BORDE DEL DECK ES EL DE ABAJO? (29-9-2026). Se daba por hecho que
	## el lado local negativo, y en las tribunas giradas al revés -la mitad-
	## las filas de butacas 3D y el público denso acababan ARRIBA DEL TODO,
	## con la parte pegada al césped casi vacía. Se mira la inclinación real.
	var eje_fondo := Vector3(1, 0, 0) if lateral else Vector3(0, 0, 1)
	var sentido: float = 1.0 if (deck.basis * eje_fondo).y >= 0.0 else -1.0
	## HACIA DÓNDE MIRA LA BUTACA (29-9-2026, «las butacas están al revés»).
	## En el modelo el respaldo queda en -Z: la butaca mira a +Z. Tiene que
	## mirar al borde bajo de la rampa, que está en -sentido sobre el eje del
	## fondo. `Basis.rotated(UP, g)` lleva +Z a (sin g, 0, cos g), así que:
	##   tribuna lateral (fondo en X): sin g = -sentido -> g = -sentido·π/2
	##   tribuna de fondo (fondo en Z): cos g = -sentido -> g = π si sentido > 0
	## Antes las tribunas de detrás de los arcos quedaban al revés.
	var giro: float = (-sentido * PI * 0.5) if lateral else (PI if sentido > 0.0 else 0.0)

	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = true
	mm.mesh = malla
	mm.instance_count = cuantas_fila * filas
	var mm_lejos := MultiMesh.new()
	mm_lejos.transform_format = MultiMesh.TRANSFORM_3D
	mm_lejos.use_colors = true
	mm_lejos.mesh = _malla_butaca_lejos()
	mm_lejos.instance_count = cuantas_fila * (filas_todas - filas)

	var rng := RandomNumberGenerator.new()
	rng.seed = int(largo * 100.0) + filas
	var c1 := Color(str(est.get("asiento1", "#1f5f3d")))
	var c2 := Color(str(est.get("asiento2", "#e8e8e8")))
	## Paleta de ropa de hincha: neutros de siempre + los dos colores del club
	## para que se lea "hinchada local", no una multitud generica.
	var colores_hincha := [Color(0.85, 0.85, 0.88), Color(0.15, 0.16, 0.2), c1, c2,
		Color(0.7, 0.2, 0.2), Color(0.2, 0.3, 0.7)]
	var hinchas_xf: Array[Transform3D] = []
	var hinchas_col: Array[Color] = []
	var det_xf: Array[Transform3D] = []
	var det_col: Array[Color] = []
	var filas_detalle: int = 6 if Calidad.elegida >= Calidad.ALTO else 3
	## Un hincha por asiento ocupado: tres por grupo (dos en calidad Media).
	var por_grupo: int = 3 if Calidad.elegida >= Calidad.ALTO else 2
	var eje_largo := Vector3(0, 0, 1) if lateral else Vector3(1, 0, 0)
	var eje_rake := Vector3(0, 0, 1) if lateral else Vector3(1, 0, 0)
	var i := 0
	var j := 0
	for f in range(filas_todas):
		## Se empieza por el borde de abajo del deck (el que da al cesped).
		var d: float = sentido * (-fondo * 0.5 + 0.6 + f * PASO_FILA)
		for c in range(cuantas_fila):
			var l: float = -largo * 0.5 + 0.8 + c * PASO_BUTACA
			var p: Vector3 = Vector3(d, 0.24, l) if lateral else Vector3(l, 0.24, d)
			## La contrarrotacion que las deja DE PIE: primero el giro y despues
			## la contrarrotacion del rake (`rotated()` premultiplica).
			var base := Basis().rotated(Vector3.UP, giro)
			if rake != 0.0:
				base = base.rotated(eje_rake, -rake)
			## Franjas de color del club, con alguna butaca desparejada: una grada
			## de un solo tono se lee como una alfombra pintada.
			var col: Color = c1 if (c / 3) % 2 == 0 else c2
			if rng.randf() < 0.04:
				col = col.lightened(0.25)
			col = col.darkened(rng.randf() * 0.12)
			if f < filas:
				mm.set_instance_transform(i, Transform3D(base, p))
				mm.set_instance_color(i, col)
				i += 1
			else:
				mm_lejos.set_instance_transform(j, Transform3D(base, p))
				mm_lejos.set_instance_color(j, col)
				j += 1
			## Un hincha por asiento ocupado. Las filas pegadas al césped de la
			## bandeja de abajo llevan el hincha de detalle; el resto, el barato.
			var cerca := bandeja == 0 and f < filas_detalle
			for k in (3 if cerca else por_grupo):
				if rng.randf() >= ocupacion:
					continue
				var desp := (float(k) - 0.5 * float((3 if cerca else por_grupo) - 1)) * 0.48
				var jit := Vector3(rng.randf_range(-0.04, 0.04), 0, rng.randf_range(-0.04, 0.04))
				## NO TODOS MIDEN LO MISMO: ±10% de talla, gratis en la matriz.
				var talla := rng.randf_range(0.9, 1.08)
				var base_h := Basis().rotated(Vector3.UP, giro + rng.randf_range(-0.15, 0.15)).scaled(Vector3(talla, talla, talla))
				if rake != 0.0:
					base_h = base_h.rotated(eje_rake, -rake)
				var xf := Transform3D(base_h, p + eje_largo * desp + jit + Vector3(0, 0.15, 0))
				var col_h: Color = colores_hincha[rng.randi_range(0, colores_hincha.size() - 1)]
				col_h = col_h.darkened(rng.randf() * 0.15)
				if cerca:
					det_xf.append(xf)
					det_col.append(col_h)
				else:
					hinchas_xf.append(xf)
					hinchas_col.append(col_h)

	## Debajo de las butacas, cemento: la textura con gente pintada ya no hace
	## falta y entre fila y fila se veía como manchas estiradas.
	deck.material_override = _mat_escalones()
	if mm_lejos.instance_count > 0:
		var mil := MultiMeshInstance3D.new()
		mil.multimesh = mm_lejos
		var mat_l := StandardMaterial3D.new()
		mat_l.vertex_color_use_as_albedo = true
		mat_l.albedo_color = Color(0.9, 0.9, 0.9)
		mat_l.roughness = 0.55
		mil.material_override = mat_l
		mil.name = "ButacasLejos"
		mil.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		deck.add_child(mil)

	var mat := StandardMaterial3D.new()
	mat.vertex_color_use_as_albedo = true
	mat.albedo_color = Color(0.9, 0.9, 0.9)
	mat.roughness = 0.55
	mat.metallic = 0.05
	var mi := MultiMeshInstance3D.new()
	mi.multimesh = mm
	mi.material_override = mat
	mi.name = "ButacasCerca"
	## SIN SOMBRA PROPIA (25-9-2026, `pruebas/medir_partido.gd`). Miles de
	## butacas y de hinchas proyectando sombra se dibujaban otra vez en CADA
	## cascada del sol -cuatro en calidad ALTO-: eran el grueso de los ~2
	## millones de triángulos por fotograma. Bajo el techo de la grada esa
	## sombra no se ve; la de la grada entera (el `deck`) sigue estando.
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	deck.add_child(mi)

	if not det_xf.is_empty():
		var mmd := MultiMesh.new()
		mmd.transform_format = MultiMesh.TRANSFORM_3D
		mmd.use_colors = true
		mmd.mesh = _malla_hincha_detalle()
		mmd.instance_count = det_xf.size()
		for k in det_xf.size():
			mmd.set_instance_transform(k, det_xf[k])
			mmd.set_instance_color(k, det_col[k])
		var mat_d := ShaderMaterial.new()
		mat_d.shader = load("res://visor/hinchada.gdshader")
		## La malla de detalle tiene el cuello más arriba y pelo.
		mat_d.set_shader_parameter("cuello_desde", 0.535)
		mat_d.set_shader_parameter("cuello_hasta", 0.55)
		mat_d.set_shader_parameter("pelo_desde", 0.715)
		var mid := MultiMeshInstance3D.new()
		mid.multimesh = mmd
		mid.material_override = mat_d
		mid.name = "HinchadaCerca"
		mid.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		deck.add_child(mid)
	if hinchas_xf.is_empty():
		return
	var mmh := MultiMesh.new()
	mmh.transform_format = MultiMesh.TRANSFORM_3D
	mmh.use_colors = true
	mmh.mesh = _malla_hincha_cache()
	mmh.instance_count = hinchas_xf.size()
	for k in hinchas_xf.size():
		mmh.set_instance_transform(k, hinchas_xf[k])
		mmh.set_instance_color(k, hinchas_col[k])
	## LA HINCHADA SE MUEVE Y TIENE CARA (23-9-2026). Ver `visor/hinchada.
	## gdshader` para el porqué de cada cosa: balanceo con fase propia, saltos
	## sueltos y la cabeza en tono de piel en vez de ser del color de la
	## camiseta. Cero coste por instancia -sigue siendo UN `MultiMesh` por
	## tribuna- y cero vértices nuevos.
	var mat_h := ShaderMaterial.new()
	mat_h.shader = load("res://visor/hinchada.gdshader")
	var mih := MultiMeshInstance3D.new()
	mih.multimesh = mmh
	mih.material_override = mat_h
	mih.name = "Hinchada"
	mih.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	deck.add_child(mih)

## LA BUTACA DE LEJOS (29-9-2026): las medidas del modelo real
## (`asientos_lod.glb`: 1,50 × 0,74 × 0,59 m, tres asientos, respaldo en -Z)
## hechas con cinco cajas -asiento corrido, tres respaldos con su hueco y la
## viga-: ~120 vértices contra 994. Se usa en las filas altas, donde la
## cámara nunca llega a distinguirlas.
static var _butaca_lejos: Mesh

static func _malla_butaca_lejos() -> Mesh:
	if _butaca_lejos != null:
		return _butaca_lejos
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var asiento := BoxMesh.new()
	asiento.size = Vector3(1.46, 0.07, 0.40)
	st.append_from(asiento, 0, Transform3D(Basis(), Vector3(-0.05, 0.40, 0.04)))
	var respaldo := BoxMesh.new()
	respaldo.size = Vector3(0.44, 0.38, 0.05)
	for k in 3:
		var x := -0.55 + float(k) * 0.5
		st.append_from(respaldo, 0, Transform3D(Basis(Vector3(1, 0, 0), -0.14), Vector3(x, 0.58, -0.20)))
	var viga := BoxMesh.new()
	viga.size = Vector3(1.40, 0.30, 0.06)
	st.append_from(viga, 0, Transform3D(Basis(), Vector3(-0.05, 0.20, -0.08)))
	_butaca_lejos = st.commit()
	return _butaca_lejos

## El piso de la grada bajo las butacas: hormigón gris, compartido.
static var _escalones: StandardMaterial3D

static func _mat_escalones() -> StandardMaterial3D:
	if _escalones == null:
		_escalones = Texturas.hormigon(Color(0.52, 0.52, 0.54), 83)
	return _escalones

static func _primera_malla(n: Node) -> Mesh:
	if n == null:
		return null
	if n is MeshInstance3D and (n as MeshInstance3D).mesh != null:
		return (n as MeshInstance3D).mesh
	for c in n.get_children():
		var r := _primera_malla(c)
		if r != null:
			return r
	return null

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

## PALETA DE LAS VALLAS (MEGAPLAN B6): los mismos textos, otra estética. La
## de fábrica ("marcas") deja cada anuncio con el color de su marca.
const NEON := [Color(0.25, 0.95, 1.0), Color(1.0, 0.3, 0.85), Color(0.6, 1.0, 0.25),
	Color(1.0, 0.72, 0.2)]
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

## La tinta se decide contra el fondo, no a ojo: sobre un panel claro un texto
## blanco desaparece, y la mitad de las 38 marcas traen colores claros.
static func _anuncio(texto: String, fondo: Color) -> Dictionary:
	var tinta := Color(0.06, 0.07, 0.09) if fondo.get_luminance() > 0.45 \
		else Color(0.97, 0.98, 1.0)
	return {"texto": texto.to_upper(), "fondo": fondo, "tinta": tinta}

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

## `tipo` (16-9-2026, Fase 2 "Componentes"), catalogo `EST_BANQUILLOS`. El
## default ("cristal") es la burbuja de siempre, asi que un rival sigue igual.
## `est` (ronda 4 de calidad visual): mismo criterio que en `_corners()` y
## `_tunel()` -si trae `asiento1` (solo el estadio propio), los asientos
## "cristal"/"bunker"/"foso" salen del color de la camiseta.
static func _banquillos_detalle(root: Node3D, tipo: String = "cristal", est: Dictionary = {}) -> void:
	## LA "BURBUJA DE CRISTAL" ERA OPACA (23-9-2026). `Texturas.cristal()` nunca
	## asigna `transparency`, así que se quedaba en `TRANSPARENCY_DISABLED` con
	## un albedo casi negro, `metallic` 0,9 y `roughness` 0,05: para una ventana
	## de fachada de la ciudad está bien -no hace falta ver adentro-, pero aquí
	## daba **una caja de cromo negro espejada al borde de la banda**, que es el
	## banquillo POR DEFECTO del catálogo y sale en todos los planos de la
	## cámara principal. Los nueve asientos que se dibujan dentro no se veían
	## nunca. El `.duplicate()` es obligatorio: `cristal()` cachea por
	## `(encendida, calido)` y hay ventanas de ciudad usando esa misma instancia.
	var vidrio: StandardMaterial3D = Texturas.cristal(false).duplicate()
	vidrio.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	vidrio.albedo_color = Color(0.55, 0.62, 0.68, 0.22)
	## Sin esto, dos paneles de metacrilato uno detrás de otro se ordenan mal y
	## parpadean según el ángulo.
	vidrio.depth_draw_mode = BaseMaterial3D.DEPTH_DRAW_OPAQUE_ONLY
	vidrio.cull_mode = BaseMaterial3D.CULL_DISABLED
	vidrio.metallic = 0.1
	vidrio.roughness = 0.08
	var estructura := Texturas.metal(_c(est.get("banquilloCol", ""), "#292b30"), 0.4)
	## Cuero de verdad (16-9-2026) para los sillones -antes color plano, y era
	## justo el banquillo mas "de lujo" del catalogo el que menos brillaba de
	## verdad. El resto sigue con el plastico simple: es a proposito, un
	## banquillo de cristal comun no tiene por que tener cuero.
	var asiento: StandardMaterial3D = Texturas.cuero(Color(0.36, 0.20, 0.12)) if tipo == "sillones" \
		else _asiento_simple(_c(est.get("asiento1"), "#24262b"))
	var madera := Texturas.madera(Color(0.42, 0.28, 0.16))
	## Cuanto se hunde el banquillo bajo el nivel del campo. 0 = a ras, como
	## siempre; los dos "excavados" del catalogo (bunker/foso) lo bajan.
	var hundido := 0.55 if tipo in ["bunker", "foso"] else 0.0
	## La cancha usa X=ancho (banda a banda, cal +-34) y Z=largo (arco a arco,
	## +-52.5) -ver los goles en _add_goal() y las constantes MEDIO_LARGO /
	## MEDIO_ANCHO en control_partido.gd/match_playback.gd. Esto tenia X y Z
	## CAMBIADOS: el "lado*12.0" (pensado para separar los dos banquillos a
	## cada lado del CIRCULO CENTRAL, como dice el comentario de arriba) caia
	## en X en vez de Z, y el "40.5" (pensado como la distancia fija a la
	## banda) caia en Z en vez de X -asi el banquillo quedaba a 12m del centro
	## del campo EN ANCHO (bien adentro de la cancha) y a 40.5m de la mitad EN
	## LARGO (practicamente dentro del area chica). Se veia -y el usuario lo
	## confirmo con una foto- como una caja negra metida en el area, no un
	## banquillo en la banda.
	## 3.5 m detrás de la línea de banda (X=±34), los DOS en la tribuna
	## principal (X positivo), separados ±14 m del círculo central en Z.
	## El dugout se rota 90° para que la fila de asientos corra a lo largo
	## de la banda, no atravesando el césped.
	const DISTANCIA_LINEA_BANDA := 3.5
	var x_banda: float = PITCH_WID * 0.5 + DISTANCIA_LINEA_BANDA
	for lado in [-1.0, 1.0]:
		var base := Vector3(x_banda, -hundido, lado * 14.0)
		var n := Node3D.new()
		n.name = "BanquilloLocal" if lado < 0.0 else "BanquilloVisita"
		n.position = base
		n.rotation_degrees.y = 90.0
		root.add_child(n)
		match tipo:
			"banca":
				## A la vieja usanza: ni vidrio ni techo, solo el banco de
				## madera y nada mas -es lo mas barato del catalogo, y se nota.
				_box(n, Vector3(0, 0.45, -0.2), Vector3(7.6, 0.12, 0.9), madera)
				for k in range(4):
					var pata := _box(n, Vector3(-3.0 + k * 2.0, 0.22, -0.2), Vector3(0.1, 0.44, 0.8), madera)
					pata.material_override = estructura
			"foso":
				## Excavado Y cubierto: una losa plana en vez de vidrio, "solo
				## se ven las cabezas" -sin paredes transparentes, con techo bajo.
				var losa := _box(n, Vector3(0, 1.35, -0.3), Vector3(8.2, 0.15, 3.2), estructura)
				losa.position.y = hundido + 1.35
				_box(n, Vector3(0, 0.12, -0.2), Vector3(7.6, 0.24, 2.4), estructura)
				for k in range(9):
					_box(n, Vector3(-3.4 + k * 0.85, 0.55, 0.2), Vector3(0.6, 0.62, 0.6), asiento)
			_:  # "cristal" (siempre), "bunker" y "sillones" comparten la burbuja
				var techo := _box(n, Vector3(0, 2.05, -0.3), Vector3(8.0, 0.12, 3.0), estructura)
				techo.rotation.x = -0.12
				_box(n, Vector3(0, 1.1, 1.15), Vector3(8.0, 2.1, 0.08), vidrio)
				for s in [-1.0, 1.0]:
					_box(n, Vector3(s * 3.95, 1.1, -0.3), Vector3(0.08, 2.1, 3.0), vidrio)
				_box(n, Vector3(0, 0.12, -0.2), Vector3(7.6, 0.24, 2.4), estructura)
				if tipo == "sillones":
					## Menos asientos, mas anchos -son sillones reclinables, no
					## una fila de banco- separados a lo largo del mismo tramo.
					for k in range(7):
						_box(n, Vector3(-3.0 + k * 1.0, 0.55, 0.2), Vector3(0.72, 0.62, 0.6), asiento)
				else:
					## "cristal" y "bunker": exactamente la fila de siempre.
					for k in range(9):
						_box(n, Vector3(-3.4 + k * 0.85, 0.55, 0.2), Vector3(0.6, 0.62, 0.6), asiento)

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

## CAMARÓGRAFOS AL BORDE DEL CAMPO (13-9-2026). Pedido del usuario ("faltan
## camarógrafos"): un estadio de televisión de verdad siempre tiene gente
## trabajando detrás de cada arco y a pie de línea en la mitad de cancha, y
## sin ellos el perímetro del césped se siente vacío. Figuras sencillas -no
## un personaje completo, no hace falta para un detalle de fondo- de un
## operador con chaleco de prensa y su cámara sobre un monopié, mirando
## siempre hacia el centro del campo.
static func _camarografos(root: Node3D) -> void:
	var chaleco := StandardMaterial3D.new()
	chaleco.albedo_color = Color(0.85, 0.55, 0.08)
	var pantalon := StandardMaterial3D.new()
	pantalon.albedo_color = Color(0.12, 0.13, 0.15)
	var piel := StandardMaterial3D.new()
	piel.albedo_color = Color(0.62, 0.47, 0.38)
	var equipo := StandardMaterial3D.new()
	equipo.albedo_color = Color(0.06, 0.06, 0.07)
	equipo.metallic = 0.5
	equipo.roughness = 0.4
	## Detrás de cada arco (a los dos lados, como en la tele de verdad) y a pie
	## de línea en la mitad de cancha, del lado de la cámara principal.
	var puestos: Array[Vector3] = [
		Vector3(21.0, 0, 54.5), Vector3(-21.0, 0, 54.5),
		Vector3(21.0, 0, -54.5), Vector3(-21.0, 0, -54.5),
		Vector3(36.5, 0, 0.0),
	]
	for p in puestos:
		_un_camarografo(root, p, chaleco, pantalon, piel, equipo)

static func _un_camarografo(root: Node3D, pos: Vector3, chaleco: Material, pantalon: Material, piel: Material, equipo: Material) -> void:
	var base := Node3D.new()
	## `VistaEstadio` busca este nombre para poner un operador de verdad en
	## lugar del maniquí de cajas (26-9-2026); los trozos con meta "cuerpo" son
	## los que se ocultan, la cámara y el monopié se quedan.
	base.name = "Camarografo"
	base.position = pos
	## Siempre mirando al centro del campo: nadie graba de espaldas a la jugada.
	var hacia := -pos
	hacia.y = 0
	if hacia.length() > 0.01:
		base.rotation.y = atan2(hacia.x, hacia.z)
	root.add_child(base)
	## RENDIMIENTO (17-9-2026): 5 camarógrafos × 6 piezas cada uno son 30 mallas
	## proyectando sombra por una figura de fondo del tamaño de un maniquí -en
	## una Intel UHD el paso de sombras es de lo más caro que hay. Sin sombra
	## propia no se nota (la tira su propia base sobre el césped) y se ahorran
	## 30 mallas del atlas de sombras enteras.
	for m: MeshInstance3D in [
			_box(base, Vector3(-0.1, 0.4, 0), Vector3(0.14, 0.8, 0.14), pantalon),
			_box(base, Vector3(0.1, 0.4, 0), Vector3(0.14, 0.8, 0.14), pantalon),
			_box(base, Vector3(0, 1.15, 0), Vector3(0.42, 0.5, 0.26), chaleco),
			_box(base, Vector3(0, 0.55, 0.32), Vector3(0.06, 1.1, 0.06), equipo),
			_box(base, Vector3(0, 1.15, 0.34), Vector3(0.30, 0.22, 0.55), equipo),
		]:
		m.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		if m.material_override != equipo:
			m.set_meta("cuerpo", true)
	var cabeza := MeshInstance3D.new()
	var sm := SphereMesh.new()
	sm.radius = 0.14
	sm.height = 0.28
	cabeza.mesh = sm
	cabeza.position = Vector3(0, 1.55, 0)
	cabeza.material_override = piel
	cabeza.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	cabeza.set_meta("cuerpo", true)
	base.add_child(cabeza)

## Boca del tunel de vestuarios, con el arco de entrada que trajo el usuario si
## esta disponible. Es por donde salen los equipos y da un punto focal a la
## tribuna principal, que era una pared lisa de 90 metros.
## `tipo` (16-9-2026, Fase 2 "Componentes"), catalogo `EST_TUNELES`. El
## default ("central") es exactamente la mole de siempre, asi que un rival
## sigue igual. `est` (ronda 4 de calidad visual): el portico inflable
## ("arco") sale del color de la camiseta si `est` lo trae -mismo criterio
## que los banderines de corner-, rojo generico si no (cualquier rival).
## `dz` (23-9-2026): el semi-largo del recinto. Antes no lo recibia y por eso
## el ancla del tunel era un numero fijo -ver el bug explicado abajo-.
static func _tunel(root: Node3D, tipo: String = "central", est: Dictionary = {},
		dz: float = 68.0) -> void:
	## SIN LUZ PROPIA, ESTA MOLE SE VE NEGRA (13-9-2026). Confirmado con una
	## captura real desde "Detrás del arco": la cara visible queda bajo la
	## cubierta de la tribuna, sin línea directa a sol/luna ni a los focos
	## -que apuntan al césped, no a una hornacina debajo del graderío-, y el
	## ambiente nocturno no basta para leer el material: sale un bloque
	## negro perfectamente plano, sin textura, que confundió al usuario
	## ("¿qué es eso en la portería?"). Un OmniLight cercano no lo arregló
	## -la hornacina sigue sin luz de verdad ahí dentro-, así que la solución
	## real es la misma que usa cualquier túnel de vestuarios de un estadio
	## real: SU PROPIA luz de entrada, no depender de que algo externo la
	## alcance. Material propio (no el `Texturas.hormigon()` compartido, para
	## no afectar a nadie más que lo use) con un pelín de emisión.
	## "esquina" desplaza toda la boca hacia el lado del corner en vez del
	## centro del lateral -los otros 4 tipos siguen centrados como siempre.
	var x_off := 24.0 if tipo == "esquina" else 0.0
	## BUG REAL ENCONTRADO Y CORREGIDO (21-9-2026, ver LEEME.md): la mole con
	## Z=45.0 quedaba DENTRO del campo -el arco esta en Z=52.5 (`MEDIO_LARGO`
	## de match_playback.gd/control_partido.gd) y la caja, de 6m de fondo,
	## llegaba hasta Z=48: a 4.5m de la linea de gol, encima del area chica-.
	## El usuario lo vio con sus propios ojos en una captura: la caja tapaba
	## el arco entero desde varios angulos de camara -no era un problema de
	## encuadre de camara, la estructura de verdad estaba sobre la cancha.
	## `ANCLA_Z` mueve todo el conjunto detras de la linea de gol, mismos
	## desfaces relativos entre mole/boca/tubo/arco que ya tenian.
	##
	## SEGUNDA PARTE DEL MISMO BUG (23-9-2026): ese arreglo dejo el ancla en
	## **64,0 metros FIJOS**, que es el `dz` de la forma "ingles" clavado a
	## mano. Con las otras cinco formas el tunel se va de sitio:
	##   - "oval" (dz=74): la tribuna empieza en 68,5 y la mole se queda en
	##     61..67, o sea SOLA sobre el hormigon, a 7 m por delante del
	##     graderio y fuera del plano de cesped.
	##   - "ingles" (dz=64) y "caldera" (65): la boca queda 2 m POR DENTRO de
	##     la rampa, enterrada, y no se ve.
	## El ancla correcta se deriva del recinto: la cara interior de la tribuna
	## esta en `dz - 5.5`, y la mole mide 6 m de fondo, asi que centrandola en
	## `dz - 2.5` su frente cae justo en esa cara y la boca queda a ras, que es
	## como se ve un tunel de vestuarios de verdad: un hueco oscuro en la
	## tribuna, ni delante ni enterrado.
	var ancla_z: float = dz - 2.5
	if tipo == "central" or tipo == "esquina" or tipo == "telescopico":
		## La mole maciza con una placa negra (lo de antes) ya no hace falta:
		## el pórtico, el pasillo y el vestuario los monta `TunelVestuario`.
		if tipo == "telescopico":
			## El tubo retractil se estira desde la boca hacia la cancha. Abierto
			## por los dos extremos: se puede salir caminando por dentro.
			var tubo := MeshInstance3D.new()
			var cm := CylinderMesh.new()
			cm.top_radius = 2.4
			cm.bottom_radius = 2.6
			cm.height = 5.0
			cm.cap_top = false
			cm.cap_bottom = false
			tubo.mesh = cm
			tubo.rotation.x = PI / 2.0
			tubo.position = Vector3(x_off, 1.9, ancla_z - 5.5)
			var mt: StandardMaterial3D = Texturas.metal(Color(0.55, 0.56, 0.58), 0.5).duplicate()
			mt.cull_mode = BaseMaterial3D.CULL_DISABLED
			tubo.material_override = mt
			root.add_child(tubo)
	elif tipo == "arco":
		## Portico hinchable: un arco curvo en vez de la mole de hormigon, con
		## un pelin de brillo propio -es lona iluminada por dentro, no piedra.
		## `Texturas.tela()` de base (16-9-2026) -es lona, no plastico duro- y
		## DUPLICADA antes de tocarle la emision: esa funcion cachea y devuelve
		## la MISMA instancia a cualquiera que pida el mismo color, y prenderle
		## la emision sin duplicar se la prendería tambien a cualquier otra
		## bandera roja de este color en el resto del estadio.
		var col_inflable := _c(est.get("asiento1"), "#d92626")
		var inflable: StandardMaterial3D = Texturas.tela(col_inflable, 0.7).duplicate()
		inflable.emission_enabled = true
		inflable.emission = col_inflable
		inflable.emission_energy_multiplier = 0.4
		## BUG REAL (23-9-2026): el portico estaba en **z = 42,5 FIJO**, y el
		## area grande va de z=33,75 a 50,25 -o sea que el arco inflable se
		## plantaba DENTRO DEL AREA, a 10 m de la linea de gol-. Es el mismo
		## bug que el comentario de mas arriba dice haber corregido el 21-9,
		## pero aquel arreglo solo toco las ramas "central/esquina/telescopico"
		## y estas dos se quedaron fuera. Ahora comparten el mismo ancla.
		var z_arco: float = ancla_z - 3.4
		var arco3d := MeshInstance3D.new()
		var tm := TorusMesh.new()
		tm.inner_radius = 2.6
		tm.outer_radius = 3.1
		arco3d.mesh = tm
		arco3d.rotation.x = PI / 2.0
		arco3d.position = Vector3(0, 3.1, z_arco)
		arco3d.material_override = inflable
		root.add_child(arco3d)
		for sx in [-1.0, 1.0]:
			_box(root, Vector3(sx * 2.8, 1.55, z_arco), Vector3(0.5, 3.1, 0.5), inflable)
	else:  # "foso": emerge desde debajo del cesped por una escalera iluminada
		## BUG REAL (23-9-2026): ademas del ancla fija, este tipo estaba
		## ENTERO POR DEBAJO DE y=0 (la mole de -1,8 a 0, los escalones hasta
		## -1,42). El plano de cesped es OPACO y cubre z hasta ±58,5, asi que
		## **no se veia absolutamente nada**: la emision alumbraba el reverso
		## del suelo. Un foso de verdad se ve porque la boca asoma sobre el
		## nivel del campo; subida para que sobresalga, con los escalones
		## bajando hacia dentro desde el borde.
		## Ahora la boca es el pórtico de `TunelVestuario`; el «foso» es su
		## umbral: tres peldaños bajos iluminados que bajan hacia la cancha.
		var escalones: StandardMaterial3D = Texturas.hormigon(Color(0.3, 0.31, 0.33), 29).duplicate()
		escalones.emission_enabled = true
		escalones.emission = Color(0.5, 0.55, 0.65)
		escalones.emission_energy_multiplier = 0.8
		for k in range(3):
			_box(root, Vector3(0, 0.25 - k * 0.08, ancla_z - 3.4 - k * 0.6),
				Vector3(4.6, 0.1, 0.6), escalones)

## EL EXTERIOR DEL ESTADIO (25-9-2026, plan maestro B6.2). Hasta hoy el recinto
## terminaba en su muro y detrás había una explanada gris vacía. Ahora, como en
## cualquier estadio de verdad: una fila de taquillas frente a la tribuna sur,
## la tienda oficial en la esquina y un estacionamiento con coches detrás de la
## tribuna norte. Todo sale de una semilla local (no de `Azar`): el mismo
## estadio siempre tiene los coches en el mismo sitio.
const RUTAS_COCHES := [
	"res://assets/ciudad/kenney_cars/sedan.glb",
	"res://assets/ciudad/kenney_cars/sedan-sports.glb",
	"res://assets/ciudad/kenney_cars/suv.glb",
	"res://assets/ciudad/kenney_cars/hatchback-sports.glb",
	"res://assets/ciudad/kenney_cars/taxi.glb",
	"res://assets/ciudad/kenney_cars/van.glb",
]

static func _exterior(root: Node3D, est: Dictionary, dx: float, dz: float, niveles: int, mi: Club) -> void:
	var fuera_z := centro_tribuna(dz, niveles) + fondo_tribuna(niveles) / 2.0
	var fuera_x := centro_tribuna(dx, niveles) + fondo_tribuna(niveles) / 2.0
	var club_col := _c(est.get("asiento1"), "#2b6b45")
	var ext := Node3D.new()
	ext.name = "Exterior"
	root.add_child(ext)
	## Taquillas: cuatro casetas con ventanilla iluminada y marquesina.
	## Mezclado con gris: con un club de camiseta negra la caseta era un
	## agujero negro en la explanada.
	## Pintura plana y no metal: el metal sin reflejos de cielo sale negro.
	var caseta := StandardMaterial3D.new()
	caseta.albedo_color = club_col.lerp(Color(0.62, 0.64, 0.66), 0.45)
	caseta.roughness = 0.6
	var ventanilla: StandardMaterial3D = Texturas.cristal(true, true)
	var losa := Texturas.hormigon(Color(0.55, 0.56, 0.58), 61)
	## El vestuario (`TunelVestuario`) está justo detrás de la tribuna, en el
	## eje del túnel: las taquillas se abren a sus dos lados.
	var tx := tunel_x(est)
	## 8-10-2026: todas del lado OESTE del vestuario. La entrada del club
	## (puerta, portero y garita) queda al este y no puede tener taquillas
	## delante.
	for i in 4:
		var x := tx - (TunelVestuario.VEST_MEDIO + 4.0 + float(i) * 4.5)
		var z := fuera_z + 9.0
		_box(ext, Vector3(x, 1.3, z), Vector3(3.0, 2.6, 2.4), caseta)
		## La ventanilla mira a la calle (+Z), no al muro del estadio.
		_box(ext, Vector3(x, 1.5, z + 1.22), Vector3(1.8, 0.9, 0.05), ventanilla)
		_box(ext, Vector3(x, 2.75, z + 0.5), Vector3(3.8, 0.15, 3.6), losa)
	var rot := Label3D.new()
	rot.text = "TAQUILLAS"
	rot.font_size = 96
	rot.pixel_size = 0.012
	rot.modulate = Color(1, 1, 1)
	rot.outline_size = 12
	## Un `Label3D` sin girar ya mira a +Z, que es la calle.
	rot.position = Vector3(tx - (TunelVestuario.VEST_MEDIO + 4.0 + 6.75), 4.6, fuera_z + 9.0)
	ext.add_child(rot)
	## La tienda oficial, en la esquina sureste.
	var tienda_pos := Vector3(fuera_x - 6.0, 0.0, fuera_z + 20.0)
	_box(ext, tienda_pos + Vector3(0, 3.0, 0), Vector3(18.0, 6.0, 10.0), _mat_fachada(str(est.get("fachada", "hormigon")), str(est.get("fachadaCol", ""))))
	_box(ext, tienda_pos + Vector3(0, 2.0, 5.05), Vector3(14.0, 3.0, 0.1), ventanilla)
	var franja := StandardMaterial3D.new()
	franja.albedo_color = club_col
	franja.emission_enabled = true
	franja.emission = club_col
	franja.emission_energy_multiplier = 0.4
	_box(ext, tienda_pos + Vector3(0, 5.0, 5.1), Vector3(18.0, 1.2, 0.1), franja)
	var r_tienda := Label3D.new()
	r_tienda.text = "TIENDA OFICIAL" if mi == null else "TIENDA %s" % Nombres.visible(mi.nombre).to_upper()
	r_tienda.font_size = 80
	r_tienda.pixel_size = 0.012
	r_tienda.outline_size = 10
	r_tienda.position = tienda_pos + Vector3(0, 5.0, 5.2)
	ext.add_child(r_tienda)
	## El estacionamiento: asfalto, rayas y coches.
	var park_z := -(fuera_z + 26.0)
	var asfalto := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2(84.0, 34.0)
	asfalto.mesh = pm
	asfalto.position = Vector3(0, -0.1, park_z)
	## Seco y mate: el de fábrica está pensado para calzada y a esta escala
	## se leía como un charco.
	var mat_asf: StandardMaterial3D = Texturas.asfalto().duplicate()
	mat_asf.roughness = 0.97
	mat_asf.roughness_texture = null
	mat_asf.normal_enabled = false
	mat_asf.metallic_specular = 0.2
	## (26-9-2026) Ya se repite en coordenadas del mundo: sin reescalar.
	asfalto.material_override = mat_asf
	ext.add_child(asfalto)
	var raya := StandardMaterial3D.new()
	raya.albedo_color = Color(0.92, 0.92, 0.88)
	var rng := RandomNumberGenerator.new()
	rng.seed = int(dx * 131.0 + dz * 17.0) + niveles
	var escenas: Array = []
	for r: String in RUTAS_COCHES:
		if ResourceLoader.exists(r):
			var e := load(r)
			if e is PackedScene:
				escenas.append(e)
	for fila in 2:
		var z_f := park_z - 7.5 + float(fila) * 15.0
		for k in 14:
			var x := -39.0 + float(k) * 6.0
			_box(ext, Vector3(x - 3.0, -0.05, z_f), Vector3(0.15, 0.02, 5.0), raya)
			if escenas.is_empty() or rng.randf() < 0.3:
				continue
			var coche: Node3D = (escenas[rng.randi() % escenas.size()] as PackedScene).instantiate()
			coche.position = Vector3(x, 0.0, z_f)
			coche.rotation.y = (0.0 if fila == 0 else PI) + rng.randf_range(-0.05, 0.05)
			coche.scale = Vector3.ONE * 1.65   ## la misma que en la ciudad
			ext.add_child(coche)
