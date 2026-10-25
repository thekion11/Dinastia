extends BaseIdea
## FASE 0 (M-404/M-279): pruebas directas de los módulos de DATOS y funciones puras
## de `visor/` que no tenían ninguna: `Banderas`, `BibliotecaCaras`, `CaraMalla`,
## `PeloQ` (tablas), `PeloCapas` (funciones puras) y `Texturas`. Sin escena 3D:
## lo que se comprueba es lo que devuelven y que sus datos casan entre sí.

func _probar() -> void:
	_titulo("FASE 0 · VISOR: DATOS Y FUNCIONES PURAS (f0m)")
	_probar_banderas()
	_probar_biblioteca()
	_probar_cara_malla()
	_probar_pelo_q_datos()
	_probar_pelo_capas_puro()
	_probar_texturas()

# ------------------------------------------------------------------ Banderas

func _probar_banderas() -> void:
	_linea("· Banderas")
	var t := Banderas.textura("CHI")
	_comprobar(t != null and t.get_size() == Vector2(Banderas.ANCHO, Banderas.ALTO), "textura de %dx%d" % [Banderas.ANCHO, Banderas.ALTO])
	_comprobar(Banderas.textura("CHI") == t, "y en caché: la segunda vez es la misma")
	## El dibujo, sobre una imagen propia (no depende de leer de la GPU).
	var img := Image.create(Banderas.ANCHO, Banderas.ALTO, false, Image.FORMAT_RGB8)
	Banderas._pintar(img, "CHI")
	var azul := img.get_pixel(3, 3)
	var blanco := img.get_pixel(Banderas.ANCHO - 3, 3)
	var rojo := img.get_pixel(Banderas.ANCHO / 2, Banderas.ALTO - 3)
	var estrella := img.get_pixel(Banderas.ANCHO / 6, Banderas.ALTO / 4)
	_comprobar(azul.b > 0.5 and azul.r < 0.2 and blanco.r > 0.95 and blanco.b > 0.95 and rojo.r > 0.7 and rojo.g < 0.3,
		"Chile: cantón azul, franja blanca arriba y roja abajo")
	_comprobar(estrella.r > 0.95 and estrella.b > 0.95, "y la estrella blanca en el centro del cantón")
	## Cada país con liga y cada selección rival de la Carrera tiene dibujo PROPIO
	## (no las dos franjas de relleno sacadas del código).
	var fuente := FileAccess.get_file_as_string("res://visor/banderas.gd")
	var re := RegEx.new()
	re.compile("(?m)^\\t\\t\"([A-Z]{3})\":")
	var dibujadas := {}
	for r in re.search_all(fuente):
		dibujadas[r.get_string(1)] = true
	var paises: Dictionary = Datos.tabla("PAIS_SELECCION")
	var sin_dibujo: Array[String] = []
	for k: String in paises:
		if not dibujadas.has(k):
			sin_dibujo.append(k)
	for nombre: String in CarreraJugador.CODIGO_SELECCION:
		var cod := String(CarreraJugador.CODIGO_SELECCION[nombre])
		if not dibujadas.has(cod):
			sin_dibujo.append(cod)
	_comprobar(paises.size() >= 20 and sin_dibujo.is_empty(), "las %d selecciones con liga y las rivales de la Carrera tienen bandera propia %s" % [paises.size(), str(sin_dibujo)])
	var ida_vuelta: Array[String] = []
	for k: String in paises:
		if Banderas.codigo_de(String(paises[k])) != k:
			ida_vuelta.append(k)
	_comprobar(ida_vuelta.is_empty(), "codigo_de(nombre del país) devuelve su código %s" % str(ida_vuelta))
	_comprobar(Banderas.codigo_de("Atlántida") == "", "un país que no existe: \"\"")
	var c := Club.new("x", "X")
	c.color1 = "#c01020"
	c.color2 = "#ffffff"
	var tc := Banderas.de_club(c)
	_comprobar(tc != null and Banderas.de_club(c) == tc, "bandera de club, en caché por colores")

