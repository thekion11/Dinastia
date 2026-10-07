class_name Reales
extends RefCounted
## "PLANTILLAS REALES" (v2.3 del HTML, `REALES`/`aplicarReales()`), que no
## tenía NINGÚN equivalente en Godot: la tabla ya estaba exportada entera en
## `datos/tablas.json` -813 futbolistas reales, repartidos por decenas de
## clubes de verdad- y ninguna clase la leía. Cada club generado terminaba con
## once nombres inventados, incluso cuando el HTML le pone a Colo-Colo su
## plantel real con Vidal, De Paul, Pizarro...
##
## Vuelca la lista sobre el mundo YA generado, sustituyendo -no añadiendo- a
## los jugadores generados más flojos de cada puesto: mismo tamaño de plantel,
## solo que una parte de los nombres pasa a ser gente real. `Jugador.real`
## marca a quién se le tocó, y es la puerta para engancharle después una foto
## de verdad en vez de la cara procedural de `Cara.gd`.
##
## Desde el 25-9-2026 el nombre pasa por `Nombres.de_tabla()`: con el pack real
## activo se guarda cubierto ("Artur0 Vidal"), no en claro.
##
## Desde el 26-9-2026 la BASE FICTICIA también trae la tabla, con nombres de
## guiño ("Arturo Bedal") generados por `herramientas/jugadores_guino.py`: los
## mismos puestos, edades, medias y países que el pack, así los jugadores son
## fijos en todas las partidas y se reconoce a quién representan.

## Las claves de `REALES` están en leetspeak ("C0lo-C0lo") porque así quedaron
## escritas en el JSON exportado, igual que el resto de nombres de club; hay
## que decensurarlas una vez para poder comparar contra `Club.nombre`, que ya
## vive en texto claro desde que `Mundo._crear_club()` lo decensura al crear
## el club.
static var _indice: Dictionary = {}
static var _indice_listo := false

## `Datos.usar_base_real()` la llama al cambiar de base: el índice se arma con
## la tabla `REALES` (con guiños en la base ficticia y en claro con el pack).
static func invalidar() -> void:
	_indice = {}
	_indice_listo = false

static func _indice_de() -> Dictionary:
	if not _indice_listo:
		_indice = {}
		var tabla: Variant = Datos.tabla("REALES")
		if tabla is Dictionary:
			for clave: String in (tabla as Dictionary):
				_indice[Nombres.limpiar(clave)] = (tabla as Dictionary)[clave]
		_indice_listo = true
	return _indice

## Vuelca las plantillas reales sobre el mundo ya generado. Devuelve cuántos
## jugadores reales se aplicaron en total, para poder comprobarlo desde el
## banco de pruebas sin contar a mano.
static func aplicar(mundo: Mundo) -> int:
	var idx := _indice_de()
	if idx.is_empty():
		return 0
	var posd: Variant = Datos.tabla("POSD")
	if not (posd is Dictionary):
		return 0
	var total := 0
	for club: Club in mundo.clubes.values():
		var lista: Variant = idx.get(Nombres.limpiar(club.nombre))
		if not (lista is Array) or (lista as Array).is_empty():
			continue
		total += _aplicar_en_club(club, lista as Array, posd as Dictionary)
	return total

static func _aplicar_en_club(club: Club, lista: Array, posd: Dictionary) -> int:
	var usados: Dictionary = {}
	var aplicados := 0
	for fila: Variant in lista:
		var partes := String(fila).split("|")
		if partes.size() < 4:
			continue
		## Con la cubierta activa el nombre se guarda ya cubierto (ver
		## `Nombres.de_tabla`); las fotos lo buscan limpiándolo.
		var nombre := Nombres.de_tabla(partes[0])
		var pos_e := partes[1] if posd.has(partes[1]) else "MC"
		var edad := int(partes[2]) if partes[2].is_valid_int() else 26
		var media := int(partes[3]) if partes[3].is_valid_int() else 70
		var pais := partes[4] if partes.size() > 4 and partes[4] != "" else club.pais
		var datos_pos: Dictionary = posd[pos_e]
		var grupo := String(datos_pos.get("g", "MED"))
		var demarcacion := String(datos_pos.get("d", grupo))

		## Primero de la MISMA demarcación, después del mismo grupo, y solo al
		## final cualquiera -si no, un lateral real aterrizaba encima de un
		## central generado y el club acababa con seis centrales, ningún carril
		## y las bandas cubiertas por gente de área-. Dentro de cada nivel, el
		## de media más baja aún libre.
		var candidato := _mas_flojo_libre(club.plantilla, usados, func(j: Jugador) -> bool:
			return String((posd.get(j.pos_e, {}) as Dictionary).get("d", "")) == demarcacion)
		if candidato == null:
			candidato = _mas_flojo_libre(club.plantilla, usados, func(j: Jugador) -> bool:
				return String((posd.get(j.pos_e, {}) as Dictionary).get("g", "")) == grupo)
		if candidato == null:
			candidato = _mas_flojo_libre(club.plantilla, usados, func(_j: Jugador) -> bool: return true)
		if candidato == null:
			break

		usados[candidato.id] = true
		candidato.nombre = nombre
		candidato.real = true
		candidato.pos_e = pos_e
		candidato.pos = grupo
		candidato.edad = clampi(edad, 15, 45)
		candidato.ovr = clampi(media, 40, 96)
		## FIJOS DE UNA PARTIDA A OTRA (26-9-2026, pedido: "en cada partida los
		## nombres cambian; deberían ser fijos, junto a sus medias"): el
		## potencial y los atributos de estos jugadores salen de su nombre, no
		## de la semilla del mundo. Se guarda el estado de `Azar`, se siembra con
		## el nombre y se devuelve tal cual: el resto del mundo no se entera.
		var estado: int = Azar._rng.state
		Azar._rng.seed = hash(Nombres.limpiar(nombre) + "|" + pos_e)
		## Los reales no dan el estirón de un canterano cualquiera: el margen es
		## más corto cuanto más veterano -igual que `aplicarReales()` del HTML-.
		var margen := 0
		if candidato.edad < 20:
			margen = Azar.ent(5, 14)
		elif candidato.edad < 23:
			margen = Azar.ent(2, 9)
		elif candidato.edad < 26:
			margen = Azar.ent(0, 5)
		candidato.pot = clampi(candidato.ovr + margen, candidato.ovr, 97)
		candidato.pais = pais
		candidato.generar_atributos()
		Azar._rng.state = estado
		candidato.tasar()
		aplicados += 1
	if aplicados > 0:
		_reescalar_generados(club)
	return aplicados

