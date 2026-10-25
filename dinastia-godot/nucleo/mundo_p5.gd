extends "res://nucleo/mundo_p5_p2.gd"
## [Capa 6/9 de `mundo.gd`] La semana, fases 14-21 (módulos del club, banco, ingresos comerciales,
## enfermería, entrenamiento, federación y plantel, continental y copa) y el guion `avanzar_semana`.

## Avanza una semana: jornada, dinero, mercado y recuperación, en ese orden.
##
## Es un guion: cada línea es una fase con nombre (fases 1-4 en `mundo_p5_p1.gd`, 5-13 en
## `mundo_p5_p2.gd`, el resto aquí). El ORDEN NO SE TOCA sin motivo: las fases tiran de `Azar`
## una detrás de otra, así que cambiar dos de sitio cambia la partida entera
## (`pruebas/huella_mundo.gd` lo detecta), y además hay dependencias de verdad -la caja se cobra
## después de la taquilla, el médico y el vestuario van después de descontar las bajas, la
## hinchada después de la prensa-, explicadas en cada fase.
## `ya_jugado` es el partido que el entrenador acaba de dirigir en directo: se anota su
## resultado en vez de volver a simularlo (liga, continental o copa, el que sea).
func avanzar_semana(ya_jugado: Partido = null) -> void:
	## El partido mirado no pasó por `simular()`: sus notas y la forma se
	## cierran aquí (antes ese partido no contaba en `Jugador.notas`).
	if ya_jugado != null:
		ya_jugado.cerrar_notas_mirado()
	_semana_contexto_de_partidos()
	_semana_once_antes_de_jugar()
	var jugaron_en_casa := _semana_jugar_ligas(ya_jugado)
	_semana_caja_y_plantillas(jugaron_en_casa)
	_semana_memoria_del_partido(ya_jugado)
	_semana_mercado()
	_semana_lesion_insolita()
	_semana_obras()
	_semana_ojeo()
	_semana_prensa_e_hinchada()
	_semana_vestuario_y_marca()
	_semana_carrera_del_dt()
	_semana_club_por_dentro()
	_semana_modulos_del_club()
	_semana_banco()
	_semana_ingresos_comerciales()
	_semana_enfermeria()
	_semana_entrenamiento()
	_semana_federacion_y_plantel()
	_semana_continental(ya_jugado)
	_semana_copa(ya_jugado)
	semana += 1
	Jugador.semana_global = anio * 100 + semana
	semana_avanzada.emit(semana, anio)

## FASE 14 · LOS MÓDULOS SEMANALES DEL CLUB: redes, mercado avanzado, fondo, cantera,
## calendario, política, contratos, leyes del país, maestría y vida personal.
func _semana_modulos_del_club() -> void:
	if redes != null:
		redes.iniciar(self)
		redes.semana(self)
	if mercado_av != null and mi_club() != null:
		mercado_av.semana(self)
	if fondo != null:
		fondo.semana(self)
	if eventos_cantera != null and mi_club() != null:
		eventos_cantera.semana(academia, mi_club(), anio, semana)
	if calendario != null and mi_club() != null:
		calendario.semana(mi_club(), anio, semana)
	if politica != null and mi_club() != null:
		politica.semana(mi_club(), anio, semana, prensa)
	if contratos != null and mi_club() != null:
		contratos.semana(mi_club(), anio, semana)
	LeyesPais.anio_actual = anio
	LeyesPais.clubes_mundo = clubes
	LeyesPais.tick += 1
	if maestria != null and mi_club() != null:
		maestria.semana(mi_club(), prensa, academia, semana, _resultado_semana)
	if vida != null and mi_club() != null and roles != null:
		vida.semana(mi_club(), roles, anio, semana, _resultado_semana)
		_resultado_semana = 2

## FASE 15 · EL BANCO: sobregiro, liquidación e insolvencia.
func _semana_banco() -> void:
	if banco == null or mi_club() == null:
		return
	## Los dos consejeros que hasta hoy decían "sin efecto" en su propia
	## descripción (`Directiva.CONSEJEROS`, `fin`/`leg`): era cierto
	## cuando se escribió, antes de que `Banco` existiera, pero se quedó
	## así después -un jugador podía pagarle a un consejero por algo que
	## de verdad no hacía nada, sin que nada avisara-. El financiero
	## abarata el sobregiro un 35%; el legal da tres semanas más antes de
	## la liquidación. Se fija cada semana -barato, y así no hace falta
	## enganchar un aviso aparte a contratar/despedir-.
	if directiva != null:
		banco.descuento_sobregiro = 0.65 if directiva.tiene_consejero("fin") else 1.0
		banco.gracia_liquidacion = 3 if directiva.tiene_consejero("leg") else 0
	banco.semana(mi_club())
	if insolvencia != null:
		insolvencia.semana(self)

