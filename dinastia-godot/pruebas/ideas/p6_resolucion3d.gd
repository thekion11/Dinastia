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
