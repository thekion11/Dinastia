class_name CaraMalla
extends RefCounted
## LA CARA DE VERDAD EN 3D (30-9-2026, pedido: «los que tenemos sus caras deben
## ser igualitos»). Cada jugador real con foto tiene su PROPIA malla de cara:
## 468 vértices con la forma de su nariz, pómulos, frente y mentón, sacada de
## su foto por `herramientas/caras_reales_malla.py` (MediaPipe, Apache 2.0), y
## pintada con los píxeles exactos de la foto (cada vértice sabe dónde cae en
## ella). Va colgada del hueso de la cabeza, delante de la cara del cuerpo, que
## se hunde un poco para no asomar (`equipacion_q.gdshader`, `hay_malla`).

const TOPOLOGIA := "res://datos/cara_malla_topologia.json"
const MALLAS := "res://datos/caras_reales_mallas.json"
const SHADER := "res://visor/cara_malla.gdshader"
## Vértices de MediaPipe; la malla trae además un anillo alrededor (`_n`).
const N := 468
## Ojos del modelo (centro de los globos, pose de reposo).
const OJO_X := 0.0338
const OJO_Y := 1.6986
## Dónde queda el plano de los rabillos de los ojos (z, m): justo delante
## de los párpados del cuerpo.
const OJOS_Z := 0.079
## Rabillos de cada ojo en la malla canónica de MediaPipe.
const OJO_IZQ := [33, 133]
const OJO_DER := [362, 263]

static var _n := N
static var _tri := PackedInt32Array()
static var _alfa := PackedFloat32Array()
static var _mallas: Dictionary = {}
static var _listo := false
static var _cache := {}

static func _cargar() -> void:
	if _listo:
		return
	_listo = true
	if not FileAccess.file_exists(TOPOLOGIA):
		return
	var jt := JSON.new()
	if jt.parse(FileAccess.get_file_as_string(TOPOLOGIA)) != OK or not (jt.data is Dictionary):
		return
	_n = int(jt.data.get("n", N))
	for i: Variant in jt.data["tri"]:
		_tri.append(int(i))
	for a: Variant in jt.data["alfa"]:
		_alfa.append(float(a))
	var jm := JSON.new()
	if FileAccess.file_exists(MALLAS) and jm.parse(FileAccess.get_file_as_string(MALLAS)) == OK and jm.data is Dictionary:
		_mallas = jm.data
	## Y las caras de la biblioteca modular (mezclas: `BibliotecaCaras`).
	BibliotecaCaras._cargar()
	for k: String in BibliotecaCaras._caras:
		_mallas[k] = BibliotecaCaras._caras[k]

static func tiene(nombre: String) -> bool:
	_cargar()
	## (Las fotos "malas" también: la auditoría mostró que la recreación
	## dibujada queda peor que su malla, aunque la foto sea de mucho costado.)
	return _mallas.has(nombre)

## [posiciones (espacio del modelo, pose de reposo), uvs] o [] si no hay.
static func _datos(nombre: String) -> Array:
	if _cache.has(nombre):
		return _cache[nombre]
	_cargar()
	var e: Variant = _mallas.get(nombre)
	if not (e is Dictionary):
		return []
	var bytes := Marshalls.base64_to_raw(String((e as Dictionary).get("m", "")))
	if bytes.size() != _n * 5 * 2:
		return []
	var canon := PackedVector3Array()
	var uv := PackedVector2Array()
	canon.resize(_n)
	uv.resize(_n)
	for i in _n:
		var o := i * 10
		canon[i] = Vector3(bytes.decode_s16(o), bytes.decode_s16(o + 2), bytes.decode_s16(o + 4)) / 100.0
		uv[i] = Vector2(bytes.decode_s16(o + 6), bytes.decode_s16(o + 8)) / 32767.0
	## De centímetros de la malla canónica al modelo: los ojos de su cara
	## sobre los globos del modelo (escala por la distancia entre ojos).
	var oi := (canon[OJO_IZQ[0]] + canon[OJO_IZQ[1]]) * 0.5
	var od := (canon[OJO_DER[0]] + canon[OJO_DER[1]]) * 0.5
	var sep := absf(od.x - oi.x)
	if sep < 0.1:
		return []
	var k := OJO_X * 2.0 / sep
	var medio := (oi + od) * 0.5
	var pos := PackedVector3Array()
	pos.resize(_n)
	for i in _n:
		var c := canon[i] - medio
		pos[i] = Vector3(c.x * k, OJO_Y + c.y * k, OJOS_Z + c.z * k)
		## El anillo de fundido (los últimos 36, alfa 0) quedaba en el aire a
		## la altura de las sienes: una mancha borrosa al lado de la cabeza
		## (5-10). Se mete hacia el cráneo: más estrecho y un poco hundido.
		if i >= 468:
			pos[i].x *= 0.86
			pos[i].z -= 0.006
	## [3] = metros del modelo por cm de la malla canónica.
	## La textura que pinta el juego: la piel REPLICADA ("a", motor_caras) si
	## está; si no, la foto recortada.
	var tex := String((e as Dictionary).get("a", (e as Dictionary).get("f", "")))
	var d := [pos, uv, "res://" + tex, k]
	_cache[nombre] = d
	return d

