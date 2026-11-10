extends BaseIdea
## (4-11) La resolución del 3D también se elige en MEDIA (50-100 %): Alta y Ultra siempre 100 %, Mínima su propio valor; se guarda y se recupera.

func _probar() -> void:
	_titulo("P6: RESOLUCIÓN DEL 3D EN MEDIA")
	var guardada := Calidad.escala_media
	var guardada_min := Calidad.escala_minimo
	Calidad.escala_media = 0.8
	Calidad.escala_minimo = 0.5
	_comprobar(is_equal_approx(Calidad.escala_3d(Calidad.MEDIO), 0.8), "media usa su valor (%.2f)" % Calidad.escala_3d(Calidad.MEDIO))
	_comprobar(is_equal_approx(Calidad.escala_3d(Calidad.MINIMO), 0.5), "mínima usa el suyo")
	_comprobar(is_equal_approx(Calidad.escala_3d(Calidad.ALTO), 1.0) and is_equal_approx(Calidad.escala_3d(Calidad.ULTRA), 1.0), "alta y ultra, 100 %")
	var vp := SubViewport.new()
	add_child(vp)
	Calidad.aplicar_viewport(vp, Calidad.MEDIO)
	_comprobar(is_equal_approx(vp.scaling_3d_scale, 0.8), "el viewport recibe el 80 %% (%.2f)" % vp.scaling_3d_scale)
	Calidad.aplicar_viewport(vp, Calidad.ALTO)
	_comprobar(is_equal_approx(vp.scaling_3d_scale, 1.0), "al pasar a Alta vuelve a 100 %")
	Calidad.escala_media = guardada
	Calidad.escala_minimo = guardada_min

	## (10-11, P1) Resolución 3D automática: altura máxima de 720 px de ULTRA BAJA a MEDIA; ALTA y ULTRA no se tocan; apagada no cambia nada.
	var auto_antes := Calidad.res3d_auto
	var alto_antes := OS.get_environment("RES3D_ALTO")
	Calidad.escala_media = 1.0
	Calidad.escala_minimo = 0.5
	OS.set_environment("RES3D_ALTO", "1080")
	Calidad.res3d_auto = false
	_comprobar(is_equal_approx(Calidad.escala_3d(Calidad.MEDIO), 1.0), "res. 3D automática apagada: MEDIA sigue a 100 %")
	Calidad.res3d_auto = true
	_comprobar(is_equal_approx(Calidad.escala_3d(Calidad.MEDIO), 720.0 / 1080.0), "automática a 1080 px de alto: MEDIA al 67 % (%.3f)" % Calidad.escala_3d(Calidad.MEDIO))
	_comprobar(is_equal_approx(Calidad.escala_3d(Calidad.ULTRA_BAJA), 0.5), "ULTRA BAJA ya estaba más abajo (50 %): no sube")
	_comprobar(is_equal_approx(Calidad.escala_3d(Calidad.BAJA), minf(lerpf(0.5, 1.0, 0.4), 720.0 / 1080.0)) and Calidad.escala_3d(Calidad.BAJA) <= 720.0 / 1080.0 + 0.0001, "BAJA se queda en el tope")
	_comprobar(is_equal_approx(Calidad.escala_3d(Calidad.ALTO), 1.0) and is_equal_approx(Calidad.escala_3d(Calidad.ULTRA), 1.0), "ALTA y ULTRA no se tocan")
	OS.set_environment("RES3D_ALTO", "720")
	_comprobar(is_equal_approx(Calidad.escala_3d(Calidad.MEDIO), 1.0), "ventana de 720 px: sin cambio")
	_comprobar(is_equal_approx(CalidadRes3D.tope_escala(4320.0), Calidad.ESCALA_MIN_POSIBLE), "nunca baja del mínimo posible (35 %)")
	OS.set_environment("RES3D_ALTO", "1080")
	var vp2 := SubViewport.new()
	add_child(vp2)
	Calidad.aplicar_viewport(vp2, Calidad.MEDIO)
	_comprobar(is_equal_approx(vp2.scaling_3d_scale, 720.0 / 1080.0), "el viewport recibe el tope (%.3f)" % vp2.scaling_3d_scale)
	var sub := SubViewport.new()
	add_child(sub)
	CalidadRes3D.limitar(sub)
	_comprobar(is_equal_approx(sub.scaling_3d_scale, 720.0 / 1080.0), "las vistas 3D secundarias a pantalla completa (casa, sorteo, prólogo) reciben el mismo tope")
	Calidad.res3d_auto = false
	var sub2 := SubViewport.new()
	add_child(sub2)
	CalidadRes3D.limitar(sub2)
	_comprobar(is_equal_approx(sub2.scaling_3d_scale, 1.0), "con la automática apagada no tocan nada")
	Calidad.res3d_auto = true
	OS.set_environment("RES3D_ALTO", alto_antes)
	Calidad.res3d_auto = auto_antes
	Calidad.escala_media = guardada
	Calidad.escala_minimo = guardada_min

	## (10-11) MODO RENDIMIENTO (E1+E2): apagado por defecto; encendido quita glow y sombra del sol de MEDIA hacia abajo y deja ALTA/ULTRA como estaban.
	var modo_antes := Calidad.modo_rendimiento
	Calidad.modo_rendimiento = false
	_comprobar(Calidad.sombra_solar(Calidad.MEDIO) and ModoRendimiento.glow(Calidad.MEDIO) and Calidad.sombra_solar(Calidad.MEDIA_BAJA), "modo rendimiento apagado: MEDIA con sombra del sol y glow como siempre")
	_comprobar(not Calidad.sombra_solar(Calidad.BAJA) and not ModoRendimiento.glow(Calidad.MINIMO) and ModoRendimiento.glow(Calidad.BAJA), "apagado: BAJA sin sol pero con glow; ULTRA BAJA sin glow (como antes)")
	Calidad.modo_rendimiento = true
	_comprobar(not Calidad.sombra_solar(Calidad.MEDIO) and not ModoRendimiento.glow(Calidad.MEDIO) and not ModoRendimiento.glow(Calidad.BAJA) and not Calidad.sombra_solar(Calidad.MEDIA_BAJA), "modo rendimiento: MEDIA y menores sin sombra del sol ni glow")
	_comprobar(Calidad.sombra_solar(Calidad.ALTO) and ModoRendimiento.glow(Calidad.ALTO) and Calidad.sombra_solar(Calidad.ULTRA) and ModoRendimiento.glow(Calidad.ULTRA), "modo rendimiento: ALTA y ULTRA no se tocan")
	Calidad.modo_rendimiento = modo_antes

	## (10-11) Ahorro del menú también en MEDIA (pregunta 7 del dueño): apagado por defecto; ALTA y superiores nunca.
	_comprobar(not Calidad.ahorro_menu_media, "el ahorro del menú en MEDIA viene apagado")
	_comprobar(AhorroMenu.nivel_ahorra(Calidad.BAJA, false) and AhorroMenu.nivel_ahorra(Calidad.MEDIA_BAJA, false) and AhorroMenu.nivel_ahorra(Calidad.MINIMO, false), "BAJA, MEDIA BAJA y ULTRA BAJA ahorran siempre")
	_comprobar(not AhorroMenu.nivel_ahorra(Calidad.MEDIO, false) and AhorroMenu.nivel_ahorra(Calidad.MEDIO, true), "MEDIA solo ahorra si se pide")
	_comprobar(not AhorroMenu.nivel_ahorra(Calidad.ALTO, true) and not AhorroMenu.nivel_ahorra(Calidad.ULTRA, true), "ALTA y ULTRA nunca ahorran")
