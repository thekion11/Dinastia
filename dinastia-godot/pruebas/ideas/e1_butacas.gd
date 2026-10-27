extends BaseIdea
## BUTACAS Y AFICIONADOS (27-10-2026): color por nivel, tope de ocupación, vomitorios con cuerpo y la opción en el diseñador y en el menú inicial.

func _probar() -> void:
	_titulo("E1 · BUTACAS: COLOR POR NIVEL, HUECOS ENTRE HINCHAS Y ACCESOS")
	var c1 := Color("#b01e2d")
	var c2 := Color("#ffffff")
	var n0 := StadiumBuilder.colores_de_nivel(c1, c2, 0)
	var n1 := StadiumBuilder.colores_de_nivel(c1, c2, 1)
	var n2 := StadiumBuilder.colores_de_nivel(c1, c2, 2)
	_comprobar(n0[0].is_equal_approx(c1) and n1[0].is_equal_approx(c2), "abajo el color 1 y en medio el 2")
	_comprobar(not n2[0].is_equal_approx(c1) and not n2[0].is_equal_approx(c2) and n2[0].r < c2.r and n2[0].r > c1.r * 0.6, "arriba una variante, mezcla de los dos")
	_comprobar(StadiumBuilder.colores_de_nivel(c1, c2, 3)[0].is_equal_approx(n2[0]), "del tercer nivel en adelante, la misma variante")
	_comprobar(StadiumBuilder.TOPE_OCUPACION < 0.9, "una grada llena deja siempre alguna butaca libre (tope %.2f)" % StadiumBuilder.TOPE_OCUPACION)
	## Opción en el diseñador.
	var e := EstadioPropio.new()
	var ops := e.opciones("asientoNivel")
	_comprobar(ops.size() == 2 and String(ops[0]["clave"]) == "por_nivel", "el diseñador ofrece «por nivel» y «uniforme»")
	_comprobar(e.es_valido("asientoNivel", "uniforme") and not e.es_valido("asientoNivel", "inventado"), "solo se aceptan las dos")
	_comprobar(String(e.ajustes.get("asientoNivel", "")) == "por_nivel", "de fábrica es por nivel")
	var club := Club.new()
	e.ajustes["asientoNivel"] = "uniforme"
	var perfil := e.perfil(club)
	_comprobar(String(perfil.get("asientoNivel", "")) == "uniforme", "el perfil lleva «uniforme» al visor")
	e.ajustes["asientoNivel"] = "por_nivel"
	_comprobar(not e.perfil(club).has("asientoNivel"), "con el valor de fábrica el perfil no cambia")
	## Menú inicial.
	var d := ConfigClubDatos.new()
	_comprobar(d.asiento_nivel == "por_nivel", "el menú inicial arranca en «por nivel»")
	d.asiento_nivel = "uniforme"
	var dic := d._dic()
	_comprobar(String((dic["club"] as Dictionary).get("asiento_nivel", "")) == "uniforme", "la elección va en la configuración guardada")
	var d2 := ConfigClubDatos.new()
	d2.desde_dic(dic)
	_comprobar(d2.asiento_nivel == "uniforme", "y se recupera al leerla")
