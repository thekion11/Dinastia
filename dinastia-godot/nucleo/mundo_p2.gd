extends "res://nucleo/mundo_p1.gd"
## [Capa 2/9 de `mundo.gd`] tiene_desafio, _norm_nombre, es_clasico, mi_club, _demarcacion_al_azar, _bolsa_extra … (+12)

func tiene_desafio(k: String) -> bool:
	return desafios.has(k)

static func _norm_nombre(s: String) -> String:
	var limpio := Nombres.limpiar(s).to_lower()
	var salida := ""
	for i in limpio.length():
		var c := limpio.unicode_at(i)
		## a-z, ñ, y las vocales acentuadas que usa normNombre() en el HTML.
		if (c >= 97 and c <= 122) or c == 0xf1 or c == 0xe1 or c == 0xe9 or c == 0xed or c == 0xf3 or c == 0xfa or c == 0xfc:
			salida += limpio[i]
	return salida

## Los dos rivales son un clásico: el "big 3" chileno de siempre, o -para
## cualquier otro par de clubes grandes del mismo país- un hash estable de
## sus nombres, tal cual el HTML. No es una lista curada del resto del mundo
## porque no la hay: es la misma regla que decide en el HTML si Boca-River o
## Real Madrid-Barcelona son clásico, aplicada igual a cualquier país.
func es_clasico(a: Club, b: Club) -> bool:
	if a == null or b == null or a.pais != b.pais or a.id == b.id:
		return false
	## Los clásicos con nombre propio (Superclásico, Gran Derbi...) lo son
	## siempre, en la base ficticia y con el pack real.
	if HistoriaClub.nombre_clasico(a.nombre, b.nombre) != "":
		return true
	var n1 := _norm_nombre(a.nombre)
	var n2 := _norm_nombre(b.nombre)
	## Los tres grandes, con sus nombres reales y con los de la base ficticia
	## (sin los segundos, en la versión publicada no había clásico chileno).
	var grandes := ["colocolo", "udechile", "ucatolica", "lautarofc", "uandina", "precordillera"]
	if a.pais == "CHI" and grandes.has(n1) and grandes.has(n2):
		return true
	if a.rep + b.rep >= 164:
		var h1 := 0
		for i in n1.length():
			h1 += n1.unicode_at(i)
		var h2 := 0
		for i in n2.length():
			h2 += n2.unicode_at(i)
		return (h1 + h2) % 3 == 0
	return false

func mi_club() -> Club:
	return clubes.get(mi_club_id)

func _demarcacion_al_azar(grupo: String) -> String:
	var t: Variant = Datos.tabla("POS_POR_GRUPO")
	if t is Dictionary and (t as Dictionary).has(grupo):
		return String(Azar.uno(t[grupo]))
	return "MC"
static func _bolsa_extra(pais: String) -> Array:
	if _bolsas_extra.is_empty():
		var j: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://datos/bolsas_nombres.json"))
		_bolsas_extra = (j as Dictionary).get("bolsas", {"_": []}) if j is Dictionary else {"_": []}
	return _bolsas_extra.get(pais, _bolsas_extra.get("_GENERAL", [])) if pais != "" else _bolsas_extra.get("_GENERAL", [])

func _sortear_nombre(pais: String, region: String = "") -> String:
	var n: Array = Datos.tabla("NOMBRES")
	var a: Array = Datos.tabla("APELLIDOS")
	var pools: Variant = Datos.tabla("POOLS_EU")
	## España con su región (C3): bolsa general o vasca, ya no todos vascos.
	var propias := Regiones.bolsas(pais, region)
	if not propias.is_empty():
		n = propias[0]
		a = propias[1]
	elif pools is Dictionary and (pools as Dictionary).has(pais):
		var par: Array = (pools as Dictionary)[pais]
		if par.size() >= 2 and not (par[0] as Array).is_empty() and not (par[1] as Array).is_empty():
			n = par[0]
			a = par[1]
	elif pais == "BRA":
		var nb: Variant = Datos.tabla("NOMBRES_BRA")
		var ab: Variant = Datos.tabla("APELLIDOS_BRA")
		if nb is Array and not (nb as Array).is_empty() and ab is Array and not (ab as Array).is_empty():
			n = nb
			a = ab
	if n == null or a == null or n.is_empty() or a.is_empty():
		return "Jugador %d" % _seq_jugador
	## M-331: las bolsas de la base eran de 14×14; se suman las de
	## `datos/bolsas_nombres.json` (la vasca se deja tal cual: es un sabor).
	if region != "EUS":
		var extra := _bolsa_extra(pais)
		if not extra.is_empty():
			n = n + (extra[0] as Array)
			a = a + (extra[1] as Array)
	return "%s %s" % [Azar.uno(n), Azar.uno(a)]
