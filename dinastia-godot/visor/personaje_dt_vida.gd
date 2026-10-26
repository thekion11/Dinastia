class_name PersonajeVida
extends RefCounted
## QUE EL DT PAREZCA UNA PERSONA (26-10-2026, opción A del dueño: el mismo modelo, sin
## mallas nuevas). Tres cosas, todas por código:
##   1. DE PIE COMO UNA PERSONA: el «parado» del pack es una guardia de combate (medido con
##      una sonda el 26-10: pie izquierdo 12 cm delante, el derecho 34 cm detrás, 45 cm entre
##      pies y la cadera 7,5 cm hundida por las rodillas dobladas). Para el DT las piernas
##      vuelven a su reposo (rectas, bajo la cadera), algo más juntas y con las puntas un
##      poco abiertas; el torso conserva la pose del clip (se compensa el giro de la pelvis).
##   2. VIVO EN REPOSO: respiración, un balanceo lento del peso y, en el estudio, la mirada
##      que sigue un poco a la cámara (`_Vida`).
##   3. LA EDAD SE VE: arrugas pintadas sobre la cara clásica (una pasada encima, que solo
##      oscurece los surcos: el color de piel base no se toca), canas y entradas en el pelo
##      (`envejecer`). Las caras de la biblioteca no se pintan.

const SHADER_ARRUGAS := "res://visor/personaje_arrugas.gdshader"
const SHADER_CANAS := "res://visor/personaje_canas.gdshader"
## Huesos de la pierna que vuelven al reposo.
const PIERNA := ["thigh", "calf", "foot", "ball"]
## Cuánto se juntan los pies (giro de la cadera hacia dentro, rad) y cuánto se abren
## las puntas (giro sobre el eje del muslo, rad).
const JUNTAR := 0.04
const PUNTAS := 0.12

## Convierte (en el sitio) un clip de pie en uno de persona: piernas al reposo y torso
## compensado para que el pecho y la cabeza queden donde los dejaba el clip.
static func piernas_de_persona(a: Animation, esq: Skeleton3D) -> void:
	var pelvis := esq.find_bone("pelvis")
	if pelvis < 0:
		return
	var rest_pelvis := esq.get_bone_rest(pelvis)
	var q_rest := rest_pelvis.basis.get_rotation_quaternion()
	var t_pelvis := -1
	var t_spine := -1
	for t in a.get_track_count():
		var ruta := str(a.track_get_path(t))
		var hueso := ruta.get_slice(":", ruta.get_slice_count(":") - 1)
		var tipo := a.track_get_type(t)
		if hueso == "pelvis" and tipo == Animation.TYPE_POSITION_3D:
			for k in a.track_get_key_count(t):
				a.track_set_key_value(t, k, rest_pelvis.origin)
		elif hueso == "pelvis" and tipo == Animation.TYPE_ROTATION_3D:
			t_pelvis = t
		elif hueso == "spine_01" and tipo == Animation.TYPE_ROTATION_3D:
			t_spine = t
		elif tipo == Animation.TYPE_ROTATION_3D and hueso.length() > 2 and hueso.substr(0, hueso.length() - 2) in PIERNA:
			var i := esq.find_bone(hueso)
			if i < 0:
				continue
			var q := esq.get_bone_rest(i).basis.get_rotation_quaternion()
			if hueso.begins_with("thigh"):
				## Rest del muslo: apunta hacia abajo; Z local = de lado, Y local = a lo largo.
				var s := 1.0 if hueso.ends_with("_l") else -1.0
				q = q * Quaternion(Vector3(0, 0, 1), JUNTAR * s) * Quaternion(Vector3(0, 1, 0), PUNTAS * s)
			for k in a.track_get_key_count(t):
				a.track_set_key_value(t, k, q)
	## El torso: spine_01' = rest_pelvis⁻¹ · pelvis_clip · spine_01 (misma orientación en el
	## mundo con la pelvis ya recta). Las claves de los dos huesos van a la par en el clip;
	## si no, se toma la pelvis en el tiempo de cada clave del tronco.
	if t_pelvis >= 0 and t_spine < 0 and esq.find_bone("spine_01") >= 0:
		## El clip no mueve el tronco: se le da una pista con su reposo en cada clave de la pelvis.
		var i_sp := esq.find_bone("spine_01")
		t_spine = a.add_track(Animation.TYPE_ROTATION_3D)
		a.track_set_path(t_spine, str(a.track_get_path(t_pelvis)).get_slice(":", 0) + ":spine_01")
		for k in a.track_get_key_count(t_pelvis):
			a.rotation_track_insert_key(t_spine, a.track_get_key_time(t_pelvis, k), esq.get_bone_rest(i_sp).basis.get_rotation_quaternion())
	if t_pelvis >= 0 and t_spine >= 0:
		for k in a.track_get_key_count(t_spine):
			var tiempo := a.track_get_key_time(t_spine, k)
			var qp: Quaternion = a.rotation_track_interpolate(t_pelvis, tiempo)
			var qs: Quaternion = a.track_get_key_value(t_spine, k)
			a.track_set_key_value(t_spine, k, (q_rest.inverse() * qp * qs).normalized())
	if t_pelvis >= 0:
		for k in a.track_get_key_count(t_pelvis):
			a.track_set_key_value(t_pelvis, k, q_rest)

