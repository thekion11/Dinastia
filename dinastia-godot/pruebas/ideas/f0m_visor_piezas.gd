extends BaseIdea
## FASE 0 (M-404/M-279): pruebas directas de piezas sueltas de `visor/` sin prueba:
## `MotorCocheSonido`, `RopaSeparada`, `KitTextureFactory`, `Girador`, `Expresion` y
## `Retrato3D`. Con mallas y materiales sintéticos (no hace falta el partido) y
## contando nodos antes y después: lo que se monta se libera entero.

func _probar() -> void:
	_titulo("FASE 0 · VISOR: PIEZAS SUELTAS (f0m)")
	_probar_motor_coche()
	_probar_ropa_separada()
	_probar_kit_factory()
	_probar_girador()
	_probar_expresion()
	_probar_retrato3d()

## Nodos vivos: los del árbol y los sueltos (huérfanos).
func _nodos() -> int:
	return int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT) + Performance.get_monitor(Performance.OBJECT_ORPHAN_NODE_COUNT))

# --------------------------------------------------------- MotorCocheSonido

func _probar_motor_coche() -> void:
	_linea("· MotorCocheSonido")
	var parado := MotorCocheSonido.rpm_de(0.0)
	_comprobar(parado == Vector2(MotorCocheSonido.RPM_RALENTI, 1), "parado: ralentí en primera")
	_comprobar(MotorCocheSonido.rpm_de(2.0 / 3.6).x == MotorCocheSonido.RPM_RALENTI, "a 2 km/h, todavía ralentí")
	var antes := MotorCocheSonido.rpm_de(21.9 / 3.6)
	var despues := MotorCocheSonido.rpm_de(22.5 / 3.6)
	_comprobar(antes.y == 1 and despues.y == 2 and antes.x > 5000.0 and despues.x < 2200.0, "a 22 km/h cambia a segunda y la nota cae (%d → %d rpm)" % [antes.x, despues.x])
	var sube := true
	for kmh in range(25, 41, 3):
		sube = sube and MotorCocheSonido.rpm_de(float(kmh + 1) / 3.6).x >= MotorCocheSonido.rpm_de(float(kmh) / 3.6).x
	_comprobar(sube, "dentro de una marcha, más velocidad = más revoluciones")
	var tope := MotorCocheSonido.rpm_de(250.0 / 3.6)
	_comprobar(tope.y == 5 and tope.x == MotorCocheSonido.RPM_CORTE, "a 250 km/h: quinta y al corte, sin pasarse")
	_comprobar(MotorCocheSonido.rpm_de(-15.0) == MotorCocheSonido.rpm_de(15.0), "marcha atrás suena como hacia delante")
	var marchas := {}
	for kmh in range(0, 200, 2):
		marchas[int(MotorCocheSonido.rpm_de(float(kmh) / 3.6).y)] = true
	_comprobar(marchas.size() == 5, "cinco marchas en total (%s)" % str(marchas.keys()))
	var n0 := _nodos()
	var mc := MotorCocheSonido.new()
	add_child(mc)
	_comprobar(mc.stream is AudioStreamGenerator, "suena con un generador sintetizado, no con un fichero")
	for i in 30:
		mc.poner(30.0 / 3.6, 1.0)
	_comprobar(mc.marcha == 2 and mc.rpm > MotorCocheSonido.RPM_RALENTI and is_finite(mc.volume_db), "acelerando a 30 km/h: segunda y las rpm suben (%d)" % mc.rpm)
	mc.free()
	_comprobar(_nodos() == n0, "y se libera sin dejar nodos")

# ------------------------------------------------------------- RopaSeparada

