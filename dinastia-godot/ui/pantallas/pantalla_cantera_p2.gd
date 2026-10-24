extends "res://ui/pantallas/pantalla_cantera_p1.gd"
## [Capa 2/3 de `pantalla_cantera.gd`] _pintar_cantera, _cambiar_rol_prometido, _pintar_roles_prometidos, _pintar_agencias, _pintar_contratos, _apellido … (+2)

func _pintar_cantera(c: Club) -> void:
	p._limpiar(p._lista_cantera)
	var ct := p.mundo.cantera
	if ct == null:
		return
	## LA ACADEMIA (10-16 años) va primero: es la cantera ANTES de la cantera,
	## y la que decide cómo llegan los que aparecen más abajo.
	PanelAcademia.pintar(p._lista_cantera, p.mundo, p._ui_ficha._paleta_ficha(), func(error: String) -> void:
		if error != "":
			p._escribir("[color=#e05555]%s.[/color]" % error.capitalize())
		p._refrescar())

	## "LEYENDAS DEL CLUB" -su propia tarjeta en `vHistoria()` de vistas.js-:
	## `Cantera.leyendas` alimenta de verdad la camada anual (`registrar_retiro()`
	## mete a cada figura retirada, `camada_anual()` puede darle un hijo con su
	## apellido años después) pero hasta esta tanda no había ni una fila en
	## ningún sitio del juego que dijera qué leyendas tiene el club esperando:
	## el jugador nunca se enteraba de que Fulano se retiró como figura y que su
	## hijo podría debutar en unos años.
	var leyendas_del_club: Array[Dictionary] = []
	for l: Dictionary in ct.leyendas:
		if String(l.get("club_id", "")) == c.id:
			leyendas_del_club.append(l)
	if not leyendas_del_club.is_empty():
		var tley := p._texto(11, Principal.COL_ORO)
		tley.text = Idiomas.t("LEYENDAS DEL CLUB")
		p._lista_cantera.add_child(tley)
		for l: Dictionary in leyendas_del_club:
			var lf := p._texto(12, Principal.COL_SUAVE if bool(l.get("usado", false)) else Principal.COL_TEXTO)
			lf.text = Idiomas.t("%s  ·  %s  ·  nivel %d%s") % [
				String(l.get("nombre", "")), String(l.get("pos", "")), int(l.get("nivel", 0)),
				Idiomas.t("  · su hijo ya debutó") if bool(l.get("usado", false)) else Idiomas.t("  · puede tener un hijo en %d") % int(l.get("anio_hijo", 0))]
			lf.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			p._lista_cantera.add_child(lf)
		p._lista_cantera.add_child(HSeparator.new())

	var camada := ct.camada_actual()
	if not camada.is_empty():
		var tc := p._texto(11, Principal.COL_ORO)
		tc.text = Idiomas.t("LA CAMADA DE ESTE AÑO")
		p._lista_cantera.add_child(tc)
		for j: Jugador in camada:
			p._lista_cantera.add_child(_fila_canterano(j, ct, c))
		p._lista_cantera.add_child(HSeparator.new())

	var listos := ct.candidatos_a_debutar()
	if not listos.is_empty():
		var tl := p._texto(11, Principal.COL_VERDE)
		tl.text = Idiomas.t("LISTOS PARA DEBUTAR")
		p._lista_cantera.add_child(tl)
		var nombres: Array[String] = []
		for j: Jugador in listos:
			nombres.append(j.nombre)
		var ll := p._texto(12, Principal.COL_TEXTO)
		ll.text = ", ".join(nombres)
		ll.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		p._lista_cantera.add_child(ll)
		p._lista_cantera.add_child(HSeparator.new())

	var cats := ct.por_categoria(c)
	for clave: String in cats:
		var datos: Dictionary = cats[clave]
		var jugadores: Array = datos["jugadores"]
		if jugadores.is_empty():
			continue
		var tcat := p._texto(11, Principal.COL_SUAVE)
		tcat.text = String(datos["nombre"]).to_upper()
		p._lista_cantera.add_child(tcat)
		for j: Jugador in jugadores:
			p._lista_cantera.add_child(_fila_canterano(j, ct, c))
	## Las dinastías van al final: se leen después de la camada, que es lo que
	## se viene a mirar aquí todas las semanas.
	_pintar_linaje(c)

