class_name Cantera
extends RefCounted
## La cantera juvenil y los representantes: los chicos de la casa y quien negocia por ellos.
##
## Son dos sistemas y viven juntos por una razón concreta: el agente aparece en
## el juego justo donde la cantera deja de ser una promesa y empieza a costar
## dinero. Un chico de dieciséis no tiene agente que valga; el día que rinde,
## alguien firma por él, y a partir de ahí cada renovación, cada rescisión y cada
## cláusula pasa por una persona con un apellido y un porcentaje.
##
## QUÉ ES ESTA CLASE Y QUÉ NO ES
##
## `Mundo._subir_de_cantera()` ya repone las plantillas por el puesto que falta,
## y esa es la cantera de los 383 clubes de la IA: invisible, automática y
## suficiente, porque nadie va a mirar nunca la Sub-17 de Coquimbo. Esto es la
## CAPA DE ARRIBA y solo para el club que diriges: la camada que llega con
## nombre, que se puede ver, becar, entrenar, perder y decidir si sube. No
## duplica la reposición: convive con ella y de hecho le quita trabajo, porque un
## juvenil de la camada ya cuenta como su demarcación en el plan de plantilla.
##
## Tampoco sube al primer equipo: eso es de `Roles.subir_al_primer_equipo()`, que
## ya lleva la cuenta de debutantes del modo director de cantera. Aquí se decide
## quién ESTÁ LISTO (`listo_para_debutar`), que es la mitad interesante.
##
## LA REGLA QUE NO SE TOCA: media baja, potencial alto.
##
## El canterano bueno nunca llega con media alta. Llega flojo y con techo, y por
## eso apostar por él es apostar. Ya se pagó una vez el error contrario —chicos
## de diecisiete con media 96 y 223 millones de valor— y por eso la media de la
## camada sale de `rep - 24` y el techo de sumarle entre 6 y 26 puntos, que son
## los números del HTML sin redondear.

# ===========================================================================
#  SEÑALES
# ===========================================================================

## Lo que sale en el diario. La interfaz se engancha aquí; esta clase no sabe
## que existe una interfaz.
signal noticia(titulo: String, cuerpo: String)
## Dinero que entra o sale, para el libro de movimientos.
signal movimiento(concepto: String, monto: int)

## Llegó la camada anual. `chicos` son los de TU club, ya dentro de la plantilla.
signal camada_lista(chicos: Array)
## El hijo de una leyenda entra en la cantera de algún club del mundo.
signal hijo_de_leyenda(j: Jugador, padre: String, club: Club)
## Un hermano (o un gemelo) se suma al plantel.
signal hermano_en_casa(nuevo: Jugador, hermano: Jugador, gemelos: bool)
## Un grande se llevó a un juvenil sin contrato profesional.
signal canterano_robado(j: Jugador, destino: Club, compensacion: int)
## La prensa aprieta al chico al que le colgaron un apellido, o lo suelta.
signal etiqueta_pesa(j: Jugador, referencia: String)
signal etiqueta_superada(j: Jugador, referencia: String)
## Se cerró la promesa de traerle un compatriota: cumplida o no.
signal promesa_resuelta(j: Jugador, cumplida: bool)
## Un representante con varios clientes en el plantel pone algo sobre la mesa.
signal agente_presiona(e: Dictionary)

# ===========================================================================
#  CONSTANTES PORTADAS
# ===========================================================================

## Cuántos chicos trae la camada anual. Del HTML: `R(2,4)` por club.
const CAMADA_MIN := 2
const CAMADA_MAX := 4

## El tope de fichas del club. El HTML no lo necesitaba porque recortaba las
## plantillas de la IA por otro lado; aquí sí, porque si no la camada suma cada
## temporada y en diez años el plantel es una guía telefónica. Cuando se llena,
## la academia no tiene cupo y se dice en voz alta: es una consecuencia de no
## vender ni dar salidas, no un fallo silencioso.
const TOPE_PLANTEL := 30

## Un chico está listo cuando su media llega a `rep - MARGEN_DEBUT`. Es el mismo
## número que usa `Roles.subir_al_primer_equipo()` para decidir si el debut es
## una fiesta o un escarmiento; se define aquí porque es una regla de cantera.
const MARGEN_DEBUT := 14

## Hasta qué edad se es juvenil a efectos de fuga y de categorías.
const EDAD_JUVENIL := 20
## Y hasta cuándo cuenta como canterano para debutar.
const EDAD_CANTERANO := 21

## Beca deportiva: estudios, alojamiento y comida. `esc$(14000)` del HTML.
const COSTE_BECA := 14000.0

## Derechos de formación cuando te roban a un chico: el 22% de su valor. Es poco
## a propósito. Tiene que doler.
const DERECHOS_FORMACION := 0.22

## Cuántas leyendas trae el mundo ya inventadas al empezar. Sin esto, los
## primeros hijos de leyenda no llegarían hasta la décima temporada y el sistema
## no existiría para quien juega tres años. Es `N_LEYENDAS_SEMILLA` del HTML.
const LEYENDAS_SEMILLA := 44

## A partir de esta media, un retirado entra en el libro de leyendas y algún día
## puede llegar un hijo suyo.
const MEDIA_DE_LEYENDA := 76

## Semanas de una temporada. Hace falta para calcular lo que queda de contrato en
## un finiquito. Se pide a la liga cuando se puede; esto es el respaldo.
const SEMANAS_TEMPORADA := 38

# ===========================================================================
#  ESTADO
# ===========================================================================

## Referencia DÉBIL al mundo, igual que en `Mercado` y en `Prensa`. El mundo
## guarda su cantera y la cantera necesita ver el mundo entero (los clubes
## rivales que roban juveniles, la reputación que fija el nivel de la camada).
## Con dos referencias normales eso es un ciclo, y RefCounted no recoge ciclos:
## al terminar una partida se quedaba vivo un Mundo entero con sus 384 clubes y
## sus 8.448 jugadores dentro. Ya han caído cuatro clases por aquí.
var _ref: WeakRef

## El libro de leyendas del mundo: cada entrada es un retirado ilustre que algún
## año traerá un hijo. Claves: nombre, club_id, pos, nivel, anio_hijo, usado.
var leyendas: Array[Dictionary] = []

