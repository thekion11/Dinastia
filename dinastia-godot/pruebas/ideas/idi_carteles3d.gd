extends BaseIdea
## M-333 (28-10-2026): LOS CARTELES DEL 3D EN OTRO IDIOMA. Se monta la ciudad entera en inglés y se recorren sus `Label3D`:
## si `Idiomas.t` cambia un rótulo que ya está puesto, ese rótulo se escribió sin pasar por la traducción (se ve en castellano
## aunque la frase está traducida). Los que no tienen traducción y parecen castellano se listan aparte: son nombres propios
## (calles, parques, puentes, estaciones, destinos de bus) y la publicidad pintada de la ciudad chilena, que se quedan en
## castellano como en la calle real; si sube de 61 es que entró un rótulo nuevo sin traducir.
##   herramientas/ideas.sh idi_carteles3d   (lista en /tmp/ideas_idi_carteles3d.txt; ~1 min, en especiales)

const PALABRAS_ES := ["de", "del", "la", "las", "los", "el", "y", "con", "para", "sobre", "junto", "calle", "plaza", "parque",
	"estación", "mercado", "ayuntamiento", "salida", "entrada", "usted", "está", "línea", "ciudad", "estadio"]

func _probar() -> void:
	_titulo("CARTELES 3D DE LA CIUDAD EN INGLÉS (M-333)")
	var antes := Idiomas.idioma
	Idiomas.idioma = "en"
	var b := CityBuilder.new()
	add_child(b)
	b.build({"club": {"nombre": "Andino FC", "c1": Color(0.8, 0.1, 0.1), "c2": Color.WHITE, "cap": 30000, "rep": 60, "socios": 20000,
		"estadioNom": "Estadio"}, "inst": {}, "obras": [], "terrenos": [], "negocios": {}, "perfil_estadio": {}, "dia_partido": true, "vecinos": 30})
	## Los nombres de calle («Av. Las Acacias / Los Maitenes») son nombres propios: no se traducen.
	var calle := RegEx.create_from_string("^(Av\\. |Pje\\. |Calle )?(El|La|Las|Los) [^|]*$|/")
	var sin_t: Array[String] = []
	var raras: Dictionary = {}
	var re := RegEx.create_from_string("(?i)(?<![\\p{L}])(" + "|".join(PALABRAS_ES) + ")(?![\\p{L}])")
	var destino := RegEx.create_from_string("^C?\\d+[ce]? · ")
	var total := 0
	for n: Node in b.find_children("*", "Label3D", true, false):
		var txt := String((n as Label3D).text)
		if txt.strip_edges() == "":
			continue
		total += 1
		## Los letreros de los buses («150 · UNIVERSIDAD») son su destino: nombre propio, como en el bus real.
		if destino.search(txt) != null:
			continue
		## «☕ Café» ya es la traducción de «☕ Cafetería»: traducirla otra vez no cuenta.
		var ya := Idiomas.origen(txt)
		if Idiomas.t(txt) != txt and (ya == "" or ya == txt):
			if not sin_t.has(txt):
				sin_t.append(txt)
		elif re.search_all(txt).size() >= 1 and calle.search(txt) == null:
			raras[txt] = true
	sin_t.sort()
	for t: String in sin_t.slice(0, 40):
		print("    sin Idiomas.t: «%s» → «%s»" % [t.replace("\n", " | "), Idiomas.t(t).replace("\n", " | ")])
	var lista := raras.keys()
	lista.sort()
	for t: String in lista.slice(0, 80):
		print("    sin traducción: «%s»" % t.replace("\n", " | "))
	_comprobar(total > 100, "%d rótulos 3D en la ciudad" % total)
	_comprobar(sin_t.is_empty(), "todos los rótulos traducibles pasan por Idiomas.t (%d no)" % sin_t.size())
	_comprobar(lista.size() <= int(OS.get_environment("IDI_RARAS_MAX") if OS.get_environment("IDI_RARAS_MAX") != "" else "9999"),
		"%d rótulos sin traducción que parecen castellano" % lista.size())
	Idiomas.idioma = antes
	b.queue_free()
