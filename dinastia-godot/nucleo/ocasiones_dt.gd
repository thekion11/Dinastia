class_name OcasionesDT
extends RefCounted
## LAS OCASIONES JUGABLES DEL DT (26-10-2026, fila 14 de la propuesta de la sesión 4).
##
## Como en New Star Manager: el partido se simula solo y, en 3 a 6 llegadas claras
## de tu equipo, se para y TÚ eliges qué hace el que lleva el balón -pase,
## conducción o tiro-. Esta clase es la parte que no dibuja nada: cuántas
## ocasiones toca, cuándo una llegada es «clara» y qué vale cada opción. La parte
## que se ve (la pausa, los botones, la cámara a pie de campo) es `OcasionJugable`.
##
## LOS PORCENTAJES SALEN DEL MISMO MODELO QUE JUEGA. La lectura de la jugada se hace
## con `MotorLibre`: se le copian las posiciones del césped, se le da el mando del
## que lleva el balón (`tomar_control`) y sus `_opciones()` -la IA de utilidad, con
## las probabilidades de `AccionesJuego` según los atributos- dicen qué vale tirar,
## a quién pasar y si conducir. Así lo que enseña el botón es lo que el juego cree
## de verdad, no un número inventado para la pantalla. Y el resultado no lo decide
## esta clase: lo decide el motor del césped al ejecutar la elección.
##
## Nada aquí usa `Azar`: mirar una ocasión no puede mover el resto de la partida.

## Cuántas ocasiones por partido entero: entre 3 y 6, como pide el diseño.
const CUPO_MIN := 3
const CUPO_MAX := 6
## Una llegada es clara a menos de esta distancia del arco rival (metros)...
const DIST_CLARA := 27.0
## ...sin irse a la esquina (metros desde el centro, a lo ancho)...
const LATERAL_CLARA := 18.0
## ...y con el rival más cercano a más de esto (metros): si lo tiene encima, no
## es una ocasión, es un forcejeo.
const ESPACIO_CLARA := 1.6
## Al final, si faltan ocasiones, se acepta una llegada algo menos clara (nivel 1)
## y, si ni así se llega a las tres del mínimo, cualquier ataque en el último
## tercio (nivel 2): un equipo que apenas pisa el área también tiene sus tres.
const DIST_APURADA := 32.0
const ESPACIO_APURADA := 1.0
const DIST_MINIMO := 40.0
const ESPACIO_MINIMO := 0.8
const LATERAL_MINIMO := 24.0
## Lo que se le deja pensar al DT (segundos reales) y lo que dura como mucho
## toda la ocasión: el encargo pide que cada una sea corta (≤ 15 s).
const SEGUNDOS_ELEGIR := 7.0
const SEGUNDOS_MAX := 15.0
## Decisiones como mucho en una misma ocasión (pase → conducción → tiro).
const PASOS_MAX := 3

## El cupo de este partido. Determinista por partido -la semilla sale de los ids
## de los clubes- y proporcional a lo que queda: un partido que se abre en el 46'
## (tras el descanso en el camarín) no reparte seis ocasiones en media hora.
static func cupo(semilla: int, minuto_inicio: int, minuto_fin: int = 90) -> int:
	var rng := RandomNumberGenerator.new()
	rng.seed = semilla
	var entero := rng.randi_range(CUPO_MIN, CUPO_MAX)
	var queda := clampf(float(minuto_fin - minuto_inicio) / 90.0, 0.0, 1.0)
	if queda <= 0.08:
		return 0
	return clampi(int(round(float(entero) * queda)), 1, CUPO_MAX)

## El primer minuto en el que puede saltar una ocasión y el hueco hasta la
## siguiente: repartidas por el partido, no tres seguidas en el 10'.
## (Medido con la prueba del partido entero: un equipo flojo pisa el área con
## espacio en 9-12 minutos de los 90; con huecos de 15' se quedaba en cuatro.)
static func primer_minuto(semilla: int, minuto_inicio: int) -> int:
	var rng := RandomNumberGenerator.new()
	rng.seed = semilla + 17
	return minuto_inicio + rng.randi_range(2, 9)

