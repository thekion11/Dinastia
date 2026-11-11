class_name LeagueGuia
extends RefCounted
## LA LOCOMOCIÓN QUE MANDA SOBRE EL CUERPO (11-11-2026, fase 4 del motor de League; `docs/04_auditorias/MOTOR_LEAGUE_SOCCER_PLAN.md` §11).
## Hasta la 4c las animaciones de arranque, frenada y giro eran solo lo que se VE. Aquí también guían el MOVIMIENTO, como en el
## original (L `HumanoidBase::SelectAnim` → el cuerpo hereda el desplazamiento del clip):
##  · mientras dura un clip, la velocidad y el rumbo siguen su recorrido (de la velocidad con la que se entra a la medida en el
##    clip, y el giro de su ángulo de salida, con la curva de un movimiento que arranca y se asienta): los pies no patinan;
##  · el rumbo y la velocidad se mezclan con los que pide el motor (más pegado al clip en la CPU, menos en el jugador, para que
##    responda): en el original el jugador queda «comprometido» con el clip ~0,3 s y aquí solo parcialmente;
##  · si lo que se pide cambia de golpe (el jugador pide otro rumbo, otro defensa se cruza), el clip se corta y manda lo nuevo;
##  · las velocidades van por MARCHAS (3,5 · 5 · carrera propia ~8 m/s, `LeagueMovimiento.rango`): a ritmo de crucero la velocidad
##    se asienta en la marcha en vez de flotar entre dos.
## Va detrás de `MotorLeague` (bandera `MOTOR_LEAGUE=1`): el motor de siempre no lo ve. `LS_GUIA=0` lo apaga; `LS_MARCHAS=0`, solo las
## marchas. Se aplica DESPUÉS de que el motor integre el paso: corrige la velocidad y la posición con la diferencia, así no se toca
## el código del motor de siempre.

static var activa := OS.get_environment("LS_GUIA") != "0"
## `LS_GUIA_C4=0`: en el motor combinado con NUESTRA locomoción (C4) la guía y los clips de arranque/frenada/giro se apagan.
static var en_c4 := OS.get_environment("LS_GUIA_C4") != "0"
static var marchas := OS.get_environment("LS_MARCHAS") != "0"
## 1/s: con qué fuerza se pega la velocidad al clip (e^(−k·dt)). Jugador del usuario: más suave, para que responda.
const K_CPU := 11.0
const K_USUARIO := 5.0
## Si lo que se pide se aleja más de esto del rumbo de salida del clip, se corta (rad): el usuario antes que la CPU.
const CORTE_USUARIO := 0.5
const CORTE_CPU := 2.0
const PAUSA_CORTE := 0.5
const MARCHA_DRIBBLE := 3.5
const MARCHA_WALK := 5.0
const TOLERANCIA := 1.08   ## una marcha nunca sube a un jugador por encima de esto de lo que daba el motor

static var cortes := 0
static var guiados := 0

## Lo anota `LeagueLocomocion._quizas_empezar` al elegir el clip: de dónde sale la guía.
static func empezar(p: Dictionary, c: Dictionary, t: float, yaw_cuerpo: float) -> void:
	if not activa or (p.has("ls_guia") and float((p["ls_guia"] as Dictionary)["hasta"]) > t):
		return   ## (ya hay una guía en curso: no se reinicia a cada revisión)
	var v: Vector3 = p["vel"]
	var sp := Vector2(v.x, v.z).length()
	var v_ent := float(c.get("v_entra", 0.0))
	var v_sal := float(c.get("v_sale", 0.0))
	## El clip decelera o acelera EN PROPORCIÓN (3,4 → 0,9 m/s = ×0,25) cuando se entra en marcha; arrancando, la salida es la suya.
	var fin := v_sal * (sp / v_ent) if v_ent > 0.5 and sp > 0.5 else v_sal
	p["ls_guia"] = {"t0": t, "hasta": t + maxf(float(c["largo"]), 0.12), "dur": maxf(float(c["largo"]), 0.12), "sp0": sp, "fin": fin,
		"h0": atan2(v.x, v.z) if sp > 0.8 else yaw_cuerpo, "ang": float(c["ang"]), "tipo": LeagueCatalogo.tipo_de(c)}

static func _suave(u: float) -> float:
	u = clampf(u, 0.0, 1.0)
	return u * u * (3.0 - 2.0 * u)

## LA DECISIÓN de empezar una guía usa SOLO el estado físico (velocidad, rumbo del nodo, destino): no mira cámara, clips cargados ni
## el cuerpo girado de la capa visual, así el movimiento es el mismo con o sin gráficos (determinismo). Cada `CADENCIA` s por jugador.
const CADENCIA := 0.1
const GIRO_MIN := 0.6

static func decidir(m: MotorJugable, p: Dictionary, n: Node3D) -> void:
	if float(p.get("lg_revisar", 0.0)) > m.t or is_same(p, m.poseedor):
		return
	p["lg_revisar"] = m.t + CADENCIA
	if p.has("ls_guia") and float((p["ls_guia"] as Dictionary)["hasta"]) > m.t:
		return
	var v: Vector3 = p["vel"]
	var sp := Vector2(v.x, v.z).length()
	var des := LeagueLocomocion.deseada(m, p, n)
	var sp_des := des.length()
	var entra := LeagueMovimiento.rango(sp)
	var sale := LeagueMovimiento.rango(sp_des)
	var rel := angle_difference(n.rotation.y, atan2(des.x, des.z)) if sp_des > 0.1 else 0.0
	var arranca := entra == LeagueMovimiento.IDLE and sale > LeagueMovimiento.IDLE
	var frena := entra > LeagueMovimiento.IDLE and sale == LeagueMovimiento.IDLE
	var gira := entra > LeagueMovimiento.IDLE and sale > LeagueMovimiento.IDLE and absf(rel) >= GIRO_MIN
	if not (arranca or frena or gira):
		return
	var c := LeagueMovimiento.elegir(sp, rel, sp_des)
	if c.is_empty() or LeagueMovimiento.estable(c):
		return
	empezar(p, c, m.t, n.rotation.y)