## Un «cuerpo» de prueba: un triángulo por zona (camiseta, pantalón, medias), uno
## que cruza zonas y uno en la cabeza. Normales a +Z, huesos y pesos de 4 en 4.
func _malla_cuerpo() -> ArrayMesh:
	var pos := PackedVector3Array([
		Vector3(0, 1.3, 0), Vector3(0.1, 1.3, 0), Vector3(0, 1.4, 0),
		Vector3(0, 0.8, 0), Vector3(0.1, 0.8, 0), Vector3(0, 0.9, 0),
		Vector3(0, 0.3, 0), Vector3(0.1, 0.3, 0), Vector3(0, 0.4, 0),
		Vector3(0, 1.7, 0), Vector3(0.05, 1.7, 0), Vector3(0, 1.75, 0)])
	var nor := PackedVector3Array()
	var uv := PackedVector2Array()
	var huesos := PackedInt32Array()
	var pesos := PackedFloat32Array()
	for i in pos.size():
		nor.append(Vector3(0, 0, 1))
		uv.append(Vector2(float(i) / 12.0, 0.5))
		huesos.append_array([i, 0, 0, 0])
		pesos.append_array([1.0, 0.0, 0.0, 0.0])
	var arr := []
	arr.resize(Mesh.ARRAY_MAX)
	arr[Mesh.ARRAY_VERTEX] = pos
	arr[Mesh.ARRAY_NORMAL] = nor
	arr[Mesh.ARRAY_TEX_UV] = uv
	arr[Mesh.ARRAY_BONES] = huesos
	arr[Mesh.ARRAY_WEIGHTS] = pesos
	arr[Mesh.ARRAY_INDEX] = PackedInt32Array([0, 1, 2, 3, 4, 5, 6, 7, 8, 0, 3, 6, 9, 10, 11])
	var am := ArrayMesh.new()
	am.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arr)
	return am

