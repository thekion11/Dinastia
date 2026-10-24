extends "res://nucleo/cantera_p1.gd"
## [Capa 2/4 de `cantera.gd`] _hijos_del_dt, _sortear_hermano, camada_anual, _sortear_nombre, _nombre_al_azar, sembrar_leyendas … (+16)

func _hijos_del_dt() -> void:
	var m := _mundo()
	if m == null or m.mi_club() == null or m.vida == null:
		return
	var perfil: Dictionary = m.vida.perfil
	if perfil.is_empty():
		return
	if not perfil.has("anio0"):
		perfil["anio0"] = m.anio
	var mio := m.mi_club()
	var apellido := _apellido_de(m.roles.nombre if m.roles != null else "Míster")
	for h: Dictionary in perfil.get("hijos", []):
		if bool(h.get("cantera", false)) or not (String(h.get("nombre", "")) in HIJOS_FUTBOLISTAS):
			continue
		var edad := int(h.get("edad", 0)) + m.anio - int(perfil["anio0"])
		if edad < 16 or mio.plantilla.size() >= TOPE_PLANTEL:
			continue
		h["cantera"] = true
		var grupo := String(Azar.uno(["DEF", "MED", "DEL"]))
		var j := m.crear_jugador(mio, grupo, demarcacion_de(grupo), 16, mio.rep - 22 + Azar.ent(0, 6))
		j.nombre = "%s %s" % [String(h["nombre"]), apellido]
		j.pot = clampi(mio.rep + Azar.ent(-2, 14), j.ovr + 6, 95)
		j.generar_atributos()
		j.tasar()
		var f := _ficha(j.id)
		f["camada"] = m.anio
		f["linaje"] = {"padre": m.roles.nombre if m.roles != null else "", "club": mio.nombre, "nivel": j.pot,
			"padre_en_club": true, "pedido": false, "propio": true}
		j.dorsal = _dorsal_libre(mio)
		mio.plantilla.append(j)
		noticia.emit("👨‍👦 Tu hijo entra en la cantera",
			"%s cumplió 16 y firma por la cantera de %s. En el vestuario ya le llaman «el hijo del míster»; decidir si juega o no es cosa tuya." % [j.nombre, mio.nombre])


# ===========================================================================
#  HERMANOS Y GEMELOS
# ===========================================================================

## De vez en cuando sube el hermano de alguien que ya está. Es el mismo material
## que el linaje —familias dentro del club— pero en horizontal, y da la única
## pareja del juego que se entiende sin mirarse: los gemelos.
func _sortear_hermano(mio: Club) -> void:
	var m := _mundo()
	if m == null or mio == null or not Azar.suerte(0.30):
		return
	if mio.plantilla.size() >= TOPE_PLANTEL:
		return
	var candidatos: Array[Jugador] = []
	for j in mio.plantilla:
		if j.edad <= 23 and String(_fichas.get(j.id, {}).get("hermano", "")) == "":
			candidatos.append(j)
	if candidatos.is_empty():
		return
	var base: Jugador = Azar.uno(candidatos)
	var gemelos := Azar.suerte(0.22)
	var edad := base.edad if gemelos else clampi(base.edad + Azar.ent(-3, 3), 16, 24)
	var ovr := base.ovr + (Azar.ent(-2, 2) if gemelos else Azar.ent(-8, 6))
	var grupo := grupo_con_tope(mio, base.pos)
	var demarcacion := base.pos_e if gemelos and grupo == base.pos else demarcacion_de(grupo)
	var j := m.crear_jugador(mio, grupo, demarcacion, edad, ovr)
	j.nombre = "%s %s" % [_nombre_de_pila(base.pais), _apellido_de(base.nombre)]
	j.pais = base.pais
	## Un gemelo no es un jugador parecido: es el mismo jugador con tres puntos
	## de margen por atributo. Si se le generan los atributos al azar, la gracia
	## se pierde y solo queda el apellido repetido.
	if gemelos:
		for k: String in base.atributos:
			j.atributos[k] = clampi(int(base.atributos[k]) + Azar.ent(-3, 3), 22, 99)
	j.tasar()
	_ficha(j.id)["hermano"] = base.id
	_ficha(j.id)["gemelo"] = gemelos
	_ficha(base.id)["hermano"] = j.id
	_ficha(base.id)["gemelo"] = gemelos
	j.dorsal = _dorsal_libre(mio)
	mio.plantilla.append(j)
	hermano_en_casa.emit(j, base, gemelos)
	if gemelos:
		noticia.emit("Llegan los gemelos %s" % _apellido_de(base.nombre),
			"El club incorpora a %s, hermano gemelo de %s. Se parecen tanto que el utilero ya se equivocó dos veces." % [j.nombre, base.nombre])
	else:
		noticia.emit("Un hermano más en el plantel",
			"%s (%d años, %s) sube al primer equipo. Es hermano de %s: jugar juntos les da un plus." % [j.nombre, j.edad, j.pos_e, base.nombre])