func _nombre_al_azar(pais: String = "", region: String = "") -> String:
	if _nombres_usados.is_empty():
		for c: Club in clubes.values():
			for j: Jugador in c.plantilla:
				_nombres_usados[j.nombre] = true
	var nombre := ""
	for _i in 8:
		nombre = Nombres.sin_vetar(func() -> String: return _sortear_nombre(pais, region))
		if not _nombres_usados.has(nombre):
			break
	_nombres_usados[nombre] = true
	return nombre

func _rasgo_al_azar() -> String:
	## Que la mayoria no tenga rasgo es intencionado: si todos tienen uno, tener
	## uno deja de significar nada.
	if not Azar.suerte(0.34):
		return ""
	var r: Dictionary = Datos.tabla("RASGOS")
	if r == null or r.is_empty():
		return ""
	return String(Azar.uno(r.keys()))

func crear_jugador(c: Club, grupo: String, demarcacion: String, edad: int = -1, ovr: int = -1) -> Jugador:
	_seq_jugador += 1
	var j := Jugador.new()
	j.id = "j%d" % _seq_jugador
	j.club_id = c.id
	j.club_formacion = c.id
	j.pos = grupo
	j.pos_e = demarcacion
	j.pais = c.pais
	## En una plantilla fija la región no puede salir del id (depende de los
	## países cargados): sale del club y del orden dentro del plantel.
	var clave_region := j.id
	if _clave_fija != "":
		_n_fijo += 1
		clave_region = "%s%d" % [_clave_fija, _n_fijo]
	j.region = Regiones.region_para(c.pais, clave_region, c)
	j.nombre = _nombre_al_azar(c.pais, j.region)
	j.edad = edad if edad > 0 else Azar.ent(17, 35)
	j.ovr = clampi(ovr if ovr > 0 else c.rep - 9 + Azar.ent(-7, 7), 40, 96)
	## El techo: los muy jovenes pueden crecer mucho, a partir de los 25 lo que
	## hay es lo que hay. Es lo que convierte a un chico de media baja en un
	## fichaje interesante.
	var margen := Azar.ent(4, 18) if j.edad < 21 else (Azar.ent(0, 8) if j.edad < 25 else 0)
	j.pot = clampi(j.ovr + margen, j.ovr, 97)
	j.rasgo = _rasgo_al_azar()
	j.forma = Azar.ent(45, 70)
	j.moral = Azar.ent(55, 80)
	j.anios_contrato = Contratos.ajustar_anios(j, Azar.ent(1, 4))
	j.generar_atributos()
	j.tasar()
	## LAS HABILIDADES DE NACIMIENTO. `Entrenamiento.sortear_habilidades()`
	## existía -catálogo completo, más probabilidad cuanto mejor la media- y
	## nadie la llamaba nunca: ni un solo futbolista del mundo nacía con una
	## habilidad especial, todas se conseguían gastando puntos de
	## entrenamiento. Va aquí, con `ovr`/`pot` ya fijados -de eso depende
	## cuántas le tocan- y antes del `return`, así que cubre a los ~8.000 del
	## mundo generado Y a cada canterano o agente libre creado después.
	if entrenamiento != null:
		entrenamiento.sortear_habilidades(j)
	return j

## Los tres desafíos que se resuelven UNA vez, al empezar la partida -los
## otros (invicto, derbis, trotamundos) se comprueban jugando, más abajo en
## este archivo-. Se llama justo después de `tomar_el_mando()`.
##
## "Local" no deja a los extranjeros como agentes libres -el HTML sí, con su
## propia bolsa `G.libres`- porque aquí no existe ese concepto todavía: se
## sueltan sin más. Es una simplificación a propósito, no un olvido: el efecto
## que le importa al desafío -que tu plantel quede sin extranjeros- es idéntico.
func aplicar_desafios() -> void:
	var c := mi_club()
	if c == null or desafios.is_empty():
		return
	if tiene_desafio("pobreza"):
		c.saldo = int(round(Eco.ref_caja(float(c.rep)) * 0.04))
	if tiene_desafio("local"):
		var fuera := 0
		for j in c.plantilla.duplicate():
			if j.pais != c.pais:
				c.soltar(j)
				fuera += 1
		while c.plantilla.size() < 20:
			var grupo := String(Azar.uno(["POR", "DEF", "DEF", "MED", "MED", "DEL"]))
			var pos := _demarcacion_al_azar(grupo)
			var nv := crear_jugador(c, grupo, pos, Azar.ent(18, 28), c.rep - 10 + Azar.ent(-5, 5))
			nv.pais = c.pais

