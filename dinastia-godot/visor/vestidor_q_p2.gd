extends "res://visor/vestidor_q_p1.gd"
## (Parte 2 de 3 de `vestidor_q.gd`.)

## Pinta la equipación sobre un `FutbolistaQ` ya terminado. Devuelve false si
## no pudo (sin shader o sin máscara) y quien llama cae a `vestir()`.
##
## `pantalon`/`medias` con alfa 0 = automáticos: medias del color principal,
## pantalón del secundario en una camiseta lisa y del principal en una con
## dibujo (Boca: azul con franja oro y pantalón azul; Colo-Colo: blanca lisa y
## pantalón negro).
static func vestir_equipacion(d: Dictionary, c1: Color, c2: Color, estilo: String,
		piel: Color, pelo: Color, pantalon: Color = Color(0, 0, 0, 0),
		medias: Color = Color(0, 0, 0, 0), largo: bool = false, kit_x: Dictionary = {}, dorsal: int = 0) -> bool:
	var modelo: Node = d.get("modelo")
	if modelo == null or not ResourceLoader.exists(SHADER_EQUIPACION) \
			or not ResourceLoader.exists(MASCARA) or not ResourceLoader.exists(COORDS):
		return false
	var cuerpo: MeshInstance3D = null
	var superficie := -1
	var es_mujer := false
	for mv in _mallas(modelo):
		var mi: MeshInstance3D = mv
		if mi.mesh == null:
			continue
		for s in mi.mesh.get_surface_count():
			var m := mi.get_active_material(s)
			if m == null:
				continue
			match m.resource_name:
				MATERIAL_CUERPO, "MI_Superhero_Female":
					cuerpo = mi
					superficie = s
					es_mujer = m.resource_name == "MI_Superhero_Female"
				MATERIAL_CEJAS, "MI_Hair_2":  # el cuerpo de mujer trae sus cejas con MI_Hair_2
					mi.set_surface_override_material(s, _material_liso(PeloQ.color_cejas(pelo), 0.9))
					if String(mi.name).begins_with("Eyebrows"):
						PeloQ.sin_lejos(mi)
				MATERIAL_OJOS:
					## Las texturas de ojos del pack no vinieron en el repo:
					## sin esto, blanco puro de fábrica y mirada de maniquí.
					mi.set_surface_override_material(s, _material_liso(Color(0.12, 0.09, 0.07), 0.3))
					PeloQ.sin_lejos(mi, DIST_OJOS)
	if cuerpo == null:
		return false
	## REALISMO (26-9-2026): la posición de reposo de cada vértice, escrita en
	## la malla (UV2 = x,y; COLOR.r = z). Con ella el dibujo y los cortes de
	## las prendas se calculan exactos por píxel; con la textura de 8 bits de
	## antes salían en escalones de 7 mm.
	_con_reposo(cuerpo, superficie)
	var estilos: Variant = Datos.tabla("KITS")
	var i_estilo: int = maxi(0, (estilos as Array).find(estilo)) if estilos is Array else 0
	if pantalon.a == 0.0:
		pantalon = c2 if i_estilo == 0 else c1
	if medias.a == 0.0:
		medias = c1
	## EL DISEÑADOR (26-9-2026): sin equipación completa, se arma una con lo de
	## siempre (colores, estilo, pantalón y medias) para que TODO pase por el
	## mismo camino del shader.
	var kit := kit_x
	if kit.is_empty():
		kit = {"dis": estilo if DisenosKit.claves().has(estilo) else "liso",
			"cols": [c1.to_html(false), c2.to_html(false), c2.darkened(0.35).to_html(false), "ffffff", "111111"],
			"trim": 1, "num": "ffffff",
			"pant": {"dis": "liso", "c1": pantalon.to_html(false), "c2": c1.to_html(false)},
			"med": {"dis": "lisas", "c1": medias.to_html(false), "c2": c2.to_html(false)},
			"bot": {"mod": _botin_de(dorsal, c1)}, "acc": {}}
	var clave := "%s|%s|%d|%s|%s|%s|%s|%d|%d" % [c1.to_html(false), c2.to_html(false), i_estilo,
		pantalon.to_html(false), medias.to_html(false), _piel_cuantizada(piel), largo, hash(kit), dorsal]
	## Cuerpo de mujer y de hombre NO comparten material (13-10-2026): su
	## textura de piel y sus medidas son otras.
	if es_mujer:
		clave += "|m"
	var mat: ShaderMaterial = _cache_equipacion.get(clave)
	if mat == null:
		var original := cuerpo.get_active_material(superficie) as BaseMaterial3D
		mat = ShaderMaterial.new()
		mat.shader = load(SHADER_EQUIPACION)
		if original != null and original.albedo_texture != null:
			mat.set_shader_parameter("piel_tex", original.albedo_texture)
		if original != null and original.normal_enabled and original.normal_texture != null:
			mat.set_shader_parameter("normal_tex", original.normal_texture)
			mat.set_shader_parameter("usa_normal", true)
		mat.set_shader_parameter("mascara", load(MASCARA))
		mat.set_shader_parameter("coords", load(COORDS))
		mat.set_shader_parameter("color1", c1)
		mat.set_shader_parameter("color2", c2)
		mat.set_shader_parameter("color_pantalon", pantalon)
		mat.set_shader_parameter("color_medias", medias)
		mat.set_shader_parameter("estilo", i_estilo)
		mat.set_shader_parameter("tinte_piel", _tinte(piel))
		## La muñeca (fin de la manga larga) del cuerpo de mujer está más adentro.
		mat.set_shader_parameter("muneca", 0.69 if es_mujer else 0.755)
		mat.set_shader_parameter("dy_cuerpo", -0.06 if es_mujer else 0.0)
		var pl := piel.srgb_to_linear()
		mat.set_shader_parameter("piel_obj", Vector3(pl.r, pl.g, pl.b))
		mat.set_shader_parameter("largo", largo)
		mat.set_shader_parameter("usa_reposo", (cuerpo.mesh as ArrayMesh) != null and cuerpo.mesh.has_meta("con_reposo"))
		var un := DisenosKit.uniforms(kit, dorsal)
		for k: String in un:
			mat.set_shader_parameter(k, un[k])
		_cache_equipacion[clave] = mat
	if ropa_aparte and (cuerpo.mesh as ArrayMesh) != null and cuerpo.mesh.has_meta("con_reposo"):
		## El cuerpo, sin inflar (las prendas ya tienen su volumen).
		var k2 := clave + "|aparte"
		var mat_c: ShaderMaterial = _cache_equipacion.get(k2)
		if mat_c == null:
			mat_c = mat.duplicate() as ShaderMaterial
			mat_c.set_shader_parameter("holgura", 0.0)
			_cache_equipacion[k2] = mat_c
		cuerpo.set_surface_override_material(superficie, mat_c)
		RopaSeparada.vestir(cuerpo, superficie, mat)
		return true
	elif cuerpo.get_parent() != null:
		for h in cuerpo.get_parent().get_children():
			if h.has_meta("prenda_aparte"):
				h.queue_free()
	## Sin pantalla (banco headless) la malla no trae superficies.
	if superficie >= cuerpo.get_surface_override_material_count():
		return false
	cuerpo.set_surface_override_material(superficie, mat)
	return true

