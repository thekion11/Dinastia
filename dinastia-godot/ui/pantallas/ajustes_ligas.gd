class_name AjustesLigas
extends RefCounted
## AÑADIR LIGAS DESDE AJUSTES (10-11-2026; núcleo y pantalla de la sesión 6, `LigasActivas` y `LigasActivasPantalla`). Hasta ahora solo se ofrecía al
## cerrar la temporada. En Ajustes → Partida, «Añadir ligas» abre la misma pantalla en modo añadir. Solo con la temporada SIN EMPEZAR (ninguna jornada
## jugada en ninguna liga): `LigasActivas.agregar` vuelve a sortear copas y torneos continentales, y a mitad de temporada se perderían los que están
## en marcha. (12-11, como Football Manager) Si ya empezó, el mismo botón PROGRAMA los países elegidos para la temporada siguiente
## (`LigasActivas.programar`, guardados con la partida) y entran solos al cerrarla (`AccionesTemporada._nueva_temporada`).

## ¿Se pueden añadir ligas ahora? (sin jornadas jugadas)
static func sin_empezar(m: Mundo) -> bool:
	for l: Liga in m.ligas:
		if l.jornada_actual > 0:
			return false
	return true

static func pintar(p: Principal) -> void:
	if p.mundo == null:
		return
	var faltan := LigasActivas.faltan(p.mundo)
	var t := p._texto(11, Principal.COL_SUAVE)
	t.text = Idiomas.t("LIGAS DE LA PARTIDA")
	p._lista_ajustes.add_child(t)
	var fila := HBoxContainer.new()
	fila.add_theme_constant_override("separation", 8)
	p._lista_ajustes.add_child(fila)
	var et := p._texto(13, Principal.COL_TEXTO)
	et.text = Idiomas.t("%d países cargados · %d por añadir") % [LigasActivas.de(p.mundo).size(), faltan.size()]
	et.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	fila.add_child(et)
	var b := Button.new()
	b.name = "AnadirLigas"
	b.text = "➕ " + Idiomas.t("Añadir ligas")
	if not sin_empezar(p.mundo):
		b.text = "➕ " + Idiomas.t("Añadir la próxima temporada")
	b.disabled = faltan.is_empty()
	b.pressed.connect(func() -> void: abrir(p))
	fila.add_child(b)
	var prog := LigasActivas.pendientes(p.mundo)
	if not faltan.is_empty() and not sin_empezar(p.mundo):
		var nota := p._texto(11, Principal.COL_SUAVE)
		nota.text = Idiomas.t("Con la temporada en marcha, las ligas elegidas entran al cerrarla (las copas y los torneos continentales en curso no se tocan).")
		if not prog.is_empty():
			nota.text += "  " + Idiomas.t("Programadas: %s") % ", ".join(prog)
		nota.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		p._lista_ajustes.add_child(nota)

## La misma pantalla que al cerrar la temporada (`AccionesTemporada._ofrecer_ligas`).
static func abrir(p: Principal) -> void:
	if sin_empezar(p.mundo):
		await p._acciones_temporada._ofrecer_ligas()
		return
	await programar_desde_pantalla(p)

## Con la temporada en marcha: la misma pantalla, con lo ya programado marcado; lo elegido queda para la próxima temporada.
static func programar_desde_pantalla(p: Principal) -> void:
	var pa := LigasActivasPantalla.new()
	pa.mundo_agregar = p.mundo
	p.add_child(pa)
	for cod: String in LigasActivas.pendientes(p.mundo):
		pa.marcar(cod, true)
	var d: Dictionary = await pa.terminado
	pa.queue_free()
	if bool(d.get("cancelado", false)):   ## «Ahora no»: lo programado se queda como estaba
		return
	LigasActivas.programar(p.mundo, (d.get("ligas", {}) as Dictionary).get("paises", []))
	var prog := LigasActivas.pendientes(p.mundo)
	if not prog.is_empty():
		p._escribir("[color=#4caf6d]%s[/color]" % (Idiomas.t("Programadas: %s") % ", ".join(prog)))
	p._refrescar()
