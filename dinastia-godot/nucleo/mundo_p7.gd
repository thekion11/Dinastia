extends "res://nucleo/mundo_p6.gd"
## [Capa 8/9 de `mundo.gd`] nueva_temporada, perfil_estadio_de, estacion, clima, campana_lanzada_este_anio, lanzar_campana … (+11)

## Cerrar la temporada ES pasar a la siguiente: premios, ascensos y `anio + 1`
## en el núcleo. Antes `cerrar_temporada()` dejaba el año quieto (diez cierres
## y la partida seguía en 2026). La UI llama a `nueva_temporada()`: una vez.
func cerrar_temporada() -> Dictionary:
	return nueva_temporada()

func nueva_temporada() -> Dictionary:
	## Primero se cierra la que acaba -premios, ascensos y descensos- y DESPUÉS
	## envejece la gente. Al revés, los clubes se repartirían las divisiones con
	## las plantillas del año siguiente y el descendido ya habría perdido a sus
	## veteranos antes de saber que bajaba.
	var resumen := _cerrar_campeonato()
	## Lo que queda entre partidas: un sobre de cromos y la foto del mundo.
	Meta.fin_de_temporada(self)
	## La selección y el Mundial de Clubes leen los campeones continentales de
	## ESTA temporada que se acaba, así que van antes de volver a sortear los
	## continentales de la siguiente -si no, mirarían el cuadro vacío del año
	## que recién empieza y el Mundial de Clubes nunca tendría campeón.
	if selecciones != null:
		resumen["selecciones"] = selecciones.cierre_de_temporada(anio)
	anio += 1
	semana = 1
	for c: Club in clubes.values():
		var siguen: Array[Jugador] = []
		for j in c.plantilla:
			## La foto de la media con la que arranca el ano, para poder decir
			## despues cuanto crecio cada uno. Se toma ANTES de la curva de
			## progreso de abajo: si se tomara despues, el crecimiento del ano
			## saldria siempre a cero.
			j.ovr_al_empezar = j.ovr
			## `anio` ya se incrementó arriba (línea de "anio += 1"): `anio - 1`
			## es la temporada que de verdad se está cerrando.
			j.registrar_temporada(anio - 1, c.nombre)
			j.edad += 1
			j.partidos = 0
			j.goles = 0
			j.amarillas = 0
			## La curva de progreso: los jovenes suben hacia su techo, los
			## veteranos bajan. Es lo que hace que una plantilla envejezca.
			## Vive en `ProgresoJugador` (cantera_progreso.gd), con la semanal.
			ProgresoJugador.anual(j)
			## EL RETIRO POR LESIONES. `Medico.retiro_forzado()` estaba escrita y no
			## la llamaba nadie: tres lesiones graves seguidas no acababan con la
			## carrera de nadie, que es justo el peor final que puede tener un
			## futbolista y el que hace que cuidar el fisico importe.
			if c.id == mi_club_id and medico != null and medico.retiro_forzado(j):
				if cantera != null:
					cantera.registrar_retiro(j, c)
				if prensa != null:
					prensa.noticia.emit("Se retira por lesiones: %s" % j.nombre,
						"Los médicos no le dan el alta competitiva. %d años y tres lesiones graves en poco tiempo: cuelga las botas antes de tiempo." % j.edad)
				continue
			if j.edad >= 38 or (j.edad >= 35 and Azar.suerte(0.4)):
				if cantera != null:
					cantera.registrar_retiro(j, c)
				continue   ## se retira
			if _vence_contrato(j, c):
				continue   ## se va libre
			siguen.append(j)
		c.plantilla = siguen
		_subir_de_cantera(c)
		_repartir_dorsales(c)
	for l in ligas:
		l.preparar()
	## La camada nueva: DESPUES de los retiros (para que registren su leyenda
	## antes de que alguien pueda ser su hijo) y de la reposicion automatica
	## (para que un canterano de la camada no le robe el hueco a la reposicion
	## por puesto de _subir_de_cantera()).
	if cantera != null:
		cantera.camada_anual()
		cantera.chequeo_promesas()
	## Los de la academia que cumplen 16 suben DESPUÉS de la camada: son los
	## tuyos de verdad, y si no hay ficha se quedan un año más (ver `Academia`).
	if academia != null:
		academia.fin_de_temporada()
	## LAS JOYAS DE LAS ACADEMIAS, una por sede. Van DESPUES de la camada porque
	## comparten el tope de plantilla: la joya que se paga todo el ano no puede
	## quedarse fuera por un canterano de relleno que subio antes.
	if ojeadores != null and mi_club() != null:
		for joya in ojeadores.joyas_de_academia(mi_club()):
			mi_club().plantilla.append(joya)
	## Los cedidos vuelven a casa: sin esto, aceptar una cesion regalaba al
	## canterano para siempre aunque el texto prometiera que volvia.
	## Las cesiones las resuelve `Cesiones`, que es quien sabe si habia opcion de
	## compra. `prensa.volver_de_cesion` se queda sin usar a proposito: tenia el
	## mismo fallo que el HTML, devolver a todos a casa antes de mirar la opcion.
	if cesiones != null:
		cesiones.resolver(anio)
		cesiones.cobrar_plusvalias(anio)
	if vestuario != null:
		vestuario.nueva_temporada()
	## La campaña de abonos: se lanza sola al empezar la temporada, con el plan
	## que tengas elegido. Es un ingreso grande y de una vez -ocho partidos
	## cobrados por adelantado- y por eso elegir plan importa.
	if hinchada != null and mi_club() != null:
		var trofeos_hasta_hoy := roles.trofeos.size() if roles != null else 0
		resumen["abonos"] = hinchada.campana_abonos(mi_club(),
			prensa.animo if prensa != null else 60, trofeos_hasta_hoy)
	## EL MERCADO DE AUSPICIOS SE ABRE EN PRETEMPORADA: tres marcas sobre la
	## mesa. Va DESPUES de los ascensos y descensos porque la oferta depende de
	## la division en la que vas a jugar, no de la que acabas de dejar.
	if copa != null and copa.campeon != null:
		_campeon_copa_pasado = copa.campeon
	if comercial != null and mi_club() != null:
		comercial.cierre_de_temporada(mi_club())
	## La subvencion municipal se cobra al cerrar el ano: sale de lo que el club
	## le devuelve al barrio, no de lo que gana en la cancha.
	if ciudad != null and mi_club() != null:
		ciudad.cobrar_subvencion(mi_club())
	## EL FAIR PLAY FINANCIERO mira las cuentas del ano. Se usa el MISMO
	## porcentaje que ya enseña la proyeccion anual en pantalla: si aqui se
	## calculara aparte, el jugador veria un numero y la federacion juzgaria otro.
	if federacion != null and federacion.fpf_activo and mi_club() != null:
		var f_fpf := Finanzas.new(mi_club(), 0.0, 0, 0.0)
		f_fpf.aplica_operacion = true
		f_fpf.factor_operacion = obras.abarata_operacion() if obras != null else 1.0
		var proy := f_fpf.proyeccion_anual(15, ingreso_tienda(mi_club()))
		resumen["fpf"] = federacion.revisar_fair_play(mi_club(), int(proy["pct_salarial"]))
	if auspicio != null and mi_club() != null:
		auspicio.generar_ofertas(mi_club(),
			directiva != null and directiva.tiene_consejero("mkt"),
			roles.multiplicador_sponsor() if roles != null else 1.0)
	if entrenamiento != null:
		entrenamiento.reiniciar_pretemporada()
		entrenamiento.reiniciar_subidas()
	## La copa nacional se sortea de cero cada temporada, con los clubes de
	## primera del pais donde diriges.
	## LA SUPERCOPA abre el ano: campeon de liga contra campeon de copa. Va aqui
	## y no en el cierre porque es el PRIMER titulo de la temporada nueva, no el
	## ultimo de la vieja.
	var sc := jugar_supercopa()
	if not sc.is_empty():
		resumen["supercopa"] = sc
	## Y se reabre la pretemporada: hay una por ano.
	amistoso_hecho = false
	_montar_copa()
	## Y los torneos continentales, con las plazas ya puestas al dia por los
	## ascensos/descensos y reputaciones de la temporada que se acaba de cerrar.
	## Antes esto solo se hacia una vez, al tomar el mando: pasada la primera
	## temporada, Champions/Libertadores se quedaban congeladas para siempre con
	## el mismo cuadro y el mismo campeon.
	_sortear_continentales()
	## Trotamundos: a las dos temporadas en el mismo club, toca hacer las
	## maletas. Reutiliza el mismo mecanismo que un despido de verdad
	## -`despedido_ya`- porque es exactamente el mismo destino: la interfaz ya
	## sabe leerlo y ya deja elegir otro club desde el selector de arriba.
	if tiene_desafio("trotamundos") and directiva != null and not directiva.despedido_ya:
		anios_en_club += 1
		if anios_en_club >= 2:
			anios_en_club = 0
			directiva.despedido_ya = true
			resumen["trotamundos"] = true
	return resumen

