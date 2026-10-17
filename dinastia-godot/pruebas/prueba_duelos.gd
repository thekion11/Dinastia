extends Node3D
## LOS DUELOS CUERPO A CUERPO (16-10-2026). Comprueba en el motor real
## (`MotorJugable`) que:
##   1. en una carrera hombro con hombro tras un balón suelto, con la misma
##      velocidad, el MÁS FUERTE se queda el balón la mayoría de las veces
##      (pero no siempre: hay azar y posición);
##   2. en un partido entero con un once fuerte contra uno débil, el fuerte
##      gana más duelos;
##   3. hay duelos de los tres tipos, faltas por duelo y no se pasan;
##   4. los cuerpos no se atraviesan (pares a menos de 0,45 m).
##   godot --headless --path . res://pruebas/prueba_duelos.tscn
const DT := 1.0 / 30.0
var _fallos := 0
var _m: Mundo

func _ok(c: bool, txt: String) -> void:
	print(("  ok    " if c else "  FALLO ") + txt)
	if not c:
		_fallos += 1

func _ready() -> void:
	_m = Mundo.new()
	_m.generar(["CHI"], 777)
	print("===== PRUEBA DUELOS =====")
	_carreras()
	_partidos()
	print("===== FIN PRUEBA DUELOS: %d fallos =====" % _fallos)
	get_tree().quit(1 if _fallos > 0 else 0)

## Un partido montado como en la sonda del DT (sin pantalla).
func _montar(semilla: int) -> Array:
	var raiz := Node3D.new()
	add_child(raiz)
	var a: Club = _m.ligas[0].clubes[0]
	var b: Club = _m.ligas[0].clubes[1]
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
	motor.tarjetas_reales = true
	motor.preparar(lista, ball, "", semilla)
	return [raiz, motor]

func _fijar(p: Dictionary, fuerza: float) -> void:
	p["fuerza"] = fuerza
	p["equilibrio"] = fuerza
	p["attr"]["rit"] = 0.7
	p["attr"]["reg"] = 0.6
	p["aguante"] = 1.0

## 1. CARRERAS: dos rivales salen juntos, a 0,8 m uno del otro, detrás de un
## balón suelto que rueda hacia delante. Mismo ritmo; uno fuerte, otro débil.
func _carreras() -> void:
	var r: Array = _montar(91)
	var raiz: Node3D = r[0]
	var motor: MotorJugable = r[1]
	var loc: Dictionary = {}
	var vis: Dictionary = {}
	for p: Dictionary in motor.jugadores:
		if bool(p["por"]):
			continue
		if bool(p["es_local"]) and loc.is_empty():
			loc = p
		elif not bool(p["es_local"]) and vis.is_empty():
			vis = p
	var fuera: Array = motor.jugadores.duplicate()
	motor.jugadores = [loc, vis]
	var gana_fuerte := 0
	var decididas := 0
	var contactos := 0
	var n := 40
	for i in n:
		var fuerte_local := i % 2 == 0
		var fuerte_izq := (i / 2) % 2 == 0
		_fijar(loc, 0.8 if fuerte_local else 0.4)
		_fijar(vis, 0.4 if fuerte_local else 0.8)
		var zdir := 1.0 if i % 4 < 2 else -1.0
		var x_loc := -0.42 if fuerte_izq == fuerte_local else 0.42
		for p: Dictionary in [loc, vis]:
			var nd: Node3D = p["node"]
			nd.position = Vector3(x_loc if p == loc else -x_loc, 0, -4.0 * zdir)
			nd.rotation.y = 0.0 if zdir > 0.0 else PI
			p["vel"] = Vector3(0, 0, 6.0 * zdir)
			for k: String in ["contacto_hasta", "gesto_hasta", "freno_duelo_hasta", "enfriar", "regate_hasta"]:
				p[k] = 0.0
			p["empujon"] = Vector3.ZERO
			p["empujon_obj"] = Vector3.ZERO
		motor.estado = "juego"
		motor.mitad = 1
		motor.t = 20.0
		motor.poseedor = {}
		motor.pase_a = {}
		motor.ultimo_toque = {}
		motor.penultimo_toque = {}
		motor._offside = {}
		motor._tiro_vivo = {}
		motor.balon.position = Vector3(0, 0.11, 2.5 * zdir)
		motor.vel_balon = Vector3(0, 0, 5.5 * zdir)
		var antes: int = int(motor.duelos["hombro"]) + int(motor.duelos["dividido"])
		var pasos := 0
		while motor.poseedor.is_empty() and motor.estado == "juego" and pasos < 150:
			motor.paso(DT)
			pasos += 1
		if int(motor.duelos["hombro"]) + int(motor.duelos["dividido"]) > antes:
			contactos += 1
		if motor.poseedor.is_empty():
			continue
		decididas += 1
		if bool(motor.poseedor["es_local"]) == fuerte_local:
			gana_fuerte += 1
	motor.jugadores = fuera
	print("  carreras: %d de %d decididas, el fuerte se queda %d, con contacto %d" % [decididas, n, gana_fuerte, contactos])
	_ok(decididas >= n * 3 / 4, "las carreras terminan con alguien con el balón (%d/%d)" % [decididas, n])
	_ok(contactos >= n / 2, "en la carrera hay choque o balón dividido (%d/%d)" % [contactos, n])
	var pct := float(gana_fuerte) / maxf(float(decididas), 1.0)
	_ok(pct >= 0.65, "el más fuerte gana la mayoría (%.0f %%)" % (pct * 100.0))
	_ok(pct <= 0.95, "pero no siempre (%.0f %%)" % (pct * 100.0))
	raiz.queue_free()

