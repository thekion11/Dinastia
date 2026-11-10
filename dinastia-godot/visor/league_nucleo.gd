class_name LeagueNucleo
extends RefCounted
## NÚCLEO DE LEAGUE-SOCCER PORTADO A GDSCRIPT (10-11-2026, orden del dueño: el motor del partido pasa a ser el de League-Soccer,
## C++ Apache 2.0, heredero de GameplayFootball / Google Research Football; copia en `terceros/league_soccer/codigo_y_recursos`).
## Plan y cifras: `docs/04_auditorias/MOTOR_LEAGUE_SOCCER_PLAN.md`. Atribución: `terceros/league_soccer/NOTICE_DINASTIA.md`.
##
## Funciones PURAS (sin nodos ni azar propio: el azar entra por argumento) traducidas línea a línea del original, en SU MARCO:
##   Vector2(x, y) con x = largo (nuestro Z) e y = ancho (nuestro X); `lado` = signo del arco PROPIO (League `team->GetSide()`),
##   es decir lado = -dir_ataque. Medio largo 52,5 m (`pitchHalfW`), medio ancho 34 m (`pitchHalfH`).
## Origen de cada función (ruta L = `terceros/league_soccer/codigo_y_recursos/src/onthepitch/`) en su comentario.
## Si algún día se pasa a la extensión C++ (`nativo/`), cada función nativa debe ser copia exacta de esta.

const MEDIO_LARGO := 52.5   ## pitchHalfW
const MEDIO_ANCHO := 34.0   ## pitchHalfH
## L velocitystate.hpp
const V_PARADO := 0.0
const V_CONDUCE := 3.5
const V_TROTE := 5.0
const V_SPRINT := 8.0
const CAMBIO_PARADO_CONDUCE := 1.8
const CAMBIO_CONDUCE_TROTE := 4.4
const CAMBIO_TROTE_SPRINT := 6.2
## L gamedefines.hpp `distanceToVelocityMultiplier`.
const DIST_A_VEL := 2.6
## Tipos de golpeo (L `e_FunctionType`).
const CORTO := 0
const LARGO := 1
const ALTO := 2
const TIRO := 3

static func normalizado(v: float, a: float, b: float) -> float:   ## bluntmath NormalizedClamp
	return clampf((v - a) / (b - a), 0.0, 1.0) if b != a else 0.0

static func curva(x: float, sesgo := 1.0) -> float:   ## bluntmath curve: lineal «/» hacia senoidal «_/-»
	return (sin((x - 0.5) * PI) * 0.5 + 0.5) * sesgo + x * (1.0 - sesgo)

static func rango_velocidad(v: float) -> float:   ## L velocitystate RangeVelocity
	if v >= CAMBIO_PARADO_CONDUCE and v < CAMBIO_CONDUCE_TROTE:
		return V_CONDUCE
	if v >= CAMBIO_CONDUCE_TROTE and v < CAMBIO_TROTE_SPRINT:
		return V_TROTE
	if v >= CAMBIO_TROTE_SPRINT:
		return V_SPRINT
	return V_PARADO

## L AIfunctions AI_GetMindSet, con nuestros puestos (EI/ED = extremos de ataque, cerca del mediapunta).
static func mentalidad(puesto: String) -> float:
	match puesto:
		"POR", "DFC": return 0.0
		"LD", "LI", "MCD", "CAD", "CAI": return 0.25
		"MC", "MD", "MI": return 0.5
		"MCO", "MP", "ED", "EI", "SD": return 0.75
		"DC": return 1.0
	return 0.5

# ------------------------------------------------------------------ balón (L ballphysics.cpp ApplyBallMotionForces)

