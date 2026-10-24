extends Node
## EL MÓVIL SIN MENSAJES (23-10-2026): el estado vacío de la app Mensajes, en el idioma que se pida.
##   IDIOMA=en herramientas/captura.sh res://pruebas/captura_movil_vacio.tscn
## Guarda pruebas/capturas/movil_<inicio|mensajes|noticias>_<idioma>.png
var _n := 0
var _p: Node
var _tel: Telefono
var _idioma := "es"

func _ready() -> void:
	if OS.get_environment("IDIOMA") != "":
		_idioma = OS.get_environment("IDIOMA")
	_p = load("res://escenas/principal.tscn").instantiate()
	add_child(_p)

func _process(_d: float) -> void:
	_n += 1
	if _n == 9:
		Idiomas.idioma = _idioma      ## la partida nueva carga el idioma guardado: se fuerza aquí
	if _n == 10:
		var m: Mundo = _p.get("mundo")
		var pop := Telefono.abrir(_p, m)
		_tel = pop.find_children("*", "Telefono", true, false)[0]
		_tel.abrir_app("inicio")
	if _n == 30:
		_foto("inicio")
		_tel.abrir_app("mensajes")
	if _n == 50:
		_foto("mensajes")
		_tel.abrir_app("noticias")
	if _n == 70:
		_foto("noticias")
		get_tree().quit()

func _foto(nombre: String) -> void:
	var img := get_viewport().get_texture().get_image()
	img.save_png("res://pruebas/capturas/movil_%s_%s.png" % [nombre, _idioma])
	print("CAPTURA OK ", nombre)
