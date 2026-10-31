extends BaseIdea
## s3 (26-10-2026): NINGÚN TEXTO VISIBLE CON EL NOMBRE INTERNO DE UNA COMPETICIÓN.
## Con la base ficticia, «Copa del Mundo», «Mundial de Clubes», «Eurocopa»... son
## nombres del núcleo: en pantalla van los de `CompeticionInfo.nombre_visible()`
## (tabla en docs/05_referencia/competiciones.md). Se recorren las noticias (registro,
## correo, móvil, avisos, mentor y portada), el calendario, los sorteos, la ficha de
## la competición y el palmarés mundial en los 9 idiomas, y se busca el nombre
## interno y su traducción en cada texto que se ve.
const IDIOMAS := ["es", "en", "pt", "fr", "it", "de", "ca", "pl", "tr"]
var _p: Principal
var _vistos_visibles := 0

func _ready() -> void:
	await get_tree().process_frame
	_titulo("S3: NOMBRES DE COMPETICIÓN (el visible, nunca el interno, en 9 idiomas)")
	var idioma_antes := Idiomas.idioma
	var m := Mundo.new()
	m.generar([], 20261026)
	m.tomar_el_mando(m.ligas[0].clubes[0].id)
	PedidoPartida.mundo_pregenerado = m
	_p = load("res://escenas/principal.tscn").instantiate()
	add_child(_p)
	for i in 4:
		await get_tree().process_frame
	_filtro()
	_comprobar(not Datos.base_real, "la prueba corre con la base ficticia")
	for idioma: String in IDIOMAS:
		Idiomas.idioma = idioma
		await _pasada(idioma)
	Idiomas.idioma = idioma_antes
	_comprobar(_vistos_visibles >= IDIOMAS.size() * 3, "y los nombres visibles SÍ salen (%d apariciones en las pasadas)" % _vistos_visibles)
	print("")
	print("===== FIN. %d fallos =====" % _fallos.size())
	get_tree().quit(0 if _fallos.is_empty() else 1)

## El filtro de texto libre, sin pantalla.
func _filtro() -> void:
	var t := CompeticionInfo.visibles_en("🌍 Mundial de Clubes 2027. Se jugó la Copa del Mundo y la Copa África de Clubes.")
	_comprobar(t == "🌍 Copa Intercontinental de Campeones 2027. Se jugó la Copa Mundial de Naciones y la Copa África de Clubes.",
		"visibles_en cambia los nombres internos y respeta la continental «Copa África de Clubes» (%s)" % t)
	_comprobar(CompeticionInfo.visibles_en("Copa África 2028") == "Copa de Naciones del Sol 2028", "«Copa África» a secas es la de selecciones")

## Lo prohibido en un idioma: el nombre interno y su traducción (si no coincide
## con la del visible).
func _prohibidos() -> Array:
	var r: Array = []
	for k: String in CompeticionInfo.FICTICIOS:
		r.append(k)
		var tk := Idiomas.t(k)
		if tk != Idiomas.t(String(CompeticionInfo.FICTICIOS[k])) and not r.has(tk):
			r.append(tk)
	return r

