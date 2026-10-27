class_name VistasMenu
extends RefCounted
## (fase 6, paso 7 del plan §7.1: sale de `Principal`, ui/principal_p7.gd, el 27-10-2026). `p` es la pantalla principal;
## sus miembros se usan como `p.x` y `Principal` conserva puentes de una línea con los nombres de siempre.

var p: Principal
## Estado propio de esta pantalla (fase 6, paso 7: antes eran variables de `Principal`).
var _clubes_pais := ""

func _init(principal: Principal) -> void:
	p = principal

## Mismo motivo y mismo arreglo que `_ver_estadio_propio()`: `VistaCiudad`
## tampoco trae fondo opaco -para que el 3D se vea de verdad-, así que hay
## que esconder el resto de la pantalla mientras está abierta.
## El ídolo del club para la estatua de la ciudad: la última leyenda retirada
## del club; si no hay, el capitán; si no, el de más media.
func _idolo_del_club(c: Club) -> String:
	if p.mundo.cantera != null:
		for k in range(p.mundo.cantera.leyendas.size() - 1, -1, -1):
			var L: Dictionary = p.mundo.cantera.leyendas[k]
			if String(L.get("club_id", "")) == c.id:
				return String(L.get("nombre", ""))
	var mejor: Jugador = null
	for j: Jugador in c.plantilla:
		if j.capitan:
			return j.nombre
		if mejor == null or j.ovr > mejor.ovr:
			mejor = j
	return mejor.nombre if mejor != null else ""
func _ver_ciudad_propia() -> void:
	p._fundido_entrada()
	var c := p.mundo.mi_club()
	if c == null or p.mundo.obras == null:
		return
	var ocultados: Array = []
	for h in p.get_children():
		if h is CanvasItem and (h as CanvasItem).visible:
			(h as CanvasItem).visible = false
			ocultados.append(h)
	var vista := VistaCiudad.new()
	p.add_child(vista)
	vista.construir = p._ui_club_vida._empezar_obra
	var prox := p.mundo.proximo_partido()
	vista.dia_partido = not prox.is_empty() and prox[0] == c
	vista.animo = CiudadAnimo.de(p.mundo, c)
	vista.idolo = _idolo_del_club(c)
	vista.abrir(c, p.mundo.obras, p.mundo.ciudad, p.mundo.perfil_estadio_de(c))
	vista.cerrado.connect(func() -> void:
		vista.queue_free()
		for h in ocultados:
			if is_instance_valid(h):
				(h as CanvasItem).visible = true
		(p as Principal)._refrescar())
	## Clic en el estadio, o el botón "Editar mi estadio": mismo cierre que
	## "Volver" -devuelve la pestaña de Club, que quedaba oculta- y además
	## salta directo a Estadio con el diseñador ya pintado, en vez de dejar al
	## jugador en la pestaña en la que estaba antes de entrar a la ciudad.
	vista.editar_estadio_pedido.connect(func() -> void:
		vista.queue_free()
		for h in ocultados:
			if is_instance_valid(h):
				(h as CanvasItem).visible = true
		p._ir_a_pestana("Estadio")
		p._pintar_estadio(c))
func _ver_ciudad_con_carga() -> void:
	PantallaCarga.club = p.mundo.mi_club() if p.mundo != null else null
	var carga := PantallaCarga.mostrar(p, Idiomas.t("Construyendo la ciudad…"))
	await p.get_tree().process_frame
	await p.get_tree().process_frame
	_ver_ciudad_propia()
	## Si algo la cerró mientras se esperaba (otra pantalla encima, o el
	## recorrido de pantallas), llamarla aquí tumbaba el juego (señal 11).
	if is_instance_valid(carga):
		carga.cerrar()
