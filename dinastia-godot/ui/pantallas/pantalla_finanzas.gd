class_name PantallaFinanzas
extends "res://ui/pantallas/pantalla_finanzas_p1.gd"
## [Capa 2/2 de `pantalla_finanzas.gd`] camarín (clanes, salud mental), directrices, rol y carrera

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
	t.text = Idiomas.t("🧢 TRABAJAS PARA ÉL") if es_ayudante else Idiomas.t("🪑 EL BANCO NO ES TUYO")
	p._lista_club.add_child(t)
	var quien := p._texto(13, Principal.COL_TEXTO)
	quien.text = Idiomas.t("%s  ·  estilo %s") % [r.dt_nombre(), String(r.dt_empleado.get("estilo", ""))]
	p._lista_club.add_child(quien)
	var sin := int(r.dt_empleado.get("confianza", 45)) if es_ayudante else int(r.dt_empleado.get("sintonia", 60))
	p._dato("Confianza que tiene en ti" if es_ayudante else "Sintonía contigo", "%d / 100" % sin,
		Principal.COL_ROJO if sin < 30 else (Principal.COL_ORO if sin < 60 else Principal.COL_VERDE), p._lista_club)
	var aviso_caso := p._texto(11, Principal.COL_SUAVE)
	aviso_caso.text = Idiomas.t("Cada indicación que le das desgasta la relación. Con la sintonía baja, hace lo que le da la gana.")
	aviso_caso.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	p._lista_club.add_child(aviso_caso)

	var te := p._texto(11, Principal.COL_SUAVE)
	te.text = Idiomas.t("CÓMO QUIERES QUE JUEGUE")
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
	t.text = Idiomas.t("TU CARGO")
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
	var t := p._texto(11, Principal.COL_SUAVE); t.text = Idiomas.t("TU CARRERA")
	p._lista_club.add_child(t)
	var pres := p._texto(14, Principal.COL_ORO)
	pres.text = Idiomas.t("Prestigio %d/99  ·  %d trofeo(s)  ·  %d temporada(s)") % [r.prestigio, r.trofeos.size(), r.temporadas]
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
		h.text = Idiomas.t("Antes: ") + ", ".join(partes)
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
			nom.text = Idiomas.t("Tu jefe: %s  ·  confianza en ti %d/100") % [r.jefe_nombre(), r.jefe_confianza()]
		else:
			## El HTML muestra la clave cruda ("estilo pizarron"), no la frase
			## larga de `DT_ESTILOS` -esa es para otra pantalla-; se capitaliza
			## igual que `nombre_del_cargo()` arriba, no se inventa una frase.
			nom.text = Idiomas.t("Entrenador del banco: %s  ·  estilo %s") % [
				r.dt_nombre(), String(r.dt_empleado.get("estilo", "")).capitalize()]
		nom.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		nom.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		fila.add_child(nom)
		if r.puede_contratar_dt():
			var b := Button.new()
			b.text = Idiomas.t("Cambiar  %s") % p._dinero(int(Roles.COSTE_CAMBIAR_DT))
			b.add_theme_font_size_override("font_size", 11)
			b.pressed.connect(_cambiar_dt)
			fila.add_child(b)

	if r.puede_inyectar_capital():
		var restantes := r.inyecciones_restantes()
		var bi := Button.new()
		bi.text = Idiomas.t("💰 Inyectar %s de tu bolsillo (%d/%d esta temporada)") % [
			p._dinero(int(Roles.INYECCION)), Roles.INYECCIONES_POR_TEMPORADA - restantes, Roles.INYECCIONES_POR_TEMPORADA]
		bi.disabled = restantes <= 0
		bi.pressed.connect(_inyectar_capital)
		p._lista_club.add_child(bi)
	if r.puede_vender_club():
		var bv := Button.new()
		bv.text = Idiomas.t("¿SEGURO? Vender el club") if p._confirmar_venta_club else Idiomas.t("🏷️ Vender el club")
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

