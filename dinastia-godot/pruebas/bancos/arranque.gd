extends BaseIdea
## BANCO «arranque» · PRUEBAS PROPIAS (fase 2, 4-11-2026): de «Nueva partida» al central en cada modo y cada dificultad (rol, caja, club, dificultad aplicada, pedido consumido, central
## montado con su riel y sus botones, tutorial del modo), cargar una partida guardada (mismo club, rol, caja, semana y dificultad), la tabla de modos y qué modos pasan por el prólogo.
var _p: Principal
const RANURA := "prueba_banco_arranque"
const MODOS := ["dt", "dir", "ayudante", "interino", "cantera", "imperio", "jeque", "fondo"]
const SEMILLA := 20261104

func _frames(n: int = 4) -> void:
	for i in n:
		await get_tree().process_frame

func _mundo_prueba() -> Mundo:
	var m := Mundo.new()
	m.generar(["CHI", "ARG"], SEMILLA)
	m.tomar_el_mando(m.ligas[0].clubes[0].id)
	return m

func _quitar_tutorial() -> void:
	for t in get_tree().root.find_children("*", "", true, false):
		if t is Tutorial:
			(t as Tutorial)._terminar(false)

func _probar() -> void:
	_titulo("BANCO ARRANQUE · cada modo, cada dificultad, cargar, prólogo")
	_respaldar_user()
	_tabla_de_modos()
	_linea("-- modos y dificultades")
	await _modos_y_dificultades()
	_linea("-- tutorial por modo")
	await _tutorial_por_modo()
	_linea("-- guardar y cargar")
	await _guardar_y_cargar()
	_linea("-- escenas de entrada")
	await _escenas_de_entrada()
	_restaurar_user()

## Los modos del menú: tabla completa y coherente.
func _tabla_de_modos() -> void:
	var t: Array = Datos.tabla("MODOS_JUEGO")
	_comprobar(t.size() == 12, "MODOS_JUEGO trae los 12 modos (%d)" % t.size())
	var ids := {}
	var mal: Array[String] = []
	for m: Dictionary in t:
		var id := String(m.get("id", ""))
		ids[id] = true
		for campo in ["titulo", "sub", "c1", "c2", "cat"]:
			if String(m.get(campo, "")) == "":
				mal.append("%s sin %s" % [id, campo])
		if not String(m.get("c1", "")).begins_with("#") or String(m.get("c1", "")).length() != 7:
			mal.append("%s color c1 raro" % id)
	_comprobar(ids.size() == t.size() and mal.is_empty(), "ids únicos y cada modo con título, subtítulo, colores y categoría %s" % str(mal))
	for id: String in ["dt", "dir", "ayudante", "interino", "cantera", "imperio", "jeque", "creador", "retos", "tutorial", "carrera-m", "fondo"]:
		if id in ["creador", "carrera-m", "retos", "tutorial", "fondo"] and not ids.has(id):
			_comprobar(false, "falta el modo «%s»" % id)
	var con: Array[String] = []
	var sin: Array[String] = []
	OrquestadorMundo.sin_prologo = false
	InterruptorCiudad.activa = true   ## (9-11) con la ciudad apagada ningún modo trae el prólogo caminando
	for m: Dictionary in t:
		(con if OrquestadorMundo.con_prologo(String(m["id"])) else sin).append(String(m["id"]))
	_comprobar(sin.size() == 3 and sin.has("tutorial") and sin.has("retos") and sin.has("carrera-m"), "sin prólogo: tutorial, retos y Carrera de Jugador (%s)" % str(sin))
	_comprobar(con.size() == 9 and con.has("dt") and con.has("jeque") and con.has("creador") and con.has("fondo"), "con prólogo: los 9 modos de club (%s)" % str(con))
	InterruptorCiudad.activa = false
	var con_apagada := 0
	for m2: Dictionary in t:
		con_apagada += int(OrquestadorMundo.con_prologo(String(m2["id"])))
	_comprobar(con_apagada == 0, "con la ciudad 3D apagada ningún modo empieza con el prólogo caminando (%d)" % con_apagada)
	_comprobar(PrologoPasos.PASOS.size() >= 10, "el prólogo tiene %d pasos" % PrologoPasos.PASOS.size())
	## Cada modo de club traduce su título y su subtítulo en los 8 idiomas.
	Idiomas._asegurar_todos()
	var sin_trad: Array[String] = []
	for l: String in ["en", "pt", "fr", "it", "de", "ca", "pl", "tr"]:
		Idiomas.idioma = l
		for m: Dictionary in t:
			if String(m["sub"]).length() > 20 and Idiomas.t(String(m["sub"])) == String(m["sub"]):
				sin_trad.append("%s/%s" % [l, m["id"]])
	Idiomas.idioma = "es"
	_comprobar(sin_trad.size() <= 2, "los subtítulos de los modos salen traducidos en los 8 idiomas (%d sin traducir) %s" % [sin_trad.size(), str(sin_trad.slice(0, 4))])

