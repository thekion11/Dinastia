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
	## CORREGIDO (7-10-2026): con «d > 0,5» el tren frenaba hasta quedar a
	## menos de medio metro, daba la estación por pasada y seguía sin parar
	## (el banco lo cazó: 0 paradas en 10 minutos). Ahora solo se descarta la
	## estación donde acaba de parar.
	var ultima_parada := -INF

	func proxima() -> float:
		var mejor := INF
		for e in estaciones:
			if absf(e - ultima_parada) < 0.01:
				continue
			var d := (e - s) * sentido
			if d > -0.01 and d < mejor:
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
		if paso >= dist or dist < 0.6:
			s = objetivo
			v = 0.0
			espera = PARADA
			paradas_hechas += 1
			ultima_parada = objetivo
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

## Los accesos para el personaje: {pie (calle), anden (donde aparece), linea, elevada}.

## LOS NOMBRES DE LAS ESTACIONES (de norte a sur / de oeste a este).
const NOMBRES := {
	"Línea 1": ["Alto Norte", "Mercado Este", "Cine", "Transbordo", "Hospital", "Ensanche", "Puerta Sur"],
	"Línea 2": ["Ribera Oeste", "Puerto", "Talleres", "Plaza Mayor", "Estación Central", "Ópera", "Transbordo"],
}
const ANDEN_LAT := 4.0      ## centro de cada andén lateral (a cada lado de la vía)
const ANDEN_ANCHO := 4.0
const ANDEN_LARGO := 60.0
const PISO_COCHE := 1.0     ## altura del suelo del coche sobre la vía

## Los accesos para el personaje: {pie (calle), anden (centro del andén), linea, idx, elevada, dir}.
var accesos: Array = []
var lineas: Array = []     ## [{nombre, color, a, b, elevada, estaciones, est_s, trenes, nodos, nodos_x}]
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
		var nombres: Array = NOMBRES[l["nombre"]]
		if bool(l["elevada"]):
			_viaducto(a, b, col)
		else:
			_tunel_xray(a, b, col)
			_tunel(a, b, est_pos, dir)
		for i in est_pos.size():
			var p: Vector3 = est_pos[i]
			if bool(l["elevada"]):
				_estacion_elevada(p, dir, col, String(nombres[i]), String(l["nombre"]), i)
			else:
				_estacion_subterranea(p, dir, col, String(nombres[i]), String(l["nombre"]), i)
			_decorar_estacion(p, dir, col, String(nombres[i]), bool(l["elevada"]))
			_panel(p, l, est_s[i])
		var trenes: Array = []
		var nodos: Array = []
		var nodos_x: Array = []
		for k in 3:
			var t := Tren.new(largo, est_s, largo * (float(k) + 0.5) / 3.0, 1.0 if k % 2 == 0 else -1.0)
			trenes.append(t)
			var real := _tren_real(col)
			add_child(real)
			nodos.append(real)
			if not bool(l["elevada"]):
				nodos_x.append(_tren_fantasma(col))
		l["trenes"] = trenes
		l["nodos"] = nodos
		l["nodos_x"] = nodos_x
	exp.lineas_metro = []
	for l: Dictionary in lineas:
		exp.lineas_metro.append({"nombre": l["nombre"], "color": l["color"], "estaciones": l["estaciones"], "elevada": l["elevada"]})
	## Accesos de la línea subterránea: las bocas de la acera (las dibuja
	## `CiudadExpansion._bocas_metro` en esta misma posición).
	var l2: Dictionary = lineas[1]
	for i in (l2["estaciones"] as Array).size():
		var p2: Vector3 = l2["estaciones"][i]
		var boca := p2 + Vector3(CiudadExpansion.ANCHO_AV * 0.5 + CiudadExpansion.ACERA + 3.0, 0, CiudadExpansion.ANCHO_AV * 0.5 + CiudadExpansion.ACERA + 3.0)
		accesos.append({"pie": boca, "anden": _centro_anden(l2, i), "linea": "Línea 2", "idx": i, "elevada": false,
			"nombre": String(NOMBRES["Línea 2"][i])})
	## Un tótem «Ⓜ» con el nombre en cada acceso de la calle.
	for acc: Dictionary in accesos:
		_totem(acc["pie"], String(acc["nombre"]), Color(0.85, 0.15, 0.15) if bool(acc["elevada"]) else Color(0.15, 0.4, 0.9))

