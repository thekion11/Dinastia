class_name LeagueSinBalon
extends RefCounted
## LA IA SIN BALÓN DE LEAGUE-SOCCER PORTADA A GDSCRIPT (10-11-2026, fase 3 de `docs/04_auditorias/MOTOR_LEAGUE_SOCCER_PLAN.md`).
## Funciones PURAS en el marco de `LeagueNucleo` (x = largo, y = ancho, `lado` = signo del arco propio). Origen (L =
## `terceros/league_soccer/codigo_y_recursos/src/onthepitch/`): `player/controller/strategies/offtheball/default_{def,mid,off}.cpp`,
## `elizacontroller.cpp` (GetSupportPosition_ForceField, GetLazyVelocity, caza del portador), `playercontroller.cpp`
## (AddDefensiveComponent, GetDefendPosition), `teamAIcontroller.cpp` (CalculateMarkingQuality, CalculateManMarking),
## `humanoid_utils.cpp` (NeedDefendingMovement). Atribución Apache 2.0: `terceros/league_soccer/NOTICE_DINASTIA.md`.

## Parámetros de cada estrategia (L default_def / default_mid / default_off):
## [distancia de acción mín, máx, multiplicador del sesgo estático, ataque mín, ataque máx, umbral de la carrera, k defensivo, trampa].
const ESTRATEGIA := {
	"def": [12.0, 18.0, 1.1, 0.2, 0.9, 0.7, 1.9, true],
	"med": [15.0, 20.0, 0.9, 0.1, 0.7, 0.9, 1.5, true],
	"ata": [15.0, 20.0, 0.8, 0.1, 0.6, 0.7, 1.3, false],
}

## Qué estrategia usa cada puesto (L: LB/CB/RB defensa; DM/LM/CM/RM/AM medio; CF ataque).
static func grupo(puesto: String) -> String:
	match puesto:
		"DFC", "LD", "LI", "CAD", "CAI": return "def"
		"DC": return "ata"
	return "med"

## Peso de la posición estática frente a la dinámica (roles intercambiados) según lo lejos que está la acción.
static func sesgo_estatico(g: String, dist_accion: float) -> float:
	var s: Array = ESTRATEGIA[g]
	return LeagueNucleo.curva(float(s[2]) * LeagueNucleo.normalizado(dist_accion, float(s[0]), float(s[1])), 1.0)

## Cuánto pesa el apoyo ofensivo (L attackBias): sale de la posesión que se desvanece; la defensa lo escala por su mentalidad.
static func sesgo_ataque(g: String, posesion_desv: float, mente: float) -> float:
	var s: Array = ESTRATEGIA[g]
	var b := LeagueNucleo.normalizado(posesion_desv - 0.5, float(s[3]), float(s[4]))
	if g == "def":
		b *= minf(0.72 + clampf(mente, 0.0, 1.0) * 0.52, 1.0)   ## L AITactics::GetDefenderSupportScale
	return b