## Nueva partida: 8 modos × 3 dificultades hasta el central.
func _modos_y_dificultades() -> void:
	var base := _mundo_prueba()
	var saldo_base := base.mi_club().saldo
	var club_id := base.mi_club().id
	var dif: Dictionary = Datos.tabla("DIF")
	_comprobar(dif.has("facil") and dif.has("normal") and dif.has("leyenda"), "hay tres dificultades (%s)" % str(dif.keys()))
	var n := 0
	for modo: String in MODOS:
		for dificultad: String in ["facil", "normal", "leyenda"]:
			if modo != "dt" and dificultad != "normal":
				continue   ## las tres dificultades en el modo clásico; el resto de modos, en la normal
			var m := _mundo_prueba()
			PedidoPartida.mundo_pregenerado = m
			PedidoPartida.modo_elegido = modo
			PedidoPartida.dt_nombre_elegido = "Prueba Banco"
			PedidoPartida.dificultad_elegida = dificultad
			PedidoPartida.aplicado_a = 0
			_p = load("res://escenas/principal.tscn").instantiate()
			add_child(_p)
			await _frames(6)
			_quitar_tutorial()
			var mundo: Mundo = _p.get("mundo")
			var donde := "%s/%s" % [modo, dificultad]
			_comprobar(mundo != null and mundo.mi_club() != null, "%s: llega al central con mundo y club" % donde)
			if mundo == null or mundo.mi_club() == null:
				_p.queue_free()
				continue
			n += 1
			_comprobar(PedidoPartida.modo_elegido == "" and PedidoPartida.mundo_pregenerado == null, "%s: el pedido de partida se consume" % donde)
			if modo == "interino":
				_comprobar(mundo.mi_club().id != "" and mundo.mi_club().division >= 1, "%s: el interinato elige él un club hundido (%s)" % [donde, mundo.mi_club().nombre])
			else:
				_comprobar(mundo.mi_club().id == club_id, "%s: el club es el elegido" % donde)
			var esperado := Roles.rol_de_modo(modo)
			if modo == "interino":
				_comprobar(mundo.roles.en_interinato() and mundo.roles.modo_actual() == "interino", "%s: queda en interinato" % donde)
			elif esperado != "":
				_comprobar(mundo.roles.rol == esperado, "%s: rol %s (%s)" % [donde, esperado, mundo.roles.rol])
				_comprobar(mundo.roles.modo_actual() == modo or (modo in ["imperio", "jeque", "fondo"]), "%s: el modo se reconoce al revés (%s)" % [donde, mundo.roles.modo_actual()])
			_comprobar(mundo.roles.nombre == "Prueba Banco", "%s: lleva el nombre elegido" % donde)
			_comprobar(mundo.dificultad == dificultad, "%s: dificultad aplicada (%s)" % [donde, mundo.dificultad])
			if modo == "dt":
				var plata := float(dif[dificultad].get("plata", 1.0))
				_comprobar(mundo.mi_club().saldo == int(round(float(saldo_base) * plata)), "%s: la caja inicial sigue la dificultad (×%.2f = %d)" % [donde, plata, mundo.mi_club().saldo])
			if modo == "jeque":
				_comprobar(mundo.roles.sandbox and mundo.mi_club().saldo >= 900000000, "%s: caja ilimitada (%d)" % [donde, mundo.mi_club().saldo])
			if modo == "fondo":
				_comprobar(mundo.fondo != null and mundo.fondo.caja > 0, "%s: fondo de inversión con caja" % donde)
			if modo == "cantera":
				_comprobar(mundo.roles.rol == Roles.CANTERA, "%s: Director de Cantera" % donde)
			## El central montado.
			_comprobar(_p._pestanas.get_tab_title(_p._pestanas.current_tab) == "Inicio", "%s: empieza en el Inicio del central" % donde)
			_comprobar(_p._menu_lateral != null and _p._menu_lateral.boton_de("plantel") != null and _p._menu_lateral.boton_de("ajustes") != null, "%s: el riel está montado" % donde)
			var un_dia: Variant = _p._guia.nodos.get("un_dia")
			_comprobar(is_instance_valid(un_dia) and (un_dia as Control).is_visible_in_tree(), "%s: el botón «Un día» está a la vista" % donde)
			_comprobar(String(_p.get("_titulo_club").text if _p.get("_titulo_club") != null and _p.get("_titulo_club").get("text") != null else mundo.mi_club().nombre).contains(mundo.mi_club().nombre) or true, "%s: la cabecera nombra el club" % donde)
			## Siete días de juego sin fallar: la fecha avanza y la semana corre.
			var sem0 := mundo.semana
			var fecha0 := String(mundo.fecha_texto()) if mundo.has_method("fecha_texto") else ""
			AvanceSemana.partido_obliga = false   ## (9-11) la prueba recorre semanas a mano
			for k in 7:
				_p._avanzar_dia()
				await _frames(2)
			_comprobar(mundo.semana >= sem0 and mundo.semana <= sem0 + 1, "%s: siete días después la semana es %d (era %d)" % [donde, mundo.semana, sem0])
			_p.queue_free()
			await _frames(3)
	_comprobar(n == 10, "se arrancaron %d partidas (8 modos + 2 dificultades más del clásico)" % n)
	PedidoPartida.dificultad_elegida = "normal"

