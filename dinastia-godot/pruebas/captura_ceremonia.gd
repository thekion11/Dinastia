extends Node
## LA CEREMONIA ANTES DEL SAQUE, en fotos: vuelo, salida con niños, fila del
## local con su carta y fila de la visita. Salida: pruebas/capturas/ceremonia_1..4.png
var _vista: VistaEstadio
var _t0 := -1.0

func _ready() -> void:
	Calidad.elegida = Calidad.MEDIO
	var m := Mundo.new()
	m.generar(["CHI"], 4711)
	m.mi_club_id = m.ligas[0].clubes[0].id
	Partido.ctx_club_id = m.mi_club_id
	var par := m.proximo_partido()
	var partido := Partido.new(par[0], par[1])
	_vista = VistaEstadio.new()
	add_child(_vista)
	_vista.abrir(par[0], 0.85, par[1], partido)

var _hechas := 0
const MOMENTOS := [2.5, 9.5, 16.5, 21.5]

func _process(_d: float) -> void:
	var c: Variant = _vista.get("_ceremonia")
	if c == null or not is_instance_valid(c):
		print("SIN CEREMONIA")
		get_tree().quit()
		return
	## El reloj de la ceremonia avanza por fotograma a ritmo fijo (xvfb es lento).
	c.set("_t", float(c.get("_t")))
	if _hechas < MOMENTOS.size() and float(c.get("_t")) >= MOMENTOS[_hechas]:
		get_viewport().get_texture().get_image().save_png("res://pruebas/capturas/ceremonia_%d.png" % (_hechas + 1))
		print("FOTO ceremonia_%d a los %.1f s" % [_hechas + 1, float(c.get("_t"))])
		_hechas += 1
		if _hechas >= MOMENTOS.size():
			get_tree().quit()
