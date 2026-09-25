class_name Hinchada
extends RefCounted
## `vHinchada()` del HTML: la gente que llena el estadio, tratada como lo que es
## -grupos con intereses distintos que no se pueden contentar a la vez-.
##
## QUÉ ENTRA. Del original se portan los cinco sistemas que se sostienen con lo
## que el motor de Godot ya tiene: **segmentos**, **abonos**, **encuestas**,
## **peñas** y **ramas del club** (balonmano, básquet...) -ver `RAMAS`/
## `abrir_rama()`/`fundar_pena()` más abajo-. Las dos últimas SÍ dependen de
## `Ciudad` -vecinos, seguridad privada, terrenos-, y esa clase ya existe
## (`nucleo/ciudad.gd`): esta nota decía lo contrario y quedó desactualizada
## desde antes de que se escribiera `Ciudad`.
##
## LA IDEA QUE LO SOSTIENE: cinco grupos que quieren cosas distintas. El abono
## popular llena el estadio y gana al barrio pero recauda poco; el premium da
## dinero y enfada a las familias. No hay una opción correcta, hay una elegida.

const SEMANAS_TEMPORADA := 30

## Los cinco grupos, con lo que le importa a cada uno. La tabla vive en
## `datos/tablas.json` como todo lo demás.
var segmentos := {"historicos": 60, "nuevos": 55, "barra": 55, "familias": 60, "socios": 60}
var abono := "general"
var abonados := 0
var encuesta := {}   ## {pregunta, opciones, pct, mejor}

signal noticia(titulo: String, cuerpo: String)
signal movimiento(concepto: String, monto: int)

var _m: WeakRef = null   ## el Mundo, en WeakRef: ver la regla dura del LEEME

func _init(mundo: Mundo) -> void:
	_m = weakref(mundo)

func _mundo() -> Mundo:
	return _m.get_ref() if _m != null else null

func multiplicador_abono() -> float:
	var t: Variant = Datos.tabla("PLANES_ABONO")
	if t is Array:
		for fila: Array in (t as Array):
			if String(fila[0]) == abono:
				return float(fila[2])
	return 1.0

func nombre_abono() -> String:
	var t: Variant = Datos.tabla("PLANES_ABONO")
	if t is Array:
		for fila: Array in (t as Array):
			if String(fila[0]) == abono:
				return String(fila[1]).strip_edges()
	return abono

func fijar_abono(clave: String) -> void:
	abono = clave

## La campaña de abonos, al empezar cada temporada. Es un ingreso GRANDE y de
## una vez -ocho partidos cobrados por adelantado-, y es lo que hace que elegir
## plan importe: el popular llena pero deja poco por cabeza.
func campana_abonos(c: Club, animo: int, trofeos: int) -> int:
	var mult := multiplicador_abono()
	var atractivo := clampf((float(animo) / 100.0) * (1.25 - mult * 0.12) * (1.0 + float(trofeos) * 0.02), 0.15, 0.95)
	abonados = int(round(float(c.estadio_aforo) * atractivo * 0.62))
	var por_cabeza := Finanzas.ingreso_por_espectador(c.precio_entrada) * mult
	var ingreso := int(round(float(abonados) * por_cabeza * 8.0))
	c.mover_saldo(ingreso)
	movimiento.emit("Campaña de abonos (%s)" % nombre_abono(), ingreso)
	## Cada plan mueve a la gente de forma distinta: el popular gana al barrio,
	## el caro lo pierde.
	if abono == "popular":
		_mover("familias", 10)
		_mover("historicos", 6)
	elif abono == "premium" or abono == "vitalicio":
		_mover("familias", -8)
		_mover("historicos", -6)
	noticia.emit("Campaña de abonos",
		"%d abonados con el %s. Entran %d de golpe." % [abonados, nombre_abono().to_lower(), ingreso])
	return ingreso

func _mover(clave: String, delta: int) -> void:
	if segmentos.has(clave):
		segmentos[clave] = clampi(int(segmentos[clave]) + delta, 0, 100)

