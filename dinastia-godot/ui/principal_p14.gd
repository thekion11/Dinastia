extends "res://ui/principal_p13.gd"
## [Capa 14/17 de `principal.gd`] _enviar_oferta_negociacion, _al_ajustar_rol_neg, _al_ajustar_campo_neg y los puentes a `Hubs` (carril y hubs)

func _enviar_oferta_negociacion() -> void:
	var n := mundo.mercado.negociacion
	if n == null:
		return
	var j := n.jugador
	var res := n.enviar_oferta()
	_negociacion_ultimo = res
	var tipo := String(res.get("tipo", ""))
	match tipo:
		"sin_caja":
			_escribir("[color=#e05555]%s[/color] %s" % [Idiomas.t("No te alcanza:"),
				Idiomas.t("la parte fija más la comisión cuesta %s.") % _dinero(int(res.get("hace_falta", 0)))])
		"club_pide_mas":
			## Plantillas con `Idiomas.t` (s3): `prefiere` y `motivo` ya llegan traducidos del núcleo.
			_escribir("[color=#c9a227]%s[/color] %s" % [
				Idiomas.t("↩️ Contraoferta de %s.") % ((mundo.clubes.get(j.club_id) as Club).nombre if mundo.clubes.has(j.club_id) else Idiomas.t("el club")),
				Idiomas.t("Faltan unos %s y prefieren %s.") % [_dinero(int(res.get("falta", 0))), String(res.get("prefiere", ""))]])
		"rota":
			_escribir("[color=#e05555]❌ Negociación rota.[/color] El club se levantó de la mesa por %s." % j.nombre)
			mundo.mercado.cerrar_negociacion()
		"rival_traspaso", "rival_firma":
			var rc: Club = res.get("club")
			_escribir("[color=#e05555]💥 Fichaje perdido:[/color] %s cerró el traspaso de %s por %s mientras seguías negociando." % [
				rc.nombre if rc else "otro club", j.nombre, _dinero(int(res.get("precio", 0)))])
			mundo.mercado.cerrar_negociacion()
		"jugador_no":
			_escribir("[color=#c9a227]%s[/color] %s" % [Idiomas.t("%s todavía no firma.") % j.nombre, String(res.get("motivo", ""))])
		"jugador_rota":
			_escribir("[color=#e05555]%s[/color] %s %s" % [Idiomas.t("❌ %s dice que no.") % j.nombre, String(res.get("motivo", "")),
				Idiomas.t("No se sienta a hablar de él por un tiempo.")])
			mundo.mercado.cerrar_negociacion()
		"cerrado":
			var r: Dictionary = res.get("resumen", {})
			Sonido.toca("fichaje")
			_escribir("[color=#4caf6d][b]✅ Fichaje cerrado:[/b][/color] %s firma por %d temporadas con ficha de %s/semana." % [
				j.nombre, int(r.get("anios", n.anios)), _dinero(int(r.get("sueldo", n.sueldo)))])
			mundo.mercado.cerrar_negociacion()
			_negociacion_ultimo = {}
	_refrescar()

## "TU CARRERA" de `vDirectorio()`: el prestigio y la vitrina te siguen de club
## en club -a diferencia de `Directiva.trofeos`, que se quedan en el que
## dejas-, más las dos escaleras (ayudante→DT, DT→director→dueño) y lo que
## trae cada peldaño: un entrenador empleado que puedes cambiar, o -siendo
## dueño- meter capital propio y vender el club. Toda esta lógica ya estaba
## escrita y probada en `Roles`; no había ninguna pantalla que la mostrara.

# ---------------------------------------------------------------------------
#  HANDLERS DE SEÑALES — PanelMercado
#  Los conecta _construir(); los ejecuta Principal porque son los únicos
#  que tienen acceso a `mundo` para modificarlo.
# ---------------------------------------------------------------------------

## Ajusta el rol prometido en la negociación activa. La señal `"__clausula__"`
## es el caso especial de alternar la cláusula de rescisión.
func _al_ajustar_rol_neg(rol: String) -> void:
	if mundo == null or mundo.mercado.negociacion == null:
		return
	if rol == "__clausula__":
		mundo.mercado.negociacion.alternar_clausula()
	else:
		mundo.mercado.negociacion.ajustar_rol(rol)
	_refrescar()

