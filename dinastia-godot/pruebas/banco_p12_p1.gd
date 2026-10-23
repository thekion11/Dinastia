extends "res://pruebas/banco_p11.gd"
## (Parte 1 de 2 de `banco_p12.gd`: la norma de 450 líneas lo partió en capas, cada una extiende a la anterior; la última, `banco_p12.gd`, conserva la clase.)

## (Parte 12 de 25 de `banco.gd`.)

## Tramo 1 de 2 de `_probar_guardado` (la norma de 450 líneas la troceó).
func _probar_guardado_1() -> Array:
	_titulo("GUARDAR Y CARGAR")
	var m := Mundo.new()
	m.generar(["CHI", "ARG"], 777)
	m.tomar_el_mando(m.ligas[0].clubes[3].id)
	## Se toca el estado de los sistemas nuevos para que el guardado tenga algo
	## que conservar: uno recien creado se parece a cualquier otro recien creado.
	m.staff.subir("ayudante", m.mi_club())
	m.staff.subir("medico", m.mi_club())
	## Los cuatro interruptores tacticos: se guardaban... no, no se guardaban.
	## Se activaban, movian el partido, y volvian a false en cada carga sin
	## avisar. Se marcan dos si y dos no para que la prueba distinga entre
	## "vuelve el valor" y "vuelve el valor por defecto".
	m.mi_club().tactica.salida_corta = true
	m.mi_club().tactica.tiro_lejano = true
	m.mi_club().tactica.marca_al_hombre = false
	m.mi_club().tactica.fuera_de_juego = false
	## Un once a mano, para comprobar que sobrevive: los once primeros del plantel.
	var once_a_mano: Array[Jugador] = []
	for n in 11:
		once_a_mano.append(m.mi_club().plantilla[n])
	m.mi_club().fijar_once(once_a_mano)
	## La tienda: se lanza una linea y se comprueba que rinde y que sobrevive.
	var sin_tienda := m.ingreso_tienda(m.mi_club())
	_comprobar(sin_tienda == 0, "sin lineas lanzadas la tienda no da nada (%d)" % sin_tienda)
	var err_t := m.alternar_tienda("buf", m.mi_club())
	_comprobar(err_t == "", "se lanza una linea de tienda (%s)" % err_t)
	_comprobar(m.ingreso_tienda(m.mi_club()) > 0, "y ya rinde todos los meses (%d)" % m.ingreso_tienda(m.mi_club()))
	## MENTORIAS: un veterano apadrina a un chico y el chico crece mas rapido.
	var maestro: Jugador = null
	var pupilo: Jugador = null
	for j in m.mi_club().plantilla:
		if maestro == null and m.entrenamiento.puede_ser_mentor(j):
			maestro = j
		elif pupilo == null and m.entrenamiento.puede_ser_pupilo(j):
			pupilo = j
	if maestro != null and pupilo != null:
		var moral_antes := pupilo.moral
		_comprobar(m.entrenamiento.crear_mentoria(maestro, pupilo) == "", "se crea una mentoria")
		_comprobar(pupilo.moral > moral_antes, "al pupilo le sube la moral al ser apadrinado (%d -> %d)" % [moral_antes, pupilo.moral])
		_comprobar(m.entrenamiento.mentorias.size() == 1, "queda registrada")
		_comprobar(not m.entrenamiento.puede_ser_pupilo(pupilo), "y ya no se le puede apadrinar dos veces")
	## EL BONO AL CUERPO TECNICO: una vez por temporada, y sube mas si vas bien.
	## Se parte de cero A PROPOSITO: este mundo ya trae staff contratado de
	## pruebas anteriores, y sin limpiarlo la primera comprobacion -"sin cuerpo
	## tecnico no hay bono"- pasaba de largo repartiendolo de verdad, dejando el
	## ano marcado y haciendo fallar a las tres siguientes.
	m.staff.niveles.clear()
	m.staff.anio_bono = 0
	var r_bono_sin := m.staff.repartir_bono(m.mi_club(), m.anio, 1, 16)
	_comprobar(r_bono_sin.has("error"), "sin cuerpo tecnico no hay bono que repartir")
	m.staff.subir("ayudante", m.mi_club())
	m.mi_club().mover_saldo(50000000)
	var moral_antes_b := m.mi_club().plantilla[0].moral
	var r_bono := m.staff.repartir_bono(m.mi_club(), m.anio, 1, 16)
	_comprobar(r_bono.has("ok"), "con cuerpo tecnico se reparte el bono")
	_comprobar(int(r_bono.get("moral", 0)) == 5, "yendo primero sube 5 de moral (%d)" % int(r_bono.get("moral", 0)))
	_comprobar(m.mi_club().plantilla[0].moral > moral_antes_b, "y la moral del plantel sube de verdad")
	_comprobar(m.staff.repartir_bono(m.mi_club(), m.anio, 1, 16).has("error"), "no se puede repartir dos veces el mismo ano")
	## LA PROYECCION ANUAL: la contabilidad del ejercicio. No inventa cifras,
	## multiplica lo que ya cobra y paga `mes()`, asi que lo que se comprueba es
	## que cuadre consigo misma y que la masa salarial salga en un rango creible.
	var fin := Finanzas.new(m.mi_club(), 0.0, 0, 0.0)
	var proy := fin.proyeccion_anual(15, 0)
	var suma_ing := 0
	for k: String in proy["ingresos"]:
		suma_ing += int(proy["ingresos"][k])
	_comprobar(suma_ing == int(proy["total_ingresos"]), "los ingresos del ejercicio suman el total (%d)" % suma_ing)
	_comprobar(int(proy["resultado"]) == int(proy["total_ingresos"]) - int(proy["total_gastos"]),
		"el resultado es ingresos menos gastos")
	_linea("  ejercicio: entran %d, salen %d, resultado %d, masa salarial %d%%" % [
		int(proy["total_ingresos"]), int(proy["total_gastos"]), int(proy["resultado"]), int(proy["pct_salarial"])])
	_comprobar(int(proy["pct_salarial"]) > 5 and int(proy["pct_salarial"]) < 200,
		"la masa salarial sobre ingresos sale en un rango creible (%d%%)" % int(proy["pct_salarial"]))

	## LA HINCHADA: cinco segmentos, abonos y encuestas.
	var h := m.hinchada
	_comprobar(h != null, "tomar el mando crea la hinchada")
	if h != null:
		_comprobar(h.segmentos.size() == 5, "hay cinco segmentos de aficion (%d)" % h.segmentos.size())
		## El plan de abono cambia lo que se recauda: el popular llena pero deja
		## poco por cabeza, el premium al reves. Es LA decision de la pantalla.
		h.fijar_abono("popular")
		var caja_antes_ab := m.mi_club().saldo
		var ing_popular := h.campana_abonos(m.mi_club(), 70, 0)
		var abon_popular := h.abonados
		m.mi_club().mover_saldo(caja_antes_ab - m.mi_club().saldo)
		h.fijar_abono("premium")
		var ing_premium := h.campana_abonos(m.mi_club(), 70, 0)
		var abon_premium := h.abonados
		_linea("  abonos: popular %d socios / %d | premium %d socios / %d" % [
			abon_popular, ing_popular, abon_premium, ing_premium])
		_comprobar(abon_popular > abon_premium, "el abono popular llena mas que el premium")
		_comprobar(ing_premium > ing_popular, "pero el premium recauda mas")
		## Los segmentos se mueven con el animo, en el sentido correcto.
		var barra_antes := int(h.segmentos["barra"])
		for i in 40:
			h.semana(90)
		var barra_bien := int(h.segmentos["barra"])
		for i in 40:
			h.semana(20)
		_comprobar(barra_bien >= barra_antes, "con el animo alto la barra no empeora (%d -> %d)" % [barra_antes, barra_bien])
		_comprobar(int(h.segmentos["barra"]) < barra_bien, "y con el animo por el suelo se enfada (%d)" % int(h.segmentos["barra"]))

	## LAS DIRECTRICES AL ENTRENADOR EMPLEADO: pedirle cosas desgasta la relacion.
	var r_dir := m.roles
	r_dir.dt_empleado = {"nombre": "Un DT", "estilo": "pizarron", "sintonia": 60}
	r_dir.rol = Roles.DT
	var sint_antes := int(r_dir.dt_empleado["sintonia"])
	r_dir.fijar_directriz("cantera", true)
	_comprobar(bool(r_dir.directrices["cantera"]), "la directriz queda puesta")
	_comprobar(int(r_dir.dt_empleado["sintonia"]) < sint_antes,
		"pedirle algo le desgasta la sintonia (%d -> %d)" % [sint_antes, int(r_dir.dt_empleado["sintonia"])])
	## Con la sintonia por el suelo casi nunca hace caso; con ella alta, casi siempre.
	r_dir.dt_empleado["sintonia"] = 100
	var caso_alto := 0
	for i in 200:
		if r_dir.dt_obedece():
			caso_alto += 1
	r_dir.dt_empleado["sintonia"] = 0
	var caso_bajo := 0
	for i in 200:
		if r_dir.dt_obedece():
			caso_bajo += 1
	_linea("  te hace caso: %d%% con sintonia 100, %d%% con sintonia 0" % [caso_alto / 2, caso_bajo / 2])
	_comprobar(caso_alto > caso_bajo, "cuanta mas sintonia, mas caso te hace")
	r_dir.dt_empleado = {}

	## LOS ROLES TACTICOS: el sistema estaba escrito y sin pantalla, asi que lo
	## que hay que demostrar no es que la tabla exista -eso ya se sabia- sino que
	## ELEGIR UN ROL LLEGA AL EQUIPO. Si `bonus_roles()` no moviera los factores,
	## la pantalla nueva seria un adorno que miente.
	var v_rt := m.vestuario
	var once_rt: Array = m.mi_club().once()
	if v_rt != null and once_rt.size() == 11:
		var previos := {}
		for j: Jugador in once_rt:
			previos[j.id] = v_rt.rol_tactico(j)
		## Un once entero de gente que va hacia adelante contra uno entero de
		## gente que se queda: son los dos extremos de la tabla ROLES.
		for j: Jugador in once_rt:
			if not j.es_portero():
				v_rt.fijar_rol_tactico(j, "latOf" if Datos.grupo(j.pos_e) == "DEF" else "llegador")
		var ofensivo: Dictionary = v_rt.bonus_roles(once_rt)
		for j: Jugador in once_rt:
			if not j.es_portero():
				v_rt.fijar_rol_tactico(j, "latDef" if Datos.grupo(j.pos_e) == "DEF" else "pivote")
		var defensivo: Dictionary = v_rt.bonus_roles(once_rt)
		_linea("  roles: once ofensivo ata x%.3f def x%.3f | once defensivo ata x%.3f def x%.3f" % [
			float(ofensivo["att"]), float(ofensivo["def"]), float(defensivo["att"]), float(defensivo["def"])])
		_comprobar(float(ofensivo["att"]) > float(defensivo["att"]),
			"un once de llegadores ataca mas que uno de pivotes")
		_comprobar(float(defensivo["def"]) > float(ofensivo["def"]),
			"y defiende menos: pedir roles ofensivos REGALA la espalda")
		## Y que el numero llega al club de verdad, no se queda en Vestuario.
		_comprobar(absf(v_rt.factor_ataque(m.mi_club()) - 1.0) > 0.0001,
			"el factor de ataque del club recoge el efecto de los roles")
		## La aptitud mide contra la propia media del jugador, asi que el mismo
		## central da numeros distintos segun lo que le pidas.
		var central: Jugador = null
		for j: Jugador in once_rt:
			if j.pos_e == "DFC":
				central = j
				break
		if central != null:
			var marcador := v_rt.aptitud_rol(central, "centralMar")
			var salida := v_rt.aptitud_rol(central, "centralSal")
			_linea("  %s como central marcador %.2f, como central de salida %.2f" % [central.nombre, marcador, salida])
			_comprobar(absf(marcador - salida) > 0.001,
				"el mismo central no vale lo mismo para marcar que para salir jugando")
		for j: Jugador in once_rt:
			v_rt.fijar_rol_tactico(j, String(previos[j.id]))

	## LAS ARENGAS. Lo que hay que probar es que el subidon LLEGA A LA FUERZA del
	## equipo. Si solo pintara el boton de otro color seria decoracion, que es el
	## error que este proyecto ya ha pagado varias veces.
	var mio_ar := m.mi_club()
	var rival_ar: Club = null
	for c_ar: Club in m.clubes.values():
		if c_ar != mio_ar:
			rival_ar = c_ar
			break
	if rival_ar != null:
		var p_ar := Partido.new(mio_ar, rival_ar)
		p_ar.preparar()
		var antes_ar: float = p_ar.fuerza(p_ar.once_local, mio_ar)["ata"]
		## Se arenga a los once para que la diferencia sea medible: con uno solo
		## se pierde en el redondeo de la media por linea.
		for j_ar: Jugador in p_ar.once_local:
			p_ar.arengar(j_ar)
		var despues_ar: float = p_ar.fuerza(p_ar.once_local, mio_ar)["ata"]
		_linea("  arenga: ataque %.2f -> %.2f" % [antes_ar, despues_ar])
		_comprobar(despues_ar > antes_ar, "arengar sube la fuerza de ataque de verdad")
		_comprobar(p_ar.con_impulso(p_ar.once_local[0]), "y el jugador queda encendido")
		## No se puede arengar dos veces al mismo mientras le dura.
		_comprobar(p_ar.arengar(p_ar.once_local[0]) != "", "no se puede arengar dos veces seguidas al mismo")

	## LAS JUGADAS ENSAYADAS Y LOS PLANES. Lo que hay que probar es que la
	## efectividad DEPENDE del once -si diera lo mismo con cualquier plantel,
	## elegir jugada seria un adorno- y que el plan del minuto 60 toca la tactica
	## de verdad.
	var once_bp: Array = m.mi_club().once()
	var ent_bp := m.entrenamiento
	if ent_bp != null and once_bp.size() == 11:
		## Una jugada que pide habilidades que nadie tiene rinde por debajo de 1;
		## el minimo de la formula es 0,82.
		var sin_nadie := Tactica.efectividad(once_bp, ["habilidad_que_no_existe"], ent_bp)
		_comprobar(sin_nadie < 1.0, "una jugada sin especialistas rinde por debajo de 1 (%.2f)" % sin_nadie)
		_comprobar(Tactica.efectividad([], ["cabezazo"], ent_bp) == 1.0,
			"sin once no se inventa un factor: devuelve 1")
	## El plan: perdiendo, ofensivo; ganando, cerrojo; empatando, nada.
	var t_bp := Tactica.new()
	t_bp.plan_perdiendo = "ofensivo"
	t_bp.plan_ganando = "cerrojo"
	var perdiendo := t_bp.plan_para(-1)
	var ganando := t_bp.plan_para(1)
	_comprobar(not perdiendo.is_empty() and int(perdiendo["mentalidad"]) == Tactica.Mentalidad.OFENSIVA,
		"yendo perdiendo el plan sale a por el partido")
	_comprobar(not ganando.is_empty() and int(ganando["mentalidad"]) == Tactica.Mentalidad.DEFENSIVA,
		"yendo ganando el plan cierra el partido")
	_comprobar(t_bp.plan_para(0).is_empty(), "empatando no se toca nada")

	## LA DEUDA (`vBanco`). Es el unico sistema que puede terminar una partida
	## sin perder un partido, asi que lo que hay que probar es el RELOJ: que las
	## semanas en rojo avanzan y que a las doce se liquida. Y la cuota francesa,
	## que es lo que hace que prepagar temprano ahorre y tarde no.
	var bk := m.banco
	if bk != null:
		var mio_b := m.mi_club()
		## La cuota francesa: pagando `n` cuotas se cubre deuda + intereses, asi
		## que el total pagado tiene que ser MAYOR que la deuda.
		var cuota := Banco.cuota_francesa(1000000, 0.01, 26)
		_linea("  credito de 1.000.000 a 26 cuotas: %d por cuota, %d en total" % [cuota, cuota * 26])
		_comprobar(cuota * 26 > 1000000, "la cuota francesa cubre deuda mas intereses")
		_comprobar(Banco.cuota_francesa(1000000, 0.0, 10) == 100000,
			"sin intereses la cuota es la division exacta")
		## Pedir sube la caja; el credito queda vigente.
		var saldo_antes := mio_b.saldo
		_comprobar(bk.pedir(0, mio_b) == "", "se puede pedir un credito")
		_comprobar(mio_b.saldo > saldo_antes, "el credito entra en caja")
		_comprobar(bk.prestamos.size() == 1, "el credito queda vigente")
		## Y no mas de dos lineas.
		bk.pedir(1, mio_b)
		_comprobar(bk.pedir(2, mio_b) != "", "no se pueden abrir mas de dos lineas de deuda")
		## El reloj: doce semanas con la caja en rojo y se liquida.
		bk.prestamos.clear()
		bk.semanas_en_rojo = 0
		bk.liquidado_ya = false
		var saldo_guardado := mio_b.saldo
		mio_b.mover_saldo(-mio_b.saldo - 1000)
		for i in 12:
			bk.semana(mio_b)
		_comprobar(bk.liquidado_ya, "doce semanas en rojo liquidan el club (%d semanas)" % bk.semanas_en_rojo)
		_comprobar(bk.en_mora(), "y por el camino se pasa por la mora")
		## Se deja como estaba: el resto del banco sigue usando este mundo.
		bk.semanas_en_rojo = 0
		bk.liquidado_ya = false
		mio_b.mover_saldo(saldo_guardado - mio_b.saldo)

	## EL HORARIO DEL PARTIDO. Lo que se prueba es que la eleccion IMPORTA: si el
	## factor no llegara a la taquilla seria un menu decorativo, que es el error
	## que este proyecto ya ha pagado varias veces.
	var mio_h := m.mi_club()
	var f_h := Finanzas.new(mio_h)
	var tarde := f_h.taquilla(false, 1.0)
	mio_h.mover_saldo(-tarde)
	var lunes := f_h.taquilla(false, 0.68)
	mio_h.mover_saldo(-lunes)
	_linea("  taquilla: tarde de sabado %d, lunes por la noche %d" % [tarde, lunes])
	_comprobar(lunes < tarde, "jugar el lunes por la noche llena menos el estadio")
	## Y que los cuatro horarios existen con sus dos factores.
	_comprobar(Mundo.HORARIOS.size() == 4, "hay cuatro horarios para elegir")
	m.horario = "lunes"
	_comprobar(absf(m.factor_publico() - 0.68) < 0.001, "el horario elegido manda en el factor de publico")
	_comprobar(m.factor_tv_horario() > 1.0, "y el lunes paga mas derechos de television")
	m.horario = "tarde"
	## El clima es estable: la misma semana del mismo ano da siempre lo mismo,
	## porque sale de un hash y no de un sorteo. Si no, no se podria reproducir
	## una partida.
	var clima1 := m.clima()
	var clima2 := m.clima()
	_comprobar(clima1 == clima2, "el clima de una semana es estable (%s)" % clima1)

	## LOS JUEGOS MENTALES: dos banderas que se encendian y no las apagaba nadie.
	## `consumir_presion()` y `consumir_dato_del_rival()` estaban escritas y sin
	## una sola llamada en todo el proyecto: pagabas 80.000 por espiar al rival y
	## no pasaba nada. Lo que se prueba es que se CONSUMEN -una sola vez- y que
	## la promesa mueve el animo en los dos sentidos.
	var pr := m.prensa
	if pr != null:
		pr.dato_del_rival = true
		_comprobar(pr.consumir_dato_del_rival(), "el informe del rival se puede usar una vez")
		_comprobar(not pr.consumir_dato_del_rival(), "y solo una: lo que pagaste ya lo gastaste")
		pr.presion_prometida = true
		_comprobar(pr.consumir_presion(), "la promesa de la rueda de prensa se cobra")
		_comprobar(not pr.consumir_presion(), "y no se cobra dos veces")
		## Y que el animo se mueve al alza si cumples y a la baja si no. Se
		## llama a `mover_animo` directamente porque el cobro vive en `Mundo` y
		## depende del resultado del partido, que aqui no se juega.
		var animo0 := pr.animo
		pr.mover_animo(6)
		_comprobar(pr.animo > animo0, "cumplir la promesa sube el animo (%d -> %d)" % [animo0, pr.animo])
		var animo1 := pr.animo
		pr.mover_animo(-8)
		_comprobar(pr.animo < animo1, "y fallarla lo hunde (%d -> %d)" % [animo1, pr.animo])

	## LA CHARLA DEL ENTRETIEMPO. Lo que hay que demostrar es que NO hay un tono
	## bueno: si "Sacudir" fuera siempre mejor que "Calmar", el camarin seria un
	## boton con seis dibujos distintos.
	var v_ch := m.vestuario
	if v_ch != null:
		var once_ch: Array = m.mi_club().once()
		## Mismo equipo, misma moral de partida, muchas repeticiones: lo que se
		## compara es el promedio, porque cada charla lleva su dado.
		var moral_base := {}
		for j: Jugador in once_ch:
			moral_base[j.id] = j.moral
		var suma := {}
		for tono_ch in ["calma", "furia"]:
			var acc := 0
			for intento in 60:
				for j: Jugador in once_ch:
					j.moral = int(moral_base[j.id])
				v_ch.charla(once_ch, tono_ch)
				for j: Jugador in once_ch:
					acc += j.moral - int(moral_base[j.id])
			suma[tono_ch] = float(acc) / 60.0
		_linea("  charla: calmar %+.1f de moral total, sacudir %+.1f" % [float(suma["calma"]), float(suma["furia"])])
		_comprobar(absf(float(suma["calma"]) - float(suma["furia"])) > 0.5,
			"los tonos no dan lo mismo: elegir importa")
		for j: Jugador in once_ch:
			j.moral = int(moral_base[j.id])
		## Y el tono escrito se deduce de las palabras, que es lo que hace que
		## escribir en el camarin no sea decorativo.
		_comprobar(v_ch.tono_de_texto("¡¡Esto es una vergüenza, carajo!!") == "furia",
			"un grito con palabrota se lee como furia")
		_comprobar(v_ch.tono_de_texto("Esto es inaceptable, así no") == "exigir",
			"un reproche seco se lee como exigencia")
		_comprobar(v_ch.tono_de_texto("Tranquilos, confío en ustedes") == "animar",
			"un mensaje de confianza se lee como elogio")
		_comprobar(v_ch.tono_de_texto("Suban la línea y presionen la salida") == "tactico",
			"una indicacion de pizarra se lee como tactica")
		## El psicologo existe de verdad en el cuerpo tecnico: si no, el bonus de
		## la charla seria una linea muerta que devuelve cero para siempre.
		_comprobar(Staff.PUESTOS.has("psi"), "el psicologo deportivo existe como puesto contratable")

	## LO QUE LEE LA FICHA DEL JUGADOR. La pantalla no se puede probar, pero SI
	## se pueden probar las claves exactas que lee: escribir "nombre" donde el
	## motor guarda "n" no rompe nada -sale un texto vacio y ya-, que es la clase
	## de fallo que no se ve hasta que alguien mira esa ficha en concreto.
	var j_f: Jugador = m.mi_club().plantilla[0]
	if m.vestuario != null:
		var em_f: Dictionary = m.vestuario.estado_mental(j_f)
		_comprobar(em_f.has("txt") and em_f.has("color"), "estado_mental trae txt y color")
		var sat_f: Dictionary = m.vestuario.satisfaccion(j_f)
		for k_f in ["min", "rend", "tact", "inst", "total"]:
			_comprobar(sat_f.has(k_f), "satisfaccion desglosa '%s'" % k_f)
		var def_f := m.vestuario.def_rol(m.vestuario.rol_plantel(j_f))
		_comprobar(def_f.size() >= 4, "def_rol trae nombre y minutos exigidos (%d campos)" % def_f.size())
	if m.medico != null:
		## Se provoca una lesion para que el historial NO este vacio: probar el
		## formato de una lista vacia no prueba nada.
		m.medico.lesionar(j_f, Medico.MEDIA, "prueba de ficha", m.anio, m.semana)
		var h_f: Array = m.medico.historial(j_f)
		if not h_f.is_empty():
			var e_f: Dictionary = h_f[h_f.size() - 1]
			for k_h in ["n", "sem", "anio"]:
				_comprobar(e_f.has(k_h), "el historial medico guarda '%s'" % k_h)
		j_f.lesion = 0

	## LOS ROLES PROMETIDOS: lo que se prueba es que NO es un desplegable tonto.
	## Si `acepta_rol()` dejara pasar cualquier cosa, prometer seria gratis y el
	## sistema entero sobraria.
	var v_rp := m.vestuario
	return [m, v_rp]
