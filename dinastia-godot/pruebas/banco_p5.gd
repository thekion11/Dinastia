extends "res://pruebas/banco_p4.gd"
## (Parte 5 de 25 de `banco.gd`.)

## `vBanco()` del HTML: creditos, cuota francesa y el camino a la liquidacion.
## El motor (`nucleo/banco.gd`) y la pantalla ya estaban completos -ya gateaba
## el mercado de fichajes en mora, `_motivo_fichaje_bloqueado()` lo usa esta
## misma sesion-, pero no tenia ni una prueba funcional propia: solo un ida y
## vuelta de guardado que comprobaba la serializacion, no la matematica de la
## deuda ni la escalada a la liquidacion.
func _probar_banco() -> void:
	_titulo("EL BANCO: CUOTA FRANCESA, MORA Y LIQUIDACION")

	## LA CUOTA FRANCESA. Con interes cero se reparte a partes iguales -el caso
	## limite de la propia formula-; con interes, la cuota exacta se puede
	## verificar a mano: 1.000.000 al 1% en 12 cuotas da 88.849 con la formula
	## c = D*i / (1-(1+i)^-n).
	var c0 := Banco.cuota_francesa(1200000, 0.0, 12)
	_comprobar(c0 == 100000, "interes cero reparte a partes iguales (%d)" % c0)
	var c1 := Banco.cuota_francesa(1000000, 0.01, 12)
	_comprobar(absi(c1 - 88849) <= 1, "la cuota francesa calcula lo que calcula la formula (%d, se esperaban 88849)" % c1)

	var m := Mundo.new()
	m.generar(["CHI"], 4242)
	var c: Club = m.ligas[0].clubes[0]
	c.saldo = 500000
	var b := Banco.new()

	## PEDIR: entra el monto, la cuota queda fijada, y hay tope de dos lineas.
	var caja_antes := c.saldo
	var err_pedir := b.pedir(0, c)
	_comprobar(err_pedir == "", "pedir un credito de una linea valida no da error (%s)" % err_pedir)
	_comprobar(c.saldo > caja_antes, "el monto del credito entra a la caja (%d -> %d)" % [caja_antes, c.saldo])
	_comprobar(b.prestamos.size() == 1, "queda un prestamo anotado")
	var p0: Dictionary = b.prestamos[0]
	_comprobar(int(p0["cuota"]) == Banco.cuota_francesa(int(p0["deuda"]), float(p0["tasa"]), int(p0["restan"])),
		"la cuota guardada coincide con la formula sobre el monto y plazo de verdad")
	_comprobar(b.pedir(1, c) == "", "se puede pedir una segunda linea")
	_comprobar(b.pedir(2, c) != "", "la tercera linea se niega: tope de dos")

	## EL BONO SOCIAL: no cuenta aparte del tope -ocupa una de las dos lineas-,
	## y solo puede haber uno vigente.
	var b2 := Banco.new()
	b2.pedir(0, c)
	_comprobar(b2.emitir_bono(c) == "", "con una linea abierta todavia cabe el bono social")
	_comprobar(b2.emitir_bono(c) != "", "no se puede emitir un segundo bono social a la vez")

	## PREPAGAR: cancela de golpe y saca el credito de la lista. Si no hay caja
	## para la deuda pendiente, se niega.
	var b3 := Banco.new()
	var c3: Club = m.ligas[0].clubes[1]
	c3.saldo = 0
	b3.pedir(0, c3)
	var deuda3 := int((b3.prestamos[0] as Dictionary)["deuda"])
	c3.saldo = deuda3 - 1
	_comprobar(b3.prepagar(0, c3) != "", "prepagar con menos caja de la que debes se niega")
	c3.saldo = deuda3
	var caja_antes_prepago := c3.saldo
	_comprobar(b3.prepagar(0, c3) == "", "con caja de sobra, prepagar se hace")
	_comprobar(b3.prestamos.is_empty(), "el credito prepagado desaparece de la lista")
	_comprobar(c3.saldo == caja_antes_prepago - deuda3, "prepagar cobra exactamente la deuda pendiente")

	## RENEGOCIAR: baja la cuota, sube la tasa y el plazo, y solo una vez.
	var b4 := Banco.new()
	var c4: Club = m.ligas[0].clubes[2]
	c4.saldo = 500000
	b4.pedir(1, c4)
	var cuota_antes := int((b4.prestamos[0] as Dictionary)["cuota"])
	b4.renegociar(0)
	var p4: Dictionary = b4.prestamos[0]
	_comprobar(int(p4["cuota"]) < cuota_antes, "renegociar baja la cuota (%d -> %d)" % [cuota_antes, int(p4["cuota"])])
	_comprobar(bool(p4["renegociado"]), "queda marcado como renegociado")
	_comprobar(b4.renegociar(0) != "", "no se puede renegociar el mismo credito dos veces")

	## LA SEMANA: cobra la cuota, reduce la deuda, y el credito se cierra solo
	## cuando llega a cero o se acaban las cuotas.
	var b5 := Banco.new()
	var c5: Club = m.ligas[0].clubes[3]
	c5.saldo = 5000000
	b5.pedir(0, c5)
	var deuda5_antes := int((b5.prestamos[0] as Dictionary)["deuda"])
	var caja5_antes := c5.saldo
	b5.semana(c5)
	_comprobar(c5.saldo < caja5_antes, "la semana cobra la cuota de verdad (%d -> %d)" % [caja5_antes, c5.saldo])
	_comprobar(int((b5.prestamos[0] as Dictionary)["deuda"]) < deuda5_antes, "la deuda baja cada semana")
	## Pagando la cuota exacta cada semana durante todas las que quedan, el
	## credito debe cerrarse solo -sin quedar en un limbo de deuda residual-.
	var restan5 := int((b5.prestamos[0] as Dictionary)["restan"])
	for i in restan5:
		b5.semana(c5)
	_comprobar(b5.prestamos.is_empty(), "pagando todas las cuotas el credito se cierra solo")

	## EL SOBREGIRO: caja en rojo cobra intereses y cuenta semanas. Saneando la
	## caja, el contador vuelve a cero -no se acumula "media mora" de una racha
	## mala a la siguiente-.
	var b6 := Banco.new()
	var c6: Club = m.ligas[0].clubes[4]
	c6.saldo = -100000
	var caja6_antes := c6.saldo
	b6.semana(c6)
	_comprobar(c6.saldo < caja6_antes, "el sobregiro cobra intereses sobre la caja en rojo")
	_comprobar(b6.semanas_en_rojo == 1, "una semana en rojo cuenta como una")
	c6.saldo = 100000
	b6.semana(c6)
	_comprobar(b6.semanas_en_rojo == 0, "sanear la caja pone el contador de semanas en rojo a cero")

	## LA ESCALADA COMPLETA: sobregiro -> mora -> veedor -> liquidacion, en las
	## semanas exactas que marcan las constantes, con la caja SIEMPRE en rojo
	## -si se sanea a mitad de camino, el contador se reinicia y nunca llega-.
	var b7 := Banco.new()
	var c7: Club = m.ligas[0].clubes[5]
	c7.saldo = -50000
	var avisos: Dictionary = {"total": 0}
	b7.aviso.connect(func(_t: String, _x: String) -> void: avisos["total"] += 1)
	var liquidado_avisado := {"si": false}
	b7.liquidado.connect(func() -> void: liquidado_avisado["si"] = true)
	var en_mora_en_semana := -1
	var veedor_en_semana := -1
	for s in 20:
		c7.saldo = mini(c7.saldo, -1)   ## nunca sale del rojo a proposito
		b7.semana(c7)
		if en_mora_en_semana < 0 and b7.en_mora():
			en_mora_en_semana = s + 1
		if veedor_en_semana < 0 and b7.hay_veedor():
			veedor_en_semana = s + 1
		if b7.liquidado_ya:
			break
	_comprobar(en_mora_en_semana == Banco.SEM_MORA, "entra en mora exactamente a la cuarta semana en rojo (semana %d)" % en_mora_en_semana)
	_comprobar(veedor_en_semana == Banco.SEM_VEEDOR, "el veedor llega exactamente a la octava semana en rojo (semana %d)" % veedor_en_semana)
	_comprobar(b7.liquidado_ya, "doce semanas seguidas en rojo liquidan el club")
	_comprobar(liquidado_avisado["si"], "la senal 'liquidado' se dispara de verdad")
	_comprobar(int(avisos["total"]) >= 3, "se avisa en cada escalon, no solo al final (%d avisos)" % int(avisos["total"]))

	## PEDIR EN MORA: los bancos cierran la ventanilla, pero el bono social de
	## la hinchada sigue disponible -es su gracia, "incluso en mora"-.
	var b8 := Banco.new()
	var c8: Club = m.ligas[0].clubes[6]
	c8.saldo = -1
	for s2 in Banco.SEM_MORA:
		c8.saldo = -1
		b8.semana(c8)
	_comprobar(b8.en_mora(), "el club de la prueba esta de verdad en mora")
	_comprobar(b8.pedir(0, c8) != "", "en mora, ningun banco abre una linea nueva")
	c8.saldo = 100000
	_comprobar(b8.emitir_bono(c8) == "", "el bono social SI se puede emitir incluso en mora")

	## ESTADO: el texto que ve el jugador tiene que coincidir con el numero.
	var c9: Club = m.ligas[0].clubes[7]
	c9.saldo = 100000
	var b9 := Banco.new()
	_comprobar(String(b9.estado(c9)["estado"]) == "AL DÍA", "caja en azul es 'AL DÍA'")
	c9.saldo = -1
	_comprobar(String(b9.estado(c9)["estado"]) == "SOBREGIRO", "caja en rojo bajo mora es 'SOBREGIRO'")
	b9.semanas_en_rojo = Banco.SEM_MORA
	_comprobar(String(b9.estado(c9)["estado"]) == "EN MORA", "en mora el estado dice 'EN MORA'")
	b9.semanas_en_rojo = Banco.SEM_VEEDOR
	_comprobar(String(b9.estado(c9)["estado"]) == "VEEDOR EN FUNCIONES", "con veedor el estado lo dice")

	## GUARDADO: ida y vuelta completa, no solo que no reviente.
	var b10 := Banco.new()
	var c10: Club = m.ligas[0].clubes[8]
	c10.saldo = 500000
	b10.pedir(0, c10)
	b10.pedir(1, c10)
	b10.semanas_en_rojo = 3
	var d10 := b10.a_dic()
	var b11 := Banco.new()
	b11.desde_dic(d10)
	_comprobar(b11.prestamos.size() == b10.prestamos.size(), "vuelven los mismos prestamos (%d)" % b11.prestamos.size())
	_comprobar(int((b11.prestamos[0] as Dictionary)["deuda"]) == int((b10.prestamos[0] as Dictionary)["deuda"]),
		"la deuda de cada prestamo vuelve exacta")
	_comprobar(b11.semanas_en_rojo == 3, "las semanas en rojo vuelven exactas")

