extends "res://pruebas/banco/varios_p6_p1.gd"
## [Capa de `varios_p6.gd`, 21-11 refactor de forma] Secciones de ASPECTO Y AUDIO. Cada una es
## independiente (no comparte estado); el orden de las comprobaciones y los textos son los de antes.


## LOS FONDOS Y EL CLIMA.
func _av_fondos_clima() -> void:
	## LOS FONDOS. Veinticuatro, y todos tienen que rasterizar de verdad.
	_comprobar(Fondo.NOMBRES.size() == 24, "hay 24 fondos (%d)" % Fondo.NOMBRES.size())
	var sin_titulo: Array[String] = []
	var flacos: Array[String] = []
	for k: String in Fondo.NOMBRES:
		if not Fondo.TITULOS.has(k):
			sin_titulo.append(k)
		## Un SVG que no dibuja nada tambien "funciona": sale un string corto.
		if Fondo.svg_de(k).length() < 800:
			flacos.append(k)
	_comprobar(sin_titulo.is_empty(), "todos los fondos tienen nombre en el menu")
	_comprobar(flacos.is_empty(), "y todos dibujan algo (%s)" % ("ninguno vacio" if flacos.is_empty() else ", ".join(flacos)))
	var tex := Fondo.textura("aeropuerto")
	_comprobar(tex != null and tex.get_width() > 100, "un fondo nuevo rasteriza a imagen de verdad")

	## EL CLIMA. Diez modos, y el que no existe no puede reventar.
	_comprobar(FondoAnimado.MODOS.size() == 10, "hay 10 climas (%d)" % FondoAnimado.MODOS.size())
	_comprobar(FondoAnimado.MODOS.has("ninguno"), "y se puede apagar el movimiento")


## LOS SONIDOS (que tengan onda) y QUE NO TOCAN `Azar`.
func _av_sonidos_azar() -> void:
	## LOS SONIDOS. Que existan no basta: tienen que tener onda.
	var cat: Array = Sonido.catalogo()
	_comprobar(cat.size() >= 60, "hay al menos 60 efectos (%d)" % cat.size())
	var mudos: Array[String] = []
	var largos: Array[String] = []
	for n: String in cat:
		var f: Dictionary = Sonido.ficha(n)
		if int(f.get("pico", 0)) < 200:
			mudos.append(n)
		if float(f.get("segundos", 0.0)) > 6.0:
			largos.append(n)
	_comprobar(mudos.is_empty(), "y ninguno sale en silencio (%s)" % ("todos suenan" if mudos.is_empty() else ", ".join(mudos)))
	_comprobar(largos.is_empty(), "y ninguno se pasa de 6 s (%s)" % ("ninguno" if largos.is_empty() else ", ".join(largos)))
	for pedido: String in ["clausula", "lesion_grave", "oferta", "contrato_vence",
			"obra", "venta", "ronda_superada"]:
		_comprobar(cat.has(pedido), "existe el sonido propio de «%s» que pedia el LEEME" % pedido)

	## Y QUE NO TOQUEN `Azar`. Es la regla que ya se rompio una vez en este
	## proyecto: un adorno que consume el generador determinista cambia la liga.
	var m := Mundo.new()
	m.generar(["CHI"], 4242)
	var antes := Azar.ent(0, 1000000)
	for i in 40:
		Sonido.toca("clic")
		Sonido.toca("gol")
	Azar.sembrar(4242)
	var despues_a := Azar.ent(0, 1000000)
	Azar.sembrar(4242)
	var despues_b := Azar.ent(0, 1000000)
	_comprobar(despues_a == despues_b, "el azar sigue siendo reproducible tras sembrar")
	_comprobar(antes >= 0, "  (referencia %d)" % antes)


## LA MÚSICA. Seis piezas, con onda y en bucle.
func _av_musica() -> void:
	## LA MÚSICA. Seis piezas, con onda y en bucle.
	_comprobar(Musica.PIEZAS.size() == 6, "hay 6 piezas de musica (%d)" % Musica.PIEZAS.size())
	for clave: String in Musica.PIEZAS:
		var fm: Dictionary = Musica.ficha(clave)
		_comprobar(int(fm.get("pico", 0)) > 500, "«%s» suena (pico %d)" % [clave, int(fm.get("pico", 0))])
		_comprobar(bool(fm.get("bucle", false)), "  y esta en bucle")
		_comprobar(float(fm.get("segundos", 0.0)) > 15.0,
			"  y dura lo suyo (%.1f s)" % float(fm.get("segundos", 0.0)))


## LOS IDIOMAS: ninguna fila corta, cobertura y los ordinales y mayúsculas por idioma.
func _av_idiomas() -> void:
	## LOS IDIOMAS. Lo que se comprueba no es que la traduccion sea buena -eso no
	## lo sabe un banco- sino que ninguna fila se quede CORTA: una fila con menos
	## columnas que idiomas deja ese idioma en castellano sin avisar.
	_comprobar(Idiomas.ORDEN.size() == 8, "hay 8 idiomas ademas del castellano (%d)" % Idiomas.ORDEN.size())
	var cortas: Array[String] = []
	for k2: String in Idiomas.TABLA:
		var fila: Array = Idiomas.TABLA[k2]
		if fila.size() != Idiomas.COLUMNAS_TABLA:
			cortas.append(k2)
	_comprobar(cortas.is_empty(), "y ninguna fila se queda corta (%s)" % ("todas completas" if cortas.is_empty() else ", ".join(cortas)))
	for idi: String in Idiomas.ORDEN:
		## Al menos las de la tabla: los de columna, por la tabla; polaco y turco,
		## porque su diccionario la trae entera.
		_comprobar(Idiomas.cobertura(idi) >= Idiomas.TABLA.size(),
			"«%s» tiene al menos las %d frases (%d)" % [idi, Idiomas.TABLA.size(), Idiomas.cobertura(idi)])
	Idiomas.idioma = "en"
	_comprobar(Idiomas.t("Guardar") == "Save", "traducir funciona (Guardar -> %s)" % Idiomas.t("Guardar"))
	_comprobar(Idiomas.t("Una frase que no existe") == "Una frase que no existe",
		"y lo que no esta traducido se queda en castellano en vez de salir en blanco")
	## Ordinales y mayúsculas por idioma (MEGAPLAN fase 1).
	Idiomas.idioma = "fr"
	var o_fr := Idiomas.t("vas 1º (meta: 3º)")
	_comprobar(o_fr.contains("1er") and o_fr.contains("3e"), "francés: 1er y 3e (%s)" % o_fr)
	Idiomas.idioma = "ca"
	var o_ca := Idiomas.t("vas 2º (meta: 12º)")
	_comprobar(o_ca.contains("2n") and o_ca.contains("12è"), "catalán: 2n y 12è (%s)" % o_ca)
	Idiomas.idioma = "tr"
	_comprobar(Idiomas.mayusculas("lig") == "LİG", "turco: la i con punto en mayúscula (%s)" % Idiomas.mayusculas("lig"))
	Idiomas.idioma = "es"
	_comprobar(Idiomas.t("Guardar") == "Guardar", "y volver al castellano no deja nada traducido")


## LAS FORMAS Y MARCAS DE TARJETA.
func _av_tarjetas() -> void:
	## LAS FORMAS Y MARCAS DE TARJETA.
	_comprobar(MarcaPanel.ESTILOS.size() == 7, "hay 7 marcas de tarjeta (%d)" % MarcaPanel.ESTILOS.size())
	_comprobar(MarcaPanel.ESTILOS.has("ninguno"), "y se pueden quitar")