func _probar_ropa_separada() -> void:
	_linea("· RopaSeparada")
	var zonas := [[Vector3(0, 1.3, 0), 1], [Vector3(0.3, 1.4, 0), 1], [Vector3(-0.5, 1.4, 0), 0], [Vector3(0, 0.8, 0), 2],
		[Vector3(0, 0.3, 0), 3], [Vector3(0, 0.05, 0), 0], [Vector3(0, 1.62, 0), 0]]
	var mal: Array[String] = []
	for z: Array in zonas:
		if RopaSeparada.prenda_en(z[0]) != int(z[1]):
			mal.append(str(z[0]))
	_comprobar(mal.is_empty(), "prenda_en(): torso y manga → camiseta, mano y cabeza → nada, pantalón, medias %s" % str(mal))
	_comprobar(RopaSeparada.holgura_en(1, Vector3(0.42, 1.4, 0)) > RopaSeparada.holgura_en(1, Vector3(0.23, 1.4, 0)), "la manga se abre hacia el puño")
	_comprobar(RopaSeparada.holgura_en(1, Vector3(0, 1.0, 0)) > RopaSeparada.holgura_en(1, Vector3(0, 1.3, 0)), "la camiseta, más suelta abajo que en el pecho")
	_comprobar(RopaSeparada.holgura_en(2, Vector3(0, 0.62, 0)) > RopaSeparada.holgura_en(2, Vector3(0, 0.9, 0)) and RopaSeparada.holgura_en(3, Vector3.ZERO) == 0.006
		and RopaSeparada.holgura_en(0, Vector3.ZERO) == 0.0, "el pantalón se abre en la pernera; las medias, ajustadas")
	var am := _malla_cuerpo()
	var ms := RopaSeparada.mallas(am, 0)
	_comprobar(ms.size() == 3 and ms.has(1) and ms.has(2) and ms.has(3), "tres prendas sacadas del cuerpo")
	var ok := true
	for k: int in [1, 2, 3]:
		var p: ArrayMesh = ms.get(k)
		ok = ok and p != null and p.surface_get_array_len(0) == 3 and p.surface_get_array_index_len(0) == 3 and int(p.get_meta("prenda", 0)) == k
	_comprobar(ok, "cada una con SU triángulo: el que cruza zonas y el de la cabeza se quedan fuera")
	if ms.has(1):
		var a: Array = (ms[1] as ArrayMesh).surface_get_arrays(0)
		var v0: Vector3 = (a[Mesh.ARRAY_VERTEX] as PackedVector3Array)[0]
		var hb: PackedInt32Array = a[Mesh.ARRAY_BONES]
		_comprobar(is_equal_approx(v0.z, RopaSeparada.holgura_en(1, Vector3(0, 1.3, 0))) and is_equal_approx(v0.y, 1.3), "la tela se separa del cuerpo por la normal, lo que dice holgura_en")
		_comprobar(hb.size() == 12 and hb[0] == 0 and hb[4] == 1, "y conserva los huesos de sus vértices (se mueve con el jugador)")
	_comprobar(is_same(RopaSeparada.mallas(am, 0), ms), "en caché por malla de cuerpo")
	## Vestir: tres prendas colgadas junto al cuerpo, con su material.
	var n0 := _nodos()
	var padre := Node3D.new()
	add_child(padre)
	var cuerpo := MeshInstance3D.new()
	cuerpo.mesh = am
	padre.add_child(cuerpo)
	var sh := Shader.new()
	sh.code = "shader_type spatial;\nuniform int prenda = 0;\nuniform float holgura = 0.1;\nvoid fragment() { ALBEDO = vec3(1.0); }\n"
	var mat := ShaderMaterial.new()
	mat.shader = sh
	_comprobar(not RopaSeparada.vestido(cuerpo), "sin vestir, vestido() es falso")
	RopaSeparada.vestir(cuerpo, 0, mat)
	var prendas := padre.get_children().filter(func(h: Node) -> bool: return h.has_meta("prenda_aparte"))
	var mats_ok := prendas.size() == 3
	for h: MeshInstance3D in prendas:
		var cual := int((h.mesh as ArrayMesh).get_meta("prenda"))
		mats_ok = mats_ok and int((h.material_override as ShaderMaterial).get_shader_parameter("prenda")) == cual and h.material_override != mat
	_comprobar(RopaSeparada.vestido(cuerpo) and mats_ok, "vestir(): 3 prendas, cada una con su material (prenda 1, 2, 3)")
	_comprobar(RopaSeparada.material_de(mat, 2) == RopaSeparada.material_de(mat, 2), "material_de() en caché")
	RopaSeparada.vestir(cuerpo, 0, mat)
	var vivas := padre.get_children().filter(func(h: Node) -> bool: return h.has_meta("prenda_aparte") and not h.is_queued_for_deletion())
	_comprobar(vivas.size() == 3, "vestir dos veces no duplica: las de antes se van")
	padre.free()
	_comprobar(_nodos() == n0, "y al quitar el cuerpo no queda nada")

# -------------------------------------------------------- KitTextureFactory

