extends BaseIdea
## PRUEBA DE LA PANTALLA DE PAÍS (fase 1, etapa 3): `PantallaPais` y sus piezas.
##   · los datos: 24 países con nombre completo, nombre oficial, continente y 5 monumentos;
##   · los 120 monumentos se DIBUJAN de verdad (sin polígonos que Godot no sepa
##     triangular) y caben en su hueco;
##   · la pantalla: país inicial, nombre completo en grande y en el rótulo del globo,
##     rotación de monumentos cada 30 s, teclado, confirmación y lo que emite;
##   · «si creas un club, no se muestran los demás», y con un mundo generado se elige un
##     club de verdad (su id viaja en `club_id`).
## Necesita frames (el dibujo de las siluetas ocurre en `_draw`), así que lleva su propio
## `_ready` asíncrono en vez del `_probar()` síncrono de la base.

func _ready() -> void:
	get_window().size = Vector2i(1280, 720)
	await get_tree().process_frame
	_titulo("PANTALLA DE PAÍS (f1g): datos")
	_datos()
	_titulo("PANTALLA DE PAÍS (f1g): los 120 monumentos se dibujan y caben")
	await _dibujos()
	_titulo("PANTALLA DE PAÍS (f1g): la pantalla, modo normal")
	await _pantalla_normal()
	_titulo("PANTALLA DE PAÍS (f1g): crear club no enseña clubes")
	await _pantalla_crear()
	_titulo("PANTALLA DE PAÍS (f1g): con mundo generado se elige club de verdad")
	await _pantalla_con_mundo()
	print("")
	print("===== FIN. %d fallos =====" % _fallos.size())
	get_tree().quit(0 if _fallos.is_empty() else 1)

func _datos() -> void:
	var todos := PaisDatos.todos()
	_comprobar(todos.size() == 24, "24 países en la lista (%d)" % todos.size())
	var malos: Array[String] = []
	for p: String in todos:
		var m := PaisDatos.monumentos(p)
		var nombres := {}
		for f: Array in m:
			nombres[f[0]] = true
		if m.size() != 5 or nombres.size() != 5 or not PaisDatos.OFICIAL.has(p) \
				or not Globo3D.GLOBO_PAIS.has(p) or PaisDatos.continente_de(p) == "" or PaisDatos.nombre(p) == p:
			malos.append(p)
	_comprobar(malos.is_empty(), "cada país: nombre completo, oficial, continente, pin y 5 monumentos distintos %s" % [malos])
	_comprobar(PaisDatos.nombre("KOR") == "Corea del Sur" and PaisDatos.nombre("USA") == "Estados Unidos",
		"nombre completo, no la abreviatura de las selecciones")
	_comprobar(not PaisDatos.tiene_liga("VEN") and PaisDatos.tiene_liga("CHI") and PaisDatos.tiene_liga("JPN"),
		"Venezuela sin liga; Chile y Japón con liga")
	_comprobar(PaisDatos.estrellas("ENG") == 5 and PaisDatos.estrellas("BOL") == 1 and PaisDatos.estrellas("CHI") == 2,
		"nivel de liga: Inglaterra 5, Chile 2, Bolivia 1")
	_comprobar(Globo3D.CAPITAL["AUS"] == "Canberra", "la capital de Australia es Canberra")

