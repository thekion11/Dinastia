extends "res://pruebas/banco/estadio_p2.gd"
## [Capa extra de `estadio.gd`, 10-11] _probar_ocultar_estadio_dentro, _probar_precarga_menu

## (10-11, rendimiento en móvil) Dentro del edificio del club (plantas distintas de la 0) no se dibuja el estadio de fuera; al volver a la 0 queda como estaba (lo que ya estaba oculto, oculto).
func _probar_ocultar_estadio_dentro() -> void:
	_titulo("CLUB A PIE: SIN ESTADIO DE FUERA DENTRO DEL EDIFICIO")
	var raiz := Node3D.new()
	var grada := Node3D.new()
	grada.name = "Grada"
	var apagado := Node3D.new()
	apagado.name = "YaOculto"
	apagado.visible = false
	var tunel := Node3D.new()
	tunel.name = "TunelVestuario"
	var calle := Node3D.new()
	calle.name = "Exterior"
	var luz := OmniLight3D.new()
	var explorador := Node3D.new()
	for n: Node in [grada, apagado, tunel, calle, luz, explorador]:
		raiz.add_child(n)
	add_child(raiz)
	OcultarEstadioDentro.actualizar(explorador, 0)
	_comprobar(grada.visible and tunel.visible, "en la planta 0 no se oculta nada")
	OcultarEstadioDentro.actualizar(explorador, -1)
	_comprobar(not grada.visible, "en un sótano la grada no se dibuja")
	_comprobar(tunel.visible and calle.visible and luz.visible and explorador.visible, "el edificio, la calle, las luces y el explorador siguen")
	OcultarEstadioDentro.actualizar(explorador, 2)
	_comprobar(not grada.visible, "subir de planta no la devuelve")
	OcultarEstadioDentro.actualizar(explorador, 0)
	_comprobar(grada.visible and not apagado.visible, "al volver a la planta 0 vuelve la grada y lo que ya estaba oculto sigue oculto")
	OcultarEstadioDentro.actualizar(explorador, 1)
	OcultarEstadioDentro.devolver(explorador)
	_comprobar(grada.visible, "al cerrar el recorrido se devuelve el estadio")
	## OCLUSIÓN POR SALA (10-11, sesión 7): en el vestuario el estadio solo se dibuja si la boca del túnel (plano z = 40) está en el campo de visión.
	var cam := Camera3D.new()
	explorador.add_child(cam)
	cam.position = Vector3(0.0, 1.6, 46.0)
	var datos := {"x0": 0.0, "z_out": 40.0}
	cam.look_at_from_position(cam.position, Vector3(0.0, 1.6, 30.0), Vector3.UP)   ## hacia la boca
	OcultarEstadioDentro.actualizar(explorador, 0, "Vestuario", cam, datos)
	_comprobar(grada.visible, "vestuario mirando a la boca del túnel: el estadio se dibuja")
	cam.look_at_from_position(cam.position, Vector3(0.0, 1.6, 60.0), Vector3.UP)   ## de espaldas
	OcultarEstadioDentro.actualizar(explorador, 0, "Vestuario", cam, datos)
	_comprobar(not grada.visible and tunel.visible and not apagado.visible, "vestuario de espaldas a la boca: el estadio se oculta (y el edificio sigue)")
	cam.look_at_from_position(cam.position, Vector3(0.0, 1.6, 30.0), Vector3.UP)
	OcultarEstadioDentro.actualizar(explorador, 0, "Vestuario", cam, datos)
	_comprobar(grada.visible and not apagado.visible, "al volver a mirar a la boca vuelve el estadio")
	cam.look_at_from_position(cam.position, Vector3(0.0, 1.6, 60.0), Vector3.UP)
	OcultarEstadioDentro.actualizar(explorador, 0, "Túnel", cam, datos)
	_comprobar(grada.visible, "en el túnel (no es sala cerrada) nunca se oculta")
	cam.look_at_from_position(Vector3(0.0, 1.6, 40.8), Vector3(0.0, 1.6, 60.0), Vector3.UP)
	cam.position = Vector3(0.0, 1.6, 40.8)
	OcultarEstadioDentro.actualizar(explorador, 0, "Vestuario", cam, datos)
	_comprobar(grada.visible, "pegado a la boca siempre se ve")
	## TÚNEL y VENTANAS (sesión 7): el túnel oculta estadio y calle si no se ve la boca al campo (z_boca = 20); una planta alta conserva la calle solo con una ventana a la vista.
	datos = {"x0": 0.0, "z_out": 40.0, "z_boca": 20.0, "z_fin": 60.0}
	cam.position = Vector3(0.0, 1.6, 30.0)
	cam.look_at_from_position(cam.position, Vector3(0.0, 1.6, 10.0), Vector3.UP)   ## en el túnel, hacia el campo
	OcultarEstadioDentro.actualizar(explorador, 0, "Túnel", cam, datos)
	_comprobar(grada.visible and calle.visible, "túnel mirando al campo: se dibuja todo")
	cam.look_at_from_position(cam.position, Vector3(0.0, 1.6, 50.0), Vector3.UP)   ## de espaldas al campo
	OcultarEstadioDentro.actualizar(explorador, 0, "Túnel", cam, datos)
	_comprobar(not grada.visible and not calle.visible and tunel.visible, "túnel de espaldas al campo: sin estadio ni calle (el edificio sigue)")
	OcultarEstadioDentro.actualizar(explorador, 0, "Campo", cam, datos)
	_comprobar(grada.visible and calle.visible, "en el campo vuelve todo")
	cam.position = Vector3(0.0, 5.6, 50.0)
	cam.look_at_from_position(cam.position, Vector3(0.0, 5.6, 70.0), Vector3.UP)   ## planta 1 mirando a las ventanas del fondo (z 60,31)
	OcultarEstadioDentro.actualizar(explorador, 1, "Despacho del presidente", cam, datos)
	_comprobar(not grada.visible and calle.visible, "planta 1 con ventana a la vista: sin estadio, con calle")
	cam.look_at_from_position(cam.position, Vector3(0.0, 5.6, 30.0), Vector3.UP)   ## de espaldas a las ventanas
	OcultarEstadioDentro.actualizar(explorador, 1, "Despacho del presidente", cam, datos)
	_comprobar(not grada.visible and not calle.visible, "planta 1 sin ventana a la vista: tampoco calle")
	OcultarEstadioDentro.actualizar(explorador, -1, "Utilería", cam, datos)
	_comprobar(not grada.visible and not calle.visible, "un sótano no tiene ventanas: sin calle")
	## PLANTAS DEL EDIFICIO (sesión 7): cada planta cuelga de «Planta_p»; dentro de una planta solo se dibuja ella, en el túnel/vestuario ninguna, en el campo y viajando todas.
	var edif := Node3D.new()
	edif.add_to_group("edificio_club")
	var pls: Dictionary = {}
	for pp in [-1, 1, 2]:
		var nd := Node3D.new()
		nd.name = "Planta_%d" % pp
		nd.set_meta("planta", pp)
		edif.add_child(nd)
		pls[pp] = nd
	tunel.add_child(edif)
	OcultarEstadioDentro.actualizar(explorador, 1, "Oficina del DT", cam, datos)
	_comprobar(pls[1].visible and not pls[2].visible and not pls[-1].visible, "dentro de la planta 1 solo se dibuja la planta 1")
	OcultarEstadioDentro.actualizar(explorador, 1, "Pasillo", cam, datos, true)
	_comprobar(pls[1].visible and pls[2].visible and pls[-1].visible, "viajando en el ascensor se dibujan todas")
	OcultarEstadioDentro.actualizar(explorador, 0, "Túnel", cam, datos)
	_comprobar(not pls[1].visible and not pls[2].visible and not pls[-1].visible, "en el túnel no se dibuja ninguna planta")
	OcultarEstadioDentro.actualizar(explorador, 0, "Campo", cam, datos)
	_comprobar(pls[1].visible and pls[2].visible and pls[-1].visible, "en el campo vuelven todas (se ve la fachada)")
	OcultarEstadioDentro.actualizar(explorador, 2, "Sala de prensa", cam, datos)
	pls[2].visible = true
	OcultarEstadioDentro.devolver(explorador)
	_comprobar(pls[1].visible and pls[2].visible and pls[-1].visible, "al cerrar el recorrido se devuelven todas")
	edif.queue_free()
	OcultarEstadioDentro.devolver(explorador)
	raiz.queue_free()

## (10-11, arranque del menú) Los scripts que la precarga del menú compila en su hilo existen (si un script se borra o se renombra, la lista se queda coja sin que nada falle: aquí sí).
func _probar_precarga_menu() -> void:
	_titulo("PRECARGA: LOS SCRIPTS DEL MENÚ EXISTEN")
	_comprobar(Precarga.SCRIPTS_MENU.size() > 20, "hay lista de scripts del menú (%d)" % Precarga.SCRIPTS_MENU.size())
	var faltan: Array[String] = []
	for r: String in Precarga.SCRIPTS_MENU:
		if not ResourceLoader.exists(r):
			faltan.append(r)
	_comprobar(faltan.is_empty(), "todos existen (faltan: %s)" % str(faltan))
