extends RefCounted
## [Capa 1/4 de `cantera.gd`] _init, _mundo, bono_de_camada, multiplicador_de_reputacion, grupo_con_tope, demarcacion_de … (+8)

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

## TOPE DE PORTEROS (7-10-2026). La prueba larga encontró clubes con 6 y 7
## porteros: la camada juvenil (uno de cada seis chicos), los hermanos (copian
## el puesto) y los hijos de leyenda (heredan el del padre) metían porteros sin
## mirar cuántos había. Solo los fugados tenían tope. Con tres porteros, el que
## llega juega en otra línea.
const TOPE_PORTEROS := 3

## LA DINASTÍA DEL ENTRENADOR (fase 5): los hijos de tu familia (`VidaDT`)
## crecen con las temporadas y, al cumplir 16, el varón que juega al fútbol
## entra en la cantera del club que diriges, con tu apellido. Su techo sale de
## la casa (la academia y la reputación) más un poco de suerte.
const HIJOS_FUTBOLISTAS := ["Agustín", "Benjamín", "Vicente", "Lucas", "Mateo"]

func _init(mundo: Mundo) -> void:
	_ref = weakref(mundo)

func _mundo() -> Mundo:
	return _ref.get_ref() as Mundo

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

func grupo_con_tope(c: Club, grupo: String) -> String:
	if grupo != "POR" or c == null:
		return grupo
	var n := 0
	for j: Jugador in c.plantilla:
		if j.es_portero():
			n += 1
	return String(Azar.uno(["DEF", "MED", "DEL"])) if n >= TOPE_PORTEROS else grupo

## Una demarcación concreta dentro de un grupo (POR/DEF/MED/DEL). La tabla repite
## las más pobladas (dos DFC, dos MC, dos DC) para que el sorteo salga con la
## forma de una plantilla de verdad y no con seis medios ofensivos.
func demarcacion_de(grupo: String) -> String:
	var t: Variant = Datos.tabla("POS_POR_GRUPO")
	if t is Dictionary and (t as Dictionary).has(grupo):
		return String(Azar.uno(t[grupo]))
	return "MC"
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

## El primer dorsal libre a partir del 20, que es por donde empiezan los chicos.
func _dorsal_libre(c: Club) -> int:
	var usados := {}
	for j in c.plantilla:
		usados[j.dorsal] = true
	var n := 20
	while usados.has(n) and n < 99:
		n += 1
	return n

## Los chicos de un club. La media sale de `rep - 24` y el techo de sumarle entre
## 6 y 26 puntos (sesgado hacia abajo): media baja, potencial alto, que es la regla de la casa.
func _camada_de(c: Club) -> Array[Jugador]:
	var m := _mundo()
	var salida: Array[Jugador] = []
	var cuantos := Azar.ent(CAMADA_MIN, CAMADA_MAX)
	var bono := bono_de_camada()
	var mult := multiplicador_de_reputacion()
	for i in cuantos:
		if c.plantilla.size() >= TOPE_PLANTEL:
			break
		var grupo := grupo_con_tope(c, String(Azar.uno(["POR", "DEF", "DEF", "MED", "MED", "DEL"])))
		var edad := Azar.ent(16, 18)
		## Por encima de rep 80 la base se aplana (25-10): un grande sacaba chicos de 16 con 71-77.
		var base := c.rep - 24 if c.rep <= 80 else 56 + int(round(float(c.rep - 80) * 0.3))
		var ovr := base + Azar.ent(-4, 8)
		var j := m.crear_jugador(c, grupo, demarcacion_de(grupo), edad, ovr)
		## El techo SESGADO (25-10, paquete cant): con +6..26 plano, la camada media de un grande pasaba de
		## 90 y en cinco temporadas tu club sin tocar nada tenía nueve 80+ con menos de 23. Ahora +6..26 sigue
		## siendo posible, pero la mayoría se queda en +6..14: la promesa de verdad es una de cada cinco.
		var techo := j.ovr + 6 + int(round(20.0 * pow(Azar.f(), 2.0)))
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
	j.cambiar_moral(-6, "Cantera")

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
		## DINASTÍA PROPIA (fase 5): el hijo de TU jugador retirado llega siempre
		## a la cantera del club que diriges ahora.
		var propio := bool(L.get("propio", false))
		if propio:
			destino = m.mi_club()
		elif destino == null or not Azar.suerte(0.7):
			destino = m.clubes.get(String(Azar.uno(m.clubes.keys())))
		if destino == null or destino.plantilla.size() >= TOPE_PLANTEL:
			continue
		var grupo := String(L.get("pos", "MED"))
		if not Azar.suerte(0.7):
			grupo = String(Azar.uno(["POR", "DEF", "MED", "DEL"]))
		grupo = grupo_con_tope(destino, grupo)
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
			"propio": propio,
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
		if propio:
			noticia.emit("👨‍👦 Tu hijo llega a la cantera",
				"%s, tu hijo, se incorpora a la cantera de %s. Lleva tu apellido y tu forma de pisar el área. Ahora el entrenador eres tú." % [j.nombre, destino.nombre])
		elif destino.id == mio_id or (club_padre != null and club_padre.id == mio_id):
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
