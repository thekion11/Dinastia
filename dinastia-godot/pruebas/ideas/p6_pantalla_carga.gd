extends BaseIdea
## La pantalla de carga cubre la ventana entera y centra su contenido aunque su padre no sea un Control o aún no tenga tamaño (móvil, prólogo en 3D).

func _probar() -> void:
	_titulo("P6: PANTALLA DE CARGA SIEMPRE A PANTALLA COMPLETA")
	await get_tree().process_frame
	var vp := get_viewport().get_visible_rect().size
	## Padre que NO es un Control (como el prólogo, un Node3D).
	var p3d := Node3D.new()
	add_child(p3d)
	var n1 := PantallaCarga.mostrar(p3d, "Construyendo la ciudad…")
	await get_tree().process_frame
	_comprobar(n1.size.is_equal_approx(vp) and n1.position == Vector2.ZERO, "con un Node3D de padre cubre la ventana (%s de %s)" % [str(n1.size), str(vp)])
	var centro: CenterContainer = n1.get_child(2)
	_comprobar(centro is CenterContainer and centro.size.is_equal_approx(vp), "y su contenido va dentro de un contenedor centrado del mismo tamaño")
	## Padre Control de tamaño 0 (aún sin maquetar).
	var c := Control.new()
	c.size = Vector2.ZERO
	add_child(c)
	var n2 := PantallaCarga.mostrar(c, "Construyendo la ciudad…")
	await get_tree().process_frame
	_comprobar(n2.size.x >= vp.x - 1.0 and n2.size.y >= vp.y - 1.0, "con un Control de tamaño 0 de padre también cubre la ventana (%s)" % str(n2.size))
	## La barra avanza con las etapas de la construcción.
	PantallaCarga.paso("_suelo")
	PantallaCarga.paso("_estadio")
	_comprobar(is_equal_approx(n2._destino, 0.33) and n2._etapa.text != "", "al acabar el estadio la barra va por el 33 %% y dice «%s»" % n2._etapa.text)
	PantallaCarga.paso("_calles")   ## una etapa anterior no retrocede la barra
	_comprobar(is_equal_approx(n2._destino, 0.33), "y no retrocede si llega un aviso de una etapa anterior")
	for i in 120:
		n2._process(0.05)
	_comprobar(n2._frac >= 0.33 and n2._frac < 0.5 and n2._barra.size.x > 0.0, "la barra se dibuja hasta ahí (%.2f)" % n2._frac)
	var todas := true
	for k: String in PantallaCarga.ETAPAS:
		todas = todas and Idiomas.t(String((PantallaCarga.ETAPAS[k] as Array)[1])) != ""
	_comprobar(todas, "todas las etapas tienen texto")
	## Los consejos avanzan aunque haya pocos fotogramas (la construcción bloquea el hilo): el texto cambia al instante.
	var antes: String = n2._tarjeta_txt.text
	var k0: int = n2._k
	n2._process(5.0)
	_comprobar(n2._k == k0 + 1 and n2._tarjeta_txt.text != antes, "con un solo fotograma largo el consejo cambia al instante («%s»)" % n2._tarjeta_txt.text.left(30))
	n2._ultimo_cambio = Time.get_ticks_msec() - 3000   ## hace más de 2,5 s (con 0 dependía de que el motor llevase 2,5 s en marcha)
	var k1: int = n2._k
	PantallaCarga.paso("_estadio")
	_comprobar(n2._k == k1 + 1, "y cada etapa que acaba también pasa al consejo siguiente")
