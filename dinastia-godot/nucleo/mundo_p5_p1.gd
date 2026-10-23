extends "res://nucleo/mundo_p4.gd"
## [Capa 5/9 de `mundo.gd`] avanzar_semana_1

## (Parte 5 de 8 de `mundo.gd`.)

## Avanza una semana: jornada, dinero, mercado y recuperación, en ese orden.
##
## El orden importa. Los sueldos se pagan DESPUÉS de la taquilla de la jornada,
## que es como funciona un club de verdad: primero entra lo del domingo y luego
## se paga. Al revés, un club justo de caja se le quedaba en números rojos un
## día antes de cobrar y la IA lo daba por arruinado.
## `ya_jugado` es el partido que el entrenador acaba de dirigir en directo: se
## anota su resultado en vez de volver a simularlo.
## Tramo 1 de 2 de `avanzar_semana` (la norma de 450 líneas la troceó).
func avanzar_semana_1(ya_jugado: Partido):
	## El partido mirado no pasó por `simular()`: sus notas y la forma se
	## cierran aquí (antes ese partido no contaba en `Jugador.notas`).
	if ya_jugado != null:
		ya_jugado.cerrar_notas_mirado()
	## EL CONTEXTO DE LA SEMANA PARA TODOS LOS PARTIDOS que se van a jugar: el
	## recorte de tarjetas por videoarbitraje -que vota la asamblea- y el parte
	## medico de tu club. `Liga`, `Copa` y `Continental` crean sus partidos por
	## dentro y no conocen el mundo, asi que se les deja puesto antes de empezar.
	Partido.ctx_factor_tarjetas = federacion.factor_tarjetas() if federacion != null else 1.0
	Partido.ctx_medico = medico
	Partido.ctx_club_id = mi_club_id
	Partido.ctx_anio = anio
	Partido.ctx_semana = semana
	## EL CÉSPED DE TU ESTADIO. `Ciudad.penalizacion_cesped()` -"el único
	## efecto" del césped, dice su propio comentario- llevaba escrita desde
	## siempre sin que nadie la multiplicara en ningún cálculo de partido:
	## alquilar el estadio para un concierto rompía el pasto solo en
	## apariencia, sin costo deportivo. Mismo mecanismo de contexto que
	## `ctx_club_id`: se calcula una vez por semana, no dentro del bucle de
	## fuerzas.
	Partido.ctx_cesped_local = ciudad.penalizacion_cesped() if ciudad != null else 1.0
	## B6.5: la superficie decide cuánto de ese desgaste llega al campo y cuánto
	## se lesiona la gente en él.
	if estadio != null:
		Partido.ctx_cesped_local = lerpf(1.0, Partido.ctx_cesped_local, estadio.factor_desgaste_cesped())
		Partido.ctx_lesion_local = estadio.factor_lesion()
	## La moda de la era, para todos los dibujos que existen. Se calcula una vez
	## por semana y no dentro del bucle de fuerzas, que corre miles de veces.
	Partido.ctx_analisis = consumir_analisis()
	Partido.ctx_moda = {}
	var formas: Variant = Datos.tabla("FORMS")
	if formas is Dictionary:
		for f: String in (formas as Dictionary):
			Partido.ctx_moda[f] = factor_moda(f)
	## Si el banco no es tuyo, el entrenador arma su equipo ANTES de la jornada,
	## con tus indicaciones si te hace caso. Va aquí y no dentro de `Liga` para
	## que solo afecte a tu club: los otros 383 ya tienen su propio automático.
	## LA ROTACION, antes que nada: si esta puesta, los fundidos salen del once
	## y entran los frescos. Va antes de las directrices porque el entrenador
	## empleado puede querer cambiar el once despues, y manda el.
	var rotados := aplicar_rotacion()
	if rotados > 0 and prensa != null:
		prensa.noticia.emit("Rotacion",
			"%d cambio(s) en el once: los que llegaban fundidos descansan." % rotados)
	if roles != null and mi_club() != null:
		roles.aplicar_directrices(mi_club())
		## Y con el once ya armado se anota con qué modelo saliste. Va DESPUÉS
		## de las directrices a propósito: si el entrenador empleado te cambió
		## el dibujo, la escuela que nazca es la suya, no la que tú pediste.
		roles.chequeo_filosofia(mi_club().tactica)
	var jugaron_en_casa := {}
	for l in ligas:
		if l.quedan_jornadas():
			## Se anota quién jugó en casa ANTES de jugar la jornada, porque
			## `jugar_jornada` ya avanza el contador y después no hay forma de
			## saber a quién le tocaba taquilla.
			for par: Array in l.calendario[l.jornada_actual]:
				## Se guarda el RIVAL, no solo que se jugo en casa: los precios
				## dinamicos cobran segun contra quien se juega, y despues de la
				## jornada ya no hay forma de saberlo.
				jugaron_en_casa[par[0].id] = par[1]
			var resultados := l.jugar_jornada(ya_jugado)
			_avisar_a_la_directiva(resultados)

	for c: Club in clubes.values():
		var soy_yo := c.id == mi_club_id
		var f := Finanzas.new(c, obras.aporte_ocupacion() if soy_yo else 0.0,
			directiva.honorarios_semanales() if soy_yo and directiva != null else 0,
			(0.1 if soy_yo and directiva != null and directiva.tiene_consejero("mkt") else 0.0))
		if c.id == mi_club_id:
			f.movimiento.connect(_anotar_movimiento)
			## LOS TRES MULTIPLICADORES DE LA TELEVISION, que existian los tres y
			## no movian una moneda: el reparto que vota la asamblea y el modelo de
			## contrato que elige el club. El del horario se cobra aparte, por
			## partido, porque asi lo paga la television de verdad.
			f.factor_tv = federacion.factor_tv() * (prensa.factor_tv() if prensa != null else 1.0)
			## "OPERACIÓN, VIAJES, SEGURIDAD E IMPUESTOS": el "oper" del HTML, que
			## nunca se portó -sin él, el mundo entero cobraba television y
			## patrocinio sin devolver un 42% de eso en gastos de club, y por eso
			## `Instalaciones.abarata_operacion()` llevaba escrita desde antes sin
			## que la llamara nadie. Solo la paga tu club -los otros 383 usan el
			## ajuste de la directiva como correctivo, no esta partida suelta-.
			f.aplica_operacion = true
			f.factor_operacion = obras.abarata_operacion()
			f.factor_estructura = Contratos.factor_estructura(c.pais, anio, semana)
		var en_casa := jugaron_en_casa.has(c.id)
		## LOS PRECIOS DINAMICOS. El mismo asiento no vale lo mismo contra el
		## lider que contra el colista, y con el interruptor encendido se cobra
		## asi. Solo para tu club: la IA no juega con la caja.
		if en_casa and soy_yo and hinchada != null and hinchada.precio_dinamico:
			var rival_casa: Club = jugaron_en_casa[c.id]
			var cobrado := hinchada.precio_efectivo(int(round(c.precio_entrada)), rival_casa.rep)
			f.precio_de_hoy = float(cobrado)
			## Y la gente lo nota: subirle la entrada el dia del clasico se paga
			## en animo, que es lo que impide que esto sea dinero gratis.
			var castigo := hinchada.castigo_por_subida(int(round(c.precio_entrada)), cobrado)
			if castigo > 0 and prensa != null:
				prensa.mover_animo(-castigo)
		if en_casa and c.id == mi_club_id:
			## Se anota la asistencia real: es de donde salen los ingresos de
			## estacionamiento, que si no cobrarian sobre un cero.
			obras.ultima_asistencia = f.asistencia()
			## La concentración previa: hotel y logística por cada partido en
			## casa, a cambio de dos puntos de físico para todo el plantel.
			if bool(normas.get("conc", false)):
				var coste_conc := Eco.escalar(3500, c.rep)
				c.mover_saldo(-coste_conc)
				_anotar_movimiento("Concentración previa (hotel y logística)", -coste_conc)
				for j in c.plantilla:
					j.fisico = clampi(j.fisico + 2, 10, 100)
		## El horario elegido mueve la taquilla: un lunes por la noche llena un
		## tercio menos. El otro lado -los derechos de TV- lo cobra `Federacion`.
		## EL TECHO RETRACTIL salva la taquilla cuando llueve, que es literalmente
		## para lo que se compra. Multiplica el factor de publico del horario.
		var f_publico := factor_publico()
		if soy_yo and comercial != null:
			f_publico *= comercial.factor_techo()
		## Y LA SANCION DEL TRIBUNAL. Puertas cerradas es cero taquilla y aforo
		## reducido es un 40%: es la unica forma que tiene el juego de cobrarte un
		## incidente en el estadio, y por eso vale la pena pagar seguridad.
		if soy_yo and ciudad != null:
			f_publico *= ciudad.factor_aforo()
		## C13: una semana de fiesta nacional llena más el estadio (y una de
		## memoria no: con duelo no hay fiesta).
		if soy_yo:
			f_publico *= Calendario.factor_publico(c.pais, anio, semana)
			if maestria != null:
				f_publico *= maestria.factor_publico()
		f.semana(en_casa, false, f_publico)
		## EL PLUS DE LA TELEVISION POR EL HORARIO. Un lunes por la noche no va
		## nadie al estadio y paga mucho mas la television: sin este cobro, elegir
		## horario era regalar taquilla a cambio de nada.
		if en_casa and c.id == mi_club_id:
			var plus_h := factor_tv_horario()
			if plus_h > 1.0:
				var plus := int(round(float(f.derechos_tv_base()) * (plus_h - 1.0) * 0.6))
				if plus > 0:
					c.mover_saldo(plus)
					_anotar_movimiento("Plus de televisión por el horario %s" % String(horario_actual()[1]), plus)
		## El embajador suma socios TODAS las semanas -"G.socios+=25" del HTML
		## corre en su función semanal, a diferencia del sueldo del cuerpo
		## técnico, que Godot ya paga en un solo pago mensual-.
		if c.id == mi_club_id and directiva != null and not directiva.embajador.is_empty():
			c.socios += Directiva.SOCIOS_POR_SEMANA_EMBAJADOR
		if semana % Finanzas.SEMANAS_DEL_MES == 0:
			f.mes()
			## El cuerpo tecnico cobra con el resto de la nomina. Asi un staff
			## grande aprieta la caja TODOS los meses, no solo el dia que se ficha.
			if c.id == mi_club_id:
				var st := staff.sueldo_semanal(c.rep) * Finanzas.SEMANAS_DEL_MES
				if st > 0:
					c.mover_saldo(-st)
				## El entrenador empleado -o tu jefe, si eres ayudante- tambien
				## cobra: "G.rol!=='dt'&&G.dtEmp" del HTML. Si diriges tu mismo
				## no hay a quien pagarle.
				if roles != null and roles.rol != Roles.DT and not roles.dt_empleado.is_empty():
					var sueldo_dt := Roles.SUELDO_SEMANAL_DT_EMPLEADO * Finanzas.SEMANAS_DEL_MES
					c.mover_saldo(-sueldo_dt)
					_anotar_movimiento("Sueldo del entrenador: %s" % roles.dt_nombre(), -sueldo_dt)
				if directiva != null and not directiva.embajador.is_empty():
					var sueldo_emb := int(directiva.embajador.get("sueldo", Directiva.SUELDO_EMBAJADOR_SEMANAL)) * Finanzas.SEMANAS_DEL_MES
					c.mover_saldo(-sueldo_emb)
					_anotar_movimiento("Embajador: %s" % String(directiva.embajador.get("nombre", "")), -sueldo_emb)
				## Y lo que dan la tienda, el museo y los estacionamientos: son los
				## unicos ingresos del club que no dependen de ganar partidos.
				var sube_tienda := directiva != null and directiva.tiene_consejero("mkt")
				for ing: Dictionary in obras.ingresos_del_mes(c):
					var monto: int = ing["monto"]
					if sube_tienda and String(ing["concepto"]) == "Tienda y museo":
						monto = int(round(float(monto) * 1.1))
					c.mover_saldo(monto)
				var mant := obras.mantenimiento_del_mes(c.rep)
				if mant > 0:
					c.mover_saldo(-mant)
					_anotar_movimiento("Mantenimiento de instalaciones", -mant)
				var venta := ingreso_tienda(c)
				if venta > 0:
					c.mover_saldo(venta)
					_anotar_movimiento("Tienda del club", venta)
				## Los medios propios del club: si no te gusta cómo lo cuentan,
				## cuéntalo tú. Cuestan una vez y rentan cada mes.
				if prensa != null:
					var medios_r := prensa.renta_medios(c)
					if medios_r > 0:
						c.mover_saldo(medios_r)
						_anotar_movimiento("Medios propios del club", medios_r)
				## Las ramas del club NO dan dinero: cuestan. Lo que dan es
				## reputación, y esa decisión -sostener el femenino aunque no
				## pague- es de las que definen qué clase de club llevas.
				if hinchada != null:
					var ramas_c := hinchada.coste_ramas(c)
					if ramas_c > 0:
						c.mover_saldo(-ramas_c)
						_anotar_movimiento("Ramas deportivas del club", -ramas_c)
					c.socios += hinchada.socios_de_penas()
			## La directiva cuadra las cuentas de los clubes de la IA. A tu club
			## no: ahi la caja es tuya y las consecuencias tambien.
			if c.id != mi_club_id:
				f.ajuste_de_directiva()
		for j in c.plantilla:
			if j.lesion > 0:
				j.lesion -= 1
			if j.suspension > 0:
				j.suspension -= 1
			## El preparador fisico se nota aqui: tu plantel pierde menos forma. Es
			## un solo numero, pero es el que hace que contratarlo no sea un boton
			## de gastar dinero.
			var suelo := -3 + ((staff.aguante() + obras.aguante()) if c.id == mi_club_id else 0)
			j.forma = clampi(j.forma + Azar.ent(mini(suelo, 0), 4), 20, 99)
			## Un suplente que no juega se harta. Es lo que alimenta el mercado
			## de la IA: sin gente descontenta no hay traspasos.
			## Con una prima de fidelidad vigente no pide salir -esa es la promesa
			## que se le pagó, ofrecerFidelidad() del HTML-.
			if j.partidos == 0 and semana > 6 and (j.fidelidad_hasta <= 0 or anio >= j.fidelidad_hasta) and Azar.suerte(0.02):
				j.pide_salir = true

	## La memoria del club: cara a cara, rachas y récords. Solo el partido que
	## dirigiste en directo trae el `Partido` completo con el once y los
	## goleadores -`Liga.jugar_jornada()` descarta esos datos para los que solo
	## se simulan por dentro, así que semanas sin dirigir no alimentan la
	## memoria. Es una limitación conocida, no un olvido.
	if ya_jugado != null and logros != null and mi_club() != null \
			and (ya_jugado.local == mi_club() or ya_jugado.visita == mi_club()):
		## Antes solo distinguía Copa/Liga: un continental dirigido en vivo
		## quedaba anotado como "Liga" en la memoria del club, mentira chica
		## pero mentira -ahora que `_dirigir()` sí puede llevarte a uno-.
		var competicion := "Liga"
		if _copa_es_de(ya_jugado):
			competicion = "Copa"
		elif _continental_es_de(mi_continental(), ya_jugado):
			competicion = "Continental"
		logros.tras_partido(ya_jugado, competicion, int(obras.ultima_asistencia))
	## El interinato se cuenta en fechas, no en semanas: `fechas_interinato_
	## restantes()` las saca del propio calendario de la liga, así que llamar de
	## más no adelanta ni atrasa nada -solo hay que no dejar de llamarla.
	if roles != null and mi_club() != null:
		roles.tras_jornada()

	mercado.mover()
	mercado.buscar_oferta_por_mi_jugador()
	if libres.is_empty():
		generar_libres()
	_procesar_libres()
	## El toque de queda: disciplina a cambio de humor. Cada seis semanas.
	if bool(normas.get("queda", false)) and semana % 6 == 0:
		var mio_normas := mi_club()
		if mio_normas != null:
			for j in mio_normas.plantilla:
				j.cambiar_moral(-1, "Normas y cuerpo técnico del club")
	## LESIONES ABSURDAS FUERA DE LA CANCHA (C8): raras, cortas y noticia. El
	## toque de queda evita las de noche. Sin `Azar`.
	var absurda := LesionesAbsurdas.sortear(mi_club(), anio, semana, bool(normas.get("queda", false)))
	if not absurda.is_empty():
		var ja: Jugador = absurda["jugador"]
		ja.lesionar(int(absurda["semanas"]))
		if prensa != null:
			var txt := "%s. Estará %d semana%s de baja." % [String(absurda["texto"]), int(absurda["semanas"]),
				"" if int(absurda["semanas"]) == 1 else "s"]
			prensa.noticia.emit("🤕 Lesión insólita", txt)
			prensa.guardar_portada("¡INSÓLITO! " + String(absurda["texto"]).to_upper(), txt, "mal",
				{"img": "pid:" + ja.id, "sub": txt, "medio": "Canal Deportes", "nueva": true})
			if bool(absurda["noche"]):
				prensa.mentor_dice.emit("Lo de %s" % ja.nombre,
					"Esto pasó de noche. Un toque de queda en las normas del vestuario habría evitado el disgusto.")

	## Las obras avanzan una semana. Se hace antes de la prensa para que la
	## noticia de "obra terminada" salga la misma semana en que termina.
	var mio_obras := mi_club()
	if mio_obras != null:
		for k in obras.avanzar_semana(mio_obras):
			obra_lista.emit(k)
		if prensa != null:
			for txt: String in obras.ultimos_imprevistos:
				prensa.noticia.emit("🚧 Imprevisto en la obra", txt)
		## La reforma del diseñador del estadio también es obra.
		if estadio != null and estadio.avanzar_semana():
			obra_lista.emit("reforma_estadio")

	## El ojeador trae informes: descubre el techo real de un chico de otro club.
	## Es lo unico que hace que fichar a ciegas y fichar informado se distingan.
	_informes_de_ojeo()
	## El humor de la red de ojeadores por nombre -si nunca les haces caso,
	## renuncian y se pierde la cobertura de su país-.
	if ojeadores != null:
		ojeadores.procesar_semana()
		## EL MODELO DE DATOS busca por su cuenta, y a partir del nivel dos se pelea
		## con el ojeo de siempre. El nivel del jefe de ojeadores decide si hay
		## guerra: sin vieja escuela en casa no hay con quien discutir.
		ojeadores.semana_analitica(staff.nivel("ojo") if staff != null else 0)
		## Y las sedes internacionales cuestan todas las semanas, se use o no la
		## joya que traen en pretemporada.
		if mi_club() != null:
			var mant := ojeadores.mantencion_academias(mi_club())
			if mant > 0:
				mi_club().mover_saldo(-mant)
				_anotar_movimiento("Academias internacionales", -mant)

	## El pulso de la semana fuera del campo: prensa, parte medico y continental.
	if prensa != null:
		prensa.semana()
		prensa.semana_redes()
		prensa.sortear_evento()
		## El vocero se va con el jugador: si lo vendes, el club se queda mudo.
		prensa.revisar_vocero(mi_club())
		## LA PRESION DEL FONDO. Si vendiste un porcentaje de un canterano, el que
		## lo compro quiere cobrar, y aparece a pedir que lo vendas. Decir que no
		## cuesta moral del chico: su entorno le come la cabeza.
		if cesiones != null and prensa.pendiente.is_empty():
			var pf := cesiones.presion_de_fondo()
			if not pf.is_empty():
				var jf: Jugador = pf["jugador"]
				prensa.pendiente = {
					"id": "fondo_presiona", "pid": jf.id,
					"txt": "💸 %s" % String(pf["texto"]),
					"opcion_a": "Ponerlo en el mercado", "opcion_b": "No se vende",
				}
				prensa.evento_creado.emit(prensa.pendiente)
		## La hinchada se mueve DESPUÉS de la prensa, que es quien acaba de
		## actualizar el ánimo: al revés reaccionaría al ánimo de la semana
		## pasada y los segmentos irían siempre un paso por detrás.
		if hinchada != null:
			hinchada.semana(prensa.animo)
	## EL UTILERO. Un punto de moral a todo el plantel cuando llega a nivel 3.
	## Es lo mas pequeño que hace un puesto del cuerpo tecnico, y es a proposito:
	## es el que se contrata cuando ya esta todo lo demas.
	if staff != null and mi_club() != null:
		var util := staff.bono_utilero()
		if util > 0:
			for j in mi_club().plantilla:
				j.cambiar_moral(util, "Normas y cuerpo técnico del club")
	## LOS DIAS SEÑALADOS y lo que dejan las figuras por su marca personal. Los
	## dos son del HTML y no estaban portados: la temporada eran cuarenta y dos
	## semanas iguales, y tener una estrella no daba un peso de mas.
	_procesar_fiesta()
	if mi_club() != null:
		var marca := ingreso_marca()
		if marca > 0:
			mi_club().mover_saldo(marca)
			_anotar_movimiento("Marca personal de tus figuras", marca)
	if gente != null:
		gente.semana()
	## El sueldo del entrenador va a SU bolsillo, no a la caja del club: son dos
	## dineros distintos y esa separación es lo que hace que exista una carrera
	## personal por encima de la gestión.
	## EL DESCUENTO DEL CONTABLE en la nomina del cuerpo tecnico. Se refresca
	## cada semana porque el arbol puede crecer entre una y otra.
	if staff != null and entrenamiento != null:
		staff.factor_sueldos = entrenamiento.factor_sueldo_staff()
	if roles != null:
		roles.semana_patrimonio()
		## EL DESGASTE. Una semana en el cargo cansa; ganar descansa y la funa
		## quema. No te echa nunca: te deja trabajando peor, que es distinto.
		roles.semana_desgaste(_gano_la_ultima, prensa.funa if prensa != null else 0)
		## LA CARRERA POR DENTRO: el rival personal aparece solo cuando hay con
		## quien picarse, la leyenda viva visita cada seis semanas y los clubes
		## filiales reparten dividendos cada tres meses.
		roles.buscar_rival_dt()
		## QUE TE QUIERA OTRO CLUB. Lo unico del juego que te ofrece IRTE: sin
		## esto, la unica forma de cambiar de banquillo es que te echen.
		var of := roles.sortear_oferta_de_club()
		if not of.is_empty() and prensa != null:
			prensa.noticia.emit("Te quiere %s" % String(of["nombre"]),
				"Han llamado desde %s: te ofrecen su banquillo. Puedes contestar en Club › Legado." % String(of["nombre"]))
		roles.semana_leyenda_viva()
		roles.semana_filiales()
	if club_dentro != null and mi_club() != null:
		club_dentro.semana(mi_club(), prensa)
		## La app y la web CRECEN cada semana -"procesoClubIn()" del HTML corre
		## en el mismo proceso semanal que la prensa o la cantera, no en el
		## cierre de mes-, y crecen más rápido si vienes ganando en liga.
		for mov: Dictionary in club_dentro.crecer_digital(mi_club(), prensa):
			_anotar_movimiento(String(mov["concepto"]), int(mov["monto"]))
	if junta != null and mi_club() != null:
		junta.semana(mi_club(), anio, semana)
	if charlas != null and mi_club() != null:
		charlas.semana(mi_club(), anio, semana)
	if trabajadores != null and mi_club() != null:
		trabajadores.semana(mi_club(), obras, anio, semana, prensa)
