extends Node
## (9-11) El partido de despedida JUGADO en directo de principio a fin (modo «vivo», en texto; necesita pantalla: xvfb-run): se elige «Jugarlo», se llega al
## final, se vuelve, sale la ceremonia y la taquilla entra. xvfb-run -a godot --path . --rendering-driver opengl3 res://pruebas/prueba_despedida_vivo.tscn
var _n := 0
var _p: Node
var _saldo0 := 0
var _fase := 0

func _ready() -> void:
	var cfg := ConfigFile.new()
	cfg.load(CajonAjustes.RUTA)
	cfg.set_value(Principal.SECCION_SIMULACION, "liga", OS.get_environment("MODO") if OS.get_environment("MODO") != "" else "vivo")
	cfg.save(CajonAjustes.RUTA)
	_p = load("res://escenas/principal.tscn").instantiate()
	add_child(_p)

func _hijo(sig: String) -> Node:
	for h in _p.get_children():
		if h.has_signal(sig):
			return h
	return null

func _process(_d: float) -> void:
	_n += 1
	if _n == 12 and _fase == 0:
		_saldo0 = _p.mundo.mi_club().saldo
		JornadaDespedida.ofrecer(_p)
		_fase = 1
	elif _fase == 1 and _n > 20:
		var q: Node = null   ## (10-11) solo la pregunta de la despedida: antes salen el festejo de fin de liga y los sorteos de copa, que también tienen «elegido»
		for h in _p.get_children():
			if h is EventoDespedida:
				q = h
		if q == null and _n < 700:
			return
		if q == null:
			print("NO SE OFRECIÓ"); print("FIN. 1 fallos"); get_tree().quit(); return
		q.emit_signal("elegido", "jugar")
		_fase = 2
		_n = 30
	elif _fase == 2 and _n > 50:
		var v := _hijo("cerrado")
		if v == null and _n < 1500:
			return   ## el partido en directo tarda en montarse
		if v == null:
			print("NO ABRIÓ EL PARTIDO EN DIRECTO"); print("FIN. 1 fallos"); get_tree().quit(); return
		v.call("_hasta_el_final")
		_fase = 3
		_n = 60
	elif _fase == 3 and _n > 80:
		var v2 := _hijo("cerrado")
		var p: Partido = v2.get("partido")
		print("marcador ", p.goles_local, "-", p.goles_visita, " terminado ", p.terminado_ya)
		if not p.terminado_ya:
			print("FIN. 1 fallos"); get_tree().quit(); return
		v2.emit_signal("cerrado")   ## «Volver»
		_fase = 4
		_n = 90
	elif _fase == 4 and _n > 110:
		var cer := _hijo("terminado")
		if cer == null and _n < 800:
			return
		print("ceremonia ", cer != null)
		if cer != null:
			cer.emit_signal("terminado")
			cer.queue_free()
		_fase = 5
		_n = 120
	elif _fase == 5 and _n > 150:
		var sube: bool = _p.mundo.mi_club().saldo > _saldo0
		print("taquilla ", sube, " despedida_anio ", _p.mundo.prensa.despedida_anio == _p.mundo.anio)
		print("FIN. ", 0 if (sube and _p.mundo.prensa.despedida_anio == _p.mundo.anio) else 1, " fallos")
		get_tree().quit()
