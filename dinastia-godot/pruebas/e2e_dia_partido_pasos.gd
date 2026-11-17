extends RefCounted
## Los pasos de `e2e_dia_partido` (la prueba del día de partido de extremo a extremo, 17-11-2026). `t` es la escena de la prueba (ok, esperar, hasta).

var t: Node
var p: Principal

func _init(prueba: Node) -> void:
	t = prueba
	p = prueba.p

## Tres clubes de tres países distintos del mundo de la partida (orden 34).
func elegir_clubes() -> Array:
	var m: Mundo = p.mundo
	var r: Array = []
	var paises := {}
	for l: Liga in m.ligas:
		if r.size() >= 3:
			break
		if l.clubes.size() < 6 or paises.has((l.clubes[0] as Club).pais):
			continue
		paises[(l.clubes[0] as Club).pais] = true
		r.append(l.clubes[(r.size() * 3 + 1) % l.clubes.size()])
	return r

func _vivos(clase: String) -> Node:
	return t.buscar(p, clase)

## UN DÍA DE PARTIDO ENTERO con el club `c`.
func dia_de_partido(c: Club) -> void:
	var m: Mundo = p.mundo
	var pais := c.pais
	print("== %s · %s ==" % [pais, Nombres.visible(c.nombre)])
	m.tomar_el_mando(c.id)
	m.prensa.eventos_vistos.append("directiva:%d" % m.anio)
	p._refrescar()
	await t.esperar(20)
	await _contestar_eventos()
	var mem0 := Performance.get_monitor(Performance.MEMORY_STATIC) / 1048576.0
	var huerf0 := int(Performance.get_monitor(Performance.OBJECT_ORPHAN_NODE_COUNT))
	t.set_meta("huerfanos0", Node.get_orphan_node_ids())
	t.set_meta("guardados0", load("res://pruebas/e2e_dia_partido_pasos2.gd").nodos_guardados())
	var liga := m.liga_de(c)
	var jugados0 := _jugados(liga, c)
	## 1) MENÚ CENTRAL → AVANZAR hasta el día de partido (sin las pantallas del avance: no son lo que se prueba aquí)
	var dias = p._avance.dias()
	dias.sin_pantalla = true
	var vueltas := 0
	while not dias.partido_hoy() and vueltas < 12:
		await dias.pulsar(true)
		await t.esperar(3)
		vueltas += 1
	dias.sin_pantalla = false
	await _contestar_eventos()
	if not t.ok(dias.partido_hoy(), "[%s] «Avanzar» llega al día de partido (%d pasos)" % [pais, vueltas]):
		return
	## 2) «JUGAR PARTIDO» → la previa
	dias.jugar()
	var menu: MenuPartido = null
	await t.hasta(func() -> bool:
		var menu_ = _vivos("MenuPartido") as MenuPartido
		return menu_ != null, 20.0)
	menu = _vivos("MenuPartido") as MenuPartido
	if not t.ok(menu != null, "[%s] «Jugar partido» abre la previa" % pais):
		print("    registro: ", p._registro.get_parsed_text().right(600).replace("\n", " | "))
		print("    capas: ", p.get_children().map(func(n: Node) -> String: return n.name if n.get_script() == null else "%s(%s)" % [n.name, n.get_script().get_global_name()]).slice(-8))
		return
	await t.esperar(20)
	## 3) UNIFORME alternativo y CÁMARA lejana
	menu._abrir("uniforme")
	await t.esperar(10)
	var alt := _boton_con(menu._cuerpo, Idiomas.t("Alternativa"))
	t.ok(alt != null, "[%s] la pestaña Uniforme tiene «Alternativa»" % pais)
	if alt != null:
		alt.pressed.emit()
	await t.esperar(5)
	t.ok(String(OpcionesPartido.leer("uniforme_partido", "")) == "alternativa", "[%s] el uniforme elegido queda guardado" % pais)
	menu._abrir("camara")
	await t.esperar(10)
	var lejos := _boton_con(menu._cuerpo, Idiomas.t("Alejada"))
	if lejos != null:
		lejos.pressed.emit()
	t.ok(String(OpcionesPartido.leer("pro_camara", "")) == "lejos", "[%s] la cámara elegida queda guardada (%s)" % [pais, OpcionesPartido.leer("pro_camara", "")])
	## 4) PLAN DE JUEGO: otra formación (pulsando su botón en la Táctica del juego) y otro titular
	var form0 := c.tactica.formacion
	menu._abrir("plan")
	var pm: PantallaMenu = null
	await t.hasta(func() -> bool:
		var pm_ = _vivos("PantallaMenu") as PantallaMenu
		return pm_ != null and pm_.is_visible_in_tree(), 12.0)
	pm = _vivos("PantallaMenu") as PantallaMenu
	t.ok(pm != null, "[%s] «Plan de juego» abre la Táctica del juego" % pais)
	var nueva := "4-4-2" if form0 != "4-4-2" else "4-3-3"
	if pm != null:
		var bf := _boton_con(pm, nueva, true)
		t.ok(bf != null, "[%s] la Táctica tiene el botón de la formación %s" % [pais, nueva])
		if bf != null:
			bf.pressed.emit()
		await t.esperar(5)
	t.ok(c.tactica.formacion == nueva, "[%s] la formación cambia a %s (era %s)" % [pais, nueva, form0])
	var once := c.once()
	var entra := _suplente_para(c, once)
	var sale: Jugador = once[once.size() - 1]
	if entra != null:
		var nuevo: Array[Jugador] = []
		nuevo.assign(once)
		nuevo[nuevo.find(sale)] = entra
		c.fijar_once(nuevo)
	t.ok(entra != null and c.once().has(entra) and not c.once().has(sale), "[%s] el titular cambia (entra %s por %s)" % [pais, entra.nombre if entra else "?", sale.nombre])
	if pm != null:
		pm.cerrar()
	await t.hasta(func() -> bool: return menu.visible, 5.0)
	## 5) CONFIRMAR → el partido jugable (C4)
	menu.confirmar()
	var vista: VistaEstadio = null
	await t.hasta(func() -> bool:
		var vista_ = _vivos("VistaEstadio") as VistaEstadio
		return vista_ != null and vista_.get("_motor") != null and vista_.partido != null and vista_.partido.minuto >= 0 and String(vista_.get("_motor").estado) != "", 120.0)
	vista = _vivos("VistaEstadio") as VistaEstadio
	if not t.ok(vista != null, "[%s] Confirmar abre el partido 3D" % pais):
		return
	var partido: Partido = vista.partido
	await t.esperar(30)
	_comprobar_uniforme(vista, c, pais)
	t.ok((partido.local if partido.local == c else partido.visita).tactica.formacion == nueva and _formacion_en_campo(vista, c) == nueva,
		"[%s] el motor juega con la formación elegida (%s; en el campo: %s)" % [pais, nueva, _formacion_en_campo(vista, c)])
	var once_p := partido.once_local if partido.local == c else partido.once_visita
	t.ok(entra != null and once_p.has(entra) and not once_p.has(sale), "[%s] el titular elegido sale al campo" % pais)
	## 6) UNOS MINUTOS DE JUEGO con entradas simuladas
	var min0 := partido.minuto
	var j := Jugando.new()
	t.add_child(j)
	await t.hasta(func() -> bool: return partido.minuto >= min0 + 2 or partido.terminado_ya, 240.0)
	j.queue_free()
	Jugando.soltar()
	t.ok(partido.minuto >= min0 + 2, "[%s] se juega con el mando simulado (minuto %d → %d, %d pulsaciones)" % [pais, min0, partido.minuto, j.pulsaciones])
	await load("res://pruebas/e2e_dia_partido_pasos2.gd").new(t, self).despues_de_jugar(c, vista, partido, liga, jugados0, mem0, huerf0)

