extends Node
## COMPARAR LOS TRES MOTORES DEL PARTIDO POR DIVERSIÓN (11-11-2026, sesión 11; parte de `comparar_motor_league.gd`).
## Partidos COMPLETOS en autopiloto (dos mitades hasta «fin», sin pantalla) con clubes de 3 PAÍSES distintos (orden 34: nunca un solo
## equipo; cada cruce lleva estilos distintos), con la misma semilla y los mismos onces para cada motor: «siempre» (el nuestro),
## «league» y «combinado». Mide con `MedidorDiversion` las cifras de JUGABILIDAD (ocasiones, regates y duelos, cadenas de pases,
## variedad de goles, cambios de marcador, juego seguido, palos y paradas) y el COSTE de CPU del motor (µs por paso y ms por partido).
##   N_PARTIDOS=6 MITAD=240 MOTORES=siempre,league,combinado PAISES=CHI,ESP,BRA [INVERTIR=1] [MOTOR_C_PIEZAS=locomocion=siempre]
##   godot --headless --path . res://pruebas/comparar_tres_motores.tscn
## Salida: una línea «TRES_JSON {…}» por partido y motor (la lee `herramientas/informe_tres_motores.py` para el informe) y «FIN. N fallos».
## El motor combinado imprime sus piezas (`MOTOR_C_PIEZAS` mide una pieza cada vez: la «ablación» que dice qué pieza gana).
const DT := 1.0 / 30.0

var fallos := 0

func _ready() -> void:
	await get_tree().process_frame
	var n := int(OS.get_environment("N_PARTIDOS")) if OS.get_environment("N_PARTIDOS") != "" else 6
	var mitad := float(OS.get_environment("MITAD")) if OS.get_environment("MITAD") != "" else 240.0
	var motores: PackedStringArray = (OS.get_environment("MOTORES") if OS.get_environment("MOTORES") != "" else "siempre,league,combinado").split(",", false)
	var paises: Array[String] = []
	for p in (OS.get_environment("PAISES") if OS.get_environment("PAISES") != "" else "CHI,ESP,BRA").split(",", false):
		paises.append(String(p))
	for mo in motores:
		if not MotorEleccion.MOTORES.has(mo):
			fallos += 1
			print("FALLO: motor desconocido ", mo)
	var m := Mundo.new()
	m.generar(paises, 4711)
	var pares := _pares(m, n)
	var cpu := {}
	for k in pares.size():
		var par: Array = pares[k]
		for mo in motores:
			var r := _jugar(par[0], par[1], 100 + k, String(mo), mitad)
			r["k"] = k
			print("TRES_JSON ", JSON.stringify(r))
			cpu[mo] = float(cpu.get(mo, 0.0)) + float(r["us_paso"])
	for mo in cpu:
		print("TRES_CPU ", mo, " us_paso_medio=", snappedf(float(cpu[mo]) / float(maxi(pares.size(), 1)), 0.1))
	print("FIN. %d fallos" % fallos)
	get_tree().quit()

## Cruces entre clubes de países distintos (rotando los pares de países) con estilos distintos (`EstiloClub`).
func _pares(m: Mundo, n: int) -> Array:
	var por_pais := {}
	for liga: Liga in m.ligas:
		if int(liga.div) == 1 and not liga.clubes.is_empty():
			por_pais[liga.pais] = liga.clubes
	var paises := por_pais.keys()
	var r: Array = []
	for i in n:
		var pa: Array = por_pais[paises[i % paises.size()]]
		var pb: Array = por_pais[paises[(i + 1) % paises.size()]]
		var ca: Club = pa[(i * 3) % pa.size()]
		var cb: Club = pb[(i * 5 + 1) % pb.size()]
		for k in pb.size():
			var otro: Club = pb[(i * 5 + 1 + k) % pb.size()]
			if EstiloClub.estilo_de(otro) != EstiloClub.estilo_de(ca):
				cb = otro
				break
		var par := [ca, cb]
		if OS.get_environment("INVERTIR") == "1":
			par.reverse()
		r.append(par)
	return r

func _jugar(a: Club, b: Club, semilla: int, motor_id: String, mitad: float) -> Dictionary:
	var raiz := Node3D.new()
	add_child(raiz)
	var sp := PlayerSpawner.new()
	var lista: Array = []
	var l := Puente3D.once(a.once())
	var v := Puente3D.once(b.once())
	lista.append_array(sp.spawn_team(raiz, l["xi"], l["jugadores"], Puente3D.formacion(a.tactica.formacion), true, Puente3D.kit(a), Puente3D.kit_portero(a)))
	lista.append_array(sp.spawn_team(raiz, v["xi"], v["jugadores"], Puente3D.formacion(b.tactica.formacion), false, Puente3D.kit(b), Puente3D.kit_portero(b)))
	var ball := StadiumBuilder.spawn_ball(raiz, Vector3(0, 0.11, 0))
	var motor := MotorFabrica.crear(motor_id)
	raiz.add_child(motor)
	motor.set_physics_process(false)
	motor.autopiloto = true
	motor.duracion_mitad = mitad
	motor.tacticas = [MotorJugable.tactica_desde(a.tactica), MotorJugable.tactica_desde(b.tactica)]
	motor.preparar(lista, ball, "", semilla)
	var med := MedidorDiversion.new(motor)
	var us := 0
	var us_max := 0
	var pasos := 0
	var tope := int((mitad * 2.0 * 1.6 + 300.0) / DT)
	while motor.estado != "fin" and pasos < tope:
		var t0 := Time.get_ticks_usec()
		motor.paso(DT)
		var d := Time.get_ticks_usec() - t0
		us += d
		us_max = maxi(us_max, d)
		med.observar(DT)
		pasos += 1
	if motor.estado != "fin":
		fallos += 1
		print("FALLO: el partido no terminó (", motor_id, ": ", a.nombre, " - ", b.nombre, ")")
	var r := med.resultado()
	r["motor"] = motor_id
	if motor is MotorCombinado:
		r["piezas"] = (motor as MotorCombinado).descripcion_piezas()
	r["partido"] = "%s (%s, %s %s) - %s (%s, %s %s)" % [a.nombre, a.pais, a.tactica.formacion, EstiloClub.estilo_de(a), b.nombre, b.pais, b.tactica.formacion, EstiloClub.estilo_de(b)]
	r["marcador"] = "%d-%d" % [motor.goles[0], motor.goles[1]]
	r["goles"] = int(motor.goles[0]) + int(motor.goles[1])
	r["tiros"] = int(motor.tiros[0]) + int(motor.tiros[1])
	r["pases"] = int(motor.pases[0]) + int(motor.pases[1])
	r["pases_ok"] = int(motor.pases_ok[0]) + int(motor.pases_ok[1])
	r["pasos"] = pasos
	r["us_paso"] = snappedf(float(us) / maxf(float(pasos), 1.0), 0.1)
	r["us_max"] = us_max
	r["ms_partido"] = snappedf(float(us) / 1000.0, 0.1)
	raiz.queue_free()
	return r