func _dibujos() -> void:
	var lienzos: Array = []
	for p: String in PaisDatos.todos():
		for f: Array in PaisDatos.monumentos(p):
			var mo := PaisMonumento.new()
			mo.size = Vector2(420, 260)
			mo.poner(String(f[1]), String(f[2]))
			add_child(mo)
			lienzos.append([mo, "%s/%s" % [p, f[0]]])
	## Un frame para que pasen los dibujos que encoló `poner()` y no se mezclen al medir.
	await get_tree().process_frame
	PaisTrazo.validar = true
	var sin_dibujo: Array[String] = []
	var rotos: Array[String] = []
	var salidos: Array[String] = []
	## Uno a uno, para saber cuál falla: se redibuja y se mira lo que midió el lápiz.
	for par: Array in lienzos:
		var mo: PaisMonumento = par[0]
		PaisTrazo.reiniciar_medida()
		mo.queue_redraw()
		await get_tree().process_frame
		if not mo.dibujado:
			sin_dibujo.append(par[1])
		if PaisTrazo.malos > 0:
			rotos.append("%s (%d)" % [par[1], PaisTrazo.malos])
		var c := PaisTrazo.caja
		var hueco := Rect2(Vector2(-8, -8), mo.size + Vector2(16, 10))
		if not hueco.encloses(c):
			salidos.append("%s %s" % [par[1], c])
	PaisTrazo.validar = false
	_comprobar(sin_dibujo.is_empty(), "los 120 tipos/variantes tienen dibujo %s" % [sin_dibujo])
	_comprobar(rotos.is_empty(), "ningún polígono sin triangular %s" % [rotos])
	_comprobar(salidos.is_empty(), "cada silueta cabe en su hueco %s" % [salidos])
	for par: Array in lienzos:
		(par[0] as Node).queue_free()

## Como la monta el orquestador: dentro de un Control a pantalla completa.
func _nueva(estado: Dictionary) -> PantallaPais:
	var caja := Control.new()
	add_child(caja)
	caja.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var s := PantallaPais.new()
	s.configurar(estado)
	caja.add_child(s)
	return s

func _pantalla_normal() -> void:
	var s := _nueva({"modo": "dt"})
	await get_tree().process_frame
	s.sin_animaciones()
	var f := s.fondo()
	var vp := get_viewport().get_visible_rect().size
	_comprobar(s.size == vp and f.size == vp, "la pantalla y su fondo ocupan la ventana entera (%s / %s)" % [s.size, vp])
	_comprobar(s.globo().size.x > 300 and s.globo().size.y > 300 and s.ficha().size.y > 300,
		"el globo y la ficha tienen tamaño de verdad (%s, %s)" % [s.globo().size, s.ficha().size])
	_comprobar(s.pais == "CHI" and not s.crear, "empieza en Chile, modo normal")
	_comprobar(s.get("_nombre").text == "Chile" and s.get("_oficial").text == "República de Chile",
		"el nombre completo y el oficial, en grande")
	var rot: Label3D = s.globo().get("_rotulos")["CHI"]
	_comprobar(rot.text == "Chile", "el rótulo del globo dice el nombre completo del elegido")
	_comprobar(f.pais == "CHI" and f.indice == 0 and String(f.monumento_actual()[0]) == "Moáis de Rapa Nui",
		"de fondo la bandera de Chile y su primer monumento")
	_comprobar(s.get("_rotulo_mon").text == "Moáis de Rapa Nui", "el rótulo del monumento a la vista")
	## El reloj de 30 s (con animar apagado no corre solo: se enciende para medirlo).
	f.animar = true
	f._process(29.0)
	_comprobar(f.indice == 0, "a los 29 s sigue el mismo monumento")
	f._process(1.5)
	_comprobar(f.indice == 1 and s.get("_rotulo_mon").text == "Torres del Paine", "a los 30 s rota al segundo")
	for i in 4:
		f._process(30.0)
	_comprobar(f.indice == 0, "tras los 5, vuelve al primero")
	f.animar = false
	_comprobar(s.ficha().clubes_listados.size() == 16, "modo normal: se ven los 16 clubes de primera (%d)" % s.ficha().clubes_listados.size())
	## Cambiar de país desde la lista.
	(s.get("_lista") as PaisLista).elegido.emit("JPN")
	_comprobar(s.pais == "JPN" and s.get("_nombre").text == "Japón" and f.pais == "JPN" and f.indice == 0,
		"elegir Japón cambia nombre, fondo y vuelve al primer monumento")
	_comprobar(rot.text == "CHI" and (s.globo().get("_rotulos")["JPN"] as Label3D).text == "Japón",
		"el rótulo de Chile vuelve a su código y el de Japón se nombra")
	_comprobar(s.globo().pais_actual == "JPN", "el globo viaja a Japón")
	## Teclado: abajo pasa al siguiente de la lista (Japón → Corea del Sur).
	var ev := InputEventAction.new()
	ev.action = "ui_down"
	ev.pressed = true
	s._unhandled_input(ev)
	_comprobar(s.pais == "KOR", "flecha abajo: el siguiente país de la lista (%s)" % s.pais)
	## Venezuela no tiene liga: no se puede confirmar.
	s.call("_elegir", "VEN")
	s.pedir_confirmacion()
	_comprobar(s.get("_btn_confirmar").disabled and not s.confirmacion().visible, "sin liga no se confirma")
	## Confirmar Francia: primero la tarjeta de confirmación, luego la señal.
	s.call("_elegir", "FRA")
	var recibido: Array = []
	s.terminado.connect(func(d: Dictionary) -> void: recibido.append(d))
	s.pedir_confirmacion()
	_comprobar(s.confirmacion().visible and recibido.is_empty(), "confirmar abre la tarjeta y aún no emite")
	s.confirmacion().aceptado.emit()
	_comprobar(recibido.size() == 1 and String(recibido[0].get("pais", "")) == "FRA",
		"al aceptar emite terminado({\"pais\": \"FRA\"}) %s" % [recibido])
	_comprobar(not (recibido[0] as Dictionary).has("club_id") if recibido.size() == 1 else false,
		"sin mundo no hay id de club que emitir")
	var volvio := [false]
	s.volver.connect(func() -> void: volvio[0] = true)
	var esc := InputEventAction.new()
	esc.action = "ui_cancel"
	esc.pressed = true
	s._unhandled_input(esc)
	_comprobar(volvio[0], "Esc emite volver()")
	s.get_parent().queue_free()

