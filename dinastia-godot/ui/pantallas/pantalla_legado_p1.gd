extends RefCounted
## [Capa 1/3 de `pantalla_legado.gd`] _init, _pintar_inicio, _texto_proximo_compromiso, _pintar_desgaste, _pintar_rival_dt, _pintar_leyenda_viva … (+6)

## INICIO, CARRERA Y LEGADO: la portada, el legado, el rival DT, las filiales, la sucesión, el árbol de habilidades, el fin de carrera y los récords.
##
## Sale de `ui/principal.gd` (mapa de metas 15: el archivo pasaba de
## 15.000 líneas). `p` es la pantalla principal: sus ayudantes (`p._texto`,
## `p._boton`...), el mundo (`p.mundo`) y el repintado (`p._refrescar()`).

var p: Principal

func _init(principal: Principal) -> void:
	p = principal

func _pintar_inicio(c: Club) -> void:
	p._limpiar(p._lista_inicio)
	var liga := p._liga_de(c)
	## EL TABLERO (25-9-2026): próximo partido con los dos escudos, anillos de
	## valoración, la cara de la estrella y la racha. Ver `TableroInicio`.
	TableroInicio.pintar(p._lista_inicio, c, p.mundo, liga, p._ir_a_pestana, p._ver_ficha)
	p._lista_inicio.add_child(HSeparator.new())
	p._ui_cantera._pintar_informe()
	p._lista_inicio.add_child(HSeparator.new())

	## LOS ACCESOS RÁPIDOS. Se marcan en Ajustes y salen aquí, que es donde se
	## usan: entras al club y saltas a lo tuyo sin recorrer seis grupos.
	if not p._favoritos.is_empty():
		var tfav := p._texto(11, Principal.COL_SUAVE)
		tfav.text = Idiomas.t("⭐ ACCESOS RÁPIDOS")
		p._lista_inicio.add_child(tfav)
		var rej := HBoxContainer.new()
		rej.add_theme_constant_override("separation", 4)
		p._lista_inicio.add_child(rej)
		for tab: String in p._favoritos:
			var b := Button.new()
			b.text = tab
			b.add_theme_font_size_override("font_size", 11)
			b.clip_text = true
			b.custom_minimum_size = Vector2(70, 0)
			b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			b.pressed.connect(func() -> void: p._ir_a_pestana(tab))
			rej.add_child(b)
		p._lista_inicio.add_child(HSeparator.new())

	## ÚLTIMOS RESULTADOS. Sale de `Liga.historial`, que se guarda desde la misma
	## tanda que la pantalla de competición: antes el resultado viajaba en una
	## señal y se perdía.
	var tr := p._texto(11, Principal.COL_SUAVE)
	tr.text = Idiomas.t("ÚLTIMOS RESULTADOS")
	p._lista_inicio.add_child(tr)
	var puestos := 0
	for i in range(liga.historial.size() - 1, -1, -1):
		if puestos >= 5:
			break
		for r: Dictionary in liga.historial[i]:
			if r["local"] != c and r["visita"] != c:
				continue
			var gl := int(r["gl"])
			var gv := int(r["gv"])
			var mios := gl if r["local"] == c else gv
			var suyos := gv if r["local"] == c else gl
			var col := Principal.COL_VERDE if mios > suyos else (Principal.COL_ROJO if mios < suyos else Principal.COL_SUAVE)
			p._dato("J%d  %s %d-%d %s" % [i + 1, (r["local"] as Club).nombre, gl, gv, (r["visita"] as Club).nombre],
				"✔" if mios > suyos else ("✕" if mios < suyos else "="), col, p._lista_inicio)
			puestos += 1
	if puestos == 0:
		var vac := p._texto(12, Principal.COL_SUAVE)
		vac.text = Idiomas.t("Aún sin partidos jugados.")
		p._lista_inicio.add_child(vac)
	p._lista_inicio.add_child(HSeparator.new())

	## CORREO RECIENTE: los tres últimos de la bandeja, con el punto de "sin
	## leer". Es el gancho para que el correo no se quede sin abrir nunca.
	var tc := p._texto(11, Principal.COL_SUAVE)
	tc.text = Idiomas.t("CORREO RECIENTE")
	p._lista_inicio.add_child(tc)
	if p._bandeja.is_empty():
		var vac2 := p._texto(12, Principal.COL_SUAVE)
		vac2.text = Idiomas.t("Sin novedades.")
		p._lista_inicio.add_child(vac2)
	else:
		for i in mini(3, p._bandeja.size()):
			var m: Dictionary = p._bandeja[i]
			var b := Button.new()
			b.text = ("●  " if not bool(m.get("leida", false)) else "     ") + String(m.get("titulo", ""))
			b.flat = true
			b.alignment = HORIZONTAL_ALIGNMENT_LEFT
			b.clip_text = true
			b.custom_minimum_size = Vector2(120, 0)
			b.add_theme_font_size_override("font_size", 12)
			b.add_theme_color_override("font_color", p._color_de_paleta(Principal.COL_TEXTO if not bool(m.get("leida", false)) else Principal.COL_SUAVE))
			b.pressed.connect(func() -> void: p._ir_a_pestana("Correo"))
			p._lista_inicio.add_child(b)