## Cada semana los grupos se mueven según cómo vaya el equipo. Los números son
## los del HTML: la barra es la que más rápido se enfada y la que más rápido se
## entusiasma, y el público familiar el que menos se mueve.
func semana(animo: int) -> void:
	var bien := animo > 65
	if Azar.suerte(0.40):
		_mover("historicos", 1 if bien else -1)
	if Azar.suerte(0.50):
		_mover("nuevos", 2 if bien else -2)
	if Azar.suerte(0.50):
		_mover("barra", 1 if bien else -2)
	if Azar.suerte(0.30):
		_mover("familias", 1 if bien else -1)
	if Azar.suerte(0.30):
		_mover("socios", 1 if bien else -1)
	## La barra por debajo de 25 es un problema que se nota en el estadio.
	if int(segmentos["barra"]) < 25 and Azar.suerte(0.12):
		noticia.emit("La barra se planta",
			"Silencio en la tribuna y lienzos contra la dirigencia. El ambiente se cae.")
	## Y de vez en cuando la gente opina, quieras o no.
	if encuesta.is_empty() and Azar.suerte(0.04):
		_lanzar_encuesta()

func _lanzar_encuesta() -> void:
	var t: Variant = Datos.tabla("PREGUNTAS")
	if not (t is Array) or (t as Array).is_empty():
		return
	## La tabla trae [clave, pregunta, opciones]: la pregunta es la SEGUNDA
	## columna, no la primera -la primera es el identificador interno-.
	var fila: Array = Azar.uno(t as Array)
	var opciones: Array = fila[2]
	var votos: Array[int] = []
	var total := 0
	for i in opciones.size():
		var v := Azar.ent(10, 60)
		votos.append(v)
		total += v
	var pct: Array[int] = []
	var mejor := 0
	for i in votos.size():
		pct.append(int(round(float(votos[i]) * 100.0 / float(maxi(total, 1)))))
		if votos[i] > votos[mejor]:
			mejor = i
	encuesta = {"pregunta": String(fila[1]), "opciones": opciones, "pct": pct, "mejor": mejor}
	noticia.emit("Encuesta a los socios", String(fila[1]))

## Responder la encuesta. Hacer lo que pide la mayoría sube el ánimo; ignorarla
## lo baja. No hay opción neutra: la gente ya opinó.
func responder_encuesta(indice: int) -> Dictionary:
	if encuesta.is_empty():
		return {"error": "no hay ninguna encuesta abierta"}
	var acertó := indice == int(encuesta["mejor"])
	var d_animo := Azar.ent(5, 11) if acertó else -Azar.ent(3, 8)
	_mover("socios", 10 if acertó else -8)
	encuesta = {}
	return {"ok": true, "acerto": acertó, "animo": d_animo}

## El fair play de la hinchada, que mira la federación. Del HTML se porta lo que
## tiene equivalente: la funa y el ánimo. Las cámaras y la seguridad privada
## salen de `initCiudad()`, que no existe aquí, así que no entran.
func fair_play(funa: int, animo: int) -> int:
	return clampi(60 - funa * 2 + int(round(float(animo - 50) * 0.25)), 0, 100)

func a_dic() -> Dictionary:
	return {"segmentos": segmentos, "abono": abono, "abonados": abonados, "encuesta": encuesta,
		"dias_hincha": dias_hincha, "penas": penas.duplicate(true), "ramas": ramas.duplicate(),
		"precio_dinamico": precio_dinamico}

func desde_dic(d: Dictionary) -> void:
	var s: Dictionary = d.get("segmentos", {})
	for k in segmentos:
		if s.has(k):
			segmentos[k] = int(s[k])
	abono = String(d.get("abono", "general"))
	abonados = int(d.get("abonados", 0))
	encuesta = d.get("encuesta", {})
	dias_hincha = int(d.get("dias_hincha", 0))
	penas = (d.get("penas", []) as Array).duplicate(true)
	ramas = (d.get("ramas", {}) as Dictionary).duplicate()
	precio_dinamico = bool(d.get("precio_dinamico", false))

# ---------------------------------------------------------------------------
#  EL DÍA DEL HINCHA
# ---------------------------------------------------------------------------

## Lo que cuesta organizarlo, antes de escalar al tamaño del club.
const COSTE_DIA_HINCHA := 26000.0

