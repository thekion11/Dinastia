extends "res://nucleo/mundo_p3.gd"
## (Parte 4 de 8 de `mundo.gd`.)

## Le cuenta a la directiva como te fue el domingo.
##
## Solo mira TU partido: a la directiva de Coquimbo no le importa lo que hagas
## tu, y simular la paciencia de 383 juntas directivas seria gastar en algo que
## nadie va a ver.
func _avisar_a_la_directiva(resultados: Array) -> void:
	var mio := mi_club()
	if mio == null:
		return
	for r: Dictionary in resultados:
		var soy_local: bool = r["local"] == mio
		if not soy_local and r["visita"] != mio:
			continue
		var gf: int = r["gl"] if soy_local else r["gv"]
		var gc: int = r["gv"] if soy_local else r["gl"]
		if directiva != null and not directiva.despedido_ya:
			directiva.tras_partido(gf, gc, r["visita"] if soy_local else r["local"])
		## El prestigio del entrenador se mueve con CUALQUIER resultado tuyo, no
		## solo el que dirigiste: a diferencia de Logros (que necesita el once y
		## los goleadores del `Partido` completo, y eso solo sobrevive en el
		## dirigido), a Roles le basta el marcador, y ese SÍ llega siempre por
		## `resultados`.
		## EL CUPO JUVENIL, que la asamblea vota y nadie revisaba. `Federacion`
		## tenia escrita la multa por salir sin ningun sub-21 y la bonificacion por
		## cada uno que juegue, y no la llamaba nadie: se podia votar el reglamento
		## y no pasaba absolutamente nada en toda la temporada.
		if federacion != null and mio != null:
			federacion.revisar_cupo_juvenil(mio, mio.once())
			## Las reglas de la liga de tu país: si decidiste incumplirlas, multa.
			federacion.revisar_leyes_pais(self, mio)
			## La sanción al DT se cumple partido a partido.
			federacion.cumplir_sancion_dt()
		## EL FICHAJE IMPUESTO -por la ocupación hostil del dueño o el trato
		## comercial del patrocinador-, mismo patrón que el cupo juvenil de
		## arriba: `Prensa.revisar_impuesto()` ya existía escrito y nadie lo
		## llamaba desde que se firmaba el pacto en el despacho.
		if prensa != null and mio != null:
			prensa.revisar_impuesto(mio, mio.once(), anio)
		_gano_la_ultima = gf > gc
		_resultado_semana = 1 if gf > gc else (0 if gf == gc else -1)
		## "G.clubes[miClub].forma.push(...)" del HTML: solo cuenta para esto lo
		## que se juega de LIGA -este bloque nace de `_avisar_a_la_directiva`,
		## que `avanzar_semana()` llama justo después de `l.jugar_jornada()`-.
		if club_dentro != null:
			club_dentro.registrar_resultado_liga(gf > gc, gf == gc)
		## "G.ultArbMal" del HTML: perdiste -no empate, perdiste de verdad- y el
		## árbitro de ese partido es de los que sesgan -"casero"/"figura"-, así
		## que el directorio pregunta si reclamas formalmente (`Prensa.
		## arbitro_dudoso()`, cuya rama de despacho ya estaba completa y sin
		## nadie que la llamara). Solo liga, igual que el resto de este bloque.
		## MISMO `Previa.arbitro_de()` que ya usa `vPrevia()` y que acaba de
		## pitar el partido en `Partido.preparar()`: no una tercera copia del
		## hash.
		## El historial por árbitro (reglamento fino, 28-9-2026).
		if federacion != null:
			var rival_arb: Club = r["visita"] if soy_local else r["local"]
			var arb_h := Previa.arbitro_de(rival_arb.id, semana)
			federacion.anotar_arbitro(String(arb_h["nombre"]), String(arb_h["perfil"]), gf, gc)
		if prensa != null and gf < gc:
			var rival_perdido: Club = r["visita"] if soy_local else r["local"]
			var arb_partido := Previa.arbitro_de(rival_perdido.id, semana)
			if String(arb_partido["perfil"]) == "casero" or String(arb_partido["perfil"]) == "figura":
				prensa.arbitro_dudoso(String(arb_partido["nombre"]))
		## SE APUNTA CON QUE DIBUJO se jugo. Es lo que despues contesta «de verdad
		## me funciona el 4-3-3», que ninguna otra pantalla puede responder.
		anotar_eficacia(mio.tactica.formacion if mio.tactica != null else "", gf, gc)
		if roles != null:
			roles.tras_partido(gf, gc)
			## Y si el de enfrente es TU rival, el cruce se cuenta aparte: es la
			## unica estadistica del juego que no es del club, es tuya.
			var el_otro: Club = r["visita"] if soy_local else r["local"]
			roles.registrar_duelo(el_otro.id, gf > gc, gf == gc)
		## LAS REDES HABLAN DE LO QUE PASA. Sin esto el feed sería un generador
		## de frases sueltas; enganchado al resultado, es la voz de la gente.
		if prensa != null:
			var rival_p: Club = r["visita"] if soy_local else r["local"]
			if gf > gc:
				prensa.publicar("%d-%d al %s. Así da gusto." % [gf, gc, rival_p.nombre], "hincha", 1.6)
			elif gf < gc:
				prensa.publicar("%d-%d contra el %s. Otra vez lo mismo." % [gf, gc, rival_p.nombre], "troll", 1.8)
			else:
				prensa.publicar("Empate sin más contra el %s. Se escapan dos puntos." % rival_p.nombre, "analista", 1.0)
		## EL INCIDENTE EN EL ESTADIO. Solo de local, porque la seguridad que
		## pagas es la de TU recinto. Sube con el mal ambiente y la funa, y baja
		## con lo que hayas invertido: es lo que convierte a la seguridad privada
		## en un gasto que se entiende en vez de en un numero mas.
		if ciudad != null and soy_local and ciudad.sancion.is_empty() and prensa != null:
			if Azar.suerte(ciudad.riesgo_incidente(prensa.animo, prensa.funa)):
				ciudad.sancionar("cerradas" if Azar.suerte(0.35) else "aforo")
				ciudad.vecinos = clampi(ciudad.vecinos - Azar.ent(4, 10), 0, 100)
		## LA RUEDA DE PRENSA Y LA PORTADA DEL LUNES.
		##
		## `Prensa.sortear_rueda()` pedía un `Partido` entero y aquí solo llega
		## el marcador, así que no la llamaba nadie: la sala de prensa completa
		## -tres barajas de preguntas, cinco lenguajes corporales, trece
		## decisiones y la promesa que se cobra diez líneas más abajo- no se
		## abría ni una vez en una partida de verdad. La promesa se cobraba sin
		## que existiera forma de hacerla.
		if prensa != null:
			var otro: Club = r["visita"] if soy_local else r["local"]
			var gano := gf > gc
			var empato := gf == gc
			var semilla := "%d|%d|%s|%d-%d" % [anio, semana, otro.id, gf, gc]
			var loc0: Club = r["local"]
			var vis0: Club = r["visita"]
			prensa.portada_tras_resultado(gano, empato, es_clasico(mio, otro), semilla,
				"%s %d-%d %s" % [Nombres.visible(loc0.nombre), int(r["gl"]), int(r["gv"]), Nombres.visible(vis0.nombre)],
				HistoriaClub.nombre_clasico(mio.nombre, otro.nombre))
			## El tiempo de ese partido, por si la rueda pregunta por él.
			var loc: Club = r["local"]
			var vis: Club = r["visita"]
			prensa.clima_ultimo = Clima.del_partido(loc.pais, semana, anio, loc.id + vis.id)
			prensa.competicion_rueda = "liga"
			prensa.clubes_rueda = []
			prensa.rueda_tras_resultado(gano, empato)
		## LA PROMESA DE LA RUEDA DE PRENSA se cobra AQUÍ, que es el único sitio
		## donde se sabe el resultado. `Prensa.presion_prometida` se encendía al
		## responder al DT rival y `consumir_presion()` no la llamaba nadie: la
		## bravata salía gratis. Ahora tiene precio -y premio si se cumple-,
		## que es lo que convierte contestar en una decisión.
		if prensa != null and prensa.consumir_presion():
			if gf > gc:
				prensa.mover_animo(6)
				prensa.noticia.emit("Dijiste que ganabas y ganaste",
					"La hinchada celebra el doble: primero el resultado y después la cara del otro.")
			else:
				prensa.mover_animo(-8)
				prensa.noticia.emit("Prometiste y no cumpliste",
					"La frase de la conferencia se te da vuelta. En la calle no se habla del partido, se habla de ti.")
		if not desafios.is_empty():
			var rival: Club = r["visita"] if soy_local else r["local"]
			_chequear_desafios_tras_partido(gf, gc, rival)
		return