## Lo que este sistema le cuelga a cada jugador, indexado por id igual que las
## fichas de `Medico`. No se le añaden campos a `Jugador`: allí solo vive lo que
## necesitan el once y el simulador, y así nadie puede corromper un linaje sin
## pasar por esta puerta.
var _fichas: Dictionary = {}

## Los ids de la última camada que llegó a tu club, para poder enseñarla en el
## menú sin recorrer la plantilla adivinando quién es nuevo.
var ultima_camada: Array[String] = []

## --- LOS REPRESENTANTES -----------------------------------------------------
## Cuánto te debe (o cuánto te odia) cada agencia. Es el `G.agConf` del HTML.
var confianza_agentes: Dictionary = {}
## El agente con el que firmaste exclusividad, o "".
var exclusiva: String = ""
## Cuántos pagos por debajo de la mesa llevas. A partir del tercero la
## federación puede enterarse.
var turbio: int = 0
## La exigencia de un representante esperando respuesta, o vacío. Claves: tipo,
## agente, pid, ids, txt, opcion_a, opcion_b.
var exigencia: Dictionary = {}

func _init(mundo: Mundo) -> void:
	_ref = weakref(mundo)

func _mundo() -> Mundo:
	return _ref.get_ref() as Mundo


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
	_sortear_hermano(mio)
	return salida

## Los chicos de un club. La media sale de `rep - 24` y el techo de sumarle entre
## 6 y 26 puntos: media baja, potencial alto, que es la regla de la casa.
func _camada_de(c: Club) -> Array[Jugador]:
	var m := _mundo()
	var salida: Array[Jugador] = []
	var cuantos := Azar.ent(CAMADA_MIN, CAMADA_MAX)
	var bono := bono_de_camada()
	var mult := multiplicador_de_reputacion()
	for i in cuantos:
		if c.plantilla.size() >= TOPE_PLANTEL:
			break
		var grupo := String(Azar.uno(["POR", "DEF", "DEF", "MED", "MED", "DEL"]))
		var edad := Azar.ent(16, 18)
		var ovr := c.rep - 24 + Azar.ent(-4, 8)
		var j := m.crear_jugador(c, grupo, demarcacion_de(grupo), edad, ovr)
		var techo := j.ovr + Azar.ent(6, 26)
		## Lo que aporta el club: academia y residencia (`Instalaciones`), el
		## director de cantera (`Staff`) y el árbol del entrenador
		## (`Entrenamiento`). El bono sube un poco la media y MUCHO el techo -el
		## doble-, porque una buena academia no fabrica cracks hechos: fabrica
		## chicos con más recorrido.
		if bono > 0:
			j.ovr = clampi(j.ovr + bono, 40, 90)
			techo = int(round(float(techo + 2 * bono) * mult))
		## LA EPOCA DEL PAIS. Una generacion entera sube un 13% o baja un 10%, y
		## dura entre cuatro y nueve anos. Es lo que hace que tener ojeadores en un
		## sitio concreto sea una apuesta con calendario y no un gasto fijo.
		var bono_era := m.eras.bono(c.pais, m.anio) if m.eras != null else 1.0
		if not is_equal_approx(bono_era, 1.0):
			techo = int(round(float(techo) * bono_era))
			## Y en las doradas, uno de cada diez sale ademas con un extra: no es
			## que todos suban un poco, es que ademas aparecen los irrepetibles.
			if bono_era > 1.0 and Azar.suerte(0.10):
				techo += Azar.ent(3, 8)
		j.pot = clampi(techo, j.ovr, 97)
		## Los atributos se rehacen porque la media ha cambiado, y el valor
		## después, porque depende del techo: un chico de 17 con proyección 90 no
		## vale lo que uno con proyección 70 aunque hoy tengan la misma media.
		j.generar_atributos()
		_sortear_origen(j)
		j.tasar()
		var f := _ficha(j.id)
		f["camada"] = m.anio
		## El dorsal se reparte aquí y no se deja en cero. `Mundo` ya los repartió
		## al empezar la temporada y no vuelve a pasar: sin esto, la camada entera
		## sale a la cancha con el número 0.
		j.dorsal = _dorsal_libre(c)
		c.plantilla.append(j)
		salida.append(j)
	return salida

## El primer dorsal libre a partir del 20, que es por donde empiezan los chicos.
func _dorsal_libre(c: Club) -> int:
	var usados := {}
	for j in c.plantilla:
		usados[j.dorsal] = true
	var n := 20
	while usados.has(n) and n < 99:
		n += 1
	return n

## Todo lo que suma techo a una camada, en un solo sitio. Los tres sistemas ya
## dan su número: no se inventa ninguno aquí.
func bono_de_camada() -> int:
	var m := _mundo()
	if m == null:
		return 0
	var n := 0
	if m.staff != null:
		n += m.staff.techo_cantera()
	if m.obras != null:
		n += m.obras.techo_cantera()
	if m.entrenamiento != null:
		n += m.entrenamiento.techo_cantera_dt()
	return n

## `bonusReputacion().cantera` del HTML: un entrenador con nombre atrae mejores
## camadas. Un 1% de techo por cada dos puntos de prestigio sobre 50.
func multiplicador_de_reputacion() -> float:
	var m := _mundo()
	var rep := 50
	if m != null and m.roles != null:
		rep = m.roles.prestigio
		## Y la fama de formador (26-9-2026, `Reputacion`).
		return (1.0 + float(rep - 50) * 0.005) * m.roles.reputacion.mult_cantera()
	return 1.0 + float(rep - 50) * 0.005


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

