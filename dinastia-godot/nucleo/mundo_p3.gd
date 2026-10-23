extends "res://nucleo/mundo_p2.gd"
## [Capa 3/9 de `mundo.gd`] fundar_club, multiplicador_desafios, alternar_tienda, ingreso_tienda, puntaje_carrera, proximo_partido … (+20)

func fundar_club(nombre_club: String, pais: String, col1: String = "", col2: String = "", estadio: String = "") -> Club:
	var candidatos: Array[Club] = []
	for c: Club in clubes.values():
		if c.pais != pais:
			continue
		if pais == "CHI" and c.division != 2:
			continue
		candidatos.append(c)
	if candidatos.is_empty():
		return null
	candidatos.sort_custom(func(a: Club, b: Club) -> bool: return a.rep < b.rep)
	var c: Club = candidatos[0]
	## El nombre lo escribió el jugador, no viene de una tabla en leetspeak:
	## no pasa por Nombres.limpiar(), que es para decensurar datos del juego,
	## no para tocar lo que alguien tecleó a mano.
	c.nombre = nombre_club
	c.rep = REP_FUNDACION
	## Los colores y el estadio que eligió el fundador (26-9-2026, "Crear tu
	## Club" desde el menú); sin elegir, los de siempre.
	c.color1 = col1 if col1 != "" else "#1e4030"
	c.color2 = col2 if col2 != "" else "#c9a227"
	if estadio != "":
		c.estadio_nombre = estadio
	c.plantilla.clear()
	_poblar(c)
	tomar_el_mando(c.id)
	return c

## El multiplicador de puntaje final: se multiplican los factores de todos los
## desafíos activos entre sí, tal cual el HTML.
func multiplicador_desafios() -> float:
	var m := 1.0
	var tabla: Variant = Datos.tabla("DESAFIOS")
	if not (tabla is Array):
		return m
	for k: String in desafios:
		for fila: Array in (tabla as Array):
			if String(fila[0]) == k:
				m *= float(fila[4])
				break
	return m

## Lanza o retira una línea. Devuelve "" si salió bien.
func alternar_tienda(clave: String, c: Club) -> String:
	if not TIENDA.has(clave):
		return "esa línea no existe"
	if bool(tienda.get(clave, false)):
		tienda[clave] = false
		return ""
	var coste := Eco.escalar(int(TIENDA[clave]["montaje"]), c.rep)
	if c.saldo < coste:
		return "montar la línea cuesta %d" % coste
	c.mover_saldo(-coste)
	_anotar_movimiento("Lanzamiento de línea: %s" % String(TIENDA[clave]["nombre"]), -coste)
	tienda[clave] = true
	return ""

## Lo que deja la tienda en el cierre de mes.
func ingreso_tienda(c: Club) -> int:
	if c.id != mi_club_id:
		return 0
	var bruto := 0.0
	for clave: String in TIENDA:
		if bool(tienda.get(clave, false)):
			bruto += float(c.socios) * float(TIENDA[clave]["por_socio"])
	if bruto <= 0.0:
		return 0
	var animo := float(prensa.animo) if prensa != null else 60.0
	var mkt := 1.1 if directiva != null and directiva.tiene_consejero("mkt") else 1.0
	return int(round(bruto * (animo / 60.0) * mkt))

## `puntajeCarrera()` del HTML: la cifra que resume una carrera entera, y la
## única razón por la que elegir desafíos duros compensa -multiplican esto-.
## Todo lo que suma ya se lleva la cuenta por otro lado; aquí solo se juntan.
func puntaje_carrera() -> Dictionary:
	var titulos := roles.trofeos.size() if roles != null else 0
	var prestigio := roles.prestigio if roles != null else 0
	var cuantos_logros := logros.desbloqueados.size() if logros != null else 0
	var temporadas := maxi(1, anio - 2026)
	var base := titulos * 1000 + prestigio * 40 + cuantos_logros * 300 + temporadas * 120
	var mult := multiplicador_desafios()
	return {
		"titulos": titulos, "prestigio": prestigio, "logros": cuantos_logros,
		"temporadas": temporadas, "base": base, "multiplicador": mult,
		"total": int(round(float(base) * mult)),
	}

