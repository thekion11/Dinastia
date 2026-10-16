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
			## Las pantallas colgadas del andén, a su línea y su estación.
			for pa: Dictionary in _paneles:
				if pa.has("pantalla") and not pa.has("linea"):
					pa["linea"] = l
					pa["s"] = est_s[i]
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
	_gente_cerca(delta)
	_embarques(delta)
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
			var cuando := "llegando" if mejor < 20.0 else "%d min" % int(ceil(mejor / 60.0))
			if pa.has("pantalla"):
				lab.text = "%s · %s\nPróximo tren: %s" % [String((pa["linea"] as Dictionary)["nombre"]), String(pa["est"]), cuando]
			else:
				lab.text = "%s · próximo tren: %s" % [String((pa["linea"] as Dictionary)["nombre"]), cuando]
		for l: Dictionary in lineas:
			for k in (l["trenes"] as Array).size():
				## Parado en una estación dice dónde está (antes decía «Próxima:
				## Cine» estando ya en Cine).
				var aqui := estacion_del_tren(String(l["nombre"]), k)
				var txt := "%s\n%s" % [String(l["nombre"]), ("Estación: %s" % String(NOMBRES[l["nombre"]][aqui])) if aqui >= 0 else ("Próxima: %s" % proxima_de(String(l["nombre"]), k))]
				for led: Label3D in (l["nodos"][k] as Node3D).get_meta("leds", []):
					led.text = txt

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
		## Los bancos, papeleras y máquinas los pone `_amueblar_anden` (kit de Kenney).
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
	## Por encima del panel del próximo tren (ALTO_VIADUCTO + 8,6): a +7,5 los
	## dos rótulos se pisaban.
	l.position = p + Vector3(0, suelo + 9.4, 0)
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
			## Los paneles de los lados repiten el NOMBRE (como en un metro de
			## verdad, se lee desde la ventana del tren); el icono-emoji no se
			## dibujaba (la fuente no lo tiene) y el panel quedaba vacío.
			ico.text = ("Ⓜ %s" % nombre) if k != 1 else "%s\n%s" % [nombre, String(tema[2])]
			## Más contenido: con 0,011 el lema llenaba la ventana del tren.
			ico.font_size = 64 if k != 1 else 54
			ico.pixel_size = 0.0085 if k != 1 else 0.0075
			ico.width = 1000.0
			ico.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
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
		## Máquinas, bancos, papeleras, plantas y pantallas (kit de Kenney), y
		## los sitios donde espera la gente.
		_amueblar_anden(p, fondo, hacia, lon, y, nombre, col, elevada)
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

# ------------------------------------------------- andenes vivos (15-10-2026)
## «A ese nivel debe estar todo en la ciudad» (los kits de Kenney): los andenes
## estaban vacíos (un banco-tabla y jardineras de caja con una esfera). Ahora
## llevan piezas del kit (CC0) a escala real y GENTE ESPERANDO, de pie y
## sentada. La gente solo existe en la estación junto a la cámara (`_process`).

const KENNEY := "res://assets/kenney/"
## pieza -> escala (medidas en EVALUACION_KENNEY_CIUDAD.md: arcade ×2,4-2,5;
## muebles ×2; montaña rusa ×2-2,2).
const PIEZAS_ANDEN := {
	"expendedora": ["mini_arcade/vending-machine", 2.5],     ## 1,25 × 1,9 m
	"billetes": ["mini_arcade/ticket-machine", 2.0],         ## 0,8 × 1,85 m
	"banco": ["montana_rusa/bench", 2.0],                    ## 1,6 m de largo
	"papelera": ["montana_rusa/trash", 1.9],                 ## 0,8 m de alto
	"planta": ["muebles/pottedPlant", 2.6],                  ## 1,7 m de alto
}
## Altura y fondo del asiento del banco a la escala de arriba (medidos en la
## captura: asiento a 0,45 m; el centro del asiento, 0,1 m por delante del origen).
const BANCO_ASIENTO := 0.45
const BANCO_FONDO := 0.15
const RADIO_GENTE := 75.0   ## a esta distancia de la cámara se llena el andén

static var _escenas := {}
var _sitios: Array = []     ## [{centro, clave, sitios: [{p, giro, sentado, pareja}]}]
var _gente_clave := ""
var _gente: Node3D
var _cola_gente: Array = []
var _fijos_gente: Array = []
var _t_gente := 0.0
var _rng_gente := RandomNumberGenerator.new()

## Una pieza del kit, a escala, mirando hacia `mira` (su +Z), y con
## distancia de dibujo para no cargar la ciudad.
func _kenney(clave: String, pos: Vector3, mira: Vector3, padre: Node3D = null, rango: float = 140.0) -> Node3D:
	var info: Array = PIEZAS_ANDEN[clave]
	var ruta := KENNEY + String(info[0]) + ".glb"
	if not _escenas.has(ruta):
		_escenas[ruta] = load(ruta) if ResourceLoader.exists(ruta) else null
	var ps: PackedScene = _escenas[ruta]
	if ps == null:
		return null
	var n: Node3D = ps.instantiate()
	n.scale = Vector3.ONE * float(info[1])
	n.position = pos
	n.rotation.y = atan2(mira.x, mira.z)
	for mi: MeshInstance3D in n.find_children("*", "MeshInstance3D", true, false):
		mi.visibility_range_end = rango
	(padre if padre != null else self).add_child(n)
	return n

