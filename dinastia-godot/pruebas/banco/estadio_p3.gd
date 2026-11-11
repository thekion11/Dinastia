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
	## CONO POR LA BOCA DEL TÚNEL (sesión 7): con la boca a la vista solo se dibuja lo que cae dentro de la pirámide cámara→boca y más allá de ella.
	var cajas: Dictionary = {}
	for par in [["detras", Vector3(0, 1, 70)], ["enfrente", Vector3(0, 1, -30)], ["lateral", Vector3(60, 1, -5)]]:
		var mi := MeshInstance3D.new()
		var bm := BoxMesh.new()
		bm.size = Vector3(10, 10, 10)
		mi.mesh = bm
		mi.position = par[1]
		mi.name = "Caja_" + String(par[0])
		raiz.add_child(mi)
		cajas[par[0]] = mi
	cam.position = Vector3(0.0, 1.6, 30.0)
	cam.look_at_from_position(cam.position, Vector3(0.0, 1.6, 10.0), Vector3.UP)   ## en el túnel, hacia el campo
	OcultarEstadioDentro.actualizar(explorador, 0, "Túnel", cam, datos)
	_comprobar(cajas["enfrente"].visible and not cajas["detras"].visible and not cajas["lateral"].visible, "cono: se dibuja lo de enfrente; lo de detrás y lo de un lado, no")
	OcultarEstadioDentro.actualizar(explorador, 0, "Túnel", cam, datos)
	_comprobar(cajas["enfrente"].visible and not cajas["detras"].visible, "cono: repetir no cambia nada")
	OcultarEstadioDentro.actualizar(explorador, 0, "Campo", cam, datos)
	_comprobar(cajas["enfrente"].visible and cajas["detras"].visible and cajas["lateral"].visible, "al salir al campo el cono devuelve todo")
	OcultarEstadioDentro.actualizar(explorador, 0, "Túnel", cam, datos)
	cam.look_at_from_position(cam.position, Vector3(0.0, 1.6, 50.0), Vector3.UP)   ## de espaldas: la boca sale de la vista
	OcultarEstadioDentro.actualizar(explorador, 0, "Túnel", cam, datos)
	OcultarEstadioDentro.actualizar(explorador, 0, "Campo", cam, datos)
	OcultarEstadioDentro.devolver(explorador)
	_comprobar(cajas["enfrente"].visible and cajas["detras"].visible and cajas["lateral"].visible, "tras el cono y la ocultación total, devolver deja todo visible")
	for c in cajas.values():
		c.queue_free()
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

## (10-11) El cajón de ajustes se llena al abrirlo por primera vez (`CajonAjustes.contenido`): antes del primer `abrir` está vacío, después trae lo mismo, y abrirlo otra vez no lo duplica. Sin `contenido`, como siempre.
func _probar_cajon_perezoso() -> void:
	_titulo("CAJÓN DE AJUSTES PEREZOSO (10-11): se llena al abrirlo")
	var padre := Control.new()
	add_child(padre)
	var llamadas := [0]
	var c := CajonAjustes.crear(padre, "banco_perezoso", func(_cj: CajonAjustes) -> void: llamadas[0] += 1)
	_comprobar(llamadas[0] == 0, "antes del primer abrir el cajón no ha ejecutado su contenido (llamadas=%d)" % llamadas[0])
	c.abrir(false)
	_comprobar(llamadas[0] == 1, "al abrir ejecuta el contenido (llamadas=%d)" % llamadas[0])
	c.cerrar(false)
	c.abrir(false)
	_comprobar(llamadas[0] == 1, "abrirlo otra vez no lo vuelve a llenar (llamadas=%d)" % llamadas[0])
	c.cerrar(false)   ## el cajón recuerda si quedó abierto (`ajustes.cfg`): se deja cerrado para que la prueba se pueda repetir
	## Recordado como abierto (`ajustes.cfg`): abre DENTRO de `crear` y el contenido ya recibe su cajón (antes reventaba: «seccion en Nil»).
	c.abrir(false)   ## (se guarda abierto)
	var recibido := [null]
	var e := CajonAjustes.crear(padre, "banco_perezoso", func(cj: CajonAjustes) -> void: recibido[0] = cj)
	_comprobar(e != null and recibido[0] == e, "con el cajón recordado abierto, el contenido recibe el propio cajón")
	e.cerrar(false)
	var d := CajonAjustes.crear(padre, "banco_clasico")
	d.seccion("A")
	d.boton("b", func() -> void: pass)
	_comprobar(d._lista.get_child_count() == 2, "sin `contenido` se llena desde fuera, como siempre")
	padre.queue_free()

