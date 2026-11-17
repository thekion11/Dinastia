extends Node
## SONDA DEL FRENTE 3 (16-11-2026, jugabilidad tipo PES 2020): lo MEDIBLE del partido con el mando, en el motor C4 (el de por defecto).
##   A) RESPUESTA A LA PALANCA (`SoloA`): tiempo a la punta y a 10 m desde parado, frenada, «505» virtual (5 m, giro de 180°, 5 m) y giro
##      de 90°, para el más rápido, el mediano y el más lento del once, sin balón. Referencias reales: 10 m en ~1,76 s, punta ~8,3 m/s,
##      test 505 de élite ~2,2-2,3 s (ver el plan, frente 3).
##   B) PASE POR DIRECCIÓN (`SondaPaseDir`): en partidos IA contra IA, cada segundo, para el portador y 8 direcciones de la palanca:
##      ¿el compañero elegido está donde apuntas? (error angular; obedece = elegido a ≤ 30° cuando hay alguien a ≤ 30°).
##   C) BOT HUMANO (`SondaPaseDir.bot`): en partidos IA contra IA, el local da a menudo el pase «como un humano»: apunta a un compañero
##      libre (ruido de ±10°) y el receptor sale de la palanca; mide si sale al apuntado y si se completa.
##   SOLO=A|B|C  PAISES=CHI,ESP,BRA  N=3 (partidos por parte)  MITAD=120
##   godot --headless --path . res://pruebas/sonda_mando_f3.tscn  → líneas «F3_JSON {…}» y «FIN. N fallos».
const DT := 1.0 / 30.0
const SondaPaseDir := preload("res://pruebas/sonda_pase_dir.gd")

var fallos := 0

func _ready() -> void:
	await get_tree().process_frame
	var solo := OS.get_environment("SOLO")
	var paises: Array[String] = []
	for p in (OS.get_environment("PAISES") if OS.get_environment("PAISES") != "" else "CHI,ESP,BRA").split(",", false):
		paises.append(String(p))
	var n := int(OS.get_environment("N")) if OS.get_environment("N") != "" else 3
	var mitad := float(OS.get_environment("MITAD")) if OS.get_environment("MITAD") != "" else 120.0
	var m := Mundo.new()
	m.generar(paises, 4711)
	var clubes := _clubes(m)
	if solo == "" or solo == "A":
		for i in mini(n, clubes.size()):
			_respuesta_palanca(clubes[i], clubes[(i + 1) % clubes.size()], 300 + i)
	if solo == "" or solo == "B":
		var sb := SondaPaseDir.new()
		for i in n:
			var par := _par(clubes, i)
			var motor := _montar(par[0], par[1], 500 + i, true, mitad, "")
			sb.medir_direccion(motor, DT)
			_desmontar(motor)
		print("F3_JSON ", JSON.stringify({"parte": "B", "res": sb.resumen_dir(), "forma": sb.resumen_forma(), "tiros": sb.resumen_tiros()}))
	if solo == "" or solo == "C":
		var sc := SondaPaseDir.new()
		for i in n:
			var par := _par(clubes, i)
			var motor := _montar(par[0], par[1], 700 + i, true, mitad, "")
			sc.bot(motor, DT, 9100 + i)
			_desmontar(motor)
		print("F3_JSON ", JSON.stringify({"parte": "C", "res": sc.resumen_bot()}))
	print("FIN. %d fallos" % fallos)
	get_tree().quit()

## Un club de primera de cada país (orden 34: nunca un solo equipo).
func _clubes(m: Mundo) -> Array:
	var r: Array = []
	for liga: Liga in m.ligas:
		if int(liga.div) == 1 and not liga.clubes.is_empty():
			r.append(liga.clubes[0])
			if liga.clubes.size() > 3:
				r.append(liga.clubes[3])
	return r

func _par(clubes: Array, i: int) -> Array:
	return [clubes[(i * 2) % clubes.size()], clubes[(i * 2 + 3) % clubes.size()]]

