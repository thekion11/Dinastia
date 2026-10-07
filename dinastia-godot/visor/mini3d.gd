class_name Mini3D
extends RefCounted
## LOS MINIJUEGOS EN 3D (7-10-2026, pedido: «los mini juegos también deben ser
## 3D con animaciones»). Piezas comunes para que cada minijuego monte su escena
## en un `SubViewport` con mundo propio (no toca la ciudad que queda debajo):
##   · `vista()`: el visor, con el cielo y el sol de `Calidad`, y su cámara;
##   · `persona()`: un vecino del paquete Quaternius (`PeatonQ`) con TODAS las
##     animaciones (saludar, aplaudir, celebrar, atajar, patear...);
##   · `anim()`: reproducir un clip y volver a la pose de reposo al terminar;
##   · `caja()`, `cilindro()`, `esfera()`, `mat()`: la utilería.

static func vista(padre: Control, momento: int = Calidad.DIA) -> Dictionary:
	var cont := SubViewportContainer.new()
	cont.stretch = true
	cont.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	cont.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var vp := SubViewport.new()
	vp.own_world_3d = true
	vp.msaa_3d = Viewport.MSAA_4X
	vp.handle_input_locally = false
	cont.add_child(vp)
	padre.add_child(cont)
	padre.move_child(cont, 0)
	var raiz := Node3D.new()
	vp.add_child(raiz)
	var we := Calidad.entorno(Calidad.MEDIO, momento)
	## Escenas chicas y a pleno sol: con la exposición del estadio se lavaban.
	we.environment.tonemap_exposure = 0.82
	we.environment.fog_enabled = false
	we.environment.volumetric_fog_enabled = false
	raiz.add_child(we)
	var sol := Calidad.sol(Calidad.MEDIO, momento)
	sol.light_energy *= 0.8
	raiz.add_child(sol)
	var cam := Camera3D.new()
	cam.fov = 55.0
	raiz.add_child(cam)
	cam.current = true
	return {"cont": cont, "vp": vp, "raiz": raiz, "cam": cam, "sol": sol}

## Un vecino animado. `deporte` lo viste de corto con los colores dados (el
## portero, los chicos del barrio); si no, ropa de calle.
static func persona(padre: Node3D, rng: RandomNumberGenerator, pos: Vector3, deporte: Array = []) -> Dictionary:
	if deporte.size() >= 2:
		return _deportista(padre, rng, pos, deporte)
	var d := PeatonQ.crear(rng)
	if d.is_empty():
		return d
	var nodo: Node3D = d["nodo"]
	padre.add_child(nodo)
	nodo.position = pos
	PeatonQ.terminar(d)
	_todas_las_animaciones(d)
	for mi in nodo.find_children("*", "MeshInstance3D", true, false):
		(mi as MeshInstance3D).visibility_range_end = 0.0
	anim(d, "parado")
	return d

static func _todas_las_animaciones(d: Dictionary) -> void:
	var ap: AnimationPlayer = d["anim"]
	var esq: Skeleton3D = d["esqueleto"]
	if ap.has_animation_library(""):
		ap.remove_animation_library("")
	ap.add_animation_library("", AnimQuaternius.construir(esq, str(ap.get_path_to(esq)), true))

## De corto (o manga larga, el portero), vestido una sola vez como los
## futbolistas del partido.
static func _deportista(padre: Node3D, rng: RandomNumberGenerator, pos: Vector3, deporte: Array) -> Dictionary:
	var d := FutbolistaQ.crear(rng.randf_range(1.74, 1.88), "male")
	if d.is_empty():
		return d
	var nodo: Node3D = d["nodo"]
	padre.add_child(nodo)
	nodo.position = pos
	FutbolistaQ.terminar(d, true)
	var c1: Color = deporte[0]
	var c2: Color = deporte[1]
	var piel := Color(String(PeatonQ.PIELES[rng.randi() % PeatonQ.PIELES.size()]))
	var pelo: Color = PeatonQ.PELOS[rng.randi() % PeatonQ.PELOS.size()]
	VestidorQ.vestir_equipacion(d, c1, c2, "liso", piel, pelo, c2, c1, deporte.size() > 2 and bool(deporte[2]))
	PeloQ.poner(d, String(PeatonQ.CORTES_H[rng.randi() % PeatonQ.CORTES_H.size()]), pelo, rng.randf() < 0.3)
	anim(d, "parado")
	return d

## Reproduce un clip; si no es de bucle, al acabar vuelve a `luego`.
static func anim(d: Dictionary, nombre: String, luego: String = "parado", mezcla: float = 0.2, vel: float = 1.0) -> void:
	if d.is_empty():
		return
	var ap: AnimationPlayer = d["anim"]
	if not ap.has_animation(nombre):
		nombre = "parado"
	ap.play(nombre, mezcla, vel)
	ap.clear_queue()
	var a := ap.get_animation(nombre)
	if a != null and a.loop_mode == Animation.LOOP_NONE and luego != "" and ap.has_animation(luego):
		ap.queue(luego)

static func mat(c: Color, rug: float = 0.7, emi: float = 0.0) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = rug
	if c.a < 1.0:
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	if emi > 0.0:
		m.emission_enabled = true
		m.emission = c
		m.emission_energy_multiplier = emi
	return m

static func caja(padre: Node3D, pos: Vector3, tam: Vector3, m: Material) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = tam
	mi.mesh = bm
	mi.material_override = m
	mi.position = pos
	padre.add_child(mi)
	return mi

static func cilindro(padre: Node3D, pos: Vector3, radio: float, alto: float, m: Material, radio_arriba: float = -1.0) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.bottom_radius = radio
	cm.top_radius = radio if radio_arriba < 0.0 else radio_arriba
	cm.height = alto
	cm.radial_segments = 16
	mi.mesh = cm
	mi.material_override = m
	mi.position = pos
	padre.add_child(mi)
	return mi

