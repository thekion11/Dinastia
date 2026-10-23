class_name Logros
extends "res://nucleo/logros_p2.gd"
## (Parte 3 de 3 de `logros.gd`.)

## La gala: equipo ideal, mejor joven, mejor entrenador, fair play, club más
## popular, mejor hinchada y mejor estadio. Devuelve el acta entera y la archiva.
func premios_temporada() -> Dictionary:
	if mundo == null:
		return {}
	var mio := mundo.mi_club()
	if mio == null:
		return {}
	var liga := mundo.liga_de(mio)
	var t: Array = liga.tabla() if liga != null else []
	var campeon: Club = t[0]["club"] if not t.is_empty() else mio
	var mi_puesto := 0
	for i in t.size():
		if t[i]["club"] == mio:
			mi_puesto = i + 1
			break

	var universo := mundo.jugadores()
	var acta := {"anio": mundo.anio, "puesto": mi_puesto}

	## EQUIPO IDEAL. Se reparte plaza por plaza y no de una vez, porque un mismo
	## jugador no puede ocupar dos: por eso los ya elegidos se descartan.
	var ideal: Array[Jugador] = []
	for grupo: String in PUESTOS_IDEAL:
		var mejor: Jugador = null
		var mejor_nota := -1.0
		for j in universo:
			if Datos.grupo(j.pos_e) != grupo or ideal.has(j):
				continue
			var n := _nota_de_temporada(j)
			if n > mejor_nota:
				mejor_nota = n
				mejor = j
		if mejor != null:
			ideal.append(mejor)
	var ideal_texto: Array[String] = []
	for j in ideal:
		ideal_texto.append("%s (%s, %s)" % [Nombres.visible(j.nombre), j.pos_e, _nombre_club(j.club_id)])
	acta["ideal"] = ideal_texto
	## Cada premio queda en la ficha del jugador (C17).
	for j in ideal:
		j.premios.append({"anio": mundo.anio, "premio": "Equipo ideal de la temporada"})
	## EL MÁXIMO GOLEADOR de tu liga, con su trofeo en la ficha.
	var pichichi: Jugador = null
	if liga != null:
		for c: Club in liga.clubes:
			for j2: Jugador in c.plantilla:
				if pichichi == null or j2.goles > pichichi.goles:
					pichichi = j2
	if pichichi != null and pichichi.goles > 0:
		pichichi.premios.append({"anio": mundo.anio, "premio": "Máximo goleador (%d goles)" % pichichi.goles})
		acta["pichichi"] = "%s (%d goles, %s)" % [Nombres.visible(pichichi.nombre), pichichi.goles, _nombre_club(pichichi.club_id)]

	## MEJOR JOVEN. Sub-21, y en caso de empate manda la media: entre dos chicos
	## con los mismos números, el mejor jugador.
	var joven: Jugador = null
	var joven_nota := -1.0
	for j in universo:
		if j.edad > 21:
			continue
		var n := _nota_de_temporada(j)
		if n > joven_nota or (is_equal_approx(n, joven_nota) and joven != null and j.ovr > joven.ovr):
			joven_nota = n
			joven = j
	if joven != null:
		joven.premios.append({"anio": mundo.anio, "premio": "Mejor jugador joven"})
	acta["joven"] = "%s (%d años, %s)" % [
		Nombres.visible(joven.nombre), joven.edad, _nombre_club(joven.club_id)] if joven != null else "—"

	## MEJOR ENTRENADOR: el del campeón. Los técnicos rivales no están portados,
	## así que se nombra al club y no a la persona; lo que sí importa de verdad
	## —si eres tú— se decide igual.
	acta["dt"] = campeon.nombre
	acta["dt_es_mio"] = campeon == mio

	## FAIR PLAY: el club de primera de tu país con menos amarillas en todo el
	## año. El HTML fijaba "CHI" a mano porque allí solo se podía dirigir en
	## Chile; aquí se usa el país de tu club, que da lo mismo dirigiendo en Chile
	## y lo correcto dirigiendo en cualquier otro sitio.
	var amarillas := {}
	for j in universo:
		var c: Club = mundo.clubes.get(j.club_id)
		if c == null or c.pais != mio.pais or c.division != 1:
			continue
		amarillas[c.id] = int(amarillas.get(c.id, 0)) + j.amarillas
	var limpio_id := ""
	var limpio_n := -1
	for id: String in amarillas:
		if limpio_n < 0 or int(amarillas[id]) < limpio_n:
			limpio_n = int(amarillas[id])
			limpio_id = id
	acta["fairplay"] = _nombre_club(limpio_id)
	acta["fairplay_es_mio"] = limpio_id == mio.id

	## CLUB MÁS POPULAR Y MEJOR HINCHADA. La popularidad es la reputación; la
	## hinchada la ganas tú si la tienes contenta, y si no se la lleva uno de los
	## grandes. El sorteo va por `Azar` a propósito: con el azar de Godot la
	## misma semilla dejaría de dar la misma gala.
	var grandes: Array[Club] = []
	for c: Club in mundo.clubes.values():
		if c.pais == mio.pais and c.division == 1:
			grandes.append(c)
	grandes.sort_custom(func(a: Club, b: Club) -> bool: return a.rep > b.rep)
	acta["popular"] = grandes[0].nombre if not grandes.is_empty() else "—"
	var hinchada: Club = mio
	if mio.confianza < 78 and not grandes.is_empty():
		hinchada = grandes[Azar.ent(0, mini(3, grandes.size() - 1))]
	acta["hinchada"] = hinchada.nombre
	acta["hinchada_es_mia"] = hinchada == mio

	## MEJOR ESTADIO: el de más aforo. Empatado gana el tuyo, como en el HTML.
	var mejor_ajeno := 0
	for c in grandes:
		if c != mio:
			mejor_ajeno = maxi(mejor_ajeno, c.estadio_aforo)
	acta["estadio_es_mio"] = mio.estadio_aforo >= mejor_ajeno
	acta["estadio"] = "Estadio de %s" % (mio.nombre if acta["estadio_es_mio"] else _mayor_aforo(grandes, mio))

	## QUÉ SE LLEVA TU CLUB. Es la lista que se lee en voz alta, y por eso se
	## arma aquí y no en la interfaz: el acta tiene que poder contarse sola.
	var ganados: Array[String] = []
	if bool(acta["dt_es_mio"]):
		ganados.append("Mejor entrenador del año")
	if bool(acta["fairplay_es_mio"]):
		ganados.append("Premio Fair Play")
	if bool(acta["hinchada_es_mia"]):
		ganados.append("Mejor hinchada")
	if bool(acta["estadio_es_mio"]):
		ganados.append("Estadio del año")
	if joven != null and joven.club_id == mio.id:
		ganados.append("Mejor joven: %s" % Nombres.visible(joven.nombre))
	var mios_en_ideal := 0
	for j in ideal:
		if j.club_id == mio.id:
			mios_en_ideal += 1
	if mios_en_ideal > 0:
		ganados.append("%d jugador(es) en el equipo ideal" % mios_en_ideal)
	acta["ganados"] = ganados

	premios.push_front(acta)
	while premios.size() > MAX_PREMIOS:
		premios.pop_back()
	_archivar_plantel(mi_puesto)
	premios_entregados.emit(acta)
	return acta

