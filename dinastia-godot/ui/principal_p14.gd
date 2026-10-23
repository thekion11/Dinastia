extends "res://ui/principal_p13.gd"
## (Parte 14 de 18 de `principal.gd`.)

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
			_escribir("[color=#e05555]No te alcanza:[/color] la parte fija más la comisión cuesta %s." % _dinero(int(res.get("hace_falta", 0))))
		"club_pide_mas":
			_escribir("[color=#c9a227]↩️ Contraoferta de %s.[/color] Faltan unos %s y prefieren %s." % [
				(mundo.clubes.get(j.club_id) as Club).nombre if mundo.clubes.has(j.club_id) else "el club",
				_dinero(int(res.get("falta", 0))), String(res.get("prefiere", ""))])
		"rota":
			_escribir("[color=#e05555]❌ Negociación rota.[/color] El club se levantó de la mesa por %s." % j.nombre)
			mundo.mercado.cerrar_negociacion()
		"rival_traspaso", "rival_firma":
			var rc: Club = res.get("club")
			_escribir("[color=#e05555]💥 Fichaje perdido:[/color] %s cerró el traspaso de %s por %s mientras seguías negociando." % [
				rc.nombre if rc else "otro club", j.nombre, _dinero(int(res.get("precio", 0)))])
			mundo.mercado.cerrar_negociacion()
		"jugador_no":
			_escribir("[color=#c9a227]%s todavía no firma.[/color] %s" % [j.nombre, String(res.get("motivo", ""))])
		"jugador_rota":
			_escribir("[color=#e05555]❌ %s dice que no.[/color] %s No se sienta a hablar de él por un tiempo." % [j.nombre, String(res.get("motivo", ""))])
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

func _indice_grupo(gid: String) -> int:
	for i in GRUPOS.size():
		if String(GRUPOS[i]["id"]) == gid:
			return i
	return 0

func _paso_pagina(v: float) -> void:
	if _marco_paginas == null:
		return
	_marco_paginas.add_theme_constant_override("margin_left", int(v))
	_marco_paginas.add_theme_constant_override("margin_right", int(-v))

func _animar_pagina(direccion: int) -> void:
	if _marco_paginas == null or direccion == 0:
		return
	var desde := 46.0 * float(direccion)
	_paso_pagina(desde)
	_marco_paginas.modulate.a = 0.25
	var tw := create_tween().set_parallel(true)
	tw.tween_method(_paso_pagina, desde, 0.0, 0.20).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tw.tween_property(_marco_paginas, "modulate:a", 1.0, 0.20)

func _actualizar_fila_grupos() -> void:
	for i in _fila_grupos.get_child_count():
		var b: Button = _fila_grupos.get_child(i)
		b.button_pressed = (String(GRUPOS[i]["id"]) == _grupo_actual)

func _grupo_por_id(gid: String) -> Dictionary:
	for g: Dictionary in GRUPOS:
		if String(g["id"]) == gid:
			return g
	return {}

func _seccion_activa(chip: Dictionary) -> bool:
	var secc := String(chip.get("secc", ""))
	if secc == "":
		return true
	match String(chip["tab"]):
		"Club": return _secc_club == secc
		"Gente": return _secc_gente == secc
		"Ajustes": return _secc_ajustes == secc
		"Récords": return _secc_records == secc
		"Redes": return _secc_redes == secc
		"Vida": return _secc_vida == secc
	return true

## Abre un chip: primero fija la sección dentro de la pestaña -si el chip
## trae `secc`- y después salta a la pestaña. El orden importa: al revés, la
## pestaña se pintaría con la sección vieja y habría que repintar dos veces.
func _ir_a_chip(chip: Dictionary) -> void:
	var secc := String(chip.get("secc", ""))
	## «Equipación» es su propia pantalla, entera: el diseñador.
	if secc == "kits" and mundo != null and mundo.mi_club() != null:
		var dz := DisenadorKit.abrir(self, mundo)
		dz.cerrado.connect(_refrescar)
		return
	if secc != "":
		match String(chip["tab"]):
			"Club": _secc_club = secc
			"Gente": _secc_gente = secc
			"Ajustes": _secc_ajustes = secc
			"Récords": _secc_records = secc
			"Redes": _secc_redes = secc
			"Vida": _secc_vida = secc
	_ir_a_pestana(String(chip["tab"]))
	## OJO: `_elegir_grupo("central")` corre dentro de `_construir()`, cuando
	## `mundo` todavía es null -la escena se arma antes de que le pasen la
	## partida-. Sin este candado, arrancar el juego tiraba "Nonexistent
	## function 'mi_club' in base 'Nil'" antes de pintar nada.
	if mundo != null:
		_refrescar()

## EL CARRIL DE CHIPS (nivel 2). Un chip queda marcado cuando coinciden LAS
## DOS cosas: su pestaña y su sección. Sin mirar la sección, los cinco chips
## que comparten la pestaña "Club" se encenderían todos a la vez.
func _reconstruir_fila_sub() -> void:
	_limpiar(_fila_sub)
	var titulo_actual := ""
	if _pestanas.get_tab_count() > 0:
		titulo_actual = _pestanas.get_tab_title(_pestanas.current_tab)
	for chip: Dictionary in (_grupo_por_id(_grupo_actual).get("tabs", []) as Array):
		var b := _pildora(String(chip["label"]), 12, 30)
		b.button_pressed = (String(chip["tab"]) == titulo_actual) and _seccion_activa(chip)
		var destino := chip
		b.pressed.connect(func() -> void: _ir_a_chip(destino))
		_fila_sub.add_child(b)
		## LA CASCADA. Cada chip entra un pelo después que el anterior -35 ms-,
		## así el carril "se abre" en vez de aparecer de golpe. Es lo que hace
		## que cambiar de bloque se sienta un gesto y no un parpadeo. El
		## desfase es corto a propósito: con 10 chips el último entra a los
		## 350 ms, todavía antes de que la mano llegue a tocar nada.
		b.modulate.a = 0.0
		var tw := create_tween()
		tw.tween_interval(0.035 * float(_fila_sub.get_child_count() - 1))
		tw.tween_property(b, "modulate:a", 1.0, 0.14)