static func _mas_flojo_libre(plantilla: Array[Jugador], usados: Dictionary, filtro: Callable) -> Jugador:
	var mejor: Jugador = null
	for j: Jugador in plantilla:
		if usados.has(j.id) or not filtro.call(j):
			continue
		if mejor == null or j.ovr < mejor.ovr:
			mejor = j
	return mejor

## Un suplente inventado no puede salir mejor que el fondo de plantel real -el
## comentario del propio HTML lo explica mejor que ningún resumen: "un jugador
## de relleno no es una estrella, es fondo de plantilla"-. Se reescala el
## rango propio de los generados (el mejor generado sigue siendo el mejor
## generado) dentro de una banda por debajo del cuartil bajo de los reales, en
## vez de recortar con un clamp -que dejaría a once suplentes empatados en el
## techo, cantando tanto como el problema que se quiere evitar-.
static func _reescalar_generados(club: Club) -> void:
	var reales_ovr: Array[int] = []
	for j: Jugador in club.plantilla:
		if j.real:
			reales_ovr.append(j.ovr)
	if reales_ovr.size() < 6:
		return
	reales_ovr.sort()
	reales_ovr.reverse()
	var idx_cuartil := mini(reales_ovr.size() - 1, int(floor(float(reales_ovr.size()) * 0.75)))
	var ref_baja := reales_ovr[idx_cuartil]
	## La banda se anclaba SOLO a los reales (`ref_baja`), y eso aplastaba la
	## liga entera: al grande le hundía el fondo de plantel y al chico se lo
	## SUBÍA. Medido con semilla 777: Colo-Colo (rep 88) pasaba de 77,0 a 69,0 de
	## media y D. Limache (rep 67) de 55,8 a 61,5 -13,7 puntos de compresión que
	## se comían los 21 de diferencia de reputación, y por eso un rep 88 no era
	## más fuerte que un rep 67-.
	##
	## Ahora el techo respeta también lo que el club MERECE por reputación
	## (`rep - 9`, la misma referencia que usa `Mundo._poblar()`): el reescalado
	## puede bajar al que sobra, pero nunca subir al que no da la talla.
	## El suelo es 40, no 38: es el minimo que el resto del juego da por bueno
	## -`Jugador.tasar()` y el propio banco comprueban que ninguna media se sale
	## de [40,96]-. Con el techo anclado a la reputacion, un club chico podia
	## bajar hasta 38 y colar diez jugadores fuera de rango.
	var techo := maxi(44, mini(ref_baja - 1, club.rep - 9))
	var suelo := maxi(40, techo - 13)

	var generados: Array[Jugador] = []
	for j: Jugador in club.plantilla:
		if not j.real:
			generados.append(j)
	if generados.is_empty():
		return
	var g_max := generados[0].ovr
	var g_min := generados[0].ovr
	for j: Jugador in generados:
		g_max = maxi(g_max, j.ovr)
		g_min = mini(g_min, j.ovr)
	for j: Jugador in generados:
		var t := float(j.ovr - g_min) / float(g_max - g_min) if g_max > g_min else 0.5
		var nuevo := int(round(float(suelo) + t * float(techo - suelo)))
		if nuevo != j.ovr:
			j.ovr = nuevo
			j.pot = clampi(maxi(j.pot, j.ovr), j.ovr, 97)
			## SIN ESTO los atributos se quedaban en los del `ovr` VIEJO, y el
			## juego acababa mirando dos magnitudes distintas del mismo jugador:
			## `Club.once()` elige el once por `media_en(puesto)` -atributos- y
			## `Partido._media_linea()` puntúa por `ovr`. Un relleno bajado de 86
			## a 70 conservaba atributos de 86, así que ENTRABA al once por
			## delante de Vidal (78) y luego puntuaba como un 70.
			##
			## Colo-Colo salía al campo con nueve rellenos degradados y Vidal,
			## Cepeda, Pizarro y De Paul en el banco. Con esta línea su ataque
			## sube de 59,3 a 65,8.
			j.generar_atributos()
			j.tasar()
