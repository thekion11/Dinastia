extends "res://nucleo/selecciones_p1.gd"
## (Parte 2 de 3 de `selecciones.gd`.)

## Los 30 preseleccionados: los mejores elegibles sanos del mundo entero.
func _prenomina() -> void:
	var m := _mundo()
	var lista := _elegibles_sanos(m)
	lista.sort_custom(_mejor_media)
	if lista.size() > TOPE_PRENOMINA:
		lista.resize(TOPE_PRENOMINA)
	prenomina_ids.clear()
	var mios: Array[String] = []
	for j in lista:
		prenomina_ids.append(j.id)
		if j.club_id == m.mi_club_id:
			mios.append(j.nombre)
	var sel := nombre_seleccion()
	noticia.emit("Prenómina de " + sel,
		"La selección de %s publica una lista preliminar de %d jugadores rumbo a la próxima fecha internacional." % [sel, lista.size()]
		+ (" De tu club: %s." % ", ".join(mios) if not mios.is_empty() else " Sin jugadores de tu club en el corte inicial."))
	prenomina_publicada.emit(lista)

## Ids a jugadores en UNA pasada por el mundo. Buscar cada id por separado sería
## recorrer los miles de jugadores dieciocho veces: es exactamente el error que
## le costó al HTML el 93% de su tiempo de ejecución con `plantelDe()`.
func _resolver(ids: Array[String]) -> Array[Jugador]:
	var salida: Array[Jugador] = []
	var m := _mundo()
	if m == null or ids.is_empty():
		return salida
	var quiero := {}
	for id in ids:
		quiero[id] = null
	for c: Club in m.clubes.values():
		for j in c.plantilla:
			if quiero.has(j.id):
				quiero[j.id] = j
	for id in ids:
		var j: Jugador = quiero[id]
		if j != null:
			salida.append(j)
	return salida

# ---------------------------------------------------------------------------
#  LISTAS PARA LA PANTALLA
# ---------------------------------------------------------------------------

func convocados() -> Array[Jugador]:
	return _resolver(nomina_ids)

func prenominados() -> Array[Jugador]:
	return _resolver(prenomina_ids)

# ---------------------------------------------------------------------------
#  LO QUE PUEDE HACER EL ENTRENADOR
# ---------------------------------------------------------------------------

func caps_de(j: Jugador) -> int:
	return int(_caps.get(j.id, 0)) if j != null else 0

func racha_de(j: Jugador) -> int:
	return int(_racha.get(j.id, 0)) if j != null else 0

## Lo que le cuesta a TU club la gira. Solo a los tuyos: el físico de los
## jugadores de la IA no lo recupera nadie (`Entrenamiento` solo procesa tu
## plantel), así que restárselo sería una sangría permanente que no se ve en
## ninguna pantalla. En el HTML pasa lo mismo y por el mismo motivo.
func _desgastar(j: Jugador, mio: Club, anio: int, semana_n: int) -> void:
	var racha := racha_de(j) + 1
	_racha[j.id] = racha
	var sobreuso := racha >= FECHAS_PARA_SOBREUSO
	j.fisico = clampi(j.fisico - DESGASTE_FIFA - (DESGASTE_SOBREUSO if sobreuso else 0), 10, 100)
	if not Azar.suerte(RIESGO_GIRA + (RIESGO_EXTRA_SOBREUSO if sobreuso else 0.0)):
		return

	var m := _mundo()
	var sev := Medico.MEDIA if Azar.suerte(PROB_LESION_MEDIA) else Medico.LEVE
	var sem := 0
	var tipo := "molestia"
	if m.medico != null:
		sem = m.medico.lesionar(j, sev, "jugando con su selección", anio, semana_n)
		tipo = m.medico.diagnostico(j)
	else:
		## Sin parte médico (todavía no has tomado un club) no hay diagnóstico,
		## pero la baja existe igual: el jugador vuelve roto de la gira.
		sem = Azar.ent(1, 3)
		j.lesionar(sem)
	if sem <= 0:
		return

	## El programa de protección de clubes de la FIFA: te paga el sueldo del
	## lesionado. Se escala al tamaño de tu club como cualquier ingreso
	## operativo, que es lo que hace `esc$` en el HTML.
	var compensacion := Eco.escalar(float(j.sueldo) * float(COMPENSACION_BASE + sem), float(mio.rep))
	if compensacion > 0:
		mio.mover_saldo(compensacion)
		movimiento.emit("Compensación de la federación internacional por lesión en gira: " + j.nombre, compensacion)
	noticia.emit(
		("⚠️ Sobrecarga en la selección: " if sobreuso else "Lesionado en la selección: ") + j.nombre,
		"%s vuelve tocado de la gira: %s (%d sem)." % [j.nombre, tipo.to_lower(), sem]
		+ (" Es su %dª convocatoria seguida sin descanso: la selección lo exprime y el club paga las consecuencias." % racha if sobreuso else "")
		+ (" El club recibe la ayuda del programa de protección de clubes de la federación internacional." if compensacion > 0 else ""))
	vuelve_tocado.emit(j, sem, sobreuso)