func _probar_staff() -> void:
	_titulo("CUERPO TECNICO")
	var m := Mundo.new()
	m.generar(["CHI"], 616)
	var c: Club = m.ligas[0].clubes[0]
	m.tomar_el_mando(c.id)
	var s := m.staff

	## Solo la parte del cuerpo técnico (el camarín ya suma desde el primer día).
	s.aplicar(c)
	_comprobar(is_equal_approx(c.bonus_ataque, 1.0), "sin staff, los bonificadores estan a uno")
	m.aplicar_bonificadores()
	var caja := c.saldo
	var coste := s.coste_subir("ayudante", c.rep)
	_comprobar(s.subir("ayudante", c) == "", "se contrata al ayudante de campo")
	_linea("  ayudante nivel 1 cuesta %s" % _dinero(coste))
	_comprobar(c.saldo == caja - coste, "el fichaje del staff sale de la caja")
	## Lo que importa: que se NOTE. Un menu que no cambia un numero del motor es
	## un boton de gastar dinero, y este proyecto ya pago ese error varias veces.
	_comprobar(c.bonus_ataque > 1.0, "contratar al ayudante sube el ataque del equipo (%.3f)" % c.bonus_ataque)

	## El coste crece mas rapido que el efecto: llenar los seis puestos al maximo
	## no puede ser la jugada obvia del primer ano.
	var c1 := s.coste_subir("ayudante", c.rep)
	s.subir("ayudante", c)
	var c2 := s.coste_subir("ayudante", c.rep)
	_linea("  subir de 1 a 2 cuesta %s; de 2 a 3, %s" % [_dinero(c1), _dinero(c2)])
	_comprobar(c2 > c1, "cada nivel cuesta mas que el anterior")

	## Y el efecto de cada puesto, uno por uno.
	s.niveles["medico"] = 3
	_comprobar(s.descuento_lesion(8) == 5, "el jefe medico acorta las lesiones (8 -> %d)" % s.descuento_lesion(8))
	_comprobar(s.descuento_lesion(1) >= 1, "pero nunca las cura por decreto")
	s.niveles["ojeador"] = 2
	_comprobar(s.ojo() > 0.0, "el ojeador trae informes")
	s.niveles["fisico"] = 4
	_comprobar(s.aguante() == 4, "el preparador fisico da aguante")
	_comprobar(s.sueldo_semanal(c.rep) > 0, "el cuerpo tecnico cobra todas las semanas")

	## Aplicar dos veces no puede duplicar la bonificacion: al cargar una partida
	## se vuelve a aplicar, y acumulando el equipo saldria con el doble.
	var antes := c.bonus_ataque
	s.aplicar(c)
	s.aplicar(c)
	_comprobar(is_equal_approx(c.bonus_ataque, antes), "aplicar el staff dos veces no duplica el efecto")