## Amuebla un andén. `fondo`: punto de la pared del fondo a la altura 0;
## `hacia`: de la pared hacia la vía; `y`: altura del suelo del andén.
## Medidas (desde la pared): bancos a 0,6 m, papeleras y plantas a 0,5 m; la
## gente de pie, a 1,8-2,6 m de la franja amarilla. Nada en los pilares de la
## marquesina (±9 y ±27 a lo largo) ni en la llegada de la escalera (+25..+30).
func _amueblar_anden(p: Vector3, fondo: Vector3, hacia: Vector3, lon: Vector3, y: float, nombre: String, col: Color, elevada: bool) -> void:
	var base := fondo + Vector3(0, y, 0)
	var en := func(db: float, f: float) -> Vector3: return base + hacia * db + lon * f
	## Hasta el borde del andén (franja amarilla incluida).
	var ancho := (ANDEN_ANCHO - 0.15) if elevada else (2.0 + 8.0 - 0.45 - 2.0)
	var sitios: Array = []
	## Máquinas de billetes y expendedora, al lado del plano de la red.
	_kenney("expendedora", en.call(0.65, -25.6), hacia)
	_kenney("billetes", en.call(0.5, -23.6), hacia)
	_kenney("billetes", en.call(0.5, -22.6), hacia)
	## Bancos de espaldas a la pared, papeleras entre ellos y plantas grandes.
	for f: float in [-12.0, -4.0, 4.0, 12.0]:
		## El banco del kit mira a su -Z (el respaldo queda en +Z): de espaldas a
		## la pared hay que girarlo hacia la pared.
		_kenney("banco", en.call(0.6, f), -hacia)
		for s: float in [-0.42, 0.42]:
			sitios.append({"p": en.call(0.6 + BANCO_FONDO, f + s), "giro": atan2(hacia.x, hacia.z), "sentado": true})
	for f: float in [-8.0, 8.0]:
		_kenney("papelera", en.call(0.45, f), hacia)
	for f: float in [-19.6, 19.6]:
		_kenney("planta", en.call(0.45, f), hacia)
	if not elevada:
		_kenney("planta", en.call(0.45, -29.0), hacia)
		_kenney("papelera", en.call(0.45, 27.0), hacia)
	## Pantallas del próximo tren colgadas del techo, de dos caras (una mira a
	## cada punta del andén).
	var techo := (y + 4.35) if elevada else (PROF_TUNEL + 6.2)
	for f: float in [-6.0, 14.0]:
		var c: Vector3 = en.call(ancho * 0.45, f)
		var alto_p := y + 2.75
		## Caja negra con dos pantallas (la tele del kit traía su pie de mesa).
		_caja(self, Vector3(c.x, alto_p + 0.45, c.z), _tam_lon(lon, Vector3(1.5, 0.82, 0.16)), _mat(Color(0.08, 0.08, 0.09), 0.4))
		for s: float in [-1.0, 1.0]:
			_caja(self, Vector3(c.x, alto_p + 0.45, c.z) + lon * s * 0.085, _tam_lon(lon, Vector3(1.36, 0.68, 0.01)), _mat(Color(0.05, 0.1, 0.22), 0.2, 0.6))
			var lab := Label3D.new()
			lab.font_size = 28
			lab.pixel_size = 0.0042
			lab.modulate = Color(1.0, 0.78, 0.25)
			lab.outline_size = 0
			lab.double_sided = false
			lab.width = 300.0
			lab.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			lab.position = Vector3(c.x, alto_p + 0.45, c.z) + lon * s * 0.1
			lab.rotation.y = atan2(lon.x * s, lon.z * s)
			lab.visibility_range_end = 60.0
			add_child(lab)
			_paneles.append({"label": lab, "linea_n": "", "s": 0.0, "pantalla": true, "est": nombre, "elevada": elevada})
		## Las varillas que la cuelgan.
		for s2: float in [-0.45, 0.45]:
			var lado_v := hacia.cross(Vector3.UP).normalized()
			var largo_v := techo - (alto_p + 0.86)
			_caja(self, Vector3(c.x, alto_p + 0.86 + largo_v * 0.5, c.z) + lado_v * s2, Vector3(0.04, largo_v, 0.04), _mat(Color(0.3, 0.3, 0.32), 0.4))
	## Gente de pie esperando: cerca del borde (sin pisar la franja), unos
	## sueltos mirando a la vía y algunas parejas charlando.
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(nombre) + (7 if elevada else 0) + int(absf(fondo.x) + absf(fondo.z))
	var usados: Array = []
	for k in 7:
		var f := rng.randf_range(-24.0, 22.0)
		for _intento in 6:
			var libre := true
			for u: float in usados:
				if absf(u - f) < 2.2:
					libre = false
			if libre:
				break
			f = rng.randf_range(-24.0, 22.0)
		usados.append(f)
		## Ni delante de la escalera ni pegados a las pantallas.
		var db := ancho - rng.randf_range(1.0, 1.9)
		var giro := atan2(hacia.x, hacia.z) + rng.randf_range(-0.5, 0.5)
		if k % 3 == 2:
			## Pareja: dos de cara, a 0,9 m.
			var g2 := atan2(lon.x, lon.z)
			sitios.append({"p": en.call(db, f - 0.45), "giro": g2, "sentado": false, "charla": true})
			sitios.append({"p": en.call(db, f + 0.45), "giro": g2 + PI, "sentado": false, "charla": true})
		else:
			sitios.append({"p": en.call(db, f), "giro": giro, "sentado": false})
	## La salida del andén (la llegada de la escalera, +25..+30 a lo largo):
	## por ahí se van los que bajan del tren y llegan los que vienen a esperar.
	var centro: Vector3 = base + hacia * (ancho * 0.5)
	_sitios.append({"centro": centro, "clave": "%s|%s|%d" % [nombre, str(elevada), int(fondo.x + fondo.z)],
		"sitios": sitios, "elevada": elevada, "col": col, "p": p, "salida": centro + lon * 27.5})

## Una caja de tamaño `t` (x = ancho, z = grosor) puesta de cara a lo largo de `lon`.
static func _tam_lon(lon: Vector3, t: Vector3) -> Vector3:
	return t if absf(lon.z) > 0.5 else Vector3(t.z, t.y, t.x)

## Altura de la pelvis de pie (pose de reposo) respecto al origen de la
## persona (misma medida que `InteriorInstalacion._altura_cadera`).
static func altura_cadera(nodo: Node3D) -> float:
	var esqueletos := nodo.find_children("*", "Skeleton3D", true, false)
	if esqueletos.is_empty():
		return 0.0
	var sk: Skeleton3D = esqueletos[0]
	var b := sk.find_bone("pelvis")
	if b < 0:
		b = sk.find_bone("Hips")
	if b < 0:
		return 0.0
	var t := sk.get_bone_global_rest(b)
	var n: Node = sk
	while n != null and n != nodo:
		if n is Node3D:
			t = (n as Node3D).transform * t
		n = n.get_parent()
	return t.origin.y

