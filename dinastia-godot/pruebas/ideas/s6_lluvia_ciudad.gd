extends BaseIdea
## S6 · LLUVIA EN LA CIUDAD (27-10-2026): emisores que siguen la cámara, con tope de partículas por calidad, y suelo mojado.

func _probar() -> void:
	_titulo("S6 · LLUVIA EN LA CIUDAD CON TOPE DE PARTÍCULAS Y SUELO MOJADO")
	_comprobar(PrecipitacionCiudad.montar(self, "despejado") == null and PrecipitacionCiudad.montar(self, "nieve") == null, "solo llueve con lluvia o tormenta")
	var previas := -1
	for nivel in [Calidad.MEDIO, Calidad.ALTO, Calidad.ULTRA]:
		var cont := PrecipitacionCiudad.montar(self, "lluvia", nivel)
		var n := PrecipitacionCiudad.particulas(cont)
		_comprobar(n <= PrecipitacionCiudad.tope(nivel) and n > 0, "calidad %d: %d partículas (tope %d)" % [nivel, n, PrecipitacionCiudad.tope(nivel)])
		_comprobar(n >= previas, "más calidad, no menos lluvia")
		previas = n
		cont.queue_free()
	var t := PrecipitacionCiudad.montar(self, "tormenta", Calidad.ALTO)
	_comprobar(t.get_node_or_null("Relampagos") != null and PrecipitacionCiudad.particulas(t) <= PrecipitacionCiudad.TOPE_ALTO, "la tormenta lleva relámpagos y respeta el tope")
	var alto := PrecipitacionCiudad.particulas(PrecipitacionCiudad.montar(self, "lluvia", Calidad.ALTO))
	_comprobar(alto <= 4200 and alto < 15000, "bastante menos que la lluvia del partido (15 000): %d" % alto)
	## Suelo mojado.
	var m := CityBuilder.asfalto_mate(Texturas.asfalto(Color(0.4, 0.4, 0.415)).duplicate(), 0.8)
	var antes := m.albedo_color
	CityBuilder.mojar(true)
	_comprobar(m.roughness < 0.4 and m.albedo_color.r < antes.r and m.metallic_specular > 0.5, "con lluvia el asfalto es más liso y más oscuro")
	CityBuilder.mojar(false)
	_comprobar(is_equal_approx(m.roughness, 0.8) and m.albedo_color.is_equal_approx(antes), "al escampar vuelve a como estaba")