## Respiración, balanceo y (si `mirar`) la mirada a la cámara. Corre después del
## AnimationPlayer (como el guardián de escalas) y SUMA un giro pequeño a lo que dejó el
## clip. Si el clip no tiene pista para un hueso, lo que hay es lo que puso este nodo el
## fotograma anterior: se parte de la base guardada para no acumular.
class _Vida extends Node:
	var esq: Skeleton3D
	var ap: AnimationPlayer
	var mirar := false
	var t := 0.0
	var fase := 0.0
	var _peso_mirada := 0.0
	var _mirada := Vector2.ZERO
	var _base := {}
	var _escrito := {}

	func _girar(hueso: String, giro_esq: Quaternion) -> void:
		var i := esq.find_bone(hueso)
		if i < 0:
			return
		var actual := esq.get_bone_pose_rotation(i)
		if _escrito.has(i) and actual.is_equal_approx(_escrito[i]):
			actual = _base[i]
		_base[i] = actual
		## El giro llega en el espacio del esqueleto: L' = P⁻¹ · D · P · L.
		var padre := esq.get_bone_parent(i)
		var p := esq.get_bone_global_pose(padre).basis.get_rotation_quaternion() if padre >= 0 else Quaternion.IDENTITY
		var nueva := (p.inverse() * giro_esq * p * actual).normalized()
		esq.set_bone_pose_rotation(i, nueva)
		_escrito[i] = nueva

	func _process(delta: float) -> void:
		if esq == null or ap == null:
			return
		t += minf(delta, 0.1)
		var quieto := ap.current_animation.ends_with("parado")
		## Respirar: el pecho sube y baja (~4 s por respiración), siempre.
		var resp := sin(t * TAU / 4.2 + fase)
		_girar("spine_02", Quaternion(Vector3.RIGHT, 0.010 * resp))
		_girar("spine_03", Quaternion(Vector3.RIGHT, 0.008 * resp))
		## El peso pasa despacio de un pie al otro (solo de pie y quieto).
		if quieto:
			var bal := sin(t * TAU / 9.0 + fase * 1.7)
			_girar("spine_01", Quaternion(Vector3.FORWARD, 0.012 * bal))
		## La mirada: la cabeza busca la cámara, poco y suave; nunca se tuerce hacia atrás.
		var objetivo := Vector2.ZERO
		var cam := get_viewport().get_camera_3d() if mirar else null
		if cam != null and quieto:
			var h := esq.find_bone("Head")
			var desde := esq.global_transform * esq.get_bone_global_pose(h).origin
			var dl := (esq.global_basis.orthonormalized().inverse() * (cam.global_position - desde)).normalized()
			var yaw := atan2(dl.x, dl.z)
			if absf(yaw) < 1.3:
				objetivo = Vector2(clampf(yaw, -0.32, 0.32), clampf(asin(clampf(dl.y, -1.0, 1.0)), -0.14, 0.14))
		_mirada = _mirada.lerp(objetivo, minf(1.0, delta * 2.5))
		_peso_mirada = move_toward(_peso_mirada, 1.0 if quieto else 0.0, delta * 1.5)
		var m := _mirada * _peso_mirada
		if m.length() > 0.0005:
			for par: Array in [["neck_01", 0.4], ["Head", 0.6]]:
				var w: float = par[1]
				_girar(String(par[0]), Quaternion(Vector3.UP, m.x * w) * Quaternion(Vector3.LEFT, m.y * w))