## El balance de blancos de su foto (por canal, lineal).
static func balance(nombre: String) -> Vector3:
	var wb: Variant = entrada(nombre).get("wb")
	if wb is Array and (wb as Array).size() == 3:
		return Vector3(float(wb[0]), float(wb[1]), float(wb[2]))
	return Vector3.ONE

## Todo lo medido en su foto (pelo "h", barba "b", cejas "e", piel "s").
static func entrada(nombre: String) -> Dictionary:
	_cargar()
	var e: Variant = _mallas.get(nombre)
	return e if e is Dictionary else {}

## Posiciones (espacio del modelo), uvs, triángulos y escala, para `PeloCapas`.
static func geometria(nombre: String) -> Array:
	var d := _datos(nombre)
	return [] if d.is_empty() else [d[0], d[1], _tri, d[3]]

## El color de su pelo sacado de la foto (o alfa 0 si no se vio pelo).
static func color_pelo(nombre: String) -> Color:
	_cargar()
	var e: Variant = _mallas.get(nombre)
	if e is Dictionary and (e as Dictionary).get("h") is Dictionary:
		return Color(String(e["h"].get("c", "#2a211b")))
	if e is Dictionary and String((e as Dictionary).get("p", "")) != "":
		return Color(String(e["p"]))
	return Color(0, 0, 0, 0)

## El recorte de su cara (384 px) con mipmaps, cacheado. Se lee a mano, como
## `Cara.foto_de_ruta` (no hace falta reimportar el proyecto por foto nueva).
static var _texturas := {}

static func foto(nombre: String) -> Texture2D:
	if _texturas.has(nombre):
		return _texturas[nombre]
	var d := _datos(nombre)
	if d.is_empty() or not FileAccess.file_exists(String(d[2])):
		return null
	var img := Image.new()
	if img.load_jpg_from_buffer(FileAccess.get_file_as_bytes(String(d[2]))) != OK:
		return null
	img.generate_mipmaps()
	var t := ImageTexture.create_from_image(img)
	_texturas[nombre] = t
	return t

## El tono de su piel en la foto: la media RECORTADA de los 468 puntos de la
## cara (se ordenan por claridad y se promedia el 60 % del medio: fuera
## brillos, ojos, cejas y barba). Una media de pocos puntos caía en brillos
## (cuello más claro y naranja); la mediana por canal perdía el azul (cuello
## más rojo). Comprobado en Python contra la media de lo que pinta la cara.
static func tono_piel(nombre: String, tex: Texture2D) -> Color:
	var d := _datos(nombre)
	if d.is_empty() or tex == null:
		return Color(0, 0, 0, 0)
	var img := tex.get_image()
	if img == null:
		return Color(0, 0, 0, 0)
	if img.is_compressed():
		img.decompress()
	var muestras: Array = []
	var uvs: PackedVector2Array = d[1]
	for i in N:
		var px := clampi(int(uvs[i].x * img.get_width()), 0, img.get_width() - 1)
		var py := clampi(int(uvs[i].y * img.get_height()), 0, img.get_height() - 1)
		var c := img.get_pixel(px, py).srgb_to_linear()
		muestras.append([0.2126 * c.r + 0.7152 * c.g + 0.0722 * c.b, c])
	muestras.sort_custom(func(a: Array, b: Array) -> bool: return float(a[0]) < float(b[0]))
	var suma := Color(0, 0, 0, 0)
	var desde := int(N * 0.2)
	var hasta := int(N * 0.8)
	for k in range(desde, hasta):
		suma += muestras[k][1]
	var n := float(hasta - desde)
	return Color(suma.r / n, suma.g / n, suma.b / n, 1.0).linear_to_srgb()

