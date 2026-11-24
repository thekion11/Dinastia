extends "res://nucleo/selecciones_p2.gd"
## [Capa intermedia de `selecciones.gd`, entre `selecciones_p2.gd` y `selecciones.gd`] nacionalidad deportiva, nacionalizaciones, descansos y el Mundial de Clubes (20-11, orden 63: partido por tamaño).

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
	var clave := Continental.confed_de(pais_seleccion())
	if not Calendario.toca_continental_selecciones(clave, anio):   ## (10-11) el ciclo real de cada torneo, igual que el calendario
		return {}
	var torneo := String(TORNEO_POR_CONFED.get(clave, "Copa América"))
	var sel := nombre_seleccion()
	## (10-11) Un torneo DE VERDAD, con grupos, eliminatorias y partidos (`SeleccionesTorneos`), en vez de sortear el puesto.
	var t := cargo.listo(torneo, anio)   ## (10-11) el mismo torneo que jugó tu selección como seleccionador, si es el mismo
	if t == null:
		t = SeleccionesTorneos.continental(self, _mundo(), clave, torneo, anio)
	t.jugar_entero()
	cargo.anotar(_mundo(), t)
	ultimo_torneo = t
	var mia := SeleccionesTorneos.equipo_en(t, sel)
	if mia == null:
		return {}
	var puesto := t.puesto_de(mia)
	_anotar_resultado("%s %d: %s %s" % [torneo, anio, sel, PUESTOS_TORNEO[puesto]])
	noticia.emit("%s: %s %s" % [torneo, sel, PUESTOS_TORNEO[puesto]],
		"¡Título continental! Tus seleccionados vuelven en una nube." if puesto == 0
		else "Cierra el torneo de selecciones del verano.")
	if puesto == 0:
		for j in convocados():
			j.cambiar_moral(MORAL_TITULO_CONTINENTAL, "Selección nacional")
	torneo_de_selecciones.emit(torneo, puesto)
	return {"torneo": torneo, "puesto": puesto, "seleccion": sel, "anio": anio, "campeon": t.campeon.nombre if t.campeon != null else ""}

# ---------------------------------------------------------------------------
#  EL MUNDIAL DE CLUBES
# ---------------------------------------------------------------------------

## Apunta a los campeones continentales de la temporada (el registro de la partida y la noticia) y los devuelve.
##
## Los torneos de la FIFA ya no se juegan aquí: `FifaClubes` arma el Mundial de Clubes y la Copa Intercontinental al sortear la
## temporada que empieza, con los campeones de la que se cierra, y se juegan semana a semana. La lista de confederaciones
## sale de `Continental.PRINCIPALES`: son las mismas copas grandes, y la segunda copa de un continente (Sudamericana, Europa
## League) no da plaza.
func anotar_campeones_continentales(anio: int) -> Array[Club]:
	var m := _mundo()
	var campeones: Array[Club] = []
	if m == null:
		return campeones
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
	return campeones

## Juega AHORA el Mundial de Clubes con los campeones continentales de la temporada, de un tirón y sin esperar al calendario.
## En la partida no se usa (el torneo se juega en sus semanas, ver `FifaClubes`); queda para pruebas y para los casos sin calendario.
func mundial_de_clubes(anio: int) -> Dictionary:
	var m := _mundo()
	if m == null:
		return {}
	var campeones := anotar_campeones_continentales(anio)
	if campeones.size() < 2:
		mundial_clubes = {}
		return {}
	var torneo := MundialClubes.new()
	torneo.preparar(campeones)
	while torneo.en_curso():
		torneo.jugar_ronda()
	if torneo.campeon == null:
		mundial_clubes = {}
		return {}
	return registrar_mundial(torneo, anio)

## Deja constancia de un Mundial de Clubes ya jugado: el resumen de la pantalla de la federación, el premio de la vitrina, el
## prestigio y la noticia. Lo llaman `FifaClubes.coronar` (cuando se juega en sus semanas) y `mundial_de_clubes` (de un tirón).
func registrar_mundial(torneo: Continental, anio: int) -> Dictionary:
	var m := _mundo()
	var campeon: Club = torneo.campeon
	if m == null or campeon == null:
		mundial_clubes = {}
		return {}
	var mio := m.mi_club()
	var entro := torneo.participa(mio)
	var relato: Array[String] = []
	if entro:
		relato = FifaClubes.relato(torneo, mio)
	var eres_tu := mio != null and campeon == mio
	mundial_clubes = {
		"anio": anio, "campeon": campeon.nombre, "club_id": campeon.id,
		"mio": eres_tu, "relato": relato,
	}
	if eres_tu:
		## El premio ya lo cobró el club dentro del torneo. Aquí solo queda lo que no es dinero: la vitrina de la carrera y el
		## prestigio. `sumar_trofeo` ya suma 3 de prestigio, así que se completan los 10 del HTML con 7.
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
