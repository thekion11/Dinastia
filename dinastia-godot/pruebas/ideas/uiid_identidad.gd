extends BaseIdea
## IDENTIDAD, EDITOR Y ESTADIO: LO QUE SE VE (25-10-2026, paquete uiid). Las rejillas de forma, patrón y
## estampado llevan la miniatura de cada opción (y pintarlas no cambia el club), la vista previa del
## escudo en una tinta, las cachés acotadas, el editor que repinta la cara al tocar un rasgo y las filas
## que ya no separan un rótulo de su control.

var _p: Node

func _probar() -> void:
	_titulo("IDENTIDAD, EDITOR Y ESTADIO (uiid)")
	_p = load("res://escenas/principal.tscn").instantiate()
	add_child(_p)
	var m: Mundo = _p.get("mundo")
	var mio := m.mi_club()
	_identidad(mio)
	_caches(mio)
	_editor(m, mio)
	_estadio(m, mio)

func _identidad(mio: Club) -> void:
	var forma_antes := Escudo.forma_de(mio)
	var patron_antes := Escudo.patron_de(mio)
	_p.set("_secc_gente", "identidad")
	_p.call("_limpiar", _p.get("_lista_gente"))
	_p.call("_pintar_identidad", mio)
	var lista: Control = _p.get("_lista_gente")
	var con_icono := 0
	var botones_forma: Array[Button] = []
	for b: Button in lista.find_children("*", "Button", true, false):
		if b.icon != null and b.text == "" and b.toggle_mode:
			con_icono += 1
	## 26 formas + 30 patrones + 12 estampados de identidad + 12 × 3 camisetas.
	var esperado := Escudo.FORMAS.size() + Escudo.PATRONES.size() + Jersey.KITS.size() * 4
	_comprobar(con_icono >= esperado, "botones con miniatura: %d (se esperan al menos %d)" % [con_icono, esperado])
	_comprobar(Escudo.forma_de(mio) == forma_antes and Escudo.patron_de(mio) == patron_antes,
		"pintar las miniaturas no le cambia la forma ni el patrón al club")
	## Pulsar una miniatura de forma la elige de verdad.
	var otra := String(Escudo.FORMAS[(Escudo.FORMAS.find(forma_antes) + 3) % Escudo.FORMAS.size()])
	var tex_otra := EscudoMuestras.escudo_con(mio, "esc_forma", otra, 40)
	for b: Button in lista.find_children("*", "Button", true, false):
		if b.icon == tex_otra and not b.is_queued_for_deletion():
			botones_forma.append(b)
	_comprobar(botones_forma.size() == 1, "la miniatura de la forma «%s» está una vez en la rejilla" % otra)
	if botones_forma.size() == 1:
		botones_forma[0].pressed.emit()
		_comprobar(mio.esc_forma == otra, "pulsarla elige esa forma")
	mio.esc_forma = ""
	## La vista previa en una tinta: solo tinta y blanco, y el rótulo con iniciales.
	var prensa := EscudoMuestras.escudo_prensa(mio, 64)
	var tr: TextureRect = prensa.find_children("*", "TextureRect", true, false)[0]
	var img := tr.texture.get_image()
	var raros := 0
	for y in range(0, img.get_height(), 3):
		for x in range(0, img.get_width(), 3):
			var px := img.get_pixel(x, y)
			## Con margen de un paso de 8 bits: la tinta se guarda en la imagen como bytes.
			var d_tinta := Vector3(px.r - EscudoMuestras.TINTA.r, px.g - EscudoMuestras.TINTA.g, px.b - EscudoMuestras.TINTA.b).length()
			var d_blanco := Vector3(1.0 - px.r, 1.0 - px.g, 1.0 - px.b).length()
			if px.a > 0.99 and d_tinta > 0.02 and d_blanco > 0.02:
				raros += 1
	_comprobar(raros == 0, "el escudo de prensa es de una tinta (%d píxeles de otro color)" % raros)
	var et: Label = prensa.find_children("*", "Label", true, false)[0]
	_comprobar(et.text != "", "el escudo de prensa lleva iniciales o símbolo («%s»)" % et.text)
	prensa.free()

