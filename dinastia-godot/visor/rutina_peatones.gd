class_name RutinaPeatones
extends RefCounted
## RUTINAS DE LOS PEATONES POR HORA Y BARRIO (M-183, 27-10-2026). Antes la gente solo bajaba a un tercio de madrugada (`TraficoCiudad.faros`).
## Ahora cada barrio (el SECTOR de `RecorridosRed.sector_de`) tiene su curva de gente a lo largo del día:
##   100 Estadio y club · de día, con más movimiento a media mañana y al caer la tarde (entrenos, tienda, museo).
##   200 Centro         · oficinas: hora punta de entrada (8), de salida (18) y la comida (13).
##   300 Este           · compras: de las 10 a las 21, con el pico de la tarde.
##   400 Sur            · residencial: salen al trabajo por la mañana (7-8) y vuelven por la tarde (19).
##   500 Oeste y puerto · turnos: cambio a las 6-7, a las 14-15 y a las 22-23.
##   600 Periferia      · poca gente siempre.
## Y el SENTIDO: por la mañana salen a la calle sobre todo los que caminan hacia el Centro (el trabajo) y por la tarde los que vuelven de él.
## Y la manera de andar: con prisa en las horas punta de los barrios de trabajo (+25 %), paseando a la hora de comer o por la noche (-15 %),
## y los que se paran (móvil, llamada, charla) son más a la hora de comer y por la tarde-noche, y casi nadie en hora punta.
## Cada peatón tiene su azar estable (`hash` de su posición en la lista): el mismo sale a la calle a la misma hora. Estático y sin escena.

## El punto al que se va a trabajar por la mañana (el Centro, sector 200) y del que se vuelve por la tarde.
const TRABAJO := Vector3(-50.0, 0.0, -520.0)
const TOQUE_MS := 2500   ## cada cuánto se repasa a la gente (ms de reloj real)
static var _ultimo_ms := -100000

static func pico(h: float, c: float, w: float) -> float:
	var d := (h - c) / w
	return exp(-d * d)

## Entre 0 y 1: «de día» (sube a las 6-8 h, baja a las 20-23 h).
static func dia(h: float) -> float:
	return smoothstep(5.5, 8.0, h) * (1.0 - smoothstep(20.0, 23.5, h))

## Qué parte de la gente de ese barrio está en la calle a esa hora (0,08..1).
static func densidad(h: float, sector: int) -> float:
	var d := dia(h)
	match sector:
		100:
			return 0.10 + 0.90 * d * (0.55 + 0.45 * maxf(pico(h, 11.0, 2.0), pico(h, 17.0, 2.0)))
		200:
			return 0.10 + 0.90 * clampf(d * 0.4 + maxf(pico(h, 8.0, 1.5), maxf(pico(h, 13.0, 1.2), pico(h, 18.0, 1.6))), 0.0, 1.0)
		300:
			return 0.10 + 0.90 * clampf(smoothstep(9.0, 11.0, h) * (1.0 - smoothstep(20.0, 22.5, h)) * 0.6 + 0.4 * pico(h, 18.0, 2.5), 0.0, 1.0)
		400:
			return 0.10 + 0.90 * clampf(pico(h, 7.5, 1.6) + pico(h, 19.0, 2.2) + 0.3 * d, 0.0, 1.0)
		500:
			return 0.12 + 0.88 * clampf(maxf(pico(h, 6.5, 1.0), maxf(pico(h, 14.5, 1.0), pico(h, 22.5, 1.0))) + 0.4 * d, 0.0, 1.0)
		_:
			return 0.08 + 0.30 * d

## Sentido del flujo: +1 por la mañana (la gente va hacia el trabajo), -1 por la tarde (vuelve), 0 el resto del día.
static func sentido(h: float) -> float:
	return pico(h, 8.0, 1.6) - pico(h, 18.0, 1.8)

## Cuánto pesa que el peatón vaya hacia el trabajo (`coseno` = su rumbo frente a la dirección del trabajo, -1..1) a esa hora: 0,3..1,4.
static func factor_flujo(h: float, coseno: float) -> float:
	return clampf(1.0 - 0.85 * maxf(0.0, -sentido(h) * coseno), 0.15, 1.0)   ## sale menos quien va a contramano de la hora

## ¿Lleva maletín? Quien va al trabajo por la mañana o vuelve de él por la tarde, en hora punta (uno de cada tres, estable por peatón).
static func lleva_maletin(h: float, coseno: float, i: int) -> bool:
	var punta := maxf(pico(h, 8.0, 1.2), pico(h, 18.0, 1.4))
	var rumbo_ok := (h < 12.0 and coseno > 0.3) or (h >= 12.0 and coseno < -0.3)
	return punta > 0.35 and rumbo_ok and posmod(hash([i, 97]), 3) == 0