## El cierre completo de la temporada desde el lado del reconocimiento: la
## experiencia por haberla aguantado entera, la gala y el repaso de logros.
##
## Se llama DESPUÉS de que la liga haya terminado y ANTES de `Mundo.
## nueva_temporada()`, que es donde se ponen los goles y los partidos a cero. Al
## revés, la gala premiaría a once jugadores con cero partidos jugados.
func cerrar_temporada() -> Dictionary:
	sumar_xp(XP_TEMPORADA)
	var acta := premios_temporada()
	revisar()
	return acta

# ---------------------------------------------------------------------------
#  CONSULTAS Y GUARDADO
# ---------------------------------------------------------------------------

## El cara a cara con un rival, para la previa del partido.
func cara_a_cara(rival: Club) -> Dictionary:
	return h2h.get(rival.id, {"pj": 0, "pg": 0, "pe": 0, "pp": 0, "gf": 0, "gc": 0})

func rivalidad_con(rival: Club) -> int:
	var h := cara_a_cara(rival)
	var pj := int(h["pj"])
	if pj == 0:
		return 0
	## Base por historia compartida: seis puntos por partido, con techo. Dos
	## equipos que llevan veinte años cruzándose ya se tienen ganas.
	var v := mini(45, pj * 6)
	## Las derrotas pesan el doble que las victorias: lo que enciende una
	## rivalidad es lo que te han hecho, no lo que has hecho tú.
	v += int(h["pp"]) * 5 + int(h["pg"]) * 2
	## Y las goleadas encajadas, aparte: hay derrotas que no se olvidan.
	var dif := int(h["gc"]) - int(h["gf"])
	if dif > 0:
		v += mini(15, dif * 2)
	## El clásico de origen entra ya encendido: no hace falta jugar nada para
	## que un derbi de toda la vida sea un derbi de toda la vida.
	var m := mundo
	if m != null and m.mi_club() != null and m.es_clasico(m.mi_club(), rival):
		v += 30
	return clampi(v, 0, 100)

func nivel_rivalidad(v: int) -> String:
	for fila: Array in NIVELES_RIVALIDAD:
		if v >= int(fila[0]):
			return String(fila[1])
	return "Roce menor"

