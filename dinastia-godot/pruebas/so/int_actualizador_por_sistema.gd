extends BaseSO
## INTEGRACIÓN · Actualizador ↔ Parches según el sistema: el actualizador elige el parche de SU sistema («android» en Android, «escritorio» en los
## demás), el nombre del archivo que descarga es el que `Parches` busca al arrancar, y un parche escrito en la carpeta de destino aparece en
## `Parches.buscar()` (con el orden por versión). La versión del juego es una versión válida.
func _nombre() -> String:
	return "int_actualizador_por_sistema"

func _probar() -> void:
	_titulo("INTEGRACIÓN · actualizador ↔ parches [%s]" % sistema())
	var esperado := String(por_so({"android": "android", "defecto": "escritorio"}))
	_comprobar(Actualizador.sistema() == esperado, "sistema del actualizador en %s = «%s»" % [sistema(), Actualizador.sistema()])
	var v := Actualizador.version_actual()
	_comprobar(Actualizador.partes(v).size() >= 3 and v != "0.0.0", "versión del juego válida: %s" % v)
	var siguiente := "%d.%d.%d" % [Actualizador.partes(v)[0], Actualizador.partes(v)[1], Actualizador.partes(v)[2] + 1]
	var lista: Array = []
	for sis in ["escritorio", "android"]:
		var nombre := Actualizador.nombre_archivo(siguiente)
		lista.append({"tag_name": "parche-%s-%s" % [siguiente, sis], "draft": false, "prerelease": false, "body": sis,
			"assets": [{"name": nombre, "size": 1000, "browser_download_url": "https://ejemplo.invalido/%s/%s" % [sis, nombre]}]})
	var el: Dictionary = Actualizador.elegir(lista, v, Actualizador.sistema())
	_comprobar(not el.is_empty() and String(el["notas"]) == Actualizador.sistema(), "entre los parches de los dos sistemas elige el de este (%s)" % str(el.get("tag", "ninguno")))
	_comprobar(Actualizador.elegir(lista, siguiente, Actualizador.sistema()).is_empty(), "si ya tiene esa versión no ofrece nada")
	var otro := "android" if Actualizador.sistema() == "escritorio" else "escritorio"
	_comprobar(String(Actualizador.elegir(lista, v, otro).get("notas", "")) == otro, "y con el otro sistema elige el otro")
	## Nombre ↔ Parches
	var arch := Actualizador.nombre_archivo(siguiente)
	_comprobar(arch.begins_with(Parches.PREFIJO) and arch.ends_with(".pck"), "«%s» empieza por el prefijo que busca Parches («%s») y acaba en .pck" % [arch, Parches.PREFIJO])
	_comprobar(Actualizador.ruta_destino(siguiente).begins_with("user://") and Actualizador.CARPETA == "user://parches", "los parches se bajan a user://parches (escribible en todos los sistemas)")
	var carpeta := _carpeta_user()
	var dest := carpeta.path_join("parches")
	DirAccess.make_dir_recursive_absolute(dest)
	for ver in ["%s" % siguiente, "0.0.9", "0.0.10"]:
		var f := FileAccess.open(dest.path_join(Actualizador.nombre_archivo(ver)), FileAccess.WRITE)
		f.store_string("x")
		f.close()
	OS.set_environment("DINASTIA_PARCHES_PRUEBA", ProjectSettings.globalize_path(dest))
	var halladas := Parches.buscar()
	OS.set_environment("DINASTIA_PARCHES_PRUEBA", "")
	_comprobar(halladas.size() == 3, "Parches.buscar() encuentra los 3 que baja el actualizador")
	_comprobar(halladas.size() == 3 and halladas[0].ends_with("parche_0.0.9.pck") and halladas[1].ends_with("parche_0.0.10.pck"), "y los ordena por versión: 0.0.9, 0.0.10, %s" % siguiente)
	_comprobar(Actualizador.comparar("0.0.9", "0.0.10") < 0, "comparar() ve 0.0.9 < 0.0.10 (no por texto)")
	_borrar_carpeta("user://pruebas_so/" + _nombre())
