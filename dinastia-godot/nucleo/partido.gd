class_name Partido
extends "res://nucleo/partido_p2.gd"
## [Capa 3/3 de `partido.gd`] simular_minuto, _por_id, gol_externo, anular_gol_externo, remate_externo, tarjeta_externa … (+14)

func simular_minuto() -> void:
	if terminado_ya:
		return
	## LA INVASIÓN, DENTRO DEL MINUTO (25-9-2026, plan maestro B2). Antes solo
	## la miraba `PartidoVivo` desde su reloj: jugado en 3D o simulado, esa
	## tirada de `Azar` no ocurría y el mismo partido podía terminar distinto
	## según cómo se mirara. Ahora es parte del minuto para cualquier vista; cada
	## una solo decide cómo contarla (`invasion_de_campo`).
	if _hinchada_club != null and not invasion_ya:
		var soy_local := local == _hinchada_club
		var mis_goles: int = goles_local if soy_local else goles_visita
		var sus_goles: int = goles_visita if soy_local else goles_local
		if chequear_invasion(_hinchada_animo, soy_local, mis_goles < sus_goles):
			invasion_de_campo.emit(minuto)
	minuto += 1
	## LOS PLANES SEGÚN EL MARCADOR. A partir del minuto 60 el entrenador aplica
	## lo que dejó preparado: ir a por el partido si va perdiendo, cerrarlo si va
	## ganando. Va en el 60 y no antes porque cambiar el plan en el 20 no es un
	## plan, es nerviosismo. Y solo se aplica UNA VEZ -`_plan_aplicado`- o cada
	## minuto se estaría reescribiendo la táctica sobre sí misma.
	if minuto == 60 and not _plan_aplicado:
		_plan_aplicado = true
		_aplicar_plan()
	var fl := _fza_local
	var fv := _fza_visita
	## Sin empuje de local en cancha neutral: es lo que hace que una final en
	## campo neutro se sienta distinta de una en casa.
	var bono_l := 1.0 if neutral else 1.08
	var bono_v := 1.0 if neutral else 0.94

	var p_l := _probabilidad(fl["ata"], fv["def"]) * bono_l * clima
	var p_v := _probabilidad(fv["ata"], fl["def"]) * bono_v * clima * _f_clima_visita
	## Las instrucciones efímeras solo pegan de TU lado: "riesgo" (todo al
	## ataque) sube tu llegada un 18% y baja tu defensa un 16%; "tiempo"
	## (cerrar el partido) hace justo lo contrario -0.72/1.12-, los mismos
	## factores que `mAtk`/`mDef` en `simularMinuto()` del HTML.
	if instr_riesgo or instr_tiempo:
		var mult_ataque := (1.18 if instr_riesgo else 1.0) * (0.72 if instr_tiempo else 1.0)
		var mult_defensa := (0.84 if instr_riesgo else 1.0) * (1.12 if instr_tiempo else 1.0)
		if local.id == ctx_club_id:
			p_l *= mult_ataque
			p_v /= max(mult_defensa, 0.4)
		elif visita.id == ctx_club_id:
			p_v *= mult_ataque
			p_l /= max(mult_defensa, 0.4)

	## EL CÉSPED. Mismo lado que las instrucciones de arriba -solo pega en TU
	## partido, y solo cuando juegas de local: es tu pasto el que se rompe-.
	if local.id == ctx_club_id and ctx_cesped_local < 1.0:
		p_l *= ctx_cesped_local

	## La posesión no es un dato que el motor lleve: se DEDUCE de quién está
	## llegando más, con la misma media móvil del HTML -6% por minuto, para que
	## no salte de un lado al otro- y sus mismos topes (22-78: ningún partido
	## real acaba 95-5). El ritmo bajo suma porque jugar lento es tener la
	## pelota, que es justo lo que dice `ritmo===0?1.06:1` allá.
	var dominio := p_l / maxf(p_l + p_v, 0.0001)
	var empuje := 1.06 if local.tactica.ritmo == 0 else 1.0
	posesion_local = clampf(posesion_local * 0.94 + dominio * 100.0 * empuje * 0.06, 22.0, 78.0)
	## Córners, faltas y fueras de juego con las probabilidades por minuto del
	## HTML, tal cual. El local saca algún córner más y comete alguna falta
	## menos: no es simetría rota, es la ventaja de campo contada en detalle.
	if Azar.suerte(0.10):
		corners_local += 1
	if Azar.suerte(0.09):
		corners_visita += 1
	if Azar.suerte(0.16):
		faltas_local += 1
	if Azar.suerte(0.17):
		faltas_visita += 1
	if Azar.suerte(0.05):
		fueras_local += 1
	if Azar.suerte(0.05):
		fueras_visita += 1

	if not motor_externo:
		if Azar.suerte(p_l):
			_atacar(local, once_local, true)
		if Azar.suerte(p_v):
			_atacar(visita, once_visita, false)

	_incidencias()
	minuto_jugado.emit(minuto)
	if minuto >= minutos_fin:
		terminado_ya = true
		terminado.emit(goles_local, goles_visita)

