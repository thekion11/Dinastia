class_name Mundo
extends RefCounted
## El estado de una partida: los clubes, los jugadores y las ligas.
##
## Es lo que en el HTML era la variable global `G`, un objeto suelto que
## cualquiera de las 847 funciones podia modificar sin avisar. Aqui es un objeto
## con dueno: quien quiera cambiar algo pasa por sus metodos, y las senales
## avisan a la interfaz sin que el simulador sepa que existe una interfaz.

signal semana_avanzada(semana: int, anio: int)
signal temporada_terminada(anio: int, campeon: Club)

## El último mundo creado, para lo que se dibuja sin tener el mundo a mano (los
## patrocinadores de la camiseta, `SponsorKit`). Débil: no lo mantiene vivo.
static var _ultimo: WeakRef = null

static func actual() -> Mundo:
	return _ultimo.get_ref() as Mundo if _ultimo != null else null

func _init() -> void:
	_ultimo = weakref(self)

var semilla: int = 0
var anio: int = 2026
var semana: int = 1
var clubes: Dictionary = {}       ## id -> Club
var ligas: Array[Liga] = []
var mi_club_id: String = ""

## El mercado necesita ver el mundo entero para tasar (el precio depende de la
## caja del club vendedor) y para buscar objetivos. Se crea con el mundo.
var mercado: Mercado

## La copa nacional de la temporada. Se juega en paralelo a la liga: una ronda
## cada cuatro jornadas, que es lo que hace que el calendario apriete de verdad.
var copa: Copa

## La directiva de TU club y tu cuerpo tecnico. Solo tuyos: los otros 383 clubes
## no necesitan que nadie les exija ni que les paguen un ayudante, y simularlo
## para todos seria gastar en algo que nadie va a ver nunca.
var directiva: Directiva
var staff: Staff = Staff.new()
var obras: Instalaciones = Instalaciones.new()
var entrenamiento: Entrenamiento
var cesiones: Cesiones
var vestuario: Vestuario
var selecciones: Selecciones
var cantera: Cantera
## Los chicos de 10 a 16 años de tu club, antes de ser jugadores (`Academia`).
var academia: Academia
var ojeadores: Ojeadores

## `G.libro` del HTML: el registro de movimientos de caja de tu club. Siete
## clases -Finanzas, Cesiones, Cantera, Federacion, Prensa, Selecciones,
## EstadioPropio- tienen una señal `movimiento(concepto, monto)` desde hace
## tiempo, y ninguna la escuchaba nadie: los pagos pasaban de verdad -la caja
## sí se movía- pero no quedaba ni rastro de POR QUÉ. Se llena en
## `_anotar_movimiento()`, conectada una vez por cada fuente.
var libro_financiero: Array[Dictionary] = []
const LIBRO_MAX := 60

func _anotar_movimiento(concepto: String, monto: int) -> void:
	libro_financiero.append({"concepto": concepto, "monto": monto, "anio": anio, "semana": semana})
	while libro_financiero.size() > LIBRO_MAX:
		libro_financiero.pop_front()

## El rol puede cambiar SIN pasar por `tomar_el_mando()` -un ayudante que
## asciende, un director que compra el club-, así que `Directiva.puede_despedirte`
## no se puede fijar solo una vez: tiene que seguir al rol mientras dure la carrera
## en este club.
func _rol_cambio_directiva(_antes: String, _ahora: String) -> void:
	if directiva != null:
		directiva.puede_despedirte = roles.le_pueden_echar()
## `Roles` necesita ver el mundo, asi que se crea en `generar()`, no aqui: en la
## declaracion todavia no existe el `self` que hay que pasarle.
var roles: Roles
var federacion: Federacion = Federacion.new()
var estadio: EstadioPropio = EstadioPropio.new()
var prensa: Prensa
var medico: Medico
## Los desafíos activos de esta partida (claves de la tabla `DESAFIOS`), del
## paso 5 del asistente del HTML. Se eligen una vez, al empezar, y no cambian
## -por eso viven como un simple array del Mundo y no como una clase propia
## con `_mundo()` en `WeakRef`, que es para lo que necesita ver el mundo por
## fuera de sí mismo.
var desafios: Array[String] = []

## `G.libres` del HTML: futbolistas sin club, fichables sin traspaso -solo una
## prima de fichaje y el sueldo-. Es del MUNDO, no de tu club -cualquier club
## podría fichar de aquí, aunque hoy solo lo hace el tuyo-, así que vive junto
## a `copa`/`continentales`, no dentro de `_restaurar_lo_tuyo()`.
var libres: Array[Jugador] = []
signal libre_estrella(j: Jugador)

## La gente que llena el estadio: segmentos, abonos y encuestas. Solo de TU
## club, como la prensa o el vestuario.
var hinchada: Hinchada
## `vGente()`: las diez personas del club. Ver `nucleo/gente.gd`.
var gente: Gente
## `vClubIn()`: vestuario, sala de prensa, palco y lo digital.
var club_dentro: ClubDentro
## El presidente del club, los accionistas y la junta trimestral (C5).
var junta: Junta
## Las charlas uno a uno con cada jugador y las promesas hechas (C7).
var charlas: Charlas
## La licencia de entrenador y sus exámenes (C7).
var licencia: Licencia
## Los trabajadores de las instalaciones y sus eventos (C10), y los asuntos de
## la cantera (C11).
var trabajadores: Trabajadores
var eventos_cantera: EventosCantera
var calendario: Calendario
var politica: Politica
var contratos: Contratos
var vida: VidaDT
var maestria: Maestria
## El resultado de tu último partido de liga para `VidaDT`: 1, 0, -1, o 2 si no hubo.
var _resultado_semana: int = 2
## `vBanco()`: deuda, cuotas y el reloj de la liquidación.
var banco: Banco
## La marca del pecho: ofertas, firma y exigencia contractual.
var auspicio: Auspicio
## Epocas doradas y decadencias: un pais entero ganando o perdiendo una camada.
## Lo que se vende del club: kits, proveedor, zonas de patrocinio y naming.
var comercial: Comercial
## El club y su barrio: terrenos, negocios, vecinos, permisos y seguridad.
var ciudad: Ciudad
## Si tu club gano su ultimo partido. Lo escribe `_avisar_a_la_directiva()` y lo
## lee el desgaste del entrenador: ganar descansa.
var _gano_la_ultima: bool = false
var eras: Eras = Eras.new()   ## se recrea con el mundo en `generar()`

func tiene_desafio(k: String) -> bool:
	return desafios.has(k)

## El "fin de partida" del desafío invicto: no bloquea nada por dentro -el
## motor sigue, se puede seguir jugando si se quiere-, es la bandera que la
## interfaz lee para plantar "FIN DE LA PARTIDA" delante, igual que hace
## `despedido_ya` de Directiva.
var fin_partida: Dictionary = {}

## Cuántas temporadas seguidas llevas en el mismo club: lo que hace que el
## desafío "trotamundos" te eche solo a las dos. Se resetea al cambiar de
## club a mano (`tomar_el_mando`), no solo cuando el desafío te obliga.
var anios_en_club: int = 0

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

static func _norm_nombre(s: String) -> String:
	var limpio := Nombres.limpiar(s).to_lower()
	var salida := ""
	for i in limpio.length():
		var c := limpio.unicode_at(i)
		## a-z, ñ, y las vocales acentuadas que usa normNombre() en el HTML.
		if (c >= 97 and c <= 122) or c == 0xf1 or c == 0xe1 or c == 0xe9 or c == 0xed or c == 0xf3 or c == 0xfa or c == 0xfc:
			salida += limpio[i]
	return salida

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

## "Crear tu Club" (`crearClubPortada()` del HTML): funda un club de cero
## tomando el puesto del colista de un país -en Chile, el colista de Ascenso;
## en el resto, el más flojo de su única división, porque ahí no hay Ascenso
## en los datos-, con su plantel entero rehecho a la reputación de fundación.
## No pisa nombres ni escudos de nadie más: solo cambia el club que ya iba a
## ser el peor de la tabla.
##
## Devuelve el club fundado, o null si no hay candidato en ese país -no
## debería pasar nunca con las 24 ligas generadas, pero un país vacío no
## puede reventar el fundador.
const REP_FUNDACION := 58

func fundar_club(nombre_club: String, pais: String) -> Club:
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
	c.color1 = "#1e4030"
	c.color2 = "#c9a227"
	c.plantilla.clear()
	_poblar(c)
	tomar_el_mando(c.id)
	return c

func _demarcacion_al_azar(grupo: String) -> String:
	var t: Variant = Datos.tabla("POS_POR_GRUPO")
	if t is Dictionary and (t as Dictionary).has(grupo):
		return String(Azar.uno(t[grupo]))
	return "MC"

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

## `TIENDA_DEF` y `toggleTienda()` del HTML: líneas de producto que se lanzan
## pagando el montaje una vez y luego venden todos los meses. Lo que las hace
## interesantes es de qué dependen: de los SOCIOS (cada socio es un cliente) y
## del ÁNIMO de la hinchada, así que la tienda rinde cuando el equipo ilusiona.
##
## Del HTML entran tres de las cuatro: falta "Peluche de la mascota", que
## depende de un sistema de mascota que Godot no tiene. Documentado, no colado
## a medias.
## `G.normas` del HTML: el reglamento interno. Cuatro decisiones con efecto de
## verdad, no adornos -cada una cuesta o da algo, y ninguna es gratis-:
##  · multas    → un lío nocturno se cobra caro, pero al multado le baja la moral
##  · queda     → toque de queda: −1 de moral cada seis semanas a todo el plantel,
##                a cambio de que los polémicos den menos problemas
##  · conc      → concentración previa a cada partido de local: cuesta dinero y
##                da +2 de físico a todos
##  · primas    → primas por objetivos: se pagan al cumplir, y suben la moral
var normas := {"multas": true, "queda": false, "conc": false, "primas": false}
const NORMAS_DEF := [
	["multas", "Multas del reglamento interno",
		"Un lío fuera de la cancha se cobra caro. Entra dinero, pero al multado le baja la moral."],
	["queda", "Toque de queda",
		"Cuesta un punto de moral a todo el plantel cada seis semanas, y a cambio los jugadores conflictivos dan menos guerra."],
	["conc", "Concentración antes de jugar en casa",
		"Hotel y logística por cada partido de local. El plantel llega con dos puntos más de físico."],
	["primas", "Primas por objetivos",
		"Se pagan al cumplir lo que pide la directiva, y el vestuario lo celebra con seis puntos de moral."],
]

const TIENDA := {
	"buf": {"nombre": "Bufandas", "montaje": 60000, "por_socio": 2.2},
	"taza": {"nombre": "Tazones", "montaje": 40000, "por_socio": 1.4},
	"alb": {"nombre": "Álbum de figuritas", "montaje": 120000, "por_socio": 3.0},
}
var tienda: Dictionary = {}

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
var logros: Logros

## Los torneos continentales de la temporada, por clave de confederacion
## ("lib", "sud", "ucl", "uel"...). Se sortean al empezar cada temporada.
var continentales: Dictionary = {}

var _seq_jugador: int = 0
## Que el mundo generado al empezar -8.000 y pico jugadores, ninguno pasado
## por `crear_jugador()` con un `Entrenamiento` ya vivo- reciba UNA vez sus
## habilidades de nacimiento. No se guarda en la partida a propósito: si una
## carga la vuelve a disparar, `Entrenamiento.desde_dic()` -que corre justo
## después, en `partida.gd`- pisa el sorteo con los datos de verdad guardados.
var _habilidades_sembradas: bool = false
var _seq_club: int = 0

func mi_club() -> Club:
	return clubes.get(mi_club_id)

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

func liga_de(c: Club) -> Liga:
	for l in ligas:
		if l.clubes.has(c):
			return l
	return ligas[0] if not ligas.is_empty() else null

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
func _poblar(c: Club) -> void:
	var plan: Array = Datos.tabla("PLAN_PLANTEL")
	var base := c.rep - 9
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
	_repartir_dorsales(c)

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

## `edad` y `ovr` a -1 significan "sortealos tu": lo usan los canteranos que
## suben a final de temporada, donde no hay una plantilla que respetar.
func crear_jugador(c: Club, grupo: String, demarcacion: String, edad: int = -1, ovr: int = -1) -> Jugador:
	_seq_jugador += 1
	var j := Jugador.new()
	j.id = "j%d" % _seq_jugador
	j.club_id = c.id
	j.club_formacion = c.id
	j.pos = grupo
	j.pos_e = demarcacion
	j.pais = c.pais
	j.region = Regiones.region_para(c.pais, j.id, c)
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

## HASTA HOY (22-9-2026): sin `pais`, TODO el mundo -los ~8.000 jugadores del
## arranque más cada canterano- salía con apellido chileno (`NOMBRES`/
## `APELLIDOS`, el fondo de fábrica), jugara en Alemania, Japón o Arabia
## Saudita. El usuario lo pidió explícito ("usa apellidos de los canteranos
## según su nacionalidad"), y la infraestructura para esto YA EXISTÍA -
## `POOLS_EU` (13 países) + `NOMBRES_BRA`/`APELLIDOS_BRA`- pero solo se
## usaba para el DT rival en la previa (`previa.gd::_nombre_dt()`) y para
## ojeadores extranjeros (`ojeadores.gd`), nunca para el jugador mismo, que
## es el 90% del mundo. Mismo criterio que `previa.gd`: `POOLS_EU` primero,
## BRA aparte; el resto (CHI/ARG/PER/URU/COL... hispanohablantes sin bolsa
## propia todavía) cae al fondo chileno de siempre -no a `NOMBRES_EXT`/
## `APELLIDOS_EXT` (para el DT "genérico" sin nacionalidad reconocida): un
## jugador peruano se lee mejor con un apellido hispano real que con uno
## inventado sin origen ninguno-. `ESP` se sumó a `POOLS_EU` en esta misma
## ronda (con sabor vasco a propósito -Etxeberria, Agirre, Garmendia...-,
## a pedido del usuario, mencionando el Athletic Club de Bilbao).
##
## Nunca devuelve el nombre de un futbolista real (`Nombres.vetado()`).
func _nombre_al_azar(pais: String = "", region: String = "") -> String:
	return Nombres.sin_vetar(func() -> String: return _sortear_nombre(pais, region))

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
	return "%s %s" % [Azar.uno(n), Azar.uno(a)]

