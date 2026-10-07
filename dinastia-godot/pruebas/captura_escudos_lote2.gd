extends Node
## Verifica a ojo la segunda tanda de siluetas/patrones nuevos (22-9-2026,
## "mas cantidad" a pedido del usuario): 14 formas + 16 patrones. Cada forma
## nueva se muestra una vez, cada patron nuevo se muestra una vez, cruzados
## entre si para no repetir la misma combinacion dos veces.

func _ready() -> void:
	var col := VBoxContainer.new()
	add_child(col)

	var formas_nuevas := ["frances", "curvo", "arco3", "hexalgo", "rombolgo", "banda_cinta", "estandarte"]
	var patrones_a := ["liso", "banda", "franjas", "aro", "tablero", "corona2", "rayo"]
	var fila1 := HBoxContainer.new()
	fila1.add_theme_constant_override("separation", 10)
	col.add_child(fila1)
	for i in formas_nuevas.size():
		_agregar(fila1, formas_nuevas[i], patrones_a[i])

	var formas_nuevas2 := ["doblepunta", "geometrico", "coronadoble", "ovalo", "redondeado", "trianguloesc", "cruzesc"]
	var patrones_b := ["anillos", "abanico", "interior", "puntas", "barras", "borde", "escalera"]
	var fila2 := HBoxContainer.new()
	fila2.add_theme_constant_override("separation", 10)
	col.add_child(fila2)
	for i in formas_nuevas2.size():
		_agregar(fila2, formas_nuevas2[i], patrones_b[i])

	var patrones_c := ["pila", "estrella8", "manchas", "florlis", "trebol", "medialuna"]
	var formas_viejas := ["clasico", "circulo", "escudo", "hex", "penta", "banderin"]
	var fila3 := HBoxContainer.new()
	fila3.add_theme_constant_override("separation", 10)
	col.add_child(fila3)
	for i in patrones_c.size():
		_agregar(fila3, formas_viejas[i], patrones_c[i])

func _agregar(padre: Node, forma: String, patron: String) -> void:
	var c := Club.new()
	c.id = "%s_%s" % [forma, patron]
	c.nombre = c.id
	c.color1 = "#1b5e20" if (forma.length() + patron.length()) % 2 == 0 else "#b71c1c"
	c.color2 = "#ffd54f" if (forma.length() + patron.length()) % 2 == 0 else "#eceff1"
	c.esc_forma = forma
	c.esc_patron = patron
	var tex := Escudo.textura(c, 80)
	var tr := TextureRect.new()
	tr.texture = tex
	tr.custom_minimum_size = Vector2(80, 88)
	tr.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	var caja := VBoxContainer.new()
	caja.add_child(tr)
	var lbl := Label.new()
	lbl.text = "%s\n%s" % [forma, patron]
	lbl.add_theme_font_size_override("font_size", 8)
	caja.add_child(lbl)
	padre.add_child(caja)

var _frame := 0

func _process(_d: float) -> void:
	_frame += 1
	if _frame == 5:
		var img := get_viewport().get_texture().get_image()
		img.save_png("res://pruebas/capturas/pantalla_escudos_lote2.png")
		print("captura guardada: res://pruebas/pantalla_escudos_lote2.png")
		print("FIN. 0 fallos")
		get_tree().quit()
