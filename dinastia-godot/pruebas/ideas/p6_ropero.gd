extends BaseIdea
## M-188 (3-11, decisión del dueño: inventario): el ropero del DT se llena al comprar, las prendas son únicas, los balones se repiten y todo se guarda con la partida.

func _probar() -> void:
	_titulo("P6: ROPERO DEL DT (INVENTARIO QUE SE GUARDA)")
	var r := {}
	_comprobar(RoperoDT.puede(r, "camiseta_club") and RoperoDT.puede(r, "balon"), "al principio se puede comprar todo")
	RoperoDT.agregar(r, "camiseta_club")
	RoperoDT.agregar(r, "balon")
	RoperoDT.agregar(r, "balon")
	_comprobar(not RoperoDT.puede(r, "camiseta_club"), "la camiseta es única: no se repite")
	_comprobar(RoperoDT.puede(r, "balon") and int(r["balon"]) == 2, "los balones sí se repiten (×%d)" % int(r["balon"]))
	_comprobar(not RoperoDT.puede(r, "no_existe"), "un artículo que no existe no se puede comprar")
	var s := RoperoDT.surtido(r)
	var marcadas := 0
	for it: Dictionary in s:
		_comprobar(it.has("inv") and int(it["precio"]) > 0, "«%s» tiene clave de inventario y precio" % String(it["nombre"]))
		if String(it["nombre"]).ends_with("✔"):
			marcadas += 1
	_comprobar(marcadas == 1, "solo la camiseta sale marcada como ya comprada (%d)" % marcadas)
	_comprobar(RoperoDT.resumen(r).contains("×2"), "el resumen cuenta los repetidos: %s" % RoperoDT.resumen(r))
	## Se guarda con los roles.
	var m := Mundo.new()
	m.generar(["CHI"], 77)
	m.tomar_el_mando(m.ligas[0].clubes[0].id)
	RoperoDT.agregar(m.roles.ropero, "botines")
	var d: Dictionary = m.roles.a_dic()
	var m2 := Mundo.new()
	m2.generar(["CHI"], 77)
	m2.tomar_el_mando(m2.ligas[0].clubes[0].id)
	m2.roles.desde_dic(d)
	_comprobar(RoperoDT.tiene(m2.roles.ropero, "botines"), "tras guardar y cargar, los botines siguen en el ropero")
	## Cobro: el precio sale de la cartera.
	m.roles.cartera.efectivo = 100
	var antes: int = m.roles.cartera.efectivo
	var dia := CarteraDT.clave_dia(m.anio, m.semana, m.reloj.dia)
	var res: Dictionary = m.roles.cartera.cobrar(m.roles, 12, "Gorra del club", dia)
	_comprobar(String(res["error"]) == "" and m.roles.cartera.efectivo == antes - 12, "la compra se cobra de la cartera")

	## Partidas viejas: sin el campo «ropero» cargan con el ropero vacío.
	var d_viejo: Dictionary = m.roles.a_dic()
	d_viejo.erase("ropero")
	m2.roles.desde_dic(d_viejo)
	_comprobar(m2.roles.ropero.is_empty(), "una partida vieja (sin «ropero») carga con el ropero vacío")
	## Que se vea: la ropa del personaje y el rincón de la casa.
	var asp := RoperoDT.aplicar({"ropa": "traje", "corbata": true}, "camiseta_club", Color("1f5fa8"), Color("ffffff"))
	_comprobar(String(asp["ropa"]) == "polo" and String(asp["c_ropa"]) == "1f5fa8" and not bool(asp["corbata"]), "la camiseta del club viste al personaje con los colores del club")
	_comprobar(bool(RoperoDT.aplicar({}, "gorra_club", Color.RED, Color.WHITE)["gorra"]) and bool(RoperoDT.aplicar({}, "bufanda_club", Color.RED, Color.WHITE)["bufanda"]), "la gorra y la bufanda se ponen")
	_comprobar(RoperoDT.aplicar({}, "balon", Color.RED, Color.WHITE).is_empty() and RoperoDT.aplicar({}, "botines", Color.RED, Color.WHITE).is_empty(), "balones y botines no son prendas del aspecto (se ven en casa)")
	var casa := Node3D.new()
	add_child(casa)
	_comprobar(RoperoCasa.montar(casa, {}, null) == 0 and casa.get_child_count() == 0, "sin compras, la casa queda igual")
	var n := RoperoCasa.montar(casa, {"balon": 2, "balon_playa": 1, "botines": 1, "camiseta_club": 1, "bufanda_club": 1}, null)
	_comprobar(n == 6 and casa.get_child_count() > 10, "con compras, la casa muestra balones, botines, camiseta y bufanda (%d piezas)" % n)
