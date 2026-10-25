extends Node
## PULIDO DEL MÓVIL Y DE MI VIDA (25-10-2026, paquete uite): antes/después.
##   IDIOMA=en RESOLUCION=1280x720 TAG=antes herramientas/captura.sh res://pruebas/captura_uite_movil.tscn
## Guarda pruebas/capturas/uite_<toma>_<TAG>_<idioma>_<alto>.png:
##   vacio    el móvil de una partida nueva: Tribuna (perfil sin publicaciones);
##   mensajes la app Mensajes sin chats;
##   feed     Tribuna con publicaciones, comentarios abiertos y el aviso arriba;
##   vida     MI VIDA › Bienestar (ocio de la semana).
var _n := 0
var _p: Node
var _tel: Telefono
var _pop: Control
var _m: Mundo
var _idioma := "es"
var _tag := "x"

func _ready() -> void:
	_idioma = OS.get_environment("IDIOMA") if OS.get_environment("IDIOMA") != "" else "es"
	_tag = OS.get_environment("TAG") if OS.get_environment("TAG") != "" else "x"
	_p = load("res://escenas/principal.tscn").instantiate()
	add_child(_p)

func _process(_d: float) -> void:
	_n += 1
	if _n == 9:
		Idiomas.idioma = _idioma
	if _n == 10:
		_m = _p.get("mundo")
		_pop = Telefono.abrir(_p, _m)
		_tel = _pop.find_children("*", "Telefono", true, false)[0]
		_m.redes.sesion = "dt"
		_tel.set("_sub", "perfil")
		_tel.abrir_app("tribuna")
	if _n == 40:
		_foto("vacio")
		_tel.abrir_app("mensajes")
	if _n == 60:
		_foto("mensajes")
		_m.redes.publicar(_m, "hinchada", ["#Hinchada", _m.redes.tendencia])
		_m.redes.dar_acceso_club(_m)
		_m.redes._publican_jugadores(_m)
		_tel.set("_sub", "inicio")
		_tel.abrir_app("tribuna")
		## Los comentarios de la primera publicación, abiertos.
		if not _m.redes.publicaciones.is_empty():
			var ab: Dictionary = _tel.get("_abiertos")
			ab[int(_m.redes.publicaciones[0]["id"])] = true
			_tel.abrir_app("tribuna")
		_tel.call("_decir", Idiomas.t("✔ Sesión iniciada: %s") % "@mister")
	if _n == 85:
		_foto("feed")
		_pop.queue_free()
		_m.vida.estres = 62
		_p.call("_elegir_grupo", "vida")
		_p.call("_ir_a_chip", {"tab": "Vida", "secc": "bienestar", "label": "Bienestar"})
	if _n == 110:
		_foto("vida")
		get_tree().quit()

func _foto(nombre: String) -> void:
	var img := get_viewport().get_texture().get_image()
	img.save_png("res://pruebas/capturas/uite_%s_%s_%s_%d.png" % [nombre, _tag, _idioma, img.get_height()])
	print("CAPTURA OK ", nombre)
