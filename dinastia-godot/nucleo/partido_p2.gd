extends "res://nucleo/partido_p1.gd"
## [Capa 2/3 de `partido.gd`] _aporte_tarjeta, _init, valoraciones, mejor_del_partido, preparar, chequear_invasion … (+10)

func _aporte_tarjeta(j: Jugador, roja: bool, _m: int) -> void:
	_aporte(j, -1.4 if roja else -0.35)

func _init(_local: Club, _visita: Club, _neutral: bool = false) -> void:
	local = _local
	visita = _visita
	neutral = _neutral
	gol.connect(_aporte_gol)
	remate.connect(_aporte_remate)
	tarjeta.connect(_aporte_tarjeta)

## LAS VALORACIONES DEL PARTIDO (M-141): la nota de cada uno de los que
## jugaron, como en los diarios, de mejor a peor:
##   [{jugador, nota, local, titular}]
## La base es la nota del partido (6 + goles), más lo apuntado en `_aportes`,
## el resultado del equipo (+0,4 / −0,3), la portería a cero o los goles encajados
## (porteros y defensas) y un poco de la calidad del jugador. Los que entraron
## de cambio se mueven menos (jugaron menos). Determinista, sin `Azar`: se
## puede pedir las veces que haga falta y no cambia nada del partido.
func valoraciones() -> Array:
	var r: Array = []
	var empate := goles_local == goles_visita
	for j in _todos:
		var es_local := local.plantilla.has(j)
		var n := float(_notas.get(j.id, 6.0)) + float(_aportes.get(j.id, 0.0))
		if not empate:
			n += 0.4 if (goles_local > goles_visita) == es_local else -0.3
		var encajados := goles_visita if es_local else goles_local
		if j.pos == "POR" or j.pos == "DEF":
			var k := 1.3 if j.pos == "POR" else 1.0
			n += (0.6 * k) if encajados == 0 else -0.25 * k * float(mini(encajados, 4))
		n += clampf(float(j.ovr - 65) * 0.02, -0.3, 0.3)
		var titular := _titulares.has(j.id)
		if not titular:
			n = 6.0 + (n - 6.0) * 0.75
		n = clampf(round(n * 10.0) / 10.0, 3.0, 10.0)
		r.append({"jugador": j, "nota": n, "local": es_local, "titular": titular})
	r.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		if float(a["nota"]) != float(b["nota"]):
			return float(a["nota"]) > float(b["nota"])
		return int((a["jugador"] as Jugador).ovr) > int((b["jugador"] as Jugador).ovr))
	return r

## El mejor del partido (el primero de `valoraciones()`), o {} si no jugó nadie.
func mejor_del_partido() -> Dictionary:
	var v := valoraciones()
	return v[0] if not v.is_empty() else {}

func preparar() -> void:
	if clima_info.is_empty():
		fijar_clima(Clima.del_partido(local.pais, ctx_semana, ctx_anio, local.id + visita.id))
	once_local = local.once()
	once_visita = visita.once()
	## `Previa.arbitro_de(rival_id, semana)` -la MISMA que ya usa `vPrevia()`
	## para enseñarlo antes del partido-, no una copia: si se recalculara aparte
	## acá, el árbitro que se anuncia en la previa y el que de verdad pita
	## podrían ser dos personas distintas. Cuando el cruce es tuyo, "rival_id"
	## es el otro club -igual que le pasa `principal.gd` a `Previa`-; entre dos
	## clubes de la IA no hay un "rival" con sentido, así que se usa `visita.id`
	## sin más: solo hace falta que sea determinista, no que sea "el tuyo".
	var rival_id := visita.id
	if local.id == ctx_club_id:
		rival_id = visita.id
	elif visita.id == ctx_club_id:
		rival_id = local.id
	arbitro = Previa.arbitro_de(rival_id, ctx_semana)
	goles_local = 0
	goles_visita = 0
	peor_diferencia_local = 0
	peor_diferencia_visita = 0
	remates_local = 0
	remates_visita = 0
	## Las estadisticas tambien se ponen a cero: `preparar()` se puede llamar
	## dos veces sobre el mismo partido -lo hace `simular()` y lo hace cualquier
	## pantalla que lo rearme-, y sin esto la posesion y los corners se irian
	## acumulando de una simulacion a la siguiente.
	posesion_local = 50.0
	tiros_puerta_local = 0
	tiros_puerta_visita = 0
	xg_local = 0.0
	xg_visita = 0.0
	corners_local = 0
	corners_visita = 0
	faltas_local = 0
	faltas_visita = 0
	fueras_local = 0
	fueras_visita = 0
	cambios_local = 0
	cambios_visita = 0
	minuto = 0
	minutos_fin = MINUTOS
	cambios_extra = 0
	terminado_ya = false
	cronica.clear()
	_todos = once_local + once_visita
	_notas_cerradas = false
	_notas.clear()
	_aportes.clear()
	_titulares.clear()
	for j in _todos:
		_notas[j.id] = 6.0
		_titulares[j.id] = true
	invalidar_fuerza()

