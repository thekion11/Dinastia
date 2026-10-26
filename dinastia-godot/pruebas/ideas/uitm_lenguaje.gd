extends BaseIdea
## PAQUETE uitm (25-10-2026): el lenguaje visual común.
##  - Tema: accesibilidad (daltonismo y escala de letra) que por defecto no cambia nada.
##  - Aviso: se QUEDA en pantalla (antes salía a la vez que entraba), se aparta
##    con el ratón encima, la cola no se atasca si su padre desaparece y se traduce.
##  - Menú lateral: cajón traducido y por encima de lo que flota al desplegarlo.
##  - Cuadro de diálogo y BotonFx: foco visible para mando.
## Va con esperas reales (las animaciones son por tiempo), por eso redefine `_ready`.

func _ready() -> void:
	await get_tree().process_frame
	await _probar_todo()
	print("")
	print("===== FIN. %d fallos =====" % _fallos.size())
	get_tree().quit(0 if _fallos.is_empty() else 1)

func _esperar(seg: float) -> void:
	await get_tree().create_timer(seg).timeout

func _probar_todo() -> void:
	_tema()
	await _aviso()
	await _aviso_cola()
	_traducciones()
	_menu_lateral()
	_dialogo()
	await _boton_fx()

func _tema() -> void:
	_titulo("Tema: accesibilidad apagada = todo igual")
	_comprobar(not Tema.daltonico and is_equal_approx(Tema.escala_texto, 1.0), "por defecto, sin daltonismo y con la letra al 100 %")
	var iguales := true
	for t: int in [Tema.TAM_ROTULO, Tema.TAM_CUERPO, Tema.TAM_DESTACADO, Tema.TAM_TITULO, Tema.TAM_MARCADOR, 7, 30]:
		iguales = iguales and Tema.letra(t) == t
	_comprobar(iguales, "letra(t) devuelve t tal cual con la escala a 1,0 (también 7 px, sin subirla a 8)")
	_comprobar(Tema.accesible(Tema.BIEN) == Tema.BIEN and Tema.accesible(Tema.MAL) == Tema.MAL and Tema.accesible(Tema.ORO) == Tema.ORO, "los semánticos no cambian sin el modo daltónico")
	var l := Tema.etiqueta(Tema.TAM_CUERPO, Tema.BIEN, "x")
	_comprobar(l.get_theme_font_size("font_size") == Tema.TAM_CUERPO and l.get_theme_color("font_color") == Tema.BIEN, "etiqueta: mismo tamaño y color que antes")
	_comprobar(Tema.de_resultado(2, 1) == Tema.BIEN and Tema.de_resultado(0, 1) == Tema.MAL and Tema.de_resultado(1, 1) == Tema.NEUTRO, "de_resultado igual que antes")
	l.free()

	_titulo("Tema: daltonismo y letra grande (valores puestos a mano, como haría Principal)")
	Tema.daltonico = true
	Tema.escala_texto = 1.3
	_comprobar(Tema.bien() == Tema.BIEN_DALT and Tema.mal() == Tema.MAL_DALT and Tema.oro() == Tema.ORO_DALT, "bien/mal/oro pasan a azul cielo, bermellón y ámbar")
	var medio := Tema.accesible(Color(Tema.MAL, 0.5))
	_comprobar(Color(medio, 1.0) == Tema.MAL_DALT and is_equal_approx(medio.a, 0.5), "conserva el alfa (Color(Tema.MAL, 0.5) → bermellón al 50 %%)")
	_comprobar(Tema.accesible(Tema.TEXTO) == Tema.TEXTO and Tema.accesible(Tema.ACENTO) == Tema.ACENTO, "los colores sin significado no se tocan")
	var l2 := Tema.etiqueta(Tema.TAM_CUERPO, Tema.ORO, "x")
	_comprobar(l2.get_theme_font_size("font_size") == 17 and l2.get_theme_color("font_color") == Tema.ORO_DALT, "etiqueta: 13 px → 17 px y oro → ámbar (es %d)" % l2.get_theme_font_size("font_size"))
	var r := Tema.rotulo("rótulo")
	_comprobar(r.get_theme_font_size("font_size") == 14, "el rótulo (11 px) también escala: 14 px")
	_comprobar(Tema.de_resultado(3, 0) == Tema.BIEN_DALT, "de_resultado respeta el modo daltónico")
	Tema.escala_texto = 0.5
	_comprobar(Tema.letra(13) == 9, "la escala se acota a 0,7 como en Ajustes (13 px → 9 px)")
	l2.free()
	r.free()
	Tema.daltonico = false
	Tema.escala_texto = 1.0