## Contra quien juega tu club esta jornada: [local, visita], o vacio si no hay.
## Lo necesita la interfaz para dirigir ESE partido en directo antes de que el
## mundo simule los otros.
func proximo_partido() -> Array:
	var c := mi_club()
	if c == null:
		return []
	for l in ligas:
		if l.clubes.has(c):
			return l.emparejamiento_de(c)
	return []

## El cruce de copa de tu club esta semana, o vacio. Solo hay copa cada cuatro
## jornadas, y solo si tu club sigue vivo en el torneo.
func partido_de_copa() -> Array:
	if copa == null or not copa.en_curso() or semana % 4 != 0:
		return []
	return copa.emparejamiento_de(mi_club())

## El torneo continental en el que juega tu club, o null.
func mi_continental() -> Continental:
	var c := mi_club()
	return Continental.de_club(continentales, c) if c != null else null

## El cruce continental de tu club esta semana -Libertadores, Sudamericana,
## Champions, Europa League, lo que le toque a tu país-, o vacio.
##
## HASTA ESTA TANDA NO EXISTÍA, y por eso `_dirigir()` nunca podía llevarte a
## un partido continental en vivo: solo miraba copa y liga. El motor de abajo
## -`Continental.jugar_ronda(ya_jugado)`- ya sabía recibir el partido que
## acabas de dirigir y no volver a simularlo; solo faltaba esta puerta.
func partido_continental() -> Array:
	if Continental.toca_ronda(semana) < 0:
		return []
	var t := mi_continental()
	if t == null or not t.en_curso():
		return []
	return t.emparejamiento_de(mi_club())

## Saca la lista de ligas de DATA_P1/DATA_P2 (Chile, las dos divisiones) y de
## PAISES_LIGAS (el resto del mundo), que es donde las tiene el HTML.
func _fuentes_de_liga(paises: Array[String]) -> Array:
	var salida: Array = []
	var quiere := func(p: String) -> bool: return paises.is_empty() or paises.has(p)
	if quiere.call("CHI"):
		var p1: Array = Datos.tabla("DATA_P1")
		var p2: Array = Datos.tabla("DATA_P2")
		if p1 != null:
			salida.append({"nombre": "Primera División", "pais": "CHI", "clubes": p1})
		if p2 != null:
			salida.append({"nombre": "Primera B", "pais": "CHI", "clubes": p2, "division": 2})
	var pl: Dictionary = Datos.tabla("PAISES_LIGAS")
	if pl != null:
		for pais: String in pl:
			if not quiere.call(pais):
				continue
			var d: Dictionary = pl[pais]
			salida.append({
				"nombre": Nombres.de_tabla(String(d.get("liga", pais))),
				"pais": pais,
				"clubes": d.get("clubes", []),
			})
	return salida

## Una fila de club es [nombre, color1, color2, reputacion, aforo].
func _crear_club(fila: Array, pais: String) -> Club:
	_seq_club += 1
	var c := Club.new("c%d" % _seq_club, Nombres.de_tabla(String(fila[0])))
	c.pais = pais
	c.color1 = String(fila[1]) if fila.size() > 1 else "#2b6b45"
	c.color2 = String(fila[2]) if fila.size() > 2 else "#ffffff"
	c.rep = int(fila[3]) if fila.size() > 3 else 70
	c.estadio_aforo = int(fila[4]) if fila.size() > 4 else 20000
	c.saldo = int(Eco.ref_caja(float(c.rep)))
	## Los socios salen del aforo: un club con estadio grande tiene masa social
	## grande. Es lo que hace que un club historico venido a menos siga llenando.
	c.socios = int(float(c.estadio_aforo) * (0.22 + float(c.rep) / 420.0))
	return c