# ===========================================================================
#  LA CAMADA ANUAL
# ===========================================================================

## La camada de juveniles de la temporada, más los hijos de leyenda que tocaban
## este año y el hermano que aparece de vez en cuando.
##
## Se llama al empezar una temporada, DESPUÉS de los retiros y de la reposición
## automática. Ese orden importa: si llegara antes, los chicos de la camada
## contarían para el plan de plantilla y `Mundo._subir_de_cantera()` no repondría
## el lateral izquierdo que acaba de colgar las botas.
##
## Devuelve los chicos de TU club, que son los únicos que alguien va a mirar.
func camada_anual() -> Array[Jugador]:
	var m := _mundo()
	var salida: Array[Jugador] = []
	if m == null:
		return salida
	var mio := m.mi_club()
	ultima_camada.clear()
	if mio != null:
		salida = _camada_de(mio)
		for j in salida:
			ultima_camada.append(j.id)
		if not salida.is_empty():
			camada_lista.emit(salida)
			noticia.emit("Llega la camada juvenil",
				"%d chicos suben de la academia a la plantilla. Están verdes y ese es el trato: mira la proyección, no la media." % salida.size())
		else:
			noticia.emit("La academia se queda sin cupo",
				"Este año no sube nadie de la cantera: el plantel tiene %d fichas y no caben más. Dar salidas también es formar." % mio.plantilla.size())
	_hijos_de_leyendas()
	_hijos_del_dt()
	_sortear_hermano(mio)
	return salida

func _sortear_nombre(pais: String, region: String = "") -> String:
	var a: Array = Datos.tabla("APELLIDOS")
	var pools: Variant = Datos.tabla("POOLS_EU")
	var propias := Regiones.bolsas(pais, region)
	if not propias.is_empty():
		return "%s %s" % [String(Azar.uno(propias[0])), String(Azar.uno(propias[1]))]
	if pools is Dictionary and (pools as Dictionary).has(pais):
		var par: Array = (pools as Dictionary)[pais]
		if par.size() >= 2 and not (par[1] as Array).is_empty():
			a = par[1]
	elif pais == "BRA":
		var ab: Variant = Datos.tabla("APELLIDOS_BRA")
		if ab is Array and not (ab as Array).is_empty():
			a = ab
	if a is Array and not (a as Array).is_empty():
		return "%s %s" % [_nombre_de_pila(pais), String(Azar.uno(a))]
	return _nombre_de_pila(pais)

## Nunca devuelve el nombre de un futbolista real (`Nombres.vetado()`).
func _nombre_al_azar(pais: String = "", region: String = "") -> String:
	return Nombres.sin_vetar(func() -> String: return _sortear_nombre(pais, region))


# ===========================================================================
#  LINAJE: LOS HIJOS DE TUS LEYENDAS
# ===========================================================================
#
# Es la idea central del juego y la razón por la que una partida dura décadas.
# El delantero que te dio el título en 2029 se retira, entra en el libro de
# leyendas, y entre cuatro y nueve años después llega a una cantera —la tuya con
# un 70% de probabilidad, la de otro con el resto— un chico con su apellido y
# parte de su talento. La prensa se lo cuelga antes de que toque una pelota.

## Siembra leyendas inventadas al empezar la partida. Sin esto, el primer hijo de
## leyenda llegaría en la décima temporada y quien juegue tres años no sabría que
## el sistema existe.
func sembrar_leyendas(cuantas: int = LEYENDAS_SEMILLA) -> void:
	var m := _mundo()
	if m == null or m.clubes.is_empty():
		return
	var ids: Array = m.clubes.keys()
	for i in cuantas:
		var club_id := String(Azar.uno(ids))
		var club_leyenda: Club = m.clubes.get(club_id)
		leyendas.append({
			"nombre": _nombre_al_azar(club_leyenda.pais if club_leyenda != null else ""),
			"club_id": club_id,
			"pos": String(Azar.uno(["POR", "DEF", "MED", "MED", "DEL", "DEL"])),
			"nivel": Azar.ent(78, 93),
			"anio_hijo": m.anio + Azar.ent(0, 6),
			"usado": false,
		})

## El linaje del chico: de quién es hijo, de qué club era su padre y a qué nivel
## llegó. Vacío si es un jugador sin apellido que pese.
func linaje_de(j: Jugador) -> Dictionary:
	return _fichas.get(j.id, {}).get("linaje", {}) if j != null else {}

