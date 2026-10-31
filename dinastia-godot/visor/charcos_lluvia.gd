class_name CharcosLluvia
extends Node3D
## CHARCOS DE LLUVIA EN LA CIUDAD (M-190, 28-10-2026): mientras llueve, alrededor de la cámara aparecen charcos oscuros y lisos (reflejan
## farolas y fachadas) con ondas de gotas. Son un solo MultiMesh de `CELDAS`² discos sobre una rejilla del mundo (un charco por celda según
## su hash, así no bailan al moverse); se recoloca solo cuando la cámara cambia de celda. Nacen y mueren con `PrecipitacionCiudad`.
const LADO := 7.0
const CELDAS := 14
const PROBABILIDAD := 85   ## % de celdas con charco
const ALTURA := 0.22

var _mm: MultiMesh
var _celda := Vector2i(1 << 20, 1 << 20)
var _n := 0
var altura: Callable:   ## (x, z) -> altura del terreno; sin ella los charcos van a ras de y = 0
	set(v):
		altura = v
		_celda = Vector2i(1 << 20, 1 << 20)

static func montar(padre: Node) -> CharcosLluvia:
	var c := CharcosLluvia.new()
	c.name = "CharcosLluvia"
	padre.add_child(c)
	return c

func _ready() -> void:
	var q := QuadMesh.new()
	q.size = Vector2.ONE
	q.orientation = PlaneMesh.FACE_Y
	var mat := ShaderMaterial.new()
	mat.shader = load("res://visor/charcos_lluvia.gdshader")
	_mm = MultiMesh.new()
	_mm.transform_format = MultiMesh.TRANSFORM_3D
	_mm.use_custom_data = false
	_mm.mesh = q
	_mm.instance_count = CELDAS * CELDAS
	var mi := MultiMeshInstance3D.new()
	mi.multimesh = _mm
	mi.material_override = mat
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mi.extra_cull_margin = LADO * CELDAS
	add_child(mi)
	top_level = true
	reponer(Vector3.ZERO)

func _process(_d: float) -> void:
	var cam := get_viewport().get_camera_3d()
	if cam != null:
		reponer(cam.global_position)

## Hash estable de una celda de la rejilla del mundo.
static func hash_celda(c: Vector2i) -> int:
	return absi(hash([c.x, c.y, 90]))

## Cuántos charcos hay con la cámara en `pos` (para las pruebas).
func reponer(pos: Vector3) -> int:
	var centro := Vector2i(floori(pos.x / LADO), floori(pos.z / LADO))
	if centro == _celda:
		return visibles()
	_celda = centro
	var k := 0
	_n = 0
	var mitad := CELDAS / 2
	for dz in range(-mitad, mitad):
		for dx in range(-mitad, mitad):
			var c := centro + Vector2i(dx, dz)
			var h := hash_celda(c)
			var t := Transform3D.IDENTITY
			if h % 100 < PROBABILIDAD:
				_n += 1
				var ancho := 2.4 + float(h / 100 % 40) / 8.0
				var largo := ancho * (0.6 + float(h / 4000 % 40) / 100.0)
				var giro := float(h / 160000 % 628) / 100.0
				var o := Vector2(float(h / 7 % 100) / 100.0, float(h / 700 % 100) / 100.0) * (LADO - 2.0) + Vector2.ONE
				var px: float = c.x * LADO + o.x
				var pz: float = c.y * LADO + o.y
				t = Transform3D(Basis(Vector3.UP, giro).scaled(Vector3(ancho, 1.0, largo)), Vector3(px, _suelo(px, pz) + ALTURA, pz))
			else:
				t = Transform3D(Basis.from_scale(Vector3.ZERO), Vector3(0, -50, 0))
			_mm.set_instance_transform(k, t)
			k += 1
	return visibles()

func _suelo(x: float, z: float) -> float:
	return float(altura.call(x, z)) if altura.is_valid() else 0.0

func visibles() -> int:
	return _n
