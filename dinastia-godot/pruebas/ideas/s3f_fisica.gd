extends BaseIdea
## s3f · RECORRIDO DE LA FÍSICA DEL PARTIDO (semana 3 del plan, «etapa 5: balón, choques, objetos que no
## se atraviesan», 27-10-2026). El balón bota cada vez menos y se para; rodando frena; el poste y el
## larguero lo devuelven (no se cuelan); dentro de la red se muere sin salir por detrás; y en un partido
## entero ningún par de jugadores se queda uno dentro del otro.

const DT := 1.0 / 60.0

func _probar() -> void:
	_titulo("S3F: la física del partido")
	var r := _motor()
	var motor: MotorJugable = r[0]
	var raiz: Node3D = r[1]
	for p: Dictionary in motor.jugadores:
		(p["node"] as Node3D).position = Vector3(30.0, 0, 0)   ## todos lejos del balón
	_bote(motor)
	_rodar(motor)
	_poste(motor, Vector3(MotorJugable.PALO, 1.0, 0.0), "el poste")
	_poste(motor, Vector3(0.0, MotorJugable.LARGUERO, 0.0), "el larguero")
	_red(motor)
	_cuerpos(motor)
	raiz.queue_free()

## El balón suelto en `p` con velocidad `v`, sin nadie cerca que lo toque.
func _suelto(motor: MotorJugable, p: Vector3, v: Vector3) -> void:
	motor.estado = "juego"
	motor.poseedor = {}
	motor._tiro_vivo = {}
	motor.balon.position = p
	motor.vel_balon = v
	motor.giro_balon = Vector3.ZERO

func _bote(motor: MotorJugable) -> void:
	_suelto(motor, Vector3(0, 3.0, 0), Vector3.ZERO)
	var cumbres: Array[float] = []
	var subiendo := false
	var alto := 0.0
	var parado := -1.0
	for i in int(8.0 / DT):
		motor._mover_balon(DT)
		var y := motor.balon.position.y
		if motor.vel_balon.y > 0.0:
			subiendo = true
			alto = maxf(alto, y)
		elif subiendo:
			cumbres.append(alto)
			subiendo = false
			alto = 0.0
		if parado < 0.0 and y <= MotorJugable.R + 0.001 and absf(motor.vel_balon.y) < 0.01:
			parado = i * DT
	var baja := cumbres.size() >= 2
	for k in range(1, cumbres.size()):
		baja = baja and cumbres[k] < cumbres[k - 1]
	_comprobar(baja and not cumbres.is_empty() and cumbres[0] < 3.0, "desde 3 m bota cada vez menos (%s)" % str(cumbres.map(func(c: float) -> String: return "%.2f" % c)))
	_comprobar(parado > 0.0 and parado < 6.0, "y se queda en el suelo (a los %.1f s)" % parado)

func _rodar(motor: MotorJugable) -> void:
	_suelto(motor, Vector3(-20, MotorJugable.R, 0), Vector3(10, 0, 0))
	var t_parado := -1.0
	for i in int(15.0 / DT):
		motor._mover_balon(DT)
		if motor.vel_balon.length() < 0.05:
			t_parado = i * DT
			break
	var recorrido := motor.balon.position.x + 20.0
	_comprobar(t_parado > 2.0 and t_parado < 12.0 and recorrido > 8.0 and recorrido < 40.0,
		"rodando a 10 m/s frena y se para (%.1f s, %.1f m)" % [t_parado, recorrido])

## Un tiro que cruza la línea de gol justo por `punto` (x, y): rebota hacia el campo, no es gol.
func _poste(motor: MotorJugable, punto: Vector3, que: String) -> void:
	var goles_antes: int = motor.goles[0] + motor.goles[1]
	var linea := MotorJugable.LARGO
	_suelto(motor, Vector3(punto.x, punto.y, linea - 0.3), Vector3(0, 0, 20))
	motor.vel_balon.y = 0.5 * MotorJugable.G * 0.015 / 1.0   ## casi recto
	for i in 6:
		motor._mover_balon(DT)
	var goles: int = motor.goles[0] + motor.goles[1]
	_comprobar(goles == goles_antes and motor.balon.position.z < linea and motor.vel_balon.z < 0.0,
		"%s devuelve el balón al campo (z %.2f, vz %.1f; no es gol)" % [que, motor.balon.position.z, motor.vel_balon.z])

func _red(motor: MotorJugable) -> void:
	var linea := MotorJugable.LARGO
	motor.estado = "juego"
	_suelto(motor, Vector3(0, 1.0, linea + 0.4), Vector3(0, 0, 25))
	motor.estado = "gol"   ## ya es gol: solo la red
	var lejos := 0.0
	for i in int(2.0 / DT):
		motor._mover_balon(DT)
		lejos = maxf(lejos, motor.balon.position.z)
	_comprobar(lejos <= linea + 1.81, "dentro de la red el balón se muere sin salir por detrás (z máx %.2f)" % lejos)

func _cuerpos(motor: MotorJugable) -> void:
	motor._saque_de_centro(true)
	motor.autopiloto = true
	var minimo := INF
	var pares := 0
	for i in 1800:
		motor.paso(1.0 / 30.0)
		if i % 10 != 0 or motor.estado != "juego":
			continue
		var js: Array = motor.jugadores
		for a in js.size():
			for b in range(a + 1, js.size()):
				var pa: Vector3 = (js[a]["node"] as Node3D).position
				var pb: Vector3 = (js[b]["node"] as Node3D).position
				var d := Vector2(pa.x - pb.x, pa.z - pb.z).length()
				minimo = minf(minimo, d)
				pares += 1 if d < MotorJugable.RADIO_CUERPO * 1.6 else 0
	_comprobar(minimo > MotorJugable.RADIO_CUERPO, "en 60 s de partido ningún par queda uno dentro del otro (mínimo %.2f m; radio %.2f)" % [minimo, MotorJugable.RADIO_CUERPO])

func _motor() -> Array:
	var m := Mundo.new()
	m.generar(["CHI"], 4711)
	var a: Club = m.ligas[0].clubes[0]
	var b: Club = m.ligas[0].clubes[1]
	var raiz := Node3D.new()
	add_child(raiz)
	var sp := PlayerSpawner.new()
	var lista: Array = []
	var l := Puente3D.once(a.once())
	var v := Puente3D.once(b.once())
	lista.append_array(sp.spawn_team(raiz, l["xi"], l["jugadores"], Puente3D.formacion(a.tactica.formacion), true, Puente3D.kit(a), Puente3D.kit_portero(a)))
	lista.append_array(sp.spawn_team(raiz, v["xi"], v["jugadores"], Puente3D.formacion(b.tactica.formacion), false, Puente3D.kit(b), Puente3D.kit_portero(b)))
	var ball := StadiumBuilder.spawn_ball(raiz, Vector3(0, 0.11, 0))
	var motor := MotorJugable.new()
	raiz.add_child(motor)
	motor.set_physics_process(false)
	motor.autopiloto = true
	motor.preparar(lista, ball, "", 7)
	return [motor, raiz, a]
