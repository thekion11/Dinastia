class_name Hubs
extends RefCounted
## LOS HUBS CONTEXTUALES Y EL CARRIL DE CHIPS (fase 6, paso 5 del plan §7.1; sale de
## `Principal`, capas 13 y 14, el 27-10-2026). Una sola responsabilidad: la NAVEGACIÓN
## de nivel 1 y 2 del menú central: los bloques maestros (`Principal.GRUPOS`), el carril
## de chips de cada bloque, los hubs contextuales (`Principal.HUBS`, la capa que sube al
## tocar el plantel, la caja o la tabla) y el paso de página animado. `p` es la pantalla
## principal: las secciones abiertas, las filas y las pestañas siguen viviendo en ella;
## aquí solo se decide a dónde se va y cómo se pinta el carril. `Principal` conserva
## puentes de una línea con los nombres de siempre (los usan tutorial, atajos y pruebas).

var p: Principal

func _init(principal: Principal) -> void:
	p = principal

## UN HUB CONTEXTUAL. Se abre tocando la zona de la pantalla que ya habla de
## eso -el plantel, el marcador, la caja, la tabla- y ofrece sus pestañas como
## botones grandes. No es una pestaña más: es una puerta, y por eso se cierra
## sola en cuanto eliges.
func abrir(clave: String) -> void:
	var hub: Dictionary = Principal.HUBS.get(clave, {})
	if hub.is_empty():
		return
	var capa := PanelContainer.new()
	capa.set_anchors_preset(Control.PRESET_FULL_RECT)
	var estilo := StyleBoxFlat.new()
	estilo.bg_color = Color(p.COL_FONDO.r, p.COL_FONDO.g, p.COL_FONDO.b, 0.93)
	capa.add_theme_stylebox_override("panel", estilo)
	p.add_child(capa)

	var caja := VBoxContainer.new()
	caja.alignment = BoxContainer.ALIGNMENT_CENTER
	caja.add_theme_constant_override("separation", 10)
	capa.add_child(caja)
	var t := p._texto(20, p.COL_ORO)
	t.text = String(hub["titulo"])
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	caja.add_child(t)
	var flow := HFlowContainer.new()
	flow.alignment = FlowContainer.ALIGNMENT_CENTER
	flow.add_theme_constant_override("h_separation", 8)
	flow.add_theme_constant_override("v_separation", 8)
	caja.add_child(flow)
	for titulo: String in (hub["tabs"] as Array):
		var b := Button.new()
		b.text = titulo
		b.custom_minimum_size = Vector2(180, 44)
		b.add_theme_font_size_override("font_size", 14)
		var destino := titulo
		b.pressed.connect(func() -> void:
			capa.queue_free()
			p._ir_a_pestana(destino)
			p._refrescar())
		flow.add_child(b)
	var cerrar := Button.new()
	cerrar.text = Idiomas.t("✕  Cerrar")
	cerrar.custom_minimum_size = Vector2(0, 34)
	cerrar.pressed.connect(func() -> void: capa.queue_free())
	caja.add_child(cerrar)
	## La entrada con un desliz corto hacia arriba: es lo que hace que el hub
	## se sienta una capa que sube y no un cambio de pantalla seco.
	caja.modulate.a = 0.0
	caja.position.y += 18.0
	var tw := p.create_tween().set_parallel(true)
	tw.tween_property(caja, "modulate:a", 1.0, 0.16)
	tw.tween_property(caja, "position:y", caja.position.y - 18.0, 0.16).set_trans(Tween.TRANS_CUBIC)

func indice_grupo(gid: String) -> int:
	for i in Principal.GRUPOS.size():
		if String(Principal.GRUPOS[i]["id"]) == gid:
			return i
	return 0

func _paso_pagina(v: float) -> void:
	if p._marco_paginas == null:
		return
	p._marco_paginas.add_theme_constant_override("margin_left", int(v))
	p._marco_paginas.add_theme_constant_override("margin_right", int(-v))