## ¿Lleva mochila a la espalda? En las horas de colegio (entrada de 7 a 9, salida de 13 a 15,5) la lleva más de la mitad; de día, uno de cada cinco;
## de noche casi nadie. Estable por peatón (`hash`).
static func lleva_mochila(h: float, i: int) -> bool:
	var cole := maxf(pico(h, 8.0, 1.0), pico(h, 14.3, 1.3))
	var prob := lerpf(0.2 * dia(h) + 0.06, 0.6, cole)
	return float(posmod(hash([i, 131]), 1000)) / 1000.0 < prob

## Ritmo de paso: 1 normal, hasta 1,25 en hora punta y hasta 0,85 paseando.
static func prisa(h: float, sector: int) -> float:
	if sector == 600:
		return 1.0
	var punta := maxf(pico(h, 8.0, 1.1), pico(h, 18.0, 1.1))
	var paseo := maxf(pico(h, 13.2, 1.0), pico(h, 21.0, 1.8))
	return clampf(1.0 + 0.25 * punta - 0.15 * paseo, 0.85, 1.25)

## Multiplicador de la probabilidad de pararse a mirar el móvil, llamar o charlar.
static func pausa(h: float, sector: int) -> float:
	var ocio := maxf(pico(h, 13.2, 1.2), pico(h, 20.0, 2.0)) * (1.6 if sector == 300 or sector == 100 else 1.0)
	var punta := maxf(pico(h, 8.0, 1.0), pico(h, 18.0, 1.0))
	return clampf(1.0 + 2.5 * ocio - 0.5 * punta, 0.5, 4.0)

## Repasa la lista de peatones de `trafico` (`TraficoCiudad`) a la hora `hora` (0..24).
## Devuelve {visibles, total, prisa} para las pruebas y el diagnóstico.
static func tick(vehiculos: Array, hora: float) -> Dictionary:
	var visibles := 0
	var total := 0
	var prisa_suma := 0.0
	var i := -1
	for v: Dictionary in vehiculos:
		i += 1
		if not bool(v.get("peaton", false)):
			continue
		var nodo := v.get("nodo") as Node3D
		if nodo == null or not is_instance_valid(nodo):
			continue
		total += 1
		var sector := RecorridosRed.sector_de(nodo.position)
		var r := float(posmod(hash([i, 83]), 1000)) / 1000.0
		var rumbo := Vector3(sin(nodo.rotation.y), 0.0, cos(nodo.rotation.y))
		var al_trabajo := Vector3(TRABAJO.x - nodo.position.x, 0.0, TRABAJO.z - nodo.position.z).normalized()
		var sale := r < densidad(hora, sector) * factor_flujo(hora, rumbo.dot(al_trabajo))   ## más gente hacia el trabajo por la mañana y de vuelta por la tarde
		v["oculto_rut"] = not sale
		nodo.visible = sale and not bool(v.get("oculto", false))
		var f_nuevo := prisa(hora, sector)
		var f_viejo := float(v.get("rut_f", 1.0))
		if absf(f_nuevo - f_viejo) > 0.03:
			v["vel"] = float(v["vel"]) / f_viejo * f_nuevo
			v["rut_f"] = f_nuevo
		v["rut_pausa"] = pausa(hora, sector)
		var con_mochila := lleva_mochila(hora, i) and not lleva_maletin(hora, rumbo.dot(al_trabajo), i)
		if not v.has("mochila_hora") or con_mochila != bool(v["mochila_hora"]):
			v["mochila_hora"] = con_mochila
			PeatonVida.mochila(v, con_mochila)
		var con_maletin := lleva_maletin(hora, rumbo.dot(al_trabajo), i)
		if con_maletin != bool(v.get("maletin", false)):
			v["maletin"] = con_maletin
			PeatonVida.maletin(v, con_maletin)
		if sale:
			visibles += 1
			prisa_suma += float(v.get("rut_f", 1.0))
	return {"visibles": visibles, "total": total, "prisa": prisa_suma / maxf(float(visibles), 1.0)}

## Lo llama la vista de la ciudad en cada fotograma; solo repasa cada TOQUE_MS.
static func tick_si_toca(trafico: Object, hora: float) -> void:
	if trafico == null or OS.get_environment("RUTINA_PEATONES") == "0":   ## para las capturas «antes»
		return
	var ahora := Time.get_ticks_msec()
	if ahora - _ultimo_ms < TOQUE_MS:
		return
	_ultimo_ms = ahora
	tick(trafico.get("_vehiculos"), hora)