func _rasgo_al_azar() -> String:
	## Que la mayoria no tenga rasgo es intencionado: si todos tienen uno, tener
	## uno deja de significar nada.
	if not Azar.suerte(0.34):
		return ""
	var r: Dictionary = Datos.tabla("RASGOS")
	if r == null or r.is_empty():
		return ""
	return String(Azar.uno(r.keys()))

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

const MOTIVOS_LIBRE := [
	"Rescindió por sueldos impagos", "Su club descendió y lo dejó libre",
	"No renovó y quedó sin equipo", "Volvió del extranjero sin club",
	"Se recuperó de una lesión larga y nadie lo llamó",
	"Rompió el contrato tras una pelea con su DT",
]

## `generarLibres()` del HTML: entre 10 y 16 nombres sin club, la primera vez
## que hace falta la bolsa (igual que `if(!G.libres.length)generarLibres()`).
func generar_libres() -> void:
	for i in Azar.ent(10, 16):
		libres.append(_nuevo_libre())

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

## Avanza una semana: jornada, dinero, mercado y recuperación, en ese orden.
##
## El orden importa. Los sueldos se pagan DESPUÉS de la taquilla de la jornada,
## que es como funciona un club de verdad: primero entra lo del domingo y luego
## se paga. Al revés, un club justo de caja se le quedaba en números rojos un
## día antes de cobrar y la IA lo daba por arruinado.
## `ya_jugado` es el partido que el entrenador acaba de dirigir en directo: se
## anota su resultado en vez de volver a simularlo.
func avanzar_semana(ya_jugado: Partido = null) -> void:
	## EL CONTEXTO DE LA SEMANA PARA TODOS LOS PARTIDOS que se van a jugar: el
	## recorte de tarjetas por videoarbitraje -que vota la asamblea- y el parte
	## medico de tu club. `Liga`, `Copa` y `Continental` crean sus partidos por
	## dentro y no conocen el mundo, asi que se les deja puesto antes de empezar.
	Partido.ctx_factor_tarjetas = federacion.factor_tarjetas() if federacion != null else 1.0
	Partido.ctx_medico = medico
	Partido.ctx_club_id = mi_club_id
	Partido.ctx_anio = anio
	Partido.ctx_semana = semana
	## EL CÉSPED DE TU ESTADIO. `Ciudad.penalizacion_cesped()` -"el único
	## efecto" del césped, dice su propio comentario- llevaba escrita desde
	## siempre sin que nadie la multiplicara en ningún cálculo de partido:
	## alquilar el estadio para un concierto rompía el pasto solo en
	## apariencia, sin costo deportivo. Mismo mecanismo de contexto que
	## `ctx_club_id`: se calcula una vez por semana, no dentro del bucle de
	## fuerzas.
	Partido.ctx_cesped_local = ciudad.penalizacion_cesped() if ciudad != null else 1.0
	## B6.5: la superficie decide cuánto de ese desgaste llega al campo y cuánto
	## se lesiona la gente en él.
	if estadio != null:
		Partido.ctx_cesped_local = lerpf(1.0, Partido.ctx_cesped_local, estadio.factor_desgaste_cesped())
		Partido.ctx_lesion_local = estadio.factor_lesion()
	## La moda de la era, para todos los dibujos que existen. Se calcula una vez
	## por semana y no dentro del bucle de fuerzas, que corre miles de veces.
	Partido.ctx_analisis = consumir_analisis()
	Partido.ctx_moda = {}
	var formas: Variant = Datos.tabla("FORMS")
	if formas is Dictionary:
		for f: String in (formas as Dictionary):
			Partido.ctx_moda[f] = factor_moda(f)
	## Si el banco no es tuyo, el entrenador arma su equipo ANTES de la jornada,
	## con tus indicaciones si te hace caso. Va aquí y no dentro de `Liga` para
	## que solo afecte a tu club: los otros 383 ya tienen su propio automático.
	## LA ROTACION, antes que nada: si esta puesta, los fundidos salen del once
	## y entran los frescos. Va antes de las directrices porque el entrenador
	## empleado puede querer cambiar el once despues, y manda el.
	var rotados := aplicar_rotacion()
	if rotados > 0 and prensa != null:
		prensa.noticia.emit("Rotacion",
			"%d cambio(s) en el once: los que llegaban fundidos descansan." % rotados)
	if roles != null and mi_club() != null:
		roles.aplicar_directrices(mi_club())
		## Y con el once ya armado se anota con qué modelo saliste. Va DESPUÉS
		## de las directrices a propósito: si el entrenador empleado te cambió
		## el dibujo, la escuela que nazca es la suya, no la que tú pediste.
		roles.chequeo_filosofia(mi_club().tactica)
	var jugaron_en_casa := {}
	for l in ligas:
		if l.quedan_jornadas():
			## Se anota quién jugó en casa ANTES de jugar la jornada, porque
			## `jugar_jornada` ya avanza el contador y después no hay forma de
			## saber a quién le tocaba taquilla.
			for par: Array in l.calendario[l.jornada_actual]:
				## Se guarda el RIVAL, no solo que se jugo en casa: los precios
				## dinamicos cobran segun contra quien se juega, y despues de la
				## jornada ya no hay forma de saberlo.
				jugaron_en_casa[par[0].id] = par[1]
			var resultados := l.jugar_jornada(ya_jugado)
			_avisar_a_la_directiva(resultados)

	for c: Club in clubes.values():
		var soy_yo := c.id == mi_club_id
		var f := Finanzas.new(c, obras.aporte_ocupacion() if soy_yo else 0.0,
			directiva.honorarios_semanales() if soy_yo and directiva != null else 0,
			(0.1 if soy_yo and directiva != null and directiva.tiene_consejero("mkt") else 0.0))
		if c.id == mi_club_id:
			f.movimiento.connect(_anotar_movimiento)
			## LOS TRES MULTIPLICADORES DE LA TELEVISION, que existian los tres y
			## no movian una moneda: el reparto que vota la asamblea y el modelo de
			## contrato que elige el club. El del horario se cobra aparte, por
			## partido, porque asi lo paga la television de verdad.
			f.factor_tv = federacion.factor_tv() * (prensa.factor_tv() if prensa != null else 1.0)
			## "OPERACIÓN, VIAJES, SEGURIDAD E IMPUESTOS": el "oper" del HTML, que
			## nunca se portó -sin él, el mundo entero cobraba television y
			## patrocinio sin devolver un 42% de eso en gastos de club, y por eso
			## `Instalaciones.abarata_operacion()` llevaba escrita desde antes sin
			## que la llamara nadie. Solo la paga tu club -los otros 383 usan el
			## ajuste de la directiva como correctivo, no esta partida suelta-.
			f.aplica_operacion = true
			f.factor_operacion = obras.abarata_operacion()
			f.factor_estructura = Contratos.factor_estructura(c.pais, anio, semana)
		var en_casa := jugaron_en_casa.has(c.id)
		## LOS PRECIOS DINAMICOS. El mismo asiento no vale lo mismo contra el
		## lider que contra el colista, y con el interruptor encendido se cobra
		## asi. Solo para tu club: la IA no juega con la caja.
		if en_casa and soy_yo and hinchada != null and hinchada.precio_dinamico:
			var rival_casa: Club = jugaron_en_casa[c.id]
			var cobrado := hinchada.precio_efectivo(int(round(c.precio_entrada)), rival_casa.rep)
			f.precio_de_hoy = float(cobrado)
			## Y la gente lo nota: subirle la entrada el dia del clasico se paga
			## en animo, que es lo que impide que esto sea dinero gratis.
			var castigo := hinchada.castigo_por_subida(int(round(c.precio_entrada)), cobrado)
			if castigo > 0 and prensa != null:
				prensa.mover_animo(-castigo)
		if en_casa and c.id == mi_club_id:
			## Se anota la asistencia real: es de donde salen los ingresos de
			## estacionamiento, que si no cobrarian sobre un cero.
			obras.ultima_asistencia = f.asistencia()
			## La concentración previa: hotel y logística por cada partido en
			## casa, a cambio de dos puntos de físico para todo el plantel.
			if bool(normas.get("conc", false)):
				var coste_conc := Eco.escalar(3500, c.rep)
				c.mover_saldo(-coste_conc)
				_anotar_movimiento("Concentración previa (hotel y logística)", -coste_conc)
				for j in c.plantilla:
					j.fisico = clampi(j.fisico + 2, 10, 100)
		## El horario elegido mueve la taquilla: un lunes por la noche llena un
		## tercio menos. El otro lado -los derechos de TV- lo cobra `Federacion`.
		## EL TECHO RETRACTIL salva la taquilla cuando llueve, que es literalmente
		## para lo que se compra. Multiplica el factor de publico del horario.
		var f_publico := factor_publico()
		if soy_yo and comercial != null:
			f_publico *= comercial.factor_techo()
		## Y LA SANCION DEL TRIBUNAL. Puertas cerradas es cero taquilla y aforo
		## reducido es un 40%: es la unica forma que tiene el juego de cobrarte un
		## incidente en el estadio, y por eso vale la pena pagar seguridad.
		if soy_yo and ciudad != null:
			f_publico *= ciudad.factor_aforo()
		## C13: una semana de fiesta nacional llena más el estadio (y una de
		## memoria no: con duelo no hay fiesta).
		if soy_yo:
			f_publico *= Calendario.factor_publico(c.pais, anio, semana)
			if maestria != null:
				f_publico *= maestria.factor_publico()
		f.semana(en_casa, false, f_publico)
		## EL PLUS DE LA TELEVISION POR EL HORARIO. Un lunes por la noche no va
		## nadie al estadio y paga mucho mas la television: sin este cobro, elegir
		## horario era regalar taquilla a cambio de nada.
		if en_casa and c.id == mi_club_id:
			var plus_h := factor_tv_horario()
			if plus_h > 1.0:
				var plus := int(round(float(f.derechos_tv_base()) * (plus_h - 1.0) * 0.6))
				if plus > 0:
					c.mover_saldo(plus)
					_anotar_movimiento("Plus de televisión por el horario %s" % String(horario_actual()[1]), plus)
		## El embajador suma socios TODAS las semanas -"G.socios+=25" del HTML
		## corre en su función semanal, a diferencia del sueldo del cuerpo
		## técnico, que Godot ya paga en un solo pago mensual-.
		if c.id == mi_club_id and directiva != null and not directiva.embajador.is_empty():
			c.socios += Directiva.SOCIOS_POR_SEMANA_EMBAJADOR
		if semana % Finanzas.SEMANAS_DEL_MES == 0:
			f.mes()
			## El cuerpo tecnico cobra con el resto de la nomina. Asi un staff
			## grande aprieta la caja TODOS los meses, no solo el dia que se ficha.
			if c.id == mi_club_id:
				var st := staff.sueldo_semanal(c.rep) * Finanzas.SEMANAS_DEL_MES
				if st > 0:
					c.mover_saldo(-st)
				## El entrenador empleado -o tu jefe, si eres ayudante- tambien
				## cobra: "G.rol!=='dt'&&G.dtEmp" del HTML. Si diriges tu mismo
				## no hay a quien pagarle.
				if roles != null and roles.rol != Roles.DT and not roles.dt_empleado.is_empty():
					var sueldo_dt := Roles.SUELDO_SEMANAL_DT_EMPLEADO * Finanzas.SEMANAS_DEL_MES
					c.mover_saldo(-sueldo_dt)
					_anotar_movimiento("Sueldo del entrenador: %s" % roles.dt_nombre(), -sueldo_dt)
				if directiva != null and not directiva.embajador.is_empty():
					var sueldo_emb := int(directiva.embajador.get("sueldo", Directiva.SUELDO_EMBAJADOR_SEMANAL)) * Finanzas.SEMANAS_DEL_MES
					c.mover_saldo(-sueldo_emb)
					_anotar_movimiento("Embajador: %s" % String(directiva.embajador.get("nombre", "")), -sueldo_emb)
				## Y lo que dan la tienda, el museo y los estacionamientos: son los
				## unicos ingresos del club que no dependen de ganar partidos.
				var sube_tienda := directiva != null and directiva.tiene_consejero("mkt")
				for ing: Dictionary in obras.ingresos_del_mes(c):
					var monto: int = ing["monto"]
					if sube_tienda and String(ing["concepto"]) == "Tienda y museo":
						monto = int(round(float(monto) * 1.1))
					c.mover_saldo(monto)
				var venta := ingreso_tienda(c)
				if venta > 0:
					c.mover_saldo(venta)
					_anotar_movimiento("Tienda del club", venta)
				## Los medios propios del club: si no te gusta cómo lo cuentan,
				## cuéntalo tú. Cuestan una vez y rentan cada mes.
				if prensa != null:
					var medios_r := prensa.renta_medios(c)
					if medios_r > 0:
						c.mover_saldo(medios_r)
						_anotar_movimiento("Medios propios del club", medios_r)
				## Las ramas del club NO dan dinero: cuestan. Lo que dan es
				## reputación, y esa decisión -sostener el femenino aunque no
				## pague- es de las que definen qué clase de club llevas.
				if hinchada != null:
					var ramas_c := hinchada.coste_ramas(c)
					if ramas_c > 0:
						c.mover_saldo(-ramas_c)
						_anotar_movimiento("Ramas deportivas del club", -ramas_c)
					c.socios += hinchada.socios_de_penas()
			## La directiva cuadra las cuentas de los clubes de la IA. A tu club
			## no: ahi la caja es tuya y las consecuencias tambien.
			if c.id != mi_club_id:
				f.ajuste_de_directiva()
		for j in c.plantilla:
			if j.lesion > 0:
				j.lesion -= 1
			if j.suspension > 0:
				j.suspension -= 1
			## El preparador fisico se nota aqui: tu plantel pierde menos forma. Es
			## un solo numero, pero es el que hace que contratarlo no sea un boton
			## de gastar dinero.
			var suelo := -3 + ((staff.aguante() + obras.aguante()) if c.id == mi_club_id else 0)
			j.forma = clampi(j.forma + Azar.ent(mini(suelo, 0), 4), 20, 99)
			## Un suplente que no juega se harta. Es lo que alimenta el mercado
			## de la IA: sin gente descontenta no hay traspasos.
			## Con una prima de fidelidad vigente no pide salir -esa es la promesa
			## que se le pagó, ofrecerFidelidad() del HTML-.
			if j.partidos == 0 and semana > 6 and (j.fidelidad_hasta <= 0 or anio >= j.fidelidad_hasta) and Azar.suerte(0.02):
				j.pide_salir = true

	## La memoria del club: cara a cara, rachas y récords. Solo el partido que
	## dirigiste en directo trae el `Partido` completo con el once y los
	## goleadores -`Liga.jugar_jornada()` descarta esos datos para los que solo
	## se simulan por dentro, así que semanas sin dirigir no alimentan la
	## memoria. Es una limitación conocida, no un olvido.
	if ya_jugado != null and logros != null and mi_club() != null \
			and (ya_jugado.local == mi_club() or ya_jugado.visita == mi_club()):
		## Antes solo distinguía Copa/Liga: un continental dirigido en vivo
		## quedaba anotado como "Liga" en la memoria del club, mentira chica
		## pero mentira -ahora que `_dirigir()` sí puede llevarte a uno-.
		var competicion := "Liga"
		if _copa_es_de(ya_jugado):
			competicion = "Copa"
		elif _continental_es_de(mi_continental(), ya_jugado):
			competicion = "Continental"
		logros.tras_partido(ya_jugado, competicion, int(obras.ultima_asistencia))
	## El interinato se cuenta en fechas, no en semanas: `fechas_interinato_
	## restantes()` las saca del propio calendario de la liga, así que llamar de
	## más no adelanta ni atrasa nada -solo hay que no dejar de llamarla.
	if roles != null and mi_club() != null:
		roles.tras_jornada()

	mercado.mover()
	mercado.buscar_oferta_por_mi_jugador()
	if libres.is_empty():
		generar_libres()
	_procesar_libres()
	## El toque de queda: disciplina a cambio de humor. Cada seis semanas.
	if bool(normas.get("queda", false)) and semana % 6 == 0:
		var mio_normas := mi_club()
		if mio_normas != null:
			for j in mio_normas.plantilla:
				j.moral = clampi(j.moral - 1, 10, 99)
	## LESIONES ABSURDAS FUERA DE LA CANCHA (C8): raras, cortas y noticia. El
	## toque de queda evita las de noche. Sin `Azar`.
	var absurda := LesionesAbsurdas.sortear(mi_club(), anio, semana, bool(normas.get("queda", false)))
	if not absurda.is_empty():
		var ja: Jugador = absurda["jugador"]
		ja.lesionar(int(absurda["semanas"]))
		if prensa != null:
			var txt := "%s. Estará %d semana%s de baja." % [String(absurda["texto"]), int(absurda["semanas"]),
				"" if int(absurda["semanas"]) == 1 else "s"]
			prensa.noticia.emit("🤕 Lesión insólita", txt)
			prensa.guardar_portada("¡INSÓLITO! " + String(absurda["texto"]).to_upper(), txt, "mal",
				{"img": "pid:" + ja.id, "sub": txt, "medio": "Canal Deportes", "nueva": true})
			if bool(absurda["noche"]):
				prensa.mentor_dice.emit("Lo de %s" % ja.nombre,
					"Esto pasó de noche. Un toque de queda en las normas del vestuario habría evitado el disgusto.")

	## Las obras avanzan una semana. Se hace antes de la prensa para que la
	## noticia de "obra terminada" salga la misma semana en que termina.
	var mio_obras := mi_club()
	if mio_obras != null:
		for k in obras.avanzar_semana(mio_obras):
			obra_lista.emit(k)

	## El ojeador trae informes: descubre el techo real de un chico de otro club.
	## Es lo unico que hace que fichar a ciegas y fichar informado se distingan.
	_informes_de_ojeo()
	## El humor de la red de ojeadores por nombre -si nunca les haces caso,
	## renuncian y se pierde la cobertura de su país-.
	if ojeadores != null:
		ojeadores.procesar_semana()
		## EL MODELO DE DATOS busca por su cuenta, y a partir del nivel dos se pelea
		## con el ojeo de siempre. El nivel del jefe de ojeadores decide si hay
		## guerra: sin vieja escuela en casa no hay con quien discutir.
		ojeadores.semana_analitica(staff.nivel("ojo") if staff != null else 0)
		## Y las sedes internacionales cuestan todas las semanas, se use o no la
		## joya que traen en pretemporada.
		if mi_club() != null:
			var mant := ojeadores.mantencion_academias(mi_club())
			if mant > 0:
				mi_club().mover_saldo(-mant)
				_anotar_movimiento("Academias internacionales", -mant)

	## El pulso de la semana fuera del campo: prensa, parte medico y continental.
	if prensa != null:
		prensa.semana()
		prensa.semana_redes()
		prensa.sortear_evento()
		## El vocero se va con el jugador: si lo vendes, el club se queda mudo.
		prensa.revisar_vocero(mi_club())
		## LA PRESION DEL FONDO. Si vendiste un porcentaje de un canterano, el que
		## lo compro quiere cobrar, y aparece a pedir que lo vendas. Decir que no
		## cuesta moral del chico: su entorno le come la cabeza.
		if cesiones != null and prensa.pendiente.is_empty():
			var pf := cesiones.presion_de_fondo()
			if not pf.is_empty():
				var jf: Jugador = pf["jugador"]
				prensa.pendiente = {
					"id": "fondo_presiona", "pid": jf.id,
					"txt": "💸 %s" % String(pf["texto"]),
					"opcion_a": "Ponerlo en el mercado", "opcion_b": "No se vende",
				}
				prensa.evento_creado.emit(prensa.pendiente)
		## La hinchada se mueve DESPUÉS de la prensa, que es quien acaba de
		## actualizar el ánimo: al revés reaccionaría al ánimo de la semana
		## pasada y los segmentos irían siempre un paso por detrás.
		if hinchada != null:
			hinchada.semana(prensa.animo)
	## EL UTILERO. Un punto de moral a todo el plantel cuando llega a nivel 3.
	## Es lo mas pequeño que hace un puesto del cuerpo tecnico, y es a proposito:
	## es el que se contrata cuando ya esta todo lo demas.
	if staff != null and mi_club() != null:
		var util := staff.bono_utilero()
		if util > 0:
			for j in mi_club().plantilla:
				j.moral = clampi(j.moral + util, 10, 99)
	## LOS DIAS SEÑALADOS y lo que dejan las figuras por su marca personal. Los
	## dos son del HTML y no estaban portados: la temporada eran cuarenta y dos
	## semanas iguales, y tener una estrella no daba un peso de mas.
	_procesar_fiesta()
	if mi_club() != null:
		var marca := ingreso_marca()
		if marca > 0:
			mi_club().mover_saldo(marca)
			_anotar_movimiento("Marca personal de tus figuras", marca)
	if gente != null:
		gente.semana()
	## El sueldo del entrenador va a SU bolsillo, no a la caja del club: son dos
	## dineros distintos y esa separación es lo que hace que exista una carrera
	## personal por encima de la gestión.
	## EL DESCUENTO DEL CONTABLE en la nomina del cuerpo tecnico. Se refresca
	## cada semana porque el arbol puede crecer entre una y otra.
	if staff != null and entrenamiento != null:
		staff.factor_sueldos = entrenamiento.factor_sueldo_staff()
	if roles != null:
		roles.semana_patrimonio()
		## EL DESGASTE. Una semana en el cargo cansa; ganar descansa y la funa
		## quema. No te echa nunca: te deja trabajando peor, que es distinto.
		roles.semana_desgaste(_gano_la_ultima, prensa.funa if prensa != null else 0)
		## LA CARRERA POR DENTRO: el rival personal aparece solo cuando hay con
		## quien picarse, la leyenda viva visita cada seis semanas y los clubes
		## filiales reparten dividendos cada tres meses.
		roles.buscar_rival_dt()
		## QUE TE QUIERA OTRO CLUB. Lo unico del juego que te ofrece IRTE: sin
		## esto, la unica forma de cambiar de banquillo es que te echen.
		var of := roles.sortear_oferta_de_club()
		if not of.is_empty() and prensa != null:
			prensa.noticia.emit("Te quiere %s" % String(of["nombre"]),
				"Han llamado desde %s: te ofrecen su banquillo. Puedes contestar en Club › Legado." % String(of["nombre"]))
		roles.semana_leyenda_viva()
		roles.semana_filiales()
	if club_dentro != null and mi_club() != null:
		club_dentro.semana(mi_club(), prensa)
		## La app y la web CRECEN cada semana -"procesoClubIn()" del HTML corre
		## en el mismo proceso semanal que la prensa o la cantera, no en el
		## cierre de mes-, y crecen más rápido si vienes ganando en liga.
		for mov: Dictionary in club_dentro.crecer_digital(mi_club(), prensa):
			_anotar_movimiento(String(mov["concepto"]), int(mov["monto"]))
	if junta != null and mi_club() != null:
		junta.semana(mi_club(), anio, semana)
	if charlas != null and mi_club() != null:
		charlas.semana(mi_club(), anio, semana)
	if trabajadores != null and mi_club() != null:
		trabajadores.semana(mi_club(), obras, anio, semana, prensa)
	if eventos_cantera != null and mi_club() != null:
		eventos_cantera.semana(academia, mi_club(), anio, semana)
	if calendario != null and mi_club() != null:
		calendario.semana(mi_club(), anio, semana)
	if politica != null and mi_club() != null:
		politica.semana(mi_club(), anio, semana, prensa)
	if contratos != null and mi_club() != null:
		contratos.semana(mi_club(), anio, semana)
	if maestria != null and mi_club() != null:
		maestria.semana(mi_club(), prensa, academia, semana, _resultado_semana)
	if vida != null and mi_club() != null and roles != null:
		vida.semana(mi_club(), roles, anio, semana, _resultado_semana)
		_resultado_semana = 2
	if banco != null and mi_club() != null:
		## Los dos consejeros que hasta hoy decían "sin efecto" en su propia
		## descripción (`Directiva.CONSEJEROS`, `fin`/`leg`): era cierto
		## cuando se escribió, antes de que `Banco` existiera, pero se quedó
		## así después -un jugador podía pagarle a un consejero por algo que
		## de verdad no hacía nada, sin que nada avisara-. El financiero
		## abarata el sobregiro un 35%; el legal da tres semanas más antes de
		## la liquidación. Se fija cada semana -barato, y así no hace falta
		## enganchar un aviso aparte a contratar/despedir-.
		if directiva != null:
			banco.descuento_sobregiro = 0.65 if directiva.tiene_consejero("fin") else 1.0
			banco.gracia_liquidacion = 3 if directiva.tiene_consejero("leg") else 0
		banco.semana(mi_club())
	## EL AUSPICIO GOTEA TODAS LAS SEMANAS. No entra de golpe: es el `monto/42`
	## del HTML, y por eso firmar tarde cuesta dinero de verdad.
	if auspicio != null and mi_club() != null:
		var cuota_ausp := auspicio.semanal()
		if cuota_ausp > 0:
			mi_club().mover_saldo(cuota_ausp)
			_anotar_movimiento("Auspicio: %s" % auspicio.marca_en_camiseta(), cuota_ausp)
	## Y lo comercial: las cinco zonas de la camiseta, el naming del estadio, los
	## palcos y el contrato del proveedor. Todo junto en una linea porque todo
	## junto es como se cobra.
	if comercial != null and mi_club() != null:
		var renta_com := comercial.renta_semanal(mi_club())
		if renta_com > 0:
			mi_club().mover_saldo(renta_com)
			_anotar_movimiento("Explotación comercial (camiseta, estadio y palcos)", renta_com)
	## LA CIUDAD: los negocios anexos ingresan TODAS las semanas del año, jueguen
	## o no, y el resto -cesped, vecinos, permisos y sanciones- corre su plazo.
	if ciudad != null and mi_club() != null:
		ciudad.semana(mi_club(), prensa.animo if prensa != null else 60)
		if semana % 4 == 0:
			ciudad.mes()
	if medico != null and mi_club() != null:
		## OJO: va DESPUES del bucle que descuenta la semana de baja. Si fuera
		## antes, tu plantel se curaria al doble de velocidad que el de los
		## rivales y no se veria en ninguna pantalla.
		## La carga de la semana sale del PLAN de entrenamiento, no de una constante:
		## es lo que hace que apretar en los entrenamientos se pague en la enfermeria.
		var carga := entrenamiento.carga_riesgo() if entrenamiento != null else Medico.CARGA_POR_DEFECTO
		medico.revisar_semana(mi_club(), carga, anio, semana)
		## EL BROTE: una gripe que se lleva a media plantilla unos días. Cae dos
		## veces cada tres temporadas -0,7% semanal- y dura dos o tres semanas.
		## Es el único evento del juego que obliga a rotar de golpe, y por eso no
		## puede ser frecuente: si pasara cada mes dejaría de ser una urgencia.
		medico.avanzar_brote()
		if medico.brote.is_empty() and Azar.suerte(0.007):
			medico.iniciar_brote(mi_club(), Azar.ent(4, 8), Azar.ent(2, 3))
	if entrenamiento != null and mi_club() != null:
		entrenamiento.procesar_semana(mi_club(), anio, semana)
		## EL RESTO DEL MUNDO TAMBIÉN ENTRENA. `procesar_ajeno()` existía desde
		## hace tiempo -recuperación de físico y una progresión simple, sin foco
		## ni intensidad ni instalaciones, igual que `semEntrenamiento()` trata a
		## quien no es tuyo en el HTML- pero nadie la llamaba: el propio
		## comentario del código ya avisaba "sin esto, los rivales se quedan
		## congelados y en tres temporadas tu cantera domina el continente
		## sola". Va DESPUÉS de tu plantel y no antes, por la misma razón que el
		## médico: que tu progreso no dependa del orden en que se recorra nada.
		for c: Club in clubes.values():
			if c.id == mi_club_id:
				continue
			for j: Jugador in c.plantilla:
				entrenamiento.procesar_ajeno(j)
	## La federacion: votaciones, cupos y auditoria.
	if mi_club() != null:
		federacion.semana(mi_club(), anio, semana)
		## El vestuario va DESPUES del bucle que descuenta lesiones: la baja
		## psicologica se cobra escribiendo `j.lesion`, y antes se la comeria el
		## descuento de la misma semana.
		if vestuario != null:
			vestuario.semana(semana)
			## EL SUCESO DEL CAMARIN. Una cosa pequeña por semana -el polemico se va
			## de fiesta, el lider reune al grupo, alguien cumple años-. Sin esto,
			## los rasgos de personalidad eran etiquetas que no pasaban nunca.
			vestuario.suceso_semanal()
			## LAS SOLICITUDES DEL PLANTEL. `sortear_solicitud()`/`resolver_solicitud()`
			## existían enteros -catálogo de siete peticiones, candidatos según la
			## situación real de cada uno- sin que nadie los llamara: ningún
			## jugador le pedía nunca nada al DT. Se tira una vez por semana, igual
			## que `suceso_semanal()`.
			vestuario.sortear_solicitud(obras)
		if cesiones != null:
			cesiones.pagar_cuotas(semana, mi_club())
			cesiones.revisar_bonos(mi_club())
		## La selección: prenómina, fecha FIFA y sus efectos en físico y moral.
		## Va aquí y no antes del descuento de lesiones por la misma razón que el
		## vestuario -si no, un jugador que vuelve tocado de gira se curaría la
		## misma semana en vez de perder las que le tocan.
		if selecciones != null:
			selecciones.semana(anio, semana)
		## La cantera: fugas de canteranos sin ficha profesional, y la presion de
		## la prensa sobre el que carga con un apellido ajeno.
		if cantera != null:
			cantera.procesar_semana()
			cantera.sortear_guerra_agentes()
		## La academia de 10 a 16: crecimiento, colegio, comida y la familia.
		if academia != null:
			academia.procesar_semana()
		## Y se recalculan los bonificadores: si no, el factor del camarin se queda
		## congelado en el de la semana en que tomaste el mando.
		aplicar_bonificadores()
	var fecha_conti := Continental.toca_ronda(semana)
	if fecha_conti >= 0:
		for t: Continental in continentales.values():
			if t.en_curso():
				_fatiga_de_viaje(t)
				## `ya_jugado` -el partido que acabas de dirigir en vivo, si
				## era justo este cruce- para no volver a simularlo por
				## dentro y que el marcador que viste no coincida con el que
				## queda anotado. Hasta esta tanda esto se llamaba en blanco
				## SIEMPRE: `_dirigir()` no sabía llevarte a un continental,
				## así que nunca hacía falta -ahora sí-.
				var res_c: Array = t.jugar_ronda(ya_jugado if _continental_es_de(t, ya_jugado) else null)
				_rueda_de_eliminatoria(res_c, "conti", t.participantes)
				## El continental se corona a mitad de temporada, no al cierre:
				## por eso esta celebración no puede esperar a cerrar_temporada()
				## como la de liga y copa. `en_curso()` pasa a false en cuanto hay
				## campeón, así que esto solo entra la semana exacta en que se
				## decide -no cada semana que quede del año.
				if t.campeon == mi_club() and logros != null:
					logros.celebrar_titulo(Continental.nombre_conti(t.clave))

	## La copa: una ronda cada cuatro jornadas, en paralelo a la liga. Se monta
	## la primera vez que hace falta y no al generar el mundo, porque al generar
	## todavía no se sabe qué club diriges y la copa es la de TU país.
	if copa == null:
		_montar_copa()
	if copa != null and copa.en_curso() and semana % 4 == 0:
		var res_copa: Array = copa.jugar_ronda(ya_jugado if _copa_es_de(ya_jugado) else null)
		_rueda_de_eliminatoria(res_copa, "copa", copa.participantes)

	semana += 1
	semana_avanzada.emit(semana, anio)

