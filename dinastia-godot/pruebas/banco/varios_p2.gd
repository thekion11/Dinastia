extends "res://pruebas/banco/varios_p1.gd"
## [Capa 2/10 de `varios.gd`] _probar_pie_habil, _probar_banquillo, _probar_banco

## EL PIE HÁBIL: "D.d==='LAT'&&D.b&&j.pie&&D.b!==j.pie" del HTML. `Jugador.
## pie()` YA EXISTÍA -de un hash de su id, no guardado, misma proporción
## 76/24 del HTML- pero solo lo leía `aptitud_en()`, usado en un único sitio
## de la interfaz; nunca llegaba a la fuerza real del partido. Se prueba con
## dos jugadores IDÉNTICOS salvo el id -que es de donde sale el pie-, puestos
## de laterales derechos: el zurdo tiene que rendir un 6% menos, ni un
## central ni un delantero pierden nada por jugar del pie contrario.
func _probar_pie_habil() -> void:
	_titulo("EL PIE HÁBIL: LOS LATERALES SÍ LO NOTAN")
	var m := Mundo.new()
	m.generar(["CHI"], 5150)
	var a: Club = m.ligas[0].clubes[0]
	var b: Club = m.ligas[0].clubes[1]
	var p := Partido.new(a, b)

	## `pie()` sale del id, así que para comparar un diestro con un zurdo hay
	## que buscar dos ids -no importa cuáles- cuyo hash caiga a cada lado.
	var id_d := ""
	var id_i := ""
	for i in 200:
		var candidato := "prueba_pie_%d" % i
		var j0 := Jugador.new()
		j0.id = candidato
		if j0.pie() == "D" and id_d == "":
			id_d = candidato
		elif j0.pie() == "I" and id_i == "":
			id_i = candidato
		if id_d != "" and id_i != "":
			break
	_comprobar(id_d != "" and id_i != "", "se encuentran ids de sobra para un diestro y un zurdo")

	var diestro := Jugador.new()
	diestro.id = id_d; diestro.pos_e = "LD"; diestro.pos = "DEF"; diestro.ovr = 75
	diestro.forma = 60; diestro.fisico = 70; diestro.moral = 60
	var zurdo := Jugador.new()
	zurdo.id = id_i; zurdo.pos_e = "LD"; zurdo.pos = "DEF"; zurdo.ovr = 75
	zurdo.forma = 60; zurdo.fisico = 70; zurdo.moral = 60

	var media_diestro := p._media_linea([diestro], "DEF")
	var media_zurdo := p._media_linea([zurdo], "DEF")
	_linea("  LD con pie D: %.2f   ·   LD con pie I: %.2f" % [media_diestro, media_zurdo])
	_comprobar(media_zurdo < media_diestro,
		"un lateral del pie contrario a su banda rinde menos (%.2f < %.2f)" % [media_zurdo, media_diestro])
	_comprobar(absf(media_zurdo / media_diestro - 0.94) < 0.001,
		"la penalizacion es exactamente la del HTML, 0.94 (%.4f)" % (media_zurdo / media_diestro))

	## Un central zurdo, en cambio, no pierde nada: "es_lateral()" es falso
	## para DFC.
	var central_zurdo := Jugador.new()
	central_zurdo.id = id_i; central_zurdo.pos_e = "DFC"; central_zurdo.pos = "DEF"; central_zurdo.ovr = 75
	central_zurdo.forma = 60; central_zurdo.fisico = 70; central_zurdo.moral = 60
	var central_diestro := Jugador.new()
	central_diestro.id = id_d; central_diestro.pos_e = "DFC"; central_diestro.pos = "DEF"; central_diestro.ovr = 75
	central_diestro.forma = 60; central_diestro.fisico = 70; central_diestro.moral = 60
	var media_central_zurdo := p._media_linea([central_zurdo], "DEF")
	var media_central_diestro := p._media_linea([central_diestro], "DEF")
	_comprobar(absf(media_central_zurdo - media_central_diestro) < 0.001,
		"un central no pierde nada por ser zurdo (%.2f vs %.2f)" % [media_central_zurdo, media_central_diestro])

	## Y de nacimiento: casi 8 de cada 10 futbolistas del mundo son diestros
	## -se mide sobre el mundo generado de verdad, con los ids que de verdad
	## reparte `Mundo.crear_jugador()` ("j1","j2","j3"...), no sobre una
	## muestra sintética-.
	var m2 := Mundo.new()
	m2.generar(["CHI", "ARG", "BRA"], 6060)
	var diestros := 0
	var total := 0
	for c: Club in m2.clubes.values():
		for j: Jugador in c.plantilla:
			total += 1
			if j.pie() == "D":
				diestros += 1
	var pct := float(diestros) / float(maxi(total, 1))
	_linea("  %d futbolistas: %.0f%% diestros" % [total, pct * 100.0])
	_comprobar(pct > 0.68 and pct < 0.84, "la proporcion diestro/zurdo ronda el 76%% del HTML (%.0f%%)" % (pct * 100.0))