## Lo que se abre solo (la reunión de la directiva) se contesta como lo haría el jugador: la primera opción.
func _contestar_eventos() -> void:
	for h: Node in p.get_children():
		if h is EventoDialogo and not h.is_queued_for_deletion():
			(h as EventoDialogo).selector.elegir(0)
		elif h is EventoPantallaCompleta:
			h.queue_free()
	await t.esperar(30)

func _jugados(liga: Liga, c: Club) -> int:
	return int((liga.tabla_puntos.get(c.id, {}) as Dictionary).get("pj", 0))

func _boton_con(raiz: Node, texto: String, exacto := false) -> BaseButton:
	for b in raiz.find_children("*", "BaseButton", true, false):
		if b.is_queued_for_deletion() or not (b as Control).is_visible_in_tree():
			continue
		var tx := String(b.get("text")).strip_edges()
		if tx == "":   ## botones con el texto en una etiqueta hija (las fotos de la cámara)
			for l in b.find_children("*", "Label", true, false):
				tx += String((l as Label).text) + " "
			tx = tx.strip_edges()
		if (exacto and tx == texto) or (not exacto and tx.to_lower().contains(texto.to_lower())):
			return b
	return null

## Un suplente sano que no sea portero (entra por el último del once, que nunca es el portero).
func _suplente_para(c: Club, once: Array[Jugador]) -> Jugador:
	for j: Jugador in c.plantilla:
		if not once.has(j) and j.pos_e != "POR" and j.disponible():
			return j
	return null