func _capitan_si_falta(c: Club) -> void:
	var mejor: Jugador = null
	for j: Jugador in c.plantilla:
		if j.capitan:
			return
		if j.edad >= 27 and (mejor == null or j.ovr > mejor.ovr):
			mejor = j
	if mejor == null and not c.plantilla.is_empty():
		mejor = c.plantilla[0]
	if mejor != null:
		mejor.capitan = true

## Genera el mundo a partir de las tablas exportadas del HTML.
##
## `paises` limita que ligas se crean. Generar las 24 completas son mas de
## 10.000 jugadores: util para una partida de verdad, un desperdicio para una
## prueba que solo mira si la tabla suma. Por eso se puede pedir un mundo chico.
func generar(paises: Array[String] = [], semilla_partida: int = 0) -> void:
	semilla = Azar.sembrar(semilla_partida)
	mercado = Mercado.new(self)
	roles = Roles.new(self)
	cesiones = Cesiones.new(self)
	## Las epocas son del MUNDO, no de tu club: se crean con el mundo y no al
	## tomar el mando, porque una camada boliviana sube o baja aunque tu dirijas
	## en Chile.
	eras = Eras.new(self)
	copa = null
	clubes.clear()
	ligas.clear()
	_seq_jugador = 0
	_seq_club = 0

	var fuentes := _fuentes_de_liga(paises)
	for f: Dictionary in fuentes:
		var liga := Liga.new(f["nombre"], f["pais"], int(f.get("division", 1)))
		for fila: Array in f["clubes"]:
			var c := _crear_club(fila, f["pais"])
			c.division = int(f.get("division", 1))
			clubes[c.id] = c
			liga.clubes.append(c)
			_poblar(c)
		liga.preparar()
		ligas.append(liga)
	## "PLANTILLAS REALES" del HTML: se aplica al final, con el mundo entero ya
	## generado -Reales necesita ver TODOS los clubes creados para poder cruzar
	## sus nombres contra la tabla, no uno a uno mientras se crean-.
	Reales.aplicar(self)
	## Con las plantillas reales nadie llevaba la cinta (21-10, M-073): el
	## veterano de más media de cada club sin capitán.
	for c: Club in clubes.values():
		_capitan_si_falta(c)
	## EL MUNDO HEREDADO (28-9-2026, `Meta`): si se pidió, los clubes arrancan
	## con la reputación con la que quedaron en tu última partida.
	if Meta.heredar_proximo:
		Meta.heredar_proximo = false
		Meta.aplicar_herencia(self)
	LeyesPais.clubes_mundo = clubes
	LeyesPais.anio_actual = anio

func jugadores() -> Array[Jugador]:
	var l: Array[Jugador] = []
	for c: Club in clubes.values():
		l.append_array(c.plantilla)
	return l

func cuantos_jugadores() -> int:
	var n := 0
	for c: Club in clubes.values():
		n += c.plantilla.size()
	return n

## `nuevoLibre()` del HTML. `crear_jugador()` exige un club -lo usa para país,
## formación de origen y referencia de media-, así que se genera con uno
## cualquiera y se desliga después: `club_id = ""` ya es el valor de fábrica
## de un `Jugador` nuevo, el mismo truco que usa el HTML (`j.club=''`).
func _nuevo_libre(elite: bool = false) -> Jugador:
	var demarcacion: String = Azar.uno(Datos.posd().keys())
	var grupo := Datos.grupo(demarcacion)
	var edad := Azar.ent(29, 34) if elite \
		else int(Azar.uno([18, 19, 20, 21, 27, 28, 29, 30, 31, 32, 33, 34, 35]))
	var ovr := Azar.ent(80, 88) if elite \
		else clampi(Azar.ent(52, 74) - (3 if edad > 32 else 0), 42, 88)
	var plantilla_club: Club = clubes.values()[Azar.ent(0, clubes.size() - 1)]
	var j := crear_jugador(plantilla_club, grupo, demarcacion, edad, ovr)
	j.club_id = ""
	j.club_formacion = ""
	## `j.pide` del HTML (lo que pide de sueldo) reutiliza directamente
	## `j.sueldo` -que `tasar()` ya dejó a precio de mercado según su media-,
	## en vez de un campo `pide_libre` aparte: mientras está libre ese campo no
	## significa otra cosa, y es el mismo número que se queda al firmar.
	j.sueldo = int(j.sueldo * (1.0 + Azar.f() * 0.5))
	j.motivo_libre = String(Azar.uno(MOTIVOS_LIBRE))
	return j

