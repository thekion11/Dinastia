class_name RedArco
extends Node
## LA RED QUE SE ONDULA AL GOL (17-10-2026, M-149). Va colgada de cada arco
## (`StadiumBuilder._add_goal`) y guarda los paños de red con `red_arco.gdshader`.
## `RedArco.golpe(raiz, pos_balon)` busca el arco más cercano al balón y lanza
## la onda desde donde entró; solo procesa mientras dura (≈2,4 s).

const DURA := 2.4
var panos: Array[MeshInstance3D] = []
var _edad := 99.0

static func golpe(raiz: Node, pos_balon: Vector3, fuerza := 0.7) -> bool:
	if raiz == null:
		return false
	var mejor: RedArco = null
	var md := INF
	for r in raiz.find_children("RedArco*", "", true, false):
		var ra := r as RedArco
		if ra == null or ra.panos.is_empty() or not is_instance_valid(ra.panos[0]):
			continue
		var d := ra.panos[0].global_position.distance_to(pos_balon)
		if d < md:
			md = d
			mejor = ra
	if mejor == null or md > 12.0:
		return false
	mejor._lanzar(pos_balon, fuerza)
	return true

func _ready() -> void:
	set_process(false)

func _lanzar(pos_balon: Vector3, fuerza: float) -> void:
	_edad = 0.0
	for m in panos:
		var sm := m.material_override as ShaderMaterial
		if sm == null:
			continue
		var l := m.to_local(pos_balon)
		## Hacia fuera del arco = del lado contrario al balón respecto del paño.
		var signo := -1.0 if l.z > 0.0 else 1.0
		## El paño de fondo recibe el golpe entero; el techo, un tercio.
		var k := 1.0 if String(m.name) == "RedFondo" else 0.35
		sm.set_shader_parameter("impacto", Vector2(l.x, l.y))
		sm.set_shader_parameter("fuerza", fuerza * k * signo)
		sm.set_shader_parameter("edad", 0.0)
	set_process(true)

func _process(delta: float) -> void:
	_edad += delta
	var fin := _edad >= DURA
	for m in panos:
		if not is_instance_valid(m):
			continue
		var sm := m.material_override as ShaderMaterial
		if sm != null:
			sm.set_shader_parameter("edad", _edad)
			if fin:
				sm.set_shader_parameter("fuerza", 0.0)
	if fin:
		set_process(false)