## Cuatro pantallas del HTML en una sola pestaña, porque son la misma pregunta
## hecha a distinta profundidad -"¿qué hay ahí fuera?"-: `vLigas()` (la tabla de
## cualquier liga del mundo), `vClubes()` (el directorio de clubes),
## `vFichaClub()` (el plantel de uno concreto) y `vGoleadores()` (los artilleros
## de esa liga). Hasta hoy solo se veía TU liga y ningún plantel ajeno.
##
## No hace falta ni un dato nuevo: todo sale de `mundo.ligas` y de las
## plantillas que ya existen.
func _pintar_clubes() -> void:
	p._limpiar(p._lista_clubes)
	if _clubes_pais == "":
		_clubes_pais = p.mundo.mi_club().pais
	p._ui_plantel._pintar_rivalidades()

	var paises: Array[String] = []
	for l in p.mundo.ligas:
		if not paises.has(l.pais):
			paises.append(l.pais)
	paises.sort()
	var t := p._texto(11, p.COL_SUAVE)
	t.text = Idiomas.t("LIGAS DEL MUNDO")
	p._lista_clubes.add_child(t)
	## Los países no caben en una fila: se reparten en filas de ocho.
	var fila_pais: HBoxContainer = null
	for i in paises.size():
		if i % 8 == 0:
			fila_pais = HBoxContainer.new()
			fila_pais.add_theme_constant_override("separation", 4)
			p._lista_clubes.add_child(fila_pais)
		var pais := paises[i]
		var bp := Button.new()
		bp.text = pais
		bp.toggle_mode = true
		bp.button_pressed = pais == _clubes_pais
		bp.add_theme_font_size_override("font_size", 11)
		bp.pressed.connect(func() -> void:
			_clubes_pais = pais
			p._clubes_ficha = null
			_pintar_clubes())
		fila_pais.add_child(bp)
	p._lista_clubes.add_child(HSeparator.new())

	for l in p.mundo.ligas:
		if l.pais != _clubes_pais:
			continue
		var tl := p._texto(12, p.COL_ORO)
		tl.text = l.nombre
		p._lista_clubes.add_child(tl)
		var g := GridContainer.new()
		g.columns = 7
		g.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		g.add_theme_constant_override("h_separation", 10)
		p._lista_clubes.add_child(g)
		for enc in ["#", "CLUB", "PJ", "G", "E", "P", "PTS"]:
			p._celda(g, enc, p.COL_SUAVE, enc != "CLUB" and enc != "#", 11)
		var puesto := 1
		for fila: Dictionary in l.tabla():
			var club: Club = fila["club"]
			p._celda(g, str(puesto), p.COL_SUAVE, false, 11)
			## El nombre es un botón: pulsarlo abre su plantel abajo. Eso es
			## `vFichaClub()`, que en el HTML es una pantalla aparte.
			var b := Button.new()
			b.text = club.nombre
			b.flat = true
			b.alignment = HORIZONTAL_ALIGNMENT_LEFT
			b.add_theme_font_size_override("font_size", 12)
			b.add_theme_color_override("font_color", p._color_de_paleta(p.COL_ACENTO if club == p.mundo.mi_club() else p.COL_TEXTO))
			b.pressed.connect(func() -> void:
				p._clubes_ficha = null if p._clubes_ficha == club else club
				_pintar_clubes())
			g.add_child(b)
			for clave in ["pj", "g", "e", "p", "pts"]:
				var txt := str(int(fila.get(clave, 0)))
				## Los puntos quitados por sanción, a la vista (−3 en rojo).
				if clave == "pts" and int(fila.get("sancion", 0)) > 0:
					txt += " (−%d)" % int(fila["sancion"])
				p._celda(g, txt, p.COL_TEXTO if clave == "pts" else p.COL_SUAVE, true, 11)
			puesto += 1
		p._lista_clubes.add_child(HSeparator.new())

	if p._clubes_ficha != null:
		p._ui_plantel._pintar_ficha_club(p._clubes_ficha)
	p._ui_plantel._pintar_goleadores(_clubes_pais)
## La barra de cinco -un botón por grupo, con el mismo icono que `#tabs` del
## HTML-. Se toca una sola vez; el submenú de abajo cambia solo.
## CUÁNTO HAY SIN RESOLVER EN CADA BLOQUE. Todo sale de datos que el motor ya
## lleva -no hay contador nuevo que mantener-, y por eso no puede
## desincronizarse: si el correo tiene tres sin leer, es porque `_bandeja`
## tiene tres sin leer.
func _pendientes_de_grupo(gid: String) -> int:
	if p.mundo == null:
		return 0
	var n := 0
	match gid:
		"central":
			for m: Dictionary in p._bandeja:
				if not bool(m.get("leido", false)):
					n += 1
		"gente":
			if p.mundo.cantera != null and p.mundo.cantera.hay_exigencia():
				n += 1
		"operaciones":
			if p.mundo.prensa != null and p.mundo.prensa.hay_rueda():
				n += 1
			if p.mundo.mercado != null:
				n += p.mundo.mercado.ofertas_recibidas.size()
	return n