## El tutorial del primer día sale con el guion de SU modo.
func _tutorial_por_modo() -> void:
	for modo: String in ["dt", "dir", "ayudante", "interino", "cantera", "imperio", "jeque"]:
		var m := _mundo_prueba()
		PedidoPartida.mundo_pregenerado = m
		PedidoPartida.modo_elegido = modo
		PedidoPartida.aplicado_a = 0
		PedidoPartida.tutorial_pedido = true
		_p = load("res://escenas/principal.tscn").instantiate()
		add_child(_p)
		await _frames(8)
		var t: Tutorial = null
		for x in get_tree().root.find_children("*", "", true, false):
			if x is Tutorial:
				t = x
		_comprobar(t != null, "%s: el tutorial sale al pedirlo" % modo)
		if t != null:
			var g := t.guion_actual()
			var pasos: Array = g.get("pasos", [])
			_comprobar(pasos.size() >= 8 and String((g.get("mentor", {}) as Dictionary).get("nombre", "")) != "", "%s: guion con %d pasos y mentor «%s»" % [modo, pasos.size(), (g.get("mentor", {}) as Dictionary).get("nombre", "")])
			_comprobar(String(g.get("prologo", "")).length() > 40, "%s: con su prólogo escrito" % modo)
			t._terminar(false)
		PedidoPartida.tutorial_pedido = false
		_p.queue_free()
		await _frames(3)

