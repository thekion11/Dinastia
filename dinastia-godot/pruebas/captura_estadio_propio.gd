extends Node
## Comprueba el botón nuevo "👁️ Ver mi estadio en 3D" en Club → Estadio: hasta
## ahora `VistaEstadio` solo se abría desde el partido en vivo, y para ver una
## reforma recién pagada había que esperar al próximo partido en casa.
##
##   godot --path . --rendering-driver opengl3 res://pruebas/captura_estadio_propio.tscn

const ESPERA := 14

var _n := 0
var _pantalla: Node

func _ready() -> void:
	_pantalla = load("res://escenas/principal.tscn").instantiate()
	add_child(_pantalla)

func _process(_d: float) -> void:
	_n += 1
	if _n == ESPERA:
		var mundo: Mundo = _pantalla.get("mundo")
		var tabs: TabContainer = _pantalla.get("_pestanas")
		for i in tabs.get_tab_count():
			if tabs.get_tab_title(i) == "Club":
				tabs.current_tab = i
				break
		var mio: Club = mundo.mi_club()
		mio.saldo = 999999999
		## Se cambia la FORMA a propósito -y a algo que casi nunca sale del hash
		## por defecto para un club de reputación alta ("herradura")-, para poder
		## distinguir a simple vista si el visor 3D respeta el diseño guardado o
		## si sigue mostrando el genérico de siempre. Antes de este arreglo,
		## `estadio.gd` llamaba a `club.perfil_estadio()` a secas y esta reforma
		## nunca se habría visto en el 3D, ni en el partido en vivo ni en el
		## botón nuevo -aunque la pestaña de texto sí la mostrara bien-.
		var problema: String = mundo.estadio.reformar(mio, {"forma": "herradura", "techo": "sin"}, mundo.obras)
		print("reforma aplicada: '%s' -> forma ahora %s" % [problema, mundo.estadio.ajustes.get("forma")])
		print("perfil_estadio_de(mio) dice forma=%s techo=%s" % [
			mundo.perfil_estadio_de(mio).get("forma"), mundo.perfil_estadio_de(mio).get("techo")])
		_pantalla.call("_pintar_estadio", mio)
		_guardar("res://pruebas/capturas/pantalla_estadio_boton.png")
	if _n == ESPERA + 4:
		## Pulsa el botón de verdad, buscándolo por texto -no llamando a la
		## función interna a secas-, para probar el mismo camino que sigue el
		## jugador.
		var lista: Control = _pantalla.get("_lista_estadio")
		var boton := _buscar_boton(lista, "Ver mi estadio en 3D")
		if boton == null:
			print("NO SE ENCONTRO el boton 'Ver mi estadio en 3D'")
			get_tree().quit()
			return
		print("boton encontrado, pulsando...")
		boton.pressed.emit()
	if _n == ESPERA + 10:
		var vista := _pantalla.get_children().filter(func(c): return c is VistaEstadio)
		print("VistaEstadio abierta = %s" % (not vista.is_empty()))
		_guardar("res://pruebas/capturas/pantalla_estadio_3d_abierto.png")
	if _n == ESPERA + 40:
		_guardar("res://pruebas/capturas/pantalla_estadio_3d_abierto_tarde.png")
		var hijos := _pantalla.get_children().filter(func(c): return c is VistaEstadio)
		if hijos.is_empty():
			print("NO HAY VistaEstadio para cerrar")
		else:
			print("emitiendo cerrado en VistaEstadio...")
			(hijos[0] as VistaEstadio).cerrado.emit()
	if _n == ESPERA + 46:
		var vista := _pantalla.get_children().filter(func(c): return c is VistaEstadio)
		print("VistaEstadio sigue abierta tras Volver = %s" % (not vista.is_empty()))
		var lista: Control = _pantalla.get("_lista_estadio")
		print("_lista_estadio visible tras Volver = %s" % (is_instance_valid(lista) and lista.is_visible_in_tree()))
		_guardar("res://pruebas/capturas/pantalla_estadio_despues_de_volver.png")
		get_tree().quit()

func _buscar_boton(n: Node, texto: String) -> Button:
	if n is Button and String((n as Button).text).contains(texto):
		return n
	for h in n.get_children():
		var r := _buscar_boton(h, texto)
		if r != null:
			return r
	return null

func _guardar(ruta: String) -> void:
	var img := get_viewport().get_texture().get_image()
	img.save_png(ruta)
	print("captura guardada: %s (%dx%d)" % [ruta, img.get_width(), img.get_height()])
