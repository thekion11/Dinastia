extends BaseIdea
## M-186: los comercios con rótulo abren SU sala (farmacia, banco, hotel, ferretería, floristería) y no una tienda u oficina genérica.

func _probar() -> void:
	_titulo("P6: SALAS PROPIAS DE LOS COMERCIOS")
	var pares := {"Farmacia": "edificio_farmacia", "Banco": "edificio_banco", "Hotel": "edificio_hotel", "Ferretería": "edificio_ferreteria", "Floristería": "edificio_floristeria", "Correos": "edificio_correos", "Deportes": "edificio_deportes", "Pizzería": "edificio_pizzeria", "Heladería": "edificio_heladeria", "Peña del club": "edificio_pena"}
	for rotulo: String in pares:
		_comprobar(String(ExploradorCiudad.SALA_DE_ROTULO.get(rotulo, "")) == pares[rotulo], "«%s» abre %s" % [rotulo, pares[rotulo]])
		_comprobar(InteriorInstalacion.tiene(String(pares[rotulo])), "%s tiene sala" % pares[rotulo])
	var padre := Control.new()
	add_child(padre)
	for rotulo: String in pares:
		var sala := InteriorInstalacion.abrir(padre, "%s|%s" % [pares[rotulo], rotulo], null)
		_comprobar(sala != null and sala.find_children("*", "MeshInstance3D", true, false).size() > 20, "%s: sala amueblada (%d mallas)" % [rotulo, sala.find_children("*", "MeshInstance3D", true, false).size() if sala != null else 0])
		if sala != null:
			sala.queue_free()