## LA RUEDA DE PRENSA TAMBIÉN DESPUÉS DE LA COPA (26-9-2026, plan maestro C1).
## Hasta hoy solo se abría tras la liga. Con la misma tirada de siempre
## (`rueda_tras_resultado`), y avisando a la sala de qué competición es para
## que los escudos del fondo sean los de ESA competición.
func _rueda_de_eliminatoria(resultados: Array, comp: String, clubes: Array) -> void:
	var mio := mi_club()
	if prensa == null or mio == null:
		return
	for r: Dictionary in resultados:
		if r["local"] != mio and r["visita"] != mio:
			continue
		var soy_local: bool = r["local"] == mio
		var gf: int = r["gl"] if soy_local else r["gv"]
		var gc: int = r["gv"] if soy_local else r["gl"]
		var paso: bool = r.get("pasa") == mio if r.has("pasa") else gf > gc
		var loc: Club = r["local"]
		var vis: Club = r["visita"]
		prensa.clima_ultimo = Clima.del_partido(loc.pais, semana, anio, loc.id + vis.id)
		prensa.competicion_rueda = comp
		prensa.clubes_rueda = clubes.duplicate()
		prensa.rueda_tras_resultado(paso or gf > gc, gf == gc and not r.has("pasa"))
		return

## ¿El partido que se acaba de dirigir era de copa y no de liga? Hace falta para
## no anotar un resultado en la competición equivocada.
func _copa_es_de(p: Partido) -> bool:
	if p == null or copa == null:
		return false
	var par := copa.emparejamiento_de(mi_club())
	return par.size() == 2 and par[0] == p.local and par[1] == p.visita

