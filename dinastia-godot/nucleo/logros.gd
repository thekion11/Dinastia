class_name Logros
extends RefCounted
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

func _init(m: Mundo = null) -> void:
	mundo = m
	if m != null:
		anio_inicio = m.anio
	rec = {"goles": {}, "pj": {}}
	_anotar_plantilla_inicial()

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

## Se llama al terminar cada partido de tu club. Alimenta cara a cara, rachas,
## récords, goleadores históricos y debuts de cantera, y de paso revisa si algo
## de eso acaba de desbloquear un logro.
##
## `publico` lo pone quien lo sepa (`Finanzas.asistencia()`); a cero no se anota
## récord de asistencia, que es mejor que anotar uno inventado.
func tras_partido(p: Partido, competicion: String = "Liga", publico: int = 0, por_penales: bool = false) -> void:
	if mundo == null or p == null:
		return
	var mio := mundo.mi_club()
	if mio == null:
		return
	var soy_local := p.local == mio
	if not soy_local and p.visita != mio:
		return   ## no es mi partido: la memoria es la del club que diriges

	_anotar_plantilla_inicial()
	var rival: Club = p.visita if soy_local else p.local
	var mis_goles := p.goles_local if soy_local else p.goles_visita
	var sus_goles := p.goles_visita if soy_local else p.goles_local
	var gane := mis_goles > sus_goles
	var empate := mis_goles == sus_goles
	if gane and p.hubo_remontada_de(mio):
		marcar("remontada")

	_anotar_cara_a_cara(rival, mis_goles, sus_goles, gane, empate)
	_anotar_rachas(gane, empate)
	_anotar_records(rival, mis_goles, sus_goles, competicion, publico)
	_anotar_participaciones(p, soy_local)

	var dif := mis_goles - sus_goles
	if absi(dif) >= DIF_EFEMERIDE or (por_penales and not empate):
		var texto := ""
		if dif > 0:
			texto = "Goleada %d-%d a %s" % [mis_goles, sus_goles, rival.nombre]
		else:
			texto = "Paliza %d-%d de %s" % [sus_goles, mis_goles, rival.nombre]
		_apuntar_efemeride(texto)

	revisar()

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

func _fijar_record(clave: String, ficha: Dictionary, campo: String, valor: int) -> void:
	var d := ficha.duplicate()
	d[campo] = valor
	rec[clave] = d
	record_batido.emit(clave, d)

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
		var nombre := Nombres.limpiar(j.nombre)
		if not pj.has(j.id):
			pj[j.id] = {"nombre": nombre, "n": 0}
		pj[j.id]["n"] += 1
		_mirar_debut(j)
	var goles: Dictionary = rec["goles"]
	var mi_id := (p.local if soy_local else p.visita).id
	for e: Dictionary in p.cronica:
		if String(e.get("tipo", "")) != "gol" or String(e.get("club", "")) != mi_id:
			continue
		var autor := Nombres.limpiar(String(e.get("autor", "")))
		if autor == "" or autor == "?":
			continue
		goles[autor] = int(goles.get(autor, 0)) + 1

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

func _apuntar_efemeride(texto: String) -> void:
	efemerides.append({"anio": mundo.anio, "semana": mundo.semana, "texto": texto})
	while efemerides.size() > MAX_EFEMERIDES:
		efemerides.pop_front()
	efemeride_nueva.emit(mundo.anio, texto)