## El perfil del estadio que va al visor 3D.
##
## Si el club es el TUYO, manda lo que hayas diseñado en `EstadioPropio`; para
## cualquier otro, sale del hash de su id como siempre. Es la misma regla del
## HTML: tu recinto lo construyes, el del rival te lo encuentras.
func perfil_estadio_de(c: Club) -> Dictionary:
	if c != null and c.id == mi_club_id and estadio != null:
		estadio.asegurar_real(c)
		var p := estadio.perfil(c, obras)
		## Lo que el 3D necesita de las instalaciones: obras en curso (andamios
		## y grúa) y lo construido (palcos, prensa, museo, tienda).
		if obras != null:
			p["en_obra"] = obras.obras.keys()
			p["inst"] = obras.niveles.duplicate()
		## La reforma del diseñador en obras: andamios hasta que termine.
		if estadio.en_obras():
			var eo: Array = p.get("en_obra", [])
			p["en_obra"] = eo + ["reforma"]
		return p
	return c.perfil_estadio() if c != null else {}

func estacion() -> Array:
	var s := float((semana - 1) % 42) / 42.0
	if s < 0.25:
		return ESTACIONES[0]
	if s < 0.5:
		return ESTACIONES[1]
	if s < 0.75:
		return ESTACIONES[2]
	return ESTACIONES[3]