func _montar(a: Club, b: Club, semilla: int, auto: bool, mitad: float, usuario_id: String) -> MotorJugable:
	var raiz := Node3D.new()
	add_child(raiz)
	var sp := PlayerSpawner.new()
	var lista: Array = []
	var l := Puente3D.once(a.once())
	var v := Puente3D.once(b.once())
	lista.append_array(sp.spawn_team(raiz, l["xi"], l["jugadores"], Puente3D.formacion(a.tactica.formacion), true, Puente3D.kit(a), Puente3D.kit_portero(a)))
	lista.append_array(sp.spawn_team(raiz, v["xi"], v["jugadores"], Puente3D.formacion(b.tactica.formacion), false, Puente3D.kit(b), Puente3D.kit_portero(b)))
	var ball := StadiumBuilder.spawn_ball(raiz, Vector3(0, 0.11, 0))
	var motor := MotorFabrica.crear(OS.get_environment("MOTOR_F3") if OS.get_environment("MOTOR_F3") != "" else "combinado_c4")
	raiz.add_child(motor)
	motor.set_physics_process(false)
	motor.autopiloto = auto
	motor.duracion_mitad = mitad
	motor.tacticas = [MotorJugable.tactica_desde(a.tactica), MotorJugable.tactica_desde(b.tactica)]
	motor.preparar(lista, ball, usuario_id, semilla)
	motor.set_meta("partido", "%s (%s) - %s (%s)" % [a.nombre, a.pais, b.nombre, b.pais])
	return motor

func _desmontar(motor: MotorJugable) -> void:
	for acc in SondaPaseDir.ACC:
		Input.action_release(acc)
	motor.get_parent().queue_free()

# ------------------------------------------------------------------ A) respuesta a la palanca

func _respuesta_palanca(a: Club, b: Club, semilla: int) -> void:
	var l := Puente3D.once(a.once())
	var motor := _montar(a, b, semilla, false, 600.0, String(l["xi"][6]))
	motor.bloqueo = true
	var pasos := 0
	while motor.estado != "juego" and pasos < 900:
		if pasos % 20 == 10:
			Input.action_press("jugar_pase")   ## el saque inicial, si lo hace el que manejas
		motor.paso(DT)
		Input.action_release("jugar_pase")
		pasos += 1
	if motor.estado != "juego":
		fallos += 1
		print("FALLO: el partido no arrancó")
		_desmontar(motor)
		return
	## El más rápido, el mediano y el más lento de los de campo del local.
	var campo: Array = []
	for q: Dictionary in motor.jugadores:
		if bool(q["es_local"]) and not bool(q["por"]):
			campo.append(q)
	campo.sort_custom(func(x: Dictionary, y: Dictionary) -> bool: return float(x["attr"]["rit"]) > float(y["attr"]["rit"]))
	for q: Dictionary in [campo[0], campo[campo.size() / 2], campo[campo.size() - 1]]:
		motor._poner_usuario(q)
		var r := {"parte": "A", "partido": motor.get_meta("partido"), "rit": snappedf(float(q["attr"]["rit"]), 0.01)}
		r.merge(_valida(motor, q, _arranque_y_frenada))
		r.merge(_valida(motor, q, _prueba_505))
		r.merge(_valida(motor, q, _giro_90))
		print("F3_JSON ", JSON.stringify(r))
	_desmontar(motor)

## Repite la prueba (hasta 4 veces) si el partido se paró, le llegó el balón o se cambió de jugador en medio.
func _valida(motor: MotorJugable, q: Dictionary, prueba: Callable) -> Dictionary:
	var r := {}
	for _i in 4:
		var t0 := motor.t
		r = prueba.call(motor, q)
		if motor.estado == "juego" and motor.usuario == q and motor.poseedor != q and motor.t - t0 > 1.0 and not r.values().has(-1.0):
			return r
		_esperar_juego(motor)
	r["invalida"] = true
	return r

func _esperar_juego(motor: MotorJugable) -> void:
	_palanca(motor, motor.usuario, Vector3.ZERO, false)
	var pasos := 0
	while motor.estado != "juego" and pasos < 900:
		if pasos % 20 == 10:
			Input.action_press("jugar_pase")
		motor.paso(DT)
		Input.action_release("jugar_pase")
		pasos += 1

## Lo pone quieto lejos del balón, en su campo, mirando al arco rival.
func _colocar(motor: MotorJugable, q: Dictionary, x: float, z: float) -> void:
	var d := MotorJugable.dir_ataque(bool(q["es_local"]))
	var n: Node3D = q["node"]
	n.position = Vector3(x, 0, z * d)
	n.rotation.y = atan2(0.0, d)
	q["vel"] = Vector3.ZERO
	q["aguante"] = 1.0

