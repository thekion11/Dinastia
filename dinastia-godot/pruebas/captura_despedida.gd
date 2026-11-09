extends Node
## Captura del diálogo del partido de despedida (necesita pantalla: xvfb-run): se ofrece, «Simularlo» deja la taquilla y quita la pregunta.
## xvfb-run -a godot --path . --rendering-driver opengl3 res://pruebas/prueba_despedida_ui.tscn
var _n := 0
var _p: Node
var _saldo0 := 0
var _fase := 0

func _ready() -> void:
	_p = load("res://escenas/principal.tscn").instantiate()
	add_child(_p)

func _process(_d: float) -> void:
	_n += 1
	if _n == 12 and _fase == 0:
		_saldo0 = _p.mundo.mi_club().saldo
		JornadaDespedida.ofrecer(_p)   ## sin await: queda esperando la elección
		_fase = 1
	if _fase == 1 and _n > 20:
		var capa: Node = null
		for h in _p.get_children():
			if h is CanvasLayer and h.has_signal("elegido"):
				capa = h
		if capa == null:
			print("NO SE OFRECIÓ (¿no hay once de leyendas?)")
			print("FIN. 1 fallos")
			get_tree().quit()
			return
		await get_tree().create_timer(1.0).timeout
		get_viewport().get_texture().get_image().save_jpg("/tmp/despedida_dialogo.jpg", 0.85)
		print("CAPTURA OK")
		get_tree().quit()
		return
	if _fase == 2 and _n > 60:
		var sube: bool = _p.mundo.mi_club().saldo > _saldo0
		var sin_pregunta := true
		for h in _p.get_children():
			if h is CanvasLayer and h.has_signal("elegido"):
				sin_pregunta = false
		print("taquilla ", sube, " pregunta cerrada ", sin_pregunta)
		print("FIN. ", 0 if (sube and sin_pregunta) else 1, " fallos")
		get_tree().quit()
