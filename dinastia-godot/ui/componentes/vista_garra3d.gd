class_name VistaGarra3D
extends SubViewportContainer
## LA MÁQUINA DE PELUCHES EN 3D (27-10-2026, orden del líder al llegar los modelos del Drive). Lo que antes se dibujaba en 2D sobre el cristal de
## `PanelPeluches` es ahora una escena 3D en un `SubViewport`: el suelo de la máquina con sus cristales, los peluches de `Peluches.PELUCHES` con su
## modelo (`PelucheModelo.montar`) en las posiciones del campo, la salida y la garra (cable y tres dedos) que baja, cierra, sube y lleva lo agarrado.
## No decide nada: `actualizar(panel)` copia en cada fotograma el estado del panel (garra, fase, tiempos, agarrado, campo).

const ANCHO := 1.0           ## el campo, en metros (x de 0 a 1 → −0,5 … 0,5)
const FONDO := 0.75          ## y del campo 0 … 1 → z −0,375 … 0,375 (0 = al fondo, 1 = delante)
const ALTO_GARRA := 0.62     ## altura de la garra en reposo
const ALTO_ABAJO := 0.24     ## altura al cerrar sobre el montón (la garra, ×1,8, llega con los dedos a los peluches)
const SALIDA := Vector2(0.09, 0.9)

var _vp := SubViewport.new()
var _raiz := Node3D.new()
var _peluches := Node3D.new()
var _garra := Node3D.new()
var _cable := MeshInstance3D.new()
var _dedos: Array[Node3D] = []
var _colgado: Node3D
var _colgado_id := ""
var _campo_visto := ""
var _gana_nodo: Node3D

static func en(caja: Control, rect: Rect2) -> VistaGarra3D:
	var v := VistaGarra3D.new()
	v.position = rect.position
	v.size = rect.size
	v.stretch = true
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	caja.add_child(v)
	return v

func _ready() -> void:
	_vp.own_world_3d = true
	_vp.transparent_bg = false
	_vp.msaa_3d = Viewport.MSAA_4X
	add_child(_vp)
	_vp.add_child(_raiz)
	_montar_escena()

static func a_mundo(p: Vector2, alto: float = 0.0) -> Vector3:
	return Vector3((p.x - 0.5) * ANCHO, alto, (p.y - 0.5) * FONDO)

static func _mat(c: Color, rugoso := 0.8, metal := 0.0) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = rugoso
	m.metallic = metal
	return m

func _caja_malla(tam: Vector3, pos: Vector3, mat: Material, padre: Node3D = null) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = tam
	mi.mesh = bm
	mi.material_override = mat
	mi.position = pos
	(padre if padre != null else _raiz).add_child(mi)
	return mi

func _montar_escena() -> void:
	var cam := Camera3D.new()
	cam.position = Vector3(0, 1.22, 1.08)
	cam.fov = 44.0
	_raiz.add_child(cam)
	cam.look_at(Vector3(0, 0.08, 0.02))
	var env := WorldEnvironment.new()
	var e := Environment.new()
	e.background_mode = Environment.BG_COLOR
	e.background_color = Color(0.06, 0.07, 0.12)
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	e.ambient_light_color = Color(0.75, 0.78, 0.9)
	e.ambient_light_energy = 0.55
	env.environment = e
	_raiz.add_child(env)
	var luz := DirectionalLight3D.new()
	luz.rotation_degrees = Vector3(-62, 28, 0)
	luz.light_energy = 1.1
	luz.shadow_enabled = true
	_raiz.add_child(luz)
	var foco := OmniLight3D.new()                       ## la luz del techo de la máquina
	foco.position = Vector3(0, 0.9, 0)
	foco.light_color = Color(1.0, 0.92, 0.8)
	foco.omni_range = 2.0
	foco.light_energy = 0.8
	_raiz.add_child(foco)
	## El suelo (moqueta), los cristales de los lados y la boca de la salida.
	_caja_malla(Vector3(ANCHO + 0.06, 0.04, FONDO + 0.06), Vector3(0, -0.02, 0), _mat(Color(0.18, 0.22, 0.38), 0.95))
	var vidrio := _mat(Color(0.7, 0.85, 1.0, 0.12), 0.05)
	vidrio.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	for lado: float in [-1.0, 1.0]:
		_caja_malla(Vector3(0.01, 0.8, FONDO), Vector3(lado * (ANCHO * 0.5 + 0.02), 0.4, 0), vidrio)
	_caja_malla(Vector3(ANCHO, 0.8, 0.01), Vector3(0, 0.4, -FONDO * 0.5 - 0.02), _mat(Color(0.22, 0.12, 0.3), 0.7))
	var boca := a_mundo(SALIDA)
	_caja_malla(Vector3(0.17, 0.005, 0.15), boca + Vector3(0, 0.002, 0), _mat(Color(0.02, 0.02, 0.03)))
	var naranja := _mat(Color(0.95, 0.5, 0.15), 0.5)
	for k in 4:
		var horiz := k < 2
		var s := -1.0 if k % 2 == 0 else 1.0
		_caja_malla(Vector3(0.19 if horiz else 0.02, 0.07, 0.02 if horiz else 0.17),
			boca + (Vector3(0, 0.035, s * 0.085) if horiz else Vector3(s * 0.095, 0.035, 0)), naranja)
	_raiz.add_child(_peluches)
	## La garra: cuerpo, cable hacia el techo y tres dedos que se cierran.
	_raiz.add_child(_garra)
	_garra.scale = Vector3.ONE * 1.8                    ## a escala real (4 cm) no se veía entre los peluches
	var metal := _mat(Color(0.95, 0.8, 0.22), 0.3, 0.8)
	var cuerpo := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = 0.035
	cm.bottom_radius = 0.045
	cm.height = 0.06
	cuerpo.mesh = cm
	cuerpo.material_override = metal
	_garra.add_child(cuerpo)
	var cl := CylinderMesh.new()
	cl.top_radius = 0.004
	cl.bottom_radius = 0.004
	cl.height = 1.0
	_cable.mesh = cl
	_cable.material_override = _mat(Color(0.8, 0.8, 0.85), 0.4, 0.6)
	_raiz.add_child(_cable)
	for k in 3:
		var eje := Node3D.new()
		eje.rotation.y = TAU * float(k) / 3.0
		eje.position.y = -0.02
		_garra.add_child(eje)
		var bisagra := Node3D.new()
		bisagra.position = Vector3(0, 0, 0.035)
		eje.add_child(bisagra)
		_caja_malla(Vector3(0.012, 0.1, 0.012), Vector3(0, -0.05, 0), metal, bisagra)
		_dedos.append(bisagra)

