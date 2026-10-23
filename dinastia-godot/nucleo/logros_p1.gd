extends RefCounted
## (Parte 1 de 3 de `logros.gd`: la norma de 450 líneas lo partió en capas, cada una extiende a la anterior; la última, `logros.gd`, conserva la clase.)

## La memoria del club, los premios de la temporada y el perfil de gestor.
##
## Son tres cosas distintas y están juntas a propósito, porque en el HTML ya lo
## estaban y porque se alimentan unas a otras: dos de los veinte logros
## ("Muralla" y "Sin piedad") no se pueden comprobar mirando el estado del
## mundo, solo mirando lo que ha pasado. Alguien tiene que ir apuntando racha
## por racha y récord por récord, y ese alguien es esta clase. Separarlo en tres
## ficheros obligaría a que dos de ellos se conocieran igual.
##
## Las tres capas, de la más corta a la más larga:
##
##  1. MEMORIA DEL CLUB. Cara a cara, rachas, récords y efemérides. Vive dentro
##     de una partida y se guarda con ella (`a_dic()` / `desde_dic()`).
##  2. PREMIOS DE TEMPORADA. La gala de fin de año: equipo ideal, mejor joven,
##     mejor entrenador, fair play, hinchada y estadio.
##  3. PERFIL DE GESTOR. Sobrevive a la partida. Se guarda en `user://` y no se
##     borra al empezar de cero: es tu carrera por encima de cada carrera. Solo
##     suma reconocimiento, nunca bloquea contenido; esa regla es del HTML y se
##     mantiene.
##
## Los textos de los logros NO están escritos aquí: salen de la tabla LOGROS que
## exportó el HTML, igual que los clubes o las demarcaciones. Aquí solo viven las
## CONDICIONES, que en JavaScript eran funciones dentro de la propia tabla y por
## eso no se pudieron exportar (el JSON las dejó en `null`).

## El logro cae en el momento en que se cumple, no al final de la temporada: por
## eso hay señal y no un valor de retorno que alguien tenga que ir a mirar.
signal logro_desbloqueado(clave: String, icono: String, titulo: String, descripcion: String)
signal record_batido(clave: String, ficha: Dictionary)
## Las efemérides son la voz del club: goleadas, palizas, placas conmemorativas y
## aniversarios. En el HTML todo esto entraba por `noticia()`; aquí no hay
## bandeja de noticias todavía, así que sale por aquí y quien quiera la pinta.
signal efemeride_nueva(anio: int, texto: String)
signal canterano_debuta(j: Jugador)
signal premios_entregados(premios: Dictionary)
signal perfil_subio_de_nivel(nivel: int, nombre: String, lema: String)
## Se emite cada vez que TU club levanta un título -liga, copa o continental-.
## Existe solo para el sonido de "trofeo": `celebrar_titulo()` la llama tambien
## `Mundo.nueva_temporada()` durante el banco de pruebas headless, que juega
## cientos de temporadas sin pantalla, y `Sonido` no debe sonar ahi -la misma
## regla de siempre, la de `_al_gol()` en `partido_vivo.gd`-. Quien quiera el
## sonido se conecta a esto, no se toca aqui dentro.
signal titulo_celebrado(nombre: String)

# ---------------------------------------------------------------------------
#  PERFIL DE GESTOR
# ---------------------------------------------------------------------------

## Los siete niveles, tal cual vienen del HTML: umbral de experiencia, nombre y
## lema. El salto entre niveles casi se dobla cada vez, y eso es lo que hace que
## llegar a "Dinastía" sea cosa de muchas carreras y no de una tarde.
const NIVELES_PERFIL := [
	[0, "Aficionado", "Acabas de llegar al fútbol de verdad."],
	[150, "Ayudante", "Ya sabes por dónde se entra al vestuario."],
	[400, "Entrenador", "Tienes oficio y algún banco que lo demuestra."],
	[900, "Técnico de oficio", "Los clubes te llaman antes de mirar a nadie más."],
	[1800, "Maestro", "Tus equipos se reconocen a la primera."],
	[3200, "Leyenda", "Ya no diriges clubes: diriges épocas."],
	[5500, "Dinastía", "Tu apellido es una manera de entender el fútbol."],
]

## Lo que paga cada cosa. Son los cuatro `perfilXP()` que hay repartidos por el
## HTML, recogidos aquí para que se vea de un vistazo de dónde sale la carrera:
## ganar títulos, aguantar temporadas enteras, sacar chicos de la cantera y el
## día que dejas de ser el ayudante de alguien.
const XP_TITULO := 120
const XP_TEMPORADA := 35
const XP_DEBUT_CANTERANO := 20
const XP_ASCENSO_AYUDANTE := 200

