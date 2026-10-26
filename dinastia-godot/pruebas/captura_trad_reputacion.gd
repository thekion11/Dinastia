extends Node
## EL PANEL DE REPUTACIÓN EN OTRO IDIOMA (paquete trad, 25-10-2026): titular de fama («Known for…»),
## nivel del club y motivos traducidos. IDIOMA=en|de|… (por defecto en).
##   IDIOMA=en herramientas/captura.sh res://pruebas/captura_trad_reputacion.tscn
var _n := 0
var _p: Node

func _ready() -> void:
	_p = load("res://escenas/principal.tscn").instantiate()
	add_child(_p)

func _process(_d: float) -> void:
	_n += 1
	var m: Mundo = _p.get("mundo") if _n >= 10 else null
	if _n == 10:
		## Después de arrancar: la principal carga las preferencias y pondría el idioma guardado.
		Idiomas.idioma = OS.get_environment("IDIOMA") if OS.get_environment("IDIOMA") != "" else "en"
		var r := m.roles
		r.anotar_reputacion("ganador", 8, "Título: Liga")
		r.anotar_reputacion("formador", 12, "6 canteranos en el plantel")
		r.anotar_reputacion("social", -9, "Lo que el club hace por su gente")
		r.anotar_reputacion("leal", 3, "Otra temporada en %s" % m.mi_club().nombre)
		_p.call("_ir_a_chip", {"tab": "Club", "secc": "carrera", "label": "Mi Carrera"})
		_p.call("_refrescar")
	if _n == 16:
		var lista: Control = _p.get("_lista_club")
		var sc := lista.get_parent()
		while sc != null and not (sc is ScrollContainer):
			sc = sc.get_parent()
		for l in lista.find_children("*", "Label", true, false):
			if Idiomas.mayusculas((l as Label).text).contains(Idiomas.mayusculas(Idiomas.t("LO QUE HA HECHO TU FAMA"))) and sc != null:
				(sc as ScrollContainer).scroll_vertical = int((l as Label).global_position.y - lista.global_position.y) - 240
				break
	if _n == 24:
		get_viewport().get_texture().get_image().save_png("res://pruebas/capturas/trad_reputacion_%s.png" % Idiomas.idioma)
		## Devolver el castellano para no dejar guardado otro idioma en las preferencias de prueba.
		Idiomas.idioma = "es"
		_p.call("_refrescar")
		get_tree().quit()