## La frase de "qué toca esta semana". Sale del mismo sitio que decide qué se
## juega al pulsar «Dirigir el partido», para que las dos no puedan discrepar.
func _texto_proximo_compromiso(c: Club) -> String:
	if not p.mundo.partido_de_copa().is_empty() and p.mundo.copa != null:
		return "%s · %s" % [p.mundo.copa.nombre, p.mundo.copa.nombre_de_ronda()]
	var liga := p._liga_de(c)
	var par := liga.emparejamiento_de(c)
	if par.is_empty():
		return "Semana sin partido: entrenamiento doble."
	var rival: Club = par[0] if par[0] != c else par[1]
	var de_local: bool = par[0] == c
	return "vs %s  ·  %s  ·  jornada %d de %s" % [
		rival.nombre, "Local" if de_local else "Visita",
		liga.jornada_actual + 1, liga.nombre]

## EL DESGASTE Y EL CURRÍCULUM. Las dos cosas que hacen que esto sea una carrera
## y no una partida: lo que te cuesta el cargo, y por dónde has pasado.
func _pintar_desgaste(r: Roles) -> void:
	p._lista_legado.add_child(HSeparator.new())
	var t := p._texto(11, Principal.COL_SUAVE)
	t.text = Idiomas.t("🔥 DESGASTE EN EL CARGO")
	p._lista_legado.add_child(t)
	p._dato("Nivel", "%d de 100" % r.desgaste,
		Principal.COL_ROJO if r.quemado() else (Principal.COL_ORO if r.desgaste >= 55 else Principal.COL_VERDE), p._lista_legado)
	var d := p._texto(10, Principal.COL_ROJO if r.quemado() else Principal.COL_SUAVE)
	if r.quemado():
		d.text = Idiomas.t("Estás quemado. Duermes mal y se te nota: lo que dices en rueda de prensa vale la mitad. Cambiar de aire lo arregla; seguir aquí, no.")
	elif r.desgaste >= 55:
		d.text = Idiomas.t("Se te empieza a notar el ciclo. Ganar descansa; la funa quema el doble.")
	else:
		d.text = Idiomas.t("Entero. Cada semana en el cargo cansa un poco; ganar lo compensa.")
	d.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	p._lista_legado.add_child(d)

	if r.curriculum.is_empty():
		return
	p._lista_legado.add_child(HSeparator.new())
	var tc := p._texto(11, Principal.COL_SUAVE)
	tc.text = Idiomas.t("📄 CURRÍCULUM")
	p._lista_legado.add_child(tc)
	for i in range(r.curriculum.size() - 1, -1, -1):
		var c: Dictionary = r.curriculum[i]
		var hasta := int(c.get("hasta", 0))
		var l := p._texto(12, Principal.COL_ORO if hasta == 0 else Principal.COL_TEXTO)
		l.text = "%s  ·  %d–%s" % [String(c.get("nombre", "")), int(c.get("desde", 0)),
			"hoy" if hasta == 0 else str(hasta)]
		p._lista_legado.add_child(l)
		if hasta != 0:
			var m := p._texto(10, Principal.COL_SUAVE)
			m.text = Idiomas.t("     %d título(s) al irte  ·  %s") % [int(c.get("trofeos", 0)), String(c.get("motivo", ""))]
			p._lista_legado.add_child(m)