func horario_actual() -> Array:
	for h: Array in HORARIOS:
		if String(h[0]) == horario:
			return h
	return HORARIOS[0]

## Lo que el horario elegido hace con el público y con los derechos de TV.
func factor_publico() -> float:
	return float(horario_actual()[3])

func factor_tv_horario() -> float:
	return float(horario_actual()[4])

## ¿El partido que se acaba de dirigir era de copa y no de liga? Hace falta para
## no anotar un resultado en la competición equivocada.
func _copa_es_de(p: Partido) -> bool:
	if p == null or copa == null:
		return false
	var par := copa.emparejamiento_de(mi_club())
	return par.size() == 2 and par[0] == p.local and par[1] == p.visita

## Lo mismo que `_copa_es_de()`, pero para UN continental concreto -hay
## varios a la vez en `continentales`, uno por confederación, y el mismo
## `ya_jugado` no puede repartirse a todos: solo al que de verdad jugaste.
func _continental_es_de(t: Continental, p: Partido) -> bool:
	if p == null or t == null:
		return false
	var par := t.emparejamiento_de(mi_club())
	return par.size() == 2 and par[0] == p.local and par[1] == p.visita

func _informes_de_ojeo() -> void:
	var p := staff.ojo()
	if p <= 0.0 or not Azar.suerte(p):
		return
	var lista: Array = clubes.values()
	for intento in 30:
		var c: Club = lista[Azar.ent(0, lista.size() - 1)]
		if c.id == mi_club_id or c.plantilla.is_empty():
			continue
		var j: Jugador = c.plantilla[Azar.ent(0, c.plantilla.size() - 1)]
		## Solo interesa el informe que aporta algo: un chico con recorrido. De un
		## veterano de 33 ya se sabe todo con mirarle la media.
		if ojeados.has(j.id) or j.edad > 23 or j.pot < j.ovr + 8:
			continue
		ojeados[j.id] = true
		informe_de_ojeo.emit(j, c)
		return