## Un paso de fuerzas sobre el balón (en NUESTRO 3D: Y arriba; las fuerzas son iguales en el plano). Devuelve [pos, momento].
## `cfg`: rebote, rebote_lineal, arrastre, roce, roce_lineal, gravedad, cesped, humedad, viento (Vector3).
static func fuerzas_balon(pos: Vector3, mom: Vector3, cfg: Dictionary, dt: float, radio := 0.11) -> Array:
	mom.y += float(cfg["gravedad"]) * dt
	var velo := mom.length()
	var velo_frenada := velo - float(cfg["arrastre"]) * velo * velo * dt
	mom = (mom / velo * velo_frenada) if velo > 0.0 else Vector3.ZERO
	var abajo := pos.y - radio
	var cesped := float(cfg["cesped"])
	var hierba := pow(clampf(1.0 - abajo / cesped, 0.0, 1.0), 0.7)
	mom += (cfg["viento"] as Vector3) * ((1.0 - hierba) * dt)
	if pos.y < radio:
		if mom.y < 0.0:
			mom.y = -mom.y * float(cfg["rebote"])
			mom.y = maxf(mom.y - float(cfg["rebote_lineal"]), 0.0)
		pos.y = radio
	if pos.y < radio + cesped:
		var moja := 1.0 - clampf(float(cfg["humedad"]), 0.0, 1.0) * 0.5
		var roce := float(cfg["roce"]) * hierba * moja
		var xy := Vector2(mom.x, mom.z)
		var v := xy.length()
		var nv := v - roce * v * v * dt
		nv = clampf(nv - float(cfg["roce_lineal"]) * hierba * moja * dt, 0.0, 100000.0)
		xy = xy.normalized() * nv if v > 0.0 else Vector2.ZERO
		mom.x = xy.x
		mom.z = xy.y
	return [pos, mom]

## Valores por defecto de L `BallPhysicsConfig` (afinados «PES 5/6» en el original).
static func config_balon(humedad := 0.0, viento := Vector3.ZERO) -> Dictionary:
	return {"rebote": 0.64, "rebote_lineal": 0.05, "arrastre": 0.017, "roce": 0.06, "roce_lineal": 1.55,
		"gravedad": -9.81, "cesped": 0.025, "humedad": humedad, "viento": viento}

# ------------------------------------------------------------------ espacio y situación (L AIfunctions, player.cpp)

## L AI_CalculateFreeSpace. `rivales`: Array de [pos: Vector2, mov: Vector2, portero: bool].
static func espacio_libre(foco: Vector2, rivales: Array, seguro: float, futuro: float, sin_portero := true) -> float:
	var suma := 0.0
	for r: Array in rivales:
		if sin_portero and bool(r[2]):
			continue
		var rp: Vector2 = (r[0] as Vector2) + (r[1] as Vector2) * 0.2
		var hacia := (foco - rp).normalized() * V_SPRINT * maxf(futuro - 0.2, 0.0)
		if hacia.length() > (foco - rp).length():
			hacia = foco - rp
		rp += hacia
		suma += 1.0 - clampf((rp - foco).length(), 0.0, seguro) / seguro
	return 1.0 - normalizado(suma, 0.0, 2.5)

## L Player::_CalculateTacticalSituation → [espacio_adelante, espacio, adelante].
static func situacion(pos: Vector2, mov: Vector2, lado: float, rivales: Array) -> Array:
	var adelante_pos := pos + Vector2(-lado, 0.0) * V_SPRINT * 0.5
	var esp_adelante := espacio_libre(adelante_pos, rivales, 5.0, 0.5)
	var esp := espacio_libre(pos + mov * 0.1, rivales, 5.0, 0.1)
	var cerca := 1.0 - clampf((Vector2(MEDIO_LARGO * -lado, 0.0) - pos).length() / (MEDIO_LARGO * 2.0), 0.0, 1.0)
	return [esp_adelante, esp, pow(cerca, 1.5)]

# ------------------------------------------------------------------ pase (L elizacontroller.cpp _GetPassingOdds)