# ----------------------------------------------------------- BibliotecaCaras

func _probar_biblioteca() -> void:
	_linea("· BibliotecaCaras")
	_comprobar(BibliotecaCaras.hay(), "la biblioteca está")
	var caras := BibliotecaCaras.caras()
	var pelos := BibliotecaCaras.pelos()
	var ordenadas := caras.duplicate()
	ordenadas.sort()
	_comprobar(caras.size() == 72 and caras == ordenadas, "72 caras, en orden (%d)" % caras.size())
	_comprobar(pelos.size() >= 30, "y %d cortes de pelo" % pelos.size())
	var por_tono := {}
	var sin_foto: Array[String] = []
	for k: String in caras:
		var e := BibliotecaCaras.entrada_cara(k)
		var tono := int(e.get("tono", -1))
		por_tono[tono] = int(por_tono.get(tono, 0)) + 1
		if not FileAccess.file_exists("res://" + String(e.get("a", ""))):
			sin_foto.append(k)
	_comprobar(por_tono.size() == 6 and por_tono.values().all(func(n: int) -> bool: return n == 12), "12 caras por cada uno de los 6 tonos %s" % str(por_tono))
	_comprobar(sin_foto.is_empty(), "cada cara tiene su textura en disco %s" % str(sin_foto.slice(0, 5)))
	var claras := BibliotecaCaras.del_tono(Color(0.95, 0.82, 0.72))
	var oscuras := BibliotecaCaras.del_tono(Color(0.22, 0.14, 0.1))
	_comprobar(claras.size() == 12 and int(BibliotecaCaras.entrada_cara(claras[0])["tono"]) == 0, "piel clara → caras del tono 0")
	_comprobar(oscuras.size() == 12 and int(BibliotecaCaras.entrada_cara(oscuras[0])["tono"]) == 5, "piel muy oscura → caras del tono 5")
	var piel := Color(0.78, 0.6, 0.45)
	_comprobar(BibliotecaCaras.cara_de_tono(piel, 3) == BibliotecaCaras.cara_de_tono(piel, 3 + 12) and BibliotecaCaras.cara_de_tono(piel, -1) == "",
		"cara_de_tono da la vuelta a la lista y no acepta índices negativos")
	var a := BibliotecaCaras.para("jug_123", piel, Color(0.2, 0.1, 0.05))
	var b := BibliotecaCaras.para("jug_123", piel, Color(0.2, 0.1, 0.05))
	_comprobar(a == b and BibliotecaCaras.del_tono(piel).has(a["cara"]) and pelos.has(a["pelo"]), "para(): siempre lo mismo para la misma semilla, del tono de su piel")
	var distintas := {}
	for i in 40:
		distintas[BibliotecaCaras.para("p%d" % i, piel, Color.BLACK)["cara"]] = true
	_comprobar(distintas.size() >= 6, "y semillas distintas reparten caras (%d de 12)" % distintas.size())
	var p := BibliotecaCaras.pelo(String(pelos[0]), Color(0.5, 0.3, 0.1))
	_comprobar(String(p.get("c", "")) == "#" + Color(0.5, 0.3, 0.1).to_html(false) and String(p.get("r", "")) != String(p.get("c", "")), "pelo(): el corte con su color y la raíz más oscura")
	_comprobar(BibliotecaCaras.pelo("no_existe", Color.RED).is_empty() and BibliotecaCaras.nombre_pelo("no_existe") == "?", "un corte que no existe: vacío y «?»")

# ----------------------------------------------------------------- CaraMalla