## El centro del andén (lado +lateral) de la estación `i` de una línea, a la
## altura del suelo del andén.
func _centro_anden(l: Dictionary, i: int) -> Vector3:
	var p: Vector3 = l["estaciones"][i]
	var dir: Vector3 = l["dir"]
	var lat := Vector3(dir.z, 0, -dir.x).abs() if true else Vector3.ZERO
	var y := ALTO_VIADUCTO + 0.6 + PISO_COCHE if bool(l["elevada"]) else PROF_TUNEL + PISO_COCHE
	return p + lat * ANDEN_LAT + Vector3(0, y, 0)

func linea(nombre: String) -> Dictionary:
	for l: Dictionary in lineas:
		if String(l["nombre"]) == nombre:
			return l
	return {}

## Un tren detenido con las puertas abiertas en la estación `i` (o -1).
func tren_parado_en(nombre: String, i: int) -> int:
	var l := linea(nombre)
	if l.is_empty():
		return -1
	var s := float(l["est_s"][i])
	for k in (l["trenes"] as Array).size():
		var t: Tren = l["trenes"][k]
		if t.espera > 0.8 and absf(t.s - s) < 1.0:
			return k
	return -1

## La estación (índice) donde está parado el tren `k`, o -1 si va en marcha.
func estacion_del_tren(nombre: String, k: int) -> int:
	var l := linea(nombre)
	var t: Tren = l["trenes"][k]
	if t.espera <= 0.0:
		return -1
	for i in (l["est_s"] as PackedFloat32Array).size():
		if absf(t.s - float(l["est_s"][i])) < 1.0:
			return i
	return -1

## El nombre de la próxima estación del tren `k`.
func proxima_de(nombre: String, k: int) -> String:
	var l := linea(nombre)
	var t: Tren = l["trenes"][k]
	var obj := t.proxima()
	var est: PackedFloat32Array = l["est_s"]
	var mejor := 0
	for i in est.size():
		if absf(est[i] - obj) < absf(est[mejor] - obj):
			mejor = i
	if obj == INF:
		return String(NOMBRES[nombre][0 if t.sentido > 0.0 else est.size() - 1])
	return String(NOMBRES[nombre][mejor])

func eta_minima(nombre: String, i: int) -> float:
	var l := linea(nombre)
	var mejor := INF
	for t: Tren in l["trenes"]:
		mejor = minf(mejor, t.eta(float(l["est_s"][i])))
	return mejor

func alternar_rayos_x() -> bool:
	_xray.visible = not _xray.visible
	return _xray.visible

func _process(delta: float) -> void:
	for l: Dictionary in lineas:
		var a: Vector3 = l["a"]
		var dir: Vector3 = l["dir"]
		var y := ALTO_VIADUCTO + 0.6 if bool(l["elevada"]) else PROF_TUNEL
		for i in (l["trenes"] as Array).size():
			var t: Tren = l["trenes"][i]
			t.simular(delta)
			var n: Node3D = l["nodos"][i]
			n.position = a + dir * t.s + Vector3(0, y, 0)
			n.rotation.y = atan2(dir.x, dir.z) + (0.0 if t.sentido > 0.0 else PI)
			_puertas(n, t.espera > 0.8 and t.espera < PARADA - 0.4)
			if not (l["nodos_x"] as Array).is_empty():
				var g: Node3D = l["nodos_x"][i]
				g.position = a + dir * t.s + Vector3(0, 0.9, 0)
				g.rotation.y = n.rotation.y
	_t_panel -= delta
	if _t_panel <= 0.0:
		_t_panel = 1.0
		for pa: Dictionary in _paneles:
			var mejor := INF
			for t: Tren in (pa["linea"] as Dictionary)["trenes"]:
				mejor = minf(mejor, t.eta(float(pa["s"])))
			var lab: Label3D = pa["label"]
			lab.text = "%s · próximo tren: %s" % [String((pa["linea"] as Dictionary)["nombre"]), "llegando" if mejor < 20.0 else "%d min" % int(ceil(mejor / 60.0))]
		for l: Dictionary in lineas:
			for k in (l["trenes"] as Array).size():
				var led: Label3D = (l["nodos"][k] as Node3D).get_meta("led", null)
				if led != null:
					led.text = "%s  ▸  Próxima: %s" % [String(l["nombre"]), proxima_de(String(l["nombre"]), k)]

## Abre o cierra las puertas (paneles que se deslizan a lo largo del coche).
func _puertas(n: Node3D, abiertas: bool) -> void:
	for d: Array in n.get_meta("puertas", []):
		var nodo: Node3D = d[0]
		var base: Vector3 = d[1]
		var hacia: float = d[2]
		var obj := base + Vector3(0, 0, hacia * (0.75 if abiertas else 0.0))
		nodo.position = nodo.position.lerp(obj, 0.18)

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
	for lado: float in [-1.0, 1.0]:
		var off := Vector3(lado * 3.4, 0, 0) if vertical else Vector3(0, 0, lado * 3.4)
		_caja(self, m + off + Vector3(0, ALTO_VIADUCTO + 1.0, 0), Vector3(0.3, 1.0, largo) if vertical else Vector3(largo, 1.0, 0.3), _mat(col, 0.5))
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

