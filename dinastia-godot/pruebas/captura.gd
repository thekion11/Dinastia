extends Node
## Abre la pantalla principal, la deja con datos y guarda dos capturas: el
## plantel con una ficha propia abierta, y el mercado con la ficha de alguien de
## otro club, que es donde se ven las tres puertas del fichaje.
##
## OJO: esto NO puede correr con --headless. Sin ventana no hay framebuffer y la
## textura sale nula o negra; el visor 3D de este proyecto ya pago esa leccion.
##
##   godot --path . --rendering-driver opengl3 res://pruebas/captura.tscn

const ESPERA := 12   ## fotogramas antes de tocar nada: los Control se colocan solos

var _n := 0
var _pantalla: Node
var _vivo: PartidoVivo = null
## La cinematica del sorteo, para poder saltarla entre capturas.
var _scroll_ajustes: ScrollContainer = null
var _y_ajustes: int = -1
var _etiqueta_aspecto: Control = null
var _sorteo: Sorteo = null
## EL IDIOMA DE VERDAD, para devolverlo tal cual estaba. `Principal._ready()`
## ya cargó "user://preferencias.cfg" -el MISMO archivo que usa el juego real,
## no uno de prueba: este build de Godot no trae `--user-data-dir` para
## aislarlo (se probó, cuelga el proceso sin avisar)-, así que lo que sea que
## `Idiomas.idioma` valga aquí es lo que el jugador de verdad tiene elegido.
## Sin esto, la prueba de "en" más abajo (`_n == ESPERA + 31`) se queda pegada
## en el archivo real la próxima vez que alguien repinte Ajustes -que es
## justo lo que pasó el 11-9-2026: la partida de Gustavo amaneció en inglés
## sin que él tocara nada-.
var _idioma_real: String = "es"

func _ready() -> void:
	_pantalla = load("res://escenas/principal.tscn").instantiate()
	add_child(_pantalla)

