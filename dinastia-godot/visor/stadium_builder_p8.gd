extends "res://visor/stadium_builder_p7.gd"
## [Capa 8/12 de `stadium_builder.gd`] _focos, color_luz, _exterior, _pantalla_textura, _quad_pantalla, _pantallas … (+2)

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

	## LA CABEZA DEL FOCO, NO UNA CAJA (25-10-2026, ultra pulido): la lámpara era un
	## ladrillo blanco de 6 × 1,6 m mirando al cielo. Ahora es un bastidor oscuro
	## ORIENTADO al campo (apunta a un punto del césped, así que se inclina solo)
	## con su rejilla de proyectores redondos encendidos. Todos los proyectores
	## del estadio van en UN MultiMesh: una llamada de dibujo más en total.
	var proyectores: Array[Transform3D] = []
	var bastidor := Texturas.metal(Color(0.11, 0.115, 0.13), 0.5)
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
				var cima := base + Vector3(0, h + 0.6, 0)
				_cabeza_foco(root, cima, Vector3(base.x * 0.2, 0.0, base.z * 0.2), Vector2(6.4, 2.6), 6, 3, bastidor, proyectores)
				_cono_de_luz(root, base + Vector3(0, h - 0.6, 0), Vector3(0, 0.3, 0), 7.0, luz)
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
			_cabeza_foco(root, p, Vector3(p.x * 0.35, 0.0, p.z * 0.35), Vector2(2.2, 0.7), 4, 1, bastidor, proyectores)
			if i % 2 == 0:
				_cono_de_luz(root, p - Vector3(0, 0.3, 0), Vector3(0, 0.3, 0), 4.0, luz)
	if proyectores.is_empty():
		return
	var disco := CylinderMesh.new()
	disco.top_radius = 0.36
	disco.bottom_radius = 0.40
	disco.height = 0.16
	disco.radial_segments = 12
	disco.rings = 1
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = disco
	mm.instance_count = proyectores.size()
	for k in proyectores.size():
		mm.set_instance_transform(k, proyectores[k])
	var mmi := MultiMeshInstance3D.new()
	mmi.name = "ProyectoresFocos"
	mmi.multimesh = mm
	mmi.material_override = lampara
	mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	root.add_child(mmi)

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
	rot.text = Idiomas.t("TAQUILLAS")
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
	r_tienda.text = Idiomas.t("TIENDA OFICIAL") if mi == null else Idiomas.t("TIENDA %s") % Nombres.visible(mi.nombre).to_upper()
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

## El escudo en la grada/fachada/techo -las posiciones de `EST_ESCUDOS` que
## necesitan la geometria del recinto, por eso viven en `build()` y no en
## `build_pitch()` (ver `_escudo_cancha()` para "cancha"/"todo"). Uno solo por
## posicion, en la tribuna principal (la que da a la camara "Principal (TV)"),
## que es donde de verdad se ve -repetirlo en las 4 tribunas seria ruido.
static func _escudo_tribuna(root: Node3D, mi: Club, donde: String, dx: float, dz: float, alto: float,
		fachada_puesta := false) -> void:
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
	## 16-10-2026: si `FachadaEstadio` ya lo colgó en su paño, no se repite aquí.
	if (donde == "fachada" or donde == "todo") and not fachada_puesta:
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