## Estación elevada: DOS andenes laterales (la vía va por el medio), marquesina,
## pasarelas a las aceras y escaleras paralelas a la avenida.
func _estacion_elevada(p: Vector3, dir: Vector3, col: Color, nombre: String, linea_n: String, idx: int) -> void:
	var vertical := absf(dir.z) > 0.5
	var lat := Vector3(1, 0, 0) if vertical else Vector3(0, 0, 1)
	var lon := Vector3(0, 0, 1) if vertical else Vector3(1, 0, 0)
	var suelo := ALTO_VIADUCTO + 0.6 + PISO_COCHE
	## Gris de baldosa: con 0,8 el andén al sol salía blanco quemado (etapa 1).
	var losa: StandardMaterial3D = Texturas.hormigon(Color(0.6, 0.59, 0.56), 41)
	var borde := _mat(Color(0.95, 0.8, 0.1), 0.5)
	for lado: float in [-1.0, 1.0]:
		var c := p + lat * lado * ANDEN_LAT
		_caja(self, c + Vector3(0, suelo - 0.5, 0), (Vector3(ANDEN_ANCHO, 1.0, ANDEN_LARGO) if vertical else Vector3(ANDEN_LARGO, 1.0, ANDEN_ANCHO)), losa)
		## Franja amarilla del borde del andén.
		_caja(self, c - lat * lado * (ANDEN_ANCHO * 0.5 - 0.25) + Vector3(0, suelo + 0.01, 0), (Vector3(0.4, 0.02, ANDEN_LARGO) if vertical else Vector3(ANDEN_LARGO, 0.02, 0.4)), borde)
		for k in 3:
			var f := (float(k) - 1.0) * 18.0
			_banco(c + lon * f + lat * lado * 1.2 + Vector3(0, suelo, 0), vertical)
	var vidrio := StandardMaterial3D.new()
	vidrio.albedo_color = Color(0.7, 0.85, 0.95, 0.4)
	vidrio.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_caja(self, p + Vector3(0, suelo + 4.5, 0), Vector3(16.0, 0.3, ANDEN_LARGO) if vertical else Vector3(ANDEN_LARGO, 0.3, 16.0), vidrio)
	for k in 4:
		for lado: float in [-1.0, 1.0]:
			var f := (float(k) / 3.0 - 0.5) * (ANDEN_LARGO - 6.0)
			_caja(self, p + lat * lado * 5.8 + lon * f + Vector3(0, suelo + 2.2, 0), Vector3(0.4, 4.6, 0.4), _mat(col, 0.5))
	## Accesos: pasarela por encima de los carriles hasta la acera y escalera
	## bajando PARALELA a la avenida (no se mete en las manzanas).
	var gris := _mat(Color(0.6, 0.6, 0.62), 0.6)
	var baranda := _mat(col, 0.5)
	var subida := 22.0
	var alto := suelo
	for lado2: float in [-1.0, 1.0]:
		var x_acera := CiudadExpansion.ANCHO_AV * 0.5 + 2.0
		var z0 := ANDEN_LARGO * 0.5 - 2.0
		var x0 := ANDEN_LAT + ANDEN_ANCHO * 0.5
		var pas_c := p + lat * lado2 * (x0 + x_acera) * 0.5 + lon * z0 + Vector3(0, alto - 0.2, 0)
		_caja(self, pas_c, (Vector3(x_acera - x0 + 1.5, 0.4, 3.0) if vertical else Vector3(3.0, 0.4, x_acera - x0 + 1.5)), gris)
		var largo_e := sqrt(subida * subida + alto * alto)
		var esc_c := p + lat * lado2 * x_acera + lon * (z0 + 1.5 + subida * 0.5) + Vector3(0, alto * 0.5, 0)
		var esc := _caja(self, esc_c, Vector3(3.0, 0.4, largo_e) if vertical else Vector3(largo_e, 0.4, 3.0), gris)
		var ang := atan2(alto, subida)
		if vertical:
			esc.rotation.x = ang
		else:
			esc.rotation.z = -ang
		for lb: float in [-1.6, 1.6]:
			var bar := _caja(self, esc_c + lat * lb + Vector3(0, 1.0, 0), Vector3(0.1, 0.1, largo_e) if vertical else Vector3(largo_e, 0.1, 0.1), baranda)
			bar.rotation = esc.rotation
		var pie := p + lat * lado2 * x_acera + lon * (z0 + 1.5 + subida + 1.5)
		accesos.append({"pie": Vector3(pie.x, 0.0, pie.z), "anden": p + lat * lado2 * ANDEN_LAT + lon * (ANDEN_LARGO * 0.5 - 5.0) + Vector3(0, suelo, 0),
			"linea": linea_n, "idx": idx, "elevada": true, "nombre": nombre, "lado": lado2})
	var l := Label3D.new()
	l.text = "Ⓜ %s" % nombre
	l.font_size = 64
	l.pixel_size = 0.03
	l.modulate = Color.WHITE
	l.outline_size = 8
	l.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	l.position = p + Vector3(0, suelo + 7.5, 0)
	add_child(l)