func _process(_d: float) -> void:
	_n += 1
	## El sorteo salta solo cuando toca ronda de copa. Se cierra AQUÍ, cada
	## fotograma, y no dentro de `_guardar()`: `queue_free()` no libera hasta el
	## final del fotograma, así que cerrarlo en el mismo instante de la captura
	## habría salido igual de tapado.
	if _sorteo == null:
		_cerrar_sorteos()
	if _n == ESPERA:
		_idioma_real = Idiomas.idioma
		for i in 12:
			_pantalla.call("_avanzar_semana")
		var mio: Club = _pantalla.get("mundo").mi_club()
		var mejor: Jugador = mio.plantilla[0]
		for j in mio.plantilla:
			if j.ovr > mejor.ovr:
				mejor = j
		_pantalla.call("_ver_ficha", mejor)
	if _n == ESPERA + 6:
		_guardar("res://pruebas/pantalla.png")
		## Ahora el mercado: se cambia de pestana y se abre la ficha del primer
		## objetivo, que es de otro club y por tanto trae las tres puertas.
		var tabs: TabContainer = _pantalla.get("_pestanas")
		tabs.current_tab = 1
		var mio2: Club = _pantalla.get("mundo").mi_club()
		var objetivos: Array = _pantalla.call("_objetivos", mio2)
		if not objetivos.is_empty():
			_pantalla.call("_ver_ficha", objetivos[0])
	if _n == ESPERA + 12:
		_guardar("res://pruebas/pantalla_mercado.png")
		## Y el partido en directo, con el reloj corriendo y un titular ya
		## senalado para el cambio: es el estado en el que de verdad se usa.
		_pantalla.call("_dirigir")
		_vivo = _pantalla.get_children().filter(func(n): return n is PartidoVivo).front()
		if _vivo != null:
			for i in 34:
				_vivo.partido.simular_minuto()
			_vivo.set("_saliendo", _vivo.partido.once_local[9])
			_vivo.call("_poner_velocidad", 0)
			_vivo.call("_refrescar")
	if _n == ESPERA + 18:
		_guardar("res://pruebas/pantalla_partido.png")
		if _vivo != null:
			_vivo.call("_hasta_el_final")
			_vivo.queue_free()
		## La copa, con varias rondas ya jugadas.
		for i in 20:
			_pantalla.call("_avanzar_semana")
		var tabs2: TabContainer = _pantalla.get("_pestanas")
		## Se fuerza una decision pendiente y una rueda de prensa para que la
		## captura ensene el despacho con algo dentro, no vacio.
		var mun = _pantalla.get("mundo")
		if mun.prensa != null:
			mun.semana = 9
			for i in 60:
				if mun.prensa.hay_evento():
					break
				mun.prensa.sortear_evento()
		tabs2.current_tab = 9
		_pantalla.call("_refrescar")
	if _n == ESPERA + 24:
		## El pizarron tactico: es un dibujo, y un dibujo hay que MIRARLO.
		_pantalla.call("_ir_a_pestana", "Táctica")
	if _n == ESPERA + 26:
		_guardar("res://pruebas/pantalla_tactica.png")
		## EL MENU DE LA COMPETICION -columna izquierda-. Va ANTES del sorteo:
		## el sorteo tapa la pantalla entera y ya no dejaria abrir nada mas.
		_pantalla.call("_abrir_competicion")
	if _n == ESPERA + 30:
		_guardar("res://pruebas/pantalla_competicion.png")
		var comp = _pantalla.get_children().filter(func(n): return n is Competicion).front()
		if comp != null:
			comp.queue_free()
	if _n == ESPERA + 31:
		## AJUSTES CON UNA PALETA CLARA. De las nueve, las claras -papel, cuaderno-
		## son las unicas que pueden salir mal de verdad: si el texto no se tradujo
		## a la paleta, queda blanco sobre blanco y la pantalla sale en blanco. Y se
		## abre la seccion de Aspecto, que es donde viven las opciones nuevas.
		_pantalla.set("_paleta", "cuaderno")
		_pantalla.set("_secc_ajustes", "aspecto")
		## Y en ingles: si la tabla de idiomas no se aplicara, la captura saldria
		## en castellano y nadie se enteraria.
		Idiomas.idioma = "en"
		_pantalla.call("_aplicar_aspecto")
		_pantalla.call("_ir_a_pestana", "Ajustes")
		_pantalla.call("_refrescar")
	if _n == ESPERA + 34:
		_guardar("res://pruebas/pantalla_ajustes.png")
		_pantalla.set("_paleta", "bosque")
		Idiomas.idioma = _idioma_real
		_pantalla.call("_aplicar_aspecto")
		_pantalla.call("_refrescar")
	if _n == ESPERA + 36:
		## LA CINEMÁTICA DEL SORTEO. Se abre a mano con datos de verdad -tu
		## continental y tu club-, porque esperar a que caiga sola exigiría
		## simular media temporada en la captura.
		var mun2 = _pantalla.get("mundo")
		var conti = mun2.mi_continental()
		if conti != null:
			_sorteo = Sorteo.new()
			_sorteo.set_anchors_preset(Control.PRESET_FULL_RECT)
			_pantalla.add_child(_sorteo)
			if not conti.grupos.is_empty():
				_sorteo.abrir_grupos(conti.clave, conti.grupos, mun2.mi_club())
	## Dos capturas del sorteo: una con el bombo en marcha y otra con el cuadro
	## final ya puesto. Son dos momentos distintos y los dos hay que mirarlos.
	if _n == ESPERA + 49:
		_guardar("res://pruebas/pantalla_sorteo.png")
		if _sorteo != null:
			_sorteo.call("_saltar")
	if _n == ESPERA + 59:
		_guardar("res://pruebas/pantalla_sorteo_cuadro.png")
		if _sorteo != null:
			_sorteo.queue_free()
			_sorteo = null
		## EL CALENDARIO -pantalla nueva, pedida por el usuario-: la fecha
		## próxima, el botón de simular sin dirigir, y el resto de la
		## temporada con el escudo de cada rival.
		_pantalla.call("_ir_a_pestana", "Calendario")
	if _n == ESPERA + 61:
		_guardar("res://pruebas/pantalla_calendario.png")
		## SEGUNDA RED, además de la de `_n == ESPERA + 34`: si algo más
		## adelante en esta misma secuencia -el sorteo, el calendario- llegara
		## a repintar Ajustes con el idioma todavía en inglés, esto lo deja
		## bien puesto ANTES de que el proceso muera. Es la última línea que
		## corre, y por eso es la única que de verdad puede prometer que el
		## archivo real queda como se encontró.
		Idiomas.idioma = _idioma_real
		_pantalla.set("_secc_ajustes", "aspecto")
		_pantalla.call("_aplicar_aspecto")
		_pantalla.call("_ir_a_pestana", "Ajustes")
		_pantalla.call("_refrescar")
		get_tree().quit()


## Cierra la cinemática del sorteo si está abierta. Se llama antes de cada
## captura porque el sorteo salta SOLO cuando toca ronda de copa -es lo que se
## quiere en el juego- pero aquí tapaba la pantalla que se venía a fotografiar.
func _cerrar_sorteos() -> void:
	for n in _pantalla.get_children():
		if n is Sorteo and n != _sorteo:
			n.queue_free()

func _guardar(ruta: String) -> void:
	var img := get_viewport().get_texture().get_image()
	img.save_png(ruta)
	print("captura guardada: %s (%dx%d)" % [ruta, img.get_width(), img.get_height()])