## Repinta SOLO los rótulos de los seis bloques, para que el punto de aviso
## aparezca y desaparezca al avanzar la semana. Se hace aparte de
## `_reconstruir_grupos()` porque eso reconstruye botones enteros y esto
## corre en cada repintado: cambiar seis textos es gratis, recrear seis
## botones con sus estilos no.
func _actualizar_badges() -> void:
	if p._fila_grupos == null:
		return
	for i in mini(p._fila_grupos.get_child_count(), Principal.GRUPOS.size()):
		var b := p._fila_grupos.get_child(i) as Button
		if b == null:
			continue
		var g: Dictionary = Principal.GRUPOS[i]
		var rotulo := String(g["icono"]) if p._estilo_menu == "compacto" \
			else "%s  %s" % [String(g["icono"]), String(g["nombre"])]
		if _pendientes_de_grupo(String(g["id"])) > 0:
			rotulo += "  ●"
		b.text = rotulo

## EL MUSEO DEL CLUB. `Instalaciones` deja construirlo y cobra ingresos por él
## desde el porte, pero no tenía CONTENIDO: se pagaba un edificio cuyo interior
## no existía en ninguna pantalla.
##
## Las piezas no se guardan aparte: se deducen de lo que el club ya tiene
## anotado —trofeos, récords, goleadores— igual que el salón de la fama. Una
## lista paralela sería otro sitio más que mantener al día.
func _pintar_museo(lg: Logros) -> void:
	if p.mundo.obras == null or p.mundo.obras.nivel("museo") <= 0:
		return
	var piezas := lg.piezas_del_museo()
	p._lista_logros.add_child(HSeparator.new())
	var t := p._texto(11, p.COL_SUAVE)
	t.text = Idiomas.t("🏛️ MUSEO DEL CLUB  ·  nivel %d  ·  %d pieza(s)") % [p.mundo.obras.nivel("museo"), piezas.size()]
	p._lista_logros.add_child(t)
	if piezas.is_empty():
		var vac := p._texto(11, p.COL_SUAVE)
		vac.text = Idiomas.t("El museo está construido pero las vitrinas están vacías. Gana algo y se irán llenando solas.")
		vac.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		p._lista_logros.add_child(vac)
	else:
		for pieza: Dictionary in piezas:
			var l := p._texto(12, p.COL_ORO)
			l.text = "%s  %s" % [String(pieza["icono"]), String(pieza["titulo"])]
			p._lista_logros.add_child(l)
			var d := p._texto(10, p.COL_SUAVE)
			d.text = "     %s" % String(pieza["detalle"])
			d.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			p._lista_logros.add_child(d)

	## EL COMPARADOR DE GENERACIONES. No compara jugadores uno a uno —eso sería
	## inventarse datos de gente retirada— sino la media del mejor plantel que
	## has tenido contra la del de ahora, que es la pregunta de verdad.
	var comp: Dictionary = lg.comparador_de_generaciones()
	if comp.is_empty():
		return
	var tc := p._texto(11, p.COL_SUAVE)
	tc.text = Idiomas.t("⚖️ AQUEL EQUIPO Y ESTE")
	p._lista_logros.add_child(tc)
	p._dato("Tu mejor plantilla", "%d  ·  quedó %d.º  ·  figura: %s" % [
		int(comp["anio"]), int(comp["puesto"]), String(comp["mvp"])], p.COL_ORO, p._lista_logros)
	p._dato("Media del plantel de hoy", "%.1f" % float(comp["media_actual"]), p.COL_TEXTO, p._lista_logros)