## El HTML lo guarda en `localStorage['dinPerfil']`. Aquí va a `user://`, que es
## la carpeta del usuario y no la del juego: reinstalar o recompilar no se lo
## lleva por delante, que es justo lo que promete la pantalla del perfil.
const RUTA_PERFIL := "user://perfil_gestor.json"

# ---------------------------------------------------------------------------
#  MEMORIA DEL CLUB
# ---------------------------------------------------------------------------

## Topes del HTML. La memoria de un club de veinte temporadas no cabe en una
## pantalla ni le interesa a nadie entera: se queda con lo último y lo mejor.
const MAX_EFEMERIDES := 60
const MAX_PLANTELES := 40
const MAX_PREMIOS := 30

## Diferencia de goles a partir de la cual un partido se recuerda por escrito.
const DIF_EFEMERIDE := 4

## OJO: referencia DEBIL al mundo, no fuerte.
##
## El mundo guarda sus logros y los logros necesitan ver el mundo. Con dos
## referencias normales eso es un ciclo, y RefCounted no recoge ciclos: al salir
## del banco de pruebas se quedaban 19.259 objetos sin liberar, porque un Mundo
## que no muere se lleva consigo sus clubes y sus miles de jugadores. Es la misma
## trampa que ya cazamos en `mercado.gd`, `prensa.gd` y `roles.gd`.
##
## Se expone como propiedad para no tener que reescribir los cuarenta usos: el
## `get` resuelve la referencia debil cada vez.
var mundo: Mundo:
	get:
		return _ref_mundo.get_ref() as Mundo if _ref_mundo != null else null
	set(v):
		_ref_mundo = weakref(v) if v != null else null
var _ref_mundo: WeakRef
## El año en que tomaste el mando. El HTML restaba contra un 2026 escrito a mano
## porque la partida siempre empezaba ahí; aquí se apunta, que sale igual de
## barato y no se rompe el día que se pueda empezar en otro año.
var anio_inicio: int = 2026

var desbloqueados: Dictionary = {}      ## clave -> {"anio": int, "semana": int}
var h2h: Dictionary = {}                ## club_id rival -> {pj, pg, pe, pp, gf, gc}
var rachas: Dictionary = {
	"invicto": 0, "invicto_max": 0,
	"sin_ganar": 0, "sin_ganar_max": 0,
	"ganando": 0, "ganando_max": 0,
}
var rec: Dictionary = {}                ## mayor_goleada, peor_derrota, mas_goles, mas_publico, goles, pj
var efemerides: Array = []
var muro: Array = []                    ## un título levantado, con el once que lo levantó
var planteles: Array = []               ## la foto de plantilla de cada temporada
var premios: Array = []                 ## las galas, la más reciente primero
## Los canteranos que ya han debutado, por id. Se guarda el conjunto y no un
## contador porque el mismo chico juega muchos partidos y solo debuta una vez.
var canteranos_debutados: Dictionary = {}

## LA TRAMPA DE LOS DEBUTS, QUE COSTÓ UNA PRUEBA ENTERA.
##
## `Mundo._poblar()` crea la plantilla inicial de cada club con
## `club_formacion = club.id`, así que los veinticuatro jugadores con los que
## coges el equipo son, técnicamente, canteranos de la casa. Mirando solo ese
## campo, el logro "Fábrica" (quince canteranos debutados) saltaba en la
## jornada diecisiete de la PRIMERA temporada, sin que hubieras subido a nadie.
##
## Por eso se apunta quién estaba ya en la plantilla el día que llegaste: esos no
## debutan, ya estaban. Solo cuenta el que aparece después, que es exactamente lo
## que en el HTML llamaba a `ceremoniaDebut()`. Va al guardado con todo lo demás;
## si no, cargar una partida convertía a la plantilla entera en debutantes.
var _ya_estaban: Dictionary = {}
var _plantilla_anotada: bool = false