## El clima de la semana. Sale de un HASH del año y la semana, no de un sorteo:
## así la misma partida da siempre el mismo tiempo y se puede reproducir. Y la
## bolsa depende de la estación, que es lo que hace que un invierno se note.
func clima() -> String:
	var est := String(estacion()[0])
	var bolsa: Array = ["despejado", "nublado", "viento", "lluvia", "despejado", "despejado", "nublado", "calor"]
	match est:
		"invierno":
			bolsa = ["lluvia", "lluvia", "tormenta", "frío", "frío", "niebla", "nublado", "despejado"]
		"verano":
			bolsa = ["despejado", "despejado", "calor", "calor", "nublado", "viento", "despejado", "lluvia"]
		"otoño":
			bolsa = ["nublado", "lluvia", "viento", "despejado", "niebla", "lluvia", "nublado", "tormenta"]
	var h := 0
	var clave := "cl%d-%d" % [anio, semana]
	for i in clave.length():
		h = (h * 31 + clave.unicode_at(i)) & 0x7FFFFFFF
	return String(bolsa[h % bolsa.size()])

func campana_lanzada_este_anio() -> bool:
	return not campana.is_empty() and int(campana.get("anio", 0)) == anio

## Lanza una campaña. Devuelve "" si se hizo, o el motivo por el que no.
func lanzar_campana(clave: String) -> String:
	var c := mi_club()
	if c == null:
		return "no hay club"
	if campana_lanzada_este_anio():
		return "ya lanzaste una campaña esta temporada"
	var d := Finanzas.def_campana(clave)
	if d.is_empty():
		return "esa campaña no existe"
	var coste := Eco.escalar(float(d[3]), float(c.rep))
	if c.saldo < coste:
		return "cuesta %s y no hay caja" % Cesiones.dinero(coste)
	c.mover_saldo(-coste)
	_anotar_movimiento("Campaña: %s" % String(d[1]), -coste)
	campana = {"anio": anio, "clave": clave}
	var efectos: Dictionary = d[4]
	if efectos.has("socios"):
		c.socios += int(round(float(c.socios) * float(efectos["socios"])))
	if efectos.has("animo") and prensa != null:
		prensa.mover_animo(int(efectos["animo"]))
	if efectos.has("seguidores") and prensa != null:
		prensa.seguidores += int(round(float(prensa.seguidores) * float(efectos["seguidores"])))
	return ""