## Llena (o vacía) los andenes según dónde esté la cámara. Un andén elevado
## tiene dos lados: se llenan los dos de esa estación.
func _gente_cerca(delta: float) -> void:
	## Se crea una persona por fotograma (crear muchas de golpe da tirones).
	if not _cola_gente.is_empty() and _gente != null:
		_crear_persona(_cola_gente.pop_front())
	if not _cola_pas.is_empty() and _pas_nodo != null and is_instance_valid(_pas_nodo):
		_crear_pasajero(_cola_pas.pop_front())
	for f: Dictionary in _fijos_gente:
		if not bool(f["charla"]):
			continue
		f["t"] = float(f["t"]) - delta
		if float(f["t"]) <= 0.0:
			f["t"] = _rng_gente.randf_range(4.0, 9.0)
			Mini3D.anim(f["d"], "charla" if _rng_gente.randf() < 0.7 else "parado", "")
	## En pasos cortos: con fotogramas lentos, un paso de un metro de golpe hacía
	## que el esquive rebotara y la gente se quedara clavada.
	var pasos := mini(20, ceili(delta / 0.05))
	for _i in pasos:
		_mover_caminantes(delta / float(pasos))
	_llegadas(delta)
	_t_gente -= delta
	if _t_gente > 0.0:
		return
	_t_gente = 0.5
	var cam := get_viewport().get_camera_3d() if is_inside_tree() else null
	if cam == null:
		return
	var yo := cam.global_position
	_pasajeros_cerca(yo)
	var mejor: Dictionary = {}
	var dmin := RADIO_GENTE
	for e: Dictionary in _sitios:
		var d := yo.distance_to(e["centro"])
		if d < dmin:
			dmin = d
			mejor = e
	## La estación (los dos andenes de la elevada).
	var clave := "" if mejor.is_empty() else "%s" % str(mejor["p"])
	if clave == _gente_clave:
		return
	_gente_clave = clave
	if _gente != null:
		_gente.queue_free()
		_gente = null
	_cola_gente.clear()
	_fijos_gente.clear()
	_caminantes.clear()
	_embarque.clear()
	_huecos.clear()
	_gente_linea = ""
	_gente_idx = -1
	_gente_lados.clear()
	if clave == "":
		return
	_gente = Node3D.new()
	_gente.name = "GenteAnden"
	add_child(_gente)
	_rng_gente.seed = hash(clave)
	for e: Dictionary in _sitios:
		if str(e["p"]) == clave:
			_gente_lados.append(e)
			for s: Dictionary in e["sitios"]:
				## No todos los asientos ocupados.
				if bool(s["sentado"]) and _rng_gente.randf() < 0.45:
					continue
				_cola_gente.append({"tipo": "sitio", "s": s, "e": e})
	## Qué línea y qué estación es (para saber cuándo para su tren).
	for l: Dictionary in lineas:
		if bool(l["elevada"]) != bool(mejor["elevada"]):
			continue
		for i in (l["estaciones"] as Array).size():
			if (l["estaciones"][i] as Vector3).distance_to(mejor["p"]) < 0.5:
				_gente_linea = String(l["nombre"])
				_gente_idx = i

func _crear_persona(item: Dictionary) -> void:
	match String(item["tipo"]):
		"sitio":
			var s: Dictionary = item["s"]
			var d := Mini3D.persona(_gente, _rng_gente, s["p"])
			if d.is_empty():
				return
			_asentar(d, s, item["e"])
		"bajar":
			var ruta: Array = item["ruta"]
			var d2 := Mini3D.persona(_gente, _rng_gente, ruta[0])
			if d2.is_empty():
				return
			(d2["nodo"] as Node3D).rotation.y = atan2((ruta[1] - ruta[0]).x, (ruta[1] - ruta[0]).z)
			_caminantes.append({"d": d2, "ruta": ruta.slice(1), "fin": "salir", "tren": item["tren"],
				"suelta": 1, "espera": float(item["espera"]), "andando": false})
		"llegar":
			var e: Dictionary = item["e"]
			var d3 := Mini3D.persona(_gente, _rng_gente, e["salida"])
			if d3.is_empty():
				return
			_caminantes.append({"d": d3, "ruta": [(item["s"] as Dictionary)["p"]], "fin": "sitio", "s": item["s"], "e": e,
				"tren": -1, "suelta": 99, "espera": 0.0, "andando": false})

## Deja a una persona en su sitio: sentada en el banco o de pie esperando.
func _asentar(d: Dictionary, s: Dictionary, e: Dictionary) -> void:
	var p: Vector3 = s["p"]
	var n: Node3D = d["nodo"]
	n.position = p
	n.rotation.y = float(s["giro"])
	var sentado := bool(s["sentado"])
	if sentado:
		var cadera := altura_cadera(n)
		if cadera > 0.0:
			n.position.y = p.y + BANCO_ASIENTO + 0.08 - cadera * 0.99
	var charla := bool(s.get("charla", false))
	Mini3D.anim(d, "sentado" if sentado else ("charla" if charla else "parado"), "")
	(d["anim"] as AnimationPlayer).seek(_rng_gente.randf() * 0.8, true)
	_fijos_gente.append({"d": d, "charla": charla, "t": _rng_gente.randf_range(2.0, 8.0), "s": s, "e": e})

# ------------------------------------- subir y bajar del tren (16-10-2026)
## Pedido: «nadie sube ni baja del tren». Cuando el tren para en la estación
## con gente, algunos de los que esperan caminan hasta la puerta más cercana y
## entran; otros salen del tren y se van hacia la escalera. El tren NO arranca
## hasta que terminan (como mucho `RETENCION_MAX` s más). Los sitios que dejan
## los que suben se vuelven a ocupar con gente que llega por la escalera.
const RETENCION_MAX := 10.0
const VEL_GENTE := 1.35
const RADIO_PERSONA := 0.3
var _gente_linea := ""
var _gente_idx := -1
var _gente_lados: Array = []
var _caminantes: Array = []   ## [{d, ruta, fin, tren, suelta, espera, andando, s?, e?}]
var _embarque := {}           ## k del tren -> {t}
var _huecos: Array = []       ## [{s, e, t}] sitios libres que se volverán a ocupar

## La posición (en el espacio del metro) de un punto del coche: `x` lateral, `z` a lo largo.
static func _en_tren(tren: Transform3D, x: float, z: float) -> Vector3:
	return tren * Vector3(x, PISO_COCHE, z)

## Dónde está el tren según su lógica (el nodo se mueve más tarde en el
## fotograma: con su posición vieja la gente iba a la puerta de otro sitio).
static func transform_tren(l: Dictionary, t: Tren) -> Transform3D:
	var a: Vector3 = l["a"]
	var dir: Vector3 = l["dir"]
	var y := ALTO_VIADUCTO + 0.6 if bool(l["elevada"]) else PROF_TUNEL
	var giro := atan2(dir.x, dir.z) + (0.0 if t.sentido > 0.0 else PI)
	return Transform3D(Basis(Vector3.UP, giro), a + dir * t.s + Vector3(0, y, 0))