## LA DECORACIÓN DE CADA ESTACIÓN (7-10-2026, «el metro debe tener
## decoraciones por estación, nombre de estación»): cada una tiene su tema
## -un icono y un color- en un mural a lo largo del andén, más lo que trae
## cualquier estación de verdad: plano de la red, máquinas de billetes, una
## expendedora, reloj, papeleras y jardineras.
const TEMAS := {
	"Alto Norte": ["⛰️", Color(0.45, 0.6, 0.8), "Las cumbres del norte"],
	"Mercado Este": ["🍊", Color(0.95, 0.6, 0.2), "Frutas y mercados"],
	"Cine": ["🎬", Color(0.25, 0.25, 0.3), "Cien años de cine"],
	"Transbordo": ["🔁", Color(0.6, 0.3, 0.7), "Líneas 1 y 2"],
	"Hospital": ["➕", Color(0.3, 0.7, 0.5), "Salud y cuidado"],
	"Ensanche": ["🏘️", Color(0.85, 0.7, 0.45), "La ciudad que crece"],
	"Puerta Sur": ["🚪", Color(0.7, 0.4, 0.3), "La antigua muralla"],
	"Ribera Oeste": ["🌊", Color(0.25, 0.55, 0.75), "El río y sus orillas"],
	"Puerto": ["⚓", Color(0.15, 0.3, 0.55), "Barcos y remeros"],
	"Talleres": ["⚙️", Color(0.5, 0.5, 0.52), "Oficios de la ciudad"],
	"Plaza Mayor": ["🏛️", Color(0.8, 0.65, 0.4), "El corazón del barrio"],
	"Estación Central": ["🕰️", Color(0.55, 0.35, 0.25), "Trenes de toda la vida"],
	"Ópera": ["🎭", Color(0.6, 0.15, 0.25), "Música y teatro"],
}

