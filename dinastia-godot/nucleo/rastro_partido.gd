class_name RastroPartido
extends RefCounted
## EL RASTRO DE UN PARTIDO (26-10-2026, sesión 5, fila 4 de la propuesta): lo que hace falta para explicar
## DESPUÉS por qué salió el resultado (`CausasPartido`) y que el `Partido` no guardaba: cómo llegaban los
## dos onces (forma, físico, calidad, pizarra) al empezar, el momentum minuto a minuto, lo que decidió el
## árbitro por su cuenta y contra quién, las rojas y las lesiones.
##
## Solo ESCUCHA las señales del partido (`gol`, `remate`, `tarjeta`, `decision_arbitral`, `lesion`,
## `minuto_jugado`): no usa `Azar` ni toca nada que decida el marcador, así que el mismo partido sale igual
## con o sin rastro. Sirve igual para la simulación, el partido en vivo y el motor del 3D.
##
## No guarda el `Partido` (sería un ciclo de referencias: el partido es dueño del rastro): lo mira por una
## referencia débil cuando necesita saber si lo está jugando el motor del 3D.

var local_id := ""
var visita_id := ""
## Cómo llegaba cada uno: [local, visita] de "forma", "fisico", "ovr", "tac_ata", "tac_def", y "mentalidad"
## y "formacion" de las dos pizarras de salida (el plan del 60' las cambia y se devuelven al final).
var inicio: Dictionary = {}
## [minuto, valor]: +2/−2 un gol, +1/−1 un remate; positivo = a favor del local (como `momentum_eventos`).
var momentum: Array = []
## {min, contra_local: bool, tipo: "tarjeta" | "penal"}: lo que el árbitro decidió POR SU CUENTA.
var arbitraje: Array = []
## {min, local: bool, nombre}
var rojas: Array = []
var lesiones: Array = []
## true si algún minuto lo jugó el motor del 3D (el clima, el xG y la localía no pesan igual ahí).
var con_motor := false
var _ids_local: Dictionary = {}
var _pend_arbitro := -1
var _wp: WeakRef = null

func enganchar(p: RefCounted) -> void:
	_wp = weakref(p)
	p.connect("gol", _al_gol)
	p.connect("remate", _al_remate)
	p.connect("tarjeta", _a_la_tarjeta)
	p.connect("decision_arbitral", _a_la_decision)
	p.connect("lesion", _a_la_lesion)
	p.connect("minuto_jugado", _al_minuto)

## Se llama al final de `Partido.preparar()`, con los onces ya puestos.
func al_preparar(p: RefCounted) -> void:
	var loc: Club = p.get("local")
	var vis: Club = p.get("visita")
	local_id = loc.id
	visita_id = vis.id
	_ids_local.clear()
	for j: Jugador in loc.plantilla:
		_ids_local[j.id] = true
	var onces := [p.get("once_local"), p.get("once_visita")]
	inicio = {"forma": [0, 0], "fisico": [0, 0], "ovr": [0, 0], "tac_ata": [1.0, 1.0], "tac_def": [1.0, 1.0],
		"mentalidad": [1, 1], "formacion": ["", ""]}
	for i in 2:
		var once: Array = onces[i]
		var n := maxi(once.size(), 1)
		var f := 0.0
		var fi := 0.0
		var o := 0.0
		for j: Jugador in once:
			f += float(j.forma)
			fi += float(j.fisico)
			o += float(j.ovr)
		inicio["forma"][i] = int(round(f / n))
		inicio["fisico"][i] = int(round(fi / n))
		inicio["ovr"][i] = int(round(o / n))
		var c: Club = loc if i == 0 else vis
		if c.tactica != null:
			inicio["tac_ata"][i] = c.tactica.multiplicador_ataque()
			inicio["tac_def"][i] = c.tactica.multiplicador_defensa()
			inicio["mentalidad"][i] = c.tactica.mentalidad
			inicio["formacion"][i] = c.tactica.formacion
	momentum.clear()
	arbitraje.clear()
	rojas.clear()
	lesiones.clear()
	_pend_arbitro = -1
	con_motor = false

func _es_local(c: Club) -> bool:
	return c != null and c.id == local_id

func _al_gol(c: Club, _autor: Jugador, m: int, _asis: Jugador) -> void:
	momentum.append([m, 2 if _es_local(c) else -2])
	if _pend_arbitro == m:
		_pend_arbitro = -1
		## El penal que se inventa el árbitro: va CONTRA el que lo encaja.
		arbitraje.append({"min": m, "contra_local": not _es_local(c), "tipo": "penal"})

func _al_remate(c: Club, _autor: Jugador, _tipo: String, m: int) -> void:
	momentum.append([m, 1 if _es_local(c) else -1])

func _a_la_tarjeta(j: Jugador, roja: bool, m: int) -> void:
	var loc := _ids_local.has(j.id)
	if roja:
		rojas.append({"min": m, "local": loc, "nombre": j.nombre})
	if _pend_arbitro == m:
		_pend_arbitro = -1
		arbitraje.append({"min": m, "contra_local": loc, "tipo": "tarjeta"})

## La frase llega justo ANTES de su tarjeta o su gol (`_tarjeta_arbitral`, el penal del «estricto»): se
## apunta el minuto y la señal que viene detrás dice contra quién fue. La del «figura» (anula por nada, sin
## tocar el marcador) no va seguida de nada y se queda sin apuntar: no cambió el partido.
func _a_la_decision(_texto: String, m: int) -> void:
	_pend_arbitro = m

func _a_la_lesion(j: Jugador, semanas: int, m: int) -> void:
	lesiones.append({"min": m, "local": _ids_local.has(j.id), "nombre": j.nombre, "semanas": semanas})

func _al_minuto(_m: int) -> void:
	if con_motor or _wp == null:
		return
	var p: Object = _wp.get_ref()
	if p != null and bool(p.get("motor_externo")):
		con_motor = true

## El tramo de `largo` minutos con más momentum neto para un lado: {desde, hasta, neto (+ local)}.
func tramo_dominante(largo: int = 15) -> Dictionary:
	var mejor := {"desde": 0, "hasta": largo, "neto": 0}
	if momentum.is_empty():
		return mejor
	var ultimo := int(momentum[momentum.size() - 1][0])
	for desde in range(0, maxi(ultimo - largo + 2, 1)):
		var neto := 0
		for e: Array in momentum:
			if int(e[0]) >= desde and int(e[0]) < desde + largo:
				neto += int(e[1])
		if absi(neto) > absi(int(mejor["neto"])):
			mejor = {"desde": desde, "hasta": desde + largo, "neto": neto}
	return mejor