func _anotar_resultado(linea: String) -> void:
	resultados.push_front(linea)
	while resultados.size() > MAX_RESULTADOS:
		resultados.remove_at(resultados.size() - 1)

## El partido de la fecha FIFA. El rival sale del escalafón mundial evitando que
## te enfrentes a ti mismo, y el marcador es un sorteo puro: la selección no
## tiene plantilla que simular, y fingir un partido de verdad con jugadores que
## no están en ningún club sería inventar un motor entero para una línea de texto.
func _jugar_amistoso(sel: String) -> void:
	var rivales: Array = []
	for n: String in _tabla_selecciones():
		if _txt(n) != sel:
			rivales.append(_txt(n))
	if rivales.is_empty():
		return
	var rival := String(Azar.uno(rivales))
	var g1 := Azar.ent(0, 3)
	var g2 := Azar.ent(0, 3)
	var linea := "%s %d - %d %s" % [sel, g1, g2, rival]
	_anotar_resultado(linea)
	noticia.emit("Fecha internacional: " + linea,
		"Cierra la ventana internacional. Los que fueron vuelven con %s." % ("el ánimo arriba" if g1 >= g2 else "la mochila pesada"))

## La nómina de 18 y el partido. Aquí es donde la selección se lleva a los tuyos.
func _fecha_fifa(anio: int, semana_n: int) -> void:
	var m := _mundo()
	var mio := m.mi_club()
	var sel := nombre_seleccion()

	## Primero el filtro, con el pedido de descanso resuelto dentro: la
	## federación decide una sola vez por jugador y por fecha, gane o pierda.
	var candidatos: Array[Jugador] = []
	for j in _elegibles_sanos(m):
		if mio != null and j.club_id == mio.id and _descanso.has(j.id):
			_descanso.erase(j.id)
			var figura := j.ovr >= mio.rep + MARGEN_FIGURA
			if Azar.suerte(RESPETA_A_LA_FIGURA if figura else RESPETA_AL_SUPLENTE):
				_racha[j.id] = 0
				noticia.emit("La federación respeta el pedido",
					"El cuerpo técnico de %s decide no citar a %s esta fecha internacional, atendiendo el pedido de descanso del club." % [sel, j.nombre])
				continue
			noticia.emit("La federación ignora el pedido",
				"Pediste que %s descansara y la federación lo citó igual. Vuelve el lunes, y verás cómo." % j.nombre)
		candidatos.append(j)
	candidatos.sort_custom(_mejor_media)

	## Los 18, por líneas. Se recorre la lista ya ordenada, así que cada línea se
	## queda con sus mejores: es lo que impide que la nómina sean once medios.
	var cupos := CUPOS.duplicate()
	var convocados: Array[Jugador] = []
	for j in candidatos:
		if int(cupos.get(j.pos, 0)) > 0:
			convocados.append(j)
			cupos[j.pos] = int(cupos[j.pos]) - 1
		if convocados.size() >= TOPE_NOMINA:
			break
	nomina_ids.clear()
	for j in convocados:
		nomina_ids.append(j.id)

	## Los que estaban en la prenómina y no llegaron. Es la mitad de para lo que
	## sirve publicar una lista preliminar.
	var cortados: Array[String] = []
	for j in prenominados():
		if mio != null and j.club_id == mio.id and not convocados.has(j):
			cortados.append(j.nombre)
	if not cortados.is_empty():
		noticia.emit("Quedaron fuera de la nómina final",
			"Estaban en la prenómina pero no llegaron a la lista definitiva: %s. El cuerpo técnico prefirió otras variantes." % ", ".join(cortados))

	## Al que no va se le corta la racha: el sobreuso castiga fechas SEGUIDAS.
	for j in candidatos:
		if mio != null and j.club_id == mio.id and not convocados.has(j):
			_racha[j.id] = 0

	var mios: Array[Jugador] = []
	for j in convocados:
		_caps[j.id] = caps_de(j) + 1
		j.cambiar_moral(MORAL_CONVOCADO, "Selección nacional")
		if mio == null or j.club_id != mio.id:
			continue
		mios.append(j)
		_desgastar(j, mio, anio, semana_n)

	_jugar_amistoso(sel)
	if not mios.is_empty():
		var nombres: Array[String] = []
		for j in mios:
			nombres.append(j.nombre)
		noticia.emit("Convocados de tu club",
			"Se van con %s: %s. Vuelven con la moral arriba y con el depósito vacío." % [sel, ", ".join(nombres)])
	convocatoria.emit(convocados, mios)

