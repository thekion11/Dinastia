class_name MotorCorner
extends RefCounted
## CÓRNERES POR DESVÍO (03-11-2026, ciclo 26 de la sesión líder). El motor saca ≈2 córneres por partido (real ≈10): un tiro que sale por la línea de fondo es SIEMPRE saque de puerta
## salvo que lo toque un defensor, y casi ningún tiro lo toca. Con `CORNER_DESVIO=p` (0 = como antes) un remate fallado que sale por el fondo es córner con probabilidad `p` (un bloqueo o un
## desvío de la defensa), no saque de puerta. Solo sortea con la bandera encendida (no cambia la huella apagada).
static var P := float(OS.get_environment("CORNER_DESVIO")) if OS.get_environment("CORNER_DESVIO") != "" else 0.0

## ¿Este remate que sale por el fondo fue desviado (córner)? Llamar ANTES de `_cerrar_tiro("fallo")` (que borra el tiro en vuelo).
static func desvio(m: MotorJugable) -> bool:
	var pd := float(m.get_meta("corner_desvio", P))   ## C4 lo pide por metadato (`MejorasC4`); el motor de siempre, solo con la bandera
	return pd > 0.0 and not m._tiro_vivo.is_empty() and m._rng.randf() < pd

## CABEZAZO CON MARCA (ciclo 26): al desviar córneres el cabezazo seguía siendo casi a puerta vacía (7 goles de 32 córneres = 22 %; real ≈3 %). Con `CABEZA_FALLO=f` (0 = como antes) el remate de cabeza
## falla con probabilidad `f` (y `f` + 0,25 si hay un rival a < 1,8 m, tope 0,95): se va fuera por un palo o por encima del larguero. Solo sortea con la bandera encendida.
static var CABEZA := float(OS.get_environment("CABEZA_FALLO")) if OS.get_environment("CABEZA_FALLO") != "" else 0.0

static func cabeza(m: MotorJugable, p: Dictionary, destino: Vector3) -> Vector3:
	if CABEZA <= 0.0:
		return destino
	var f := minf(CABEZA + (0.25 if m._presion(p) < 1.8 else 0.0), 0.95)
	if m._rng.randf() >= f:
		return destino
	var d := destino
	if m._rng.randf() < 0.6:
		d.x = (signf(d.x) if absf(d.x) > 0.3 else 1.0) * (m.PALO + m._rng.randf_range(0.4, 2.5))
	else:
		d.y = m.LARGUERO + m._rng.randf_range(0.4, 1.8)
	return d

## CENTROS (ciclo 32, plan «construir hasta el área» C3): la IA centraba 3 veces en 16 partidos (real ≈25 por partido; ≈2,8 % de los pases), con 0 compañeros en el área. El centro exigía estar a > 17 m del
## eje y a < 20 m de la línea de fondo, con un 55 % de probabilidad. `CENTRO_X`/`CENTRO_Z`/`CENTRO_P` (17 · 20 · 0,55 = como antes) relajan esas tres condiciones. Mismo orden de sorteo que antes.
static var CX := float(OS.get_environment("CENTRO_X")) if OS.get_environment("CENTRO_X") != "" else 17.0
static var CZ := float(OS.get_environment("CENTRO_Z")) if OS.get_environment("CENTRO_Z") != "" else 20.0
static var CP := float(OS.get_environment("CENTRO_P")) if OS.get_environment("CENTRO_P") != "" else 0.55

## Con `CENTRO_ESPERA=s` (segundos; 0 = como antes) el centrador ESPERA a que haya al menos 2 compañeros a < 18 m del arco (máximo `s` segundos desde que entra en la zona de centro): antes el centro salía al instante y
## nadie había llegado al área.
static var ESPERA := float(OS.get_environment("CENTRO_ESPERA")) if OS.get_environment("CENTRO_ESPERA") != "" else 0.0

static func centrar(m: MotorJugable, p: Dictionary, yo: Vector3, arco: Vector3) -> bool:
	var zona := absf(yo.x) > CX and absf(arco.z - yo.z) < CZ
	if ESPERA > 0.0:
		if not zona:
			p.erase("_centro_t0")
		else:
			if not p.has("_centro_t0"):
				p["_centro_t0"] = m.t
			var n := 0
			for q: Dictionary in m.jugadores:
				if q != p and bool(q["es_local"]) == bool(p["es_local"]) and not bool(q["por"]) and m.pos(q).distance_to(arco) < 18.0:
					n += 1
			if n < 2 and m.t - float(p["_centro_t0"]) < ESPERA:
				return false
	return zona and m._rng.randf() < CP