# ---------------------------------------------------------------------------
#  LO QUE MANDA EL MOTOR REAL
# ---------------------------------------------------------------------------

func _por_id(id: String) -> Jugador:
	for j in once_local:
		if j.id == id:
			return j
	for j in once_visita:
		if j.id == id:
			return j
	for j in _todos:
		if j.id == id:
			return j
	return null

## Un gol que pasó en el césped. `autor_id` vacío = en propia puerta.
func gol_externo(es_local: bool, autor_id: String, asist_id: String) -> void:
	if terminado_ya:
		return
	var c := local if es_local else visita
	var autor := _por_id(autor_id) if autor_id != "" else null
	var asistente := _por_id(asist_id) if asist_id != "" else null
	if es_local:
		goles_local += 1
		remates_local += 1
		tiros_puerta_local += 1
		xg_local += 0.3
	else:
		goles_visita += 1
		remates_visita += 1
		tiros_puerta_visita += 1
		xg_visita += 0.3
	peor_diferencia_local = mini(peor_diferencia_local, goles_local - goles_visita)
	peor_diferencia_visita = mini(peor_diferencia_visita, goles_visita - goles_local)
	if autor != null:
		autor.anotar()
		_notas[autor.id] = minf(float(_notas.get(autor.id, 6.0)) + 1.1, 10.0)
	cronica.append({"min": minuto, "tipo": "gol", "club": c.id, "autor": autor.nombre if autor else "en propia puerta"})
	_momentum_push(2, es_local)
	gol.emit(c, autor, minuto, asistente)

## EL VAR ANULA (17-10-2026): deshace el último gol de ese equipo (marcador,
## goles del autor, nota y crónica, que lo deja como "gol_anulado").
func anular_gol_externo(es_local: bool, autor_id: String) -> void:
	if terminado_ya:
		return
	var c := local if es_local else visita
	if es_local:
		if goles_local <= 0:
			return
		goles_local -= 1
	else:
		if goles_visita <= 0:
			return
		goles_visita -= 1
	var autor := _por_id(autor_id) if autor_id != "" else null
	if autor != null:
		autor.goles = maxi(autor.goles - 1, 0)
		_notas[autor.id] = maxf(float(_notas.get(autor.id, 6.0)) - 1.1, 1.0)
	for i in range(cronica.size() - 1, -1, -1):
		var e: Dictionary = cronica[i]
		if String(e.get("tipo", "")) == "gol" and String(e.get("club", "")) == c.id:
			e["tipo"] = "gol_anulado"
			break
	_momentum_push(1, not es_local)

