extends BaseIdea
## EL MÓVIL CON TECLADO Y MANDO (25-10-2026, paquete uite). Esc/B da un paso atrás (chat → Mensajes →
## inicio → guardar el móvil; pestaña de Tribuna → su inicio), el foco cae dentro del móvil y no en la
## pantalla de detrás, y el aviso de arriba sale traducido y con el filo del color que toca.

class Anfitrion extends Control:
	var mundo: Mundo
	var _bandeja: Array = []
	var refrescos := 0
	func _refrescar() -> void:
		refrescos += 1

func _probar() -> void:
	_titulo("EL MÓVIL CON TECLADO Y MANDO (uite)")
	var m := _mundo(5151)
	m.redes.dar_acceso_club(m)
	var host := Anfitrion.new()
	host.mundo = m
	host.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(host)
	## Un botón «de detrás» con el foco, como el que abre el móvil desde MI VIDA.
	var detras := Button.new()
	detras.text = "Abrir el móvil"
	host.add_child(detras)
	detras.grab_focus()
	var pop := Telefono.abrir(host, m)
	var tel: Telefono = pop.find_children("*", "Telefono", true, false)[0]
	_comprobar(tel.al_cerrar.is_valid(), "quien abre el móvil a pantalla completa le dice cómo guardarse")
	tel.enfocar()
	var foco := get_viewport().gui_get_focus_owner()
	_comprobar(foco != null and tel.is_ancestor_of(foco), "al abrirlo, el foco pasa al móvil (estaba en «%s»)" % (foco.name if foco != null else "nadie"))
	_comprobar(foco is Button and (foco as Button).text != "‹", "el foco cae en una app, no en «atrás»")
	## Chat → Mensajes → inicio, con Esc.
	var chats := m.movil.chats()
	_comprobar(not chats.is_empty(), "hay un chat (la clave del club)")
	tel.set("_chat", String(chats[0]["de"]))
	tel.abrir_app("mensajes")
	_esc(tel)
	_comprobar(String(tel.get("_chat")) == "" and String(tel.get("_app")) == "mensajes", "Esc en un chat vuelve a la lista de Mensajes")
	_esc(tel)
	_comprobar(String(tel.get("_app")) == "inicio", "Esc en una app vuelve a la pantalla de inicio")
	## Tribuna: de una pestaña a su inicio, y de ahí a la pantalla de inicio.
	m.redes.sesion = "dt"
	tel.set("_sub", "publicar")
	tel.abrir_app("tribuna")
	_esc(tel)
	_comprobar(String(tel.get("_sub")) == "inicio" and String(tel.get("_app")) == "tribuna", "Esc en «Publicar» vuelve al inicio de Tribuna")
	_esc(tel)
	_comprobar(String(tel.get("_app")) == "inicio", "y otro Esc, a la pantalla de inicio del móvil")
	## El aviso: traducido, visible y con filo rojo si es un problema, dorado si salió bien.
	Idiomas.idioma = "en"
	tel.call("_decir", "⚠️ Clave incorrecta.")
	var aviso: Label = tel.get("_aviso")
	var sb := aviso.get_theme_stylebox("normal") as StyleBoxFlat
	_comprobar(aviso.visible and aviso.text == "⚠️ Wrong password.", "el aviso sale traducido («%s»)" % aviso.text)
	_comprobar(sb != null and sb.border_color.is_equal_approx(Color("e5534b")) and sb.border_width_left > 0, "un problema lleva el filo rojo")
	tel.call("_decir", Idiomas.t("✔ Sesión iniciada: %s") % "@mister")
	_comprobar(aviso.text == "✔ Signed in: @mister" and sb.border_color.is_equal_approx(Tema.ORO), "lo que salió bien lleva el filo dorado («%s»)" % aviso.text)
	Idiomas.idioma = "es"
	tel.abrir_app("inicio")
	_comprobar(not aviso.visible, "al cambiar de app el aviso se va")
	## Desde el inicio, Esc guarda el móvil (y no se lo pasa a la pantalla de detrás).
	_comprobar(tel.atras(), "en el inicio, «atrás» guarda el móvil")
	_comprobar(pop.has_meta("cerrando"), "el móvil se está guardando (con su fundido)")
	## En la casa 3D el Esc del inicio sale de la casa; un móvil suelto sin quien lo guarde no se come el Esc.
	var suelto := Telefono.crear(m)
	add_child(suelto)
	_comprobar(not suelto.atras(), "un móvil sin «guardar» deja el Esc a la pantalla de debajo")
	suelto.queue_free()

func _esc(tel: Telefono) -> void:
	var ev := InputEventAction.new()
	ev.action = "ui_cancel"
	ev.pressed = true
	tel._unhandled_input(ev)