## Los hijos que tocaban este año. El techo del chico sale del NIVEL DEL PADRE,
## no de la reputación del club: por eso el hijo de un 93 es una joya aunque
## aparezca en un club modesto, y por eso conviene tener ojeadores.
func _hijos_de_leyendas() -> void:
	var m := _mundo()
	if m == null:
		return
	## Se recorre una copia porque al final se poda la lista, y quitar entradas
	## del array que estás recorriendo se salta leyendas.
	for L: Dictionary in leyendas.duplicate():
		if bool(L.get("usado", false)) or int(L.get("anio_hijo", 0)) > m.anio:
			continue
		L["usado"] = true
		var club_padre: Club = m.clubes.get(String(L.get("club_id", "")))
		## Siete de cada diez van al club del padre. El resto se reparte, y ese
		## resto es la mejor historia que da el sistema: el hijo de tu ídolo
		## formándose en el rival.
		var destino: Club = club_padre
		if destino == null or not Azar.suerte(0.7):
			destino = m.clubes.get(String(Azar.uno(m.clubes.keys())))
		if destino == null or destino.plantilla.size() >= TOPE_PLANTEL:
			continue
		var grupo := String(L.get("pos", "MED"))
		if not Azar.suerte(0.7):
			grupo = String(Azar.uno(["POR", "DEF", "MED", "DEL"]))
		var edad := Azar.ent(16, 17)
		var ovr := destino.rep - 24 + Azar.ent(0, 6)
		var j := m.crear_jugador(destino, grupo, demarcacion_de(grupo), edad, ovr)
		var apellido := _apellido_de(String(L.get("nombre", "")))
		j.nombre = "%s %s" % [_nombre_de_pila(destino.pais), apellido]
		## El techo hereda del padre con un margen del 85% al 120%. Nunca menos
		## de cuatro puntos por encima de su media de hoy: un hijo de leyenda que
		## no tuviera recorrido sería una noticia sin historia detrás.
		j.pot = clampi(int(round(float(int(L.get("nivel", 80))) * (0.85 + Azar.f() * 0.35))), j.ovr + 4, 97)
		j.generar_atributos()
		_sortear_origen(j)
		j.tasar()
		var f := _ficha(j.id)
		f["camada"] = m.anio
		f["linaje"] = {
			"padre": String(L.get("nombre", "")),
			"club": club_padre.nombre if club_padre != null else "?",
			"nivel": int(L.get("nivel", 80)),
			"padre_en_club": false,
			"pedido": false,
		}
		j.dorsal = _dorsal_libre(destino)
		destino.plantilla.append(j)
		## La etiqueta se cuelga aquí y no en el debut: la prensa no espera a que
		## juegue para llamarlo «el nuevo Fulano». Ese es justo el problema.
		etiquetar_promesa(j, String(L.get("nombre", "")))
		hijo_de_leyenda.emit(j, String(L.get("nombre", "")), destino)
		## La señal sale siempre; el titular solo si te toca. Con 384 clubes en el
		## mundo, anunciar cada hijo de cada leyenda llenaba el diario de gente
		## que no conoces. Interesa el que llega a TU cantera y el que lleva el
		## apellido de alguien que jugó en tu club: ese es el que duele.
		var mio_id := m.mi_club_id
		if destino.id == mio_id or (club_padre != null and club_padre.id == mio_id):
			noticia.emit("Llega el hijo de una leyenda",
				"La cantera de %s incorpora a %s, hijo de %s (%d en su mejor momento). La prensa ya habla del «nuevo %s»." % [
					destino.nombre, j.nombre, String(L.get("nombre", "")), int(L.get("nivel", 80)), apellido])
	## El libro solo guarda a los que todavía no han traído hijo. Una leyenda ya
	## usada no vuelve a hacer nada, y sin podarlas la lista crece para siempre:
	## en cincuenta temporadas eran miles de entradas muertas en cada guardado.
	## El apellido no se pierde, se queda en el linaje del hijo.
	var pendientes: Array[Dictionary] = []
	for L: Dictionary in leyendas:
		if not bool(L.get("usado", false)):
			pendientes.append(L)
	leyendas = pendientes

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
	var grupo := base.pos
	var demarcacion := base.pos_e if gemelos else demarcacion_de(grupo)
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
	j.moral = clampi(j.moral + 14, 10, 99)
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

## El pulso semanal de la cantera: quién se va y a quién le pesa el apellido.
## Devuelve lo que ha pasado, para que quien llame pueda contarlo o ignorarlo.
func procesar_semana() -> Array[Dictionary]:
	var sucesos: Array[Dictionary] = []
	sucesos.append_array(_chequeo_fugas())
	sucesos.append_array(_proceso_etiquetas())
	return sucesos

func _chequeo_fugas() -> Array[Dictionary]:
	var m := _mundo()
	var sucesos: Array[Dictionary] = []
	if m == null:
		return sucesos
	var mio := m.mi_club()
	if mio == null:
		return sucesos
	## Se copia la lista antes de recorrerla: dentro del bucle se saca gente de
	## la plantilla, y modificar el array que estás recorriendo se salta jugadores.
	for j in mio.plantilla.duplicate():
		if not Azar.suerte(riesgo_fuga(j)):
			continue
		var destino := _grande_que_se_lo_lleva(m, mio, j)
		if destino == null:
			continue
		var compensacion := int(round(float(j.valor) * DERECHOS_FORMACION))
		mio.mover_saldo(compensacion)
		movimiento.emit("Derechos de formación: %s" % j.nombre, compensacion)
		mio.soltar(j)
		destino.fichar(j)
		canterano_robado.emit(j, destino, compensacion)
		noticia.emit("Te roban un canterano",
			"%s se lleva a %s (%d años, proyección %d) aprovechando que no tenía contrato profesional. Solo cobras los derechos de formación. Con residencia, academia y becas esto pasa mucho menos." % [
				destino.nombre, j.nombre, j.edad, j.pot])
		sucesos.append({"tipo": "fuga", "jugador": j, "destino": destino, "monto": compensacion})
	return sucesos

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


# ===========================================================================
#  EL PESO DE UN APELLIDO
# ===========================================================================

## Le cuelga a un chico la etiqueta de «el nuevo Fulano». Vende diarios y lo
## aplasta: a partir de aquí no se le mide por lo que hace, se le mide por lo que
## hizo otro.
func etiquetar_promesa(j: Jugador, referencia: String) -> void:
	var m := _mundo()
	if j == null or m == null:
		return
	var f := _ficha(j.id)
	if not (f.get("etiqueta", {}) as Dictionary).is_empty():
		return
	f["etiqueta"] = {"ref": referencia, "desde": m.anio, "cumple": 0, "presion": 0, "libre": false}
	## La etiqueta llega con un golpe de moral: el chico se entera el mismo día
	## que la prensa, y a los diecisiete eso no es un halago.
	j.moral = clampi(j.moral - 6, 10, 99)

func etiqueta_de(j: Jugador) -> Dictionary:
	return _fichas.get(j.id, {}).get("etiqueta", {}) if j != null else {}

