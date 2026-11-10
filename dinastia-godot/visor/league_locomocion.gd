class_name LeagueLocomocion
extends RefCounted
## LA LOCOMOCIÓN VISUAL DE LEAGUE-SOCCER EN EL PARTIDO (10-11-2026, fase 4c de `docs/04_auditorias/MOTOR_LEAGUE_SOCCER_PLAN.md`).
## Solo la usa `MotorLeague` (bandera MOTOR_LEAGUE=1); solo cambia lo que se VE, nunca posiciones, velocidades, el giro del nodo
## (del que dependen alcances y entradas) ni `gesto_hasta`:
##  · el portador conduce con los ciclos con balón del original (`LeagueAnim.CICLOS_CONDUCIR`);
##  · los demás, al arrancar, frenar o girar fuerte, hacen el clip que elige el original (`LeagueMovimiento.elegir`). El giro del
##    cuerpo que trae el clip se compensa en el MODELO (hijo raíz del AnimationPlayer) para no sumarse al del nodo, y al acabar
##    esa compensación se apaga en ~0,1 s (sin saltos). `LS_LOCO=0` apaga las transiciones.

static var transiciones_activas := OS.get_environment("LS_LOCO") != "0"
const GIRO_MIN := 0.6          ## ~35°: por debajo, nuestro giro continuo basta (el original elige 0° o ±20°: paso estable)
const ESPERA := 0.2
const CICLOS := ["parado", "trotar", "correr"]
const CONDUCIR := ["conducir", "correr", "trotar", "conducir_ls", "conducir_ls_rapido"]

static func paso(m: MotorLeague, delta: float) -> void:
	portador(m)
	if not transiciones_activas:
		return
	for p: Dictionary in m.jugadores:
		var en_curso := float(p.get("ls_trans_hasta", 0.0)) > m.t
		var off := float(p.get("ls_off", 0.0))
		if not en_curso and off == 0.0:
			## Lo barato primero: solo los que van con un ciclo normal pueden empezar una transición.
			if String(p.get("anim_actual", "")) in CICLOS:
				_quizas_empezar(m, p)
			continue
		var n: Node3D = p.get("node")
		var modelo: Node3D = p.get("ls_modelo")
		if not is_instance_valid(n) or not is_instance_valid(modelo):
			p["ls_off"] = 0.0
			continue
		if en_curso:
			(p["anim"] as AnimationPlayer).speed_scale = 1.0
			off = angle_difference(n.rotation.y, float(p["ls_yaw0"]))
		else:
			off = off * exp(-25.0 * delta) if absf(off) > 0.002 else 0.0
		p["ls_off"] = off
		modelo.rotation.y = float(p["ls_modelo_base"]) + off

## Copia de la velocidad deseada de `MotorJugable._mover_jugadores` (sin los frenos de duelo, que no cambian la clase de paso).
static func deseada(m: MotorJugable, p: Dictionary, n: Node3D) -> Vector3:
	if not p.has("objetivo") or float(p.get("levanta_hasta", 0.0)) > m.t:
		return Vector3.ZERO
	var obj: Vector3 = p["objetivo"]
	var dif := Vector3(obj.x - n.position.x, 0.0, obj.z - n.position.z)
	var dist := dif.length()
	if dist <= 0.25:
		return Vector3.ZERO
	var tope := (4.4 + float(p["attr"]["rit"]) * 4.2) * (1.0 if bool(p.get("correr", false)) else 0.62) * (0.7 + 0.3 * float(p["aguante"]))
	return dif / dist * minf(tope * float(p.get("freno", 1.0)), dist * 2.5)