func _pantalla_crear() -> void:
	var s := _nueva({"modo": "creador", "pais": "ARG"})
	await get_tree().process_frame
	s.sin_animaciones()
	_comprobar(s.crear and s.pais == "ARG", "modo crear club y país inicial del estado (Argentina)")
	var ficha := s.ficha()
	var con_club := 0
	for n in ficha.find_children("*", "Button", true, false):
		if (n as Button).has_meta("club"):
			con_club += 1
	_comprobar(ficha.clubes_listados.is_empty() and con_club == 0, "crear club: no existe ni un botón de club ajeno")
	_comprobar(not s.datos().has("club_id") and s.datos()["pais"] == "ARG", "emite solo el país")
	_comprobar(PantallaPais.crea_club({"modo": {"id": "creador"}}) and PantallaPais.crea_club({"crear": true})
		and not PantallaPais.crea_club({"modo": "dt"}), "lee el modo venga como venga")
	s.get_parent().queue_free()

func _pantalla_con_mundo() -> void:
	var m := Mundo.new()
	m.generar(["CHI", "ARG"], 4242)
	var s := _nueva({"modo": "dt", "mundo": m, "pais": {"pais": "ARG"}})
	await get_tree().process_frame
	s.sin_animaciones()
	var primera: Liga = null
	for l: Liga in m.ligas:
		if l.pais == "ARG" and l.division() == 1:
			primera = l
	_comprobar(s.pais == "ARG" and primera != null, "empieza en Argentina (país dentro de un diccionario)")
	_comprobar(s.datos().get("club_id", "") == primera.clubes[0].id, "por defecto, el primero de su primera división")
	var otro: Club = primera.clubes[3]
	for n in s.ficha().find_children("*", "Button", true, false):
		if n.get_meta("club", null) == otro:
			(n as Button).pressed.emit()
	_comprobar(s.datos().get("club_id", "") == otro.id, "tocar otro club cambia el id que se emite (%s)" % otro.nombre)
	s.pedir_confirmacion()
	var texto: String = (s.confirmacion().get("_texto") as Label).text
	_comprobar(texto.contains(otro.nombre), "la confirmación nombra el club elegido («%s»)" % texto)
	s.get_parent().queue_free()
