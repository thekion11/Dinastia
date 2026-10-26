extends SubViewportContainer
## LA MASCOTA EN 3D, GIRANDO (configuración del club, paso «Mascota»). Es la
## misma `MascotaQ` que sale a la banda en el partido y en la ceremonia, con la
## camiseta del club: lo que se elige aquí es lo que se verá en el estadio.
## Se monta al primer `mostrar()` (no antes: carga el cuerpo de un futbolista).

const ALTO_CAMARA := 1.25

var _vp: SubViewport
var _pivote: Node3D
var _actual := ""
var _colores := ""
var _masc: Node3D = null
var _pendiente: Array = []

func _init() -> void:
	stretch = true
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_vp = SubViewport.new()
	_vp.own_world_3d = true
	## Fondo propio y no transparente: con el fondo transparente, en Forward+ el
	## traje y el pelaje salían casi invisibles sobre el panel oscuro (captura).
	_vp.transparent_bg = false
	_vp.msaa_3d = Viewport.MSAA_2X
	_vp.render_target_update_mode = SubViewport.UPDATE_WHEN_VISIBLE
	add_child(_vp)
	var env := WorldEnvironment.new()
	var e := Environment.new()
	e.background_mode = Environment.BG_COLOR
	e.background_color = Color(0.1, 0.15, 0.12)
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	e.ambient_light_color = Color(0.72, 0.74, 0.78)
	e.ambient_light_energy = 1.1
	e.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.environment = e
	_vp.add_child(env)
	var sol := DirectionalLight3D.new()
	sol.rotation_degrees = Vector3(-35, 30, 0)
	sol.light_energy = 1.25
	_vp.add_child(sol)
	var relleno := DirectionalLight3D.new()
	relleno.rotation_degrees = Vector3(-15, -150, 0)
	relleno.light_energy = 0.45
	_vp.add_child(relleno)
	var cam := Camera3D.new()
	cam.position = Vector3(0, ALTO_CAMARA, 4.3)
	cam.fov = 34.0
	## A mano y no con `look_at`: aquí todavía no hay árbol y `look_at` lo exige.
	cam.transform = Transform3D(Basis.looking_at(Vector3(0, 0.98, 0) - cam.position), cam.position)
	_vp.add_child(cam)
	_pivote = Node3D.new()
	_vp.add_child(_pivote)
	## Un disco bajo los pies: sin suelo la mascota flota en la nada.
	var disco := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = 0.9
	cm.bottom_radius = 0.95
	cm.height = 0.06
	disco.mesh = cm
	var md := StandardMaterial3D.new()
	md.albedo_color = Color(0.16, 0.36, 0.2)
	md.roughness = 0.9
	disco.material_override = md
	disco.position.y = -0.03
	_vp.add_child(disco)

## Pone `animal` con los colores de `c`. Solo rehace si cambió algo.
func mostrar(c: Club, animal: String) -> void:
	var cols := c.color1 + c.color2
	if animal == _actual and cols == _colores:
		return
	if not is_inside_tree():
		## `MascotaQ.crear` necesita el árbol: se repite al entrar (con lo último pedido).
		_pendiente = [c, animal]
		if not tree_entered.is_connected(_al_entrar):
			tree_entered.connect(_al_entrar, CONNECT_ONE_SHOT | CONNECT_DEFERRED)
		return
	_actual = animal
	_colores = cols
	for h in _pivote.get_children():
		h.queue_free()
	_masc = MascotaQ.crear(_pivote, c, animal, Vector3.ZERO, 0.0)

func _al_entrar() -> void:
	if _pendiente.size() == 2:
		mostrar(_pendiente[0] as Club, String(_pendiente[1]))
	_pendiente = []

func animal_actual() -> String:
	return _actual

func _process(delta: float) -> void:
	if _pivote != null and not Animar.reducidas():
		_pivote.rotation.y += delta * 0.45
	## En la banda la mascota pasea; aquí no hay banda: camina en el sitio.
	if is_instance_valid(_masc):
		_masc.position = Vector3.ZERO