## Los rivales ordenados por cuánto se les tiene ganas. Solo los que existen:
## un club que desapareció del mundo no es un rival, es un recuerdo.
func rivalidades() -> Array[Dictionary]:
	var m := mundo
	var salida: Array[Dictionary] = []
	if m == null:
		return salida
	for id: String in h2h:
		if not m.clubes.has(id):
			continue
		var c: Club = m.clubes[id]
		var v := rivalidad_con(c)
		if v <= 0:
			continue
		salida.append({"club": c, "valor": v, "nivel": nivel_rivalidad(v), "h2h": cara_a_cara(c)})
	salida.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return int(a["valor"]) > int(b["valor"]))
	return salida

func goleadores_historicos(cuantos_max: int = 10) -> Array[Dictionary]:
	var lista: Array[Dictionary] = []
	var goles: Dictionary = rec.get("goles", {})
	for nombre: String in goles:
		lista.append({"nombre": nombre, "goles": int(goles[nombre])})
	lista.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return int(a["goles"]) > int(b["goles"]))
	return lista.slice(0, cuantos_max)

## Los que más veces se han puesto la camiseta.
func mas_partidos(cuantos_max: int = 10) -> Array[Dictionary]:
	var lista: Array[Dictionary] = []
	var pj: Dictionary = rec.get("pj", {})
	for id: String in pj:
		lista.append({"nombre": String(pj[id]["nombre"]), "partidos": int(pj[id]["n"])})
	lista.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return int(a["partidos"]) > int(b["partidos"]))
	return lista.slice(0, cuantos_max)

## Los máximos goleadores de la historia de tu era, de más a menos.
## `vMemoria()` del HTML: el SALÓN DE LA FAMA. No hace falta guardar una lista
## aparte -sería otro sitio más que mantener al día-: se deduce de lo que ya se
## lleva anotado. Entra quien deje huella por cualquiera de las tres vías, que
## son las tres formas de ser recordado en un club:
##   · goles     — el que llenó la red
##   · partidos  — el que estuvo siempre
##   · títulos   — el que estaba en el once el día que se levantó algo
func salon_de_la_fama(cuantos_max: int = 12) -> Array[Dictionary]:
	var puntos := {}
	var motivos := {}
	for f: Dictionary in goleadores_historicos(50):
		var n := String(f["nombre"])
		puntos[n] = int(puntos.get(n, 0)) + int(f["goles"]) * 3
		motivos[n] = "%d goles" % int(f["goles"])
	for f2: Dictionary in mas_partidos(50):
		var n2 := String(f2["nombre"])
		puntos[n2] = int(puntos.get(n2, 0)) + int(f2["partidos"])
		var antes := String(motivos.get(n2, ""))
		motivos[n2] = "%s%d partidos" % [antes + " · " if antes != "" else "", int(f2["partidos"])]
	## Estar en el once de un título pesa mucho: es lo que separa a un buen
	## jugador de uno que la gente recuerda.
	var titulos := {}
	for entrada: Dictionary in muro:
		for nombre in entrada.get("once", []):
			var n3 := String(nombre)
			puntos[n3] = int(puntos.get(n3, 0)) + 120
			titulos[n3] = int(titulos.get(n3, 0)) + 1
	var salida: Array[Dictionary] = []
	for n4: String in puntos:
		var m := String(motivos.get(n4, ""))
		if titulos.has(n4):
			var t := int(titulos[n4])
			m = "%s%d título%s" % [m + " · " if m != "" else "", t, "" if t == 1 else "s"]
		salida.append({"nombre": n4, "puntos": int(puntos[n4]), "motivo": m, "titulos": int(titulos.get(n4, 0))})
	salida.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return int(a["puntos"]) > int(b["puntos"]))
	return salida.slice(0, cuantos_max)

## La memoria entera, para meterla en el guardado. El perfil de gestor NO va
## aquí: es de la persona, no de la partida, y vive en su propio fichero.
func a_dic() -> Dictionary:
	return {
		"anio_inicio": anio_inicio,
		"desbloqueados": desbloqueados,
		"h2h": h2h,
		"rachas": rachas,
		"rec": rec,
		"efemerides": efemerides,
		"muro": muro,
		"planteles": planteles,
		"premios": premios,
		"cantera": canteranos_debutados,
		"ocultos": ocultos.duplicate(),
		"marcas": marcas.duplicate(),
		"ya_estaban": _ya_estaban,
	}

