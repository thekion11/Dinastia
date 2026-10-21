extends Node
## CLAUDE JUEGA DE VERDAD (20-10-2026, pedido del dueño: «en ciertas pruebas
## especiales tú mismo deberías jugar realmente, como experimento»). Un partido
## del DT con el motor real en el que el equipo local lo maneja este guion
## pulsando los MISMOS botones que una persona (stick relativo a la cámara de
## TV, pase, tiro cargado, sprint, cambio de jugador, contener y entradas). No
## toca el motor por dentro: solo `Input`. Al final dice cómo fue el partido y
## lo raro que vio (jugador que no responde, balón atascado, controles muertos).
##   godot --headless --fixed-fps 60 --path . res://pruebas/claude_juega.tscn
##   MITADES=1 (solo la primera parte) · SEMILLA=n (otro partido)
var _vista: VistaEstadio
var _motor: MotorJugable
var _t := 0
var _prev_estado := ""
var _tiro_carga := 0      ## fotogramas con TIRO apretado
var _pase_suelta := 0
var _info := {"frames": 0, "con_balon": 0, "pulsaciones": 0, "pases": 0, "tiros": 0, "entradas": 0,
	"cambios": 0, "atascado": 0, "sin_usuario": 0, "parado_con_stick": 0}
var _quieto := 0
var _pos_prev := Vector3.INF
var _balon_prev := Vector3.INF
var _balon_quieto := 0
var _fin := false
var _apretadas: Dictionary = {}
var _prefs_antes := {}
## El vídeo de gameplay (21-10-2026) hereda de este guion: deja la ceremonia
## (CEREMONIA=1), elige el ritmo (RITMO=rapido|normal|largo) y no cierra al final.
var salir_al_terminar := true

func _ready() -> void:
	var cfg := ConfigFile.new()
	cfg.load(CajonAjustes.RUTA)
	## Se apunta lo que había para dejarlo igual al terminar (las otras pruebas
	## leen el mismo archivo: con el ritmo «rápido» la del acta fallaba).
	for k in ["ceremonia", "intro", "ritmo_partido", "control_equipo", "dificultad_cpu"]:
		_prefs_antes[k] = cfg.get_value(CajonAjustes.SECCION, k) if cfg.has_section_key(CajonAjustes.SECCION, k) else null
	## DIFICULTAD=nivel: contra qué CPU juego (20-10-2026).
	if OS.get_environment("DIFICULTAD") != "":
		cfg.set_value(CajonAjustes.SECCION, "dificultad_cpu", OS.get_environment("DIFICULTAD"))
	var con_ceremonia := OS.get_environment("CEREMONIA") != ""
	cfg.set_value(CajonAjustes.SECCION, "ceremonia", con_ceremonia)
	cfg.set_value(CajonAjustes.SECCION, "intro", con_ceremonia)
	var ritmo := OS.get_environment("RITMO")
	cfg.set_value(CajonAjustes.SECCION, "ritmo_partido", ritmo if ritmo != "" else "rapido")
	cfg.save(CajonAjustes.RUTA)
	var m := Mundo.new()
	m.generar(["CHI"], int(OS.get_environment("SEMILLA")) if OS.get_environment("SEMILLA") != "" else 4711)
	m.mi_club_id = m.ligas[0].clubes[0].id
	Partido.ctx_club_id = m.mi_club_id
	var par := m.proximo_partido()
	var partido := Partido.new(par[0], par[1])
	_vista = VistaEstadio.new()
	add_child(_vista)
	_vista.abrir(par[0], 0.8, par[1], partido)
	_motor = _vista.get("_motor")
	print("CLAUDE JUEGA: %s (yo) vs %s · CPU %s" % [par[0].nombre, par[1].nombre, VistaEstadio.dificultad_cpu_guardada()])

## Mantiene apretadas exactamente estas acciones (con su fuerza) y suelta el resto.
func _mandos(quiero: Dictionary) -> void:
	for a: String in _apretadas.keys():
		if not quiero.has(a):
			Input.action_release(a)
			_apretadas.erase(a)
	for a: String in quiero:
		if not _apretadas.has(a):
			_info["pulsaciones"] += 1
		Input.action_press(a, float(quiero[a]))
		_apretadas[a] = true

## El stick (como una persona): la dirección en el mundo pasada a la pantalla
## con la misma regla que usa el motor (`_a_mundo`), invertida.
func _stick(dir_mundo: Vector3, quiero: Dictionary) -> void:
	dir_mundo.y = 0.0
	if dir_mundo.length() < 0.05:
		return
	dir_mundo = dir_mundo.normalized()
	var d := MotorJugable.dir_ataque(true)
	var ex: Vector3 = _motor._a_mundo(Vector2(1, 0), d)
	var ey: Vector3 = _motor._a_mundo(Vector2(0, 1), d)
	## dir = ex·vx + ey·vy  →  resolver 2x2 en el plano XZ.
	var det := ex.x * ey.z - ey.x * ex.z
	if absf(det) < 0.0001:
		return
	var vx := (dir_mundo.x * ey.z - ey.x * dir_mundo.z) / det
	var vy := (ex.x * dir_mundo.z - dir_mundo.x * ex.z) / det
	var v := Vector2(vx, vy).limit_length(1.0)
	if v.x > 0.05: quiero["jugar_derecha"] = v.x
	if v.x < -0.05: quiero["jugar_izquierda"] = -v.x
	if v.y > 0.05: quiero["jugar_abajo"] = v.y
	if v.y < -0.05: quiero["jugar_arriba"] = -v.y