## El pulso semanal de la selección. Se llama siempre; decide ella si toca algo.
func semana(anio: int, semana_n: int) -> void:
	if _mundo() == null:
		return
	if hay_prenomina(semana_n):
		_prenomina()
	if hay_fecha_fifa(semana_n):
		_fecha_fifa(anio, semana_n)

func temporadas_en_el_pais(j: Jugador) -> int:
	return int(_residencia.get(j.id, 0)) if j != null else 0

func nacionalidad_deportiva(j: Jugador) -> String:
	return String(_nacionalizados.get(j.id, "")) if j != null else ""

func pidio_descanso(j: Jugador) -> bool:
	return j != null and _descanso.has(j.id)

## Lo que cuesta el trámite: un fijo escalado al tamaño del club más diez semanas
## de su sueldo. Nacionalizar a un crack es una inversión; a un suplente, casi gratis.
func costo_nacionalizacion(j: Jugador) -> int:
	var m := _mundo()
	var mio: Club = m.mi_club() if m != null else null
	var rep := float(mio.rep) if mio != null else Eco.REP_PIVOTE
	return Eco.escalar(COSTE_NACIONALIZACION, rep) + int(round(float(j.sueldo) * MULTIPLO_SUELDO_NACIONALIZACION))

## Tramita la nacionalidad deportiva. Devuelve "" si se hizo, o el motivo por el
## que no, como el resto de acciones del proyecto.
func nacionalizar(j: Jugador) -> String:
	var m := _mundo()
	if m == null or j == null:
		return "no hay partida"
	var mio := m.mi_club()
	if mio == null or j.club_id != mio.id:
		return "solo puedes nacionalizar a los tuyos"
	if elegible(j):
		return "ya puede jugar por " + nombre_seleccion()
	if temporadas_en_el_pais(j) < TEMPORADAS_PARA_NACIONALIZAR:
		return "necesita %d temporadas jugando en el país" % TEMPORADAS_PARA_NACIONALIZAR
	var costo := costo_nacionalizacion(j)
	if costo > mio.saldo:
		return "no hay caja: cuesta %d y tienes %d" % [costo, mio.saldo]
	mio.mover_saldo(-costo)
	movimiento.emit("Trámite de nacionalización: " + j.nombre, -costo)
	_nacionalizados[j.id] = pais_seleccion()
	noticia.emit("Carta de nacionalización",
		"%s (nacido en %s) obtiene la nacionalidad de %s tras %d temporadas en el país. Ya puede ser convocado a la selección."
		% [j.nombre, j.pais, nombre_seleccion(), temporadas_en_el_pais(j)])
	return ""

## Pide a la federación que no lo citen en la próxima fecha. No es un botón de
## "no va": la federación decide, y a una figura casi nunca te la perdona. Ese
## reparto es lo que convierte el pedido en una apuesta y no en un interruptor.
func pedir_descanso(j: Jugador) -> String:
	var m := _mundo()
	if m == null or j == null:
		return "no hay partida"
	var mio := m.mi_club()
	if mio == null or j.club_id != mio.id:
		return "solo puedes pedirlo por los tuyos"
	if _descanso.has(j.id):
		return "ya hay un pedido en curso"
	_descanso[j.id] = true
	return ""

