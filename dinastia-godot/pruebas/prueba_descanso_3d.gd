extends Node
## EL DESCANSO CON EL 3D ABIERTO (28-9-2026): el partido en vivo abre el
## estadio, al 45 vuelve al camarín, se da la charla, "Salir a la segunda
## parte" reabre el 3D con el reloj en el 45 (no en el 0) y el partido acaba.
##   godot --headless --path . res://pruebas/prueba_descanso_3d.tscn
var _vivo: PartidoVivo
var _p: Partido
var _fase := 0
var _n := 0
var _min_reapertura := -1

func _ready() -> void:
	var m := Mundo.new()
	m.generar(["CHI"], 5)
	var l := m.ligas[0]
	_p = Partido.new(l.clubes[0], l.clubes[1])
	_vivo = PartidoVivo.new()
	add_child(_vivo)
	_vivo.abrir(_p, l.clubes[0], m.vestuario)

func _vista() -> VistaEstadio:
	for h in _vivo.get_children():
		if h is VistaEstadio and not h.is_queued_for_deletion():
			return h
	return null

func _process(_d: float) -> void:
	_n += 1
	var v := _vista()
	## Acelerar el reloj de la reproducción todo lo que se pueda.
	if _fase == 1 and v != null and v.get("_juego") != null and _min_reapertura < 0:
		_min_reapertura = (v.get("_juego") as MatchPlayback).current_minute()
	if v != null and v.get("_juego") != null:
		var j: MatchPlayback = v.get("_juego")
		if not is_equal_approx(j.seconds_per_minute, 0.02):
			j.elapsed = j.elapsed / j.seconds_per_minute * 0.02
		j.vel_idx = MatchPlayback.VELOCIDADES.size() - 1
		j.seconds_per_minute = 0.02
		if v.get("_intro") != null:
			(v.get("_intro") as Node).set("activa", false)
	match _fase:
		0:
			if bool(_vivo.get("_entretiempo")) and v == null:
				print("DESCANSO: camarín abierto en el %d', sin 3D delante" % _p.minuto)
				_vivo.call("_dar_charla", String(Vestuario.TONOS.keys()[0]))
				_vivo.call("_salir_segunda")
				_fase = 1
		1:
			if _min_reapertura >= 0:
				print("REAPERTURA: el reloj del 3D arranca en el %d'" % _min_reapertura)
				_fase = 2
		2:
			if _p.terminado_ya:
				print("FIN OK: %d-%d en %d fotogramas" % [_p.goles_local, _p.goles_visita, _n])
				get_tree().quit()
	if _n > 20000:
		print("FALLO: fase %d, minuto %d" % [_fase, _p.minuto])
		get_tree().quit()
