extends BaseSO
## ERRORES · faltan el paquete de caras reales (`caras_reales.pck`) o un parche, o vienen rotos. El juego público sigue entero: `PaqueteReal`
## no monta nada, `Datos` cae en la base ficticia aunque se pida la real, y montar un .pck inexistente o corrupto devuelve false sin colgar.
func _nombre() -> String:
	return "err_pck_y_pack_ausentes"

func _probar() -> void:
	_titulo("ERRORES · .pck y base real ausentes [%s]" % sistema())
	var carpeta := _carpeta_user()
	_comprobar(PaqueteReal.NOMBRE == "caras_reales.pck", "el paquete privado se llama caras_reales.pck")
	_comprobar(PaqueteReal.montado == "" or FileAccess.file_exists(PaqueteReal.montado), "sin .pck junto al ejecutable no hay nada montado (%s)" % PaqueteReal.montado)
	_comprobar(not ProjectSettings.load_resource_pack(carpeta.path_join("no_existe.pck"), false), "montar un .pck inexistente devuelve false")
	var roto := carpeta.path_join("roto.pck")
	var f := FileAccess.open(roto, FileAccess.WRITE)
	f.store_string("esto no es un paquete de Godot, ni de lejos" + "x".repeat(2000))
	f.close()
	_comprobar(not ProjectSettings.load_resource_pack(roto, false), "montar un .pck corrupto devuelve false")
	var vacio := carpeta.path_join("vacio.pck")
	FileAccess.open(vacio, FileAccess.WRITE).close()
	_comprobar(not ProjectSettings.load_resource_pack(vacio, false), "montar un .pck vacío devuelve false")
	## Un parche roto no entra en la lista de montados y la búsqueda ordena por nombre natural.
	DirAccess.make_dir_recursive_absolute(carpeta.path_join("parches"))
	for n in ["parche_0.10.0.pck", "parche_0.9.1.pck", "otro.txt"]:
		var g := FileAccess.open(carpeta.path_join("parches").path_join(n), FileAccess.WRITE)
		g.store_string("x")
		g.close()
	OS.set_environment("DINASTIA_PARCHES_PRUEBA", ProjectSettings.globalize_path(carpeta.path_join("parches")))
	var lista := Parches.buscar()
	OS.set_environment("DINASTIA_PARCHES_PRUEBA", "")
	_comprobar(lista.size() == 2, "buscar encuentra solo los parche_*.pck (%d)" % lista.size())
	_comprobar(lista.size() == 2 and lista[0].ends_with("parche_0.9.1.pck") and lista[1].ends_with("parche_0.10.0.pck"), "orden natural: 0.9.1 antes que 0.10.0 %s" % str(lista))
	for ruta in lista:
		_comprobar(not ProjectSettings.load_resource_pack(ruta, true), "el parche roto no se monta: %s" % ruta.get_file())
	## Sin pack real en el equipo, pedir la base real deja la ficticia.
	if not Datos.hay_pack_real():
		_comprobar(Datos.usar_base_real(true) == false, "sin pack real, usar_base_real(true) deja la base ficticia")
	else:
		_comprobar(Datos.nombre_pack() != "", "con pack real instalado tiene nombre (%s)" % Datos.nombre_pack())
		Datos.usar_base_real(false)
		_comprobar(Datos.base_real == false, "y se puede volver a la ficticia")
	_borrar_carpeta("user://pruebas_so/" + _nombre())