## Palanca en una dirección del campo (adelante = hacia el arco rival) con o sin sprint.
func _palanca(motor: MotorJugable, q: Dictionary, mundo: Vector3, sprint: bool) -> void:
	for acc in SondaPaseDir.ACC:
		Input.action_release(acc)
	SondaPaseDir.apuntar(mundo, MotorJugable.dir_ataque(bool(q["es_local"])))
	if sprint:
		Input.action_press("jugar_sprint")

func _vel(q: Dictionary) -> Vector3:
	var v: Vector3 = q["vel"]
	v.y = 0.0
	return v

func _arranque_y_frenada(motor: MotorJugable, q: Dictionary) -> Dictionary:
	var d := MotorJugable.dir_ataque(bool(q["es_local"]))
	_colocar(motor, q, -24.0, -40.0)
	var ini := motor.pos(q)
	_palanca(motor, q, Vector3(0, 0, d), true)
	var vs: Array[float] = []
	var t10 := -1.0
	for i in int(3.5 / DT):
		motor.paso(DT)
		vs.append(_vel(q).length())
		if t10 < 0.0 and motor.pos(q).distance_to(ini) >= 10.0:
			t10 = (i + 1) * DT
	var punta: float = vs.max()
	var t90 := -1.0
	for i in vs.size():
		if vs[i] >= 0.9 * punta:
			t90 = (i + 1) * DT
			break
	## Frenada: suelta la palanca a toda carrera.
	_palanca(motor, q, Vector3.ZERO, false)
	var p0 := motor.pos(q)
	var t_para := -1.0
	for i in int(3.0 / DT):
		motor.paso(DT)
		if _vel(q).length() < 0.5:
			t_para = (i + 1) * DT
			break
	return {"punta": snappedf(punta, 0.01), "t_punta90": snappedf(t90, 0.01), "t_10m": snappedf(t10, 0.01),
		"t_frena": snappedf(t_para, 0.01), "m_frena": snappedf(motor.pos(q).distance_to(p0), 0.01)}

## «505» virtual: a toda carrera cruza una línea, a 5 m se invierte la palanca y se cronometra hasta volver a cruzarla.
func _prueba_505(motor: MotorJugable, q: Dictionary) -> Dictionary:
	var d := MotorJugable.dir_ataque(bool(q["es_local"]))
	_colocar(motor, q, -24.0, -40.0)
	_palanca(motor, q, Vector3(0, 0, d), true)
	for _i in int(2.5 / DT):
		motor.paso(DT)
	var linea := motor.pos(q).z * d
	var x0 := motor.pos(q).x
	var t := 0.0
	var invertido := false
	var t_cero := -1.0
	var abre := 0.0
	var vuelta := -1.0
	for _i in int(6.0 / DT):
		motor.paso(DT)
		t += DT
		var z := motor.pos(q).z * d
		abre = maxf(abre, absf(motor.pos(q).x - x0))
		if not invertido and z >= linea + 5.0:
			invertido = true
			_palanca(motor, q, Vector3(0, 0, -d), true)
		if invertido and t_cero < 0.0 and _vel(q).z * d <= 0.0:
			t_cero = t
		if invertido and z <= linea:
			vuelta = t
			break
	return {"t_505": snappedf(vuelta, 0.01), "t_505_parado": snappedf(t_cero, 0.01), "m_abre_giro": snappedf(abre, 0.01)}

## Giro de 90° a toda carrera: hasta que el rumbo esté a ≤ 20° del nuevo y la velocidad mínima en la curva.
func _giro_90(motor: MotorJugable, q: Dictionary) -> Dictionary:
	var d := MotorJugable.dir_ataque(bool(q["es_local"]))
	_colocar(motor, q, -24.0, -40.0)
	_palanca(motor, q, Vector3(0, 0, d), true)
	for _i in int(2.5 / DT):
		motor.paso(DT)
	var nueva := Vector3(1, 0, 0)
	_palanca(motor, q, nueva, true)
	var t_giro := -1.0
	var v_min := 99.0
	for i in int(3.0 / DT):
		motor.paso(DT)
		var v := _vel(q)
		v_min = minf(v_min, v.length())
		if v.length() > 0.5 and rad_to_deg(v.angle_to(nueva)) <= 20.0:
			t_giro = (i + 1) * DT
			break
	_palanca(motor, q, Vector3.ZERO, false)
	return {"t_giro90": snappedf(t_giro, 0.01), "v_min_giro90": snappedf(v_min, 0.01)}