## Apunta a un retirado en el libro de leyendas. Se llama al cerrar la temporada,
## por cada jugador que cuelga las botas.
##
## Entran los que tenían media de figura y TAMBIÉN los que ya eran hijos de
## alguien: así el apellido salta de generación en generación y una partida larga
## acaba teniendo dinastías de verdad, que es de donde sale el nombre del juego.
func registrar_retiro(j: Jugador, club: Club) -> bool:
	var m := _mundo()
	if j == null or m == null:
		return false
	if j.ovr < MEDIA_DE_LEYENDA and linaje_de(j).is_empty():
		return false
	leyendas.append({
		"nombre": j.nombre,
		"club_id": j.club_id,
		"pos": j.pos,
		"nivel": j.ovr,
		"anio_hijo": m.anio + 1 + Azar.ent(2, 8),
		"usado": false,
	})
	if club != null and club.id == m.mi_club_id:
		noticia.emit("Se retira una figura",
			"%s cuelga las botas. Queda inscrito entre las leyendas del club… y quién sabe si algún día llega un hijo suyo a la cantera." % j.nombre)
	return true

## El árbol genealógico del club: familias de linaje y parejas de hermanos, para
## poder enseñarlas juntas en una pantalla en vez de como jugadores sueltos.
func familias() -> Dictionary:
	var m := _mundo()
	var fams := {}
	if m == null:
		return fams
	for c: Club in m.clubes.values():
		for j in c.plantilla:
			var f: Dictionary = _fichas.get(j.id, {})
			if f.is_empty():
				continue
			var clave := ""
			var lin: Dictionary = f.get("linaje", {})
			if not lin.is_empty():
				clave = "L:%s" % String(lin.get("padre", ""))
			elif String(f.get("hermano", "")) != "":
				var par := [j.id, String(f["hermano"])]
				par.sort()
				clave = "H:%s-%s" % [par[0], par[1]]
			if clave == "":
				continue
			if not fams.has(clave):
				fams[clave] = []
			(fams[clave] as Array).append(j)
	return fams

## El bono de hermanos NO vive aquí. Vivía, y era un duplicado muerto: la copia
## viva es `Vestuario.bonus_hermanos()`, que es la que llama `Vestuario.factores()`
## y por tanto la única que llega al partido. Esta de aquí no la invocaba nadie y
## se borró para que nadie la "arregle" un día creyendo que hace algo.


# ===========================================================================
#  QUIÉN ESTÁ LISTO PARA SUBIR
# ===========================================================================

## Los juveniles de un club, del que más proyección al que menos. Ordenar por
## potencial y no por media es deliberado: en esta pantalla no importa quién es
## mejor hoy, importa quién va a serlo.
func juveniles(c: Club, edad_max: int = EDAD_CANTERANO) -> Array[Jugador]:
	var salida: Array[Jugador] = []
	if c == null:
		return salida
	for j in c.plantilla:
		if j.edad <= edad_max:
			salida.append(j)
	salida.sort_custom(func(a: Jugador, b: Jugador) -> bool: return a.pot > b.pot)
	return salida

func _jugador(c: Club, pid: String) -> Jugador:
	if pid == "" or c == null:
		return null
	for j in c.plantilla:
		if j.id == pid:
			return j
	return null

## La camada de este año, ya como jugadores. Es lo que enseña el menú al empezar
## la temporada; se guarda por id para que sobreviva a que vendas a uno de ellos.
func camada_actual() -> Array[Jugador]:
	var m := _mundo()
	var salida: Array[Jugador] = []
	if m == null or m.mi_club() == null:
		return salida
	for id in ultima_camada:
		var j := _jugador(m.mi_club(), id)
		if j != null:
			salida.append(j)
	return salida

## ¿Está listo para el primer equipo? La media tiene que llegar a `rep - 14`.
##
## Es el mismo umbral que usa `Roles.subir_al_primer_equipo()` para decidir si el
## debut es una fiesta o un escarmiento. Aquí existe para poder DECIRLO antes: el
## botón que avisa «aún verde» es lo que convierte la promoción en una decisión.
func listo_para_debutar(j: Jugador) -> bool:
	var m := _mundo()
	if j == null or m == null:
		return false
	var mio := m.mi_club()
	return mio != null and j.ovr >= mio.rep - MARGEN_DEBUT

## La media que le falta al chico para estar listo, o 0 si ya lo está.
func le_falta_para_debutar(j: Jugador) -> int:
	var m := _mundo()
	if j == null or m == null or m.mi_club() == null:
		return 0
	return maxi(0, (m.mi_club().rep - MARGEN_DEBUT) - j.ovr)

## Los que hoy podrían subir sin quemarse. Es la lista que se le pone delante al
## director de cantera cuando el club le pide debutantes.
func candidatos_a_debutar() -> Array[Jugador]:
	var m := _mundo()
	if m == null:
		return []
	var salida: Array[Jugador] = []
	for j in juveniles(m.mi_club()):
		if listo_para_debutar(j):
			salida.append(j)
	return salida

