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
