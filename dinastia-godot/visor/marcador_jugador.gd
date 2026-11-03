class_name MarcadorJugador
extends Node
## EL TRIÁNGULO SOBRE EL JUGADOR CONTROLADO (P2, 3-11, prueba del dueño en su teléfono): un triángulo invertido de color FUERTE (amarillo con
## borde negro, siempre de cara a la cámara, sin depender de la camiseta ni del césped) flotando sobre la cabeza del jugador que llevas en
## `PartidoJugable`. Sube y baja un poco, y crece con la distancia a la cámara para leerse igual de cerca que desde la cámara de tele.
## Se mueve en el paso de FÍSICA, como los jugadores (la raíz del partido se interpola: así va a su compás). Se esconde en repeticiones y goles.

const COLOR := Color(1.0, 0.86, 0.0)
const BORDE := Color(0.05, 0.05, 0.07)
const ANCHO := 1.1              ## m, a poca distancia
const ALTURA_PUNTA := 3.1       ## m sobre los pies: por encima del rótulo con el nombre

var _pj: Node
var _marca: MeshInstance3D
var _t := 0.0

static func poner(partido: Node) -> MarcadorJugador:
	var m := MarcadorJugador.new()
	m._pj = partido
	partido.add_child(m)
	m._montar(partido.get("_raiz") as Node3D)
	return m

func _montar(raiz: Node3D) -> void:
	if raiz == null:
		return
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	## Borde: el mismo triángulo más grande y un pelo detrás; encima, el de color.
	for tri: Array in [[0.62, 1.0, BORDE, -0.01], [0.5, 0.82, COLOR, 0.0]]:
		var a: float = tri[0]
		var h: float = tri[1]
		var z: float = tri[3]
		st.set_color(tri[2])
		st.add_vertex(Vector3(-a, h, z))
		st.set_color(tri[2])
		st.add_vertex(Vector3(a, h, z))
		st.set_color(tri[2])
		st.add_vertex(Vector3(0.0, 0.0 if tri[2] == COLOR else -0.1, z))
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.vertex_color_use_as_albedo = true
	mat.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	mat.no_depth_test = true   ## se ve aunque otro jugador o el árbitro se interpongan
	mat.render_priority = 10
	_marca = MeshInstance3D.new()
	_marca.name = "TrianguloControlado"
	_marca.mesh = st.commit()
	_marca.material_override = mat
	_marca.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_marca.visible = false
	raiz.add_child(_marca)

func _process(delta: float) -> void:
	_t += delta

func _physics_process(_d: float) -> void:
	if _marca == null or not is_instance_valid(_pj):
		return
	var motor: Variant = _pj.get("motor")
	var jugador: Dictionary = motor.usuario if motor != null else {}
	var cine: Variant = _pj.get("_cine")
	var repe: Variant = _pj.get("_repe")
	var oculto: bool = jugador.is_empty() or is_instance_valid(cine) or (is_instance_valid(repe) and bool(repe.get("reproduciendo"))) \
		or not is_instance_valid(jugador.get("node"))
	_marca.visible = not oculto
	if oculto:
		return
	var nodo: Node3D = jugador["node"]
	var cam := get_viewport().get_camera_3d()
	var dist := cam.global_position.distance_to(nodo.global_position) if cam != null else 20.0
	var k := clampf(dist * 0.045, 1.0, 2.6)
	_marca.scale = Vector3.ONE * k * ANCHO
	_marca.position = nodo.position + Vector3(0, ALTURA_PUNTA + 0.2 * k + 0.1 * sin(_t * 4.0), 0)
