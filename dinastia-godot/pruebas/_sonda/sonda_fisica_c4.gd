extends Node
## SONDA DE TRANSICIONES Y FÍSICAS DEL PARTIDO C4 (24-11-2026, orden del dueño: «que las transiciones y las físicas sean realistas»).
## Juega N partidos C4 (clubes de 6 ligas, nunca uno solo) y mide, paso a paso (1/30 s):
##  JUGADORES: aceleración máxima (m/s²: un futbolista real da ~6-8 al arrancar y ~8-10 al frenar), giro por paso (°) a más de 4 m/s, saltos de posición
##  (teletransporte: más de 1,5× lo que da su velocidad), y «patinaje»: pasos en que corre a más de 3 m/s con el clip de idle o casi parado.
##  BALÓN: saltos de velocidad sin que nadie lo toque ni bote (energía regalada), rebotes (cociente de velocidad vertical, real ~0,6-0,75 en césped),
##  rodadura (cuánto frena por segundo en césped, real ~0,5-1 m/s²) y velocidad máxima (tiro real ≤ ~38 m/s).
##   N=6 godot --headless --path . res://pruebas/_sonda/sonda_fisica_c4.tscn
const DT := 1.0 / 30.0
const LIGAS: Array[String] = ["ESP", "ENG", "ITA", "GER", "ARG", "BRA"]
var _m := {}

func _suma(k: String, v: float) -> void:
	var e: Dictionary = _m.get(k, {"n": 0, "s": 0.0, "max": 0.0, "p95": []})
	e["n"] += 1
	e["s"] += v
	e["max"] = maxf(float(e["max"]), v)
	(e["p95"] as Array).append(v)
	_m[k] = e

func _cuenta(k: String, n := 1) -> void:
	_m[k] = int(_m.get(k, 0)) + n

func _ready() -> void:
	await get_tree().process_frame
	var n := int(OS.get_environment("N")) if OS.get_environment("N") != "" else 6
	var mundo := Mundo.new()
	mundo.generar(LIGAS, 2611)
	var por_liga: Array = []
	for liga: Liga in mundo.ligas:
		if int(liga.div) == 1 and liga.clubes.size() >= 10:
			por_liga.append(liga.clubes)
	for k in n:
		var la: Array = por_liga[k % por_liga.size()]
		var lb: Array = por_liga[(k + 1) % por_liga.size()]
		_jugar(la[(k * 3) % la.size()], lb[(k * 5 + 1) % lb.size()], 700 + k)
	_informe(n)
	get_tree().quit()