func _decorar_estacion(p: Vector3, dir: Vector3, col: Color, nombre: String, elevada: bool) -> void:
	var vertical := absf(dir.z) > 0.5
	var lat := Vector3(1, 0, 0) if vertical else Vector3(0, 0, 1)
	var lon := Vector3(0, 0, 1) if vertical else Vector3(1, 0, 0)
	var tema: Array = TEMAS.get(nombre, ["Ⓜ", col, ""])
	var tcol: Color = tema[1]
	var y := (ALTO_VIADUCTO + 0.6 + PISO_COCHE) if elevada else (PROF_TUNEL + PISO_COCHE)
	## Lado del andén donde va el mural: en la subterránea, la pared del fondo
	## del vestíbulo; en la elevada, un panel en cada andén (de espaldas a la vía).
	var lados: Array = [1.0, -1.0] if elevada else [1.0]
	for lado: float in lados:
		var fondo := p + lat * lado * ((ANDEN_LAT + ANDEN_ANCHO * 0.5 - 0.15) if elevada else (2.0 + 8.0 - 0.45))
		var hacia := -lat * lado
		## El mural: tres paneles del color del tema con el icono y el lema.
		for k in 3:
			var c := fondo + lon * (float(k) - 1.0) * 16.0 + Vector3(0, y + (1.7 if elevada else 2.4), 0)
			_caja(self, c, (Vector3(0.12, 2.6 if elevada else 3.2, 10.0) if vertical else Vector3(10.0, 2.6 if elevada else 3.2, 0.12)), _mat(tcol, 0.6, 0.15))
			var ico := Label3D.new()
			ico.text = String(tema[0]) if k != 1 else "%s\n%s" % [nombre, String(tema[2])]
			## Más contenido: con 0,011 el lema llenaba la ventana del tren.
			ico.font_size = 120 if k != 1 else 54
			ico.pixel_size = 0.009 if k != 1 else 0.0075
			ico.outline_size = 10
			ico.outline_modulate = tcol.darkened(0.5)
			ico.position = c + hacia * 0.1
			ico.rotation.y = atan2(hacia.x, hacia.z)
			ico.visibility_range_end = 90.0
			add_child(ico)
		## Plano de la red: un panel blanco con las dos líneas y sus estaciones.
		var pl := fondo + lon * 24.0 + Vector3(0, y + 1.6, 0) + hacia * 0.05
		_caja(self, pl, (Vector3(0.1, 1.8, 2.6) if vertical else Vector3(2.6, 1.8, 0.1)), _mat(Color(0.96, 0.96, 0.94), 0.6))
		## Marco y trasera oscuros: por detrás era una placa blanca lisa.
		_caja(self, pl - hacia * 0.06, (Vector3(0.06, 1.95, 2.75) if vertical else Vector3(2.75, 1.95, 0.06)), _mat(Color(0.18, 0.2, 0.24), 0.5))
		var plano := Label3D.new()
		plano.text = "PLANO DE LA RED\n🔴 L1: %s\n🔵 L2: %s\n\nUsted está en: %s" % [" · ".join(NOMBRES["Línea 1"]), " · ".join(NOMBRES["Línea 2"]), nombre]
		plano.font_size = 22
		plano.pixel_size = 0.0045
		plano.modulate = Color(0.1, 0.1, 0.15)
		plano.outline_size = 0
		plano.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		plano.width = 520.0
		plano.position = pl + hacia * 0.07
		plano.rotation.y = atan2(hacia.x, hacia.z)
		plano.visibility_range_end = 40.0
		add_child(plano)
		## Máquinas de billetes y una expendedora junto al plano.
		for k in 2:
			var mq := fondo + lon * (-24.0 - float(k) * 1.4) + hacia * 0.5 + Vector3(0, y + 0.9, 0)
			_caja(self, mq, Vector3(0.7, 1.8, 1.0) if vertical else Vector3(1.0, 1.8, 0.7), _mat(Color(0.2, 0.22, 0.25), 0.4))
			_caja(self, mq + hacia * 0.36 + Vector3(0, 0.3, 0), Vector3(0.02, 0.5, 0.6) if vertical else Vector3(0.6, 0.5, 0.02), _mat(Color(0.3, 0.7, 1.0), 0.2, 1.2))
		var exp_c := fondo + lon * -28.0 + hacia * 0.5 + Vector3(0, y + 0.95, 0)
		_caja(self, exp_c, Vector3(0.8, 1.9, 1.1) if vertical else Vector3(1.1, 1.9, 0.8), _mat(Color(0.8, 0.12, 0.12), 0.4))
		_caja(self, exp_c + hacia * 0.41 + Vector3(0, 0.2, 0), Vector3(0.02, 1.1, 0.8) if vertical else Vector3(0.8, 1.1, 0.02), _mat(Color(0.95, 0.9, 0.6), 0.2, 0.6))
		## Jardineras y papeleras a lo largo del andén.
		for k in 4:
			var jd := fondo + lon * ((float(k) - 1.5) * 13.0 + 6.0) + hacia * 0.7 + Vector3(0, y + 0.35, 0)
			_caja(self, jd, Vector3(0.9, 0.7, 0.9), _mat(Color(0.45, 0.42, 0.4), 0.8))
			var mata := MeshInstance3D.new()
			var sm := SphereMesh.new()
			sm.radius = 0.6
			sm.height = 1.0
			mata.mesh = sm
			mata.material_override = _mat(Color(0.2, 0.5, 0.22), 0.9)
			mata.position = jd + Vector3(0, 0.75, 0)
			add_child(mata)
		## El reloj de la estación, colgado.
		var rl := fondo + lon * 8.0 + hacia * 1.5 + Vector3(0, y + 3.3, 0)
		var reloj := MeshInstance3D.new()
		var cm := CylinderMesh.new()
		cm.top_radius = 0.45
		cm.bottom_radius = 0.45
		cm.height = 0.1
		reloj.mesh = cm
		reloj.material_override = _mat(Color.WHITE, 0.4, 0.3)
		reloj.position = rl
		reloj.rotation = Vector3(PI * 0.5, atan2(hacia.x, hacia.z), 0)
		add_child(reloj)

## El tótem de la boca: poste alto con la «Ⓜ» y el nombre de la estación.
func _totem(pie: Vector3, nombre: String, col: Color) -> void:
	_caja(self, pie + Vector3(1.8, 2.2, 1.8), Vector3(0.18, 4.4, 0.18), _mat(Color(0.25, 0.25, 0.28), 0.4))
	_caja(self, pie + Vector3(1.8, 4.7, 1.8), Vector3(0.9, 0.9, 0.9), _mat(col, 0.4, 0.6))
	var l := Label3D.new()
	l.text = "Ⓜ\n%s" % nombre
	l.font_size = 40
	l.pixel_size = 0.005
	l.outline_size = 8
	l.outline_modulate = col.darkened(0.5)
	l.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	l.position = pie + Vector3(1.8, 5.9, 1.8)
	l.visibility_range_end = 220.0
	add_child(l)

