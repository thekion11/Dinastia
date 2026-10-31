extends BaseIdea
## M-300 (28-10-2026): «↶ Deshacer» en la pizarra táctica.
##   herramientas/ideas.sh tac_deshacer

func _probar() -> void:
	_titulo("M-300: DESHACER EN LA PIZARRA")
	var c := Club.new()
	c.id = "prueba_m300"
	var t0 := c.tactica
	_comprobar(not DeshacerTactica.hay(c), "al empezar no hay nada que deshacer")
	DeshacerTactica.apuntar(c)
	c.tactica.formacion = "3-5-2"
	c.tactica.mentalidad = 2
	c.tactica.roles["DC"] = "ariete"
	DeshacerTactica.apuntar(c)
	c.once_elegido.assign(["a", "b"])
	DeshacerTactica.apuntar(c)
	c.tactica.tiro_lejano = not c.tactica.tiro_lejano
	_comprobar(DeshacerTactica.pasos(c) == 3, "tres cambios, tres pasos")
	var tiro := c.tactica.tiro_lejano
	DeshacerTactica.deshacer(c)
	_comprobar(c.tactica.tiro_lejano != tiro and c.once_elegido.size() == 2, "deshace el interruptor y deja el once")
	DeshacerTactica.deshacer(c)
	_comprobar(c.once_elegido.is_empty() and c.tactica.formacion == "3-5-2", "deshace el once")
	DeshacerTactica.deshacer(c)
	_comprobar(c.tactica.formacion != "3-5-2" and c.tactica.mentalidad != 2 and not c.tactica.roles.has("DC"), "deshace dibujo, mentalidad y roles (%s)" % c.tactica.formacion)
	_comprobar(c.tactica == t0, "sobre la misma Tactica (no la cambia por otra)")
	_comprobar(not DeshacerTactica.deshacer(c), "sin pasos, no hace nada")
	for i in 30:
		DeshacerTactica.apuntar(c)
	_comprobar(DeshacerTactica.pasos(c) == DeshacerTactica.MAX, "la pila se queda en %d" % DeshacerTactica.MAX)
	DeshacerTactica.olvidar()