static func esfera(padre: Node3D, pos: Vector3, radio: float, m: Material) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var sm := SphereMesh.new()
	sm.radius = radio
	sm.height = radio * 2.0
	sm.radial_segments = 16
	sm.rings = 8
	mi.mesh = sm
	mi.material_override = m
	mi.position = pos
	padre.add_child(mi)
	return mi

## Un modelo de los kits de la ciudad (karts, conos, ruedas) o null.
static func kit(ruta: String) -> Node3D:
	if not ResourceLoader.exists(ruta):
		return null
	var ps: PackedScene = load(ruta)
	return ps.instantiate() if ps != null else null

## Punto del suelo (y = 0) bajo el ratón.
static func suelo_bajo(cam: Camera3D, pos_pantalla: Vector2, alto: float = 0.0) -> Variant:
	var o := cam.project_ray_origin(pos_pantalla)
	var d := cam.project_ray_normal(pos_pantalla)
	if absf(d.y) < 0.0001:
		return null
	var t := (alto - o.y) / d.y
	return o + d * t if t > 0.0 else null

const ANCHO_ARCO := 7.32
const ALTO_ARCO := 2.44

## Medio campo de entrenamiento: césped a franjas, líneas del área, el arco
## con su red (devuelta, para inflarla con el gol), vallas y una grada.
static func campo_y_arco(raiz: Node3D) -> Node3D:
	## El césped a franjas y las líneas del área.
	for k in 16:
		Mini3D.caja(raiz, Vector3(0, -0.05, -10.0 + float(k) * 3.0), Vector3(70, 0.1, 3.0),
			Mini3D.mat(Color(0.2, 0.47, 0.22) if k % 2 == 0 else Color(0.24, 0.53, 0.26), 0.9))
	var cal := Mini3D.mat(Color(0.95, 0.95, 0.95), 0.6)
	Mini3D.caja(raiz, Vector3(0, 0.01, 0), Vector3(40.3, 0.02, 0.12), cal)
	for x: float in [-9.16, 9.16]:
		Mini3D.caja(raiz, Vector3(x, 0.01, 2.75), Vector3(0.12, 0.02, 5.5), cal)
	Mini3D.caja(raiz, Vector3(0, 0.01, 5.5), Vector3(18.32, 0.02, 0.12), cal)
	for x: float in [-20.16, 20.16]:
		Mini3D.caja(raiz, Vector3(x, 0.01, 8.25), Vector3(0.12, 0.02, 16.5), cal)
	Mini3D.caja(raiz, Vector3(0, 0.01, 16.5), Vector3(40.3, 0.02, 0.12), cal)
	Mini3D.cilindro(raiz, Vector3(0, 0.01, 11.0), 0.12, 0.02, cal)
	## El arco: postes, travesaño y la red (lados, techo y fondo).
	var blanco := Mini3D.mat(Color.WHITE, 0.3)
	for x: float in [-ANCHO_ARCO * 0.5, ANCHO_ARCO * 0.5]:
		Mini3D.cilindro(raiz, Vector3(x, ALTO_ARCO * 0.5, 0), 0.06, ALTO_ARCO + 0.06, blanco)
	var trav := Mini3D.cilindro(raiz, Vector3(0, ALTO_ARCO, 0), 0.06, ANCHO_ARCO + 0.12, blanco)
	trav.rotation.z = PI * 0.5
	var red := Node3D.new()
	raiz.add_child(red)
	var red_m := Mini3D.mat(Color(0.95, 0.95, 0.95, 0.28), 0.8)
	red_m.cull_mode = BaseMaterial3D.CULL_DISABLED
	Mini3D.caja(red, Vector3(0, ALTO_ARCO * 0.5, -2.0), Vector3(ANCHO_ARCO, ALTO_ARCO, 0.02), red_m)
	Mini3D.caja(red, Vector3(0, ALTO_ARCO, -1.0), Vector3(ANCHO_ARCO, 0.02, 2.0), red_m)
	for x: float in [-ANCHO_ARCO * 0.5, ANCHO_ARCO * 0.5]:
		Mini3D.caja(red, Vector3(x, ALTO_ARCO * 0.5, -1.0), Vector3(0.02, ALTO_ARCO, 2.0), red_m)
	## La cuadrícula de la red, en hilos.
	var hilo := Mini3D.mat(Color(0.9, 0.9, 0.9, 0.6), 0.8)
	for k in 25:
		Mini3D.caja(red, Vector3(-ANCHO_ARCO * 0.5 + float(k) * ANCHO_ARCO / 24.0, ALTO_ARCO * 0.5, -2.0), Vector3(0.015, ALTO_ARCO, 0.015), hilo)
	for k in 9:
		Mini3D.caja(red, Vector3(0, float(k) * ALTO_ARCO / 8.0, -2.0), Vector3(ANCHO_ARCO, 0.015, 0.015), hilo)
	## Vallas de publicidad y una grada al fondo.
	for k in 6:
		Mini3D.caja(raiz, Vector3(-17.5 + float(k) * 7.0, 0.5, -5.0), Vector3(6.8, 1.0, 0.2),
			Mini3D.mat(Color.from_hsv(float(k) * 0.17, 0.6, 0.8), 0.5, 0.25))
	for f in 6:
		Mini3D.caja(raiz, Vector3(0, 1.4 + float(f) * 0.9, -8.0 - float(f) * 1.2), Vector3(48, 0.9, 1.2), Mini3D.mat(Color(0.3, 0.32, 0.38), 0.8))
	return red