## LA GUERRA DE MARCAS: ir a por el patrocinador de tu mayor rival.
##
## Es la jugada más sucia que permite el juego y por eso tiene su precio: si
## sale, firmas mejor y a ellos les duele; si falla, pierdes el dinero y se
## enteran igual. El palco sube las opciones, porque es donde se cierran estas
## cosas —el HTML lo dice con esas palabras—.
func rival_de_marcas() -> Club:
	if logros == null:
		return null
	var lista := logros.rivalidades()
	if lista.is_empty():
		return null
	return (lista[0] as Dictionary)["club"] as Club

func coste_guerra_marcas() -> int:
	var c := mi_club()
	if c == null:
		return 0
	var rival := rival_de_marcas()
	var calor := logros.rivalidad_con(rival) if (rival != null and logros != null) else 0
	return Eco.escalar(180000.0 * (1.0 + float(calor) / 100.0), float(c.rep))

func probabilidad_guerra_marcas() -> float:
	var c := mi_club()
	var rival := rival_de_marcas()
	if c == null or rival == null:
		return 0.0
	var palco := club_dentro.bono_palco() if club_dentro != null else 0
	return clampf(0.35 + float(c.rep - rival.rep) * 0.02 + float(palco) / 50.0, 0.1, 0.9)

func pujar_por_marca() -> String:
	var c := mi_club()
	var rival := rival_de_marcas()
	if c == null or rival == null:
		return "no tienes todavía un rival al que quitarle nada"
	var coste := coste_guerra_marcas()
	if c.saldo < coste:
		return "la operación cuesta %s y no hay caja" % Cesiones.dinero(coste)
	c.mover_saldo(-coste)
	_anotar_movimiento("Operación por el patrocinador de %s" % rival.nombre, -coste)
	if not Azar.suerte(probabilidad_guerra_marcas()):
		if prensa != null:
			prensa.publicar("Intentaron quitarnos el patrocinador y se estrellaron.", "troll", 1.6)
		return "Salió mal. Perdiste el dinero y en %s se enteraron igual." % rival.nombre
	## El premio: un ingreso de golpe y una publicación que lo cuenta. El
	## patrocinio recurrente ya lo calcula `Finanzas.patrocinio()` a partir de la
	## reputación, así que no hace falta otro contador que mantener.
	var premio := Eco.escalar(420000.0, float(c.rep))
	c.mover_saldo(premio)
	_anotar_movimiento("Nuevo patrocinador principal", premio)
	if prensa != null:
		prensa.publicar("Les hemos quitado el patrocinador. Hoy se duerme bien.", "hincha", 2.4)
		prensa.mover_animo(6)
	return "Salió. Firmas con su patrocinador y en %s les ha dolido de verdad." % rival.nombre

func mercado_abierto() -> bool:
	return semana <= VENTANA_VERANO \
		or (semana >= VENTANA_INVIERNO_INI and semana <= VENTANA_INVIERNO_FIN)

## Cuántas semanas quedan para que cierre. Cero si está cerrado.
func semanas_de_mercado() -> int:
	if semana <= VENTANA_VERANO:
		return VENTANA_VERANO - semana + 1
	if semana >= VENTANA_INVIERNO_INI and semana <= VENTANA_INVIERNO_FIN:
		return VENTANA_INVIERNO_FIN - semana + 1
	return 0