## Levantar un título. Es lo más caro del perfil de gestor y lo único que llena
## la vitrina, y además se NOTA en el club: la hinchada se vuelca, llegan socios
## nuevos y el vestuario se pone a tope de moral.
##
## Esos tres efectos no son adorno. En el HTML son lo que hace que el año
## siguiente a un título se juegue distinto: más gente en el estadio, más cuotas
## y una plantilla que rinde. Un título que solo añade una línea a una lista es
## una pantalla, no un premio.
func celebrar_titulo(nombre: String) -> void:
	if mundo == null:
		return
	var c := mundo.mi_club()
	if c == null:
		return
	sumar_xp(XP_TITULO)
	titulo_celebrado.emit(nombre)

	var once := c.plantilla.duplicate()
	once.sort_custom(func(a: Jugador, b: Jugador) -> bool: return a.ovr > b.ovr)
	var nombres: Array[String] = []
	for j in once.slice(0, 11):
		nombres.append(Nombres.limpiar(j.nombre))
	muro.append({"anio": mundo.anio, "titulo": nombre, "once": nombres})

	c.confianza = clampi(c.confianza + Azar.ent(8, 16), 0, 100)
	c.socios += Azar.ent(600, 2200)
	for j in c.plantilla:
		j.moral = 99

	var total := mundo.directiva.trofeos.size() if mundo.directiva != null else muro.size()
	if total > 0 and total % 10 == 0:
		_apuntar_efemeride("El club coloca una placa en el acceso principal por los %d títulos de tu era" % total)
	var anios := mundo.anio - anio_inicio
	if anios > 0 and anios % 5 == 0:
		_apuntar_efemeride("Se cumplen %d años de tu llegada: gala con las leyendas de la casa y lleno absoluto" % anios)

	revisar()

# ---------------------------------------------------------------------------
#  LOS VEINTE LOGROS
# ---------------------------------------------------------------------------

## Las condiciones que el JSON no pudo traer.
##
## Van en un `match` y no en un diccionario de `Callable`, que sería la
## traducción literal del array de funciones del HTML, por dos razones: un
## `Callable` que llama a un método propio se queda con una referencia a este
## objeto, y este objeto se queda con el diccionario, así que el contador de
## referencias nunca llega a cero y la memoria del club no se libera nunca. Y
## además un `match` sale en la traza cuando algo falla, y una lambda anónima no.
func _cumple(clave: String) -> bool:
	if mundo == null:
		return false
	var c := mundo.mi_club()
	if c == null:
		return false
	var trofeos: Array = []
	if mundo.directiva != null:
		trofeos = mundo.directiva.trofeos

	match clave:
		"primer": return trofeos.size() >= 1
		"diez": return trofeos.size() >= 10
		"veinte": return trofeos.size() >= 20
		"conti": return _algun_trofeo(trofeos, ["Libertador", "Sudamer", "Champ", "Europ"])
		"mundoclub": return _algun_trofeo(trofeos, ["Mundial de Clubes"])
		"salvador": return _algun_trofeo(trofeos, ["Permanencia"])
		"invicto": return int(rachas["invicto_max"]) >= 20
		"goleada": return rec.has("mayor_goleada") and int(rec["mayor_goleada"]["dif"]) >= 6
		"cantera": return canteranos_debutados.size() >= 15
		"estadio": return c.estadio_aforo >= 60000
		"querido": return c.confianza >= 95
		"millon": return float(c.saldo) * Eco.ECO >= 100000000.0
		## "Manos limpias" pide diez temporadas sin un solo pago turbio. Los
		## sobornos todavía no están portados, así que no hay forma de
		## ensuciarse: aguantar diez años basta. El día que entren, la condición
		## solo tiene que sumar el "y sin pagos turbios" que le falta.
		"limpio": return mundo.anio - anio_inicio >= 10
	return false

func _algun_trofeo(trofeos: Array, fragmentos: Array) -> bool:
	for t: String in trofeos:
		for f: String in fragmentos:
			if t.containsn(f):
				return true
	return false

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

## Repasa los veinte y devuelve las claves que acaban de caer.
##
## Cada logro da UN PUNTO del árbol de habilidades del entrenador, igual que en
## el HTML. Esa línea llevaba desde el porte esperando a que el árbol existiera
## -el comentario de aquí decía literalmente "cuando lo esté, el sitio donde
## sumarlo es justo aquí"-; ya existe, así que ya suma. Es lo que convierte los
## logros en progreso y no en una lista de cromos.
func revisar() -> Array[String]:
	var nuevos: Array[String] = []
	var tabla: Variant = Datos.tabla("LOGROS")
	if tabla == null:
		return nuevos
	for fila: Array in tabla:
		var clave := String(fila[0])
		if desbloqueados.has(clave):
			continue
		if not _cumple(clave):
			continue
		desbloqueados[clave] = {"anio": mundo.anio, "semana": mundo.semana}
		nuevos.append(clave)
		if mundo != null and mundo.entrenamiento != null:
			mundo.entrenamiento.dt_sumar_puntos(1)
		logro_desbloqueado.emit(clave, String(fila[1]), String(fila[2]), String(fila[3]))
	nuevos.append_array(revisar_ocultos())
	return nuevos

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

