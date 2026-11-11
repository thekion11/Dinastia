class_name PerfilColocacion
extends Node
## PERFIL DE CPU DE LAS PIEZAS DEL MOTOR (11-11-2026, sesión 11): ¿qué parte del coste de la colocación sin balón nuestra es nuestra y qué parte es de League?
## Juega partidos completos y mide, por método del motor, los µs totales y las llamadas (tiempo INCLUSIVO: `_estado_league` contiene a `_estado_sin_balon` e `_interferir`).
##   MOTOR=combinado|siempre|league  MOTOR_C_PIEZAS=… N_PARTIDOS=2 MITAD=120 godot --headless --path . res://pruebas/perfil_colocacion.tscn
## Salida: «PERFIL motor=… método µs/paso llamadas/paso»; termina en «FIN. 0 fallos».
const DT := 1.0 / 30.0
const METODOS := ["_estado_league", "_estado_sin_balon", "_interferir", "_forma", "_ia_ataque_sin_balon", "_ia_defensa", "_ia_portador", "_mover_balon", "_mover_jugadores"]
static var us := {}
static var n := {}

static func _t(m: String, t0: int) -> void:
	us[m] = int(us.get(m, 0)) + Time.get_ticks_usec() - t0
	n[m] = int(n.get(m, 0)) + 1

class PerfC extends MotorCombinado:
	func _estado_league(d: float) -> void:
		var t0 := Time.get_ticks_usec(); super(d); PerfilColocacion._t("_estado_league", t0)
	func _estado_sin_balon(d: float) -> void:
		var t0 := Time.get_ticks_usec(); super(d); PerfilColocacion._t("_estado_sin_balon", t0)
	func _interferir() -> void:
		var t0 := Time.get_ticks_usec(); super(); PerfilColocacion._t("_interferir", t0)
	func _forma(p: Dictionary, e: bool) -> Vector3:
		var t0 := Time.get_ticks_usec(); var r := super(p, e); PerfilColocacion._t("_forma", t0); return r
	func _ia_ataque_sin_balon(p: Dictionary) -> Vector3:
		var t0 := Time.get_ticks_usec(); var r := super(p); PerfilColocacion._t("_ia_ataque_sin_balon", t0); return r
	func _ia_defensa(p: Dictionary) -> Vector3:
		var t0 := Time.get_ticks_usec(); var r := super(p); PerfilColocacion._t("_ia_defensa", t0); return r
	func _ia_portador(p: Dictionary) -> void:
		var t0 := Time.get_ticks_usec(); super(p); PerfilColocacion._t("_ia_portador", t0)
	func _mover_balon(d: float) -> void:
		var t0 := Time.get_ticks_usec(); super(d); PerfilColocacion._t("_mover_balon", t0)
	func _mover_jugadores(d: float) -> void:
		var t0 := Time.get_ticks_usec(); super(d); PerfilColocacion._t("_mover_jugadores", t0)

class PerfJ extends MotorJugable:
	func _forma(p: Dictionary, e: bool) -> Vector3:
		var t0 := Time.get_ticks_usec(); var r := super(p, e); PerfilColocacion._t("_forma", t0); return r
	func _ia_ataque_sin_balon(p: Dictionary) -> Vector3:
		var t0 := Time.get_ticks_usec(); var r := super(p); PerfilColocacion._t("_ia_ataque_sin_balon", t0); return r
	func _ia_defensa(p: Dictionary) -> Vector3:
		var t0 := Time.get_ticks_usec(); var r := super(p); PerfilColocacion._t("_ia_defensa", t0); return r
	func _ia_portador(p: Dictionary) -> void:
		var t0 := Time.get_ticks_usec(); super(p); PerfilColocacion._t("_ia_portador", t0)
	func _mover_balon(d: float) -> void:
		var t0 := Time.get_ticks_usec(); super(d); PerfilColocacion._t("_mover_balon", t0)
	func _mover_jugadores(d: float) -> void:
		var t0 := Time.get_ticks_usec(); super(d); PerfilColocacion._t("_mover_jugadores", t0)

func _ready() -> void:
	await get_tree().process_frame
	var cuantos := int(OS.get_environment("N_PARTIDOS")) if OS.get_environment("N_PARTIDOS") != "" else 2
	var mitad := float(OS.get_environment("MITAD")) if OS.get_environment("MITAD") != "" else 120.0
	var cual := OS.get_environment("MOTOR") if OS.get_environment("MOTOR") != "" else "combinado"
	var m := Mundo.new()
	m.generar(["CHI", "ESP", "BRA", "ENG"], 4711)
	var clubes: Array = []
	for liga: Liga in m.ligas:
		if int(liga.div) == 1 and not liga.clubes.is_empty():
			clubes.append(liga.clubes)
	var pasos := 0
	var total := 0
	for k in cuantos:
		var a: Club = (clubes[k % clubes.size()] as Array)[(k * 3) % 18]
		var b: Club = (clubes[(k + 1) % clubes.size()] as Array)[(k * 5 + 1) % 18]
		var raiz := Node3D.new()
		add_child(raiz)
		var sp := PlayerSpawner.new()
		var lista: Array = []
		var l := Puente3D.once(a.once())
		var v := Puente3D.once(b.once())
		lista.append_array(sp.spawn_team(raiz, l["xi"], l["jugadores"], Puente3D.formacion(a.tactica.formacion), true, Puente3D.kit(a), Puente3D.kit_portero(a)))
		lista.append_array(sp.spawn_team(raiz, v["xi"], v["jugadores"], Puente3D.formacion(b.tactica.formacion), false, Puente3D.kit(b), Puente3D.kit_portero(b)))
		var ball := StadiumBuilder.spawn_ball(raiz, Vector3(0, 0.11, 0))
		var motor: MotorJugable = PerfJ.new() if cual == "siempre" else PerfC.new()
		if motor is MotorCombinado and cual == "league":
			for p: String in MotorCombinado.PIEZAS:
				(motor as MotorCombinado).piezas[p] = "league"
		raiz.add_child(motor)
		motor.set_physics_process(false)
		motor.autopiloto = true
		motor.duracion_mitad = mitad
		motor.tacticas = [MotorJugable.tactica_desde(a.tactica), MotorJugable.tactica_desde(b.tactica)]
		motor.preparar(lista, ball, "", 100 + k)
		var t0 := Time.get_ticks_usec()
		var tope := int((mitad * 2.0 * 1.6 + 300.0) / DT)
		var i := 0
		while motor.estado != "fin" and i < tope:
			motor.paso(DT)
			i += 1
		total += Time.get_ticks_usec() - t0
		pasos += i
		raiz.queue_free()
	var cab := "motor=%s piezas=%s" % [cual, (PerfC.new() as MotorCombinado).descripcion_piezas() if cual != "siempre" else "-"]
	print("PERFIL ", cab, " total_us_paso=", snappedf(float(total) / float(pasos), 0.1), " pasos=", pasos)
	for mt in METODOS:
		if n.has(mt):
			print("PERFIL   %-22s %8.1f µs/paso  %6.1f llamadas/paso  %6.2f µs/llamada" % [mt, float(us[mt]) / float(pasos), float(n[mt]) / float(pasos), float(us[mt]) / float(n[mt])])
	print("FIN. 0 fallos")
	get_tree().quit()