## Probabilidad de que el pase llegue: 1 = limpio. `rivales` como en `espacio_libre`.
static func odds_pase(origen: Vector2, destino: Vector2, tipo: int, rivales: Array, mult_vel := 1.0) -> float:
	var escala := 1.0
	var peligro := 0.0
	var seg := destino - origen
	var largo2 := seg.length_squared()
	for r: Array in rivales:
		var rp: Vector2 = (r[0] as Vector2) + (r[1] as Vector2) * 0.2
		var u := (rp - origen).dot(seg) / largo2 if largo2 > 0.0 else 0.0
		var punto := origen + seg * clampf(u, 0.0, 1.0)
		var dist_r := (rp - (origen + seg * u)).length() if largo2 > 0.0 else (rp - origen).length()
		if u >= 0.0 and u <= 1.2:
			if tipo != ALTO or u < 0.2 or u > 0.65:
				var t_rival := (dist_r + 1.0) / V_SPRINT
				var castigo := 2.5 if (tipo == ALTO and u > 0.5) else 0.0
				var t_balon := (0.7 + (punto - origen).length() * u * 0.03 + castigo) / mult_vel
				peligro += clampf(t_balon - t_rival + escala * 0.5, 0.0, escala)
	if tipo == ALTO:
		peligro += 0.4
	return 1.0 - normalizado(peligro, 0.0, escala)

## L ElizaController::_GetPassingOdds(Player*): el destino es donde estará el receptor.
static func odds_pase_a(origen: Vector2, mov_origen: Vector2, receptor: Vector2, mov_receptor: Vector2, lado: float, tipo: int, rivales: Array) -> float:
	var d0 := (receptor - origen).length()
	if tipo == ALTO and d0 < 10.0:
		return 0.0
	var t_est := 0.7 + d0 * 0.03
	var destino := receptor + mov_receptor * clampf(t_est, 0.0, 0.5)
	if tipo == LARGO:
		destino += Vector2(-lado * d0 * 0.2, 0.0)
	return odds_pase(origen + mov_origen * 0.12, destino, tipo, rivales)

## L AI_GetAutoPass → [dirección 3D en marco League (x, y, alto), potencia]. Velocidad de salida: `vel_pase`.
static func auto_pase(tipo: int, vector: Vector2) -> Array:
	var alto := 0.11
	var factor := 1.8
	if tipo == ALTO:
		alto = 0.45 - normalizado(vector.length(), 0.0, 60.0) * 0.15
		factor = 1.15
	var dir := Vector3(vector.normalized().x, vector.normalized().y, alto).normalized()
	return [dir, pow(normalizado(vector.length(), 0.0, 60.0), 1.4) * factor]

## L humanoid.cpp: touchVec = ballDirection * 36 * (ballPower + 0.3).
static func vel_pase(potencia: float) -> float:
	return 36.0 * (potencia + 0.3)

# ------------------------------------------------------------------ decisión con balón (L ElizaController::GetOnTheBallCommands)