## `vCarrera()`: EL RIVAL PERSONAL. No se elige y no se puede quitar: nace del
## club con el que más te has picado, y a partir de ahí cada cruce se cuenta
## aparte. Es la única estadística del juego que no es del club, es tuya.
func _pintar_rival_dt(r: Roles) -> void:
	if r.rival_dt.is_empty():
		return
	p._lista_legado.add_child(HSeparator.new())
	var t := p._texto(11, Principal.COL_SUAVE)
	t.text = Idiomas.t("👔 TU RIVAL")
	p._lista_legado.add_child(t)
	var c: Club = p.mundo.clubes.get(String(r.rival_dt.get("club_id", "")))
	var n := p._texto(13, Principal.COL_ROJO)
	n.text = "%s  ·  %s" % [String(r.rival_dt.get("nombre", "")), c.nombre if c else "?"]
	p._lista_legado.add_child(n)
	var e := p._texto(10, Principal.COL_SUAVE)
	e.text = String(r.rival_dt.get("estilo", ""))
	e.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	p._lista_legado.add_child(e)
	var pj := int(r.rival_dt.get("pj", 0))
	p._dato("Cara a cara desde %d" % int(r.rival_dt.get("desde", 0)),
		"%d–%d–%d en %d duelo%s" % [int(r.rival_dt.get("g", 0)), int(r.rival_dt.get("e", 0)),
			int(r.rival_dt.get("p", 0)), pj, "" if pj == 1 else "s"],
		Principal.COL_TEXTO, p._lista_legado)
	var tension := int(r.rival_dt.get("tension", 0))
	p._dato("Tensión", "%d de 100" % tension,
		Principal.COL_ROJO if tension >= 80 else (Principal.COL_ORO if tension >= 60 else Principal.COL_SUAVE), p._lista_legado)
	if tension >= 80 and not p._modo_experto:
		var av := p._texto(10, Principal.COL_ROJO)
		av.text = Idiomas.t("Está a punto de salirse de la cancha. El próximo cruce puede acabar en el túnel y con los micrófonos abiertos.")
		av.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		p._lista_legado.add_child(av)