func _lienzo() -> Control:
	var c := Control.new()
	c.size = Vector2(1280, 720)
	add_child(c)
	return c

func _aviso_de(c: Node) -> Aviso:
	for n in c.get_children():
		if n is Aviso:
			return n
	return null

func _aviso() -> void:
	_titulo("Aviso: entra, se queda y se aparta")
	var c := _lienzo()
	Aviso.mostrar(c, "logro", "🏆", "Primer título", "Levantaste tu primer trofeo.")
	await _esperar(0.9)
	var a := _aviso_de(c)
	_comprobar(a != null, "el aviso está colgado del lienzo")
	if a == null:
		return
	_comprobar(is_equal_approx(a.position.x, 1280.0 - Aviso.ANCHO - Aviso.MARGEN) and a.modulate.a > 0.95, "a los 0,9 s está en su sitio y opaco (x=%.0f, alfa=%.2f)" % [a.position.x, a.modulate.a])
	await _esperar(2.2)
	_comprobar(is_instance_valid(a) and is_equal_approx(a.position.x, 1280.0 - Aviso.ANCHO - Aviso.MARGEN) and a.modulate.a > 0.95,
		"a los 3,1 s SIGUE quieto y legible (antes ya se había ido a los 0,9 s)")
	## El ratón por encima: se vuelve casi transparente; al salir, vuelve.
	var mov := InputEventMouseMotion.new()
	mov.position = a.get_global_rect().get_center()
	mov.global_position = mov.position
	get_viewport().push_input(mov)
	await _esperar(0.3)
	var dentro_ok := is_instance_valid(a) and a.get_global_rect().has_point(a.get_global_mouse_position())
	if dentro_ok:
		_comprobar(a.modulate.a < 0.3, "con el ratón encima se aparta (alfa %.2f)" % a.modulate.a)
		mov.position = Vector2(20, 600)
		mov.global_position = mov.position
		get_viewport().push_input(mov)
		await _esperar(0.3)
		_comprobar(is_instance_valid(a) and a.modulate.a > 0.95, "al quitar el ratón vuelve a verse entero")
	else:
		_linea("  (sin ratón en este modo: la parte del ratón encima no se puede comprobar aquí)")
	await _esperar(1.2)
	_comprobar(not is_instance_valid(a), "y se va solo pasado su tiempo")
	c.queue_free()

func _aviso_cola() -> void:
	_titulo("Aviso: la cola no se atasca si el padre se va a media animación")
	var c1 := _lienzo()
	Aviso.mostrar(c1, "alerta", "⚠️", "Uno", "a")
	Aviso.mostrar(c1, "alerta", "⚠️", "Dos", "b")
	await _esperar(0.3)
	c1.queue_free()
	await _esperar(0.2)
	var c2 := _lienzo()
	Aviso.mostrar(c2, "dinero", "💰", "Venta cerrada", "c")
	await _esperar(0.8)
	var a := _aviso_de(c2)
	_comprobar(a != null and a.modulate.a > 0.9, "tras cerrar la pantalla, el aviso siguiente sale (antes la cola se quedaba bloqueada para siempre)")
	c2.queue_free()
	await _esperar(0.2)

