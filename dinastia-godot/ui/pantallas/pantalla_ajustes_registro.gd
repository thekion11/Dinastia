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
	## (13-11, decisión del dueño) LA SEMILLA DEL MUNDO vive aquí, no en la portada: sirve para repetir este mundo y para que un informe de
	## fallo sea reproducible. Se ve, se copia con un botón y el informe copiado la lleva en la primera línea.
	if p.mundo != null:
		var se := p._texto(11, Principal.COL_TEXTO)
		se.name = "SemillaMundo"
		se.text = Idiomas.t("Semilla del mundo: %d (sirve para repetir este mundo y para informar de fallos)") % int(p.mundo.semilla)
		se.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		p._lista_ajustes.add_child(se)
	if Registro.CONTACTO != "":
		var co := p._texto(11, Principal.COL_TEXTO)
		co.text = Idiomas.t("Mándalo a: %s") % Registro.CONTACTO
		p._lista_ajustes.add_child(co)
	var fila := HBoxContainer.new()
	fila.add_theme_constant_override("separation", 6)
	p._lista_ajustes.add_child(fila)
	var bc := Button.new()
	bc.name = "CopiarInforme"
	bc.text = Idiomas.t("Copiar informe de fallos")
	bc.add_theme_font_size_override("font_size", 11)
	bc.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bc.pressed.connect(func() -> void:
		DisplayServer.clipboard_set(informe_con_semilla(int(p.mundo.semilla) if p.mundo != null else -1, Registro.informe()))
		p._escribir(Idiomas.t("Informe de fallos copiado al portapapeles.")))
	fila.add_child(bc)
	if p.mundo != null:
		var bs := Button.new()
		bs.name = "CopiarSemilla"
		bs.text = Idiomas.t("Copiar semilla")
		bs.add_theme_font_size_override("font_size", 11)
		bs.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		bs.pressed.connect(func() -> void:
			DisplayServer.clipboard_set(str(int(p.mundo.semilla)))
			p._escribir(Idiomas.t("Semilla copiada al portapapeles.")))
		fila.add_child(bs)
	if Registro.puede_abrir_carpeta():
		var ba := Button.new()
		ba.name = "AbrirCarpeta"
		ba.text = Idiomas.t("Abrir carpeta")
		ba.add_theme_font_size_override("font_size", 11)
		ba.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		ba.pressed.connect(func() -> void: Registro.abrir_carpeta())
		fila.add_child(ba)
	p._lista_ajustes.add_child(HSeparator.new())

## El informe del registro con la semilla del mundo en la primera línea (`semilla` < 0 = sin mundo: el informe de siempre).
static func informe_con_semilla(semilla: int, informe: String) -> String:
	return informe if semilla < 0 else ("Semilla del mundo: %d\n" % semilla) + informe
