extends BaseIdea
## MEGA AUDITORÍA 4 (4-11-2026), repaso 5: las NOTICIAS que emite el núcleo (`noticia.emit`, ~240 sitios) llegan a la interfaz en castellano y la
## interfaz las pasa por `Idiomas.t` al mostrarlas. Aquí se recogen las que salen de verdad en 2 años de partida simulada (todas las señales `noticia`
## del mundo) y se miden en 8 idiomas: ¿cuántas se quedan con aspecto de castellano? (mismo detector que el recorrido de pantallas.)
## Con NOTICIAS_FALTAN=<ruta> guarda las frases sin traducir.
const LANGS := ["en", "pt", "fr", "it", "de", "ca", "pl", "tr"]
var _vistas: Dictionary = {}

func _probar() -> void:
	_titulo("A4 (noticias): lo que el núcleo emite, traducido a los 8 idiomas")
	Partido.limpiar_contexto()
	var m := Mundo.new()
	var paises: Array[String] = ["CHI", "ARG"]
	m.generar(paises, 88)
	m.tomar_el_mando(m.ligas[0].clubes[0].id)
	_conectar(m)
	for sem in 110:
		m.avanzar_semana()
		_conectar(m)
		if sem % 20 == 19:
			await get_tree().process_frame
	## Y las plantillas con nombre de los eventos sueltos (imprevistos y lesiones insólitas), formadas con un nombre de ejemplo: salen pocas veces en 2 años.
	var ex := RegEx.create_from_string('"((?:[^"\\\\]|\\\\.)*)"')
	for f in ["imprevistos", "lesiones_absurdas"]:
		for mm in ex.search_all(FileAccess.get_file_as_string("res://nucleo/%s.gd" % f)):
			var plant: String = mm.get_string(1)
			if plant.contains("%s") and plant.contains(" ") and plant.length() > 12:
				_vistas[plant.replace("%s", "Juan Pérez")] = true
	_comprobar(_vistas.size() >= 20, "se recogieron noticias distintas (%d)" % _vistas.size())
	var re := RegEx.create_from_string("(?i)(?<![\\p{L}])(que|se|tu|tus|con|para|por|del|las|los|una|está|hay|más|pero|muy|sin|años|semanas|jugadores|partido|partidos|equipo|tienes|puedes|cuando)(?![\\p{L}])")
	var siglas := RegEx.create_from_string("\\b(POR|DEF|MED|DEL|DFC|LAT|BAN|POS)\\b")
	var faltan: Dictionary = {}
	var antes := Idiomas.idioma
	for l: String in LANGS:
		Idiomas.idioma = l
		var comp: Array = (load("res://pruebas/recorrido_pantallas.gd") as GDScript).get_script_constant_map().get("COMPARTIDAS", {}).get(l, [])
		var mal := 0
		for k: String in _vistas:
			var t := Idiomas.t(k)
			var palabras := re.search_all(siglas.sub(t, "", true)).filter(func(x: RegExMatch) -> bool: return not comp.has(x.get_string().to_lower()))
			if t == k and palabras.size() >= 2:
				mal += 1
				if l == "en":
					faltan[k] = true
		print("  %s: %d de %d noticias con aspecto de castellano" % [l, mal, _vistas.size()])
		_comprobar(mal <= 2, "%s: pocas noticias sin traducir (%d de %d)" % [l, mal, _vistas.size()])
	Idiomas.idioma = antes
	var ruta := OS.get_environment("NOTICIAS_FALTAN")
	if ruta != "":
		var f := FileAccess.open(ruta, FileAccess.WRITE)
		for k: String in faltan:
			f.store_line(k.replace("\n", " "))
	for k: String in faltan.keys().slice(0, 12):
		print("    SIN TRADUCIR: ", k.left(150))

func _conectar(m: Mundo) -> void:
	for pr in m.get_property_list():
		var o: Variant = m.get(pr["name"])
		if o is Object and (o as Object).has_signal("noticia") and not (o as Object).has_meta("_a4_noticias"):
			(o as Object).set_meta("_a4_noticias", true)
			(o as Object).connect("noticia", func(t: String, c: String) -> void:
				for trozo: String in (t + "\n" + c).split("\n"):
					if trozo.strip_edges() != "":
						_vistas[trozo.strip_edges()] = true)