## `generarLibres()` del HTML: entre 10 y 16 nombres sin club, la primera vez
## que hace falta la bolsa (igual que `if(!G.libres.length)generarLibres()`).
func generar_libres() -> void:
	for i in Azar.ent(10, 16):
		libres.append(_nuevo_libre())

## `ficharLibre(idx)` del HTML: sin traspaso -no hay club vendedor-, solo una
## prima de fichaje (a la caja de una vez) más el sueldo normal. Usa la misma
## vara que la mesa de fichajes (`Mercado.deseo_de_venir()`, ya a prueba de
## `club_id == ""`: sin club propio, salta directo a las tres razones que no
## dependen de comparar clubes) para decidir si firma, así que un libre puede
## decir que no igual que cualquier objetivo del mercado normal.
func fichar_libre(idx: int, c: Club) -> Dictionary:
	if idx < 0 or idx >= libres.size():
		return {"error": "ese jugador ya no está libre"}
	var j := libres[idx]
	if not Regiones.admite(c, j):
		return {"error": Regiones.motivo(c)}
	var factor_agente := 1.0
	if prensa != null:
		factor_agente = float(prensa.agente_de(j).get("f", 1.0))
	var prima := int(round(float(j.sueldo) * 6.0 * factor_agente))
	if prima > c.saldo:
		return {"error": "no alcanza la prima de fichaje: %s" % str(prima)}
	var deseo := mercado.deseo_de_venir(j, c)
	if Azar.f() > clampf(0.20 + float(deseo["p"]) * 0.85, 0.10, 0.94):
		j.rechazos_libre += 1
		var expulsado := j.rechazos_libre >= 2
		if expulsado:
			libres.erase(j)
		return {"rechazado": true, "expulsado": expulsado}
	mercado.fichar(j, c, prima, j.sueldo, Azar.ent(2, 4))
	j.motivo_libre = ""
	libres.erase(j)
	return {"ok": true}

## `procesoLibres()` del HTML, cada semana: la bolsa se repone sola (50% si
## hay menos de 6), rarísima vez aparece una joya (4%, con su propio aviso -es
## lo bastante especial para no confundirlo con las demás noticias-), y se va
## vaciando sola (35%) simulando que otros clubes -de la IA, sin que haga
## falta simular el fichaje entero- se llevan a alguno.
func _procesar_libres() -> void:
	if libres.size() < 6 and Azar.suerte(0.5):
		libres.append(_nuevo_libre())
	if Azar.suerte(0.04):
		var e := _nuevo_libre(true)
		libres.push_front(e)
		libre_estrella.emit(e)
	if not libres.is_empty() and Azar.suerte(0.35):
		libres.remove_at(Azar.ent(0, libres.size() - 1))

## `G.jug[pid]` del HTML. No hay un índice plano -los jugadores solo viven
## dentro de `Club.plantilla`-, así que es una búsqueda lineal por todos los
## clubes; para algo puntual como el comparador o resolver una oferta guardada
## no hace falta un índice aparte.
func jugador_por_id(id: String) -> Jugador:
	if id == "":
		return null
	for c: Club in clubes.values():
		for j in c.plantilla:
			if j.id == id:
				return j
	return null

## Se consume al jugar: el análisis vale para UN partido, no para siempre.
func consumir_analisis() -> float:
	var b := bono_analisis
	bono_analisis = 1.0
	return b

func era_actual() -> Array:
	return ERAS_TACTICAS[era_tactica % ERAS_TACTICAS.size()]

