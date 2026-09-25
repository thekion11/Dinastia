extends Node
## Prueba de lo que se agregó a `vEditor`: exportar CSV, el picker de país y
## el botón "🎲 Aleatorio" que repinta el aspecto entero de un jugador.

var _n := 0
var _pantalla: Node

func _ready() -> void:
	_pantalla = load("res://escenas/principal.tscn").instantiate()
	add_child(_pantalla)

func _process(_d: float) -> void:
	_n += 1
	if _n == 12:
		var mundo: Mundo = _pantalla.get("mundo")
		var j: Jugador = mundo.mi_club().plantilla[0]
		var ed := Editor.new(mundo)

		## EXPORTAR CSV
		var csv_liga := ed.exportar_csv(true)
		var csv_todo := ed.exportar_csv(false)
		var n_liga := csv_liga.count("\n") + 1 if csv_liga != "" else 0
		var n_todo := csv_todo.count("\n") + 1 if csv_todo != "" else 0
		print("export mi liga: %d lineas" % n_liga)
		print("export todo el mundo: %d lineas (>= mi liga = %s)" % [n_todo, n_todo >= n_liga])
		print("primera linea de mi liga: %s" % csv_liga.split("\n")[0])
		var r := ed.importar_csv(csv_liga, false)
		print("reimportar lo exportado: filas=%d problemas=%d" % [int(r.get("filas", 0)), (r.get("problemas", []) as Array).size()])

		## PAÍS
		var pais_antes := j.pais
		var otro_pais := "BRA" if pais_antes != "BRA" else "ARG"
		ed.fijar_campo(j, "pais", otro_pais)
		print("pais: %s -> %s (aplicado=%s)" % [pais_antes, otro_pais, j.pais == otro_pais])

		## ALEATORIO
		var look_antes := Cara.look_de(j).duplicate()
		ed.aleatorizar_look(j)
		var look_despues := Cara.look_de(j)
		var cambio := false
		for k in look_antes:
			if look_antes[k] != look_despues.get(k):
				cambio = true
		print("aleatorio cambio el aspecto = %s" % cambio)

		## LA PANTALLA DE VERDAD: se selecciona el mismo jugador y se abre el
		## editor, para ver el picker de pais y el boton nuevo en su sitio.
		_pantalla.set("_ed_jugador", j.id)
		_pantalla.call("_ir_a_pestana", "Editor")
		_pantalla.call("_refrescar")
		print("pantalla del editor pintada sin reventar con un jugador seleccionado")
	if _n == 20:
		var img := get_viewport().get_texture().get_image()
		img.save_png("res://pruebas/pantalla_editor_gaps.png")
		get_tree().quit()