## `yo`: {pos, mov, lado, puesto, tec_pase, tec_tiro, posee_ms, sit: [esp_adel, esp, adel]}.
## `companeros`: Array de {i, pos, mov, puesto, sit}. `rivales` como en `espacio_libre`. `azar`: RandomNumberGenerator.
## Devuelve {accion: "pase"|"panico"|"tiro"|"conducir", ...}. El original encola varias órdenes y el muñeco ejecuta la primera
## que puede: aquí se devuelve la de más prioridad en el mismo orden (pánico, pase, tiro; si no, conducir).
## `muestras`: cuántos ciclos de 10 ms del original cubre esta decisión (el original sortea el tiro en CADA ciclo; aquí se toma el
## máximo de `muestras` sorteos, que tiene la misma probabilidad: u^(1/n) es el máximo de n uniformes).
static func decidir(yo: Dictionary, companeros: Array, rivales: Array, mov_balon: Vector2, posesion: float, azar: RandomNumberGenerator, muestras := 1) -> Dictionary:
	var mov: Vector2 = yo["mov"]
	var pos: Vector2 = yo["pos"]
	var lado := float(yo["lado"])
	var mente := mentalidad(String(yo["puesto"]))
	var dif := normalizado((mov_balon - mov).length(), 0.0, 10.0)
	var toque_dificil := dif - float(yo["tec_pase"]) * dif * 0.8
	var largo_posesion := pow(normalizado(float(yo["posee_ms"]), 0.0, 5000.0), 2.0)
	var p_esp_adel := 0.4
	var p_esp := 0.3
	var p_adel := 2.0 + mente * 5.0
	var total1 := p_esp_adel + p_esp + p_adel
	var umbral_mejora := 0.06 * (1.0 - mente)
	var p_dif := 1.0 + pow(mente, 2.0) * 10.0
	var p_pase := 1.0
	var pase_min := 0.2 * (1.0 - mente) - largo_posesion * 0.1
	var total2 := p_dif + p_pase
	var umbral_pase := 0.12 - largo_posesion * 0.06
	var sit: Array = yo["sit"]
	var nota_yo := (float(sit[0]) * p_esp_adel + float(sit[1]) * p_esp + float(sit[2]) * p_adel) / total1
	var mejor := {}
	var mejor_total := 0.0
	for c: Dictionary in companeros:
		var cs: Array = c["sit"]
		var nota := (float(cs[0]) * p_esp_adel + float(cs[1]) * p_esp + float(cs[2]) * p_adel) / total1
		if String(c["puesto"]) == "POR":
			nota *= 0.7
		var progresa := nota > nota_yo + umbral_mejora
		var apoyo := apoyo_pase(nota_yo, float(sit[1]), nota, float(cs[1]), largo_posesion)
		if not (progresa or apoyo):
			continue
		var bono := bono_apoyo(float(sit[1]), float(cs[1]), largo_posesion) if apoyo else 0.0
		var oc := odds_pase_a(pos, mov, c["pos"], c["mov"], lado, CORTO, rivales)
		var ol := odds_pase_a(pos, mov, c["pos"], c["mov"], lado, LARGO, rivales)
		var oa := odds_pase_a(pos, mov, c["pos"], c["mov"], lado, ALTO, rivales)
		var tipo := CORTO
		var odds := oc
		if not (oc >= ol and oc >= oa):
			if ol >= oa:
				tipo = LARGO; odds = ol
			else:
				tipo = ALTO; odds = oa
		var total := (maxf(nota - nota_yo, 0.0) * p_dif + odds * p_pase + bono - toque_dificil) / total2
		if total > mejor_total and total > umbral_pase and odds > pase_min:
			mejor_total = total
			mejor = {"accion": "pase", "i": c["i"], "tipo": tipo, "odds": odds}
	## LA COLA (L: el original encola pánico, pase y tiro en ese orden y el muñeco ejecuta la primera que puede).
	var cola: Array = []
	## Pánico (solo los de mentalidad defensiva): despeje lejos del arco propio.
	if mente < 0.25:
		var propension := 1.0 - mente * 2.0
		var cerca_arco := 1.0 - normalizado((pos - Vector2(MEDIO_LARGO * lado, 0.0)).length(), 2.0, 16.0)
		if String(yo["puesto"]) != "POR":
			if (mejor.is_empty() or float(mejor["odds"]) < propension * cerca_arco) and posesion < 0.9 + propension * cerca_arco * 0.8:
				cola.append({"accion": "panico"})
		elif posesion < 3.0:
			cola.append({"accion": "panico"})
	if not mejor.is_empty():
		cola.append(mejor)
	## ¿Tiro? (L: tres puntos del arco, el mejor; ganas = sqrt(odds) + azar).
	var dist_arco := normalizado((Vector2(MEDIO_LARGO * -lado, 0.0) - pos).length(), 0.0, 32.0)
	var ideal := curva(1.0 - normalizado((Vector2((MEDIO_LARGO - 7.0) * -lado, 0.0) - pos).length(), 0.0, 16.0), 1.0)
	if ideal > 0.1:
		var mejor_y := 0.0
		var odds_t := odds_pase(pos + mov * 0.12, Vector2((MEDIO_LARGO + 1.0) * -lado, 0.0), TIRO, rivales, 3.0)
		for y: float in [-3.6, 3.6]:
			var o := odds_pase(pos + mov * 0.12, Vector2((MEDIO_LARGO + 1.0) * -lado, y), TIRO, rivales, 3.0)
			if o > odds_t:
				odds_t = o
				mejor_y = signf(y) * 3.5
		odds_t = sqrt(odds_t)
		if odds_t + pow(azar.randf(), 1.0 / float(maxi(muestras, 1))) * 0.28 > 0.55:
			var tec := float(yo["tec_tiro"])
			cola.append({"accion": "tiro", "y": mejor_y + azar.randf_range(-1.0 + tec, 1.0 - tec),
				"potencia": azar.randf_range(0.7 * (0.6 + dist_arco * 0.4), 1.0 * (0.6 + dist_arco * 0.4))})
	var r: Dictionary = (cola[0] as Dictionary).duplicate() if not cola.is_empty() else {"accion": "conducir"}
	r["cola"] = cola
	r["zona"] = ideal > 0.1
	return r