static func hueco(minuto: int, minuto_fin: int, restantes: int) -> int:
	if restantes <= 0:
		return 999
	return clampi(int(float(minuto_fin - minuto) / (float(restantes) + 1.5)), 3, 15)

## Cuánto se rebaja el listón: 0 normal, 1 si quedan pocos minutos para las que
## faltan, 2 si peligra el mínimo de tres.
static func nivel(minuto: int, minuto_fin: int, hechas: int, cupo_: int) -> int:
	var quedan := float(minuto_fin - minuto)
	if hechas < mini(CUPO_MIN, cupo_) and quedan < float(mini(CUPO_MIN, cupo_) - hechas) * 6.0:
		return 2
	return 1 if quedan < float(cupo_ - hechas) * 12.0 else 0

## ¿Esta llegada es clara para el listón `nivel` (ver `nivel()`)?
static func es_clara(dist_arco: float, lateral: float, espacio: float, nivel_: int = 0) -> bool:
	match nivel_:
		2: return dist_arco <= DIST_MINIMO and absf(lateral) <= LATERAL_MINIMO and espacio >= ESPACIO_MINIMO
		1: return dist_arco <= DIST_APURADA and absf(lateral) <= LATERAL_CLARA and espacio >= ESPACIO_APURADA
	return dist_arco <= DIST_CLARA and absf(lateral) <= LATERAL_CLARA and espacio >= ESPACIO_CLARA

## LA LECTURA DE LA JUGADA. `posiciones`: id del jugador → posición en el césped
## en el sistema de `MotorLibre` CON TU EQUIPO ATACANDO HACIA +x (quien llama gira
## el campo si hace falta). Devuelve:
##   {"tiro": {prob, u}, "pase": {prob, u, receptor_id, dist}, "conducir": {prob, u},
##    "recomendada": "tiro"|"pase"|"conducir", "dist_arco": m}
## `prob` es la probabilidad de que salga: gol en el tiro, que llegue en el pase,
## que gane metros en la conducción. Las claves que no tienen sentido (tirar desde
## 35 m, nadie a quien pasar) no aparecen.
static func lectura(once_mio: Array, once_rival: Array, posiciones: Dictionary, portador_id: String,
		bono_mio: float = 1.0, bono_rival: float = 1.0) -> Dictionary:
	var ml := MotorLibre.new(once_mio, once_rival, bono_mio, bono_rival, 1)
	var idx := -1
	for i in ml.agentes.size():
		var a: Dictionary = ml.agentes[i]
		var id := (a["j"] as Jugador).id
		if posiciones.has(id):
			a["pos"] = posiciones[id]
		else:
			## Quien no está en el césped (expulsado, sin datos) no debe tapar nada.
			a["pos"] = Vector2(-MotorLibre.MEDIO_L * MotorLibre._dir(int(a["eq"])), MotorLibre.MEDIO_A + 30.0)
		if id == portador_id and int(a["eq"]) == 0:
			idx = i
	if idx < 0:
		return {}
	ml.poseedor = idx
	ml.balon = ml.agentes[idx]["pos"]
	ml.tomar_control(idx)
	var j: Jugador = ml.agentes[idx]["j"]
	var p: Vector2 = ml.agentes[idx]["pos"]
	var pres := ml._presion(p, 0)
	var meta := ml._porteria_rival(0)
	var r := {"dist_arco": p.distance_to(meta)}
	var mejor_u := -INF
	for o: Array in ml._opciones(idx):
		var u := float(o[0])
		var tipo := String(o[1])
		if tipo.begins_with("tiro"):
			var pe := AccionesJuego.prob_exito(j, tipo, {"dist": p.distance_to(meta), "presion": pres, "bono": bono_mio})
			var rel := p - meta
			var pg := AccionesJuego.xg(Vector2(absf(rel.x), rel.y)) * (0.3 + 0.7 * pe) * ml._factor_portero(1) * (1.0 - 0.5 * pres)
			r["tiro"] = {"prob": clampf(pg, 0.01, 0.95), "u": u, "accion": tipo}
		elif tipo.begins_with("pase"):
			if r.has("pase") and float(r["pase"]["u"]) >= u:
				continue
			var k: int = o[2]
			var q: Vector2 = ml.agentes[k]["pos"]
			var d := p.distance_to(q)
			var pe2 := AccionesJuego.prob_exito(j, tipo, {"dist": d, "presion": pres, "bono": bono_mio})
			pe2 *= clampf(0.65 + ml._hueco(p, q, 0) / 8.0, 0.25, 1.0)
			r["pase"] = {"prob": clampf(pe2, 0.02, 0.98), "u": u, "receptor_id": (ml.agentes[k]["j"] as Jugador).id,
				"dist": d, "accion": tipo}
		elif tipo == "conducir":
			var adelante: Vector2 = o[2]
			var pc := clampf(ml._hueco(p, adelante, 0) / 5.0, 0.2, 1.0) * AccionesJuego.prob_exito(j, "conducir", {"presion": pres, "bono": bono_mio})
			r["conducir"] = {"prob": clampf(pc, 0.02, 0.98), "u": u}
		else:
			continue
		if u > mejor_u:
			mejor_u = u
			r["recomendada"] = "conducir" if tipo == "conducir" else ("tiro" if tipo.begins_with("tiro") else "pase")
	return r