## Un remate que no fue gol: "atajada", "poste" o "fallo".
func remate_externo(es_local: bool, autor_id: String, tipo: String) -> void:
	if terminado_ya:
		return
	var c := local if es_local else visita
	if es_local:
		remates_local += 1
		xg_local += 0.09
		if tipo == "atajada":
			tiros_puerta_local += 1
	else:
		remates_visita += 1
		xg_visita += 0.09
		if tipo == "atajada":
			tiros_puerta_visita += 1
	_momentum_push(1, es_local)
	remate.emit(c, _por_id(autor_id), tipo, minuto)

## Una tarjeta que sacó el árbitro del 3D. La roja deja al equipo con uno menos
## también aquí (sale del once: la fuerza se vuelve a medir).
func tarjeta_externa(jugador_id: String, roja: bool) -> void:
	var j := _por_id(jugador_id)
	if j == null:
		return
	j.amarillas += 1
	if roja:
		j.suspension = maxi(j.suspension, 1)
		once_local.erase(j)
		once_visita.erase(j)
		invalidar_fuerza()
	tarjeta.emit(j, roja, minuto)

## Posesión, córners y faltas medidos en el césped.
func fijar_estadisticas(pos_local: float, corners: Array, faltas_: Array, fueras_: Array = []) -> void:
	posesion_local = clampf(pos_local, 0.0, 100.0)
	corners_local = int(corners[0])
	corners_visita = int(corners[1])
	faltas_local = int(faltas_[0])
	faltas_visita = int(faltas_[1])
	## Los fueras de juego del césped (20-10-2026): antes el resumen mostraba
	## los que sorteaba la simulación, no los que pitó el árbitro del 3D.
	if fueras_.size() == 2:
		fueras_local = int(fueras_[0])
		fueras_visita = int(fueras_[1])

## Mete a `entra` por `sale`. Devuelve por qué no se pudo, o cadena vacía si se
## hizo: quien llama necesita poder decírselo al jugador, no adivinarlo.
##
## Después de tocar el once hay que volver a medirlo. La fuerza está cacheada
## porque no cambia durante los noventa minutos, y un cambio es justo la
## excepción: sin `invalidar_fuerza()` el equipo seguiría jugando con la fuerza
## del once que ya no está en el campo, y el cambio no serviría para nada.
func cambiar(sale: Jugador, entra: Jugador) -> String:
	var es_local := once_local.has(sale)
	if not es_local and not once_visita.has(sale):
		return "%s no está en el campo" % sale.nombre
	var hechos := cambios_local if es_local else cambios_visita
	if hechos >= MAX_CAMBIOS + cambios_extra:
		return "ya no quedan cambios"
	if not entra.disponible():
		return "%s no está en condiciones de entrar" % entra.nombre
	if once_local.has(entra) or once_visita.has(entra):
		return "%s ya está jugando" % entra.nombre
	var once := once_local if es_local else once_visita
	once[once.find(sale)] = entra
	if es_local:
		cambios_local += 1
	else:
		cambios_visita += 1
	_todos.append(entra)
	invalidar_fuerza()
	cronica.append({"min": minuto, "tipo": "cambio", "sale": sale.nombre, "entra": entra.nombre})
	cambio_hecho.emit(sale, entra, minuto)
	return ""

## La tanda que se jugó en el 3D. Va ANTES del pitido final del acta: quien
## escuche `terminado` y pida `penales()` recibe la del césped.
func penales_externos(l: int, v: int) -> void:
	_penales = [l, v]
	penales_en_cesped = true
	cronica.append({"min": minuto, "tipo": "penales", "local": l, "visita": v})

## El motor real decidió ir a la prórroga: el acta sigue hasta el 120'.
func prorroga_externa() -> void:
	if terminado_ya or minutos_fin > MINUTOS:
		return
	minutos_fin = MINUTOS + 30
	cambios_extra = 1
	cronica.append({"min": minuto, "tipo": "prorroga"})