func _probar_cara_malla() -> void:
	_linea("· CaraMalla")
	var k := "cara_000"
	_comprobar(CaraMalla.tiene(k) and not CaraMalla.tiene("nadie_se_llama_asi"), "las caras de la biblioteca están en CaraMalla")
	var g := CaraMalla.geometria(k)
	_comprobar(g.size() == 4, "geometria(): posiciones, uvs, triángulos y escala")
	if g.size() != 4:
		return
	var pos: PackedVector3Array = g[0]
	var uv: PackedVector2Array = g[1]
	var tri: PackedInt32Array = g[2]
	var n := CaraMalla._n
	_comprobar(pos.size() == n and uv.size() == n and CaraMalla._alfa.size() == n and n >= CaraMalla.N, "%d vértices con su uv y su alfa" % n)
	var idx_ok := tri.size() % 3 == 0 and tri.size() > 900
	for i in tri:
		idx_ok = idx_ok and i >= 0 and i < n
	_comprobar(idx_ok, "%d triángulos, todos con índices válidos" % (tri.size() / 3))
	var uv_ok := true
	for u in uv:
		uv_ok = uv_ok and u.x >= -0.01 and u.x <= 1.01 and u.y >= -0.01 and u.y <= 1.01
	_comprobar(uv_ok and float(g[3]) > 0.0, "las uv caen dentro de la foto")
	## Los ojos de la malla, sobre los globos del modelo (escala por los rabillos).
	var ojos := CaraMalla.centros_ojos(k)
	var ojos_ok := ojos.size() == 2 and (ojos[0] as Vector2).x < 0.0 and (ojos[1] as Vector2).x > 0.0
	if ojos_ok:
		for o: Vector2 in ojos:
			ojos_ok = ojos_ok and absf(absf(o.x) - CaraMalla.OJO_X) < 0.012 and absf(o.y - CaraMalla.OJO_Y) < 0.02
	_comprobar(ojos_ok, "los ojos quedan a ±%.3f m y a %.3f m de alto %s" % [CaraMalla.OJO_X, CaraMalla.OJO_Y, str(ojos)])
	var nariz := pos[1]
	_comprobar(nariz.z > pos[CaraMalla.OJO_IZQ[0]].z and nariz.y < CaraMalla.OJO_Y, "la punta de la nariz va delante de los ojos y por debajo")
	_comprobar(CaraMalla.balance(k) == Vector3.ONE and CaraMalla.balance("nadie") == Vector3.ONE, "balance de blancos (y neutro si no hay cara)")
	_comprobar(CaraMalla.color_iris(k).a > 0.5 and CaraMalla.color_iris("nadie").a == 0.0, "color de iris medido (alfa 0 si no hay)")
	_comprobar(CaraMalla.geometria("nadie").is_empty() and CaraMalla.centros_ojos("nadie").is_empty(), "sin cara: vacío, no error")
	## El tono de piel: media recortada de los puntos de la cara sobre la foto.
	var img := Image.create(64, 64, false, Image.FORMAT_RGBA8)
	var tono := Color(0.72, 0.52, 0.4)
	img.fill(tono)
	var medido := CaraMalla.tono_piel(k, ImageTexture.create_from_image(img))
	if medido.a == 0.0:
		_linea("  (headless sin imágenes de GPU: tono_piel no se puede medir aquí)")
	else:
		_comprobar(absf(medido.r - tono.r) < 0.02 and absf(medido.g - tono.g) < 0.02 and absf(medido.b - tono.b) < 0.02, "tono_piel de una foto lisa = su color (%s)" % medido.to_html(false))
	var f := CaraMalla.foto(k)
	_comprobar(f != null and CaraMalla.foto(k) == f and f.get_width() > 100, "la foto de la cara se carga y queda en caché")

# --------------------------------------------------------------- PeloQ (datos)