## Pone la vida a un personaje de `PersonajeDT.crear`.
static func animar(d: Dictionary, mirar := false) -> void:
	if not d.has("esqueleto") or not d.has("anim"):
		return
	var v := _Vida.new()
	v.name = "Vida"
	v.esq = d["esqueleto"]
	v.ap = d["anim"]
	v.mirar = mirar
	v.fase = float(absi(hash(str(d["nodo"]))) % 628) / 100.0
	v.process_priority = 101
	(d["nodo"] as Node).add_child(v)

## Enciende o apaga la mirada a la cámara (el estudio la quiere; la banda, no).
static func mirar_camara(d: Dictionary, si: bool) -> void:
	var n: Node = d.get("nodo")
	if n != null and n.get_node_or_null("Vida") != null:
		n.get_node("Vida").set("mirar", si)

# -----------------------------------------------------------------------------
#  LA EDAD
# -----------------------------------------------------------------------------

## 0 (sin marcas, hasta ~32 años) .. 1 (unos 65).
static func arrugas_de(edad: int) -> float:
	return clampf((edad - 32) / 33.0, 0.0, 1.0)

static func canas_de(edad: int) -> float:
	return clampf((edad - 40) / 40.0, 0.0, 0.6)

static func entradas_de(edad: int) -> float:
	return clampf((edad - 36) / 28.0, 0.0, 0.85)

## Mapas de posiciones (UV de la piel -> punto del modelo en reposo), uno por cuerpo.
static var _mapas := {}

## Arrugas, canas y entradas según `a["edad"]` (0 o sin edad: nada).
static func envejecer(d: Dictionary, a: Dictionary) -> void:
	var edad := int(a.get("edad", 0))
	if edad <= 0 or not d.has("nodo"):
		return
	var mujer := String(a.get("cuerpo", "male")) == "female"
	var ojos_y := 1.656 if mujer else 1.699
	var nodo: Node = d["nodo"]
	## Canas y entradas en las mallas de pelo, barba y cejas (cuelgan de «Pelo»).
	var esq: Skeleton3D = d.get("esqueleto")
	var anc := esq.get_node_or_null("Pelo") if esq != null else null
	var cabeza := esq.find_bone("Head") if esq != null else -1
	if anc != null and cabeza >= 0 and canas_de(edad) + entradas_de(edad) > 0.0:
		for mi: MeshInstance3D in anc.find_children("*", "MeshInstance3D", false, false):
			var base := mi.material_override as StandardMaterial3D
			if base == null:
				continue
			var cejas := mi.name.begins_with("Eyebrows")
			var sm := ShaderMaterial.new()
			sm.shader = load(SHADER_CANAS)
			sm.set_shader_parameter("textura", base.albedo_texture)
			sm.set_shader_parameter("color", base.albedo_color)
			sm.set_shader_parameter("a_modelo", esq.get_bone_global_rest(cabeza) * mi.transform)
			sm.set_shader_parameter("ojos_y", ojos_y)
			var k := 0.45 if cejas else (1.15 if mi.name == "Hair_Beard" else 1.0)
			sm.set_shader_parameter("canas", canas_de(edad) * k)
			## Entradas solo en el pelo de un hombre (ni barba ni cejas).
			var ent := 0.0 if mujer or cejas or mi.name == "Hair_Beard" else entradas_de(edad)
			sm.set_shader_parameter("entradas", ent)
			mi.material_override = sm
	## Arrugas: solo la cara clásica (con una cara de la biblioteca, la piel es otra).
	if int(a.get("cara", -1)) >= 0 and not mujer:
		return
	if arrugas_de(edad) <= 0.0:
		return
	for mi: MeshInstance3D in nodo.find_children("*", "MeshInstance3D", true, false):
		if not (mi.name.begins_with("SuperHero_") or mi.name.begins_with("Superhero_")) or mi.mesh == null:
			continue
		var mapa := _mapa(mi.mesh, "f" if mujer else "m")
		if mapa == null:
			continue
		var so := ShaderMaterial.new()
		so.shader = load(SHADER_ARRUGAS)
		so.set_shader_parameter("posiciones", mapa)
		so.set_shader_parameter("edad", arrugas_de(edad))
		so.set_shader_parameter("ojos_y", ojos_y)
		so.set_shader_parameter("ojos_x", 0.0345 if mujer else 0.033)
		mi.material_overlay = so