func penales() -> Array:
	if not _penales.is_empty():
		return _penales
	var l := 0
	var v := 0
	for i in 5:
		if Azar.suerte(0.76): l += 1
		if Azar.suerte(0.76): v += 1
	while l == v:
		if Azar.suerte(0.76): l += 1
		if Azar.suerte(0.76): v += 1
	cronica.append({"min": minuto, "tipo": "penales", "local": l, "visita": v})
	_penales = [l, v]
	return _penales

## Cierra las notas del partido y actualiza la forma.
##
## Portado del HTML: la nota base se mueve con el resultado del EQUIPO (+0,6 si
## ganas, -0,6 si pierdes) mas un margen de azar, y despues la forma se arrastra
## hacia esa nota con un 30% de peso. Eso es lo que hace que una racha se note en
## la forma sin que un solo partido malo hunda a nadie.
##
## Se llama al terminar, no minuto a minuto: una nota a mitad de partido no
## significa nada y ademas el resultado todavia no se sabe.
func _cerrar_notas() -> void:
	_notas_cerradas = true
	var gano_local := goles_local > goles_visita
	var empate := goles_local == goles_visita
	for j in _todos:
		var suyo := once_local.has(j)
		var bono := 0.0
		if not empate:
			bono = 0.6 if (gano_local == suyo) else -0.6
		var n: float = clampf(float(_notas.get(j.id, 6.0)) + bono + Azar.f() * 1.4 - 0.7, 3.0, 10.0)
		n = round(n * 10.0) / 10.0
		j.anotar_nota(n)
		j.forma = clampi(int(round(float(j.forma) * 0.7 + n * 10.0 * 0.3)), 20, 99)
		j.partidos += 1

func guardar_si_es_mio() -> void:
	if local == null or visita == null:
		return
	if local.id != ctx_club_id and visita.id != ctx_club_id:
		return
	ultimo_mio = {"local": local.nombre, "visita": visita.nombre, "local_id": local.id,
		"gl": goles_local, "gv": goles_visita, "cronica": cronica.duplicate(true),
		"anio": ctx_anio, "semana": ctx_semana}

## Juega el partido entero de una vez. Es lo que usa la simulacion de temporadas
## y el banco de pruebas; en pantalla se llama a simular_minuto() con un reloj.
func simular() -> Dictionary:
	preparar()
	while not terminado_ya:
		simular_minuto()
	_cerrar_notas()
	guardar_si_es_mio()
	return {"local": goles_local, "visita": goles_visita}

func _to_string() -> String:
	return "%s %d-%d %s" % [local.nombre, goles_local, goles_visita, visita.nombre]

## ¿Ganó `c` este partido después de haber estado tres goles abajo o más en
## algún momento? El logro oculto "remontada" (`Logros.marcar()`), que la
## propia tabla del HTML prometía -"Ganar un partido yendo tres goles
## abajo"- sin que nada en `juego.js` lo activara jamás: bug del original, no
## del porte, y se cierra aquí en vez de dejarlo matemáticamente imposible.
func hubo_remontada_de(c: Club) -> bool:
	if c == local:
		return goles_local > goles_visita and peor_diferencia_local <= -3
	if c == visita:
		return goles_visita > goles_local and peor_diferencia_visita <= -3
	return false

func cerrar_notas_mirado() -> void:
	if _notas_cerradas or not terminado_ya:
		return
	_notas_cerradas = true
	for v: Dictionary in valoraciones():
		var j: Jugador = v["jugador"]
		var n := float(v["nota"])
		j.anotar_nota(n)
		j.forma = clampi(int(round(float(j.forma) * 0.7 + n * 10.0 * 0.3)), 20, 99)
		j.partidos += 1

## La nota de un jugador en este partido, para poder pintarla en directo.
func nota_de(j: Jugador) -> float:
	return float(_notas.get(j.id, 6.0))

static func marcar_ex(j: Jugador, club_id: String) -> void:
	if j == null or club_id == "":
		return
	ex_de_mi_club[j.id] = club_id

func fijar_hinchada(club: Club, animo: int) -> void:
	_hinchada_club = club
	_hinchada_animo = animo