func _banco(p: Vector3, vertical: bool) -> void:
	var madera := _mat(Color(0.5, 0.35, 0.2), 0.7)
	_caja(self, p + Vector3(0, 0.45, 0), Vector3(0.5, 0.1, 2.2) if vertical else Vector3(2.2, 0.1, 0.5), madera)

## El túnel de la línea subterránea: cerrado (suelo, paredes, techo) para que
## desde dentro no se vea el cielo, con luces cada 30 m. Se corta en las
## estaciones, que tienen su propio vestíbulo.
func _tunel(a: Vector3, b: Vector3, estaciones: Array, dir: Vector3) -> void:
	var muro := _mat(Color(0.32, 0.32, 0.34), 0.95)
	var luz := _mat(Color(1.0, 0.92, 0.7), 0.4, 2.0)
	var vertical := absf(dir.z) > 0.5
	var lat := Vector3(1, 0, 0) if vertical else Vector3(0, 0, 1)
	var cortes: Array = [0.0]
	for p: Vector3 in estaciones:
		var s := a.distance_to(p)
		cortes.append(s - ANDEN_LARGO * 0.5 - 2.0)
		cortes.append(s + ANDEN_LARGO * 0.5 + 2.0)
	cortes.append(a.distance_to(b))
	var luces: Array[Transform3D] = []
	for k in range(0, cortes.size() - 1, 2):
		var s0 := float(cortes[k])
		var s1 := float(cortes[k + 1])
		if s1 - s0 < 1.0:
			continue
		var c := a + dir * (s0 + s1) * 0.5
		var largo := s1 - s0
		var y := PROF_TUNEL
		_caja(self, c + Vector3(0, y - 0.3, 0), (Vector3(8.0, 0.6, largo) if vertical else Vector3(largo, 0.6, 8.0)), muro)
		_caja(self, c + Vector3(0, y + 5.5, 0), (Vector3(8.0, 0.6, largo) if vertical else Vector3(largo, 0.6, 8.0)), muro)
		for lado: float in [-1.0, 1.0]:
			_caja(self, c + lat * lado * 3.8 + Vector3(0, y + 2.6, 0), (Vector3(0.4, 5.6, largo) if vertical else Vector3(largo, 5.6, 0.4)), muro)
		var n := int(largo / 30.0)
		for q in n:
			var pl := a + dir * (s0 + (float(q) + 0.5) * largo / float(maxi(n, 1)))
			luces.append(Transform3D(Basis.from_scale(Vector3(0.4, 0.15, 1.6) if vertical else Vector3(1.6, 0.15, 0.4)), pl + lat * 3.4 + Vector3(0, y + 4.6, 0)))
	if not luces.is_empty():
		var mm := MultiMesh.new()
		mm.transform_format = MultiMesh.TRANSFORM_3D
		mm.mesh = BoxMesh.new()
		mm.instance_count = luces.size()
		for i in luces.size():
			mm.set_instance_transform(i, luces[i])
		var mi := MultiMeshInstance3D.new()
		mi.multimesh = mm
		mi.material_override = luz
		add_child(mi)

