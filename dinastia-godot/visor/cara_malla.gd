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
## Mejillas y frente: de ahí sale el tono exacto de la piel del jugador.
const PUNTOS_PIEL := [50, 280, 101, 330, 108, 337, 151]

static var _tri := PackedInt32Array()
static var _alfa := PackedFloat32Array()
static var _mallas: Dictionary = {}
static var _listo := false
static var _cache := {}

static func _cargar() -> void:
	if _listo:
		return
	_listo = true
	if not FileAccess.file_exists(TOPOLOGIA) or not FileAccess.file_exists(MALLAS):
		return
	var jt := JSON.new()
	if jt.parse(FileAccess.get_file_as_string(TOPOLOGIA)) != OK or not (jt.data is Dictionary):
		return
	for i: Variant in jt.data["tri"]:
		_tri.append(int(i))
	for a: Variant in jt.data["alfa"]:
		_alfa.append(float(a))
	var jm := JSON.new()
	if jm.parse(FileAccess.get_file_as_string(MALLAS)) == OK and jm.data is Dictionary:
		_mallas = jm.data

static func tiene(nombre: String) -> bool:
	_cargar()
	return _mallas.has(nombre)

## [posiciones (espacio del modelo, pose de reposo), uvs] o [] si no hay.
static func _datos(nombre: String) -> Array:
	if _cache.has(nombre):
		return _cache[nombre]
	_cargar()
	var b64 := String(_mallas.get(nombre, ""))
	if b64 == "":
		return []
	var bytes := Marshalls.base64_to_raw(b64)
	if bytes.size() != N * 5 * 2:
		return []
	var canon := PackedVector3Array()
	var uv := PackedVector2Array()
	canon.resize(N)
	uv.resize(N)
	for i in N:
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
	pos.resize(N)
	for i in N:
		var c := canon[i] - medio
		pos[i] = Vector3(c.x * k, OJO_Y + c.y * k, OJOS_Z + c.z * k)
	var d := [pos, uv]
	_cache[nombre] = d
	return d

## El tono medio de la piel en la foto (mejillas y frente), exacto.
static func tono_piel(nombre: String, foto: Texture2D) -> Color:
	var d := _datos(nombre)
	if d.is_empty() or foto == null:
		return Color(0, 0, 0, 0)
	var img := foto.get_image()
	if img == null:
		return Color(0, 0, 0, 0)
	if img.is_compressed():
		img.decompress()
	var suma := Color(0, 0, 0, 0)
	var n := 0
	for i: int in PUNTOS_PIEL:
		var uv: Vector2 = (d[1] as PackedVector2Array)[i]
		for dy in range(-1, 2):
			for dx in range(-1, 2):
				var px := clampi(int(uv.x * img.get_width()) + dx, 0, img.get_width() - 1)
				var py := clampi(int(uv.y * img.get_height()) + dy, 0, img.get_height() - 1)
				suma += img.get_pixel(px, py)
				n += 1
	return Color(suma.r / n, suma.g / n, suma.b / n, 1.0)

## Cuelga la cara del hueso de la cabeza del jugador. null si no hay malla.
static func poner(d: Dictionary, nombre: String, foto: Texture2D) -> MeshInstance3D:
	var datos := _datos(nombre)
	var esq: Skeleton3D = d.get("esqueleto")
	if datos.is_empty() or foto == null or esq == null or _tri.size() < 3 or not ResourceLoader.exists(SHADER):
		return null
	var hueso := esq.find_bone("Head")
	if hueso < 0:
		return null
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var pos: PackedVector3Array = datos[0]
	var uv: PackedVector2Array = datos[1]
	for i in N:
		st.set_uv(uv[i])
		st.set_color(Color(1, 1, 1, _alfa[i] if i < _alfa.size() else 1.0))
		st.add_vertex(pos[i])
	## Godot toma como cara de delante la de vértices en sentido horario vista
	## desde fuera; la malla de MediaPipe viene al revés.
	for t in range(0, _tri.size() - 2, 3):
		st.add_index(_tri[t])
		st.add_index(_tri[t + 2])
		st.add_index(_tri[t + 1])
	st.generate_normals()
	var malla := st.commit()
	var mat := ShaderMaterial.new()
	mat.shader = load(SHADER)
	mat.set_shader_parameter("foto", foto)
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