func desde_dic(d: Dictionary) -> void:
	anio_inicio = int(d.get("anio_inicio", anio_inicio))
	desbloqueados = d.get("desbloqueados", {})
	h2h = d.get("h2h", {})
	## Las rachas se copian clave a clave y no de golpe: un guardado viejo al que
	## le falte una racha dejaría el diccionario incompleto y `_anotar_rachas`
	## sumaría sobre un valor que no existe.
	var r: Dictionary = d.get("rachas", {})
	for k: String in rachas:
		rachas[k] = int(r.get(k, 0))
	rec = d.get("rec", {"goles": {}, "pj": {}})
	if not rec.has("goles"):
		rec["goles"] = {}
	if not rec.has("pj"):
		rec["pj"] = {}
	efemerides = d.get("efemerides", [])
	muro = d.get("muro", [])
	planteles = d.get("planteles", [])
	premios = d.get("premios", [])
	canteranos_debutados = d.get("cantera", {})
	ocultos = (d.get("ocultos", {}) as Dictionary).duplicate()
	marcas = (d.get("marcas", {}) as Dictionary).duplicate()
	_ya_estaban = d.get("ya_estaban", {})
	_plantilla_anotada = not _ya_estaban.is_empty()

# ---------------------------------------------------------------------------
#  EL MUSEO DEL CLUB (`vMemoria()`)
# ---------------------------------------------------------------------------
#
# `Instalaciones` deja construir un museo y cobra ingresos por él desde el
# porte, pero el museo no tenía CONTENIDO: se podía pagar un edificio cuyo
# interior no existía en ninguna pantalla.
#
# Las piezas no se guardan aparte. Se DEDUCEN de lo que el club ya tiene
# anotado —trofeos, récords, leyendas, canteranos—, igual que el salón de la
# fama. Guardar una lista paralela sería otro sitio más que mantener al día y
# que se puede desincronizar de la realidad.

## Cuántas piezas hay y cuáles. Cada una es {icono, titulo, detalle}.
func piezas_del_museo() -> Array[Dictionary]:
	var salida: Array[Dictionary] = []
	## Los títulos: una vitrina por cada uno, con el año y el once que lo ganó.
	for e: Dictionary in muro:
		var once: Array = e.get("once", [])
		salida.append({
			"icono": "🏆",
			"titulo": "%s %d" % [String(e.get("titulo", "")), int(e.get("anio", 0))],
			"detalle": "La camiseta de %s, enmarcada." % (String(once[0]) if not once.is_empty() else "aquel equipo"),
		})
	## Los récords del club, que son las noches que nadie olvida.
	if rec.has("mayor_goleada"):
		var g: Dictionary = rec["mayor_goleada"]
		salida.append({"icono": "⚽", "titulo": "La mayor goleada",
			"detalle": "%s ante %s, en %d. El marcador original del estadio." % [
				String(g.get("marcador", "")), String(g.get("rival", "")), int(g.get("anio", 0))]})
	if rec.has("mas_publico"):
		var p: Dictionary = rec["mas_publico"]
		salida.append({"icono": "🎟️", "titulo": "El récord de público",
			"detalle": "%d personas contra %s. La entrada número uno de aquel día." % [
				int(p.get("n", 0)), String(p.get("rival", ""))]})
	## Los máximos goleadores de la era: sus botas.
	for f: Dictionary in goleadores_historicos(3):
		salida.append({"icono": "👟", "titulo": "Las botas de %s" % String(f["nombre"]),
			"detalle": "%d goles con esta camiseta." % int(f["goles"])})
	## Y los que más veces se la pusieron.
	for f2: Dictionary in mas_partidos(3):
		salida.append({"icono": "🧣", "titulo": "El brazalete de %s" % String(f2["nombre"]),
			"detalle": "%d partidos. Se lo llevó puesto media vida." % int(f2["partidos"])})
	return salida

## El once histórico contra el actual: el "comparador de generaciones" de
## `vMemoria()`. No compara jugadores uno a uno -eso sería inventarse datos de
## gente retirada- sino la MEDIA del mejor plantel que has tenido contra la del
## de ahora, que es la pregunta que de verdad se hace uno.
func comparador_de_generaciones() -> Dictionary:
	if planteles.is_empty() or mundo == null or mundo.mi_club() == null:
		return {}
	var mejor: Dictionary = {}
	var mejor_puesto := 99
	for p: Dictionary in planteles:
		var puesto := int(p.get("puesto", 99))
		if puesto < mejor_puesto:
			mejor_puesto = puesto
			mejor = p
	if mejor.is_empty():
		return {}
	var c := mundo.mi_club()
	var actual := 0.0
	var n := 0
	for j in c.plantilla:
		actual += float(j.ovr)
		n += 1
	return {
		"anio": int(mejor.get("anio", 0)),
		"puesto": mejor_puesto,
		"mvp": String(mejor.get("mvp", "")),
		"jugadores": mejor.get("jugadores", []),
		"media_actual": actual / float(maxi(1, n)),
	}