## Devuelve true si la grada acaba de invadir el campo. Lo mira el partido en
## vivo para parar el reloj y abrir el vestuario.
func chequear_invasion(animo: int, soy_local: bool, voy_perdiendo: bool) -> bool:
	if invasion_ya or terminado_ya:
		return false
	if minuto < MINUTO_INVASION or not soy_local or not voy_perdiendo:
		return false
	if animo > ANIMO_PARA_INVASION:
		return false
	## Una de cada cinco, aun cumpliendo las tres condiciones. Si fuera segura,
	## bastaría con ir perdiendo en casa para saber lo que va a pasar.
	if not Azar.suerte(0.2):
		return false
	invasion_ya = true
	## A los dos equipos se les caen las piernas: el frío de veinte minutos
	## parados con la policía en el campo no distingue de camisetas.
	for j in _todos:
		j.fisico = clampi(j.fisico - Azar.ent(3, 8), 10, 100)
		j.cambiar_moral(-(Azar.ent(2, 6)), "Partido")
	return true

## Aplica el plan que el entrenador dejó preparado para cómo vaya el marcador.
## Solo el club del jugador: los otros 383 ya tienen su propio automático, y
## simular la cabeza de 383 entrenadores sería gastar en algo que nadie ve.
func _aplicar_plan() -> void:
	for c in [local, visita]:
		if c == null or c.tactica == null:
			continue
		var mia: int = goles_local if c == local else goles_visita
		var suya: int = goles_visita if c == local else goles_local
		var cambio: Dictionary = c.tactica.plan_para(mia - suya)
		if cambio.is_empty():
			continue
		c.tactica.mentalidad = int(cambio["mentalidad"])
		c.tactica.linea = int(cambio["linea"])
		## Cambiar la táctica invalida la fuerza cacheada: sin esto el cambio se
		## guardaría pero el partido seguiría midiendo con los números viejos, y
		## el plan sería un adorno. Es la misma razón por la que `cambiar()` la
		## invalida al hacer una sustitución.
		invalidar_fuerza()

func _probabilidad(ata: float, def_rival: float) -> float:
	## REALISMO (13-10-2026): con la fórmula vieja un once de media 86 contra
	## uno de 69 llegaba solo un 17 % más, y los campeones sacaban el 56-64 % de
	## los puntos (en las ligas de verdad, 70-85 %). Ahora cuenta el cociente
	## ataque/defensa con más peso; entre iguales, la misma probabilidad de antes.
	var igual: float = pow(REPARTO / 2.0, EXPONENTE)
	return BASE_ATAQUE * igual * pow(ata / maxf(def_rival, 0.001), SENSIBILIDAD)

func _alguien(l: Array[Jugador]) -> Jugador:
	if l.is_empty():
		return null
	return l[Azar.ent(0, l.size() - 1)]

## Reparte una amarilla arbitral igual que `_incidencias()` reparte las
## normales -segunda amarilla con 18% de ir a la roja-, y la narra con la frase
## que le toca a esta personalidad.
func _tarjeta_arbitral(arr: Array[Jugador], frase: String) -> void:
	var j := _alguien(arr)
	if j == null:
		return
	j.amarillas += 1
	var roja := j.amarillas % 2 == 0 and Azar.suerte(0.18)
	if roja:
		j.suspension = maxi(j.suspension, 1)
	decision_arbitral.emit(frase + j.nombre, minuto)
	tarjeta.emit(j, roja, minuto)

## El goleador no se sortea plano: se pondera por lo cerca del area que juega y
## por su pegada. Si se sortea plano, los centrales marcan tanto como los nueves
## y la tabla de goleadores deja de tener sentido.
func _elegir_goleador(once: Array[Jugador]) -> Jugador:
	if once.is_empty():
		return null
	var pesos: Array[float] = []
	var total := 0.0
	for j in once:
		var base := 0.02
		match Datos.grupo(j.pos_e):
			"DEL": base = 1.0
			"MED": base = 0.42
			"DEF": base = 0.11
			"POR": base = 0.004
		base *= 0.5 + float(j.atributos.get("tir", 50)) / 100.0
		pesos.append(base)
		total += base
	var r := Azar.f() * total
	for i in once.size():
		r -= pesos[i]
		if r <= 0.0:
			return once[i]
	return once[once.size() - 1]

