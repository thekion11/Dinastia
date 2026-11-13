extends Node
## SONDA DE IDIOMAS DE «LA RUTA»: pinta todas las pantallas del modo jugador en
## español y en los 8 idiomas y lista los textos que salen IGUAL que en español
## (candidatos a «sin traducir»; los nombres propios y las cifras se ven a ojo).
##   xvfb-run -a godot --path . res://pruebas/_sonda/sonda_idiomas_ruta.tscn
var _ui: CarreraJugadorUI

func _textos(raiz: Node, en: Dictionary) -> void:
	for n: Node in raiz.find_children("*", "", true, false):
		var t := ""
		if n is Label:
			t = (n as Label).text
		elif n is Button:
			t = (n as Button).text
		if t.strip_edges().length() >= 3:
			en[t] = true
		if n is Control and (n as Control).tooltip_text.length() >= 3:
			en[(n as Control).tooltip_text] = true

func _recorrer() -> Dictionary:
	var en := {}
	var m := CarreraJugadorUI.mundo
	var c := _ui.carrera
	_ui._pintar_crear()
	_textos(_ui, en)
	RutaCrear.pintar_ofertas(_ui, CarreraComienzo.pruebas(m, 5))
	_textos(_ui, en)
	for pest: String in ["hoy", "yo", "ruta"]:
		_ui._pestana = pest
		_ui._pintar_semana()
		_textos(_ui, en)
	var toque := RutaToque.abrir(_ui)
	_textos(toque, en)
	toque.free()
	var club := c.club(m)
	var mo := RutaMomentos.abrir(_ui, _ui._partido_de_la_semana(club))
	for tipo: String in CarreraMomentos.TIPOS:
		for q: float in [1.0, 0.6, 0.1]:
			en[Idiomas.t(String(CarreraMomentos.desenlace(tipo, q)["texto"]))] = true
		en[Idiomas.t(String(CarreraMomentos.TIPOS[tipo][0]))] = true
		en[Idiomas.t(String(CarreraMomentos.TIPOS[tipo][1]))] = true
	_textos(mo, en)
	mo.free()
	(c.ruta["ultimo"] as Dictionary)["visto"] = false
	(c.ruta["temporada"] as Dictionary)["visto"] = false
	_ui._pestana = "hoy"
	_ui._pintar_semana()
	_textos(_ui, en)
	_ui._pintar_semana()
	_textos(_ui, en)
	RutaCrear.pintar_retiro(_ui)
	_textos(_ui, en)
	return en

func _ready() -> void:
	RutaEstilo.sin_animar = true
	CarreraJugadorUI.mundo = null
	_ui = load("res://escenas/carrera_jugador.tscn").instantiate()
	add_child(_ui)
	_ui._crear()
	var m := CarreraJugadorUI.mundo
	var c := _ui.carrera
	## Un estado con de todo: decisiones, oferta, botas, premios, compras, misiones.
	c.fama = 45
	c.eventos.append(CarreraPatrocinio.eventos(c)[0])
	c.ofertas.append({"club_id": m.ligas[0].clubes[0].id, "sueldo": 9000, "semanas": 2})
	CarreraPatrocinio.firmar(c, "rayo")
	c.ruta["puntos"] = 2
	c.ruta["ahorros"] = CarreraVida.precio(c, m, "fisio") * 2
	CarreraVida.comprar(c, m, "fisio")
	c.energia = 20
	c.tras_partido(m, {"minutos": 90, "goles": 2, "asist": 1, "nota": 8.4, "titular": true, "encajados": 0, "paradas": 3})
	c.stats_temp["pj"] = 32
	CarreraPremios.cerrar(c, m)
	c.capitan = true
	var base := {}
	var repetidos := {}
	for idi: String in ["es"] + Array(Idiomas.ORDEN):
		Idiomas.idioma = idi
		var en := _recorrer()
		if idi == "es":
			base = en
			print("TEXTOS EN ESPAÑOL: %d" % base.size())
			continue
		for t: String in en:
			if base.has(t):
				repetidos[t] = String(repetidos.get(t, "")) + idi + " "
	var lista: Array = repetidos.keys()
	lista.sort()
	for t2: String in lista:
		print("IGUAL [%s] %s" % [String(repetidos[t2]).strip_edges(), t2.replace("\n", " ")])
	print("FIN SONDA IDIOMAS: %d textos iguales en algún idioma" % lista.size())
	get_tree().quit()
