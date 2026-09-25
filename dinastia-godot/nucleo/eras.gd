class_name Eras
extends RefCounted
## ÉPOCAS DORADAS Y DECADENCIAS: un país entero ganando o perdiendo una generación.
##
## `procesoEras()` del HTML. Cada cierre de temporada se sortea si algún país
## entra en una época dorada —una camada irrepetible— o en decadencia, y durante
## los siguientes cinco a nueve años TODOS sus juveniles nacen un 13% por encima
## o un 10% por debajo de lo normal.
##
## POR QUÉ IMPORTA. Sin esto, el mapa del mundo es plano: ojear en Chile, en
## España o en Bolivia da lo mismo salvo por el dinero. Con esto, hay un momento
## en el que un país concreto es EL sitio donde hay que estar, y ese momento se
## acaba. Es lo que convierte tener una red de ojeadores en una apuesta con
## calendario en vez de en un gasto fijo.
##
## La decadencia no es simétrica: le toca a los países cuya liga está de verdad
## empobrecida, mirando la caja media de sus clubes. Un país rico puede entrar en
## época dorada; solo uno arruinado puede hundirse.

signal noticia(titulo: String, cuerpo: String)

## Como mucho tres países marcados a la vez. Si medio mundo estuviera en época
## dorada, ninguna lo sería.
const MAX_A_LA_VEZ := 3

## Cada cuánto sale una. Un tercio de las temporadas: lo bastante raro para que
## la noticia importe y lo bastante frecuente para verlo varias veces en una
## carrera larga.
const PROBABILIDAD := 0.34

const BONO_DORADA := 1.13
const BONO_DECADENCIA := 0.90

## país -> {tipo, desde, hasta}
var activas: Dictionary = {}

var _ref: WeakRef

func _init(mundo: Mundo = null) -> void:
	_ref = weakref(mundo)

func _mundo() -> Mundo:
	return _ref.get_ref() as Mundo if _ref != null else null

## La época de un país, o vacío. Se comprueba el año porque una época caducada
## sigue en el diccionario hasta el cierre siguiente.
func era_de(pais: String, anio: int) -> Dictionary:
	var e: Variant = activas.get(pais)
	if e is Dictionary and int((e as Dictionary).get("hasta", 0)) >= anio:
		return e as Dictionary
	return {}

## El multiplicador del TECHO de los juveniles de ese país. Uno si no pasa nada.
func bono(pais: String, anio: int) -> float:
	var e := era_de(pais, anio)
	if e.is_empty():
		return 1.0
	return BONO_DORADA if String(e["tipo"]) == "dorada" else BONO_DECADENCIA

## El cierre de temporada: caducan las viejas y puede aparecer una nueva.
func cierre_de_temporada() -> void:
	var m := _mundo()
	if m == null:
		return
	for k: String in activas.keys():
		var e: Dictionary = activas[k]
		if int(e["hasta"]) >= m.anio:
			continue
		activas.erase(k)
		if String(e["tipo"]) == "dorada":
			noticia.emit("Se apaga una generación",
				"Los expertos dan por cerrada la época dorada de %s. Aquella camada ya pasó los treinta y el relevo no aparece. Quedan las fotos y dos o tres apellidos que nadie va a olvidar." % k)

	if activas.size() >= MAX_A_LA_VEZ:
		return
	if not Azar.suerte(PROBABILIDAD):
		return
	var candidatos: Array[String] = []
	for c: Club in m.clubes.values():
		if not activas.has(c.pais) and not candidatos.has(c.pais):
			candidatos.append(c.pais)
	if candidatos.is_empty():
		return
	var p := String(Azar.uno(candidatos))

	## La decadencia mira la caja: solo se hunde el país cuya liga ya estaba
	## pobre. Un país rico no pierde una generación por sorteo.
	var suma := 0.0
	var cuantos := 0
	for c: Club in m.clubes.values():
		if c.pais != p:
			continue
		suma += float(maxi(0, c.saldo))
		cuantos += 1
	var caja_media := suma / float(maxi(1, cuantos))
	var pobre := caja_media < Eco.ref_caja(60.0) * 0.5
	var tipo := "decadencia" if pobre and Azar.suerte(0.6) else "dorada"
	var duracion := Azar.ent(5, 9) if tipo == "dorada" else Azar.ent(4, 7)
	activas[p] = {"tipo": tipo, "desde": m.anio, "hasta": m.anio + duracion}
	if tipo == "dorada":
		noticia.emit("Época dorada en %s" % p,
			"Algo pasó en las canteras de %s hace quince años y recién ahora se ve: está saliendo una generación entera por encima de la media. Durante los próximos %d años sus juveniles van a valer oro. Si tienes ojeadores allí, es el momento." % [p, duracion])
	else:
		noticia.emit("Decadencia futbolística de %s" % p,
			"La liga de %s se hundió económicamente y las canteras se quedaron sin recursos. Sus juveniles llegarán bastante por debajo de lo habitual durante los próximos años. Un país entero perdiendo una generación." % p)

## Lo que enseña la pantalla: una fila por país marcado.
func mapa_del_talento(anio: int) -> Array[Dictionary]:
	var salida: Array[Dictionary] = []
	for k: String in activas:
		var e: Dictionary = activas[k]
		if int(e["hasta"]) < anio:
			continue
		var dorada := String(e["tipo"]) == "dorada"
		salida.append({
			"pais": k, "tipo": String(e["tipo"]), "dorada": dorada,
			"desde": int(e["desde"]), "hasta": int(e["hasta"]),
			"quedan": int(e["hasta"]) - anio,
			"texto": "sus camadas salen un 13% por encima de lo normal" if dorada \
				else "sus camadas salen un 10% por debajo de lo normal",
			"consejo": "Es el momento de poner ojeadores ahí." if dorada \
				else "Cuidado con fichar juveniles de ese mercado estos años.",
		})
	salida.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return int(a["hasta"]) > int(b["hasta"]))
	return salida

func a_dic() -> Dictionary:
	return {"activas": activas.duplicate(true)}

func desde_dic(d: Dictionary) -> void:
	activas = (d.get("activas", {}) as Dictionary).duplicate(true)