func _cambiar_rol_prometido(j: Jugador, rol: String) -> void:
	var r: Dictionary = p.mundo.vestuario.cambiar_rol(j, rol)
	var txt := String(r.get("txt", ""))
	if txt != "":
		var col := "#4caf6d" if bool(r.get("ok", false)) else "#e05555"
		p._escribir("[color=%s][b]%s.[/b][/color] %s" % [col, j.nombre, txt])
	p._refrescar()

## CONTRATOS: cesiones, cláusulas de rescisión y a quién prestar. La letra
## pequeña de un fichaje, que hasta hoy corría sola por dentro y no se podía
## ni ver ni decidir desde ningún lado.
## Los ROLES PROMETIDOS de `vContratos()`: qué papel le has jurado a cada uno.
##
## `Vestuario` lleva la promesa, la ventana de cumplimiento y el castigo de moral
## desde hace tanto que solo la renovación escribía ahí: fuera de la mesa de
## negociación no había forma de cambiarle el papel a nadie. Y es media mitad del
## sistema, porque prometer titular a un suplente y no darle minutos es
## exactamente lo que revienta un vestuario.
##
## `acepta_rol()` es lo que hace que no sea un desplegable tonto: el mejor de su
## puesto no acepta menos que titular, y a un quinto no le puedes prometer ser
## intocable porque sabe que no lo vas a cumplir.
func _pintar_roles_prometidos(c: Club) -> void:
	var v := p.mundo.vestuario
	if v == null:
		return
	var tabla := v.tabla_roles()
	if tabla.is_empty():
		return
	var t := p._texto(11, Principal.COL_SUAVE)
	t.text = Idiomas.t("ROLES PROMETIDOS")
	p._lista_contratos.add_child(t)
	var ex := p._texto(10, Principal.COL_SUAVE)
	ex.text = Idiomas.t("Lo que le has prometido a cada uno. Bajarle el escalafón cuesta moral en el acto; subírselo la sube. Y prometer sin cumplir se paga después.")
	ex.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	p._lista_contratos.add_child(ex)
	var plantel := c.plantilla.duplicate()
	plantel.sort_custom(func(a: Jugador, b: Jugador) -> bool: return a.ovr > b.ovr)
	for j: Jugador in plantel:
		var actual := v.rol_plantel(j)
		var fila := HBoxContainer.new()
		fila.add_theme_constant_override("separation", 6)
		p._lista_contratos.add_child(fila)
		fila.add_child(p._retrato(j, 22))
		var nom := p._texto(12, Principal.COL_TEXTO)
		nom.text = "%s  %s  ·  %d" % [j.pos_e, j.nombre, j.ovr]
		nom.custom_minimum_size = Vector2(170, 0)
		fila.add_child(nom)
		var op := OptionButton.new()
		op.add_theme_font_size_override("font_size", 11)
		op.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var elegido := 0
		for n in tabla.size():
			var f: Array = tabla[n]
			op.add_item(String(f[1]), n)
			if String(f[0]) == actual:
				elegido = n
			## Los que no aceptaría salen en la lista pero apagados: ver lo que
			## NO puedes ofrecerle explica su sitio en el plantel mejor que
			## cualquier texto.
			if not bool(v.acepta_rol(j, String(f[0]))["ok"]):
				op.set_item_disabled(n, true)
		op.selected = elegido
		var jug := j
		var filas := tabla
		op.item_selected.connect(func(idx: int) -> void:
			_cambiar_rol_prometido(jug, String((filas[idx] as Array)[0])))
		fila.add_child(op)
		## Los minutos que exige el papel: es la promesa concreta, y lo que se
		## va a comprobar cuando toque.
		var def := v.def_rol(actual)
		if not def.is_empty():
			var mn := p._texto(11, Principal.COL_SUAVE)
			mn.text = Idiomas.t("%d%% min.") % int(def[3])
			mn.custom_minimum_size = Vector2(56, 0)
			fila.add_child(mn)
	p._lista_contratos.add_child(HSeparator.new())

