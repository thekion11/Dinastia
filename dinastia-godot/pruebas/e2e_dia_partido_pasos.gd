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
	var mem0 := Performance.get_monitor(Performance.MEMORY_STATIC) / 1048576.0
	var huerf0 := int(Performance.get_monitor(Performance.OBJECT_ORPHAN_NODE_COUNT))
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
	if not t.ok(dias.partido_hoy(), "[%s] «Avanzar» llega al día de partido (%d pasos)" % [pais, vueltas]):
		return
	## 2) «JUGAR PARTIDO» → la previa
	dias.jugar()
	var menu: MenuPartido = null
	await t.hasta(func() -> bool:
		menu = _vivos("MenuPartido") as MenuPartido
		return menu != null, 20.0)
	if not t.ok(menu != null, "[%s] «Jugar partido» abre la previa" % pais):
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
		pm = _vivos("PantallaMenu") as PantallaMenu
		return pm != null and pm.is_visible_in_tree(), 12.0)
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
		vista = _vivos("VistaEstadio") as VistaEstadio
		return vista != null and vista.get("_motor") != null and vista.partido != null and vista.partido.minuto >= 0 and String(vista.get("_motor").estado) != "", 120.0)
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

func _jugados(liga: Liga, c: Club) -> int:
	return int((liga.tabla_puntos.get(c.id, {}) as Dictionary).get("pj", 0))

func _boton_con(raiz: Node, texto: String, exacto := false) -> BaseButton:
	for b in raiz.find_children("*", "BaseButton", true, false):
		if b.is_queued_for_deletion() or not (b as Control).is_visible_in_tree():
			continue
		var tx := String(b.get("text")).strip_edges()
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
	t.ok(mios >= 10 and bien == mios, "[%s] en el 3D mi equipo lleva la ALTERNATIVA (%d de %d; %s, la titular es %s)" % [pais, bien, mios, esperado.to_html(false), titular.to_html(false)])

## La formación que dibujan en el campo los jugadores de mi club (por sus casillas), comparada con las de la tabla.
func _formacion_en_campo(vista: VistaEstadio, c: Club) -> String:
	var mio_local := vista.partido.local == c
	var codigos: Array = []
	for f: Dictionary in vista.get("_en_campo"):
		if bool(f.get("es_local", false)) == mio_local and f.has("slot_code"):
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