func _probar_banquillo() -> void:
	_titulo("BANQUILLO: ONCE, CAMBIOS Y PENALES")
	var m := Mundo.new()
	m.generar(["CHI"], 1234)
	var a: Club = m.ligas[0].clubes[0]
	var b: Club = m.ligas[0].clubes[1]

	## El once que elige el entrenador manda sobre el automatico.
	var mio: Array[Jugador] = []
	var libres := a.disponibles()
	for i in 11:
		mio.append(libres[i])
	a.fijar_once(mio)
	var salido := a.once()
	var coincide := salido.size() == 11
	if coincide:
		for i in 11:
			if salido[i] != mio[i]:
				coincide = false
				break
	_comprobar(coincide, "el once elegido a mano es el que sale al campo")
	## Y si uno de los elegidos se lesiona, se arma el automatico en vez de
	## sacar a diez: es el caso que rompe un once guardado de la semana pasada.
	mio[5].lesion = 3
	_comprobar(a.once().size() == 11, "con un titular lesionado sigue saliendo un once de 11")
	mio[5].lesion = 0
	a.limpiar_once()

	var p := Partido.new(a, b)
	p.preparar()
	for i in 20:
		p.simular_minuto()
	var titular: Jugador = p.once_local[7]
	var suplente: Jugador = null
	for j in a.plantilla:
		if not p.once_local.has(j) and j.disponible():
			suplente = j
			break
	var fuerza_antes: float = p.fuerza(p.once_local, a)["ata"]
	_comprobar(p.cambiar(titular, suplente) == "", "se puede hacer un cambio")
	_comprobar(p.once_local.has(suplente) and not p.once_local.has(titular), "el suplente entra y el titular sale")
	_comprobar(p.cambiar(titular, suplente) != "", "no se puede sacar a quien ya no esta en el campo")
	## Lo que de verdad importa: que el cambio SE NOTE. Si la fuerza cacheada no
	## se invalida, el equipo sigue jugando con el once que ya no esta ahi y la
	## pizarra es un menu decorativo.
	var fuerza_despues: float = p.fuerza(p.once_local, a)["ata"]
	_comprobar(not is_equal_approx(fuerza_antes, fuerza_despues) or titular.ovr == suplente.ovr,
		"cambiar a alguien cambia la fuerza del equipo")

	## El tope de cinco.
	var hechos := 1
	for j in a.plantilla:
		if hechos >= 8:
			break
		if p.once_local.has(j) or not j.disponible():
			continue
		if p.cambiar(p.once_local[0], j) == "":
			hechos += 1
	_comprobar(p.cambios_local == Partido.MAX_CAMBIOS, "no se pueden hacer mas de %d cambios (van %d)" % [
		Partido.MAX_CAMBIOS, p.cambios_local])

	## Penales: nunca pueden acabar en empate.
	## `penales()` quedó memoizado (`partido_vivo.gd` puede resolverlos en vivo y
	## `Copa.jugar_ronda()` los vuelve a pedir después sobre el MISMO objeto, y
	## sin caché el visor podía anunciar un ganador distinto del que la copa
	## calculaba al avanzar la semana) -así que probar 200 tandas hace falta un
	## `Partido` nuevo cada vez, o las 200 vueltas leerían la primera memoizada.
	var empates := 0
	for i in 200:
		var pp := Partido.new(a, b)
		var r := pp.penales()
		if r[0] == r[1]:
			empates += 1
	_comprobar(empates == 0, "una tanda de penales nunca acaba empatada (%d de 200)" % empates)

	## Y el partido dirigido: su resultado tiene que ser el que va a la tabla.
	var m2 := Mundo.new()
	m2.generar(["CHI"], 31)
	m2.mi_club_id = m2.ligas[0].clubes[2].id
	var par := m2.proximo_partido()
	_comprobar(par.size() == 2, "hay partido esta jornada")
	var dirigido := Partido.new(par[0], par[1])
	dirigido.simular()
	## Se fuerza un marcador imposible de repetir por azar: si en la tabla
	## aparece otro numero, es que la jornada lo volvio a simular por dentro.
	dirigido.goles_local = 7
	dirigido.goles_visita = 3
	m2.avanzar_semana(dirigido)
	var liga := m2.liga_de(m2.mi_club())
	var gf_local := 0
	var gc_local := 0
	for fila: Dictionary in liga.tabla():
		if fila["club"] == par[0]:
			gf_local = fila["gf"]
			gc_local = fila["gc"]
	_comprobar(gf_local == 7 and gc_local == 3,
		"el resultado del partido dirigido es el que va a la tabla (%d-%d)" % [gf_local, gc_local])


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