func _process(_d: float) -> void:
	if _fin:
		return
	_t += 1
	if _motor == null or not is_instance_valid(_vista):
		_informe("la vista del partido se cerró")
		return
	## SIN_MANDO=1: el mismo partido sin tocar el mando (la CPU juega los dos lados), para comparar.
	if OS.get_environment("SIN_MANDO") != "":
		if _t == 5 and _motor.control_equipo >= 0:
			_vista.call("_alternar_control_motor")
		var pa: Partido = _vista.get("partido")
		if pa.terminado_ya or _motor.estado == "fin":
			_informe("final (sin mando)")
		return
	if _t == 5 and _motor.control_equipo < 0:
		_vista.call("_alternar_control_motor")
	if _t < 10:
		return
	var partido: Partido = _vista.get("partido")
	var mitades := int(OS.get_environment("MITADES")) if OS.get_environment("MITADES") != "" else 2
	if partido.terminado_ya or _motor.estado == "fin" or (mitades == 1 and _motor.mitad >= 2):
		_informe("final" if partido.terminado_ya or _motor.estado == "fin" else "fin de la primera parte")
		return
	if _t > 60 * 60 * 12:
		_informe("tope de tiempo (12 min de juego)")
		return
	_info["frames"] += 1
	var quiero := {}
	var u: Dictionary = _motor.usuario
	var est := String(_motor.estado)
	if est != _prev_estado:
		_prev_estado = est
	if u.is_empty():
		if est == "juego":
			_info["sin_usuario"] += 1
		_mandos(quiero)
		return
	var yo: Vector3 = _motor.pos(u)
	var b: Vector3 = _motor.balon.position
	var arco: Vector3 = _motor._arco_rival(u)
	var due: Dictionary = _motor.poseedor
	## Saques: si me toca sacar, toco el pase al tercer segundo (como cualquiera).
	if est == "saque":
		if _motor.apuntando and _motor._t_estado > 1.2:
			quiero["jugar_pase"] = 1.0
		_mandos(quiero)
		return
	if est != "juego":
		_mandos(quiero)
		return
	## ¿Me quedé quieto pidiendo moverme? (controles muertos)
	if _pos_prev != Vector3.INF and _apretadas.has("jugar_derecha") or _apretadas.has("jugar_izquierda") \
			or _apretadas.has("jugar_arriba") or _apretadas.has("jugar_abajo"):
		if _pos_prev != Vector3.INF and yo.distance_to(_pos_prev) < 0.001:
			_quieto += 1
			if _quieto == 90:
				_info["parado_con_stick"] += 1
		else:
			_quieto = 0
	_pos_prev = yo
	## Balón atascado en juego (3 s sin moverse y sin dueño).
	if due.is_empty() and _balon_prev != Vector3.INF and b.distance_to(_balon_prev) < 0.002:
		_balon_quieto += 1
		if _balon_quieto == 180:
			_info["atascado"] += 1
	else:
		_balon_quieto = 0
	_balon_prev = b
	if due == u:
		_con_balon(u, yo, arco, quiero)
	elif due.is_empty():
		## Balón suelto: a por él, corriendo.
		_stick(b - yo, quiero)
		quiero["jugar_sprint"] = 1.0
	elif bool(due["es_local"]):
		## Lo tiene un compañero: me ofrezco por delante, hacia el arco.
		var hueco := _motor.pos(due) + (arco - _motor.pos(due)).normalized() * 12.0 + Vector3(signf(yo.x - _motor.pos(due).x) * 6.0, 0, 0)
		_stick(hueco - yo, quiero)
	else:
		_defender(u, yo, due, quiero)
	_mandos(quiero)