## Cuántos se han organizado. Es el número que mide si el club se acuerda de su
## gente o solo de sus resultados.
var dias_hincha: int = 0

## `organizarDiaHincha()`: puertas abiertas, entrenamiento a la vista, firmas y
## partido de leyendas. Sube TODOS los segmentos a la vez, que es lo que lo hace
## distinto de bajar el precio de la entrada -eso solo contenta al que paga-.
##
## Devuelve "" si se hizo, o el motivo por el que no.
func dia_del_hincha(c: Club, prensa) -> String:
	if c == null:
		return "no hay club"
	var coste := Eco.escalar(COSTE_DIA_HINCHA, float(c.rep))
	if c.saldo < coste:
		return "cuesta %s y no hay caja" % Cesiones.dinero(coste)
	c.mover_saldo(-coste)
	dias_hincha += 1
	c.socios += Azar.ent(400, 1600)
	for k: String in segmentos:
		segmentos[k] = clampi(int(segmentos[k]) + Azar.ent(3, 9), 0, 100)
	if prensa != null:
		prensa.mover_animo(Azar.ent(8, 15))
	for j in c.plantilla:
		j.moral = clampi(j.moral + 3, 10, 99)
	return ""

# ---------------------------------------------------------------------------
#  PEÑAS Y RAMAS DEL CLUB
# ---------------------------------------------------------------------------
#
# Las dos formas de que el club sea más que un equipo de fútbol.
#
# Las PEÑAS son gratis de mantener y suman socios donde no llegas: cada una es
# gente que se organiza sola en otra ciudad. Las RAMAS cuestan todos los meses y
# no dan dinero directo: dan REPUTACIÓN, que es lo que después mueve
# patrocinios, canteranos y lo que la gente piensa del club.
#
# Es deliberado que las ramas sean un gasto puro. Un club que solo hace lo que
# da dinero no es un club, es una empresa, y el juego tiene que dejar sitio para
# esa decisión.

const COSTE_PENA := 24000.0

const CIUDADES_PENA := [
	"Antofagasta", "Valparaíso", "Concepción", "Temuco", "Punta Arenas",
	"Iquique", "La Serena", "Chillán", "Osorno", "Arica",
	"Buenos Aires", "Madrid", "Nueva York", "Sídney", "Estocolmo", "Milán",
]

## clave, icono, nombre, coste de apertura, coste mensual, reputación que da,
## qué mejora, descripción.
const RAMAS := [
	["femenino", "⚽", "Fútbol femenino", 1400000, 22000, 7, "cantera",
		"Rama competitiva completa: reputación social y una cantera nueva"],
	["futsal", "🥅", "Futsal", 420000, 6000, 3, "barrio",
		"Barato y muy querido por el barrio"],
	["adaptado", "♿", "Deporte adaptado", 380000, 5000, 6, "imagen",
		"Impacto institucional enorme y patrocinadores que solo firman con clubes inclusivos"],
	["basquet", "🏀", "Baloncesto", 900000, 15000, 5, "taquilla",
		"Llena el polideportivo entre semana con su propia taquilla"],
	["voley", "🏐", "Vóleibol", 520000, 8000, 3, "barrio",
		"Deporte de colegio: la rama que más acerca a las familias del barrio"],
	["atletismo", "🏃", "Atletismo", 600000, 9000, 4, "fisico",
		"Pista, gimnasio y preparadores compartidos con el primer equipo"],
	["natacion", "🏊", "Natación", 700000, 11000, 4, "fisico",
		"Piscina propia: recuperación sin impacto para los lesionados"],
	["esports", "🎮", "eSports", 480000, 7000, 3, "digital",
		"Compite online y arrastra a un público que no pisa el estadio"],
]

var penas: Array = []      ## [{ciudad, socios}]
var ramas: Dictionary = {} ## clave -> true

