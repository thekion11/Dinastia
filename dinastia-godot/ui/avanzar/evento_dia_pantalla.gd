class_name EventoDiaPantalla
extends EventoPantallaCompleta
## LA PANTALLA COMPLETA GENÉRICA DE UN EVENTO DEL AVANCE (paso 4, 17-11-2026): un símbolo grande con su animación, la clase, el título, el texto y la CAUSA (por qué
## pasó). Cada evento con arte propio (premio, propuesta, parte médico, balance…) se sumará como pantalla aparte; mientras, esta cubre a todos con el mismo marco.
## Emite `elegido("0")` al seguir. Al cerrar, el avance vuelve al menú.

static func mostrar(pr: Node, ev: Dictionary) -> EventoDiaPantalla:
	var e := EventoDiaPantalla.new()
	e.paleta_noche = true
	e.acento = AvanzarTextos.COLOR_PANTALLA
	e._montar_base(pr)
	e._rellenar(ev)
	return e

func _rellenar(ev: Dictionary) -> void:
	_centro.custom_minimum_size = Vector2(ancho_base(760.0), 0)
	_centro.add_theme_constant_override("separation", 14)
	var col := AvanzarTextos.COLOR_PANTALLA
	var simbolo := etiqueta(AvanzarTextos.icono(ev), 96, col)
	var clase := etiqueta(Idiomas.t("EVENTO IMPORTANTE"), 14, Color(col, 0.9))
	var titulo := etiqueta(AvanzarTextos.titulo(ev), 36, Color.WHITE)
	var raya := ColorRect.new()
	raya.color = Color(col, 0.5)
	raya.custom_minimum_size = Vector2(120, 2)
	raya.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	var cuerpo := etiqueta(AvanzarTextos.texto(ev), 22, Color(1, 1, 1, 0.9))
	cuerpo.custom_minimum_size = Vector2(ancho_base(620.0), 0)
	cuerpo.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	var piezas: Array = [simbolo, clase, titulo, raya, cuerpo]
	var seguir := boton(Idiomas.t("Continuar"), true)
	seguir.custom_minimum_size = Vector2(240, 58)
	seguir.pressed.connect(func() -> void: elegido.emit("0"))
	for n: Control in piezas:
		_centro.add_child(n)
	fijar_abajo(seguir)
	entrada_en_cascada(piezas, 0.15, 0.2)
	if not Animar.reducidas():
		simbolo.pivot_offset = Vector2(60, 60)
		var tw := create_tween().set_loops()
		tw.tween_property(simbolo, "scale", Vector2(1.08, 1.08), 0.9).set_trans(Tween.TRANS_SINE)
		tw.tween_property(simbolo, "scale", Vector2.ONE, 0.9).set_trans(Tween.TRANS_SINE)
