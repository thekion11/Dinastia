class_name PiezasObra
extends RefCounted
## LAS PIEZAS DE OBRA (3-11-2026, memoria del menú): una caja con material (y colisión), el material compartido por color y el rótulo en 3D. Salieron
## de `TunelVestuario` porque las usan también el edificio del club, la galería y el museo, y por eso arrastraban el túnel (y con él el constructor del
## estadio entero) a la memoria al abrir el menú. Esto no depende de nada del juego. `TunelVestuario._caja` etc. siguen existiendo y llaman aquí.

## Una caja con material y, si `solida`, con colisión.
static func _caja(padre: Node3D, pos: Vector3, tam: Vector3, mat: Material, solida: bool) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = tam
	mi.mesh = bm
	mi.position = pos
	mi.material_override = mat
	padre.add_child(mi)
	if solida:
		var cuerpo := StaticBody3D.new()
		var forma := CollisionShape3D.new()
		var bs := BoxShape3D.new()
		bs.size = tam
		forma.shape = bs
		cuerpo.add_child(forma)
		cuerpo.position = pos
		padre.add_child(cuerpo)
	return mi

## MATERIALES COMPARTIDOS (2-11-2026, auditoría 28-10 §1): `_mat` devuelve el MISMO material para el mismo color y
## rugosidad. Quien lo vaya a MODIFICAR (o cambiarlo desde el nodo) pide `_mat_unico`. `materiales_alterados()` lo vigila.
static var _cache_mat := {}

static func _mat(c: Color, rugosidad: float) -> StandardMaterial3D:
	var k := "%s|%.3f" % [c.to_html(true), rugosidad]
	if _cache_mat.has(k):
		return (_cache_mat[k] as Dictionary)["m"]
	var m := _mat_unico(c, rugosidad)
	_cache_mat[k] = {"m": m, "c": c, "rug": rugosidad}
	return m

static func _mat_unico(c: Color, rugosidad: float) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = rugosidad
	return m

static func materiales_alterados() -> Array:
	var malos: Array = []
	for k: String in _cache_mat:
		var d: Dictionary = _cache_mat[k]
		var m: StandardMaterial3D = d["m"]
		var ref := _mat_unico(d["c"], d["rug"])
		if m.albedo_color != ref.albedo_color or not is_equal_approx(m.roughness, ref.roughness) \
				or not is_equal_approx(m.metallic, ref.metallic) or m.transparency != ref.transparency \
				or m.emission_enabled != ref.emission_enabled or m.cull_mode != ref.cull_mode or m.albedo_texture != ref.albedo_texture:
			malos.append(k)
	return malos

## Texto en 3D. `giro`: rotación en Y (0 = mira a +Z).
static func _rotulo(padre: Node3D, texto: String, pos: Vector3, giro: float, tam: int, col: Color) -> void:
	var l := Label3D.new()
	l.text = texto
	l.font_size = tam
	l.pixel_size = 0.006
	l.modulate = col
	l.outline_size = 6
	l.outline_modulate = Color(0, 0, 0, 0.6)
	l.position = pos
	l.rotation.y = giro
	l.double_sided = false
	l.shaded = false
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	padre.add_child(l)


## Un rótulo que NO pasa de `ancho_max` m (el hueco entre dos vitrinas): si el texto es más ancho, baja el cuerpo de la letra (mínimo 8) y, si
## aun así no cabe, lo corta con «…». (A4-M3D-X11: «Supercopa de Campeones Continentales · 2031» pisaba el rótulo de la vitrina de al lado.)
static func _rotulo_ajustado(padre: Node3D, texto: String, pos: Vector3, giro: float, tam: int, col: Color, ancho_max: float) -> void:
	var fuente := ThemeDB.fallback_font
	var t := texto
	var px := tam
	var ancho := func(cadena: String, cuerpo: int) -> float: return fuente.get_string_size(cadena, HORIZONTAL_ALIGNMENT_LEFT, -1, cuerpo).x * 0.006
	if ancho.call(t, px) > ancho_max:
		px = maxi(8, int(float(tam) * ancho_max / float(ancho.call(t, tam))))
	while ancho.call(t, px) > ancho_max and t.length() > 6:
		t = t.left(t.length() - 2).strip_edges() + "…"
	_rotulo(padre, t, pos, giro, px, col)