## Logros cuya condición NO se puede evaluar todavía porque el sistema del que
## dependen no está portado. Se listan aquí, y no repartidos en comentarios, para
## que se vean juntos: es la lista de lo que le falta al juego para estar
## completo, escrita desde el lado del jugador.
##
##   linaje  -> hijos de leyendas (Jugador no tiene linaje)
##   magnate -> comprar acciones de tu club
##   pro     -> licencias de entrenador
##   escuela -> que la prensa bautice tu estilo de juego
##   imperio -> los negocios anexos de la ciudad deportiva
##   verde   -> certificación ecológica del estadio
##   leyenda -> el prestigio del entrenador, que aquí no existe: `Directiva.
##              confianza` es lo que piensa TU directiva de ti, que es otra cosa
##              y no se puede usar en su lugar
##
## Siguen en el catálogo porque están en la tabla y porque enseñarlos bloqueados
## es honesto; lo que no sería honesto es hacerlos saltar con una condición
## parecida pero distinta.
const SIN_SISTEMA := ["linaje", "magnate", "pro", "escuela", "imperio", "verde", "leyenda"]

# ---------------------------------------------------------------------------
#  LOGROS OCULTOS
# ---------------------------------------------------------------------------
#
# Los diez de `LOGROS_OCULTOS`. No se anuncian: no salen en ninguna lista hasta
# que caen, y hasta entonces la pantalla enseña "???". Esa es toda la gracia —
# premian cosas que casi nunca pasan y que nadie va a perseguir a propósito
# porque no sabe que existen.
#
# Tres de los diez del HTML NO se pueden comprobar todavía y se dejan fuera a
# propósito, en vez de fingir que se comprueban: `fenix` (ascender el año
# siguiente a un descenso) necesita memoria de descensos, y `museo` necesita el
# museo, que no está portado. Un logro que nunca puede caer es peor que uno que
# no está: el jugador lo ve gris para siempre y no sabe que es imposible.

## clave -> año en que cayó.
var ocultos: Dictionary = {}

## Marcas de cosas que pasan DENTRO de un partido y que al terminar ya no se
## pueden deducir del resultado. La pone quien las ve; aquí solo se guardan.
var marcas: Dictionary = {}

# ---------------------------------------------------------------------------
#  PREMIOS DE FIN DE TEMPORADA
# ---------------------------------------------------------------------------

## Las once plazas del equipo ideal, en el orden en que se reparten. Es un 4-3-3
## fijo: el HTML no elige formación para la gala, y tampoco tiene sentido que la
## elija, porque no es un equipo que vaya a jugar.
const PUESTOS_IDEAL := ["POR", "DEF", "DEF", "DEF", "DEF", "MED", "MED", "MED", "DEL", "DEL", "DEL"]

## Partidos mínimos para entrar en la gala. El HTML pedía ocho notas de partido;
## aquí se piden ocho partidos, que es la misma idea: al que jugó tres no se le
## premia por una buena tarde.
const PARTIDOS_MINIMOS := 8

# ---------------------------------------------------------------------------
#  RIVALIDADES
# ---------------------------------------------------------------------------
#
# `vRivalidades()`: la rivalidad NO se declara, se construye. Y no hace falta
# guardarla en ningún sitio nuevo —eso sería otro contador más que mantener al
# día y que puede desincronizarse—: se DEDUCE del cara a cara, que ya se lleva
# partido a partido, más si es clásico de origen.
#
# Lo que la sube: jugar mucho contra alguien, y sobre todo perder. Una paliza
# recibida pesa más que una ganada, porque así funciona el rencor.

## clave -> [umbral, nombre]. De menos a más.
const NIVELES_RIVALIDAD := [
	[80, "Odio deportivo"],
	[60, "Clásico consolidado"],
	[35, "Rivalidad viva"],
	[0, "Roce menor"],
]

## Lee el perfil del disco. Si no hay nada o está roto, devuelve uno en blanco:
## un perfil ilegible no puede impedir jugar, como mucho empezar de cero.
static func perfil_leer() -> Dictionary:
	var vacio := {"xp": 0, "hitos": {}, "desde": 0}
	if not FileAccess.file_exists(RUTA_PERFIL):
		return vacio
	var f := FileAccess.open(RUTA_PERFIL, FileAccess.READ)
	if f == null:
		return vacio
	var crudo := f.get_as_text()
	f.close()
	var j := JSON.new()
	if j.parse(crudo) != OK or typeof(j.data) != TYPE_DICTIONARY:
		return vacio
	var d: Dictionary = j.data
	return {
		"xp": int(d.get("xp", 0)),
		"hitos": d.get("hitos", {}),
		"desde": int(d.get("desde", 0)),
	}

