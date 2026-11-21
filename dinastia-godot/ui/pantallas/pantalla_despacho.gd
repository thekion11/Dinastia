class_name PantallaDespacho
extends "res://ui/pantallas/pantalla_despacho_p1.gd"
## (Parte 2 de 2 de `pantalla_despacho.gd`.)

func _pintar_fila_asuntos(asuntos: Array) -> void:
	## Fila que SALTA DE LÍNEA: con 7+ asuntos una HBox pedía ~1262 px de
	## ancho mínimo y desbordaba la pantalla entera por la derecha (a 1280 y a 1920).
	var fila := HFlowContainer.new()
	fila.add_theme_constant_override("h_separation", 6)
	fila.add_theme_constant_override("v_separation", 4)
	p._despacho.add_child(fila)
	var cab := p._texto(11, Principal.COL_SUAVE)
	cab.text = (Idiomas.t("🔔 %d asunto") if asuntos.size() == 1 else Idiomas.t("🔔 %d asuntos")) % asuntos.size()
	fila.add_child(cab)
	for i in asuntos.size():
		var a: Dictionary = asuntos[i]
		var b := p._pildora(String(a["et"]), 11, 26)
		b.button_pressed = (i == p._aviso_abierto)
		var idx := i
		b.pressed.connect(func() -> void:
			p._aviso_abierto = idx
			p._aviso_plegado = false
			_pintar_despacho())
		fila.add_child(b)
	## (16-11, frente 1) Plegado por defecto, como una notificación: la fila dice cuántos y cuáles; tocar uno lo abre.
	var plegar := LinkButton.new()   ## LinkButton y no Button: no cuenta como píldora de asunto
	plegar.text = Idiomas.t("▾ Ver") if p._aviso_plegado else Idiomas.t("▴ Plegar")
	plegar.underline = LinkButton.UNDERLINE_MODE_NEVER
	plegar.focus_mode = Control.FOCUS_ALL
	plegar.add_theme_font_size_override("font_size", Tema.letra(11))
	plegar.add_theme_color_override("font_color", Tema.oro())
	plegar.pressed.connect(func() -> void:
		p._aviso_plegado = not p._aviso_plegado
		_pintar_despacho())
	fila.add_child(plegar)
## El contrato de la pantalla (`PantallaBase`, fase 0 §7.2): sus secciones, que se abren con `abrir(sección)`.
func secciones() -> Dictionary:
	return {"despacho": _pintar_despacho}