func animar_pagina(direccion: int) -> void:
	if p._marco_paginas == null or direccion == 0:
		return
	var desde := 46.0 * float(direccion)
	_paso_pagina(desde)
	p._marco_paginas.modulate.a = 0.25
	var tw := p.create_tween().set_parallel(true)
	tw.tween_method(_paso_pagina, desde, 0.0, 0.20).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tw.tween_property(p._marco_paginas, "modulate:a", 1.0, 0.20)

func actualizar_fila_grupos() -> void:
	for i in p._fila_grupos.get_child_count():
		var b: Button = p._fila_grupos.get_child(i)
		b.button_pressed = (String(Principal.GRUPOS[i]["id"]) == p._grupo_actual)

func grupo_por_id(gid: String) -> Dictionary:
	for g: Dictionary in Principal.GRUPOS:
		if String(g["id"]) == gid:
			return g
	return {}

func seccion_activa(chip: Dictionary) -> bool:
	var secc := String(chip.get("secc", ""))
	if secc == "":
		return true
	match String(chip["tab"]):
		"Club": return p._secc_club == secc
		"Gente": return p._secc_gente == secc
		"Ajustes": return p._secc_ajustes == secc
		"Récords": return p._secc_records == secc
		"Redes": return p._secc_redes == secc
		"Vida": return p._secc_vida == secc
	return true

## Abre un chip: primero fija la sección dentro de la pestaña -si el chip
## trae `secc`- y después salta a la pestaña. El orden importa: al revés, la
## pestaña se pintaría con la sección vieja y habría que repintar dos veces.
func ir_a_chip(chip: Dictionary) -> void:
	var secc := String(chip.get("secc", ""))
	## «Equipación» es su propia pantalla, entera: el diseñador.
	if secc == "kits" and p.mundo != null and p.mundo.mi_club() != null:
		var dz := DisenadorKit.abrir(p, p.mundo)
		dz.cerrado.connect(p._refrescar)
		return
	if secc != "":
		match String(chip["tab"]):
			"Club": p._secc_club = secc
			"Gente": p._secc_gente = secc
			"Ajustes": p._secc_ajustes = secc
			"Récords": p._secc_records = secc
			"Redes": p._secc_redes = secc
			"Vida": p._secc_vida = secc
	p._ir_a_pestana(String(chip["tab"]))
	## OJO: `elegir_grupo("central")` corre dentro de `_construir()`, cuando
	## `p.mundo` todavía es null -la escena se arma antes de que le pasen la
	## partida-. Sin este candado, arrancar el juego tiraba "Nonexistent
	## function 'mi_club' in base 'Nil'" antes de pintar nada.
	if p.mundo != null:
		p._refrescar()

## EL CARRIL DE CHIPS (nivel 2). Un chip queda marcado cuando coinciden LAS
## DOS cosas: su pestaña y su sección. Sin mirar la sección, los cinco chips
## que comparten la pestaña "Club" se encenderían todos a la vez.
func reconstruir_fila_sub() -> void:
	p._limpiar(p._fila_sub)
	var titulo_actual := ""
	if p._pestanas.get_tab_count() > 0:
		titulo_actual = p._pestanas.get_tab_title(p._pestanas.current_tab)
	for chip: Dictionary in chips_del_carril(titulo_actual):
		var b := p._pildora(Idiomas.t(String(chip["label"])), 12, 30)
		b.button_pressed = (String(chip["tab"]) == titulo_actual) and seccion_activa(chip)
		var destino := chip
		b.pressed.connect(func() -> void: ir_a_chip(destino))
		p._fila_sub.add_child(b)
		## LA CASCADA. Cada chip entra un pelo después que el anterior -35 ms-,
		## así el carril "se abre" en vez de aparecer de golpe. Es lo que hace
		## que cambiar de bloque se sienta un gesto y no un parpadeo. El
		## desfase es corto a propósito: con 10 chips el último entra a los
		## 350 ms, todavía antes de que la mano llegue a tocar nada.
		b.modulate.a = 0.0
		var tw := p.create_tween()
		tw.tween_interval(0.035 * float(p._fila_sub.get_child_count() - 1))
		tw.tween_property(b, "modulate:a", 1.0, 0.14)
	## La chuleta «?» de las pantallas con más cifras, al final del carril.
	AyudaPestana.anadir(p._fila_sub, titulo_actual)

