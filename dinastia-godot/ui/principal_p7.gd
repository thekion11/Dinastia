extends "res://ui/principal_p6.gd"
## [Capa 7/17 de `principal.gd`] _idolo_del_club, _ir_a_pestana, _ver_ciudad_propia, _ver_ciudad_con_carga, _celda, _pintar_clubes … (+9)

## Mismo motivo y mismo arreglo que `_ver_estadio_propio()`: `VistaCiudad`
## tampoco trae fondo opaco -para que el 3D se vea de verdad-, así que hay
## que esconder el resto de la pantalla mientras está abierta.
## El ídolo del club para la estatua de la ciudad: la última leyenda retirada
## del club; si no hay, el capitán; si no, el de más media.
func _idolo_del_club(c: Club) -> String:
	if mundo.cantera != null:
		for k in range(mundo.cantera.leyendas.size() - 1, -1, -1):
			var L: Dictionary = mundo.cantera.leyendas[k]
			if String(L.get("club_id", "")) == c.id:
				return String(L.get("nombre", ""))
	var mejor: Jugador = null
	for j: Jugador in c.plantilla:
		if j.capitan:
			return j.nombre
		if mejor == null or j.ovr > mejor.ovr:
			mejor = j
	return mejor.nombre if mejor != null else ""

func _ir_a_pestana(titulo: String) -> void:
	for i in _pestanas.get_tab_count():
		if _pestanas.get_tab_title(i) == titulo:
			_pestanas.current_tab = i
			return

func _ver_ciudad_propia() -> void:
	_fundido_entrada()
	var c := mundo.mi_club()
	if c == null or mundo.obras == null:
		return
	var ocultados: Array = []
	for h in get_children():
		if h is CanvasItem and (h as CanvasItem).visible:
			(h as CanvasItem).visible = false
			ocultados.append(h)
	var vista := VistaCiudad.new()
	add_child(vista)
	vista.construir = _ui_club_vida._empezar_obra
	var prox := mundo.proximo_partido()
	vista.dia_partido = not prox.is_empty() and prox[0] == c
	vista.animo = CiudadAnimo.de(mundo, c)
	vista.idolo = _idolo_del_club(c)
	vista.abrir(c, mundo.obras, mundo.ciudad, mundo.perfil_estadio_de(c))
	vista.cerrado.connect(func() -> void:
		vista.queue_free()
		for h in ocultados:
			if is_instance_valid(h):
				(h as CanvasItem).visible = true
		(self as Principal)._refrescar())
	## Clic en el estadio, o el botón "Editar mi estadio": mismo cierre que
	## "Volver" -devuelve la pestaña de Club, que quedaba oculta- y además
	## salta directo a Estadio con el diseñador ya pintado, en vez de dejar al
	## jugador en la pestaña en la que estaba antes de entrar a la ciudad.
	vista.editar_estadio_pedido.connect(func() -> void:
		vista.queue_free()
		for h in ocultados:
			if is_instance_valid(h):
				(h as CanvasItem).visible = true
		_ir_a_pestana("Estadio")
		_pintar_estadio(c))

func _ver_ciudad_con_carga() -> void:
	PantallaCarga.club = mundo.mi_club() if mundo != null else null
	var carga := PantallaCarga.mostrar(self, Idiomas.t("Construyendo la ciudad…"))
	await get_tree().process_frame
	await get_tree().process_frame
	_ver_ciudad_propia()
	## Si algo la cerró mientras se esperaba (otra pantalla encima, o el
	## recorrido de pantallas), llamarla aquí tumbaba el juego (señal 11).
	if is_instance_valid(carga):
		carga.cerrar()

## Puente (fase 6, paso 6): la pestaña Ciudad la pinta `PantallaCiudad`.
func _pintar_ciudad(c: Club) -> void: _ui_ciudad._pintar_ciudad(c)

func _celda(g: GridContainer, texto: String, color: Color, derecha: bool = false, tam: int = 12) -> Label:
	var l := _texto(tam, color)
	l.text = texto
	if derecha:
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	g.add_child(l)
	return l

