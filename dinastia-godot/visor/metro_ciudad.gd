class_name MetroCiudad
extends Node3D
## EL METRO DE LA CIUDAD (7-10-2026, pedido: «metro… la ciudad debe ser real,
## interactiva»). Dos líneas que FUNCIONAN:
##
##  · LÍNEA 1 (roja), ELEVADA: un viaducto sobre la mediana de la avenida
##    x = 660, de punta a punta de la ciudad, con siete estaciones de andén
##    alto. Sus trenes se ven pasar por encima del tráfico.
##  · LÍNEA 2 (azul), SUBTERRÁNEA: bajo la avenida z = -660, cruzando por
##    debajo del río, con sus bocas en la acera. Desde arriba no se ve; el
##    botón «🚇 Metro» del mapa activa la vista de rayos X: el túnel y los
##    trenes se dibujan a través del suelo.
##  · Transbordo entre las dos en (660, -660).
##
## Cada tren (tres coches) va y vuelve por su línea: acelera, va a su
## velocidad de crucero, frena antes de cada estación, abre unos segundos y
## sigue (`Tren.simular`, lógica pura y comprobable). Los paneles de cada
## estación dicen cuánto falta para el próximo tren.

const ALTO_VIADUCTO := 11.0
const PROF_TUNEL := -12.0
const VEL := 16.0          ## m/s de crucero (~58 km/h)
const ACEL := 1.2          ## m/s²
const PARADA := 7.0        ## s con las puertas abiertas

## Un tren sobre una línea recta de estaciones (posiciones `s` a lo largo).
class Tren:
	var s := 0.0
	var v := 0.0
	var sentido := 1.0
	var espera := 0.0
	var largo := 0.0
	var estaciones: PackedFloat32Array
	var paradas_hechas := 0

	func _init(largo_linea: float, est: PackedFloat32Array, s0: float, sentido0: float) -> void:
		largo = largo_linea
		estaciones = est
		s = s0
		sentido = sentido0

	## La próxima estación en el sentido de la marcha (INF si no queda ninguna:
	## está en la cabecera).
	func proxima() -> float:
		var mejor := INF
		for e in estaciones:
			var d := (e - s) * sentido
			if d > 0.5 and d < mejor:
				mejor = d
		if mejor == INF:
			return INF
		return s + mejor * sentido

	func simular(delta: float) -> void:
		if espera > 0.0:
			espera -= delta
			return
		var objetivo := proxima()
		if objetivo == INF:
			## Cabecera: da la vuelta y sigue.
			sentido = -sentido
			return
		var dist := absf(objetivo - s)
		var frenada := v * v / (2.0 * ACEL)
		if dist <= frenada + 0.3:
			v = maxf(0.0, v - ACEL * delta)
		else:
			v = minf(VEL, v + ACEL * delta)
		var paso := v * delta
		if paso >= dist or (v <= 0.05 and dist < 1.5):
			s = objetivo
			v = 0.0
			espera = PARADA
			paradas_hechas += 1
			return
		s += paso * sentido

	## Segundos aproximados hasta pasar por `pos` (en `s`).
	func eta(pos: float) -> float:
		var d := (pos - s) * sentido
		if d < 0.0:
			d = (largo - s if sentido > 0.0 else s) + (largo - pos if sentido > 0.0 else pos)
			d = absf(d)
		var n_paradas := 0
		for e in estaciones:
			var de := (e - s) * sentido
			if de > 0.5 and de < d:
				n_paradas += 1
		return d / VEL + float(n_paradas) * (PARADA + VEL / ACEL) + maxf(espera, 0.0)

var lineas: Array = []     ## [{nombre, color, a, b, elevada, estaciones: [Vector3], trenes: [Tren], nodos: [Node3D]}]
var _xray: Node3D
var _paneles: Array = []   ## [{label, linea, s}]
var _t_panel := 0.0