func revisar_ocultos() -> Array[String]:
	var nuevos: Array[String] = []
	var tabla: Variant = Datos.tabla("LOGROS_OCULTOS")
	if not (tabla is Array) or mundo == null:
		return nuevos
	for fila: Array in tabla:
		var clave := String(fila[0])
		if ocultos.has(clave) or not _cumple_oculto(clave):
			continue
		ocultos[clave] = mundo.anio
		nuevos.append(clave)
		logro_desbloqueado.emit(clave, "🎖️", String(fila[1]), String(fila[2]))
	return nuevos

func _cumple_oculto(clave: String) -> bool:
	var c := mundo.mi_club()
	if c == null:
		return false
	match clave:
		"centenario":
			return mundo.roles != null and mundo.roles.trofeos.size() >= 100
		"mecenas":
			## Diez inyecciones de capital. `Roles` cuenta las de la temporada;
			## el total acumulado lo lleva `_inyecciones_totales`, que se añadió
			## para esto: sin él el logro solo podría caer dentro de un mismo año.
			return mundo.roles != null and mundo.roles.inyecciones_totales >= 10
		"imperio":
			return mundo.obras != null and mundo.obras.todo_al_maximo()
		"sabio":
			return mundo.entrenamiento != null and mundo.entrenamiento.mentorias.size() >= 4
		"cantera11":
			## Once canteranos a la vez. Se mira el once REAL, no la plantilla:
			## tener once de la casa en la lista no es alinearlos.
			var once := c.once()
			if once.size() < 11 or mundo.cantera == null:
				return false
			for j: Jugador in once:
				if not mundo.cantera.es_canterano(j):
					return false
			return true
		"idolos":
			var n := 0
			for j in c.plantilla:
				if j.partidos >= 60 and j.moral >= 80:
					n += 1
			return n >= 5
		"invicto":
			## Temporada invicta: se lee de las rachas, que ya cuentan el invicto
			## máximo del año.
			var l := mundo.liga_de(c)
			return l != null and not l.quedan_jornadas() and int(rachas.get("invicto", 0)) >= l.jornadas()
		"remontada":
			return bool(marcas.get("remontada", false))
	return false

## Marcas de cosas que pasan DENTRO de un partido y que al terminar ya no se
## pueden deducir del resultado. La pone quien las ve; aquí solo se guardan.
var marcas: Dictionary = {}

func marcar(clave: String) -> void:
	marcas[clave] = true

## Los ocultos con su estado, para la pantalla. Los que no han caído salen sin
## título ni descripción: enseñarlos delataría lo que hay que hacer.
func catalogo_oculto() -> Array[Dictionary]:
	var salida: Array[Dictionary] = []
	var tabla: Variant = Datos.tabla("LOGROS_OCULTOS")
	if not (tabla is Array):
		return salida
	for fila: Array in tabla:
		var clave := String(fila[0])
		var caido := ocultos.has(clave)
		salida.append({
			"clave": clave,
			"titulo": String(fila[1]) if caido else "???",
			"descripcion": String(fila[2]) if caido else "Sigue jugando.",
			"conseguido": caido,
			"anio": int(ocultos.get(clave, 0)),
		})
	return salida

func conseguido(clave: String) -> bool:
	return desbloqueados.has(clave)

func cuantos() -> int:
	return desbloqueados.size()

