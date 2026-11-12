class_name MarcadorJugador
extends Node
## EL TRIÁNGULO SOBRE EL JUGADOR CONTROLADO (P2, 3-11, prueba del dueño en su teléfono): un triángulo invertido de color FUERTE (amarillo con
## borde negro, siempre de cara a la cámara, sin depender de la camiseta ni del césped) flotando sobre la cabeza del jugador que llevas en
## `PartidoJugable`. Sube y baja un poco, y crece con la distancia a la cámara para leerse igual de cerca que desde la cámara de tele.
## Se mueve en el paso de FÍSICA, como los jugadores (la raíz del partido se interpola: así va a su compás). Se esconde en repeticiones y goles.
## (12-11, sesión 14, legibilidad en el móvil) El triángulo ya no tiene tamaño mínimo de 1,1 m: con la cámara cercana del modo carrera
## tapaba media pantalla; ahora mide lo mismo en pantalla a cualquier distancia. Y QUIÉN LLEVA EL BALÓN: un aro en el césped bajo el
## portador, del color de su lado (celeste el tuyo, naranja el rival), con una flecha hacia donde ataca su equipo (1 malla, sin sombra).
## `SIN_ARO_BALON=1` lo quita.
const COLOR_PROPIO := Color(0.25, 0.85, 1.0)
const COLOR_RIVAL := Color(1.0, 0.45, 0.15)

const COLOR := Color(1.0, 0.86, 0.0)
const BORDE := Color(0.05, 0.05, 0.07)
const ANCHO := 1.1              ## m, a poca distancia
const ALTURA_PUNTA := 3.1       ## m sobre los pies: por encima del rótulo con el nombre

var _pj: Node
var _marca: MeshInstance3D
var _aro: MeshInstance3D
var _mat_aro: StandardMaterial3D
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
	if OS.get_environment("SIN_ARO_BALON") == "":
		_montar_aro(raiz)

## El aro (radio 0,45-0,72 m) y la flecha de ataque (hacia +z; se gira con el sentido del equipo), en una sola malla.
func _montar_aro(raiz: Node3D) -> void:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	const N := 28
	for i in N:
		var a0 := TAU * i / N
		var a1 := TAU * (i + 1) / N
		var p := [Vector3(sin(a0), 0, cos(a0)), Vector3(sin(a1), 0, cos(a1))]
		for v: Vector3 in [p[0] * 0.45, p[0] * 0.72, p[1] * 0.72, p[0] * 0.45, p[1] * 0.72, p[1] * 0.45]:
			st.add_vertex(v)
	for v: Vector3 in [Vector3(-0.42, 0, 0.82), Vector3(0.42, 0, 0.82), Vector3(0, 0, 1.45)]:
		st.add_vertex(v)
	_mat_aro = StandardMaterial3D.new()
	_mat_aro.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_mat_aro.cull_mode = BaseMaterial3D.CULL_DISABLED
	_mat_aro.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_mat_aro.albedo_color = COLOR_PROPIO
	_mat_aro.no_depth_test = true   ## el pasto (capas) lo tapaba: se dibuja encima del césped, como el aro de los juegos de móvil
	_mat_aro.render_priority = 5
	_aro = MeshInstance3D.new()
	_aro.name = "AroPortador"
	_aro.mesh = st.commit()
	_aro.material_override = _mat_aro
	_aro.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_aro.visible = false
	raiz.add_child(_aro)

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
	_poner_aro(motor, jugador, oculto or (is_instance_valid(repe) and bool(repe.get("reproduciendo"))) or is_instance_valid(cine))
	if oculto:
		return
	var nodo: Node3D = jugador["node"]
	var cam := _marca.get_viewport().get_camera_3d()   ## (12-11) la del SubViewport del partido (la del principal es nula)
	## A la MARCA, no a los pies: en el modo carrera la cámara va detrás y arriba, a la altura del triángulo (3 m), y medido a los
	## pies (21 m) salía de 1 m a dos pasos de la cámara: un triángulo enorme abajo en el centro de la pantalla.
	var arriba := nodo.position + Vector3(0, ALTURA_PUNTA, 0)
	var dist := cam.global_position.distance_to(_marca.get_parent().to_global(arriba) if _marca.get_parent() is Node3D else arriba) if cam != null else 20.0
	var k := clampf(dist * 0.045, 0.05, 2.6)
	_marca.scale = Vector3.ONE * k * ANCHO
	_marca.position = nodo.position + Vector3(0, ALTURA_PUNTA + 0.2 * k + 0.1 * sin(_t * 4.0), 0)

func _poner_aro(motor: Variant, jugador: Dictionary, en_pausa: bool) -> void:
	if _aro == null:
		return
	var por: Dictionary = motor.poseedor if motor != null else {}
	var ver := not en_pausa and not por.is_empty() and is_instance_valid(por.get("node")) and not (String(motor.estado) in ["gol", "fin", "descanso", "tanda"])
	_aro.visible = ver
	if not ver:
		return
	var local := bool(por["es_local"])
	var mio := local == bool(jugador.get("es_local", true))
	_mat_aro.albedo_color = Color(COLOR_PROPIO if mio else COLOR_RIVAL, 0.85)
	var nodo: Node3D = por["node"]
	var cam := _marca.get_viewport().get_camera_3d()   ## (12-11) la del SubViewport del partido (la del principal es nula)
	var dist := cam.global_position.distance_to(nodo.global_position) if cam != null else 20.0
	_aro.scale = Vector3.ONE * clampf(dist * 0.05, 1.0, 3.0)   ## con la cámara baja el aro se aplasta: crece con la distancia
	_aro.position = Vector3(nodo.position.x, 0.05, nodo.position.z)
	_aro.rotation.y = 0.0 if float(motor.dir_ataque(local)) > 0.0 else PI
