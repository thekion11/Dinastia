extends Node
## (10-11) EL FINAL DE TEMPORADA COMPLETO con pantalla: al pulsar «Temporada siguiente» sale la pantalla ÚNICA de resumen (a pantalla completa) y, al
## cerrarla, sigue el documental. Necesita pantalla: xvfb-run -a godot --path . --rendering-driver opengl3 res://pruebas/prueba_resumen_temporada.tscn
## Con CAPTURAR=<carpeta> guarda la foto en <carpeta>/resumen_temporada.jpg.
var _n := 0
var _p: Node
var _fase := 0

func _ready() -> void:
	AvanceSemana.partido_obliga = false
	_p = load("res://escenas/principal.tscn").instantiate()
	add_child(_p)

func _resumen() -> Node:
	for h in _p.get_children():
		if h is ResumenTemporada:
			return h
	return null

func _process(_d: float) -> void:
	_n += 1
	if _n == 12 and _fase == 0:
		_fase = 9
		var guard := 0
		while _p.mundo.temporada_en_curso() and guard < 80:
			_p.mundo.avanzar_semana()
			guard += 1
		if _p.mundo.prensa != null:
			_p.mundo.prensa.despedida_ofrecida_anio = _p.mundo.anio   ## esta prueba mira el resumen, no la despedida
		var au = _p.mundo.auspicio
		if au != null and au.contrato.is_empty():   ## un patrocinador en el pecho, para ver su franja en el resumen
			au.generar_ofertas(_p.mundo.mi_club())
			if not au.ofertas.is_empty():
				au.firmar(0)
		_p._nueva_temporada()
		_fase = 1
		_n = 20
	elif _fase == 1 and _n > 40:
		_fase = 9
		var rs := _resumen()
		var sale := rs != null
		print("al pulsar «Temporada siguiente» sale la pantalla única de resumen: ", sale)
		var ok := sale
		if sale:
			await get_tree().create_timer(1.0).timeout
			var dir := OS.get_environment("CAPTURAR")
			if dir != "":
				get_viewport().get_texture().get_image().save_jpg(dir.path_join("resumen_temporada.jpg"), 0.9)
			var tam: Vector2 = (rs as ResumenTemporada)._raiz.size
			var completa: bool = tam.x >= get_viewport().get_visible_rect().size.x - 1.0
			print("ocupa toda la pantalla: ", completa)
			ok = ok and completa
			(rs as ResumenTemporada)._cerrar()
			await get_tree().create_timer(0.8).timeout
			var se_fue := _resumen() == null or (_resumen() as ResumenTemporada).is_queued_for_deletion()
			print("al cerrarla se va: ", se_fue)
			ok = ok and se_fue
		print("FIN. %d fallos" % (0 if ok else 1))
		get_tree().quit()
