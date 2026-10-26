extends Node
## EL PORQUÉ DEL RESULTADO (26-10-2026, sesión 5): las tres causas en el resumen del partido (modo
## instantáneo) y en el final del partido en vivo. Salida: pruebas/capturas/s5_porque_1..2 (JPG con captura.sh).
##   RESOLUCION=1280x720 herramientas/captura.sh res://pruebas/captura_s5_porque.tscn
var _fase := 0
var _espera := 0
var _m: Mundo
var _res: ResumenPartido
var _vivo: PartidoVivo

func _ready() -> void:
	_m = Mundo.new()
	_m.generar(["CHI"], 4711)
	_m.tomar_el_mando(_m.ligas[0].clubes[0].id)
	Partido.ctx_club_id = _m.mi_club_id
	Azar.sembrar(31)
	var par := _m.proximo_partido()
	var p := Partido.new(par[0], par[1])
	p.preparar()
	var c := Control.new()
	c.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(c)
	_res = ResumenPartido.mostrar(c, p, _m.mi_club(), false, false)

func _foto(n: int) -> void:
	get_viewport().get_texture().get_image().save_png("res://pruebas/capturas/s5_porque_%d.png" % n)
	print("FOTO s5_porque_%d" % n)

func _process(_d: float) -> void:
	if _espera > 0:
		_espera -= 1
		return
	match _fase:
		0:
			## El «por qué» queda a la vista (la lista puede ser más alta que la pantalla).
			var caja: Control = _res.find_child("PorQue", true, false)
			var scroll := _res.find_children("*", "ScrollContainer", true, false)
			if caja != null and not scroll.is_empty():
				(scroll[0] as ScrollContainer).ensure_control_visible(caja)
			_espera = 8
			_fase = 1
		1:
			_foto(1)
			_res.get_parent().queue_free()
			var par := _m.proximo_partido()
			var p := Partido.new(par[1], par[0])
			_vivo = PartidoVivo.new()
			_vivo.con_3d = false
			_vivo.set_anchors_preset(Control.PRESET_FULL_RECT)
			add_child(_vivo)
			_vivo.abrir(p, _m.mi_club())
			while not p.terminado_ya:
				p.simular_minuto()
			_espera = 12
			_fase = 2
		2:
			_vivo._cronica.scroll_to_line(_vivo._cronica.get_line_count() - 1)
			_espera = 6
			_fase = 3
		3:
			_foto(2)
			get_tree().quit(0)