## L aitactics.hpp ShouldConsiderSupportPass / GetSupportPassBonus.
static func apoyo_pase(nota_yo: float, esp_yo: float, nota_c: float, esp_c: float, largo_posesion: float) -> bool:
	var retener := maxf(1.0 - clampf(esp_yo, 0.0, 1.0), clampf(largo_posesion, 0.0, 1.0))
	return retener >= 0.55 and esp_c >= esp_yo + 0.12 and nota_c >= nota_yo - 0.15

static func bono_apoyo(esp_yo: float, esp_c: float, largo_posesion: float) -> float:
	var ganancia := clampf((esp_c - esp_yo) / 0.4, 0.0, 1.0)
	var retener := maxf(1.0 - clampf(esp_yo, 0.0, 1.0), clampf(largo_posesion, 0.0, 1.0))
	return ganancia * retener * 0.35

## L ElizaController::_AddPanicPass: dirección del despeje (marco League, con algo de altura).
static func dir_panico(mirada: Vector2, lado: float) -> Vector2:
	var ylado := 1.0 if mirada.y >= 0.0 else -1.0
	var d := (mirada * Vector2(0.8, 1.0)).normalized() + Vector2(-lado * 0.9, ylado * 0.35)
	return d.normalized() if d.length() > 0.0 else Vector2(-lado, 0.0)

# ------------------------------------------------------------------ regate (L AI_GetBestDribbleMovement + AI_GetForceFieldMovement)

## Campo de fuerzas: los 5 rivales más cercanos repelen, las bandas repelen, el arco atrae. Devuelve [dirección, velocidad].
static func regate(pos: Vector2, mov: Vector2, mirada: Vector2, lado: float, cercanos: Array, mente: float, ofensivo := 0.5, iman := 0.5) -> Array:
	var empuje := 0.55 + clampf(ofensivo, 0.0, 1.0) * 0.28 + clampf(mente, 0.0, 1.0) * 0.12
	var fondo := normalizado(absf(pos.x) / MEDIO_LARGO, 0.0, 1.0)
	var centro_inv := (1.0 - fondo * fondo) * 0.5
	var arco := Vector2(-lado * MEDIO_LARGO, pos.y * (1.0 - iman) * centro_inv)
	var futuro := 0.25
	var campo: Array = []   ## [origen, repele, constante, potencia, escala, exp]
	for r: Array in cercanos:
		campo.append([(r[0] as Vector2) + (r[1] as Vector2) * futuro, true, false, 2.0, 10.0, 1.0])
	var sy := 1.0 if pos.y >= 0.0 else -1.0
	var sx := 1.0 if pos.x >= 0.0 else -1.0
	campo.append([Vector2(pos.x, (MEDIO_ANCHO + 5.0) * sy), true, false, 4.0, 20.0, 0.7])
	campo.append([Vector2((MEDIO_LARGO + 5.0) * sx, pos.y), true, false, 4.0, 20.0, 0.7])
	campo.append([arco, false, true, empuje, 1.0, 1.0])
	var m := movimiento_campo(campo, pos + mov * futuro, 1.0)
	var dir := m.normalized() if m.length() > 0.0 else mirada
	return [dir, rango_velocidad(clampf(m.length() * DIST_A_VEL, V_PARADO, V_SPRINT))]