## Cuatro pantallas del HTML en una sola pestaña, porque son la misma pregunta
## hecha a distinta profundidad -"¿qué hay ahí fuera?"-: `vLigas()` (la tabla de
## cualquier liga del mundo), `vClubes()` (el directorio de clubes),
## `vFichaClub()` (el plantel de uno concreto) y `vGoleadores()` (los artilleros
## de esa liga). Hasta hoy solo se veía TU liga y ningún plantel ajeno.
##
## No hace falta ni un dato nuevo: todo sale de `mundo.ligas` y de las
## plantillas que ya existen.
func _pintar_clubes() -> void:
	_limpiar(_lista_clubes)
	if _clubes_pais == "":
		_clubes_pais = mundo.mi_club().pais
	_ui_plantel._pintar_rivalidades()

	var paises: Array[String] = []
	for l in mundo.ligas:
		if not paises.has(l.pais):
			paises.append(l.pais)
	paises.sort()
	var t := _texto(11, COL_SUAVE)
	t.text = Idiomas.t("LIGAS DEL MUNDO")
	_lista_clubes.add_child(t)
	## Los países no caben en una fila: se reparten en filas de ocho.
	var fila_pais: HBoxContainer = null
	for i in paises.size():
		if i % 8 == 0:
			fila_pais = HBoxContainer.new()
			fila_pais.add_theme_constant_override("separation", 4)
			_lista_clubes.add_child(fila_pais)
		var pais := paises[i]
		var bp := Button.new()
		bp.text = pais
		bp.toggle_mode = true
		bp.button_pressed = pais == _clubes_pais
		bp.add_theme_font_size_override("font_size", 11)
		bp.pressed.connect(func() -> void:
			_clubes_pais = pais
			_clubes_ficha = null
			_pintar_clubes())
		fila_pais.add_child(bp)
	_lista_clubes.add_child(HSeparator.new())

	for l in mundo.ligas:
		if l.pais != _clubes_pais:
			continue
		var tl := _texto(12, COL_ORO)
		tl.text = l.nombre
		_lista_clubes.add_child(tl)
		var g := GridContainer.new()
		g.columns = 7
		g.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		g.add_theme_constant_override("h_separation", 10)
		_lista_clubes.add_child(g)
		for enc in ["#", "CLUB", "PJ", "G", "E", "P", "PTS"]:
			_celda(g, enc, COL_SUAVE, enc != "CLUB" and enc != "#", 11)
		var puesto := 1
		for fila: Dictionary in l.tabla():
			var club: Club = fila["club"]
			_celda(g, str(puesto), COL_SUAVE, false, 11)
			## El nombre es un botón: pulsarlo abre su plantel abajo. Eso es
			## `vFichaClub()`, que en el HTML es una pantalla aparte.
			var b := Button.new()
			b.text = club.nombre
			b.flat = true
			b.alignment = HORIZONTAL_ALIGNMENT_LEFT
			b.add_theme_font_size_override("font_size", 12)
			b.add_theme_color_override("font_color", _color_de_paleta(COL_ACENTO if club == mundo.mi_club() else COL_TEXTO))
			b.pressed.connect(func() -> void:
				_clubes_ficha = null if _clubes_ficha == club else club
				_pintar_clubes())
			g.add_child(b)
			for clave in ["pj", "g", "e", "p", "pts"]:
				var txt := str(int(fila.get(clave, 0)))
				## Los puntos quitados por sanción, a la vista (−3 en rojo).
				if clave == "pts" and int(fila.get("sancion", 0)) > 0:
					txt += " (−%d)" % int(fila["sancion"])
				_celda(g, txt, COL_TEXTO if clave == "pts" else COL_SUAVE, true, 11)
			puesto += 1
		_lista_clubes.add_child(HSeparator.new())

	if _clubes_ficha != null:
		_ui_plantel._pintar_ficha_club(_clubes_ficha)
	_ui_plantel._pintar_goleadores(_clubes_pais)

## La barra de cinco -un botón por grupo, con el mismo icono que `#tabs` del
## HTML-. Se toca una sola vez; el submenú de abajo cambia solo.
## CUÁNTO HAY SIN RESOLVER EN CADA BLOQUE. Todo sale de datos que el motor ya
## lleva -no hay contador nuevo que mantener-, y por eso no puede
## desincronizarse: si el correo tiene tres sin leer, es porque `_bandeja`
## tiene tres sin leer.
func _pendientes_de_grupo(gid: String) -> int:
	if mundo == null:
		return 0
	var n := 0
	match gid:
		"central":
			for m: Dictionary in _bandeja:
				if not bool(m.get("leido", false)):
					n += 1
		"gente":
			if mundo.cantera != null and mundo.cantera.hay_exigencia():
				n += 1
		"operaciones":
			if mundo.prensa != null and mundo.prensa.hay_rueda():
				n += 1
			if mundo.mercado != null:
				n += mundo.mercado.ofertas_recibidas.size()
	return n

## Repinta SOLO los rótulos de los seis bloques, para que el punto de aviso
## aparezca y desaparezca al avanzar la semana. Se hace aparte de
## `_reconstruir_grupos()` porque eso reconstruye botones enteros y esto
## corre en cada repintado: cambiar seis textos es gratis, recrear seis
## botones con sus estilos no.
func _actualizar_badges() -> void:
	if _fila_grupos == null:
		return
	for i in mini(_fila_grupos.get_child_count(), GRUPOS.size()):
		var b := _fila_grupos.get_child(i) as Button
		if b == null:
			continue
		var g: Dictionary = GRUPOS[i]
		var rotulo := String(g["icono"]) if _estilo_menu == "compacto" \
			else "%s  %s" % [String(g["icono"]), String(g["nombre"])]
		if _pendientes_de_grupo(String(g["id"])) > 0:
			rotulo += "  ●"
		b.text = rotulo


## Puentes (fase 6, paso 7): viven en `AccionesFichaje`.
func _reconvertir(j: Jugador, pe: String) -> void: _acciones_fichaje._reconvertir(j, pe)
func _listar_transferible(j: Jugador) -> void: _acciones_fichaje._listar_transferible(j)
func _rescindir(j: Jugador, total: int) -> void: _acciones_fichaje._rescindir(j, total)
func _motivo_fichaje_bloqueado(j: Jugador) -> String: return _acciones_fichaje._motivo_fichaje_bloqueado(j)
func _intentar_fichar(j: Jugador, monto: int, sueldo: int) -> void: _acciones_fichaje._intentar_fichar(j, monto, sueldo)
func _pedir_informe_medico(j: Jugador) -> void: _acciones_fichaje._pedir_informe_medico(j)