## Cada semana la prensa mide si el chico está a la altura del apellido que le
## colgaron. Si rinde, lo bendicen; si no, lo entierran. A las seis semanas malas
## le pasan factura, y a los ocho aciertos se lo quitan de encima para siempre.
func _proceso_etiquetas() -> Array[Dictionary]:
	var m := _mundo()
	var sucesos: Array[Dictionary] = []
	if m == null or m.mi_club() == null:
		return sucesos
	for j in m.mi_club().plantilla:
		var e: Dictionary = _fichas.get(j.id, {}).get("etiqueta", {})
		if e.is_empty() or bool(e.get("libre", false)):
			continue
		var anios := m.anio - int(e.get("desde", m.anio))
		var rinde := j.partidos >= 4 and j.media_notas(3) >= 6.6
		if rinde:
			e["cumple"] = int(e.get("cumple", 0)) + 1
			e["presion"] = maxi(0, int(e.get("presion", 0)) - 1)
		elif anios >= 1 and j.partidos >= 6:
			e["presion"] = int(e.get("presion", 0)) + 1
		if int(e["presion"]) == 6:
			j.moral = clampi(j.moral - 14, 5, 99)
			etiqueta_pesa.emit(j, String(e.get("ref", "")))
			noticia.emit("El peso de un apellido",
				"La prensa se cansó de esperar a %s. «El nuevo %s no aparece», titulan hoy. El chico entrenó cabizbajo toda la semana: la etiqueta que le pusieron a los diecisiete le pesa como una mochila de piedras." % [
					j.nombre, String(e.get("ref", ""))])
			sucesos.append({"tipo": "etiqueta_pesa", "jugador": j})
		if int(e.get("cumple", 0)) >= 8:
			e["libre"] = true
			j.moral = clampi(j.moral + 12, 5, 99)
			etiqueta_superada.emit(j, String(e.get("ref", "")))
			noticia.emit("Ya no es «el nuevo» nadie",
				"%s se sacó la etiqueta de encima a fuerza de partidos. Hoy la prensa escribe su nombre solo, sin compararlo con %s." % [
					j.nombre, String(e.get("ref", ""))])
			sucesos.append({"tipo": "etiqueta_superada", "jugador": j})
	return sucesos


# ===========================================================================
#  DE DÓNDE SALIÓ EL CHICO
# ===========================================================================

## El origen no es un adorno: el potrero da regate y físico, la academia da pase
## y cabeza, el turno de noche da piernas. Se sortea PONDERADO (del potrero salen
## muchos, refugiados casi ninguno) porque con un hash plano la distribución
## quedaba uniforme y cíclica.
func _sortear_origen(j: Jugador) -> void:
	var origenes: Variant = Datos.tabla("ORIGENES")
	if j == null or not (origenes is Array) or (origenes as Array).is_empty():
		return
	var total := 0
	for o: Array in origenes:
		total += int(o[6])
	var r := Azar.f() * float(total)
	var elegido: Array = origenes[0]
	for o: Array in origenes:
		r -= float(int(o[6]))
		if r <= 0.0:
			elegido = o
			break
	_ficha(j.id)["origen"] = String(elegido[0])
	## Al portero no se le tocan los atributos de campo: los suyos son otros
	## (paradas, saques) y sumarle regate no significaría nada.
	if j.es_portero():
		return
	var bonos: Dictionary = elegido[4]
	for k: String in bonos:
		if j.atributos.has(k):
			j.atributos[k] = clampi(int(j.atributos[k]) + int(bonos[k]), 22, 99)

## La ficha de origen completa (icono, frase e historia), para poder contarla en
## la ficha del jugador. Devuelve vacío si el chico no tiene origen sorteado.
func origen_de(j: Jugador) -> Dictionary:
	var clave := String(_fichas.get(j.id, {}).get("origen", "")) if j != null else ""
	if clave == "":
		return {}
	var origenes: Variant = Datos.tabla("ORIGENES")
	if not (origenes is Array):
		return {}
	for o: Array in origenes:
		if String(o[0]) == clave:
			return {"id": clave, "icono": String(o[1]), "frase": String(o[2]), "historia": String(o[3])}
	return {}

## El linaje del chico: de quién es hijo, de qué club era su padre y a qué nivel
## llegó. Vacío si es un jugador sin apellido que pese.
func linaje_de(j: Jugador) -> Dictionary:
	return _fichas.get(j.id, {}).get("linaje", {}) if j != null else {}

## Un chico que llega de la Academia (10-16 años, `Academia`) es tan canterano
## como uno de la camada: se anota igual, con su año, para el linaje, las
## etiquetas y la cuenta de debutantes del modo director de cantera.
func registrar_de_academia(j: Jugador, anio: int) -> void:
	var f := _ficha(j.id)
	f["camada"] = anio
	f["origen"] = "academia"

func es_canterano(j: Jugador) -> bool:
	return j != null and _fichas.get(j.id, {}).has("camada")


# ===========================================================================
#  LA PROMESA DEL COMPATRIOTA
# ===========================================================================

## Le prometiste traerle a alguien de su país. En el HTML esto se guardaba y
## nadie lo comprobaba nunca: era una frase gratis en una negociación. Aquí se
## apunta el año y al cerrar la temporada se pasa factura.
func prometer_compatriota(j: Jugador) -> void:
	var m := _mundo()
	if j == null or m == null:
		return
	_ficha(j.id)["promesa_compa"] = m.anio

func tiene_promesa(j: Jugador) -> bool:
	return j != null and int(_fichas.get(j.id, {}).get("promesa_compa", 0)) > 0