## El asistente (18-9-2026), igual de ponderado que el goleador pero por pase
## en vez de por remate -un mediocampista asiste mucho más que un central-.
## PURAMENTE COSMÉTICO: no toca `goles_local/visita`, no toca notas, no toca
## nada que ya decidiera el resultado del partido (eso ya pasó antes de
## llegar aquí). Solo alimenta la crónica y, vía `gol.emit()`, la
## dramatización 3D (`estadio.gd::_al_gol()` → `MatchPlayback::_jugada_gol()`),
## que hasta esta pieza no tenía forma de saber quién había dado el pase.
##
## NO USA `Azar`: esta es LA MISMA trampa que ya se pagó una vez con un feed
## cosmético y que `Sonido` documenta al elegir variante -si algo cosmético
## consume un número del generador determinista de la partida, todo lo que se
## sortea DESPUÉS (el próximo remate, la próxima tarjeta) sale corrido, y una
## temporada entera deja de ser reproducible por culpa de un dato que nadie
## mira dos veces. Se prueba: sin este cambio, `_probar_partidos()` medía un
## resultado distinto (137 vs 138 locales ganadores) solo por haber agregado
## esta elección -precisamente la prueba que existe para cazarlo-. Una
## semilla propia, derivada del propio gol (autor + minuto), es determinista
## sin tocar el generador compartido.
func _elegir_asistente(once: Array[Jugador], autor: Jugador, minuto: int) -> Jugador:
	var candidatos: Array[Jugador] = []
	for j in once:
		if j != autor:
			candidatos.append(j)
	if candidatos.is_empty():
		return null
	var pesos: Array[float] = []
	var total := 0.0
	for j in candidatos:
		var base := 0.05
		match Datos.grupo(j.pos_e):
			"MED": base = 1.0
			"DEL": base = 0.55
			"DEF": base = 0.22
			"POR": base = 0.02
		base *= 0.5 + float(j.atributos.get("pas", 50)) / 100.0
		pesos.append(base)
		total += base
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(str(autor.id if autor != null else "") + "_" + str(minuto))
	var r := rng.randf() * total
	for i in candidatos.size():
		r -= pesos[i]
		if r <= 0.0:
			return candidatos[i]
	return candidatos[candidatos.size() - 1]

func _anotar(c: Club, once: Array[Jugador], es_local: bool) -> void:
	var autor := _elegir_goleador(once)
	if es_local:
		goles_local += 1
	else:
		goles_visita += 1
	peor_diferencia_local = mini(peor_diferencia_local, goles_local - goles_visita)
	peor_diferencia_visita = mini(peor_diferencia_visita, goles_visita - goles_local)
	if autor != null:
		autor.anotar()
		_notas[autor.id] = minf(float(_notas.get(autor.id, 6.0)) + 1.1, 10.0)
	var asistente := _elegir_asistente(once, autor, minuto) if autor != null else null
	cronica.append({"min": minuto, "tipo": "gol", "club": c.id, "autor": autor.nombre if autor else "?"})
	_momentum_push(2, es_local)
	gol.emit(c, autor, minuto, asistente)

## `_arb`/`registrarFalloArbitro()` del HTML: cada árbitro tiene una personalidad
## y esa personalidad decide cosas por su cuenta -tarjetas de más, un penal que
## no era, un gol que anula por nada-. `ctx_factor_tarjetas` (el "_fVAR" del
## HTML) recorta las probabilidades a la mitad cuando la liga vota VAR, IGUAL
## que recorta las tarjetas normales en `_incidencias()`: el árbitro también
## se cuida más con la cámara encima.
func _chequeo_arbitral() -> void:
	if arbitro.is_empty():
		return
	var f_var := ctx_factor_tarjetas
	var nombre := String(arbitro.get("nombre", ""))
	match String(arbitro.get("perfil", "")):
		"tarjetero":
			if not Azar.suerte(0.010 * f_var):
				return
			var arr := once_local if Azar.suerte(0.5) else once_visita
			_tarjeta_arbitral(arr, "🟨 %s saca otra amarilla: " % nombre)
		"casero":
			if not Azar.suerte(0.008 * f_var):
				return
			## Siempre contra el que visita: es lo que hace "casero" casero.
			_tarjeta_arbitral(once_visita, "🟨 %s cobra para la casa: amarilla a " % nombre)
		"estricto":
			if not Azar.suerte(0.004 * f_var):
				return
			## 55%/45% a tu favor cuando el partido es tuyo -"_favMi" del HTML-;
			## sin nadie a quien favorecer -un cruce entre dos clubes de la IA-
			## se reparte parejo.
			var prob_local := 0.5
			if local.id == ctx_club_id:
				prob_local = 0.55
			elif visita.id == ctx_club_id:
				prob_local = 0.45
			if Azar.suerte(prob_local):
				decision_arbitral.emit("⚽ ¡GOL de penal! %s no dudó en cobrarlo." % nombre, minuto)
				_anotar(local, once_local, true)
			else:
				decision_arbitral.emit("⚽ Penal cobrado en contra. Con %s no se toca a nadie." % nombre, minuto)
				_anotar(visita, once_visita, false)
		"figura":
			if Azar.suerte(0.003 * f_var):
				decision_arbitral.emit(
					"⚖️ %s anula un gol por milímetros. Protestas en las dos bancas." % nombre, minuto)
		_:
			pass   ## "permisivo": no hace nada por su cuenta -deja jugar, es la gracia.

