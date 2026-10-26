class_name PartidaArchivoUI
extends Node
## LOS BOTONES DE EXPORTAR / IMPORTAR / ABRIR PARTIDA de la pantalla de inicio
## (26-10-2026, plan §10). La lógica está en `PartidaExportar`; aquí solo los
## diálogos: elegir partida, elegir archivo, pedir otro nombre si choca y avisar.
##
## Escritorio: `FileDialog` (el nativo del sistema si lo hay). Móvil sin diálogo
## nativo: exportar va directo a Documentos con el nombre de la partida, e
## importar abre el `FileDialog` de Godot en esa misma carpeta.

## Cambió la lista de partidas (se importó una): la pantalla se repinta.
signal lista_cambiada
## El jugador eligió abrir una partida de la lista.
signal abrir_pedido(nombre: String)

var _menu: PopupMenu
var _accion := ""
var _nombres: Array[String] = []
var _aviso: AcceptDialog
var _pedir: ConfirmationDialog
var _campo: LineEdit
var _ruta_pendiente := ""

## Fila de botones lista para colgar donde sea.
func construir_botones() -> HBoxContainer:
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 8)
	h.alignment = BoxContainer.ALIGNMENT_CENTER
	var hay := not Partida.listar().is_empty()
	_boton(h, Idiomas.t("📂 Partidas guardadas"), func() -> void: _elegir_partida("abrir"), not hay)
	_boton(h, Idiomas.t("⇪ Exportar partida"), func() -> void: _elegir_partida("exportar"), not hay)
	_boton(h, Idiomas.t("⇩ Importar partida"), _pedir_archivo_importar, false)
	return h

func _boton(h: HBoxContainer, texto: String, cb: Callable, apagado: bool) -> void:
	var b := Button.new()
	b.text = texto
	b.disabled = apagado
	b.add_theme_font_size_override("font_size", 12)
	b.pressed.connect(cb)
	h.add_child(b)

func _elegir_partida(accion: String) -> void:
	_accion = accion
	_nombres.clear()
	if _menu == null:
		_menu = PopupMenu.new()
		_menu.id_pressed.connect(_partida_elegida)
		add_child(_menu)
	_menu.clear()
	for f: Dictionary in Partida.listar():
		_nombres.append(String(f.get("fichero", "")))
		_menu.add_item(Idiomas.t("%s — %s · %d, semana %d") % [String(f.get("fichero", "")),
			String(f.get("club", "")), int(f.get("anio", 0)), int(f.get("semana", 0))], _nombres.size() - 1)
	if _nombres.is_empty():
		return
	_menu.popup_centered()

func _partida_elegida(id: int) -> void:
	var nombre := _nombres[id]
	if _accion == "abrir":
		abrir_pedido.emit(nombre)
		return
	if _hay_dialogo_de_archivos():
		var fd := _dialogo(FileDialog.FILE_MODE_SAVE_FILE)
		fd.current_file = nombre + String(PartidaExportar.EXTENSIONES[0])
		fd.file_selected.connect(func(r: String) -> void: _avisar_exportado(PartidaExportar.exportar(nombre, r), r))
		fd.popup_centered_ratio(0.7)
	else:
		var r := PartidaExportar.carpeta_por_defecto().path_join(nombre + String(PartidaExportar.EXTENSIONES[0]))
		_avisar_exportado(PartidaExportar.exportar(nombre, r), r)

func _avisar_exportado(error: String, ruta: String) -> void:
	if error.is_empty():
		_avisar(Idiomas.t("Partida exportada a:\n%s") % ruta)
	else:
		_avisar(error)

func _pedir_archivo_importar() -> void:
	var fd := _dialogo(FileDialog.FILE_MODE_OPEN_FILE)
	fd.file_selected.connect(func(r: String) -> void: _importar(r, ""))
	fd.popup_centered_ratio(0.7)

func _importar(ruta: String, nombre: String) -> void:
	var r := PartidaExportar.importar(ruta, nombre)
	if r.get("ok", false):
		_avisar(Idiomas.t("Partida importada como «%s».") % String(r["nombre"]))
		lista_cambiada.emit()
	elif r.get("choca", false):
		_pedir_nombre(ruta, String(r["sugerido"]))
	else:
		_avisar(String(r.get("error", "")))

## Ya hay una partida con ese nombre: se propone uno libre y se deja cambiarlo.
func _pedir_nombre(ruta: String, sugerido: String) -> void:
	_ruta_pendiente = ruta
	if _pedir == null:
		_pedir = ConfirmationDialog.new()
		_pedir.title = Idiomas.t("Ese nombre ya existe")
		var v := VBoxContainer.new()
		var l := Label.new()
		l.text = Idiomas.t("Ya tienes una partida con ese nombre. Elige otro para no pisarla:")
		v.add_child(l)
		_campo = LineEdit.new()
		v.add_child(_campo)
		_pedir.add_child(v)
		_pedir.confirmed.connect(func() -> void: _importar(_ruta_pendiente, _campo.text))
		add_child(_pedir)
	_campo.text = sugerido
	_pedir.popup_centered(Vector2i(420, 140))

func _avisar(texto: String) -> void:
	if _aviso == null:
		_aviso = AcceptDialog.new()
		_aviso.title = Idiomas.t("Partidas")
		add_child(_aviso)
	_aviso.dialog_text = texto
	_aviso.popup_centered()

## En móvil sin diálogo nativo no hay selector cómodo para GUARDAR: se exporta
## directo a Documentos. Para abrir sí se usa el `FileDialog` de Godot.
func _hay_dialogo_de_archivos() -> bool:
	var movil := OS.has_feature("android") or OS.has_feature("ios")
	return not movil or DisplayServer.has_feature(DisplayServer.FEATURE_NATIVE_DIALOG_FILE)

func _dialogo(modo: FileDialog.FileMode) -> FileDialog:
	var fd := FileDialog.new()
	fd.file_mode = modo
	fd.access = FileDialog.ACCESS_FILESYSTEM
	fd.use_native_dialog = DisplayServer.has_feature(DisplayServer.FEATURE_NATIVE_DIALOG_FILE)
	fd.current_dir = PartidaExportar.carpeta_por_defecto()
	var filtros := PackedStringArray()
	for e: String in PartidaExportar.EXTENSIONES:
		filtros.append("*%s" % e)
	fd.filters = PackedStringArray([", ".join(filtros) + " ; " + Idiomas.t("Partida de Dinastía")])
	## Un diálogo por uso: se libera al cerrarse para no acumular nodos.
	fd.visibility_changed.connect(func() -> void:
		if not fd.visible:
			fd.queue_free())
	add_child(fd)
	return fd