func _probar_pelo_q_datos() -> void:
	_linea("· PeloQ (tablas)")
	## Todo corte que puede pedir alguien tiene su malla 3D: el retrato, el creador
	## del DT y los peatones. Uno que falte cae en silencio en «raya al lado».
	var faltan: Array[String] = []
	for lista: Array in [Cara.CORTES, CaraDT.CORTES, PeatonQ.CORTES_H, PeatonQ.CORTES_M]:
		for corte: String in lista:
			if not PeloQ.DE_CORTE.has(corte) and not faltan.has(corte):
				faltan.append(corte)
	_comprobar(faltan.is_empty(), "cada corte de Cara, CaraDT y PeatonQ tiene su malla en PeloQ.DE_CORTE %s" % str(faltan))
	var sin_archivo: Array[String] = []
	for corte: String in PeloQ.DE_CORTE:
		var malla := String(PeloQ.DE_CORTE[corte][0])
		if malla != "" and not ResourceLoader.exists(PeloQ.CARPETA + malla + ".gltf"):
			sin_archivo.append(malla)
	for extra: String in ["Hair_Beard", "Eyebrows_Regular"]:
		if not ResourceLoader.exists(PeloQ.CARPETA + extra + ".gltf"):
			sin_archivo.append(extra)
	_comprobar(sin_archivo.is_empty(), "y cada malla existe en disco %s" % str(sin_archivo))
	var oscuro := Color(0.25, 0.16, 0.09)
	var canoso := Color(0.85, 0.85, 0.82)
	_comprobar(PeloQ.color_cejas(oscuro).get_luminance() < oscuro.get_luminance() and PeloQ.color_cejas(canoso).get_luminance() < canoso.get_luminance() * 0.5,
		"las cejas, más oscuras que el pelo (y mucho más con pelo canoso)")
	var m1 := PeloQ._material(oscuro, 1)
	_comprobar(PeloQ._material(oscuro, 1) == m1 and PeloQ._material(oscuro, 2) != m1 and m1.transparency == BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR,
		"materiales de pelo en caché por color y textura, con recorte de transparencia")

# ------------------------------------------------------ PeloCapas (puras)

func _probar_pelo_capas_puro() -> void:
	_linea("· PeloCapas (funciones puras)")
	var casos := [
		[{"rizo": 0.8, "alto": 11.0, "lados": 0.55}, "afro"], [{"largo": 0.2, "lados": 0.8}, "melena_rizada"],
		[{"alto": 6.0}, "rapado"], [{"alto": 9.0, "lados": 0.3}, "tupe"], [{"alto": 7.5, "lados": 0.3}, "degradado"], [{}, "normal"],
	]
	var mal: Array[String] = []
	for cs: Array in casos:
		if PeloCapas.corte_de(cs[0]) != String(cs[1]):
			mal.append("%s→%s" % [cs[1], PeloCapas.corte_de(cs[0])])
	_comprobar(mal.is_empty(), "corte_de(): afro, melena rizada, rapado, tupé, degradado y normal %s" % str(mal))
	var linea := [Vector2(-1, 1.0), Vector2(0, 2.0), Vector2(1, 1.5)]
	_comprobar(PeloCapas._linea_en([], 0.0) == 1.76 and is_equal_approx(PeloCapas._linea_en(linea, -0.5), 1.5)
		and PeloCapas._linea_en(linea, -9.0) == 1.0 and PeloCapas._linea_en(linea, 9.0) == 1.5, "_linea_en(): interpola y por fuera toma el borde")
	var den := PeloCapas._densidades(Marshalls.raw_to_base64(PackedByteArray([0, 255, 51])), 5)
	_comprobar(den.size() == 5 and den[0] == 0.0 and den[1] == 1.0 and is_equal_approx(den[2], 0.2) and den[4] == 0.0, "_densidades(): bytes → 0..1, relleno con ceros")
	_comprobar(PeloCapas._max(den) == 1.0 and PeloCapas._densidades("", 3) == PackedFloat32Array([0, 0, 0]), "_max y densidades vacías")
	## Una tira de cuatro triángulos (0-1-2, 1-3-2, 2-3-4, 3-5-4) para los recorridos.
	var tri := PackedInt32Array([0, 1, 2, 1, 3, 2, 2, 3, 4, 3, 5, 4])
	var an := PeloCapas._anillo([0], tri, 1)
	_comprobar(an.has(0) and an.has(1) and an.has(2) and not an.has(3), "_anillo(): un paso por triángulos desde el vértice 0")
	var dens := PackedFloat32Array([1, 1, 0, 0, 1, 1])
	_comprobar(PeloCapas._solo_con(tri, dens, 2) == PackedInt32Array([0, 1, 2, 3, 5, 4]), "_solo_con(): los triángulos con dos vértices con densidad")
	var plano := PackedVector3Array([Vector3(0, 0, 0), Vector3(1, 0, 0), Vector3(0, 1, 0), Vector3(1, 1, 0), Vector3(0, 2, 0), Vector3(1, 2, 0)])
	var nor := PeloCapas._normales(plano, tri)
	var nor_ok := nor.size() == 6
	for v in nor:
		nor_ok = nor_ok and v.is_equal_approx(Vector3(0, 0, 1))
	_comprobar(nor_ok, "_normales(): un plano da normales unitarias hacia fuera (+Z)")
	_comprobar(PeloCapas._pestanas(plano, nor) == null, "sin la cara completa no hay pestañas")
	var g := CaraMalla.geometria("cara_000")
	if g.size() == 4:
		var pc: PackedVector3Array = g[0]
		var ms := PeloCapas._pestanas(pc, PeloCapas._normales(pc, g[2]))
		var nv := ms.surface_get_array_len(0) if ms != null else 0
		_comprobar(nv == 2 * (PeloCapas.PARPADO_DER.size() - 1) * 6, "pestañas: una tira por párpado (%d vértices)" % nv)
	var corte_wb := PeloCapas._wb({"wb": [1.1, 1.0, 0.9]})
	_comprobar(corte_wb == Vector3(1.1, 1.0, 0.9) and PeloCapas._wb({}) == Vector3.ONE, "_wb(): balance de la foto o neutro")