## Dorsales por jerarquia y brazalete al veterano de mas media. Son dos detalles
## de nada que hacen que una plantilla parezca una plantilla y no una lista.
func _repartir_dorsales(c: Club) -> void:
	var orden := c.plantilla.duplicate()
	orden.sort_custom(func(a: Jugador, b: Jugador) -> bool: return a.ovr > b.ovr)
	var siguiente := 2
	for j: Jugador in orden:
		j.dorsal = 0
	for j: Jugador in orden:
		if j.es_portero() and j.dorsal == 0:
			j.dorsal = 1        ## el 1 es del mejor portero, siempre
			break
	for j: Jugador in orden:
		if j.dorsal == 0:
			j.dorsal = siguiente
			siguiente += 1
	var capitan: Jugador = null
	for j: Jugador in orden:
		if j.edad >= 27:
			capitan = j
			break
	if capitan == null and not orden.is_empty():
		capitan = orden[0]
	if capitan != null:
		capitan.capitan = true

## Rellena la plantilla. Portado de `generarPlantel()` del HTML, incluida la
## plantilla de demarcaciones (PLAN_PLANTEL: 3 porteros, 4 centrales, 3 delanteros
## centro...), que es lo que garantiza que ningun club salga sin lateral izquierdo.
##
## La media sale de `rep - 9` con un margen de ±7 y dos castigos por edad. Los
## castigos importan mas de lo que parecen: sin el de los menores de 20 salian
## canteranos de 17 anos con media 96 valorados en 223 millones, que es
## exactamente lo que un manager no se puede permitir mostrar. El chico bueno
## tiene que tener POTENCIAL alto y media baja; eso es lo que hace que ficharlo
## sea una apuesta y no una compra evidente.
##
## PLANTILLAS FIJAS (MEGAPLAN fase 4): hasta hoy solo los clubes con tabla
## `REALES` tenían caras conocidas de una partida a otra; en los otros 128
## cada semilla repartía nombres, edades y medias nuevos, y el «9 de siempre»
## del rival no existía. Ahora la plantilla de arranque se siembra con el
## NOMBRE del club -no con la semilla del mundo ni con su id, que cambia según
## qué países se carguen-: el mismo club trae siempre a la misma gente. Se
## guarda el estado de `Azar` y se devuelve tal cual, así el resto del mundo
## (calendario, canteras, mercado) sigue variando con la semilla. Lo que llega
## después -canteranos, agentes libres, regens- sigue siendo de cada partida.
func _poblar(c: Club) -> void:
	var plan: Array = Datos.tabla("PLAN_PLANTEL")
	var base := c.rep - 9
	var estado: int = Azar._rng.state
	Azar._rng.seed = hash("plantilla|" + Nombres.limpiar(c.nombre))
	_clave_fija = "fijo|" + Nombres.limpiar(c.nombre)
	_n_fijo = 0
	for entrada: Array in plan:
		var demarcacion := String(entrada[0])
		for i in int(entrada[1]):
			var edad := Azar.ent(17, 35)
			var ovr := base + Azar.ent(-7, 7)
			if edad < 20:
				ovr -= 5
			if edad >= 33:
				ovr -= 2
			var j := crear_jugador(c, Datos.grupo(demarcacion), demarcacion, edad, ovr)
			c.plantilla.append(j)
	_clave_fija = ""
	Azar._rng.state = estado
	_repartir_dorsales(c)

func liga_de(c: Club) -> Liga:
	for l in ligas:
		if l.clubes.has(c):
			return l
	return ligas[0] if not ligas.is_empty() else null

## Combina en UN solo sitio todo lo que bonifica al equipo.
##
## `Staff.aplicar()` vuelca `bonus_ataque` y `bonus_defensa` ENTEROS, no acumula.
## Si el arbol del DT escribiera ahi por su cuenta, el siguiente fichaje de staff
## borraria su aporte sin que nadie se enterase. Por eso el calculo vive aqui:
## el staff pone la base y el DT la multiplica.
func aplicar_bonificadores() -> void:
	var c := mi_club()
	if c == null:
		return
	staff.aplicar(c)
	if entrenamiento != null:
		var dt := entrenamiento.bonus_dt()
		## MI VIDA: trabajar más prepara mejor el partido (y de baja, peor).
		if vida != null:
			dt *= vida.factor_trabajo(anio, semana)
		c.bonus_ataque *= dt
		c.bonus_defensa *= dt
	## LAS MAESTRÍAS (15 categorías de 30 niveles): ataque, defensa, porteros,
	## balón parado y análisis de rivales.
	if maestria != null:
		c.bonus_ataque *= maestria.factor_ataque()
		c.bonus_defensa *= maestria.factor_defensa()
	## Y el camarin: hermanos en el campo, roles cumplidos y ansiedad del once.
	if vestuario != null:
		c.bonus_ataque *= vestuario.factor_ataque(c)
		c.bonus_defensa *= vestuario.factor_defensa(c)

