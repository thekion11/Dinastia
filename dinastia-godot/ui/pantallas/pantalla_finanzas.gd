class_name PantallaFinanzas
extends RefCounted
## FINANZAS, CAMARÍN Y ROL: las cuentas, el vestuario, la equipación, las directrices y la carrera en el club.
##
## Sale de `ui/principal.gd` (mapa de metas 15: el archivo pasaba de
## 15.000 líneas). `p` es la pantalla principal: sus ayudantes (`p._texto`,
## `p._boton`...), el mundo (`p.mundo`) y el repintado (`p._refrescar()`).

var p: Principal

func _init(principal: Principal) -> void:
	p = principal

func _mediar_clan(clan_id: String) -> void:
	var r := p.mundo.vestuario.mediar(clan_id)
	var ok := bool(r.get("ok", false))
	p._escribir("[color=%s]%s[/color]" % ["#4caf6d" if ok else "#e05555", String(r.get("txt", ""))])
	p._refrescar()

func _dar_terapia_mental(j: Jugador) -> void:
	var problema := p.mundo.vestuario.dar_terapia(j)
	if problema != "":
		p._escribir("[color=#e05555]No se pudo dar terapia: %s.[/color]" % problema)
		return
	p._escribir("[color=#4caf6d]Terapia deportiva para %s.[/color]" % j.nombre)
	p._refrescar()

func _pedir_descanso_mental(j: Jugador) -> void:
	var problema := p.mundo.vestuario.descanso_mental(j)
	if problema != "":
		p._escribir("[color=#e05555]No se pudo dar descanso: %s.[/color]" % problema)
		return
	p._refrescar()

func _ceder_canterano(j: Jugador) -> void:
	var r := p.mundo.cesiones.ceder_canterano(j)
	if r.has("error"):
		p._escribir("[color=#e05555]No se puede ceder: %s.[/color]" % String(r["error"]))
		return
	p._escribir("[color=#4caf6d]%s sale cedido[/color] a %s." % [j.nombre, (r["destino"] as Club).nombre])
	p._refrescar()

func _ceder_con_opcion(j: Jugador, tipo: String) -> void:
	var r := p.mundo.cesiones.ceder_con_opcion(j, tipo)
	if r.has("error"):
		p._escribir("[color=#e05555]No se puede ceder: %s.[/color]" % String(r["error"]))
		return
	p._escribir("[color=#4caf6d]%s sale cedido[/color] a %s." % [j.nombre, (r["destino"] as Club).nombre])
	p._refrescar()

func _pactar_clausula_propia(j: Jugador) -> void:
	var ya_tenia := p.mundo.cesiones.clausula_de(j) > 0
	var monto := p.mundo.cesiones.blindar(j) if ya_tenia else p.mundo.cesiones.pactar_clausula(j)
	p._escribir("[color=#4caf6d]Cláusula %s para %s:[/color] %s." % [
		"reforzada" if ya_tenia else "pactada", j.nombre, p._dinero(monto)])
	p._refrescar()