## Arrastrar el selector de color no puede llenar la memoria: cada color nuevo
## son ~90 miniaturas y un escudo a 4x.
func _caches(mio: Club) -> void:
	var antes := mio.esc_color1
	for i in 30:
		mio.esc_color1 = "#%02x3355" % (i * 8)
		Escudo.textura(mio, 54)
		for f: String in Escudo.FORMAS:
			EscudoMuestras.escudo_con(mio, "esc_forma", f, 40)
	mio.esc_color1 = antes
	_comprobar(EscudoMuestras.en_cache() <= EscudoMuestras.TOPE_CACHE, "caché de miniaturas acotada (%d)" % EscudoMuestras.en_cache())
	_comprobar(Escudo._cache.size() <= Escudo.TOPE_CACHE, "caché de escudos acotada (%d)" % Escudo._cache.size())

func _editor(m: Mundo, mio: Club) -> void:
	var j: Jugador = mio.plantilla[0]
	## Como si la pestaña Editor estuviera a la vista (sin ventana, el repintado
	## se aplazaría con `_perezoso` y no habría nada que comprobar).
	_p.set("pintar_todo", true)
	_p.set("_ed_club", mio.id)
	_p.set("_ed_jugador", j.id)
	_p.get("_ui_editor").call("_pintar_editor")
	var lista: Control = _p.get("_lista_editor")
	## «Victoria:» y su desplegable en la misma caja.
	var juntos := false
	for l: Label in lista.find_children("*", "Label", true, false):
		if l.text == "Victoria:" and l.get_parent() is HBoxContainer:
			juntos = (l.get_parent() as HBoxContainer).get_child(1) is OptionButton
	_comprobar(juntos, "«Victoria:» va pegado a su desplegable")
	var textos: Array[String] = []
	for b: Button in lista.find_children("*", "Button", true, false):
		textos.append(b.text)
	_comprobar("Estirada" in textos or "Ritmo" in textos or _hay_label(lista, "Estirada") or _hay_label(lista, "Ritmo"),
		"los atributos se ven con su nombre, no con la clave")
	_comprobar("Tazón" in textos and "Gorra" in textos and not ("tazon" in textos), "cortes y accesorios con nombre legible")
	_comprobar(not ("lider" in textos) and "Líder" in textos, "rasgos con nombre legible")
	## «Pecas» repinta: el botón de antes se suelta y aparece uno nuevo con el estado cambiado.
	var pecas: Button = null
	for b: Button in lista.find_children("*", "Button", true, false):
		if b.text == "Pecas":
			pecas = b
	var antes := bool(Cara.look_de(j).get("pecas", false))
	pecas.pressed.emit()
	_comprobar(bool(Cara.look_de(j).get("pecas", false)) != antes and not pecas.is_inside_tree(),
		"«Pecas» cambia el aspecto Y repinta la ficha (la cara de arriba se actualiza)")

func _hay_label(raiz: Node, t: String) -> bool:
	for l: Label in raiz.find_children("*", "Label", true, false):
		if l.text == t:
			return true
	return false

func _estadio(m: Mundo, mio: Club) -> void:
	_p.call("_pintar_estadio", mio)
	var lista: Control = _p.get("_lista_estadio")
	var con_ayuda := 0
	for ob: OptionButton in lista.find_children("*", "OptionButton", true, false):
		var fila := ob.get_parent()
		if fila is HBoxContainer and fila.get_child(0) is Label:
			var l := fila.get_child(0) as Label
			if l.tooltip_text == l.text and l.custom_minimum_size.x >= 160:
				con_ayuda += 1
	_comprobar(con_ayuda >= 20, "los rótulos del diseñador llevan su texto entero de ayuda (%d)" % con_ayuda)