func _montar_copa() -> void:
	var mio := mi_club()
	var pais := mio.pais if mio != null else "CHI"
	var aspirantes: Array[Club] = []
	for c: Club in clubes.values():
		if c.pais == pais:
			aspirantes.append(c)
	if aspirantes.size() < 4:
		copa = null
		return
	## El nombre del pais sale de PAIS_SELECCION, la tabla que el HTML ya usa
	## para las selecciones. Poniendo el codigo salia "Copa de CHI".
	var paises: Dictionary = Datos.tabla("PAIS_SELECCION")
	var nombre_pais: String = String(paises.get(pais, pais)) if paises != null else pais
	## LA COPA DEL PAIS, CON SU NOMBRE DE VERDAD. Antes todos los paises
	## jugaban una generica "Copa de <pais>"; ahora Inglaterra juega la FA Cup y
	## Espana la Copa del Rey, que es lo que pedia el documento de instrucciones.
	##
	## Los paises con DOS copas juegan la segunda a partir de la temporada
	## siguiente: dos eliminatorias a la vez en el mismo calendario semanal se
	## pisarian, y lo que se gana enseñando dos nombres no compensa un calendario
	## que no cierra. Se alterna por ano, que ademas hace que las temporadas no
	## se sientan iguales.
	var copas: Array = Copa.copas_de(pais, nombre_pais)
	var elegida: Array = copas[anio % copas.size()] if copas.size() > 1 else copas[0]
	copa = Copa.new(String(ajustes_competicion.get("copa_nombre", "")) if String(ajustes_competicion.get("copa_nombre", "")) != "" else String(elegida[0]))
	copa.peso_premio = float(elegida[1])
	copa.sede_final_id = String(ajustes_competicion.get("copa_sede", ""))
	copa.preparar(aspirantes)

## Sortea los torneos continentales con las plazas de cada pais.
func _sortear_continentales() -> void:
	if copa == null:
		_montar_copa()
	continentales = Continental.sortear(clubes.values(), ligas,
		copa.campeon if copa != null else null)