## EL LOGO DE UN SPONSOR, mismo patrón que `_escudo()` de arriba: la textura
## de `Marca` debajo y las iniciales encima con el color de contraste que
## corresponda. Antes de esto un sponsor era solo una palabra pintada del
## color de la tabla -ver la nota de `Marca` para el porqué-.
func _marca(nombre: String, color_hex: String, alto: int = 28) -> Control:
	var caja := Control.new()
	caja.custom_minimum_size = Vector2(alto, alto)
	var t := TextureRect.new()
	t.texture = Marca.textura(nombre, color_hex, alto)
	t.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	t.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	t.set_anchors_preset(Control.PRESET_FULL_RECT)
	caja.add_child(t)
	var l := Label.new()
	l.text = Marca.iniciales(nombre)
	l.add_theme_font_size_override("font_size", maxi(8, alto / 2 - 2))
	l.add_theme_color_override("font_color", p._tinta(Color(color_hex)))
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	l.set_anchors_preset(Control.PRESET_FULL_RECT)
	caja.add_child(l)
	return caja
## Abre la ciudad y arranca directamente el paseo ("pie") o la conducción ("coche").
func _ver_ciudad_explorando(modo: String) -> void:
	## Fase 3: sin coche propio (o en el taller) se sale a pie, y la vida se engancha al paseo.
	var transp := VidaCiudad.transporte(p.mundo)
	if modo == "coche" and not bool(transp["coche"]):
		Aviso.mostrar(p, "vida", "🚌", Idiomas.t("Sin coche esta semana"), Idiomas.t(String(transp["motivo"])))
		modo = "pie"
	await p._ver_ciudad_con_carga()
	for h in p.get_children():
		if h is VistaCiudad:
			(h as VistaCiudad).explorar(modo)
			VidaCiudad.enganchar((h as VistaCiudad)._explorador, h as VistaCiudad, p.mundo)

func _ver_estadio_propio() -> void:
	p._fundido_entrada()
	var c := p.mundo.mi_club()
	if c == null:
		return
	var f := Finanzas.new(c)
	var gente := float(f.asistencia()) / float(maxi(c.estadio_aforo, 1))
	## VistaEstadio pinta el 3D DIRECTO en el viewport raíz y a propósito no
	## trae ningún fondo opaco -es lo que deja ver el estadio de verdad, ver
	## el comentario en `estadio.gd::_construir()`-, pero eso significa que
	## cualquier Control que siga encima -la barra superior, las pestañas,
	## esta misma lista de Estadio- lo tapa entero: en un mismo viewport los
	## Control se pintan SIEMPRE sobre el 3D, sin importar el orden en que se
	## añadieron los nodos. `partido_vivo._ver_estadio()` no tiene este
	## problema porque su propia pantalla ya deja hueco de sobra; esta sí
	## está cubierta de paneles, así que hay que esconderlos a mano mientras
	## el visor está abierto y devolverlos tal cual al volver -guardando
	## cuáles estaban visibles, no asumiendo que todos lo estaban-.
	var ocultados: Array = []
	for h in p.get_children():
		if h is CanvasItem and (h as CanvasItem).visible:
			(h as CanvasItem).visible = false
			ocultados.append(h)
	var vista := VistaEstadio.new()
	## Sin partido la pantalla gigante enseña bienvenida + tabla + goleadores,
	## que es lo que hace un estadio de verdad un día entre semana. Va antes de
	## `abrir()`, que es donde se monta.
	vista.datos_pantalla = p._datos_pantalla_estadio(c)
	p.add_child(vista)
	vista.abrir(c, clampf(gente, 0.05, 1.0), null, null, p.mundo.perfil_estadio_de(c),
		Comercial.color_balon(p.mundo.comercial.balon, c))
	vista.cerrado.connect(func() -> void:
		vista.queue_free()
		for h in ocultados:
			if is_instance_valid(h):
				(h as CanvasItem).visible = true)
## Con pantalla de carga y consejos: se pinta ANTES de empezar a construir.
func _ver_estadio_con_carga() -> void:
	PantallaCarga.club = p.mundo.mi_club() if p.mundo != null else null
	var carga := PantallaCarga.mostrar(p, Idiomas.t("Levantando el estadio…"))
	await p.get_tree().process_frame
	await p.get_tree().process_frame
	_ver_estadio_propio()
	## Si algo la cerró mientras se esperaba (otra pantalla encima, o el
	## recorrido de pantallas), llamarla aquí tumbaba el juego (señal 11).
	if is_instance_valid(carga):
		carga.cerrar()