## Los chips del carril para la pestaña abierta (s3, «primera hora»): los de su
## bloque; y si es de un hub contextual (Finanzas, Mercado, Copa...) que no está en
## el bloque, los de ese hub -antes se quedaba el carril del bloque anterior, sin
## ningún chip marcado, como si la pestaña no existiera-.
func chips_del_carril(titulo: String) -> Array:
	var del_grupo: Array = grupo_por_id(p._grupo_actual).get("tabs", [])
	for ch: Dictionary in del_grupo:
		if String(ch["tab"]) == titulo:
			return del_grupo
	for h: String in Principal.HUBS:
		var tabs: Array = Principal.HUBS[h]["tabs"]
		if tabs.has(titulo):
			var out: Array = []
			for t: String in tabs:
				out.append({"tab": t, "label": t})
			return out
	return del_grupo

## Cambia de bloque maestro: entra siempre por su primer chip -índice 0-, que
## es lo que pidió el usuario ("al cambiar de pestaña madre, el nivel 2 se
## reinicia al primer chip").
func elegir_grupo(gid: String) -> void:
	var antes := indice_grupo(p._grupo_actual)
	var ahora := indice_grupo(gid)
	if gid != p._grupo_actual:
		animar_pagina(1 if ahora > antes else -1)
	p._grupo_actual = gid
	actualizar_fila_grupos()
	reconstruir_fila_sub()
	var chips: Array = grupo_por_id(gid).get("tabs", [])
	if not chips.is_empty():
		ir_a_chip(chips[0])

func construir_grupos() -> void:
	for g: Dictionary in Principal.GRUPOS:
		## En "compacto" el bloque va SOLO con su icono: seis iconos ocupan un
		## tercio de la fila y dejan el ancho para los chips, que es donde de
		## verdad hay que leer. El tooltip guarda el nombre entero.
		var rotulo := String(g["icono"]) if p._estilo_menu == "compacto" \
			else "%s  %s" % [String(g["icono"]), String(g["nombre"])]
		## EL AVISO DE NOVEDAD. Un punto al lado del bloque que tiene algo sin
		## resolver -correo sin leer, un representante esperando, contratos que
		## vencen-. Es lo que convierte la barra en un tablero: sin esto hay
		## que entrar a los seis bloques para descubrir dónde pasa algo.
		var pend := p._pendientes_de_grupo(String(g["id"]))
		if pend > 0:
			rotulo += "  ●"
		var b := p._pildora(rotulo, 13, 38)
		b.tooltip_text = String(g["nombre"])
		## YA NO se recortan ni se estiran: la barra vive a ancho completo de
		## pantalla, no dentro de la columna del medio, así que los seis
		## rótulos entran enteros y cada píldora mide lo que mide su texto.
		var gid := String(g["id"])
		b.pressed.connect(func() -> void: elegir_grupo(gid))
		## Los que ahora tienen menú propio en el panel lateral no se ven arriba
		## (siguen existiendo: la navegación y el tutorial van por índice).
		b.visible = not MenuLateral.EN_PANEL.has(gid)
		p._fila_grupos.add_child(b)

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
func grupo_de_pestana(titulo: String) -> String:
	for g: Dictionary in Principal.GRUPOS:
		if String(g["id"]) != p._grupo_actual:
			continue
		for chip: Dictionary in (g["tabs"] as Array):
			if String(chip["tab"]) == titulo and seccion_activa(chip):
				return String(g["id"])
	for g: Dictionary in Principal.GRUPOS:
		for chip: Dictionary in (g["tabs"] as Array):
			if String(chip["tab"]) == titulo and chip.has("secc") and seccion_activa(chip):
				return String(g["id"])
	for g: Dictionary in Principal.GRUPOS:
		for chip: Dictionary in (g["tabs"] as Array):
			if String(chip["tab"]) == titulo:
				return String(g["id"])
	return ""