func _probar_roles_y_federacion() -> void:
	_titulo("ROLES, ENTRENAMIENTO, FEDERACION Y ESTADIO")
	var m := Mundo.new()
	m.generar(["CHI"], 909090)
	m.tomar_el_mando(m.ligas[0].clubes[0].id)

	## ROLES: cada uno tiene que APAGAR cosas distintas. Un rol que permite lo
	## mismo que otro no es un rol, es un nombre.
	_comprobar(m.roles != null, "el rol arranca al tomar el mando")
	_linea("  cargo: %s   manda=%s   puede fichar=%s" % [
		m.roles.nombre_del_cargo(), m.roles.manda(), m.roles.puede_fichar()])
	_comprobar(m.roles.puede_fichar(), "el DT clasico puede fichar")
	var m2 := Mundo.new()
	m2.generar(["CHI"], 909090)
	m2.tomar_el_mando(m2.ligas[0].clubes[0].id)
	m2.roles.arrancar_ayudante()
	_linea("  de ayudante: %s   mercado bloqueado=%s" % [
		m2.roles.nombre_del_cargo(), m2.roles.mercado_bloqueado() != ""])
	_comprobar(m2.roles.es_ayudante(), "se puede empezar de ayudante de campo")
	_comprobar(not m2.roles.puede_fichar(), "el ayudante NO puede fichar")
	var m3 := Mundo.new()
	m3.generar(["CHI"], 909090)
	m3.tomar_el_mando(m3.ligas[0].clubes[0].id)
	m3.roles.arrancar_interinato("CHI")
	_comprobar(m3.roles.en_interinato(), "se puede entrar de interino")
	_comprobar(not m3.roles.puede_fichar(), "el interino tiene el mercado cerrado")

	## ENTRENAMIENTO: apretar tiene que subir el riesgo, o el plan no decide nada.
	var e := m.entrenamiento
	_comprobar(e != null, "el entrenamiento arranca con el mando")
	var r0 := e.carga_riesgo()
	e.fijar_intensidad("alta")
	var r1 := e.carga_riesgo()
	e.fijar_intensidad("baja")
	var r2 := e.carga_riesgo()
	_linea("  carga: baja %.1f, normal %.1f, alta %.1f" % [r2, r0, r1])
	_comprobar(r1 > r2, "entrenar fuerte carga mas las piernas que entrenar suave")
	_comprobar(e.bonus_dt() >= 1.0, "el arbol del DT no penaliza al equipo (%.2f)" % e.bonus_dt())

	## FEDERACION: sin playoffs votados, el campeon es el lider de la tabla.
	var liga := m.liga_de(m.mi_club())
	m.jugar_temporada()
	var t := liga.tabla()
	var lider: Club = t[0]["club"]
	var camp := m.federacion.campeon_de_liga(t, m.anio, m.mi_club_id)
	_linea("  sin playoffs: lider %s, campeon %s" % [lider.nombre, camp.nombre if camp else "ninguno"])
	_comprobar(camp == lider, "sin playoffs votados, campeon = lider de la tabla")
	## Con playoffs, el lider ya NO gana siempre: es justo la gracia de votarlos.
	m.federacion.playoffs = true
	var perdidos := 0
	for i in 30:
		var c2 := m.federacion.campeon_de_liga(t, m.anio, m.mi_club_id)
		if c2 != null and c2 != lider:
			perdidos += 1
	_linea("  con playoffs: de 30 finales, el lider perdio el titulo %d veces" % perdidos)
	_comprobar(perdidos > 0, "con playoffs el lider puede perder el titulo")

	## ESTADIO PROPIO: el perfil que va al visor tiene que traer las claves que
	## consume el constructor 3D, o el estadio sale a medias sin un solo error.
	var p := m.perfil_estadio_de(m.mi_club())
	var faltan: Array[String] = []
	for k in ["forma", "niveles", "techo", "cesped", "asientoP", "focos", "pantalla", "vallas", "aforo"]:
		if not p.has(k):
			faltan.append(k)
	_linea("  perfil de tu estadio: %s de %d niveles, techo %s, %d butacas" % [
		p.get("forma", "?"), int(p.get("niveles", 0)), p.get("techo", "?"), int(p.get("aforo", 0))])
	_comprobar(faltan.is_empty(), "el perfil trae las 9 claves del visor 3D (faltan: %s)" % [faltan])
	## Y el de un rival sigue saliendo de su hash, no del tuyo.
	var rival: Club = liga.clubes[5]
	var pr := m.perfil_estadio_de(rival)
	_comprobar(pr.has("forma"), "el rival tambien tiene perfil de estadio")
	_comprobar(m.perfil_estadio_de(rival)["forma"] == pr["forma"], "y es siempre el mismo")
	_comprobar(not pr.has("bandejas"), "el rival nunca trae la clave bandejas (no tiene disenador)")

	## BANDEJA (16-9-2026, Fase 1 de "el estadio por MODULOS"): con el
	## interruptor apagado, el perfil no debe cambiar NI UNA clave respecto al
	## de antes de esta fase -es el requisito explicito de la reforma.
	_comprobar(not p.has("bandejas"), "sin personalizar_bandejas, el perfil no trae la clave bandejas")
	var claves_antes: Array = p.keys()
	claves_antes.sort()
	## Incluye ya las 5 claves de la Fase 2 (Componentes) -esas SI son
	## incondicionales desde que se cerro esa fase, a diferencia de `bandejas`
	## que solo aparece con el interruptor activo.
	## "sonidoGol" (18-9-2026): faltaba en `perfil()` desde que existe el
	## catalogo -se podia elegir y pagar en la UI, pero el visor nunca la vio-.
	var claves_esperadas: Array = ["aforo", "arcoCol", "asiento1", "asiento2", "asiento3",
		"asientoP", "banderas", "banquillo", "cesped", "cespedClaro", "cespedOscuro", "clima",
		"corner", "escudoDonde", "focos", "forma", "lineaCol", "niveles", "pantalla",
		"personalizado", "redCol", "redTipo", "sonidoGol", "techo", "tunel", "vallas",
		## B6 (25-9-2026): las secciones, también incondicionales.
		"fachada", "fachadaCol", "techoCol", "luzFocos", "luzClub", "banquilloCol",
		"superficie", "exterior",
		## 26-9-2026: obras en curso y lo construido, para el 3D (`EstadioExtras`).
		"en_obra", "inst"]
	claves_esperadas.sort()
	_comprobar(claves_antes == claves_esperadas,
		"perfil() trae exactamente las claves de siempre, ni una de mas (dio: %s)" % [claves_antes])

	## COMPONENTES (16-9-2026, Fase 2): las 5 claves ya llegan al visor. Desde
	## el 25-9 el rival trae red, córner y banquillo de su estilo (más variedad
	## de estadios), pero sigue sin túnel ni escudo: esos solo los decide quien
	## diseña su propio estadio.
	for k in ["redTipo", "corner", "banquillo", "tunel", "escudoDonde"]:
		_comprobar(p.has(k), "el perfil propio trae la clave nueva '%s'" % k)
	for k in ["tunel", "escudoDonde"]:
		_comprobar(not pr.has(k), "el rival NO trae '%s' (sigue sin disenador)" % k)

	## Con el interruptor prendido y una reforma de una sola tribuna, solo esa
	## tribuna cambia -las otras tres siguen heredando el valor global.
	var mio := m.mi_club()
	mio.saldo = 999999999
	_comprobar(m.estadio.reformar(mio, {"personalizar_bandejas": true}, m.obras) == "",
		"se puede activar personalizar cada tribuna")
	_comprobar(m.estadio.reformar(mio, {"bandeja_sur_asientoP": "damero"}, m.obras) == "",
		"se puede reformar solo la tribuna sur")
	m.estadio.terminar_obra()
	var p2 := m.perfil_estadio_de(mio)
	_comprobar(p2.has("bandejas"), "con el interruptor activo, el perfil SI trae bandejas")
	var bandejas: Dictionary = p2.get("bandejas", {})
	_comprobar(String(bandejas.get("sur", {}).get("asientoP", "")) == "damero",
		"la tribuna sur quedo con el patron reformado")
	for lado in ["norte", "este", "oeste"]:
		_comprobar(String(bandejas.get(lado, {}).get("asientoP", "")) == String(p2.get("asientoP", "")),
			"la tribuna %s sigue heredando el patron global" % lado)

	## TRAMO (22-9-2026, Fase 3 de "el estadio por MODULOS", ultima de las
	## tres): mismo criterio que Bandeja -apagado no cambia una clave,
	## prendido solo cambia lo que se reformo-, mas la resolucion de los
	## tercios en blanco. Con `personalizar_bandejas` YA prendido (bloque de
	## arriba) para probar de paso que las dos fases conviven: la tribuna sur
	## tiene ahora un `bandeja_sur_asientoP` propio ("damero"), asi que sus
	## tercios en blanco tienen que heredar ESE valor, no el global.
	_comprobar(not p.has("tramos"), "sin personalizar_tramos, el perfil no trae la clave tramos")
	_comprobar(m.estadio.reformar(mio, {"personalizar_tramos": true}, m.obras) == "",
		"se puede activar mezclar patrones por tercios")
	_comprobar(m.estadio.reformar(mio, {"tramo_sur_2": "moteado"}, m.obras) == "",
		"se puede reformar solo el tercio 2 de la tribuna sur")
	m.estadio.terminar_obra()
	var p3 := m.perfil_estadio_de(mio)
	_comprobar(p3.has("tramos"), "con el interruptor activo, el perfil SI trae tramos")
	var tramos: Dictionary = p3.get("tramos", {})
	var tramos_sur: Array = tramos.get("sur", [])
	_comprobar(tramos_sur.size() == 3, "la tribuna sur trae sus 3 tercios (dio %d)" % tramos_sur.size())
	_comprobar(String(tramos_sur[0]) == "damero" and String(tramos_sur[2]) == "damero",
		"los tercios 1 y 3 en blanco heredan 'damero' -el de Bandeja, no el global- (dio %s y %s)" % [
			tramos_sur[0] if tramos_sur.size() > 0 else "?", tramos_sur[2] if tramos_sur.size() > 2 else "?"])
	_comprobar(String(tramos_sur[1]) == "moteado", "el tercio 2 quedo con el patron reformado")
	for lado in ["norte", "este", "oeste"]:
		var t_lado: Array = tramos.get(lado, [])
		_comprobar(t_lado.size() == 3 and t_lado[0] == t_lado[1] and t_lado[1] == t_lado[2]
			and String(t_lado[0]) == String(p3.get("asientoP", "")),
			"la tribuna %s (sin tercios propios) sale con sus 3 tercios iguales al patron global" % lado)
	## El rival nunca disenio nada: nunca trae ni bandejas ni tramos.
	_comprobar(not m.perfil_estadio_de(rival).has("tramos"), "el rival nunca trae la clave tramos")

	## LOS 8 ESTILOS, ENRIQUECIDOS (16-9-2026): ya traian banquillo/tunel/corner
	## desde antes -mudos hasta la Fase 2 de hoy-, y ahora tambien redTipo y
	## escudoDonde. Los 8, no solo uno, para no dejar pasar un typo de catalogo
	## en cualquiera de ellos -"redTipo": "gruesa" vale, "REDTIPO":"Gruesa" no.
	var estilos := m.estadio.presets()
	_comprobar(estilos.size() == 24, "los 24 estilos completos (8 de siempre + 8 del 25-9 + 8 de B6) (dio %d)" % estilos.size())
	for est_p: Dictionary in estilos:
		var cambios: Dictionary = est_p["cambios"]
		_comprobar(cambios.has("redTipo") and m.estadio.es_valido("redTipo", cambios["redTipo"]),
			"'%s' trae un redTipo valido (%s)" % [est_p["clave"], cambios.get("redTipo")])
		_comprobar(cambios.has("escudoDonde") and m.estadio.es_valido("escudoDonde", cambios["escudoDonde"]),
			"'%s' trae un escudoDonde valido (%s)" % [est_p["clave"], cambios.get("escudoDonde")])
