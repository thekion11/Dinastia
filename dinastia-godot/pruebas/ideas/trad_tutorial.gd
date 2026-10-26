extends BaseIdea
## EL TUTORIAL EN LOS 9 IDIOMAS (agente trad, 26-10-2026). El guion se arma en castellano (las misiones son
## también su clave en `PanelObjetivos`) y se traduce al pintar con `Idiomas.t`: exactas para lo fijo y
## patrones para lo que lleva el club, el mentor, la estrella o el rival. Aquí se arma el guion de cada modo
## con una partida de verdad y se comprueba que cada texto visible sale traducido en los 8 idiomas, y que en
## inglés no queda ni una palabra castellana (quitando los nombres propios del contexto).
const MODOS := ["dt", "dir", "ayudante", "interino", "cantera", "imperio", "jeque", "creador"]

func _probar() -> void:
	_titulo("TRAD · el tutorial traducido")
	var m := _mundo(2600)
	var ctx := Tutorial.contexto(m, m.mi_club().nombre)
	## Para que salgan todos los pasos opcionales del guion.
	if (ctx["joven"] as Dictionary).is_empty():
		ctx["joven"] = {"id": "x", "nombre": "Tomás Prueba", "edad": 19, "pot": 80}
	ctx["chico"] = {"nombre": "Nico Prueba", "edad": 13}
	var propios: Array[String] = []
	for k: String in ["club", "estadio", "rival", "liga", "dt"]:
		if String(ctx.get(k, "")) != "":
			propios.append(String(ctx[k]))
	for k: String in ["estrella", "joven", "chico"]:
		if (ctx[k] as Dictionary).has("nombre"):
			propios.append(String(ctx[k]["nombre"]))
	var rx := RegEx.create_from_string("[áéíóúñ¿¡]|\\b(el|la|los|las|del|que|con|para|por|una|sin|más|está|tu|tus|su|sus|usted|esta|este)\\b")
	var textos := 0
	var fallos: Array[String] = []
	for modo: String in MODOS:
		var g := Tutorial.guion(modo, ctx)
		var mentor := String(g["mentor"]["nombre"])
		var visibles: Array[String] = [String(g["prologo"]), String(g["lugar"]), String(g["mentor"]["cargo"])]
		for paso: Dictionary in g["pasos"]:
			visibles.append(String(paso["texto"]))
			if paso.has("mision"):
				visibles.append(String(paso["mision"]))
		for s: String in visibles:
			textos += 1
			for idi: String in Idiomas.ORDEN:
				Idiomas.idioma = idi
				var t := Idiomas.t(s)
				if t == s:
					fallos.append("%s/%s: %s" % [modo, idi, s.left(60)])
				elif idi == "en":
					var limpio := t.replace(mentor, "")
					for n: String in propios:
						limpio = limpio.replace(n, "")
					if rx.search(limpio.to_lower()) != null:
						fallos.append("%s/en con castellano: %s" % [modo, t.left(90)])
	Idiomas.idioma = "es"
	_comprobar(textos > 100, "textos visibles del tutorial en los 8 modos: %d" % textos)
	_comprobar(fallos.is_empty(), "todo el tutorial sale traducido (%d fallos%s)" % [fallos.size(),
		"" if fallos.is_empty() else ": " + " | ".join(fallos.slice(0, 5))])
