class_name AjustesRegistro
extends RefCounted
## AJUSTES → PARTIDA → «INFORME DE FALLOS» (26-10-2026, plan §10). Sección
## pequeña aparte para no tocar el resto de la pantalla de ajustes: copia al
## portapapeles el informe del autoload `Registro` (datos del sistema + últimas
## líneas, sin datos personales) y, en escritorio, abre la carpeta del registro.

static func pintar(p: Principal) -> void:
	var t := p._texto(11, Principal.COL_SUAVE)
	t.text = Idiomas.t("INFORME DE FALLOS")
	p._lista_ajustes.add_child(t)
	var ex := p._texto(10, Principal.COL_SUAVE)
	ex.text = Idiomas.t("El juego apunta sus errores en un registro local. Si algo falla, copia el informe y pégalo al avisar: lleva la versión, el sistema y los últimos errores, sin datos personales.")
	ex.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	p._lista_ajustes.add_child(ex)
	var fila := HBoxContainer.new()
	fila.add_theme_constant_override("separation", 6)
	p._lista_ajustes.add_child(fila)
	var bc := Button.new()
	bc.name = "CopiarInforme"
	bc.text = Idiomas.t("Copiar informe de fallos")
	bc.add_theme_font_size_override("font_size", 11)
	bc.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bc.pressed.connect(func() -> void:
		DisplayServer.clipboard_set(Registro.informe())
		p._escribir(Idiomas.t("Informe de fallos copiado al portapapeles.")))
	fila.add_child(bc)
	if Registro.puede_abrir_carpeta():
		var ba := Button.new()
		ba.name = "AbrirCarpeta"
		ba.text = Idiomas.t("Abrir carpeta")
		ba.add_theme_font_size_override("font_size", 11)
		ba.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		ba.pressed.connect(func() -> void: Registro.abrir_carpeta())
		fila.add_child(ba)
	p._lista_ajustes.add_child(HSeparator.new())
