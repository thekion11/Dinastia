extends "res://ui/principal_p15.gd"
## [Capa 15/17 de `principal.gd`] _ready, _bloque_vecino, _rejilla, _fila_jugador, _fijar_modo_simulacion, _selector_modo_partido … (+8)

func _ready() -> void:
	BotonFx.activar(get_tree())
	## El mando se prepara ANTES de construir la interfaz: las acciones `ui_*`
	## tienen que existir cuando aparezca el primer boton para que el foco se
	## pueda mover con la cruceta desde el primer momento.
	_preparar_mando()
	## Las preferencias se leen ANTES de `_construir()`: la paleta decide el color
	## del fondo raiz y los FPS el limite del motor, y ambos se fijan ahi.
	_cargar_preferencias()
	Engine.max_fps = _fps_elegido
	if ContadorFps.visible_pref:
		ContadorFps.poner(get_tree(), true)
	_construir()
	if PedidoPartida.mundo_a_cargar != null:
		var cargada := PedidoPartida.mundo_a_cargar
		PedidoPartida.mundo_a_cargar = null
		_partida.entrar_cargada(cargada)
	elif PedidoPartida.mundo_pregenerado != null:
		var m := PedidoPartida.mundo_pregenerado
		PedidoPartida.mundo_pregenerado = null
		_partida.arrancar_con(m)
		var modo := m.roles.modo_actual() if m.roles != null else "dt"   ## (31-10) el modo ya aplicado (`PedidoPartida.aplicar`)
		if not m.prologo_visto:   ## tras el prólogo 3D la guía del taxi sobra (26-10)
			_guia.quizas(modo)
	else:
		_partida.nueva()

## Puentes (fase 6, paso 7): viven en `ui/principal/paneles_club.gd`.
func _bloque_vecino(paso: int) -> void: _paneles_club._bloque_vecino(paso)
func _rejilla(lista: VBoxContainer, columnas: int) -> GridContainer: return _paneles_club._rejilla(lista, columnas)
func _fila_jugador(g: GridContainer, j: Jugador, columnas: Array, colores: Array) -> void: _paneles_club._fila_jugador(g, j, columnas, colores)
func _fijar_modo_simulacion(comp: String, modo: String) -> void: _paneles_club._fijar_modo_simulacion(comp, modo)
func _selector_modo_partido(padre: Node) -> void: _paneles_club._selector_modo_partido(padre)
func _pintar_pendientes() -> void: _paneles_club._pintar_pendientes()
func _objetivos(mio: Club) -> Array[Jugador]: return _paneles_club._objetivos(mio)







func _process(_d: float) -> void:
	if not _pendientes.is_empty():
		_pintar_pendientes()
	## Las partículas del fondo del menú NO van encima de una vista 3D (ciudad,
	## estadio, partido): salían como «humo» sobre la cabeza del personaje,
	## donde estaba el cursor (13-10-2026).
	if _clima != null:
		var cam := get_viewport().get_camera_3d()
		var hay_3d := cam != null and cam.is_inside_tree() and cam.is_visible_in_tree()
		if _clima.visible == hay_3d:
			_clima.visible = not hay_3d


## Puentes (fase 6, paso 7): viven en `PanelesClub`.
func _pintar_equipacion(c: Club) -> void: _paneles_club._pintar_equipacion(c)
func _club_infra(c: Club) -> void: _paneles_club._club_infra(c)
func _club_carrera(_c: Club) -> void: _paneles_club._club_carrera(_c)
func _resolver(op: String) -> void: _paneles_club._resolver(op)
func _pintar_decision(e: Dictionary) -> void: _paneles_club._pintar_decision(e)





