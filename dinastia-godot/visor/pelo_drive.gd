class_name PeloDrive
extends RefCounted
## PEINADOS DEL DRIVE DEL DUEÑO (27-10-2026, «nv toufa», 105 peinados en un OBJ de 122 MB): se eligieron 12, se decimaron a ~4500 triángulos
## (`herramientas/pelo_drive_extraer.py` y `pelo_drive_a_res.gd`; ~20 KB cada uno, `.res` fuera de LFS) y aquí se ajustan a la cabeza de
## Quaternius. Cada malla viene normalizada: ancho 1,0, y = 0 en lo más alto, centrada en x y z. El ajuste (escala por el ancho, altura de la
## coronilla y fondo) sale de medir la cabeza del cuerpo (`HEAD` ±9 cm de ancho, coronilla a +21 cm del hueso en el masculino).
## Licencia: confirmada por el dueño (regalos de Drive). Regla: un peinado entra solo si de cerca se ve MEJOR que el de Quaternius.
const CARPETA := "res://assets/ciudad_personajes_pelo_drive/"
const RUTA := "res://assets/characters/pelo_drive/pelo_%03d.res"
## Hombres y mujeres: los 11 que quedaron bien sobre la cabeza tras probar 30 de los 105 (el modelo del pack mira a -z: se gira 180°).
const HOMBRES := [80, 68, 59]   ## (rizado, flequillo despeinado y rizado corto: de cerca se ven mejor que el corte de Quaternius al que sustituyen)
## Revisión 27-10 (hoja antes/después, 1,5 m, frente/3/4/perfil): los otros 9 se descartaron (parecen casco, tapan los ojos o dejan huecos).
const MUJERES := []
## [ancho que ocupa el peinado, altura de su parte alta sobre el hueso Head, desplazamiento en z] según el cuerpo (en m).
const AJUSTE_M := [0.215, 0.255, 0.008]
const AJUSTE_F := [0.200, 0.235, 0.004]
## Peatones con un peinado del Drive en vez de uno del pack (%): el resto sigue con los cortes de Quaternius.
const PROB := 45

## El peinado del Drive de una persona (determinista por su semilla), o -1 si lleva uno del pack.
static func elegir(semilla: int, mujer: bool) -> int:
	if absi(hash([semilla, 41])) % 100 >= PROB or OS.get_environment("SIN_PELO_DRIVE") != "":   ## (SIN_PELO_DRIVE=1: para medir antes/después)
		return -1
	var lista: Array = MUJERES if mujer else HOMBRES
	if lista.is_empty():
		return -1
	return int(lista[absi(hash([semilla, 43])) % lista.size()])

static var _mallas: Dictionary = {}
static var _mats: Dictionary = {}

static func malla(id: int) -> Mesh:
	if _mallas.has(id):
		return _mallas[id]
	var m: Mesh = null
	if ResourceLoader.exists(RUTA % id):
		m = load(RUTA % id) as Mesh
	_mallas[id] = m
	return m

static func material(color: Color) -> StandardMaterial3D:
	var k := color.to_html(false)
	if not _mats.has(k):
		var m := StandardMaterial3D.new()
		m.albedo_color = color
		m.roughness = 0.7
		m.metallic = 0.0
		m.cull_mode = BaseMaterial3D.CULL_DISABLED
		m.rim_enabled = true
		m.rim = 0.25
		m.rim_tint = 0.5
		_mats[k] = m
	return _mats[k]

## Cuelga el peinado `id` del `anc` (el BoneAttachment3D «Pelo» de `PeloQ`) de un cuerpo con esqueleto `esq`. `gira` = 180° si el modelo del pack
## mira al otro lado. Devuelve el MeshInstance3D o null si no hay malla.
static func poner(esq: Skeleton3D, anc: Node3D, id: int, color: Color, mujer: bool, gira := true) -> MeshInstance3D:
	var m := malla(id)
	if m == null:
		return null
	var h := esq.find_bone("Head")
	var reposo := esq.get_bone_global_rest(h)
	var aj: Array = AJUSTE_F if mujer else AJUSTE_M
	var s: float = aj[0]
	var base := Basis().scaled(Vector3.ONE * s)
	if gira:
		base = Basis(Vector3.UP, PI) * base
	var en_modelo := Transform3D(base, Vector3(0.0, reposo.origin.y + float(aj[1]), reposo.origin.z + float(aj[2])))
	var mi := MeshInstance3D.new()
	mi.name = "PeloDrive%d" % id
	mi.mesh = m
	mi.material_override = material(color)
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mi.transform = reposo.affine_inverse() * en_modelo
	anc.add_child(mi)
	return mi
