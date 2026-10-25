extends BaseIdea
## FILA DE ASUNTOS DEL DESPACHO (25-10-2026, cierre de la sesión 2): con muchos asuntos a la vez la fila
## era una HBox que pedía ~1262 px de ancho mínimo y empujaba la pantalla ENTERA fuera por la derecha
## (lo vio el paquete uipl en la ficha, a 1280 y a 1920). Ahora salta de línea: aquí se abren 8 asuntos
## de verdad y se comprueba que todas las píldoras siguen ahí y que el despacho cabe en 1280.

func _probar() -> void:
	_titulo("DESPACHO: LA FILA DE ASUNTOS SALTA DE LÍNEA")
	var p: Principal = load("res://escenas/principal.tscn").instantiate()
	add_child(p)
	var m: Mundo = p.mundo
	var abiertos := 0
	for par: Array in [[m.prensa, "pendiente"], [m.junta, "pendiente"], [m.eventos_cantera, "pendiente"],
			[m.trabajadores, "pendiente"], [m.mercado_av, "pendiente"], [m.insolvencia, "pendiente"]]:
		if par[0] != null:
			par[0].set(par[1], {"id": "x", "texto": "x", "a": "a", "b": "b"})
			abiertos += 1
	if m.vestuario != null:
		m.vestuario.solicitud = {"id": "x", "texto": "x"}
		abiertos += 1
	## El último asunto (Mi vida) es el que se pinta abierto: con sus campos de verdad.
	m.vida.pendiente = {"texto": "Prueba", "a": "Sí", "b": "No"}
	abiertos += 1
	p._aviso_abierto = 99
	p._ui_despacho._pintar_despacho()
	## La fila se busca por su contenido (la cabecera «🔔 N asuntos»), no por su tipo: así la prueba
	## también mide el código viejo y falla por el ancho, no por la clase.
	var fila: Container = null
	for h in p._despacho.get_children():
		if h is Container and not h.is_queued_for_deletion() and h.get_child_count() > 0 \
				and h.get_child(0) is Label and (h.get_child(0) as Label).text.begins_with("🔔"):
			fila = h
	_comprobar(fila != null, "se encuentra la fila de asuntos")
	if fila == null:
		return
	_comprobar(fila is HFlowContainer, "la fila de asuntos salta de línea")
	var pildoras := fila.get_children().filter(func(n: Node) -> bool: return n is Button).size()
	_comprobar(abiertos >= 8 and pildoras == abiertos, "salen las %d píldoras de los %d asuntos abiertos" % [pildoras, abiertos])
	var ancho := fila.get_combined_minimum_size().x
	_comprobar(ancho < 400.0, "la fila ya no impone ancho mínimo (pide %d px; antes ~1262)" % int(ancho))
	var ancho_despacho := p._despacho.get_combined_minimum_size().x
	_comprobar(ancho_despacho < 1280.0, "el despacho entero cabe en 1280 (pide %d px)" % int(ancho_despacho))