## Lo que le hace la moda a un dibujo concreto.
func factor_moda(formacion: String) -> float:
	var e := era_actual()
	if (e[2] as Array).has(formacion):
		return BONO_MODA
	if (e[3] as Array).has(formacion):
		return CASTIGO_MODA
	return 1.0

## Aplica la rotación: los fundidos salen del once y entran los frescos de su
## mismo puesto. Devuelve cuántos cambió.
func aplicar_rotacion() -> int:
	if not rotacion_activa:
		return 0
	var mio := mi_club()
	if mio == null or mio.tactica == null:
		return 0
	var once := mio.once()
	var cambiados := 0
	for j: Jugador in once:
		if j.fisico >= FISICO_PARA_TITULAR or not j.disponible():
			continue
		## El recambio: alguien del mismo puesto, disponible y más fresco. Si no
		## lo hay, se queda el cansado —rotar por rotar y sacar a un titular por
		## un juvenil de 40 sería peor que no rotar.
		var mejor: Jugador = null
		for s: Jugador in mio.plantilla:
			if once.has(s) or not s.disponible():
				continue
			if s.pos_e != j.pos_e and not s.pos_sec.has(j.pos_e):
				continue
			if s.fisico < FISICO_PARA_TITULAR:
				continue
			if mejor == null or s.media_en(j.pos_e) > mejor.media_en(j.pos_e):
				mejor = s
		if mejor == null:
			continue
		## El once elegido a mano vive en `Club.once_elegido` -una lista de ids-.
		## Si no hay ninguno puesto, se parte del automatico de esta semana: rotar
		## sobre una lista vacia no cambiaria nada.
		if mio.once_elegido.size() != 11:
			mio.once_elegido.clear()
			for t: Jugador in once:
				mio.once_elegido.append(t.id)
		var pos := mio.once_elegido.find(j.id)
		if pos < 0:
			continue
		mio.once_elegido[pos] = mejor.id
		cambiados += 1
	return cambiados

func anotar_eficacia(formacion: String, gf: int, gc: int) -> void:
	if formacion == "":
		return
	if not eficacia_tactica.has(formacion):
		eficacia_tactica[formacion] = {"pj": 0, "pg": 0, "pe": 0, "pp": 0, "gf": 0, "gc": 0}
	var f: Dictionary = eficacia_tactica[formacion]
	f["pj"] = int(f["pj"]) + 1
	f["gf"] = int(f["gf"]) + gf
	f["gc"] = int(f["gc"]) + gc
	if gf > gc:
		f["pg"] = int(f["pg"]) + 1
	elif gf == gc:
		f["pe"] = int(f["pe"]) + 1
	else:
		f["pp"] = int(f["pp"]) + 1

## Los dos desafíos que se juegan en un solo partido: el invicto se acaba con
## la primera derrota -no empate, derrota- y el del clásico solo aprieta si
## ADEMÁS perdiste contra un rival de verdad.
func _chequear_desafios_tras_partido(gf: int, gc: int, rival: Club) -> void:
	var perdio := gf < gc
	if tiene_desafio("invicto") and perdio and fin_partida.is_empty():
		fin_partida = {"motivo": "invicto", "anio": anio, "semana": semana}
	if tiene_desafio("derbis") and perdio and es_clasico(mi_club(), rival):
		if directiva != null:
			## `mover_confianza()` solo recibe un DELTA, así que el objetivo absoluto
			## -la mitad de la confianza actual, redondeada, tal cual el HTML
			## (`Math.round(G.confianza*0.5)`)- se calcula primero y se resta el
			## delta que hace falta para llegar ahí. Restar directamente la mitad
			## redondeada (`-round(confianza*0.5)`) no es lo mismo con confianza
			## impar: con 55 de confianza daba 27 en vez de los 28 del HTML.
			var objetivo := int(round(float(directiva.confianza) * 0.5))
			directiva.mover_confianza(objetivo - directiva.confianza,
				"perdiste el clásico -desafío activo, cuesta el doble-")