## Arranca tu carrera en un club: fija el objetivo que te pone la directiva.
##
## El puesto esperado sale de la reputacion dentro de SU liga, no del ranking
## mundial: ser decimoquinto de Chile no es lo mismo que serlo de Inglaterra.
func tomar_el_mando(club_id: String) -> Directiva:
	## EL CURRICULUM. Antes de cambiar de club se cierra el capitulo del anterior:
	## es lo que convierte una partida larga en una CARRERA y no en una sucesion
	## de clubes sin memoria.
	if roles != null and mi_club_id != "" and mi_club_id != club_id:
		var antes: Club = clubes.get(mi_club_id)
		var motivo := "despedido" if directiva != null and directiva.despedido_ya else "se fue"
		roles.cerrar_capitulo(mi_club_id, antes.nombre if antes != null else "", anio, motivo)
	mi_club_id = club_id
	var c := mi_club()
	var l := liga_de(c)
	var orden := l.clubes.duplicate()
	orden.sort_custom(func(a: Club, b: Club) -> bool: return a.rep > b.rep)
	directiva = Directiva.new(c, orden.find(c) + 1)
	## Al dueño, al ayudante y al interino no los juzga el directorio -"lo_echan"
	## de `Roles.PERMISOS`-: la confianza les sigue midiendo el apoyo del
	## entorno igual que a cualquiera, pero cruzar el umbral no te saca del club.
	directiva.puede_despedirte = roles.le_pueden_echar()
	if not roles.rol_cambiado.is_connected(_rol_cambio_directiva):
		roles.rol_cambiado.connect(_rol_cambio_directiva)
	staff.aplicar(c)
	obras.fijar_aforo_base(c.estadio_aforo)
	obras.aplicar(c)
	medico = Medico.new(staff, mi_club_id)
	entrenamiento = Entrenamiento.new(staff, obras, medico)
	## LA SIEMBRA ÚNICA. El mundo entero se generó en `generar()`, ANTES de que
	## existiera ningún `Entrenamiento` -no hay club elegido todavía, así que
	## `crear_jugador()` no tiene a quién pedirle el sorteo-, y por eso ninguno
	## de esos jugadores nacía con una habilidad especial. Se reparte aquí, una
	## sola vez por partida, apenas existe el primer `Entrenamiento` de verdad.
	if not _habilidades_sembradas:
		_habilidades_sembradas = true
		for club_s: Club in clubes.values():
			for js: Jugador in club_s.plantilla:
				entrenamiento.sortear_habilidades(js)
	aplicar_bonificadores()
	## El rol arranca en "dt" salvo que se diga otra cosa: es el modo clasico y el
	## que no bloquea nada, para que empezar una partida no exija elegir antes.
	if roles.rol == "":
		roles.arrancar("dt")
	## Los tres sistemas que solo existen para TU club: la prensa que te pregunta,
	## el parte medico de tu plantel y la memoria de lo que vas consiguiendo.
	prensa = Prensa.new(self)
	logros = Logros.new(self)
	vestuario = Vestuario.new(self)
	hinchada = Hinchada.new(self)
	gente = Gente.new(self)
	club_dentro = ClubDentro.new()
	junta = Junta.new()
	junta.formar(mi_club())
	charlas = Charlas.new()
	licencia = Licencia.new()
	trabajadores = Trabajadores.new()
	Trabajadores.actual = trabajadores
	movil = Movil.new()
	mercado_av = MercadoAvanzado.new()
	insolvencia = Insolvencia.new()
	redes = Redes.new()
	redes.iniciar(self)
	eventos_cantera = EventosCantera.new()
	calendario = Calendario.new()
	politica = Politica.new()
	contratos = Contratos.new()
	vida = VidaDT.new()
	maestria = Maestria.new()
	banco = Banco.new()
	auspicio = Auspicio.new(self)
	comercial = Comercial.new(self)
	ciudad = Ciudad.new(self)
	comercial.generar_ofertas_zona(mi_club(), roles.multiplicador_sponsor() if roles != null else 1.0)
	comercial.generar_ofertas_naming(mi_club())
	## Y con las marcas ya en la mesa desde el primer dia: si las ofertas solo se
	## abrieran en la pretemporada siguiente, la primera temporada entera se
	## jugaria con el pecho en blanco y sin ese ingreso.
	auspicio.generar_ofertas(mi_club(), false, roles.multiplicador_sponsor() if roles != null else 1.0)
	if roles != null:
		var c_nuevo := mi_club()
		roles.abrir_capitulo(club_id, c_nuevo.nombre if c_nuevo != null else "", anio)
	gente.armar()
	## Hay que armarlas al momento: sin esto no hay camarillas hasta la semana 6 y
	## el vestuario no existe durante el primer mes y medio.
	vestuario.armar()
	selecciones = Selecciones.new(self)
	cantera = Cantera.new(self)
	academia = Academia.new(self)
	academia.sembrar()
	ojeadores = Ojeadores.new(self)
	## Sembradas al tomar el mando y no en generar(): antes de elegir club no hay
	## "tu" cantera todavía, y `sembrar_leyendas()` reparte las leyendas entre
	## clubes al azar sin necesitar saber cuál es el tuyo -pero conviene que la
	## primera camada de hijos de leyenda ya tenga candidatos esperando.
	cantera.sembrar_leyendas()
	## El libro de movimientos: siete fuentes. `tomar_el_mando()` se puede llamar
	## más de una vez sobre el mismo Mundo -fundar club, trotamundos, cargar una
	## partida-, y no todas estas clases se recrean cada vez -`federacion` y
	## `estadio` viven desde que se crea el Mundo, `cesiones` desde `generar()`-,
	## así que conectar sin comprobar antes iría duplicando la conexión y cada
	## movimiento acabaría anotado dos, tres, cuatro veces. `Finanzas` es aparte:
	## se crea una instancia nueva cada semana para cada club en
	## `avanzar_semana()`, así que esa conexión va ahí, no aquí.
	for fuente: Variant in [federacion, estadio, cesiones, cantera, prensa, selecciones]:
		var sig: Signal = fuente.movimiento
		if not sig.is_connected(_anotar_movimiento):
			sig.connect(_anotar_movimiento)
	_sortear_continentales()
	## Cada vez que tomas un club de cero -incluido el primero- empiezas a
	## contar temporadas en él desde cero. Es lo que hace que "trotamundos" mida
	## de verdad cuánto llevas echando raíces y no arrastre el contador del club
	## anterior.
	anios_en_club = 0
	## Otra vez al final (20-10-2026): la llamada de arriba llega antes de que
	## existan el camarín y los demás sistemas, y tu club jugaba la primera
	## semana sin sus bonificaciones (al cargar la partida sí las tenía).
	aplicar_bonificadores()
	return directiva