func _traducciones() -> void:
	_titulo("Textos traducidos: avisos y cajón")
	var antes := Idiomas.idioma
	Idiomas.idioma = "en"
	var c := _lienzo()
	var a := Aviso.new()
	a._tipo = "logro"
	a._titulo = "Mi vida"
	c.add_child(a)
	var textos: Array[String] = []
	for n in a.find_children("*", "Label", true, false):
		textos.append((n as Label).text)
	_comprobar(textos.has("ACHIEVEMENT UNLOCKED"), "la etiqueta del tipo sale en inglés (%s)" % ", ".join(textos))
	_comprobar(textos.has(Idiomas.t("Mi vida")) and Idiomas.t("Mi vida") != "Mi vida", "el título se traduce en el aviso")
	var ml := MenuLateral.crear(null)
	c.add_child(ml)
	var cab := ""
	for b in ml.find_children("*", "Button", true, false):
		if b.has_meta("_es") and String((b as Button).text).contains("📜"):
			cab = (b as Button).text
			break
	_comprobar(cab == "📜  " + Idiomas.mayusculas(Idiomas.t("Historia")) and not cab.contains("HISTORIA"), "el cajón dice «%s», no HISTORIA" % cab)
	var subs := 0
	for b in ml.find_children("*", "Button", true, false):
		if String((b as Button).text).strip_edges() == Idiomas.t("Historia del club"):
			subs += 1
	_comprobar(subs == 1, "los submenús también (%s)" % Idiomas.t("Historia del club"))
	Idiomas.idioma = antes
	ml._traducir()
	var cab_es := ""
	for b in ml.find_children("*", "Button", true, false):
		if b.has_meta("_es") and String((b as Button).text).contains("📜"):
			cab_es = (b as Button).text
	_comprobar(cab_es == "📜  HISTORIA", "al volver al castellano, igual que siempre («%s»)" % cab_es)
	a.queue_free()
	c.queue_free()

func _menu_lateral() -> void:
	_titulo("Menú lateral: el cajón se abre por encima de lo que flota")
	var c := _lienzo()
	var ml := MenuLateral.crear(null)
	c.add_child(ml)
	var flotante := PanelContainer.new()
	flotante.name = "ConsejoDelPresidente"
	c.add_child(flotante)
	_comprobar(ml.get_index() < flotante.get_index(), "antes de abrir, el consejo está encima")
	ml.desplegar()
	_comprobar(ml.abierto() and ml.get_index() == c.get_child_count() - 1, "al desplegar, el cajón pasa a ser lo último (se ve encima)")
	c.queue_free()

func _dialogo() -> void:
	_titulo("Cuadro de diálogo: foco de mando visible, sin cambiar de tamaño")
	var b := CuadroDialogo.respuesta(Button.new())
	var foco := b.get_theme_stylebox("focus") as StyleBoxFlat
	var reposo := b.get_theme_stylebox("normal") as StyleBoxFlat
	var encima := b.get_theme_stylebox("hover") as StyleBoxFlat
	_comprobar(foco.border_width_left == 2 and is_equal_approx(foco.border_color.a, 1.0), "el foco lleva borde de 2 px opaco")
	_comprobar(foco.border_width_left != encima.border_width_left, "el foco ya no es igual que pasar el ratón")
	_comprobar(foco.get_minimum_size() == reposo.get_minimum_size(), "mismo tamaño mínimo que en reposo (los márgenes son fijos)")
	_comprobar(b.get_theme_font_size("font_size") == 15, "letra de la respuesta igual que antes (15 px)")
	_comprobar(CuadroDialogo._tecla_seguir() == ("E ▸" if not Mando.hay_mando() else "X ▸"), "el «sigue» dice la tecla del dispositivo (%s)" % CuadroDialogo._tecla_seguir())
	b.free()

func _boton_fx() -> void:
	_titulo("BotonFx: el foco de mando aclara el botón; el del ratón no se queda")
	BotonFx.activar(get_tree())
	var c := _lienzo()
	var b := Button.new()
	b.text = "Probar"
	c.add_child(b)
	b.grab_focus()
	await _esperar(0.25)
	_comprobar(b.has_meta("_foco_mando") and b.self_modulate.r > 1.1, "con foco de teclado/mando se aclara (r=%.2f)" % b.self_modulate.r)
	b.release_focus()
	await _esperar(0.25)
	_comprobar(not b.has_meta("_foco_mando") and is_equal_approx(b.self_modulate.r, 1.0), "al perder el foco vuelve a su color")
	c.queue_free()