## Se pasa la cuenta de las promesas. Se llama al cerrar la temporada.
##
## La plantilla se lee UNA vez y se comprueba sobre esa lista: pedirla otra vez
## dentro del bucle era recorrer el plantel entero tantas veces como promesas
## hubiera, para nada. Es la nota que dejó el propio HTML.
func chequeo_promesas() -> Array[Dictionary]:
	var m := _mundo()
	var salida: Array[Dictionary] = []
	if m == null or m.mi_club() == null:
		return salida
	var plantel := m.mi_club().plantilla
	for j in plantel:
		if not tiene_promesa(j):
			continue
		var cumplida := false
		for x in plantel:
			if x.id != j.id and x.pais == j.pais:
				cumplida = true
				break
		if cumplida:
			j.moral = clampi(j.moral + 8, 10, 99)
			noticia.emit("Promesa cumplida: %s" % j.nombre,
				"Le prometiste traer a alguien de su país y ahora tiene con quién hablar en su idioma. Se le nota en el ánimo.")
		else:
			## EL TRADUCTOR AMORTIGUA EL GOLPE. Con uno bueno, el extranjero que se
			## quedo sin compatriota se siente solo pero no se hunde, y sobre todo no
			## pide salir: es exactamente para lo que se le paga.
			var amortigua := m.staff.adaptacion_extranjeros() if m.staff != null else 1.0
			j.moral = clampi(j.moral - int(round(16.0 * amortigua)), 10, 99)
			j.pide_salir = amortigua > 0.5
			noticia.emit("Promesa incumplida: %s" % j.nombre,
				"Pasó la temporada y nunca llegó ese compatriota que le prometiste. Se siente solo, la moral se le cayó y ya pidió salir.")
		_ficha(j.id)["promesa_compa"] = 0
		promesa_resuelta.emit(j, cumplida)
		salida.append({"jugador": j, "cumplida": cumplida})
	return salida


# ===========================================================================
#  LOS REPRESENTANTES
# ===========================================================================
#
# Cada jugador tiene agente y el agente tiene perfil. Un tiburón te cobra un 20%
# más en cada mesa y se lleva el 12% de comisión; un formador negocia por debajo
# del mercado porque le interesa que su chico juegue. No es un adorno: es lo que
# hace que dos jugadores idénticos cuesten distinto según quién firme por ellos.
#
# LA TABLA NO SE DUPLICA. `Prensa.agente_de()` ya la lee de `AGENTES` y
# `AG_PERFIL` con el hash del id, que es lo que garantiza que el mismo futbolista
# tenga siempre al mismo representante. Aquí se delega en ella y lo que se añade
# es lo que faltaba: qué hace ese perfil en la mesa de negociación y qué pasa
# cuando una agencia controla a media plantilla.

## El agente de un jugador. Delega en `Prensa`, que es donde está la tabla.
## Si todavía no hay prensa (mundo generado pero sin club tomado), devuelve un
## representante neutro para que ninguna fórmula se quede sin factor.
func agente_de(j: Jugador) -> Dictionary:
	var m := _mundo()
	if m != null and m.prensa != null and j != null:
		return m.prensa.agente_de(j)
	return {"nombre": "un representante", "perfil": "discreto", "etiqueta": "discreto", "f": 1.0, "com": 0.10}

## Cuánto multiplica este agente lo que su cliente pide. El tiburón un 20% más,
## el formador un 5% menos. Va en renovaciones, primas de fichaje y finiquitos.
func factor_pide(j: Jugador) -> float:
	return float(agente_de(j).get("f", 1.0))

## La comisión que se lleva de una operación. Se paga APARTE del traspaso: es el
## dinero que desaparece de la caja sin que llegue a nadie del club, y es la
## razón de que un fichaje cueste siempre más de lo que dice el titular.
func comision(j: Jugador, monto: int) -> int:
	return int(round(float(monto) * float(agente_de(j).get("com", 0.10))))

## Lo que pide para renovar: el sueldo actual con recargo por moral baja y por
## rendir por encima del club, todo multiplicado por su agente.
func pide_para_renovar(j: Jugador) -> int:
	var m := _mundo()
	var rep := 70
	if m != null and m.mi_club() != null:
		rep = m.mi_club().rep
	var f := 1.1
	f += 0.35 if j.moral < 50 else 0.15
	if j.ovr >= rep:
		f += 0.20
	return int(round(float(j.sueldo) * f * factor_pide(j)))

## `renovarJug()` del HTML: se le firma lo que pide. Con cláusula de salida
## acepta un 10% MENOS de sueldo -le pones precio de salida, y a cambio cobra
## menos-, que es la única decisión de verdad que hay aquí.
##
## `pide_para_renovar()` llevaba tiempo escrita y nadie la llamaba: se podía
## calcular lo que pedía un jugador, pero no había forma de decirle que sí.
func renovar(j: Jugador, con_clausula: bool = false) -> Dictionary:
	var m := _mundo()
	if m == null or j == null or j.club_id != m.mi_club_id:
		return {"error": "ese jugador no es tuyo"}
	var pedido := pide_para_renovar(j)
	j.sueldo = int(round(float(pedido) * 0.9)) if con_clausula else pedido
	j.anios_contrato = Contratos.ajustar_anios(j, Azar.ent(2, 4))
	var clausula := 0
	if con_clausula and m.cesiones != null:
		clausula = m.cesiones.pactar_clausula(j)
	## El agente mediático se apunta el tanto en la prensa y el jugador queda
	## contento: el mismo +3 de moral que el HTML.
	var ag := agente_de(j)
	if String(ag.get("perfil", "")) == "mediatico":
		j.moral = clampi(j.moral + 3, 10, 99)
	noticia.emit("Renovado: %s" % Nombres.visible(j.nombre),
		"Firma por %d temporadas a %d/sem%s. Negoció su agente %s (%s)." % [
			j.anios_contrato, j.sueldo,
			" con cláusula de salida" if con_clausula else "",
			String(ag.get("nombre", "?")), String(ag.get("perfil", ""))])
	return {"ok": true, "sueldo": j.sueldo, "anios": j.anios_contrato, "clausula": clausula}

## Semanas de contrato que le quedan: lo que falta de esta temporada más las
## enteras que vienen. Mínimo cuatro, porque nadie firma una salida por cero.
func semanas_de_contrato(j: Jugador) -> int:
	var m := _mundo()
	var total := SEMANAS_TEMPORADA
	if m != null and m.mi_club() != null:
		var l := m.liga_de(m.mi_club())
		if l != null and l.jornadas() > 0:
			total = l.jornadas()
	var restantes := total - (m.semana if m != null else 1)
	return maxi(4, restantes + maxi(0, j.anios_contrato - 1) * total)

## Lo que cuesta rescindirle el contrato. El 0,6 es lo que se arregla de verdad:
## nadie paga el 100% de lo que queda, pero un tiburón te deja mucho más cerca
## del 100% que un formador. Si el jugador ya se quiere ir, la salida es barata.
func finiquito(j: Jugador) -> int:
	var base := float(semanas_de_contrato(j)) * float(j.sueldo) * 0.6 * factor_pide(j)
	if j.pide_salir:
		base *= 0.55
	return int(max(1000.0, round(base / 1000.0) * 1000.0))