## FASE 16 · LOS INGRESOS COMERCIALES DE CADA SEMANA: auspicio, explotación comercial
## y la ciudad.
func _semana_ingresos_comerciales() -> void:
	## EL AUSPICIO GOTEA TODAS LAS SEMANAS. No entra de golpe: es el `monto/42`
	## del HTML, y por eso firmar tarde cuesta dinero de verdad.
	if auspicio != null and mi_club() != null:
		var cuota_ausp := auspicio.semanal()
		if cuota_ausp > 0:
			mi_club().mover_saldo(cuota_ausp)
			_anotar_movimiento("Auspicio: %s" % auspicio.marca_en_camiseta(), cuota_ausp)
	## Y lo comercial: las cinco zonas de la camiseta, el naming del estadio, los
	## palcos y el contrato del proveedor. Todo junto en una linea porque todo
	## junto es como se cobra.
	if comercial != null and mi_club() != null:
		var renta_com := comercial.renta_semanal(mi_club())
		if renta_com > 0:
			mi_club().mover_saldo(renta_com)
			_anotar_movimiento("Explotación comercial (camiseta, estadio y palcos)", renta_com)
	## LA CIUDAD: los negocios anexos ingresan TODAS las semanas del año, jueguen
	## o no, y el resto -cesped, vecinos, permisos y sanciones- corre su plazo.
	if ciudad != null and mi_club() != null:
		ciudad.semana(mi_club(), prensa.animo if prensa != null else 60)
		if semana % 4 == 0:
			ciudad.mes()

## FASE 17 · LA ENFERMERÍA: el parte de la semana y el brote de gripe.
## OJO: va DESPUES del bucle que descuenta la semana de baja (fase 4). Si fuera
## antes, tu plantel se curaria al doble de velocidad que el de los
## rivales y no se veria en ninguna pantalla.
func _semana_enfermeria() -> void:
	if medico == null or mi_club() == null:
		return
	## La carga de la semana sale del PLAN de entrenamiento, no de una constante:
	## es lo que hace que apretar en los entrenamientos se pague en la enfermeria.
	var carga := entrenamiento.carga_riesgo() if entrenamiento != null else Medico.CARGA_POR_DEFECTO
	medico.revisar_semana(mi_club(), carga, anio, semana)
	## EL BROTE: una gripe que se lleva a media plantilla unos días. Cae dos
	## veces cada tres temporadas -0,7% semanal- y dura dos o tres semanas.
	## Es el único evento del juego que obliga a rotar de golpe, y por eso no
	## puede ser frecuente: si pasara cada mes dejaría de ser una urgencia.
	medico.avanzar_brote()
	if medico.brote.is_empty() and Azar.suerte(0.007):
		medico.iniciar_brote(mi_club(), Azar.ent(4, 8), Azar.ent(2, 3))

## FASE 18 · EL ENTRENAMIENTO: tu plantel con su plan y el resto del mundo con el suyo.
func _semana_entrenamiento() -> void:
	if entrenamiento == null or mi_club() == null:
		return
	entrenamiento.procesar_semana(mi_club(), anio, semana)
	## EL RESTO DEL MUNDO TAMBIÉN ENTRENA. `procesar_ajeno()` existía desde
	## hace tiempo -recuperación de físico y una progresión simple, sin foco
	## ni intensidad ni instalaciones, igual que `semEntrenamiento()` trata a
	## quien no es tuyo en el HTML- pero nadie la llamaba: el propio
	## comentario del código ya avisaba "sin esto, los rivales se quedan
	## congelados y en tres temporadas tu cantera domina el continente
	## sola". Va DESPUÉS de tu plantel y no antes, por la misma razón que el
	## médico: que tu progreso no dependa del orden en que se recorra nada.
	for c: Club in clubes.values():
		if c.id == mi_club_id:
			continue
		for j: Jugador in c.plantilla:
			entrenamiento.procesar_ajeno(j)