const CONTORNO_OJOS := [33, 7, 163, 144, 145, 153, 154, 155, 133, 173, 157, 158, 159, 160, 161, 246,
	263, 249, 390, 373, 374, 380, 381, 382, 362, 398, 384, 385, 386, 387, 388, 466]

static func _en_ojo(i: int) -> bool:
	return i in CONTORNO_OJOS

## El centro de la abertura de cada ojo en SU malla (espacio del modelo, x,y):
## [ojo de x negativa, ojo de x positiva]. El iris 3D se centra ahí; con el
## centro fijo del modelo, un iris quedaba corrido en la abertura y el
## jugador parecía bizco.
static func centros_ojos(nombre: String) -> Array:
	var d := _datos(nombre)
	if d.is_empty():
		return []
	var pos: PackedVector3Array = d[0]
	var out := [Vector2.ZERO, Vector2.ZERO]
	for grupo: Array in [CONTORNO_OJOS.slice(0, 16), CONTORNO_OJOS.slice(16, 32)]:
		var c := Vector2.ZERO
		for i: int in grupo:
			c += Vector2(pos[i].x, pos[i].y)
		c /= float(grupo.size())
		out[0 if c.x < 0.0 else 1] = c
	return out

## El color de su iris medido en la foto (alfa 0 si no hay).
static func color_iris(nombre: String) -> Color:
	var c := String(entrada(nombre).get("iris", ""))
	return Color(c) if c != "" else Color(0, 0, 0, 0)

## Cuelga la cara del hueso de la cabeza del jugador. null si no hay malla.
static func poner(d: Dictionary, nombre: String, tex: Texture2D, piel: Color) -> MeshInstance3D:
	var datos := _datos(nombre)
	var esq: Skeleton3D = d.get("esqueleto")
	if datos.is_empty() or tex == null or esq == null or _tri.size() < 3 or not ResourceLoader.exists(SHADER):
		return null
	var hueso := esq.find_bone("Head")
	if hueso < 0:
		return null
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var pos: PackedVector3Array = datos[0]
	var uv: PackedVector2Array = datos[1]
	## COLOR.g = tapado en la foto (una mano, un brazo): ahí se pinta su piel.
	var tapado := PeloCapas._densidades(String(entrada(nombre).get("t", "")), _n)
	for i in _n:
		st.set_uv(uv[i])
		st.set_color(Color(1, tapado[i], 1, _alfa[i] if i < _alfa.size() else 1.0))
		st.add_vertex(pos[i])
	## Godot toma como cara de delante la de vértices en sentido horario vista
	## desde fuera; la malla de MediaPipe viene al revés.
	## Los ojos de la foto NO se pintan: se abre el ojo en la malla y se ven los
	## globos 3D detrás, mirando al frente con el color de su iris. (En fotos
	## de tres cuartos el espejo copiaba el mismo ojo a los dos lados y parecía
	## bizco.) Se quitan los triángulos que tienen los tres puntos en el
	## contorno de un ojo.
	for t in range(0, _tri.size() - 2, 3):
		if _en_ojo(_tri[t]) and _en_ojo(_tri[t + 1]) and _en_ojo(_tri[t + 2]):
			continue
		st.add_index(_tri[t])
		st.add_index(_tri[t + 2])
		st.add_index(_tri[t + 1])
	st.generate_normals()
	var malla := st.commit()
	var mat := ShaderMaterial.new()
	mat.shader = load(SHADER)
	mat.set_shader_parameter("foto", tex)
	## Luminancia media de su piel (lineal): la referencia para quitarle a la
	## foto la luz con que se sacó.
	var pl := piel.srgb_to_linear()
	mat.set_shader_parameter("piel_lin", Vector3(pl.r, pl.g, pl.b))
	if String(entrada(nombre).get("a", "")) != "":
		## Piel replicada: la luz y el balance ya vienen quitados del motor.
		mat.set_shader_parameter("quitar_luz", 0.0)
		mat.set_shader_parameter("balance", Vector3.ONE)
	else:
		mat.set_shader_parameter("balance", balance(nombre))
	mat.set_shader_parameter("lum_media", 0.2126 * pl.r + 0.7152 * pl.g + 0.0722 * pl.b)
	var mi := MeshInstance3D.new()
	mi.name = "CaraReal"
	mi.mesh = malla
	mi.material_override = mat
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var anc := BoneAttachment3D.new()
	anc.name = "CaraRealHueso"
	anc.bone_name = "Head"
	esq.add_child(anc)
	mi.transform = esq.get_bone_global_rest(hueso).affine_inverse()
	anc.add_child(mi)
	return mi
