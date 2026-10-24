class_name PantallaEditor
extends "res://ui/pantallas/pantalla_editor_p1.gd"
## [Capa 2/2 de `pantalla_editor.gd`] _pintar_editor_csv, _pintar_editor

## EL IMPORTADOR. Formato del HTML sin tocar, para que una base hecha para el
## HTML se pueda pegar aquí tal cual.
func _pintar_editor_csv(ed: Editor) -> void:
	p._lista_editor.add_child(HSeparator.new())
	var t := p._texto(11, p.COL_ACENTO)
	t.text = Idiomas.t("IMPORTAR UNA BASE (CSV)")
	p._lista_editor.add_child(t)
	var ex := p._texto(10, Principal.COL_SUAVE)
	ex.text = Idiomas.t("Una línea por futbolista: Club;Nombre;POS;Edad;Media[;País;Proyección;Pie]. POS admite grupos (POR/DEF/MED/DEL) o puestos concretos. Con %d filas o más de un mismo club, se REEMPLAZA su plantilla; con menos, se añaden.") % Editor.FILAS_PARA_REEMPLAZAR
	ex.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	p._lista_editor.add_child(ex)

	var fila := HBoxContainer.new()
	fila.add_theme_constant_override("separation", 8)
	p._lista_editor.add_child(fila)
	var etc := p._texto(11, Principal.COL_TEXTO)
	etc.text = Idiomas.t("Censurar los nombres importados")
	etc.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	etc.tooltip_text = Idiomas.t("Sustituye algunas letras por números, como hace el resto del juego con los nombres generados.")
	fila.add_child(etc)
	var bc := Button.new()
	bc.text = "SÍ" if p._ed_censura else "NO"
	bc.pressed.connect(func() -> void:
		p._ed_censura = not p._ed_censura
		p._refrescar())
	fila.add_child(bc)

	var caja := TextEdit.new()
	caja.text = p._ed_csv
	caja.placeholder_text = Idiomas.t("C0lo-C0lo;Arturo Vidal;MED;38;79\nB0ca Juni0rs;Edinson Cavani;DEL;39;80;URU;80")
	caja.custom_minimum_size = Vector2(0, 120)
	caja.add_theme_font_size_override("font_size", 11)
	caja.wrap_mode = TextEdit.LINE_WRAPPING_BOUNDARY
	caja.text_changed.connect(func() -> void: p._ed_csv = caja.text)
	p._lista_editor.add_child(caja)

	var bi := Button.new()
	bi.text = Idiomas.t("📥 Importar")
	bi.add_theme_font_size_override("font_size", 11)
	bi.pressed.connect(func() -> void: _importar_csv(ed))
	p._lista_editor.add_child(bi)
	var bp := Button.new()
	bp.text = Idiomas.t("📋 Pegar desde el portapapeles")
	bp.add_theme_font_size_override("font_size", 11)
	bp.pressed.connect(func() -> void:
		p._ed_csv = DisplayServer.clipboard_get()
		p._refrescar())
	p._lista_editor.add_child(bp)

	p._lista_editor.add_child(HSeparator.new())
	var te := p._texto(11, p.COL_ACENTO)
	te.text = Idiomas.t("EXPORTAR LA BASE (CSV)")
	p._lista_editor.add_child(te)
	var ee := p._texto(10, Principal.COL_SUAVE)
	ee.text = Idiomas.t("Mismo formato que el importador, con el pie hábil de regalo -no se puede reimportar, es calculado, no guardado- y sin habilidades -esas viven en el árbol de entrenamiento de cada club, no en el jugador-. Se copia al portapapeles.")
	ee.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	p._lista_editor.add_child(ee)
	var fila_ex := HBoxContainer.new()
	fila_ex.add_theme_constant_override("separation", 8)
	p._lista_editor.add_child(fila_ex)
	var b_mi := Button.new()
	b_mi.text = Idiomas.t("Mi liga")
	b_mi.add_theme_font_size_override("font_size", 11)
	b_mi.pressed.connect(func() -> void: _exportar_csv(ed, true))
	fila_ex.add_child(b_mi)
	var b_todo := Button.new()
	b_todo.text = Idiomas.t("Todo el mundo")
	b_todo.add_theme_font_size_override("font_size", 11)
	b_todo.pressed.connect(func() -> void: _exportar_csv(ed, false))
	fila_ex.add_child(b_todo)

func _pintar_editor() -> void:
	p._limpiar(p._lista_editor)
	var ed := p._ui_ciudad._editor_de()
	var t := p._texto(11, Principal.COL_SUAVE)
	t.text = Idiomas.t("🛠️ EDITOR")
	p._lista_editor.add_child(t)
	if not p._modo_experto:
		var ex := p._texto(10, Principal.COL_SUAVE)
		ex.text = Idiomas.t("Renombra, repinta y reconstruye el mundo del juego: clubes, escudos, plantillas, atributos, puestos y caras. Los cambios van al guardado como cualquier otra cosa.")
		ex.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		p._lista_editor.add_child(ex)

	_pintar_editor_competiciones(ed)
	_pintar_editor_clubes(ed)
	_pintar_editor_jugadores(ed)
	_pintar_editor_csv(ed)
