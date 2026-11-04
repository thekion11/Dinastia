class_name AjustesActualizar
extends RefCounted
## «BUSCAR ACTUALIZACIÓN» EN AJUSTES → Partida y guardado (4-11-2026): la cara del `Actualizador`. La versión instalada, un botón para buscar, el resultado, y si hay una versión nueva
## el botón «Descargar» con su barra de progreso; al acabar pregunta si reiniciar ahora o más tarde. Nada se baja ni se instala sin que la persona lo pida.

## Las filas, dentro de `p._lista_ajustes`. Devuelve el `Actualizador` (las pruebas lo usan para no depender de la red).
static func pintar(p: Principal) -> Actualizador:
	var t := p._texto(11, Principal.COL_SUAVE)
	t.text = Idiomas.t("ACTUALIZACIONES")
	p._lista_ajustes.add_child(t)
	var v := p._texto(12, Principal.COL_TEXTO)
	v.text = Idiomas.t("Versión instalada: %s · %s") % [Actualizador.version_actual(), Idiomas.t("escritorio") if Actualizador.sistema() == "escritorio" else "Android"]
	p._lista_ajustes.add_child(v)
	var nota := p._texto(11, Principal.COL_SUAVE)
	nota.text = Idiomas.t("Solo se conecta a internet cuando pulsas «Buscar actualización», y no se baja ni se instala nada sin que lo aceptes.")
	nota.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	p._lista_ajustes.add_child(nota)
	var act := Actualizador.new()
	act.name = "Actualizador"
	p._lista_ajustes.add_child(act)
	var fila := HBoxContainer.new()
	fila.add_theme_constant_override("separation", 8)
	p._lista_ajustes.add_child(fila)
	var buscar := Button.new()
	buscar.name = "Buscar"
	buscar.text = Idiomas.t("🔄 Buscar actualización")
	fila.add_child(buscar)
	var bajar := Button.new()
	bajar.name = "Descargar"
	bajar.visible = false
	fila.add_child(bajar)
	var estado := p._texto(12, Principal.COL_SUAVE)
	estado.name = "Estado"
	estado.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	p._lista_ajustes.add_child(estado)
	var barra := ProgressBar.new()
	barra.name = "Barra"
	barra.visible = false
	barra.custom_minimum_size = Vector2(0, 18)
	p._lista_ajustes.add_child(barra)
	var notas := p._texto(11, Principal.COL_SUAVE)
	notas.name = "Notas"
	notas.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	notas.visible = false
	p._lista_ajustes.add_child(notas)
	buscar.pressed.connect(func() -> void:
		if act.ocupado():
			return
		bajar.visible = false
		notas.visible = false
		barra.visible = false
		estado.text = Idiomas.t("Buscando…")
		buscar.disabled = true
		act.consultar())
	act.consultado.connect(func(hay: bool, info: Dictionary, mensaje: String) -> void:
		buscar.disabled = false
		if not hay:
			estado.text = Idiomas.t("Ya tienes la última versión (%s).") % Actualizador.version_actual()
			return
		estado.text = Idiomas.t("Hay una versión nueva: %s.") % String(info["version"])
		bajar.text = Idiomas.t("⬇ Descargar %s (%s)") % [String(info["version"]), _tamano(int(info["tam"]))]
		bajar.visible = true
		notas.text = String(info.get("notas", ""))
		notas.visible = notas.text.strip_edges() != ""
		bajar.set_meta("info", info))
	bajar.pressed.connect(func() -> void:
		if act.ocupado():
			return
		var info: Dictionary = bajar.get_meta("info", {})
		bajar.disabled = true
		buscar.disabled = true
		barra.value = 0.0
		barra.max_value = float(maxi(int(info.get("tam", 1)), 1))
		barra.visible = true
		estado.text = Idiomas.t("Descargando…")
		act.descargar(info))
	act.progreso.connect(func(recibido: int, total: int) -> void:
		barra.value = float(recibido)
		estado.text = Idiomas.t("Descargando… %s de %s") % [_tamano(recibido), _tamano(total)])
	act.descargado.connect(func(_ruta: String, info: Dictionary) -> void:
		buscar.disabled = false
		bajar.disabled = false
		bajar.visible = false
		barra.visible = false
		estado.text = Idiomas.t("Parche %s descargado. Se usará al reiniciar el juego.") % String(info["version"])
		_preguntar_reinicio(p, String(info["version"])))
	act.fallo.connect(func(mensaje: String) -> void:
		buscar.disabled = false
		bajar.disabled = false
		barra.visible = false
		estado.text = "⚠ " + Idiomas.t(mensaje))
	p._lista_ajustes.add_child(HSeparator.new())
	return act

static func _tamano(bytes: int) -> String:
	if bytes >= 1048576:
		return "%.1f MB" % (float(bytes) / 1048576.0)
	return "%d KB" % maxi(int(round(float(bytes) / 1024.0)), 1)

## «¿Reiniciar ahora?»: nunca se reinicia solo. En Android no se puede reiniciar desde dentro: se pide cerrar y volver a abrir.
static func _preguntar_reinicio(p: Principal, version: String) -> void:
	var d := ConfirmationDialog.new()
	d.title = Idiomas.t("Actualización lista")
	if OS.has_feature("android"):
		d.dialog_text = Idiomas.t("El parche %s está descargado. Cierra el juego del todo y vuelve a abrirlo para usarlo.") % version
		d.get_cancel_button().visible = false
		d.ok_button_text = Idiomas.t("Entendido")
	else:
		d.dialog_text = Idiomas.t("El parche %s está descargado. Hace falta reiniciar el juego para usarlo. ¿Reiniciar ahora?") % version
		d.ok_button_text = Idiomas.t("Reiniciar ahora")
		d.cancel_button_text = Idiomas.t("Más tarde")
		d.confirmed.connect(func() -> void:
			if p.mundo != null:
				Partida.guardar(p.mundo, p._partida._ranura())
			reiniciar(p.get_tree()))
	d.name = "DialogoReinicio"
	p.add_child(d)
	d.popup_centered(Vector2i(520, 170))

## Reinicia el juego con los mismos argumentos (la persona ya lo aceptó).
static func reiniciar(arbol: SceneTree) -> void:
	OS.set_restart_on_exit(true, OS.get_cmdline_args())
	arbol.quit()
