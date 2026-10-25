extends Control
## CAPTURAS DEL PERSONAJE (f1p, 25-10-2026): el creador del menú y la etapa
## obligatoria de entrada (`PantallaPersonaje`), en Forward+:
##   QUE=creador   herramientas/captura.sh res://pruebas/f1p_captura_personaje.tscn
##   QUE=etapa     (aspecto, datos y la confirmación)
## Las imágenes salen en `pruebas/capturas/f1p_<que>_<n>.png` (captura.sh las pasa a JPG).
var _n := 0
var _que := "creador"
var _nodo: Control
var _fotos: Array = []

func _ready() -> void:
	_que = OS.get_environment("QUE") if OS.get_environment("QUE") != "" else "creador"
	var m := Mundo.new()
	m.generar(["CHI"], 77)
	m.tomar_el_mando(m.ligas[0].clubes[0].id)
	m.roles.look["p3d"] = {"ropa": "traje", "gafas": "ver", "barba": true, "complexion": 0.3}
	if _que == "creador":
		_fotos = [70]
		(func() -> void: _nodo = CreadorPersonaje.abrir(self, m)).call_deferred()
	else:
		_fotos = [40, 70, 100]
		var p: Control = load("res://ui/entrada/personaje.gd").new()
		p.set_anchors_preset(Control.PRESET_FULL_RECT)
		p.call("configurar", {"modo": "dt", "pais": "ARG", "club": m.mi_club(), "paso": 6})
		add_child(p)
		_nodo = p

func _process(_d: float) -> void:
	if _nodo == null:
		return
	_n += 1
	if _n == 10 and _que == "creador":
		_siguiente(-1)
	var k := _fotos.find(_n)
	if k >= 0:
		get_viewport().get_texture().get_image().save_png("res://pruebas/capturas/f1p_%s_%d.png" % [_que, k])
		_siguiente(k)
	if _n > int(_fotos.back()) + 2:
		get_tree().quit()

## Entre foto y foto: otra pestaña del creador, o el siguiente paso de la etapa.
func _siguiente(k: int) -> void:
	if _que == "creador":
		var pest: Variant = _nodo.get("_pestanas")
		if pest is TabContainer:
			(pest as TabContainer).current_tab = 1
		return
	if k == 0:
		_nodo.call("_ir_a", "datos")
		_nodo.call("_poner_datos", {"nombre": "Lucía", "apellido": "Ferreyra", "edad": 41})
	elif k == 1:
		_nodo.call("_confirmar")
