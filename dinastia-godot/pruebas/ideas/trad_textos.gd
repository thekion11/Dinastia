extends BaseIdea
## TRADUCCIONES DE LA SESIÓN 2 (paquete trad, 25-10-2026). Comprueba en los 8 idiomas que los textos del
## núcleo que se pintan (charlas de la gente, fama, mesa del agente, carrera, jornada legal...) salen
## traducidos, que los marcadores %s/%d de cada plantilla nueva van en el mismo orden y que los patrones
## con nombres no se tragan la oración siguiente (el fallo que daba «…a Pedro Soto. El directorio…» en turco).
const IDIOMAS := ["en", "pt", "fr", "it", "de", "ca", "pl", "tr"]
const RUTA_PARCHE := "res://datos/trad_parches/s2_trad.json"

func _probar() -> void:
	_titulo("TRADUCCIONES DEL PAQUETE trad")
	var parche: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(RUTA_PARCHE))
	var exactas: Dictionary = parche.get("exactas", {})
	_comprobar(exactas.size() > 400 and (parche.get("patrones", []) as Array).size() > 150, "el parche trae %d frases y %d patrones" % [exactas.size(), (parche.get("patrones", []) as Array).size()])
	var rx := RegEx.create_from_string("%[+\\-]?\\d*\\.?\\d*[sdf]")
	var sin := 0
	var marcas_mal := 0
	for l: String in IDIOMAS:
		Idiomas.idioma = l
		for es: String in exactas:
			var tr := Idiomas._directa(es)
			if tr == "":
				sin += 1
				continue
			var a: Array = rx.search_all(es).map(func(m: RegExMatch) -> String: return m.get_string())
			var b: Array = rx.search_all(tr).map(func(m: RegExMatch) -> String: return m.get_string())
			if a != b:
				marcas_mal += 1
	_comprobar(sin == 0, "todas las frases del parche están en el diccionario en los 8 idiomas (faltan %d)" % sin)
	_comprobar(marcas_mal == 0, "los marcadores %%s/%%d van en el mismo orden en todos los idiomas (%d mal)" % marcas_mal)
	## Frases compuestas: oraciones con nombres, señales del agente y fama.
	var casos := [
		"Dejas el club en manos de Pedro Soto. Leyenda del club. La gente lo idolatra, pero nunca ha dirigido. El directorio le da un margen de 8 partidos.",
		"Se le borra la sonrisa. «Bueno, bueno... hablemos.» Baja a 25 %. (Se le escapa una media sonrisa: tiene sitio.) (Mira el reloj.)",
		"Te conocen como ganador, aunque dicen que te falta juego limpio",
		"Te avisa sin rodeos: hay 3 que llegan justos. Él no los sacaría.",
		"🧣  3-1 al Chillán Rojo. Así da gusto.",
		"Rival de siempre: U. Andina.",
		"INTERINATO: salvar al club del descenso en 5 fechas",
		"Barrera, rosca y una barra de potencia.\nRécord: 0 de 5",
	]
	for l: String in IDIOMAS:
		Idiomas.idioma = l
		Idiomas._cache.clear()
		var quedan: Array[String] = []
		for c: String in casos:
			var t := Idiomas.t(c)
			## Ninguna oración castellana debe quedar entera dentro del resultado.
			if t == c or t.contains("El directorio") or t.contains("Mira el reloj") or t.contains("Así da gusto") or t.contains("salvar al club") or t.contains("Récord"):
				quedan.append(c.left(30))
		_comprobar(quedan.is_empty(), "%s: las frases compuestas salen traducidas enteras %s" % [l, str(quedan)])
	Idiomas.idioma = "en"
	Idiomas._cache.clear()
	_comprobar(Idiomas.t("Dejas el club en manos de Pedro Soto. Leyenda del club. La gente lo idolatra, pero nunca ha dirigido. El directorio le da un margen de 8 partidos.").ends_with("The board gives him 8 matches of grace."), "en: el nombre no se traga la oración siguiente")
	_comprobar(Idiomas.t("Rival de siempre: U. Andina.") == "Long-standing rival: U. Andina.", "en: un nombre con inicial («U. Andina») no corta el patrón")
	_comprobar(Idiomas.t("R. M4ldini (Grupo Sur) controla a 3 de tus jugadores.") == "R. M4ldini (Grupo Sur) controls 3 of your players.", "en: inicial al principio y nombre entre paréntesis")
	## La fama va en frases enteras: «formador» suelto sigue siendo el perfil del agente («mentor»).
	_comprobar(Idiomas.t("Te conocen como formador") == "Known for developing talent" and Idiomas.t("formador") == "mentor", "en: el titular de fama no pisa el perfil del agente")
	## La jornada legal y el tipo de contrato se traducen en el propio núcleo (solo se pintan).
	var jt := Contratos.texto_jornada("CHI", 2026, 30)
	_comprobar(jt.contains("h a week") and jt.contains("Law 21.561") and not jt.contains("semanales"), "en: jornada legal traducida: %s" % jt.left(70))
	var m := _mundo(2500)
	var j: Jugador = m.mi_club().plantilla[0]
	_comprobar(Contratos.tipo(j, true) == "On loan", "en: el tipo de contrato se traduce")
	Idiomas.idioma = "es"
	Idiomas._cache.clear()
	_comprobar(Contratos.tipo(j, true) == "Cedido" and Contratos.texto_jornada("CHI", 2026, 30).begins_with("42 h semanales"), "es: en castellano no cambia nada")