func _probar_kit_factory() -> void:
	_linea("· KitTextureFactory")
	var f := KitTextureFactory.new()
	## Colores de 8 bits exactos: la imagen RGBA8 los guarda tal cual.
	var rojo := Color8(204, 26, 26)
	var m8 := f.get_material(rojo, Color.WHITE, "liso", 8, 0)
	_comprobar(m8 != null and m8.albedo_texture != null and m8.albedo_texture.get_size() == Vector2(1024, 1024), "un material con el atlas de 1024x1024")
	var bases_ok := f._base_images.size() == KitTextureFactory.BASE_SKINS.size()
	for bi: Image in f._base_images:
		bases_ok = bases_ok and not bi.is_compressed() and bi.get_format() == Image.FORMAT_RGBA8
	_comprobar(bases_ok, "las pieles base se pintan en RGBA8 (las importadas vienen comprimidas: hay que descomprimirlas)")
	_comprobar(f.get_material(rojo, Color.WHITE, "liso", 8, 0) == m8 and f.get_material(rojo, Color.WHITE, "liso", 9, 0) != m8, "en caché por equipación y dorsal")
	_comprobar(f.get_material(rojo, Color.WHITE, "liso", 8, 99) != null, "una variante fuera de rango se acota (no revienta)")
	## El dorsal, en siete segmentos y solo en la espalda (sobre una imagen propia).
	var img := Image.create(1024, 1024, false, Image.FORMAT_RGBA8)
	img.fill(rojo)
	f._paint_dorsal(img, 8, Color.WHITE)
	var cx := KitTextureFactory.TORSO_ESPALDA.position.x + KitTextureFactory.TORSO_ESPALDA.size.x / 2
	var cy := KitTextureFactory.TORSO_ESPALDA.position.y + int(KitTextureFactory.TORSO_ESPALDA.size.y * 0.30)
	_comprobar(img.get_pixel(cx, cy + 5).is_equal_approx(Color.WHITE) and img.get_pixel(cx, cy + 48 - 5 + 5).is_equal_approx(Color.WHITE),
		"el 8: segmento de arriba y del medio encendidos")
	var img1 := Image.create(1024, 1024, false, Image.FORMAT_RGBA8)
	img1.fill(rojo)
	f._paint_dorsal(img1, 1, Color.WHITE)
	_comprobar(img1.get_pixel(cx, cy + 5).is_equal_approx(rojo) and img1.get_pixel(cx + 31 - 5, cy + 20).is_equal_approx(Color.WHITE), "el 1: solo la barra de la derecha")
	var pecho := false
	for y in range(KitTextureFactory.TORSO_PECHO.position.y, KitTextureFactory.TORSO_PECHO.end.y, 4):
		for x in range(KitTextureFactory.TORSO_PECHO.position.x, KitTextureFactory.TORSO_PECHO.end.x, 4):
			pecho = pecho or img.get_pixel(x, y).is_equal_approx(Color.WHITE)
	_comprobar(not pecho, "y nada en el pecho (taparía el escudo)")
	var img0 := Image.create(1024, 1024, false, Image.FORMAT_RGBA8)
	f._paint_dorsal(img0, 0, Color.WHITE)
	_comprobar(img0.get_pixel(cx, cy + 5).a == 0.0, "dorsal 0: sin número")
	## El color dominante (no el promedio): azul con una banda amarilla y letras.
	var k := Image.create(200, 200, false, Image.FORMAT_RGBA8)
	var azul := Color8(12, 51, 153)
	k.fill(azul)
	k.fill_rect(Rect2i(0, 80, 200, 40), Color8(242, 204, 26))
	k.fill_rect(Rect2i(60, 30, 20, 20), Color.WHITE)
	var dom := KitTextureFactory._color_dominante(k, Rect2i(0, 0, 200, 200))
	_comprobar(dom.is_equal_approx(azul), "color dominante: el azul, no un gris de promedio (%s)" % dom.to_html(false))

# ------------------------------------------------------------------ Girador

func _probar_girador() -> void:
	_linea("· Girador")
	var g := Girador.new()
	g.vel = 2.0
	for i in 4:
		g._process(0.1)
	var ang := g.transform.basis.x.signed_angle_to(Vector3.RIGHT, Vector3.BACK)
	_comprobar(absf(absf(ang) - 0.8) < 0.001 and g.transform.basis.z.is_equal_approx(Vector3.BACK), "gira sobre su Z local a vel·delta (0,8 rad en 0,4 s) sin cabecear")
	g.free()

# ----------------------------------------------------------------- Expresion