## Estación subterránea: vestíbulo alicatado con el andén a un lado, bancos,
## carteles con el nombre, luces y el panel del próximo tren.
func _estacion_subterranea(p: Vector3, dir: Vector3, col: Color, nombre: String, linea_n: String, idx: int) -> void:
	var vertical := absf(dir.z) > 0.5
	var lat := Vector3(1, 0, 0) if vertical else Vector3(0, 0, 1)
	var lon := Vector3(0, 0, 1) if vertical else Vector3(1, 0, 0)
	var y := PROF_TUNEL
	var largo := ANDEN_LARGO + 4.0
	var ancho := 16.0
	var azulejo := _mat(Color(0.7, 0.72, 0.74), 0.5)
	var franja := _mat(col, 0.4, 0.3)
	var suelo_m := _mat(Color(0.45, 0.45, 0.47), 0.8)
	var c := p + lat * 2.0
	_caja(self, c + Vector3(0, y - 0.3, 0), (Vector3(ancho, 0.6, largo) if vertical else Vector3(largo, 0.6, ancho)), suelo_m)
	_caja(self, c + Vector3(0, y + 6.5, 0), (Vector3(ancho, 0.6, largo) if vertical else Vector3(largo, 0.6, ancho)), azulejo)
	for lado: float in [-1.0, 1.0]:
		var pared := c + lat * lado * ancho * 0.5 + Vector3(0, y + 3.1, 0)
		_caja(self, pared, (Vector3(0.4, 6.8, largo) if vertical else Vector3(largo, 6.8, 0.4)), azulejo)
		_caja(self, pared - lat * lado * 0.21 + Vector3(0, -1.2, 0), (Vector3(0.05, 0.6, largo) if vertical else Vector3(largo, 0.6, 0.05)), franja)
		var cart := Label3D.new()
		cart.text = "Ⓜ  %s" % nombre
		cart.font_size = 72
		cart.pixel_size = 0.02
		cart.modulate = Color.WHITE
		cart.outline_size = 6
		cart.outline_modulate = col.darkened(0.4)
		cart.position = pared - lat * lado * 0.3 + Vector3(0, 0.6, 0)
		cart.rotation.y = atan2(-lat.x * lado, -lat.z * lado)
		add_child(cart)
	for e: float in [-1.0, 1.0]:
		_caja(self, c + lon * e * largo * 0.5 + Vector3(0, y + 3.1, 0), (Vector3(ancho, 6.8, 0.4) if vertical else Vector3(0.4, 6.8, ancho)), azulejo)
	## El andén (lado +lateral), con su borde amarillo y bancos.
	var ca := p + lat * ANDEN_LAT * 1.6
	_caja(self, ca + Vector3(0, y + PISO_COCHE - 0.5, 0), (Vector3(ANDEN_ANCHO * 2.2, 1.0, ANDEN_LARGO) if vertical else Vector3(ANDEN_LARGO, 1.0, ANDEN_ANCHO * 2.2)), _mat(Color(0.56, 0.55, 0.52), 0.75))
	_caja(self, p + lat * (ANDEN_LAT * 1.6 - ANDEN_ANCHO * 1.1 + 0.25) + Vector3(0, y + PISO_COCHE + 0.01, 0), (Vector3(0.4, 0.02, ANDEN_LARGO) if vertical else Vector3(ANDEN_LARGO, 0.02, 0.4)), _mat(Color(0.95, 0.8, 0.1), 0.5))
	for k in 3:
		_banco(ca + lon * (float(k) - 1.0) * 18.0 + lat * 3.0 + Vector3(0, y + PISO_COCHE, 0), vertical)
	## Luces del vestíbulo: tiras y dos focos de verdad.
	for k in 4:
		_caja(self, c + lon * (float(k) - 1.5) * 15.0 + Vector3(0, y + 6.1, 0), Vector3(1.2, 0.1, 6.0) if vertical else Vector3(6.0, 0.1, 1.2), _mat(Color(1, 0.97, 0.9), 0.3, 2.5))
	for f: float in [-0.25, 0.25]:
		var o := OmniLight3D.new()
		o.omni_range = 30.0
		o.light_energy = 0.7
		o.position = c + lon * f * largo + Vector3(0, y + 5.0, 0)
		add_child(o)
	var panel := Label3D.new()
	panel.font_size = 32
	panel.pixel_size = 0.006
	panel.modulate = Color(1.0, 0.85, 0.3)
	panel.outline_size = 6
	panel.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	panel.position = ca + lon * 12.0 + Vector3(0, y + PISO_COCHE + 2.6, 0)
	add_child(panel)
	_paneles.append({"label": panel, "linea_n": linea_n, "s": a_s(linea_n, idx), "pend": true})

func a_s(_n: String, _i: int) -> float:
	return 0.0

func _panel(p: Vector3, linea: Dictionary, s: float) -> void:
	## Arreglo de los paneles subterráneos creados antes de tener la línea.
	for pa: Dictionary in _paneles:
		if pa.has("pend") and String(pa["linea_n"]) == String(linea["nombre"]) and not pa.has("linea"):
			pa["linea"] = linea
			pa["s"] = s
			pa.erase("pend")
			return
	var l := Label3D.new()
	l.font_size = 40
	l.pixel_size = 0.022
	l.modulate = Color(1.0, 0.85, 0.3)
	l.outline_size = 6
	l.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	l.position = p + Vector3(0, ALTO_VIADUCTO + 8.6, 0)
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