func _pasada(idioma: String) -> void:
	var c := _p.mundo.mi_club()
	## NOTICIAS: el calendario de verdad en una semana del Mundial (noticia y
	## mentor), la selección y un aviso.
	var cal: Calendario = _p.mundo.calendario
	cal.explicadas = {}
	cal.ultima_semana = -1
	for sem in 60:
		if not Calendario.torneo_en_curso(2026, sem).is_empty():
			cal.semana(c, 2026, sem)
			break
	_p.mundo.selecciones.noticia.emit("🌍 Mundial de Clubes 2027",
		"Ganaste el Mundial de Clubes 2027. Todos ellos disputan el Mundial de Clubes.")
	Aviso.mostrar(_p, "logro", "🏆", "Campeón de Eurocopa", "La Copa América y la Copa Oro, también.")
	var portada := PortadaPeriodico.mostrar(_p, _p.mundo, {"t": "La Copa del Mundo ya tiene dueño", "sub": "Se jugó la Copa del Mundo."})
	## CALENDARIO (un año con Mundial y otro con Eurocopa y Copa América) y el
	## palmarés de la selección.
	var anio := _p.mundo.anio
	var s: Selecciones = _p.mundo.selecciones
	s.mundial = {"campeon": "Brasil", "anio": 2026}
	s.mundial_clubes = {"campeon": c.nombre, "anio": 2027, "mio": true, "relato": "Ganaste el Mundial de Clubes."}
	var textos: Array = []
	for a in [2026, 2028]:
		_p.mundo.anio = a
		_p._ui_plantel._pintar_calendario(c)
		textos.append_array(_textos_de(_p._lista_calendario, false))
	_p.mundo.anio = anio
	_p._ui_cantera._pintar_seleccion(c)
	textos.append_array(_textos_de(_p._lista_seleccion, false))
	## SORTEO y FICHA DE LA COMPETICIÓN.
	var otro: Club = _p.mundo.ligas[1].clubes[0]
	var so := Sorteo.new()
	so.set_anchors_preset(Control.PRESET_FULL_RECT)
	_p.add_child(so)
	so.abrir_eliminatoria("ucl", "Octavos de final", [[c, otro]], c)
	var fi := Competicion.new()
	fi.set_anchors_preset(Control.PRESET_FULL_RECT)
	_p.add_child(fi)
	fi.abrir(_p.mundo, _p._liga_de(c))
	for i in 3:
		await get_tree().process_frame
	textos.append_array(_textos_de(_p))
	for d: Dictionary in Aviso._cola:
		textos.append_array([Idiomas.t(String(d["titulo"])), Idiomas.t(String(d["desc"]))])
	for d: Dictionary in MentorVoz._cola:
		textos.append_array([Idiomas.t(String(d["titulo"])), Idiomas.t(String(d["texto"]))])
	for b: Dictionary in _p._bandeja:
		textos.append_array([Idiomas.t(String(b["titulo"])), Idiomas.t(String(b["cuerpo"]))])
	if _p.mundo.movil != null:
		for msj: Dictionary in _p.mundo.movil.mensajes:
			textos.append(Movil.texto(msj))
	var malos: Array = []
	var prohibidos := _prohibidos()
	## «Copa África de Clubes» es la continental, no la de selecciones.
	var res: Array = []
	for x: String in prohibidos:
		res.append(RegEx.create_from_string("\\Q%s\\E(?! de Clubes)" % x))
	for t: String in textos:
		for k in prohibidos.size():
			if (res[k] as RegEx).search(t) != null:
				malos.append("«%s» en «%s»" % [prohibidos[k], t.left(90)])
	for k: String in CompeticionInfo.FICTICIOS:
		var v := Idiomas.t(String(CompeticionInfo.FICTICIOS[k]))
		for t: String in textos:
			if t.contains(v) or t.contains(Idiomas.mayusculas(v)):
				_vistos_visibles += 1
				break
	_comprobar(malos.is_empty(), "[%s] ningún texto visible (noticias, correo, avisos, mentor, portada, calendario, selección, sorteo, ficha) dice el nombre interno (%d textos; %s)" % [
		idioma, textos.size(), str(malos.slice(0, 4))])
	## Recoger para la pasada siguiente.
	so.queue_free()
	fi.queue_free()
	if is_instance_valid(portada):
		portada.queue_free()
	Aviso._cola.clear()
	MentorVoz._cola.clear()
	for n in _p.get_children():
		if n is Aviso or n is MentorVoz:
			n.queue_free()
	_p._registro.clear()
	await get_tree().process_frame

## Todo lo que se lee en un árbol: etiquetas, botones, texto enriquecido,
## ayudas, entradas de los desplegables y rótulos 3D.
func _textos_de(raiz: Node, solo_visible := true) -> Array:
	var r: Array = []
	for n in raiz.find_children("*", "", true, false):
		if solo_visible and n is Control and not (n as Control).is_visible_in_tree():
			continue
		if n is Label:
			r.append((n as Label).text)
		elif n is RichTextLabel:
			r.append((n as RichTextLabel).get_parsed_text())
		elif n is Button:
			r.append((n as Button).text)
		elif n is Label3D:
			r.append((n as Label3D).text)
		if n is OptionButton:
			for i in (n as OptionButton).item_count:
				r.append((n as OptionButton).get_item_text(i))
		if n is Control and (n as Control).tooltip_text != "":
			r.append((n as Control).tooltip_text)
	return r