func fiesta_de_la_semana() -> Array:
	return FIESTAS.get(semana, [])

func _procesar_fiesta() -> void:
	var f := fiesta_de_la_semana()
	if f.is_empty():
		return
	var mio := mi_club()
	if prensa != null:
		prensa.sumar_animo(Azar.ent(3, 8))
	## Navidad da descanso; el aniversario trae socios. Cada fiesta hace algo
	## distinto: si todas subieran el ánimo y ya está, daría igual cuál fuera.
	if mio != null:
		if semana == 12:
			for j in mio.plantilla:
				j.fisico = clampi(j.fisico + 4, 10, 100)
		elif semana == 20:
			mio.socios += Azar.ent(200, 900)
	if prensa != null:
		prensa.noticia.emit("%s %s" % [String(f[0]), String(f[1])], "%s." % String(f[2]))

## Lo idolo que es se aproxima con lo que lleva hecho AQUI -partidos y goles
## con esta camiseta-, que es de lo que sale el salon de la fama. Un fichaje
## recien llegado no tiene marca personal en este club por muy bueno que sea,
## y eso es exactamente lo correcto. Publica (no solo interna a
## `ingreso_marca()`) para que la ficha del jugador pueda enseñar el mismo
## numero -esIdolo()/marcaPersonal() del HTML- en vez de inventar otro.
func idolo_aproximado(j: Jugador) -> int:
	return clampi(j.partidos + j.goles * 3, 0, 100)

# ---------------------------------------------------------------------------
#  LA MARCA PERSONAL DE TUS FIGURAS Y LOS DÍAS SEÑALADOS
# ---------------------------------------------------------------------------

## Cuánta marca personal tiene un futbolista: cuánto vende él, no el club. Sale
## de su nivel, de lo ídolo que sea y de las habilidades especiales que domina,
## que son las que salen en los vídeos.
static func marca_personal(j: Jugador, idolo: int, habilidades: int) -> int:
	var base := float(j.ovr - 60) * 2.2 + float(idolo) * 0.35 + float(habilidades) * 3.0
	return clampi(int(round(base)), 0, 100)