## Lo mismo que `_copa_es_de()`, pero para UN continental concreto -hay
## varios a la vez en `continentales`, uno por confederación, y el mismo
## `ya_jugado` no puede repartirse a todos: solo al que de verdad jugaste.
func _continental_es_de(t: Continental, p: Partido) -> bool:
	if p == null or t == null:
		return false
	var par := t.emparejamiento_de(mi_club())
	return par.size() == 2 and par[0] == p.local and par[1] == p.visita

## LOS VIAJES LARGOS SE PAGAN EN LAS PIERNAS. Porte de `fatigaViaje()` +
## `aplicarFatigaViaje()` del HTML, que hasta ahora no existía en Godot: jugar de
## visita un continental contra un club de OTRO país costaba lo mismo que un
## clásico de barrio.
##
## Mismas cuentas que el HTML -golpe de 4 a 9, el once lo paga entero y el resto
## un 35%-, con dos correcciones que hay que tener escritas:
##
## 1. **El alivio.** El HTML resta `G.inst.pf*0.4 + G.staff.pf*0.6 +
##    G.inst.piscina*0.5`, pero `pf` no es una instalación sino un puesto del
##    cuerpo técnico (la lista de la línea 6014 de `juego.js`, con sueldo): ese
##    primer sumando valía 0 siempre. Aquí queda el preparador físico (`fisico`
##    en `Staff.PUESTOS`) y la piscina, que es lo que el HTML hacía en la práctica.
## 2. **El avión.** `Comercial.alivio_de_viaje()` existía, se cobraba y se
##    anunciaba ("menos fatiga en los viajes largos") y nadie lo llamaba: comprar
##    el avión no hacía nada. Ahora resta sus 3 puntos aquí.
##
## Va ANTES de `jugar_ronda()` para que el cansancio se note en ESE partido, que
## es donde el HTML lo aplica (`prepararPartido`, antes de armar el once).
func _fatiga_de_viaje(t: Continental) -> void:
	var mio := mi_club()
	if mio == null:
		return
	var par := t.emparejamiento_de(mio)
	if par.size() != 2 or par[1] != mio or par[0] == null or par[0].pais == mio.pais:
		return
	var alivio := float(staff.nivel("fisico")) * 0.6 + float(obras.nivel("piscina")) * 0.5
	if comercial != null:
		alivio += float(comercial.alivio_de_viaje())
	var f := maxi(1, int(round(float(Azar.ent(4, 9)) - alivio)))
	var once := mio.once()
	for j: Jugador in mio.plantilla:
		var golpe := float(f) if once.has(j) else float(f) * 0.35
		j.fisico = clampi(int(round(float(j.fisico) - golpe)), 10, 100)
	if prensa != null:
		prensa.noticia.emit("✈️ Vuelta de un viaje largo",
			"El plantel llegó de madrugada desde %s y paga el viaje: −%d de estado físico a los que juegan." % [
				par[0].nombre, f])

func temporada_en_curso() -> bool:
	for l in ligas:
		if l.quedan_jornadas():
			return true
	return false

func jugar_temporada() -> void:
	while temporada_en_curso():
		avanzar_semana()
	var campeon: Club = null
	if not ligas.is_empty():
		var t := ligas[0].tabla()
		if not t.is_empty():
			## `Federacion.campeon_de_liga()`, no `t[0]["club"]` directo: el
			## propio docstring de `federacion.gd` describe este bug exacto del
			## HTML -"se votaban los playoffs... y en diciembre el campeón
			## seguía siendo el primero de la tabla"- como algo que "este
			## proyecto ya pagó", pero seguía sin arreglar AQUÍ. Cuando no se
			## votó playoffs, `campeon_de_liga()` devuelve exactamente
			## `t[0]["club"]`: mismo resultado, cero riesgo.
			campeon = federacion.campeon_de_liga(t, anio, mi_club_id)
	temporada_terminada.emit(anio, campeon)

## Premio del campeón de liga. Es una cifra FIJA, no escalada al tamaño del
## club: viene así del HTML y es lo que hace que un título valga de verdad para
## un club chico. Escalarlo lo convertiría en un ingreso más de los grandes.
const PREMIO_LIGA := 500000

