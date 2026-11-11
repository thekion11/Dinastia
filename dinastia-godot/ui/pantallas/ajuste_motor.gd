class_name AjusteMotor
extends RefCounted
## AJUSTES → «MOTOR DEL PARTIDO (prueba a ciegas)» (11-11-2026, sesión 11). Por defecto, el motor de siempre; con A, B o C el dueño
## juega sin saber cuál es cuál (el reparto se baraja una vez y se guarda: `MotorEleccion`) y al acabar vota de 1 a 5. «Revelar»
## muestra el reparto y los votos por motor. Solo nombra la clase ligera `MotorEleccion`: no toca nada del partido (memoria del menú).

static func crear(p: Object) -> void:
	var t: Label = p._texto(10, Principal.COL_SUAVE)
	t.text = Idiomas.t("Motor del partido (prueba a ciegas)")
	p._lista_ajustes.add_child(t)
	var fila := HFlowContainer.new()
	fila.add_theme_constant_override("h_separation", 4)
	fila.add_theme_constant_override("v_separation", 4)
	p._lista_ajustes.add_child(fila)
	var actual := MotorEleccion.seleccion()
	for letra: String in ["", "A", "B", "C"]:
		var b := Button.new()
		b.text = Idiomas.t("Por defecto") if letra == "" else letra
		b.toggle_mode = true
		b.button_pressed = actual == letra
		b.add_theme_font_size_override("font_size", 11)
		b.custom_minimum_size = Vector2(70, 0)
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.tooltip_text = Idiomas.t("Elige A, B o C sin saber cuál es cuál y juega: al terminar cada partido te pedimos una nota de diversión. «Por defecto» es el motor de siempre.")
		b.pressed.connect(func() -> void:
			MotorEleccion.elegir(letra)
			p._refrescar())
		fila.add_child(b)
	var fila2 := HFlowContainer.new()
	fila2.add_theme_constant_override("h_separation", 4)
	p._lista_ajustes.add_child(fila2)
	var rev := MotorEleccion.revelado()
	var br := Button.new()
	br.text = Idiomas.t("Ocultar qué es cada letra") if rev else Idiomas.t("Revelar qué es cada letra")
	br.add_theme_font_size_override("font_size", 11)
	br.pressed.connect(func() -> void:
		if rev:
			MotorEleccion.ocultar()
		else:
			MotorEleccion.revelar()
		p._refrescar())
	fila2.add_child(br)
	var bb := Button.new()
	bb.text = Idiomas.t("Barajar las letras de nuevo")
	bb.add_theme_font_size_override("font_size", 11)
	bb.pressed.connect(func() -> void:
		MotorEleccion.barajar()
		MotorEleccion.ocultar()
		p._refrescar())
	fila2.add_child(bb)
	var votos := MotorEleccion.resumen_votos()
	var partes: PackedStringArray = []
	for i in MotorEleccion.LETRAS.size():
		var m := String(MotorEleccion.orden()[i])
		var v: Dictionary = votos[m]
		var nombre := Idiomas.t(String(MotorEleccion.NOMBRES[m])) if rev else ""
		partes.append("%s%s: %s" % [MotorEleccion.LETRAS[i], " (" + nombre + ")" if rev else "", (Idiomas.t("%d votos, media %.2f") % [int(v["votos"]), float(v["media"])]) if int(v["votos"]) > 0 else Idiomas.t("sin votos")])
	var info: Label = p._texto(10, Principal.COL_SUAVE)
	info.text = ("\n".join(partes)) if rev else (Idiomas.t("Votos por letra") + ": " + " · ".join(partes))
	info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	p._lista_ajustes.add_child(info)
