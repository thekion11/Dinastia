class_name IncendioVisual
extends RefCounted
## LO QUE SE VE DE UN INCIDENTE (27-10-2026, pieza E): las llamas con su luz y su humo (incendio), los dos coches siniestrados con los
## intermitentes (accidente) y la cinta de la policía (robo y accidente). Sin azar y sin sombras: solo mallas, un OmniLight y una
## función `animar` que sube y baja las llamas con el tiempo y la fracción que queda por apagar.
const COCHES := "res://assets/ciudad/kenney_cars/%s.glb"

static func _mat(c: Color, brillo := 0.0, alfa := 1.0) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(c.r, c.g, c.b, alfa)
	if brillo > 0.0:
		m.emission_enabled = true
		m.emission = c
		m.emission_energy_multiplier = brillo
	if alfa < 1.0:
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED if brillo > 0.0 else BaseMaterial3D.SHADING_MODE_PER_PIXEL
	return m

## Un fuego en el solar de la acera: llamas (conos de tres tamaños), luz parpadeante y cuatro bolas de humo que suben.
static func fuego(padre: Node3D, pos: Vector3) -> Node3D:
	var raiz := Node3D.new()
	raiz.name = "Incendio"
	raiz.position = pos
	var tamanos := [Vector3(4.2, 9.0, 4.2), Vector3(3.0, 6.4, 3.0), Vector3(2.2, 4.6, 2.2)]
	var cols := [Color(1.0, 0.38, 0.05), Color(1.0, 0.62, 0.1), Color(1.0, 0.86, 0.3)]
	for k in 3:
		var mi := MeshInstance3D.new()
		var cono := CylinderMesh.new()
		cono.top_radius = 0.0
		cono.bottom_radius = tamanos[k].x * 0.5
		cono.height = tamanos[k].y
		cono.radial_segments = 6
		mi.mesh = cono
		mi.material_override = _mat(cols[k], 2.0)
		mi.position = Vector3(float(k - 1) * 1.6, tamanos[k].y * 0.5, float(k % 2) * 1.4 - 0.7)
		mi.name = "Llama%d" % k
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		raiz.add_child(mi)
	var luz := OmniLight3D.new()
	luz.name = "LuzFuego"
	luz.light_color = Color(1.0, 0.55, 0.2)
	luz.omni_range = 26.0
	luz.light_energy = 3.0
	luz.position = Vector3(0, 4.5, 0)
	raiz.add_child(luz)
	for k in 4:
		var humo := MeshInstance3D.new()
		var esf := SphereMesh.new()
		esf.radius = 1.6
		esf.height = 3.2
		esf.radial_segments = 8
		esf.rings = 4
		humo.mesh = esf
		humo.material_override = _mat(Color(0.18, 0.18, 0.2), 0.0, 0.55)
		humo.name = "Humo%d" % k
		humo.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		raiz.add_child(humo)
	padre.add_child(raiz)
	return raiz

## `t`: segundos; `resta`: fracción que queda por apagar (1 = recién empezado, 0 = apagado). Las llamas encogen; el humo sube y se repite.
static func animar(raiz: Node3D, t: float, resta: float) -> void:
	if raiz == null or not is_instance_valid(raiz):
		return
	for k in 3:
		var l := raiz.get_node_or_null("Llama%d" % k) as MeshInstance3D
		if l != null:
			var pulso := 1.0 + 0.18 * sin(t * (9.0 + float(k) * 3.0) + float(k))
			l.scale = Vector3(1.0, 1.0, 1.0) * maxf(resta, 0.02) * pulso
			l.position.y = (l.mesh as CylinderMesh).height * 0.5 * l.scale.y
	var luz := raiz.get_node_or_null("LuzFuego") as OmniLight3D
	if luz != null:
		luz.light_energy = 3.0 * resta * (0.85 + 0.15 * sin(t * 17.0))
	for k in 4:
		var h := raiz.get_node_or_null("Humo%d" % k) as MeshInstance3D
		if h != null:
			var f := fposmod(t * 0.18 + float(k) * 0.25, 1.0)
			h.position = Vector3(sin(float(k) * 2.1) * 1.6, 7.0 + f * 20.0, cos(float(k) * 2.1) * 1.6)
			h.scale = Vector3.ONE * (0.6 + f * 1.8) * (0.25 + 0.75 * resta)

## Dos coches que chocaron: uno atravesado y otro con el morro contra él, con los cuatro intermitentes de aviso.
static func accidente(padre: Node3D, pos: Vector3) -> Node3D:
	var raiz := Node3D.new()
	raiz.name = "Accidente"
	raiz.position = pos
	for par: Array in [["sedan", Vector3(-2.2, 0, 0), 0.5, 0.0], ["taxi", Vector3(2.4, 0, 3.0), -2.2, 0.06]]:
		var ps := load(COCHES % String(par[0])) as PackedScene
		if ps == null:
			continue
		var n: Node3D = ps.instantiate()
		n.scale = Vector3.ONE * 2.3
		n.position = par[1]
		n.rotation = Vector3(0.0, float(par[2]), float(par[3]))
		raiz.add_child(n)
	for k in 4:
		var l := MeshInstance3D.new()
		var b := BoxMesh.new()
		b.size = Vector3(0.35, 0.22, 0.2)
		l.mesh = b
		l.material_override = _mat(Color(1.0, 0.6, 0.05), 2.5)
		l.position = Vector3(-2.2 + float(k % 2) * 4.6, 0.9, float(k / 2) * 3.0)
		l.name = "Intermitente%d" % k
		raiz.add_child(l)
	padre.add_child(raiz)
	return raiz

static func parpadeo(raiz: Node3D, t: float) -> void:
	if raiz == null or not is_instance_valid(raiz):
		return
	var on := fmod(t * 1.5, 1.0) < 0.5
	for k in 4:
		var l := raiz.get_node_or_null("Intermitente%d" % k) as MeshInstance3D
		if l != null:
			l.visible = on

## La cinta amarilla y negra de la policía: cuatro postes y un cordón a cada lado, alrededor de `pos`.
static func cinta(padre: Node3D, pos: Vector3, lado := 6.0) -> Node3D:
	var raiz := Node3D.new()
	raiz.name = "CintaPolicia"
	raiz.position = pos
	var amarillo := _mat(Color(0.95, 0.8, 0.1))
	var postes: Array[Vector3] = [Vector3(-lado, 0, -lado), Vector3(lado, 0, -lado), Vector3(lado, 0, lado), Vector3(-lado, 0, lado)]
	for k in 4:
		var p := MeshInstance3D.new()
		var cil := CylinderMesh.new()
		cil.top_radius = 0.07
		cil.bottom_radius = 0.07
		cil.height = 1.3
		p.mesh = cil
		p.material_override = _mat(Color(0.25, 0.25, 0.28))
		p.position = postes[k] + Vector3(0, 0.65, 0)
		raiz.add_child(p)
		var a: Vector3 = postes[k]
		var b: Vector3 = postes[(k + 1) % 4]
		var c := MeshInstance3D.new()
		var caja := BoxMesh.new()
		caja.size = Vector3(0.04 if absf(a.x - b.x) < 0.1 else a.distance_to(b), 0.12, a.distance_to(b) if absf(a.x - b.x) < 0.1 else 0.04)
		c.mesh = caja
		c.material_override = amarillo
		c.position = (a + b) * 0.5 + Vector3(0, 1.05, 0)
		raiz.add_child(c)
	padre.add_child(raiz)
	return raiz
