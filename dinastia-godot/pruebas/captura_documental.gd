extends Node
## El documental de la temporada: tres planos (portada, goleador, veredicto).
##   xvfb-run -a godot --path . --rendering-driver opengl3 --resolution 1280x720 res://pruebas/captura_documental.tscn
var _n := 0
var _p: Node
var _d: DocumentalTemporada

func _ready() -> void:
	_p = load("res://escenas/principal.tscn").instantiate()
	add_child(_p)

func _process(_dt: float) -> void:
	_n += 1
	var m: Mundo = _p.get("mundo")
	if _n == 6:
		var sem := 0
		while m.temporada_en_curso() and sem < 80:
			m.avanzar_semana()
			sem += 1
		_d = DocumentalTemporada.abrir(_p, DocumentalTemporada.guion(m), Callable(_p, "_retrato"))
	for k in 3:
		if _n == 14 + k * 10:
			get_viewport().get_texture().get_image().save_png("res://pruebas/capturas/documental_%d.png" % k)
			_d.call("_siguiente")
			if k == 0:
				_d.call("_siguiente")
	if _n == 46:
		get_tree().quit()
