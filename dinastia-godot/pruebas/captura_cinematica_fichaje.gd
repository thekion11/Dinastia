extends Node
## LA PRESENTACIÓN DE UN FICHAJE EN EL ESTADIO (29-9-2026, mapa de metas 13):
## una foto de cada uno de los tres planos de la cinemática.
##   godot --path . --rendering-driver opengl3 --resolution 1600x900 res://pruebas/captura_cinematica_fichaje.tscn
var _n := 0
var _p: Node
var _cin: CinematicaFichaje
var _espera := 0
var _fotos := [[1.5, "fichaje_cine_1"], [6.5, "fichaje_cine_2"], [9.8, "fichaje_cine_3"]]
func _ready() -> void:
	_p = load("res://escenas/principal.tscn").instantiate()
	add_child(_p)
func _process(_d: float) -> void:
	_n += 1
	if _n == 10:
		var m: Mundo = _p.get("mundo")
		var mio := m.mi_club()
		var j: Jugador = mio.plantilla[0]
		for x: Jugador in mio.plantilla:
			if x.pos_e != "POR" and x.ovr > j.ovr:
				j = x
		var de: Club = m.ligas[0].clubes[1] if m.ligas[0].clubes[1] != mio else m.ligas[0].clubes[2]
		_cin = CinematicaFichaje.mostrar(_p, m, j, de, true)
		_cin.set_process(false)
	if _cin != null and _n > 14 and not _fotos.is_empty():
		var f: Array = _fotos[0]
		if _cin._t < float(f[0]):
			_cin._t = float(f[0]) - 0.001
			_cin._process(0.002)
			return
		_espera += 1
		if _espera >= 45:
			_espera = 0
			get_viewport().get_texture().get_image().save_png("res://pruebas/%s.png" % String(f[1]))
			_fotos.pop_front()
			if _fotos.is_empty():
				get_tree().quit()
