extends Node
## CAPTURAS DEL PAQUETE uico (25-10-2026): competición, tabla del hub, portada,
## gente, prensa, récords, legado y reputación, tras jugar unas jornadas.
##   RESOLUCION=1280x720 VISTA=comp [IDIOMA=en] herramientas/captura.sh res://pruebas/captura_uico.tscn
## Guarda `pruebas/capturas/uico_<vista>_<ancho>[_<idioma>].png`.
var _n := 0
var _p: Node
var _vista := "comp"

func _ready() -> void:
	_vista = OS.get_environment("VISTA") if OS.get_environment("VISTA") != "" else "comp"
	_p = load("res://escenas/principal.tscn").instantiate()
	add_child(_p)

func _process(_d: float) -> void:
	_n += 1
	if _n == 10:
		var m: Mundo = _p.get("mundo")
		## Unas jornadas jugadas: tabla con puntos, historial y portadas.
		for i in 9:
			m.avanzar_semana()
		## La portada que se abre sola tras el partido taparía lo demás.
		for h in _p.get_children():
			if h is PortadaPeriodico:
				h.queue_free()
		var idi := OS.get_environment("IDIOMA")
		if idi != "":
			Idiomas.idioma = idi
		match _vista:
			"comp":
				_p.call("_abrir_competicion")
			"portada":
				var d := {"t": "\"El equipo se planta en lo más alto\"", "c": "Tercera victoria seguida y la hinchada ya sueña.",
					"semana": m.semana, "anio": m.anio, "tipo": "bien", "medio": "El Pelotazo"}
				if m.prensa != null and not m.prensa.portadas.is_empty():
					d = m.prensa.portadas[0]
				PortadaPeriodico.mostrar(_p, m, d)
			"gente":
				_p.call("_ir_a_chip", {"tab": "Gente", "secc": "personas", "label": "La gente del club"})
			"prensa":
				_p.call("_ir_a_chip", {"tab": "Redes", "secc": "prensa", "label": "Sala de Prensa"})
			"debate":
				_p.call("_ir_a_chip", {"tab": "Redes", "secc": "debate", "label": "El Ruido de Fuera"})
			"records":
				_p.call("_ir_a_chip", {"tab": "Récords", "secc": "records", "label": "Récords"})
			"rivales":
				_p.call("_ir_a_chip", {"tab": "Récords", "secc": "rivales", "label": "Rivales"})
			"legado":
				_p.call("_ir_a_chip", {"tab": "Legado", "label": "Historia"})
			"reput":
				_p.call("_ir_a_chip", {"tab": "Club", "secc": "carrera", "label": "Mi Carrera"})
		if _vista != "comp" and _vista != "portada":
			_p.call("_refrescar")
	## La portada automática sale unos fotogramas DESPUÉS del partido: se quita
	## también aquí, salvo cuando es lo que se quiere ver.
	if _n >= 11 and _n <= 25 and _vista != "portada":
		for h in _p.get_children():
			if h is PortadaPeriodico or (h is Control and h.get_script() != null and (String(h.get_script().resource_path).contains("sorteo") or String(h.get_script().resource_path).contains("mentor_voz"))):
				h.queue_free()
		## Y la rueda de prensa a pantalla completa que abre el resultado.
		var rueda: Control = _p.get("_rueda_pop")
		if rueda != null and is_instance_valid(rueda):
			rueda.queue_free()
			_p.set("_rueda_pop", null)
	if _n == 14 and _vista == "reput":
		var lista: Control = _p.get("_lista_club")
		var sc := lista.get_parent()
		while sc != null and not (sc is ScrollContainer):
			sc = sc.get_parent()
		for l in lista.find_children("*", "Label", true, false):
			if (l as Label).text.contains("REPUTA") and sc != null:
				(sc as ScrollContainer).scroll_vertical = int((l as Label).global_position.y - lista.global_position.y) - 10
				break
	if _n == 26:
		var tam := get_viewport().get_visible_rect().size
		var idi2 := OS.get_environment("IDIOMA")
		var nombre := "uico_%s_%d%s" % [_vista, int(tam.x), ("_" + idi2) if idi2 != "" else ""]
		## En --headless no hay imagen: solo sirve para listar textos.
		if DisplayServer.get_name() != "headless":
			get_viewport().get_texture().get_image().save_png("res://pruebas/capturas/%s.png" % nombre)
		print("CAPTURA ", nombre)
		if idi2 != "":
			_listar_castellano()
		get_tree().quit()

## Con IDIOMA puesto: los textos VISIBLES que siguen con pinta de castellano.
func _listar_castellano() -> void:
	var rx := RegEx.new()
	rx.compile("[áéíóúñ¿¡]|\\b(el|la|los|las|de|del|que|con|para|por|tu|tus|una|un|sin|más|hay|está|son|se|su|sus|jornada|partidos|semana)\\b")
	var vistos := {}
	for n in find_children("*", "Control", true, false):
		var c := n as Control
		if not c.is_visible_in_tree():
			continue
		var t := ""
		if c is Label:
			t = (c as Label).text
		elif c is Button:
			t = (c as Button).text
		if t.length() >= 4 and rx.search(t.to_lower()) and not vistos.has(t):
			vistos[t] = true
			print("  CASTELLANO· ", t.replace("\n", " ⏎ ").left(140))