## Los veinte con su estado, listos para pintar una pantalla de logros sin que
## la interfaz tenga que saber nada de tablas ni de condiciones.
func catalogo() -> Array[Dictionary]:
	var salida: Array[Dictionary] = []
	var tabla: Variant = Datos.tabla("LOGROS")
	if tabla == null:
		return salida
	for fila: Array in tabla:
		var clave := String(fila[0])
		salida.append({
			"clave": clave,
			"icono": String(fila[1]),
			"titulo": String(fila[2]),
			"descripcion": String(fila[3]),
			"conseguido": desbloqueados.has(clave),
			"cuando": desbloqueados.get(clave, {}),
			"pendiente": SIN_SISTEMA.has(clave),
		})
	return salida

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

## LA NOTA DE LA TEMPORADA, Y LO QUE HAY QUE CAMBIAR CUANDO SE PORTEN LAS NOTAS.
##
## En el HTML cada jugador acumula un `ratingTemp`: un array con la nota que sacó
## en cada partido, y la gala ordena por su promedio. Ese sistema todavía no está
## portado a Godot, así que aquí se ordena con lo único que sí existe hoy —los
## partidos jugados, los goles y la media—, y eso tiene un sesgo que conviene
## tener presente: premia al delantero y deja al central y al portero ordenados
## solo por su media, que es la nota que traían de casa y no lo que hicieron
## este año.
##
## Cuando se porten las notas por partido, este método es el ÚNICO sitio que hay
## que tocar: se sustituye el cuerpo por el promedio del array de notas (con el
## mismo mínimo de ocho) y toda la gala pasa a ordenarse bien sola, porque nadie
## más mira los goles. No hay que inventar mientras tanto un sistema de notas
## paralelo: serían dos criterios distintos conviviendo y el día de la mudanza
## habría que decidir cuál gana.
func _nota_de_temporada(j: Jugador) -> float:
	if j.partidos < PARTIDOS_MINIMOS:
		return 0.0
	return float(j.ovr) + 1.5 * float(j.goles)

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
		ideal_texto.append("%s (%s, %s)" % [Nombres.limpiar(j.nombre), j.pos_e, _nombre_club(j.club_id)])
	acta["ideal"] = ideal_texto

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
	acta["joven"] = "%s (%d años, %s)" % [
		Nombres.limpiar(joven.nombre), joven.edad, _nombre_club(joven.club_id)] if joven != null else "—"

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
		ganados.append("Mejor joven: %s" % Nombres.limpiar(joven.nombre))
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

func _mayor_aforo(grandes: Array[Club], mio: Club) -> String:
	var mejor: Club = null
	for c in grandes:
		if c == mio:
			continue
		if mejor == null or c.estadio_aforo > mejor.estadio_aforo:
			mejor = c
	return mejor.nombre if mejor != null else "—"

## La foto de la plantilla del año, con el puesto y el mejor de los tuyos. Es lo
## que hace que dentro de quince temporadas se pueda mirar atrás y reconocer al
## equipo del primer ascenso.
func _archivar_plantel(puesto: int) -> void:
	var mio := mundo.mi_club()
	if mio == null:
		return
	var mvp: Jugador = null
	var mvp_nota := -1.0
	var lista: Array = []
	for j in mio.plantilla:
		var n := _nota_de_temporada(j)
		if n > mvp_nota:
			mvp_nota = n
			mvp = j
		## LA FOTO COMPLETA, no solo el nombre. Antes se guardaba la cadena
		## "Fulano (78)" y con eso no se podia enseñar el plantel de aquel año:
		## ni el dorsal, ni el puesto, ni lo que jugó, ni lo que hizo. Era una
		## memoria que no se podia consultar.
		lista.append({
			"n": Nombres.limpiar(j.nombre), "ovr": j.ovr, "pos": j.pos_e,
			"d": j.dorsal, "pj": j.partidos, "g": j.goles, "edad": j.edad,
		})
	planteles.append({
		"anio": mundo.anio, "puesto": puesto,
		"mvp": Nombres.limpiar(mvp.nombre) if mvp != null else "",
		"jugadores": lista,
	})
	while planteles.size() > MAX_PLANTELES:
		planteles.pop_front()

func _nombre_club(id: String) -> String:
	var c: Club = mundo.clubes.get(id)
	return c.nombre if c != null else "—"

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