## LA LEYENDA VIVA. Un ex jugador ligado al club de por vida. No entrena, no
## fila y no sale en ninguna estadística: viene, habla con los chicos y está.
func _pintar_leyenda_viva(r: Roles) -> void:
	p._lista_legado.add_child(HSeparator.new())
	var t := p._texto(11, Principal.COL_SUAVE)
	t.text = Idiomas.t("🕰️ LEYENDA VIVA DEL CLUB")
	p._lista_legado.add_child(t)
	if not r.leyenda_viva.is_empty():
		var n := p._texto(13, Principal.COL_ORO)
		n.text = "%s  ·  %s" % [String(r.leyenda_viva.get("nombre", "")), String(r.leyenda_viva.get("pos", ""))]
		p._lista_legado.add_child(n)
		p._dato("Ligado al club desde", str(int(r.leyenda_viva.get("desde", 0))), Principal.COL_SUAVE, p._lista_legado)
		var d := p._texto(10, Principal.COL_SUAVE)
		d.text = Idiomas.t("Cada seis semanas se sienta con un juvenil del plantel. Le sube la moral y a veces algo más.")
		d.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		p._lista_legado.add_child(d)
		return
	## Solo veteranos de la casa: nombrar leyenda a un fichaje de enero sería
	## un chiste, y el juego se lo tomaría en serio.
	var mio := p.mundo.mi_club()
	var candidatos: Array[Jugador] = []
	if mio != null:
		for j: Jugador in mio.plantilla:
			if j.edad >= 32 and j.club_formacion == mio.id:
				candidatos.append(j)
	if candidatos.is_empty():
		var vac := p._texto(10, Principal.COL_SUAVE)
		vac.text = Idiomas.t("Todavía no hay a quién nombrar. Hace falta un veterano de 32 años o más formado en la casa.")
		vac.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		p._lista_legado.add_child(vac)
		return
	var ex := p._texto(10, Principal.COL_SUAVE)
	ex.text = Idiomas.t("Nombrar a alguien lo liga al club de por vida. La hinchada lo agradece de inmediato.")
	ex.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	p._lista_legado.add_child(ex)
	for j: Jugador in candidatos:
		var quien := j
		var fila := HBoxContainer.new()
		fila.add_theme_constant_override("separation", 6)
		p._lista_legado.add_child(fila)
		var l := p._texto(12, Principal.COL_TEXTO)
		l.text = Idiomas.t("%s  ·  %s, %d años") % [j.nombre, j.pos_e, j.edad]
		l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		l.clip_text = true
		fila.add_child(l)
		var b := Button.new()
		b.text = Idiomas.t("Nombrar")
		b.add_theme_font_size_override("font_size", 11)
		b.custom_minimum_size = Vector2(90, 0)
		b.pressed.connect(func() -> void:
			var msg := r.nombrar_leyenda_viva(quien)
			if msg != "":
				p._escribir("[color=#e05555]No se pudo: %s.[/color]" % msg)
			p._refrescar())
		fila.add_child(b)

func _comprar_dt(clave: String) -> void:
	var problema := p.mundo.roles.comprar_dt(clave)
	if problema != "":
		p._escribir("[color=#e05555]No se pudo: %s.[/color]" % problema)
	p._refrescar()

## `vCarrera()`: tu patrimonio personal y en qué lo inviertes.
##
## Hasta ahora el entrenador no cobraba: el club pagaba sueldos y él no tenía
## bolsillo. Y sin bolsillo no hay carrera personal, solo gestión de un club.
##
## Lo que se compra aquí NO mejora al equipo: mejora al ENTRENADOR, y te sigue
## cuando cambias de banquillo. Es dinero tuyo, no del club, y esa separación es
## todo el sentido de la pantalla.
func _pintar_patrimonio_dt(r: Roles) -> void:
	p._lista_legado.add_child(HSeparator.new())
	var t := p._texto(11, Principal.COL_SUAVE)
	t.text = Idiomas.t("💼 TU PATRIMONIO")
	p._lista_legado.add_child(t)
	p._dato("Ahorros", p._dinero(r.patrimonio), Principal.COL_ORO, p._lista_legado)
	p._dato("Tu sueldo", "%s / semana" % p._dinero(r.sueldo_semanal()), Principal.COL_TEXTO, p._lista_legado)
	p._dato("Semanas dirigiendo", str(r.semanas_trabajadas), Principal.COL_SUAVE, p._lista_legado)
	var lic := ["ninguna", "Licencia B", "Licencia A", "Licencia PRO"]
	p._dato("Titulación", String(lic[clampi(r.licencia, 0, 3)]),
		Principal.COL_VERDE if r.licencia > 0 else Principal.COL_SUAVE, p._lista_legado)
	if not p._modo_experto:
		var ex := p._texto(10, Principal.COL_SUAVE)
		ex.text = Idiomas.t("Es dinero TUYO, no del club. Lo que compres aquí te sigue cuando cambies de banquillo.")
		ex.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		p._lista_legado.add_child(ex)
	for f: Array in Roles.COMPRAS_DT:
		var clave := String(f[0])
		var tengo := r.tiene(clave)
		var fila := HBoxContainer.new()
		fila.add_theme_constant_override("separation", 6)
		p._lista_legado.add_child(fila)
		var n := p._texto(12, Principal.COL_VERDE if tengo else Principal.COL_TEXTO)
		n.text = "%s%s" % ["✔  " if tengo else "     ", String(f[1])]
		n.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		n.clip_text = true
		n.tooltip_text = String(f[3])
		fila.add_child(n)
		var b := Button.new()
		b.text = Idiomas.t("Puesto") if tengo else p._dinero(int(f[2]))
		b.add_theme_font_size_override("font_size", 11)
		b.disabled = tengo or r.patrimonio < int(f[2])
		b.custom_minimum_size = Vector2(96, 0)
		b.pressed.connect(func() -> void: _comprar_dt(clave))
		fila.add_child(b)
		if not tengo and not p._modo_experto:
			var d := p._texto(10, Principal.COL_SUAVE)
			d.text = "     %s" % String(f[3])
			d.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			p._lista_legado.add_child(d)