## Reparte los premios de la liga y mueve a los clubes entre divisiones.
##
## Se le pasan las tablas ya calculadas en vez de volver a pedirlas: son la misma
## foto que ha usado el resto del cierre, y recalcularlas aquí podría dar otra si
## algo las hubiera tocado en medio. Es la nota que dejó el propio HTML.
func cerrar_temporada() -> Dictionary:
	var resumen := {"campeones": [], "suben": [], "bajan": [], "directiva": {}}
	## LAS RAMAS TERMINAN SU TEMPORADA (C12).
	if hinchada != null and mi_club() != null and prensa != null:
		for rr: Dictionary in hinchada.temporada_ramas(mi_club(), anio):
			var p := int(rr["puesto"])
			var txt := ("¡Campeón!" if p == 1 else ("%d.º: al podio." % p if p <= 3 else "%d.º puesto." % p))
			prensa.noticia.emit("🏅 %s" % String(rr["rama"]), "Temporada terminada: %s" % txt)
			if p == 1 and String(rr["clave"]) == "femenino":
				prensa.guardar_portada("¡EL FEMENINO, CAMPEÓN!", "La rama femenina del club gana la liga.", "bien",
					{"img": "escudo", "sub": "La rama femenina gana la liga y el club suma reputación y socios.", "nueva": true})
	var tablas := {}
	## El puesto de TU club, con la foto de antes de mover a nadie.
	var mi_puesto := 0
	for l in ligas:
		tablas[l] = l.tabla()
		var t: Array = tablas[l]
		if t.is_empty():
			continue
		## Playoffs solo si se votaron -y solo pesan sobre TU liga: la
		## asamblea que los vota es la de tu federación, las demás siguen
		## coronando al primero de la tabla, que es lo que ya hacían-.
		## `campeon_de_liga()` cae en `t[0]["club"]` sola cuando no se
		## votaron, así que esto no cambia nada salvo cuando de verdad toca.
		var es_mi_liga := mi_club() != null and l.pais == mi_club().pais and l.division() == 1
		var campeon: Club = federacion.campeon_de_liga(t, anio, mi_club_id) if es_mi_liga else t[0]["club"]
		campeon.mover_saldo(PREMIO_LIGA)
		## Ganar la liga sube la reputación del club, y la reputación es la que
		## mueve la caja, la taquilla y lo que puedes fichar el año siguiente.
		campeon.rep = clampi(campeon.rep + 1, 40, 96)
		resumen["campeones"].append({"liga": l, "club": campeon})
		## Se apunta el campeon de TU liga para la Supercopa del ano que viene: al
		## empezar la temporada nueva la tabla ya esta a cero y no habria a quien
		## preguntarle quien gano.
		if mi_club() != null and l.pais == mi_club().pais and l.division() == 1:
			_campeon_liga_pasado = campeon
		if campeon == mi_club() and logros != null:
			logros.celebrar_titulo(l.nombre)
		if mi_club() != null and l.clubes.has(mi_club()):
			var n := 1
			for fila: Dictionary in t:
				if fila["club"] == mi_club():
					break
				n += 1
			mi_puesto = n

	## La gala de fin de año: equipo ideal, mejor joven, mejor entrenador. Tiene
	## que ir AQUÍ, antes del bloque de ascensos/descensos de abajo: por dentro
	## vuelve a pedir `liga_de(mi_club()).tabla()`, y si ya se hubiera movido de
	## liga esa tabla sería la de la liga NUEVA, recién estrenada a cero puntos
	## -la misma trampa que ya pagó `mi_puesto` unas líneas más arriba.
	if logros != null:
		resumen["logros"] = logros.cerrar_temporada()
	## Las epocas doradas se sortean al cerrar el ano, antes de que la camada
	## siguiente nazca: si fuera despues, el pais estrenaria su epoca con una
	## generacion ya repartida y el bono llegaria un ano tarde.
	if eras != null:
		eras.cierre_de_temporada()
	## Y la moda tactica, que cambia cada cuatro a siete temporadas: sin esto, el
	## mejor dibujo del juego lo es para siempre y se elige una vez en diez años.
	_rodar_era()

	## LA MARCA DEL PECHO MIRA LA TABLA. La exigencia contractual se cobra aqui,
	## con `mi_puesto` ya calculado sobre la foto de ANTES de mover a nadie de
	## liga: si se leyera despues, un descendido tendria el puesto de su liga
	## nueva y la marca le daria las gracias por un top 1 que no existio.
	if auspicio != null:
		var cierre_ausp := auspicio.cierre(mi_puesto)
		if cierre_ausp != "":
			resumen["auspicio"] = cierre_ausp

	## Los dos últimos de Primera bajan y los dos primeros de Segunda suben, por
	## cada país que tenga las dos divisiones.
	for primera in ligas:
		if primera.division() != 1:
			continue
		var segunda := _segunda_de(primera.pais)
		if segunda == null:
			continue
		var t1: Array = tablas.get(primera, primera.tabla())
		var t2: Array = tablas.get(segunda, segunda.tabla())
		if t1.size() < 3 or t2.size() < 3:
			continue
		var bajan: Array[Club] = [t1[t1.size() - 1]["club"], t1[t1.size() - 2]["club"]]
		var suben: Array[Club] = [t2[0]["club"], t2[1]["club"]]
		for c in bajan:
			_mover_de_liga(c, primera, segunda)
		for c in suben:
			_mover_de_liga(c, segunda, primera)
		resumen["bajan"].append_array(bajan)
		resumen["suben"].append_array(suben)

	## Y la cuenta que de verdad importa: si cumpliste lo que te pidieron.
	##
	## OJO: el puesto se saca de `mi_puesto`, calculado ARRIBA con la foto de las
	## tablas de antes de mover a nadie. Mirarlo aqui seria mirar la liga NUEVA de
	## tu club si acabas de ascender o descender, donde todavia no has jugado nada
	## y por tanto eres primero por diferencia de goles cero. Al que acaba de bajar
	## le saldria que cumplio.
	## Los puntos de habilidad de la temporada, antes del veredicto: si te echan,
	## al menos tu plantel se queda con lo que ganó jugando.
	if entrenamiento != null and mi_club() != null:
		entrenamiento.repartir_puntos(mi_club())
	if copa != null and copa.campeon == mi_club() and logros != null:
		logros.celebrar_titulo(copa.nombre)
	if directiva != null and not directiva.despedido_ya and mi_puesto > 0:
		resumen["directiva"] = directiva.tras_temporada(mi_puesto, mi_puesto == 1,
			copa != null and copa.campeon == mi_club())
		## Las primas por objetivos del reglamento interno: se pagan al cumplir,
		## no antes. Es lo que las hace una apuesta y no un gasto fijo.
		if bool(normas.get("primas", false)) and bool(resumen["directiva"].get("cumplido", false)):
			var mio_p := mi_club()
			var prima_total := Eco.escalar(800000, mio_p.rep)
			mio_p.mover_saldo(-prima_total)
			_anotar_movimiento("Primas por objetivos al plantel", -prima_total)
			for j in mio_p.plantilla:
				j.moral = clampi(j.moral + 6, 10, 99)
			resumen["primas_pagadas"] = prima_total
	## El pulso de la carrera: prestigio, ascensos, y si el interino no se
	## resolvió por fechas (interinato de menos de cinco semanas jugadas al
	## cerrar la temporada), por temporada terminada.
	if roles != null:
		resumen["roles"] = roles.tras_temporada(resumen.get("directiva", {}))
	return resumen

func _segunda_de(pais: String) -> Liga:
	for l in ligas:
		if l.pais == pais and l.division() == 2:
			return l
	return null

## Cambia a un club de liga. Hay que mover TRES cosas a la vez: la lista de la
## liga que lo pierde, la de la que lo gana, y su propia división.
##
## La división no es una etiqueta: de ella dependen los derechos de televisión
## (300.000 en Primera contra 58.000 en Segunda) y el patrocinio. Moverlo de
## lista sin cambiarle la división dejaría a un club recién descendido cobrando
## como si siguiera arriba, que es justo el castigo que el descenso tiene que ser.
func _mover_de_liga(c: Club, desde: Liga, hasta: Liga) -> void:
	desde.clubes.erase(c)
	if not hasta.clubes.has(c):
		hasta.clubes.append(c)
	c.division = hasta.division()
	## Y la TABLA, que son cuatro cosas y no tres.
	##
	## `Liga.tabla()` recorre `clubes` y busca a cada uno en `tabla_puntos`. Moviendo
	## solo la lista, el recien llegado no tenia fila y la tabla reventaba con
	## "Invalid access to key 'cNN'". No saltaba casi nunca porque `nueva_temporada()`
	## llama despues a `preparar()`, que la reconstruye entera — pero cualquiera que
	## pidiera la tabla ENTRE el ascenso y esa llamada se la encontraba rota. Y eso
	## es justo lo que hace el veredicto de la directiva cuando TU club sube o baja.
	desde.tabla_puntos.erase(c.id)
	if not hasta.tabla_puntos.has(c.id):
		hasta.tabla_puntos[c.id] = {"pts": 0, "pj": 0, "gf": 0, "gc": 0, "g": 0, "e": 0, "p": 0}

## Cierra la temporada: cumpleanos, retiros y un campeonato nuevo.
func nueva_temporada() -> Dictionary:
	## Primero se cierra la que acaba -premios, ascensos y descensos- y DESPUÉS
	## envejece la gente. Al revés, los clubes se repartirían las divisiones con
	## las plantillas del año siguiente y el descendido ya habría perdido a sus
	## veteranos antes de saber que bajaba.
	var resumen := cerrar_temporada()
	## La selección y el Mundial de Clubes leen los campeones continentales de
	## ESTA temporada que se acaba, así que van antes de volver a sortear los
	## continentales de la siguiente -si no, mirarían el cuadro vacío del año
	## que recién empieza y el Mundial de Clubes nunca tendría campeón.
	if selecciones != null:
		resumen["selecciones"] = selecciones.cierre_de_temporada(anio)
	anio += 1
	semana = 1
	for c: Club in clubes.values():
		var siguen: Array[Jugador] = []
		for j in c.plantilla:
			## La foto de la media con la que arranca el ano, para poder decir
			## despues cuanto crecio cada uno. Se toma ANTES de la curva de
			## progreso de abajo: si se tomara despues, el crecimiento del ano
			## saldria siempre a cero.
			j.ovr_al_empezar = j.ovr
			## `anio` ya se incrementó arriba (línea de "anio += 1"): `anio - 1`
			## es la temporada que de verdad se está cerrando.
			j.registrar_temporada(anio - 1, c.nombre)
			j.edad += 1
			j.partidos = 0
			j.goles = 0
			j.amarillas = 0
			## La curva de progreso: los jovenes suben hacia su techo, los
			## veteranos bajan. Es lo que hace que una plantilla envejezca.
			if j.edad <= 24 and j.ovr < j.pot:
				j.ajustar_media(Azar.ent(0, 3))
			elif j.edad >= 31:
				j.ajustar_media(-Azar.ent(0, 3))
			## EL RETIRO POR LESIONES. `Medico.retiro_forzado()` estaba escrita y no
			## la llamaba nadie: tres lesiones graves seguidas no acababan con la
			## carrera de nadie, que es justo el peor final que puede tener un
			## futbolista y el que hace que cuidar el fisico importe.
			if c.id == mi_club_id and medico != null and medico.retiro_forzado(j):
				if cantera != null:
					cantera.registrar_retiro(j, c)
				if prensa != null:
					prensa.noticia.emit("Se retira por lesiones: %s" % j.nombre,
						"Los médicos no le dan el alta competitiva. %d años y tres lesiones graves en poco tiempo: cuelga las botas antes de tiempo." % j.edad)
				continue
			if j.edad >= 38 or (j.edad >= 35 and Azar.suerte(0.4)):
				if cantera != null:
					cantera.registrar_retiro(j, c)
				continue   ## se retira
			siguen.append(j)
		c.plantilla = siguen
		_subir_de_cantera(c)
		_repartir_dorsales(c)
	for l in ligas:
		l.preparar()
	## La camada nueva: DESPUES de los retiros (para que registren su leyenda
	## antes de que alguien pueda ser su hijo) y de la reposicion automatica
	## (para que un canterano de la camada no le robe el hueco a la reposicion
	## por puesto de _subir_de_cantera()).
	if cantera != null:
		cantera.camada_anual()
		cantera.chequeo_promesas()
	## Los de la academia que cumplen 16 suben DESPUÉS de la camada: son los
	## tuyos de verdad, y si no hay ficha se quedan un año más (ver `Academia`).
	if academia != null:
		academia.fin_de_temporada()
	## LAS JOYAS DE LAS ACADEMIAS, una por sede. Van DESPUES de la camada porque
	## comparten el tope de plantilla: la joya que se paga todo el ano no puede
	## quedarse fuera por un canterano de relleno que subio antes.
	if ojeadores != null and mi_club() != null:
		for joya in ojeadores.joyas_de_academia(mi_club()):
			mi_club().plantilla.append(joya)
	## Los cedidos vuelven a casa: sin esto, aceptar una cesion regalaba al
	## canterano para siempre aunque el texto prometiera que volvia.
	## Las cesiones las resuelve `Cesiones`, que es quien sabe si habia opcion de
	## compra. `prensa.volver_de_cesion` se queda sin usar a proposito: tenia el
	## mismo fallo que el HTML, devolver a todos a casa antes de mirar la opcion.
	if cesiones != null:
		cesiones.resolver(anio)
		cesiones.cobrar_plusvalias(anio)
	if vestuario != null:
		vestuario.nueva_temporada()
	## La campaña de abonos: se lanza sola al empezar la temporada, con el plan
	## que tengas elegido. Es un ingreso grande y de una vez -ocho partidos
	## cobrados por adelantado- y por eso elegir plan importa.
	if hinchada != null and mi_club() != null:
		var trofeos_hasta_hoy := roles.trofeos.size() if roles != null else 0
		resumen["abonos"] = hinchada.campana_abonos(mi_club(),
			prensa.animo if prensa != null else 60, trofeos_hasta_hoy)
	## EL MERCADO DE AUSPICIOS SE ABRE EN PRETEMPORADA: tres marcas sobre la
	## mesa. Va DESPUES de los ascensos y descensos porque la oferta depende de
	## la division en la que vas a jugar, no de la que acabas de dejar.
	if copa != null and copa.campeon != null:
		_campeon_copa_pasado = copa.campeon
	if comercial != null and mi_club() != null:
		comercial.cierre_de_temporada(mi_club())
	## La subvencion municipal se cobra al cerrar el ano: sale de lo que el club
	## le devuelve al barrio, no de lo que gana en la cancha.
	if ciudad != null and mi_club() != null:
		ciudad.cobrar_subvencion(mi_club())
	## EL FAIR PLAY FINANCIERO mira las cuentas del ano. Se usa el MISMO
	## porcentaje que ya enseña la proyeccion anual en pantalla: si aqui se
	## calculara aparte, el jugador veria un numero y la federacion juzgaria otro.
	if federacion != null and federacion.fpf_activo and mi_club() != null:
		var f_fpf := Finanzas.new(mi_club(), 0.0, 0, 0.0)
		f_fpf.aplica_operacion = true
		f_fpf.factor_operacion = obras.abarata_operacion() if obras != null else 1.0
		var proy := f_fpf.proyeccion_anual(15, ingreso_tienda(mi_club()))
		resumen["fpf"] = federacion.revisar_fair_play(mi_club(), int(proy["pct_salarial"]))
	if auspicio != null and mi_club() != null:
		auspicio.generar_ofertas(mi_club(),
			directiva != null and directiva.tiene_consejero("mkt"),
			roles.multiplicador_sponsor() if roles != null else 1.0)
	if entrenamiento != null:
		entrenamiento.reiniciar_pretemporada()
		entrenamiento.reiniciar_subidas()
	## La copa nacional se sortea de cero cada temporada, con los clubes de
	## primera del pais donde diriges.
	## LA SUPERCOPA abre el ano: campeon de liga contra campeon de copa. Va aqui
	## y no en el cierre porque es el PRIMER titulo de la temporada nueva, no el
	## ultimo de la vieja.
	var sc := jugar_supercopa()
	if not sc.is_empty():
		resumen["supercopa"] = sc
	## Y se reabre la pretemporada: hay una por ano.
	amistoso_hecho = false
	_montar_copa()
	## Y los torneos continentales, con las plazas ya puestas al dia por los
	## ascensos/descensos y reputaciones de la temporada que se acaba de cerrar.
	## Antes esto solo se hacia una vez, al tomar el mando: pasada la primera
	## temporada, Champions/Libertadores se quedaban congeladas para siempre con
	## el mismo cuadro y el mismo campeon.
	_sortear_continentales()
	## Trotamundos: a las dos temporadas en el mismo club, toca hacer las
	## maletas. Reutiliza el mismo mecanismo que un despido de verdad
	## -`despedido_ya`- porque es exactamente el mismo destino: la interfaz ya
	## sabe leerlo y ya deja elegir otro club desde el selector de arriba.
	if tiene_desafio("trotamundos") and directiva != null and not directiva.despedido_ya:
		anios_en_club += 1
		if anios_en_club >= 2:
			anios_en_club = 0
			directiva.despedido_ya = true
			resumen["trotamundos"] = true
	return resumen

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
	copa = Copa.new(String(elegida[0]))
	copa.peso_premio = float(elegida[1])
	copa.preparar(aspirantes)

