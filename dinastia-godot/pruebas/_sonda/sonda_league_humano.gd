extends Node
## RESPUESTA DEL JUGADOR HUMANO CON LA GUÍA DEL MOVIMIENTO (11-11-2026, fase 4d; `docs/04_auditorias/MOTOR_LEAGUE_SOCCER_PLAN.md` §11).
## Un jugador «manejado» (`ls_humano`) corre a toda velocidad y recibe órdenes bruscas del mando: girar 90°, girar 180°, parar.
## Se mueve el motor SOLO en lo del movimiento (`_mover_jugadores`), sin IA, para aislar la guía. Mide los segundos hasta que la
## velocidad real obedece (rumbo a menos de 20° de lo pedido; o velocidad < 1 m/s al parar). Con `LS_GUIA=0` y con `=1`:
##   LS_GUIA=1 godot --headless --path . res://pruebas/_sonda/sonda_league_humano.tscn
## Salida: «HUMANO …» por prueba y «FIN. N fallos» (falla si la guía retrasa más de 0,15 s a la respuesta del motor de siempre).
const DT := 1.0 / 30.0
var fallos := 0

func _ready() -> void:
	await get_tree().process_frame
	var m := Mundo.new()
	m.generar(["CHI", "ESP", "BRA"], 4711)
	var clubes: Array = []
	for liga: Liga in m.ligas:
		if int(liga.div) == 1:
			clubes.append_array(liga.clubes)
	var medias: Array = []
	for guia in [false, true]:
		LeagueGuia.activa = guia
		var res := {"g90": [], "g180": [], "para": []}
		for k in 3:
			var r := _probar(clubes[k * 7 % clubes.size()], clubes[(k * 7 + 3) % clubes.size()], k)
			for c: String in res:
				(res[c] as Array).append(r[c])
			print("HUMANO guia=", guia, " ", k, " ", r)
		var med := {}
		for c: String in res:
			var s := 0.0
			for v: float in res[c]:
				s += v
			med[c] = s / float((res[c] as Array).size())
		medias.append(med)
		print("HUMANO_MEDIA guia=", guia, " ", med)
	for c: String in medias[0]:
		if float(medias[1][c]) > float(medias[0][c]) + 0.15:
			fallos += 1
			print("FALLO: con la guía el humano tarda más en «", c, "»: ", medias[1][c], " frente a ", medias[0][c])
	print("===== FIN. ", fallos, " fallos =====")
	get_tree().quit()

func _probar(a: Club, b: Club, semilla: int) -> Dictionary:
	var raiz := Node3D.new()
	add_child(raiz)
	var sp := PlayerSpawner.new()
	var lista: Array = []
	var l := Puente3D.once(a.once())
	var v := Puente3D.once(b.once())
	lista.append_array(sp.spawn_team(raiz, l["xi"], l["jugadores"], Puente3D.formacion(a.tactica.formacion), true, Puente3D.kit(a), Puente3D.kit_portero(a)))
	lista.append_array(sp.spawn_team(raiz, v["xi"], v["jugadores"], Puente3D.formacion(b.tactica.formacion), false, Puente3D.kit(b), Puente3D.kit_portero(b)))
	var ball := StadiumBuilder.spawn_ball(raiz, Vector3(0, 0.11, 0))
	var motor := MotorLeague.new()
	raiz.add_child(motor)
	motor.set_physics_process(false)
	motor.autopiloto = true
	motor.preparar(lista, ball, "", 100 + semilla)
	motor.estado = "juego"
	var p: Dictionary = {}
	for q: Dictionary in motor.jugadores:
		q["objetivo"] = Vector3(q["node"].position.x, 0.0, q["node"].position.z)
		if p.is_empty() and not bool(q["por"]) and bool(q["es_local"]):
			p = q
	p["ls_humano"] = true
	var n: Node3D = p["node"]
	n.position = Vector3(0, 0, -30)
	n.rotation.y = 0.0
	p["correr"] = true
	p["aguante"] = 1.0
	var salida := {}
	var fases := [["g90", Vector3(1, 0, 0), 1.2], ["g180", Vector3(-1, 0, 0), 1.2], ["para", Vector3.ZERO, 1.0]]
	var dir := Vector3(0, 0, 1)
	_correr(motor, p, dir, 1.6)
	for f: Array in fases:
		var nueva: Vector3 = f[1]
		var t := _responder(motor, p, nueva, float(f[2]))
		salida[f[0]] = t
		if nueva != Vector3.ZERO:
			_correr(motor, p, nueva, 1.4)
			dir = nueva
	raiz.queue_free()
	return salida

## Corre `seg` segundos hacia `dir` (arranca de parado).
func _correr(motor: MotorLeague, p: Dictionary, dir: Vector3, seg: float) -> void:
	for i in int(seg / DT):
		_paso(motor, p, dir)

## Pide `dir` (ZERO = soltar el stick) y devuelve los segundos hasta que la velocidad real obedece (tope `max_s`).
func _responder(motor: MotorLeague, p: Dictionary, dir: Vector3, max_s: float) -> float:
	for i in int(max_s / DT):
		_paso(motor, p, dir)
		var vel: Vector3 = p["vel"]
		if dir == Vector3.ZERO:
			if vel.length() < 1.0:
				return (i + 1) * DT
		elif vel.length() > 2.0 and absf(angle_difference(atan2(vel.x, vel.z), atan2(dir.x, dir.z))) < 0.35:
			return (i + 1) * DT
	return max_s

func _paso(motor: MotorLeague, p: Dictionary, dir: Vector3) -> void:
	var n: Node3D = p["node"]
	p["objetivo"] = n.position + dir * 3.0 if dir != Vector3.ZERO else n.position
	p["manual"] = dir
	motor.t += DT
	motor._mover_jugadores(DT)