static func movimiento_campo(campo: Array, actual: Vector2, amortigua: float) -> Vector2:
	var suma := Vector2.ZERO
	var fuerza_total := 0.0
	for f: Array in campo:
		var o: Vector2 = f[0]
		var dist := (o - actual).length()
		var intensidad := 1.0
		if not bool(f[2]):
			intensidad = clampf(1.0 - dist / float(f[4]), 0.0, 1.0)
			if float(f[5]) != 1.0:
				intensidad = pow(intensidad, float(f[5]))
		if intensidad <= 0.0:
			continue
		var rel := (o - actual).normalized() if dist > 0.0 else Vector2.ZERO
		if bool(f[1]):
			rel = -rel
		elif dist < amortigua:
			rel *= dist / amortigua
		var fz := float(f[3]) * intensidad
		suma += rel * fz
		fuerza_total += fz
	return (suma / fuerza_total) * V_SPRINT if fuerza_total > 0.0 else Vector2.ZERO

# ------------------------------------------------------------------ colocación (L TeamAIController::GetAdaptedFormationPosition)

## Tácticas base del equipo (L TeamAIController: `baseTeamTactics`) y cuánto las mueve cada palanca del usuario (`teamTacticsModMultipliers`).
const TACTICA_BASE := {"od": 0.92, "dd": 0.80, "ow": 0.90, "dw": 0.74, "oh": 0.52, "dh": 0.58, "om": 0.65, "dm": 0.55,
	"oms": 0.40, "dms": 0.42, "os": 0.10, "ds": 0.45, "omi": 0.72, "dmi": 0.82}
const TACTICA_MULT := {"od": 0.10, "dd": 0.10, "ow": 0.10, "dw": 0.10, "om": 0.28, "dm": 0.28, "os": 0.10, "ds": 0.10, "omi": 0.15, "dmi": 0.15}
const PROFUNDIDAD := 0.45   ## L `depth`
const ANCHURA := 0.95       ## L `width`

## L UpdateTactics: `usuario` = {clave: 0..1} (0,5 = neutro) → tácticas vivas.
static func tactica_viva(usuario: Dictionary) -> Dictionary:
	var viva := TACTICA_BASE.duplicate()
	for k: String in usuario:
		if viva.has(k):
			viva[k] = clampf(float(viva[k]) + (float(usuario[k]) - 0.5) * 2.0 * float(TACTICA_MULT.get(k, 0.0)), 0.0, 1.0)
	return viva

## L UpdateTactics: ofensividad por marcador y reloj (mitad posesión reciente). `t_ms` = minuto de juego en ms.
static func ofensividad(goles: int, goles_rival: int, t_ms: float, posesion_reciente: float) -> float:
	var f_gol := clampf(0.5 + float(goles_rival - goles) * 0.17, 0.0, 1.0)
	var f_t := 0.5 + 0.5 * clampf(t_ms / 6300000.0, 0.0, 1.0)
	var ataque := clampf(0.5 + (f_gol - 0.5) * f_t, 0.0, 1.0)
	return ataque * 0.5 + posesion_reciente * 0.5

## L mixup: retoques por puesto.
static func mezcla(base: float, k: String, puesto: String, contra: float) -> float:
	var v := -100.0
	match puesto:
		"DFC":
			if k == "ow": v = 0.2
		"LD", "LI", "CAD", "CAI":
			if k == "dh": v = -0.075
			elif k == "ow": v = 0.2
			elif k == "oh": v = -0.1
		"MD", "MI":
			if k == "dh": v = -(0.02 + 0.06 * contra)
			elif k == "oh": v = -0.1
		"MCO", "MP", "ED", "EI", "SD", "DC":
			if k == "dd": v = 0.05 + 0.15 * contra
	return clampf(base + v, 0.0, 1.0) if v > -100.0 else base