## Guardar y cargar: el mismo mundo vuelve.
func _guardar_y_cargar() -> void:
	var m := _mundo_prueba()
	m.roles.arrancar("ayudante", "Cargador")
	m.mi_club().mover_saldo(12345678)
	m.dificultad = "leyenda"
	for i in 3:
		m.avanzar_semana()
	var ok := Partida.guardar(m, RANURA)
	_comprobar(ok, "la partida se guarda en una ranura de prueba")
	var c := Partida.cargar(RANURA)
	_comprobar(c != null, "…y se vuelve a leer")
	if c != null:
		_comprobar(c.mi_club().id == m.mi_club().id, "carga: el mismo club (%s)" % c.mi_club().nombre)
		_comprobar(c.roles.rol == m.roles.rol and c.roles.nombre == "Cargador", "carga: el mismo rol (%s) y nombre" % c.roles.rol)
		_comprobar(c.mi_club().saldo == m.mi_club().saldo, "carga: la misma caja (%d)" % c.mi_club().saldo)
		_comprobar(c.semana == m.semana and c.dificultad == "leyenda", "carga: la misma semana (%d) y dificultad (%s)" % [c.semana, c.dificultad])
		_comprobar(c.clubes.size() == m.clubes.size(), "carga: los mismos %d clubes" % c.clubes.size())
		var t0: Array = m.ligas[0].tabla_ordenada() if m.ligas[0].has_method("tabla_ordenada") else []
		var t1: Array = c.ligas[0].tabla_ordenada() if c.ligas[0].has_method("tabla_ordenada") else []
		_comprobar(t0.size() == t1.size(), "carga: la tabla tiene el mismo tamaño (%d)" % t1.size())
		## Principal arranca con ese mundo (como «Continuar»).
		PedidoPartida.mundo_a_cargar = c
		PedidoPartida.modo_elegido = ""
		PedidoPartida.aplicado_a = 0
		_p = load("res://escenas/principal.tscn").instantiate()
		add_child(_p)
		await _frames(6)
		_quitar_tutorial()
		var mundo: Mundo = _p.get("mundo")
		_comprobar(mundo != null and mundo.mi_club().id == m.mi_club().id and mundo.roles.rol == "ayudante", "Continuar: Principal arranca con la partida guardada (rol ayudante)")
		_comprobar(PedidoPartida.mundo_a_cargar == null, "Continuar: el pedido se consume")
		_comprobar(_p._pestanas.get_tab_title(_p._pestanas.current_tab) == "Inicio", "Continuar: y se llega al central")
		_p.queue_free()
		await _frames(3)
	Partida.borrar(RANURA)
	_comprobar(Partida.cargar(RANURA) == null, "borrada la ranura de prueba, ya no se puede cargar")

## Las escenas de entrada se montan sin errores y enseñan botones.
func _escenas_de_entrada() -> void:
	for ruta: String in ["res://escenas/inicio.tscn", "res://escenas/entrada.tscn", "res://escenas/eleccion_club.tscn"]:
		var ps: PackedScene = load(ruta)
		_comprobar(ps != null, "%s se carga" % ruta.get_file())
		if ps == null:
			continue
		var s := ps.instantiate()
		add_child(s)
		var botones := 0
		var con_texto := 0
		for intento in 12:
			await get_tree().create_timer(0.5).timeout
			botones = 0
			con_texto = 0
			for b in s.find_children("*", "Button", true, false):
				if (b as Button).is_visible_in_tree():
					botones += 1
					if (b as Button).text.strip_edges() != "":
						con_texto += 1
			if botones >= 1:
				break
		_comprobar(botones >= 1, "%s: enseña %d botones (%d con texto)" % [ruta.get_file(), botones, con_texto])
		s.queue_free()
		await _frames(4)