## Sube canteranos hasta completar la plantilla, y los sube EN EL PUESTO QUE
## FALTA, comparando con el plan de plantilla. Rellenando al azar, en diez
## temporadas un club acababa con seis porteros y sin lateral izquierdo, porque
## los retiros no se reparten por igual entre las demarcaciones.
##
## Ojo con el orden: la edad y la media se le pasan a `crear_jugador`, no se le
## ponen despues. Poniendolas despues el jugador ya venia tasado con otra edad y
## el valor salia mal; el fallo no se ve hasta que alguien mira una ficha.
func _subir_de_cantera(c: Club) -> void:
	var plan: Array = Datos.tabla("PLAN_PLANTEL")
	var faltan: Array[String] = []
	for entrada: Array in plan:
		var demarcacion := String(entrada[0])
		var tiene := 0
		for j in c.plantilla:
			if j.pos_e == demarcacion:
				tiene += 1
		for k in maxi(0, int(entrada[1]) - tiene):
			faltan.append(demarcacion)
	for demarcacion in faltan:
		if c.plantilla.size() >= 24:
			break
		var edad := Azar.ent(17, 20)
		## El canterano entra flojo y con techo: media baja, potencial alto. Es
		## lo que hace que la cantera sea una apuesta y no una fuente de cracks.
		var ovr := c.rep - 20 + Azar.ent(0, 8)
		var nuevo := crear_jugador(c, Datos.grupo(demarcacion), demarcacion, edad, ovr)
		## EL CLUB QUE VIVE DE SU CANTERA (C3) la cuida más: sus chicos
		## suben con más techo. Sin `Azar` extra: es un ajuste fijo.
		if not Regiones.filosofia(c).is_empty():
			nuevo.ovr = mini(nuevo.ovr + 4, 90)
			nuevo.pot = clampi(nuevo.pot + 6, nuevo.ovr, 97)
			nuevo.tasar()
		c.plantilla.append(nuevo)

## --- LO QUE APORTA EL CUERPO TECNICO ---------------------------------------

## Jugadores de otros clubes cuyo potencial real ya conoces. Sin ojeador, la
## ficha de un rival solo enseña su media de hoy; con ojeador, su techo.
var ojeados: Dictionary = {}

func _informes_de_ojeo() -> void:
	var p := staff.ojo()
	if p <= 0.0 or not Azar.suerte(p):
		return
	var lista: Array = clubes.values()
	for intento in 30:
		var c: Club = lista[Azar.ent(0, lista.size() - 1)]
		if c.id == mi_club_id or c.plantilla.is_empty():
			continue
		var j: Jugador = c.plantilla[Azar.ent(0, c.plantilla.size() - 1)]
		## Solo interesa el informe que aporta algo: un chico con recorrido. De un
		## veterano de 33 ya se sabe todo con mirarle la media.
		if ojeados.has(j.id) or j.edad > 23 or j.pot < j.ovr + 8:
			continue
		ojeados[j.id] = true
		informe_de_ojeo.emit(j, c)
		return

signal informe_de_ojeo(j: Jugador, club_suyo: Club)
signal obra_lista(clave: String)

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
	return directiva

## Sortea los torneos continentales con las plazas de cada pais.
func _sortear_continentales() -> void:
	if copa == null:
		_montar_copa()
	continentales = Continental.sortear(clubes.values(), ligas,
		copa.campeon if copa != null else null)

## El torneo continental en el que juega tu club, o null.
func mi_continental() -> Continental:
	var c := mi_club()
	return Continental.de_club(continentales, c) if c != null else null

## Le cuenta a la directiva como te fue el domingo.
##
## Solo mira TU partido: a la directiva de Coquimbo no le importa lo que hagas
## tu, y simular la paciencia de 383 juntas directivas seria gastar en algo que
## nadie va a ver.
func _avisar_a_la_directiva(resultados: Array) -> void:
	var mio := mi_club()
	if mio == null:
		return
	for r: Dictionary in resultados:
		var soy_local: bool = r["local"] == mio
		if not soy_local and r["visita"] != mio:
			continue
		var gf: int = r["gl"] if soy_local else r["gv"]
		var gc: int = r["gv"] if soy_local else r["gl"]
		if directiva != null and not directiva.despedido_ya:
			directiva.tras_partido(gf, gc, r["visita"] if soy_local else r["local"])
		## El prestigio del entrenador se mueve con CUALQUIER resultado tuyo, no
		## solo el que dirigiste: a diferencia de Logros (que necesita el once y
		## los goleadores del `Partido` completo, y eso solo sobrevive en el
		## dirigido), a Roles le basta el marcador, y ese SÍ llega siempre por
		## `resultados`.
		## EL CUPO JUVENIL, que la asamblea vota y nadie revisaba. `Federacion`
		## tenia escrita la multa por salir sin ningun sub-21 y la bonificacion por
		## cada uno que juegue, y no la llamaba nadie: se podia votar el reglamento
		## y no pasaba absolutamente nada en toda la temporada.
		if federacion != null and mio != null:
			federacion.revisar_cupo_juvenil(mio, mio.once())
		## EL FICHAJE IMPUESTO -por la ocupación hostil del dueño o el trato
		## comercial del patrocinador-, mismo patrón que el cupo juvenil de
		## arriba: `Prensa.revisar_impuesto()` ya existía escrito y nadie lo
		## llamaba desde que se firmaba el pacto en el despacho.
		if prensa != null and mio != null:
			prensa.revisar_impuesto(mio, mio.once(), anio)
		_gano_la_ultima = gf > gc
		_resultado_semana = 1 if gf > gc else (0 if gf == gc else -1)
		## "G.clubes[miClub].forma.push(...)" del HTML: solo cuenta para esto lo
		## que se juega de LIGA -este bloque nace de `_avisar_a_la_directiva`,
		## que `avanzar_semana()` llama justo después de `l.jugar_jornada()`-.
		if club_dentro != null:
			club_dentro.registrar_resultado_liga(gf > gc, gf == gc)
		## "G.ultArbMal" del HTML: perdiste -no empate, perdiste de verdad- y el
		## árbitro de ese partido es de los que sesgan -"casero"/"figura"-, así
		## que el directorio pregunta si reclamas formalmente (`Prensa.
		## arbitro_dudoso()`, cuya rama de despacho ya estaba completa y sin
		## nadie que la llamara). Solo liga, igual que el resto de este bloque.
		## MISMO `Previa.arbitro_de()` que ya usa `vPrevia()` y que acaba de
		## pitar el partido en `Partido.preparar()`: no una tercera copia del
		## hash.
		if prensa != null and gf < gc:
			var rival_perdido: Club = r["visita"] if soy_local else r["local"]
			var arb_partido := Previa.arbitro_de(rival_perdido.id, semana)
			if String(arb_partido["perfil"]) == "casero" or String(arb_partido["perfil"]) == "figura":
				prensa.arbitro_dudoso(String(arb_partido["nombre"]))
		## SE APUNTA CON QUE DIBUJO se jugo. Es lo que despues contesta «de verdad
		## me funciona el 4-3-3», que ninguna otra pantalla puede responder.
		anotar_eficacia(mio.tactica.formacion if mio.tactica != null else "", gf, gc)
		if roles != null:
			roles.tras_partido(gf, gc)
			## Y si el de enfrente es TU rival, el cruce se cuenta aparte: es la
			## unica estadistica del juego que no es del club, es tuya.
			var el_otro: Club = r["visita"] if soy_local else r["local"]
			roles.registrar_duelo(el_otro.id, gf > gc, gf == gc)
		## LAS REDES HABLAN DE LO QUE PASA. Sin esto el feed sería un generador
		## de frases sueltas; enganchado al resultado, es la voz de la gente.
		if prensa != null:
			var rival_p: Club = r["visita"] if soy_local else r["local"]
			if gf > gc:
				prensa.publicar("%d-%d al %s. Así da gusto." % [gf, gc, rival_p.nombre], "hincha", 1.6)
			elif gf < gc:
				prensa.publicar("%d-%d contra el %s. Otra vez lo mismo." % [gf, gc, rival_p.nombre], "troll", 1.8)
			else:
				prensa.publicar("Empate sin más contra el %s. Se escapan dos puntos." % rival_p.nombre, "analista", 1.0)
		## EL INCIDENTE EN EL ESTADIO. Solo de local, porque la seguridad que
		## pagas es la de TU recinto. Sube con el mal ambiente y la funa, y baja
		## con lo que hayas invertido: es lo que convierte a la seguridad privada
		## en un gasto que se entiende en vez de en un numero mas.
		if ciudad != null and soy_local and ciudad.sancion.is_empty() and prensa != null:
			if Azar.suerte(ciudad.riesgo_incidente(prensa.animo, prensa.funa)):
				ciudad.sancionar("cerradas" if Azar.suerte(0.35) else "aforo")
				ciudad.vecinos = clampi(ciudad.vecinos - Azar.ent(4, 10), 0, 100)
		## LA RUEDA DE PRENSA Y LA PORTADA DEL LUNES.
		##
		## `Prensa.sortear_rueda()` pedía un `Partido` entero y aquí solo llega
		## el marcador, así que no la llamaba nadie: la sala de prensa completa
		## -tres barajas de preguntas, cinco lenguajes corporales, trece
		## decisiones y la promesa que se cobra diez líneas más abajo- no se
		## abría ni una vez en una partida de verdad. La promesa se cobraba sin
		## que existiera forma de hacerla.
		if prensa != null:
			var otro: Club = r["visita"] if soy_local else r["local"]
			var gano := gf > gc
			var empato := gf == gc
			var semilla := "%d|%d|%s|%d-%d" % [anio, semana, otro.id, gf, gc]
			var loc0: Club = r["local"]
			var vis0: Club = r["visita"]
			prensa.portada_tras_resultado(gano, empato, es_clasico(mio, otro), semilla,
				"%s %d-%d %s" % [Nombres.visible(loc0.nombre), int(r["gl"]), int(r["gv"]), Nombres.visible(vis0.nombre)],
				HistoriaClub.nombre_clasico(mio.nombre, otro.nombre))
			## El tiempo de ese partido, por si la rueda pregunta por él.
			var loc: Club = r["local"]
			var vis: Club = r["visita"]
			prensa.clima_ultimo = Clima.del_partido(loc.pais, semana, anio, loc.id + vis.id)
			prensa.competicion_rueda = "liga"
			prensa.clubes_rueda = []
			prensa.rueda_tras_resultado(gano, empato)
		## LA PROMESA DE LA RUEDA DE PRENSA se cobra AQUÍ, que es el único sitio
		## donde se sabe el resultado. `Prensa.presion_prometida` se encendía al
		## responder al DT rival y `consumir_presion()` no la llamaba nadie: la
		## bravata salía gratis. Ahora tiene precio -y premio si se cumple-,
		## que es lo que convierte contestar en una decisión.
		if prensa != null and prensa.consumir_presion():
			if gf > gc:
				prensa.mover_animo(6)
				prensa.noticia.emit("Dijiste que ganabas y ganaste",
					"La hinchada celebra el doble: primero el resultado y después la cara del otro.")
			else:
				prensa.mover_animo(-8)
				prensa.noticia.emit("Prometiste y no cumpliste",
					"La frase de la conferencia se te da vuelta. En la calle no se habla del partido, se habla de ti.")
		if not desafios.is_empty():
			var rival: Club = r["visita"] if soy_local else r["local"]
			_chequear_desafios_tras_partido(gf, gc, rival)
		return

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

## El perfil del estadio que va al visor 3D.
##
## Si el club es el TUYO, manda lo que hayas diseñado en `EstadioPropio`; para
## cualquier otro, sale del hash de su id como siempre. Es la misma regla del
## HTML: tu recinto lo construyes, el del rival te lo encuentras.
func perfil_estadio_de(c: Club) -> Dictionary:
	if c != null and c.id == mi_club_id and estadio != null:
		var p := estadio.perfil(c, obras)
		## Lo que el 3D necesita de las instalaciones: obras en curso (andamios
		## y grúa) y lo construido (palcos, prensa, museo, tienda).
		if obras != null:
			p["en_obra"] = obras.obras.keys()
			p["inst"] = obras.niveles.duplicate()
		return p
	return c.perfil_estadio() if c != null else {}

# ---------------------------------------------------------------------------
#  AMBIENTE: ESTACIÓN, CLIMA Y HORARIO
# ---------------------------------------------------------------------------
#
# `vEntrenoPlus()` del HTML. Son tres cosas pequeñas que juntas hacen que una
# temporada no se sienta como cuarenta y dos semanas iguales: que en invierno
# llueva, que en verano apriete el calor, y que elegir la hora del partido sea
# una decisión entre la taquilla y los derechos de televisión.

## Las cuatro estaciones repartidas en las 42 semanas.
const ESTACIONES := [
	["verano", "☀️"], ["otoño", "🍂"], ["invierno", "❄️"], ["primavera", "🌸"],
]

func estacion() -> Array:
	var s := float((semana - 1) % 42) / 42.0
	if s < 0.25:
		return ESTACIONES[0]
	if s < 0.5:
		return ESTACIONES[1]
	if s < 0.75:
		return ESTACIONES[2]
	return ESTACIONES[3]

## El clima de la semana. Sale de un HASH del año y la semana, no de un sorteo:
## así la misma partida da siempre el mismo tiempo y se puede reproducir. Y la
## bolsa depende de la estación, que es lo que hace que un invierno se note.
func clima() -> String:
	var est := String(estacion()[0])
	var bolsa: Array = ["despejado", "nublado", "viento", "lluvia", "despejado", "despejado", "nublado", "calor"]
	match est:
		"invierno":
			bolsa = ["lluvia", "lluvia", "tormenta", "frío", "frío", "niebla", "nublado", "despejado"]
		"verano":
			bolsa = ["despejado", "despejado", "calor", "calor", "nublado", "viento", "despejado", "lluvia"]
		"otoño":
			bolsa = ["nublado", "lluvia", "viento", "despejado", "niebla", "lluvia", "nublado", "tormenta"]
	var h := 0
	var clave := "cl%d-%d" % [anio, semana]
	for i in clave.length():
		h = (h * 31 + clave.unicode_at(i)) & 0x7FFFFFFF
	return String(bolsa[h % bolsa.size()])