## La misma normalización de exposición que `cara_malla.gdshader` (por la
## luminancia lineal de su piel en la foto).
static func exposicion_piel(lum: float) -> float:
	## (Última pasada, 5-10: con 0,55·l^0,6/l las pieles medias y oscuras
	## salían hundidas por el pie del mapeo de tonos -medido de día: Ayoze al
	## 74 %, Kondogbia casi negro-. Las claras no cambian; el orden se mantiene.)
	return clampf(pow(0.39 / maxf(lum, 0.001), 0.53), 1.0, 3.0)
## La compensación de saturación, mayor en pieles oscuras (salían naranjas).
## La misma cuenta que `cara_malla.gdshader`.
static func compensar_piel(lum: float) -> float:
	return COMPENSAR_PIEL + 0.8 * clampf((0.25 - lum) / 0.2, 0.0, 1.0)

## La transformación afín que lleva los ojos y la boca del retrato (espacio
## 0-64 de `Cara.svg_rasgos`) a los de la foto (0-1). [] si no hay puntos o
## son degenerados.
static func _afin_foto(p: Array) -> Array:
	if p.size() < 6:
		return []
	var origen := [Vector2(26, 33), Vector2(38, 33), Vector2(32, 44.5)]
	var destino := [Vector2(p[0], p[1]), Vector2(p[2], p[3]), Vector2(p[4], p[5])]
	## Resolver [a b c; d e f] con tres puntos: base con el primero.
	var o1: Vector2 = origen[1] - origen[0]
	var o2: Vector2 = origen[2] - origen[0]
	var d1: Vector2 = destino[1] - destino[0]
	var d2: Vector2 = destino[2] - destino[0]
	var det := o1.x * o2.y - o1.y * o2.x
	if absf(det) < 0.001 or absf(d1.x * d2.y - d1.y * d2.x) < 0.0001:
		return []
	## M * o1 = d1 y M * o2 = d2  =>  M = [d1 d2] * inversa([o1 o2]).
	var inv := [Vector2(o2.y, -o1.y) / det, Vector2(-o2.x, o1.x) / det]  # columnas de la inversa
	var a: float = d1.x * inv[0].x + d2.x * inv[0].y
	var b: float = d1.x * inv[1].x + d2.x * inv[1].y
	var dd: float = d1.y * inv[0].x + d2.y * inv[0].y
	var e: float = d1.y * inv[1].x + d2.y * inv[1].y
	var c: float = destino[0].x - (a * origen[0].x + b * origen[0].y)
	var f: float = destino[0].y - (dd * origen[0].x + e * origen[0].y)
	return [Vector3(a, b, c), Vector3(dd, e, f)]