## L GetSupportPosition_ForceField. `e` = {base, pos, mov, lado, mente, puesto, correr: bool, adelantado: bool,
## principal: Vector2 (portador + mov·0,1), es_principal: bool, rivales: Array de [pos, mov] (los 3 más cercanos),
## companeros: Array de [pos, mov] (los 6 más cercanos, sin él), posesion_desv, balon_pred: Array de 4 Vector2 (200/350/500/650 ms),
## linea_offside, red (L support web scale)}.
static func apoyo(e: Dictionary) -> Vector2:
	var lado := float(e["lado"])
	var actual: Vector2 = (e["pos"] as Vector2) + (e["mov"] as Vector2) * 0.1
	var principal: Vector2 = e["principal"]
	var mente := float(e["mente"])
	var red := float(e["red"])
	var peso_rival := 0.3
	match String(e["puesto"]):
		"DFC", "LD", "LI": peso_rival *= 2.2
		"MCD": peso_rival *= 2.0
		"MC", "MD", "MI": peso_rival *= 1.6
		"MCO", "MP", "ED", "EI": peso_rival *= 1.2
	var campo: Array = []   ## [origen, repele, constante, potencia, escala, exp] como `LeagueNucleo.movimiento_campo`
	var o: Vector2 = e["base"]
	if bool(e["adelantado"]):
		o.x += -lado * (0.3 + 0.7 * mente) * 12.0
	else:
		var carril := (-1.0 if principal.y >= 0.0 else 1.0) * 8.0
		var cant := 22.0 * LeagueNucleo.curva(1.0 - LeagueNucleo.normalizado(absf(carril - actual.y), 0.0, 30.0), 1.0)
		o.x += -lado * pow(mente, 1.5) * cant
	campo.append([o, false, true, 0.7 * (0.3 + 0.7 * LeagueNucleo.normalizado((o - actual).length(), 0.0, 20.0)), 1.0, 1.0])
	var corre := bool(e["correr"])
	if corre:
		campo.append([Vector2(-lado * LeagueNucleo.MEDIO_LARGO, actual.y * 0.5), false, true, 2.0, 1.0, 1.0])
	for r: Array in e["rivales"]:
		var rp: Vector2 = (r[0] as Vector2) + (r[1] as Vector2) * 0.1
		var detras := rp + (rp - principal).normalized() * 2.0 if rp != principal else rp
		campo.append([detras, true, false, peso_rival * (0.5 if corre else 1.0), 2.0 if corre else 5.0, 0.7])
	var pd := float(e["posesion_desv"])
	if pd >= 1.02:
		for c: Array in e["companeros"]:
			campo.append([(c[0] as Vector2) + (c[1] as Vector2) * 0.1, true, false, 0.4, 14.0 * red, 1.0])
	var es_p := bool(e["es_principal"])
	if not es_p and pd >= 1.06:
		for bp: Vector2 in e["balon_pred"]:
			campo.append([bp, true, false, 1.0, 2.0, 0.5])
	if not es_p:
		campo.append([principal, false, false, 0.45, 28.0 * red, 1.0])
		campo.append([principal, true, false, 0.45, 16.0 * red, 1.0])
	var r2 := actual + LeagueNucleo.movimiento_campo(campo, actual, 7.0)
	var linea := float(e["linea_offside"])
	var margen := 0.08
	if r2.x * -lado > linea * -lado - margen:
		r2.x = linea - margen * -lado
	return Vector2(clampf(r2.x, -LeagueNucleo.MEDIO_LARGO, LeagueNucleo.MEDIO_LARGO), clampf(r2.y, -LeagueNucleo.MEDIO_ANCHO, LeagueNucleo.MEDIO_ANCHO))

## L PlayerController::AddDefensiveComponent: acercarse al «punto de tiro» del rival que marca. `rival_pos` ya con su mov·0,5.
static func componente_defensiva(deseada: Vector2, sesgo: float, rival_pos: Vector2, rival_es_portador: bool, lado: float, trampa_x: float, mi_pos: Vector2) -> Vector2:
	var umbral := 24.0 if rival_es_portador else 8.0
	var arco := Vector2(LeagueNucleo.MEDIO_LARGO * lado, 0.0)
	var d_arco := (arco - rival_pos).length()
	var hasta := clampf(d_arco - umbral, 0.4, LeagueNucleo.MEDIO_LARGO)
	var punto := rival_pos + (arco - rival_pos).normalized() * hasta
	if punto.x * lado > trampa_x * lado:
		## Cruce de la línea rival→arco con la línea de la trampa.
		var dx := arco.x - rival_pos.x
		if absf(dx) > 0.0001:
			var u := (trampa_x - rival_pos.x) / dx
			punto = rival_pos + (arco - rival_pos) * u
			hasta = (punto - rival_pos).length()
	var defensa := deseada
	var a_punto := punto - deseada
	var holgura := a_punto.length() - (hasta - 4.0)
	if holgura > 0.0:
		defensa = deseada + a_punto.normalized() * clampf(holgura, 0.0, a_punto.length())
	var holgura_real := (punto - mi_pos).length() - hasta
	if holgura_real > 0.0:
		defensa += (arco - defensa).normalized() * holgura_real * 0.7
	return deseada * (1.0 - sesgo) + defensa * sesgo

