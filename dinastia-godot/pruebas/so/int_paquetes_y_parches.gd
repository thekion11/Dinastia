extends BaseSO
## INTEGRACIÓN · paquetes: se construye un .pck de verdad (como `empaquetar_caras.gd` y el actualizador), se monta y se lee desde res://;
## un parche montado con reemplazo cambia un archivo y el original sigue en el repo; un .pck montado DOS veces no rompe nada. Funciona en
## cualquier sistema (en Web el .pck vive en la memoria virtual de user://). En editor `PaqueteReal.montar()` no hace nada: se comprueba esa regla.
func _nombre() -> String:
	return "int_paquetes_y_parches"

func _pck(ruta: String, archivos: Dictionary) -> bool:
	var p := PCKPacker.new()
	if p.pck_start(ruta) != OK:
		return false
	var carpeta := ruta.get_base_dir()
	for dentro: String in archivos:
		var tmp := carpeta.path_join("tmp_" + dentro.get_file())
		var f := FileAccess.open(tmp, FileAccess.WRITE)
		f.store_string(archivos[dentro])
		f.close()
		if p.add_file(dentro, ProjectSettings.globalize_path(tmp)) != OK:
			return false
	return p.flush() == OK

func _probar() -> void:
	_titulo("INTEGRACIÓN · paquetes y parches [%s]" % sistema())
	var carpeta := _carpeta_user()
	var ruta := carpeta.path_join(Actualizador.nombre_archivo("9.9.9"))   ## el nombre que baja el actualizador, el que busca Parches
	var ok := _pck(ruta, {"res://pruebas_so_paquete/hola.txt": "hola desde el paquete", "res://datos/novedades_prueba_so.txt": "novedad"})
	_comprobar(ok and FileAccess.file_exists(ruta), "se construye un .pck (%d bytes)" % FileAccess.get_file_as_bytes(ruta).size())
	_comprobar(not FileAccess.file_exists("res://pruebas_so_paquete/hola.txt"), "antes de montar, el archivo no existe")
	_comprobar(ProjectSettings.load_resource_pack(ruta, false), "el paquete se monta")
	_comprobar(FileAccess.get_file_as_string("res://pruebas_so_paquete/hola.txt") == "hola desde el paquete", "se lee su contenido desde res://")
	_comprobar(FileAccess.file_exists("res://datos/novedades_prueba_so.txt"), "también un archivo dentro de una carpeta que ya existe")
	_comprobar(ProjectSettings.load_resource_pack(ruta, true), "montarlo otra vez (con reemplazo) no falla")
	## Un parche con reemplazo pisa un archivo existente, sin tocar el original del disco.
	var original := FileAccess.get_file_as_string("res://datos/creditos_fotos.txt")
	var ruta2 := carpeta.path_join("parche_9.9.10.pck")
	_comprobar(_pck(ruta2, {"res://datos/creditos_fotos.txt": "REEMPLAZADO POR EL PARCHE"}), "se construye un parche que reemplaza creditos_fotos.txt")
	_comprobar(ProjectSettings.load_resource_pack(ruta2, true), "el parche se monta con reemplazo")
	_comprobar(FileAccess.get_file_as_string("res://datos/creditos_fotos.txt") == "REEMPLAZADO POR EL PARCHE", "el archivo ahora sale del parche")
	_comprobar(original != "" and original != "REEMPLAZADO POR EL PARCHE", "y el original era distinto (%d bytes)" % original.length())
	## Lo que escribió el actualizador es lo que Parches encuentra al arrancar.
	OS.set_environment("DINASTIA_PARCHES_PRUEBA", ProjectSettings.globalize_path(carpeta))
	var halladas := Parches.buscar()
	OS.set_environment("DINASTIA_PARCHES_PRUEBA", "")
	_comprobar(halladas.size() == 2 and String(halladas[0]).get_file() == Actualizador.nombre_archivo("9.9.9"), "Parches.buscar() encuentra los parches con el nombre del actualizador (%s)" % str(halladas.size()))
	## PaqueteReal: en el editor no monta nada; fuera de él busca junto al ejecutable y en user://.
	PaqueteReal.montar()
	if OS.has_feature("editor"):
		_comprobar(PaqueteReal.montado == "", "en el editor PaqueteReal.montar() no monta nada")
	else:
		_comprobar(PaqueteReal.montado == "" or FileAccess.file_exists(PaqueteReal.montado), "fuera del editor, lo montado existe: «%s»" % PaqueteReal.montado)
	_borrar_carpeta("user://pruebas_so/" + _nombre())