# ------------------------------------------------------------------ Texturas

func _probar_texturas() -> void:
	_linea("· Texturas")
	var tinte := Color(0.6, 0.55, 0.5)
	var mats := {
		"hormigon": Texturas.hormigon(tinte), "ladrillo": Texturas.ladrillo(tinte), "asfalto": Texturas.asfalto(),
		"baldosa": Texturas.baldosa(), "enredadera": Texturas.enredadera(), "cesped": Texturas.cesped(),
		"tela": Texturas.tela(tinte), "madera": Texturas.madera(tinte), "cuero": Texturas.cuero(tinte),
		"metal": Texturas.metal(tinte), "cristal": Texturas.cristal(true), "churrete": Texturas.churrete(),
	}
	var nulos: Array[String] = []
	for k: String in mats:
		if not (mats[k] is StandardMaterial3D):
			nulos.append(k)
	_comprobar(nulos.is_empty(), "las %d familias de material salen %s" % [mats.size(), str(nulos)])
	_comprobar(Texturas.hormigon(tinte) == mats["hormigon"] and Texturas.hormigon(Color(0.2, 0.2, 0.2)) != mats["hormigon"]
		and Texturas.hormigon(tinte, 99) != mats["hormigon"], "en caché por tinte y semilla (y distintos si cambian)")
	_comprobar((mats["hormigon"] as StandardMaterial3D).albedo_color == tinte and (mats["hormigon"] as StandardMaterial3D).normal_enabled, "el hormigón lleva el tinte pedido y relieve")
	_comprobar((mats["cristal"] as StandardMaterial3D).emission_enabled and not Texturas.cristal(false).emission_enabled, "ventana encendida emite; apagada, no")
	var ch: StandardMaterial3D = mats["churrete"]
	_comprobar(ch.transparency == BaseMaterial3D.TRANSPARENCY_ALPHA and ch.albedo_texture != null and ch.albedo_texture.get_size() == Vector2(64, 128),
		"churrete: textura de 64x128 con transparencia")
