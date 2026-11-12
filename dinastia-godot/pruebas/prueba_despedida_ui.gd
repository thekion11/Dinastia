extends Node
## (9-11) El partido de despedida desde la interfaz (necesita pantalla: xvfb-run): se ofrece, «Simularlo» deja la taquilla y quita la pregunta.
## xvfb-run -a godot --path . --rendering-driver opengl3 res://pruebas/prueba_despedida_ui.tscn
var _n := 0
var _p: Node
var _saldo0 := 0
var _fase := 0

## (12-11) MOVIL=1 con una ventana más alta que ancha: como en un teléfono de pie. CAPTURAR=<carpeta>: foto de la pregunta y de la ceremonia.
func _foto(nombre: String) -> void:
	var dir := OS.get_environment("CAPTURAR")
	if dir != "":
		await get_tree().create_timer(1.5).timeout
		get_viewport().get_texture().get_image().save_jpg(dir.path_join(nombre + ".jpg"), 0.9)

func _ready() -> void:
	if OS.get_environment("MOVIL") == "1":
		EscalaMovil.forzar = true
		EscalaMovil.poner(get_tree(), EscalaMovil.ZOOM_MOVIL)
	_p = load("res://escenas/principal.tscn").instantiate()
	add_child(_p)

func _process(_d: float) -> void:
	_n += 1
	if _n == 12 and _fase == 0:
		_saldo0 = _p.mundo.mi_club().saldo
		JornadaDespedida.ofrecer(_p)   ## sin await: queda esperando la elección
		_fase = 1
	if _fase == 1 and _n > 20:
		## (10-11) Antes de la pregunta salen otras cosas (festejo de fin de liga, sorteos de copa): se busca SOLO la pregunta de la despedida y se espera a que salga.
		var capa: Node = null
		for h in _p.get_children():
			if h is EventoDespedida:
				capa = h
		if capa == null and _n < 600:
			return
		if capa == null:
			print("NO SE OFRECIÓ (¿no hay once de leyendas?)")
			print("FIN. 1 fallos")
			get_tree().quit()
			return
		_fase = 9
		await _foto("despedida_pregunta")
		capa.emit_signal("elegido", "simular")
		_fase = 2
		_n = 30
	if _fase == 2 and _n > 45:   ## la ceremonia espera «Continuar»: se pulsa
		for h in _p.get_children():
			if h is CeremoniaDespedida:
				_fase = 9
				await _foto("despedida_ceremonia")
				h.emit_signal("terminado")
				h.queue_free()
				_fase = 3
	if _fase == 3 and _n > 70:
		var sube: bool = _p.mundo.mi_club().saldo > _saldo0
		var sin_pregunta := true
		for h in _p.get_children():
			if h is EventoDespedida:
				sin_pregunta = false
		print("taquilla ", sube, " pregunta cerrada ", sin_pregunta)
		print("FIN. ", 0 if (sube and sin_pregunta) else 1, " fallos")
		get_tree().quit()
