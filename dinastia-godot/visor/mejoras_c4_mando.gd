class_name MejorasC4Mando
extends RefCounted
## EL MANDO EN C4 (16-11-2026, frente 3, jugabilidad tipo PES 2020). Lo que cambia la SENSACIÓN del jugador que manejas: todo APAGADO
## por defecto para que el dueño lo pruebe con el mando (se enciende con la variable de entorno). Medido con `pruebas/sonda_mando_f3.tscn`.

## `C4_PASE_DIR=1`: el pase (y el pase al hueco) va al compañero hacia donde apuntas, como en PES: manda la DIRECCIÓN.
## El de siempre (`_companero_en_direccion`) puntúa `3·cos(ángulo) − 0,03·distancia − 1,2 si la línea está tapada`: cerca del centro
## el coseno casi no cambia (apuntar 25° de lado cuesta lo mismo que 9 m) y una línea tapada pesa como desviarse ~50°, así que a menudo
## sale al que NO apuntabas. Aquí: primero el cono de 30°; si no hay nadie, el de 55°; si tampoco, el de siempre.
static var pase_dir := OS.get_environment("C4_PASE_DIR") == "1"
static var pase_dir_ang := float(OS.get_environment("C4_PASE_DIR_ANG")) if OS.get_environment("C4_PASE_DIR_ANG") != "" else 0.05   ## nota por grado
static var pase_dir_tapada := float(OS.get_environment("C4_PASE_DIR_TAPADA")) if OS.get_environment("C4_PASE_DIR_TAPADA") != "" else 0.6   ## = 12° de desvío

## El compañero en la dirección `dir` (vacío = que decida el de siempre).
static func companero(m: MotorJugable, p: Dictionary, dir: Vector3) -> Dictionary:
	var yo := m.pos(p)
	var local := bool(p["es_local"])
	var d := dir.normalized()
	var mejor30: Dictionary = {}
	var nota30 := -INF
	var mejor55: Dictionary = {}
	var nota55 := -INF
	for q: Dictionary in m.jugadores:
		if q == p or bool(q["es_local"]) != local or bool(q["por"]):
			continue
		var v := m.pos(q) - yo
		v.y = 0.0
		var dist := v.length()
		if dist < 3.0 or dist > 50.0:
			continue
		var ang := rad_to_deg(v.angle_to(d))
		if ang > 55.0:
			continue
		var nota := -ang * pase_dir_ang - dist * 0.02
		if m._linea_tapada(yo, m.pos(q), local):
			nota -= pase_dir_tapada
		if ang <= 30.0:
			if nota > nota30:
				nota30 = nota
				mejor30 = q
		elif nota > nota55:
			nota55 = nota
			mejor55 = q
	return mejor30 if not mejor30.is_empty() else mejor55

## `C4_PUNTA=1`: la palanca ya no topa la velocidad. El de siempre pone el objetivo del que manejas a 3 m y la física limita la marcha a
## `distancia × 2,5` = 7,5 m/s: con el balón o sin él, un jugador rápido (ritmo > 0,74, punta 7,5-8,6 m/s con la IA) corre MÁS LENTO cuando lo
## manejas tú que cuando lo lleva la máquina (medido: punta 7,5 m/s con ritmo 0,76 y 0,97). Con el objetivo a 4 m el tope sube a 10 m/s.
static var punta := OS.get_environment("C4_PUNTA") != "0"   ## (16-11) ENCENDIDA por defecto: era un fallo (la palanca topaba a 7,5 m/s a todos); `C4_PUNTA=0` la apaga
## `C4_GIRO_SECO=1`: al invertir la palanca (> 120°) a carrera, primero FRENA en línea recta y gira casi en el sitio (apoyo y giro, como en
## PES), en vez de trazar una U de ~3 m de ancho como un patinador.
static var giro_seco := OS.get_environment("C4_GIRO_SECO") == "1"
const GIRO_SECO_ANG := 120.0
const GIRO_SECO_V := 0.6   ## por debajo de esta velocidad la física ya no curva: arranca recto hacia la palanca
## `C4_INERCIA=1`: el arranque con PESO. La física de siempre acelera a ritmo fijo (6-8 m/s²) y llega al 90 % de la punta en ~0,9 s; un
## futbolista real sigue una curva v(t) = punta·(1 − e^(−t/τ)) con τ ≈ 0,9-1,1 s (perfiles fuerza-velocidad de Samozino y Morin): 10 m en
## ~1,8-1,9 s y el 90 % de la punta a los ~2 s. Aquí el objetivo del que manejas se acerca para pedir esa curva (también quita el tope de 7,5 m/s).
## Medido (sonda, parte A): τ = 0,9 → 10 m en 1,97-2,33 s (algo lento); τ = 0,8 por defecto.
static var inercia := OS.get_environment("C4_INERCIA") == "1"
static var inercia_tau := float(OS.get_environment("C4_INERCIA_TAU")) if OS.get_environment("C4_INERCIA_TAU") != "" else 0.8

## Retoca el objetivo que puso `_control_usuario` (solo si es el de la palanca: a 3 m en la dirección `manual`).
static func carrera(m: MotorJugable, p: Dictionary, delta: float) -> void:
	if p.is_empty() or not (punta or giro_seco or inercia):
		return
	var man: Vector3 = p.get("manual", Vector3.ZERO)
	if man.length() < 0.5 or not p.has("objetivo"):
		return
	var yo := m.pos(p)
	var obj: Vector3 = p["objetivo"]
	if absf(Vector3(obj.x - yo.x, 0, obj.z - yo.z).length() - 3.0) > 0.05:
		return   ## otra orden (contener, presión, portero…): no se toca
	var vel: Vector3 = p.get("vel", Vector3.ZERO)
	vel.y = 0.0
	if giro_seco and vel.length() > GIRO_SECO_V and rad_to_deg(vel.angle_to(man)) > GIRO_SECO_ANG:
		p["objetivo"] = yo   ## frena recto; cuando baja de GIRO_SECO_V, gira rápido (el giro es más cerrado cuanto más lento)
		return
	if inercia and delta > 0.0:
		var tope := tope_de(m, p)
		var sp := vel.length()
		var quiere := sp + (tope - sp) * clampf(delta / inercia_tau, 0.0, 1.0)
		p["objetivo"] = yo + man.normalized() * maxf(quiere / 2.5, 0.3)
	elif punta:
		p["objetivo"] = yo + man.normalized() * 4.0

## La punta que le deja la física ahora mismo (misma cuenta que `_mover_fisica_gd`).
static func tope_de(m: MotorJugable, p: Dictionary) -> float:
	var tope := (4.4 + float(p["attr"]["rit"]) * 4.2) * (1.0 if bool(p.get("correr", false)) else 0.62) * (0.7 + 0.3 * float(p["aguante"]))
	if m.poseedor == p:
		tope *= 0.88
	tope *= float(p.get("freno", 1.0))
	if float(p.get("freno_duelo_hasta", 0.0)) > m.t:
		tope *= float(p.get("freno_duelo", 1.0))
	return tope