## La puerta del tren más cercana a `p` (en coordenadas del coche): [lado, z].
static func puerta_cercana(tren: Transform3D, p: Vector3) -> Array:
	var local := tren.affine_inverse() * p
	var mejor_z := 0.0
	var dmin := INF
	for k in 3:
		for dz: float in [-3.5, 3.5]:
			var z := (float(k) - 1.0) * 16.6 + dz
			if absf(z - local.z) < dmin:
				dmin = absf(z - local.z)
				mejor_z = z
	return [signf(local.x) if absf(local.x) > 0.01 else 1.0, mejor_z]

## Los trenes que paran (o arrancan) en la estación con gente.
func _embarques(delta: float) -> void:
	if _gente_linea == "" or _gente == null:
		return
	var l := linea(_gente_linea)
	var s_est := float(l["est_s"][_gente_idx])
	for k in (l["trenes"] as Array).size():
		var t: Tren = l["trenes"][k]
		var en_estacion := absf(t.s - s_est) < 1.0
		if en_estacion and t.espera > 0.0 and not _embarque.has(k):
			_embarque[k] = {"t": 0.0}
			_planear_embarque(k, transform_tren(l, t))
		elif _embarque.has(k):
			if not en_estacion:
				## Ya se fue: los que no llegaron a la puerta se quedan esperando.
				_embarque.erase(k)
				for c: Dictionary in _caminantes:
					if int(c["tren"]) == k and String(c["fin"]) == "subir":
						c["fin"] = "sitio"
						c["tren"] = -1
						c["ruta"] = [(c["s"] as Dictionary)["p"]]
				continue
			var emb: Dictionary = _embarque[k]
			emb["t"] = float(emb["t"]) + delta
			## Retener el tren mientras alguien está entrando o saliendo por la puerta.
			var ocupado := false
			for c: Dictionary in _caminantes:
				if int(c["tren"]) == k and (c["ruta"] as Array).size() > int(c["suelta"]):
					ocupado = true
					break
			if not ocupado:
				for it: Dictionary in _cola_gente:
					if String(it["tipo"]) == "bajar" and int(it["tren"]) == k:
						ocupado = true
						break
			if ocupado and float(emb["t"]) < PARADA + RETENCION_MAX:
				t.espera = maxf(t.espera, 1.0 + delta)

## Elige quién sube (de los que esperan) y crea a los que bajan.
func _planear_embarque(k: int, tren: Transform3D) -> void:
	var suben := 0
	var quedan: Array = []
	for f: Dictionary in _fijos_gente:
		var s: Dictionary = f["s"]
		var prob := 0.18 if bool(s["sentado"]) else (0.3 if bool(f["charla"]) else 0.55)
		if suben >= 5 or _rng_gente.randf() > prob:
			quedan.append(f)
			continue
		suben += 1
		var d: Dictionary = f["d"]
		var n: Node3D = d["nodo"]
		var pos := n.position
		pos.y = (s["p"] as Vector3).y
		n.position = pos
		var pu := puerta_cercana(tren, pos)
		var lado := float(pu[0])
		var z := float(pu[1]) + _rng_gente.randf_range(-0.25, 0.25)
		## Primero hacia la puerta por el andén, luego dentro del coche.
		var ruta: Array = [_en_tren(tren, lado * 2.7, z), _en_tren(tren, lado * 1.75, z),
			_en_tren(tren, lado * 0.8, z + _rng_gente.randf_range(-0.6, 0.6))]
		_caminantes.append({"d": d, "ruta": ruta, "fin": "subir", "tren": k, "suelta": -1,
			"espera": _rng_gente.randf_range(0.3, 1.8), "andando": false, "s": s, "e": f["e"]})
	_fijos_gente = quedan
	## Los que bajan: 1-3 por cada andén de la estación, escalonados.
	var retraso := 0.4
	for e: Dictionary in _gente_lados:
		var lado_e := float(puerta_cercana(tren, e["centro"])[0])
		for _q in _rng_gente.randi_range(1, 3):
			var coche := _rng_gente.randi_range(0, 2)
			var z := (float(coche) - 1.0) * 16.6 + (3.5 if _rng_gente.randf() < 0.5 else -3.5)
			var salida: Vector3 = e["salida"]
			var fuera := _en_tren(tren, lado_e * 3.2, z + _rng_gente.randf_range(-0.8, 0.8))
			_cola_gente.append({"tipo": "bajar", "tren": k, "espera": retraso,
				"ruta": [_en_tren(tren, lado_e * 0.7, z), _en_tren(tren, lado_e * 1.8, z), fuera,
					Vector3(salida.x, fuera.y, salida.z)]})
			retraso += _rng_gente.randf_range(0.5, 1.1)

## Camina a cada uno hacia su siguiente punto, sin atravesar a los demás.
func _mover_caminantes(delta: float) -> void:
	if _caminantes.is_empty():
		return
	var quedan: Array = []
	for c: Dictionary in _caminantes:
		var d: Dictionary = c["d"]
		var n: Node3D = d["nodo"]
		if not is_instance_valid(n):
			continue
		if float(c["espera"]) > 0.0:
			c["espera"] = float(c["espera"]) - delta
			quedan.append(c)
			continue
		if not bool(c["andando"]):
			c["andando"] = true
			Mini3D.anim(d, "caminar", "")
		var ruta: Array = c["ruta"]
		var obj: Vector3 = ruta[0]
		var hacia := Vector3(obj.x - n.position.x, 0, obj.z - n.position.z)
		var dist := hacia.length()
		var paso := VEL_GENTE * delta
		## Los puntos de paso no hace falta pisarlos exactos (si alguien espera
		## justo ahí, se quedaba atascado empujándolo); el último sí.
		var tolerancia := 0.12 if ruta.size() == 1 else 0.45
		if dist <= maxf(paso, tolerancia):
			if ruta.size() == 1:
				n.position = obj
			ruta.pop_front()
			if ruta.is_empty():
				_fin_caminante(c)
				continue
			quedan.append(c)
			continue
		var dir := hacia / dist
		var antes := n.position
		var p := n.position + dir * paso
		## Al cruzar la puerta ya no se esquiva (dentro del coche no hay nadie del
		## andén); y quien lleva un rato atascado pasa rozando (el tren espera).
		var atasco := float(c.get("atasco", 0.0))
		if (ruta.size() > 1 or String(c["fin"]) != "subir") and atasco < 1.2:
			p = _apartar_de_otros(p, n, dir, paso)
		var avance := Vector2(p.x - antes.x, p.z - antes.z).dot(Vector2(dir.x, dir.z))
		if avance < paso * 0.3:
			c["atasco"] = atasco + delta
		elif atasco >= 1.2:
			c["atasco"] = atasco + delta if atasco < 2.5 else 0.0
		else:
			c["atasco"] = 0.0
		p.y = lerpf(n.position.y, obj.y, minf(1.0, delta * 6.0))
		n.position = p
		n.rotation.y = lerp_angle(n.rotation.y, atan2(dir.x, dir.z), minf(1.0, delta * 8.0))
		quedan.append(c)
	_caminantes = quedan

