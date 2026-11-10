class_name AjusteResolucion3D
extends RefCounted
## La resolución del 3D que elige el jugador (pedido del dueño 3-11): en Mínima del 35 al 100 % (bilineal) y, desde el 4-11, también en Media del 50 al 100 %
## (FSR en Forward+/Mobile, bilineal en Compatibilidad). En Alta y Ultra siempre es 100 % y no se muestra el control.
static func crear(p: Object) -> void:
	var nivel := Calidad.elegida
	if nivel <= Calidad.MEDIO:   ## (10-11, P1) el interruptor de la resolución automática (máx. 720 px de alto) vale de ULTRA BAJA a MEDIA; en el móvil viene encendido
		var ca := CheckButton.new()
		ca.text = Idiomas.t("Resolución 3D automática (máx. 720 px de alto)")
		ca.button_pressed = Calidad.res3d_auto
		ca.toggled.connect(func(on: bool) -> void:
			Calidad.res3d_auto = on
			Calidad.guardar()
			Calidad.aplicar_viewport(p.get_viewport(), Calidad.elegida))
		p._lista_ajustes.add_child(ca)
	if nivel > Calidad.MEDIO or nivel == Calidad.BAJA or nivel == Calidad.MEDIA_BAJA:   ## BAJA y MEDIA BAJA derivan de las dos escalas que se eligen en ULTRA BAJA y MEDIA
		return
	var minimo := nivel <= Calidad.MINIMO
	var plantilla := "Resolución del 3D en Mínima: %d %%" if minimo else "Resolución del 3D en Media: %d %%"
	var er := Label.new()
	er.text = Idiomas.t(plantilla) % int(round(Calidad.escala_3d(nivel) * 100.0))
	p._lista_ajustes.add_child(er)
	var sr := HSlider.new()
	sr.min_value = (Calidad.ESCALA_MIN_POSIBLE if minimo else Calidad.ESCALA_MEDIA_MIN) * 100.0
	sr.max_value = 100.0
	sr.step = 5.0
	sr.value = Calidad.escala_3d(nivel) * 100.0
	sr.value_changed.connect(func(v: float) -> void:
		if minimo:
			Calidad.escala_minimo = clampf(v / 100.0, Calidad.ESCALA_MIN_POSIBLE, 1.0)
		else:
			Calidad.escala_media = clampf(v / 100.0, Calidad.ESCALA_MEDIA_MIN, 1.0)
		Calidad.guardar()
		er.text = Idiomas.t(plantilla) % int(v)
		Calidad.aplicar_viewport(p.get_viewport(), Calidad.elegida))
	p._lista_ajustes.add_child(sr)