func fundar_pena(c: Club) -> String:
	if c == null:
		return "no hay club"
	var usadas := {}
	for p: Dictionary in penas:
		usadas[String(p.get("ciudad", ""))] = true
	var libres: Array[String] = []
	for ciudad: String in CIUDADES_PENA:
		if not usadas.has(ciudad):
			libres.append(ciudad)
	if libres.is_empty():
		return "ya tienes peñas en todas partes"
	var coste := Eco.escalar(COSTE_PENA, float(c.rep))
	if c.saldo < coste:
		return "fundar una peña cuesta %s" % Cesiones.dinero(coste)
	c.mover_saldo(-coste)
	var elegida := String(Azar.uno(libres))
	var socios := Azar.ent(120, 900)
	penas.append({"ciudad": elegida, "socios": socios})
	c.socios += socios
	return elegida

func tiene_rama(clave: String) -> bool:
	return ramas.has(clave)

func def_rama(clave: String) -> Array:
	for f: Array in RAMAS:
		if String(f[0]) == clave:
			return f
	return []

func abrir_rama(clave: String, c: Club) -> String:
	if tiene_rama(clave):
		return "esa rama ya existe"
	var d := def_rama(clave)
	if d.is_empty():
		return "esa rama no existe"
	var coste := Eco.escalar(float(d[3]), float(c.rep))
	if c.saldo < coste:
		return "abrirla cuesta %s y no hay caja" % Cesiones.dinero(coste)
	c.mover_saldo(-coste)
	ramas[clave] = true
	## La reputación del club sube: es lo que se compra de verdad.
	c.rep = clampi(c.rep + int(d[5]) / 2, 1, 99)
	return ""

## Cerrar una rama. No devuelve nada y cuesta reputación: cerrar el femenino
## para ahorrar es una decisión con consecuencias, no un ajuste de hoja de
## cálculo.
func cerrar_rama(clave: String, c: Club) -> String:
	if not tiene_rama(clave):
		return "esa rama no está abierta"
	var d := def_rama(clave)
	ramas.erase(clave)
	c.rep = clampi(c.rep - int(d[5]), 1, 99)
	return ""

## Lo que cuestan todas las ramas al mes.
func coste_ramas(c: Club) -> int:
	var n := 0
	for f: Array in RAMAS:
		if tiene_rama(String(f[0])):
			n += Eco.escalar(float(f[4]), float(c.rep))
	return n

## Los socios que aportan las peñas cada mes: poco cada una, pero suman.
func socios_de_penas() -> int:
	var n := 0
	for p: Dictionary in penas:
		n += int(round(float(int(p.get("socios", 0))) * 0.02))
	return n

# ---------------------------------------------------------------------------
#  PRECIOS DINÁMICOS
# ---------------------------------------------------------------------------
#
# El mismo asiento no vale lo mismo contra el líder que contra el colista, y
# cualquier club de verdad lo cobra así. Aquí es un interruptor porque tiene las
# dos caras: sube la recaudación de los partidos que llenan solos y le sube la
# entrada a la gente justo el día del clásico, que es cuando más duele.
#
# La fórmula es la del HTML sin retocar: un 2% por cada punto de reputación que
# el rival tenga por encima o por debajo de 60, con suelo de 3 y techo de 20.
var precio_dinamico: bool = false

const PRECIO_MIN := 3
const PRECIO_MAX := 20

func alternar_precio_dinamico() -> String:
	precio_dinamico = not precio_dinamico
	if precio_dinamico:
		return "El precio de la entrada subirá en los partidos grandes y bajará en los flojos. Más ingresos, pero la hinchada protesta cuando le suben el clásico."
	return "Mismo precio para todos los partidos. Menos ingreso, más paz."

## Lo que se cobra por entrar a ESTE partido. Sin precios dinámicos es el precio
## de siempre, que es justo lo que hace que el interruptor signifique algo.
func precio_efectivo(precio_base: int, rival_rep: int) -> int:
	if not precio_dinamico:
		return precio_base
	var d := float(rival_rep - 60)
	return clampi(int(round(float(precio_base) * (1.0 + d * 0.02))), PRECIO_MIN, PRECIO_MAX)

## Lo que la hinchada opina de que le suban la entrada. Solo se cobra cuando el
## precio SUBE: bajarla en un partido flojo no molesta a nadie.
func castigo_por_subida(precio_base: int, cobrado: int) -> int:
	if not precio_dinamico or cobrado <= precio_base:
		return 0
	return mini(3, cobrado - precio_base)