## FASE 19 · LA FEDERACIÓN Y EL PLANTEL: votaciones, vestuario, cesiones, selección,
## cantera, academia y bonificadores.
func _semana_federacion_y_plantel() -> void:
	if mi_club() == null:
		return
	## La federacion: votaciones, cupos y auditoria.
	federacion.semana(mi_club(), anio, semana)
	## El vestuario va DESPUES del bucle que descuenta lesiones: la baja
	## psicologica se cobra escribiendo `j.lesion`, y antes se la comeria el
	## descuento de la misma semana.
	if vestuario != null:
		vestuario.semana(semana)
		## EL SUCESO DEL CAMARIN. Una cosa pequeña por semana -el polemico se va
		## de fiesta, el lider reune al grupo, alguien cumple años-. Sin esto,
		## los rasgos de personalidad eran etiquetas que no pasaban nunca.
		vestuario.suceso_semanal()
		## LAS SOLICITUDES DEL PLANTEL. `sortear_solicitud()`/`resolver_solicitud()`
		## existían enteros -catálogo de siete peticiones, candidatos según la
		## situación real de cada uno- sin que nadie los llamara: ningún
		## jugador le pedía nunca nada al DT. Se tira una vez por semana, igual
		## que `suceso_semanal()`.
		vestuario.sortear_solicitud(obras)
	if cesiones != null:
		cesiones.pagar_cuotas(semana, mi_club())
		cesiones.revisar_bonos(mi_club())
	## La selección: prenómina, fecha FIFA y sus efectos en físico y moral.
	## Va aquí y no antes del descuento de lesiones por la misma razón que el
	## vestuario -si no, un jugador que vuelve tocado de gira se curaría la
	## misma semana en vez de perder las que le tocan.
	if selecciones != null:
		selecciones.semana(anio, semana)
	## La cantera: fugas de canteranos sin ficha profesional, y la presion de
	## la prensa sobre el que carga con un apellido ajeno.
	if cantera != null:
		cantera.procesar_semana()
		cantera.sortear_guerra_agentes()
	## La academia de 10 a 16: crecimiento, colegio, comida y la familia.
	if academia != null:
		academia.procesar_semana()
	## Y se recalculan los bonificadores: si no, el factor del camarin se queda
	## congelado en el de la semana en que tomaste el mando.
	aplicar_bonificadores()

## FASE 20 · LA RONDA CONTINENTAL, si esta semana toca.
func _semana_continental(ya_jugado: Partido) -> void:
	var fecha_conti := Continental.toca_ronda(semana)
	if fecha_conti < 0:
		return
	for t: Continental in continentales.values():
		if not t.en_curso():
			continue
		_fatiga_de_viaje(t)
		## `ya_jugado` -el partido que acabas de dirigir en vivo, si
		## era justo este cruce- para no volver a simularlo por
		## dentro y que el marcador que viste no coincida con el que
		## queda anotado. Hasta esta tanda esto se llamaba en blanco
		## SIEMPRE: `_dirigir()` no sabía llevarte a un continental,
		## así que nunca hacía falta -ahora sí-.
		var res_c: Array = t.jugar_ronda(ya_jugado if _continental_es_de(t, ya_jugado) else null)
		_rueda_de_eliminatoria(res_c, "conti", t.participantes)
		## El continental se corona a mitad de temporada, no al cierre:
		## por eso esta celebración no puede esperar a cerrar_temporada()
		## como la de liga y copa. `en_curso()` pasa a false en cuanto hay
		## campeón, así que esto solo entra la semana exacta en que se
		## decide -no cada semana que quede del año.
		if t.campeon == mi_club() and logros != null:
			logros.celebrar_titulo(Continental.nombre_conti(t.clave))

## FASE 21 · LA COPA: una ronda cada cuatro jornadas, en paralelo a la liga. Se monta
## la primera vez que hace falta y no al generar el mundo, porque al generar
## todavía no se sabe qué club diriges y la copa es la de TU país.
func _semana_copa(ya_jugado: Partido) -> void:
	if copa == null:
		_montar_copa()
	if copa != null and copa.en_curso() and semana % 4 == 0:
		var res_copa: Array = copa.jugar_ronda(ya_jugado if _copa_es_de(ya_jugado) else null)
		_rueda_de_eliminatoria(res_copa, "copa", copa.participantes)