func montar(exp: CiudadExpansion) -> void:
	var cel := CiudadExpansion.CELDA
	lineas = [
		{"nombre": "Línea 1", "color": Color(0.85, 0.15, 0.15), "elevada": true,
			"a": Vector3(6 * cel, 0, -11 * cel), "b": Vector3(6 * cel, 0, 11 * cel),
			"estaciones": [-9, -6, -3, 0, 3, 6, 9]},
		{"nombre": "Línea 2", "color": Color(0.15, 0.4, 0.9), "elevada": false,
			"a": Vector3(-11 * cel, 0, -6 * cel), "b": Vector3(11 * cel, 0, -6 * cel),
			"estaciones": [-9, -6, -3, 0, 3, 6, 9]},
	]
	_xray = Node3D.new()
	_xray.name = "MetroRayosX"
	_xray.visible = false
	add_child(_xray)
	for l: Dictionary in lineas:
		var a: Vector3 = l["a"]
		var b: Vector3 = l["b"]
		var largo := a.distance_to(b)
		var dir := (b - a).normalized()
		var est_s := PackedFloat32Array()
		var est_pos: Array = []
		for k: int in l["estaciones"]:
			var p := Vector3(float(k) * cel, 0, a.z) if absf(dir.x) > 0.5 else Vector3(a.x, 0, float(k) * cel)
			est_pos.append(p)
			est_s.append(a.distance_to(p))
		l["estaciones"] = est_pos
		l["est_s"] = est_s
		l["largo"] = largo
		l["dir"] = dir
		var col: Color = l["color"]
		if bool(l["elevada"]):
			_viaducto(a, b, col)
		else:
			_tunel_xray(a, b, col)
		for p: Vector3 in est_pos:
			if bool(l["elevada"]):
				_estacion_elevada(p, dir, col, String(l["nombre"]))
			_panel(p, l, est_s[est_pos.find(p)])
		var trenes: Array = []
		var nodos: Array = []
		for k in 3:
			var t := Tren.new(largo, est_s, largo * (float(k) + 0.5) / 3.0, 1.0 if k % 2 == 0 else -1.0)
			trenes.append(t)
			nodos.append(_tren(col, not bool(l["elevada"])))
		l["trenes"] = trenes
		l["nodos"] = nodos
	exp.lineas_metro = []
	for l: Dictionary in lineas:
		exp.lineas_metro.append({"nombre": l["nombre"], "color": l["color"], "estaciones": l["estaciones"], "elevada": l["elevada"]})

func alternar_rayos_x() -> bool:
	_xray.visible = not _xray.visible
	return _xray.visible

func _process(delta: float) -> void:
	for l: Dictionary in lineas:
		var a: Vector3 = l["a"]
		var dir: Vector3 = l["dir"]
		var y := ALTO_VIADUCTO + 1.0 if bool(l["elevada"]) else PROF_TUNEL
		for i in (l["trenes"] as Array).size():
			var t: Tren = l["trenes"][i]
			t.simular(delta)
			var n: Node3D = l["nodos"][i]
			n.position = a + dir * t.s + Vector3(0, y if bool(l["elevada"]) else 0.9, 0)
			n.rotation.y = atan2(dir.x, dir.z) + (0.0 if t.sentido > 0.0 else PI)
	_t_panel -= delta
	if _t_panel <= 0.0:
		_t_panel = 1.0
		for pa: Dictionary in _paneles:
			var mejor := INF
			for t: Tren in (pa["linea"] as Dictionary)["trenes"]:
				mejor = minf(mejor, t.eta(float(pa["s"])))
			var lab: Label3D = pa["label"]
			lab.text = "%s · próximo tren: %s" % [String((pa["linea"] as Dictionary)["nombre"]), "llegando" if mejor < 20.0 else "%d min" % int(ceil(mejor / 60.0))]

# ---------------------------------------------------------------- dibujo

func _mat(c: Color, rug := 0.6, emi := 0.0) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = rug
	if emi > 0.0:
		m.emission_enabled = true
		m.emission = c
		m.emission_energy_multiplier = emi
	return m

func _caja(padre: Node3D, pos: Vector3, tam: Vector3, m: Material) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = tam
	mi.mesh = bm
	mi.material_override = m
	mi.position = pos
	padre.add_child(mi)
	return mi

func _viaducto(a: Vector3, b: Vector3, col: Color) -> void:
	var hormigon := _mat(Color(0.72, 0.71, 0.68), 0.8)
	var largo := a.distance_to(b)
	var m := (a + b) * 0.5
	var vertical := absf(a.x - b.x) < 0.1
	_caja(self, m + Vector3(0, ALTO_VIADUCTO, 0), Vector3(7.0, 1.2, largo) if vertical else Vector3(largo, 1.2, 7.0), hormigon)
	## Pretiles con la franja del color de la línea.
	for lado: float in [-1.0, 1.0]:
		var off := Vector3(lado * 3.4, 0, 0) if vertical else Vector3(0, 0, lado * 3.4)
		_caja(self, m + off + Vector3(0, ALTO_VIADUCTO + 1.0, 0), Vector3(0.3, 1.0, largo) if vertical else Vector3(largo, 1.0, 0.3), _mat(col, 0.5))
	## Pilares cada 30 m (en la mediana de la avenida), en un MultiMesh.
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	var cm := CylinderMesh.new()
	cm.top_radius = 1.0
	cm.bottom_radius = 1.2
	cm.height = ALTO_VIADUCTO
	mm.mesh = cm
	var n := int(largo / 30.0)
	mm.instance_count = n
	for k in n:
		var p := a.lerp(b, (float(k) + 0.5) / float(n))
		mm.set_instance_transform(k, Transform3D(Basis(), p + Vector3(0, ALTO_VIADUCTO * 0.5, 0)))
	var mi := MultiMeshInstance3D.new()
	mi.multimesh = mm
	mi.material_override = hormigon
	add_child(mi)

