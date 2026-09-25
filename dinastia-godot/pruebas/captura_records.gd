extends Node
## Comprueba la pestana "Records" nueva -vRecords() de vistas.js-: rachas,
## marcas del club, goleadores, cara a cara y archivo de planteles, datos que
## Logros ya llevaba por dentro pero que hasta esta tanda no se veian en
## ningun sitio del juego.
##
##   godot --path . --rendering-driver opengl3 res://pruebas/captura_records.tscn

const ESPERA := 14

var _n := 0
var _pantalla: Node

func _ready() -> void:
	_pantalla = load("res://escenas/principal.tscn").instantiate()
	add_child(_pantalla)

func _process(_d: float) -> void:
	_n += 1
	if _n == ESPERA:
		## Dos temporadas jugadas de verdad, dirigiendo cada partido propio, para
		## que se acumulen rachas, marcas y cara a cara reales -Logros.tras_partido()
		## solo anota el partido que diriges en directo, no los simulados-.
		for i in 65:
			var mundo0: Mundo = _pantalla.get("mundo")
			if not mundo0.temporada_en_curso():
				_pantalla.call("_nueva_temporada")
				continue
			_pantalla.call("_dirigir")
			var v := _pantalla.get_children().filter(func(n): return n is PartidoVivo)
			if not v.is_empty():
				v[0].call("_hasta_el_final")
				## Igual que pulsar "Volver al club": esa señal es la que de
				## verdad hace avanzar_semana(partido_ya_jugado) -queue_free()
				## a secas no mueve la semana, y el bucle se quedaria atascado
				## dirigiendo el mismo partido para siempre-.
				v[0].emit_signal("cerrado")
				## queue_free() no actua hasta el siguiente respiro del bucle de
				## eventos, y las 65 vueltas de este for corren en el mismo
				## _process() sin ceder el turno: sin esto se apilan varios
				## PartidoVivo a medio borrar, uno encima del otro, tapando la
				## pantalla entera al final.
				_pantalla.remove_child(v[0])
				v[0].free()
			else:
				_pantalla.call("_avanzar_semana")
		var mundo2: Mundo = _pantalla.get("mundo")
		var lg := mundo2.logros
		print("rachas: ", lg.rachas, "  h2h: ", lg.h2h.size(), " rivales  rec: ", lg.rec.keys())
		var tabs: TabContainer = _pantalla.get("_pestanas")
		for i2 in tabs.get_tab_count():
			if tabs.get_tab_title(i2) == "Récords":
				tabs.current_tab = i2
				break
		_pantalla.call("_refrescar")
	if _n == ESPERA + 4:
		_guardar("res://pruebas/pantalla_records.png")
		get_tree().quit()

func _guardar(ruta: String) -> void:
	var img := get_viewport().get_texture().get_image()
	img.save_png(ruta)
	print("captura guardada: %s (%dx%d)" % [ruta, img.get_width(), img.get_height()])
