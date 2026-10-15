class_name CespedCapas
extends MeshInstance3D
## La malla de capas del césped con volumen (`cesped_capas.gdshader`): un
## parche de 36 x 36 m con N capas apiladas que va siempre debajo de lo que
## mira la cámara. Lejos no se dibuja (desde la cámara alta de la tele la
## brizna no se distingue y no se paga). ULTRA 14 capas, ALTO 10, MEDIO nada.

const LADO := 80.0
var _mat: ShaderMaterial

static func capas_por_calidad() -> int:
	if Calidad.motor_ligero:
		return 0
	match Calidad.elegida:
		Calidad.ULTRA: return 12
		Calidad.ALTO: return 8
	return 0

## `base`: el material del campo, del que se copian el dibujo y los verdes.
static func montar(padre: Node3D, base: ShaderMaterial, tam: Vector2) -> CespedCapas:
	var n := capas_por_calidad()
	if n <= 0:
		return null
	var c := CespedCapas.new()
	c.name = "CespedCapas"
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var alt := 0.032
	var h := LADO * 0.5
	for i in n:
		var y := alt * float(i + 1) / float(n)
		st.set_normal(Vector3.UP)
		for v: Vector3 in [Vector3(-h, y, -h), Vector3(h, y, -h), Vector3(h, y, h), Vector3(-h, y, -h), Vector3(h, y, h), Vector3(-h, y, h)]:
			st.add_vertex(v)
	c.mesh = st.commit()
	## Grande a propósito para que el recorte de la cámara no lo quite al moverse.
	c.custom_aabb = AABB(Vector3(-h, 0, -h), Vector3(LADO, 0.1, LADO))
	c.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var m := ShaderMaterial.new()
	m.shader = load("res://visor/cesped_capas.gdshader")
	for k in ["dibujo", "claro_s", "oscuro_s", "claro", "oscuro"]:
		m.set_shader_parameter(k, base.get_shader_parameter(k))
	m.set_shader_parameter("tam_plano", tam)
	m.set_shader_parameter("altura", alt)
	c.material_override = m
	c._mat = m
	padre.add_child(c)
	return c

func _process(_d: float) -> void:
	var cam := get_viewport().get_camera_3d()
	var padre := get_parent() as Node3D
	## Solo en el estadio sin girar (en la ciudad el campo va movido).
	if cam == null or padre == null or not padre.global_transform.is_equal_approx(Transform3D.IDENTITY):
		visible = false
		return
	var cp := cam.global_position
	visible = cp.y < 40.0 and capas_por_calidad() > 0
	if not visible:
		return
	var fw := -cam.global_basis.z
	var plano := Vector2(fw.x, fw.z)
	if plano.length() > 0.01:
		plano = plano.normalized()
	## Hasta donde llega el rayo de la cámara al suelo, sin pasar de 12 m.
	var hasta := 30.0
	if fw.y < -0.05:
		hasta = minf(cp.y / -fw.y, 40.0)
	var foco := Vector2(cp.x, cp.z) + plano * hasta * 0.55
	global_position = Vector3(foco.x, 0.0, foco.y)
