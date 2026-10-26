class_name BanderasGrada
extends Node3D
## BANDERAS GRANDES EN EL GOL (26-10-2026): con la cámara de TV (a ~80 m) el
## festejo de cada hincha ocupa pocos píxeles; unas pocas banderas de 7×4,5 m con
## los colores del club que suben y ondean sobre la grada de casa sí se leen.
## Geometría mínima: un plano de 24×10 cuadros por bandera (~500 triángulos), un
## shader de vértice (`bandera_grada.gdshader`), sin texturas ni sombras. Se
## colocan sobre el público real (`FestejoGrada._sitios_de_grada`) y se borran
## solas. Apagado con el motor ligero.
##   BanderasGrada.lanzar(raiz, c1, c2, sitios, dura)

const ANCHO := 7.0
const ALTO := 4.5
var _t := 0.0
var _dura := 8.0
var _mats: Array[ShaderMaterial] = []

static func lanzar(raiz: Node3D, c1: Color, c2: Color, sitios: Array, dura := 8.0, cuantas := 3) -> BanderasGrada:
	if raiz == null or sitios.is_empty() or Calidad.motor_ligero:
		return null
	var b := BanderasGrada.new()
	b.name = "BanderasGrada"
	b._dura = dura
	raiz.add_child(b)
	var malla := PlaneMesh.new()
	malla.orientation = PlaneMesh.FACE_Z
	malla.size = Vector2(ANCHO, ALTO)
	malla.subdivide_width = 24
	malla.subdivide_depth = 10
	var sh: Shader = load("res://visor/bandera_grada.gdshader")
	for i in mini(cuantas, sitios.size()):
		var s: Vector3 = sitios[i]
		var m := ShaderMaterial.new()
		m.shader = sh
		## Una con el primer color dominante, la siguiente al revés.
		m.set_shader_parameter("color1", c1 if i % 2 == 0 else c2)
		m.set_shader_parameter("color2", c2 if i % 2 == 0 else c1)
		m.set_shader_parameter("fase", float(i) * 1.9)
		var mi := MeshInstance3D.new()
		mi.mesh = malla
		mi.material_override = m
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		mi.custom_aabb = AABB(Vector3(-ANCHO, -ALTO - 2.0, -2.0), Vector3(ANCHO * 2.0, ALTO * 2.0 + 2.0, 4.0))
		## Encima de la gente, de cara al campo (el centro del estadio es el origen).
		var hacia := Vector3(-s.x, 0.0, -s.z).normalized()
		mi.position = s + Vector3(0, ALTO * 0.5 + 1.6, 0) - hacia * 1.0
		b.add_child(mi)
		mi.look_at(mi.position - hacia, Vector3.UP)
		b._mats.append(m)
	return b

func _process(delta: float) -> void:
	_t += delta
	## Sube en 0,8 s, ondea y baja en el último segundo.
	var s := clampf(_t / 0.8, 0.0, 1.0) * (1.0 - clampf((_t - _dura + 1.0), 0.0, 1.0))
	for m in _mats:
		m.set_shader_parameter("subida", s)
	if _t > _dura:
		queue_free()