## LA GUERRA DE AGENTES. `Cantera.sortear_guerra_agentes()` corre CADA SEMANA
## desde `Mundo` y presiona de verdad: un representante con dos o más clientes
## tuyos te exige cosas. Pero `agencias_del_plantel()` -quién controla a quién y
## cuánto confía en ti- no la llamaba ninguna pantalla, así que la presión te
## llegaba sin que pudieras ver de dónde venía ni prepararte.
func _pintar_agencias(c: Club) -> void:
	if p.mundo.cantera == null:
		return
	var lista := p.mundo.cantera.agencias_del_plantel()
	if lista.is_empty():
		return
	var t := p._texto(11, Principal.COL_SUAVE)
	t.text = Idiomas.t("🕴️ AGENCIAS DEL PLANTEL")
	p._lista_contratos.add_child(t)
	var ex := p._texto(10, Principal.COL_SUAVE)
	ex.text = Idiomas.t("Un representante con dos o más clientes tuyos tiene con qué apretarte. Aquí se ve quién los tiene.")
	ex.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	p._lista_contratos.add_child(ex)
	for f: Dictionary in lista:
		var jugadores: Array = f["jugadores"]
		var ag: Dictionary = f["agente"]
		var conf := int(f.get("confianza", 50))
		## En rojo los que tienen fuerza para exigir: dos clientes o más es
		## exactamente el umbral que usa el sorteo semanal.
		var peligro := jugadores.size() >= 2
		var l := p._texto(12, Principal.COL_ROJO if peligro and conf < 45 else Principal.COL_TEXTO)
		l.text = Idiomas.t("%s  ·  %s  ·  %d jugador(es)  ·  confianza %d") % [
			String(ag.get("nombre", "un representante")), String(ag.get("perfil", "")),
			jugadores.size(), conf]
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		p._lista_contratos.add_child(l)
		var nombres: Array[String] = []
		for j: Jugador in jugadores:
			nombres.append(j.nombre)
		var n := p._texto(10, Principal.COL_SUAVE)
		n.text = "    " + ", ".join(nombres)
		n.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		p._lista_contratos.add_child(n)
	p._lista_contratos.add_child(HSeparator.new())