## Una llegada al area. Se anota como remate siempre, y solo a veces como gol:
## el resto se reparte entre atajada, palo y fallo con el mismo `r` -un solo
## tiro de dados, como en el HTML, no uno para el gol y otro aparte para el
## resto- para que las proporciones no se descuadren.
func _atacar(c: Club, once: Array[Jugador], es_local: bool) -> void:
	## EL ÁRBITRO, antes que nada: en el HTML sus chequeos van al principio de
	## `ataque()`, sobre CADA llegada, sin que le importe si termina en gol,
	## atajada o fallo -son sucesos aparte, no una consecuencia del remate-.
	_chequeo_arbitral()
	## El xG de cada llegada: entre 0,09 y 0,31, como en el HTML. Sumado a lo
	## largo del partido es lo que permite decir "generamos para tres y metimos
	## uno" sin que sea una impresión, sino un número.
	var xg_de_esta := 0.09 + Azar.f() * 0.22
	if es_local:
		remates_local += 1
		xg_local += xg_de_esta
	else:
		remates_visita += 1
		xg_visita += xg_de_esta
	var r := Azar.f()
	if r < CONVERSION:
		## Un gol es, por definición, un tiro a puerta.
		if es_local:
			tiros_puerta_local += 1
		else:
			tiros_puerta_visita += 1
		_anotar(c, once, es_local)
		return
	var autor := _elegir_goleador(once)
	var tipo := "fallo"
	if r < R_ATAJADA:
		tipo = "atajada"
		## Y una atajada también: el portero solo ataja lo que iba dentro. El
		## palo NO cuenta -pega en el poste, no la para nadie-, igual que en el
		## HTML, que solo hace `puertaMi++` en el gol y en la atajada.
		if es_local:
			tiros_puerta_local += 1
		else:
			tiros_puerta_visita += 1
	elif r < R_POSTE:
		tipo = "poste"
	_momentum_push(1, es_local)
	remate.emit(c, autor, tipo, minuto)

## Tarjetas y lesiones. Las probabilidades por minuto salen de las del HTML
## repartidas sobre los 90: ~2,8 amarillas y ~0,2 lesiones por partido.
func _incidencias() -> void:
	## EL VAR RECORTA LAS TARJETAS. `Federacion.factor_tarjetas()` devolvia un 0,5
	## que no leia nadie: la asamblea podia votar el videoarbitraje y en el campo
	## se sacaban exactamente las mismas amarillas. Con video se protesta menos y
	## se inventan menos faltas, que es justo lo que el HTML llamaba `_fVAR`.
	if Azar.suerte(0.031 * ctx_factor_tarjetas) and not motor_externo:
		var l := _alguien(_todos)
		if l != null:
			l.amarillas += 1
			var roja := l.amarillas % 2 == 0 and Azar.suerte(0.18)
			if roja:
				l.suspension = max(l.suspension, 1)
			tarjeta.emit(l, roja, minuto)
	## Una sola tirada siempre: la superficie cambia la probabilidad, no cuántas
	## veces se consulta `Azar`.
	var f_sup := ctx_lesion_local if local != null and local.id == ctx_club_id else 1.0
	if Azar.suerte(0.0024 * f_sup):
		var h := _alguien(_todos)
		if h != null:
			## LA LESION LA DIAGNOSTICA `Medico`, no un numero suelto.
			##
			## Antes se sorteaban de una a ocho semanas aqui mismo y no se pasaba por
			## el parte medico: la lesion no tenia nombre, no entraba en el historial
			## y `severidad_en_partido()` -escrita para esto exactamente- no la
			## llamaba nadie. Ahora la lesion del campo es la misma que la del parte.
			var semanas := 0
			if ctx_medico != null and h.club_id == ctx_club_id:
				semanas = ctx_medico.lesionar(h, ctx_medico.severidad_en_partido(),
					"lesión en partido", ctx_anio, ctx_semana)
			else:
				semanas = Azar.ent(1, 8)
				if h.rasgo == "fragil":
					semanas += Azar.ent(1, 3)
				h.lesionar(semanas)
			lesion.emit(h, semanas, minuto)