## Las tácticas vivas con los retoques de un puesto (se puede guardar: solo cambia cuando cambian las tácticas, una vez por segundo).
static func mezclas(viva: Dictionary, puesto: String, contra: float) -> Dictionary:
	var f := {}
	for k: String in viva:
		f[k] = mezcla(float(viva[k]), k, puesto, contra)
	return f

## Destino de un jugador sin balón (marco League). `e` = {forma: Vector2 (−1 atrás..1 delante, −1..1 ancho), puesto, lado,
## pos: Vector2, foco: Vector2 (el de la posesión), balon_x_lento, balon_y_lento, balon_3s, balon_2s (Vector2),
## posesion_desvanecida (0..1 del equipo), lado_posesion_medio (−1..1), ofensividad, viva (tácticas), contra, trampa_x}.
static func posicion_formacion(e: Dictionary) -> Vector2:
	var puesto := String(e["puesto"])
	var lado := float(e["lado"])
	var mente := mentalidad(puesto)
	var of := float(e["ofensividad"])
	var f: Dictionary = e["mezcla"] if e.has("mezcla") else mezclas(e["viva"], puesto, float(e["contra"]))
	var os := clampf(float(f["os"]) + (-0.5 + mente) * 0.2 - 0.3 + of * 0.3, 0.0, 1.0)
	var ds := clampf(float(f["ds"]) + (0.5 - mente) * 0.2 - 0.3 + (1.0 - of) * 0.3, 0.0, 1.0)
	var bx := float(e["balon_x_lento"])
	var by := float(e["balon_y_lento"])
	var foco: Vector2 = e["foco"]
	var b_pos := normalizado(float(e["posesion_desvanecida"]) - 0.5, 0.3, 0.7)
	var b_balon := normalizado((bx / MEDIO_LARGO) * -lado, -0.7, 0.7)
	var bb := (1.0 - absf(b_pos * 2.0 - 1.0)) * 0.6
	var pb := clampf(b_pos * (1.0 - bb) + b_balon * bb + (of - 0.5) * 0.3, 0.0, 1.0)
	foco = (e["balon_3s"] as Vector2) * pb + ((e["balon_2s"] as Vector2) * 0.5 + foco * 0.5) * (1.0 - pb)
	var prof := PROFUNDIDAD * (float(f["od"]) * pb + float(f["dd"]) * (1.0 - pb))
	var anch := ANCHURA * (float(f["ow"]) * pb + float(f["dw"]) * (1.0 - pb))
	var off_x := MEDIO_LARGO * lado * ((float(f["oh"]) * 2.0 - 1.0) * pb + (float(f["dh"]) * 2.0 - 1.0) * (1.0 - pb))
	var side_f := os * pb + ds * (1.0 - pb)
	var sf := pb * 2.0 - 1.0
	var side_x := 0.2 * sf * -lado * MEDIO_LARGO + 0.8 * -float(e["lado_posesion_medio"]) * MEDIO_LARGO
	var cx := clampf(bx * (1.0 - side_f) + side_x * side_f + off_x, -MEDIO_LARGO, MEDIO_LARGO)
	var cy := clampf(by, -MEDIO_ANCHO, MEDIO_ANCHO)
	cx *= (1.0 - prof) * 0.95 + 0.05
	cy *= (1.0 - anch) * 0.9 + 0.1
	var atras := cx - prof * MEDIO_LARGO * -lado
	var delante := cx + prof * MEDIO_LARGO * -lado
	var bajo := cy - anch * MEDIO_ANCHO
	var alto := cy + anch * MEDIO_ANCHO
	var trampa := float(e["trampa_x"])
	if atras * lado > trampa * lado:
		atras = trampa
	var y_fuerza := 0.5 * pb + 0.2 * (1.0 - pb)
	## CORRECCIÓN (10-11): el original hace clamp(foco + side·2, −pitchHalfW, backXBound·side), que solo limita bien con side = +1
	## (allí los equipos cambian de campo en el descanso y se compensa; aquí no, y la visita tenía ~15 puntos más de posesión).
	## Versión simétrica de la misma idea: el foco defensivo no pasa de la línea de atrás del bloque.
	var dfx := foco.x + lado * 2.0
	if dfx * lado > atras * lado:
		dfx = atras
	var defensivo := Vector2(clampf(dfx, -MEDIO_LARGO, MEDIO_LARGO), foco.y * 0.9)
	var micro := Vector2(clampf(foco.x - lado * 1.0, -MEDIO_LARGO, MEDIO_LARGO), foco.y * 0.9) * pb + defensivo * (1.0 - pb)
	var micro_f := float(f["omi"]) * pb + float(f["dmi"]) * (1.0 - pb)
	var msb := normalizado((bx / MEDIO_LARGO) * -lado, -0.7, 0.7) * 0.7 + 0.3
	micro_f *= 0.2 + 0.8 * (pow(msb, 0.8) * pb + pow(1.0 - msb, 0.6) * (1.0 - pb))
	var mf := (float(f["om"]) * pb + float(f["dm"]) * (1.0 - pb)) * 0.7 + normalizado((bx / MEDIO_LARGO) * -lado, -0.8, 0.8) * 0.3
	var mfs := float(f["oms"]) * pb + float(f["dms"]) * (1.0 - pb)
	var r := formacion_adaptada(e["forma"], lado, atras, delante, bajo, alto, by, y_fuerza, micro, micro_f, mf, mfs)
	return Vector2(clampf(r.x, -MEDIO_LARGO, MEDIO_LARGO), clampf(r.y, -MEDIO_ANCHO, MEDIO_ANCHO))