## Se llama tras `MotorJugable._mover_jugadores`.
static func paso(m: MotorJugable, delta: float) -> void:
	if not activa or delta <= 0.0:
		return
	for p: Dictionary in m.jugadores:
		var n: Node3D = p.get("node")
		if not is_instance_valid(n) or float(p.get("levantar_en", 0.0)) > 0.0 or float(p.get("levanta_hasta", 0.0)) > m.t:
			continue
		if float(p.get("gesto_hasta", 0.0)) > m.t or bool(p["por"]):
			p.erase("ls_guia")
			continue
		if not p.has("ls_guia") and float(p.get("ls_espera_g", 0.0)) <= m.t and float(p.get("mirar_hasta", 0.0)) <= m.t:
			decidir(m, p, n)
		var v: Vector3 = p["vel"]
		var nuevo := v
		if p.has("ls_guia") and float((p["ls_guia"] as Dictionary)["hasta"]) > m.t:
			nuevo = _seguir_clip(m, p, v, delta)
		else:
			p.erase("ls_guia")
			if marchas:
				nuevo = _marcha(m, p, n, v, delta)
		if nuevo != v:
			p["vel"] = nuevo
			n.position += (nuevo - v) * delta

## ¿Lo maneja una persona? (el del usuario, o uno marcado para las pruebas)
static func humano(m: MotorJugable, p: Dictionary) -> bool:
	return is_same(p, m.usuario) or bool(p.get("ls_humano", false))

## Sigue el recorrido del clip: rumbo h0 + ang·suave(u / 0,8) y velocidad sp0 → fin con la curva suave.
## El JUGADOR HUMANO (11-11, pedido del líder: la orden del mando no se retrasa por esperar al final del clip): solo se le aplica la
## curva de VELOCIDAD del clip (el rumbo lo manda su stick con la inercia del motor) y el clip se corta en cuanto lo pedido se aparta
## ~30° de adonde iba (CORTE_USUARIO), o al soltar el stick.
static func _seguir_clip(m: MotorJugable, p: Dictionary, v: Vector3, delta: float) -> Vector3:
	var g: Dictionary = p["ls_guia"]
	var u := (m.t - float(g["t0"])) / float(g["dur"])
	var es_humano := humano(m, p)
	var vel := lerpf(float(g["sp0"]), float(g["fin"]), _suave(u))
	var rumbo := float(g["h0"]) + float(g["ang"]) * _suave(u / 0.8)
	var clip := Vector3(sin(rumbo), 0.0, cos(rumbo)) * vel
	## ¿Lo que pide el motor se aleja mucho de adonde va el clip? Entonces manda lo nuevo y el clip se corta.
	var pide: Vector3 = p.get("objetivo", Vector3.ZERO) - (p["node"] as Node3D).position
	pide.y = 0.0
	var corte := CORTE_USUARIO if es_humano else CORTE_CPU
	var desvio := absf(angle_difference(float(g["h0"]) + float(g["ang"]), atan2(pide.x, pide.z))) if pide.length() > 0.5 else 0.0
	if (u > 0.3 or es_humano) and desvio > corte:
		LeagueLocomocion.cortar(p)
		p.erase("ls_guia")
		p["ls_espera_g"] = m.t + PAUSA_CORTE   ## sin pausa, arranca otro clip en el acto y se vuelve a cortar (bucle)
		cortes += 1
		return v
	guiados += 1
	var a := 1.0 - exp(-(K_USUARIO if es_humano else K_CPU) * delta)
	var plano := Vector3(v.x, 0.0, v.z)
	if es_humano:
		## Solo la rapidez: el rumbo sigue siendo el del motor.
		var sp := plano.length()
		if sp < 0.01:
			return v
		return plano * (lerpf(sp, vel, a) / sp) + Vector3(0.0, v.y, 0.0)
	return plano.lerp(clip, a) + Vector3(0.0, v.y, 0.0)

## Marchas: a ritmo de crucero (no frenando ni acelerando, ni llegando al destino) la velocidad se asienta en 3,5 · 5 · la propia.
static func _marcha(m: MotorJugable, p: Dictionary, n: Node3D, v: Vector3, delta: float) -> Vector3:
	var sp := Vector2(v.x, v.z).length()
	if sp < LeagueMovimiento.IDLE_DRIBBLE or sp >= LeagueMovimiento.WALK_SPRINT or not p.has("objetivo"):
		return v   ## parado, en arranque o a toda carrera (su marcha es la suya)
	var obj: Vector3 = p["objetivo"]
	if Vector2(obj.x - n.position.x, obj.z - n.position.z).length() * 2.5 < sp * 1.15:
		return v   ## llegando: el motor frena
	var marcha := MARCHA_WALK if sp >= LeagueMovimiento.DRIBBLE_WALK else MARCHA_DRIBBLE
	marcha = minf(marcha, sp * TOLERANCIA)
	if absf(sp - marcha) < 0.02:
		return v
	var a := 1.0 - exp(-3.0 * delta)
	var objetivo := lerpf(sp, marcha, a)
	return Vector3(v.x, 0.0, v.z) * (objetivo / sp) + Vector3(0.0, v.y, 0.0)

static func reiniciar_cuenta() -> void:
	cortes = 0
	guiados = 0