## EL CARGO: qué eres en este club y qué te dejan tocar.
##
## Se pinta como una lista de permisos en verde y rojo, no como un párrafo. Un
## rol se entiende por lo que te prohíbe, y verlo de un vistazo evita que el
## jugador pulse botones que no van a hacer nada.
## `vDespachoTactica()` del HTML: lo que le PIDES al entrenador cuando el banco
## no es tuyo. `Roles.dt_empleado` existía con su sintonía y su confianza, y no
## había forma de decirle nada: dirigías un club sin poder opinar sobre el once.
##
## Lo que lo hace una decisión y no una lista de deseos: **te hace caso según la
## sintonía, y cada indicación la desgasta**. Puedes dirigir sin dirigir, pero
## se paga en relación.
func _pintar_directrices(r: Roles) -> void:
	if r.dt_empleado.is_empty():
		return
	p._lista_club.add_child(HSeparator.new())
	var es_ayudante := r.rol == Roles.AYUDANTE
	var t := p._texto(11, Principal.COL_SUAVE)
	t.text = "🧢 TRABAJAS PARA ÉL" if es_ayudante else "🪑 EL BANCO NO ES TUYO"
	p._lista_club.add_child(t)
	var quien := p._texto(13, Principal.COL_TEXTO)
	quien.text = "%s  ·  estilo %s" % [r.dt_nombre(), String(r.dt_empleado.get("estilo", ""))]
	p._lista_club.add_child(quien)
	var sin := int(r.dt_empleado.get("confianza", 45)) if es_ayudante else int(r.dt_empleado.get("sintonia", 60))
	p._dato("Confianza que tiene en ti" if es_ayudante else "Sintonía contigo", "%d / 100" % sin,
		Principal.COL_ROJO if sin < 30 else (Principal.COL_ORO if sin < 60 else Principal.COL_VERDE), p._lista_club)
	var aviso_caso := p._texto(11, Principal.COL_SUAVE)
	aviso_caso.text = "Cada indicación que le das desgasta la relación. Con la sintonía baja, hace lo que le da la gana."
	aviso_caso.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	p._lista_club.add_child(aviso_caso)

	var te := p._texto(11, Principal.COL_SUAVE)
	te.text = "CÓMO QUIERES QUE JUEGUE"
	p._lista_club.add_child(te)
	var fila_e := HBoxContainer.new()
	fila_e.add_theme_constant_override("separation", 6)
	p._lista_club.add_child(fila_e)
	for est: Array in Roles.ESTILOS_DEF:
		var clave := String(est[0])
		var be := Button.new()
		be.text = String(est[1])
		be.toggle_mode = true
		be.button_pressed = String(r.directrices.get("estilo", "equilibrio")) == clave
		be.add_theme_font_size_override("font_size", 11)
		be.pressed.connect(func() -> void: _fijar_directriz("estilo", clave))
		fila_e.add_child(be)

	for dd: Array in Roles.DIRECTRICES_DEF:
		var clave2 := String(dd[0])
		var activa := bool(r.directrices.get(clave2, false))
		var fila_d := HBoxContainer.new()
		fila_d.add_theme_constant_override("separation", 8)
		p._lista_club.add_child(fila_d)
		var ld := p._texto(12, Principal.COL_TEXTO if activa else Principal.COL_SUAVE)
		ld.text = String(dd[1])
		ld.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		fila_d.add_child(ld)
		var bd := Button.new()
		bd.text = "SÍ" if activa else "NO"
		bd.add_theme_font_size_override("font_size", 11)
		bd.pressed.connect(func() -> void: _fijar_directriz(clave2, not activa))
		fila_d.add_child(bd)
		var dsc := p._texto(10, Principal.COL_SUAVE)
		dsc.text = String(dd[2])
		dsc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		p._lista_club.add_child(dsc)

## La queja del entrenador no se escribe aquí: `fijar_directriz()` desgasta la
## relación y, si se rompe, sale por `roles.aviso`, que ya está conectada.
func _fijar_directriz(clave: String, valor: Variant) -> void:
	p.mundo.roles.fijar_directriz(clave, valor)
	p._refrescar()

func _pintar_rol() -> void:
	p._lista_club.add_child(HSeparator.new())
	var r := p.mundo.roles
	if r == null:
		return
	_pintar_directrices(r)
	var t := p._texto(11, Principal.COL_SUAVE)
	t.text = "TU CARGO"
	p._lista_club.add_child(t)
	var n := p._texto(14, Principal.COL_ORO)
	n.text = r.nombre_del_cargo().capitalize()
	p._lista_club.add_child(n)
	var permisos := {
		"Fichar": r.puede_fichar(),
		"Poner el once": r.puede_alinear(),
		"Contratar cuerpo técnico": r.puede_contratar_staff(),
		"Construir": r.puede_construir(),
		"Vender jugadores": r.puede_vender_jugadores(),
		"Contratar entrenador": r.puede_contratar_dt(),
	}
	for k: String in permisos:
		var l := p._texto(12, Principal.COL_VERDE if permisos[k] else Principal.COL_ROJO)
		l.text = ("sí   " if permisos[k] else "no   ") + k
		p._lista_club.add_child(l)
	var bloqueo := r.mercado_bloqueado()
	if bloqueo != "":
		var b := p._texto(11, Principal.COL_ROJO)
		b.text = bloqueo
		b.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		p._lista_club.add_child(b)
	_pintar_carrera(r)

func _abrir_examen() -> void:
	var ex := ExamenLicencia.mostrar(p, p.mundo)
	ex.cerrado.connect(p._refrescar)

func _abrir_penales() -> void:
	MinijuegoPenales.mostrar(p, p.mundo)

