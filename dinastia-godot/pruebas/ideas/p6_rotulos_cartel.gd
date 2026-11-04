extends BaseIdea
## C2 (3-11, prueba del dueño): los nombres de los lugares no flotan a la vista desde lejos: a pie o en coche son carteles de tamaño de mundo, tapados por lo de delante y solo cercanos.

func _probar() -> void:
	_titulo("P6: ROTULOS DEL MAPA COMO CARTELES")
	var e := ExploradorCiudad.new()
	add_child(e)
	var l := Label3D.new()
	l.text = "Parque"
	l.fixed_size = true
	l.pixel_size = 0.0007
	l.no_depth_test = true
	l.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	l.add_to_group("rotulo_mapa")
	add_child(l)
	e.modo = "pie"
	e._rotulos_de_paseo(true)
	_comprobar(not l.fixed_size and l.pixel_size > 0.005 and not l.no_depth_test, "a pie es un cartel de tamaño de mundo y lo tapa lo que haya delante")
	_comprobar(l.visibility_range_end > 0.0 and l.visibility_range_end <= 50.0, "a pie solo se ve a menos de %d m" % int(l.visibility_range_end))
	e.modo = "coche"
	e._rotulos_de_paseo(true)
	_comprobar(l.visibility_range_end > 0.0 and l.visibility_range_end <= 100.0, "en coche solo se ve a menos de %d m" % int(l.visibility_range_end))
	e._rotulos_de_paseo(false)
	_comprobar(l.fixed_size and l.no_depth_test and l.visibility_range_end == 0.0, "en la vista aérea vuelve la etiqueta de tamaño fijo y sin límite")