func _jugar(a: Club, b: Club, semilla: int) -> void:
	var raiz := Node3D.new()
	add_child(raiz)
	var sp := PlayerSpawner.new()
	var lista: Array = []
	var l := Puente3D.once(a.once())
	var v := Puente3D.once(b.once())
	lista.append_array(sp.spawn_team(raiz, l["xi"], l["jugadores"], Puente3D.formacion(a.tactica.formacion), true, Puente3D.kit(a), Puente3D.kit_portero(a)))
	lista.append_array(sp.spawn_team(raiz, v["xi"], v["jugadores"], Puente3D.formacion(b.tactica.formacion), false, Puente3D.kit(b), Puente3D.kit_portero(b)))
	var ball := StadiumBuilder.spawn_ball(raiz, Vector3(0, 0.11, 0))
	var motor: MotorJugable = MotorFabrica.crear("combinado_c4")
	raiz.add_child(motor)
	motor.set_physics_process(false)
	motor.autopiloto = true
	motor.duracion_mitad = 240.0
	motor.tacticas = [MotorJugable.tactica_desde(a.tactica), MotorJugable.tactica_desde(b.tactica)]
	motor.preparar(lista, ball, "", semilla)
	var prev := {}   ## id → [pos, vel]
	var bp := motor.balon.position
	var bv := Vector3.ZERO
	var toque_prev: Variant = null
	var i := 0
	var tope := int((240.0 * 2.0 * 1.6 + 300.0) / DT)
	while motor.estado != "fin" and i < tope:
		motor.paso(DT)
		i += 1
		if motor.estado != "juego":
			prev.clear()
			bp = motor.balon.position
			bv = motor.vel_balon
			continue
		for p: Dictionary in motor.jugadores:
			var id := String(p["id"])
			var pp: Vector3 = motor.pos(p)
			if prev.has(id):
				var q: Array = prev[id]
				var vel := (pp - (q[0] as Vector3)) / DT
				vel.y = 0.0
				var sp_ := vel.length()
				var acc := (vel - (q[1] as Vector3)).length() / DT
				_suma("acel_jugador", acc)
				if acc > 30.0:
					_cuenta("acel_mayor_de_30")
					if int(_m.get("acel_mayor_de_30", 0)) <= 12:
						print("FISICA  tirón %.0f m/s² %s %s t=%.1f vel %.1f→%.1f clip=%s" % [acc, String(p.get("slot_code", "")), motor.estado, motor.t, (q[1] as Vector3).length(), sp_, String((p.get("anim") as AnimationPlayer).current_animation) if is_instance_valid(p.get("anim")) else ""])
				if sp_ > 4.0 and (q[1] as Vector3).length() > 4.0:
					var ang := rad_to_deg(vel.angle_to(q[1] as Vector3))
					_suma("giro_por_paso_a_mas_de_4ms", ang)
				var esperado: float = maxf((q[1] as Vector3).length(), sp_) * DT
				if (pp - (q[0] as Vector3)).length() > 1.5 * esperado + 0.35:
					_cuenta("salto_de_posicion")
				var ap: AnimationPlayer = p.get("anim")
				var clip := String(ap.current_animation) if is_instance_valid(ap) else ""
				if sp_ > 3.0 and clip.to_lower().contains("idle"):
					_cuenta("patina_corriendo_con_clip_idle")
				_cuenta("pasos_jugador")
				prev[id] = [pp, vel]
			else:
				prev[id] = [pp, Vector3.ZERO]
		## Balón: velocidad real entre pasos y qué la cambió.
		var np := motor.balon.position
		var vb := (np - bp) / DT
		var dv := (vb - bv).length()
		var suelo := np.y < 0.16 and bp.y < 0.16
		var tocado: bool = not motor.poseedor.is_empty() or motor.ultimo_toque != toque_prev
		if not tocado:
			if suelo and vb.length() > 1.0 and bv.length() > 1.0:
				_suma("balon_frena_rodando_ms2", (bv.length() - vb.length()) / DT)
			elif np.y > 0.3 and dv / DT > 12.0:
				_suma("balon_aire_salto_ms2", dv / DT)   ## en el aire solo debe cambiar por G, arrastre y efecto
		if vb.length() > 1.0:
			_suma("balon_velocidad", vb.length())
		if bp.y > 0.2 and np.y < 0.16 and bv.y < -2.0 and motor.poseedor.is_empty() and not tocado:
			_suma("rebote_cociente_vertical", absf(vb.y) / absf(bv.y))
		toque_prev = motor.ultimo_toque
		bp = np
		bv = vb
	raiz.queue_free()

func _informe(n: int) -> void:
	print("FISICA %d partidos C4" % n)
	for k: String in _m:
		var e: Variant = _m[k]
		if e is Dictionary:
			var a: Array = e["p95"]
			a.sort()
			print("FISICA %-34s n=%7d  media %7.2f  p95 %7.2f  p99 %7.2f  máx %7.2f" % [k, int(e["n"]), float(e["s"]) / maxf(1.0, float(e["n"])), float(a[int(a.size() * 0.95)]), float(a[int(a.size() * 0.99)]), float(e["max"])])
		else:
			print("FISICA %-34s %d" % [k, int(e)])