## Los cuatro horarios: [clave, hora, nombre, factor de público, factor de TV,
## explicación]. La decisión es siempre la misma y siempre incómoda: cuanto más
## paga la televisión, menos gente va al estadio.
const HORARIOS := [
	["tarde", "16:00", "Tarde de sábado", 1.0, 1.0, "El horario de toda la vida"],
	["noche", "21:30", "Noche de sábado", 1.08, 1.12, "Ambiente de caldera y mejor audiencia"],
	["mediodia", "12:30", "Mediodía de domingo", 0.82, 1.18, "A la televisión le encanta; a la hinchada no"],
	["lunes", "20:00", "Lunes por la noche", 0.68, 1.25, "Casi nadie va, pero pagan más los derechos"],
]
var horario: String = "tarde"

func horario_actual() -> Array:
	for h: Array in HORARIOS:
		if String(h[0]) == horario:
			return h
	return HORARIOS[0]

## Lo que el horario elegido hace con el público y con los derechos de TV.
func factor_publico() -> float:
	return float(horario_actual()[3])

func factor_tv_horario() -> float:
	return float(horario_actual()[4])

# ---------------------------------------------------------------------------
#  CAMPAÑAS PUBLICITARIAS Y GUERRA DE MARCAS
# ---------------------------------------------------------------------------
#
# El catálogo vive en `Finanzas` porque es cosa de dinero; el ESTADO vive aquí
# porque `Finanzas` se construye por club y por semana y no sobrevive de una a
# otra: no puede recordar qué campaña lanzaste este año.

## {anio, clave} de la última campaña lanzada. Una por temporada.
var campana: Dictionary = {}

func campana_lanzada_este_anio() -> bool:
	return not campana.is_empty() and int(campana.get("anio", 0)) == anio

## Lanza una campaña. Devuelve "" si se hizo, o el motivo por el que no.
func lanzar_campana(clave: String) -> String:
	var c := mi_club()
	if c == null:
		return "no hay club"
	if campana_lanzada_este_anio():
		return "ya lanzaste una campaña esta temporada"
	var d := Finanzas.def_campana(clave)
	if d.is_empty():
		return "esa campaña no existe"
	var coste := Eco.escalar(float(d[3]), float(c.rep))
	if c.saldo < coste:
		return "cuesta %s y no hay caja" % Cesiones.dinero(coste)
	c.mover_saldo(-coste)
	_anotar_movimiento("Campaña: %s" % String(d[1]), -coste)
	campana = {"anio": anio, "clave": clave}
	var efectos: Dictionary = d[4]
	if efectos.has("socios"):
		c.socios += int(round(float(c.socios) * float(efectos["socios"])))
	if efectos.has("animo") and prensa != null:
		prensa.mover_animo(int(efectos["animo"]))
	if efectos.has("seguidores") and prensa != null:
		prensa.seguidores += int(round(float(prensa.seguidores) * float(efectos["seguidores"])))
	return ""

## LA GUERRA DE MARCAS: ir a por el patrocinador de tu mayor rival.
##
## Es la jugada más sucia que permite el juego y por eso tiene su precio: si
## sale, firmas mejor y a ellos les duele; si falla, pierdes el dinero y se
## enteran igual. El palco sube las opciones, porque es donde se cierran estas
## cosas —el HTML lo dice con esas palabras—.
func rival_de_marcas() -> Club:
	if logros == null:
		return null
	var lista := logros.rivalidades()
	if lista.is_empty():
		return null
	return (lista[0] as Dictionary)["club"] as Club

func coste_guerra_marcas() -> int:
	var c := mi_club()
	if c == null:
		return 0
	var rival := rival_de_marcas()
	var calor := logros.rivalidad_con(rival) if (rival != null and logros != null) else 0
	return Eco.escalar(180000.0 * (1.0 + float(calor) / 100.0), float(c.rep))

func probabilidad_guerra_marcas() -> float:
	var c := mi_club()
	var rival := rival_de_marcas()
	if c == null or rival == null:
		return 0.0
	var palco := club_dentro.bono_palco() if club_dentro != null else 0
	return clampf(0.35 + float(c.rep - rival.rep) * 0.02 + float(palco) / 50.0, 0.1, 0.9)

func pujar_por_marca() -> String:
	var c := mi_club()
	var rival := rival_de_marcas()
	if c == null or rival == null:
		return "no tienes todavía un rival al que quitarle nada"
	var coste := coste_guerra_marcas()
	if c.saldo < coste:
		return "la operación cuesta %s y no hay caja" % Cesiones.dinero(coste)
	c.mover_saldo(-coste)
	_anotar_movimiento("Operación por el patrocinador de %s" % rival.nombre, -coste)
	if not Azar.suerte(probabilidad_guerra_marcas()):
		if prensa != null:
			prensa.publicar("Intentaron quitarnos el patrocinador y se estrellaron.", "troll", 1.6)
		return "Salió mal. Perdiste el dinero y en %s se enteraron igual." % rival.nombre
	## El premio: un ingreso de golpe y una publicación que lo cuenta. El
	## patrocinio recurrente ya lo calcula `Finanzas.patrocinio()` a partir de la
	## reputación, así que no hace falta otro contador que mantener.
	var premio := Eco.escalar(420000.0, float(c.rep))
	c.mover_saldo(premio)
	_anotar_movimiento("Nuevo patrocinador principal", premio)
	if prensa != null:
		prensa.publicar("Les hemos quitado el patrocinador. Hoy se duerme bien.", "hincha", 2.4)
		prensa.mover_animo(6)
	return "Salió. Firmas con su patrocinador y en %s les ha dolido de verdad." % rival.nombre

# ---------------------------------------------------------------------------
#  LAS DOS VENTANAS DE MERCADO
# ---------------------------------------------------------------------------
#
# «Fichajes de última hora en el cierre de mercado» (idea 87). Hasta ahora se
# podía fichar cualquier semana del año, y eso quitaba de golpe dos cosas que
# son media gracia del género: la urgencia del último día y tener que aguantar
# medio año con la plantilla que armaste.
#
# Son las mismas dos ventanas del HTML —`sem<=6` y `18<=sem<=24`—: la de
# pretemporada, larga, y la de invierno, corta y cara.
const VENTANA_VERANO := 6
const VENTANA_INVIERNO_INI := 18
const VENTANA_INVIERNO_FIN := 24

func mercado_abierto() -> bool:
	return semana <= VENTANA_VERANO \
		or (semana >= VENTANA_INVIERNO_INI and semana <= VENTANA_INVIERNO_FIN)

## Cuántas semanas quedan para que cierre. Cero si está cerrado.
func semanas_de_mercado() -> int:
	if semana <= VENTANA_VERANO:
		return VENTANA_VERANO - semana + 1
	if semana >= VENTANA_INVIERNO_INI and semana <= VENTANA_INVIERNO_FIN:
		return VENTANA_INVIERNO_FIN - semana + 1
	return 0

## Cuándo vuelve a abrir, para poder decirlo en vez de un "está cerrado" seco.
func semanas_hasta_mercado() -> int:
	if mercado_abierto():
		return 0
	if semana < VENTANA_INVIERNO_INI:
		return VENTANA_INVIERNO_INI - semana
	## Pasada la de invierno, la siguiente es la del año que viene.
	## Pasada la de invierno, la siguiente es la del año que viene: se cuenta
	## contra las jornadas que le quedan a tu liga, que es lo que de verdad marca
	## cuando se acaba la temporada aqui.
	var l := liga_de(mi_club())
	var quedan := (l.jornadas() - l.jornada_actual) if l != null else 8
	return maxi(1, quedan + VENTANA_VERANO)

func texto_de_mercado() -> String:
	if mercado_abierto():
		var q := semanas_de_mercado()
		if q <= 2:
			return "Mercado abierto: cierra en %d semana%s. Últimos días." % [q, "" if q == 1 else "s"]
		return "Mercado abierto: quedan %d semanas." % q
	return "Mercado cerrado. Vuelve a abrir en %d semanas." % semanas_hasta_mercado()

# ---------------------------------------------------------------------------
#  LA SUPERCOPA Y LOS AMISTOSOS DE PRETEMPORADA
# ---------------------------------------------------------------------------
#
# Ideas 169 y 170. Las dos ocupan el hueco vacío del calendario -el que va entre
# que se cierra una temporada y arranca la siguiente- y las dos existen por lo
# mismo: hoy ese hueco es un botón de «temporada siguiente» y no pasa nada.

## El campeón de liga contra el campeón de copa, a partido único. Se juega al
## empezar la temporada nueva y da un título de verdad: cuenta para la vitrina,
## para el palmarés y para el prestigio.
const PREMIO_SUPERCOPA := 140000

func jugar_supercopa() -> Dictionary:
	if _campeon_liga_pasado == null or _campeon_copa_pasado == null:
		return {}
	if _campeon_liga_pasado == _campeon_copa_pasado:
		## El mismo club ganó las dos: no hay Supercopa que jugar, y el doblete
		## ya se celebró en su momento.
		return {}
	var a := _campeon_liga_pasado
	var b := _campeon_copa_pasado
	var p := Partido.new(a, b)
	var r := p.simular()
	var gl: int = r["local"]
	var gv: int = r["visita"]
	## Partido único: si acaba en empate, decide la reputación —no hay prórroga
	## que simular y un título no puede quedar sin dueño.
	var gana: Club = a if gl > gv else (b if gv > gl else (a if a.rep >= b.rep else b))
	gana.mover_saldo(PREMIO_SUPERCOPA)
	var nombre := "Supercopa de %s" % _nombre_pais_de(gana.pais)
	if gana == mi_club():
		if logros != null:
			logros.celebrar_titulo(nombre)
		if roles != null:
			roles.sumar_trofeo(nombre)
	if prensa != null:
		prensa.noticia.emit(nombre,
			"%s %d-%d %s. %s levanta el primer título del año." % [a.nombre, gl, gv, b.nombre, gana.nombre])
	return {"nombre": nombre, "campeon": gana, "local": a, "visita": b, "gl": gl, "gv": gv}

func _nombre_pais_de(pais: String) -> String:
	var t: Dictionary = Datos.tabla("PAIS_SELECCION")
	return String(t.get(pais, pais)) if t != null else pais

var _campeon_liga_pasado: Club = null
var _campeon_copa_pasado: Club = null

## Los amistosos de pretemporada. No dan puntos ni dinero grande: dan FORMA, que
## es lo que le falta a un plantel que lleva un mes parado. Es la única forma de
## llegar afinado a la primera jornada.
const AMISTOSOS := [
	["local", "Triangular en casa", 0.0, 6],
	["gira", "Gira internacional", 220000.0, 11],
	["cantera", "Amistosos con la cantera", 0.0, 3],
]

var amistoso_hecho: bool = false

func def_amistoso(clave: String) -> Array:
	for f: Array in AMISTOSOS:
		if String(f[0]) == clave:
			return f
	return []

## Juega la pretemporada elegida. Devuelve "" si se hizo, o el motivo.
func jugar_amistosos(clave: String) -> String:
	if amistoso_hecho:
		return "la pretemporada ya está jugada"
	var d := def_amistoso(clave)
	if d.is_empty():
		return "esa pretemporada no existe"
	var mio := mi_club()
	if mio == null:
		return "no hay club"
	var coste := Eco.escalar(float(d[2]), float(mio.rep)) if float(d[2]) > 0.0 else 0
	if coste > mio.saldo:
		return "la gira cuesta %s y no hay caja" % Cesiones.dinero(coste)
	if coste > 0:
		mio.mover_saldo(-coste)
		_anotar_movimiento("Pretemporada: %s" % String(d[1]), -coste)
	amistoso_hecho = true
	var gana: int = d[3]
	for j in mio.plantilla:
		j.forma = clampi(j.forma + gana, 20, 99)
	## La gira internacional además vende camisetas y trae socios: es cara y se
	## paga sola si el club es grande.
	if clave == "gira":
		var ingreso := Eco.escalar(180000.0, float(mio.rep))
		mio.mover_saldo(ingreso)
		_anotar_movimiento("Taquilla y merchandising de la gira", ingreso)
		mio.socios += Azar.ent(300, 900)
	## Y la de cantera le da minutos a los chicos, que es lo que de verdad los
	## hace crecer: sube la forma de los sub-21 el doble.
	if clave == "cantera":
		for j2 in mio.plantilla:
			if j2.edad <= 21:
				j2.forma = clampi(j2.forma + gana, 20, 99)
	if prensa != null:
		prensa.noticia.emit("Pretemporada: %s" % String(d[1]),
			"El plantel llega a la primera jornada con %d de forma extra." % gana)
	return ""

# ---------------------------------------------------------------------------
#  LA MARCA PERSONAL DE TUS FIGURAS Y LOS DÍAS SEÑALADOS
# ---------------------------------------------------------------------------

## Cuánta marca personal tiene un futbolista: cuánto vende él, no el club. Sale
## de su nivel, de lo ídolo que sea y de las habilidades especiales que domina,
## que son las que salen en los vídeos.
static func marca_personal(j: Jugador, idolo: int, habilidades: int) -> int:
	var base := float(j.ovr - 60) * 2.2 + float(idolo) * 0.35 + float(habilidades) * 3.0
	return clampi(int(round(base)), 0, 100)