## El uniforme del 3D: los jugadores de campo de mi club llevan la camiseta de la alternativa (`Puente3D.kit_elegido`).
func _comprobar_uniforme(vista: VistaEstadio, c: Club, pais: String) -> void:
	var esperado := Color(String(Puente3D.kit_elegido(c, "alternativa")["c1"]))
	var titular := Color(String(Puente3D.kit(c)["c1"]))
	var mios := 0
	var bien := 0
	var mio_local := vista.partido.local == c
	for f: Dictionary in vista.get("_en_campo"):
		var n: Node3D = f.get("node")
		if not is_instance_valid(n) or bool(f.get("es_local", false)) != mio_local or String(f.get("slot_code", "")) == "POR" or not n.has_meta("kit_c1"):
			continue
		mios += 1
		if (n.get_meta("kit_c1") as Color).is_equal_approx(esperado):
			bien += 1
	if not t.ok(mios >= 10 and bien == mios, "[%s] en el 3D mi equipo lleva la ALTERNATIVA (%d de %d; %s, la titular es %s)" % [pais, bien, mios, esperado.to_html(false), titular.to_html(false)]):
		var vistos := {}
		for f: Dictionary in vista.get("_en_campo"):
			var n: Node3D = f.get("node")
			if is_instance_valid(n) and n.has_meta("kit_c1"):
				vistos["%s %s" % ["L" if bool(f.get("es_local", false)) else "V", (n.get_meta("kit_c1") as Color).to_html(false)]] = true
		print("    camisetas en el campo: %s · ctx_club_id=%s · mi club=%s (local: %s) · uniforme_partido=%s" % [vistos.keys(), Partido.ctx_club_id, c.id, str(mio_local), OpcionesPartido.leer("uniforme_partido", "")])

## La formación que dibujan en el campo los jugadores de mi club (por sus casillas), comparada con las de la tabla.
func _formacion_en_campo(vista: VistaEstadio, c: Club) -> String:
	var mio_local := vista.partido.local == c
	var codigos: Array = []
	for f: Dictionary in vista.get("_en_campo"):
		if bool(f.get("es_local", false)) == mio_local and f.has("slot_code") and String(f["slot_code"]) != "ARB":   ## los árbitros no son de nadie
			codigos.append(String(f["slot_code"]))
	codigos.sort()
	for nombre: String in Datos.tabla("FORMS").keys():
		var otros: Array = []
		for s: Variant in (Puente3D.formacion(nombre).get("s", []) as Array):
			otros.append(String(s[0]) if s is Array else String(s))
		otros.sort()
		if otros == codigos:
			return nombre
	return "?"

## El mando simulado: el stick hacia la portería rival con algo de giro, sprint a ratos y pases y tiros de vez en cuando.
class Jugando extends Node:
	var pulsaciones := 0
	var _f := 0
	const ACC := ["jugar_derecha", "jugar_arriba", "jugar_izquierda", "jugar_abajo", "jugar_sprint", "jugar_pase", "jugar_tiro"]
	static func soltar() -> void:
		for a: String in ACC:
			if InputMap.has_action(a):
				Input.action_release(a)
	func _process(_d: float) -> void:
		_f += 1
		soltar()
		var dir: String = ["jugar_arriba", "jugar_derecha", "jugar_arriba", "jugar_izquierda"][(_f / 45) % 4]
		Input.action_press(dir, 1.0)
		if (_f / 30) % 3 == 0:
			Input.action_press("jugar_sprint")
		if _f % 70 == 0:
			Input.action_press("jugar_pase")
			pulsaciones += 1
		if _f % 160 == 0:
			Input.action_press("jugar_tiro")
			pulsaciones += 1
