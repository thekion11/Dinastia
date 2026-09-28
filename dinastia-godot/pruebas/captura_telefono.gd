extends Node
## EL MÓVIL (Tribuna, 28-9-2026): las cuatro pestañas y una publicación tuya
## con los comentarios abiertos para responder.
##   godot --path . --rendering-driver opengl3 --resolution 1600x900 res://pruebas/captura_telefono.tscn
const PASOS := ["inicio", "perfil", "club", "publicar", "comentarios"]
var _n := 0
var _p: Node
var _tel: Telefono
var _i := 0

func _ready() -> void:
	_p = load("res://escenas/principal.tscn").instantiate()
	add_child(_p)

func _process(_d: float) -> void:
	_n += 1
	if _n == 10:
		var m: Mundo = _p.get("mundo")
		_p.call("_anotar", "✅ Victoria de visita", "El equipo gana 2-1 y se sube al tercer puesto.")
		_p.call("_anotar", "❌ Eliminados de la copa", "Caída en penales ante un club de Ascenso.")
		m.redes.publicar(m, "hinchada", ["#Hinchada", m.redes.tendencia])
		var pop := Telefono.abrir(_p, m)
		_tel = pop.find_children("*", "Telefono", true, false)[0]
	if _n < 20:
		return
	var t := _n - 20
	if t % 10 == 0:
		if _i >= PASOS.size():
			get_tree().quit()
			return
		var paso := String(PASOS[_i])
		if paso == "comentarios":
			var mio: Dictionary = (_p.get("mundo") as Mundo).redes.de_cuenta("dt")[0]
			(_tel.get("_abiertos") as Dictionary)[int(mio["id"])] = true
			_tel.ir("perfil")
			(_tel.get("_scroll") as ScrollContainer).set_deferred("scroll_vertical", 330)
		else:
			_tel.ir(paso)
	if t % 10 == 8:
		get_viewport().get_texture().get_image().save_png("res://pruebas/telefono_%s.png" % PASOS[_i])
		_i += 1