## Lo idolo que es se aproxima con lo que lleva hecho AQUI -partidos y goles
## con esta camiseta-, que es de lo que sale el salon de la fama. Un fichaje
## recien llegado no tiene marca personal en este club por muy bueno que sea,
## y eso es exactamente lo correcto. Publica (no solo interna a
## `ingreso_marca()`) para que la ficha del jugador pueda enseñar el mismo
## numero -esIdolo()/marcaPersonal() del HTML- en vez de inventar otro.
func idolo_aproximado(j: Jugador) -> int:
	return clampi(j.partidos + j.goles * 3, 0, 100)

## Lo que las figuras le dejan al club por semana. Y el precio: con tres o más
## jugadores muy mediáticos, el foco se lo llevan ellos y no el escudo —eso sube
## el ruido, que es exactamente lo que pasa en un vestuario de estrellas—.
func ingreso_marca() -> int:
	var mio := mi_club()
	if mio == null:
		return 0
	var bruto := 0
	var egos := 0
	for j: Jugador in mio.plantilla:
		var idolo := idolo_aproximado(j)
		var habs := entrenamiento.habilidades(j).size() if entrenamiento != null else 0
		var m := marca_personal(j, idolo, habs)
		if m < 55:
			continue
		bruto += Eco.escalar(1800.0 * (float(m) / 100.0), float(mio.rep))
		if m >= 80:
			egos += 1
	if egos >= 3 and prensa != null:
		prensa._mover_funa(1)
	return bruto

## Los días señalados del calendario. Son cuatro y siempre caen en la misma
## semana: la gracia no es la sorpresa, es que la temporada tenga fechas con
## nombre en vez de cuarenta y dos semanas iguales.
const FIESTAS := {
	3:  ["🎉", "Fiestas patrias", "La ciudad está de fiesta: más gente en la calle y en el estadio"],
	12: ["🎄", "Navidad", "Semana rara: entrenamientos cortos y la cabeza en otra parte"],
	20: ["🎊", "Aniversario del club", "El club cumple años y la hinchada se vuelca"],
	31: ["🌞", "Vacaciones de invierno", "Familias enteras al estadio"],
}

func fiesta_de_la_semana() -> Array:
	return FIESTAS.get(semana, [])

func _procesar_fiesta() -> void:
	var f := fiesta_de_la_semana()
	if f.is_empty():
		return
	var mio := mi_club()
	if prensa != null:
		prensa.sumar_animo(Azar.ent(3, 8))
	## Navidad da descanso; el aniversario trae socios. Cada fiesta hace algo
	## distinto: si todas subieran el ánimo y ya está, daría igual cuál fuera.
	if mio != null:
		if semana == 12:
			for j in mio.plantilla:
				j.fisico = clampi(j.fisico + 4, 10, 100)
		elif semana == 20:
			mio.socios += Azar.ent(200, 900)
	if prensa != null:
		prensa.noticia.emit("%s %s" % [String(f[0]), String(f[1])], "%s." % String(f[2]))

# ---------------------------------------------------------------------------
#  EL INFORME DE GESTIÓN
# ---------------------------------------------------------------------------
#
# «Resumen semanal tipo informe de gestión» (idea 245). Es una pantalla que no
# añade ninguna mecánica: junta en un sitio las seis cosas que hay que mirar
# cada lunes y que hoy están repartidas por ocho pestañas.
#
# POR QUÉ HACE FALTA. Este juego tiene dieciocho pestañas. Un jugador nuevo no
# sabe cuáles mirar y uno veterano se olvida de una. El informe no decide nada:
# dice qué está mal esta semana y a qué pestaña ir.

func informe_de_gestion() -> Array[Dictionary]:
	var salida: Array[Dictionary] = []
	var mio := mi_club()
	if mio == null:
		return salida

	## 1. La caja, que es lo único que puede acabar la partida sin jugar.
	var caja_ref := Eco.ref_caja(float(mio.rep))
	if mio.saldo < 0:
		salida.append({"grave": true, "txt": "La caja está en rojo (%s). Cada semana así cuesta intereses." % Cesiones.dinero(mio.saldo), "tab": "Finanzas"})
	elif float(mio.saldo) < caja_ref * 0.25:
		salida.append({"grave": false, "txt": "La caja está justa: %s. Cuidado con el próximo fichaje." % Cesiones.dinero(mio.saldo), "tab": "Finanzas"})

	## 2. Quién no puede jugar el domingo.
	var fuera := 0
	for j: Jugador in mio.plantilla:
		if j.lesion > 0 or j.suspension > 0:
			fuera += 1
	if fuera > 0:
		salida.append({"grave": fuera >= 4, "txt": "%d jugador%s no está%s disponible%s." % [
			fuera, "es" if fuera > 1 else "", "n" if fuera > 1 else "", "s" if fuera > 1 else ""], "tab": "Enfermería"})

	## 3. Los contratos que se acaban: es el aviso que más caro sale ignorar.
	var acaban := 0
	for j2: Jugador in mio.plantilla:
		if j2.anios_contrato <= 1:
			acaban += 1
	if acaban > 0:
		salida.append({"grave": acaban >= 4, "txt": "%d contrato%s termina%s este año. Sin renovar, se van gratis." % [
			acaban, "s" if acaban > 1 else "", "n" if acaban > 1 else ""], "tab": "Contratos"})

	## 4. El vestuario.
	var descontentos := 0
	for j3: Jugador in mio.plantilla:
		if j3.moral < 40 or j3.pide_salir:
			descontentos += 1
	if descontentos > 0:
		salida.append({"grave": descontentos >= 5, "txt": "%d jugador%s con la moral por los suelos o pidiendo salir." % [
			descontentos, "es" if descontentos > 1 else ""], "tab": "Camarín"})

	## 5. La calle y el despacho.
	if prensa != null and prensa.funa >= 55:
		salida.append({"grave": prensa.funa >= 75, "txt": "El ruido en redes está en %d. La directiva lo lee." % prensa.funa, "tab": "Redes"})
	if directiva != null and directiva.confianza < 40:
		salida.append({"grave": directiva.confianza < 25, "txt": "La confianza del directorio está en %d. Estás en la cuerda floja." % directiva.confianza, "tab": "Club"})

	## 6. Lo que se puede hacer y no se está haciendo.
	if mercado_abierto() and semanas_de_mercado() <= 2:
		salida.append({"grave": false, "txt": "El mercado cierra en %d semana(s)." % semanas_de_mercado(), "tab": "Mercado"})
	if entrenamiento != null and entrenamiento.dt_puntos > 0:
		salida.append({"grave": false, "txt": "Tienes %d punto(s) de entrenador sin gastar." % entrenamiento.dt_puntos, "tab": "Legado"})
	if not amistoso_hecho and semana <= 3:
		salida.append({"grave": false, "txt": "Todavía no has jugado la pretemporada: el plantel llega frío.", "tab": "Entrenar"})
	if auspicio != null and auspicio.contrato.is_empty() and not auspicio.ofertas.is_empty():
		salida.append({"grave": false, "txt": "Hay %d marcas esperando respuesta por la camiseta." % auspicio.ofertas.size(), "tab": "Finanzas"})

	if salida.is_empty():
		salida.append({"grave": false, "txt": "Todo en orden: sin lesionados largos, sin contratos en el aire y con la caja sana.", "tab": ""})
	return salida

# ===========================================================================
#  LA MODA TÁCTICA Y LO QUE DE VERDAD TE FUNCIONA
# ===========================================================================
#
# Ideas 411 y 412: «evolución táctica por era: el fútbol de moda cambia con los
# años» y «estadística de eficacia por cada táctica utilizada».
#
# LAS DOS JUNTAS SON UNA SOLA COSA. Sin la primera, la mejor formación del juego
# es la mejor para siempre y se elige una vez en diez temporadas. Sin la segunda,
# el jugador no tiene forma de saber que la moda cambió: lo notaría perdiendo y
# sin entender por qué.

## Las eras del fútbol, en orden. Cada una favorece un dibujo y castiga otro, y
## duran entre cuatro y siete temporadas. Son las modas de verdad del fútbol
## moderno, puestas en fila.
const ERAS_TACTICAS := [
	["contragolpe", "La era del contragolpe", ["4-4-2", "5-3-2"], ["4-3-3"],
		"Se juega replegado y a la espalda. Los bloques bajos ganan partidos."],
	["posesion", "La era de la posesión", ["4-3-3", "3-5-2"], ["4-4-2"],
		"Manda el que tiene la pelota. Los equipos que solo esperan se ahogan."],
	["presion", "La era de la presión alta", ["4-2-3-1", "4-3-3"], ["5-3-2"],
		"Se roba arriba y se ataca en cinco segundos. Salir jugando desde atrás es un riesgo."],
	["bloque", "La era del bloque medio", ["4-2-3-1", "4-4-2"], ["3-5-2"],
		"Ni arriba ni atrás: se defiende en el centro y se sale rápido por fuera."],
]

## Cuánto pesa estar de moda. Un 5% arriba y un 5% abajo: lo justo para que se
## note en una temporada larga y no tanto como para que el dibujo elegido decida
## los partidos por encima de los jugadores.
const BONO_MODA := 1.05
const CASTIGO_MODA := 0.95

var era_tactica: int = 0
var era_hasta: int = 0

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

## Cada temporada se mira si la moda cambia. Va al cierre del año, con el resto.
func _rodar_era() -> void:
	if era_hasta == 0:
		era_hasta = anio + Azar.ent(4, 7)
		return
	if anio < era_hasta:
		return
	era_tactica = (era_tactica + 1) % ERAS_TACTICAS.size()
	era_hasta = anio + Azar.ent(4, 7)
	var e := era_actual()
	if prensa != null:
		prensa.noticia.emit("Cambia la moda: %s" % String(e[1]),
			"%s Los que juegan con %s salen ganando; los de %s van a sufrir." % [
				String(e[4]), ", ".join(e[2]), ", ".join(e[3])])

# ---------------------------------------------------------------------------
#  QUÉ TE FUNCIONA A TI
# ---------------------------------------------------------------------------
#
# El registro de lo que pasa con CADA dibujo que usas: partidos, puntos y goles.
# No dice cuál es el mejor del juego —eso depende de tu plantilla—: dice cuál te
# está funcionando a TI, que es la única pregunta que importa.

## formacion -> {pj, pg, pe, pp, gf, gc}
var eficacia_tactica: Dictionary = {}

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

## Las formaciones que has usado, ordenadas por puntos por partido. Es la tabla
## que contesta «¿de verdad me funciona el 4-3-3?».
func ranking_tactico() -> Array[Dictionary]:
	var salida: Array[Dictionary] = []
	for k: String in eficacia_tactica:
		var f: Dictionary = eficacia_tactica[k]
		var pj := int(f["pj"])
		if pj <= 0:
			continue
		salida.append({
			"formacion": k, "pj": pj, "pg": int(f["pg"]), "pe": int(f["pe"]), "pp": int(f["pp"]),
			"gf": int(f["gf"]), "gc": int(f["gc"]),
			"ppp": float(int(f["pg"]) * 3 + int(f["pe"])) / float(pj),
			"moda": factor_moda(k),
		})
	salida.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return float(a["ppp"]) > float(b["ppp"]))
	return salida

# ---------------------------------------------------------------------------
#  ROTACIÓN Y VIDEOANÁLISIS
# ---------------------------------------------------------------------------
#
# Ideas 414 y 441: «rotación planificada para calendarios congestionados» y
# «video-análisis grupal antes de rivales difíciles».
#
# LA ROTACIÓN no es cambiar el once a mano —eso ya se puede—: es decirle al club
# que en las semanas de tres partidos guarde a los que están fundidos. Sin esto,
# una semana de liga + copa + continental te deja el plantel a treinta de físico
# y no hay forma de evitarlo salvo alinear a mano cada jornada.

## Cuánto físico hace falta para ser titular con la rotación puesta.
const FISICO_PARA_TITULAR := 62

var rotacion_activa: bool = false

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

# ---------------------------------------------------------------------------
#
# EL VIDEOANÁLISIS es la única preparación que se hace ANTES de saber cómo va el
# partido. Cuesta una sesión de la semana y da un empujón contra el rival de
# turno; contra uno mucho mejor que tú, da más: es para lo que se usa de verdad.

const SEMANAS_ENTRE_ANALISIS := 3
var _ultimo_analisis: int = -99
var bono_analisis: float = 1.0

func puede_analizar() -> bool:
	return semana - _ultimo_analisis >= SEMANAS_ENTRE_ANALISIS

## Prepara al equipo para el rival de esta semana. Devuelve "" si se hizo.
func analizar_rival() -> String:
	if not puede_analizar():
		return "ya hicisteis videoanálisis hace poco: uno cada %d semanas" % SEMANAS_ENTRE_ANALISIS
	var mio := mi_club()
	if mio == null:
		return "no hay club"
	var l := liga_de(mio)
	var par := l.emparejamiento_de(mio) if l != null else []
	if par.size() != 2:
		return "esta semana no hay rival que estudiar"
	var rival: Club = par[0] if par[0] != mio else par[1]
	_ultimo_analisis = semana
	## Contra uno mejor que tú el análisis vale más: estudiar a un equipo que te
	## supera es lo que de verdad cambia un partido, y estudiar al colista no.
	var diferencia := rival.rep - mio.rep
	bono_analisis = 1.0 + clampf(0.02 + float(diferencia) * 0.004, 0.01, 0.07)
	## Y el analista de vídeo del cuerpo técnico lo afina.
	if staff != null:
		bono_analisis += 0.005 * float(staff.nivel("ojeador"))
	for j in mio.plantilla:
		j.fisico = clampi(j.fisico - 2, 10, 100)
	if prensa != null:
		prensa.noticia.emit("Videoanálisis de %s" % rival.nombre,
			"Sesión de vídeo con todo el plantel: dónde aprietan, por dónde salen y a quién hay que tapar. El equipo sale al campo con la lección hecha (+%d%%)." % int(round((bono_analisis - 1.0) * 100.0)))
	return ""

## Se consume al jugar: el análisis vale para UN partido, no para siempre.
func consumir_analisis() -> float:
	var b := bono_analisis
	bono_analisis = 1.0
	return b