## Lo que las figuras le dejan al club por semana. Y el precio: con tres o más
## jugadores muy mediáticos, el foco se lo llevan ellos y no el escudo —eso sube
## el ruido, que es exactamente lo que pasa en un vestuario de estrellas—.
func ingreso_marca() -> int:
	var mio := mi_club()
	if mio == null:
		return 0
	var bruto := 0
	var egos := 0
	for j: Jugador in mio.plantilla:
		var idolo := idolo_aproximado(j)
		var habs := entrenamiento.habilidades(j).size() if entrenamiento != null else 0
		var m := marca_personal(j, idolo, habs)
		if m < 55:
			continue
		bruto += Eco.escalar(1800.0 * (float(m) / 100.0), float(mio.rep))
		if m >= 80:
			egos += 1
	if egos >= 3 and prensa != null:
		prensa._mover_funa(1)
	return bruto

## LOS VIAJES LARGOS SE PAGAN EN LAS PIERNAS. Porte de `fatigaViaje()` +
## `aplicarFatigaViaje()` del HTML, que hasta ahora no existía en Godot: jugar de
## visita un continental contra un club de OTRO país costaba lo mismo que un
## clásico de barrio.
##
## Mismas cuentas que el HTML -golpe de 4 a 9, el once lo paga entero y el resto
## un 35%-, con dos correcciones que hay que tener escritas:
##
## 1. **El alivio.** El HTML resta `G.inst.pf*0.4 + G.staff.pf*0.6 +
##    G.inst.piscina*0.5`, pero `pf` no es una instalación sino un puesto del
##    cuerpo técnico (la lista de la línea 6014 de `juego.js`, con sueldo): ese
##    primer sumando valía 0 siempre. Aquí queda el preparador físico (`fisico`
##    en `Staff.PUESTOS`) y la piscina, que es lo que el HTML hacía en la práctica.
## 2. **El avión.** `Comercial.alivio_de_viaje()` existía, se cobraba y se
##    anunciaba ("menos fatiga en los viajes largos") y nadie lo llamaba: comprar
##    el avión no hacía nada. Ahora resta sus 3 puntos aquí.
##
## Va ANTES de `jugar_ronda()` para que el cansancio se note en ESE partido, que
## es donde el HTML lo aplica (`prepararPartido`, antes de armar el once).
func _fatiga_de_viaje(t: Continental) -> void:
	var mio := mi_club()
	if mio == null:
		return
	var par := t.emparejamiento_de(mio)
	if par.size() != 2 or par[1] != mio or par[0] == null or par[0].pais == mio.pais:
		return
	var alivio := float(staff.nivel("fisico")) * 0.6 + float(obras.nivel("piscina")) * 0.5
	if comercial != null:
		alivio += float(comercial.alivio_de_viaje())
	var f := maxi(1, int(round(float(Azar.ent(4, 9)) - alivio)))
	var once := mio.once()
	for j: Jugador in mio.plantilla:
		var golpe := float(f) if once.has(j) else float(f) * 0.35
		j.fisico = clampi(int(round(float(j.fisico) - golpe)), 10, 100)
	if prensa != null:
		prensa.noticia.emit("✈️ Vuelta de un viaje largo",
			"El plantel llegó de madrugada desde %s y paga el viaje: −%d de estado físico a los que juegan." % [
				par[0].nombre, f])

## LA RUEDA DE PRENSA TAMBIÉN DESPUÉS DE LA COPA (26-9-2026, plan maestro C1).
## Hasta hoy solo se abría tras la liga. Con la misma tirada de siempre
## (`rueda_tras_resultado`), y avisando a la sala de qué competición es para
## que los escudos del fondo sean los de ESA competición.
func _rueda_de_eliminatoria(resultados: Array, comp: String, clubes: Array) -> void:
	var mio := mi_club()
	if prensa == null or mio == null:
		return
	for r: Dictionary in resultados:
		if r["local"] != mio and r["visita"] != mio:
			continue
		var soy_local: bool = r["local"] == mio
		var gf: int = r["gl"] if soy_local else r["gv"]
		var gc: int = r["gv"] if soy_local else r["gl"]
		var paso: bool = r.get("pasa") == mio if r.has("pasa") else gf > gc
		var loc: Club = r["local"]
		var vis: Club = r["visita"]
		prensa.clima_ultimo = Clima.del_partido(loc.pais, semana, anio, loc.id + vis.id)
		prensa.competicion_rueda = comp
		prensa.clubes_rueda = clubes.duplicate()
		prensa.rueda_tras_resultado(paso or gf > gc, gf == gc and not r.has("pasa"))
		return