## Lo que cuesta la rescisión completa: finiquito más la comisión de salida.
func coste_rescision(j: Jugador) -> Dictionary:
	var fin := finiquito(j)
	var com := comision(j, fin)
	return {"finiquito": fin, "comision": com, "total": fin + com}

## Prima de fidelidad -ofrecerFidelidad() del HTML-: se paga por adelantado y
## el jugador no pide salida en tres temporadas. "" si se hizo, o el motivo por
## el que no.
func ofrecer_fidelidad(j: Jugador, c: Club) -> String:
	if j == null or c == null or j.club_id != c.id:
		return "ese jugador no es tuyo"
	if j.fidelidad_hasta > 0:
		return "ya tiene cláusula de fidelidad"
	var m := _mundo()
	var costo := int(round(float(j.sueldo) * 26.0))
	if c.saldo < costo:
		return "caja insuficiente: cuesta %d" % costo
	c.mover_saldo(-costo)
	j.fidelidad_hasta = (m.anio if m != null else 0) + 3
	j.moral = clampi(j.moral + 14, 10, 99)
	noticia.emit("Prima de fidelidad: %s" % Nombres.visible(j.nombre),
		"Firma su cláusula de fidelidad hasta %d: no pedirá salir mientras siga vigente." % j.fidelidad_hasta)
	return ""

func confianza_de(agente: String) -> int:
	return int(confianza_agentes.get(agente, 0))

## Los representantes con más de un cliente en tu plantel, del que más manda al
## que menos. Es la foto que explica por qué el vestuario se mueve solo.
func agencias_del_plantel() -> Array[Dictionary]:
	var m := _mundo()
	if m == null or m.mi_club() == null:
		return []
	var por_agente := {}
	for j in m.mi_club().plantilla:
		var ag := agente_de(j)
		var n := String(ag.get("nombre", ""))
		if not por_agente.has(n):
			por_agente[n] = {"agente": ag, "jugadores": []}
		(por_agente[n]["jugadores"] as Array).append(j)
	var salida: Array[Dictionary] = []
	for n: String in por_agente:
		var d: Dictionary = por_agente[n]
		d["confianza"] = confianza_de(n)
		salida.append(d)
	salida.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return (a["jugadores"] as Array).size() > (b["jugadores"] as Array).size())
	return salida

## Sortea la exigencia semanal de un representante. Devuelve el evento creado o
## vacío si esta semana no toca.
##
## Solo aparece si una agencia controla a DOS o más de tus jugadores: la presión
## de un agente con un solo cliente no es presión, es una conversación.
func sortear_guerra_agentes() -> Dictionary:
	var m := _mundo()
	if m == null or not exigencia.is_empty() or not Azar.suerte(0.055):
		return {}
	var mio := m.mi_club()
	if mio == null or mio.plantilla.size() < 8:
		return {}
	var fuertes: Array[Dictionary] = []
	for a in agencias_del_plantel():
		if (a["jugadores"] as Array).size() >= 2:
			fuertes.append(a)
	if fuertes.is_empty():
		return {}
	var elegida: Dictionary = Azar.uno(fuertes.slice(0, mini(3, fuertes.size())))
	var suyos: Array = elegida["jugadores"]
	var orden := suyos.duplicate()
	orden.sort_custom(func(a: Jugador, b: Jugador) -> bool: return a.ovr > b.ovr)
	var estrella: Jugador = orden[0]
	var nombre := String(elegida["agente"].get("nombre", ""))
	var etiqueta := String(elegida["agente"].get("etiqueta", "discreto"))
	var tipo := String(Azar.uno(["canterano", "mejora", "comision", "exclusiva"]))
	var ids: Array[String] = []
	for j: Jugador in suyos:
		ids.append(j.id)
	exigencia = {"tipo": tipo, "agente": nombre, "pid": estrella.id, "ids": ids,
		"perfil": String(elegida["agente"].get("perfil", "discreto"))}
	match tipo:
		"canterano":
			exigencia["txt"] = "%s (%s) controla a %d de tus jugadores. Te exige fichar a un canterano de su agencia o «no responde por el ánimo» de %s y compañía." % [
				nombre, etiqueta, suyos.size(), estrella.nombre]
			exigencia["opcion_a"] = "Fichar a su canterano"
			exigencia["opcion_b"] = "Que se olvide"
		"mejora":
			exigencia["txt"] = "%s exige mejorarle el contrato a %s ya mismo. Amenaza con bajar el rendimiento de sus representados si no lo haces." % [
				nombre, estrella.nombre]
			exigencia["opcion_a"] = "Mejorar el contrato"
			exigencia["opcion_b"] = "Aguantar la presión"
		"comision":
			exigencia["txt"] = "%s te pide una comisión extra por debajo de la mesa para «facilitar» la próxima operación. Es plata que no aparece en ningún libro." % nombre
			exigencia["opcion_a"] = "Pagar la comisión"
			exigencia["opcion_b"] = "Denunciarlo internamente"
		_:
			exigencia["txt"] = "%s te ofrece exclusividad: primero te muestra a ti a todos sus jugadores, pero espera que le compres al menos uno por temporada." % nombre
			exigencia["opcion_a"] = "Aceptar la exclusiva"
			exigencia["opcion_b"] = "Prefiero manos libres"
	agente_presiona.emit(exigencia)
	return exigencia

func hay_exigencia() -> bool:
	return not exigencia.is_empty()

