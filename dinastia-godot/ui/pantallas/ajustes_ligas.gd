class_name AjustesLigas
extends RefCounted
## AÑADIR LIGAS DESDE AJUSTES (10-11-2026; núcleo y pantalla de la sesión 6, `LigasActivas` y `LigasActivasPantalla`). Hasta ahora solo se ofrecía al
## cerrar la temporada. En Ajustes → Partida, «Añadir ligas» abre la misma pantalla en modo añadir. Solo con la temporada SIN EMPEZAR (ninguna jornada
## jugada en ninguna liga): `LigasActivas.agregar` vuelve a sortear copas y torneos continentales, y a mitad de temporada se perderían los que están
## en marcha. Si ya empezó, el botón se ve desactivado y dice cuándo se puede.

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
	var se_puede := sin_empezar(p.mundo) and not faltan.is_empty()
	b.disabled = not se_puede
	b.pressed.connect(func() -> void: abrir(p))
	fila.add_child(b)
	if not faltan.is_empty() and not sin_empezar(p.mundo):
		var nota := p._texto(11, Principal.COL_SUAVE)
		nota.text = Idiomas.t("Con la temporada en marcha no se pueden añadir: las copas y los torneos continentales se volverían a sortear. Se ofrece al cerrar la temporada.")
		nota.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		p._lista_ajustes.add_child(nota)

## La misma pantalla que al cerrar la temporada (`AccionesTemporada._ofrecer_ligas`).
static func abrir(p: Principal) -> void:
	if not sin_empezar(p.mundo):
		return
	await p._acciones_temporada._ofrecer_ligas()