## El tren de verdad: tres coches HUECOS con su interior (asientos, barras,
## asideros, luces, ventanas, puertas que se abren) y un panel LED con la
## próxima estación. Se ve desde fuera por las ventanas y se puede viajar dentro.
func _tren_real(col: Color) -> Node3D:
	var n := Node3D.new()
	var blanco := _mat(Color(0.93, 0.94, 0.96), 0.35)
	var franja := _mat(col, 0.4, 0.2)
	var vidrio := StandardMaterial3D.new()
	vidrio.albedo_color = Color(0.6, 0.75, 0.85, 0.22)
	vidrio.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	vidrio.roughness = 0.05
	var asiento := _mat(col.darkened(0.3), 0.7)
	var metal := _mat(Color(0.75, 0.76, 0.78), 0.25)
	metal.metallic = 0.8
	var luz := _mat(Color(1, 0.97, 0.9), 0.3, 1.1)
	var suelo := _mat(Color(0.3, 0.3, 0.32), 0.9)
	var puerta_m := _mat(Color(0.82, 0.84, 0.86), 0.3)
	var puertas: Array = []
	var f := PISO_COCHE
	for k in 3:
		var z := (float(k) - 1.0) * 16.6
		_caja(n, Vector3(0, f - 0.3, z), Vector3(3.0, 0.6, 16.0), blanco)          ## bastidor
		_caja(n, Vector3(0, f + 0.02, z), Vector3(2.9, 0.04, 15.9), suelo)
		_caja(n, Vector3(0, f + 2.65, z), Vector3(3.0, 0.15, 16.0), blanco)        ## techo
		for lado: float in [-1.0, 1.0]:
			var x := lado * 1.45
			_caja(n, Vector3(x, f + 0.45, z), Vector3(0.1, 0.9, 16.0), blanco)       ## panel bajo
			_caja(n, Vector3(x * 1.04, f + 0.35, z), Vector3(0.02, 0.25, 16.0), franja)
			_caja(n, Vector3(x, f + 2.4, z), Vector3(0.1, 0.4, 16.0), blanco)        ## sobre ventanas
			_caja(n, Vector3(x, f + 1.55, z), Vector3(0.04, 1.3, 16.0), vidrio)      ## ventanas
			for q in 8:
				_caja(n, Vector3(x, f + 1.55, z - 7.0 + float(q) * 2.0), Vector3(0.12, 1.3, 0.18), blanco)
			## Asientos laterales entre puertas, con respaldo.
			for tramo: Array in [[-6.0, 3.0], [0.0, 5.0], [6.0, 3.0]]:
				_caja(n, Vector3(lado * 1.1, f + 0.45, z + float(tramo[0])), Vector3(0.55, 0.12, float(tramo[1])), asiento)
				_caja(n, Vector3(lado * 1.35, f + 0.8, z + float(tramo[0])), Vector3(0.1, 0.6, float(tramo[1])), asiento)
			## Puertas: dos por lado; se deslizan al abrir.
			for dz: float in [-3.5, 3.5]:
				for hoja: float in [-1.0, 1.0]:
					var base := Vector3(x * 1.03, f + 1.15, z + dz + hoja * 0.37)
					var p := _caja(n, base, Vector3(0.06, 2.2, 0.72), puerta_m)
					puertas.append([p, base, hoja])
		## Barras y asideros.
		for q in 5:
			var b := MeshInstance3D.new()
			var cm := CylinderMesh.new()
			cm.top_radius = 0.03
			cm.bottom_radius = 0.03
			cm.height = 2.6
			b.mesh = cm
			b.material_override = metal
			b.position = Vector3(0, f + 1.3, z - 6.0 + float(q) * 3.0)
			n.add_child(b)
		for lado3: float in [-0.55, 0.55]:
			_caja(n, Vector3(lado3, f + 2.25, z), Vector3(0.04, 0.04, 15.0), metal)
		_caja(n, Vector3(0, f + 2.55, z), Vector3(0.5, 0.05, 15.0), luz)
		## Testeros con ventana (los extremos del coche).
		for e: float in [-1.0, 1.0]:
			_caja(n, Vector3(0, f + 1.3, z + e * 8.0), Vector3(3.0, 2.6, 0.1), blanco)
	## Panel LED en el testero delantero del primer coche.
	var led := Label3D.new()
	led.font_size = 36
	led.pixel_size = 0.006
	led.modulate = Color(1.0, 0.6, 0.1)
	led.position = Vector3(0, f + 2.25, 16.6 + 7.9)
	led.rotation.y = PI
	n.add_child(led)
	n.set_meta("led", led)
	n.set_meta("puertas", puertas)
	return n

## El tren «fantasma» de la línea subterránea: solo se ve en rayos X.
func _tren_fantasma(col: Color) -> Node3D:
	var n := Node3D.new()
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(col.r, col.g, col.b, 0.85)
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.no_depth_test = true
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	for k in 3:
		_caja(n, Vector3(0, 1.8, (float(k) - 1.0) * 17.0), Vector3(3.0, 3.4, 16.0), m)
	_xray.add_child(n)
	return n