func _fin_caminante(c: Dictionary) -> void:
	var d: Dictionary = c["d"]
	match String(c["fin"]):
		"subir":
			(d["nodo"] as Node3D).queue_free()
			_huecos.append({"s": c["s"], "e": c["e"], "t": _rng_gente.randf_range(8.0, 22.0)})
		"salir":
			(d["nodo"] as Node3D).queue_free()
		"sitio":
			_asentar(d, c["s"], c["e"])

## Los sitios que quedaron libres se vuelven a ocupar al rato.
func _llegadas(delta: float) -> void:
	if _huecos.is_empty() or _gente == null:
		return
	var quedan: Array = []
	for h: Dictionary in _huecos:
		h["t"] = float(h["t"]) - delta
		if float(h["t"]) <= 0.0:
			_cola_gente.append({"tipo": "llegar", "s": h["s"], "e": h["e"]})
		else:
			quedan.append(h)
	_huecos = quedan

## Separa `p` de la gente del andén (salvo `yo`): círculos de `RADIO_PERSONA`.
## Si el otro está delante (según `dir`), además se da un paso al costado para
## rodearlo (de frente, el empuje solo lo dejaba parado).
func _apartar_de_otros(p: Vector3, yo: Node3D, dir: Vector3, paso: float) -> Vector3:
	var minimo := RADIO_PERSONA * 2.0
	for o: Node3D in _cuerpos_gente():
		if o == yo:
			continue
		var dx := p.x - o.position.x
		var dz := p.z - o.position.z
		var d2 := dx * dx + dz * dz
		if d2 < minimo * minimo and d2 > 0.0001:
			var d := sqrt(d2)
			p.x = o.position.x + dx / d * minimo
			p.z = o.position.z + dz / d * minimo
			if -(dx * dir.x + dz * dir.z) > 0.0:
				var lado := Vector3(-dir.z, 0, dir.x)
				if lado.x * dx + lado.z * dz < 0.0:
					lado = -lado
				p += lado * paso * 0.8
	return p

## Los cuerpos de la gente del andén (esperando y caminando).
func _cuerpos_gente() -> Array:
	var r: Array = []
	for f: Dictionary in _fijos_gente:
		var n: Node3D = f["d"]["nodo"]
		if is_instance_valid(n):
			r.append(n)
	for c: Dictionary in _caminantes:
		var n2: Node3D = c["d"]["nodo"]
		if is_instance_valid(n2):
			r.append(n2)
	return r

## EL PERSONAJE NO ATRAVIESA A LA GENTE DEL ANDÉN (16-10-2026): lo usa el
## explorador en el andén. Devuelve `p` empujado fuera de cada persona
## (círculos), así el personaje se desliza a su alrededor en vez de cruzarla.
func apartar(p: Vector3, radio: float) -> Vector3:
	if _gente == null:
		return p
	var minimo := radio + RADIO_PERSONA
	for _vuelta in 2:
		for o: Node3D in _cuerpos_gente():
			if absf(o.position.y - p.y) > 1.5:
				continue
			var dx := p.x - o.position.x
			var dz := p.z - o.position.z
			var d2 := dx * dx + dz * dz
			if d2 < minimo * minimo:
				var d := sqrt(d2)
				if d < 0.0001:
					dx = 1.0
					dz = 0.0
					d = 1.0
				p.x = o.position.x + dx / d * minimo
				p.z = o.position.z + dz / d * minimo
	return p

## Para las pruebas: cuánta gente hay y qué hace.
func estado_gente() -> Dictionary:
	var suben := 0
	var bajan := 0
	var llegan := 0
	for c: Dictionary in _caminantes:
		match String(c["fin"]):
			"subir": suben += 1
			"salir": bajan += 1
			"sitio": llegan += 1
	var pas := 0
	if _pas_nodo != null and is_instance_valid(_pas_nodo):
		pas = _pas_nodo.get_child_count()
	return {"esperando": _fijos_gente.size(), "suben": suben, "bajan": bajan, "llegan": llegan,
		"retenidos": _embarque.size(), "pasajeros": pas}

## Posiciones de la gente del andén (para las pruebas).
func posiciones_gente() -> Array:
	var r: Array = []
	for n: Node3D in _cuerpos_gente():
		r.append(n.position)
	return r

# ------------------------------------------- pasajeros dentro del coche
## Solo en el tren más cercano a la cámara (a menos de 45 m): unos sentados y
## alguno de pie junto a las barras. Se crean de uno en uno.
var _pas_tren: Node3D
var _pas_nodo: Node3D
var _cola_pas: Array = []

func _pasajeros_cerca(yo: Vector3) -> void:
	var mejor: Node3D = null
	var dmin := 45.0
	for l: Dictionary in lineas:
		for n: Node3D in l["nodos"]:
			var d := n.position.distance_to(yo)
			if d < dmin:
				dmin = d
				mejor = n
	if mejor == _pas_tren:
		return
	_pas_tren = mejor
	if _pas_nodo != null and is_instance_valid(_pas_nodo):
		_pas_nodo.queue_free()
	_pas_nodo = null
	_cola_pas.clear()
	if mejor == null:
		return
	_pas_nodo = Node3D.new()
	_pas_nodo.name = "Pasajeros"
	mejor.add_child(_pas_nodo)
	var rng := RandomNumberGenerator.new()
	rng.seed = mejor.get_instance_id()
	## Asientos (en coordenadas del coche): los mismos de `_interior_coche`.
	var libres: Array = []
	for k in 3:
		for lado: float in [-1.0, 1.0]:
			for tramo: Array in TRAMOS_ASIENTO:
				var n_as := int(float(tramo[1]) / PASO_ASIENTO)
				for q in n_as:
					var z := (float(k) - 1.0) * 16.6 + float(tramo[0]) + (float(q) - float(n_as - 1) * 0.5) * PASO_ASIENTO
					libres.append(Vector3(lado, 0, z))
	for _i in 8:
		var a: Vector3 = libres.pop_at(rng.randi() % libres.size())
		## No delante de la cámara del viajero (coche central, z ≈ -5).
		if a.z > -7.0 and a.z < -3.0:
			continue
		_cola_pas.append({"pos": Vector3(a.x * 1.04, PISO_COCHE, a.z), "giro": atan2(-a.x, 0.0), "sentado": true})
	## De pie, junto a las barras del centro.
	for z2: float in [0.0, -16.6, 22.6]:
		_cola_pas.append({"pos": Vector3(rng.randf_range(0.25, 0.45) * (1.0 if rng.randf() < 0.5 else -1.0), PISO_COCHE, z2 + 0.35), "giro": rng.randf_range(-PI, PI), "sentado": false})

