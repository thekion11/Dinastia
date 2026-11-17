class_name MejorasC4Marca
extends RefCounted
## EL MARCAJE EN EL ÁREA (17-11-2026, orden de Auditoría tras la sonda de goles de C4: de 191 remates desde el área en 24 partidos, 64 salían con
## el rival de campo más cercano a 5 m o más y daban 43 goles; esos remates SOLOS eran 2,7 por partido y el 39 % de los goles). Con
## `C4_MARCA_AREA=1`, mientras el rival ataca cerca de nuestra área (balón a menos de `ZONA` m del arco y no es nuestro):
##  - cada atacante sin balón dentro del área (con un margen) recibe UN marcador: por orden de peligro (el más cercano al punto de penal
##    primero), el defensor de campo libre más cercano; así el central más cercano al punto de penal toma al delantero más adelantado y
##    nadie queda doble ni libre mientras haya defensores;
##  - el que llega desde atrás (fuera del área, a menos de `LLEGADA` m y corriendo hacia el arco) lo toma el medio libre más cercano;
##  - con el balón abierto (centro), el lateral del lado contrario sin marca cierra el segundo palo;
##  - el marcador va a `PEGADO` m del atacante, del lado del arco, corriendo;
##  - HISTÉRESIS: un marcador conserva a su atacante mientras no haya otro defensor libre mucho más cerca (`CAMBIO`).
## Fuera de esa situación no hace nada: cada uno vuelve a su zona (la frontal no se vacía: solo se marca a los del área y a los que llegan).
## El que presiona al portador no entra en el reparto. Contadores `c4_marca_area` (asignaciones por paso) y `c4_segundo_palo`.
## Solo GDScript: nuestra `_ia_defensa` no tiene gemela C++ (la de la extensión es la colocación de League, C1).
static var ACTIVO := OS.get_environment("C4_MARCA_AREA") == "1"
const ZONA := 35.0
static var MARGEN_X := MARGEN_Z * 0.7 if MARGEN_Z > 3.0 else 2.0
static var MARGEN_Z := float(OS.get_environment("C4_MARCA_PROF")) if OS.get_environment("C4_MARCA_PROF") != "" else 3.0   ## m más allá del área en los que ya se marca
const LLEGADA := 24.0
const VEL_LLEGADA := 3.0
const PEGADO := 1.2
const CAMBIO := 3.0

## Objetivo de `p` (defensor de campo) si le toca marcar, o Vector3.INF.
static func objetivo(m: Object, p: Dictionary) -> Vector3:
	if not ACTIVO:
		return Vector3.INF
	var local := bool(p["es_local"])
	var reparto := _reparto(m, local)
	var id := String(p["id"])
	if not reparto.has(id):
		return Vector3.INF
	var dest: Variant = reparto[id]
	if dest is Vector3:
		p["correr"] = true
		return dest
	var att: Dictionary = dest
	var arco: Vector3 = m._arco_propio(p)
	var pa: Vector3 = m.pos(att)
	p["correr"] = true
	return pa + (arco - pa).normalized() * PEGADO

## Reparto del equipo `local` en este paso: {id del defensor: atacante (Dictionary) o punto (Vector3, segundo palo)}.
static func _reparto(m: Object, local: bool) -> Dictionary:
	var k := "_marca_l" if local else "_marca_v"
	var e: Dictionary = m.get_meta(k, {"t": -1.0, "r": {}, "pares": {}})
	if float(e["t"]) == float(m.t):
		return e["r"]
	var r := {}
	var pares := {}   ## id del atacante → id del marcador (para la histéresis del paso siguiente)
	var previo: Dictionary = e["pares"]
	var b: Vector3 = m.balon.position
	var pos_rival: Dictionary = m.poseedor
	var arco := Vector3(0, 0, -m.LARGO if local else m.LARGO)
	var ataca_rival := Vector2(b.x - arco.x, b.z - arco.z).length() < ZONA and (pos_rival.is_empty() or bool(pos_rival["es_local"]) != local)
	if ataca_rival:
		var d_area: float = m.AREA_Z + MARGEN_Z
		var hacia := signf(arco.z)
		var defensores: Array = []
		var atacantes: Array = []
		var llegan: Array = []
		var pp: Array = MotorPresion.papeles(m as MotorJugable, local)
		for q: Dictionary in m.jugadores:
			if bool(q["por"]):
				continue
			if bool(q["es_local"]) == local:
				if String(q["id"]) != String(pp[0]) and q != m.usuario:
					defensores.append(q)
				continue
			if q == pos_rival:
				continue
			var pq: Vector3 = m.pos(q)
			var prof := (pq.z - arco.z) * -hacia   ## metros desde la línea de gol hacia el campo
			if absf(pq.x) < m.AREA_X + MARGEN_X and prof < d_area:
				atacantes.append(q)
			elif Vector2(pq.x - arco.x, pq.z - arco.z).length() < LLEGADA:
				var v: Vector3 = q.get("vel", Vector3.ZERO)
				if v.z * hacia > VEL_LLEGADA:   ## corre hacia nuestro arco
					llegan.append(q)
		var penal := Vector3(0, 0, arco.z - hacia * 11.0)
		atacantes.sort_custom(func(x: Dictionary, y: Dictionary) -> bool: return (m.pos(x) as Vector3).distance_to(penal) < (m.pos(y) as Vector3).distance_to(penal))
		for att: Dictionary in atacantes:
			_asignar(m, att, defensores, previo, r, pares, false)
		for att: Dictionary in llegan:
			_asignar(m, att, defensores, previo, r, pares, true)
		## Centro desde la banda: el lateral contrario libre cierra el segundo palo.
		if absf(b.x) > m.AREA_X:
			for q: Dictionary in defensores:
				if m._rol(q) in ["LD", "LI"] and signf((m.pos(q) as Vector3).x) != signf(b.x) and not r.has(String(q["id"])):
					r[String(q["id"])] = Vector3(-signf(b.x) * 3.5, 0, arco.z - hacia * 4.0)
					m._contar("c4_segundo_palo")
					break
	m.set_meta(k, {"t": float(m.t), "r": r, "pares": pares})
	return r

## El defensor libre más cercano a `att` (los medios primero si llega desde atrás); con histéresis.
static func _asignar(m: Object, att: Dictionary, defensores: Array, previo: Dictionary, r: Dictionary, pares: Dictionary, llega: bool) -> void:
	var pa: Vector3 = m.pos(att)
	var mejor: Dictionary = {}
	var md := 999.0
	for q: Dictionary in defensores:
		if r.has(String(q["id"])):
			continue
		if llega and not (m._rol(q) in ["MC", "ED", "EI"]):
			continue
		var d: float = (m.pos(q) as Vector3).distance_to(pa)
		if d < md:
			md = d
			mejor = q
	if llega and mejor.is_empty():
		return
	var antes := String(previo.get(String(att["id"]), ""))
	if antes != "" and (mejor.is_empty() or antes != String(mejor["id"])):
		for q: Dictionary in defensores:
			if String(q["id"]) == antes and not r.has(antes) and (m.pos(q) as Vector3).distance_to(pa) < md + CAMBIO:
				mejor = q
				break
	if mejor.is_empty():
		return
	r[String(mejor["id"])] = att
	pares[String(att["id"])] = String(mejor["id"])
	m._contar("c4_marca_area")
