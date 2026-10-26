extends BaseIdea
## Exportar/importar una partida a un archivo (plan §10): ida y vuelta idéntica,
## rechazo de archivos alterados o de versión más nueva, y nombre repetido sin pisar.

const N := "exim_prueba"
const N2 := "exim_prueba_imp"

func _probar() -> void:
	_titulo("EXPORTAR E IMPORTAR PARTIDA (plan §10)")
	var m := _mundo(4242)
	var tmp := OS.get_user_data_dir().path_join("exim_tmp")
	DirAccess.make_dir_recursive_absolute(tmp)
	for n: String in [N, N2, N2 + " (2)"]:
		Partida.borrar(n)
	_comprobar(Partida.guardar(m, N), "se guarda la partida de prueba")
	var ruta := tmp.path_join("copia")
	_comprobar(PartidaExportar.exportar(N, ruta) == "", "exportar va bien")
	ruta += ".dinastia"
	_comprobar(FileAccess.file_exists(ruta), "se añade la extensión .dinastia")
	_comprobar(PartidaExportar.exportar("no_existe_xyz", ruta + "2") != "", "exportar una partida inexistente da error")

	## Ida y vuelta: la partida importada es la misma.
	var r := PartidaExportar.importar(ruta, N2)
	_comprobar(r.get("ok", false), "importar va bien")
	var a := Partida.instantanea(Partida.cargar(N))
	var b := Partida.instantanea(Partida.cargar(N2))
	a.erase("guardado"); b.erase("guardado")
	_comprobar(JSON.stringify(a) == JSON.stringify(b), "exportar→importar da la misma partida")
	var en_lista := false
	for f: Dictionary in Partida.listar():
		en_lista = en_lista or String(f.get("fichero", "")) == N2
	_comprobar(en_lista, "la importada aparece en la lista de partidas")

	## Nombre repetido: no pisa y sugiere otro.
	var antes := FileAccess.get_file_as_bytes(Partida.ruta_de(N))
	var c := PartidaExportar.importar(ruta, N)
	_comprobar(c.get("choca", false) and not c.has("ok"), "un nombre repetido se rechaza (choca)")
	_comprobar(FileAccess.get_file_as_bytes(Partida.ruta_de(N)) == antes, "la partida existente no se pisa")
	_comprobar(String(c.get("sugerido", "")) == N + " (2)", "se sugiere un nombre libre")
	_comprobar(String(PartidaExportar.importar(ruta, N2).get("sugerido", "")) == N2 + " (2)", "el sugerido es «nombre (2)»")

	## Archivo alterado: un byte cambiado en los datos.
	var bytes := FileAccess.get_file_as_bytes(ruta)
	bytes[bytes.size() / 2] = bytes[bytes.size() / 2] ^ 0x5A
	var mal := tmp.path_join("alterada.dinastia")
	_escribir(mal, bytes)
	var e1 := PartidaExportar.importar(mal, "exim_mala")
	_comprobar(e1.has("error") and not PartidaExportar.existe("exim_mala"), "un archivo alterado se rechaza")
	_linea("    mensaje: " + String(e1.get("error", "")))
	## Archivo que no es de Dinastía.
	var basura := tmp.path_join("basura.din2")
	_escribir(basura, "hola, no soy una partida de nada".to_utf8_buffer())
	_comprobar(PartidaExportar.importar(basura, "exim_mala").has("error"), "un archivo cualquiera se rechaza")

	## Versión más nueva: se empaqueta bien (huella correcta) pero con versión futura.
	var d := Partida.instantanea(m)
	d["version"] = Partida.VERSION + 1
	var nueva := tmp.path_join("futura.dinastia")
	_escribir(nueva, PartidaArchivo.empaquetar(JSON.stringify(d).to_utf8_buffer()))
	var e2 := PartidaExportar.importar(nueva, "exim_mala")
	_comprobar(e2.has("error") and String(e2["error"]).contains(str(Partida.VERSION + 1)), "una versión más nueva se rechaza con mensaje claro")
	_linea("    mensaje: " + String(e2.get("error", "")))
	## Versión vieja (1): se migra y entra.
	d["version"] = 1
	var vieja := tmp.path_join("vieja.dinastia")
	_escribir(vieja, PartidaArchivo.empaquetar(JSON.stringify(d).to_utf8_buffer()))
	var r3 := PartidaExportar.importar(vieja, N2 + " (2)")
	_comprobar(r3.get("ok", false), "una versión vieja se migra e importa")

	## La interfaz: los tres botones se construyen y, con partidas, están activos.
	var ui := PartidaArchivoUI.new()
	add_child(ui)
	var fila := ui.construir_botones()
	_comprobar(fila.get_child_count() == 3 and not (fila.get_child(1) as Button).disabled, "la fila de botones sale con exportar activo")
	fila.free()
	ui.free()

	for n: String in [N, N2, N2 + " (2)", "exim_mala"]:
		Partida.borrar(n)
	for f: String in DirAccess.get_files_at(tmp):
		DirAccess.remove_absolute(tmp.path_join(f))
	DirAccess.remove_absolute(tmp)

func _escribir(ruta: String, b: PackedByteArray) -> void:
	var f := FileAccess.open(ruta, FileAccess.WRITE)
	f.store_buffer(b)
	f.close()