func _crear_pasajero(item: Dictionary) -> void:
	var d := Mini3D.persona(_pas_nodo, _rng_gente, item["pos"])
	if d.is_empty():
		return
	var n: Node3D = d["nodo"]
	n.rotation.y = float(item["giro"])
	if bool(item["sentado"]):
		var cadera := altura_cadera(n)
		if cadera > 0.0:
			n.position.y = PISO_COCHE + ALTO_ASIENTO + 0.08 - cadera * 0.99
		Mini3D.anim(d, "sentado", "")
	else:
		Mini3D.anim(d, "parado", "")
	(d["anim"] as AnimationPlayer).seek(_rng_gente.randf() * 0.8, true)

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
	## Bancos y demás: `_amueblar_anden`.
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
	## Es para verlo desde la calle; en el andén ya están las pantallas colgadas
	## (desde allí quedaba cortado detrás del tren).
	l.visibility_range_begin = 30.0
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

## Tramos de pared entre puertas (z desde-hasta, coordenadas del coche): las
## puertas están en ±3,5 y miden 1,5 m.
const TRAMOS_PARED := [[-8.0, -4.25], [-2.75, 2.75], [4.25, 8.0]]
## Tramos de asientos (centro, largo) y paso entre asientos.
const TRAMOS_ASIENTO := [[-6.1, 3.3], [0.0, 5.0], [6.1, 3.3]]
const PASO_ASIENTO := 0.55
const ALTO_ASIENTO := 0.47   ## altura del cojín sobre el suelo del coche
## Anuncios del vagón (marcas inventadas).
const ANUNCIOS := [
	"LECHE LA PRADERA\nfresca cada mañana", "MUSEO DEL FÚTBOL\nabierto todos los días",
	"BANCO HORIZONTE\ntu primera cuenta", "ZAPATILLAS VELOZ\ncorre más lejos",
	"FESTIVAL DEL RÍO\nmúsica en la ribera", "PANADERÍA EL TRIGAL\npan de leña",
	"ESCUELA DE IDIOMAS\naprende en 3 meses", "CINE AURORA\nestrenos los viernes",
	"SEGUROS LA BRÚJULA\nviaja tranquilo", "AGUA MANANTIAL\nde la sierra",
]
const COLORES_ANUNCIO := [Color(0.85, 0.25, 0.2), Color(0.15, 0.45, 0.75), Color(0.95, 0.7, 0.15),
	Color(0.2, 0.6, 0.35), Color(0.55, 0.25, 0.6), Color(0.1, 0.12, 0.18)]

static var _mallas_interior := {}
static var _mat_int: StandardMaterial3D

static func _mat_interior() -> StandardMaterial3D:
	if _mat_int == null:
		_mat_int = StandardMaterial3D.new()
		_mat_int.vertex_color_use_as_albedo = true
		_mat_int.vertex_color_is_srgb = true
		_mat_int.roughness = 0.8
		_mat_int.cull_mode = BaseMaterial3D.CULL_DISABLED
	return _mat_int

## Una caja en la malla de colores de vértice.
static func _caja_st(st: SurfaceTool, c: Vector3, t: Vector3, color: Color) -> void:
	var h := t * 0.5
	st.set_color(color)
	for eje in 3:
		for s: float in [-1.0, 1.0]:
			var nrm := Vector3.ZERO
			nrm[eje] = s
			var u := Vector3.ZERO
			var v := Vector3.ZERO
			u[(eje + 1) % 3] = 1.0
			v[(eje + 2) % 3] = 1.0
			var o := c + nrm * h[eje]
			var du := u * h[(eje + 1) % 3]
			var dv := v * h[(eje + 2) % 3]
			var q := [o - du - dv, o + du - dv, o + du + dv, o - du + dv]
			st.set_normal(nrm)
			for i: int in [0, 1, 2, 0, 2, 3]:
				st.add_vertex(q[i])