func _pintar_carrera(r: Roles) -> void:
	PanelAspectoDT.pintar(p._lista_club, r, p._texto, {"suave": Principal.COL_SUAVE, "acento": p.COL_ACENTO}, p._refrescar,
		func() -> void:
			var cp := CreadorPersonaje.abrir(p, p.mundo)
			cp.cerrado.connect(p._refrescar))
	## LA REPUTACIÓN (26-9-2026): nivel del club, tu fama y lo que la movió.
	PanelReputacion.pintar(p._lista_club, p.mundo)
	if p.mundo.fondo != null:
		PanelFondo.pintar(p._lista_club, p.mundo, p._refrescar)
	p._lista_club.add_child(HSeparator.new())
	var t := p._texto(11, Principal.COL_SUAVE); t.text = "TU CARRERA"
	p._lista_club.add_child(t)
	var pres := p._texto(14, Principal.COL_ORO)
	pres.text = "Prestigio %d/99  ·  %d trofeo(s)  ·  %d temporada(s)" % [r.prestigio, r.trofeos.size(), r.temporadas]
	p._lista_club.add_child(pres)
	var barra := ProgressBar.new()
	barra.min_value = 0
	barra.max_value = 99
	barra.value = r.prestigio
	barra.custom_minimum_size = Vector2(0, 14)
	barra.show_percentage = false
	p._lista_club.add_child(barra)

	var escalon := r.siguiente_escalon()
	if escalon != "":
		var e := p._texto(11, Principal.COL_SUAVE)
		e.text = escalon
		e.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		p._lista_club.add_child(e)
	if r.puede_ascender() != "":
		p._boton("Ascender a %s" % Roles.PERMISOS[r.puede_ascender()]["cargo"], _ascender_rol, p._lista_club)

	if not r.historial.is_empty():
		var h := p._texto(11, Principal.COL_SUAVE)
		var partes: Array[String] = []
		for paso: Dictionary in r.historial:
			partes.append("%s (hasta %s)" % [String(paso.get("club", "")), str(paso.get("hasta", ""))])
		h.text = "Antes: " + ", ".join(partes)
		h.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		p._lista_club.add_child(h)

	## El entrenador empleado: solo existe si no diriges tú (director, dueño,
	## cantera) o si eres ayudante -ahí es tu jefe, con el mismo diccionario-.
	if not r.dt_empleado.is_empty():
		var fila := HBoxContainer.new()
		fila.add_theme_constant_override("separation", 8)
		p._lista_club.add_child(fila)
		var nom := p._texto(12, Principal.COL_TEXTO)
		if r.es_ayudante():
			nom.text = "Tu jefe: %s  ·  confianza en ti %d/100" % [r.jefe_nombre(), r.jefe_confianza()]
		else:
			## El HTML muestra la clave cruda ("estilo pizarron"), no la frase
			## larga de `DT_ESTILOS` -esa es para otra pantalla-; se capitaliza
			## igual que `nombre_del_cargo()` arriba, no se inventa una frase.
			nom.text = "Entrenador del banco: %s  ·  estilo %s" % [
				r.dt_nombre(), String(r.dt_empleado.get("estilo", "")).capitalize()]
		nom.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		nom.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		fila.add_child(nom)
		if r.puede_contratar_dt():
			var b := Button.new()
			b.text = "Cambiar  %s" % p._dinero(int(Roles.COSTE_CAMBIAR_DT))
			b.add_theme_font_size_override("font_size", 11)
			b.pressed.connect(_cambiar_dt)
			fila.add_child(b)

	if r.puede_inyectar_capital():
		var restantes := r.inyecciones_restantes()
		var bi := Button.new()
		bi.text = "💰 Inyectar %s de tu bolsillo (%d/%d esta temporada)" % [
			p._dinero(int(Roles.INYECCION)), Roles.INYECCIONES_POR_TEMPORADA - restantes, Roles.INYECCIONES_POR_TEMPORADA]
		bi.disabled = restantes <= 0
		bi.pressed.connect(_inyectar_capital)
		p._lista_club.add_child(bi)
	if r.puede_vender_club():
		var bv := Button.new()
		bv.text = "¿SEGURO? Vender el club" if p._confirmar_venta_club else "🏷️ Vender el club"
		bv.pressed.connect(_vender_club)
		p._lista_club.add_child(bv)

## El mensaje de éxito no se escribe aquí -ya lo hacen `roles.aviso` y
## `roles.ascenso`/`sin_banco`, conectados una sola vez en `_conectar_noticias()`-;
## este método solo se ocupa de sacar a pantalla el motivo cuando falla.
func _ascender_rol() -> void:
	var problema := p.mundo.roles.ascender()
	if problema != "":
		p._escribir("[color=#e05555]%s[/color]" % problema)
		return
	p._refrescar()

func _cambiar_dt() -> void:
	var problema := p.mundo.roles.cambiar_dt()
	if problema != "":
		p._escribir("[color=#e05555]No se pudo cambiar de entrenador: %s.[/color]" % problema)
		return
	p._refrescar()

func _inyectar_capital() -> void:
	var problema := p.mundo.roles.inyectar_capital()
	if problema != "":
		p._escribir("[color=#e05555]%s.[/color]" % problema)
		return
	p._refrescar()

func _vender_club() -> void:
	if not p._confirmar_venta_club:
		p._confirmar_venta_club = true
		p._refrescar()
		return
	p._confirmar_venta_club = false
	var problema := p.mundo.roles.vender_club()
	if problema != "":
		p._escribir("[color=#e05555]%s.[/color]" % problema)
	p._refrescar()