## Responde al representante. `op` es "a" o "b". Devuelve {titulo, cuerpo}.
##
## No hay opción neutra: las dos ramas mueven algo. Decirle que no a un agente
## con media plantilla en la cartera tiene precio, y decirle que sí también.
##
## `f` (fase 4, mini-juego de la mesa, ver `MesaAgente`): la parte de la
## exigencia que se pactó, 0..1. `se_fue`: se levantó de la mesa sin trato,
## que es un no con una pizca más de rencor.
func resolver_agente(op: String, f: float = 1.0, se_fue: bool = false) -> Dictionary:
	var m := _mundo()
	if exigencia.is_empty() or m == null or m.mi_club() == null:
		exigencia = {}
		return {}
	var mio := m.mi_club()
	var acepta := op == "a"
	var nombre := String(exigencia.get("agente", ""))
	var tipo := String(exigencia.get("tipo", ""))
	var cuerpo := ""
	f = clampf(f, 0.0, 1.0)
	if se_fue:
		_mover_confianza(nombre, -1)
	match tipo:
		"canterano":
			if acepta and mio.plantilla.size() >= TOPE_PLANTEL:
				## Aceptar sin sitio dejaría al agente contento y al chico en
				## ninguna parte. Se dice que no cabe y se paga como un no.
				_mover_confianza(nombre, -1)
				cuerpo = "Le dijiste que sí, pero el plantel tiene %d fichas y no cabe nadie más. %s se lo tomó como una excusa." % [
					mio.plantilla.size(), nombre]
			elif acepta:
				var grupo := String(Azar.uno(["DEF", "MED", "DEL"]))
				var jov := m.crear_jugador(mio, grupo, demarcacion_de(grupo),
					Azar.ent(17, 19), mio.rep - 16 + Azar.ent(0, 8))
				_ficha(jov.id)["camada"] = m.anio
				jov.dorsal = _dorsal_libre(mio)
				mio.plantilla.append(jov)
				if f < 1.0:
					jov.sueldo = maxi(1, int(round(float(jov.sueldo) * f)))
				_mover_confianza(nombre, 2 if f >= 0.8 else 1)
				cuerpo = "Fichaste a %s (%d años, media %d, proyección %d). %s ahora te debe una." % [
					jov.nombre, jov.edad, jov.ovr, jov.pot, nombre]
			else:
				_mover_confianza(nombre, -2)
				_castigar_clientes(m, Azar.ent(4, 10))
				cuerpo = "Le dijiste que no. Sus representados amanecieron con la moral por el piso."
		"mejora":
			var j := _jugador(mio, String(exigencia.get("pid", "")))
			if acepta and j != null:
				j.sueldo = int(round(float(j.sueldo) * (1.0 + 0.3 * f)))
				j.moral = clampi(j.moral + int(round(14.0 * f)), 10, 99)
				j.anios_contrato = maxi(j.anios_contrato, 3)
				_mover_confianza(nombre, 1 if f >= 0.6 else 0)
				## El resto del vestuario mira de reojo la escala salarial: no es
				## un castigo aleatorio, es lo que pasa cuando uno cobra más y los
				## de su nivel se enteran.
				for x in mio.plantilla:
					if f > 0.6 and x.id != j.id and x.ovr >= j.ovr - 3:
						x.moral = clampi(x.moral - Azar.ent(1, 5), 10, 99)
				cuerpo = "%s firma la mejora. El resto del vestuario mira de reojo la escala salarial." % j.nombre
			else:
				_mover_confianza(nombre, -2)
				_castigar_clientes(m, Azar.ent(5, 12))
				cuerpo = "Aguantaste. Sus representados rinden con desgana y la prensa ya habla de la interna."
		"comision":
			if acepta:
				var coste := int(round(float(Eco.escalar(float(mio.rep) * 2200.0, float(mio.rep))) * f))
				mio.mover_saldo(-coste)
				movimiento.emit("Gastos de intermediación (sin detalle)", -coste)
				_mover_confianza(nombre, maxi(1, int(round(3.0 * f))))
				turbio += 1
				cuerpo = "Pagaste. %s te abre la puerta grande… y ahora sabe algo de ti." % nombre
				## Tres pagos turbios y la cosa se filtra. No es seguro: es una
				## moneda al aire cada vez, que es lo que hace que se siga jugando.
				if turbio >= 3 and Azar.suerte(0.5):
					if m.directiva != null:
						m.directiva.mover_confianza(-14, "pagos irregulares a representantes")
					cuerpo += " Alguien filtró los pagos: se abrió una investigación federativa."
			else:
				_mover_confianza(nombre, -3)
				if m.roles != null:
					m.roles.sumar_prestigio(3)
				cuerpo = "Lo denunciaste ante el directorio. Tu reputación limpia sube, pero %s te va a cerrar puertas." % nombre
		_:
			if acepta:
				_mover_confianza(nombre, maxi(1, int(round(4.0 * f))))
				exclusiva = nombre
				cuerpo = "Trato cerrado con %s. Verás primero a sus jugadores en el mercado." % nombre
			else:
				_mover_confianza(nombre, -1)
				if exclusiva == nombre:
					exclusiva = ""
				cuerpo = "Prefieres moverte libre. %s se lo tomó con deportividad… por ahora." % nombre
	var titulo := "Representantes: %s" % nombre
	if acepta and f < 1.0:
		cuerpo = "Negociado en la mesa al %d %% de lo que pedía. %s" % [int(round(f * 100.0)), cuerpo]
	elif se_fue:
		cuerpo = "%s se levantó de la mesa. %s" % [nombre, cuerpo]
	exigencia = {}
	noticia.emit(titulo, cuerpo)
	return {"titulo": titulo, "cuerpo": cuerpo}

func _mover_confianza(agente: String, d: int) -> void:
	confianza_agentes[agente] = clampi(confianza_de(agente) + d, -10, 10)

func _castigar_clientes(m: Mundo, castigo: int) -> void:
	var mio := m.mi_club()
	if mio == null:
		return
	for id: String in exigencia.get("ids", []):
		var x := _jugador(mio, id)
		if x != null:
			x.moral = clampi(x.moral - castigo, 10, 99)


# ===========================================================================
#  AUXILIARES
# ===========================================================================

## La ficha de cantera de un jugador, creándola si hace falta. Se guarda por id y
## no dentro de `Jugador` por la misma razón que el parte médico: allí solo vive
## lo que necesitan el once y el simulador.
func _ficha(id: String) -> Dictionary:
	if not _fichas.has(id):
		_fichas[id] = {"linaje": {}, "origen": "", "etiqueta": {}, "beca": false,
			"hermano": "", "gemelo": false, "promesa_compa": 0}
	return _fichas[id]