## Sesgo de la componente defensiva de cada estrategia: pow(clamp(k − mentalidad − posesión desvanecida, 0, 1), 0,7).
static func sesgo_defensa(g: String, mente: float, posesion_desv: float) -> float:
	return pow(clampf(float(ESTRATEGIA[g][6]) - mente - posesion_desv, 0.0, 1.0), 0.7)

## L PlayerController::GetDefendPosition: interceptar al rival en su línea hacia el arco.
static func posicion_defensa(rival_pos: Vector2, rival_mov: Vector2, mi_pos: Vector2, lado: float, distancia := 0.0) -> Vector2:
	var arco := Vector2(LeagueNucleo.MEDIO_LARGO * lado, 0.0)
	var al_arco := arco - rival_pos
	var medio := (mi_pos + rival_pos) * 0.5
	var perp := (mi_pos - medio).rotated(PI * 0.5)
	## Intersección de la línea rival→arco con la mediatriz yo↔rival (parámetro u sobre rival→arco).
	var den := al_arco.x * perp.y - al_arco.y * perp.x
	var u := 0.0
	if absf(den) > 0.0001:
		var w := medio - rival_pos
		u = (w.x * perp.y - w.y * perp.x) / den
	u = clampf(u, 0.0, 1.0)
	var objetivo := rival_pos + al_arco * u
	return objetivo + al_arco.normalized() * LeagueNucleo.V_SPRINT * 0.1 + rival_mov * 0.14 + al_arco.normalized() * distancia

## L NeedDefendingMovement: solo se mueve si hace falta de verdad.
static func necesita_defender(lado: float, pos: Vector2, objetivo: Vector2) -> bool:
	var hondo := maxf((objetivo.x - pos.x) * -lado, 0.0) - 0.5
	return absf(objetivo.y - pos.y) > hondo * 0.8

## L TeamAIController::CalculateMarkingQuality.
static func calidad_marcaje(mi_pos: Vector2, mi_mov: Vector2, rival_pos: Vector2, rival_mov: Vector2, lado: float) -> float:
	var op := rival_pos + rival_mov * 0.1
	var pp := mi_pos + mi_mov * 0.1
	var arco := Vector2(LeagueNucleo.MEDIO_LARGO * lado, 0.0)
	var al_arco := arco - pp
	var largo := clampf(al_arco.length(), 4.0, 14.0)
	var nrm := al_arco.normalized() if al_arco.length() > 0.0 else Vector2(lado, 0.0)
	var seguro := -nrm * 0.5
	var v0 := pp + seguro + nrm.rotated(-0.5 * PI) * largo
	var v1 := pp + seguro + nrm.rotated(0.5 * PI) * largo
	var seg := v1 - v0
	var cruz := seg.x * (op.y - v0.y) - seg.y * (op.x - v0.x)
	var lado_bueno := cruz > 0.0   ## L Line::WhatSide
	var u := (op - v0).dot(seg) / seg.length_squared()
	var dist := (op - (v0 + seg * u)).length()
	var adaptada := absf(dist - 2.0) if lado_bueno else dist
	var r := 1.0 - pow(LeagueNucleo.normalizado(adaptada, 0.0, 60.0), 0.5) * 0.5 - pow(clampf(absf(u * 2.0 - 1.0), 0.0, 1.0), 0.5) * 0.5
	r = clampf(r, 0.0, 1.0)
	if not lado_bueno:
		r *= 0.6
	var cerca := 1.0 - LeagueNucleo.normalizado((pp - op).length(), 0.0, LeagueNucleo.MEDIO_LARGO * 2.0)
	return r * 0.8 + cerca * 0.2