## Las categorías inferiores por edad (Sub-15, Sub-17, Sub-20), tal como las
## define la tabla CATEGORIAS del HTML.
func categoria_de(j: Jugador) -> String:
	var cats: Variant = Datos.tabla("CATEGORIAS")
	if j == null or not (cats is Array):
		return ""
	for fila: Array in cats:
		if j.edad >= int(fila[2]) and j.edad <= int(fila[3]):
			return String(fila[0])
	return ""

## clave de categoría -> [nombre visible, jugadores]. Lo pide la pantalla de
## categorías inferiores, que es donde se ven las becas y las fugas.
func por_categoria(c: Club) -> Dictionary:
	var salida := {}
	var cats: Variant = Datos.tabla("CATEGORIAS")
	if not (cats is Array):
		return salida
	for fila: Array in cats:
		salida[String(fila[0])] = {"nombre": String(fila[1]), "jugadores": []}
	if c == null:
		return salida
	for j in c.plantilla:
		var k := categoria_de(j)
		if k != "" and salida.has(k):
			(salida[k]["jugadores"] as Array).append(j)
	return salida


# ===========================================================================
#  QUE NO TE LOS ROBEN: BECAS Y FUGAS
# ===========================================================================

## Lo que cuesta una beca en este club. Cubre estudios, alojamiento y comida.
func coste_beca() -> int:
	var m := _mundo()
	var rep := 70.0
	if m != null and m.mi_club() != null:
		rep = float(m.mi_club().rep)
	return Eco.escalar(COSTE_BECA, rep)

func tiene_beca(j: Jugador) -> bool:
	return j != null and bool(_fichas.get(j.id, {}).get("beca", false))

## Beca a un chico. Devuelve "" si se pudo, o el motivo por el que no.
func becar(j: Jugador) -> String:
	var m := _mundo()
	if m == null or j == null:
		return "no hay partida"
	var mio := m.mi_club()
	if mio == null or j.club_id != mio.id:
		return "ese chico no es del club"
	if tiene_beca(j):
		return "ya tiene beca"
	var coste := coste_beca()
	if coste > mio.saldo:
		return "no hay caja: cuesta %d y tienes %d" % [coste, mio.saldo]
	mio.mover_saldo(-coste)
	movimiento.emit("Beca deportiva: %s" % j.nombre, -coste)
	_ficha(j.id)["beca"] = true
	j.cambiar_moral(14, "Cantera")
	noticia.emit("Beca para %s" % j.nombre,
		"El club le paga estudios, alojamiento y comida. Se queda tranquilo y es mucho más difícil que se lo lleven.")
	return ""

## La probabilidad semanal de que un grande se lleve a este chico gratis.
##
## Sube con el TECHO SIN CUMPLIR (`pot - ovr`): al que promete y todavía no
## rinde es a quien vienen a buscar, no al que ya juega. Baja con la residencia
## y la sala de juegos —que es lo que mide `Instalaciones.retencion_juvenil()`—
## y con la beca. El HTML restaba nivel a nivel; aquí se usa el bonificador que
## ya existe en vez de inventar otro, y se aplica como fracción del riesgo.
func riesgo_fuga(j: Jugador) -> float:
	var m := _mundo()
	if j == null or m == null or j.edad > EDAD_JUVENIL or j.club_id != m.mi_club_id:
		return 0.0
	var r := 0.02 + float(j.pot - j.ovr) * 0.002
	if m.obras != null:
		r *= 1.0 - m.obras.retencion_juvenil()
	if tiene_beca(j):
		r -= 0.02
	if j.moral < 45:
		r += 0.02
	return clampf(r, 0.0, 0.09)

## Quién viene a robarte: uno de los seis clubes más grandes que el tuyo por al
## menos seis puntos de reputación. No el mayor de todos siempre, porque eso
## haría que el mismo club te vaciara la cantera veinte años seguidos.
## Solo un grande CON SITIO: menos de 26 y, si el chico es portero, menos de
## tres porteros. Sin esto la prueba larga encontró un club con 51 jugadores y
## 8 porteros: se quedaba todos los canteranos que se escapaban.
func _grande_que_se_lo_lleva(m: Mundo, mio: Club, j: Jugador = null) -> Club:
	var grandes: Array[Club] = []
	for c: Club in m.clubes.values():
		if c.id == mio.id or c.rep < mio.rep + 6 or c.plantilla.size() >= TOPE_PLANTEL:
			continue
		if j != null and j.es_portero() and c.plantilla.filter(func(x: Jugador) -> bool: return x.es_portero()).size() >= 3:
			continue
		grandes.append(c)
	if grandes.is_empty():
		return null
	grandes.sort_custom(func(a: Club, b: Club) -> bool: return a.rep > b.rep)
	return grandes[mini(Azar.ent(0, 5), grandes.size() - 1)]