## Ajusta un campo numérico de la negociación activa (fijo, cuotas, bonos…).
func _al_ajustar_campo_neg(campo: String, delta: int) -> void:
	if mundo == null or mundo.mercado.negociacion == null:
		return
	mundo.mercado.negociacion.ajustar(campo, delta)
	_refrescar()

func _animar_pestana() -> void:
	var pag := _pestanas.get_current_tab_control()
	if pag == null:
		return
	## Cada hoja es VBox > ScrollContainer > VBox (la lista): se anima la lista.
	for h in pag.get_children():
		if h is ScrollContainer and h.get_child_count() > 0:
			Animar.escalonar(h.get_child(0))
			return
	Animar.escalonar(pag)

func _al_cambiar_pestana(_idx: int) -> void:
	vista_cambiada.emit()
	var titulo := _pestanas.get_tab_title(_pestanas.current_tab)
	var gid := _grupo_de_pestana(titulo)
	## "" = pestaña de hub contextual (Táctica, Mercado, Copa...). No pertenece
	## a ningún bloque maestro, así que la barra de arriba se queda donde
	## estaba en vez de saltar a un bloque que no tiene nada que ver.
	if gid != "" and gid != _grupo_actual:
		_grupo_actual = gid
		_actualizar_fila_grupos()
	_reconstruir_fila_sub()
	## El contenido de la pestaña entra escalonado (plan maestro B11).
	_animar_pestana.call_deferred()

func _bloque(padre: VBoxContainer, titulo: String, ratio: float) -> VBoxContainer:
	var caja := _panel()
	caja.size_flags_vertical = Control.SIZE_EXPAND_FILL
	caja.size_flags_stretch_ratio = ratio
	padre.add_child(caja)
	var v := VBoxContainer.new()
	v.set_anchors_preset(Control.PRESET_FULL_RECT)
	v.offset_left = 12; v.offset_top = 10; v.offset_right = -12; v.offset_bottom = -10
	caja.add_child(v)
	var t := _texto(11, COL_SUAVE); t.text = titulo
	t.set_meta("titulo_bloque", true)
	v.add_child(t)
	return v

## Repinta el lienzo. Solo hace falta al cambiar de paleta: el resto se aplica
## solo al reconstruir las pantallas.
func _aplicar_aspecto() -> void:
	if _fondo_raiz != null:
		_fondo_raiz.color = _pal_fondo()
	_aplicar_tema()
	_ui_ajustes._repintar_tarjetas(self)

## Vuelve a montar la fila de bloques con el estilo actual. Hace falta porque
## `_construir_grupos()` corre UNA vez al armar la escena, y cambiar de
## estilo de menú tiene que verse sin reiniciar la partida.
func _reconstruir_grupos() -> void:
	_limpiar(_fila_grupos)
	_construir_grupos()
	_actualizar_fila_grupos()
	_reconstruir_fila_sub()
	_pintar_dias()

## Puentes (fase 6, paso 5): hubs y carril viven en `Hubs` (`ui/menu/hubs.gd`).
func _abrir_hub(clave: String) -> void: _hubs.abrir(clave)
func _indice_grupo(gid: String) -> int: return _hubs.indice_grupo(gid)
func _animar_pagina(direccion: int) -> void: _hubs.animar_pagina(direccion)
func _actualizar_fila_grupos() -> void: _hubs.actualizar_fila_grupos()
func _grupo_por_id(gid: String) -> Dictionary: return _hubs.grupo_por_id(gid)
func _seccion_activa(chip: Dictionary) -> bool: return _hubs.seccion_activa(chip)
func _ir_a_chip(chip: Dictionary) -> void: _hubs.ir_a_chip(chip)
func _reconstruir_fila_sub() -> void: _hubs.reconstruir_fila_sub()
func _chips_del_carril(titulo: String) -> Array: return _hubs.chips_del_carril(titulo)
func _elegir_grupo(gid: String) -> void: _hubs.elegir_grupo(gid)
func _construir_grupos() -> void: _hubs.construir_grupos()
func _grupo_de_pestana(titulo: String) -> String: return _hubs.grupo_de_pestana(titulo)
