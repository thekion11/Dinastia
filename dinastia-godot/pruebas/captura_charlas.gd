extends Node
## C6/C7 EN PANTALLA (26-9-2026): la charla uno a uno en la ficha, la entrevista
## al paso de un medio nuevo y la presentación de un fichaje.
##   godot --path . --rendering-driver opengl3 --resolution 1600x900 res://pruebas/captura_charlas.tscn
var _n := 0
var _p: Node
var _abierto: Node

func _ready() -> void:
	_p = load("res://escenas/principal.tscn").instantiate()
	add_child(_p)

func _foto(n: String) -> void:
	get_viewport().get_texture().get_image().save_png("res://pruebas/%s.png" % n)

func _process(_d: float) -> void:
	_n += 1
	var m: Mundo = _p.get("mundo") if _n >= 10 else null
	if _n == 10:
		var j: Jugador = m.mi_club().plantilla[4]
		_p.call("_ver_ficha", j)
		m.charlas.hablar(j, "animar", m.anio, m.semana)
	if _n == 14:
		## Bajar la ficha hasta la charla y pulsar "Exigirle más".
		var ficha: Control = _p.get("_ficha")
		for b in ficha.find_children("*", "Button", true, false):
			if (b as Button).text.contains("Exigirle"):
				(b as Button).emit_signal("pressed")
				var sc := ficha.get_parent()
				while sc != null and not (sc is ScrollContainer):
					sc = sc.get_parent()
				if sc != null:
					(sc as ScrollContainer).scroll_vertical = int((b as Button).global_position.y - ficha.global_position.y) - 60
	if _n == 22:
		_foto("charla_ficha")
		for sem in 60:
			m.prensa.al_paso = {}
			if not m.prensa.revisar_al_paso(m.anio, sem).is_empty():
				break
		_abierto = PieDeCampo.mostrar_al_paso(_p, m.prensa)
	if _n == 28:
		_foto("al_paso")
		_abierto.queue_free()
		var otro: Jugador = m.ligas[0].clubes[4].plantilla[2]
		_abierto = PresentacionFichaje.mostrar(_p, m, otro, m.ligas[0].clubes[4])
	if _n == 34:
		_foto("presentacion_fichaje")
		get_tree().quit()