## Cambia de bloque maestro: entra siempre por su primer chip -índice 0-, que
## es lo que pidió el usuario ("al cambiar de pestaña madre, el nivel 2 se
## reinicia al primer chip").
func _elegir_grupo(gid: String) -> void:
	var antes := _indice_grupo(_grupo_actual)
	var ahora := _indice_grupo(gid)
	if gid != _grupo_actual:
		_animar_pagina(1 if ahora > antes else -1)
	_grupo_actual = gid
	_actualizar_fila_grupos()
	_reconstruir_fila_sub()
	var chips: Array = _grupo_por_id(gid).get("tabs", [])
	if not chips.is_empty():
		_ir_a_chip(chips[0])

func _construir_grupos() -> void:
	for g: Dictionary in GRUPOS:
		## En "compacto" el bloque va SOLO con su icono: seis iconos ocupan un
		## tercio de la fila y dejan el ancho para los chips, que es donde de
		## verdad hay que leer. El tooltip guarda el nombre entero.
		var rotulo := String(g["icono"]) if _estilo_menu == "compacto" \
			else "%s  %s" % [String(g["icono"]), String(g["nombre"])]
		## EL AVISO DE NOVEDAD. Un punto al lado del bloque que tiene algo sin
		## resolver -correo sin leer, un representante esperando, contratos que
		## vencen-. Es lo que convierte la barra en un tablero: sin esto hay
		## que entrar a los seis bloques para descubrir dónde pasa algo.
		var pend := _pendientes_de_grupo(String(g["id"]))
		if pend > 0:
			rotulo += "  ●"
		var b := _pildora(rotulo, 13, 38)
		b.tooltip_text = String(g["nombre"])
		## YA NO se recortan ni se estiran: la barra vive a ancho completo de
		## pantalla, no dentro de la columna del medio, así que los seis
		## rótulos entran enteros y cada píldora mide lo que mide su texto.
		var gid := String(g["id"])
		b.pressed.connect(func() -> void: _elegir_grupo(gid))
		## Los que ahora tienen menú propio en el panel lateral no se ven arriba
		## (siguen existiendo: la navegación y el tutorial van por índice).
		b.visible = not MenuLateral.EN_PANEL.has(gid)
		_fila_grupos.add_child(b)

## De qué bloque maestro es una pestaña. Con los hubs contextuales hay
## pestañas que NO pertenecen a ningún bloque -Táctica, Mercado, Copa...-: esas
## devuelven "" y la barra de arriba se queda como esté, sin saltar a otro
## bloque a la fuerza.
## FALLA VISUAL ARREGLADA (26-9-2026, recorrido D4): varias pestañas viven en
## más de un grupo -"Club" está en CENTRAL (Mi Carrera) y en CLUB
## (Infraestructura, Directorio); "Estadio" en CLUB y en OPERACIONES-, y esto
## devolvía siempre el PRIMER grupo: entrabas por CLUB › Infraestructura y el
## menú encendía CENTRAL. Ahora manda, por orden: el grupo en el que ya estás si
## tiene esa pestaña; si no, el grupo cuyo chip coincide con la sección abierta;
## y solo al final, el primero que la tenga.
func _grupo_de_pestana(titulo: String) -> String:
	for g: Dictionary in GRUPOS:
		if String(g["id"]) != _grupo_actual:
			continue
		for chip: Dictionary in (g["tabs"] as Array):
			if String(chip["tab"]) == titulo and _seccion_activa(chip):
				return String(g["id"])
	for g: Dictionary in GRUPOS:
		for chip: Dictionary in (g["tabs"] as Array):
			if String(chip["tab"]) == titulo and chip.has("secc") and _seccion_activa(chip):
				return String(g["id"])
	for g: Dictionary in GRUPOS:
		for chip: Dictionary in (g["tabs"] as Array):
			if String(chip["tab"]) == titulo:
				return String(g["id"])
	return ""

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

func _siguiente_diseno() -> void:
	if not _rotar_diseno:
		return
	_diseno_i = (_diseno_i + 1) % DISENOS_CENTRAL.size()
	var d: Array = DISENOS_CENTRAL[_diseno_i]
	## Un fundido corto para que el cambio se lea como una transición y no
	## como un parpadeo.
	var velo := ColorRect.new()
	velo.color = Color(0, 0, 0, 0)
	velo.set_anchors_preset(Control.PRESET_FULL_RECT)
	velo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(velo)
	var tw := create_tween()
	tw.tween_property(velo, "color:a", 0.55, 0.35)
	tw.tween_callback(func() -> void:
		_paleta = String(d[0])
		_estilo_menu = String(d[1])
		_forma_tarjeta = String(d[2])
		_fondo_elegido = String(d[3])
		_aplicar_aspecto()
		_aplicar_fondo()
		_reconstruir_grupos()
		if mundo != null:
			_refrescar())
	tw.tween_property(velo, "color:a", 0.0, 0.45)
	tw.tween_callback(velo.queue_free)