## L AI_GetAdaptedFormationPosition (sin el foco en X, que el original deja a 0).
static func formacion_adaptada(forma: Vector2, lado: float, atras: float, delante: float, bajo: float, alto: float, y_foco: float, y_fuerza: float, micro: Vector2, micro_f: float, mf: float, mfs: float) -> Vector2:
	var p := forma
	if mfs > 0.0:
		var sesgo := curva(clampf(1.0 - absf(p.x * 1.2), 0.0, 1.0), 1.0) * mfs
		p.x = p.x * (1.0 - sesgo) + (mf * 2.0 - 1.0) * sesgo
	p.x = atras + (p.x * 0.5 + 0.5) * (delante - atras)
	p.y = bajo + (p.y * -lado * 0.5 + 0.5) * (alto - bajo)
	var pura := p
	if y_fuerza > 0.0:
		var b := (1.0 - clampf(absf(y_foco - p.y) / absf(alto - bajo), 0.0, 1.0)) * (0.2 + 0.8 * absf(y_foco) / MEDIO_ANCHO) * y_fuerza
		p.y = p.y * (1.0 - b) + y_foco * b
	if micro_f > 0.0:
		var dist := ((micro - pura) * Vector2(1.0, 0.8)).length() / 50.0
		if dist < 1.0:
			var mb := curva(1.0 - dist, 0.3)
			mb += (1.0 - normalizado(absf(dist - 0.15), 0.0, 0.25)) * 0.1
			mb = clampf(mb, 0.0, 1.0) * micro_f
			var mp := Vector2(micro.x, micro.y * 0.6 + p.y * 0.4)
			p = p * (1.0 - mb) + mp * mb
	return p

## L TeamAIController::ApplyOffsideTrap (versión suave: comprime los 4 m alrededor de la línea).
static func trampa_offside(x: float, lado: float, trampa_x: float) -> float:
	var media := 2.0
	var ax := x * lado
	var at := trampa_x * lado
	if ax > at - media:
		var frente := at - media
		var fac := clampf((ax - frente) / (media * 2.0), 0.0, 1.0)
		return (frente + media * fac) * lado
	return x