## Esconde las cejas (las del cuerpo y las de `PeloQ`) y la barba 3D.
static func _ocultar_cejas_y_barba(raiz: Node) -> void:
	if raiz == null:
		return
	for mv in _mallas(raiz):
		var mi: MeshInstance3D = mv
		if mi.name in ["Eyebrows", "Eyebrows_Regular", "Hair_Beard"]:
			mi.visible = false

## Tiñe el pelo 3D (`PeloQ`) con el color de la foto (misma cuenta que
## `PeloQ._material`: la textura del pack es oscura y se aclara x1,7).
static func _teñir_pelo(raiz: Node, color: Color) -> void:
	var pelo := raiz.find_child("Pelo", true, false)
	if pelo == null:
		return
	for mv in _mallas(pelo):
		var mi: MeshInstance3D = mv
		var m := mi.material_override as StandardMaterial3D
		if m == null:
			continue
		m = m.duplicate() as StandardMaterial3D
		m.albedo_color = Color(minf(color.r * 1.7, 1.0), minf(color.g * 1.7, 1.0), minf(color.b * 1.7, 1.0))
		mi.material_override = m

## Esconde el peinado genérico de `PeloQ` (el pelo por capas lo reemplaza).
static func _ocultar_peinado(raiz: Node) -> void:
	var pelo := raiz.find_child("Pelo", true, false)
	if pelo == null:
		return
	for mv in _mallas(pelo):
		(mv as MeshInstance3D).visible = false