## Cuándo vuelve a abrir, para poder decirlo en vez de un "está cerrado" seco.
func semanas_hasta_mercado() -> int:
	if mercado_abierto():
		return 0
	if semana < VENTANA_INVIERNO_INI:
		return VENTANA_INVIERNO_INI - semana
	## Pasada la de invierno, la siguiente es la del año que viene.
	## Pasada la de invierno, la siguiente es la del año que viene: se cuenta
	## contra las jornadas que le quedan a tu liga, que es lo que de verdad marca
	## cuando se acaba la temporada aqui.
	var l := liga_de(mi_club())
	var quedan := (l.jornadas() - l.jornada_actual) if l != null else 8
	return maxi(1, quedan + VENTANA_VERANO)

func texto_de_mercado() -> String:
	if mercado_abierto():
		var q := semanas_de_mercado()
		if q <= 2:
			return "Mercado abierto: cierra en %d semana%s. Últimos días." % [q, "" if q == 1 else "s"]
		return "Mercado abierto: quedan %d semanas." % q
	return "Mercado cerrado. Vuelve a abrir en %d semanas." % semanas_hasta_mercado()

func def_amistoso(clave: String) -> Array:
	for f: Array in AMISTOSOS:
		if String(f[0]) == clave:
			return f
	return []

## Juega la pretemporada elegida. Devuelve "" si se hizo, o el motivo.
func jugar_amistosos(clave: String) -> String:
	if amistoso_hecho:
		return "la pretemporada ya está jugada"
	var d := def_amistoso(clave)
	if d.is_empty():
		return "esa pretemporada no existe"
	var mio := mi_club()
	if mio == null:
		return "no hay club"
	var coste := Eco.escalar(float(d[2]), float(mio.rep)) if float(d[2]) > 0.0 else 0
	if coste > mio.saldo:
		return "la gira cuesta %s y no hay caja" % Cesiones.dinero(coste)
	if coste > 0:
		mio.mover_saldo(-coste)
		_anotar_movimiento("Pretemporada: %s" % String(d[1]), -coste)
	amistoso_hecho = true
	var gana: int = d[3]
	for j in mio.plantilla:
		j.forma = clampi(j.forma + gana, 20, 99)
	## La gira internacional además vende camisetas y trae socios: es cara y se
	## paga sola si el club es grande.
	if clave == "gira":
		var ingreso := Eco.escalar(180000.0, float(mio.rep))
		mio.mover_saldo(ingreso)
		_anotar_movimiento("Taquilla y merchandising de la gira", ingreso)
		mio.socios += Azar.ent(300, 900)
	## Y la de cantera le da minutos a los chicos, que es lo que de verdad los
	## hace crecer: sube la forma de los sub-21 el doble.
	if clave == "cantera":
		for j2 in mio.plantilla:
			if j2.edad <= 21:
				j2.forma = clampi(j2.forma + gana, 20, 99)
	if prensa != null:
		prensa.noticia.emit("Pretemporada: %s" % String(d[1]),
			"El plantel llega a la primera jornada con %d de forma extra." % gana)
	return ""

# ---------------------------------------------------------------------------
#  EL INFORME DE GESTIÓN
# ---------------------------------------------------------------------------
#
# «Resumen semanal tipo informe de gestión» (idea 245). Es una pantalla que no
# añade ninguna mecánica: junta en un sitio las seis cosas que hay que mirar
# cada lunes y que hoy están repartidas por ocho pestañas.
#
# POR QUÉ HACE FALTA. Este juego tiene dieciocho pestañas. Un jugador nuevo no
# sabe cuáles mirar y uno veterano se olvida de una. El informe no decide nada:
# dice qué está mal esta semana y a qué pestaña ir.

