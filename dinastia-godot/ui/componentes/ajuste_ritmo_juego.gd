class_name AjusteRitmoJuego
extends RefCounted
## Ajustes → Juego: velocidad del partido en directo (Lenta / Normal / Rápida / Arcade). Ver `RitmoJuego`.
static func pintar(p: Principal) -> void:
	p._lista_ajustes.add_child(HSeparator.new())
	var t := p._texto(11, Principal.COL_SUAVE)
	t.text = Idiomas.t("VELOCIDAD DEL JUEGO EN DIRECTO")
	p._lista_ajustes.add_child(t)
	var ayuda := p._texto(11, Principal.COL_SUAVE)
	ayuda.text = Idiomas.t("Cuánto corren los jugadores y el balón. Más lenta es más cómoda con mando.")
	ayuda.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	p._lista_ajustes.add_child(ayuda)
	var fila := HBoxContainer.new()
	fila.add_theme_constant_override("separation", 6)
	p._lista_ajustes.add_child(fila)
	for i in RitmoJuego.NIVELES.size():
		var idx := i
		var b := Button.new()
		b.text = Idiomas.t(String((RitmoJuego.NIVELES[i] as Array)[0]))
		b.toggle_mode = true
		b.button_pressed = (RitmoJuego.indice() == idx)
		b.custom_minimum_size = Vector2(90, 30)
		b.pressed.connect(func() -> void:
			RitmoJuego.fijar(idx)
			p._refrescar())
		fila.add_child(b)