## Los peluches del campo: se rehacen solo si el campo cambia (cada moneda trae uno nuevo).
func _poner_campo(campo: Array) -> void:
	var clave := str(campo)
	if clave == _campo_visto:
		return
	_campo_visto = clave
	for h in _peluches.get_children():
		h.queue_free()
	for i in campo.size():
		var f: Dictionary = campo[i]
		var n := PelucheModelo.montar(Peluches.def(String(f["id"])))
		n.position = a_mundo(Vector2(float(f["x"]), float(f["y"])))
		n.rotation.y = float(absi(hash([String(f["id"]), i])) % 628) / 100.0 - 3.14   ## cada uno mirando a un lado, siempre el mismo
		n.name = "p%d" % i
		_peluches.add_child(n)

## Copia el estado del panel. `fase` y las constantes de tiempo son las de `PanelPeluches`.
func actualizar(panel: PanelPeluches) -> void:
	_poner_campo(panel.campo)
	var fase := panel.fase
	var t := panel.get("_t") as float
	var agarrado := panel.get("_agarrado") as int
	var c: Vector2 = panel.garra
	var bajada := 0.0
	var cierre := 0.0
	match fase:
		PanelPeluches.BAJA:
			bajada = clampf(t / PanelPeluches.T_BAJA, 0.0, 1.0)
		PanelPeluches.CIERRA:
			bajada = 1.0
			cierre = clampf(t / PanelPeluches.T_CIERRA, 0.0, 1.0)
		PanelPeluches.SUBE:
			bajada = 1.0 - clampf(t / PanelPeluches.T_SUBE, 0.0, 1.0)
			cierre = 1.0
		PanelPeluches.LLEVA:
			c = panel.garra.lerp(SALIDA, clampf(t / PanelPeluches.T_LLEVA, 0.0, 1.0))
			cierre = 1.0
		PanelPeluches.SALE:
			c = SALIDA
	var alto := lerpf(ALTO_GARRA, ALTO_ABAJO, smoothstep(0.0, 1.0, bajada))
	_garra.visible = fase >= PanelPeluches.MOVER and fase != PanelPeluches.FIN
	_cable.visible = _garra.visible
	_garra.position = a_mundo(c, alto)
	_cable.position = a_mundo(c, (alto + 0.85) * 0.5)
	_cable.scale = Vector3(1, maxf(0.85 - alto, 0.01), 1)
	for d: Node3D in _dedos:
		d.rotation.x = lerpf(-0.55, 0.15, cierre)        ## abiertos hacia fuera → cerrados bajo la garra
	## El peluche agarrado deja el montón y cuelga de la garra hasta la salida; al soltarse, cae por la boca.
	var lleva := agarrado >= 0 and fase >= PanelPeluches.SUBE and fase <= PanelPeluches.LLEVA
	for i in _peluches.get_child_count():
		(_peluches.get_child(i) as Node3D).visible = not (lleva and i == agarrado) and not (fase >= PanelPeluches.SALE and i == agarrado)
	var id_colgado := String(panel.campo[agarrado]["id"]) if lleva else ""
	if id_colgado != _colgado_id:
		if _colgado != null:
			_colgado.queue_free()
			_colgado = null
		_colgado_id = id_colgado
		if id_colgado != "":
			_colgado = PelucheModelo.montar(Peluches.def(id_colgado))
			_raiz.add_child(_colgado)
	if _colgado != null:
		_colgado.position = _garra.position + Vector3(0, -0.26, 0)
	var gana := String(panel.get("_gana"))
	if fase == PanelPeluches.SALE and gana != "":
		if _gana_nodo == null:
			_gana_nodo = PelucheModelo.montar(Peluches.def(gana))
			_raiz.add_child(_gana_nodo)
		var q := clampf(t / PanelPeluches.T_SALIDA, 0.0, 1.0)
		_gana_nodo.position = a_mundo(SALIDA, lerpf(ALTO_GARRA - 0.2, -0.3, q * q))
	elif _gana_nodo != null:
		_gana_nodo.queue_free()
		_gana_nodo = null
