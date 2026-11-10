extends Node
## LOS NOMBRES DE PAÍSES Y SELECCIONES EN EL IDIOMA DEL JUEGO (10-11-2026). Los 86 países (y sus selecciones) salen de `PAIS_SELECCION` en castellano
## y en alemán se veían «Rep. Checa», «Alemania»… Recorre en ALEMÁN las pantallas que los muestran (inicio y noticias, selección, continentales,
## competiciones, correo, redes, palmarés del mundo, elegir club y «Ligas activas») y falla si queda un país en castellano. Los nombres de CLUBES no
## se traducen: se quitan del texto antes de buscar. Solo cuentan los países cuyo nombre alemán es distinto del castellano.
##   godot --headless --path . res://pruebas/auditoria_paises_idioma.tscn        (IDIOMA=fr para otro idioma)
const PESTANAS := ["Inicio", "Selección", "Continental", "Clubes", "Correo", "Redes"]
var _p: Node
var _fallos := 0
var _paises: Array = []    ## [nombre castellano, RegEx] de los que cambian en el idioma
var _clubes: Array = []    ## nombres visibles de clubes (no selecciones), del más largo al más corto
var _prefs: Variant = null

func _comprobar(ok: bool, texto: String) -> void:
	print(("  ok     " if ok else "  FALLO  ") + texto)
	if not ok:
		_fallos += 1

func _ready() -> void:
	if FileAccess.file_exists(Principal.PREFS):
		_prefs = FileAccess.get_file_as_bytes(Principal.PREFS)
	var idi := OS.get_environment("IDIOMA") if OS.get_environment("IDIOMA") != "" else "de"
	_p = load("res://escenas/principal.tscn").instantiate()
	add_child(_p)
	for i in 60:
		await get_tree().process_frame
	Idiomas.idioma = idi
	Idiomas._asegurar(idi)
	var m: Mundo = _p.mundo
	## una noticia de selección, como la que sale al aceptar un cargo
	var sel_n := "Marruecos"
	m.selecciones.cargo.ofrecer(sel_n, m.selecciones.fuerza(sel_n), 2400)
	m.selecciones.cargo.responder(m, true)
	_p.call("_refrescar")
	await _cerrar()
	var t: Dictionary = Datos.tabla("PAIS_SELECCION")
	for k: String in t:
		var es := String(t[k])
		if Idiomas.t(es) != es:
			var re := RegEx.create_from_string("(?<![\\p{L}])" + _escapar(es) + "(?![\\p{L}])")
			_paises.append([es, re])
	for c: Club in m.clubes.values():
		if not Nombres.es_pais(c.nombre):
			_clubes.append(Nombres.limpiar(c.nombre))
	_clubes.sort_custom(func(a: String, b: String) -> bool: return a.length() > b.length())
	## completitud: todos los países y selecciones tienen traducción en los 8 idiomas (los que se sumen después saltan aquí)
	var todos := {}
	for k: String in t:
		todos[String(t[k])] = true
	var sels: Variant = Datos.tabla("SELECCIONES")
	if sels is Array:
		for n: Variant in sels:
			if n is String:
				todos[n] = true
	var sin: Array = []
	for n: String in todos:
		for l: String in ["en", "pt", "fr", "it", "de", "ca", "pl", "tr"]:
			Idiomas._asegurar(l)
			if not (Idiomas._extra.get(l, {}) as Dictionary).has(n):
				sin.append("%s (%s)" % [n, l])
				break
	_comprobar(sin.is_empty(), "los %d países y selecciones tienen traducción en los 8 idiomas (%d sin: %s)" % [todos.size(), sin.size(), ", ".join(sin.slice(0, 6))])
	_comprobar(_paises.size() >= 40, "en «%s» cambian de nombre %d países de %d" % [idi, _paises.size(), t.size()])
	for nombre: String in PESTANAS:
		if nombre != "Inicio":
			_p.call("_ir_a_pestana", nombre)
		await _esperar()
		_revisar(nombre, GuardianFoco.capa_arriba(_p) if GuardianFoco.capa_arriba(_p) != null else _p)
		await _cerrar()
	var pm := PalmaresMundoUI.abrir(_p)
	await _esperar()
	_revisar("palmarés del mundo", pm._raiz)
	pm.queue_free()
	await _cerrar()
	_p.get("_ui_elegir_club").call("abrir", "elegir_club")
	await _esperar()
	var dlg: Variant = _p.get("_ui_elegir_club").get("_dlg_club")
	_revisar("elegir club", dlg if dlg is Node else _p)
	if dlg is Window:
		(dlg as Window).hide()
	await _cerrar()
	var la := LigasActivasPantalla.new()
	add_child(la)
	await _esperar()
	_revisar("ligas activas", la)
	la.queue_free()
	print("===== FIN. %d fallos =====" % _fallos)
	Idiomas.idioma = "es"
	if _prefs is PackedByteArray:
		var f := FileAccess.open(Principal.PREFS, FileAccess.WRITE)
		if f != null:
			f.store_buffer(_prefs)
			f.close()
	get_tree().quit(0 if _fallos == 0 else 1)

func _esperar() -> void:
	for i in 20:
		await get_tree().process_frame

func _cerrar() -> void:
	for h: Node in _p.get_children():
		if h is EventoDialogo and not h.is_queued_for_deletion():
			(h as EventoDialogo).selector.elegir(0)
			for i in 60:
				await get_tree().process_frame
	for h: Node in _p.get_children():
		if h is PantallaMenu and not (h as PantallaMenu).cerrando():
			(h as PantallaMenu).cerrar()
		elif h is EventoPantallaCompleta or h is Competicion:
			h.queue_free()
	for i in 10:
		await get_tree().process_frame

static func _escapar(t: String) -> String:
	var r := t
	for c: String in ["\\", ".", "^", "$", "|", "(", ")", "[", "]", "{", "}", "*", "+", "?"]:
		r = r.replace(c, "\\" + c)
	return r

func _revisar(nombre: String, raiz: Node) -> void:
	var hallados := {}
	var textos := 0
	for n: Node in raiz.find_children("*", "", true, false) + [raiz]:
		var txt := ""
		if n is RichTextLabel:
			txt = (n as RichTextLabel).get_parsed_text()
		elif n is Label or n is Button:
			txt = String(n.get("text"))
		elif n is OptionButton:
			pass
		if n is OptionButton:
			for i in (n as OptionButton).item_count:
				txt += "\n" + (n as OptionButton).get_item_text(i)
		if txt.strip_edges() == "" or (n is CanvasItem and not (n as CanvasItem).is_visible_in_tree() and not n is OptionButton):
			continue
		textos += 1
		for cl: String in _clubes:   ## los clubes no se traducen: fuera antes de buscar
			if txt.contains(cl):
				txt = txt.replace(cl, "·")
		for par: Array in _paises:
			if (par[1] as RegEx).search(txt) != null:
				hallados[par[0]] = txt.strip_edges().left(50).replace("\n", " ")
	_comprobar(hallados.is_empty(), "[%s] ningún país en castellano (%d textos; %d en castellano: %s)" % [nombre, textos, hallados.size(),
		", ".join(hallados.keys().slice(0, 5).map(func(k: String) -> String: return "%s en «%s»" % [k, hallados[k]]))])
