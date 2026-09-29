extends Node
## Verifica a ojo las 4 siluetas y 4 patrones nuevos del 22-9-2026 (diseñados
## en Figma con booleanas y portados a `ui/escudo.gd`): que carguen sin
## reventar el rasterizador SVG de Godot y que se vean como se esperaba, no
## solo que el banco no tire error.

func _ready() -> void:
	var col := VBoxContainer.new()
	add_child(col)
	var fila := HBoxContainer.new()
	fila.add_theme_constant_override("separation", 14)
	col.add_child(fila)

	var casos := [
		["ojiva", "liso"], ["octogono", "banda"], ["corona", "franjas"], ["laurel", "aro"],
		["clasico", "cruz"], ["circulo", "rombos"], ["escudo", "escamas"], ["penta", "estrella6"],
	]
	var colores := [["#c62828", "#ffffff"], ["#1565c0", "#ffd54f"]]
	for i in casos.size():
		_agregar_escudo(fila, "t%d" % i, casos[i][0], casos[i][1], colores[i % 2][0], colores[i % 2][1])

	## Segunda fila: LA MISMA silueta+patron ("ojiva"+"liso" y "corona"+"franjas",
	## los dos casos ya mostrados arriba) con paletas totalmente distintas -para
	## que se vea a ojo que el color es un parametro, no algo fijo por forma-.
	var fila2 := HBoxContainer.new()
	fila2.add_theme_constant_override("separation", 14)
	col.add_child(fila2)
	var paletas := [
		["#0d47a1", "#ffffff"], ["#2e7d32", "#fdd835"], ["#000000", "#e0e0e0"], ["#6a1b9a", "#00e5ff"],
	]
	for j in paletas.size():
		var forma := "ojiva" if j % 2 == 0 else "corona"
		var patron := "liso" if j % 2 == 0 else "franjas"
		_agregar_escudo(fila2, "r%d" % j, forma, patron, paletas[j][0], paletas[j][1])

func _agregar_escudo(padre: Node, id: String, forma: String, patron: String, col1: String, col2: String) -> void:
	var c := Club.new()
	c.id = id
	c.nombre = id
	c.color1 = col1
	c.color2 = col2
	c.esc_forma = forma
	c.esc_patron = patron
	var tex := Escudo.textura(c, 96)
	var tr := TextureRect.new()
	tr.texture = tex
	tr.custom_minimum_size = Vector2(96, 105)
	tr.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	var caja := VBoxContainer.new()
	caja.add_child(tr)
	var lbl := Label.new()
	lbl.text = "%s+%s\n%s/%s" % [forma, patron, col1, col2]
	lbl.add_theme_font_size_override("font_size", 9)
	caja.add_child(lbl)
	padre.add_child(caja)

var _frame := 0

func _process(_d: float) -> void:
	_frame += 1
	if _frame == 5:
		var img := get_viewport().get_texture().get_image()
		img.save_png("res://pruebas/capturas/pantalla_escudos_nuevos.png")
		print("captura guardada: res://pruebas/pantalla_escudos_nuevos.png")
		print("FIN. 0 fallos")
		get_tree().quit()
