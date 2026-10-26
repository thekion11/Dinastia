extends BaseIdea
## EL REGISTRO, LA BANDEJA Y LOS AVISOS EN OTRO IDIOMA (agente trad, 26-10-2026). `ui/principal/noticias_p1.gd`
## escribe en castellano (la bandeja se guarda así y el móvil reconoce remitentes por ese texto) y se traduce al
## pintar: el registro tramo a tramo entre etiquetas BBCode (`Principal._traducir_bbcode`), la bandeja con
## `traducir_arbol` y el aviso con `Idiomas.t`. Aquí se arman las líneas tal cual las arma ese archivo y se exige
## que, en inglés, cada tramo de texto salga sin castellano y que el BBCode quede igual.
const N := "Arturo Bedal"

func _probar() -> void:
	_titulo("TRAD · registro, bandeja y avisos de noticias_p1 traducidos")
	Idiomas.idioma = "en"
	var lineas: Array[String] = [
		"[color=#e05555][b]ESTÁS DESPEDIDO.[/b][/color] La directiva pierde la paciencia (%s) y te destituye a mitad de temporada. Elige tu próximo club entre las ofertas de abajo." % "rueda de prensa",
		"La directiva pierde la paciencia (%s) y te destituye a mitad de temporada." % "rueda de prensa",
		"La directiva te destituye tras la %s. Elige tu próximo club entre las ofertas de abajo." % "rueda de prensa",
		"[color=#e05555][b]EL CLUB SE LIQUIDA.[/b][/color] La deuda pudo más: la asociación toma el control y tu etapa aquí se acaba. Elige tu próximo club entre las ofertas de abajo.",
		"La deuda pudo más: la asociación liquida el club y tu etapa aquí se acaba.", "EL CLUB SE LIQUIDA",
		"[color=#c9a227][b]🏅 Logro: Primer título[/b][/color] x", "[color=#c9a227][b]Nuevo récord del club:[/b][/color] x", "Un día como hoy",
		"[color=#4caf6d][b]Subes de nivel: Entrenador.[/b][/color] x", "[color=#4caf6d][b]Debut de la casa:[/b][/color] %s se estrena con el primer equipo." % N,
		"[color=#c9a227][b]🏆 ¡CAMPEÓN![/b][/color] x", "Lo levantaste tú. Queda en la vitrina para siempre.",
		"[color=#c9a227][b]🎬 Gala de fin de año.[/b][/color] Se entregan los premios de la temporada 2026. Tu club se va de vacío.",
		"Se entregan los premios de la temporada 2026. Tu club se lleva: Mejor DT del año.",
		"[color=#c9a227][b]📨 Oferta por %s.[/b][/color] Itálica FC ofrece 3.3M EUR. Respóndela en Mercado." % N,
		"Oferta por %s" % N, "Itálica FC ofrece 3.3M EUR. Tienes que responder.",
		"[color=#8ea595]🔁 %s pasa de Lautaro FC a Itálica FC.[/color]" % N,
		"[color=#c9a227][b]🔎 Informe de ojeo: %s.[/b][/color] Itálica FC · MC · 23 años · media 70 con proyección 80." % N,
		"Campeón de Copa Chile", "Además del título, entran 2.0M EUR de premio.", "Pasas de ronda",
		"Octavos de final superada. Cada eliminatoria que se gana es taquilla y premio.",
		"[color=#c9a227][b]🏗️ Obra terminada:[/b][/color] Termina la reforma del estadio: desde hoy se juega en el estadio nuevo.", "Obra terminada",
		"[color=#c9a227][b]⭐ Agente libre de lujo en el mercado.[/b][/color] %s (28 años, media 80) quedó sin club. Rompió el contrato tras una pelea con su DT. No estará mucho tiempo disponible." % N,
		"[color=#e05555]🩹 %s se lesiona: Desgarro del isquiotibial (lesión en partido), 4 semanas fuera.[/color]" % N,
		"[color=#e05555]🩹 %s se lesiona: Contractura (entrenando al límite), 1 semana fuera.[/color]" % N,
		"🩹 %s se lesiona" % N, "Lesión grave: %s" % N, "Desgarro del isquiotibial. Se pierde 6 semanas.",
		"[color=#e05555]🩹 Recaída de %s:[/color] vuelve a caer de Contractura, 2 semanas más." % N, "vuelve a caer de Contractura, 1 semana más.",
		"[color=#4caf6d]✅ %s recibe el alta médica.[/color]" % N, "✅ Alta médica",
		"[color=#c9a227][b]🩺 Informe médico de %s.[/b][/color] Riesgo: medio-alto. Lesiones graves: 2." % N,
		"Te pagaron la cláusula", "%s se va a Itálica FC por 3.0M EUR. No hubo nada que negociar." % N, "Clausulazo",
		"%s es tuyo: pagaste su cláusula de 3.0M EUR." % N, "Venta cerrada", "%s se va a Itálica FC. Entran 3.0M EUR." % N,
		"[color=#c9a227]🏟️ Reforma recortada[/color]",
	]
	var rx_bb := RegEx.create_from_string("\\]([^\\[]+)")
	var rx_es := RegEx.create_from_string("[áéíóúñ¿¡]|\\b(el|la|los|las|del|que|con|para|por|una|sin|más|está|tu|tus|su|sus|se|de|en|y)\\b")
	var malas: Array[String] = []
	var tramos := 0
	for l: String in lineas:
		var con_bb := "]" + l if not l.begins_with("[") else l
		for m: RegExMatch in rx_bb.search_all(con_bb):
			var tramo := m.get_string(1).strip_edges()
			if tramo == "" or tramo == "x":
				continue
			tramos += 1
			var t := Idiomas.t(tramo)
			var limpio := t.replace(N, "").replace("Itálica FC", "").replace("Lautaro FC", "")
			if rx_es.search(limpio.to_lower()) != null:
				malas.append(t.left(90))
	Idiomas.idioma = "es"
	_comprobar(tramos >= 45, "tramos de texto revisados: %d" % tramos)
	_comprobar(malas.is_empty(), "en inglés no queda castellano (%d%s)" % [malas.size(), "" if malas.is_empty() else ": " + " | ".join(malas.slice(0, 4))])