## La malla del interior de los tres coches (forros, asientos, marcos, asideros,
## fondos de anuncio y planos de línea), una por color de línea.
static func _interior_malla(col: Color) -> ArrayMesh:
	var clave := col.to_html()
	if _mallas_interior.has(clave):
		return _mallas_interior[clave]
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var f := PISO_COCHE
	var suelo := Color(0.23, 0.25, 0.29)
	var pasillo := Color(0.3, 0.32, 0.36)
	var amarillo := Color(0.93, 0.72, 0.12)
	var pared_baja := Color(0.5, 0.54, 0.6)
	var pared_alta := Color(0.8, 0.79, 0.75)
	var techo := Color(0.72, 0.72, 0.7)
	var marco := Color(0.42, 0.44, 0.48)
	var base_asiento := Color(0.3, 0.31, 0.35)
	var cojin := Color(col.r * 0.8, col.g * 0.8, col.b * 0.8).lerp(Color(0.3, 0.3, 0.35), 0.15)
	var cojin_b := cojin.darkened(0.3)
	var preferente := Color(0.95, 0.55, 0.12)
	var correa := Color(0.12, 0.12, 0.14)
	var asa := col.lightened(0.25)
	var metal := Color(0.72, 0.73, 0.76)
	var blanco := Color(0.95, 0.95, 0.93)
	for k in 3:
		var z := (float(k) - 1.0) * 16.6
		## Suelo, pasillo y franjas amarillas de las puertas.
		_caja_st(st, Vector3(0, f + 0.035, z), Vector3(2.84, 0.03, 15.9), suelo)
		_caja_st(st, Vector3(0, f + 0.052, z), Vector3(0.6, 0.004, 15.6), pasillo)
		## Techo forrado (antes, el blanco del exterior quemado por la luz).
		_caja_st(st, Vector3(0, f + 2.565, z), Vector3(2.8, 0.02, 15.9), techo)
		for lado: float in [-1.0, 1.0]:
			for dz: float in [-3.5, 3.5]:
				_caja_st(st, Vector3(lado * 1.2, f + 0.054, z + dz), Vector3(0.36, 0.006, 1.5), amarillo)
				## Dintel de la puerta y plano de la línea encima.
				_caja_st(st, Vector3(lado * 1.4, f + 2.25, z + dz), Vector3(0.06, 0.08, 1.56), marco)
				_caja_st(st, Vector3(lado * 1.37, f + 2.4, z + dz), Vector3(0.012, 0.2, 1.3), blanco)
				_caja_st(st, Vector3(lado * 1.364, f + 2.4, z + dz), Vector3(0.012, 0.025, 1.18), col)
				for e in 7:
					_caja_st(st, Vector3(lado * 1.36, f + 2.4, z + dz + (float(e) - 3.0) * 0.19), Vector3(0.014, 0.06, 0.06), Color(0.1, 0.1, 0.12) if e != 3 else amarillo)
			## Forro de la pared alta (encima de las ventanas, donde van los anuncios).
			_caja_st(st, Vector3(lado * 1.385, f + 2.38, z), Vector3(0.02, 0.36, 15.9), pared_alta)
			for tr: Array in TRAMOS_PARED:
				var z0 := z + float(tr[0])
				var z1 := z + float(tr[1])
				var lz := z1 - z0
				var zc := (z0 + z1) * 0.5
				## Forro bajo, alféizar y marco de arriba de la ventana.
				_caja_st(st, Vector3(lado * 1.385, f + 0.475, zc), Vector3(0.02, 0.85, lz), pared_baja)
				_caja_st(st, Vector3(lado * 1.37, f + 0.91, zc), Vector3(0.08, 0.04, lz), marco)
				_caja_st(st, Vector3(lado * 1.39, f + 2.19, zc), Vector3(0.06, 0.04, lz), marco)
				## Montantes: en las puntas del tramo y cada ~1,9 m.
				var n_m := maxi(1, int(round(lz / 1.9)))
				for q in n_m + 1:
					var zm := z0 + lz * float(q) / float(n_m)
					zm = clampf(zm, z0 + 0.05, z1 - 0.05)
					_caja_st(st, Vector3(lado * 1.4, f + 1.55, zm), Vector3(0.07, 1.3, 0.1), marco)
			## Asientos uno a uno, con base, cojín, respaldo y reposacabezas.
			for ti in TRAMOS_ASIENTO.size():
				var tramo: Array = TRAMOS_ASIENTO[ti]
				var tc := z + float(tramo[0])
				var tl := float(tramo[1])
				_caja_st(st, Vector3(lado * 1.12, f + 0.21, tc), Vector3(0.48, 0.36, tl), base_asiento)
				var n_as := int(tl / PASO_ASIENTO)
				for q in n_as:
					var zs := tc + (float(q) - float(n_as - 1) * 0.5) * PASO_ASIENTO
					var pref := ti != 1 and (q == 0 or q == n_as - 1) and absf(absf(zs - z) - 3.5) < 2.0
					var c1 := preferente if pref else (cojin if q % 2 == 0 else cojin.lerp(cojin_b, 0.35))
					_caja_st(st, Vector3(lado * 1.1, f + ALTO_ASIENTO - 0.045, zs), Vector3(0.5, 0.09, PASO_ASIENTO - 0.05), c1)
					_caja_st(st, Vector3(lado * 1.33, f + 0.8, zs), Vector3(0.08, 0.6, PASO_ASIENTO - 0.05), c1.darkened(0.12))
					_caja_st(st, Vector3(lado * 1.32, f + 1.13, zs), Vector3(0.09, 0.1, PASO_ASIENTO - 0.08), cojin_b)
				## Mamparas y barras en las puntas que dan a las puertas.
				for s: float in [-1.0, 1.0]:
					var ze := tc + s * (tl * 0.5 + 0.06)
					if absf(absf(ze - z) - 3.5) > 1.2:
						continue
					## Mampara de tubo (una placa opaca tapaba la vista del pasillo).
					_caja_st(st, Vector3(lado * 0.86, f + 1.12, ze), Vector3(0.045, 2.2, 0.045), metal)
					for yb: float in [0.62, 1.18]:
						_caja_st(st, Vector3(lado * 1.11, f + yb, ze), Vector3(0.5, 0.04, 0.04), metal)
				## Fondo del anuncio sobre el tramo (el texto es un Label3D).
				var c_ad: Color = COLORES_ANUNCIO[(k * 3 + ti + (0 if lado > 0.0 else 2)) % COLORES_ANUNCIO.size()]
				_caja_st(st, Vector3(lado * 1.37, f + 2.38, tc), Vector3(0.012, 0.3, 1.55), c_ad)
				_caja_st(st, Vector3(lado * 1.372, f + 2.38, tc), Vector3(0.01, 0.34, 1.6), marco)
			## Asideros colgados de las barras del techo.
			for q in 21:
				var za := z - 7.0 + float(q) * 0.7
				if absf(absf(za - z) - 3.5) < 0.5:
					continue
				_caja_st(st, Vector3(lado * 0.55, f + 2.14, za), Vector3(0.02, 0.2, 0.03), correa)
				_caja_st(st, Vector3(lado * 0.55, f + 2.02, za), Vector3(0.02, 0.035, 0.1), asa)
		## Testeros: forro y puerta de paso al coche de al lado.
		for e: float in [-1.0, 1.0]:
			_caja_st(st, Vector3(0, f + 1.3, z + e * 7.93), Vector3(2.76, 2.5, 0.02), pared_alta)
			_caja_st(st, Vector3(0, f + 1.0, z + e * 7.92), Vector3(0.95, 1.9, 0.02), Color(0.28, 0.3, 0.34))
			_caja_st(st, Vector3(0, f + 1.35, z + e * 7.915), Vector3(0.6, 0.7, 0.01), Color(0.12, 0.16, 0.2))
	st.index()
	var m := st.commit()
	_mallas_interior[clave] = m
	return m

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
	## Después de los rótulos (Label3D, también transparentes): si no, el
	## motor dibujaba el cartel del andén ENCIMA del cristal y desde dentro
	## parecía pegado a la ventana, sin el tinte del vidrio.
	vidrio.render_priority = 1
	var metal := _mat(Color(0.75, 0.76, 0.78), 0.25)
	metal.metallic = 0.8
	var luz := _mat(Color(1, 0.96, 0.86), 0.3, 0.6)
	var puerta_m := _mat(Color(0.82, 0.84, 0.86), 0.3)
	var oscuro := _mat(Color(0.06, 0.06, 0.07), 0.5)
	var cabina := _mat(Color(0.08, 0.12, 0.16), 0.08)
	cabina.metallic = 0.4
	var leds: Array = []
	var puertas: Array = []
	var f := PISO_COCHE
	## EL INTERIOR (16-10-2026, «se ve casi blanco»): suelo, forros de pared y
	## techo, asientos uno a uno, marcos, asideros, anuncios y planos de línea
	## en UNA malla con colores de vértice (compartida por los trenes de la línea).
	var interior := MeshInstance3D.new()
	interior.name = "Interior"
	interior.mesh = _interior_malla(col)
	interior.material_override = _mat_interior()
	interior.visibility_range_end = 120.0
	n.add_child(interior)
	for k in 3:
		var z := (float(k) - 1.0) * 16.6
		_caja(n, Vector3(0, f - 0.3, z), Vector3(3.0, 0.6, 16.0), blanco)          ## bastidor
		_caja(n, Vector3(0, f + 2.65, z), Vector3(3.0, 0.15, 16.0), blanco)        ## techo
		for lado: float in [-1.0, 1.0]:
			var x := lado * 1.45
			_caja(n, Vector3(x, f + 2.4, z), Vector3(0.1, 0.4, 16.0), blanco)        ## sobre ventanas
			## Entre puertas: panel bajo, franja y ventana. Antes iban de punta a
			## punta y tapaban la parte baja de las puertas abiertas.
			for tr: Array in TRAMOS_PARED:
				var zc := z + (float(tr[0]) + float(tr[1])) * 0.5
				var lz := float(tr[1]) - float(tr[0])
				_caja(n, Vector3(x, f + 0.45, zc), Vector3(0.1, 0.9, lz), blanco)       ## panel bajo
				_caja(n, Vector3(x * 1.04, f + 0.35, zc), Vector3(0.02, 0.25, lz), franja)
				_caja(n, Vector3(x, f + 1.55, zc), Vector3(0.04, 1.3, lz), vidrio)      ## ventanas
			## Anuncios sobre las ventanas (el fondo de color va en la malla).
			for q in TRAMOS_ASIENTO.size():
				var ad := Label3D.new()
				var texto: String = ANUNCIOS[(k * 6 + q * 2 + (0 if lado > 0.0 else 1)) % ANUNCIOS.size()]
				ad.text = texto
				ad.font_size = 30
				ad.pixel_size = 0.0033
				ad.outline_size = 5
				ad.outline_modulate = Color(0, 0, 0, 0.6)
				ad.width = 440.0
				ad.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
				ad.double_sided = false
				ad.position = Vector3(lado * 1.355, f + 2.38, z + float(TRAMOS_ASIENTO[q][0]))
				ad.rotation.y = atan2(-lado, 0.0)
				ad.visibility_range_end = 18.0
				n.add_child(ad)
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
		_caja(n, Vector3(0, f + 2.535, z), Vector3(0.26, 0.03, 15.0), luz)
		## Testeros con ventana (los extremos del coche).
		for e: float in [-1.0, 1.0]:
			_caja(n, Vector3(0, f + 1.3, z + e * 8.0), Vector3(3.0, 2.6, 0.1), blanco)
		## Panel LED en el testero de cada coche, mirando dentro. FALLO (15-10-2026):
		## era un solo Label3D de una línea («Línea 1 ▸ Próxima: Mercado Este»)
		## de ~4,5 m de ancho en un coche de 3 m: atravesaba las paredes y desde
		## el andén se veía el final del cartel saliendo por los lados del tren.
		## Ahora: dos líneas con ancho fijo dentro de una caja negra, de una sola
		## cara, y sin pasar de 2,2 m.
		var cz := z + 7.9
		_caja(n, Vector3(0, f + 2.2, cz - 0.02), Vector3(2.3, 0.42, 0.06), oscuro)
		var led := Label3D.new()
		led.font_size = 28
		led.pixel_size = 0.0055
		led.modulate = Color(1.0, 0.6, 0.1)
		led.outline_size = 0
		led.double_sided = false
		led.position = Vector3(0, f + 2.2, cz - 0.06)
		led.rotation.y = PI
		led.visibility_range_end = 40.0
		n.add_child(led)
		leds.append(led)
		## Fuelle entre coches: tapaba el hueco por donde se veía la vía.
		if k < 2:
			_caja(n, Vector3(0, f + 1.25, z + 8.3), Vector3(2.2, 2.5, 0.62), oscuro)
	## LAS CABEZAS (15-10-2026): por fuera el tren era una caja blanca lisa.
	## Ahora cada punta lleva parabrisas oscuro, faros, franja de la línea y el
	## letrero de destino.
	var faro := _mat(Color(1.0, 0.97, 0.85), 0.2, 2.5)
	var piloto := _mat(Color(0.9, 0.1, 0.08), 0.3, 1.5)
	for e: float in [-1.0, 1.0]:
		var zc := e * (16.6 + 8.0)
		_caja(n, Vector3(0, f + 1.15, zc + e * 0.1), Vector3(2.9, 2.0, 0.12), blanco)
		_caja(n, Vector3(0, f + 1.75, zc + e * 0.17), Vector3(2.3, 0.95, 0.04), cabina)
		_caja(n, Vector3(0, f + 0.55, zc + e * 0.17), Vector3(2.95, 0.22, 0.04), franja)
		_caja(n, Vector3(0, f + 2.42, zc + e * 0.17), Vector3(1.6, 0.26, 0.04), oscuro)
		for xs: float in [-1.0, 1.0]:
			_caja(n, Vector3(xs * 1.1, f + 0.85, zc + e * 0.18), Vector3(0.32, 0.14, 0.04), faro)
			_caja(n, Vector3(xs * 0.7, f + 0.85, zc + e * 0.18), Vector3(0.16, 0.1, 0.04), piloto)
		var dest := Label3D.new()
		dest.font_size = 24
		dest.pixel_size = 0.0045
		dest.modulate = Color(1.0, 0.6, 0.1)
		dest.outline_size = 0
		dest.double_sided = false
		dest.position = Vector3(0, f + 2.42, zc + e * 0.2)
		dest.rotation.y = 0.0 if e > 0.0 else PI
		dest.visibility_range_end = 90.0
		n.add_child(dest)
		leds.append(dest)
	n.set_meta("led", leds[0])
	n.set_meta("leds", leds)
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
