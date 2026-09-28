extends Node
## EL MÓVIL (28-9-2026): inicio, Tribuna con tu foto, cerrar sesión y entrar
## a la cuenta del club con la clave escribiéndose, Mensajes y Ajustes.
##   godot --path . --rendering-driver opengl3 --resolution 1600x900 res://pruebas/captura_telefono.tscn
var _n := 0
var _p: Node
var _tel: Telefono
var _m: Mundo
## [segundo, acción, nombre de la foto o ""]. En tiempo real: el cierre de
## sesión, la clave letra a letra y el "Iniciando sesión…" usan temporizadores.
const GUION := [
	[0.4, "inicio", ""], [0.8, "", "inicio"],
	[1.0, "tribuna", ""], [1.4, "", "tribuna"],
	[1.6, "cerrar", ""], [1.9, "", "cerrando"],
	[3.0, "", "login"],
	[3.1, "clave", ""], [4.0, "", "escribiendo"],
	[6.5, "", "club"],
	[6.7, "publicar", ""], [7.1, "", "publicar_club"],
	[7.3, "mensajes", ""], [7.5, "chat", ""], [7.9, "", "mensajes"],
	[8.1, "ajustes", ""], [8.5, "", "ajustes"],
	[8.7, "calendario", ""], [9.1, "", "calendario"],
	[9.3, "fin", ""],
]
var _t := -1.0
var _hecho := 0

func _ready() -> void:
	_p = load("res://escenas/principal.tscn").instantiate()
	add_child(_p)

func _process(_d: float) -> void:
	_n += 1
	if _n == 10:
		_m = _p.get("mundo")
		_p.call("_anotar", "✅ Victoria de visita", "El equipo gana 2-1 y se sube al tercer puesto.")
		_p.call("_anotar", "La directiva confía en el proyecto", "El presidente habló con la prensa.")
		_m.redes.publicar(_m, "hinchada", ["#Hinchada", _m.redes.tendencia])
		_m.redes.dar_acceso_club(_m)
		_m.redes._publican_jugadores(_m)
		_m.movil.fondo = "atardecer"
		_m.movil.funda = "club"
		var pop := Telefono.abrir(_p, _m)
		_tel = pop.find_children("*", "Telefono", true, false)[0]
	if _tel == null:
		return
	_t += _d if _t >= 0.0 else 0.0
	if _t < 0.0:
		_t = 0.0
	while _hecho < GUION.size() and _t >= float(GUION[_hecho][0]):
		var g: Array = GUION[_hecho]
		_hecho += 1
		match String(g[1]):
			"inicio": _tel.abrir_app("inicio")
			"tribuna": _tel.abrir_app("tribuna")
			"cerrar": _tel.call("_cerrar_sesion_animado")
			"clave": _tel.entrar_con_clave_guardada()
			"publicar":
				_tel.set("_sub", "publicar")
				_tel.abrir_app("tribuna")
			"mensajes": _tel.abrir_app("mensajes")
			"chat":
				_tel.set("_chat", "Community manager")
				_tel.abrir_app("mensajes")
			"ajustes": _tel.abrir_app("ajustes")
			"calendario": _tel.abrir_app("calendario")
			"fin": get_tree().quit()
		if String(g[2]) != "" and String(g[1]) == "":
			get_viewport().get_texture().get_image().save_png("res://pruebas/telefono_%s.png" % String(g[2]))