static func perfil_guardar(p: Dictionary) -> void:
	var f := FileAccess.open(RUTA_PERFIL, FileAccess.WRITE)
	if f == null:
		## Que no se pueda escribir el perfil no es motivo para tirar la partida:
		## se pierde el reconocimiento, no el juego.
		push_warning("Logros: no puedo guardar el perfil de gestor en %s" % RUTA_PERFIL)
		return
	f.store_string(JSON.stringify(p))
	f.close()

## En qué nivel cae una cantidad de experiencia, con lo que hace falta para
## pintar la barra: cuánto llevas dentro del nivel y cuánto falta para el
## siguiente.
static func perfil_nivel(xp: int) -> Dictionary:
	var i := 0
	for k in NIVELES_PERFIL.size():
		if xp >= int(NIVELES_PERFIL[k][0]):
			i = k
	var actual: Array = NIVELES_PERFIL[i]
	var hay_siguiente := i + 1 < NIVELES_PERFIL.size()
	var base := int(actual[0])
	var tope := int(NIVELES_PERFIL[i + 1][0]) if hay_siguiente else base
	return {
		"i": i,
		"nombre": String(actual[1]),
		"lema": String(actual[2]),
		"xp": xp,
		"base": base,
		"tope": tope,
		"pct": int(round(float(xp - base) / float(maxi(1, tope - base)) * 100.0)) if hay_siguiente else 100,
		"siguiente": String(NIVELES_PERFIL[i + 1][1]) if hay_siguiente else "",
		"faltan": tope - xp if hay_siguiente else 0,
	}

## Suma experiencia y devuelve {antes, ahora, subio}.
##
## `hito` es la red contra los bucles: si se pasa una etiqueta, esa experiencia
## se cobra UNA vez en la vida del perfil. El HTML lo puso para el ascenso de
## ayudante a entrenador, que si no se podía repetir carrera tras carrera con la
## misma partida guardada.
static func perfil_sumar_xp(n: int, hito: String = "") -> Dictionary:
	var p := perfil_leer()
	var antes := perfil_nivel(int(p["xp"]))
	if n == 0:
		return {"antes": antes, "ahora": antes, "subio": false}
	var hitos: Dictionary = p["hitos"]
	if hito != "":
		if hitos.has(hito):
			return {"antes": antes, "ahora": antes, "subio": false}
		hitos[hito] = 1
	p["xp"] = int(p["xp"]) + n
	if int(p["desde"]) == 0:
		p["desde"] = int(Time.get_unix_time_from_system())
	perfil_guardar(p)
	var ahora := perfil_nivel(int(p["xp"]))
	return {"antes": antes, "ahora": ahora, "subio": int(ahora["i"]) > int(antes["i"])}

## La versión con señal, para cuando hay una partida delante mirando. La estática
## de arriba existe aparte porque el perfil también sube desde el menú, donde no
## hay ni mundo ni nadie conectado a nada.
func sumar_xp(n: int, hito: String = "") -> Dictionary:
	var r := perfil_sumar_xp(n, hito)
	if bool(r["subio"]):
		var a: Dictionary = r["ahora"]
		perfil_subio_de_nivel.emit(int(a["i"]) + 1, String(a["nombre"]), String(a["lema"]))
	return r

## Se intenta al construir y otra vez en el primer partido, porque `Logros` se
## puede crear antes de que haya club: el orden natural es generar el mundo,
## crear esto y luego elegir equipo.
func _anotar_plantilla_inicial() -> void:
	if _plantilla_anotada or mundo == null:
		return
	var c := mundo.mi_club()
	if c == null:
		return
	for j in c.plantilla:
		_ya_estaban[j.id] = true
	_plantilla_anotada = true

func _init(m: Mundo = null) -> void:
	mundo = m
	if m != null:
		anio_inicio = m.anio
	rec = {"goles": {}, "pj": {}}
	_anotar_plantilla_inicial()

func marcar(clave: String) -> void:
	marcas[clave] = true

func _anotar_cara_a_cara(rival: Club, gf: int, gc: int, gane: bool, empate: bool) -> void:
	if not h2h.has(rival.id):
		h2h[rival.id] = {"pj": 0, "pg": 0, "pe": 0, "pp": 0, "gf": 0, "gc": 0}
	var h: Dictionary = h2h[rival.id]
	h["pj"] += 1
	h["gf"] += gf
	h["gc"] += gc
	if gane:
		h["pg"] += 1
	elif empate:
		h["pe"] += 1
	else:
		h["pp"] += 1

