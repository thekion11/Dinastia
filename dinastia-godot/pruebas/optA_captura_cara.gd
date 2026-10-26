extends Control
## OPCIÓN A (26-10-2026): la pantalla de personaje con su cámara: cuerpo entero (42 años)
## y la cara de cerca a los 66 (arrugas, canas, entradas).
##   herramientas/captura.sh res://pruebas/optA_captura_cara.tscn
var _n := 0
var _p: Control

func _ready() -> void:
	var m := Mundo.new()
	m.generar(["CHI"], 77)
	m.tomar_el_mando(m.ligas[0].clubes[0].id)
	_p = load("res://ui/entrada/personaje.gd").new()
	_p.set_anchors_preset(Control.PRESET_FULL_RECT)
	_p.call("configurar", {"modo": "dt", "pais": "ARG", "club": m.mi_club(), "paso": 6})
	add_child(_p)
	set_anchors_preset(Control.PRESET_FULL_RECT)

func _process(_d: float) -> void:
	_n += 1
	var est: EstudioPersonaje = _p.get("_estudio")
	if _n == 20:
		est.girar = false
		est.get("_pivote").rotation.y = 0.35
	if _n == 50:
		get_viewport().get_texture().get_image().save_png("res://pruebas/capturas/optA_cuerpo.png")
		var hojas: HojasPersonaje = _p.get("_hojas")
		hojas.cambiar("barba", true, true)
		hojas.cambiar("color_pelo", "2a1c12", true)
		(_p.get("_campos")["edad"] as HSlider).value = 66
		est.enfocar(true)
	if _n == 110:
		get_viewport().get_texture().get_image().save_png("res://pruebas/capturas/optA_cara66.png")
		get_tree().quit()
