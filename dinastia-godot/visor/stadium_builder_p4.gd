extends "res://visor/stadium_builder_p3.gd"
## [Capa 4/12 de `stadium_builder.gd`] build_pitch, _pintar_publico, _make_stand_texture, _make_stand_texture_tramos, _techo_mat, _mat_fachada

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
	## EL CÉSPED DE TRANSMISIÓN (14-10-2026): franjas que brillan según el
	## ángulo, brizna, manchas y desgaste (`visor/cesped.gdshader`). El dibujo
	## del club sigue saliendo de la misma textura.
	var sm := ShaderMaterial.new()
	sm.shader = load("res://visor/cesped.gdshader")
	sm.set_shader_parameter("dibujo", gmat.albedo_texture)
	var c0: Color = tonos[0]
	var c1: Color = tonos[1]
	sm.set_shader_parameter("claro_s", Vector3(c0.r, c0.g, c0.b))
	sm.set_shader_parameter("oscuro_s", Vector3(c1.r, c1.g, c1.b))
	## En Compatibility (móvil y web) el sombreado no pasa a lineal: ahí van los
	## colores tal cual (si no, verde neón y franjas negras).
	var compat := String(ProjectSettings.get_setting("rendering/renderer/rendering_method", "")) == "gl_compatibility" \
		or RenderingServer.get_current_rendering_method() == "gl_compatibility"
	var l0 := c0 if compat else c0.srgb_to_linear()
	var l1 := c1 if compat else c1.srgb_to_linear()
	sm.set_shader_parameter("claro", Vector3(l0.r, l0.g, l0.b))
	sm.set_shader_parameter("oscuro", Vector3(l1.r, l1.g, l1.b))
	pitch.material_override = sm
	pitch.name = "Cesped"
	root.add_child(pitch)
	## De cerca, hierba con volumen (`CespedCapas`).
	CespedCapas.montar(root, sm, pm.size)

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
		## Un disco de 22 cm, como el reglamentario (17-10: antes era un
		## cuadrado de 35 cm que de cerca, en la tanda, parecía una losa).
		var punto_penal := MeshInstance3D.new()
		var disco := CylinderMesh.new()
		disco.top_radius = 0.11
		disco.bottom_radius = 0.11
		disco.height = 0.02
		disco.radial_segments = 20
		disco.rings = 1
		punto_penal.mesh = disco
		punto_penal.material_override = line_mat
		punto_penal.position = Vector3(0, 0.012, sgn * (PITCH_LEN / 2.0 - 11.0))
		punto_penal.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		root.add_child(punto_penal)

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