func _estacion_elevada(p: Vector3, dir: Vector3, col: Color, nombre: String) -> void:
	var vertical := absf(dir.z) > 0.5
	var largo := 60.0
	var anden := Vector3(14.0, 0.8, largo) if vertical else Vector3(largo, 0.8, 14.0)
	_caja(self, p + Vector3(0, ALTO_VIADUCTO + 0.1, 0), anden, _mat(Color(0.82, 0.8, 0.76), 0.7))
	## Marquesina de cristal y pilares.
	var vidrio := StandardMaterial3D.new()
	vidrio.albedo_color = Color(0.7, 0.85, 0.95, 0.4)
	vidrio.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_caja(self, p + Vector3(0, ALTO_VIADUCTO + 5.5, 0), Vector3(15.0, 0.3, largo) if vertical else Vector3(largo, 0.3, 15.0), vidrio)
	for k in 4:
		for lado: float in [-1.0, 1.0]:
			var f := (float(k) / 3.0 - 0.5) * (largo - 6.0)
			var q := p + (Vector3(lado * 6.8, 0, f) if vertical else Vector3(f, 0, lado * 6.8))
			_caja(self, q + Vector3(0, ALTO_VIADUCTO + 3.0, 0), Vector3(0.4, 5.0, 0.4), _mat(col, 0.5))
	## Escaleras a las dos aceras.
	for lado2: float in [-1.0, 1.0]:
		var base := p + (Vector3(lado2 * 22.0, 0, largo * 0.35) if vertical else Vector3(largo * 0.35, 0, lado2 * 22.0))
		var esc := _caja(self, base + Vector3(0, ALTO_VIADUCTO * 0.5, 0) - (Vector3(lado2 * 7.0, 0, 0) if vertical else Vector3(0, 0, lado2 * 7.0)),
			Vector3(3.0, 0.5, sqrt(ALTO_VIADUCTO * ALTO_VIADUCTO + 16.0 * 16.0)) if not vertical else Vector3(sqrt(ALTO_VIADUCTO * ALTO_VIADUCTO + 16.0 * 16.0), 0.5, 3.0), _mat(Color(0.6, 0.6, 0.62), 0.6))
		if vertical:
			esc.rotation.z = atan2(ALTO_VIADUCTO, 16.0) * lado2
		else:
			esc.rotation.x = -atan2(ALTO_VIADUCTO, 16.0) * lado2
	var l := Label3D.new()
	l.text = "Ⓜ %s" % nombre
	l.font_size = 64
	l.pixel_size = 0.03
	l.modulate = Color.WHITE
	l.outline_size = 8
	l.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	l.position = p + Vector3(0, ALTO_VIADUCTO + 8.5, 0)
	add_child(l)

func _panel(p: Vector3, linea: Dictionary, s: float) -> void:
	var l := Label3D.new()
	l.font_size = 40
	l.pixel_size = 0.022
	l.modulate = Color(1.0, 0.85, 0.3)
	l.outline_size = 6
	l.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	l.no_depth_test = not bool(linea["elevada"])
	l.position = p + Vector3(0, ALTO_VIADUCTO + 6.8 if bool(linea["elevada"]) else 5.5, 0) + (Vector3(18, 0, 18) if not bool(linea["elevada"]) else Vector3.ZERO)
	add_child(l)
	_paneles.append({"label": l, "linea": linea, "s": s})

## El túnel en rayos X: un tubo translúcido que se ve a través del suelo.
func _tunel_xray(a: Vector3, b: Vector3, col: Color) -> void:
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(col.r * 1.3, col.g * 1.3, col.b * 1.3, 0.6)
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.no_depth_test = true
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	var largo := a.distance_to(b)
	var vertical := absf(a.x - b.x) < 0.1
	_caja(_xray, (a + b) * 0.5 + Vector3(0, 0.6, 0), Vector3(10.0, 0.4, largo) if vertical else Vector3(largo, 0.4, 10.0), m)

## Un tren de tres coches. `fantasma`: el de la línea subterránea, que solo se
## ve en rayos X (dibujado sobre todo, translúcido).
func _tren(col: Color, fantasma: bool) -> Node3D:
	var n := Node3D.new()
	var cuerpo := _mat(Color(0.92, 0.93, 0.95), 0.35)
	var franja := _mat(col, 0.4, 0.3)
	var ventana := _mat(Color(0.15, 0.2, 0.28), 0.1)
	if fantasma:
		for mm: StandardMaterial3D in [cuerpo, franja, ventana]:
			mm.no_depth_test = true
			mm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			mm.albedo_color.a = 0.85
			mm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	for k in 3:
		var z := (float(k) - 1.0) * 17.0
		_caja(n, Vector3(0, 1.8, z), Vector3(3.0, 3.4, 16.0), cuerpo)
		_caja(n, Vector3(0, 1.0, z), Vector3(3.05, 0.5, 16.05), franja)
		_caja(n, Vector3(0, 2.4, z), Vector3(3.08, 1.0, 14.0), ventana)
	if fantasma:
		_xray.add_child(n)
	else:
		add_child(n)
	return n