## La pestaña CAMARÍN: cámaras, clima, clanes, salud mental y jerarquía (desde `Principal`, 27-10).
func _pintar_camarin(c: Club) -> void:
	p._limpiar(p._lista_camarin)
	var v := p.mundo.vestuario
	if v == null:
		return
	## LAS CÁMARAS. Si aceptaste el documental, el vestuario está grabado y a la
	## gente le incomoda. Va lo primero porque explica caídas de moral que si no
	## parecerían salidas de la nada.
	if p.mundo.prensa != null and p.mundo.prensa.hay_camaras():
		var cam := p._texto(12, p.COL_ORO)
		cam.text = Idiomas.t("🎥 Hay cámaras en el vestuario %d semana(s) más. A los más sensibles del plantel les incomoda.") % p.mundo.prensa.semanas_documental
		cam.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		p._lista_camarin.add_child(cam)
	var pl := c.plantilla
	var moral := 60
	var ansi := 0
	if not pl.is_empty():
		var sm := 0
		var sa := 0
		for j in pl:
			sm += j.moral
			sa += v.ansiedad(j)
		moral = int(round(float(sm) / float(pl.size())))
		ansi = int(round(float(sa) / float(pl.size())))
	var cap: Jugador = null
	for j in pl:
		if j.capitan:
			cap = j
			break

	var t := p._texto(11, p.COL_SUAVE)
	t.text = Idiomas.t("CLIMA DEL VESTUARIO")
	p._lista_camarin.add_child(t)
	var gr := GridContainer.new()
	gr.columns = 4
	gr.add_theme_constant_override("h_separation", 14)
	p._lista_camarin.add_child(gr)
	for par in [["Moral media", str(moral)], ["Ansiedad media", str(ansi)],
			["Capitán", p._ui_cantera._apellido(cap.nombre) if cap else "—"], ["Grupos", str(v.camarillas.size())]]:
		var col := VBoxContainer.new()
		gr.add_child(col)
		var et := p._texto(10, p.COL_SUAVE)
		et.text = String(par[0])
		col.add_child(et)
		var va := p._texto(15, p.COL_ROJO if (String(par[0]) == "Ansiedad media" and ansi > 50) else p.COL_TEXTO)
		va.text = String(par[1])
		col.add_child(va)
	p._lista_camarin.add_child(HSeparator.new())
	p._pintar_porque_moral(c)

	var tc := p._texto(11, p.COL_SUAVE)
	tc.text = Idiomas.t("CLANES Y CAMARILLAS")
	p._lista_camarin.add_child(tc)
	if v.camarillas.is_empty():
		var vc := p._texto(12, p.COL_SUAVE)
		vc.text = Idiomas.t("Todavía no hay grupos definidos en el vestuario.")
		p._lista_camarin.add_child(vc)
	for cl: Dictionary in v.camarillas:
		var humor := int(cl.get("humor", 0))
		var lider: Jugador = p.mundo.jugador_por_id(String(cl.get("lider", "")))
		var miembros: Array = cl.get("miembros", [])
		var en_mi_club := 0
		var nombres: Array[String] = []
		for id in miembros:
			var jm := p.mundo.jugador_por_id(String(id))
			if jm != null and jm.club_id == c.id:
				en_mi_club += 1
				if nombres.size() < 7:
					nombres.append(p._ui_cantera._apellido(jm.nombre))
		var estado_txt := "enojados" if humor < -25 else ("contentos" if humor > 15 else "neutrales")
		var estado_col := p.COL_ROJO if humor < -25 else (p.COL_VERDE if humor > 15 else p.COL_ORO)
		var fila := VBoxContainer.new()
		p._lista_camarin.add_child(fila)
		var cab := HBoxContainer.new()
		cab.add_theme_constant_override("separation", 8)
		fila.add_child(cab)
		var nom := p._texto(12, p.COL_TEXTO)
		nom.text = (Idiomas.t("%s  ·  %d jugador") if en_mi_club == 1 else Idiomas.t("%s  ·  %d jugadores")) % [String(cl.get("nombre", "")), en_mi_club]
		nom.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		cab.add_child(nom)
		var et2 := p._texto(11, estado_col)
		et2.text = estado_txt
		cab.add_child(et2)
		var lid := p._texto(11, p.COL_SUAVE)
		lid.text = Idiomas.t("Líder: %s  ·  %s") % [lider.nombre if lider else "—", ", ".join(nombres)]
		lid.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		fila.add_child(lid)
		if humor < -10:
			var cid := String(cl.get("id", ""))
			p._boton("🕊️ Mediar con el grupo", func() -> void: _mediar_clan(cid), fila)
		p._lista_camarin.add_child(HSeparator.new())

	var en_riesgo: Array[Jugador] = []
	for j in pl:
		if v.ansiedad(j) >= 48:
			en_riesgo.append(j)
	en_riesgo.sort_custom(func(a: Jugador, b: Jugador) -> bool: return v.ansiedad(a) > v.ansiedad(b))
	var tm := p._texto(11, p.COL_SUAVE)
	tm.text = Idiomas.t("🧠 SALUD MENTAL")
	p._lista_camarin.add_child(tm)
	if en_riesgo.is_empty():
		var vm := p._texto(12, p.COL_SUAVE)
		vm.text = Idiomas.t("Nadie está pasándolo mal ahora mismo.")
		p._lista_camarin.add_child(vm)
	for j: Jugador in en_riesgo:
		var est: Dictionary = v.estado_mental(j)
		var filaj := HBoxContainer.new()
		filaj.add_theme_constant_override("separation", 8)
		p._lista_camarin.add_child(filaj)
		var nomj := p._texto(12, p.COL_TEXTO)
		nomj.text = Idiomas.t("%s  ·  %s  ·  %d años") % [j.nombre, j.pos_e, j.edad]
		nomj.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		filaj.add_child(nomj)
		var etj := p._texto(11, Color(String(est.get("color", "#8ea595"))))
		etj.text = "%s  %d" % [String(est.get("txt", "")), v.ansiedad(j)]
		filaj.add_child(etj)
		p._boton("Terapia", func() -> void: _dar_terapia_mental(j), filaj)
		p._boton("Descanso mental", func() -> void: _pedir_descanso_mental(j), filaj)
	p._lista_camarin.add_child(HSeparator.new())

	var th := p._texto(11, p.COL_SUAVE)
	th.text = Idiomas.t("JERARQUÍA INTERNA")
	p._lista_camarin.add_child(th)
	var jerarquia := pl.duplicate()
	jerarquia.sort_custom(func(a: Jugador, b: Jugador) -> bool:
		var va2 := float(a.ovr) + float(a.edad) * 1.6 + (25.0 if a.capitan else 0.0)
		var vb2 := float(b.ovr) + float(b.edad) * 1.6 + (25.0 if b.capitan else 0.0)
		return va2 > vb2)
	for i in mini(10, jerarquia.size()):
		var jj: Jugador = jerarquia[i]
		var etiqueta := "referente" if i < 3 else ("influyente" if i < 6 else "periférico")
		p._dato("%d.  %s%s" % [i + 1, "ⓒ " if jj.capitan else "", jj.nombre], "%d  ·  %s" % [jj.ovr, etiqueta], p.COL_TEXTO, p._lista_camarin)