func _pintar_contratos(c: Club) -> void:
	p._limpiar(p._lista_contratos)
	_pintar_agencias(c)
	_pintar_roles_prometidos(c)
	var ce := p.mundo.cesiones
	if ce == null:
		return

	var fuera := ce.cedidos_de(c.id)
	if not fuera.is_empty():
		var tf := p._texto(11, Principal.COL_SUAVE)
		var ahorro := ce.ahorro_salarial(c.id)
		tf.text = Idiomas.t("CEDIDOS FUERA  ·  te ahorras %s/semana") % p._dinero(ahorro)
		p._lista_contratos.add_child(tf)
		for fila: Dictionary in fuera:
			var j: Jugador = fila["jugador"]
			var destino: Club = fila["club"]
			var d: Dictionary = fila["cesion"]
			var tipo := String(d.get("tipo", ""))
			var letra := "opción de compra" if tipo == Cesiones.CESION_OPCION \
				else ("obligación de compra" if tipo == Cesiones.CESION_OBLIGA else "préstamo simple")
			var l := p._texto(12, Principal.COL_TEXTO)
			l.text = Idiomas.t("%s  ·  en %s  ·  %s  ·  vuelve en %d") % [j.nombre, destino.nombre, letra, int(d.get("vuelve", 0))]
			l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			p._lista_contratos.add_child(l)
		p._lista_contratos.add_child(HSeparator.new())

	## A quién prestar: juveniles hasta 21 -formación, cesión simple- y gente que
	## no juega -ya no es formación, es venta a plazo con opción u obligación.
	var candidatos_prestamo := c.plantilla.filter(func(j: Jugador) -> bool:
		return not ce.esta_cedido(j.id) and j.edad <= Cesiones.EDAD_CANTERANO)
	var candidatos_venta := c.plantilla.filter(func(j: Jugador) -> bool:
		return not ce.esta_cedido(j.id) and j.edad > Cesiones.EDAD_CANTERANO and j.partidos == 0)
	## Ceder es una decisión de mercado como fichar o vender: el mismo permiso.
	var puede_ceder := p.mundo.roles == null or p.mundo.roles.puede_fichar()
	if not puede_ceder:
		var np := p._texto(12, Principal.COL_SUAVE)
		np.text = String(p.mundo.roles.motivo_bloqueo("fichar"))
		np.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		p._lista_contratos.add_child(np)
		p._lista_contratos.add_child(HSeparator.new())
	elif not candidatos_prestamo.is_empty() or not candidatos_venta.is_empty():
		var tc := p._texto(11, Principal.COL_SUAVE)
		tc.text = Idiomas.t("A QUIÉN CEDER")
		p._lista_contratos.add_child(tc)
		for j: Jugador in candidatos_prestamo:
			var fila2 := HBoxContainer.new()
			fila2.add_theme_constant_override("separation", 8)
			p._lista_contratos.add_child(fila2)
			var nom := p._texto(12, Principal.COL_TEXTO)
			nom.text = Idiomas.t("%s  ·  %d años  ·  cantera") % [j.nombre, j.edad]
			nom.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			fila2.add_child(nom)
			p._boton("Ceder a préstamo", func() -> void: p._ui_finanzas._ceder_canterano(j), fila2)
		for j: Jugador in candidatos_venta:
			var fila3 := HBoxContainer.new()
			fila3.add_theme_constant_override("separation", 6)
			p._lista_contratos.add_child(fila3)
			var nom2 := p._texto(12, Principal.COL_SUAVE)
			nom2.text = Idiomas.t("%s  ·  %d años  ·  0 partidos") % [j.nombre, j.edad]
			nom2.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			fila3.add_child(nom2)
			p._boton("Con opción", func() -> void: p._ui_finanzas._ceder_con_opcion(j, Cesiones.CESION_OPCION), fila3)
			p._boton("Con obligación", func() -> void: p._ui_finanzas._ceder_con_opcion(j, Cesiones.CESION_OBLIGA), fila3)
		p._lista_contratos.add_child(HSeparator.new())

	## RENOVACIONES. `Cantera.pide_para_renovar()` llevaba tiempo sabiendo
	## calcular lo que pide cada uno -sueldo actual, recargo por moral baja y por
	## rendir por encima del club, y el multiplicador de su agente- y no había
	## forma de decirle que sí. Un contrato que se acaba y no se puede renovar es
	## un jugador que se pierde solo.
	##
	## Se listan los que entran en su último año, que son los que urgen.
	if ce != null and p.mundo.cantera != null and puede_ceder:
		var por_renovar := c.plantilla.filter(func(j: Jugador) -> bool: return j.anios_contrato <= 1)
		var tr := p._texto(11, Principal.COL_SUAVE)
		tr.text = Idiomas.t("RENOVACIONES  ·  último año de contrato")
		p._lista_contratos.add_child(tr)
		if por_renovar.is_empty():
			var sin := p._texto(12, Principal.COL_SUAVE)
			sin.text = Idiomas.t("Nadie termina contrato esta temporada.")
			p._lista_contratos.add_child(sin)
		for j: Jugador in por_renovar:
			var pide := p.mundo.cantera.pide_para_renovar(j)
			var fila_r := HBoxContainer.new()
			fila_r.add_theme_constant_override("separation", 6)
			p._lista_contratos.add_child(fila_r)
			var nr := p._texto(12, Principal.COL_TEXTO)
			nr.text = Idiomas.t("%s  ·  %d años  ·  media %d  ·  cobra %s → pide %s") % [
				j.nombre, j.edad, j.ovr, p._dinero(j.sueldo), p._dinero(pide)]
			nr.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			fila_r.add_child(nr)
			p._boton("Renovar", func() -> void: p._ui_club_vida._renovar(j, false), fila_r)
			## Con cláusula cobra un 10% menos: le pones precio de salida y a
			## cambio te ahorras ficha. Es la decisión, no un adorno.
			p._boton("Con cláusula (−10%)", func() -> void: p._ui_club_vida._renovar(j, true), fila_r)
		p._lista_contratos.add_child(HSeparator.new())

	## Las cláusulas de tu plantel: la protección va al revés que un fichaje, se
	## paga para que NADIE pueda llevarse a tu figura por la puerta de atrás.
	var tcl := p._texto(11, Principal.COL_SUAVE)
	tcl.text = Idiomas.t("CLÁUSULAS DE RESCISIÓN")
	p._lista_contratos.add_child(tcl)
	var orden := c.plantilla.duplicate()
	orden.sort_custom(func(a: Jugador, b: Jugador) -> bool: return a.ovr > b.ovr)
	for j: Jugador in orden:
		var clau := ce.clausula_de(j)
		var fila4 := HBoxContainer.new()
		fila4.add_theme_constant_override("separation", 8)
		p._lista_contratos.add_child(fila4)
		var nom3 := p._texto(12, Principal.COL_TEXTO if clau > 0 else Principal.COL_SUAVE)
		nom3.text = "%s  ·  %s" % [j.nombre, p._dinero(clau) if clau > 0 else Idiomas.t("sin cláusula")]
		nom3.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		fila4.add_child(nom3)
		var b := Button.new()
		b.text = Idiomas.t("Blindar") if clau > 0 else Idiomas.t("Pactar cláusula")
		b.add_theme_font_size_override("font_size", 11)
		b.pressed.connect(func() -> void: p._ui_finanzas._pactar_clausula_propia(j))
		fila4.add_child(b)

