extends "res://nucleo/mundo_p4.gd"
## [Capa 5/9 de `mundo.gd`, tramo a] La semana, fases 1-4: contexto de los partidos, el once,
## la jornada de liga y la caja y el plantel de cada club.
##
## `avanzar_semana()` (en `mundo_p5.gd`) era un solo bloque de ~550 líneas partido a la fuerza en
## dos tramos por la norma de 450 líneas. Ahora es un guion de fases con nombre, repartidas en
## `mundo_p5_p1.gd` (esta), `mundo_p5_p2.gd` y `mundo_p5.gd`. El ORDEN de las fases es el de
## siempre y no se puede tocar a la ligera: cada tirada de `Azar` depende de las anteriores, así
## que reordenar dos fases cambia la partida entera (lo vigila `pruebas/huella_mundo.gd`).
## El único estado que pasa de una fase a otra va por parámetro (`ya_jugado`, `jugaron_en_casa`);
## lo demás es el propio mundo.

## FASE 1 · EL CONTEXTO DE LA SEMANA PARA TODOS LOS PARTIDOS que se van a jugar: el
## recorte de tarjetas por videoarbitraje -que vota la asamblea- y el parte
## medico de tu club. `Liga`, `Copa` y `Continental` crean sus partidos por
## dentro y no conocen el mundo, asi que se les deja puesto antes de empezar.
func _semana_contexto_de_partidos() -> void:
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

## FASE 2 · EL ONCE ANTES DE JUGAR. Si el banco no es tuyo, el entrenador arma su
## equipo ANTES de la jornada, con tus indicaciones si te hace caso. Va aquí y no
## dentro de `Liga` para que solo afecte a tu club: los otros 383 ya tienen su
## propio automático.
func _semana_once_antes_de_jugar() -> void:
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

## FASE 3 · LA JORNADA DE LIGA. Devuelve `{id del club local: Club rival}` de los
## que jugaron en casa, que es lo que la fase de caja necesita para cobrar taquilla.
## `ya_jugado` es el partido que el entrenador acaba de dirigir en directo: se
## anota su resultado en vez de volver a simularlo.
func _semana_jugar_ligas(ya_jugado: Partido) -> Dictionary:
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
	return jugaron_en_casa

## FASE 4 · LA CAJA Y EL PLANTEL DE CADA CLUB, club por club (los 384).
##
## El orden importa. Los sueldos se pagan DESPUÉS de la taquilla de la jornada,
## que es como funciona un club de verdad: primero entra lo del domingo y luego
## se paga. Al revés, un club justo de caja se le quedaba en números rojos un
## día antes de cobrar y la IA lo daba por arruinado. Y la caja de un club se
## cierra antes de pasar a su plantel, y su plantel antes que el club siguiente:
## así se han tirado siempre los dados de forma y de "pide salir".
func _semana_caja_y_plantillas(jugaron_en_casa: Dictionary) -> void:
	for c: Club in clubes.values():
		var f := _finanzas_de_la_semana(c)
		_cobrar_la_jornada(c, f, jugaron_en_casa)
		if semana % Finanzas.SEMANAS_DEL_MES == 0:
			_cerrar_el_mes(c, f)
		_semana_del_plantel(c)

## Las cuentas de la semana de un club. A los de la IA, las de siempre; al tuyo,
## además, las palancas que tú mueves (consejeros, obras, televisión).
func _finanzas_de_la_semana(c: Club) -> Finanzas:
	var soy_yo := c.id == mi_club_id
	var f := Finanzas.new(c, obras.aporte_ocupacion() if soy_yo else 0.0,
		directiva.honorarios_semanales() if soy_yo and directiva != null else 0,
		(0.1 if soy_yo and directiva != null and directiva.tiene_consejero("mkt") else 0.0))
	if soy_yo:
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
	return f

## Lo que entra y sale con la jornada: taquilla (con precios dinámicos, horario,
## techo, sanciones y fiestas), la concentración previa, el plus de la televisión
## y los socios del embajador.
func _cobrar_la_jornada(c: Club, f: Finanzas, jugaron_en_casa: Dictionary) -> void:
	var soy_yo := c.id == mi_club_id
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
	if en_casa and soy_yo:
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
	if en_casa and soy_yo:
		var plus_h := factor_tv_horario()
		if plus_h > 1.0:
			var plus := int(round(float(f.derechos_tv_base()) * (plus_h - 1.0) * 0.6))
			if plus > 0:
				c.mover_saldo(plus)
				_anotar_movimiento("Plus de televisión por el horario %s" % String(horario_actual()[1]), plus)
	## El embajador suma socios TODAS las semanas -"G.socios+=25" del HTML
	## corre en su función semanal, a diferencia del sueldo del cuerpo
	## técnico, que Godot ya paga en un solo pago mensual-.
	if soy_yo and directiva != null and not directiva.embajador.is_empty():
		c.socios += Directiva.SOCIOS_POR_SEMANA_EMBAJADOR

## El cierre de mes de un club: la nómina y, para el tuyo, el resto de sueldos y
## rentas del mes.
func _cerrar_el_mes(c: Club, f: Finanzas) -> void:
	f.mes()
	if c.id == mi_club_id:
		_nomina_y_rentas_del_mes(c)
	else:
		## La directiva cuadra las cuentas de los clubes de la IA. A tu club
		## no: ahi la caja es tuya y las consecuencias tambien.
		f.ajuste_de_directiva()

## Lo que tu club paga y cobra una vez al mes además de la nómina de la plantilla.
func _nomina_y_rentas_del_mes(c: Club) -> void:
	## El cuerpo tecnico cobra con el resto de la nomina. Asi un staff
	## grande aprieta la caja TODOS los meses, no solo el dia que se ficha.
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

## La semana del plantel de un club: bajas y sanciones que se descuentan, la forma
## que se mueve y los suplentes que se hartan.
func _semana_del_plantel(c: Club) -> void:
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