## Los más internacionales del mundo: [{jugador, caps}].
func mas_convocados(tope: int = 12) -> Array[Dictionary]:
	var m := _mundo()
	if m == null:
		return []
	var filas: Array[Dictionary] = []
	for c: Club in m.clubes.values():
		for j in c.plantilla:
			var n := caps_de(j)
			if n > 0:
				filas.append({"jugador": j, "caps": n})
	filas.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		if int(a["caps"]) != int(b["caps"]):
			return int(a["caps"]) > int(b["caps"])
		return (a["jugador"] as Jugador).id < (b["jugador"] as Jugador).id)
	if tope > 0 and filas.size() > tope:
		filas.resize(tope)
	return filas

## Tus extranjeros camino del pasaporte: [{jugador, temporadas}].
func candidatos_a_nacionalizar(tope: int = 6) -> Array[Dictionary]:
	var m := _mundo()
	var mio: Club = m.mi_club() if m != null else null
	if mio == null:
		return []
	var filas: Array[Dictionary] = []
	for j in mio.plantilla:
		if elegible(j) or temporadas_en_el_pais(j) <= 0:
			continue
		filas.append({"jugador": j, "temporadas": temporadas_en_el_pais(j)})
	filas.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		if int(a["temporadas"]) != int(b["temporadas"]):
			return int(a["temporadas"]) > int(b["temporadas"])
		return (a["jugador"] as Jugador).id < (b["jugador"] as Jugador).id)
	if tope > 0 and filas.size() > tope:
		filas.resize(tope)
	return filas

## Residencia de los extranjeros: cada temporada jugando en el país suma, y a las
## cuatro se les puede tramitar el pasaporte. Cambiar de país la reinicia — es lo
## que hace que un extranjero al que cedes fuera pierda el camino andado.
func residencias() -> void:
	var m := _mundo()
	if m == null:
		return
	var p := pais_seleccion()
	for c: Club in m.clubes.values():
		for j in c.plantilla:
			if elegible(j, p):
				continue
			if c.pais != p:
				_residencia.erase(j.id)
				continue
			var n := temporadas_en_el_pais(j) + 1
			_residencia[j.id] = n
			if n == TEMPORADAS_PARA_NACIONALIZAR and c.id == m.mi_club_id:
				noticia.emit("Puede nacionalizarse: " + j.nombre,
					"%s cumple %d temporadas jugando en el país. Desde su ficha puedes tramitar la nacionalización deportiva y habilitarlo con la selección."
					% [j.nombre, TEMPORADAS_PARA_NACIONALIZAR])

## El torneo continental de selecciones del verano: Copa América, Eurocopa, Copa
## África, Copa de Asia, Copa Oro o Copa de Oceanía, según dónde dirijas.
##
## Cada dos años, los pares. Y no se juega: se SORTEA el puesto con una bolsa
## sesgada, igual que en el HTML. Es una decisión de diseño, no una pieza a
## medio hacer: la selección no tiene plantilla ni rivales con plantilla, así que
## un cuadro de verdad sería un torneo inventado entre nombres. Lo que sí es real
## es la consecuencia: si sale campeón, tus internacionales vuelven en una nube y
## se les nota en la moral.
func torneo_continental(anio: int) -> Dictionary:
	if anio % 2 != 0:
		return {}
	var puesto := int(Azar.uno(BOLSA_PUESTOS))
	var clave := Continental.confed_de(pais_seleccion())
	var torneo := String(TORNEO_POR_CONFED.get(clave, "Copa América"))
	var sel := nombre_seleccion()
	_anotar_resultado("%s %d: %s %s" % [torneo, anio, sel, PUESTOS_TORNEO[puesto]])
	noticia.emit("%s: %s %s" % [torneo, sel, PUESTOS_TORNEO[puesto]],
		"¡Título continental! Tus seleccionados vuelven en una nube." if puesto == 0
		else "Cierra el torneo de selecciones del verano.")
	if puesto == 0:
		for j in convocados():
			j.cambiar_moral(MORAL_TITULO_CONTINENTAL, "Selección nacional")
	torneo_de_selecciones.emit(torneo, puesto)
	return {"torneo": torneo, "puesto": puesto, "seleccion": sel, "anio": anio}