static func _quizas_empezar(m: MotorLeague, p: Dictionary) -> void:
	if is_same(p, m.poseedor) or bool(p["por"]) or float(p.get("gesto_hasta", 0.0)) > m.t or float(p.get("mirar_hasta", 0.0)) > m.t:
		return
	var n: Node3D = p.get("node")
	var ap: AnimationPlayer = p.get("anim")
	if not is_instance_valid(n) or not is_instance_valid(ap):
		return
	var v: Vector3 = p["vel"]
	var sp := Vector2(v.x, v.z).length()
	var des := deseada(m, p, n)
	var sp_des := des.length()
	var entra := LeagueMovimiento.rango(sp)
	var sale := LeagueMovimiento.rango(sp_des)
	var rel := angle_difference(n.rotation.y, atan2(des.x, des.z)) if sp_des > 0.1 else 0.0
	var arranca := entra == LeagueMovimiento.IDLE and sale > LeagueMovimiento.IDLE
	var frena := entra > LeagueMovimiento.IDLE and sale == LeagueMovimiento.IDLE
	var gira := entra > LeagueMovimiento.IDLE and sale > LeagueMovimiento.IDLE and absf(rel) >= GIRO_MIN
	if not (arranca or frena or gira) or float(p.get("ls_espera", 0.0)) > m.t:
		return
	preparar(ap)
	var c := LeagueMovimiento.elegir(sp, rel, sp_des)
	if c.is_empty() or LeagueMovimiento.estable(c) or not ap.has_animation(String(c["nombre"])):
		p["ls_espera"] = m.t + ESPERA   ## sin clip que aporte: no se vuelve a buscar en cada fotograma
		return
	var modelo := ap.get_node_or_null(ap.root_node) as Node3D
	if modelo == null or modelo == n:
		return
	if not p.has("ls_modelo_base"):
		p["ls_modelo"] = modelo
		p["ls_modelo_base"] = modelo.rotation.y
	ap.play(String(c["nombre"]), 0.1)
	ap.speed_scale = 1.0
	p["anim_actual"] = String(c["nombre"])
	p["ls_trans_hasta"] = m.t + float(c["largo"])
	p["ls_yaw0"] = n.rotation.y
	var clave := "loco_arranque" if arranca else ("loco_frenada" if frena else "loco_giro")
	m.cuenta_toques[clave] = int(m.cuenta_toques.get(clave, 0)) + 1

static var _preparadas := {}

## Añade los clips de movimiento del original a la biblioteca del jugador (compartida por los de su esqueleto: una vez por
## biblioteca). El prefijo de las pistas se lee de su «correr».
static func preparar(ap: AnimationPlayer) -> void:
	if not ap.has_animation_library(""):
		return
	var lib := ap.get_animation_library("")
	if _preparadas.has(lib.get_instance_id()) or not lib.has_animation("correr"):
		return
	_preparadas[lib.get_instance_id()] = true
	var a := lib.get_animation("correr")
	if a.get_track_count() > 0:
		LeagueAnim.movimiento(lib, String(a.track_get_path(0)).get_slice(":", 0))

## Un gesto de verdad (golpeo, entrada, caída) corta la transición.
static func cortar(p: Dictionary) -> void:
	p["ls_trans_hasta"] = 0.0

## El portador conduce con los ciclos con balón del original según su clase de velocidad (L velocitystate: sprint desde 6,2 m/s),
## al ritmo de su velocidad.
static func portador(m: MotorJugable) -> void:
	var c: Dictionary = m.poseedor
	if not c.is_empty():
		cortar(c)
	if c.is_empty() or float(c.get("gesto_hasta", 0.0)) > m.t or not (String(c.get("anim_actual", "")) in CONDUCIR):
		return
	var sp := Vector2((c["vel"] as Vector3).x, (c["vel"] as Vector3).z).length()
	if sp < 0.5:
		return
	var clave := "conducir_ls_rapido" if sp >= LeagueNucleo.CAMBIO_TROTE_SPRINT else "conducir_ls"
	var ap: AnimationPlayer = c.get("anim")
	if not is_instance_valid(ap) or not ap.has_animation(clave):
		return
	m.call("_anim", c, clave, false)
	ap.speed_scale = clampf(sp / float(LeagueAnim.CICLOS_CONDUCIR[clave][1]), 0.7, 1.4)
