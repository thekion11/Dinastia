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
	await _pantalla_ligas()
	_titulo("PANTALLA DE PAÍS (f1g): crear club no enseña clubes")
	await _pantalla_crear()
	_titulo("PANTALLA DE PAÍS (f1g): con mundo generado se elige club de verdad")
	await _pantalla_con_mundo()
	print("")
	print("===== FIN. %d fallos =====" % _fallos.size())
	get_tree().quit(0 if _fallos.is_empty() else 1)

func _datos() -> void:
	var todos := PaisDatos.todos()
	## 24 al nacer la pantalla (25-10); la sesión 6 sumó países el 26-10. Lo que
	## importa es que la lista no se vacíe ni pierda los de siempre, no la cifra.
	_comprobar(todos.size() >= 24 and "CHI" in todos and "ESP" in todos and "JPN" in todos,
		"la lista conserva al menos los 24 países de siempre (%d)" % todos.size())
	var malos: Array[String] = []
	for p: String in todos:
		var m := PaisDatos.monumentos(p)
		var nombres := {}
		for f: Array in m:
			nombres[f[0]] = true
		## (15-11) Los 85 países de `PaisDatosExtra` entran sin monumentos ni nombre oficial (pendiente): se les pide nombre, continente, pin y capital.
		var extra := PaisDatosExtra.EXTRA.has(p)
		if (not extra and (m.size() != 5 or nombres.size() != 5 or not PaisDatos.OFICIAL.has(p))) \
				or not Globo3D.tiene(p) or Globo3D.capital(p) == "?" or PaisDatos.continente_de(p) == "" or PaisDatos.nombre(p) == p:
			malos.append(p)
	_comprobar(malos.is_empty(), "cada país: nombre completo, continente, pin y capital; los 50 de siempre, además oficial y 5 monumentos distintos %s" % [malos])
	_comprobar(PaisDatos.todos().size() == LigasActivas.todos().size() and LigasActivas.todos().all(func(x: String) -> bool: return PaisDatos.existe(x)),
		"están TODOS los países con liga (%d) en la lista y el globo" % LigasActivas.todos().size())
	_comprobar(PaisDatos.nombre("KOR") == "Corea del Sur" and PaisDatos.nombre("USA") == "Estados Unidos",
		"nombre completo, no la abreviatura de las selecciones")
	## (10-11) Ya TODOS los países del selector tienen liga: para ejercer la rama «sin liga» se quita Venezuela de la tabla un momento y se devuelve.
	var tabla_ligas: Dictionary = Datos.tabla("PAISES_LIGAS")
	var liga_ven: Variant = tabla_ligas.get("VEN")
	tabla_ligas.erase("VEN")
	_comprobar(not PaisDatos.tiene_liga("VEN") and PaisDatos.tiene_liga("CHI") and PaisDatos.tiene_liga("JPN"),
		"sin la liga de Venezuela en la tabla, Venezuela no tiene liga; Chile y Japón sí")
	tabla_ligas["VEN"] = liga_ven
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

## (15-11, pedido del dueño) Con solo España e Italia elegidas en «Ligas activas», la pantalla de país no deja elegir otro país.
func _pantalla_ligas() -> void:
	var s := _nueva({"modo": "dt", "pais": "CHI", "ligas": {"paises": ["ESP", "ITA"]}})
	await get_tree().process_frame
	s.sin_animaciones()
	var lista := s.get("_lista") as PaisLista
	_comprobar(s.pais == "ESP", "Chile no está entre las ligas elegidas: empieza en el primero que sí (%s)" % s.pais)
	_comprobar(lista.boton("ESP").visible and lista.boton("ITA").visible and not lista.boton("CHI").visible and not lista.boton("JPN").visible,
		"la lista enseña solo España e Italia")
	lista.elegido.emit("JPN")
	_comprobar(s.pais == "ESP", "elegir un país sin su liga no hace nada")
	_comprobar(not s.globo().se_puede("CHI") and s.globo().se_puede("ITA"), "en el globo, el pin de Chile no responde y el de Italia sí")
	var ev := InputEventAction.new()
	ev.action = "ui_down"
	ev.pressed = true
	s._unhandled_input(ev)
	_comprobar(s.pais == "ITA", "flecha abajo salta a Italia, sin pasar por los no elegidos (%s)" % s.pais)
	s._unhandled_input(ev)
	_comprobar(s.pais == "ESP", "y vuelve a España (%s)" % s.pais)
	s.get_parent().queue_free()
	await get_tree().process_frame

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
	var segunda_chi: int = (Datos.tabla("DATA_P2") as Array).size()
	_comprobar(s.ficha().clubes_listados.size() == 16 + segunda_chi and segunda_chi > 0,
		"modo normal: se ven los 16 clubes de primera y los %d de segunda (%d)" % [segunda_chi, s.ficha().clubes_listados.size()])
	var rotulos: Array = s.ficha().get("_cuerpo").get_children().filter(func(n: Node) -> bool: return n is Label).map(func(n: Label) -> String: return n.text)
	_comprobar(rotulos.any(func(t: String) -> bool: return t.begins_with("PRIMERA DIVISIÓN")) and rotulos.any(func(t: String) -> bool: return t.begins_with("SEGUNDA DIVISIÓN")),
		"separados por división, con su rótulo (%s)" % [rotulos])
	_comprobar(s.ficha().club_marcado() != null and s.ficha().club_marcado().nombre == s.ficha().clubes_listados[0], "queda marcado el primero de primera")
	var fichas := s.ficha()
	var visibles := func() -> int: return fichas.get("_cuerpo").get_children().filter(func(n: Node) -> bool: return n is Button and n.has_meta("club") and (n as Button).visible).size()
	_comprobar(visibles.call() == 16, "con pestañas: se ve solo primera (%d)" % visibles.call())
	fichas.ver_division(1)
	_comprobar(visibles.call() == segunda_chi and fichas.club_marcado().nombre == fichas.clubes_listados[0], "la pestaña de segunda enseña sus %d clubes y el marcado sigue siendo el de primera" % segunda_chi)
	fichas.ver_division(0)
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
	var tabla_ligas2: Dictionary = Datos.tabla("PAISES_LIGAS")
	var liga_ven2: Variant = tabla_ligas2.get("VEN")
	tabla_ligas2.erase("VEN")   ## (10-11) Venezuela ya tiene liga: se quita un momento para ejercer la rama «sin liga»
	s.call("_elegir", "VEN")
	s.pedir_confirmacion()
	_comprobar(s.get("_btn_confirmar").disabled and not s.confirmacion().visible, "sin liga no se confirma")
	tabla_ligas2["VEN"] = liga_ven2
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