## 2-4. Dos partidos de 2 × 120 s: local fuerte, visita débil.
func _partidos() -> void:
	var g := [0, 0]
	var tot := {}
	var faltas := 0
	var solapes := 0
	var pares := 0
	var np := 2
	for k in np:
		var r: Array = _montar(300 + k)
		var raiz: Node3D = r[0]
		var motor: MotorJugable = r[1]
		motor.duracion_mitad = 120.0
		for p: Dictionary in motor.jugadores:
			p["fuerza"] = 0.8 if bool(p["es_local"]) else 0.4
			p["equilibrio"] = 0.75 if bool(p["es_local"]) else 0.45
		var pasos := 0
		while motor.estado != "fin" and pasos < 30 * 400:
			motor.paso(DT)
			pasos += 1
			if motor.estado == "juego" and pasos % 3 == 0:
				var js: Array = motor.jugadores
				for i in js.size():
					var a: Vector3 = (js[i]["node"] as Node3D).position
					for j in range(i + 1, js.size()):
						var b: Vector3 = (js[j]["node"] as Node3D).position
						pares += 1
						if Vector2(a.x - b.x, a.z - b.z).length() < 0.45:
							solapes += 1
		for p: Dictionary in motor.jugadores:
			g[0 if bool(p["es_local"]) else 1] += int(p.get("duelos_g", 0))
		for kk: String in motor.duelos:
			tot[kk] = int(tot.get(kk, 0)) + int(motor.duelos[kk])
		faltas += int(motor.faltas[0]) + int(motor.faltas[1])
		raiz.queue_free()
	print("  partidos: duelos %s  ganados L %d / V %d  faltas totales %d  solapes %d de %d" % [str(tot), g[0], g[1], faltas, solapes, pares])
	var hombro := float(tot.get("hombro", 0)) / np
	var div := float(tot.get("dividido", 0)) / np
	var agr := float(tot.get("agarron", 0)) / np
	var fd := float(tot.get("faltas", 0)) / np
	_ok(hombro >= 3.0, "hay cargas hombro con hombro (%.1f por partido)" % hombro)
	_ok(div >= 1.0, "hay balones divididos (%.1f por partido)" % div)
	_ok(agr >= 1.0, "hay agarrones (%.1f por partido)" % agr)
	_ok(fd >= 0.5, "hay faltas por duelo (%.1f por partido)" % fd)
	_ok(fd <= 9.0 and float(faltas) / np <= 16.0, "sin pasarse: %.1f faltas de duelo y %.1f en total por partido" % [fd, float(faltas) / np])
	var pg := float(g[0]) / maxf(float(g[0] + g[1]), 1.0)
	_ok(pg >= 0.6, "el once fuerte gana más duelos (%.0f %%)" % (pg * 100.0))
	_ok(float(solapes) / maxf(float(pares), 1.0) < 0.002, "los cuerpos no se atraviesan (%.3f %%)" % (100.0 * solapes / maxf(float(pares), 1.0)))
