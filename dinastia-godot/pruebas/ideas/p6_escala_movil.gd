extends BaseIdea
## Interfaz en el móvil: zoom de la primera vez y cuadros de texto más altos (el escritorio no cambia).

func _probar() -> void:
	_titulo("P6: ESCALA DE LA INTERFAZ EN EL MÓVIL")
	_comprobar(EscalaMovil.zoom(1.2) == 1.2 and EscalaMovil.zoom(3.0) == 1.8 and EscalaMovil.zoom(0.1) == 0.7, "un zoom guardado se respeta (con sus topes 0,7-1,8)")
	var movil := EscalaMovil.es_movil()
	_comprobar(is_equal_approx(EscalaMovil.zoom(null), EscalaMovil.ZOOM_MOVIL if movil else 1.0), "sin zoom guardado: %.1f (%s)" % [EscalaMovil.zoom(null), "móvil" if movil else "escritorio"])
	_comprobar(EscalaMovil.campo_alto(40) == (EscalaMovil.ALTO_CAMPO_MOVIL if movil else 40), "los cuadros de texto miden %d px" % EscalaMovil.campo_alto(40))
	_comprobar(EscalaMovil.ZOOM_MOVIL >= 1.4 and EscalaMovil.ALTO_CAMPO_MOVIL >= 48, "el móvil usa un zoom y un alto de campo cómodos para el dedo")
	var raiz := get_tree().root.content_scale_factor
	EscalaMovil.aplicar(get_tree(), "user://no_existe.cfg")
	_comprobar(is_equal_approx(get_tree().root.content_scale_factor, EscalaMovil.zoom(null)), "aplicar sin preferencias pone el zoom por defecto")
	get_tree().root.content_scale_factor = raiz
