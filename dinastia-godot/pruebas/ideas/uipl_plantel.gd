extends BaseIdea
## PLANTEL Y CANTERA PULIDOS (25-10-2026, paquete uipl): el filtro por línea, el resumen, la leyenda, el
## nombre que encoge, el estado vacío del plantel y de la cantera, los canteranos que abren su ficha y la
## vida personal que no se inventa para un futbolista real.

var _p: Node

func _probar() -> void:
	_titulo("PLANTEL Y CANTERA PULIDOS (uipl)")
	_p = load("res://escenas/principal.tscn").instantiate()
	add_child(_p)
	var m: Mundo = _p.get("mundo")
	var mio := m.mi_club()
	var lista: VBoxContainer = _p.get("_lista_plantel")
	var plantel = _p.get("_ui_plantel")
	lista.set_meta(PanelPlantel.META_LINEA, "todos")
	plantel._pintar_plantel(mio)
	var g := _rejilla(lista)
	_comprobar(g != null, "la rejilla del plantel se pinta")
	var filas_todos := _filas(g)
	_comprobar(filas_todos == mio.plantilla.size(), "con «Todos» salen los %d del plantel (%d filas)" % [mio.plantilla.size(), filas_todos])
	_comprobar(_texto_con(lista, "%d jugadores" % mio.plantilla.size()), "el resumen dice cuántos jugadores hay")
	_comprobar(_texto_con(lista, "Ⓒ capitán"), "la leyenda explica las marcas")
	## Las cabeceras numéricas, alineadas a la derecha como sus celdas.
	var cab_edad := _boton(lista, "EDAD")
	_comprobar(cab_edad != null and cab_edad.alignment == HORIZONTAL_ALIGNMENT_RIGHT and cab_edad.tooltip_text != "",
		"la cabecera EDAD va a la derecha y tiene ayuda")
	## El nombre encoge: con clip_text y ayuda con el nombre entero.
	var nombre_ok := true
	for c in g.get_children():
		if c is HBoxContainer:
			for h in c.get_children():
				if h is Button and (not (h as Button).clip_text or (h as Button).tooltip_text == ""):
					nombre_ok = false
	_comprobar(nombre_ok, "los botones de nombre recortan y llevan el nombre entero en la ayuda")
	## Filtro de defensas: solo filas de defensas, y el botón queda encendido.
	var defensas := mio.plantilla.filter(func(j: Jugador) -> bool: return PanelPlantel._linea_de(j) == "DEF")
	var b_def := _boton(lista, "Defensas")
	_comprobar(b_def != null, "hay botón de filtro «Defensas»")
	if b_def != null:
		b_def.pressed.emit()
		var g2 := _rejilla(lista)
		_comprobar(_filas(g2) == defensas.size(), "el filtro deja solo a los %d defensas (%d filas)" % [defensas.size(), _filas(g2)])
		var b_def2 := _boton(lista, "Defensas")
		_comprobar(b_def2 != null and b_def2.button_pressed, "el filtro elegido se ve pulsado")
		## Ordenar (repintado completo de Principal) conserva el filtro.
		plantel._pintar_plantel(mio)
		_comprobar(_filas(_rejilla(lista)) == defensas.size(), "el filtro sobrevive a un repintado")
	lista.set_meta(PanelPlantel.META_LINEA, "todos")
	## Plantel vacío: un mensaje, no seis cabeceras sueltas.
	var guardado: Array = mio.plantilla.duplicate()
	mio.plantilla.clear()
	plantel._pintar_plantel(mio)
	_comprobar(_rejilla(lista) == null and _texto_con(lista, "Tu plantel está vacío"), "plantel vacío: mensaje y sin rejilla")
	## Cantera sin canteranos: también lo dice.
	_p.get("_ui_cantera")._pintar_cantera(mio)
	_comprobar(_texto_con(_p.get("_lista_cantera"), "Todavía no hay canteranos"), "cantera sin canteranos: mensaje")
	mio.plantilla.assign(guardado)
	## Cantera con camada: el nombre de cada chico es un botón que abre su ficha.
	m.jugar_temporada()
	m.nueva_temporada()
	_p.get("_ui_cantera")._pintar_cantera(m.mi_club())
	var chico: Button = null
	for b in (_p.get("_lista_cantera") as Node).find_children("*", "Button", true, false):
		if (b as Button).flat and (b as Button).text.contains(" años  ·  "):
			chico = b
			break
	_comprobar(chico != null, "los canteranos salen con su nombre pulsable")
	if chico != null:
		chico.pressed.emit()
		var sel: Jugador = _p.get("_seleccionado")
		_comprobar(sel != null and chico.text.begins_with(sel.nombre), "pulsar al canterano abre su ficha")
	## Un futbolista real no lleva vida personal inventada (religión, paternidad, duelos).
	var j: Jugador = m.mi_club().plantilla[0]
	var antes := FichaJugadorInfo.perfil_humano(j)
	j.real = true
	_comprobar(FichaJugadorInfo.perfil_humano(j).is_empty(), "jugador real: sin vida personal inventada")
	j.real = false
	_comprobar(FichaJugadorInfo.perfil_humano(j) == antes, "jugador ficticio: su vida personal no cambia")

func _rejilla(lista: Node) -> GridContainer:
	for h in lista.get_children():
		if h is GridContainer and not h.is_queued_for_deletion():
			return h
	return null

## Filas de jugador: cada una empieza por la celda del nombre (un HBoxContainer).
func _filas(g: GridContainer) -> int:
	if g == null:
		return -1
	var n := 0
	for c in g.get_children():
		if c is HBoxContainer:
			n += 1
	return n

func _texto_con(raiz: Node, trozo: String) -> bool:
	for l in raiz.find_children("*", "Label", true, false):
		if not l.is_queued_for_deletion() and (l as Label).text.contains(trozo):
			return true
	return false

func _boton(raiz: Node, empieza: String) -> Button:
	for b in raiz.find_children("*", "Button", true, false):
		if not b.is_queued_for_deletion() and (b as Button).text.begins_with(empieza):
			return b
	return null