## L CalculateManMarking: los 3 rivales más peligrosos, cada uno al defensor que mejor lo marca. `mios` y `rivales`: Array de
## [id, pos, mov, portero] (rivales con «portador» en el 5.º campo). Devuelve {id propio: id rival}.
static func marcajes(mios: Array, rivales: Array, lado: float, balon: Vector2) -> Dictionary:
	var peligro := Vector2((LeagueNucleo.MEDIO_LARGO - 2.0) * lado, 0.0) * 0.8 + balon * 0.2
	var info: Array = []
	for r: Array in rivales:
		var f := (1.0 - LeagueNucleo.normalizado(((r[1] as Vector2) - peligro).length(), 0.0, LeagueNucleo.MEDIO_LARGO * 2.0)) * 0.95
		if r.size() > 4 and bool(r[4]):
			f += 0.05
		info.append([f, r])
	info.sort_custom(func(a: Array, b: Array) -> bool: return float(a[0]) > float(b[0]))
	var libres := mios.filter(func(m: Array) -> bool: return not bool(m[3]))
	var r2 := {}
	for k in mini(info.size(), 3):
		var rv: Array = info[k][1]
		var mejor := -1
		var mejor_q := -1.0
		for i in libres.size():
			var q := calidad_marcaje(libres[i][1], libres[i][2], rv[1], rv[2], lado)
			if q > mejor_q:
				mejor_q = q
				mejor = i
		if mejor >= 0:
			r2[libres[mejor][0]] = rv[0]
			libres.remove_at(mejor)
		if libres.is_empty():
			break
	return r2

## L ElizaController::GetLazyVelocity. `fresco` = 1 − fatiga (L GetFatigueFactorInv), `trabajo` = mental_workrate (0..1).
static func velocidad_perezosa(v: float, fresco: float, dist_accion: float, posesion_desv: float, mente: float, vel_media: float, trabajo: float) -> float:
	var a := v
	if a > LeagueNucleo.V_SPRINT:
		a = LeagueNucleo.V_SPRINT + (a - LeagueNucleo.V_SPRINT) * 0.1
	var inicio := 18.0 * (fresco * 0.8 + 0.2)
	var fin := 55.0 * (fresco * 0.5 + 0.5)
	var pos_eq := clampf(posesion_desv - 0.5, 0.0, 1.0)
	var por_rol := mente + pos_eq * (1.0 - mente * 2.0)
	var pereza := LeagueNucleo.normalizado(dist_accion, inicio, fin) * (0.5 + por_rol * 0.5)
	var r := a * (1.0 - pereza)
	if v >= LeagueNucleo.V_CONDUCE and r < LeagueNucleo.V_CONDUCE:
		r = LeagueNucleo.V_CONDUCE
	var aire := pow(1.0 - LeagueNucleo.normalizado(vel_media, LeagueNucleo.V_PARADO, LeagueNucleo.V_SPRINT), 0.8 - trabajo * 0.2)
	aire = clampf(aire * 1.2, 0.0, 1.0)
	aire = aire * pereza + 1.0 * (1.0 - pereza)
	return minf(r, LeagueNucleo.V_SPRINT * aire)

## L ElizaController (caza): distancia a la que el que no marca a nadie sale a por el portador.
static func umbral_caza(mente: float, fresco: float, vel_media: float, dificultad: float) -> float:
	var u := 10.0 + (1.0 - mente) * 10.0
	u *= 0.5 * fresco + 0.5 * (1.0 - LeagueNucleo.normalizado(vel_media, LeagueNucleo.V_PARADO, LeagueNucleo.V_SPRINT))
	return u * (0.3 + dificultad * 0.7)