func informe_de_gestion() -> Array[Dictionary]:
	var salida: Array[Dictionary] = []
	var mio := mi_club()
	if mio == null:
		return salida

	## 1. La caja, que es lo único que puede acabar la partida sin jugar.
	var caja_ref := Eco.ref_caja(float(mio.rep))
	if mio.saldo < 0:
		salida.append({"grave": true, "txt": "La caja está en rojo (%s). Cada semana así cuesta intereses." % Cesiones.dinero(mio.saldo), "tab": "Finanzas"})
	elif float(mio.saldo) < caja_ref * 0.25:
		salida.append({"grave": false, "txt": "La caja está justa: %s. Cuidado con el próximo fichaje." % Cesiones.dinero(mio.saldo), "tab": "Finanzas"})

	## 2. Quién no puede jugar el domingo.
	var fuera := 0
	for j: Jugador in mio.plantilla:
		if j.lesion > 0 or j.suspension > 0:
			fuera += 1
	if fuera > 0:
		salida.append({"grave": fuera >= 4, "txt": "%d jugador%s no está%s disponible%s." % [
			fuera, "es" if fuera > 1 else "", "n" if fuera > 1 else "", "s" if fuera > 1 else ""], "tab": "Enfermería"})

	## 3. Los contratos que se acaban: es el aviso que más caro sale ignorar.
	var acaban := 0
	for j2: Jugador in mio.plantilla:
		if j2.anios_contrato <= 1:
			acaban += 1
	if acaban > 0:
		salida.append({"grave": acaban >= 4, "txt": "%d contrato%s termina%s este año. Sin renovar, se van gratis." % [
			acaban, "s" if acaban > 1 else "", "n" if acaban > 1 else ""], "tab": "Contratos"})

	## 4. El vestuario.
	var descontentos := 0
	for j3: Jugador in mio.plantilla:
		if j3.moral < 40 or j3.pide_salir:
			descontentos += 1
	if descontentos > 0:
		salida.append({"grave": descontentos >= 5, "txt": "%d jugador%s con la moral por los suelos o pidiendo salir." % [
			descontentos, "es" if descontentos > 1 else ""], "tab": "Camarín"})

	## 5. La calle y el despacho.
	if prensa != null and prensa.funa >= 55:
		salida.append({"grave": prensa.funa >= 75, "txt": "El ruido en redes está en %d. La directiva lo lee." % prensa.funa, "tab": "Redes"})
	if directiva != null and directiva.confianza < 40:
		salida.append({"grave": directiva.confianza < 25, "txt": "La confianza del directorio está en %d. Estás en la cuerda floja." % directiva.confianza, "tab": "Club"})

	## 6. Lo que se puede hacer y no se está haciendo.
	if mercado_abierto() and semanas_de_mercado() <= 2:
		salida.append({"grave": false, "txt": "El mercado cierra en %d semana(s)." % semanas_de_mercado(), "tab": "Mercado"})
	if entrenamiento != null and entrenamiento.dt_puntos > 0:
		salida.append({"grave": false, "txt": "Tienes %d punto(s) de entrenador sin gastar." % entrenamiento.dt_puntos, "tab": "Legado"})
	if not amistoso_hecho and semana <= 3:
		salida.append({"grave": false, "txt": "Todavía no has jugado la pretemporada: el plantel llega frío.", "tab": "Entrenar"})
	if auspicio != null and auspicio.contrato.is_empty() and not auspicio.ofertas.is_empty():
		salida.append({"grave": false, "txt": "Hay %d marcas esperando respuesta por la camiseta." % auspicio.ofertas.size(), "tab": "Finanzas"})

	if salida.is_empty():
		salida.append({"grave": false, "txt": "Todo en orden: sin lesionados largos, sin contratos en el aire y con la caja sana.", "tab": ""})
	return salida
## LA IA RENUEVA UN AÑO ANTES (25-10; antes solo a cero y por 1-3: 60% del mundo en su último año). Tu club no cambia.
func _vence_contrato(j: Jugador, c: Club) -> bool:
	var h := absi(hash("%s|%d|anticipada" % [j.id, anio]))
	if c.id != mi_club_id and j.anios_contrato == 2 and float(h % 1000) / 1000.0 < (0.35 if j.edad >= 32 else 0.8):
		j.anios_contrato = Contratos.ajustar_anios(j, 1 + (h / 1000) % 2 if j.edad >= 32 else 2 + (h / 1000) % 3)
		return false
	var antes := j.anios_contrato
	var se_va := super(j, c)
	if not se_va and antes == 1 and c.id != mi_club_id and j.edad < 32:
		j.anios_contrato = maxi(j.anios_contrato, 2)   ## la renovación a cero tampoco vuelve al último año
	return se_va
