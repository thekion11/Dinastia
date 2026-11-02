extends "res://ui/ciudad_vista_p1_p1.gd"
## (Parte 2 de 2 de `ciudad_vista_p1.gd`.)

## `desde`: dónde aparecer; sin él, el punto de siempre (la avenida sur en coche,
## la plaza a pie). El prólogo (fase 2) empieza en la acera frente a la puerta del club.
func explorar(modo: String, desde: Vector3 = Vector3.INF) -> void:
	if _explorador != null:
		return
	if _ciudad != null and not _ciudad.completa:   ## hace falta la ciudad entera (colisiones, tráfico): se espera a lo diferido
		await _ciudad.resto_listo
		if _explorador != null:
			return
	_explorador = ExploradorCiudad.new()
	_raiz3d.add_child(_explorador)
	if desde == Vector3.INF:
		desde = Vector3(0, 0, CityBuilder.RING_Z_SUR) if modo == "coche" else Vector3(0, 0, -440)
	_explorador.iniciar(_ciudad, modo, desde, club.nombre if club != null else "", String(animo.get("estado", "normal")))
	_explorador.salir.connect(_dejar_de_explorar)
	_explorador.interactuar.connect(_interactuar_en_ciudad)
	## A pie o en coche, fuera los rótulos del MAPA (nombres flotantes de parques,
	## solares...): a ras de calle se veían repetidos sobre los carteles de verdad.
	_ciudad.mostrar_rotulos(false)
	for h in get_children():
		if h is Control and (h as Control).visible and h != _ficha:
			(h as Control).visible = false
			_barra_mapa.append(h)