## Una demarcación concreta dentro de un grupo (POR/DEF/MED/DEL). La tabla repite
## las más pobladas (dos DFC, dos MC, dos DC) para que el sorteo salga con la
## forma de una plantilla de verdad y no con seis medios ofensivos.
func demarcacion_de(grupo: String) -> String:
	var t: Variant = Datos.tabla("POS_POR_GRUPO")
	if t is Dictionary and (t as Dictionary).has(grupo):
		return String(Azar.uno(t[grupo]))
	return "MC"

func _jugador(c: Club, pid: String) -> Jugador:
	if pid == "" or c == null:
		return null
	for j in c.plantilla:
		if j.id == pid:
			return j
	return null

## El apellido con el que se hereda: la última palabra del nombre. Un hijo de
## leyenda sin el apellido del padre no es un hijo de leyenda, es otro juvenil.
func _apellido_de(nombre: String) -> String:
	var partes := nombre.strip_edges().split(" ", false)
	return String(partes[partes.size() - 1]) if partes.size() > 0 else nombre

## Con `pais` (22-9-2026, mismo criterio que `Mundo._nombre_al_azar()`, ver
## ese comentario para el porqué): `POOLS_EU`/`NOMBRES_BRA` primero, el fondo
## chileno de siempre si no hay bolsa propia para ese país.
func _nombre_de_pila(pais: String = "") -> String:
	var n: Array = Datos.tabla("NOMBRES")
	var pools: Variant = Datos.tabla("POOLS_EU")
	if pools is Dictionary and (pools as Dictionary).has(pais):
		var par: Array = (pools as Dictionary)[pais]
		if par.size() >= 1 and not (par[0] as Array).is_empty():
			n = par[0]
	elif pais == "BRA":
		var nb: Variant = Datos.tabla("NOMBRES_BRA")
		if nb is Array and not (nb as Array).is_empty():
			n = nb
	if n is Array and not (n as Array).is_empty():
		return String(Azar.uno(n))
	return "Juan"

## Nunca devuelve el nombre de un futbolista real (`Nombres.vetado()`).
func _nombre_al_azar(pais: String = "", region: String = "") -> String:
	return Nombres.sin_vetar(func() -> String: return _sortear_nombre(pais, region))

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


# ===========================================================================
#  GUARDADO
# ===========================================================================

## Solo se guardan las fichas que dicen algo. Con 8.448 jugadores en el mundo,
## escribir una ficha vacía por cada uno son cientos de kilobytes de nada en cada
## partida guardada. Es la misma criba que hace `Medico.a_dic()`.
func a_dic() -> Dictionary:
	var f := {}
	for id: String in _fichas:
		var x: Dictionary = _fichas[id]
		if _ficha_vacia(x):
			continue
		f[id] = x
	return {
		"leyendas": leyendas,
		"fichas": f,
		"ultima_camada": ultima_camada,
		"confianza_agentes": confianza_agentes,
		"exclusiva": exclusiva,
		"turbio": turbio,
		"exigencia": exigencia,
	}

func _ficha_vacia(x: Dictionary) -> bool:
	return (x.get("linaje", {}) as Dictionary).is_empty() \
		and (x.get("etiqueta", {}) as Dictionary).is_empty() \
		and String(x.get("origen", "")) == "" \
		and not bool(x.get("beca", false)) \
		and String(x.get("hermano", "")) == "" \
		and int(x.get("promesa_compa", 0)) == 0 \
		and not x.has("camada")

func desde_dic(d: Dictionary) -> void:
	leyendas.clear()
	for L: Dictionary in d.get("leyendas", []):
		leyendas.append({
			"nombre": String(L.get("nombre", "")),
			"club_id": String(L.get("club_id", "")),
			"pos": String(L.get("pos", "MED")),
			"nivel": int(L.get("nivel", 80)),
			"anio_hijo": int(L.get("anio_hijo", 0)),
			"usado": bool(L.get("usado", false)),
		})
	_fichas.clear()
	var f: Dictionary = d.get("fichas", {})
	for id: String in f:
		var x: Dictionary = f[id]
		var ficha := {
			"linaje": (x.get("linaje", {}) as Dictionary).duplicate(true),
			"origen": String(x.get("origen", "")),
			"etiqueta": (x.get("etiqueta", {}) as Dictionary).duplicate(true),
			"beca": bool(x.get("beca", false)),
			"hermano": String(x.get("hermano", "")),
			"gemelo": bool(x.get("gemelo", false)),
			"promesa_compa": int(x.get("promesa_compa", 0)),
		}
		## `camada` solo existe si el chico salió de la academia: es lo que
		## distingue a un canterano de un fichaje, y ponerlo por defecto
		## convertiría a la plantilla entera en gente de la casa al cargar.
		if x.has("camada"):
			ficha["camada"] = int(x["camada"])
		_fichas[id] = ficha
	ultima_camada.clear()
	for id in d.get("ultima_camada", []):
		ultima_camada.append(String(id))
	confianza_agentes = (d.get("confianza_agentes", {}) as Dictionary).duplicate()
	exclusiva = String(d.get("exclusiva", ""))
	turbio = int(d.get("turbio", 0))
	exigencia = (d.get("exigencia", {}) as Dictionary).duplicate(true)

## `rankingCanteras()` del HTML: quién está formando de verdad. No es "cuántos
## juveniles tienes" sino cantidad Y techo juntos, porque veinte chicos del
## montón no son una cantera y tres joyas tampoco.
##
## La nota mezcla las dos cosas: la proyección media más un punto y medio por
## cabeza. Así un club con seis chicos de 80 de techo gana a uno con quince de
## 60, pero uno con dos de 90 no gana a nadie.
func ranking_canteras() -> Array[Dictionary]:
	var m := _mundo()
	if m == null:
		return []
	var salida: Array[Dictionary] = []
	for c: Club in m.clubes.values():
		if c.division <= 0:
			continue
		var n := 0
		var pot := 0
		for j in c.plantilla:
			if j.edad <= 21:
				n += 1
				pot += j.pot
		if n == 0:
			continue
		var nota := int(round(float(pot) / float(n) + float(n) * 1.6))
		## La academia propia suma: es la instalación que sube el techo de los
		## que suben, así que tener nivel cinco tiene que verse en este ranking.
		if c.id == m.mi_club_id and m.obras != null:
			nota += m.obras.nivel("acad") * 3
		salida.append({"club": c, "juveniles": n, "nota": nota})
	salida.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return int(a["nota"]) > int(b["nota"]))
	return salida