func _probar_expresion() -> void:
	_linea("· Expresion")
	_comprobar(Expresion.por_animo(0.8) == "alegre" and Expresion.por_animo(-0.8) == "triste" and Expresion.por_animo(0.1) == "neutral", "el gesto que pega con el ánimo")
	var n0 := _nodos()
	var cuerpo := Node3D.new()
	var mi := MeshInstance3D.new()
	mi.mesh = BoxMesh.new()
	cuerpo.add_child(mi)
	var ojos := ShaderMaterial.new()
	ojos.shader = load(Expresion.SHADER_OJOS)
	ojos.set_shader_parameter("apertura", 0.9)
	mi.set_surface_override_material(0, ojos)
	var e := Expresion.de(cuerpo)
	_comprobar(e != null and Expresion.de(cuerpo) == e and cuerpo.get_children().filter(func(h: Node) -> bool: return h is Expresion).size() == 1, "de(): una sola por personaje")
	var propio := mi.get_surface_override_material(0) as ShaderMaterial
	_comprobar(e.tiene_ojos() and propio != ojos and is_equal_approx(float(ojos.get_shader_parameter("apertura")), 0.9), "encuentra los ojos y se los duplica (no cambia los de todo el mundo)")
	e._t_parpadeo = 1000.0
	e.poner("alegre", 1.0)
	for i in 30:
		e._process(0.02)
	var ap := float(propio.get_shader_parameter("apertura"))
	_comprobar(e.gesto() == "alegre" and absf(ap - 0.9 * Expresion.GESTOS["alegre"]) < 0.01, "alegre: los ojos se entornan (%.3f)" % ap)
	for i in 30:
		e._process(0.02)
	_comprobar(e.gesto() == "neutral", "y al acabar su tiempo vuelve a neutral")
	e._t_parpadeo = 0.0
	e._process(0.01)
	_comprobar(float(propio.get_shader_parameter("apertura")) < 0.1, "parpadeo: el ojo se cierra de golpe")
	e.poner("no_existe")
	_comprobar(e.gesto() == "neutral", "un gesto desconocido = neutral")
	var sin := Node3D.new()
	var e2 := Expresion.de(sin)
	e2._process(0.1)
	_comprobar(not e2.tiene_ojos() and not e2.is_processing(), "sin ojos: se apaga y no gasta fotogramas")
	sin.free()
	cuerpo.free()
	_comprobar(_nodos() == n0, "sin nodos sueltos al terminar")

# ----------------------------------------------------------------- Retrato3D

## Sin pantalla no se renderiza nada: se comprueba el encargo (marcador, tamaño,
## caché y cola), que es lo que la interfaz recibe al instante.
func _probar_retrato3d() -> void:
	_linea("· Retrato3D")
	_comprobar(not Retrato3D.disponible(), "en headless no está disponible (la ficha usa el retrato antiguo)")
	var previo: Retrato3D = Retrato3D._inst
	var falso := Retrato3D.new()
	Retrato3D._inst = falso
	var j := Jugador.new()
	j.id = "f0m_retrato"
	var cola0 := Retrato3D._cola.size()
	var chico := Retrato3D.textura(j, "#c01020", "#ffffff", 64)
	var grande := Retrato3D.textura(j, "#c01020", "#ffffff", 150)
	_comprobar(chico.get_size() == Vector2(Retrato3D.TAM_CHICO, Retrato3D.TAM_CHICO) and grande.get_size() == Vector2(Retrato3D.TAM_GRANDE, Retrato3D.TAM_GRANDE), "dos resoluciones según el alto pedido")
	_comprobar(Retrato3D.textura(j, "#c01020", "#ffffff", 64) == chico and Retrato3D._cola.size() == cola0 + 2, "en caché: un encargo por jugador, tamaño y camiseta")
	var im := chico.get_image()
	var esperado := Color(Color("#c01020").darkened(0.55), 1.0)
	var px := im.get_pixel(5, 5) if im != null else Color.WHITE
	_comprobar(absf(px.r - esperado.r) < 0.01 and absf(px.g - esperado.g) < 0.01 and absf(px.b - esperado.b) < 0.01, "el marcador es el color del club, oscurecido, hasta que llega el retrato")
	Retrato3D.limpiar_cache()
	_comprobar(Retrato3D._cola.is_empty() and Retrato3D._cache.is_empty(), "limpiar_cache() vacía caché y cola")
	falso.free()
	Retrato3D._inst = previo