const LADO_MAPA := 256

## Rasteriza en el espacio UV de la piel los triángulos de la cabeza, guardando en cada
## texel el punto del modelo en reposo (RGB) y 1 en alfa. Una sola vez por cuerpo.
static func _mapa(malla: Mesh, clave: String) -> ImageTexture:
	if _mapas.has(clave):
		return _mapas[clave]
	var img := Image.create_empty(LADO_MAPA, LADO_MAPA, false, Image.FORMAT_RGBAF)
	var hay := false
	for s in malla.get_surface_count():
		var arr := malla.surface_get_arrays(s)
		var v: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
		var uv: PackedVector2Array = arr[Mesh.ARRAY_TEX_UV]
		var idx: PackedInt32Array = arr[Mesh.ARRAY_INDEX]
		if uv.size() != v.size() or idx.is_empty():
			continue
		for t in range(0, idx.size(), 3):
			var a := idx[t]
			var b := idx[t + 1]
			var c := idx[t + 2]
			if minf(v[a].y, minf(v[b].y, v[c].y)) < 1.5:
				continue
			_triangulo(img, uv[a], uv[b], uv[c], v[a], v[b], v[c])
			hay = true
	if not hay:
		_mapas[clave] = null
		return null
	_dilatar(img)
	var tex := ImageTexture.create_from_image(img)
	_mapas[clave] = tex
	return tex

static func _triangulo(img: Image, ua: Vector2, ub: Vector2, uc: Vector2, pa: Vector3, pb: Vector3, pc: Vector3) -> void:
	var n := float(LADO_MAPA)
	var a := ua * n
	var b := ub * n
	var c := uc * n
	var area := (b - a).cross(c - a)
	if absf(area) < 1e-6:
		return
	var x0 := clampi(int(floor(minf(a.x, minf(b.x, c.x)))), 0, LADO_MAPA - 1)
	var x1 := clampi(int(ceil(maxf(a.x, maxf(b.x, c.x)))), 0, LADO_MAPA - 1)
	var y0 := clampi(int(floor(minf(a.y, minf(b.y, c.y)))), 0, LADO_MAPA - 1)
	var y1 := clampi(int(ceil(maxf(a.y, maxf(b.y, c.y)))), 0, LADO_MAPA - 1)
	for y in range(y0, y1 + 1):
		for x in range(x0, x1 + 1):
			var p := Vector2(x + 0.5, y + 0.5)
			var w0 := (b - p).cross(c - p) / area
			var w1 := (c - p).cross(a - p) / area
			var w2 := 1.0 - w0 - w1
			## Un pelo de margen: los bordes de las islas quedan cubiertos.
			if w0 < -0.02 or w1 < -0.02 or w2 < -0.02:
				continue
			var q := pa * w0 + pb * w1 + pc * w2
			img.set_pixel(x, y, Color(q.x, q.y, q.z, 1.0))

## Dos pasadas de vecinos: el filtrado bilineal no mezcla el borde con «nada» (0,0,0).
static func _dilatar(img: Image) -> void:
	for _pasada in 2:
		var copia := img.duplicate() as Image
		for y in LADO_MAPA:
			for x in LADO_MAPA:
				if copia.get_pixel(x, y).a > 0.5:
					continue
				for o: Vector2i in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
					var q := Vector2i(x, y) + o
					if q.x < 0 or q.y < 0 or q.x >= LADO_MAPA or q.y >= LADO_MAPA:
						continue
					var c := copia.get_pixel(q.x, q.y)
					if c.a > 0.5:
						img.set_pixel(x, y, Color(c.r, c.g, c.b, 0.6))
						break