## AVATARES (11-11, sesión 12): solo modelos realistas elegibles, partidas viejas con un modelo quitado caen al atleta,
## el avatar regalo no va en los builds públicos y el personal del club tiene apariencia propia, única y reservada.
func _probar_avatares_realistas() -> void:
	_titulo("AVATARES: SOLO REALISTAS, AVATAR REGALO FUERA DE LO PÚBLICO, PERSONAL DEL CLUB ÚNICO")
	for solo_personal: String in ["mh_swat", "mm_soldier", "mh_punk", "mm_punk"]:
		_comprobar(not FutbolistaQ.todos_ajenos().has(solo_personal) and not FutbolistaQ.modelo_valido(solo_personal), "«%s» NO es elegible por el jugador" % solo_personal)
		_comprobar(FutbolistaQ.ajeno_disponible(solo_personal) and PersonalEstadio.MODELO_PERSONAL.values().any(func(v: Array) -> bool: return solo_personal in v), "«%s» existe y lo usa el personal del club" % solo_personal)
	for quitado: String in ["campesino", "explorador", "kk_barbaro", "kk_mago", "kk_esq_guerrero", "vrm_arla", "vrm_starter", "mh_farmer", "mh_king", "mm_witch", "mm_scifi"]:
		_comprobar(not FutbolistaQ.modelo_valido(quitado), "«%s» ya no es un modelo válido" % quitado)
		_comprobar(String(PersonajeDT.aspecto({"modelo": quitado})["modelo"]) == "", "una partida vieja con «%s» vuelve al atleta" % quitado)
	for k: String in FutbolistaQ.todos_ajenos():
		_comprobar(FutbolistaQ.ajeno_disponible(k), "«%s» (realista) está en el proyecto" % k)
	for carpeta: String in ["kaykit", "vrm", "Skins"]:
		_comprobar(not DirAccess.dir_exists_absolute("res://assets/characters/" + carpeta), "la carpeta de no realistas «%s» ya no está" % carpeta)
	## El avatar regalo: excluido de los 6 presets (licencia y cara sin confirmar).
	var cfg := FileAccess.get_file_as_string("res://export_presets.cfg")
	_comprobar(not cfg.contains("avatar_regalo"), "el avatar regalo ya NO está excluido de los presets (licencia confirmada por el dueño, 11-11)")
	if AvatarRegalo.disponible():
		var padre := Node3D.new()
		add_child(padre)
		var d := PersonajeDT.crear(padre, {"modelo": AvatarRegalo.CLAVE, "altura": 1.80})
		_comprobar(not d.is_empty() and d.has("avatar") and d.has("anim"), "el avatar regalo se arma con el cuerpo de animación del juego")
		if not d.is_empty():
			var rt := (d["avatar"] as Node).find_child("AvatarRegaloRetarget", true, false) as AvatarRegaloRetarget
			_comprobar(rt != null and rt.pares() >= 50, "su retarget cubre cadera, columna, brazos, piernas y dedos (%d huesos)" % (rt.pares() if rt != null else 0))
		padre.queue_free()
	## Personal del club: determinista, sin repetirse, reservado.
	var claves: Array = PersonalEstadio.PUESTOS.keys()
	var mujeres := {"secretaria": true, "cocinera": true, "medico": false}
	var a1: Dictionary = AparienciaPersonal.generar("CHI-01", claves, mujeres)
	var a2: Dictionary = AparienciaPersonal.generar("CHI-01", claves, mujeres)
	var b1: Dictionary = AparienciaPersonal.generar("ESP-07", claves, mujeres)
	_comprobar(a1.size() == claves.size(), "una apariencia por puesto (%d)" % a1.size())
	_comprobar(str(a1) == str(a2), "es determinista: el mismo club da las mismas caras")
	_comprobar(str(a1) != str(b1), "otro club (de otro país) da otras")
	for g: Dictionary in [a1, b1]:
		var firmas := {}
		var reservados := true
		for c: String in g:
			firmas[AparienciaPersonal.firma(g[c])] = true
			reservados = reservados and AparienciaPersonal.es_reservado(String((g[c] as Dictionary)["color_pelo"]))
		_comprobar(firmas.size() == g.size(), "ninguna se repite entre las personas del club (%d distintas)" % firmas.size())
		_comprobar(reservados, "todas llevan color de pelo reservado al personal")
	_comprobar(String((a1["secretaria"] as Dictionary)["cuerpo"]) == "female" and String((a1["portero"] as Dictionary)["cuerpo"]) == "male", "el cuerpo sigue al nombre")
	var ninguno_editable := true
	for c: String in PersonajeDT.COLORES_PELO:
		ninguno_editable = ninguno_editable and not AparienciaPersonal.es_reservado(c)
	_comprobar(ninguno_editable, "el editor del jugador no ofrece ningún color reservado")
	var asp_j := PersonajeDT.aspecto({"color_pelo": AparienciaPersonal.COLORES_PELO_PERSONAL[0]})
	_comprobar(not AparienciaPersonal.es_reservado(String(asp_j["color_pelo"])), "un personaje de jugador con color reservado cae al castaño: no puede elegirlo")
