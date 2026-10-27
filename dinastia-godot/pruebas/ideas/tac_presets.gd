extends BaseIdea
## PRESETS DE FORMACIÓN Y TÁCTICA CON NOMBRE (27-10-2026, fila 382): guardar, cargar, sobrescribir, borrar, límites y guardado de partida.

func _probar() -> void:
	_titulo("TÁCTICA · PRESETS CON NOMBRE")
	var m := Mundo.new()
	m.generar(["CHI"], 91)
	m.tomar_el_mando(m.ligas[0].clubes[0].id)
	var c := m.mi_club()
	var pr: PresetsTactica = m.roles.presets_tactica
	_comprobar(pr.nombres().is_empty(), "al empezar no hay presets")
	_comprobar(pr.guardar("   ", c.tactica) != "", "sin nombre no se guarda")
	## Una pizarra «ofensiva».
	c.tactica.formacion = "4-3-3"
	c.tactica.mentalidad = Tactica.Mentalidad.OFENSIVA
	c.tactica.presion = Tactica.Nivel.ALTO
	c.tactica.ritmo = Tactica.Nivel.ALTO
	c.tactica.salida_corta = true
	c.tactica.tiro_lejano = true
	c.tactica.corner = "corto"
	_comprobar(pr.guardar("  Ir a por el partido  ", c.tactica) == "" and pr.nombres() == ["Ir a por el partido"], "se guarda con el nombre limpio")
	## Otra «defensiva» con otra formación.
	var formas: Array = Datos.tabla("FORMS").keys()
	var otra := String(formas[0] if String(formas[0]) != "4-3-3" else formas[1])
	c.tactica.formacion = otra
	c.tactica.mentalidad = Tactica.Mentalidad.DEFENSIVA
	c.tactica.presion = Tactica.Nivel.BAJO
	c.tactica.ritmo = Tactica.Nivel.BAJO
	c.tactica.salida_corta = false
	c.tactica.tiro_lejano = false
	c.tactica.corner = "area"
	_comprobar(pr.guardar("Cerrar el partido", c.tactica) == "" and pr.nombres() == ["Cerrar el partido", "Ir a por el partido"], "dos presets, por orden alfabético")
	## Cargar el ofensivo.
	c.once_elegido = ["x"]
	_comprobar(pr.cargar("Ir a por el partido", c) == "", "se carga")
	_comprobar(c.tactica.formacion == "4-3-3" and c.tactica.mentalidad == Tactica.Mentalidad.OFENSIVA and c.tactica.presion == Tactica.Nivel.ALTO and c.tactica.salida_corta and c.tactica.tiro_lejano and c.tactica.corner == "corto", "y deja la pizarra como estaba al guardarlo")
	_comprobar(c.once_elegido.is_empty(), "al cambiar de formación se suelta el once elegido")
	c.once_elegido = ["x"]
	pr.cargar("Ir a por el partido", c)
	_comprobar(not c.once_elegido.is_empty(), "con la misma formación el once se queda")
	_comprobar(pr.cargar("No existe", c) != "", "uno que no existe da su motivo")
	## Sobrescribir.
	c.tactica.ritmo = Tactica.Nivel.BAJO
	pr.guardar("Ir a por el partido", c.tactica)
	c.tactica.ritmo = Tactica.Nivel.ALTO
	pr.cargar("Ir a por el partido", c)
	_comprobar(pr.nombres().size() == 2 and c.tactica.ritmo == Tactica.Nivel.BAJO, "guardar con el mismo nombre lo sobrescribe")
	## Guardado de partida.
	var m2 := Partida.desde_instantanea(Partida.instantanea(m))
	var pr2: PresetsTactica = m2.roles.presets_tactica
	_comprobar(pr2.nombres() == pr.nombres() and int(pr2.datos["Cerrar el partido"]["mentalidad"]) == Tactica.Mentalidad.DEFENSIVA, "los presets se guardan con la partida")
	## Borrar y límite.
	_comprobar(pr.borrar("Cerrar el partido") and pr.nombres() == ["Ir a por el partido"], "se borra")
	for k in PresetsTactica.MAX:
		pr.guardar("p%d" % k, c.tactica)
	_comprobar(pr.nombres().size() == PresetsTactica.MAX and pr.guardar("uno más", c.tactica) != "", "con %d presets no caben más hasta borrar" % PresetsTactica.MAX)
	_comprobar(pr.guardar("p3", c.tactica) == "", "pero sobrescribir uno existente sí")
	_comprobar(PresetsTactica.limpiar_nombre("x".repeat(60)).length() == PresetsTactica.LARGO_NOMBRE, "los nombres se recortan a %d" % PresetsTactica.LARGO_NOMBRE)