## LOS CLUBES FILIALES. `Entrenamiento.puede_comprar_filiales()` estaba escrita
## desde el porte y no la llamaba nadie: la habilidad «Magnate» del árbol se
## podía comprar con un punto y no servía absolutamente para nada.
func _pintar_filiales(r: Roles) -> void:
	if p.mundo.entrenamiento == null:
		return
	var puede := p.mundo.entrenamiento.puede_comprar_filiales()
	if not puede and r.filiales.is_empty():
		return
	p._lista_legado.add_child(HSeparator.new())
	var t := p._texto(11, Principal.COL_SUAVE)
	t.text = Idiomas.t("🏦 TUS CLUBES")
	p._lista_legado.add_child(t)
	if not r.filiales.is_empty():
		for cid: String in r.filiales:
			var c: Club = p.mundo.clubes.get(cid)
			if c == null:
				continue
			p._dato(c.nombre, "rep %d  ·  dividendo %s cada %d semanas" % [
				c.rep, p._dinero(c.rep * c.rep * 40), Roles.SEMANAS_DIVIDENDO],
				Principal.COL_ORO, p._lista_legado)
	if not puede:
		var av := p._texto(10, Principal.COL_SUAVE)
		av.text = Idiomas.t("Para comprar un club hace falta la habilidad «Magnate» del árbol de entrenador.")
		av.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		p._lista_legado.add_child(av)
		return
	if not p._modo_experto:
		var ex := p._texto(10, Principal.COL_SUAVE)
		ex.text = Idiomas.t("Se compran con TU dinero, no con el del club. Cuesta tres veces la caja de referencia del club y devuelve dividendos cada tres meses.")
		ex.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		p._lista_legado.add_child(ex)
	## Los cinco más baratos que todavía no son tuyos: la lista entera serían
	## trescientos ochenta y tres botones.
	var comprables: Array[Club] = []
	for c2: Club in p.mundo.clubes.values():
		if c2.id == p.mundo.mi_club_id or r.filiales.has(c2.id):
			continue
		comprables.append(c2)
	comprables.sort_custom(func(a: Club, b: Club) -> bool: return a.rep < b.rep)
	for i in mini(5, comprables.size()):
		var c3: Club = comprables[i]
		var precio := r.precio_filial(c3)
		var fila := HBoxContainer.new()
		fila.add_theme_constant_override("separation", 6)
		p._lista_legado.add_child(fila)
		var l2 := p._texto(12, Principal.COL_TEXTO)
		l2.text = Idiomas.t("%s  ·  rep %d") % [c3.nombre, c3.rep]
		l2.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		l2.clip_text = true
		fila.add_child(l2)
		var b2 := Button.new()
		b2.text = p._dinero(precio)
		b2.add_theme_font_size_override("font_size", 11)
		b2.disabled = r.patrimonio < precio
		b2.custom_minimum_size = Vector2(110, 0)
		b2.pressed.connect(func() -> void:
			var msg := r.comprar_filial(c3)
			if msg != "":
				p._escribir("[color=#e05555]No se pudo comprar: %s.[/color]" % msg)
			p._refrescar())
		fila.add_child(b2)

