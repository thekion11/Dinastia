class_name ProbarNativoSinBalon
extends RefCounted
## La colocación sin balón de League en C++ (`league_calcular_sin_balon`) = su gemela `MotorLeague._calcular_sin_balon_gd` (16-11-2026, paso a C++, opción B
## del dueño; lo llama `probar_nativo.gd`): en partidos reales (motor combinado C4, jugadores 3D) se calculan las dos en CADA llamada sobre el mismo estado
## (`MotorLeague.comparar_sb`) y se comparan byte a byte. También las parejas de duelo (`duelos_parejas` frente a `_parejas_gd`, `MotorJugable.comparar_duelos`). Tres cruces con clubes de países distintos. Devuelve {fallos, textos}.

const DT := 1.0 / 30.0
const PASOS := 2400

static func _jugar(raiz: Node3D, a: Club, b: Club, semilla: int) -> void:
	var r := Node3D.new()
	raiz.add_child(r)
	var sp := PlayerSpawner.new()
	var lista: Array = []
	var l := Puente3D.once(a.once())
	var v := Puente3D.once(b.once())
	lista.append_array(sp.spawn_team(r, l["xi"], l["jugadores"], Puente3D.formacion(a.tactica.formacion), true, Puente3D.kit(a), Puente3D.kit_portero(a)))
	lista.append_array(sp.spawn_team(r, v["xi"], v["jugadores"], Puente3D.formacion(b.tactica.formacion), false, Puente3D.kit(b), Puente3D.kit_portero(b)))
	var ball := StadiumBuilder.spawn_ball(r, Vector3(0, 0.11, 0))
	var motor := MotorCombinado.new()
	r.add_child(motor)
	motor.set_physics_process(false)
	motor.autopiloto = true
	motor.duracion_mitad = 120.0
	motor.tacticas = [MotorJugable.tactica_desde(a.tactica), MotorJugable.tactica_desde(b.tactica)]
	motor.preparar(lista, ball, "", semilla)
	for i in PASOS:
		if motor.estado == "fin":
			break
		motor.paso(DT)
	r.queue_free()

static func probar(nat: Object, raiz: Node3D) -> Dictionary:
	var fallos: Array[String] = []
	var textos: Array[String] = []
	if nat == null or not nat.has_method("league_calcular_sin_balon"):
		fallos.append("la extensión no tiene league_calcular_sin_balon")
		return {"fallos": fallos, "textos": textos}
	var m := Mundo.new()
	m.generar(["BRA", "ESP", "ENG"], 1717)
	var ligas: Array = []
	for liga: Liga in m.ligas:
		if int(liga.div) == 1 and liga.clubes.size() >= 8:
			ligas.append(liga.clubes)
	var cruces := [[(ligas[0] as Array)[2], (ligas[1] as Array)[5]], [(ligas[1] as Array)[0], (ligas[2] as Array)[7]], [(ligas[2] as Array)[3], (ligas[0] as Array)[4]]]
	for k in cruces.size():
		var a: Club = cruces[k][0]
		var b: Club = cruces[k][1]
		MotorLeague.comparar_sb = true
		MotorLeague.sb_comparados = 0
		MotorLeague.sb_distintos = 0
		MotorJugable.comparar_duelos = true
		MotorJugable.duelos_comparados = 0
		MotorJugable.duelos_distintos = 0
		MotorJugable.comparar_disputas = true
		MotorJugable.disputas_comparadas = 0
		MotorJugable.disputas_distintas = 0
		_jugar(raiz, a, b, 500 + k)
		MotorLeague.comparar_sb = false
		MotorJugable.comparar_duelos = false
		MotorJugable.comparar_disputas = false
		if MotorJugable.disputas_distintas > 0 or MotorJugable.disputas_comparadas < 1000:
			fallos.append("disputas %s - %s: distintas en %d de %d pasos" % [a.nombre, b.nombre, MotorJugable.disputas_distintas, MotorJugable.disputas_comparadas])
		textos.append("disputas (enfriar y balón suelto) %s - %s: C++ = GDScript en %d pasos" % [a.nombre, b.nombre, MotorJugable.disputas_comparadas])
		if MotorJugable.duelos_distintos > 0 or MotorJugable.duelos_comparados < 1000:
			fallos.append("parejas de duelo %s - %s: distintas en %d de %d pasos" % [a.nombre, b.nombre, MotorJugable.duelos_distintos, MotorJugable.duelos_comparados])
		textos.append("parejas de duelo %s - %s: C++ = GDScript en %d pasos" % [a.nombre, b.nombre, MotorJugable.duelos_comparados])
		if MotorLeague.sb_distintos > 0 or MotorLeague.sb_comparados < 1000:
			fallos.append("sin balón %s - %s: distinta en %d de %d llamadas" % [a.nombre, b.nombre, MotorLeague.sb_distintos, MotorLeague.sb_comparados])
		textos.append("sin balón %s - %s: C++ = GDScript en %d llamadas (distintas: %d)" % [a.nombre, b.nombre, MotorLeague.sb_comparados, MotorLeague.sb_distintos])
	return {"fallos": fallos, "textos": textos}