## Cuánto hay que multiplicar la foto (por canal, en lineal) para que su piel
## media sea la piel del modelo: la media de un óvalo de la cara (sin ojos
## ni boca, que son más oscuros) contra el tono del jugador.
static func _ajuste_foto(foto: Texture2D, af: Array, piel: Color) -> Vector3:
	var img := foto.get_image()
	if img == null or af.size() != 2:
		return Vector3.ONE
	if img.is_compressed():
		img.decompress()
	var w := img.get_width()
	var h := img.get_height()
	var suma := Vector3.ZERO
	var n := 0
	for sy in range(28, 52, 2):
		for sx in range(22, 43, 2):
			var ov := Vector2((sx - 32.0) / 9.5, (sy - 39.0) / 12.5)
			if ov.length() > 1.0:
				continue
			## Fuera ojos, cejas y boca.
			if absf(sy - 32.0) < 3.5 or absf(sy - 44.5) < 2.5:
				continue
			var q := Vector3(sx, sy, 1.0)
			var px := int((af[0] as Vector3).dot(q) * w)
			var py := int((af[1] as Vector3).dot(q) * h)
			if px < 0 or py < 0 or px >= w or py >= h:
				continue
			var c := img.get_pixel(px, py).srgb_to_linear()
			suma += Vector3(c.r, c.g, c.b)
			n += 1
	if n < 8:
		return Vector3.ONE
	var media := suma / float(n)
	var objetivo := piel.srgb_to_linear()
	return Vector3(clampf(objetivo.r / maxf(media.x, 0.01), 0.5, 1.8),
		clampf(objetivo.g / maxf(media.y, 0.01), 0.5, 1.8),
		clampf(objetivo.b / maxf(media.z, 0.01), 0.5, 1.8))

## Si la foto es de tres cuartos, qué mitad mira a la cámara (-1 la izquierda
## de la imagen, 1 la derecha), o 0 si es de frente. La punta de la nariz se
## corre hacia el lado lejano (medido con 5 retratos: de frente < 0,02; tres
## cuartos 0,14-0,28).
static func _lado_foto(p: Array) -> int:
	if p.size() < 8:
		return 0
	var sep := absf(float(p[2]) - float(p[0]))
	if sep < 0.001:
		return 0
	var corrida := (float(p[6]) - (float(p[0]) + float(p[2])) * 0.5) / sep
	if corrida > 0.12:
		return -1
	if corrida < -0.12:
		return 1
	return 0

## Como `_con_reposo` pero sin el alisado: solo la pose de reposo (UV2 = x,y;
## COLOR.r = z) en todas las superficies. Para los ojos.
static func _con_reposo_simple(mi: MeshInstance3D) -> void:
	var original := mi.mesh as ArrayMesh
	if original == null or original.has_meta("con_reposo"):
		return
	var id := original.get_instance_id()
	if _mallas_reposo.has(id):
		mi.mesh = _mallas_reposo[id]
		return
	var nueva := ArrayMesh.new()
	nueva.blend_shape_mode = original.blend_shape_mode
	for bs in original.get_blend_shape_count():
		nueva.add_blend_shape(original.get_blend_shape_name(bs))
	for s in original.get_surface_count():
		var arr := original.surface_get_arrays(s)
		var pos: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
		var uv2 := PackedVector2Array()
		var col := PackedColorArray()
		uv2.resize(pos.size())
		col.resize(pos.size())
		for i in pos.size():
			uv2[i] = Vector2(pos[i].x, pos[i].y)
			col[i] = Color(clampf((pos[i].z + 0.25) / 0.5, 0.0, 1.0), 0.0, 0.0, 1.0)
		arr[Mesh.ARRAY_TEX_UV2] = uv2
		arr[Mesh.ARRAY_COLOR] = col
		## Conservar el formato de los canales CUSTOM (los ojos traen uno) y los
		## 8 huesos por vértice: sin eso Godot rechaza la superficie.
		var fmt := original.surface_get_format(s)
		var banderas := fmt & Mesh.ARRAY_FLAG_USE_8_BONE_WEIGHTS
		for c in 4:
			var shift: int = Mesh.ARRAY_FORMAT_CUSTOM0_SHIFT + c * Mesh.ARRAY_FORMAT_CUSTOM_BITS
			banderas |= fmt & (Mesh.ARRAY_FORMAT_CUSTOM_MASK << shift)
		nueva.add_surface_from_arrays(original.surface_get_primitive_type(s), arr, original.surface_get_blend_shape_arrays(s),
			lods_de(original, s), banderas)
		if nueva.get_surface_count() <= s:
			return
		nueva.surface_set_material(s, original.surface_get_material(s))
		nueva.surface_set_name(s, original.surface_get_name(s))
	nueva.set_meta("con_reposo", true)
	_mallas_reposo[id] = nueva
	mi.mesh = nueva