## En Legado queda un resumen con el acceso al árbol, que vive en MI VIDA.
func _pintar_acceso_arbol() -> void:
	## El álbum de cromos y el museo de todas tus carreras (`Meta`).
	var sobres := int(Meta.leer()["sobres"])
	var alb := Button.new()
	alb.text = Idiomas.t("📒 Álbum de cromos y museo de tus carreras") + ((Idiomas.t("  ·  🎁 %d sobre") if sobres == 1 else Idiomas.t("  ·  🎁 %d sobres")) % sobres if sobres > 0 else "")
	alb.pressed.connect(func() -> void: PanelMeta.abrir(p, p.mundo))
	p._lista_legado.add_child(alb)
	var e := p.mundo.entrenamiento
	if e == null:
		return
	var hb := HBoxContainer.new()
	p._lista_legado.add_child(hb)
	var t := p._texto(12, Principal.COL_ORO if e.dt_puntos > 0 else Principal.COL_SUAVE)
	t.text = Idiomas.t("🎓 Habilidades de entrenador · %d punto(s) por gastar") % e.dt_puntos
	t.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hb.add_child(t)
	var b := Button.new()
	b.text = Idiomas.t("Ver el árbol")
	b.pressed.connect(func() -> void:
		p._elegir_grupo("vida")
		p._ir_a_chip({"tab": "Habilidades", "label": "Habilidades"}))
	hb.add_child(b)
	p._lista_legado.add_child(HSeparator.new())

func _homenajear(nombre: String) -> void:
	var problema := p.mundo.roles.homenajear(nombre)
	if problema != "":
		p._escribir("[color=#e05555]No se pudo hacer el homenaje: %s.[/color]" % problema)
	p._refrescar()

## Las leyendas de TU club, con el botón de homenaje. Se filtran por club a
## propósito: homenajear en el Madrid a una leyenda del Boca no significa nada.
func _pintar_homenajes(r: Roles) -> void:
	var th := p._texto(11, Principal.COL_SUAVE)
	th.text = Idiomas.t("🎖️ HOMENAJES")
	p._lista_legado.add_child(th)
	var c := p.mundo.mi_club()
	var mias: Array[Dictionary] = []
	if p.mundo.cantera != null:
		for l: Dictionary in p.mundo.cantera.leyendas:
			if String(l.get("club", "")) == c.id and mias.size() < 6:
				mias.append(l)
	if mias.is_empty():
		var vac := p._texto(12, Principal.COL_SUAVE)
		vac.text = Idiomas.t("Sin leyendas registradas en este club todavía.")
		p._lista_legado.add_child(vac)
	else:
		var coste := Eco.escalar(Roles.COSTE_HOMENAJE, c.rep)
		for l2: Dictionary in mias:
			var fila := HBoxContainer.new()
			fila.add_theme_constant_override("separation", 8)
			p._lista_legado.add_child(fila)
			var nom := p._texto(12, Principal.COL_TEXTO)
			nom.text = Idiomas.t("%s  ·  %s · nivel %d") % [String(l2.get("nombre", "")), String(l2.get("pos", "")), int(l2.get("nivel", 1))]
			nom.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			fila.add_child(nom)
			var b := Button.new()
			b.text = Idiomas.t("Homenajear  %s") % p._dinero(coste)
			b.add_theme_font_size_override("font_size", 11)
			b.disabled = c.saldo < coste
			var quien := String(l2.get("nombre", ""))
			b.pressed.connect(func() -> void: _homenajear(quien))
			fila.add_child(b)
		var nota := p._texto(10, Principal.COL_SUAVE)
		nota.text = Idiomas.t("Un homenaje llena el estadio, sube el ánimo y la moral del plantel, y deja al club un poco más grande.")
		nota.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		p._lista_legado.add_child(nota)
	p._lista_legado.add_child(HSeparator.new())
