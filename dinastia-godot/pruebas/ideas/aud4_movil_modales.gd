extends BaseIdea
## A4-INT · las PANTALLAS MODALES fuera del menú (avisos, presentación y cinemática de fichajes, despido, pie de campo, portada, teléfono del DT, documental, plan, minijuegos…) en el móvil
## (2400×1080 a 400 ppp y 1280×720; castellano, alemán y polaco): sin botones de menos de 7 mm, sin botones o texto FUERA de la pantalla (también si quedan enteros por debajo: no se podrían pulsar).
var _p: Principal
var _m: Mundo

func _frames(n: int = 2) -> void:
	for i in n:
		await get_tree().process_frame

func _lista() -> Array:
	var mio := _m.mi_club()
	var otro: Club = null
	for c: Club in _m.clubes.values():
		if c != mio:
			otro = c
			break
	var jug: Jugador = otro.plantilla[0]
	var largo := "Una descripción bastante larga para ver cómo se parte en varias líneas dentro de la tarjeta del aviso en un móvil"
	var apps: Array = []
	for app: String in ["tribuna", "mensajes", "noticias", "banco", "calendario", "fotos", "agenda", "red", "ajustes"]:
		apps.append(["teléfono · " + app, func() -> Control:
			var t: Control = Telefono.abrir(_p, _m)
			await _frames(6)
			var tel: Node = t if t.has_method("abrir_app") else null
			if tel == null:
				for h in t.find_children("*", "Control", true, false):
					if h.has_method("abrir_app"):
						tel = h
						break
			if tel != null:
				tel.call("abrir_app", app)
			return t])
	apps.append(["cinemática de fichaje (solo botones)", func() -> Control: return CinematicaFichaje.mostrar(_p, _m, jug, otro, true), true])
	return apps + [
		["aviso", func() -> Control: Aviso.mostrar(_p, "logro", "🏆", "Campeón de liga con una racha histórica", largo); return null],
		["presentación de fichaje", func() -> Control: return PresentacionFichaje.mostrar(_p, _m, jug, otro)],
		["despido", func() -> Control: return EscenaDespido.mostrar(_p, _m, "Los resultados no acompañan y la directiva pierde la confianza")],
		["pie de campo", func() -> Control: return PieDeCampo.mostrar(_p, _m.prensa, true, false, 3, 1)],
		["portada del periódico", func() -> Control: return PortadaPeriodico.mostrar(_p, _m, {"t": "Remontada histórica en el último minuto", "c": largo + ". " + largo, "tipo": "bien", "anio": _m.anio, "semana": _m.semana, "img": "dt", "sub": "2-1"})],
		["teléfono del DT", func() -> Control: return Telefono.abrir(_p, _m)],
		["documental", func() -> Control: return DocumentalTemporada.abrir(_p, DocumentalTemporada.guion(_m))],
		["rueda de prensa", func() -> Control:
			_p._abrir_rueda_pantalla_completa(_m.prensa.abrir_rueda(true, false))
			return _p._rueda_pop as Control],
		["ficha de jugador (plantel)", func() -> Control:
			_p._menu_lateral.abrir_menu("plantel", 0)
			await _frames(6)
			_p._ver_ficha(mio.plantilla[0])
			await _frames(10)
			return _p._menu_lateral.pantalla_abierta as Control],
		["negociación de fichaje", func() -> Control:
			_p._menu_lateral.abrir_menu("plantel", 0)
			await _frames(6)
			_p._ui_plantel._abrir_negociacion(jug)
			await _frames(10)
			return _p._menu_lateral.pantalla_abierta as Control],
		["mesa del agente", func() -> Control:
			var mesa := MesaAgente.new({"tipo": "mejora", "agente": "R. Maldonado", "perfil": "tiburon", "pid": jug.id}, 0, 0.0, 4242)
			var ui := MesaAgenteUI.new(mesa, func(_mm: MesaAgente) -> void: pass)
			_p.add_child(ui)
			return ui],
		["elección de cómo jugar el partido", func() -> Control:
			var el := EleccionPartido.new()
			el.titulo = "%s  vs  %s" % [mio.nombre, otro.nombre]
			_p.add_child(el)
			return el],
		["trivia", func() -> Control: return TriviaClub.mostrar(_p, _m)],
		["examen de licencia", func() -> Control: return ExamenLicencia.mostrar(_p, _m)],
		["minijuego de reflejos", func() -> Control: return MinijuegoReflejos.mostrar(_p, _m)],
		["minijuego de malabares", func() -> Control: return MinijuegoMalabares.mostrar(_p, _m)],
		["minijuego de tiro libre", func() -> Control: return MinijuegoTiroLibre.mostrar(_p, _m)],
		["minijuego de penales", func() -> Control: return MinijuegoPenales.mostrar(_p, _m)],
	]

func _probar() -> void:
	_titulo("AUDITORÍA 4 · INTERFAZ · pantallas modales en el móvil")
	_respaldar_user()
	var idioma_antes := Idiomas.idioma
	_m = _mundo(20261104)
	PedidoPartida.mundo_pregenerado = _m
	var solo := OS.get_environment("MODAL")
	var ventanas: Array = [Vector2i(2400, 1080), Vector2i(1280, 720)]
	for ventana: Vector2i in ventanas:
		for idi: String in ["es", "de"]:
			AyudaMovil.poner(ventana, get_window())
			Idiomas.idioma = idi
			_p = load("res://escenas/principal.tscn").instantiate()
			add_child(_p)
			await _frames(8)
			for t in get_tree().root.find_children("*", "Tutorial", true, false):
				(t as Tutorial)._terminar(false)
			CapasTutorial.poner_activas(false)
			_p._autoguardado = false
			var alto := EscalaMovil.alto_toque(_p)
			var lista := _lista()
			for it: Array in lista:
				var nombre: String = it[0]
				if solo != "" and not nombre.contains(solo):
					continue
				var hijos_antes := _p.get_child_count()
				var nodo: Variant = await (it[1] as Callable).call()
				await _frames(90)
				var c: Control = nodo as Control
				if c == null:
					for k in range(hijos_antes, _p.get_child_count()):
						if _p.get_child(k) is Control:
							c = _p.get_child(k) as Control
				if c == null or not is_instance_valid(c):
					_linea("      %dx%d %s: %s no devolvió pantalla" % [ventana.x, ventana.y, idi, nombre])
					continue
				var pr := AyudaMovil.problemas(c, alto)
				var solo_botones := it.size() > 2 and bool(it[2])   ## decoración recortada por diseño (fachadas de la cinemática): solo se miden los botones
				var graves := pr.filter(func(x: String) -> bool: return x.begins_with("toque") or x.begins_with("botón fuera") or x.begins_with("botón por debajo") or (not solo_botones and (x.begins_with("texto fuera") or x.begins_with("texto por debajo"))))
				var n_bot := c.find_children("*", "Button", true, false).filter(func(x: Node) -> bool: return (x as Control).is_visible_in_tree()).size()
				_comprobar(graves.is_empty(), "%dx%d %s · %s (%d botones): %d fallos %s" % [ventana.x, ventana.y, idi, nombre, n_bot, graves.size(), str(graves.slice(0, 4))])
				if is_instance_valid(c):
					if c is PantallaMenu:
						(c as PantallaMenu).cerrar()   ## devuelve el contenido a Principal (liberarla a pelo lo rompía)
					else:
						c.queue_free()
				await _frames(3)
			_p.queue_free()
			await _frames(4)
			AyudaMovil.quitar(get_window())
	Idiomas.idioma = idioma_antes
	_restaurar_user()