## Las tres rachas del HTML. Ojo con la de invicto: el empate la MANTIENE (no
## has perdido) pero corta la de victorias. Confundirlas hacía que "Muralla"
## saltara con veinte empates seguidos, que no es lo que promete el logro.
func _anotar_rachas(gane: bool, empate: bool) -> void:
	if gane:
		rachas["invicto"] += 1
		rachas["ganando"] += 1
		rachas["sin_ganar"] = 0
	elif empate:
		rachas["invicto"] += 1
		rachas["ganando"] = 0
		rachas["sin_ganar"] += 1
	else:
		rachas["invicto"] = 0
		rachas["ganando"] = 0
		rachas["sin_ganar"] += 1
	rachas["invicto_max"] = maxi(int(rachas["invicto_max"]), int(rachas["invicto"]))
	rachas["ganando_max"] = maxi(int(rachas["ganando_max"]), int(rachas["ganando"]))
	rachas["sin_ganar_max"] = maxi(int(rachas["sin_ganar_max"]), int(rachas["sin_ganar"]))

func _fijar_record(clave: String, ficha: Dictionary, campo: String, valor: int) -> void:
	var d := ficha.duplicate()
	d[campo] = valor
	rec[clave] = d
	record_batido.emit(clave, d)

func _anotar_records(rival: Club, gf: int, gc: int, competicion: String, publico: int) -> void:
	var dif := gf - gc
	var ficha := {
		"rival": rival.nombre, "marcador": "%d-%d" % [gf, gc],
		"anio": mundo.anio, "semana": mundo.semana, "competicion": competicion,
	}
	if not rec.has("mayor_goleada") or dif > int(rec["mayor_goleada"]["dif"]):
		_fijar_record("mayor_goleada", ficha, "dif", dif)
	if not rec.has("peor_derrota") or dif < int(rec["peor_derrota"]["dif"]):
		_fijar_record("peor_derrota", ficha, "dif", dif)
	if not rec.has("mas_goles") or gf > int(rec["mas_goles"]["g"]):
		_fijar_record("mas_goles", ficha, "g", gf)
	if publico > 0 and (not rec.has("mas_publico") or publico > int(rec["mas_publico"]["n"])):
		_fijar_record("mas_publico", ficha, "n", publico)

## Un canterano es el que se formó aquí; debuta el día que pisa el campo con el
## primer equipo. `Jugador.club_formacion` ya lo dice, así que no hace falta
## marcar a nadie: basta con mirar quién salta hoy y no había saltado nunca.
func _mirar_debut(j: Jugador) -> void:
	if canteranos_debutados.has(j.id) or _ya_estaban.has(j.id):
		return
	if j.club_formacion == "" or j.club_formacion != mundo.mi_club_id:
		return
	canteranos_debutados[j.id] = true
	canterano_debuta.emit(j)
	sumar_xp(XP_DEBUT_CANTERANO)

## Partidos y goles históricos del club, y de paso los debuts de cantera.
##
## El HTML sacaba los goleadores rascando con una expresión regular el texto de
## la crónica ("¡GOL! Fulano de cabeza..."), porque allí el evento solo guardaba
## la frase. Aquí la crónica ya trae el autor en un campo, así que no hay que
## adivinar nada: es la misma información sin el parche.
func _anotar_participaciones(p: Partido, soy_local: bool) -> void:
	var once: Array[Jugador] = p.once_local if soy_local else p.once_visita
	var pj: Dictionary = rec["pj"]
	for j in once:
		var nombre := Nombres.visible(j.nombre)
		if not pj.has(j.id):
			pj[j.id] = {"nombre": nombre, "n": 0}
		pj[j.id]["n"] += 1
		_mirar_debut(j)
	var goles: Dictionary = rec["goles"]
	var mi_id := (p.local if soy_local else p.visita).id
	for e: Dictionary in p.cronica:
		if String(e.get("tipo", "")) != "gol" or String(e.get("club", "")) != mi_id:
			continue
		var autor := Nombres.visible(String(e.get("autor", "")))
		if autor == "" or autor == "?":
			continue
		goles[autor] = int(goles.get(autor, 0)) + 1

func _apuntar_efemeride(texto: String) -> void:
	efemerides.append({"anio": mundo.anio, "semana": mundo.semana, "texto": texto})
	while efemerides.size() > MAX_EFEMERIDES:
		efemerides.pop_front()
	efemeride_nueva.emit(mundo.anio, texto)

func _algun_trofeo(trofeos: Array, fragmentos: Array) -> bool:
	for t: String in trofeos:
		for f: String in fragmentos:
			if t.containsn(f):
				return true
	return false