func _con_balon(u: Dictionary, yo: Vector3, arco: Vector3, quiero: Dictionary) -> void:
	_info["con_balon"] += 1
	var dist_arco := yo.distance_to(arco)
	## Tirar: cerca del arco, cargo el tiro unos fotogramas y suelto.
	if _tiro_carga > 0:
		_tiro_carga += 1
		_stick(arco - yo, quiero)
		if _tiro_carga < 14:
			quiero["jugar_tiro"] = 1.0
		else:
			_tiro_carga = 0
			_info["tiros"] += 1
		return
	if dist_arco < 22.0:
		_tiro_carga = 1
		quiero["jugar_tiro"] = 1.0
		_stick(arco - yo, quiero)
		return
	## Presionado: paso a un compañero que esté más adelantado.
	var rival := _motor._rival_mas_cercano(u)
	var apretado := not rival.is_empty() and _motor.pos(rival).distance_to(yo) < 3.0
	if _pase_suelta > 0:
		_pase_suelta -= 1
		return
	if apretado:
		var mejor: Dictionary = {}
		var mejor_nota := -INF
		for q: Dictionary in _motor.jugadores:
			if q == u or not bool(q["es_local"]) or bool(q["por"]):
				continue
			var pq: Vector3 = _motor.pos(q)
			var avance := (arco - yo).normalized().dot(pq - yo)
			var nota := avance - pq.distance_to(yo) * 0.3
			if pq.distance_to(yo) < 30.0 and nota > mejor_nota:
				mejor_nota = nota
				mejor = q
		if not mejor.is_empty():
			_stick(_motor.pos(mejor) - yo, quiero)
			quiero["jugar_pase"] = 1.0
			_pase_suelta = 6
			_info["pases"] += 1
			return
	## Conducir hacia el arco, esquivando un poco al rival que tengo delante.
	var hacia := (arco - yo).normalized()
	if not rival.is_empty() and _motor.pos(rival).distance_to(yo) < 6.0:
		var lado := signf((_motor.pos(rival) - yo).cross(hacia).y)
		hacia = (hacia + Vector3(-hacia.z, 0, hacia.x) * lado * 0.6).normalized()
	_stick(hacia, quiero)
	quiero["jugar_sprint"] = 1.0 if rival.is_empty() or _motor.pos(rival).distance_to(yo) > 5.0 else 0.0
	if quiero["jugar_sprint"] == 0.0:
		quiero.erase("jugar_sprint")

func _defender(u: Dictionary, yo: Vector3, due: Dictionary, quiero: Dictionary) -> void:
	var pr: Vector3 = _motor.pos(due)
	## Si un compañero está mucho más cerca del rival, cambio a él (Q).
	var mas_cerca: Dictionary = {}
	for q: Dictionary in _motor.jugadores:
		if bool(q["es_local"]) and not bool(q["por"]) and q != u and _motor.pos(q).distance_to(pr) + 8.0 < yo.distance_to(pr):
			mas_cerca = q
	if not mas_cerca.is_empty() and _t % 40 == 0:
		quiero["jugar_cambiar"] = 1.0
		_info["cambios"] += 1
		return
	_stick(pr - yo, quiero)
	quiero["jugar_sprint"] = 1.0
	if yo.distance_to(pr) < 2.2:
		## Contener (A) y, de vez en cuando, entrada (B).
		if _t % 50 == 0:
			quiero.erase("jugar_sprint")
			quiero["jugar_tiro"] = 1.0
			_info["entradas"] += 1
		else:
			quiero["jugar_pase"] = 1.0

func _informe(motivo: String) -> void:
	_fin = true
	_mandos({})
	var partido: Partido = _vista.get("partido") if is_instance_valid(_vista) else null
	print("===== CLAUDE JUEGA: INFORME (%s) =====" % motivo)
	if partido != null:
		print("  marcador %s %d-%d %s (minuto %d)" % [partido.local.nombre, partido.goles_local, partido.goles_visita, partido.visita.nombre, partido.minuto])
		print("  remates %d-%d · córners %d-%d · faltas %d-%d · fueras %d-%d" % [partido.remates_local, partido.remates_visita,
			partido.corners_local, partido.corners_visita, partido.faltas_local, partido.faltas_visita, partido.fueras_local, partido.fueras_visita])
	if _motor != null:
		print("  motor: goles %s · tiros %s · pases %s (llegaron %s) · posesión local %.0f %% · tarjetas %s" % [str(_motor.goles),
			str(_motor.tiros), str(_motor.pases), str(_motor.pases_ok), _motor.posesion_local(), str(_motor.tarjetas_motor)])
		print("  mis números (stats del motor): %s" % str(_motor.stats))
	print("  lo que hice: %s" % str(_info))
	var raro: Array = []
	if int(_info["sin_usuario"]) > 60:
		raro.append("%d fotogramas en juego sin jugador que manejar" % _info["sin_usuario"])
	if int(_info["parado_con_stick"]) > 0:
		raro.append("%d veces quieto 1,5 s con el stick apretado" % _info["parado_con_stick"])
	if int(_info["atascado"]) > 0:
		raro.append("%d veces el balón quieto 3 s sin dueño en pleno juego" % _info["atascado"])
	print("  RARO: " + ("nada" if raro.is_empty() else "; ".join(raro)))
	print("===== FIN CLAUDE JUEGA =====")
	var cfg := ConfigFile.new()
	cfg.load(CajonAjustes.RUTA)
	for k: String in _prefs_antes:
		if _prefs_antes[k] == null:
			if cfg.has_section_key(CajonAjustes.SECCION, k):
				cfg.erase_section_key(CajonAjustes.SECCION, k)
		else:
			cfg.set_value(CajonAjustes.SECCION, k, _prefs_antes[k])
	cfg.save(CajonAjustes.RUTA)
	if salir_al_terminar:
		get_tree().quit()