func _apellido(nombre: String) -> String:
	var partes := nombre.split(" ")
	return partes[partes.size() - 1] if not partes.is_empty() else nombre

func _alternar_comparar(j: Jugador) -> void:
	if p._comparar_ids.has(j.id):
		p._comparar_ids.erase(j.id)
	elif p._comparar_ids.size() < 3:
		p._comparar_ids.append(j.id)
	(self as PantallaCantera)._pintar_comparar()
	p._ver_ficha(j)

## Una fila del comparador: etiqueta a la izquierda, un valor por jugador, con
## el mejor resaltado en verde -`mayor_mejor=false` para Edad y Sueldo, donde
## menos es mejor-. Los valores no numéricos (el "?" de una proyección sin
## ojear) cuentan como 0 y nunca ganan el resaltado, igual que `+v||0` en el
## HTML.
func _fila_comparar(g: GridContainer, jugadores: Array[Jugador], etiqueta: String, valor_de: Callable,
		mayor_mejor: bool = true, formatear: Callable = Callable()) -> void:
	p._celda(g, etiqueta, Principal.COL_SUAVE)
	var valores: Array = []
	var numeros: Array[float] = []
	for j in jugadores:
		var v: Variant = valor_de.call(j)
		valores.append(v)
		numeros.append(float(v) if (v is int or v is float) else 0.0)
	var mejor := numeros[0]
	for n in numeros:
		if (mayor_mejor and n > mejor) or (not mayor_mejor and n < mejor):
			mejor = n
	## Igual que `(+v||0)===mejor` en el HTML: si todos empatan -incluido un
	## "?" contra otro "?"- se resaltan todos, no ninguno. No es un caso raro
	## que valga la pena tratar distinto, es lo que ya hacía el original.
	for i in valores.size():
		var texto: String = formatear.call(valores[i]) if formatear.is_valid() else str(valores[i])
		p._celda(g, texto, Principal.COL_VERDE if numeros[i] == mejor else Principal.COL_TEXTO, true)