## LA PROBABILIDAD DE GOL DEL TIRO EN EL MOTOR 3D. La de `MotorLibre` (su xG) no
## vale aquí: el tiro lo ejecuta `MotorJugable`. Curva ajustada a una sonda del
## 26-10 (2.700 tiros de la ocasión con la misma puntería al azar de su IA, de 9 a
## 30 m, por el centro y escorados, con el mejor y el peor tirador; error típico
## ±7 puntos): ~80 % a 9 m con el mejor tirador, ~30 % a 17 m, ~15 % a 25 m. Con un
## rival TAPANDO la línea de tiro no entra casi nunca (0-2 %); con el rival al
## lado, sin tapar, apenas cambia: lo que pesa es la línea, no la distancia.
##
## Y EN PLENO PARTIDO, MENOS. La curva sale de tiros limpios (solo el portero); en
## partidos enteros (20 semillas, eligiendo siempre lo mismo: 66 tiros y 105
## pases) los defensas se cierran mientras la jugada sucede y el tiro convierte
## ~0,55 de eso. El pase de la lectura (`MotorLibre`) también se pasaba de
## optimista en el césped 3D: llega ~0,66 de lo que dice. Los dos ajustes se
## aplican al enseñar el botón (y la prueba `s5_ocasiones` vigila que cuadren).
const AJUSTE_TIRO_EN_JUEGO := 0.55
const AJUSTE_PASE_3D := 0.66

static func prob_tiro_3d(dist: float, lateral: float, tapada: bool, tiro_attr: float) -> float:
	if tapada:
		return 0.02
	var geo := 0.08 + 0.85 * exp(-(dist - 8.0) / 7.0) + 0.006 * absf(lateral)
	var calidad := 0.65 + 0.35 * clampf((tiro_attr - 0.54) / 0.45, -0.5, 1.2)
	return clampf(geo * calidad, 0.02, 0.9)

## Lo que recomienda el cuerpo técnico, en una sola moneda: la probabilidad de
## que la jugada acabe en gol. Pasar o conducir vale lo que vale el tiro que
## vendría después, por lo que sale el pase o la conducción, con un pequeño
## descuento por lo que puede torcerse en medio.
static func recomendar(lect: Dictionary, gol_tras_pase: float, gol_tras_conducir: float) -> String:
	var mejor := ""
	var mv := -1.0
	for k: String in ["tiro", "pase", "conducir"]:
		if not lect.has(k):
			continue
		var v := float(lect[k]["prob"])
		if k == "pase":
			v *= gol_tras_pase * 0.9
		elif k == "conducir":
			v *= gol_tras_conducir * 0.9
		if v > mv:
			mv = v
			mejor = k
	return mejor

## Del césped 3D (`MotorJugable`: el local ataca hacia +z, x a lo ancho) al
## sistema de la lectura (tu equipo hacia +x).
static func a_plano(pos3d: Vector3, mio_es_local: bool) -> Vector2:
	var d := 1.0 if mio_es_local else -1.0
	return Vector2(pos3d.z * d, pos3d.x * d)