# ---------------------------------------------------------------------------
#  EL MUNDIAL DE CLUBES
# ---------------------------------------------------------------------------

## Corona a los campeones continentales del año y los hace jugar entre ellos.
##
## Ya no es una lista inventada, como decía el propio HTML: lo disputan los
## campeones REALES de las seis confederaciones que sortea `Continental`, y si el
## tuyo está ahí, lo juegas de verdad. La lista de confederaciones sale de
## `Continental.PRINCIPALES` y no se vuelve a escribir aquí: son las mismas seis
## copas grandes, y la segunda copa de un continente (Sudamericana, Europa
## League) no da plaza.
func mundial_de_clubes(anio: int) -> Dictionary:
	var m := _mundo()
	if m == null:
		return {}
	var campeones: Array[Club] = []
	var lineas: Array[String] = []
	for k: String in Continental.PRINCIPALES:
		var t: Continental = m.continentales.get(k)
		if t == null or t.campeon == null:
			continue
		campeones.append(t.campeon)
		var nombre_torneo := Continental.nombre_conti(k)
		lineas.append("%s: %s" % [nombre_torneo, t.campeon.nombre])
		campeones_continentales.push_front({
			"torneo": nombre_torneo, "campeon": t.campeon.nombre,
			"club_id": t.campeon.id, "clave": k, "anio": anio,
		})
	while campeones_continentales.size() > MAX_CAMPEONES_GUARDADOS:
		campeones_continentales.remove_at(campeones_continentales.size() - 1)
	if not lineas.is_empty():
		noticia.emit("🌍 Campeones continentales %d" % anio,
			" · ".join(lineas) + ". Todos ellos disputan el Mundial de Clubes.")
	if campeones.size() < 2:
		mundial_clubes = {}
		return {}

	var torneo := MundialClubes.new()
	torneo.preparar(campeones)
	var mio := m.mi_club()
	var entro := torneo.participa(mio)
	var relato: Array[String] = []
	while torneo.en_curso():
		for r: Dictionary in torneo.jugar_ronda():
			if r["local"] != mio and r["visita"] != mio:
				continue
			var l: Club = r["local"]
			var v: Club = r["visita"]
			var penales: Array = r.get("penales", [])
			relato.append("%s: %s %d-%d %s%s" % [
				r["ronda"], l.nombre, int(r["gl"]), int(r["gv"]), v.nombre,
				(" (pen %d-%d)" % [int(penales[0]), int(penales[1])]) if penales.size() == 2 else "",
			])
	var campeon: Club = torneo.campeon
	if campeon == null:
		mundial_clubes = {}
		return {}

	var eres_tu := mio != null and campeon == mio
	mundial_clubes = {
		"anio": anio, "campeon": campeon.nombre, "club_id": campeon.id,
		"mio": eres_tu, "relato": relato,
	}
	if eres_tu:
		## El premio ya lo cobró el club dentro del torneo. Aquí solo queda lo que
		## no es dinero: la vitrina de la carrera y el prestigio. `sumar_trofeo`
		## ya suma 3 de prestigio, así que se completan los 10 del HTML con 7.
		if m.roles != null:
			m.roles.sumar_trofeo("Mundial de Clubes")
			m.roles.sumar_prestigio(PRESTIGIO_MUNDIAL_CLUBES - 3)
		noticia.emit("🏆🌍 ¡CAMPEONES DEL MUNDO!",
			"Ganaste el Mundial de Clubes %d.\n\n%s\n\nNo hay techo por encima de esto: tu club entra en la historia grande del fútbol mundial."
			% [anio, "\n".join(relato)])
	else:
		noticia.emit("🌍 Mundial de Clubes %d" % anio,
			"Lo ganó %s (%s)." % [campeon.nombre, campeon.pais]
			+ ("\n\nTu camino:\n" + "\n".join(relato) if entro and not relato.is_empty() else ""))
	mundial_de_clubes_jugado.emit(anio, campeon, eres_tu)
	return mundial_clubes.duplicate()
